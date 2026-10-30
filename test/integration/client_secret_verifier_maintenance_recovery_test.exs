defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceRecoveryTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Admin.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ConsentGrantRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.UsedJtiRecord
  alias Lockspire.TestRepo
  alias Lockspire.TestSupport.ClientSecretVerifierFixtures, as: Fixtures

  @moduletag :integration

  setup_all do
    Application.put_env(:lockspire, :repo, TestRepo)

    unless Process.whereis(TestRepo) do
      start_supervised!(TestRepo)
    end

    Sandbox.mode(TestRepo, :manual)
    :ok
  end

  setup do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    old_context = context([{"recovery-old", old_key}], "recovery-old")
    staged_context = context([{"recovery-old", old_key}, {"recovery-new", new_key}], nil, :legacy)

    active_context =
      context([{"recovery-old", old_key}, {"recovery-new", new_key}], "recovery-new")

    lost_context = context([{"recovery-new", new_key}], "recovery-new")
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    :persistent_term.put(cache_key, active_context)

    on_exit(fn ->
      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)

    %{
      old_context: old_context,
      staged_context: staged_context,
      active_context: active_context,
      lost_context: lost_context
    }
  end

  test "reader-first activation rewrites old custody, preserves credentials, and needs a fresh complete check",
       %{old_context: old_context, staged_context: staged_context, active_context: active_context} do
    old_client = create_client(:client_secret_jwt, old_context)
    current_client = create_client(:client_secret_jwt, active_context)
    basic_client = create_client(:client_secret_basic, old_context)
    post_client = create_client(:client_secret_post, old_context)
    public_client = create_public_client()
    signing_key = create_signing_key()
    signing_ciphertext_before = signing_ciphertext(signing_key)
    endpoint_secret_before = Lockspire.Config.secret_key_base()

    assert {:ok, old_client.secret} ==
             ClientSecretVerifier.open(
               staged_context,
               old_client.client.client_id,
               old_client.client.client_secret_jwt_verifier_encrypted,
               []
             )

    assert {:ok, current_client.secret} ==
             ClientSecretVerifier.open(
               staged_context,
               current_client.client.client_id,
               current_client.client.client_secret_jwt_verifier_encrypted,
               []
             )

    old_hash = old_client.client.client_secret_hash
    basic_hash = basic_client.client.client_secret_hash
    post_hash = post_client.client.client_secret_hash
    old_verifier = old_client.client.client_secret_jwt_verifier_encrypted
    basic_verifier = basic_client.client.client_secret_jwt_verifier_encrypted
    post_verifier = post_client.client.client_secret_jwt_verifier_encrypted
    set_context(active_context)

    assert {:ok, preview} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 500)
             end)

    assert preview.scan_complete?
    assert preview.pending >= 3
    assert preview.committed_changed == 0

    assert fetch_client(old_client.client.client_id).client_secret_jwt_verifier_encrypted ==
             old_verifier

    assert {:ok, apply_report} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 500)
             end)

    assert apply_report.scan_complete?
    assert apply_report.committed_changed >= 3
    assert apply_report.no_material >= 1
    refute apply_report.custody_condition_met?
    refute inspect(apply_report) =~ old_client.secret
    refute inspect(apply_report) =~ old_verifier

    old_after = fetch_client(old_client.client.client_id)
    current_after = fetch_client(current_client.client.client_id)
    basic_after = fetch_client(basic_client.client.client_id)
    post_after = fetch_client(post_client.client.client_id)

    assert old_after.client_secret_hash == old_hash
    assert basic_after.client_secret_hash == basic_hash
    assert post_after.client_secret_hash == post_hash
    refute old_after.client_secret_jwt_verifier_encrypted == old_verifier
    refute basic_after.client_secret_jwt_verifier_encrypted == basic_verifier
    refute post_after.client_secret_jwt_verifier_encrypted == post_verifier

    assert current_after.client_secret_jwt_verifier_encrypted ==
             current_client.client.client_secret_jwt_verifier_encrypted

    assert {:ok, retry_report} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 500)
             end)

    assert retry_report.committed_changed == 0
    assert retry_report.already_current >= 4

    assert authenticate_jwt(old_after, old_client.secret) == {:ok, old_after}
    assert authenticate_hash(basic_after, basic_client.secret, :basic) == {:ok, basic_after}
    assert authenticate_hash(post_after, post_client.secret, :post) == {:ok, post_after}

    assert {:ok, check_report} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 500)
             end)

    assert check_report.scan_complete?
    assert check_report.custody_condition_met?
    assert check_report.failed == 0
    assert check_report.pending == 0
    assert check_report.uninspected == 0
    assert check_report.no_material >= 1

    assert Enum.any?(check_report.details, fn detail ->
             detail.client_id.value == encode_id(public_client.client_id) and
               detail.classification == :no_material
           end)

    assert Lockspire.Config.secret_key_base() == endpoint_secret_before
    assert signing_ciphertext(signing_key) == signing_ciphertext_before
    assert fetch_client(public_client.client_id).client_secret_hash == nil
    assert fetch_client(public_client.client_id).client_secret_jwt_verifier_encrypted == nil
  end

  test "lost-key reporting fails JWT closed, restoration preserves the secret, and authorized rotation replaces it",
       %{old_context: old_context, active_context: active_context, lost_context: lost_context} do
    restore_client = create_client(:client_secret_jwt, old_context)
    rotate_client = create_client(:client_secret_jwt, old_context)
    inactive_client = create_client(:client_secret_jwt, old_context, active: false)

    expired_secret_client =
      create_client(:client_secret_jwt, old_context,
        client_secret_expires_at: expired_at(-60),
        last_secret_rotated_at: expired_at(-2 * 86_400)
      )

    basic_client = create_client(:client_secret_basic, old_context)
    post_client = create_client(:client_secret_post, old_context)

    restore_before = fetch_client(restore_client.client.client_id)
    rotate_before = fetch_client(rotate_client.client.client_id)
    basic_before = fetch_client(basic_client.client.client_id)
    post_before = fetch_client(post_client.client.client_id)
    before_effects = effects(restore_client.client.client_id)
    set_context(lost_context)

    assert {:error, report} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 500)
             end)

    assert report.scan_complete?
    assert report.failed >= 1
    refute inspect(report) =~ restore_client.secret
    refute inspect(report) =~ restore_before.client_secret_jwt_verifier_encrypted
    restore_detail = detail_for(report, restore_client.client.client_id)
    assert restore_detail.classification == :unknown_key
    assert restore_detail.reason == :unknown_key
    assert restore_detail.next_action == :restore_verifier_key

    assert {:error, %ClientAuth.Error{reason_code: :client_secret_verifier_unavailable}} =
             authenticate_jwt(restore_before, restore_client.secret)

    assert effects(restore_client.client.client_id) == before_effects
    assert authenticate_hash(basic_before, basic_client.secret, :basic) == {:ok, basic_before}
    assert authenticate_hash(post_before, post_client.secret, :post) == {:ok, post_before}

    assert fetch_client(basic_client.client.client_id).client_secret_hash ==
             basic_before.client_secret_hash

    assert fetch_client(post_client.client.client_id).client_secret_hash ==
             post_before.client_secret_hash

    set_context(active_context)

    assert {:ok, restored} = authenticate_jwt(restore_before, restore_client.secret)
    assert restored.client_id == restore_before.client_id

    assert fetch_client(restore_before.client_id).client_secret_hash ==
             restore_before.client_secret_hash

    set_context(lost_context)

    assert {:ok, %{client: rotated, client_secret: replacement_secret} = rotation} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Clients.rotate_client_secret(rotate_before.client_id,
                 actor: %{type: :operator, id: "phase177-recovery"}
               )
             end)

    assert Map.keys(rotation) |> Enum.sort() == [:client, :client_secret]
    assert rotated.client_id == rotate_before.client_id
    assert rotated.client_secret_hash != rotate_before.client_secret_hash

    assert rotated.client_secret_jwt_verifier_encrypted !=
             rotate_before.client_secret_jwt_verifier_encrypted

    assert Policy.verify_client_secret(rotated.client_secret_hash, replacement_secret)

    assert {:error, %ClientAuth.Error{}} = authenticate_jwt(rotated, rotate_client.secret)
    assert {:ok, authenticated} = authenticate_jwt(rotated, replacement_secret)
    assert authenticated.client_id == rotated.client_id

    set_context(active_context)

    expired_secret_before = fetch_client(expired_secret_client.client.client_id)

    assert {:error, %ClientAuth.Error{reason_code: :client_secret_expired}} =
             authenticate_jwt(expired_secret_before, expired_secret_client.secret)

    inactive_before = fetch_client(inactive_client.client.client_id)

    assert {:error, %ClientAuth.Error{reason_code: :client_app_disabled}} =
             authenticate_jwt(inactive_before, inactive_client.secret)

    assert {:ok, %{client: inactive_rotated, client_secret: inactive_secret}} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Clients.rotate_client_secret(inactive_before.client_id,
                 actor: %{type: :operator, id: "phase177-recovery"}
               )
             end)

    refute inactive_rotated.active

    assert {:error, %ClientAuth.Error{reason_code: :client_app_disabled}} =
             authenticate_jwt(inactive_rotated, inactive_secret)
  end

  defp create_client(method, verifier_context, opts \\ []) do
    client_id = unique_id("recovery-client")
    secret = "recovery-secret-" <> Ecto.UUID.generate()
    hash = Policy.hash_client_secret(secret)

    verifier =
      if method == :none do
        nil
      else
        {:ok, value} = ClientSecretVerifier.seal(verifier_context, client_id, secret)
        value
      end

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    client = %Client{
      client_id: client_id,
      client_secret_hash: if(method == :none, do: nil, else: hash),
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: if(method == :none, do: :public, else: :confidential),
      name: "Verifier recovery fixture",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: method,
      pkce_required: false,
      subject_type: :public,
      active: Keyword.get(opts, :active, true),
      provenance: :operator,
      metadata: %{"phase177" => true},
      lifetime_version: 1,
      client_expires_at: Keyword.get(opts, :client_expires_at, DateTime.add(now, 30, :day)),
      client_secret_expires_at:
        Keyword.get(opts, :client_secret_expires_at, DateTime.add(now, 30, :day)),
      last_secret_rotated_at: Keyword.get(opts, :last_secret_rotated_at, now)
    }

    assert {:ok, persisted} =
             Sandbox.unboxed_run(TestRepo, fn -> Repository.register_client(client) end)

    on_exit(fn -> cleanup(client_id, nil) end)
    %{client: persisted, secret: secret}
  end

  defp create_public_client do
    client = %Client{
      client_id: unique_id("recovery-public"),
      client_type: :public,
      name: "Verifier no-material fixture",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :none,
      pkce_required: false,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 1,
      client_expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
    }

    assert {:ok, persisted} =
             Sandbox.unboxed_run(TestRepo, fn -> Repository.register_client(client) end)

    on_exit(fn -> cleanup(persisted.client_id, nil) end)
    persisted
  end

  defp create_signing_key do
    kid = unique_id("recovery-signing")
    Sandbox.unboxed_run(TestRepo, fn -> Lockspire.TokenExchangeCase.publish_signing_key(kid) end)
    on_exit(fn -> cleanup(nil, kid) end)
    kid
  end

  defp signing_ciphertext(kid) do
    Sandbox.unboxed_run(TestRepo, fn ->
      TestRepo.one!(
        from(key in SigningKeyRecord, where: key.kid == ^kid, select: key.private_jwk_encrypted)
      )
    end)
  end

  defp authenticate_jwt(client, secret) do
    {params, _jti, _issued_at} = Fixtures.assertion(client, secret)

    Sandbox.unboxed_run(TestRepo, fn ->
      ClientAuth.authenticate(params, nil,
        client_store: Repository,
        jti_store: Repository,
        server_policy_store: Repository,
        supported_jwt_auth_methods: [:client_secret_jwt]
      )
    end)
  end

  defp authenticate_hash(client, secret, :basic) do
    Sandbox.unboxed_run(TestRepo, fn ->
      ClientAuth.authenticate(%{}, "Basic " <> Base.encode64("#{client.client_id}:#{secret}"),
        client_store: Repository
      )
    end)
  end

  defp authenticate_hash(client, secret, :post) do
    Sandbox.unboxed_run(TestRepo, fn ->
      ClientAuth.authenticate(%{"client_id" => client.client_id, "client_secret" => secret}, nil,
        client_store: Repository
      )
    end)
  end

  defp fetch_client(client_id) do
    {:ok, client} =
      Sandbox.unboxed_run(TestRepo, fn -> Repository.fetch_client_by_id(client_id) end)

    client
  end

  defp effects(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      %{
        jtis:
          TestRepo.aggregate(
            from(jti in UsedJtiRecord, where: jti.client_id == ^client_id),
            :count
          ),
        tokens:
          TestRepo.aggregate(
            from(token in TokenRecord, where: token.client_id == ^client_id),
            :count
          ),
        grants:
          TestRepo.aggregate(
            from(grant in ConsentGrantRecord, where: grant.client_id == ^client_id),
            :count
          )
      }
    end)
  end

  defp detail_for(report, client_id) do
    encoded = encode_id(client_id)

    Enum.find(report.details, &(&1.client_id.value == encoded)) ||
      flunk("missing safe client detail")
  end

  defp encode_id(client_id), do: Base.url_encode64(client_id, padding: false)

  defp set_context(context),
    do: :persistent_term.put(Lockspire.Config.client_secret_verifier_cache_key(), context)

  defp context(keys, current, write_mode \\ :dedicated) do
    {:ok, resolved} =
      Context.resolve(
        {:present,
         [
           keys: Enum.map(keys, fn {id, key} -> {id, Base.url_encode64(key, padding: false)} end),
           current: current,
           write_mode: write_mode,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, valid} = Context.validate(resolved)
    valid
  end

  defp cleanup(client_id, kid) do
    Sandbox.unboxed_run(TestRepo, fn ->
      if is_binary(client_id) do
        interaction_ids =
          TestRepo.all(
            from(token in TokenRecord,
              where: token.client_id == ^client_id,
              select: token.interaction_id
            )
          )

        TestRepo.delete_all(
          from(event in AuditEventRecord, where: event.resource_id == ^client_id)
        )

        TestRepo.delete_all(
          from(grant in ConsentGrantRecord, where: grant.client_id == ^client_id)
        )

        TestRepo.delete_all(from(jti in UsedJtiRecord, where: jti.client_id == ^client_id))
        TestRepo.delete_all(from(token in TokenRecord, where: token.client_id == ^client_id))

        TestRepo.delete_all(
          from(interaction in InteractionRecord,
            where: interaction.interaction_id in ^interaction_ids
          )
        )

        TestRepo.delete_all(from(client in ClientRecord, where: client.client_id == ^client_id))
      end

      if is_binary(kid) do
        TestRepo.delete_all(from(key in SigningKeyRecord, where: key.kid == ^kid))
      end
    end)
  end

  defp unique_id(prefix),
    do: "phase177-#{prefix}-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

  defp expired_at(seconds),
    do: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(seconds, :second)
end
