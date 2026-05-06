defmodule Lockspire.Integration.Phase56RarValidationStorageE2ETest do
  @moduledoc """
  End-to-end coverage for Phase 56 RAR validation, normalization, and storage.
  """

  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import ExUnit.CaptureLog
  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.RAR.Fingerprint
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  defmodule RarHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "rar-user"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: to_string(account.id)
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context), do: raise("not implemented")
  end

  setup_all do
    previous_endpoint = Application.get_env(:lockspire, Lockspire.Web.Endpoint)
    previous_repo = Application.get_env(:lockspire, :repo)
    previous_issuer = Application.get_env(:lockspire, :issuer)
    previous_mount_path = Application.get_env(:lockspire, :mount_path)
    previous_known_scopes = Application.get_env(:lockspire, :known_scopes)
    previous_account_resolver = Application.get_env(:lockspire, :account_resolver)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test")
    Application.put_env(:lockspire, :mount_path, "")
    Application.put_env(:lockspire, :known_scopes, ["openid", "offline_access"])
    Application.put_env(:lockspire, :account_resolver, RarHostResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      restore_env(Lockspire.Web.Endpoint, previous_endpoint)
      restore_env(:repo, previous_repo)
      restore_env(:issuer, previous_issuer)
      restore_env(:mount_path, previous_mount_path)
      restore_env(:known_scopes, previous_known_scopes)
      restore_env(:account_resolver, previous_account_resolver)
    end)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    register_rar_validators(%{
      "payment_initiation" => Lockspire.Test.Rar.NormalizingValidator,
      "account_information" => Lockspire.Test.Rar.PassthroughValidator,
      "type_a" => Lockspire.Test.Rar.PassthroughValidator,
      "type_b" => Lockspire.Test.Rar.PassthroughValidator
    })

    {:ok, key_view} = Lockspire.Admin.Keys.generate_key()
    key_id = key_view.key.id
    {:ok, _} = Lockspire.Admin.Keys.publish_key(key_id)
    {:ok, _} = Lockspire.Admin.Keys.activate_key(key_id)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase56-client",
        client_type: :confidential,
        client_secret_hash: Policy.hash_client_secret("secret"),
        name: "Phase 56 Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_post,
        created_at: DateTime.utc_now()
      })

    code_verifier = String.duplicate("a", 43)
    code_challenge = :crypto.hash(:sha256, code_verifier) |> Base.url_encode64(padding: false)

    %{client: client, code_verifier: code_verifier, code_challenge: code_challenge}
  end

  test "normalized RAR details persist from PAR through grant issuance and refresh rotation", %{
    client: client,
    code_verifier: code_verifier,
    code_challenge: code_challenge
  } do
    raw_details = [
      %{
        "type" => "payment_initiation",
        "actions" => ["initiate"],
        "ignored" => true,
        "secret" => "do-not-persist"
      }
    ]

    normalized_details = [
      %{"type" => "payment_initiation", "actions" => ["initiate"], "validated" => true}
    ]

    request_uri = push_par!(client, code_challenge, raw_details, "par-normalized")
    request_uri_hash = Policy.hash_token(request_uri)

    assert {:ok, stored_par} =
             Repository.fetch_active_pushed_authorization_request(request_uri_hash)

    assert stored_par.authorization_details == normalized_details

    interaction_id = authorize_with_request_uri!(client, request_uri)

    assert {:ok, interaction} = Repository.fetch_interaction(interaction_id)
    assert interaction.authorization_details == normalized_details

    code = approve_interaction!(interaction_id)
    token_response = redeem_code!(client, code, code_verifier)

    assert {:ok, %Token{} = access_token} =
             Repository.fetch_active_access_token(
               Policy.hash_token(token_response["access_token"])
             )

    assert {:ok, %Token{} = refresh_token} =
             Repository.fetch_refresh_token(Policy.hash_token(token_response["refresh_token"]))

    assert is_integer(access_token.consent_grant_id)
    assert access_token.consent_grant_id == refresh_token.consent_grant_id

    assert {:ok, consent_grant} = Repository.fetch_consent_grant(access_token.consent_grant_id)
    assert consent_grant.authorization_details == normalized_details

    assert consent_grant.authorization_details_fingerprint ==
             Fingerprint.compute(normalized_details)

    rotated = redeem_refresh!(client, token_response["refresh_token"])

    assert {:ok, %Token{} = rotated_access_token} =
             Repository.fetch_active_access_token(Policy.hash_token(rotated["access_token"]))

    assert {:ok, %Token{} = rotated_refresh_token} =
             Repository.fetch_refresh_token(Policy.hash_token(rotated["refresh_token"]))

    assert rotated_access_token.consent_grant_id == access_token.consent_grant_id
    assert rotated_refresh_token.consent_grant_id == refresh_token.consent_grant_id
  end

  test "PAR consume skips a second host validation pass for pre-validated details", %{
    client: client,
    code_challenge: code_challenge
  } do
    raw_details = [
      %{"type" => "payment_initiation", "actions" => ["initiate"], "ignored" => true}
    ]

    normalized_details = [
      %{"type" => "payment_initiation", "actions" => ["initiate"], "validated" => true}
    ]

    request_uri = push_par!(client, code_challenge, raw_details, "par-short-circuit")

    register_rar_validators(%{
      "payment_initiation" => Lockspire.Test.Rar.RaisingValidator
    })

    interaction_id = authorize_with_request_uri!(client, request_uri)

    assert {:ok, interaction} = Repository.fetch_interaction(interaction_id)
    assert interaction.authorization_details == normalized_details
  end

  test "unknown RAR types are rejected without leaking the offending type", %{
    client: client,
    code_challenge: code_challenge
  } do
    client_id = client.client_id
    register_rar_validators(%{})

    handler_id = attach_unknown_type_handler!()

    log =
      capture_log(fn ->
        conn =
          build_conn()
          |> get("/authorize", %{
            "client_id" => client.client_id,
            "response_type" => "code",
            "scope" => "openid",
            "redirect_uri" => List.first(client.redirect_uris),
            "authorization_details" => Jason.encode!([%{"type" => "unregistered_type"}]),
            "code_challenge" => code_challenge,
            "code_challenge_method" => "S256",
            "nonce" => "nonce-unknown"
          })

        assert conn.status in [302, 303]
        location = get_resp_header(conn, "location") |> List.first()
        params = redirect_params(location)

        assert params["error"] == "invalid_authorization_details"
        assert params["error_description"] == "authorization_details contains an unsupported type"
        refute params["error_description"] =~ "unregistered_type"
        refute location =~ "/consent/"
      end)

    assert_received {:unknown_type, %{count: 1},
                     %{client_id: ^client_id, type: "unregistered_type"}}

    assert log =~ "Unknown RAR type rejected"

    :telemetry.detach(handler_id)
  end

  test "empty authorization_details arrays are rejected before consent", %{
    client: client,
    code_challenge: code_challenge
  } do
    conn =
      build_conn()
      |> get("/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "scope" => "openid",
        "redirect_uri" => List.first(client.redirect_uris),
        "authorization_details" => "[]",
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "nonce" => "nonce-empty"
      })

    assert conn.status in [302, 303]

    location = get_resp_header(conn, "location") |> List.first()
    params = redirect_params(location)

    assert params["error"] == "invalid_authorization_details"
    assert params["error_description"] == "authorization_details must not be empty"
    refute location =~ "/consent/"
  end

  test "remembered consent reuse requires the same RAR fingerprint", %{
    client: client,
    code_verifier: code_verifier,
    code_challenge: code_challenge
  } do
    details_a = [%{"type" => "type_a", "actions" => ["read"]}]
    details_b = [%{"type" => "type_b", "actions" => ["read"]}]

    first_interaction_id = authorize_direct!(client, code_challenge, details_a, "nonce-reuse-a1")
    first_code = approve_interaction!(first_interaction_id)
    _first_tokens = redeem_code!(client, first_code, code_verifier)

    reused_conn =
      build_conn()
      |> get("/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "scope" => "openid offline_access",
        "redirect_uri" => List.first(client.redirect_uris),
        "authorization_details" => Jason.encode!(details_a),
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "state" => "state-reuse-a2",
        "nonce" => "nonce-reuse-a2"
      })

    assert reused_conn.status in [302, 303]
    reused_location = get_resp_header(reused_conn, "location") |> List.first()
    reused_uri = URI.parse(reused_location)
    reused_params = URI.decode_query(reused_uri.query || "")

    assert reused_uri.host == "client.example.com"
    assert reused_params["code"]
    assert reused_params["state"] == "state-reuse-a2"
    refute reused_location =~ "/consent/"

    different_conn =
      build_conn()
      |> get("/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "scope" => "openid offline_access",
        "redirect_uri" => List.first(client.redirect_uris),
        "authorization_details" => Jason.encode!(details_b),
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "state" => "state-reuse-b",
        "nonce" => "nonce-reuse-b"
      })

    assert different_conn.status in [302, 303]
    different_location = get_resp_header(different_conn, "location") |> List.first()
    assert different_location =~ "/consent/"
  end

  defp register_rar_validators(validators) do
    Application.put_env(:lockspire, :rar_validators, validators)
    on_exit(fn -> Application.delete_env(:lockspire, :rar_validators) end)
  end

  defp attach_unknown_type_handler! do
    handler_id = "phase56-rar-unknown-type-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        [:lockspire, :rar, :unknown_type],
        fn _event, measurements, metadata, pid ->
          send(pid, {:unknown_type, measurements, metadata})
        end,
        self()
      )

    handler_id
  end

  defp push_par!(client, code_challenge, details, nonce) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/par", %{
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "response_type" => "code",
        "scope" => "openid offline_access",
        "redirect_uri" => List.first(client.redirect_uris),
        "authorization_details" => Jason.encode!(details),
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "state" => "state-#{nonce}",
        "nonce" => nonce
      })

    assert conn.status == 201
    Jason.decode!(conn.resp_body)["request_uri"]
  end

  defp authorize_with_request_uri!(client, request_uri) do
    conn =
      build_conn()
      |> get("/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })

    assert conn.status in [302, 303]

    location = get_resp_header(conn, "location") |> List.first()
    assert location =~ "/consent/"
    location |> String.split("/") |> List.last()
  end

  defp authorize_direct!(client, code_challenge, details, nonce) do
    conn =
      build_conn()
      |> get("/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "scope" => "openid offline_access",
        "redirect_uri" => List.first(client.redirect_uris),
        "authorization_details" => Jason.encode!(details),
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "state" => "state-#{nonce}",
        "nonce" => nonce
      })

    assert conn.status in [302, 303]

    location = get_resp_header(conn, "location") |> List.first()
    assert location =~ "/consent/"
    location |> String.split("/") |> List.last()
  end

  defp approve_interaction!(interaction_id) do
    conn =
      build_conn()
      |> post("/interactions/#{interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })

    assert conn.status in [302, 303]

    location = get_resp_header(conn, "location") |> List.first()
    redirect_params(location)["code"]
  end

  defp redeem_code!(client, code, code_verifier) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "code" => code,
        "redirect_uri" => List.first(client.redirect_uris),
        "code_verifier" => code_verifier
      })

    assert conn.status == 200
    Jason.decode!(conn.resp_body)
  end

  defp redeem_refresh!(client, refresh_token) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "refresh_token",
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "refresh_token" => refresh_token
      })

    assert conn.status == 200
    Jason.decode!(conn.resp_body)
  end

  defp redirect_params(location) do
    location
    |> URI.parse()
    |> Map.get(:query, "")
    |> URI.decode_query()
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
