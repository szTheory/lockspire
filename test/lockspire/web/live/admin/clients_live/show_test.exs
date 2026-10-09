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

    assert missing_html =~ "Client not found"
    assert missing_html =~ "Return to client inventory"
    refute missing_html =~ "Could not load client"

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailableClientRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, _error_view, error_html} =
               live(conn_for_admin(), "/admin/clients/security-show-client")

      assert error_html =~ "Could not load client"
      assert error_html =~ "The client result is unavailable."
      assert error_html =~ "Reload this view"
      refute error_html =~ "Client not found"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
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

    assert html =~ "Global security profile"
    assert html =~ "Client security override"
    assert html =~ "Effective security profile"
    assert html =~ "Strict message-signing posture"
    assert html =~ "Mixed-mode escape hatch"
    assert html =~ "Warning:"
    assert html =~ "mixed-mode bypass"
  end

  test "unavailable issuer policy is shown as unavailable instead of a default", %{
    client: client
  } do
    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_server_policies", [])

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Issuer policy is unavailable"

    assert html =~
             "The client overrides are still shown, but issuer defaults and effective behavior could not be loaded."

    visible = text_content(html)
    assert visible =~ "Global security profile Unavailable"
    assert visible =~ "Global PAR policy Unavailable"
    assert visible =~ "Global access token format Unavailable"
    refute visible =~ "Global security profile none"
    refute visible =~ "Global PAR policy optional"
    refute visible =~ "Global access token format jwt"
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
    assert edit_text =~ "Issuer default: DPoP-bound access tokens"
    assert edit_text =~ "Selected client override: Inherit from issuer"
    assert edit_text =~ "Effective behavior if saved: DPoP-bound access tokens"
    assert edit_text =~ "Issuer default: Opaque"
    assert edit_text =~ "Effective behavior if saved: Opaque"

    changed_edit_html =
      edit_view
      |> form("#client-edit-form", %{
        client: %{mode: "edit", dpop_policy: "bearer", access_token_format: "jwt"}
      })
      |> render_change()

    changed_edit_text = text_content(changed_edit_html)
    assert changed_edit_text =~ "Selected client override: Use bearer access tokens"
    assert changed_edit_text =~ "Effective behavior if saved: Bearer access tokens"
    assert changed_edit_text =~ "Selected client override: JWT (RFC 9068 at+jwt)"
    assert changed_edit_text =~ "Effective behavior if saved: JWT (RFC 9068 at+jwt)"

    assert {:ok, par_view, par_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/par-policy")

    par_text = text_content(par_html)
    assert par_text =~ "Issuer default: Required"
    assert par_text =~ "Selected client override: Inherit from issuer"
    assert par_text =~ "Effective behavior if saved: Required"

    changed_par_html =
      par_view
      |> form("#client-par-policy-form", %{client: %{mode: "par_policy", par_policy: "optional"}})
      |> render_change()

    changed_par_text = text_content(changed_par_html)

    assert changed_par_text =~
             "Selected client override: Allow requests without PAR for this client"

    assert changed_par_text =~ "Effective behavior if saved: Optional"

    assert {:ok, security_view, security_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/security-profile")

    security_text = text_content(security_html)
    assert security_text =~ "Issuer default: FAPI 2.0 Security Profile"
    assert security_text =~ "Selected client override: Inherit from issuer"
    assert security_text =~ "Effective behavior if saved: FAPI 2.0 Security Profile"

    changed_security_html =
      security_view
      |> form("#client-security-profile-form", %{
        client: %{mode: "security_profile", security_profile: "none"}
      })
      |> render_change()

    changed_security_text = text_content(changed_security_html)
    assert changed_security_text =~ "Selected client override: None (Standard OIDC)"
    assert changed_security_text =~ "Effective behavior if saved: None (Standard OIDC)"

    invalid_security_html = render_invalid_security_profile_html(client.client_id)

    invalid_security_text = text_content(invalid_security_html)
    assert invalid_security_text =~ "Client security profile was not saved."
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

    assert html =~ "Update security profile"
    assert html =~ "Client security profile override"
    assert html =~ "Inherit from global policy"
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
    |> form("form[phx-submit=save_client]", %{
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
    assert html_after =~ "Effective profile:"
    assert html_after =~ "FAPI 2.0 Message Signing"
    assert html_after =~ "Strict readiness:"
    assert html_after =~ "Ready"
  end

  test "client detail shows canonical remediation when strict message signing is selected but not ready",
       %{client: client} do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_message_signing})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Strict message-signing posture"
    assert html =~ "Strict message signing enforced"
    assert html =~ "Blocked"
    assert html =~ "Publish an ES256 or PS256 issuer signing key"
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
    assert html =~ "Review client configuration"

    for group <- [
          "Identity and current status",
          "Effective posture",
          "Credentials and assertion keys",
          "Endpoints and logout",
          "DCR and RAT context",
          "Support pivots",
          "Lifecycle and destructive actions"
        ] do
      assert html =~ group
    end

    assert html =~ "lockspire-admin-action-group"
    assert html =~ "lockspire-admin-action-group__primary"
    assert html =~ "lockspire-admin-action-group__secondary"
    assert html =~ "lockspire-admin-confirmation-panel"
    assert html =~ "/admin/clients/#{self_registered_client.client_id}/edit"
    assert html =~ "Edit client metadata"
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
    assert html =~ "Rotate registration access token"
    assert html =~ "Registration access token"
    assert html =~ "Redacted"
    assert html =~ "Review DCR onboarding"
    assert html =~ "/admin/dcr"
    assert html =~ "Edit redirect URIs"
    assert html =~ "Edit post-logout redirect URIs"
    assert html =~ "Edit logout propagation URIs"
    assert html =~ "Edit PAR policy"
    assert html =~ "Edit security profile"
    assert html =~ ~s(phx-submit="toggle_client")
    assert html =~ ~s(name="toggle[confirm]")
    assert html =~ "Confirm client disable"
    assert html =~ "Disable client"

    assert html =~
             "future OAuth/OIDC requests for this client are blocked until an operator enables it again"

    assert html =~ "Registration access token rotation is grouped with credential actions above."
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
    assert html =~ "Registration access token"
    assert html =~ "Review DCR onboarding"
    assert html =~ "No client-specific support mutation is introduced here."

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

    assert html =~ "Rotate client secret"
    assert html =~ "previous secret stops being the current credential"
    assert html =~ "Plaintext is shown once"
    assert html =~ "not stored"
    assert html =~ "token endpoint"
    assert html =~ ~s(phx-disable-with="Rotating client secret…")
    refute html =~ "sha256:show:hash"
    refute html =~ "client_secret_hash"

    html_after_rotate =
      view
      |> form("form[phx-submit=rotate_secret]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    assert html_after_rotate =~ "New client secret"
    assert html_after_rotate =~ "Plaintext is shown once"

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

    assert html =~ "Registration Access Token manages this client at its Registration Client URI"
    assert html =~ self_registered_client.registration_client_uri
    assert html =~ ~s(phx-disable-with="Rotating Registration Access Token…")

    rotated_html =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    plaintext_rat = extract_copy_once_value(rotated_html)
    assert rotated_html =~ "New Registration Access Token"

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
               "Rotation was not confirmed. No new Registration Access Token is shown."

      assert rat_error_html =~ "rat-failure-client"
      refute rat_error_html =~ "New Registration Access Token"
      refute rat_error_html =~ "sha256:rat:failure"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "client lifecycle changes require explicit confirmation", %{client: client} do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Confirm client disable"

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

    assert disabled_html =~ "Confirm client enable"
    assert disabled_html =~ "Enable client"
    assert disabled_html =~ "configured OAuth/OIDC use can resume"
    HtmlAssertions.assert_no_text(disabled_html, ["data-confirm", "force enable"])
  end

  test "client detail support pivots link to supported logout queue route", %{client: client} do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Support pivots"
    assert html =~ "Review logout deliveries"
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

    assert html =~ "Client assertion keys"
    assert html =~ "Remote JWKS URI configured"
    assert html =~ "https://client.example.com/.well-known/jwks.json"
    assert html =~ "private_key_jwt"
    assert html =~ "RS256, ES256, PS256, EdDSA"
    assert html =~ "Remote JWKS"
    assert html =~ "bounded reactive rollover support"
    assert html =~ "fails the current request closed"
    assert html =~ "Lockspire owns the guarded fetch, cache, refresh, and verify path"
    assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-show-client"
    refute html =~ "Edit JWKS"
    refute html =~ "Test fetch"
  end

  test "client detail keeps logout propagation separate from post-logout redirects", %{
    client: client
  } do
    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{
               backchannel_logout_uri: "https://client.example.com/backchannel",
               frontchannel_logout_uri: "https://client.example.com/frontchannel"
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Post-logout redirect URIs"
    assert html =~ "Post-logout redirect URIs are browser destinations after RP-initiated logout."
    assert html =~ "Logout propagation URIs are RP cleanup endpoints."
    assert html =~ "These logout propagation endpoints stay separate from browser destinations."
    assert html =~ "/admin/clients/#{client.client_id}/edit?workflow=logout-propagation"
    assert html =~ "/end_session/complete"
    assert html =~ "Front-channel logout remains best effort browser cleanup."
  end

  test "logout propagation editor explains the durable back-channel and best-effort front-channel split",
       %{client: client} do
    assert {:ok, _view, html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{client.client_id}/edit?workflow=logout-propagation"
             )

    assert html =~ "Update logout propagation"
    assert html =~ "Separate concern:"
    assert html =~ "not post-logout redirects"
    assert html =~ "/end_session/complete"
    assert html =~ "durable back-channel delivery"
    assert html =~ "front-channel logout stays best effort"
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

    assert html =~ "Shared JWT client secret posture"
    assert html =~ "client_secret_jwt"
    assert html =~ "HS256"
    refute html =~ "verifier material"
  end

  test "edit form renders the access_token_format override select with doclink and persists the choice",
       %{client: client} do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}/edit")

    assert html =~ "Access token format override"
    assert html =~ ~s(name="client[access_token_format]")
    assert html =~ ~s(value="inherit")
    assert html =~ ~s(value="jwt")
    assert html =~ ~s(value="opaque")
    assert html =~ "Inherit from server default"
    assert html =~ "JWT (RFC 9068 at+jwt)"
    assert html =~ "Opaque (Lockspire-stored)"
    assert html =~ "docs/protect-phoenix-api-routes.md"
    assert html =~ "Learn when to choose JWT vs opaque"

    # A client with nil override pre-selects the inherit option.
    assert html =~ ~r/<option value="inherit"[^>]*selected/

    view
    |> form("form[phx-submit=save_client]", %{
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
    assert html_after =~ "Client changes saved."
    assert html_after =~ "Review client configuration"
    refute html_after =~ "Save client changes"
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

    assert html =~ "Save client changes"
    assert html =~ "Return to client details"
    refute html =~ "Save metadata"

    error_html =
      view
      |> form("form[phx-submit=save_client]", %{
        client: %{
          mode: "edit",
          name: "Attempted client name",
          allowed_scopes: "",
          dpop_policy: "bearer"
        }
      })
      |> render_submit()

    assert error_html =~ "Client changes were not saved."
    assert error_html =~ ~s(role="alert")
    assert error_html =~ ~s(tabindex="-1")
    assert error_html =~ ~s(id="client_allowed_scopes-error")
    assert error_html =~ ~s(aria-describedby="client_allowed_scopes-error")
    assert error_html =~ "Enter at least one allowed scope."
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

    assert redirect_html =~ "Redirect URIs"
    assert redirect_html =~ "exactly"

    [redirect_form] =
      Regex.run(~r/<form id="client-redirect-uris-form".*?<\/form>/s, redirect_html)

    assert redirect_form =~ redirect_uri
    refute redirect_form =~ post_logout_uri

    assert {:ok, _logout_view, logout_html} =
             live(conn_for_admin(), "/admin/clients/#{client.client_id}/logout-uris")

    assert logout_html =~ "Post-logout redirect URIs"

    [logout_form] =
      Regex.run(~r/<form id="client-post-logout-redirect-uris-form".*?<\/form>/s, logout_html)

    assert logout_form =~ post_logout_uri
    refute logout_form =~ redirect_uri
  end

  test "client detail shows global / override / effective access token format rows with nil as inherit",
       %{client: client} do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Global access token format"
    assert html =~ "Client access token override"
    assert html =~ "Effective access token format"

    # nil override renders as "inherit"; server default is :jwt, so effective is jwt.
    assert html =~ "inherit"
    assert html =~ "jwt"
  end

  test "client detail effective access token format reflects an opaque override over the server default",
       %{client: client} do
    assert {:ok, _opaque_client} =
             Admin.update_client(client.client_id, %{access_token_format: :opaque})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Effective access token format"
    assert html =~ "opaque"
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
