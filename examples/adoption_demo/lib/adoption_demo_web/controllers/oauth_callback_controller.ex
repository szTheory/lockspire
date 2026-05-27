defmodule AdoptionDemoWeb.OAuthCallbackController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def show(conn, params) do
    body = """
    <section class="panel">
      <h1>OAuth callback</h1>
      <p>The client received an authorization response.</p>
      <pre>#{HTML.escape(Jason.encode!(params, pretty: true))}</pre>
    </section>
    """

    html(conn, HTML.page(conn, "OAuth callback", body))
  end
end
