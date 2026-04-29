defmodule Lockspire.Protocol.LogoutPropagationTest do
  use ExUnit.Case, async: false

  alias Lockspire.Protocol.LogoutPropagation

  describe "snapshot_targets_before_revocation/2" do
    @tag :skip
    test "selects relying parties from durable sid-linked token history before revoke_by_sid/1 runs" do
      # Plan 39 Wave 1 will implement Lockspire.Protocol.LogoutPropagation and
      # assert that target resolution snapshots client metadata before revocation
      # mutates the active token rows.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end

    @tag :skip
    test "keeps frontchannel and backchannel target metadata as separate delivery rows in the snapshot" do
      # This contract pins the need for distinct delivery records even when one
      # relying party opts into both logout propagation channels.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end
  end

  describe "complete_logout/1" do
    @tag :skip
    test "persists one durable logout event plus per-client delivery rows in a single transactional flow" do
      # Plan 39 implementation must persist the protocol fact and all fan-out
      # units together before background work begins.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end

    @tag :skip
    test "records logout requested and delivery enqueued as distinct observability milestones" do
      # The implementation must not collapse durable intent creation and async
      # worker enqueue into one opaque success event.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end

    @tag :skip
    test "avoids duplicating propagation deliveries when completion is replayed for the same logout event" do
      # Phase 39 requires idempotent completion behavior for repeated host
      # return hits and clustered retry races.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end
  end

  describe "frontchannel_render_model/1" do
    @tag :skip
    test "returns best-effort iframe targets plus bounded continue fallback data without claiming remote success" do
      # Front-channel logout stays truthful: Lockspire renders browser work but
      # does not pretend it has confirmation from each RP.
      _contract = LogoutPropagation
      flunk("not yet implemented")
    end
  end
end
