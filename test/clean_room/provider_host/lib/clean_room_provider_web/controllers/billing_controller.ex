defmodule CleanRoomProviderWeb.BillingController do
  use Phoenix.Controller, formats: [:json]
  alias Lockspire.AccessToken

  def show(conn, _params) do
    token = conn.assigns.access_token
    subject = AccessToken.subject(token)

    if host_authorized_for_billing?(subject) do
      json(conn, %{
        access_token: %{
          subject: subject,
          scopes: AccessToken.scopes(token),
          audiences: AccessToken.audiences(token),
          expires_at: format_expiry(AccessToken.expires_at(token)),
          confirmation: AccessToken.confirmation(token)
        }
      })
    else
      conn |> put_status(:forbidden) |> json(%{error: "host_forbidden"})
    end
  end

  defp format_expiry(nil), do: nil
  defp format_expiry(value), do: DateTime.to_iso8601(value)
  # Product/tenant authorization is deliberately host-owned, after Lockspire's protocol pipeline.
  defp host_authorized_for_billing?("clean-room-user"), do: true
  defp host_authorized_for_billing?(_subject), do: false
end
