defmodule Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfileTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile

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
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

    {:ok, _inherit_client} =
      Repository.register_client(%Client{
        client_id: "security-inherit",
        client_type: :confidential,
        security_profile: :inherit
      })

    {:ok, _fapi_client} =
      Repository.register_client(%Client{
        client_id: "security-fapi",
        client_type: :public,
        security_profile: :fapi_2_0_security
      })

    {:ok, _message_signing_client} =
      Repository.register_client(%Client{
        client_id: "security-message-signing",
        client_type: :confidential,
        security_profile: :fapi_2_0_message_signing
      })

    {:ok, _none_client} =
      Repository.register_client(%Client{
        client_id: "security-none",
        client_type: :public,
        security_profile: :none
      })

    :ok
  end

  test "router exposes global security profile management route" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(
             routes,
             &live_route?(&1, "/admin/policies/security-profile", SecurityProfile)
           )
  end

  test "global security profile page renders current mode nav and override summary" do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

    assert html =~ "Global security profile"
    assert html =~ "Save global security profile"
    assert html =~ "Current profile is None (Standard OIDC)"
    assert html =~ "PAR"
    assert html =~ "Security Profile"
    assert html =~ "DPoP"
    assert html =~ "DCR"
    assert html =~ "Signing-key prerequisites for FAPI 2.0 Message Signing."
    assert html =~ "FAPI 2.0 Message Signing"
    assert html =~ "client requires strict message signing"
    assert html =~ "client inherits"
    assert html =~ "client requires FAPI 2.0"
    assert html =~ "client forces None"
    assert html =~ "Publish an ES256 or PS256 issuer signing key"
    assert html =~ "Key prerequisites missing"
    assert html =~ "Readiness details:"
  end

  test "failed policy read is shown as unavailable and can be reloaded" do
    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicyReadRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

      assert html =~ "Could not load global security profile"
      assert html =~ "Reload policy"
      refute html =~ ~s(name="policy[security_profile]")
      refute html =~ "Save global security profile"

      Application.put_env(:lockspire, :repo, prior_repo)
      html = render_click(view, "reload_policy")

      assert html =~ "Global security profile"
      assert html =~ "Save global security profile"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "failed strict-readiness read is unavailable instead of a confirmed prerequisite gap" do
    prior_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(:lockspire, :repo, __MODULE__.ReadinessFailureRepo)

      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

      assert html =~ "Status:</strong> Unavailable"
      assert html =~ "The signing-key check could not be completed. Readiness is unknown."
      assert html =~ "Unable to load strict message-signing readiness."
      refute html =~ "Key prerequisites missing"
      refute html =~ "The key check below identifies what is missing"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "CONFIG-01 CONFIG-03 D-03 D-04 D-05 D-09 D-10 security profile copy explains exact scope and key prerequisites" do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

    assert html =~ "Configure"
    assert html =~ "Global security profile"
    assert html =~ "Strict readiness"
    assert html =~ "Clients that inherit"
    assert html =~ "Next safe action"
    assert html =~ "Save global security profile"
    assert html =~ "clients without a security-profile choice of their own"
    assert html =~ "PAR, DPoP-bound access tokens, and S256 PKCE"

    assert html =~
             "a JWT introspection response selected with `Accept: application/token-introspection+jwt`"

    assert html =~ "Signing-key prerequisites for FAPI 2.0 Message Signing."
    assert html =~ "Key prerequisites missing"

    assert html =~
             "The key check below identifies what is missing before FAPI 2.0 Message Signing can be enabled."

    refute String.downcase(html) =~ "operator"

    for href <- policy_nav_hrefs() do
      HtmlAssertions.assert_has_link(html, href)
    end

    HtmlAssertions.assert_no_text(html, [
      "host staff authentication",
      "host MFA",
      "role management",
      "role-management",
      "tenant policy editor",
      "Tenant policy editor",
      "host-owned product policy",
      "developer portal",
      "Create client",
      "Disable client",
      "Enable client",
      "Rotate client secret",
      "Rotate registration access token",
      "Reset nonce",
      "Inspect proof",
      "Raw proof",
      "Debug token",
      "Fetch remote key",
      "Remote key fetch",
      "Reveal secret",
      "Export credential",
      "private key export",
      "public theming",
      "AI judge",
      "AI gate",
      "browser gate",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ])
  end

  test "saving global security profile persists change across reload" do
    assert {:ok, _policy} = Admin.put_security_profile(:none)
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    now = DateTime.utc_now()

    Lockspire.Storage.Ecto.Repository.publish_key(%Lockspire.Domain.SigningKey{
      kid: "fapi-compliant-key-3",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "kid" => "fapi-compliant-key-3",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    view
    |> form("form[phx-submit=save_policy]", %{
      policy: %{security_profile: "fapi_2_0_message_signing"}
    })
    |> render_submit()

    assert {:ok, %{security_profile: :fapi_2_0_message_signing}} = Admin.get_server_policy()

    assert {:ok, _reloaded_view, html} =
             live(conn_for_admin(), "/admin/policies/security-profile")

    assert html =~ "Current profile is FAPI 2.0 Message Signing"
    assert html =~ "Status:</strong> Active; key prerequisites met"
    assert html =~ "FAPI 2.0 Message Signing is active."
  end

  test "invalid global security profile values return field errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    html =
      view
      |> render_submit("save_policy", %{policy: %{security_profile: "invalid"}})

    assert html =~
             "Choose None (Standard OIDC), FAPI 2.0 Security Profile, or FAPI 2.0 Message Signing."

    refute html =~ "invalid_security_profile"
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())
    assert {:ok, %{security_profile: :none}} = Admin.get_server_policy()
  end

  test "message-signing save names the signing-key prerequisite" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    html =
      render_submit(view, "save_policy", %{
        policy: %{security_profile: "fapi_2_0_message_signing"}
      })

    assert html =~
             "Publish an ES256 or PS256 issuer signing key before enabling FAPI 2.0 Message Signing."

    refute html =~ "missing_compliant_publishable_key"
  end

  test "FAPI security save keeps its signing-key prerequisite distinct from message signing" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    html =
      render_submit(view, "save_policy", %{
        policy: %{security_profile: "fapi_2_0_security"}
      })

    assert html =~
             "Publish an ES256 or PS256 issuer signing key before enabling FAPI 2.0 Security Profile."

    refute html =~ "before enabling FAPI 2.0 Message Signing."
  end

  test "failed global security profile save stays unconfirmed" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicySaveRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      html =
        render_submit(view, "save_policy", %{
          policy: %{security_profile: "none"}
        })

      assert html =~ "The security profile change could not be confirmed."
      assert html =~ "Reload the policy to check its current value."
      refute html =~ "request_failed"
      refute html =~ "UnavailablePolicySaveRepo"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
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

  defp backend_leak_samples do
    [
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage",
      "stacktrace",
      "constraint violation",
      "private_jwk_encrypted"
    ]
  end

  defp policy_nav_hrefs do
    [
      "/admin/policies/par",
      "/admin/policies/security-profile",
      "/admin/policies/dpop",
      "/admin/policies/dcr"
    ]
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end

defmodule Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfileTest.ReadinessFailureRepo do
  def all(
        %Ecto.Query{from: %{source: {_table, Lockspire.Storage.Ecto.SigningKeyRecord}}},
        _opts
      ) do
    raise "simulated signing-key read failure"
  end

  def all(query, opts) do
    Lockspire.TestRepo.all(query, opts)
  end

  def one(query, opts \\ []), do: Lockspire.TestRepo.one(query, opts)
end
