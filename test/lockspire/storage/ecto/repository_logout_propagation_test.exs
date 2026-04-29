defmodule Lockspire.Storage.Ecto.RepositoryLogoutPropagationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  describe "persist_logout_propagation/1" do
    @tag :skip
    test "stores one logout event with backchannel and frontchannel delivery rows transactionally" do
      # Plan 39 repository work must persist event truth and delivery snapshots
      # together before any network side effects begin.
      _contract = Repository
      flunk("not yet implemented")
    end

    @tag :skip
    test "snapshots client logout URIs and session-required flags from token-linked clients before sid revocation" do
      # Historical delivery truth must survive later client edits and token
      # revocation.
      _contract = Repository
      flunk("not yet implemented")
    end

    @tag :skip
    test "returns unique durable delivery identities suitable for one-job-per-delivery enqueueing" do
      # Back-channel workers need stable delivery identifiers so Oban uniqueness
      # can prevent duplicate fan-out.
      _contract = Repository
      flunk("not yet implemented")
    end

    @tag :skip
    test "persists only redacted delivery metadata and never the raw logout_token artifact" do
      # The database contract must preserve operator clarity without storing the
      # sensitive signed logout token itself.
      _contract = Repository
      flunk("not yet implemented")
    end
  end
end
