defmodule Lockspire.Web.Live.Admin.KeysLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Keys",
       current_section: :keys,
       keys: [],
       inventory_state: :loading,
       total_keys: nil,
       lifecycle_metrics: nil,
       generation_error: nil,
       generation_notice: nil
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign_inventory(socket, :loading)}
  end

  @impl true
  def handle_event("retry_inventory", _params, socket) do
    {:noreply, assign_inventory(socket, :loading)}
  end

  def handle_event("generate", %{"use" => use}, socket) when use in ["sig", "enc"] do
    generate_key(socket, use, String.to_existing_atom(use))
  end

  def handle_event("generate", _params, socket) do
    {:noreply,
     assign(socket,
       generation_error: "Choose signing or encryption key use before generating a key.",
       generation_notice: nil
     )}
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
        <AdminComponents.metric_grid :if={@inventory_state == :loaded}>
          <AdminComponents.summary_stat value={@lifecycle_metrics.active} label="Active" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.upcoming} label="Upcoming" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retiring} label="Retiring" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retired} label="Retired" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.total} label="Total keys" />
        </AdminComponents.metric_grid>

        <p :if={@inventory_state == :loaded} class="lockspire-admin-help lockspire-admin-help-block">
          {key_generation_group_copy(@lifecycle_metrics)}
        </p>

        <AdminComponents.action_group class="lockspire-admin-action-bar-compact">
          <:primary>
            <AdminComponents.admin_button
              phx-click="generate"
              phx-value-use="sig"
              phx-disable-with="Generating signing key…"
              variant={:primary}
              disabled={@inventory_state != :loaded}
            >
              Generate signing key
            </AdminComponents.admin_button>
          </:primary>
          <:secondary>
            <AdminComponents.admin_button
              phx-click="generate"
              phx-value-use="enc"
              phx-disable-with="Generating encryption key…"
              disabled={@inventory_state != :loaded}
            >
              Generate encryption key
            </AdminComponents.admin_button>
          </:secondary>
        </AdminComponents.action_group>

        <p :if={@generation_notice} role="status" class="lockspire-admin-help lockspire-admin-help-block">
          {@generation_notice}
        </p>
        <ul :if={@generation_error} class="lockspire-admin-errors" role="alert">
          <li>{@generation_error}</li>
        </ul>

        <p :if={@inventory_state == :loaded} class="lockspire-admin-help lockspire-admin-help-block">
          Total keys in durable storage: {@total_keys}
        </p>

        <div aria-live="polite" aria-atomic="true">
          <%= case @inventory_state do %>
            <% :loading -> %>
              <p role="status">Loading signing keys…</p>
            <% :error -> %>
              <AdminComponents.empty_state
                title="Could not load signing keys"
                body="The key inventory is unavailable. No key count or lifecycle state is shown until the read succeeds."
              >
                <:actions>
                  <AdminComponents.admin_button
                    type="button"
                    phx-click="retry_inventory"
                    phx-disable-with="Loading signing keys…"
                  >
                    Try loading signing keys again
                  </AdminComponents.admin_button>
                </:actions>
              </AdminComponents.empty_state>
            <% :loaded when @keys == [] -> %>
              <AdminComponents.empty_state
                title="No signing keys are stored"
                body="Generate signing or encryption key material before relying on JWKS publication."
              />
            <% :loaded -> %>
              <AdminComponents.resource_list>
                <%= for entry <- @keys do %>
                  <AdminComponents.resource_item
                    href={key_show_path(entry.key.id)}
                    title="Review key lifecycle"
                    subtitle={"#{entry.key.alg} / #{entry.key.kty}"}
                  >
                    <:meta>
                      <span>
                        Key
                        <AdminComponents.long_value
                          value={Redaction.handle(:kid, entry.key.kid)}
                          kind={:id}
                        />
                      </span>
                      <span>Use <AdminComponents.long_value value={entry.key.use} kind={:text} /></span>
                      <span>Published <AdminComponents.long_value value={format_datetime(entry.key.published_at)} kind={:timestamp} /></span>
                      <span>Activated <AdminComponents.long_value value={format_datetime(entry.key.activated_at)} kind={:timestamp} /></span>
                      <span>Retiring <AdminComponents.long_value value={format_datetime(entry.key.retiring_at)} kind={:timestamp} /></span>
                      <span>Retired <AdminComponents.long_value value={format_datetime(entry.key.retired_at)} kind={:timestamp} /></span>
                      <span>
                        Next safe action <AdminComponents.long_value value={key_next_action_summary(entry)} kind={:text} />
                      </span>
                    </:meta>
                    <:status>
                      <AdminComponents.status_badge
                        status={entry.key.status}
                        title={key_status_title(entry.key.status)}
                      />
                      <span class="lockspire-admin-help">
                        {if entry.publishable, do: "Served in JWKS", else: "Not served in JWKS"}
                      </span>
                    </:status>
                  </AdminComponents.resource_item>
                <% end %>
              </AdminComponents.resource_list>
          <% end %>
        </div>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_keys do
    case Admin.list_keys() do
      {:ok, keys} -> {:ok, keys}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assign_inventory(socket, :loading) do
    socket
    |> assign(
      inventory_state: :loading,
      keys: [],
      total_keys: nil,
      lifecycle_metrics: nil,
      generation_error: nil,
      generation_notice: nil
    )
    |> assign_inventory_result(load_keys())
  end

  defp assign_inventory_result(socket, {:ok, keys}) do
    assign(socket,
      inventory_state: :loaded,
      keys: keys,
      total_keys: length(keys),
      lifecycle_metrics: key_lifecycle_metrics(keys)
    )
  end

  defp assign_inventory_result(socket, {:error, _reason}) do
    assign(socket,
      inventory_state: :error,
      keys: [],
      total_keys: nil,
      lifecycle_metrics: nil
    )
  end

  defp generate_key(socket, use, use_atom) do
    key_label = if use == "sig", do: "Signing", else: "Encryption"

    case Admin.generate_key(use_atom) do
      {:ok, %{key: %{id: generated_id}}} ->
        case load_keys() do
          {:ok, keys} ->
            socket = assign_inventory_result(socket, {:ok, keys})

            if Enum.any?(keys, &(&1.key.id == generated_id)) do
              {:noreply,
               assign(socket,
                 generation_error: nil,
                 generation_notice: "#{key_label} key generated and confirmed in the inventory."
               )}
            else
              {:noreply,
               assign(socket,
                 generation_error:
                   "The generated key was not present in the refreshed inventory. Reload before retrying.",
                 generation_notice: nil
               )}
            end

          {:error, _reason} ->
            socket = assign_inventory_result(socket, {:error, :read_failed})

            {:noreply,
             assign(socket,
               generation_error:
                 "The key may have been generated, but Lockspire could not confirm it in the inventory. Reload before retrying.",
               generation_notice: nil
             )}
        end

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           generation_error: "The #{String.downcase(key_label)} key could not be generated.",
           generation_notice: nil
         )}
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

  defp key_status_title(:active), do: "Current key selected for signing or decryption operations."
  defp key_status_title(:upcoming), do: "Prepared key; publish it before activating the signer."
  defp key_status_title(:retiring), do: "Previous key remains served during retirement overlap."
  defp key_status_title(:retired), do: "Retired key is not included in the served JWKS."
  defp key_status_title(_status), do: "Signing-key lifecycle state."

  defp format_datetime(nil), do: "Not recorded"

  defp format_datetime(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")
end
