defmodule Lockspire.Storage.ManagementTokenRollbackTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Ecto.Query

  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.ServerPolicyRecord
  alias Lockspire.Test.Fixtures.DcrFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    Repository.put_server_policy(
      DcrFixtures.server_policy(%{
        registration_policy: :open,
        dcr_default_client_lifetime_seconds: 500,
        dcr_default_client_secret_lifetime_seconds: 300,
        dcr_default_registration_access_token_lifetime_seconds: 40
      })
    )

    :ok
  end

  defp dispatch(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp register_client do
    conn = build_conn(:post, "/register", DcrFixtures.valid_metadata()) |> dispatch()
    assert conn.status == 201
    Jason.decode!(conn.resp_body)
  end

  test "PUT and host recovery roll back v0/v1 replacement fields and audit on write failures" do
    for version <- [0, 1], operation <- [:put, :recovery], failure <- [:client, :audit] do
      registered = register_client()
      client_id = registered["client_id"]
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      historical = DateTime.add(now, -100, :second)

      version_fields =
        if version == 0 do
          [
            lifetime_version: 0,
            client_expires_at: historical,
            client_secret_expires_at: historical,
            registration_access_token_expires_at: historical
          ]
        else
          [
            lifetime_version: 1,
            client_expires_at: DateTime.add(now, 500, :second),
            client_secret_expires_at: DateTime.add(now, 300, :second),
            registration_access_token_expires_at: DateTime.add(now, 40, :second)
          ]
        end

      assert {1, _} =
               Lockspire.TestRepo.update_all(
                 from(c in ClientRecord, where: c.client_id == ^client_id),
                 set: Keyword.put(version_fields, :name, "original row")
               )

      {:ok, current} = Repository.fetch_client_by_id(client_id)
      before = client_row(client_id)
      audit_count = audit_count(client_id)

      result =
        with_failure(failure, fn ->
          case operation do
            :put ->
              RegistrationManagement.update(client_id, %{
                metadata: DcrFixtures.valid_metadata() |> Map.put("client_id", client_id),
                server_policy: server_policy!(),
                client: current,
                now: now
              })

            :recovery ->
              RegistrationManagement.rotate_registration_access_token(current, now: now)
          end
        end)

      assert {:error, _reason} = result
      refute match?({:ok, %{registration_access_token_plaintext: _}}, result)
      assert client_row(client_id) == before
      assert audit_count(client_id) == audit_count
    end
  end

  test "malformed recovery clock and durable policy fail as server errors without writes" do
    registered = register_client()
    client_id = registered["client_id"]
    {:ok, client} = Repository.fetch_client_by_id(client_id)
    before = client_row(client_id)
    audit_count = audit_count(client_id)

    assert {:error, %Registration.Error{code: :server_error}} =
             RegistrationManagement.rotate_registration_access_token(client, now: :invalid)

    assert client_row(client_id) == before
    assert audit_count(client_id) == audit_count

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(c in ClientRecord, where: c.client_id == ^client_id),
               set: [lifetime_version: 2]
             )

    {:ok, unsupported} = Repository.fetch_client_by_id(client_id)

    assert {:error, %Registration.Error{code: :server_error}} =
             RegistrationManagement.rotate_registration_access_token(unsupported)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(c in ClientRecord, where: c.client_id == ^client_id),
               set: [lifetime_version: 1]
             )

    assert {1, _} =
             Lockspire.TestRepo.update_all(ServerPolicyRecord,
               set: [dcr_default_registration_access_token_lifetime_seconds: -1]
             )

    {:ok, current_policy_invalid} = Repository.fetch_client_by_id(client_id)

    assert {:error, %Registration.Error{code: :server_error}} =
             RegistrationManagement.rotate_registration_access_token(current_policy_invalid)

    Repository.put_server_policy(
      DcrFixtures.server_policy(%{
        registration_policy: :open,
        dcr_default_registration_access_token_lifetime_seconds: 40
      })
    )

    assert client_row(client_id) == before
    assert audit_count(client_id) == audit_count
  end

  defp server_policy! do
    {:ok, policy} = Repository.get_server_policy()
    policy
  end

  defp with_failure(:client, fun) do
    install_client_failure()

    try do
      fun.()
    after
      remove_failures()
    end
  end

  defp with_failure(:audit, fun) do
    install_audit_failure()

    try do
      fun.()
    after
      remove_failures()
    end
  end

  defp install_client_failure do
    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan165_reject_client() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'plan165 forced management client write failure';
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan165_client_failure
    BEFORE UPDATE ON lockspire_clients
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan165_reject_client()
    """)
  end

  defp install_audit_failure do
    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan165_reject_audit() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'plan165 forced management audit failure';
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan165_audit_failure
    BEFORE INSERT ON lockspire_audit_events
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan165_reject_audit()
    """)
  end

  defp remove_failures do
    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan165_client_failure ON lockspire_clients"
    )

    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan165_audit_failure ON lockspire_audit_events"
    )

    Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_plan165_reject_client()")
    Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_plan165_reject_audit()")
  end

  defp client_row(client_id),
    do: Lockspire.TestRepo.one!(from(c in ClientRecord, where: c.client_id == ^client_id))

  defp audit_count(client_id),
    do:
      Lockspire.TestRepo.aggregate(
        from(a in AuditEventRecord, where: a.resource_id == ^client_id),
        :count
      )
end
