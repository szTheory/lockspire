defmodule Lockspire.Protocol.TokenFormatterTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenFormatter

  test "formats opaque bearer access tokens with durable hashes" do
    formatted =
      TokenFormatter.format_access_token(
        token_generator: fn -> "opaque-access-token-value" end
      )

    assert formatted.token == "opaque-access-token-value"
    assert formatted.token_type == "Bearer"
    assert formatted.token_hash == TokenFormatter.hash_token("opaque-access-token-value")
    refute formatted.token_hash == formatted.token
  end

  test "generated tokens are url-safe opaque strings" do
    formatted = TokenFormatter.format_access_token()

    assert String.match?(formatted.token, ~r/^[A-Za-z0-9_-]+$/)
    assert byte_size(formatted.token) >= 43
    assert String.match?(formatted.token_hash, ~r/^[0-9a-f]{64}$/)
  end
end
