defmodule Lockspire.Storage.Ecto.RepositoryLogoutPropagationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Storage.LogoutStore
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

  describe "logout domain/storage contracts" do
    test "logout events expose explicit durable protocol fields" do
      event = %LogoutEvent{
        event_id: "evt_123",
        sid: "sid_123",
        account_id: "account_123",
        subject: "subject_123",
        initiated_by: :rp_initiated_logout,
        post_logout_redirect_uri: "https://rp.example.com/logout-complete",
        frontchannel_continue_to: "/logout/continue"
      }

      assert event.event_id == "evt_123"
      assert event.initiated_by == :rp_initiated_logout
      assert event.frontchannel_continue_to == "/logout/continue"
    end

    test "logout deliveries model explicit channel and lifecycle state" do
      delivery = %LogoutDelivery{
        delivery_id: "ld_123",
        client_id: "client_123",
        channel: :backchannel,
        target_uri: "https://rp.example.com/backchannel-logout",
        session_required: true
      }

      assert delivery.status == :pending
      assert delivery.attempt_count == 0
      assert delivery.channel == :backchannel
      assert delivery.target_uri == "https://rp.example.com/backchannel-logout"
    end

    test "logout store behaviour exposes durable persistence contract" do
      callbacks = LogoutStore.behaviour_info(:callbacks)

      assert {:persist_logout_propagation, 1} in callbacks
    end
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
