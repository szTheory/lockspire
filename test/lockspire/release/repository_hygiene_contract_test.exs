defmodule Lockspire.Release.RepositoryHygieneContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.ReleaseProof.PackageAssertions

  test "package inputs are explicit and exclude repository-local artifacts" do
    PackageAssertions.assert_hex_package_inputs!()
  end

  test "repository hygiene stays deterministic and outside the public product surface" do
    PackageAssertions.assert_repository_hygiene!()
  end
end
