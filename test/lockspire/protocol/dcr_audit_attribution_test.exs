defmodule Lockspire.Protocol.DcrAuditAttributionTest do
  use ExUnit.Case, async: false

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  @tag :pending
  @tag :skip
  test "Phase 26-02 stub — replaced in Wave 3 plan 26-07" do
    # Wave 3 plan 26-07 fills this in (DCR-22 regression).
  end
end
