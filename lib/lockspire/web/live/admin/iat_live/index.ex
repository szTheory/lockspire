defmodule Lockspire.Web.Live.Admin.IatLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Initial Access Tokens",
       current_section: :dcr,
       tokens: load_tokens()
     )}
  end

  @impl true
  def handle_event("revoke", %{"id" => id}, socket) do
    case InitialAccessTokens.revoke_iat(String.to_integer(id)) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "IAT revoked successfully.")
         |> assign(tokens: load_tokens())}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to revoke IAT.")}
    end
  end

  defp load_tokens do
    {:ok, tokens} = InitialAccessTokens.list_iats()
    tokens
  end

  def iat_status(token) do
    cond do
      token.revoked_at != nil ->
        :revoked

      token.used_at != nil ->
        :used

      token.expires_at != nil and DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt ->
        :expired

      true ->
        :active
    end
  end

  def iat_new_path, do: Lockspire.mount_path() <> "/admin/iats/new"
end
