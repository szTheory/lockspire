defmodule AdoptionDemoWeb.AuthorizedAppsController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemo.Lockspire.AccountResolver
  alias AdoptionDemoWeb.HTML
  alias Lockspire.Admin.Consents

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    body = if account, do: signed_in_body(account), else: signed_out_body()

    html(conn, HTML.page(conn, "Authorized apps", body))
  end

  def delete(conn, %{"id" => id}) do
    case conn.assigns[:current_account] do
      nil ->
        redirect(conn, to: "/login?return_to=/authorized-apps")

      account ->
        conn
        |> disconnect(account, id)
        |> redirect(to: "/authorized-apps")
    end
  end

  # Scoped to the signed-in customer on purpose: the grant id comes from the URL,
  # so a customer must never be able to revoke another account's consent.
  defp disconnect(conn, account, id) do
    with {grant_id, ""} <- Integer.parse(to_string(id)),
         {:ok, %{grant: grant} = consent} <- Consents.get_consent(grant_id),
         true <- grant.account_id == AccountResolver.subject_for(account),
         true <- grant.status == :active,
         {:ok, _revoked} <- Consents.revoke_consent(grant_id, revoke_attrs(account)) do
      put_flash(
        conn,
        :info,
        "Disconnected #{client_label(consent)}. Lockspire marked the consent record revoked, so the app has to ask for your approval again."
      )
    else
      _other ->
        put_flash(conn, :error, "That app is not connected to your Billingo account.")
    end
  end

  defp revoke_attrs(account) do
    %{
      revoked_by: account.id,
      revoked_reason: "customer_disconnected",
      actor: %{type: :user, id: account.id, display: account.email}
    }
  end

  defp signed_in_body(account) do
    case Consents.list_consents_for_account(AccountResolver.subject_for(account)) do
      {:ok, []} -> account_shell(account, empty_state())
      {:ok, consents} -> account_shell(account, app_list(consents))
      {:error, _reason} -> account_shell(account, load_error())
    end
  end

  defp account_shell(account, inner) do
    """
    <section class="task-stage wide">
      <article class="panel task-card">
        <header class="task-header split-header">
          <div>
            <p class="kicker">Customer account</p>
            <h1>Apps connected to your Billingo data.</h1>
            <p>Review software that can use Billingo on your behalf. Billingo owns this settings surface; Lockspire stores the consent record behind it.</p>
          </div>
          <span class="status-pill neutral">#{HTML.escape(AccountResolver.subject_for(account))}</span>
        </header>
        #{inner}
      </article>
    </section>
    """
  end

  defp app_list(consents) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()

    """
    <section class="app-list" aria-label="Connected apps">
      #{Enum.map_join(consents, "\n", &app_row(&1, csrf_token))}
    </section>
    <div class="task-note">
      <p>Every row is a real consent grant Lockspire recorded for your account. Disconnecting revokes the grant; operator-side management of the same records lives in Lockspire admin.</p>
    </div>
    """
  end

  defp app_row(%{grant: grant} = consent, csrf_token) do
    active? = grant.status == :active

    """
    <article class="app-row">
      <div>
        <h2>#{HTML.escape(client_label(consent))}</h2>
        <p>#{row_summary(consent, active?)}</p>
        <p class="kicker">What this app can do</p>
        #{HTML.scope_meaning_list(grant.scopes)}
        <dl class="data-list">
          <div class="data-row"><dt>Connected on</dt><dd>#{format_timestamp(grant.granted_at)}</dd></div>
          <div class="data-row"><dt>Consent kind</dt><dd>#{consent_kind(grant.kind)}</dd></div>
          <div class="data-row"><dt>Client id</dt><dd><code>#{HTML.escape(grant.client_id)}</code></dd></div>
          #{revoked_rows(grant, active?)}
        </dl>
      </div>
      <div class="app-meta">
        #{status_pill(active?)}
        #{disconnect_form(grant, csrf_token, active?)}
      </div>
    </article>
    """
  end

  defp row_summary(consent, true) do
    "Approved by you. #{HTML.escape(client_label(consent))} can use Billingo on your behalf with the access listed below."
  end

  defp row_summary(_consent, false) do
    "No longer connected. Lockspire keeps the revoked record so the decision stays auditable."
  end

  defp status_pill(true), do: ~s(<span class="status-pill good">Active</span>)
  defp status_pill(false), do: ~s(<span class="status-pill neutral">Disconnected</span>)

  defp disconnect_form(_grant, _csrf_token, false), do: ""

  defp disconnect_form(grant, csrf_token, true) do
    """
    <form action="/authorized-apps/#{grant.id}" method="post">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="_csrf_token" value="#{csrf_token}" />
      <button class="button danger compact" type="submit">Disconnect</button>
    </form>
    """
  end

  defp revoked_rows(_grant, true), do: ""

  defp revoked_rows(grant, false) do
    """
    <div class="data-row"><dt>Disconnected on</dt><dd>#{format_timestamp(grant.revoked_at)}</dd></div>
    <div class="data-row"><dt>Reason</dt><dd>#{revoked_reason(grant.revoked_reason)}</dd></div>
    """
  end

  # Revocation reasons are protocol-side codes; Billingo owns the customer wording.
  defp revoked_reason("customer_disconnected"), do: "You disconnected this app"
  defp revoked_reason(nil), do: "not recorded"
  defp revoked_reason(reason), do: HTML.escape(reason)

  defp consent_kind(:remembered), do: "Remembered for future matching requests"
  defp consent_kind(:one_time), do: "One-time approval"
  defp consent_kind(other), do: HTML.escape(other)

  defp client_label(%{client: nil, grant: grant}), do: grant.client_id
  defp client_label(%{client: client, grant: grant}), do: client.name || grant.client_id

  defp format_timestamp(nil), do: "not recorded"

  defp format_timestamp(%DateTime{} = timestamp) do
    Calendar.strftime(timestamp, "%b %-d, %Y at %H:%M UTC")
  end

  defp empty_state do
    """
    <div class="task-note">
      <p><strong>No apps are connected yet.</strong> Once you approve an OAuth request, Lockspire records the consent grant and it shows up here with a Disconnect control.</p>
    </div>
    <div class="task-actions">
      <a class="button" href="/developer/apps">Start an authorization request</a>
      <a class="button secondary" href="/verify">Device code</a>
    </div>
    """
  end

  defp load_error do
    """
    <p class="inline-alert">Billingo could not read your consent records from Lockspire right now. Try again in a moment.</p>
    """
  end

  defp signed_out_body do
    """
    <section class="task-stage">
      <article class="panel task-card">
        <header class="task-header">
          <p class="kicker">Customer account</p>
          <h1>Review apps connected to Billingo.</h1>
          <p>Sign in as a demo customer to see the host-owned authorized-apps surface.</p>
        </header>
        <div class="task-actions">
          <a class="button" href="/login?return_to=/authorized-apps">Sign in</a>
          <a class="button secondary" href="/developer/apps">View developer app</a>
        </div>
        <div class="task-note">
          <p>Billingo presents the customer-facing connected-apps list; Lockspire keeps the consent records behind it.</p>
        </div>
      </article>
    </section>
    """
  end
end
