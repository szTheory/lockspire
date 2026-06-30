defmodule Lockspire.Web.Live.Admin.OverviewLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.OverviewLive.Index

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
    now = DateTime.utc_now()

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "overview-client",
        client_type: :confidential,
        name: "Overview Client",
        provenance: :self_registered,
        par_policy: :required,
        dpop_policy: :dpop,
        security_profile: :fapi_2_0_security
      })

    {:ok, _consent} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "overview-account",
        client_id: "overview-client",
        scopes: ["openid"],
        granted_at: now
      })

    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: "overview-token",
        token_type: :refresh_token,
        client_id: "overview-client",
        account_id: "overview-account",
        reuse_detected_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: "overview-interaction",
        client_id: "overview-client",
        return_to: "https://example.com/return",
        status: :pending_consent,
        expires_at: DateTime.add(now, 600, :second)
      })

    {:ok, _auth} =
      Repository.put_device_authorization(%DeviceAuthorization{
        device_code_hash: "overview-device",
        user_code_hash: "overview-user-code",
        verification_handle: "overview-device-handle",
        client_id: "overview-client",
        status: :pending,
        effective_poll_interval_seconds: 5,
        next_poll_allowed_at: now,
        expires_at: DateTime.add(now, 600, :second)
      })

    {:ok, _iat} =
      Repository.save_initial_access_token(%InitialAccessToken{
        token_hash: "overview-iat",
        expires_at: DateTime.add(now, 3600, :second),
        created_by: "test"
      })

    {:ok, _key} =
      Repository.publish_key(%SigningKey{
        kid: "overview-key",
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: %{"kty" => "RSA", "n" => "n", "e" => "AQAB"},
        private_jwk_encrypted: <<1>>,
        status: :active,
        published_at: now,
        activated_at: now
      })

    {:ok, logout_event} =
      %LogoutEventRecord{}
      |> LogoutEventRecord.changeset(%LogoutEvent{
        event_id: "overview-logout",
        completed_at: now
      })
      |> Lockspire.TestRepo.insert()
      |> case do
        {:ok, record} -> {:ok, LogoutEventRecord.to_domain(record)}
        other -> other
      end

    %LogoutDeliveryRecord{}
    |> LogoutDeliveryRecord.changeset(%LogoutDelivery{
      delivery_id: "overview-logout-delivery",
      logout_event_id: logout_event.id,
      client_id: "overview-client",
      channel: :backchannel,
      target_uri: "https://example.com/backchannel",
      status: :retryable,
      attempt_count: 2
    })
    |> Lockspire.TestRepo.insert!()

    :ok
  end

  test "router exposes source-derived overview routes" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/overview", Index))
  end

  test "overview renders operator cockpit metrics and journey links" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Operator cockpit"
    assert html =~ "Security posture"
    assert html =~ "Key readiness"
    assert html =~ "Support queue"
    assert html =~ "Live operations"
    assert html =~ "Refresh reuse incidents"
    assert html =~ "Active initial access tokens"
    assert html =~ "/admin/dcr"

    for href <- [
          "/admin/clients",
          "/admin/policies",
          "/admin/keys",
          "/admin/tokens?status=reuse_detected",
          "/admin/consents?status=active",
          "/admin/logouts",
          "/admin/interactions",
          "/admin/device_authorizations",
          "/admin/dcr"
        ] do
      HtmlAssertions.assert_has_link(html, href)
    end

    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    HtmlAssertions.assert_no_text(html, [
      "Rotate client secret",
      "Rotate registration access token",
      "Revoke token",
      "Revoke token family",
      "Disable client",
      "Enable client",
      "Retry logout delivery",
      "Discard logout delivery",
      "Approve DCR request",
      "Deny DCR request",
      "host tenant policy",
      "developer portal",
      "public theming",
      "AI judge",
      "browser gate"
    ])
  end

  test "security and DCR landing pages orient related workflows" do
    assert {:ok, _security_view, security_html} = live(conn_for_admin(), "/admin/policies")

    assert security_html =~ "Policy posture"
    assert security_html =~ "Dynamic Client Registration"
    assert security_html =~ "/admin/policies/dcr"

    assert {:ok, _dcr_view, dcr_html} = live(conn_for_admin(), "/admin/dcr")

    assert dcr_html =~ "DCR onboarding"
    assert dcr_html =~ "Mint initial access token"
    assert dcr_html =~ "Review self-registered clients"
    assert dcr_html =~ "Overview Client"
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
      "BEGIN PRIVATE KEY",
      "authorization_code=",
      "code_verifier="
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

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
