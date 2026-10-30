defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.ClientVerifierMaintenance
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.TestRepo

  setup_all do
    Application.put_env(:lockspire, :repo, TestRepo)
    start_supervised!(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  test "persisted native verifier rewrap preserves client state and authenticates unchanged secret" do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    old_context = context([{"maintenance-old", old_key}], "maintenance-old")

    new_context =
      context(
        [{"maintenance-old", old_key}, {"maintenance-new", new_key}],
        "maintenance-new"
      )

    set_startup_context(new_context)

    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    assert {:ok, old_verifier} = ClientSecretVerifier.seal(old_context, client_id, secret)

    client = %Client{
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: old_verifier,
      client_type: :confidential,
      name: "Verifier maintenance tracer",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }

    assert {:ok, _persisted} = Repository.register_client(client)
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)
    assert {:ok, :changed} = ClientVerifierMaintenance.rewrap_client(client_id)
    assert {:ok, after_rewrap} = Repository.fetch_client_by_id(client_id)

    assert after_rewrap.client_secret_jwt_verifier_encrypted != old_verifier
    refute String.contains?(after_rewrap.client_secret_jwt_verifier_encrypted, "maintenance-old")

    assert Map.from_struct(after_rewrap) |> Map.delete(:client_secret_jwt_verifier_encrypted) ==
             Map.from_struct(before) |> Map.delete(:client_secret_jwt_verifier_encrypted)

    assert Policy.verify_client_secret(after_rewrap.client_secret_hash, secret)

    assert {:ok, ^secret} =
             ClientSecretVerifier.open(
               new_context,
               client_id,
               after_rewrap.client_secret_jwt_verifier_encrypted,
               []
             )

    audits =
      from(event in AuditEventRecord,
        where:
          event.action == "client_secret_verifier_rewrapped" and
            event.resource_id == ^client_id
      )
      |> then(&Support.all(TestRepo, &1, sensitive: true))

    assert [%AuditEventRecord{outcome: "succeeded"} = audit] = audits
    assert audit.metadata["old_key_id"] == "maintenance-old"
    assert audit.metadata["new_key_id"] == "maintenance-new"
    assert is_binary(audit.metadata["maintenance_at"])
    refute inspect(audit) =~ Base.encode64(old_key)
    refute inspect(audit) =~ Base.encode64(new_key)
    refute inspect(audit) =~ old_verifier
    refute inspect(audit) =~ after_rewrap.client_secret_jwt_verifier_encrypted

    audit_attrs = audit_attrs(client_id, "maintenance-old", "maintenance-new")

    assert {:ok, :already_current} =
             Repository.transact(fn ->
               Repository.compare_and_rewrap(
                 client_id,
                 hash,
                 old_verifier,
                 after_rewrap.client_secret_jwt_verifier_encrypted,
                 audit_attrs
               )
             end)

    assert {:ok, :material_conflict} =
             compare_in_transaction(
               client_id,
               "different-hash",
               old_verifier,
               random_verifier(),
               audit_attrs
             )

    first_conflict = random_verifier()
    second_conflict = random_verifier()

    assert first_conflict != second_conflict

    for attempted_replacement <- [first_conflict, second_conflict] do
      assert {:ok, :material_conflict} =
               compare_in_transaction(
                 client_id,
                 hash,
                 "stale-expected-material",
                 attempted_replacement,
                 audit_attrs
               )
    end

    assert [^audit] =
             from(event in AuditEventRecord,
               where:
                 event.action == "client_secret_verifier_rewrapped" and
                   event.resource_id == ^client_id
             )
             |> then(&Support.all(TestRepo, &1, sensitive: true))
  end

  test "persisted expired migrated verifier rewrap preserves authentication expiry" do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    client_id = unique_id()
    secret = "maintenance-expired-migrated-secret"
    signed_at_ms = 1_700_000_000_123
    deadline_ms = signed_at_ms + 1_250
    old_context = context([{"maintenance-migrated-old", old_key}], "maintenance-migrated-old")

    new_context =
      context(
        [
          {"maintenance-migrated-old", old_key},
          {"maintenance-migrated-new", new_key}
        ],
        "maintenance-migrated-new"
      )

    set_startup_context(new_context)
    hash = Policy.hash_client_secret(secret)

    verifier =
      seal_migrated(
        old_context,
        client_id,
        secret,
        signed_at_ms,
        deadline_ms
      )

    assert {:ok, _persisted} = Repository.register_client(client(client_id, hash, verifier))
    assert {:ok, :changed} = ClientVerifierMaintenance.rewrap_client(client_id)
    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)

    assert stored.client_secret_jwt_verifier_encrypted != verifier

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(
               new_context,
               client_id,
               stored.client_secret_jwt_verifier_encrypted,
               verifier_now_ms: deadline_ms + 1
             )

    assert {:ok, _secret} =
             ClientSecretVerifier.open(
               new_context,
               client_id,
               stored.client_secret_jwt_verifier_encrypted,
               verifier_now_ms: deadline_ms
             )
  end

  test "compare and rewrap rejects malformed or sensitive audit values before mutation" do
    {hash, _secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    verifier = random_verifier()
    replacement = random_verifier()

    assert {:ok, _} = Repository.register_client(client(client_id, hash, verifier))
    attrs = audit_attrs(client_id, "old-key", "new-key")
    metadata = attrs.metadata
    secret_sentinel = "audit-secret-sentinel-012345678901234567890123456789"
    hash_sentinel = "audit-hash-sentinel-01234567890123456789012345678901"
    ciphertext_sentinel = "LSCV1.ciphertext-sentinel." <> String.duplicate("A", 64)
    malformed_datetime = %DateTime{DateTime.utc_now() | year: secret_sentinel}

    invalid_attrs = [
      Map.put(attrs, :action, secret_sentinel),
      Map.put(attrs, :outcome, hash_sentinel),
      Map.put(attrs, :actor, %{type: secret_sentinel}),
      Map.put(attrs, :actor, %{type: :system, id: hash_sentinel}),
      Map.put(attrs, :actor, %{}),
      Map.put(attrs, :resource, %{type: :client, id: secret_sentinel}),
      Map.put(attrs, :resource, %{type: :other, id: client_id}),
      Map.put(attrs, :resource, %{type: :client, id: client_id, extra: ciphertext_sentinel}),
      Map.put(attrs, :metadata, Map.delete(metadata, :old_key_id)),
      Map.put(attrs, :metadata, Map.put(metadata, :old_key_id, secret_sentinel)),
      Map.put(attrs, :metadata, Map.put(metadata, :old_key_id, hash_sentinel)),
      Map.put(attrs, :metadata, Map.put(metadata, :old_key_id, ciphertext_sentinel)),
      Map.put(attrs, :metadata, Map.put(metadata, :old_key_id, :malformed)),
      Map.put(attrs, :metadata, Map.put(metadata, :new_key_id, secret_sentinel)),
      Map.put(attrs, :metadata, Map.put(metadata, :new_key_id, :malformed)),
      Map.put(attrs, :metadata, Map.delete(metadata, :new_key_id)),
      Map.put(attrs, :metadata, Map.put(metadata, :maintenance_at, secret_sentinel)),
      Map.put(attrs, :metadata, Map.put(metadata, :maintenance_at, NaiveDateTime.utc_now())),
      Map.put(attrs, :metadata, Map.put(metadata, :maintenance_at, malformed_datetime)),
      Map.put(attrs, :metadata, Map.delete(metadata, :maintenance_at)),
      Map.put(attrs, :metadata, Map.put(metadata, :extra, ciphertext_sentinel)),
      Map.put(attrs, :unexpected, secret_sentinel)
    ]

    for invalid <- invalid_attrs do
      assert {:error, :client_secret_verifier_maintenance_failed} =
               compare_in_transaction(client_id, hash, verifier, replacement, invalid)

      assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
      assert stored.client_secret_jwt_verifier_encrypted == verifier

      audits =
        from(event in AuditEventRecord,
          where:
            event.action == "client_secret_verifier_rewrapped" and
              event.resource_id == ^client_id
        )
        |> then(&Support.all(TestRepo, &1, sensitive: true))

      assert audits == []
    end
  end

  test "current key custody is a no-op and creates no maintenance audit" do
    key = :crypto.strong_rand_bytes(32)
    current_context = context([{"maintenance-current", key}], "maintenance-current")
    set_startup_context(current_context)

    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    assert {:ok, verifier} = ClientSecretVerifier.seal(current_context, client_id, secret)
    assert {:ok, _} = Repository.register_client(client(client_id, hash, verifier))

    assert {:ok, :already_current} = ClientVerifierMaintenance.rewrap_client(client_id)

    audit_count =
      from(event in AuditEventRecord,
        where:
          event.action == "client_secret_verifier_rewrapped" and
            event.resource_id == ^client_id
      )
      |> then(&TestRepo.aggregate(&1, :count))

    assert audit_count == 0
    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
    assert stored.client_secret_jwt_verifier_encrypted == verifier
  end

  test "qualified legacy verifier promotion preserves age and independent client deadlines" do
    key = :crypto.strong_rand_bytes(32)
    current_context = context([{"maintenance-legacy-current", key}], "maintenance-legacy-current")
    set_startup_context(current_context)

    secret = "maintenance-qualified-legacy-secret"
    hash = Policy.hash_client_secret(secret)
    client_id = unique_id()
    signed_at_seconds = System.os_time(:second) - 60
    signed_at_ms = signed_at_seconds * 1_000
    deadline_ms = signed_at_ms + 3_600_000
    legacy_key_base = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]

    legacy =
      Lockspire.TestSupport.ClientSecretVerifierFixtures.legacy_verifier(secret,
        signed_at: signed_at_seconds,
        max_age: 3_600
      )

    expires_at = DateTime.add(DateTime.utc_now(), 7, :day)
    secret_expires_at = DateTime.add(DateTime.utc_now(), 3, :day)

    assert {:ok, _} =
             Repository.register_client(
               client(client_id, hash, legacy)
               |> Map.put(:client_expires_at, expires_at)
               |> Map.put(:client_secret_expires_at, secret_expires_at)
             )

    assert {:ok, before} = Repository.fetch_client_by_id(client_id)

    assert {:ok, :changed} =
             ClientVerifierMaintenance.rewrap_client(client_id,
               legacy_secret_key_base: legacy_key_base
             )

    assert {:ok, after_rewrap} = Repository.fetch_client_by_id(client_id)
    assert after_rewrap.client_secret_jwt_verifier_encrypted != legacy

    assert Map.from_struct(after_rewrap)
           |> Map.delete(:client_secret_jwt_verifier_encrypted) ==
             Map.from_struct(before)
             |> Map.delete(:client_secret_jwt_verifier_encrypted)

    assert {:ok, metadata} =
             ClientSecretVerifier.inspect_custody(
               current_context,
               client_id,
               after_rewrap.client_secret_jwt_verifier_encrypted,
               hash,
               now_ms: System.os_time(:millisecond)
             )

    assert metadata.age_kind == :migrated
    assert metadata.signed_at_ms == signed_at_ms
    assert metadata.deadline_ms == deadline_ms
    assert metadata.authentication_eligible?

    assert [%AuditEventRecord{} = audit] =
             from(event in AuditEventRecord,
               where:
                 event.action == "client_secret_verifier_rewrapped" and
                   event.resource_id == ^client_id
             )
             |> then(&Support.all(TestRepo, &1, sensitive: true))

    assert audit.metadata["old_key_id"] == "legacy"
    assert audit.metadata["new_key_id"] == "maintenance-legacy-current"
    assert is_binary(audit.metadata["maintenance_at"])
  end

  test "expired legacy verifier remains unchanged and requires recovery" do
    current_context =
      context(
        [{"maintenance-expired-legacy", :crypto.strong_rand_bytes(32)}],
        "maintenance-expired-legacy"
      )

    set_startup_context(current_context)

    secret = "maintenance-expired-legacy-secret"
    hash = Policy.hash_client_secret(secret)
    client_id = unique_id()
    signed_at_seconds = System.os_time(:second) - 90_000
    legacy_key_base = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]

    legacy =
      Lockspire.TestSupport.ClientSecretVerifierFixtures.legacy_verifier(secret,
        signed_at: signed_at_seconds,
        max_age: 86_400
      )

    assert {:ok, _} = Repository.register_client(client(client_id, hash, legacy))
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)

    assert {:error, :client_secret_verifier_maintenance_failed} =
             ClientVerifierMaintenance.rewrap_client(client_id,
               legacy_secret_key_base: legacy_key_base
             )

    assert {:ok, after_attempt} = Repository.fetch_client_by_id(client_id)
    assert after_attempt == before
  end

  test "missing maintenance capability fails before client access" do
    Application.put_env(:lockspire, :client_store, Lockspire.TestSupport.NoMaintenanceClientStore)

    assert {:error, :client_secret_verifier_maintenance_unsupported} =
             ClientVerifierMaintenance.rewrap_client("missing-maintenance-client")

    refute_received {:client_fetch, _client_id}
  after
    Application.delete_env(:lockspire, :client_store)
  end

  test "declared shared PostgreSQL delegation rewraps through its selected callbacks" do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    old_context = context([{"delegated-old", old_key}], "delegated-old")

    new_context =
      context([{"delegated-old", old_key}, {"delegated-new", new_key}], "delegated-new")

    set_startup_context(new_context)
    delegated = Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    Application.put_env(:lockspire, :client_store, delegated)
    Application.put_env(:lockspire, :transaction_store, delegated)

    on_exit(fn ->
      Application.delete_env(:lockspire, :client_store)
      Application.delete_env(:lockspire, :transaction_store)
    end)

    {hash, secret} = Clients.rotate_secret_hash()
    client_id = unique_id()
    assert {:ok, verifier} = ClientSecretVerifier.seal(old_context, client_id, secret)
    assert {:ok, _} = Repository.register_client(client(client_id, hash, verifier))

    assert {:ok, :changed} = ClientVerifierMaintenance.rewrap_client(client_id)
    assert_received {:client_fetch, ^client_id}
    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)

    assert {:ok, ^secret} =
             ClientSecretVerifier.open(
               new_context,
               client_id,
               stored.client_secret_jwt_verifier_encrypted,
               []
             )
  end

  defp context(keys, current) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys:
             Enum.map(keys, fn {key_id, key} ->
               {key_id, Base.url_encode64(key, padding: false)}
             end),
           current: current,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp seal_migrated(context, client_id, secret, signed_at_ms, deadline_ms) do
    key = context.keys[context.current_id]
    iv = :crypto.strong_rand_bytes(12)

    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    aad =
      "lockspire-client-secret-jwt-verifier" <>
        <<0>> <> "LSCV1" <> <<0>> <> context.current_id <> <<0>> <> client_id

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    "LSCV1." <>
      context.current_id <>
      "." <> Base.url_encode64(iv <> tag <> ciphertext, padding: false)
  end

  defp compare_in_transaction(client_id, hash, expected, replacement, attrs) do
    Repository.transact(fn ->
      Repository.compare_and_rewrap(client_id, hash, expected, replacement, attrs)
    end)
  end

  defp audit_attrs(client_id, old_key_id, new_key_id) do
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{
        old_key_id: old_key_id,
        new_key_id: new_key_id,
        maintenance_at: DateTime.utc_now()
      }
    }
  end

  defp random_verifier,
    do: "LSCV1.random." <> Base.url_encode64(:crypto.strong_rand_bytes(48), padding: false)

  defp client(client_id, hash, verifier) do
    %Client{
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Verifier maintenance delegation",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }
  end

  defp set_startup_context(context) do
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)

    ExUnit.Callbacks.on_exit(fn ->
      case previous_context do
        :missing -> :persistent_term.erase(cache_key)
        previous -> :persistent_term.put(cache_key, previous)
      end
    end)

    :persistent_term.put(cache_key, context)
  end

  defp unique_id,
    do:
      "phase177-maintenance-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end

defmodule Lockspire.TestSupport.NoMaintenanceClientStore do
  def fetch_client_by_id(client_id) do
    send(self(), {:client_fetch, client_id})
    {:ok, nil}
  end
end
