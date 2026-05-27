defmodule AdoptionDemoWeb.DeveloperController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def index(conn, _params) do
    verifier = "demo-pkce-verifier"
    challenge = code_challenge(verifier)

    authorize_url =
      "/lockspire/authorize?" <>
        URI.encode_query(%{
          "client_id" => "acme-ledger-public",
          "response_type" => "code",
          "redirect_uri" => "http://127.0.0.1:4100/oauth/callback",
          "scope" => "openid email profile read:billing",
          "state" => "demo-state",
          "nonce" => "demo-nonce",
          "prompt" => "consent",
          "code_challenge" => challenge,
          "code_challenge_method" => "S256"
        })

    body = """
    <section class="panel">
      <h1>Developer apps</h1>
      <p>The public client below is seeded for a browser-based auth-code + PKCE proof.</p>
      <dl>
        <dt>Client ID</dt><dd><code>acme-ledger-public</code></dd>
        <dt>Redirect URI</dt><dd><code>http://127.0.0.1:4100/oauth/callback</code></dd>
        <dt>PKCE verifier for the demo smoke</dt><dd><code>#{verifier}</code></dd>
      </dl>
      <p><a class="primary" href="#{authorize_url}">Start OAuth authorization</a></p>
    </section>
    """

    html(conn, HTML.page(conn, "Developer apps", body))
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end
end
