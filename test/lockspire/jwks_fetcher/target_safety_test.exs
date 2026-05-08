defmodule Lockspire.JwksFetcher.TargetSafetyTest do
  use ExUnit.Case, async: true

  alias Lockspire.JwksFetcher.TargetSafety

  test "accepts publicly routable ipv4 destinations" do
    resolver = fn "issuer.example" -> {:ok, [{93, 184, 216, 34}]} end

    assert :ok = TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end

  test "rejects loopback destinations" do
    resolver = fn "issuer.example" -> {:ok, [{127, 0, 0, 1}]} end

    assert {:error, {:unsafe_target, :loopback}} =
             TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end

  test "rejects private-network destinations" do
    resolver = fn "issuer.example" -> {:ok, [{10, 0, 1, 25}]} end

    assert {:error, {:unsafe_target, :private_network}} =
             TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end

  test "rejects link-local ipv6 destinations" do
    resolver = fn "issuer.example" -> {:ok, [{0xFE80, 0, 0, 0, 0, 0, 0, 1}]} end

    assert {:error, {:unsafe_target, :link_local}} =
             TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end

  test "rejects mixed resolution results when any address is unsafe" do
    resolver = fn "issuer.example" ->
      {:ok, [{93, 184, 216, 34}, {192, 168, 1, 10}]}
    end

    assert {:error, {:unsafe_target, :private_network}} =
             TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end

  test "fails closed when resolution does not return usable addresses" do
    resolver = fn "issuer.example" -> {:ok, []} end

    assert {:error, :resolution_failed} =
             TargetSafety.ensure_safe_host("issuer.example", resolver: resolver)
  end
end
