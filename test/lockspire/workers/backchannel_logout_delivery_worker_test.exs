defmodule Lockspire.Workers.BackchannelLogoutDeliveryWorkerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Workers.BackchannelLogoutDeliveryWorker

  describe "perform/1" do
    @tag :skip
    test "POSTs the logout_token to the persisted backchannel_logout_uri for the delivery row" do
      # Plan 39 implementation will drive Req-based POST delivery from a
      # durable delivery snapshot rather than live client lookups.
      _contract = BackchannelLogoutDeliveryWorker
      flunk("not yet implemented")
    end

    @tag :skip
    test "marks transient network or 5xx failures retryable while keeping the delivery pending for later attempts" do
      # Retry classification must be durable and bounded, not inferred from log
      # lines or process-local state.
      _contract = BackchannelLogoutDeliveryWorker
      flunk("not yet implemented")
    end

    @tag :skip
    test "converges repeated 4xx or invalid client configuration failures to a terminal discarded state" do
      # Phase 39 must not retry stable permanent failures forever.
      _contract = BackchannelLogoutDeliveryWorker
      flunk("not yet implemented")
    end

    @tag :skip
    test "records attempted and succeeded as separate durable/auditable transitions" do
      # Operators need distinct attempted and succeeded states for debugging and
      # telemetry truth.
      _contract = BackchannelLogoutDeliveryWorker
      flunk("not yet implemented")
    end

    @tag :skip
    test "redacts raw logout_token and response body material from logs, telemetry, and failure metadata" do
      # Security posture requires strong redaction for protocol artifacts even
      # when a remote relying party fails loudly.
      _contract = BackchannelLogoutDeliveryWorker
      flunk("not yet implemented")
    end
  end
end
