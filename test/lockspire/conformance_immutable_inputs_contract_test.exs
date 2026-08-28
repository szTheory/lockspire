defmodule Lockspire.ConformanceImmutableInputsContractTest do
  use ExUnit.Case, async: true

  @lock Path.expand("../../scripts/conformance/oidf-suite-lock.json", __DIR__)
  @validator Path.expand("../../scripts/conformance/oidf_inputs.py", __DIR__)
  @prepare Path.expand("../../scripts/conformance/prepare_oidf_suite.sh", __DIR__)

  test "immutable OIDF lock has the exact suite identity, checksums, and image digests" do
    lock = File.read!(@lock)

    assert lock =~ "release-v5.1.43"
    assert lock =~ "16ad152b1b2c0baacd3d2519128340d95deb2b8c"
    assert lock =~ "c11be330b5a731bf3bca312f7b44d6bfe3981b448d5f58ec3dc2e48f3f509c8e"
    assert lock =~ "sha256:f6b1bb02bc746dd216506f773bc19997b113072fd22dec515f7e3357e218d950"
    assert lock =~ "sha256:6a13e1c9ae2d19f2d0fea0a371905d580d61b960e0da84c01d5006729a5f1426"
    assert lock =~ "sha256:b415b12f638e2685d06c58ab7fb5943577c50fadec6d9340ef67d21aeac72070"
  end

  test "validator rejects mutable or malformed lock identities without printing input values" do
    validator = File.read!(@validator)

    assert validator =~ "duplicate key"
    assert validator =~ "mutable reference"
    assert validator =~ "sha256"
    assert validator =~ "release-v5.1.43"
    refute validator =~ "subprocess"
  end

  test "preparation validates before download and writes only digest-qualified compose images" do
    prepare = File.read!(@prepare)

    assert prepare =~ "--validate-only"
    assert prepare =~ "--verify-downloads"
    assert prepare =~ "--normalize-compose"
    assert prepare =~ "umask 077"
    refute prepare =~ "master"
    refute prepare =~ "latest"
    refute prepare =~ "fallback"
  end

  test "normalized suite can reach the throwaway host through Docker's explicit host gateway" do
    validator = File.read!(@validator)

    assert validator =~ "host.docker.internal:host-gateway"
    assert validator =~ "extra_hosts"
  end
end
