defmodule Lockspire.Web.Live.Admin.IatLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Redaction

  @revoke_confirm_error "Select the checkbox to confirm revoking this app setup token."
  @revoke_failure_error "Lockspire could not confirm revocation. Reload the token list to check its status before retrying."
  @inventory_failure_error "Lockspire could not load app setup tokens. Reload to try again."

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "App setup tokens",
        current_section: :dcr,
        tokens: [],
        inventory_state: :loading,
        inventory_counts: nil,
        inventory_error: nil,
        revoke_error: nil,
        revoke_error_token_id: nil,
        revoke_notice: nil
      )

    {:ok, load_inventory(socket)}
  end

  @impl true
  def handle_event("reload_iats", _params, socket) do
    {:noreply,
     socket
     |> assign(revoke_error: nil, revoke_error_token_id: nil, revoke_notice: nil)
     |> load_inventory()}
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
        {:noreply, revoke_failure(socket)}
    end
  end

  def handle_event("confirm_revoke_iat", %{"revoke" => %{"id" => id}}, socket) do
    with {:ok, token_id} <- parse_revoke_id(id),
         true <-
           Enum.any?(socket.assigns.tokens, &(&1.id == token_id and iat_status(&1) == :active)) do
      {:noreply,
       assign(socket,
         revoke_error: @revoke_confirm_error,
         revoke_error_token_id: token_id,
         revoke_notice: nil
       )}
    else
      _result -> {:noreply, revoke_failure(socket)}
    end
  end

  def handle_event("confirm_revoke_iat", _params, socket) do
    {:noreply, revoke_failure(socket)}
  end

  defp revoke_iat(token_id, socket) do
    case InitialAccessTokens.revoke_iat(token_id) do
      :ok ->
        updated_socket =
          load_inventory(assign(socket, revoke_error: nil, revoke_error_token_id: nil))

        revoke_notice =
          if updated_socket.assigns.inventory_state == :loaded do
            "The app setup token was revoked. Apps can no longer use it to register."
          else
            "The app setup token was revoked, but the list could not refresh. Reload to confirm its status."
          end

        {:noreply,
         updated_socket
         |> put_flash(:info, "App setup token revoked.")
         |> assign(revoke_notice: revoke_notice)}

      {:error, _reason} ->
        {:noreply, revoke_failure(socket)}
    end
  end

  defp revoke_failure(socket) do
    assign(socket,
      revoke_error: @revoke_failure_error,
      revoke_error_token_id: nil,
      revoke_notice: nil
    )
  end

  defp parse_revoke_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {token_id, ""} when token_id > 0 -> {:ok, token_id}
      _result -> :error
    end
  end

  defp parse_revoke_id(_id), do: :error

  defp load_inventory(socket) do
    case safely_list_iats() do
      {:ok, tokens} ->
        assign(socket,
          tokens: tokens,
          inventory_state: :loaded,
          inventory_counts: iat_inventory_status_counts(tokens),
          inventory_error: nil
        )

      {:error, _reason} ->
        assign(socket,
          tokens: [],
          inventory_state: :unavailable,
          inventory_counts: nil,
          inventory_error: @inventory_failure_error
        )
    end
  end

  defp safely_list_iats do
    case InitialAccessTokens.list_iats() do
      {:ok, tokens} when is_list(tokens) -> {:ok, tokens}
    end
  rescue
    _exception -> {:error, :unavailable}
  catch
    _kind, _reason -> {:error, :unavailable}
  end

  def iat_status(token) do
    InitialAccessTokens.lifecycle_status(token)
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

  def token_title(token), do: "App setup token #{redacted_handle(:iat, token.id)}"

  def usage_label(%{single_use: true}), do: "Single-use"
  def usage_label(_token), do: "Multi-use"

  defp iat_revoke_confirmation_copy(_token),
    do: "Apps can no longer use this token to register."

  defp iat_revoke_error(error, token_id, token_id) when not is_nil(error), do: [error]
  defp iat_revoke_error(_error, _error_token_id, _token_id), do: []

  def token_timestamp(token),
    do: token.revoked_at || token.used_at || token.updated_at || token.inserted_at

  def redacted_handle(_type, nil), do: "Not recorded"
  def redacted_handle(type, value), do: Redaction.handle(type, value)

  def formatted_timestamp(nil), do: "Not recorded"

  def formatted_timestamp(%DateTime{} = value),
    do: value

  def formatted_timestamp(value), do: to_string(value)

  def iat_new_path, do: Lockspire.mount_path() <> "/admin/iats/new"
end
