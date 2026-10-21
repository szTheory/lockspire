defmodule Lockspire.Web.Live.Admin.ClientsLive.ManagementTokenRecoveryTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])

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

    policy =
      DcrFixtures.server_policy(%{
        registration_policy: :open,
        dcr_default_registration_access_token_lifetime_seconds: 90
      })

    assert {:ok, _policy} = Repository.put_server_policy(policy)
    %{policy: policy}
  end

  test "confirmed recovery discloses a committed token once and preserves disabled lifecycle state",
       %{
         policy: _policy
       } do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    app_deadline = DateTime.add(now, -10, :second)
    secret_deadline = DateTime.add(now, 300, :second)
    management_deadline = DateTime.add(now, -1, :second)

    client =
      self_registered_client("recovery-once", now,
        active: false,
        disabled_at: now,
        disabled_by: "provider-operator",
        client_expires_at: app_deadline,
        client_secret_expires_at: secret_deadline,
        registration_access_token_expires_at: management_deadline
      )

    path = "/admin/clients/#{client.client_id}/rotate-registration-access-token"
    assert {:ok, view, html} = live(conn_for_admin(), path)
    assert html =~ client.client_id

    unconfirmed =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{}})
      |> render_submit()

    assert unconfirmed =~ "confirmation required"
    refute unconfirmed =~ "New app management token"
    {:ok, unchanged} = Repository.fetch_client_by_id(client.client_id)
    assert unchanged.registration_access_token_hash == client.registration_access_token_hash

    rotation_started_at = DateTime.utc_now() |> DateTime.truncate(:second)

    rotated_html =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    replacement = extract_copy_once_value(rotated_html)
    assert replacement != "previous-management-token"

    assert RegistrationAccessToken.verify(unchanged.registration_access_token_hash, replacement) ==
             false

    assert rotated_html =~ "New app management token"
    assert rotated_html =~ "The previous app management token stops working immediately."

    assert rotated_html =~
             "Rotating this token does not enable the app or extend app or client secret expiry."

    {:ok, after_rotation} = Repository.fetch_client_by_id(client.client_id)

    assert RegistrationAccessToken.verify(
             after_rotation.registration_access_token_hash,
             replacement
           )

    assert after_rotation.active == false
    assert DateTime.compare(after_rotation.disabled_at, now) == :eq
    assert DateTime.compare(after_rotation.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(after_rotation.client_secret_expires_at, secret_deadline) == :eq

    assert DateTime.diff(
             after_rotation.registration_access_token_expires_at,
             rotation_started_at,
             :second
           ) in 90..91

    repeated = render_submit(view, "rotate_rat", %{rotate: %{confirm: "true"}})
    assert occurrences(repeated, replacement) == 1
    {:ok, after_repeat} = Repository.fetch_client_by_id(client.client_id)

    assert after_repeat.registration_access_token_hash ==
             after_rotation.registration_access_token_hash

    acknowledged =
      view
      |> element("button[phx-click=acknowledge_rat]")
      |> render_click()

    refute acknowledged =~ replacement

    second_rotation =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    second_replacement = extract_copy_once_value(second_rotation)
    exited = render_patch(view, "/admin/clients/#{client.client_id}")
    refute exited =~ second_replacement
  end

  test "recovery remains available for an expired enabled app without renewing it", %{
    policy: _policy
  } do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    app_deadline = DateTime.add(now, -1, :second)
    secret_deadline = DateTime.add(now, 200, :second)

    client =
      self_registered_client("expired-app", now,
        client_expires_at: app_deadline,
        client_secret_expires_at: secret_deadline
      )

    assert {:ok, view, _html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{client.client_id}/rotate-registration-access-token"
             )

    rotated =
      view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    assert extract_copy_once_value(rotated)
    {:ok, after_rotation} = Repository.fetch_client_by_id(client.client_id)
    assert after_rotation.active
    assert DateTime.compare(after_rotation.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(after_rotation.client_secret_expires_at, secret_deadline) == :eq
  end

  test "stale and failed host recovery reveal no token and keep app context", %{policy: _policy} do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    stale_client = self_registered_client("recovery-stale", now)

    assert {:ok, stale_view, _html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{stale_client.client_id}/rotate-registration-access-token"
             )

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^stale_client.client_id),
               set: [registration_access_token_hash: RegistrationAccessToken.hash("newer-token")]
             )

    stale_html =
      stale_view
      |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
      |> render_submit()

    assert stale_html =~ "recovery-stale"
    assert stale_html =~ "No new app management token was created."
    refute stale_html =~ "New app management token"

    failed_client = self_registered_client("recovery-write-failed", now)

    assert {:ok, failed_view, _html} =
             live(
               conn_for_admin(),
               "/admin/clients/#{failed_client.client_id}/rotate-registration-access-token"
             )

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailableRecoveryRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      failed_html =
        failed_view
        |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
        |> render_submit()

      assert failed_html =~ failed_client.client_id
      refute failed_html =~ "New app management token"
      refute failed_html =~ failed_client.registration_access_token_hash
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "public management endpoints reject setup and client credentials and expose no recovery route" do
    assert :error =
             Phoenix.Router.route_info(
               Lockspire.Web.Router,
               "POST",
               "/register/client/rotate-registration-access-token",
               ""
             )

    refute Enum.any?(Phoenix.Router.routes(Lockspire.Web.Router), fn route ->
             String.contains?(route.path, "rotate-registration-access-token")
           end)

    policy = DcrFixtures.server_policy(%{registration_policy: :initial_access_token})
    assert {:ok, _policy} = Repository.put_server_policy(policy)
    {setup_token, _iat} = InitialAccessTokenFixtures.persist_with_plaintext(%{})

    assert {:ok, registered} =
             Registration.register(
               DcrFixtures.register_request(iat: setup_token, server_policy: policy)
               |> Map.put(:now, DateTime.utc_now() |> DateTime.truncate(:second))
             )

    client = registered.client
    credentials = [client.client_id, setup_token, registered.client_secret_plaintext]

    for credential <- credentials do
      conn = public_management_get(client.client_id, credential)
      assert conn.status == 401

      assert get_resp_header(conn, "www-authenticate") == [
               "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
             ]

      assert conn.resp_body == ""
    end

    expired_at = DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [registration_access_token_expires_at: expired_at]
             )

    expired_conn =
      public_management_get(client.client_id, registered.registration_access_token_plaintext)

    assert expired_conn.status == 401

    assert get_resp_header(expired_conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
           ]

    assert expired_conn.resp_body == ""
  end

  defp self_registered_client(suffix, now, attrs \\ []) do
    {:ok, client} =
      Repository.register_client(
        struct!(
          %Client{
            lifetime_version: 1,
            client_id: "165-06-#{suffix}",
            client_secret_hash: "sha256:management-recovery-secret",
            client_type: :confidential,
            name: "Management Recovery #{suffix}",
            redirect_uris: ["https://client.example.test/callback"],
            allowed_scopes: ["openid"],
            allowed_grant_types: ["authorization_code"],
            allowed_response_types: ["code"],
            token_endpoint_auth_method: :client_secret_basic,
            pkce_required: true,
            subject_type: :public,
            provenance: :self_registered,
            registration_access_token_hash:
              RegistrationAccessToken.hash("previous-management-token"),
            registration_client_uri: "https://example.test/register/165-06-#{suffix}",
            registration_access_token_expires_at: DateTime.add(now, -1, :second),
            created_at: now,
            metadata: %{}
          },
          attrs
        )
      )

    client
  end

  defp public_management_get(client_id, credential) do
    build_conn(:get, "/register/#{client_id}")
    |> put_req_header("authorization", "Bearer #{credential}")
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp conn_for_admin, do: Phoenix.ConnTest.build_conn()

  defp extract_copy_once_value(html) do
    [_, value] =
      Regex.run(
        ~r/<section class="[^"]*lockspire-admin-copy-once-secret[^\"]*".*?<code[^>]*>([^<]+)<\/code>/s,
        html
      )

    value
  end

  defp occurrences(text, value), do: length(String.split(text, value)) - 1
end
