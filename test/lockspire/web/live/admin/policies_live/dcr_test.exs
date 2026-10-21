defmodule Lockspire.Web.Live.Admin.PoliciesLive.DcrTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr

  @endpoint Lockspire.Web.Endpoint

  @lifetime_fields [
    :dcr_default_client_lifetime_seconds,
    :dcr_default_client_secret_lifetime_seconds,
    :dcr_default_registration_access_token_lifetime_seconds
  ]

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

    :ok
  end

  test "router exposes global DCR policy management route" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies/dcr", Dcr))
  end

  test "global DCR policy page renders current mode" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{registration_policy: :initial_access_token})

    assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "App registration settings"
    assert html =~ "Registration rules"
    assert html =~ "Save app registration settings"
    assert html =~ "App setup token required"
    assert html =~ "Apps need a one-time setup token to register."

    assert has_element?(
             view,
             ~s(.lockspire-admin-secondary-nav a[href="/admin/policies/dcr"][aria-current="page"][data-phx-link="redirect"])
           )

    assert has_element?(
             view,
             ~s(input[type="radio"][name="policy[registration_policy]"][value="initial_access_token"][checked])
           )

    refute html =~ "Review these settings"
  end

  test "disabled registration clearly says apps cannot register themselves" do
    assert {:ok, _policy} = ServerPolicy.put_dcr_policy(%{registration_policy: :disabled})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "Disabled"
    assert html =~ "Apps cannot register themselves."
  end

  test "failed policy read is unavailable and can be reloaded" do
    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicyReadRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

      text = rendered_text(html)

      assert text =~ "Could not load app registration settings"
      assert text =~ "Reload settings"
      refute text =~ "Who can register"
      refute text =~ "Disabled"
      refute text =~ "Save app registration settings"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "global DCR policy page renders one grouped workflow form with unchanged fields" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    HtmlAssertions.assert_page_contract!(html, labels: :required)
    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

    assert occurrence_count(html, ~s(id="dcr-policy-form")) == 1
    assert html =~ "Save app registration settings"
    assert html =~ "These rules apply to new app registrations only."

    assert rendered_text(html) =~ "Leave blank or enter 0 for no automatic expiry."
    assert rendered_text(html) =~ "A positive duration applies to new or replaced app management tokens."
    assert rendered_text(html) =~ "Changing this setting does not change existing app management tokens."
    assert rendered_text(html) =~ "Expiry blocks reading, updating or deleting the app's registration until an authorized team member rotates the token."
    assert rendered_text(html) =~ "Rotating the token does not renew the app or its client secret."
    refute rendered_text(html) =~ "Lockspire saves this value but doesn't expire these tokens."
    for name <- [
          "policy[registration_policy]",
          "policy[dcr_allowed_scopes]",
          "policy[dcr_allowed_grant_types]",
          "policy[dcr_allowed_response_types]",
          "policy[dcr_allowed_redirect_uri_schemes]",
          "policy[dcr_allowed_redirect_uri_hosts]",
          "policy[dcr_allowed_token_endpoint_auth_methods]",
          "policy[dcr_default_client_lifetime_seconds]",
          "policy[dcr_default_client_secret_lifetime_seconds]",
          "policy[dcr_default_registration_access_token_lifetime_seconds]"
        ] do
      assert html =~ ~s(name="#{name}")
    end

    for heading <- [
          "Who can register",
          "What apps may request",
          "Expiry limits",
          "How apps authenticate"
        ] do
      assert html =~ heading
    end

    assert occurrence_count(html, "lockspire-admin-workflow-shell") >= 4
    assert html =~ "Disabled"
    assert html =~ "Registration access"
    assert html =~ "App setup token required"
    assert html =~ "Open"
    assert html =~ "Apps can register without a setup token, within the configured limits."

    assert html =~ "private_key_jwt"
    assert html =~ "client_secret_jwt"
    assert html =~ "Allowed permissions (OAuth scopes)"
    assert html =~ "Allowed authentication methods"
    refute String.downcase(rendered_text(html)) =~ "issuer"
    refute String.downcase(rendered_text(html)) =~ "posture"
    refute html =~ "operators expect"
    refute html =~ "extreme caution"
  end

  test "registration policy preview reflects edits without saving them" do
    assert {:ok, view, initial_html} = live(conn_for_admin(), "/admin/policies/dcr")
    assert initial_html =~ "Apps cannot register themselves."

    html =
      view
      |> render_change("preview_policy", %{
        "policy" => %{
          "registration_policy" => "open",
          "dcr_allowed_scopes" => "email, profile",
          "dcr_allowed_grant_types" => "authorization_code, refresh_token",
          "dcr_allowed_response_types" => "code",
          "dcr_allowed_redirect_uri_schemes" => "https",
          "dcr_allowed_redirect_uri_hosts" => "apps.example.com",
          "dcr_allowed_token_endpoint_auth_methods" => "none, client_secret_basic",
          "dcr_default_client_lifetime_seconds" => "3600",
          "dcr_default_client_secret_lifetime_seconds" => "7200",
          "dcr_default_registration_access_token_lifetime_seconds" => "1800"
        }
      })

    text = rendered_text(html)
    assert text =~ "Apps can register without a setup token"
    assert html =~ ~s(data-values="email, profile")
    assert html =~ ~s(data-values="authorization_code, refresh_token")
    assert html =~ ~s(data-values="code")
    assert text =~ "No client secret"
    assert text =~ "Client secret in the request header"
    assert html =~ ~s(data-values="https")
    assert html =~ ~s(data-values="apps.example.com")
    assert policy_control(html, "dcr_default_client_secret_lifetime_seconds") =~ ~s(value="7200")

    assert policy_control(html, "dcr_default_registration_access_token_lifetime_seconds") =~
             ~s(value="1800")

    refute html =~ "Review these settings"

    assert {:ok, policy} = ServerPolicy.get_server_policy()
    assert policy.registration_policy == :disabled

    blank_limits_html =
      render_change(view, "preview_policy", %{
        "policy" => %{
          "dcr_default_client_lifetime_seconds" => "",
          "dcr_default_client_secret_lifetime_seconds" => " ",
          "dcr_default_registration_access_token_lifetime_seconds" => ""
        }
      })

    assert rendered_text(blank_limits_html) =~
             "Lockspire enforces app expiry for new apps and secret expiry for new or replaced app secrets. App management-token expiry is not enforced yet."

    assert rendered_text(blank_limits_html) =~
             "Lockspire stops an app from using OAuth when its expiry date is reached. This setting applies to new apps."

    assert rendered_text(blank_limits_html) =~
             "No automatic expiry"

    assert rendered_text(blank_limits_html) =~
             "For example, 2592000 is 30 days. Leave blank or enter 0 for no automatic expiry. A positive value applies to new or replaced app secrets. Changing this setting does not change expiry on existing app secrets. Some older apps may have an advisory expiry date; replacing the secret sets its new expiry using the current setting."

    refute has_element?(view, ".lockspire-admin-field-errors")
  end

  test "global DCR policy page keeps long allowlists wrapped and public-only" do
    long_host =
      "partner-#{String.duplicate("deep-subdomain-", 8)}registration.example.internal"

    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_scopes: ["openid", "profile", "partner.deep.audit.read"],
               dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
               dcr_allowed_response_types: ["code"],
               dcr_allowed_redirect_uri_schemes: ["https"],
               dcr_allowed_redirect_uri_hosts: ["partners.example.com", long_host],
               dcr_allowed_token_endpoint_auth_methods: [
                 "private_key_jwt",
                 "client_secret_jwt",
                 "client_secret_basic"
               ],
               dcr_default_client_lifetime_seconds: 86_400,
               dcr_default_client_secret_lifetime_seconds: 3_600,
               dcr_default_registration_access_token_lifetime_seconds: 900
             })

    html = render_policy_html()

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    HtmlAssertions.assert_no_text(
      html,
      forbidden_secret_samples() ++ unsupported_policy_controls()
    )

    assert occurrence_count(html, ~s(id="dcr-policy-form")) == 1
    assert html =~ "Registration access"
    assert html =~ "Open"
    assert html =~ "partner.deep.audit.read"
    assert html =~ long_host
    assert html =~ "Expiry limits"
    assert html =~ "private_key_jwt"
    assert html =~ "client_secret_jwt"
    assert html =~ "client_secret_basic"

    refute html =~ "self-service"
  end

  test "CONFIG-03 D-01 D-02 D-03 D-04 D-09 D-10 DCR policy scope stays global and future-only" do
    html = render_policy_html()

    assert occurrence_count(html, ~s(id="dcr-policy-form")) == 1
    assert html =~ "Save app registration settings"
    text = rendered_text(html)
    assert text =~ "These rules apply to new app registrations only."
    assert text =~ "Existing apps and their credentials stay unchanged."
    assert text =~ "Apps can register without a setup token, within the configured limits."

    HtmlAssertions.assert_no_text(html, [
      "Mint initial access token",
      "Rotate registration access token",
      "Rotate client secret",
      "Add app",
      "Disable app",
      "Enable app",
      "host tenant policy",
      "developer portal",
      "Reveal secret",
      "Reveal token",
      "Export credential",
      "Approve DCR request",
      "Deny DCR request",
      "Fetch remote key",
      "Force publish",
      "Tenant policy editor",
      "client_secret_hash",
      "registration_access_token_hash",
      "BEGIN PRIVATE KEY",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ])
  end

  test "app registration settings explain private-key client authentication" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_token_endpoint_auth_methods: ["private_key_jwt", "client_secret_basic"]
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "private_key_jwt"
    assert html =~ "Apps sign assertions with a private key"
    assert html =~ "RS256, ES256, PS256, EdDSA"
    assert html =~ "jwks_uri"
  end

  test "app registration settings explain shared-secret client authentication" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_token_endpoint_auth_methods: [
                 "client_secret_jwt",
                 "client_secret_basic"
               ]
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "client_secret_jwt"
    assert html =~ "Apps sign assertions with their shared secret"
    assert html =~ "HS256"
  end

  test "saving global DCR policy persists change" do
    assert {:ok, _policy} = ServerPolicy.put_dcr_policy(%{registration_policy: :disabled})

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    html =
      view
      |> form("form#dcr-policy-form", %{
        policy: %{
          registration_policy: "open",
          dcr_allowed_scopes: "openid, email"
        }
      })
      |> render_submit(%{
        policy: %{dcr_allowed_token_endpoint_auth_methods: "private_key_jwt, client_secret_basic"}
      })

    text = rendered_text(html)
    assert text =~ "App registration settings saved."
    assert text =~ "Existing apps are unchanged."

    assert {:ok, policy} = ServerPolicy.get_server_policy()
    assert policy.registration_policy == :open
    assert policy.dcr_allowed_scopes == ["openid", "email"]

    assert policy.dcr_allowed_token_endpoint_auth_methods == [
             "private_key_jwt",
             "client_secret_basic"
           ]
  end

  test "invalid input shows form errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    html =
      view
      |> render_submit("save_policy", %{
        policy: %{registration_policy: "open", dcr_default_client_lifetime_seconds: "-100"}
      })

    text = rendered_text(html)
    assert text =~ "Enter zero or a positive number of seconds."
    assert html =~ ~s(id="dcr_default_client_lifetime_seconds-error")
    client_lifetime_control = policy_control(html, "dcr_default_client_lifetime_seconds")
    assert client_lifetime_control =~ ~s(value="-100")

    assert client_lifetime_control =~
             ~s(aria-describedby="dcr_default_client_lifetime_seconds-help dcr_default_client_lifetime_seconds-info dcr_default_client_lifetime_seconds-duration dcr_default_client_lifetime_seconds-error")

    HtmlAssertions.assert_no_text(html, [
      "Ecto.Changeset",
      "Postgrex",
      "Lockspire.Storage",
      "constraint",
      "stacktrace"
    ])
  end

  test "lifetime inputs show a readable duration as the operator types" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    html =
      render_change(view, "preview_policy", %{
        "policy" => %{
          "dcr_default_client_lifetime_seconds" => "86400",
          "dcr_default_client_secret_lifetime_seconds" => "180000",
          "dcr_default_registration_access_token_lifetime_seconds" => "7200"
        }
      })

    assert duration_hint(html, "dcr_default_client_lifetime_seconds") == "1 day"
    assert duration_hint(html, "dcr_default_client_secret_lifetime_seconds") == "≈ 2.1 days"

    assert duration_hint(html, "dcr_default_registration_access_token_lifetime_seconds") ==
             "2 hours"

    html =
      render_change(view, "preview_policy", %{
        "policy" => %{"dcr_default_client_secret_lifetime_seconds" => "0"}
      })

    assert duration_hint(html, "dcr_default_client_secret_lifetime_seconds") ==
             "No automatic expiry"

    assert has_element?(
             view,
             "#dcr_default_client_secret_lifetime_seconds-info[role=tooltip]",
             "A positive value applies to new or replaced app secrets"
           )
  end

  test "every lifetime rejects negative, fractional, malformed and overflowing values before saving" do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies/dcr")
    assert {:ok, original_policy} = ServerPolicy.get_server_policy()

    for field <- @lifetime_fields do
      control = policy_control(html, Atom.to_string(field))
      assert control =~ ~s(min="0")
      assert control =~ ~s(max="2147483647")
      assert control =~ ~s(step="1")
      assert control =~ ~s(inputmode="numeric")

      for {value, message} <- [
            {"-1", "Enter zero or a positive number of seconds."},
            {"1.5", "Enter a whole number of seconds, such as 60."},
            {"not-a-number", "Enter a whole number of seconds, such as 60."},
            {"2147483648", "Enter 2,147,483,647 seconds or less."}
          ] do
        params = lifetime_params(value, field)
        changed = render_change(view, "preview_policy", %{"policy" => params})
        assert changed =~ message
        assert has_element?(view, "##{field}-error")
        assert has_element?(view, "##{field}-error li", message)
        refute has_element?(view, ".lockspire-admin-error-summary")
        assert policy_control(changed, Atom.to_string(field)) =~ ~s(aria-invalid="true")

        submitted = render_submit(view, "save_policy", %{"policy" => params})
        assert submitted =~ message
        assert has_element?(view, ".lockspire-admin-error-summary")
        assert policy_control(submitted, Atom.to_string(field)) =~ ~s(value="#{value}")
        assert {:ok, ^original_policy} = ServerPolicy.get_server_policy()
      end

      corrected =
        render_change(view, "preview_policy", %{"policy" => lifetime_params("60", field)})

      refute has_element?(view, "##{field}-error")
      assert policy_control(corrected, Atom.to_string(field)) =~ ~s(aria-invalid="false")
      assert {:ok, ^original_policy} = ServerPolicy.get_server_policy()
    end
  end

  test "every lifetime preserves blank, zero and supported whole-number boundaries" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    for {value, expected} <- [{"", nil}, {"0", 0}, {"1", 1}, {"2147483647", 2_147_483_647}] do
      params =
        @lifetime_fields
        |> Map.new(&{Atom.to_string(&1), value})
        |> Map.put("registration_policy", "disabled")

      html = render_submit(view, "save_policy", %{"policy" => params})
      assert html =~ "App registration settings saved."
      refute has_element?(view, ".lockspire-admin-field-errors")
      assert {:ok, policy} = ServerPolicy.get_server_policy()
      for field <- @lifetime_fields, do: assert(Map.fetch!(policy, field) == expected)
    end
  end

  defp lifetime_params(value, selected_field) do
    @lifetime_fields
    |> Map.new(&{Atom.to_string(&1), ""})
    |> Map.put("registration_policy", "disabled")
    |> Map.put(Atom.to_string(selected_field), value)
  end

  test "failed settings save keeps submitted values and explains the result" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicySaveRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      html =
        render_submit(view, "save_policy", %{
          policy: %{
            registration_policy: "open",
            dcr_allowed_scopes: "openid, partner.audit.read",
            dcr_default_client_lifetime_seconds: "3600"
          }
        })

      text = rendered_text(html)
      assert text =~ "App registration settings were not saved"
      assert html =~ ~s(data-values="openid, partner.audit.read")
      assert policy_control(html, "dcr_default_client_lifetime_seconds") =~ ~s(value="3600")
      refute text =~ "App registration settings saved"
      refute text =~ "UndefinedFunctionError"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp occurrence_count(html, pattern) do
    html
    |> String.split(pattern)
    |> length()
    |> Kernel.-(1)
  end

  defp rendered_text(html) do
    html
    |> String.replace(~r/<style\b[^>]*>.*?<\/style>/s, " ")
    |> String.replace(~r/<script\b[^>]*>.*?<\/script>/s, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp duration_hint(html, id) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("##{id}-duration")
    |> LazyHTML.text()
    |> String.trim()
  end

  defp policy_control(html, id) do
    case Regex.run(~r/<(?:input|select)\b[^>]*\bid="#{Regex.escape(id)}"[^>]*>/, html) do
      [tag] -> tag
      _ -> ""
    end
  end

  defp render_policy_html do
    assert {:ok, socket} = Dcr.mount(%{}, %{}, socket_for(:dcr))
    rendered_to_string(Dcr.render(socket.assigns))
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp forbidden_secret_samples do
    [
      "real-client-secret",
      "production-secret",
      "prod-access-token",
      "prod-refresh-token",
      "sk_live_",
      "pk_live_",
      "eyJhbGci",
      "BEGIN PRIVATE KEY"
    ]
  end

  defp unsupported_policy_controls do
    [
      "Mint initial access token",
      "Rotate registration access token",
      "Rotate client secret",
      "Add app",
      "Disable app",
      "Enable app",
      "host tenant policy",
      "developer portal",
      "Reveal secret",
      "Reveal token",
      "Export credential",
      "Approve DCR request",
      "Deny DCR request",
      "Fetch remote key",
      "Force publish",
      "Tenant policy editor",
      "client_secret_hash",
      "registration_access_token_hash",
      "BEGIN PRIVATE KEY",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ]
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
