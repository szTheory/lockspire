defmodule AdoptionDemoWeb.DeveloperController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def index(conn, _params) do
    verifier = "demo-pkce-verifier"
    challenge = code_challenge(verifier)
    demo_base_url = Application.fetch_env!(:adoption_demo, :demo_base_url)
    oauth_callback_url = demo_base_url <> "/oauth/callback"

    authorize_url =
      "/lockspire/authorize?" <>
        URI.encode_query(%{
          "client_id" => "acme-ledger-public",
          "response_type" => "code",
          "redirect_uri" => oauth_callback_url,
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
        <dt>Redirect URI</dt><dd><code>#{oauth_callback_url}</code></dd>
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
