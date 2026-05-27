defmodule AdoptionDemoWeb.ApiController do
  use AdoptionDemoWeb, :controller

  def billing_summary(conn, _params) do
    token = conn.assigns.access_token

    json(conn, %{
      tenant: "Acme Ledger",
      monthly_recurring_revenue: 128_400,
      invoices_due: 7,
      access_token: %{
        client_id: token.client_id,
        subject: token.claims["sub"],
        scope: token.claims["scope"],
        audience: token.claims["aud"],
        authorization_scheme: token.authorization_scheme
      }
    })
  end
end
