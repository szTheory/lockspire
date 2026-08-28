defmodule Lockspire.Release.ReleaseAutomationContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.ReleaseProof.WorkflowAssertions

  test "release workflow preserves the protected publish boundary" do
    WorkflowAssertions.assert_protected_publish_lane!()
  end

  test "release metadata and maintainer guidance agree on the current release" do
    WorkflowAssertions.assert_current_release_truth!()
  end

  test "release automation keeps contributor and publish evidence separate" do
    WorkflowAssertions.assert_evidence_boundaries!()
  end
end
