if Code.ensure_loaded?(Phoenix.LiveDashboard.PageBuilder) do
  defmodule Lockspire.LiveDashboardPage do
    @moduledoc """
    A custom LiveDashboard page for Lockspire.

    Also provides Lockspire's Telemetry metrics which can be used with
    LiveDashboard's native metrics page.
    """
    use Phoenix.LiveDashboard.PageBuilder

    @impl true
    def menu_link(_, _) do
      {:ok, "Lockspire"}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="row">
        <div class="column">
          <div class="card">
            <h5 class="card-title">Lockspire Real-time Metrics</h5>
            <div class="card-body">
              <p>Lockspire exposes Telemetry metrics which can be viewed in LiveDashboard's native Metrics tab with history support.</p>
              <p>To enable them, add the <code>metrics</code> option to your LiveDashboard configuration in <code>router.ex</code>:</p>
              <pre><code>live_dashboard "/dashboard",
        metrics: &#123;Lockspire.LiveDashboardPage, :metrics&#125;</code></pre>
            </div>
          </div>
        </div>
      </div>
      """
    end

    @doc """
    Returns a list of `Telemetry.Metrics` for Lockspire events.
    """
    def metrics do
      [
        Telemetry.Metrics.counter(
          "lockspire.token.issued.count",
          event_name: [:lockspire, :token, :issued],
          description: "Number of tokens issued"
        ),
        Telemetry.Metrics.counter(
          "lockspire.token.failed.count",
          event_name: [:lockspire, :token, :failed],
          description: "Number of token issuance failures"
        ),
        Telemetry.Metrics.counter(
          "lockspire.dpop.failed.count",
          event_name: [:lockspire, :dpop, :failed],
          description: "Number of DPoP validation failures"
        ),
        Telemetry.Metrics.counter(
          "lockspire.logout.requested.count",
          event_name: [:lockspire, :logout, :requested],
          description: "Number of logout requests"
        ),
        Telemetry.Metrics.counter(
          "lockspire.logout.delivery_succeeded.count",
          event_name: [:lockspire, :logout, :delivery_succeeded],
          description: "Number of successful logout deliveries"
        )
      ]
    end
  end
end
