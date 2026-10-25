defmodule Lockspire.ConfigClientSecretVerifierTest do
  use ExUnit.Case, async: false

  alias Lockspire.Config

  @tag :snapshot_api
  test "the application exposes a dedicated verifier snapshot API" do
    assert function_exported?(Config, :client_secret_verifier_cache_key, 0),
           "verifier snapshot API must exist"
  end
end
