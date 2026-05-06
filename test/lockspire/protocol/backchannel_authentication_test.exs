defmodule Lockspire.Protocol.BackchannelAuthenticationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Protocol.BackchannelAuthentication.Success
  alias Lockspire.Protocol.BackchannelAuthentication.Error

  defmodule MockAccountResolver do
    @behaviour Lockspire.Host.AccountResolver
    def resolve_current_account(_conn, _ctx), do: {:error, :not_implemented}
    def resolve_account("valid-user", _ctx), do: {:ok, "user-123"}
    def resolve_account("not-found", _ctx), do: {:error, :not_found}
    def build_claims(_account, _ctx), do: {:error, :not_implemented}
    def redirect_for_login(_conn, _ctx), do: %{}
  end

  defmodule MockCibaStore do
    @behaviour Lockspire.Storage.CibaAuthorizationStore
    def put_ciba_authorization(auth), do: {:ok, auth}
    def fetch_ciba_authorization_by_auth_req_id_hash(_), do: {:error, :not_implemented}
    def transition_ciba_authorization(_, _, _), do: {:error, :not_implemented}
    def record_ciba_poll(_, _, _), do: {:error, :not_implemented}
  end

  defmodule MockClientStore do
    @behaviour Lockspire.Storage.ClientStore
    def register_client(_), do: {:error, :not_implemented}
    def list_clients(_), do: {:error, :not_implemented}
    def fetch_client_by_id("client-1"), do: {:ok, %Client{client_id: "client-1", token_endpoint_auth_method: :none}}
    def update_client(_, _), do: {:error, :not_implemented}
    def rotate_client_secret(_, _, _), do: {:error, :not_implemented}
    def set_client_active(_, _, _), do: {:error, :not_implemented}
  end

  @opts [
    account_resolver: MockAccountResolver,
    ciba_authorization_store: MockCibaStore,
    client_store: MockClientStore
  ]

  describe "authorize/1" do
    test "returns success for valid request with login_hint" do
      request = %{
        params: %{
          "client_id" => "client-1",
          "scope" => "openid profile",
          "login_hint" => "valid-user",
          "binding_message" => "Confirm login"
        },
        opts: @opts
      }

      assert {:ok, %Success{} = success} = BackchannelAuthentication.authorize(request)
      assert is_binary(success.auth_req_id)
      assert success.expires_in == 600
      assert success.interval == 5
    end

    test "rejects request missing openid scope" do
      request = %{
        params: %{
          "client_id" => "client-1",
          "scope" => "profile",
          "login_hint" => "valid-user"
        },
        opts: @opts
      }

      assert {:error, %Error{error: "invalid_scope"}} = BackchannelAuthentication.authorize(request)
    end

    test "rejects request with multiple hints" do
      request = %{
        params: %{
          "client_id" => "client-1",
          "scope" => "openid",
          "login_hint" => "valid-user",
          "id_token_hint" => "some-token"
        },
        opts: @opts
      }

      assert {:error, %Error{error: "invalid_request", reason_code: :too_many_hints}} =
               BackchannelAuthentication.authorize(request)
    end

    test "rejects request with no hints" do
      request = %{
        params: %{
          "client_id" => "client-1",
          "scope" => "openid"
        },
        opts: @opts
      }

      assert {:error, %Error{error: "invalid_request", reason_code: :missing_hint}} =
               BackchannelAuthentication.authorize(request)
    end

    test "rejects request if user cannot be resolved" do
      request = %{
        params: %{
          "client_id" => "client-1",
          "scope" => "openid",
          "login_hint" => "not-found"
        },
        opts: @opts
      }

      assert {:error, %Error{error: "unknown_user"}} = BackchannelAuthentication.authorize(request)
    end
  end
end
