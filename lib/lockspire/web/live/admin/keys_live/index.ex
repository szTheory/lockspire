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
      <AdminComponents.section_card
        title="Signing key lifecycle"
        subtitle="Inspect upcoming, active, retiring, and retired keys without exposing raw status editing."
      >
        <div class="lockspire-admin-actions" style="margin-bottom: 1rem; display: flex; gap: 1rem;">
          <button phx-click="generate" phx-value-use="sig" class="button">Generate Signing Key</button>
          <button phx-click="generate" phx-value-use="enc" class="button button-secondary">Generate Encryption Key</button>
        </div>

        <p>Total keys in durable storage: {@total_keys}</p>

        <%= if @keys == [] do %>
          <AdminComponents.empty_state
            title="No signing keys are stored"
            body="Create or import a key before relying on Lockspire for JWKS publication and ID token signing."
          />
        <% else %>
          <ul class="lockspire-admin-key-list">
            <%= for entry <- @keys do %>
              <li>
                <a href={key_show_path(entry.key.id)}>{entry.key.kid}</a>
                <span>{entry.key.alg} / {entry.key.kty}</span>
                <span>Use: {entry.key.use}</span>
                <AdminComponents.status_badge status={entry.key.status} />
                <span>JWKS {if entry.publishable, do: "visible", else: "hidden"}</span>
                <span>Next action {format_actions(entry.next_actions)}</span>
              </li>
            <% end %>
          </ul>
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

  defp format_actions([]), do: "None"

  defp format_actions(actions) do
    Enum.map_join(actions, ", ", &(&1 |> Atom.to_string() |> String.capitalize()))
  end
end
