defmodule Lockspire.Web.Live.Admin.IatLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Redaction

  @revoke_confirm_error "Select the checkbox to confirm revoking this Initial Access Token."
  @revoke_failure_error "Lockspire could not confirm revocation of this Initial Access Token. Reload the inventory to check its status before retrying."
  @inventory_failure_error "The Initial Access Token inventory is unavailable. Reload the inventory to try again."

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Initial Access Tokens",
        current_section: :dcr,
        tokens: [],
        inventory_state: :loading,
        inventory_counts: nil,
        inventory_error: nil,
        revoke_error: nil,
        revoke_notice: nil
      )

    {:ok, load_inventory(socket)}
  end

  @impl true
  def handle_event("reload_iats", _params, socket) do
    {:noreply,
     socket
     |> assign(revoke_error: nil, revoke_notice: nil)
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
        {:noreply, assign(socket, revoke_error: @revoke_failure_error, revoke_notice: nil)}
    end
  end

  def handle_event("confirm_revoke_iat", _params, socket) do
    {:noreply, assign(socket, revoke_error: @revoke_confirm_error, revoke_notice: nil)}
  end

  defp revoke_iat(token_id, socket) do
    case InitialAccessTokens.revoke_iat(token_id) do
      :ok ->
        updated_socket = load_inventory(assign(socket, revoke_error: nil))

        revoke_notice =
          if updated_socket.assigns.inventory_state == :loaded do
            "The Initial Access Token was revoked. Partners can no longer use it to register clients."
          else
            "The Initial Access Token was revoked, but the inventory could not be refreshed. Reload to confirm its updated status."
          end

        {:noreply,
         updated_socket
         |> put_flash(:info, "Initial Access Token revoked.")
         |> assign(revoke_notice: revoke_notice)}

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
      {:error, reason} -> {:error, reason}
      _unexpected_result -> {:error, :unavailable}
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

  def token_title(token), do: "Initial Access Token #{redacted_handle(:iat, token.id)}"

  def usage_label(%{single_use: true}), do: "Single-use"
  def usage_label(_token), do: "Multi-use"

  defp iat_revoke_confirmation_copy(_token),
    do: "Partners can no longer use this Initial Access Token to register clients."

  defp iat_revoke_error(nil), do: []
  defp iat_revoke_error(error), do: [error]

  def token_timestamp(token),
    do: token.revoked_at || token.used_at || token.updated_at || token.inserted_at

  def redacted_handle(_type, nil), do: "Not recorded"
  def redacted_handle(type, value), do: Redaction.handle(type, value)

  def formatted_timestamp(nil), do: "Not recorded"

  def formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  def formatted_timestamp(value), do: to_string(value)

  def iat_new_path, do: Lockspire.mount_path() <> "/admin/iats/new"
end
