defmodule Lockspire.Protocol.PrivateJwkTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.PrivateJwk

  test "decodes JSON object and safe encoded map keys" do
    assert {:ok, %{"kty" => "RSA"}} = PrivateJwk.decode(~s({"kty":"RSA"}))
    assert {:ok, %{kty: :RSA}} = PrivateJwk.decode(:erlang.term_to_binary(%{kty: :RSA}))
  end

  test "fails closed for invalid material and never raises" do
    for value <- ["not-json", "[]", "null", <<131, 104>>, :not_binary, %{}, nil, 42] do
      assert {:error, :invalid_signing_key} = PrivateJwk.decode(value)
    end
  end
end
