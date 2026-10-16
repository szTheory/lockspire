defmodule Lockspire.Web.Live.Admin.ClientsLive.ShowTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.ClientsLive.Show

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

    on_exit(fn ->
      Application.put_env(:lockspire, :mount_path, "/lockspire")
    end)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "lockspire_salt"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    assert {:ok, _policy} =
             Lockspire.Storage.Ecto.Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{
               id: 1
             })

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "security-show-client",
        client_secret_hash: "sha256:show:hash",
        client_type: :confidential,
        name: "Security Show Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "router exposes per-client security profile edit route" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/security-profile", Show))
  end

  test "a missing client is distinct from a failed client read" do
    assert {:ok, _missing_view, missing_html} =
             live(conn_for_admin(), "/admin/clients/not-a-current-client")

    assert missing_html =~ "App not found"
    assert missing_html =~ "Back to apps"
    refute missing_html =~ "Could not load app"

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailableClientRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, _error_view, error_html} =
               live(conn_for_admin(), "/admin/clients/security-show-client")

      assert error_html =~ "Could not load app"
      assert error_html =~ "be loaded. Reload the page or go back to the app list."
      assert error_html =~ "Reload this view"
      refute error_html =~ "App not found"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "each client task route names its task and keeps provenance reader-facing", %{
    client: client
  } do
    assert {:ok, registered_client} =
             Repository.register_client(%Client{
               client_id: "route-copy-self-registered-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "Route Copy Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:route-copy:rat",
               registration_client_uri:
                 "https://issuer.example.com/register/route-copy-self-registered-client",
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    routes = [
      {"/admin/clients/#{client.client_id}", "App details", "sign-in destinations"},
      {"/admin/clients/#{client.client_id}/edit", "Edit app settings",
       "permissions, details, and token settings"},
      {"/admin/clients/#{client.client_id}/edit?workflow=logout-propagation",
       "Update sign-out notifications",
       "Server delivery can be retried; browser delivery is best effort"},
      {"/admin/clients/#{client.client_id}/logout-uris", "Update sign-out return URLs",
       "exact URLs where users may return after signing out"},
      {"/admin/clients/#{client.client_id}/par-policy", "Set authorization request rules",
       "Pushed Authorization Requests (PAR)"},
      {"/admin/clients/#{client.client_id}/redirects", "Update sign-in return URLs",
       "exact URLs where users return after signing in"},
      {"/admin/clients/#{registered_client.client_id}/rotate-registration-access-token",
       "Rotate app management token", "token this app uses to update or delete its registration"},
      {"/admin/clients/#{client.client_id}/rotate-secret", "Rotate client secret",
       "The new secret is shown once, right after you confirm."},
      {"/admin/clients/#{client.client_id}/security-profile", "Update app security requirements",
       "FAPI and OIDC requirements or use the provider default"}
    ]

    Enum.each(routes, fn {path, title, explanation} ->
      assert {:ok, _view, html} = live(conn_for_admin(), path)

      labels =
        if Enum.any?(
             ["/edit", "/logout-uris", "/par-policy", "/redirects", "/security-profile"],
             &String.contains?(path, &1)
           ),
           do: :required,
           else: :when_present

      HtmlAssertions.assert_page_contract!(html, labels: labels)
      visible_text = text_content(html)
      assert visible_text =~ title
      assert visible_text =~ explanation

      route_client =
        if String.contains?(path, registered_client.client_id),
          do: registered_client,
          else: client

      assert visible_text =~ route_client.name
      assert visible_text =~ route_client.client_id

      if path == "/admin/clients/#{client.client_id}" do
        assert html =~ ~s(href="/admin/clients")
        assert visible_text =~ "Back to apps"
      else
        assert html =~ ~s(data-client-task-context)
        assert html =~ ~s(href="/admin/clients/#{route_client.client_id}")
        assert html =~ "lockspire-admin-btn-secondary"
        refute visible_text =~ "Client workspace"
        refute html =~ ~s(class="lockspire-admin-hero lockspire-admin-page-hero")

        if String.contains?(path, "rotate-") do
          assert html =~ "lockspire-admin-btn-danger"
        else
          assert html =~ "lockspire-admin-btn-primary"
        end
      end
    end)

    detail_html = render_show_html(client.client_id)
    visible_detail = text_content(detail_html)
    assert visible_detail =~ "Added directly"
    refute visible_detail =~ "operator"
  end

  test "client detail shows effective strict message-signing posture and mixed-mode warning", %{
    client: client
  } do
    now = DateTime.utc_now()

    Lockspire.Storage.Ecto.Repository.publish_key(%Lockspire.Domain.SigningKey{
      kid: "fapi-compliant-key-1",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "kid" => "fapi-compliant-key-1",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    assert {:ok, _policy} = Admin.put_security_profile(:fapi_2_0_message_signing)

    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{security_profile: :none})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Security requirements"
    assert html =~ "This app:"
    assert html =~ "FAPI 2.0 message-signing rules"
    assert html =~ "Provider requirement overridden"
    assert html =~ "Provider security defaults do not apply to this app"
    assert html =~ "excluded from FAPI 2.0 checks"
  end

  test "unavailable provider settings are shown as unavailable instead of a default", %{
    client: client
  } do
    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_server_policies", [])

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Provider settings are unavailable"

    visible = text_content(html)

    assert visible =~
             "saved settings are shown, but provider defaults and the resulting behavior could not be loaded."

    assert visible =~ "Default: Unavailable"
    refute visible =~ "Default: Standard OpenID Connect"
    refute visible =~ "Default: Optional"
    refute visible =~ "Default: JWT"
  end

  test "override editors show issuer default, selected client override, and effective behavior",
       %{
         client: client
       } do
    assert {:ok, _policy} =
             Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{
               id: 1,
               par_policy: :required,
               dpop_policy: :dpop,
               security_profile: :fapi_2_0_security,
               access_token_format: :opaque
             })

    assert {:ok, edit_view, edit_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/edit")

    edit_text = text_content(edit_html)
    assert edit_text =~ "Provider default: DPoP-bound access tokens"

    assert has_element?(
             edit_view,
             ~s(input[type="radio"][name="client[dpop_policy]"][value="inherit"][checked])
           )

    refute edit_text =~ "Selected setting:"
    assert edit_text =~ "Result if saved: DPoP-bound access tokens"
    assert edit_text =~ "Provider default: Opaque"
    assert edit_text =~ "Result if saved: Opaque"

    changed_edit_html =
      edit_view
      |> form("#client-edit-form", %{
        client: %{mode: "edit", dpop_policy: "bearer", access_token_format: "jwt"}
      })
      |> render_change()

    changed_edit_text = text_content(changed_edit_html)

    assert has_element?(
             edit_view,
             ~s(input[type="radio"][name="client[dpop_policy]"][value="bearer"][checked])
           )

    assert changed_edit_text =~ "Result if saved: Bearer access tokens"

    assert has_element?(
             edit_view,
             ~s(input[type="radio"][name="client[access_token_format]"][value="jwt"][checked])
           )

    assert changed_edit_text =~ "Result if saved: JWT (RFC 9068 at+jwt)"

    assert {:ok, par_view, par_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/par-policy")

    par_text = text_content(par_html)
    assert par_text =~ "Provider default: Required"

    assert has_element?(
             par_view,
             ~s(input[type="radio"][name="client[par_policy]"][value="inherit"][checked])
           )

    assert par_text =~ "Result if saved: Required"

    changed_par_html =
      par_view
      |> form("#client-par-policy-form", %{client: %{mode: "par_policy", par_policy: "optional"}})
      |> render_change()

    changed_par_text = text_content(changed_par_html)

    assert has_element?(
             par_view,
             ~s(input[type="radio"][name="client[par_policy]"][value="optional"][checked])
           )

    assert changed_par_text =~ "Result if saved: Optional"

    assert {:ok, security_view, security_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/security-profile")

    security_text = text_content(security_html)
    assert security_text =~ "Provider default: FAPI 2.0 Security Profile"

    assert has_element?(
             security_view,
             ~s(input[type="radio"][name="client[security_profile]"][value="inherit"][checked])
           )

    assert security_text =~ "Result if saved: FAPI 2.0 Security Profile"
    assert security_text =~ "This app currently uses: FAPI 2.0 Security Profile"

    changed_security_html =
      security_view
      |> form("#client-security-profile-form", %{
        client: %{mode: "security_profile", security_profile: "none"}
      })
      |> render_change()

    changed_security_text = text_content(changed_security_html)

    assert has_element?(
             security_view,
             ~s(input[type="radio"][name="client[security_profile]"][value="none"][checked])
           )

    assert changed_security_text =~ "Result if saved: Standard OAuth and OpenID Connect"

    invalid_security_html = render_invalid_security_profile_html(client.client_id)

    invalid_security_text = text_content(invalid_security_html)
    assert invalid_security_text =~ "App security profile was not saved."
    assert invalid_security_text =~ "Review this value and try again."
    assert invalid_security_text =~ "security-show-client"
    assert invalid_security_html =~ ~s(aria-invalid="true")
    assert invalid_security_html =~ ~s(aria-describedby="client_security_profile-error")

    HtmlAssertions.assert_describedby_targets_exist(invalid_security_html)
  end

  test "per-client security profile editor renders current values and persists updates", %{
    client: client
  } do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, view, html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/security-profile")

    assert html =~ "Update app security requirements"
    assert html =~ "App security requirements"
    assert html =~ "Use provider default"
    assert html =~ "FAPI 2.0 Message Signing"
    assert html =~ "FAPI 2.0 Security Profile"
    assert html =~ "Authorization response signing algorithm"

    now = DateTime.utc_now()

    Lockspire.Storage.Ecto.Repository.publish_key(%Lockspire.Domain.SigningKey{
      kid: "fapi-compliant-key-2",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "kid" => "fapi-compliant-key-2",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        mode: "security_profile",
        security_profile: "fapi_2_0_message_signing",
        authorization_signed_response_alg: "ES256"
      }
    })
    |> render_submit()

    assert {:ok, updated_client} = Admin.get_client(client.client_id)
    assert updated_client.security_profile == :fapi_2_0_message_signing
    assert updated_client.authorization_signed_response_alg == :ES256

    html_after = render(view)
    assert html_after =~ "This app currently uses:"
    assert html_after =~ "FAPI 2.0 Message Signing"
    assert html_after =~ "Signing key ready for message signing:"
    assert html_after =~ "Ready"
  end

  test "client detail shows canonical remediation when strict message signing is selected but not ready",
       %{client: client} do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_message_signing})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "FAPI 2.0 message-signing rules"
    assert html =~ "Required for this app"
    assert html =~ "Blocked"
    assert html =~ "Publish an ES256 or PS256 Lockspire signing key"
  end

  test "client detail reports strict readiness read failures as unavailable", %{client: client} do
    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_message_signing})

    prior_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(:lockspire, :repo, __MODULE__.ReadinessFailureRepo)

      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

      assert html =~ "Could not check provider requirements"
      assert html =~ "Unable to load strict message-signing readiness."
      refute html =~ "Blocked"
      refute html =~ "Provider requirements still need setup"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "client detail groups routine, credential, endpoint, posture, and lifecycle actions",
       %{client: client} do
    assert {:ok, self_registered_client} =
             Repository.register_client(%Client{
               client_id: "self-registered-action-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "Self Registered Action Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:rat:show",
               registration_client_uri:
                 "https://issuer.example.com/register/self-registered-action-client",
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    assert {:ok, _view, html} =
             live(conn_for_admin(), "/admin/clients/#{self_registered_client.client_id}")

    assert html =~ "lockspire-admin-entity-header"
    assert html =~ "lockspire-admin-pane"
    assert html =~ "lockspire-admin-status-cluster"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "App details"
    assert html =~ "App type"
    assert html =~ "How the app authenticates"
    assert html =~ "Code exchange protection (PKCE)"

    for group <- [
          "Identity and current status",
          "Security settings",
          "Secret and signing keys",
          "Sign-in and sign-out URLs",
          "Registration details",
          "Related records",
          "Disable or enable app"
        ] do
      assert html =~ group
    end

    assert html =~ "lockspire-admin-action-group"
    assert html =~ "lockspire-admin-action-group__primary"
    assert html =~ "lockspire-admin-action-group__secondary"
    assert html =~ "lockspire-admin-confirmation-panel"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/edit"
    assert html =~ "Edit app details"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/redirects"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/logout-uris"

    assert html =~
             "/admin/clients/#{self_registered_client.client_id}/edit?workflow=logout-propagation"

    assert html =~ "/admin/clients/#{self_registered_client.client_id}/par-policy"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/security-profile"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/rotate-secret"

    assert html =~
             "/admin/clients/#{self_registered_client.client_id}/rotate-registration-access-token"

    assert html =~ "Rotate client secret"
    assert html =~ "Rotate app management token"
    assert html =~ "App management token"
    assert html =~ "Redacted"
    assert html =~ "Review API registration"
    assert html =~ "/admin/dcr"
    assert html =~ "Edit sign-in return URLs"
    assert html =~ "Edit sign-out return URLs"
    assert html =~ "Edit sign-out notifications"
    assert html =~ "Edit authorization request rules"
    assert html =~ "Edit security profile"
    assert html =~ ~s(phx-submit="toggle_client")
    assert html =~ ~s(name="toggle[confirm]")
    assert html =~ "Confirm disabling app"
    assert html =~ "Disable app"
    assert html =~ "lockspire-admin-btn-danger"

    assert html =~
             "sign users in or get tokens until you enable it again"

    assert html =~ "This app was registered through the API."
    refute html =~ "Rotate Registration Access Token (RAT)"
    refute html =~ "sha256:show:hash"
    refute html =~ "sha256:rat:show"
    refute html =~ "client_secret_hash"
    refute html =~ "registration_access_token_hash"
  end

  test "client detail keeps long Configure values wrapped and durable credential material redacted",
       %{client: client} do
    long_redirect_uri =
      "https://client.example.com/" <>
        String.duplicate("deep/redirect-segment/", 7) <>
        "callback"

    long_post_logout_uri =
      "https://client.example.com/" <>
        String.duplicate("post/logout-segment/", 7) <>
        "complete"

    long_backchannel_uri =
      "https://client.example.com/" <>
        String.duplicate("backchannel/logout-segment/", 7) <>
        "deliver"

    long_frontchannel_uri =
      "https://client.example.com/" <>
        String.duplicate("frontchannel/logout-segment/", 7) <>
        "cleanup"

    long_registration_uri =
      "https://issuer.example.com/register/" <>
        String.duplicate("self-registered-partner-", 5) <>
        "client"

    assert {:ok, long_client} =
             Repository.register_client(%Client{
               client_id: "long-configure-client",
               client_secret_hash: "sha256:long:client:secret:hash",
               client_type: :confidential,
               name: "Long Configure Client",
               redirect_uris: [long_redirect_uri],
               post_logout_redirect_uris: [long_post_logout_uri],
               backchannel_logout_uri: long_backchannel_uri,
               frontchannel_logout_uri: long_frontchannel_uri,
               allowed_scopes: ["openid", "profile"],
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:long:rat:hash",
               registration_client_uri: long_registration_uri,
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    html = render_show_html(long_client.client_id)

    assert html =~ long_redirect_uri
    assert html =~ long_post_logout_uri
    assert html =~ long_backchannel_uri
    assert html =~ long_frontchannel_uri
    assert html =~ long_registration_uri
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Current secret"
    assert html =~ "redacted"
    assert html =~ "App management token"
    assert html =~ "Review API registration"
    assert html =~ "These links open the full inventories. Match records there by this Client ID."

    html
    |> HtmlAssertions.assert_no_duplicate_ids()
    |> HtmlAssertions.assert_describedby_targets_exist()
    |> HtmlAssertions.assert_links_have_hrefs()
    |> HtmlAssertions.assert_no_generic_cta_text()
    |> HtmlAssertions.assert_no_token_like_text()
    |> HtmlAssertions.assert_no_text([
      "sha256:long:client:secret:hash",
      "sha256:long:rat:hash",
      "client_secret_hash",
      "registration_access_token_hash",
      "verifier material",
      "raw request object",
      "host tenant policy",
      "developer portal",
      "Reveal secret",
      "Export credential",
      "force-publish",
      "public theming"
    ])
  end

  test "client secret rotation uses copy-once consequence copy", %{client: client} do
    assert {:ok, view, html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/rotate-secret")

    HtmlAssertions.assert_page_contract!(html)

    assert html =~ "Rotate client secret"
    assert html =~ "previous secret stops being the current credential"
    assert html =~ "Copy it when shown"
    assert html =~ "stores only a hash, so it cannot show the secret again"
    assert html =~ "before it requests tokens"
    assert html =~ ~s(phx-disable-with="Rotating client secret…")
    refute html =~ "sha256:show:hash"
    refute html =~ "client_secret_hash"

    html_after_rotate =
      view
      |> form("form[phx-submit=rotate_secret]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    assert html_after_rotate =~ "New client secret"
    assert html_after_rotate =~ "Copy this secret now"

    plaintext_secret = extract_copy_once_value(html_after_rotate)

    assert html_after_rotate =~ plaintext_secret

    durable_html = render_show_html(client.client_id)

    durable_html
    |> HtmlAssertions.assert_no_token_like_text()
    |> HtmlAssertions.assert_no_text([
      plaintext_secret,
      "sha256:show:hash",
      "client_secret_hash",
      "verifier material",
      "Reveal secret",
      "Export credential"
    ])
  end

  test "client secret acknowledgement and route departure clear the one-time value", %{
    client: client
  } do
    assert {:ok, view, _html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/rotate-secret")

    rotated_html =
      view
      |> form("form[phx-submit=rotate_secret]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    plaintext_secret = extract_copy_once_value(rotated_html)

    hidden_html =
      view
      |> element("button[phx-click=acknowledge_secret]")
      |> render_click()

    refute hidden_html =~ plaintext_secret

    rotated_again_html =
      view
      |> form("form[phx-submit=rotate_secret]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    second_secret = extract_copy_once_value(rotated_again_html)
    assert second_secret != plaintext_secret

    detail_html = render_patch(view, "/admin/clients/#{client.client_id}")
    refute detail_html =~ second_secret

    reopened_html = render_patch(view, "/admin/clients/#{client.client_id}/rotate-secret")
    refute reopened_html =~ second_secret
  end

  test "registration access token rotation explains its endpoint and clears on acknowledgement and route exit",
       %{client: client} do
    assert {:ok, self_registered_client} =
             Repository.register_client(%Client{
               client_id: "rat-handoff-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "RAT Handoff Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:rat:handoff",
               registration_client_uri: "https://issuer.example.com/register/rat-handoff-client",
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    path = "/admin/clients/#{self_registered_client.client_id}/rotate-registration-access-token"
    assert {:ok, view, html} = live(conn_for_admin(), path)
    HtmlAssertions.assert_page_contract!(html)

    assert html =~ "Use this token to update the app&#39;s registration at this URL"
    assert html =~ self_registered_client.registration_client_uri
    assert html =~ ~s(phx-disable-with="Rotating app management token…")

    rotated_html =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    plaintext_rat = extract_copy_once_value(rotated_html)
    assert rotated_html =~ "New app management token"

    detail_html = render_patch(view, "/admin/clients/#{self_registered_client.client_id}")
    refute detail_html =~ plaintext_rat

    reopened_html = render_patch(view, path)
    refute reopened_html =~ plaintext_rat

    rotated_again_html =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    second_rat = extract_copy_once_value(rotated_again_html)

    hidden_html =
      view
      |> element("button[phx-click=acknowledge_rat]")
      |> render_click()

    refute hidden_html =~ second_rat
  end

  test "failed secret and RAT rotations preserve client context without showing a credential", %{
    client: client
  } do
    unavailable_repo = Module.concat(__MODULE__, "UnavailableRotationRepo")
    prior_repo = Application.get_env(:lockspire, :repo)

    try do
      assert {:ok, secret_view, _html} =
               live(conn_for_admin(), "/admin/clients/#{client.client_id}/rotate-secret")

      Application.put_env(:lockspire, :repo, unavailable_repo)

      secret_error_html =
        secret_view
        |> form("form[phx-submit=rotate_secret]", %{rotate: %{confirm: "true"}})
        |> render_submit()

      assert secret_error_html =~ "Rotation was not confirmed. No new client secret is shown."
      assert secret_error_html =~ "security-show-client"
      refute secret_error_html =~ "New client secret"
      refute secret_error_html =~ "client_secret_hash"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end

    assert {:ok, self_registered_client} =
             Repository.register_client(%Client{
               client_id: "rat-failure-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "RAT Failure Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               provenance: :self_registered,
               registration_access_token_hash: "sha256:rat:failure",
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    assert {:ok, rat_view, _html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{self_registered_client.client_id}/rotate-registration-access-token"
             )

    prior_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      rat_error_html =
        rat_view
        |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
        |> render_submit()

      assert rat_error_html =~
               "Rotation was not confirmed. No new app management token was created."

      assert rat_error_html =~ "rat-failure-client"
      refute rat_error_html =~ "New app management token"
      refute rat_error_html =~ "sha256:rat:failure"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "client lifecycle changes require explicit confirmation", %{client: client} do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")
    HtmlAssertions.assert_page_contract!(html)

    assert html =~ "Confirm disabling app"

    html_without_confirm =
      view
      |> form("form[phx-submit=toggle_client]", %{toggle: %{}})
      |> render_submit()

    assert html_without_confirm =~ "confirm this lifecycle change"
    assert {:ok, unchanged_client} = Admin.get_client(client.client_id)
    assert unchanged_client.active

    view
    |> form("form[phx-submit=toggle_client]", %{toggle: %{confirm: "true"}})
    |> render_submit()

    assert {:ok, disabled_client} = Admin.get_client(client.client_id)
    refute disabled_client.active

    disabled_html = render(view)

    assert disabled_html =~ "Confirm enabling app"
    assert disabled_html =~ "Enable app"
    assert disabled_html =~ "configured OAuth/OIDC use can resume"
    HtmlAssertions.assert_no_text(disabled_html, ["data-confirm", "force enable"])
  end

  test "a failed lifecycle change shows an error and leaves the app unchanged", %{client: client} do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert {1, nil} = Lockspire.TestRepo.delete_all(Lockspire.Storage.Ecto.ClientRecord)

    html =
      view
      |> form("form[phx-submit=toggle_client]", %{toggle: %{confirm: "true"}})
      |> render_submit()

    assert html =~ "The app was not changed."
  end

  test "saves outside the details form show a success notice that does not linger", %{
    client: client
  } do
    assert {:ok, _stored_client} =
             Admin.update_client(client.client_id, %{
               post_logout_redirect_uris: ["https://client.example.com/signed-out"]
             })

    assert {:ok, view, _html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/redirects")

    view
    |> form("#client-redirect-uris-form", %{
      client: %{redirect_uris: "https://client.example.com/new-callback"}
    })
    |> render_submit()

    assert render(view) =~ "App changes saved."
    assert {:ok, saved} = Admin.get_client(client.client_id)
    assert saved.redirect_uris == ["https://client.example.com/new-callback"]

    {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")
    refute render(view) =~ "App changes saved."
  end

  test "save_client ignores a missing or mismatched mode and does not crash", %{client: client} do
    assert {:ok, view, _html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/par-policy")

    render_hook(view, "save_client", %{"client" => %{"mode" => "bogus", "name" => "Hijacked"}})
    render_hook(view, "save_client", %{"client" => %{}})
    assert render(view) =~ "Security Show Client"

    assert {:ok, unchanged} = Admin.get_client(client.client_id)
    assert unchanged.name == "Security Show Client"

    assert {:ok, show_view, _html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")
    render_hook(show_view, "save_client", %{"client" => %{"mode" => "edit", "name" => "Nope"}})
    assert {:ok, still_unchanged} = Admin.get_client(client.client_id)
    assert still_unchanged.name == "Security Show Client"
  end

  test "client detail support pivots link to supported logout queue route", %{client: client} do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Related records"
    assert html =~ "Review sign-out notices"
    assert html =~ ~s(href="/admin/logouts")
    refute html =~ "/admin/logout-deliveries"
  end

  test "client detail shows read-only private_key_jwt posture for jwks_uri clients", %{
    client: client
  } do
    assert {:ok, _policy} =
             Admin.put_dcr_policy(%{dcr_allowed_token_endpoint_auth_methods: ["private_key_jwt"]})

    assert {:ok, pkjwt_client} =
             Repository.register_client(%Client{
               client_id: "pkjwt-show-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "JWT Show Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :private_key_jwt,
               pkce_required: true,
               subject_type: :public,
               created_at: DateTime.utc_now(),
               jwks_uri: "https://client.example.com/.well-known/jwks.json",
               metadata: %{}
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{pkjwt_client.client_id}")

    assert html =~ "App signing keys"
    assert html =~ "Remote JWKS URI configured"
    assert html =~ "https://client.example.com/.well-known/jwks.json"
    assert html =~ "Signed client assertion with app key"
    assert html =~ "RS256, ES256, PS256, EdDSA"
    assert html =~ "Remote JWKS"
    assert html =~ "bounded reactive rollover support"
    assert html =~ "fails the current request closed"
    assert html =~ "Lockspire owns the guarded fetch, cache, refresh, and verify path"
    assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-show-client"
    refute html =~ "Edit JWKS"
    refute html =~ "Test fetch"
  end

  test "client detail separates sign-out notifications from return URLs", %{
    client: client
  } do
    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{
               backchannel_logout_uri: "https://client.example.com/backchannel",
               frontchannel_logout_uri: "https://client.example.com/frontchannel"
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Sign-out return URLs"
    assert html =~ "Where users may return after signing out."
    assert html =~ "Server sign-out notification URL"
    assert html =~ "Browser sign-out notification URL"
    assert html =~ "Lockspire sends this app a sign-out notification from the server."
    assert html =~ "/admin/clients/#{client.client_id}/edit?workflow=logout-propagation"
    assert html =~ "Server notifications can be retried."
    assert html =~ "Browser notifications are best effort and cannot"
  end

  test "sign-out notification editor explains server retries and browser limits",
       %{client: client} do
    assert {:ok, _view, html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{client.client_id}/edit?workflow=logout-propagation"
             )

    assert html =~ "Update sign-out notifications"
    assert html =~ "Server sign-out notification URL"
    assert html =~ "These URLs tell Lockspire where this app receives sign-out notifications."
    assert html =~ "Server notifications are stored and retried."
    assert html =~ "Browser notifications may be blocked"
  end

  test "client detail renders the shared remote JWKS incident summary when metadata is present",
       %{
         client: client
       } do
    assert {:ok, incident_client} =
             Repository.register_client(%Client{
               client_id: "pkjwt-incident-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "JWT Incident Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :private_key_jwt,
               pkce_required: true,
               subject_type: :public,
               created_at: DateTime.utc_now(),
               jwks_uri: "https://client.example.com/.well-known/jwks.json",
               metadata: %{
                 "remote_jwks_diagnostic" => %{
                   "class" => "remote_jwks_key_unavailable",
                   "consumer" => "private_key_jwt",
                   "stage" => "select_key",
                   "subreason" => "post_refresh_key_still_missing",
                   "forced_refresh_attempted?" => true,
                   "requested_kid_present_in_cached_set?" => false
                 }
               }
             })

    assert {:ok, _view, html} =
             live(conn_for_admin(), "/admin/clients/#{incident_client.client_id}")

    assert html =~ "Remote JWKS"
    assert html =~ "Status"
    assert html =~ "incident"
    assert html =~ "remote_jwks_key_unavailable"
    assert html =~ "Stage=select_key"
    assert html =~ "subreason=post_refresh_key_still_missing"
    assert html =~ "forced_refresh=true"
    assert html =~ "cache_preserved=true"
    assert html =~ "Publish the requested key alongside the previous key"
    assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-incident-client"
    refute html =~ "client_secret_hash"
  end

  test "client detail shows the remote JWKS panel for JARM-only jwks_uri clients", %{
    client: client
  } do
    assert {:ok, jarm_client} =
             Repository.register_client(%Client{
               client_id: "jarm-remote-client",
               client_secret_hash: client.client_secret_hash,
               client_type: :confidential,
               name: "JARM Remote Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_basic,
               authorization_encrypted_response_alg: :RSA_OAEP_256,
               authorization_encrypted_response_enc: :A256GCM,
               pkce_required: true,
               subject_type: :public,
               created_at: DateTime.utc_now(),
               jwks_uri: "https://client.example.com/.well-known/jwks.json",
               metadata: %{}
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{jarm_client.client_id}")

    assert html =~ "Remote JWKS"
    assert html =~ "bounded reactive rollover support"
    assert html =~ "mix lockspire.doctor remote-jwks --client jarm-remote-client"
  end

  test "client detail shows read-only client_secret_jwt plus HS256 truth", %{client: client} do
    assert {:ok, jwt_client} =
             Repository.register_client(%Client{
               client_id: "csjwt-show-client",
               client_secret_hash: client.client_secret_hash,
               client_secret_jwt_verifier_encrypted: "sealed-jwt-show",
               client_type: :confidential,
               name: "Shared JWT Show Client",
               redirect_uris: client.redirect_uris,
               allowed_scopes: client.allowed_scopes,
               allowed_grant_types: client.allowed_grant_types,
               allowed_response_types: client.allowed_response_types,
               token_endpoint_auth_method: :client_secret_jwt,
               token_endpoint_auth_signing_alg: :HS256,
               pkce_required: true,
               subject_type: :public,
               created_at: DateTime.utc_now(),
               metadata: %{}
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{jwt_client.client_id}")

    assert html =~ "Signed app requests with a shared secret"
    assert html =~ "client_secret_jwt"
    assert html =~ "HS256"
    refute html =~ "verifier material"
  end

  test "edit form renders the access_token_format override select with doclink and persists the choice",
       %{client: client} do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}/edit")

    assert html =~ "Access token format"
    assert html =~ ~s(name="client[access_token_format]")
    assert html =~ ~s(value="inherit")
    assert html =~ ~s(value="jwt")
    assert html =~ ~s(value="opaque")
    assert html =~ "Use provider default"
    assert html =~ "JWT (RFC 9068 at+jwt)"
    assert html =~ "Opaque token"
    refute html =~ "docs/protect-phoenix-api-routes.md"

    assert html =~
             "JWTs let APIs verify tokens locally. Opaque tokens are checked with Lockspire."

    assert has_element?(
             view,
             ~s(input[type="radio"][name="client[access_token_format]"][value="inherit"][checked])
           )

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        mode: "edit",
        allowed_scopes: "email",
        access_token_format: "opaque"
      }
    })
    |> render_submit()

    assert {:ok, updated_client} = Admin.get_client(client.client_id)
    assert updated_client.access_token_format == :opaque

    html_after = render(view)
    assert html_after =~ "App changes saved."
    assert html_after =~ "App details"
    refute html_after =~ "Save app changes"
  end

  test "client metadata edit retains attempted and untouched values with associated save errors",
       %{
         client: client
       } do
    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{
               allowed_scopes: ["openid", "profile"],
               contacts: ["ops@example.test"],
               logo_uri: "https://client.example.test/logo.svg"
             })

    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}/edit")

    assert html =~ "Save app changes"
    assert html =~ "Back to app details"
    refute html =~ "Save metadata"

    error_html =
      view
      |> form(".lockspire-admin-form-shell form", %{
        client: %{
          mode: "edit",
          name: "Attempted client name",
          allowed_scopes: "",
          dpop_policy: "bearer"
        }
      })
      |> render_submit()

    assert error_html =~ "App changes were not saved."
    assert error_html =~ ~s(role="alert")
    assert error_html =~ ~s(tabindex="-1")
    assert error_html =~ ~s(data-lockspire-focus-on-insert="true")
    assert error_html =~ ~s(id="client_allowed_scopes-error")

    assert error_html =~
             ~s(data-described-by="client_allowed_scopes-help client_allowed_scopes-entry-help client_allowed_scopes-error")

    assert error_html =~ "Add at least one permission (OAuth scope)."
    refute error_html =~ "invalid_scope"
    assert error_html =~ ~s(value="Attempted client name")
    assert error_html =~ ~s(value="ops@example.test")
    assert error_html =~ "https://client.example.test/logo.svg"

    assert {:ok, unchanged_client} = Admin.get_client(client.client_id)
    assert unchanged_client.name == "Security Show Client"
    assert unchanged_client.allowed_scopes == ["openid", "profile"]
    assert unchanged_client.contacts == ["ops@example.test"]
  end

  test "editing one metadata field preserves stored destinations and scopes", %{client: client} do
    redirect_uri = "https://client.example.com/callback"
    logout_redirect_uri = "https://client.example.com/signed-out"

    assert {:ok, _stored_client} =
             Admin.update_client(client.client_id, %{
               redirect_uris: [redirect_uri],
               post_logout_redirect_uris: [logout_redirect_uri],
               allowed_scopes: ["openid", "profile"]
             })

    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}/edit")
    assert html =~ ~s(id="client-edit-form")

    view
    |> form("#client-edit-form", %{client: %{mode: "edit", name: "Updated client name"}})
    |> render_submit()

    assert {:ok, updated_client} = Admin.get_client(client.client_id)
    assert updated_client.name == "Updated client name"
    assert updated_client.redirect_uris == [redirect_uri]
    assert updated_client.post_logout_redirect_uris == [logout_redirect_uri]
    assert updated_client.allowed_scopes == ["openid", "profile"]
  end

  test "redirect editors keep long safe destinations complete and separate", %{client: client} do
    redirect_uri =
      "https://client.example.com/" <> String.duplicate("long-path-segment/", 12) <> "callback"

    post_logout_uri =
      "https://client.example.com/" <>
        String.duplicate("logout-path-segment/", 12) <> "signed-out"

    assert {:ok, _stored_client} =
             Admin.update_client(client.client_id, %{
               redirect_uris: [redirect_uri],
               post_logout_redirect_uris: [post_logout_uri]
             })

    assert {:ok, _redirect_view, redirect_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/redirects")

    HtmlAssertions.assert_page_contract!(redirect_html, labels: :required)

    assert redirect_html =~ "Sign-in return URLs"
    assert redirect_html =~ "one exact URL per line"

    [redirect_form] =
      Regex.run(~r/<form id="client-redirect-uris-form".*?<\/form>/s, redirect_html)

    assert redirect_form =~ redirect_uri
    refute redirect_form =~ post_logout_uri

    assert {:ok, _logout_view, logout_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/logout-uris")

    HtmlAssertions.assert_page_contract!(logout_html, labels: :required)

    assert logout_html =~ "Sign-out return URLs"

    [logout_form] =
      Regex.run(~r/<form id="client-post-logout-redirect-uris-form".*?<\/form>/s, logout_html)

    assert logout_form =~ post_logout_uri
    refute logout_form =~ redirect_uri
  end

  test "client detail summarizes the default and app access token format in plain language",
       %{client: client} do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Access token format"

    # A nil override means this app uses the provider default.
    assert html =~ "Default: JWT"
    assert html =~ "This app: Use provider default"
    assert html =~ "JWT"
  end

  test "client detail effective access token format reflects an opaque override over the server default",
       %{client: client} do
    assert {:ok, _opaque_client} =
             Admin.update_client(client.client_id, %{access_token_format: :opaque})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Access token format"
    assert html =~ "Opaque token"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp text_content(html) do
    html
    |> then(&Regex.replace(~r/<[^>]+>/u, &1, " "))
    |> String.replace(~r/\s+/u, " ")
  end

  defp render_show_html(client_id) do
    assert {:ok, socket} =
             Show.mount(%{"client_id" => client_id}, %{}, %Phoenix.LiveView.Socket{
               assigns: %{live_action: :show, __changed__: %{}}
             })

    assert {:noreply, socket} =
             Show.handle_params(
               %{"client_id" => client_id},
               "/admin/clients/#{client_id}",
               socket
             )

    rendered_to_string(Show.render(socket.assigns))
  end

  defp render_invalid_security_profile_html(client_id) do
    assert {:ok, socket} =
             Show.mount(%{"client_id" => client_id}, %{}, %Phoenix.LiveView.Socket{
               assigns: %{live_action: :security_profile, __changed__: %{}}
             })

    assert {:noreply, socket} =
             Show.handle_params(
               %{"client_id" => client_id},
               "/admin/clients/#{client_id}/security-profile",
               socket
             )

    assert {:noreply, socket} =
             Show.handle_event(
               "save_client",
               %{
                 "client" => %{
                   "mode" => "security_profile",
                   "security_profile" => "unsupported-profile",
                   "authorization_signed_response_alg" => ""
                 }
               },
               socket
             )

    rendered_to_string(Show.render(socket.assigns))
  end

  defp extract_copy_once_value(html) do
    [_, value] =
      Regex.run(
        ~r/<section class="[^"]*lockspire-admin-copy-once-secret[^"]*".*?<code[^>]*>([^<]+)<\/code>/s,
        html
      )

    value
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end

defmodule Lockspire.Web.Live.Admin.ClientsLive.ShowTest.ReadinessFailureRepo do
  def all(
        %Ecto.Query{from: %{source: {_table, Lockspire.Storage.Ecto.SigningKeyRecord}}},
        _opts
      ) do
    raise "simulated signing-key read failure"
  end

  def all(query, opts), do: Lockspire.TestRepo.all(query, opts)
  def one(query, opts \\ []), do: Lockspire.TestRepo.one(query, opts)
end
