defmodule Lockspire.Protocol.InitialAccessTokenTest do
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
  test "Phase 26-02 stub — replaced in Wave 1 plan 26-03" do
    # Wave 1 plan 26-03 fills this in (DCR-11 atomic redemption + concurrent).
  end
end