defmodule Lockspire.Web.Live.Admin.IatLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Redaction

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

  def iat_metrics(tokens) do
    %{
      active: Enum.count(tokens, &(iat_status(&1) == :active)),
      used: Enum.count(tokens, &(iat_status(&1) == :used)),
      expired: Enum.count(tokens, &(iat_status(&1) == :expired)),
      revoked: Enum.count(tokens, &(iat_status(&1) == :revoked)),
      total: length(tokens)
    }
  end

  def token_title(token), do: "Initial access token #{redacted_handle(:iat, token.id)}"

  def usage_label(%{single_use: true}), do: "Single-use"
  def usage_label(_token), do: "Multi-use"

  def token_timestamp(token), do: token.revoked_at || token.used_at || token.expires_at

  def redacted_handle(_type, nil), do: "Not recorded"
  def redacted_handle(type, value), do: Redaction.handle(type, value)

  def formatted_timestamp(nil), do: "Not recorded"

  def formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  def formatted_timestamp(value), do: to_string(value)

  def iat_new_path, do: Lockspire.mount_path() <> "/admin/iats/new"
end
