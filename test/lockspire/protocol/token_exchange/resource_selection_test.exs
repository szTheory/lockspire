defmodule Lockspire.Protocol.TokenExchange.ResourceSelectionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.ResourceSelection

  test "keeps the grant audience when no resource is requested" do
    grant = %Token{audience: ["https://api.example.test"]}

    assert {:ok, ["https://api.example.test"]} = ResourceSelection.select(%{}, grant)
  end

  test "rejects a resource outside the recorded grant audience" do
    grant = %Token{audience: ["https://api.example.test"]}

    assert {:error, error} = ResourceSelection.select(%{"resource" => "https://other.example.test"}, grant)
    assert error.error == "invalid_target"
    assert error.reason_code == :invalid_resource
  end
end
