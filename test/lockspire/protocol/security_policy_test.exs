defmodule Lockspire.Protocol.SecurityPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.Policy

  test "boot-time helpers validate required values and issuer alignment" do
    assert_raise ArgumentError,
                 "missing required config :repo for :lockspire. Set it in config/runtime.exs or config/*.exs.",
                 fn ->
                   Policy.fetch_required_config!(:repo, nil)
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Expected an absolute URL with scheme and host.",
                 fn ->
                   Policy.validate_issuer_and_mount_path!("oauth", "/oauth")
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Query parameters are not allowed.",
                 fn ->
                   Policy.validate_issuer_and_mount_path!(
                     "https://example.test/oauth?foo=bar",
                     "/oauth"
                   )
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Issuer path \"/other\" must match mount_path \"/oauth\".",
                 fn ->
                   Policy.validate_issuer_and_mount_path!("https://example.test/other", "/oauth")
                 end

    assert Policy.validate_issuer_and_mount_path!("https://example.test/oauth", "/oauth") ==
             "https://example.test/oauth"
  end

  test "reject helpers return stable reason atoms for unsupported runtime posture" do
    assert {:error, :unsupported_response_type} =
             Policy.ensure_supported_response_type("token")

    assert :ok = Policy.ensure_supported_response_type("code")

    assert {:error, :unsupported_token_endpoint_auth_method} =
             Policy.ensure_supported_token_endpoint_auth_method(:private_key_jwt)

    assert :ok = Policy.ensure_supported_token_endpoint_auth_method(:client_secret_basic)

    assert {:error, :invalid_signing_alg} = Policy.ensure_signing_alg("none")
    assert {:error, :invalid_signing_alg} = Policy.ensure_signing_alg(:ES256)
    assert :ok = Policy.ensure_signing_alg("RS256")
    assert :ok = Policy.ensure_signing_alg(:RS256)
  end
end
