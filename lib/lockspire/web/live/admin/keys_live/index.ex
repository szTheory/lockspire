defmodule Lockspire.Web.Live.Admin.KeysLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Keys",
       current_section: :keys,
       keys: [],
       total_keys: 0
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    keys = load_keys()

    {:noreply,
     assign(socket,
       keys: keys,
       total_keys: length(keys)
     )}
  end

  @impl true
  def handle_event("generate", %{"use" => use}, socket) do
    use_atom = String.to_existing_atom(use)

    case Admin.generate_key(use_atom) do
      {:ok, _key_view} ->
        keys = load_keys()
        {:noreply, assign(socket, keys: keys, total_keys: length(keys))}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Review key lifecycle"
        body="Review issuer key posture, publication overlap, rollover readiness, and safe lifecycle actions without exposing private key material."
      />

      <AdminComponents.section_card
        title="Key lifecycle posture"
        subtitle="Inspect upcoming, active, retiring, and retired keys without exposing raw status editing."
      >
        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat value={count_keys(@keys, :active)} label="Active" />
          <AdminComponents.summary_stat value={count_keys(@keys, :upcoming)} label="Upcoming" />
          <AdminComponents.summary_stat value={count_keys(@keys, :retiring)} label="Retiring" />
          <AdminComponents.summary_stat value={count_keys(@keys, :retired)} label="Retired" />
          <AdminComponents.summary_stat value={@total_keys} label="Total keys" />
        </AdminComponents.metric_grid>

        <AdminComponents.action_bar class="lockspire-admin-action-bar-compact">
          <AdminComponents.admin_button phx-click="generate" phx-value-use="sig" variant={:primary}>
            Generate signing key
          </AdminComponents.admin_button>
          <AdminComponents.admin_button phx-click="generate" phx-value-use="enc">
            Generate encryption key
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>

        <p class="lockspire-admin-help lockspire-admin-help-block">
          Total keys in durable storage: {@total_keys}
        </p>

        <%= if @keys == [] do %>
          <AdminComponents.empty_state
            title="No signing keys are stored"
            body="Create or import a key before relying on Lockspire for JWKS publication and ID token signing."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for entry <- @keys do %>
              <AdminComponents.resource_item
                href={key_show_path(entry.key.id)}
                title="Review key lifecycle"
                subtitle={"#{entry.key.alg} / #{entry.key.kty}"}
              >
                <:meta>
                  <span>Key <AdminComponents.long_value value={entry.key.kid} kind={:id} /></span>
                  <span>Use <AdminComponents.long_value value={entry.key.use} kind={:text} /></span>
                  <span>Published <AdminComponents.long_value value={format_datetime(entry.key.published_at)} kind={:timestamp} /></span>
                  <span>Activated <AdminComponents.long_value value={format_datetime(entry.key.activated_at)} kind={:timestamp} /></span>
                  <span>Next action {format_actions(entry.next_actions)}</span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={entry.key.status} />
                  <span class="lockspire-admin-help">JWKS {if entry.publishable, do: "visible", else: "hidden"}</span>
                </:status>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_keys do
    case Admin.list_keys() do
      {:ok, keys} -> keys
      {:error, _reason} -> []
    end
  end

  defp key_show_path(id), do: Lockspire.mount_path() <> "/admin/keys/" <> Integer.to_string(id)

  defp count_keys(keys, status), do: Enum.count(keys, &(&1.key.status == status))

  defp format_datetime(nil), do: "Not recorded"

  defp format_datetime(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp format_actions([]), do: "None"

  defp format_actions(actions) do
    Enum.map_join(actions, ", ", &(&1 |> Atom.to_string() |> String.capitalize()))
  end
end
