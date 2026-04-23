defmodule Lockspire.Web.AuthorizeController do
  @moduledoc """
  Thin `/authorize` delivery adapter.
  """

  use Phoenix.Controller, formats: [:html, :json]

  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Web.AuthorizeHTML

  def show(conn, params) do
    case AuthorizationRequest.validate(params) do
      {:ok, %Validated{} = validated} ->
        json(conn, %{
          status: "validated",
          request: %{
            client_id: validated.client_id,
            redirect_uri: validated.redirect_uri,
            scopes: validated.scopes,
            prompt: validated.prompt,
            state: validated.state,
            code_challenge_method: validated.code_challenge_method
          }
        })

      {:browser_error, %Error{} = error} ->
        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/html")
        |> send_resp(:bad_request, AuthorizeHTML.error_page(error))

      {:redirect_error, %Error{} = error} ->
        redirect(conn, external: redirect_location(error))
    end
  end

  defp redirect_location(%Error{} = error) do
    query =
      %{
        "error" => error.error,
        "error_description" => error.error_description,
        "state" => error.state
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
      |> URI.encode_query()

    uri = URI.parse(error.redirect_uri)
    existing_query = uri.query

    merged_query =
      [existing_query, query]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join("&")

    uri
    |> Map.put(:query, merged_query)
    |> URI.to_string()
  end
end
