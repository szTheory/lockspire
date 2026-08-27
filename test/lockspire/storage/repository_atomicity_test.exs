defmodule Lockspire.Storage.RepositoryAtomicityTest do
  use Lockspire.DataCase, async: false

  alias Lockspire.RepositoryAtomicityCharacterization

  @moduletag :integration

  test "critical repository transitions retain their transaction and lock contracts" do
    RepositoryAtomicityCharacterization.assert_critical_boundaries()
  end
end
