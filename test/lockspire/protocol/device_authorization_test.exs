defmodule Lockspire.Protocol.DeviceAuthorizationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization, as: DeviceAuthorizationState
  alias Lockspire.Protocol.DeviceAuthorization

  defmodule FakeClientStore do
    def fetch_client_by_id("valid_client"), do: {:ok, %Client{client_id: "valid_client", token_endpoint_auth_method: :none}}
    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule FakeDeviceStore do
    def put_device_authorization(%DeviceAuthorizationState{} = device_auth) do
      {:ok, device_auth}
    end
  end

  describe "authorize/1" do
    test "authenticates client, persists device authorization, and returns success" do
      request = %{
        params: %{"client_id" => "valid_client"},
        authorization: nil,
        opts: [
          client_store: FakeClientStore,
          device_authorization_store: FakeDeviceStore,
          verification_uri: "https://example.com/device"
        ]
      }

      assert {:ok, %DeviceAuthorization.Success{} = success} = DeviceAuthorization.authorize(request)

      assert is_binary(success.device_code)
      assert is_binary(success.user_code)
      assert String.length(success.user_code) == 8
      assert success.verification_uri == "https://example.com/device"
      assert success.verification_uri_complete ==
               "https://example.com/device?user_code=#{success.user_code}"
      assert success.expires_in == 300
    end

    test "returns error on invalid client authentication" do
      request = %{
        params: %{"client_id" => "invalid_client"},
        authorization: nil,
        opts: [
          client_store: FakeClientStore,
          device_authorization_store: FakeDeviceStore
        ]
      }

      assert {:error, %DeviceAuthorization.Error{} = error} = DeviceAuthorization.authorize(request)
      assert error.status == 401
      assert error.error == "invalid_client"
    end
  end
end
