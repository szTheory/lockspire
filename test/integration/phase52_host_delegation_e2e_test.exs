defmodule Lockspire.Integration.Phase52HostDelegationE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  defmodule MockNotifier do
    @behaviour Lockspire.Host.BackchannelNotification
    def notify_authentication(auth, _context) do
      send(self(), {:notified, auth.auth_req_id_hash})
      :ok
    end
  end

  defmodule MockAccountResolver do
    @behaviour Lockspire.Host.AccountResolver

    def resolve_current_account(_conn, _ctx), do: {:error, :not_implemented}
    def resolve_account(hint, _ctx), do: {:ok, hint}
    def build_claims(acc, _ctx), do: {:ok, %Lockspire.Host.Claims{subject: to_string(acc)}}
    def redirect_for_login(_conn, _ctx), do: %{}

    def verify_backchannel_user_code(_subject, "1234", _ctx), do: :ok
    def verify_backchannel_user_code(_subject, _other, _ctx), do: {:error, :invalid_user_code}
  end

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :account_resolver, MockAccountResolver)
    Application.put_env(:lockspire, :backchannel_notification, MockNotifier)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    # Ensure an active signing key exists
    case Lockspire.Admin.Keys.list_keys() do
      {:ok, []} ->
        {:ok, %{key: %{id: id}}} = Lockspire.Admin.Keys.generate_key()
        {:ok, _} = Lockspire.Admin.Keys.publish_key(id)
        {:ok, _} = Lockspire.Admin.Keys.activate_key(id)

      {:ok, views} ->
        unless Enum.any?(views, &(&1.key.status == :active)) do
          id = List.first(views).key.id
          {:ok, _} = Lockspire.Admin.Keys.publish_key(id)
          {:ok, _} = Lockspire.Admin.Keys.activate_key(id)
        end

        :ok
    end

    {:ok, client_normal} =
      Repository.register_client(%Client{
        client_id: "ciba-client-normal",
        name: "CIBA Normal",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        created_at: DateTime.utc_now()
      })

    {:ok, client_user_code} =
      Repository.register_client(%Client{
        client_id: "ciba-client-user-code",
        name: "CIBA User Code Required",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        backchannel_user_code_parameter: true,
        created_at: DateTime.utc_now()
      })

    %{client_normal: client_normal, client_user_code: client_user_code}
  end

  test "user_code enforcement: missing_user_code", %{client_user_code: client} do
    conn =
      build_conn()
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.com"
      })

    assert conn.status == 400
    assert %{"error" => "missing_user_code"} = Jason.decode!(conn.resp_body)
  end

  test "user_code enforcement: invalid_user_code", %{client_user_code: client} do
    conn =
      build_conn()
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.com",
        "user_code" => "wrong"
      })

    assert conn.status == 400
    assert %{"error" => "invalid_user_code"} = Jason.decode!(conn.resp_body)
  end

  test "successful initiation triggers notification", %{client_normal: client} do
    conn =
      build_conn()
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.com"
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id} = Jason.decode!(conn.resp_body)
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    assert_received {:notified, ^auth_req_id_hash}
  end

  test "async approval flow", %{client_normal: client} do
    # 1. Initiate
    conn =
      build_conn()
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.com"
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id} = Jason.decode!(conn.resp_body)
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    # 2. Approve via Public API
    {:ok, _} =
      Lockspire.Ciba.approve_authorization(auth_req_id_hash, "user-123", ["openid", "profile"])

    # 3. Poll for token
    conn =
      build_conn()
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert is_binary(body["access_token"])

    # Verify ID Token subject
    claims = JOSE.JWT.peek_payload(body["id_token"]).fields
    assert claims["sub"] == "user-123"
  end

  test "async denial flow", %{client_normal: client} do
    # 1. Initiate
    conn =
      build_conn()
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid",
        "login_hint" => "user@example.com"
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id} = Jason.decode!(conn.resp_body)
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    # 2. Deny via Public API
    {:ok, _} = Lockspire.Ciba.deny_authorization(auth_req_id_hash)

    # 3. Poll for token
    conn =
      build_conn()
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 400
    assert %{"error" => "access_denied"} = Jason.decode!(conn.resp_body)
  end
end
