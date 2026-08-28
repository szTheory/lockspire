defmodule Lockspire.Release.SupportSurfaceContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.ReleaseProof.DocumentationAssertions

  test "adopter documentation keeps Lockspire embedded and host-owned" do
    DocumentationAssertions.assert_embedded_host_boundaries!()
  end

  test "security documentation keeps protocol guarantees and scope limits explicit" do
    DocumentationAssertions.assert_security_boundaries!()
  end

  test "protected-resource guidance preserves the supported Phoenix pipeline" do
    DocumentationAssertions.assert_protected_resource_guidance!()
  end
end
