defmodule Lockspire.Web.Live.Admin.KeysLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.KeysLive.ActionComponent
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Key details",
       current_section: :keys,
       key_id: parse_id(id),
       selected_key_handle: safe_key_handle(parse_id(id)),
       detail_state: :loading,
       key_detail: nil,
       action_error: nil,
       action_notice: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    key_id = parse_id(Map.get(params, "id", socket.assigns.key_id))

    {:noreply,
     socket
     |> assign(
       key_id: key_id,
       selected_key_handle: safe_key_handle(key_id),
       detail_state: :loading,
       key_detail: nil,
       action_error: nil,
       action_notice: nil
     )
     |> load_key(key_id)}
  end

  @impl true
  def handle_event("retry_key_detail", _params, socket) do
    {:noreply,
     socket
     |> assign(action_error: nil, action_notice: nil, detail_state: :loading)
     |> load_key(socket.assigns.key_id)}
  end

  def handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket) do
    case Admin.publish_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         assign(socket,
           key_detail: key_detail,
           detail_state: :loaded,
           action_notice: key_transition_notice(:published, key_detail.key.use),
           action_error: nil
         )}

      {:error, :already_published} ->
        {:noreply,
         assign(socket,
           action_error:
             "This key is already shared with connected apps. Review its current status below.",
           action_notice: nil
         )}

      {:error, :invalid_state} ->
        {:noreply, transition_error(socket, "Only upcoming keys can be published.")}

      {:error, _reason} ->
        {:noreply,
         transition_error(socket, "Key could not be published. Its current details are retained.")}
    end
  end

  def handle_event("publish_key", _params, socket) do
    {:noreply,
     assign(socket,
       action_error: "Confirm publish before changing key visibility.",
       action_notice: nil
     )}
  end

  def handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket) do
    case Admin.activate_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         assign(socket,
           key_detail: key_detail,
           detail_state: :loaded,
           action_notice: key_transition_notice(:activated, key_detail.key.use),
           action_error: nil
         )}

      {:error, :not_published} ->
        {:noreply, transition_error(socket, "Publish the upcoming key before activating it.")}

      {:error, :invalid_state} ->
        {:noreply, transition_error(socket, "Only published upcoming keys can be activated.")}

      {:error, _reason} ->
        {:noreply,
         transition_error(socket, "Key could not be activated. Its current details are retained.")}
    end
  end

  def handle_event("activate_key", _params, socket) do
    {:noreply,
     assign(socket,
       action_error: activation_confirmation_error(socket.assigns.key_detail),
       action_notice: nil
     )}
  end

  def handle_event("retire_key", %{"retire" => %{"confirm" => "true"}}, socket) do
    case Admin.retire_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         assign(socket,
           key_detail: key_detail,
           detail_state: :loaded,
           action_notice: key_transition_notice(:retired, key_detail.key.use),
           action_error: nil
         )}

      {:error, :already_retired} ->
        {:noreply,
         assign(socket,
           action_error: "This key is already retired. Review its current status below.",
           action_notice: nil
         )}

      {:error, :invalid_state} ->
        {:noreply, transition_error(socket, "Only retiring keys can be retired.")}

      {:error, _reason} ->
        {:noreply,
         transition_error(socket, "Key could not be retired. Its current details are retained.")}
    end
  end

  def handle_event("retire_key", _params, socket) do
    {:noreply,
     assign(socket,
       action_error: "Confirm retirement before removing this key from the public list.",
       action_notice: nil
     )}
  end

  @impl true
  def render(%{detail_state: state} = assigns) when state != :loaded do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title={detail_title(@detail_state)}
        subtitle={detail_body(@detail_state)}
      >
        <p>
          Key ID:
          <AdminComponents.long_value value={@selected_key_handle} kind={:id} />
        </p>

        <ul :if={@action_error} class="lockspire-admin-errors" role="alert">
          <li>{@action_error}</li>
        </ul>

        <AdminComponents.action_group>
          <:primary>
            <AdminComponents.admin_button
              :if={@detail_state == :error}
              type="button"
              phx-click="retry_key_detail"
              phx-disable-with="Loading key details…"
            >
              Try loading key details again
            </AdminComponents.admin_button>
            <AdminComponents.admin_button href={keys_index_path()}>
              Return to key inventory
            </AdminComponents.admin_button>
          </:primary>
        </AdminComponents.action_group>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Key status"
        subtitle="Current status and the next available step."
      >
        <AdminComponents.description_list>
          <:item label="Status">
            <AdminComponents.status_badge
              status={@key_detail.key.status}
              title={key_status_title(@key_detail.key.status)}
            />
          </:item>
          <:item label="Key ID">
            <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
          </:item>
          <:item label="Published to connected apps">
            <strong>{jwks_state_label(@key_detail.publishable)}</strong>
          </:item>
          <:item :if={@key_detail.next_actions != []} label="Next step">
            <AdminComponents.long_value value={key_next_action_summary(@key_detail)} kind={:text} />
          </:item>
          <:item :if={@key_detail.key.published_at} label="Published at"><AdminComponents.timestamp value={@key_detail.key.published_at} /></:item>
          <:item :if={@key_detail.key.activated_at} label="Activated at"><AdminComponents.timestamp value={@key_detail.key.activated_at} /></:item>
          <:item :if={@key_detail.key.retiring_at} label="Retiring at"><AdminComponents.timestamp value={@key_detail.key.retiring_at} /></:item>
          <:item :if={@key_detail.key.retired_at} label="Retired at"><AdminComponents.timestamp value={@key_detail.key.retired_at} /></:item>
        </AdminComponents.description_list>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Public key settings"
        subtitle="Connected apps receive these settings when the key is published. Private key material stays hidden."
      >
        <AdminComponents.description_list>
          <:item label="Algorithm"><code>{@key_detail.key.alg}</code></:item>
          <:item label="Key type"><code>{@key_detail.key.kty}</code></:item>
          <:item label="Use">{key_use_label(@key_detail.key.use)}</:item>
        </AdminComponents.description_list>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@key_detail.next_actions != [] or !is_nil(@action_error) or !is_nil(@action_notice)}
        title="Key actions"
        subtitle="Publish a new key before activation; keep the previous key available while apps update."
      >
        <ActionComponent.lifecycle_actions
          key_detail={@key_detail}
          action_error={@action_error}
          action_notice={@action_notice}
        />
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_key(socket, nil),
    do: assign(socket, key_detail: nil, detail_state: :missing)

  defp load_key(socket, key_id) do
    case Admin.get_key(key_id) do
      {:ok, nil} -> assign(socket, key_detail: nil, detail_state: :missing)
      {:ok, key_detail} -> assign(socket, key_detail: key_detail, detail_state: :loaded)
      {:error, _reason} -> assign(socket, key_detail: nil, detail_state: :error)
    end
  end

  defp transition_error(socket, message),
    do: assign(socket, action_error: message, action_notice: nil)

  defp parse_id(value) when is_integer(value), do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> id
      _other -> nil
    end
  end

  defp parse_id(_value), do: nil

  defp safe_key_handle(key_id) when is_integer(key_id), do: Redaction.handle(:key, key_id)
  defp safe_key_handle(_key_id), do: "Not available"

  defp keys_index_path, do: Lockspire.mount_path() <> "/admin/keys"

  defp detail_title(:loading), do: "Loading key details"
  defp detail_title(:missing), do: "Key not found"
  defp detail_title(:error), do: "Key details are unavailable"
  defp detail_title(_state), do: "Key details are unavailable"

  defp detail_body(:loading), do: "Loading this key…"

  defp detail_body(:missing),
    do: "This key was not found. Return to the key list to choose another."

  defp detail_body(:error),
    do: "Lockspire could not load this key, so its current status is unknown."

  defp detail_body(_state), do: "Lockspire could not read this key."

  defp jwks_state_label(true), do: "Yes"
  defp jwks_state_label(false), do: "No"

  defp key_status_title(:active), do: "Current key selected for signing or decryption operations."

  defp key_status_title(:upcoming),
    do: "Prepared key; publish it so apps can recognize it before activation."

  defp key_status_title(:retiring),
    do: "Previous key remains available while apps switch to its replacement."

  defp key_status_title(:retired), do: "Retired key is no longer shared with connected apps."
  defp key_status_title(_status), do: "Key status."

  defp key_use_label(:sig), do: "Signing"
  defp key_use_label(:enc), do: "Encryption"
  defp key_use_label(_use), do: "Not recorded"

  defp key_next_action_summary(%{next_actions: [:publish], key: %{use: :enc}}),
    do: "Publish key so apps can prepare to encrypt authorization requests"

  defp key_next_action_summary(%{next_actions: [:publish]}),
    do: "Publish key so apps can prepare to trust it"

  defp key_next_action_summary(%{next_actions: [:activate], key: %{use: :enc}}),
    do: "Activate key for encrypted authorization requests"

  defp key_next_action_summary(%{next_actions: [:activate]}),
    do: "Activate key to sign new tokens"

  defp key_next_action_summary(%{next_actions: [:retire]}),
    do: "Retire key after apps switch to its replacement"

  defp key_next_action_summary(%{next_actions: []}), do: "No further action is available"

  defp activation_confirmation_error(%{key: %{use: :enc}}),
    do: "Confirm activation before changing the active encryption key."

  defp activation_confirmation_error(_detail),
    do: "Confirm activation before changing which key signs new tokens."

  defp key_transition_notice(:published, :enc),
    do: "This key is now shared with connected apps. The current encryption key remains active."

  defp key_transition_notice(:published, _use),
    do: "This key is now shared with connected apps. The current signing key remains active."

  defp key_transition_notice(:activated, :enc),
    do:
      "This key is now active for encrypted authorization requests. The previous key remains available to decrypt existing requests."

  defp key_transition_notice(:activated, _use),
    do: "This key now signs new tokens. The previous key remains available while apps switch."

  defp key_transition_notice(:retired, _use),
    do: "This key is no longer shared with connected apps."
end
