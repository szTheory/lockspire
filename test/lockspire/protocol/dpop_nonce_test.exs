defmodule Lockspire.Protocol.DPoPNonceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.DPoPNonce

  @secret_key_base String.duplicate("n", 64)

  test "issues a non-empty nonce and validates it for the matching authorization-server purpose" do
    nonce = DPoPNonce.issue(:authorization_server, secret_key_base: @secret_key_base)

    assert is_binary(nonce)
    refute nonce == ""

    assert :ok =
             DPoPNonce.validate(
               %{"nonce" => nonce},
               :authorization_server,
               secret_key_base: @secret_key_base
             )
  end

  test "rejects cross-surface nonce reuse for authorization-server and resource-server purposes" do
    authorization_server_nonce =
      DPoPNonce.issue(:authorization_server, secret_key_base: @secret_key_base)

    resource_server_nonce = DPoPNonce.issue(:resource_server, secret_key_base: @secret_key_base)

    assert {:error, :invalid_dpop_nonce} =
             DPoPNonce.validate(
               %{"nonce" => authorization_server_nonce},
               :resource_server,
               secret_key_base: @secret_key_base
             )

    assert {:error, :invalid_dpop_nonce} =
             DPoPNonce.validate(
               %{"nonce" => resource_server_nonce},
               :authorization_server,
               secret_key_base: @secret_key_base
             )
  end

  test "returns missing_dpop_nonce when the claim is absent" do
    assert {:error, :missing_dpop_nonce} =
             DPoPNonce.validate(%{}, :authorization_server, secret_key_base: @secret_key_base)
  end

  test "returns invalid_dpop_nonce for malformed nonce values" do
    assert {:error, :invalid_dpop_nonce} =
             DPoPNonce.validate(
               %{"nonce" => "not-a-valid-signed-nonce"},
               :authorization_server,
               secret_key_base: @secret_key_base
             )
  end

  test "returns invalid_dpop_nonce for expired nonce values" do
    nonce = DPoPNonce.issue(:resource_server, secret_key_base: @secret_key_base)

    assert {:error, :invalid_dpop_nonce} =
             DPoPNonce.validate(
               %{"nonce" => nonce},
               :resource_server,
               secret_key_base: @secret_key_base,
               nonce_max_age: 0
             )
  end
end
