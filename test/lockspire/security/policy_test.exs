defmodule Lockspire.Security.PolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.Policy

  @secret_key_base String.duplicate("p", 64)

  test "client-secret JWT verifier sealing accepts explicit key material" do
    encrypted = Policy.seal_client_secret_jwt_verifier("verifier-secret", @secret_key_base)

    assert {:ok, "verifier-secret"} =
             Policy.unseal_client_secret_jwt_verifier(encrypted, @secret_key_base)
  end
end
