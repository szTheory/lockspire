defmodule Lockspire.Web.EndSessionController do
  @moduledoc """
  Thin `/end_session` delivery adapter for OIDC RP-initiated logout.
  """

  use Phoenix.Controller, formats: [:html]

  alias Lockspire.Config
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.EndSession
  alias Lockspire.Protocol.LogoutPropagation
  alias Lockspire.Web.EndSessionHTML

  @token_salt "lockspire_logout"
  @token_max_age 600

  def show(conn, params), do: handle_end_session(conn, params)
  def create(conn, params), do: handle_end_session(conn, params)

  def complete(conn, %{"token" => token}) when is_binary(token) do
    case Phoenix.Token.verify(Lockspire.Web.Endpoint, @token_salt, token, max_age: @token_max_age) do
      {:ok, payload} when is_map(payload) ->
        payload
        |> complete_logout()
        |> case do
          {:ok, result} ->
            redirect_or_render_logged_out(conn, result.post_logout_redirect_uri, result.state)

          {:error, _reason} ->
            redirect_or_render_logged_out(
              conn,
              payload["post_logout_redirect_uri"] || payload[:post_logout_redirect_uri],
              payload["state"] || payload[:state]
            )
        end

      {:error, _reason} ->
        redirect_or_render_logged_out(conn, nil, nil)
    end
  end

  def complete(conn, _params) do
    redirect_or_render_logged_out(conn, nil, nil)
  end

  defp handle_end_session(conn, params) do
    case EndSession.validate(%{params: params}) do
      {:ok, %EndSession.Result{} = result} ->
        completion_token = sign_completion_token(result)
        completion_url = append_query_param(Config.mount_path() <> "/end_session/complete", "token", completion_token)
        redirect(conn, to: host_logout_destination(conn, result, completion_url))

      {:error, %EndSession.Error{} = error} ->
        render_browser_error(conn, error)
    end
  end

  defp host_logout_destination(conn, %EndSession.Result{} = result, completion_url) do
    resolver = Lockspire.account_resolver!()

    context = %{
      account_id: result.account_id,
      sid: result.sid,
      return_to: completion_url
    }

    if function_exported?(resolver, :redirect_for_logout, 2) do
      %InteractionResult{} = interaction_result = resolver.redirect_for_logout(conn, context)

      interaction_result
      |> Map.put(:return_to, completion_url)
      |> redirect_destination()
    else
      append_query_param(Config.logout_path(), "return_to", completion_url)
    end
  end

  defp redirect_or_render_logged_out(conn, post_logout_redirect_uri, state)
       when is_binary(post_logout_redirect_uri) and post_logout_redirect_uri != "" do
    redirect(conn, external: append_query_param(post_logout_redirect_uri, "state", state))
  end

  defp redirect_or_render_logged_out(conn, _post_logout_redirect_uri, _state) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, logged_out_page())
  end

  defp logged_out_page do
    EndSessionHTML.logged_out(%{})
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp render_browser_error(conn, %EndSession.Error{} = error) do
    conn
    |> put_status(error.status)
    |> put_resp_content_type("text/html")
    |> send_resp(error.status, browser_error_page(error))
  end

  defp browser_error_page(%EndSession.Error{} = error) do
    description = Plug.HTML.html_escape_to_iodata(error.error_description)
    reason = Plug.HTML.html_escape_to_iodata(to_string(error.reason_code))

    [
      "<!doctype html><html><head><meta charset=\"utf-8\"><title>Logout Error</title></head><body>",
      "<main><h1>Logout request rejected</h1><p>",
      description,
      "</p><p>Reason: <code>",
      reason,
      "</code></p></main></body></html>"
    ]
    |> IO.iodata_to_binary()
  end

  defp sign_completion_token(%EndSession.Result{} = result) do
    Phoenix.Token.sign(Lockspire.Web.Endpoint, @token_salt, %{
      event_id: Ecto.UUID.generate(),
      sid: result.sid,
      post_logout_redirect_uri: result.post_logout_redirect_uri,
      state: result.state
    })
  end

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

  defp complete_logout(payload) when is_map(payload) do
    LogoutPropagation.complete(%{
      event_id: payload["event_id"] || payload[:event_id],
      sid: payload["sid"] || payload[:sid],
      post_logout_redirect_uri:
        payload["post_logout_redirect_uri"] || payload[:post_logout_redirect_uri],
      state: payload["state"] || payload[:state]
    })
  end
end
