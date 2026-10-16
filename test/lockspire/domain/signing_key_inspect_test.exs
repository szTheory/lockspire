defmodule Lockspire.Domain.SigningKeyInspectTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  test "inspect of %SigningKey{} omits the private column" do
    out = inspect(%SigningKey{kid: "k", private_jwk_encrypted: "SENTINEL-PRIVATE"})
    assert out =~ "k"
    refute out =~ "SENTINEL-PRIVATE"
    refute out =~ "private_jwk_encrypted"
  end

  test "inspect of %SigningKeyRecord{} omits the private column" do
    out = inspect(%SigningKeyRecord{kid: "k", private_jwk_encrypted: "SENTINEL-PRIVATE"})
    assert out =~ "k"
    refute out =~ "SENTINEL-PRIVATE"
    refute out =~ "private_jwk_encrypted"
  end
end
