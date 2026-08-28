defmodule Lockspire.Storage.PrefixTest do
  use ExUnit.Case, async: true

  alias Lockspire.Storage.Prefix

  test "normalizes only its explicit input and derives prefix options" do
    assert Prefix.normalize(nil) == nil
    assert Prefix.normalize(false) == nil
    assert Prefix.normalize(:public) == "public"
    assert Prefix.normalize("  lockspire_jobs  ") == "lockspire_jobs"
    assert Prefix.prefix_opts("lockspire") == [prefix: "lockspire"]
    assert Prefix.oban_opts(nil) == []

    assert_raise ArgumentError, ~r/invalid :storage_prefix/, fn ->
      Prefix.normalize("invalid-prefix")
    end
  end
end
