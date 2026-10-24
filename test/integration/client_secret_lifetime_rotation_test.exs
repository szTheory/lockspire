defmodule Lockspire.ClientSecretLifetimeRotationTest do
  use Lockspire.DataCase, async: false

  import Ecto.Query

  alias Lockspire.Admin.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository

  @moduletag :integration

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "operator rotation uses the current DCR policy and one deferred decision time" do
    now = ~U[2030-01-02 03:04:05Z]
    app_deadline = DateTime.add(now, 10_000, :second)
    management_deadline = DateTime.add(now, 20_000, :second)
    client_id = "rotation-current-policy-#{System.unique_integer([:positive])}"

    assert {:ok, _policy} =
             Repository.put_server_policy(%ServerPolicy{
               dcr_default_client_secret_lifetime_seconds: 60
             })

    assert {:ok, _client} =
             Repository.register_client(%Client{
               lifetime_version: 1,
               client_id: client_id,
               client_secret_hash: "sha256:old-salt:old-hash",
               client_secret_jwt_verifier_encrypted: "old-verifier",
               client_type: :confidential,
               name: "Rotation Client",
               redirect_uris: ["https://client.example/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               provenance: :self_registered,
               client_expires_at: app_deadline,
               registration_access_token_expires_at: management_deadline
             })

    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:ok, %{client: %Client{} = rotated, client_secret: plaintext}} =
             Clients.rotate_client_secret(client_id, %{
               now: fn -> now end,
               actor: %{type: :operator, id: "rotation-test"}
             })

    assert DateTime.compare(rotated.last_secret_rotated_at, now) == :eq

    assert DateTime.compare(rotated.client_secret_expires_at, DateTime.add(now, 60, :second)) ==
             :eq

    assert DateTime.compare(rotated.client_expires_at, app_deadline) == :eq

    assert DateTime.compare(rotated.registration_access_token_expires_at, management_deadline) ==
             :eq

    assert rotated.active
    assert rotated.client_secret_hash != plaintext
    assert Lockspire.Security.Policy.verify_client_secret(rotated.client_secret_hash, plaintext)

    assert {:ok, %Client{} = stored} = Repository.fetch_client_by_id(client_id)
    assert stored == rotated

    assert %AuditEventRecord{} =
             audit =
             AuditEventRecord
             |> where([event], event.resource_id == ^client_id)
             |> order_by([event], desc: event.inserted_at)
             |> limit(1)
             |> Lockspire.TestRepo.one()

    assert audit.action == "client_secret_rotated"
    assert {:ok, audit_rotated_at, 0} = DateTime.from_iso8601(audit.metadata["rotated_at"])
    assert DateTime.compare(audit_rotated_at, now) == :eq
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count + 1

    row = Lockspire.TestRepo.get_by!(ClientRecord, client_id: client_id)
    assert row.client_secret_hash == rotated.client_secret_hash

    assert row.client_secret_jwt_verifier_encrypted ==
             rotated.client_secret_jwt_verifier_encrypted
  end
end
