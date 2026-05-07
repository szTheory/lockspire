defmodule Lockspire.Domain.ClientTest do
  use ExUnit.Case, async: true
  alias Lockspire.Domain.Client

  test "Client struct supports authorization_signed_response_alg" do
    client = %Client{authorization_signed_response_alg: :RS256}
    assert client.authorization_signed_response_alg == :RS256
  end
end
