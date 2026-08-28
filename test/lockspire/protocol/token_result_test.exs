defmodule Lockspire.Protocol.TokenResultTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenResult

  test "compatibility converts every neutral success field into the retained public struct" do
    neutral = %TokenResult.Success{
      access_token: "access-token",
      refresh_token: "refresh-token",
      id_token: "id-token",
      token_type: "DPoP",
      issued_token_type: "urn:ietf:params:oauth:token-type:access_token",
      expires_in: 300,
      scope: "openid profile"
    }

    assert %TokenExchange.Success{} = public = Compatibility.to_public(neutral)
    assert Map.from_struct(public) == Map.from_struct(neutral)
  end

  test "compatibility preserves OAuth and DPoP error fields without carrying sensitive inputs" do
    neutral = %TokenResult.Error{
      status: 400,
      error: "use_dpop_nonce",
      error_description: "A DPoP nonce is required",
      reason_code: :missing_dpop_nonce,
      dpop_nonce: "nonce-value"
    }

    assert %TokenExchange.Error{} = public = Compatibility.to_public(neutral)
    assert Map.from_struct(public) == Map.from_struct(neutral)
    refute inspect(neutral) =~ "access-token"
    refute inspect(neutral) =~ "private-jwk"
  end
end
