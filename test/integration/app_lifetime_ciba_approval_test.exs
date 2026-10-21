defmodule Lockspire.Integration.AppLifetimeCibaApprovalTest do
  use ExUnit.Case, async: false

  alias Lockspire.Ciba
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Storage.Ecto.Repository

  @moduletag :integration
  @before ~U[2026-04-28 10:59:59Z]
  @deadline ~U[2026-04-28 11:00:00Z]

  defmodule AccountResolver do
    @behaviour Lockspire.Host.AccountResolver
    def resolve_current_account(_conn, _context), do: {:error, :not_implemented}
    def resolve_account("user@example.test", _context), do: {:ok, "user-123"}
    def build_claims(_account, _context), do: {:error, :not_implemented}
    def redirect_for_login(_conn, _context), do: %{}
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_expires_at: @deadline,
        client_id: "app-lifetime-ciba-#{System.unique_integer([:positive])}",
        name: "Mobile client",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        created_at: @before
      })

    %{client: client}
  end

  test "CIBA initiation rechecks app expiry after host resolution before writing a request", %{
    client: client
  } do
    Process.put(:ciba_clock_calls, 0)

    clock = fn ->
      call = Process.get(:ciba_clock_calls)
      Process.put(:ciba_clock_calls, call + 1)
      if call == 0, do: @before, else: @deadline
    end

    assert {:error, %{reason_code: :client_app_expired}} =
             initiate_ciba(client, clock)

    assert scalar("SELECT COUNT(*) FROM lockspire_ciba_authorizations WHERE client_id = $1", [
             client.client_id
           ]) == 0

    assert scalar("SELECT COUNT(*) FROM lockspire_tokens WHERE client_id = $1", [client.client_id]) ==
             0
  end

  test "queued CIBA request cannot approve at app expiry and does not write approval audit", %{
    client: client
  } do
    request = ciba_request(client, @before)
    assert {:ok, _} = Repository.put_ciba_authorization(request)

    assert {:error, :expired} =
             Ciba.approve_authorization_with_opts(
               request.auth_req_id_hash,
               "user-123",
               ["openid"],
               now: fn -> @deadline end
             )

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(request.auth_req_id_hash)

    assert stored.status == :pending
    assert audit_count("ciba_authorization_approved") == 0

    assert scalar("SELECT COUNT(*) FROM lockspire_tokens WHERE client_id = $1", [client.client_id]) ==
             0
  end

  test "queued CIBA request cannot approve after the client is disabled", %{client: client} do
    request = ciba_request(client, @before)
    assert {:ok, _} = Repository.put_ciba_authorization(request)
    assert {:ok, _} = Repository.set_client_active(client, false, %{disabled_at: @before})

    assert {:error, :not_active} =
             Ciba.approve_authorization_with_opts(
               request.auth_req_id_hash,
               "user-123",
               ["openid"],
               now: fn -> @before end
             )

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(request.auth_req_id_hash)

    assert stored.status == :pending
    assert audit_count("ciba_authorization_approved") == 0
  end

  test "eligible CIBA approval records status and audit in one transaction", %{client: client} do
    request = ciba_request(client, @before)
    assert {:ok, _} = Repository.put_ciba_authorization(request)

    assert {:ok, approved} =
             Ciba.approve_authorization_with_opts(
               request.auth_req_id_hash,
               "user-123",
               ["openid"],
               now: fn -> @before end
             )

    assert approved.status == :approved
    assert audit_count("ciba_authorization_approved") == 1
  end

  defp initiate_ciba(client, clock) do
    BackchannelAuthentication.authorize(%{
      params: %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.test"
      },
      opts: [
        client_store: Repository,
        ciba_authorization_store: Repository,
        account_resolver: AccountResolver,
        now: clock
      ]
    })
  end

  defp ciba_request(client, now) do
    CibaAuthorization.issue(
      %{
        client_id: client.client_id,
        auth_req_id: "ciba-#{System.unique_integer([:positive])}",
        scopes: ["openid"],
        subject_id: "user-123"
      },
      now: now
    )
  end

  defp audit_count(action) do
    scalar("SELECT COUNT(*) FROM lockspire_audit_events WHERE action = $1", [action])
  end

  defp scalar(sql, params) do
    %{rows: [[count]]} = Ecto.Adapters.SQL.query!(Lockspire.TestRepo, sql, params)
    count
  end
end
