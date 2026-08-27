defmodule AdoptionDemoWeb.ApiController do
  use AdoptionDemoWeb, :controller

  alias Lockspire.AccessToken

  def billing_summary(conn, _params) do
    %AccessToken{} = access_token = conn.assigns.access_token
    subject = AccessToken.subject(access_token)

    if host_authorized_for_billing?(subject) do
      json(conn, %{
        tenant: "Billingo",
        monthly_recurring_revenue: 128_400,
        invoices_due: 7,
        access_token: %{
          client_id: access_token.client_id,
          subject: subject,
          scopes: AccessToken.scopes(access_token),
          audiences: AccessToken.audiences(access_token),
          expires_at: access_token |> AccessToken.expires_at() |> maybe_iso8601(),
          confirmation: AccessToken.confirmation(access_token),
          authorization_scheme: access_token.authorization_scheme
        }
      })
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "host_forbidden"})
    end
  end

  # Billingo owns this product authorization decision. Lockspire verifies the
  # OAuth token and exposes normalized protocol facts; the host decides whether
  # the resolved subject may read this tenant's billing data.
  defp host_authorized_for_billing?("user:" <> account_id), do: account_id != ""
  defp host_authorized_for_billing?(_subject), do: false

  defp maybe_iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp maybe_iso8601(nil), do: nil
end
