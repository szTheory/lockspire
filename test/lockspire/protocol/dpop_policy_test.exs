defmodule Lockspire.Protocol.DpopPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DpopPolicy

  test "bearer-default plus inherit resolves to bearer" do
    assert {:ok, resolved} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :bearer},
               %Client{dpop_policy: :inherit}
             )

    assert resolved.global_policy == :bearer
    assert resolved.client_policy == :inherit
    assert resolved.effective_policy == :bearer
    refute resolved.dpop_required?
  end

  test "dpop-default plus inherit resolves to dpop" do
    assert {:ok, resolved} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :dpop},
               %Client{dpop_policy: :inherit}
             )

    assert resolved.effective_policy == :dpop
    assert resolved.dpop_required?
  end

  test "explicit client override wins over the server default" do
    assert {:ok, resolved_bearer} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :dpop},
               %Client{dpop_policy: :bearer}
             )

    assert resolved_bearer.effective_policy == :bearer
    refute resolved_bearer.dpop_required?

    assert {:ok, resolved_dpop} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :bearer},
               %Client{dpop_policy: :dpop}
             )

    assert resolved_dpop.effective_policy == :dpop
    assert resolved_dpop.dpop_required?
  end

  test "malformed values return explicit errors instead of coercing to bearer" do
    assert {:error, :invalid_server_policy} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :inherit},
               %Client{dpop_policy: :inherit}
             )

    assert {:error, :invalid_client_policy} =
             DpopPolicy.resolve_effective_policy(
               %ServerPolicy{dpop_policy: :bearer},
               %{dpop_policy: "strict"}
             )
  end
end
