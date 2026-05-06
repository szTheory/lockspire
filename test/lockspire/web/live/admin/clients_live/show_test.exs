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

    assert {:ok, _policy} = Lockspire.Storage.Ecto.Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{id: 1})

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

  test "client detail shows effective security profile and mixed-mode warning", %{client: client} do
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

    assert {:ok, _policy} = Admin.put_security_profile(:fapi_2_0_security)

    assert {:ok, _updated_client} =
             Admin.update_client(client.client_id, %{security_profile: :none})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

    assert html =~ "Global security profile"
    assert html =~ "Client security override"
    assert html =~ "Effective security profile"
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
    assert html =~ "FAPI 2.0 Security Profile"

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
      client: %{mode: "security_profile", security_profile: "fapi_2_0_security"}
    })
    |> render_submit()

    assert {:ok, updated_client} = Admin.get_client(client.client_id)
    assert updated_client.security_profile == :fapi_2_0_security

    html_after = render(view)
    assert html_after =~ "Effective profile:"
    assert html_after =~ "FAPI 2.0 Security Profile"
  end

  test "client detail shows read-only private_key_jwt posture for jwks_uri clients", %{client: client} do
    assert {:ok, _policy} = Admin.put_dcr_policy(%{dcr_allowed_token_endpoint_auth_methods: ["private_key_jwt"]})

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
    refute html =~ "Edit JWKS"
    refute html =~ "Test fetch"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
