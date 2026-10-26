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
  end

  test "missing maintenance capability fails before client access" do
    Application.put_env(:lockspire, :client_store, Lockspire.TestSupport.NoMaintenanceClientStore)

    assert {:error, :client_secret_verifier_maintenance_unsupported} =
             ClientVerifierMaintenance.rewrap_client("missing-maintenance-client")

    refute_received {:client_fetch, _client_id}
  after
    Application.delete_env(:lockspire, :client_store)
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

  defp set_startup_context(context) do
    :persistent_term.put(Lockspire.Config.client_secret_verifier_cache_key(), context)
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
