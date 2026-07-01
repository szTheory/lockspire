defmodule Lockspire.Web.Live.Admin.IatLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Redaction

  @revoke_confirm_error "Select the confirmation checkbox to revoke this initial access token."
  @revoke_failure_error "Initial access token revocation could not be confirmed. Reload this Configure workflow before retrying."

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Initial Access Tokens",
       current_section: :dcr,
       tokens: load_tokens(),
       revoke_error: nil,
       revoke_notice: nil
     )}
  end

  @impl true
  def handle_event(
        "confirm_revoke_iat",
        %{"revoke" => %{"confirm" => "true", "id" => id}},
        socket
      ) do
    case parse_revoke_id(id) do
      {:ok, token_id} ->
        revoke_iat(token_id, socket)

      :error ->
        {:noreply, assign(socket, revoke_error: @revoke_failure_error, revoke_notice: nil)}
    end
  end

  def handle_event("confirm_revoke_iat", _params, socket) do
    {:noreply, assign(socket, revoke_error: @revoke_confirm_error, revoke_notice: nil)}
  end

  defp revoke_iat(token_id, socket) do
    case InitialAccessTokens.revoke_iat(token_id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "IAT revoked successfully.")
         |> assign(
           tokens: load_tokens(),
           revoke_error: nil,
           revoke_notice:
             "Initial access token revoked. Partners using it can no longer dynamically register clients."
         )}

      {:error, _reason} ->
        {:noreply, assign(socket, revoke_error: @revoke_failure_error, revoke_notice: nil)}
    end
  end

  defp parse_revoke_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {token_id, ""} when token_id > 0 -> {:ok, token_id}
      _result -> :error
    end
  end

  defp parse_revoke_id(_id), do: :error

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

  defp iat_inventory_status_counts(tokens) do
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

  defp iat_revoke_confirmation_copy(_token),
    do: "Partners using this intake token can no longer dynamically register clients with it."

  defp iat_revoke_error(nil), do: []
  defp iat_revoke_error(error), do: [error]

  def token_timestamp(token), do: token.revoked_at || token.used_at || token.expires_at

  def redacted_handle(_type, nil), do: "Not recorded"
  def redacted_handle(type, value), do: Redaction.handle(type, value)

  def formatted_timestamp(nil), do: "Not recorded"

  def formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  def formatted_timestamp(value), do: to_string(value)

  def iat_new_path, do: Lockspire.mount_path() <> "/admin/iats/new"
end
