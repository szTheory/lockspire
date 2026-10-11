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
       page_title: "Key detail",
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
           action_notice: key_transition_notice(:published),
           action_error: nil
         )}

      {:error, :already_published} ->
        {:noreply,
         assign(socket,
           action_error: "This key is already published. Review its current JWKS state below.",
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
           action_notice: key_transition_notice(:activated),
           action_error: nil
         )}

      {:error, :not_published} ->
        {:noreply,
         transition_error(socket, "Publish the upcoming key before cutover activation.")}

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
       action_error: "Confirm activation before changing the active signer.",
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
           action_notice: key_transition_notice(:retired),
           action_error: nil
         )}

      {:error, :already_retired} ->
        {:noreply,
         assign(socket,
           action_error: "This key is already retired. Review its current JWKS state below.",
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
       action_error: "Confirm retirement before removing publication overlap.",
       action_notice: nil
     )}
  end

  @impl true
  def render(%{detail_state: state} = assigns) when state != :loaded do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title={detail_title(@detail_state)}
        body={detail_body(@detail_state)}
      >
        <:summary>
          <span>
            Selected key
            <AdminComponents.long_value value={@selected_key_handle} kind={:id} />
          </span>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.section_card title="Key detail status">
        <p :if={@detail_state == :loading} role="status">Loading signing key details…</p>

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
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Review key lifecycle"
        body="Review public key metadata, publication state, and lifecycle consequences without exposing non-public key material."
      />

      <AdminComponents.section_card
        title={@key_detail.key.handle}
        subtitle="Check public metadata, current JWKS availability, and the supported next action. Only public key metadata is shown here."
      >
        <AdminComponents.description_list>
          <:item label="Status">
            <AdminComponents.status_badge
              status={@key_detail.key.status}
              title={key_status_title(@key_detail.key.status)}
            />
          </:item>
          <:item label="Key handle">
            <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
          </:item>
          <:item label="Database handle">
            <AdminComponents.long_value value={@key_detail.key.database_handle} kind={:id} />
          </:item>
          <:item label="Algorithm"><code>{@key_detail.key.alg}</code></:item>
          <:item label="Key type"><code>{@key_detail.key.kty}</code></:item>
          <:item label="Use"><code>{@key_detail.key.use}</code></:item>
          <:item label="Served in JWKS">
            <strong>{jwks_state_label(@key_detail.publishable)}</strong>
          </:item>
          <:item label="Next safe action">
            <AdminComponents.long_value value={key_next_action_summary(@key_detail)} kind={:text} />
          </:item>
          <:item label="Published at"><AdminComponents.timestamp value={@key_detail.key.published_at} /></:item>
          <:item label="Activated at"><AdminComponents.timestamp value={@key_detail.key.activated_at} /></:item>
          <:item label="Retiring at"><AdminComponents.timestamp value={@key_detail.key.retiring_at} /></:item>
          <:item label="Retired at"><AdminComponents.timestamp value={@key_detail.key.retired_at} /></:item>
        </AdminComponents.description_list>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Public JWK metadata"
        subtitle="Only public members are shown here. Non-public key material stays hidden."
      >
        <AdminComponents.description_list>
          <:item label="kid">
            <AdminComponents.long_value value={@key_detail.key.public_jwk["kid"]} kind={:id} />
          </:item>
          <:item label="alg"><code>{@key_detail.key.public_jwk["alg"]}</code></:item>
          <:item label="kty"><code>{@key_detail.key.public_jwk["kty"]}</code></:item>
          <:item label="use"><code>{@key_detail.key.public_jwk["use"]}</code></:item>
        </AdminComponents.description_list>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Lifecycle actions"
        subtitle="Publish, activate, and retire remain separate commands so rollover state stays truthful."
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
  defp detail_title(:missing), do: "Signing key not found"
  defp detail_title(:error), do: "Signing key details are unavailable"
  defp detail_title(_state), do: "Signing key details are unavailable"

  defp detail_body(:loading), do: "Lockspire is loading this signing key from durable storage."

  defp detail_body(:missing),
    do:
      "No signing key matches the selected safe handle. Return to the inventory to choose another key."

  defp detail_body(:error),
    do:
      "Lockspire could not read this signing key. The selected handle is retained, and no missing-key or lifecycle claim is shown."

  defp detail_body(_state), do: "Lockspire could not read this signing key."

  defp jwks_state_label(true), do: "Served in JWKS"
  defp jwks_state_label(false), do: "Not served in JWKS"

  defp key_status_title(:active), do: "Current key selected for signing or decryption operations."
  defp key_status_title(:upcoming), do: "Prepared key; publish it before activating the signer."
  defp key_status_title(:retiring), do: "Previous key remains served during retirement overlap."
  defp key_status_title(:retired), do: "Retired key is not included in the served JWKS."
  defp key_status_title(_status), do: "Signing-key lifecycle state."

  defp key_next_action_summary(%{next_actions: [:publish]}),
    do: "Publish key for verification overlap"

  defp key_next_action_summary(%{next_actions: [:activate]}),
    do: "Activate key for signer cutover"

  defp key_next_action_summary(%{next_actions: [:retire]}),
    do: "Retire key after verifier overlap"

  defp key_next_action_summary(%{next_actions: []}), do: "No lifecycle action available"

  defp key_transition_notice(:published),
    do: "Key is now served in JWKS; the current signer remains active."

  defp key_transition_notice(:activated),
    do: "Key is now the active signer, and the previous signer moved to retiring overlap."

  defp key_transition_notice(:retired), do: "Key is no longer served in JWKS."
end
