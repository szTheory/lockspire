defmodule Lockspire.Domain.DeviceAuthorizationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Security.Policy

  describe "issue/2" do
    test "creates a valid struct containing plaintext codes, hashed codes, and an expiration timestamp" do
      now = DateTime.utc_now()
      
      attrs = %{
        device_code: "foo-device-code",
        user_code: "ABCD-WXYZ",
        client_id: "test_client",
        scopes: ["openid", "profile"]
      }

      device_auth = DeviceAuthorization.issue(attrs, now: now)

      assert %DeviceAuthorization{} = device_auth
      assert device_auth.device_code == "foo-device-code"
      assert device_auth.user_code == "ABCD-WXYZ"
      assert device_auth.device_code_hash == Policy.hash_token("foo-device-code")
      assert device_auth.user_code_hash == DeviceAuthorization.hash_user_code("ABCD-WXYZ")
      assert device_auth.client_id == "test_client"
      assert device_auth.scopes == ["openid", "profile"]
      assert device_auth.effective_poll_interval_seconds == 5
      assert DateTime.diff(device_auth.next_poll_allowed_at, now, :second) == 5
      assert DateTime.diff(device_auth.expires_at, now, :second) == 300
    end
  end
end
