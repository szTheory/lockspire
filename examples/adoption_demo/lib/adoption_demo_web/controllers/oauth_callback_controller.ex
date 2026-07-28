defmodule AdoptionDemoWeb.OAuthCallbackController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def show(conn, params) do
    {status_class, status_label, title} =
      cond do
        Map.has_key?(params, "error") ->
          {"bad", "Returned error", "Authorization returned an error."}

        Map.has_key?(params, "code") ->
          {"good", "Code returned", "Authorization response received."}

        true ->
          {"neutral", "Callback opened", "OAuth callback"}
      end

    receipt_rows = callback_receipt_rows(params)
    raw_params = HTML.escape(Jason.encode!(params, pretty: true))

    body = """
    <section class="result-stage wide">
      <article class="panel result-card">
        <header class="result-header split-header">
          <div>
            <p class="kicker">OAuth callback</p>
            <h1>#{title}</h1>
            <p>
              Billingo's registered redirect URI received this response from Lockspire.
              This is the browser handoff before token exchange.
            </p>
          </div>
          <span class="status-pill #{status_class}">#{status_label}</span>
        </header>

        <div class="result-actions">
          <a class="button" href="/developer/apps">Run OAuth proof again</a>
          <a class="button secondary" href="/authorized-apps">View authorized apps</a>
        </div>

        <section class="record-section">
          <p class="kicker">Callback receipt</p>
          <div class="receipt-list">
            #{receipt_rows}
          </div>
        </section>

        <section class="record-section">
          <p class="kicker">Next in a real app</p>
          <ol class="handoff-steps">
            <li class="handoff-step">
              <span class="step-index">1</span>
              <p><strong>Verify state.</strong> Billingo checks this is the callback it started.</p>
            </li>
            <li class="handoff-step">
              <span class="step-index">2</span>
              <p><strong>Exchange code.</strong> The client sends the code and PKCE verifier to <code>/lockspire/token</code>.</p>
            </li>
            <li class="handoff-step">
              <span class="step-index">3</span>
              <p><strong>Route product UX.</strong> Billingo continues into the workspace with tokens stored safely for the client shape.</p>
            </li>
          </ol>

          <details class="raw-details">
            <summary>Raw callback parameters</summary>
            <pre>#{raw_params}</pre>
          </details>
        </section>
      </article>
    </section>
    """

    html(conn, HTML.page(conn, "OAuth callback", body))
  end

  defp callback_receipt_rows(%{"error" => error} = params) do
    description = params["error_description"] || "Lockspire returned an OAuth error."

    receipt_row(
      "error",
      "Request failed",
      "<code>#{HTML.escape(error)}</code> means no authorization code should be exchanged. #{HTML.escape(description)}"
    ) <> maybe_state_row(params)
  end

  defp callback_receipt_rows(%{"code" => code} = params) do
    receipt_row(
      "code",
      "Short-lived handoff",
      "<code>#{HTML.escape(code)}</code> is exchanged at <code>/lockspire/token</code> with the original PKCE verifier."
    ) <> maybe_state_row(params)
  end

  defp callback_receipt_rows(params) do
    receipt_row(
      "response",
      "No OAuth result yet",
      "Open this route from the developer console flow to see <code>code</code>, <code>state</code>, or <code>error</code> translated."
    ) <> maybe_state_row(params)
  end

  defp maybe_state_row(%{"state" => state}) do
    receipt_row(
      "state",
      "Client correlation check",
      "<code>#{HTML.escape(state)}</code> lets the Billingo client reject mixed-up or forged browser callbacks."
    )
  end

  defp maybe_state_row(_params), do: ""

  defp receipt_row(label, title, body) do
    """
    <div class="receipt-row">
      <span>#{HTML.escape(label)}</span>
      <div>
        <strong>#{HTML.escape(title)}</strong>
        <p>#{body}</p>
      </div>
    </div>
    """
  end
end
