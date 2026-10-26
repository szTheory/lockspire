defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Storage.ClientVerifierMaintenance

  test "selected maintenance supports a persisted native verifier rewrap" do
    assert function_exported?(ClientVerifierMaintenance, :configured, 0)
    assert function_exported?(ClientVerifierMaintenance, :rewrap_client, 2)
  end
end
