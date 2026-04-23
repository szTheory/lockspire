defmodule Lockspire.Web.Live.Admin.KeysLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
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
     |> assign(key_id: key_id, action_error: nil, action_notice: nil)
     |> load_key(key_id)}
  end

  @impl true
  def handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket) do
    case Admin.publish_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         assign(socket,
           key_detail: key_detail,
           action_notice: "Key published for verification overlap.",
           action_error: nil
         )}

      {:error, :already_published} ->
        {:noreply, assign(socket, action_error: "This upcoming key is already published.")}

      {:error, :invalid_state} ->
        {:noreply, assign(socket, action_error: "Only upcoming keys can be published.")}

      {:error, _reason} ->
        {:noreply, assign(socket, action_error: "Key could not be published.")}
    end
  end

  def handle_event("publish_key", _params, socket) do
    {:noreply, assign(socket, action_error: "Confirm publish before changing key visibility.")}
  end

  def handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket) do
    case Admin.activate_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         socket
         |> assign(
           key_detail: key_detail,
           action_notice: "Key activated. The prior signer is now retiring.",
           action_error: nil
         )
         |> load_key(socket.assigns.key_id)}

      {:error, :not_published} ->
        {:noreply,
         assign(socket, action_error: "Publish the upcoming key before cutover activation.")}

      {:error, :invalid_state} ->
        {:noreply, assign(socket, action_error: "Only published upcoming keys can be activated.")}

      {:error, _reason} ->
        {:noreply, assign(socket, action_error: "Key could not be activated.")}
    end
  end

  def handle_event("activate_key", _params, socket) do
    {:noreply,
     assign(socket, action_error: "Confirm activation before changing the active signer.")}
  end

  def handle_event("retire_key", %{"retire" => %{"confirm" => "true"}}, socket) do
    case Admin.retire_key(socket.assigns.key_id) do
      {:ok, key_detail} ->
        {:noreply,
         assign(socket,
           key_detail: key_detail,
           action_notice: "Key retired from publication overlap.",
           action_error: nil
         )}

      {:error, :already_retired} ->
        {:noreply, assign(socket, action_error: "This key is already retired.")}

      {:error, :invalid_state} ->
        {:noreply, assign(socket, action_error: "Only retiring keys can be retired.")}

      {:error, _reason} ->
        {:noreply, assign(socket, action_error: "Key could not be retired.")}
    end
  end

  def handle_event("retire_key", _params, socket) do
    {:noreply,
     assign(socket, action_error: "Confirm retirement before removing publication overlap.")}
  end

  @impl true
  def render(%{key_detail: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Signing key not found"
        body="Lockspire could not load that signing key from durable storage."
      />
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title={@key_detail.key.handle}
        subtitle="Key detail shows public metadata, lifecycle truth, and the next safe operator action."
      >
        <p>Status: <AdminComponents.status_badge status={@key_detail.key.status} /></p>
        <p>Key handle: <code>{@key_detail.key.handle}</code></p>
        <p>Database handle: <code>{@key_detail.key.database_handle}</code></p>
        <p>Algorithm: <code>{@key_detail.key.alg}</code></p>
        <p>Key type: <code>{@key_detail.key.kty}</code></p>
        <p>Use: <code>{@key_detail.key.use}</code></p>
        <p>Visible in JWKS: <code>{to_string(@key_detail.publishable)}</code></p>
        <p>Published at: <AdminComponents.timestamp value={@key_detail.key.published_at} /></p>
        <p>Activated at: <AdminComponents.timestamp value={@key_detail.key.activated_at} /></p>
        <p>Retiring at: <AdminComponents.timestamp value={@key_detail.key.retiring_at} /></p>
        <p>Retired at: <AdminComponents.timestamp value={@key_detail.key.retired_at} /></p>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Public JWK metadata"
        subtitle="Only public members are shown here. Private key material stays hidden."
      >
        <p>kid: <code>{@key_detail.key.public_jwk["kid"]}</code></p>
        <p>alg: <code>{@key_detail.key.public_jwk["alg"]}</code></p>
        <p>kty: <code>{@key_detail.key.public_jwk["kty"]}</code></p>
        <p>use: <code>{@key_detail.key.public_jwk["use"]}</code></p>
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

  defp load_key(socket, nil), do: assign(socket, key_detail: nil)

  defp load_key(socket, key_id) do
    case Admin.get_key(key_id) do
      {:ok, key_detail} -> assign(socket, key_detail: key_detail)
      {:error, _reason} -> assign(socket, key_detail: nil)
    end
  end

  defp parse_id(value) when is_integer(value), do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, _rest} -> id
      :error -> nil
    end
  end

  defp parse_id(_value), do: nil
end
