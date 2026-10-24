defmodule Lockspire.Protocol.DeviceAuthorizationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization, as: DeviceAuthorizationState
  alias Lockspire.Protocol.DeviceAuthorization
  alias Lockspire.TestSupport.TelemetryCapture

  defmodule FakeClientStore do
    def lifetime_contract do
      %{
        version: 1,
        transaction_authority:
          Lockspire.Protocol.DeviceAuthorizationTest.FakeTransactionStore.transaction_authority()
      }
    end

    def lock_clients([client_id]) do
      case fetch_client_by_id(client_id) do
        {:ok, %Client{} = client} -> {:ok, [client]}
        {:ok, nil} -> {:ok, []}
      end
    end

    def fetch_client_by_id("valid_client"),
      do:
        {:ok,
         %Client{
           client_id: "valid_client",
           token_endpoint_auth_method: :none,
           lifetime_version: 0
         }}

    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule FakeDeviceStore do
    def put_device_authorization(%DeviceAuthorizationState{} = device_auth) do
      {:ok, device_auth}
    end
  end

  defmodule FakeTransactionStore do
    def transaction_authority do
      %{
        identity: :device_test,
        participants: %{
          client_store: Lockspire.Protocol.DeviceAuthorizationTest.FakeClientStore,
          device_authorization_store: Lockspire.Protocol.DeviceAuthorizationTest.FakeDeviceStore,
          transaction_store: __MODULE__
        }
      }
    end

    def transact(fun), do: normalize(fun.())
    defp normalize({:ok, value}), do: {:ok, value}
    defp normalize({:error, reason}), do: {:error, reason}
  end

  describe "authorize/1" do
    test "authenticates client, persists device authorization, and returns success" do
      TelemetryCapture.attach(
        [:lockspire, :device_authorization, :created],
        self()
      )

      request = %{
        params: %{"client_id" => "valid_client"},
        authorization: nil,
        opts: [
          client_store: FakeClientStore,
          device_authorization_store: FakeDeviceStore,
          transaction_store: FakeTransactionStore,
          verification_uri: "https://example.com/device"
        ]
      }

      assert {:ok, %DeviceAuthorization.Success{} = success} =
               DeviceAuthorization.authorize(request)

      assert_received {:telemetry_event, [:lockspire, :device_authorization, :created],
                       _measurements, metadata}

      assert metadata.client_id == "valid_client"
      assert Map.has_key?(metadata, :verification_handle)

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
          device_authorization_store: FakeDeviceStore,
          transaction_store: FakeTransactionStore
        ]
      }

      assert {:error, %DeviceAuthorization.Error{} = error} =
               DeviceAuthorization.authorize(request)

      assert error.status == 401
      assert error.error == "invalid_client"
    end
  end
end
