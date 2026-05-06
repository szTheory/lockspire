defmodule Lockspire.RAR.FingerprintTest do
  use ExUnit.Case, async: true

  test "compute/1 returns nil for empty details" do
    assert Lockspire.RAR.Fingerprint.compute([]) == nil
  end

  test "compute/1 returns a sha256-sized binary for non-empty details" do
    fingerprint = Lockspire.RAR.Fingerprint.compute([%{"type" => "payment_initiation"}])

    assert is_binary(fingerprint)
    assert byte_size(fingerprint) == 32
  end
end
