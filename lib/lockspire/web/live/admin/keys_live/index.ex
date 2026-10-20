defmodule Lockspire.Web.Live.Admin.KeysLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.KeysLive.Protection
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Keys",
       current_section: :keys,
       keys: [],
       inventory_state: :loading,
       key_protection: nil,
       total_keys: nil,
       lifecycle_metrics: nil,
       generation_error: nil,
       generation_notice: nil,
       generated_key_path: nil
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
       generation_notice: nil,
       generated_key_path: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero body="Manage keys used to sign tokens or decrypt encrypted authorization requests." />
      <section :if={@key_protection} class="lockspire-admin-key-protection" aria-label="Key protection">
        <AdminComponents.decision_summary>
          <:item label="Key protection" value={@key_protection.value} tone={@key_protection.tone} detail={@key_protection.detail}>
            <p :if={@key_protection.command}><code>{@key_protection.command}</code></p>
          </:item>
        </AdminComponents.decision_summary>
      </section>
      <section class="lockspire-admin-key-inventory" aria-label="Key inventory">
        <AdminComponents.metric_grid :if={@inventory_state == :loaded}>
          <AdminComponents.summary_stat value={@lifecycle_metrics.active} label="Active" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.upcoming} label="Prepared (upcoming)" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retiring} label="Retiring" />
          <AdminComponents.summary_stat value={@lifecycle_metrics.retired} label="Retired" />
        </AdminComponents.metric_grid>
        <details class="lockspire-admin-help-disclosure">
          <summary>How key states work</summary>
          <div>
            <p><strong>Active:</strong> Used for signing tokens or decrypting requests, according to the key's use.</p>
            <p><strong>Prepared (upcoming):</strong> Created but not active. Publish the key so apps can recognize it, then activate it when ready.</p>
            <p><strong>Retiring:</strong> Replaced by a newer key. Still available while apps transition.</p>
            <p><strong>Retired:</strong> No longer published to apps.</p>
            <p>Counts include both signing and encryption keys. Each record identifies its use.</p>
          </div>
        </details>
        <div class="lockspire-admin-key-generation">
          <p>Create a signing key for initial setup or to replace your current key. Generation prepares it; publishing and activation are separate steps.</p>
          <AdminComponents.action_group class="lockspire-admin-action-bar-compact">
            <:primary>
              <AdminComponents.admin_button phx-click="generate" phx-value-use="sig" phx-disable-with="Generating signing key…" variant={:primary} disabled={@inventory_state != :loaded}>
                Generate signing key
              </AdminComponents.admin_button>
            </:primary>
          </AdminComponents.action_group>
          <details class="lockspire-admin-help-disclosure">
            <summary>Encryption keys</summary>
            <div>
              <p>Use an encryption key when apps send encrypted authorization requests to Lockspire. It decrypts those requests; it does not sign tokens. Generate one for initial setup or replacement, then publish and activate it from its record.</p>
              <AdminComponents.admin_button phx-click="generate" phx-value-use="enc" phx-disable-with="Generating encryption key…" disabled={@inventory_state != :loaded}>
                Generate encryption key
              </AdminComponents.admin_button>
            </div>
          </details>
          <div :if={@generation_notice} class="lockspire-admin-key-generation__result">
            <p role="status">{@generation_notice}</p>
            <AdminComponents.admin_button :if={@generated_key_path} href={@generated_key_path}>Continue key setup</AdminComponents.admin_button>
          </div>
          <ul :if={@generation_error} class="lockspire-admin-errors" role="alert"><li>{@generation_error}</li></ul>
        </div>

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
                body="Generate a signing key before Lockspire can sign tokens for connected apps."
              />
            <% :loaded -> %>
              <AdminComponents.resource_list>
                <%= for entry <- @keys do %>
                  <AdminComponents.resource_item
                    href={key_show_path(entry.key.id)}
                    class="lockspire-admin-key-record"
                    title={"Key #{Redaction.handle(:kid, entry.key.kid)}"}
                    subtitle={"#{entry.key.alg} / #{entry.key.kty}"}
                  >
                    <:meta>
                      <span><strong>Use</strong><AdminComponents.long_value value={if entry.key.use == :sig, do: "Signing", else: "Encryption"} /></span>
                      <span :if={entry.key.published_at}><strong>Published</strong><AdminComponents.timestamp value={entry.key.published_at} /></span>
                      <span :if={entry.key.activated_at}><strong>Activated</strong><AdminComponents.timestamp value={entry.key.activated_at} /></span>
                      <span :if={entry.key.retiring_at}><strong>Retiring since</strong><AdminComponents.timestamp value={entry.key.retiring_at} /></span>
                      <span :if={entry.key.retired_at}><strong>Retired</strong><AdminComponents.timestamp value={entry.key.retired_at} /></span>
                      <span :if={entry.next_actions != []} class="lockspire-admin-key-record__next-step">
                        <AdminComponents.long_value value={key_next_action_summary(entry)} />
                      </span>
                    </:meta>
                    <:status>
                      <AdminComponents.status_badge
                        status={entry.key.status}
                        title={key_status_title(entry.key.status)}
                      />
                      <span class="lockspire-admin-help">
                        {if entry.publishable, do: "Published to connected apps", else: "Not published to connected apps"}
                      </span>
                    </:status>
                  </AdminComponents.resource_item>
                <% end %>
              </AdminComponents.resource_list>
          <% end %>
        </div>
      </section>
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
      generation_notice: nil,
      generated_key_path: nil
    )
    |> assign_inventory_result(load_keys())
    |> assign(key_protection: load_key_protection())
  end

  # Only the status read is guarded: any raise or exit there reads as could-not-check, the safe
  # direction. Nothing is logged because the message could carry config text. Summarizing runs
  # unguarded so a defect in it is not silently hidden.
  defp load_key_protection do
    Protection.summarize(read_encryption_status())
  end

  defp read_encryption_status do
    Admin.encryption_status()
  rescue
    _exception -> :error
  catch
    :exit, _reason -> :error
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

    case safe_generate_key(use_atom) do
      {:ok, %{key: %{id: generated_id}}} ->
        socket = assign(socket, key_protection: load_key_protection())

        case load_keys() do
          {:ok, keys} ->
            socket = assign_inventory_result(socket, {:ok, keys})

            if Enum.any?(keys, &(&1.key.id == generated_id)) do
              {:noreply,
               assign(socket,
                 generation_error: nil,
                 generation_notice: "#{key_label} key generated. It is not active yet.",
                 generated_key_path: key_show_path(generated_id)
               )}
            else
              {:noreply,
               assign(socket,
                 generation_error:
                   "The generated key was not present in the refreshed inventory. Reload before retrying.",
                 generation_notice: nil,
                 generated_key_path: nil
               )}
            end

          {:error, _reason} ->
            socket = assign_inventory_result(socket, {:error, :read_failed})

            {:noreply,
             assign(socket,
               generation_error:
                 "The key may have been generated, but Lockspire could not confirm it in the inventory. Reload before retrying.",
               generation_notice: nil,
               generated_key_path: nil
             )}
        end

      {:error, :key_encryption_not_configured} ->
        {:noreply,
         assign(socket,
           generation_error: missing_key_encryption_error(key_label),
           generation_notice: nil,
           generated_key_path: nil
         )}

      {:error, :invalid_key_encryption_config} ->
        {:noreply,
         assign(socket,
           generation_error: invalid_key_encryption_error(),
           generation_notice: nil,
           generated_key_path: nil
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           generation_error: "The #{String.downcase(key_label)} key could not be generated.",
           generation_notice: nil,
           generated_key_path: nil
         )}
    end
  end

  # Invalid key-encryption key config raises ArgumentError when the key set is resolved. The
  # message can carry config text, so it is never echoed, logged or flashed.
  defp safe_generate_key(use_atom) do
    Admin.generate_key(use_atom)
  rescue
    ArgumentError -> {:error, :invalid_key_encryption_config}
  end

  defp invalid_key_encryption_error do
    "The key-encryption key setup is not valid, so Lockspire cannot create a key. " <>
      "Run mix lockspire.doctor.key_encryption for details."
  end

  defp missing_key_encryption_error("Signing") do
    "No key-encryption key is set up, so Lockspire cannot create a signing key. " <>
      "Lockspire will not store private keys unencrypted. " <>
      "Create one with mix lockspire.gen.kek, add it to your app's configuration, and restart the app."
  end

  defp missing_key_encryption_error("Encryption") do
    "No key-encryption key is set up, so Lockspire cannot create an encryption key. " <>
      "Lockspire will not store private keys unencrypted. " <>
      "Create one with mix lockspire.gen.kek, add it to your app's configuration, and restart the app."
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

  defp key_next_action_summary(%{next_actions: [:publish]}),
    do: "Publish key so apps can prepare to trust it"

  defp key_next_action_summary(%{next_actions: [:activate]}),
    do: "Activate key for connected apps to use"

  defp key_next_action_summary(%{next_actions: [:retire]}),
    do: "Retire key to stop publishing it"

  defp key_status_title(:active), do: "Current key selected for signing or decryption operations."

  defp key_status_title(:upcoming),
    do: "Prepared key; publish it so apps can recognize it before activation."

  defp key_status_title(:retiring),
    do: "Previous key remains available while apps switch to its replacement."

  defp key_status_title(:retired), do: "Retired key is no longer shared with connected apps."
  defp key_status_title(_status), do: "Signing key status."
end
