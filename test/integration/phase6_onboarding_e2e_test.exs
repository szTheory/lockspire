defmodule Lockspire.Integration.Phase6OnboardingE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false,
      live_view: [signing_salt: "generated_host_salt"]
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])

    Application.put_env(
      :lockspire,
      :account_resolver,
      GeneratedHostApp.Lockspire.TestAccountResolver
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase6-onboarding-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Generated Host App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "canonical onboarding path completes an auth-code flow and exposes discovery plus jwks", %{
    client: client
  } do
    signing_key = publish_signing_key("phase6-onboarding-kid")
    code_verifier = "phase6-onboarding-verifier"

    discovery_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> get("/lockspire/.well-known/openid-configuration")

    assert discovery_conn.status == 200

    discovery = Jason.decode!(discovery_conn.resp_body)

    assert discovery["issuer"] == "https://example.test/lockspire"
    assert discovery["authorization_endpoint"] == "https://example.test/lockspire/authorize"
    assert discovery["jwks_uri"] == "https://example.test/lockspire/jwks"

    authorize_conn =
      build_conn()
      |> get("/lockspire/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase6-state",
        "nonce" => "phase6-nonce",
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })

    assert authorize_conn.status in [302, 303]

    login_uri =
      authorize_conn
      |> redirected_to()
      |> URI.parse()

    assert login_uri.path == "/login"

    login_params = URI.decode_query(login_uri.query || "")
    assert %{"interaction_id" => interaction_id, "return_to" => return_to} = login_params
    assert return_to == "/lockspire/consent/#{interaction_id}"

    login_page_conn =
      build_conn()
      |> get("/login", login_params)

    assert login_page_conn.status == 200
    assert login_page_conn.resp_body =~ "Generated host login"

    login_complete_conn =
      submit_from(login_page_conn, "/login", %{
        "return_to" => return_to,
        "interaction_id" => interaction_id,
        "login" => "generated-host-user",
        "auth_time_seconds_ago" => "30"
      })

    assert login_complete_conn.status in [302, 303]

    resume_uri =
      login_complete_conn
      |> redirected_to()
      |> URI.parse()

    assert resume_uri.path == "/lockspire/interactions/#{interaction_id}"

    resumed_consent_conn =
      signed_in_conn("generated-host-user", 30)
      |> get(URI.to_string(resume_uri))

    assert resumed_consent_conn.status in [302, 303]
    assert redirected_to(resumed_consent_conn) == "/lockspire/consent/#{interaction_id}"

    loading_conn =
      signed_in_conn("generated-host-user", 30)
      |> get("/lockspire/consent/#{interaction_id}")

    assert loading_conn.status == 200
    assert loading_conn.resp_body =~ ~s(role="status")
    assert loading_conn.resp_body =~ "Loading authorization request…"
    refute loading_conn.resp_body =~ "approve-consent"
    refute loading_conn.resp_body =~ "deny-consent"
    refute loading_conn.resp_body =~ "Generated Host App"
    refute loading_conn.resp_body =~ interaction_id

    assert {:ok, consent_live, consent_html} =
             live(
               signed_in_conn("generated-host-user", 30),
               "/lockspire/consent/#{interaction_id}"
             )

    assert consent_html =~ ~s(role="status")
    assert consent_html =~ "Loading authorization request…"
    refute consent_html =~ "approve-consent"
    refute consent_html =~ "deny-consent"

    consent_html = render_async(consent_live)

    assert consent_html =~ "Generated Host App"
    assert consent_html =~ "Approve access"
    refute consent_html =~ "<code>"

    approve_form = form(consent_live, "#approve-consent", %{"remember" => "true"})
    submission_html = render_submit(approve_form)
    assert submission_html =~ "phx-trigger-action"
    assert submission_html =~ "disabled"
    assert submission_html =~ "Approving access…"
    assert submission_html =~ ~r/id="deny-consent".*disabled/s

    consent_complete_conn =
      follow_trigger_action(approve_form, signed_in_conn("generated-host-user", 30))

    assert consent_complete_conn.status in [302, 303]

    callback_uri =
      consent_complete_conn
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()

    callback_params = URI.decode_query(callback_uri.query || "")

    assert callback_uri.host == "client.example.com"
    assert callback_params["state"] == "phase6-state"
    assert code = callback_params["code"]

    token_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/lockspire/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })

    assert token_conn.status == 200

    token_response = Jason.decode!(token_conn.resp_body)

    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")
    assert token_response["token_type"] == "Bearer"

    assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
             JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

    assert id_token_claims["sub"] == "generated-host-user"
    assert id_token_claims["nonce"] == "phase6-nonce"
    assert id_token_claims["email"] == "generated-host-user@example.test"

    jwks_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> get("/lockspire/jwks")

    assert jwks_conn.status == 200

    assert %{"keys" => [public_jwk | _]} = Jason.decode!(jwks_conn.resp_body)
    assert public_jwk["kid"] == "phase6-onboarding-kid"
    assert public_jwk["alg"] == "RS256"
    refute Map.has_key?(public_jwk, "d")
  end

  test "generated consent resolves empty context and terminal failures without exposing protocol state",
       %{
         client: client
       } do
    {:ok, empty_interaction} =
      Repository.put_interaction(
        consent_interaction(client.client_id,
          account_id: "generated-host-user",
          scopes_requested: [],
          authorization_details: []
        )
      )

    {:ok, empty_live, empty_html} =
      live(
        signed_in_conn("generated-host-user", 30),
        "/lockspire/consent/#{empty_interaction.interaction_id}"
      )

    assert_loading_state(empty_html, empty_interaction.interaction_id)

    empty_html = render_async(empty_live)
    assert empty_html =~ "This application did not request any additional permissions."
    assert empty_html =~ "approve-consent"
    refute empty_html =~ "Requested access types"

    {:ok, expired_interaction} =
      Repository.put_interaction(
        consent_interaction(client.client_id,
          interaction_id: "expired-interaction-private-value",
          account_id: "generated-host-user",
          status: :expired,
          redirect_uri: "https://private.example.test/expired",
          expires_at: DateTime.add(DateTime.utc_now(), -60, :second),
          expired_at: DateTime.utc_now()
        )
      )

    assert_safe_error_state(
      expired_interaction.interaction_id,
      "This authorization request is no longer available. Return to the application and start again.",
      ["expired-interaction-private-value", "https://private.example.test/expired"]
    )

    {:ok, mismatch_interaction} =
      Repository.put_interaction(
        consent_interaction(client.client_id,
          interaction_id: "subject-mismatch-private-value",
          account_id: "another-subject",
          redirect_uri: "https://private.example.test/subject-mismatch"
        )
      )

    assert_safe_error_state(
      mismatch_interaction.interaction_id,
      "This authorization request is no longer available. Return to the application and start again.",
      [
        "subject-mismatch-private-value",
        "another-subject",
        "https://private.example.test/subject-mismatch"
      ]
    )

    assert_safe_error_state(
      "missing-interaction-private-value",
      "We could not load this authorization request. Return to the application and try again.",
      ["missing-interaction-private-value"]
    )
  end

  test "generated consent keeps remembered redirects terminal and task exits redaction-safe", %{
    client: client
  } do
    {:ok, _grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "generated-host-user",
        client_id: client.client_id,
        scopes: ["email", "profile"],
        granted_at: DateTime.utc_now(),
        status: :active,
        kind: :remembered
      })

    {:ok, remembered_interaction} =
      Repository.put_interaction(
        consent_interaction(client.client_id,
          interaction_id: "remembered-interaction-private-value",
          status: :pending_login,
          redirect_uri: "https://private.example.test/remembered"
        )
      )

    {:ok, remembered_live, remembered_html} =
      live(
        signed_in_conn("generated-host-user", 30),
        "/lockspire/consent/#{remembered_interaction.interaction_id}"
      )

    assert_loading_state(remembered_html, remembered_interaction.interaction_id)
    assert_redirect(remembered_live)

    socket =
      %Phoenix.LiveView.Socket{}
      |> Phoenix.Component.assign(loading?: true, submitting?: false, decision: nil, error: nil)

    assert {:noreply, socket} =
             GeneratedHostAppWeb.LockspireConsentLive.handle_async(
               :load_consent_context,
               {:exit, {:shutdown, "task-exit-private-value"}},
               socket
             )

    exit_html =
      Phoenix.LiveViewTest.rendered_to_string(
        GeneratedHostAppWeb.LockspireConsentLive.render(socket.assigns)
      )

    assert exit_html =~
             "We could not load this authorization request. Return to the application and try again."

    assert exit_html =~ ~s(role="alert")
    refute exit_html =~ "approve-consent"
    refute exit_html =~ "deny-consent"
    refute exit_html =~ "task-exit-private-value"
  end

  test "generated consent exposes safe host styling and long-text seams" do
    long_scope = String.duplicate("unbroken-scope", 20)
    long_detail_type = String.duplicate("unbroken-detail", 20)

    socket =
      %Phoenix.LiveView.Socket{}
      |> Phoenix.Component.assign(%{
        loading?: false,
        submitting?: false,
        decision: nil,
        error: nil,
        page_title: "Authorize Access",
        client_name: nil,
        requested_scopes: [long_scope],
        authorization_detail_types: [long_detail_type],
        remember?: true,
        finalize_path: "/lockspire/interactions/safe-id/complete"
      })

    html =
      Phoenix.LiveViewTest.rendered_to_string(
        GeneratedHostAppWeb.LockspireConsentLive.render(socket.assigns)
      )

    assert html =~ "Application details are unavailable. You can deny this request."
    refute html =~ "Application details are unavailable wants access"
    assert html =~ "host-consent-action--primary"
    assert html =~ "host-consent-action--destructive"
    assert html =~ "host-consent-actions"
    assert html =~ "host-consent-section"
    assert html =~ "host-consent-wrap"
    assert html =~ "overflow-wrap: anywhere"
    assert html =~ long_scope
    assert html =~ long_detail_type
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: "sig",
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end

  defp assert_safe_error_state(interaction_id, expected_message, sensitive_values) do
    {:ok, live, html} =
      live(signed_in_conn("generated-host-user", 30), "/lockspire/consent/#{interaction_id}")

    assert_loading_state(html, interaction_id)

    html = render_async(live)
    assert html =~ expected_message
    assert html =~ ~s(role="alert")
    refute html =~ "approve-consent"
    refute html =~ "deny-consent"

    Enum.each(sensitive_values, fn sensitive_value ->
      refute html =~ sensitive_value
    end)
  end

  defp assert_loading_state(html, interaction_id) do
    assert html =~ ~s(role="status")
    assert html =~ "Loading authorization request…"
    refute html =~ "approve-consent"
    refute html =~ "deny-consent"
    refute html =~ interaction_id
  end

  defp consent_interaction(client_id, overrides) do
    now = DateTime.utc_now()

    defaults = %Interaction{
      interaction_id: "generated-consent-#{System.unique_integer([:positive])}",
      client_id: client_id,
      account_id: nil,
      scopes_requested: ["email", "profile"],
      prompt: [],
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/consent/placeholder",
      state: "generated-consent-state",
      code_challenge: String.duplicate("a", 43),
      code_challenge_method: :S256,
      status: :pending_consent,
      login_required_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }

    struct!(defaults, Enum.into(overrides, %{}))
  end

  defp submit_from(conn, path, params) do
    csrf_token = extract_csrf_token(conn.resp_body)

    conn
    |> recycle()
    |> post(path, Map.put(params, "_csrf_token", csrf_token))
  end

  defp extract_csrf_token(body) do
    ~r/name="_csrf_token" value="([^"]+)"/
    |> Regex.run(body, capture: :all_but_first)
    |> case do
      [token] -> token
      _ -> raise "expected CSRF token in response body"
    end
  end

  defp signed_in_conn(login, auth_time_seconds_ago) do
    auth_time_unix =
      DateTime.utc_now()
      |> DateTime.add(-auth_time_seconds_ago, :second)
      |> DateTime.to_unix()

    build_conn()
    |> init_test_session(%{
      "current_account_id" => login,
      "current_account_email" => "#{login}@example.test",
      "current_account_name" => "Generated Host User",
      "current_auth_time_unix" => auth_time_unix
    })
  end
end
