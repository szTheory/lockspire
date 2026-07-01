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
       total_keys: 0,
       lifecycle_metrics: key_lifecycle_metrics([])
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    keys = load_keys()

    {:noreply,
     assign(socket,
       keys: keys,
       total_keys: length(keys),
       lifecycle_metrics: key_lifecycle_metrics(keys)
     )}
  end

  @impl true
  def handle_event("generate", %{"use" => use}, socket) do
    use_atom = String.to_existing_atom(use)

    case Admin.generate_key(use_atom) do
      {:ok, _key_view} ->
        keys = load_keys()

        {:noreply,
         assign(socket,
           keys: keys,
           total_keys: length(keys),
           lifecycle_metrics: key_lifecycle_metrics(keys)
         )}

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
        body="Review issuer key posture, publication overlap, rollover readiness, and safe lifecycle actions without exposing non-public key material."
      />

      <AdminComponents.section_card
        title="Key lifecycle posture"
        subtitle="Inspect upcoming, active, retiring, and retired keys without exposing raw status editing."
      >
        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat value={@lifecycle_metrics.active} label="Active" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.upcoming} label="Upcoming" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retiring} label="Retiring" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retired} label="Retired" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.total} label="Total keys" />
        </AdminComponents.metric_grid>

        <p class="lockspire-admin-help lockspire-admin-help-block">
          {key_generation_group_copy(@lifecycle_metrics)}
        </p>

        <AdminComponents.action_group class="lockspire-admin-action-bar-compact">
          <:primary>
            <AdminComponents.admin_button phx-click="generate" phx-value-use="sig" variant={:primary}>
              Generate signing key
            </AdminComponents.admin_button>
            <AdminComponents.admin_button phx-click="generate" phx-value-use="enc">
              Generate encryption key
            </AdminComponents.admin_button>
          </:primary>
        </AdminComponents.action_group>

        <p class="lockspire-admin-help lockspire-admin-help-block">
          Total keys in durable storage: {@total_keys}
        </p>

        <%= if @keys == [] do %>
          <AdminComponents.empty_state
            title="No signing keys are stored"
            body="Generate signing or encryption key material before relying on JWKS publication."
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
                  <span>
                    Next safe action <AdminComponents.long_value value={key_next_action_summary(entry)} kind={:text} />
                  </span>
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

  defp key_lifecycle_metrics(keys) do
    %{
      active: count_keys(keys, :active),
      upcoming: count_keys(keys, :upcoming),
      retiring: count_keys(keys, :retiring),
      retired: count_keys(keys, :retired),
      total: length(keys)
    }
  end

  defp count_keys(keys, status), do: Enum.count(keys, &(&1.key.status == status))

  defp key_generation_group_copy(_metrics), do: "Key generation actions"

  defp key_next_action_summary(%{next_actions: [:publish]}),
    do: "Publish key for verification overlap"

  defp key_next_action_summary(%{next_actions: [:activate]}),
    do: "Activate key for signer cutover"

  defp key_next_action_summary(%{next_actions: [:retire]}),
    do: "Retire key after verifier overlap"

  defp key_next_action_summary(%{next_actions: []}), do: "No lifecycle action available"

  defp format_datetime(nil), do: "Not recorded"

  defp format_datetime(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")
end
