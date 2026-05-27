defmodule AdoptionDemo.Lockspire.AccountResolver do
  @moduledoc false

  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(conn_or_socket, context) do
    case current_account(conn_or_socket) do
      nil -> {:redirect, redirect_for_login(conn_or_socket, context)}
      account -> {:ok, account}
    end
  end

  @impl true
  def resolve_account(account_reference, _context) do
    case AdoptionDemo.Accounts.get_by_id(normalize_account_id(account_reference)) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @impl true
  def build_claims(account, _context) when is_map(account) do
    subject = "user:" <> account.id

    claims = %{
      "email" => account.email,
      "name" => account.name,
      "tenant_id" => account.tenant_id,
      "tenant_name" => account.tenant_name
    }

    {:ok, %Claims{subject: subject, id_token: claims, userinfo: claims}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/login",
      return_to: Map.get(context, :return_to) || "/",
      params:
        %{}
        |> maybe_put("interaction_id", Map.get(context, :interaction_id))
        |> maybe_put("return_to", Map.get(context, :return_to))
    }
  end

  @impl true
  def verify_backchannel_user_code(_subject_id, "000000", _context), do: :ok

  def verify_backchannel_user_code(_subject_id, _user_code, _context),
    do: {:error, :invalid_user_code}

  defp current_account(%Plug.Conn{} = conn) do
    conn.assigns[:current_account]
  end

  defp current_account(%Phoenix.LiveView.Socket{} = socket) do
    socket.assigns[:current_account]
  end

  defp current_account(_other), do: nil

  defp normalize_account_id("user:" <> account_id), do: account_id
  defp normalize_account_id(account_reference), do: to_string(account_reference)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
