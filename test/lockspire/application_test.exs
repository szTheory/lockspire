defmodule Lockspire.ApplicationTest do
  use ExUnit.Case, async: false

  alias Lockspire.Application

  describe "start/2" do
    @tag :skip
    test "starts the Lockspire-owned Oban supervision child when valid queue config is present" do
      # Phase 39 startup wiring will add a library-owned Oban instance to the
      # supervision tree once config validation lands.
      _contract = Application
      flunk("not yet implemented")
    end

    @tag :skip
    test "fails fast with a clear error when required Oban repo config is missing" do
      # Missing durable queue config must fail at startup instead of silently
      # disabling back-channel logout propagation.
      _contract = Application
      flunk("not yet implemented")
    end

    @tag :skip
    test "fails fast with a clear error when Oban config shape is invalid for Lockspire startup" do
      # Invalid queue/runtime config should surface immediately so host apps do
      # not believe logout delivery is active when it is not.
      _contract = Application
      flunk("not yet implemented")
    end
  end
end
