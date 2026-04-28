defmodule Lockspire.Integration.Phase31GeneratedHostVerificationE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile", "email"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostApp.Lockspire.TestAccountResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "generated-host-device-client",
        name: "Living Room TV",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
        created_at: DateTime.utc_now()
      })

    authorization =
      DeviceAuthorization.issue(%{
        device_code: "generated-host-device-code",
        user_code: "WDJB-MJHT",
        client_id: client.client_id,
        scopes: ["openid", "profile"]
      })

    {:ok, authorization} = Repository.put_device_authorization(authorization)

    %{authorization: authorization, client: client}
  end

  test "GET /verify only prefills and never mutates pending device authorization", %{
    authorization: authorization
  } do
    conn =
      build_conn()
      |> get("/verify", %{"user_code" => "wdjb-mjht"})

    assert conn.status == 200
    assert conn.resp_body =~ ~s(value="wdjb-mjht")
    refute conn.resp_body =~ "Approve device"
    refute conn.resp_body =~ "Deny request"

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               authorization.verification_handle
             )

    assert stored.status == :pending
    assert stored.subject_id == nil
  end

  test "POST /verify renders the review step with code, client context, scopes, and explicit actions" do
    conn = prepare_form(build_conn(), "/verify", %{"user_code" => "wdjb-mjht"})

    assert conn.status == 200
    assert conn.resp_body =~ "Before approval, confirm the code matches the requesting device."
    assert conn.resp_body =~ "WDJBMJHT"
    assert conn.resp_body =~ "Living Room TV"
    assert conn.resp_body =~ "openid"
    assert conn.resp_body =~ "profile"
    assert conn.resp_body =~ "Approve device"
    assert conn.resp_body =~ "Deny request"
  end

  test "signed-out approve redirects into host login and leaves the request pending", %{
    authorization: authorization
  } do
    review_conn = prepare_form(build_conn(), "/verify", %{"user_code" => "wdjb-mjht"})

    approve_conn =
      submit_from(review_conn, "/verify/#{authorization.verification_handle}/approve", %{})

    assert approve_conn.status in [302, 303]

    location =
      approve_conn
      |> get_resp_header("location")
      |> List.first()

    assert %URI{path: "/login", query: query} = URI.parse(location)

    assert URI.decode_query(query) == %{
             "return_to" => "/verify",
             "verification_handle" => authorization.verification_handle
           }

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               authorization.verification_handle
             )

    assert stored.status == :pending
    assert stored.subject_id == nil
  end

  test "signed-in approve binds the expected subject and signed-in deny preserves host session wiring" do
    signed_in_conn =
      build_conn()
      |> init_test_session(%{"current_account_id" => "generated-host-user"})

    review_conn = prepare_form(signed_in_conn, "/verify", %{"user_code" => "wdjb-mjht"})
    handle = fetch_handle(review_conn.resp_body)

    assert review_conn.resp_body =~ "generated-host-user"

    approve_conn = submit_from(review_conn, "/verify/#{handle}/approve", %{})

    assert approve_conn.status in [302, 303]
    assert redirected_to(approve_conn) == "/verify"

    assert {:ok, approved} = Repository.fetch_device_authorization_by_verification_handle(handle)
    assert approved.status == :approved
    assert approved.subject_id == "generated-host-user"

    {:ok, client} = Repository.fetch_client_by_id("generated-host-device-client")

    denied_authorization =
      DeviceAuthorization.issue(%{
        device_code: "generated-host-device-code-2",
        user_code: "ABCD-EFGH",
        client_id: client.client_id,
        scopes: ["openid"]
      })

    {:ok, denied_authorization} = Repository.put_device_authorization(denied_authorization)

    deny_review_conn =
      build_conn()
      |> init_test_session(%{"current_account_id" => "generated-host-user"})
      |> prepare_form("/verify", %{"user_code" => "abcd-efgh"})

    deny_conn =
      submit_from(deny_review_conn, "/verify/#{denied_authorization.verification_handle}/deny", %{})

    assert deny_conn.status in [302, 303]
    assert redirected_to(deny_conn) == "/verify"

    assert {:ok, denied} =
             Repository.fetch_device_authorization_by_verification_handle(
               denied_authorization.verification_handle
             )

    assert denied.status == :denied
    assert denied.subject_id == nil
  end

  defp prepare_form(conn, path, params) do
    token_conn =
      conn
      |> get("/verify")

    submit_from(token_conn, path, params)
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

  defp fetch_handle(body) do
    ~r{/verify/([^"/]+)/approve}
    |> Regex.run(body, capture: :all_but_first)
    |> case do
      [handle] -> handle
      _ -> raise "expected verification handle in review page"
    end
  end
end
