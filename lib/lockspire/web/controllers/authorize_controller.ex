defmodule Lockspire.Web.AuthorizeController do
  @moduledoc """
  Thin `/authorize` delivery adapter.
  """

  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Config
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AuthorizeHTML

  def show(conn, params) do
    case AuthorizationRequest.validate(params) do
      {:ok, %Validated{} = validated} ->
        with {:ok, subject_context} <- resolve_subject_context(conn, validated),
             outcome <-
               AuthorizationFlow.start_authorization(
                 validated,
                 subject_context,
                 protocol_store_opts()
               ) do
          handle_authorization_outcome(conn, outcome)
        else
          {:error, %Error{} = error} ->
            render_browser_error(conn, error, :internal_server_error)
        end

      {:browser_error, %Error{} = error} ->
        render_browser_error(conn, error, :bad_request)

      {:redirect_error, %Error{} = error} ->
        redirect(conn, external: redirect_location(error))
    end
  end

  defp handle_authorization_outcome(conn, {:login_required, interaction}) do
    resolver = Lockspire.account_resolver!()

    %InteractionResult{} =
      base_result =
      resolver.redirect_for_login(conn, %{
        interaction_id: interaction.interaction_id,
        return_to: consent_path(interaction.interaction_id)
      })

    login_result = %InteractionResult{
      base_result
      | return_to: consent_path(interaction.interaction_id),
        params:
          base_result.params
          |> Map.put("interaction_id", interaction.interaction_id)
    }

    redirect_to_result(conn, login_result)
  end

  defp handle_authorization_outcome(conn, {:redirect_error, %Error{} = error}) do
    redirect(conn, external: redirect_location(error))
  end

  defp handle_authorization_outcome(conn, {:consent_required, interaction}) do
    redirect(conn, to: consent_path(interaction.interaction_id))
  end

  defp handle_authorization_outcome(conn, {:consent_reused, redirect_uri}) do
    redirect(conn, external: redirect_uri)
  end

  defp handle_authorization_outcome(conn, {:error, reason}) do
    render_browser_error(conn, protocol_error(reason), :bad_request)
  end

  defp resolve_subject_context(conn, %Validated{} = validated) do
    resolver = Lockspire.account_resolver!()

    context = %Lockspire.Host.Context{
      interaction_id: nil,
      return_to: consent_path("pending"),
      client_id: validated.client_id,
      scopes: validated.scopes
    }

    case resolver.resolve_current_account(conn, context) do
      {:ok, account} ->
        case resolver.build_claims(account, context) do
          {:ok, %Claims{} = claims} ->
            {:ok,
             %{
               subject_id: claims.subject,
               auth_time: account_auth_time(account),
               ui_required: account_ui_required(account)
             }}

          {:error, _reason} ->
            {:error,
             protocol_error(
               :account_claims_failed,
               "Unable to build account claims for the authorization request"
             )}
        end

      {:redirect, _result} ->
        {:ok, nil}

      {:error, _reason} ->
        {:error,
         protocol_error(:account_resolution_failed, "Unable to resolve the current account")}
    end
  end

  defp consent_path(interaction_id) do
    Lockspire.mount_path() <> "/consent/" <> interaction_id
  end

  defp redirect_to_result(conn, %InteractionResult{} = result) do
    destination =
      result.login_path
      |> append_query_param("return_to", result.return_to)
      |> append_query_params(result.params)

    redirect(conn, to: destination)
  end

  defp redirect_location(%Error{} = error) do
    uri = URI.parse(error.redirect_uri)
    existing_params = URI.decode_query(uri.query || "")

    oauth_params =
      %{
        "error" => error.error,
        "error_description" => error.error_description,
        "state" => error.state,
        "iss" => Config.issuer!()
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    uri
    |> Map.put(:query, URI.encode_query(Map.merge(existing_params, oauth_params)))
    |> URI.to_string()
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

  defp render_browser_error(conn, %Error{} = error, status) do
    conn
    |> put_status(status)
    |> put_resp_content_type("text/html")
    |> send_resp(status, AuthorizeHTML.error_page(error))
  end

  defp protocol_error(reason_code, description \\ "Unable to continue the authorization flow") do
    %Error{
      error: "server_error",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp protocol_store_opts do
    [
      interaction_store: Repository,
      consent_store: Repository,
      token_store: Repository
    ]
  end

  defp account_auth_time(account) when is_map(account),
    do: Map.get(account, :auth_time, Map.get(account, "auth_time"))

  defp account_auth_time(_account), do: nil

  defp account_ui_required(account) when is_map(account),
    do: Map.get(account, :ui_required, Map.get(account, "ui_required"))

  defp account_ui_required(_account), do: nil
end
