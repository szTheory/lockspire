defmodule GeneratedHostAppWeb.ProtectedApiController do
  use Phoenix.Controller, formats: [:json]

  alias Lockspire.AccessToken

  def show(conn, _params) do
    %AccessToken{} = access_token = conn.assigns.access_token
    subject = AccessToken.subject(access_token)
    scopes = AccessToken.scopes(access_token)
    audiences = AccessToken.audiences(access_token)
    expires_at = AccessToken.expires_at(access_token)
    confirmation = AccessToken.confirmation(access_token)

    if host_authorized_for_billing?(subject) do
      json(conn, %{
        access_token: %{
          client_id: access_token.client_id,
          subject: subject,
          scopes: scopes,
          audiences: audiences,
          expires_at: expires_at && DateTime.to_iso8601(expires_at),
          confirmation: confirmation
        }
      })
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "host_forbidden"})
    end
  end

  # This fixture is deliberately a host-owned product decision. Replace this
  # illustrative tenant/object check with the application's account and billing
  # policy; Lockspire only establishes the token's protocol facts above.
  defp host_authorized_for_billing?(subject) when is_binary(subject),
    do: String.starts_with?(subject, "generated-host-")

  defp host_authorized_for_billing?(_subject), do: false
end
