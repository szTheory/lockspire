defmodule <%= @authorized_apps_controller_module %> do
  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Admin.Consents
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  def index(conn, _params) do
    with {:ok, subject_context} <- resolve_subject_context(conn),
         {:ok, consents} <- Consents.list_consents_for_account(subject_context.subject_id) do
      render(conn, :index,
        consents: consents,
        page_title: "Authorized Apps"
      )
    else
      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> text("Unable to load authorized apps")
    end
  end

  def delete(conn, %{"id" => grant_id}) do
    with {:ok, subject_context} <- resolve_subject_context(conn),
         {grant_id, ""} <- Integer.parse(grant_id),
         {:ok, %{grant: grant}} <- Consents.get_consent(grant_id),
         :ok <- ensure_subject_owns_grant(grant, subject_context.subject_id),
         {:ok, _revoked} <-
           Consents.revoke_consent(grant_id, %{
             revoked_by: subject_context.subject_id,
             revoked_reason: "account_revoked"
           }) do
      conn
      |> put_flash(:info, "Authorized app access revoked.")
      |> redirect(to: authorized_apps_path())
    else
      {:redirect, %InteractionResult{} = result} ->
        redirect(conn, to: redirect_destination(result))

      :error ->
        conn
        |> put_flash(:error, "Authorized app could not be found.")
        |> redirect(to: authorized_apps_path())

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Authorized app could not be found.")
        |> redirect(to: authorized_apps_path())

      {:error, :subject_mismatch} ->
        conn
        |> put_flash(:error, "That authorized app does not belong to the current account.")
        |> redirect(to: authorized_apps_path())

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Unable to revoke that authorized app.")
        |> redirect(to: authorized_apps_path())
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:error, "Authorized app could not be found.")
    |> redirect(to: authorized_apps_path())
  end

  defp resolve_subject_context(conn) do
    resolver = Lockspire.account_resolver!()

    context = %{return_to: authorized_apps_path()}

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        with {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
          {:ok, %{subject_id: claims.subject}}
        else
          {:error, reason} -> {:error, reason}
        end

      {:redirect, %InteractionResult{} = result} ->
        {:redirect, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_subject_owns_grant(%{account_id: account_id}, subject_id) when account_id == subject_id,
    do: :ok

  defp ensure_subject_owns_grant(_grant, _subject_id), do: {:error, :subject_mismatch}

  defp redirect_destination(%InteractionResult{} = result) do
    result.login_path
    |> append_query_param("return_to", result.return_to)
    |> append_query_params(result.params)
  end

  defp append_query_params(path, params) when is_map(params) do
    Enum.reduce(params, path, fn {key, value}, acc ->
      append_query_param(acc, key, value)
    end)
  end

  defp append_query_param(path, _key, nil), do: path
  defp append_query_param(path, _key, ""), do: path

  defp append_query_param(path, key, value) do
    separator = if String.contains?(path, "?"), do: "&", else: "?"
    path <> separator <> URI.encode_query(%{to_string(key) => value})
  end

  defp authorized_apps_path, do: "/authorized-apps"
end
