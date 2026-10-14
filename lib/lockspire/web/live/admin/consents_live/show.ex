defmodule Lockspire.Web.Live.Admin.ConsentsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @consent_confirm_error "Select the confirmation checkbox to revoke this consent grant."
  @revocation_failure "Revocation could not be confirmed. The consent grant may still be active; reload this Support workflow before retrying."
  @already_revoked_copy "These saved permissions have already been removed."
  @revocation_consequence "The saved approval is removed, so the user may be asked again the next time this app requests these permissions."
  @default_filters %{"account" => "", "client" => "", "status" => "all"}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Consent grant details",
       current_section: :consents,
       consent_id: parse_id(id),
       filters: @default_filters,
       consent: nil,
       detail_state: :loading,
       revoke_notice: nil,
       revoke_error: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    consent_id = parse_id(Map.get(params, "id", socket.assigns.consent_id))
    filters = normalize_filters(params)

    {:noreply,
     socket
     |> assign(
       consent_id: consent_id,
       filters: filters,
       detail_state: :loading,
       revoke_notice: nil,
       revoke_error: nil
     )
     |> load_consent(consent_id)}
  end

  @impl true
  def handle_event(
        "revoke_consent",
        %{"revoke" => %{"confirm" => "true"}},
        %{assigns: %{consent: %{grant: %{status: :revoked}}}} = socket
      ) do
    {:noreply,
     assign(socket,
       revoke_notice: @already_revoked_copy,
       revoke_error: nil
     )}
  end

  def handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket) do
    case Admin.revoke_consent(socket.assigns.consent_id, %{
           revoked_by: "operator",
           revoked_reason: "operator_revoked"
         }) do
      {:ok, %{grant: %{status: :revoked}} = consent} ->
        {:noreply,
         assign(socket,
           consent: consent,
           revoke_notice: "Consent grant revoked. #{@revocation_consequence}",
           revoke_error: nil
         )}

      {:ok, consent} ->
        {:noreply,
         assign(socket,
           consent: consent,
           revoke_notice: nil,
           revoke_error: @revocation_failure
         )}

      {:error, _reason} ->
        {:noreply, assign(socket, revoke_error: @revocation_failure)}
    end
  end

  def handle_event("revoke_consent", _params, socket) do
    {:noreply,
     assign(socket,
       revoke_error: @consent_confirm_error
     )}
  end

  @impl true
  def render(%{detail_state: :loading, consent: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <p role="status">Loading consent grant…</p>
    </AdminLayoutLive.shell>
    """
  end

  def render(%{detail_state: :error, consent: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Could not load consent grant"
        body="The grant detail is unavailable. Retry this exact record or return to the consent inventory."
      >
        <:actions>
          <AdminComponents.admin_button href={consent_show_path(@consent_id, @filters)}>
            Retry consent grant
          </AdminComponents.admin_button>
          <AdminComponents.admin_button href={consents_index_path(@filters)}>
            Return to consent investigation
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.empty_state>
    </AdminLayoutLive.shell>
    """
  end

  def render(%{detail_state: :missing, consent: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Consent grant not found"
        body="No stored grant matches this record. Return to the consent inventory to continue the investigation."
      >
        <:actions>
          <AdminComponents.admin_button href={consents_index_path(@filters)}>
            Return to consent investigation
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.empty_state>
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <div class="lockspire-admin-detail-stack">
      <AdminComponents.page_hero
        body="Review what this app can access for this account."
      >
        <:actions>
          <AdminComponents.admin_button href={consents_index_path(@filters)}>
            Back to consent grants
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.entity_header
        title={client_display(@consent)}
        subtitle="Saved permissions for this account."
      >
        <:status>
          <AdminComponents.status_badge status={@consent.grant.status} />
          <AdminComponents.status_badge status={@consent.grant.kind} />
        </:status>
      </AdminComponents.entity_header>

      <AdminComponents.pane
        title="Grant context"
      >
        <AdminComponents.description_list>
          <:item label="Grant ID">
            <AdminComponents.long_value
              value={safe_identifier(@consent.grant.id)}
              kind={:id}
            />
          </:item>
          <:item label="Account">
            <AdminComponents.long_value
              value={redacted_account_identifier(@consent.grant.account_id)}
              kind={:id}
            />
          </:item>
          <:item label="Client ID">
            <AdminComponents.long_value
              value={safe_identifier(@consent.grant.client_id)}
              kind={:id}
            />
            <AdminComponents.admin_button
              :if={client_detail_path_available?(@consent)}
              href={client_detail_path(@consent.grant.client_id)}
            >
              View app details
            </AdminComponents.admin_button>
          </:item>
          <:item label="Granted at">
            <AdminComponents.timestamp value={@consent.grant.granted_at} />
          </:item>
          <:item :if={@consent.grant.revoked_at} label="Revoked at">
            <AdminComponents.timestamp value={@consent.grant.revoked_at} />
          </:item>
          <:item :if={@consent.grant.revoked_by} label="Revoked by"><code>{@consent.grant.revoked_by}</code></:item>
          <:item :if={@consent.grant.revoked_reason} label="Revoked reason">
            <code>{@consent.grant.revoked_reason}</code>
          </:item>
          <:item label="Scopes">
            <AdminComponents.long_value value={scope_label(@consent.grant.scopes)} kind={:text} />
          </:item>
        </AdminComponents.description_list>
      </AdminComponents.pane>

      <p :if={@revoke_notice} role="status">{@revoke_notice}</p>
      <p :if={consent_revoked?(@consent) and !@revoke_notice} role="status">{already_revoked_copy()}</p>
      <AdminComponents.pane
        :if={!consent_revoke_disabled?(@consent)}
        title="Revoke consent grant"
        subtitle="Remove the saved approval when the user should review these permissions again."
      >
        <AdminComponents.confirmation_panel
          title="Revoke consent grant"
          show_heading={false}
          embedded={true}
          variant={:danger}
          errors={consent_revoke_errors(@revoke_error)}
        >
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_consent">
              <label class="lockspire-admin-checkbox-field">
                <input
                  type="checkbox"
                  name="revoke[confirm]"
                  value="true"
                />
                <span>
                  Revoke consent grant
                  <AdminComponents.long_value
                    value={safe_identifier(@consent.grant.id)}
                    kind={:id}
                  />
                  for app
                  {client_display(@consent)}, account
                  {redacted_account_identifier(@consent.grant.account_id)}, and scopes
                  {scope_label(@consent.grant.scopes)}. {revocation_consequence()}
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button
                  type="submit"
                  variant={:danger}
                  phx-disable-with="Revoking this consent grant…"
                >
                  Revoke consent grant
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>
      </AdminComponents.pane>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_consent(socket, nil), do: assign(socket, consent: nil, detail_state: :missing)

  defp load_consent(socket, consent_id) do
    case read_consent(consent_id) do
      {:ok, nil} -> assign(socket, consent: nil, detail_state: :missing)
      {:ok, consent} -> assign(socket, consent: consent, detail_state: :loaded)
      {:error, _reason} -> assign(socket, consent: nil, detail_state: :error)
    end
  end

  defp read_consent(consent_id) do
    Admin.get_consent(consent_id)
  rescue
    _error -> {:error, :unavailable}
  end

  defp parse_id(value) when is_integer(value) and value > 0, do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> id
      :error -> nil
      _other -> nil
    end
  end

  defp parse_id(_value), do: nil

  defp normalize_filters(params) do
    %{
      "account" => normalize_filter(Map.get(params, "account")),
      "client" => normalize_filter(Map.get(params, "client")),
      "status" => normalize_status(Map.get(params, "status"))
    }
  end

  defp normalize_filter(value) when is_binary(value), do: value
  defp normalize_filter(_value), do: ""

  defp normalize_status(status) when status in ["all", "active", "revoked"], do: status
  defp normalize_status(_status), do: "all"

  defp client_display(consent) do
    case consent.client do
      %{name: name} when is_binary(name) and name != "" -> name
      %{client_id: client_id} when is_binary(client_id) and client_id != "" -> client_id
      _missing -> "App name unavailable"
    end
  end

  defp already_revoked_copy, do: @already_revoked_copy
  defp revocation_consequence, do: @revocation_consequence

  defp consent_revoked?(consent), do: consent.grant.status == :revoked

  defp consent_revoke_disabled?(consent), do: consent_revoked?(consent)

  defp consent_revoke_errors(nil), do: []
  defp consent_revoke_errors(error), do: [error]

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

  defp redacted_account_identifier(nil), do: "Not recorded"
  defp redacted_account_identifier(value), do: Redaction.handle(:account, value)

  defp scope_label([]), do: "No scopes recorded"
  defp scope_label(scopes), do: Enum.join(scopes, ", ")

  defp consents_base_path, do: Lockspire.mount_path() <> "/admin/consents"

  defp consents_index_path(filters) do
    append_filter_query(consents_base_path(), filters)
  end

  defp consent_show_path(id, filters) do
    append_filter_query(consents_base_path() <> "/#{id}", filters)
  end

  defp append_filter_query(path, @default_filters), do: path

  defp append_filter_query(path, filters) do
    query = URI.encode_query(Map.to_list(filters))
    if query == "", do: path, else: path <> "?" <> query
  end

  defp client_detail_path_available?(%{grant: %{client_id: client_id}}) when is_binary(client_id),
    do: byte_size(client_id) <= 64

  defp client_detail_path_available?(_consent), do: false

  defp client_detail_path(client_id),
    do:
      Lockspire.mount_path() <>
        "/admin/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1)
end
