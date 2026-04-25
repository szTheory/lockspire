defmodule Lockspire.Protocol.ParPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.ParPolicy

  test "resolve_effective_policy follows the optional global default" do
    resolved =
      ParPolicy.resolve_effective_policy(%ServerPolicy{par_policy: :optional}, %Client{})

    assert resolved.global_policy == :optional
    assert resolved.client_policy == :inherit
    assert resolved.effective_policy == :optional
    assert resolved.par_required? == false
  end

  test "resolve_effective_policy follows the required global default" do
    resolved =
      ParPolicy.resolve_effective_policy(%ServerPolicy{par_policy: :required}, %Client{})

    assert resolved.global_policy == :required
    assert resolved.client_policy == :inherit
    assert resolved.effective_policy == :required
    assert resolved.par_required? == true
  end

  test "resolve_effective_policy keeps inherit aligned with an optional global policy" do
    resolved =
      ParPolicy.resolve_effective_policy(
        %ServerPolicy{par_policy: :optional},
        %Client{par_policy: :inherit}
      )

    assert resolved.client_policy == :inherit
    assert resolved.effective_policy == :optional
    assert resolved.par_required? == false
  end

  test "resolve_effective_policy keeps inherit aligned with a required global policy" do
    resolved =
      ParPolicy.resolve_effective_policy(
        %ServerPolicy{par_policy: :required},
        %Client{par_policy: :inherit}
      )

    assert resolved.client_policy == :inherit
    assert resolved.effective_policy == :required
    assert resolved.par_required? == true
  end

  test "resolve_effective_policy lets a required client override an optional global policy" do
    resolved =
      ParPolicy.resolve_effective_policy(
        %ServerPolicy{par_policy: :optional},
        %Client{par_policy: :required}
      )

    assert resolved.client_policy == :required
    assert resolved.effective_policy == :required
    assert resolved.par_required? == true
  end

  test "resolve_effective_policy lets an optional client override a required global policy" do
    resolved =
      ParPolicy.resolve_effective_policy(
        %ServerPolicy{par_policy: :required},
        %Client{par_policy: :optional}
      )

    assert resolved.client_policy == :optional
    assert resolved.effective_policy == :optional
    assert resolved.par_required? == false
  end
end
