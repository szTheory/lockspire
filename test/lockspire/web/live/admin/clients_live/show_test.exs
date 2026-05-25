defmodule Lockspire.Web.Live.Admin.ClientsLive.ShowTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
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
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/security-profile", Show))
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
    assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-show-client"
    refute html =~ "Edit JWKS"
    refute html =~ "Test fetch"
  end

  test "client detail keeps logout propagation separate from post-logout redirects", %{client: client} do
    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{
               backchannel_logout_uri: "https://client.example.com/backchannel",
               frontchannel_logout_uri: "https://client.example.com/frontchannel"
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Post-logout redirect URIs"
    assert html =~ "Logout propagation"
    assert html =~ "These logout propagation URIs stay separate from post-logout redirect URIs."
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
    assert html =~ "Status:"
    assert html =~ "incident"
    assert html =~ "remote_jwks_key_unavailable"
    assert html =~ "Publish the requested key alongside the previous key"
    assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-incident-client"
  end

  test "client detail shows the remote JWKS panel for JARM-only jwks_uri clients", %{client: client} do
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

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
