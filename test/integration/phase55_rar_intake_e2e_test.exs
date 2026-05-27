defmodule Lockspire.Integration.Phase55RarIntakeE2ETest do
  @moduledoc """
  End-to-end coverage for the Phase 55 RAR (RFC 9396) intake surface.

  Verifies that `authorization_details` is parsed, length-bounded, and
  carried from PAR/Authorize through to the durable Interaction state.
  """

  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Host.Claims
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

    {:ok, key_view} = Lockspire.Admin.Keys.generate_key()
    key_id = key_view.key.id
    {:ok, _} = Lockspire.Admin.Keys.publish_key(key_id)
    {:ok, _} = Lockspire.Admin.Keys.activate_key(key_id)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "rar-client",
        client_type: :confidential,
        client_secret_hash: Policy.hash_client_secret("secret"),
        name: "RAR Client",
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

  describe "RAR-01: PAR intake" do
    test "PAR accepts authorization_details and stores decoded maps", %{
      client: client,
      code_challenge: code_challenge
    } do
      details = [
        %{
          "type" => "payment_initiation",
          "actions" => ["initiate"],
          "instructedAmount" => %{"currency" => "EUR", "amount" => "12.99"}
        }
      ]

      par_conn =
        build_conn()
        |> post("/par", %{
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "authorization_details" => Jason.encode!(details),
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce-1"
        })

      assert par_conn.status == 201
      body = Jason.decode!(par_conn.resp_body)
      assert is_binary(body["request_uri"])
      assert is_integer(body["expires_in"])

      # The decoded RAR list must round-trip into the PAR record's JSONB column.
      request_uri_hash = Policy.hash_token(body["request_uri"])

      {:ok, stored_par} =
        Repository.fetch_active_pushed_authorization_request(request_uri_hash)

      assert stored_par.authorization_details == details
    end
  end

  describe "RAR-01: PAR -> Authorize -> Interaction carry-through" do
    test "request_uri-driven /authorize threads RAR onto the Interaction record", %{
      client: client,
      code_challenge: code_challenge
    } do
      details = [
        %{
          "type" => "account_information",
          "locations" => ["https://api.example.com/v1/accounts"],
          "actions" => ["read"]
        }
      ]

      par_conn =
        build_conn()
        |> post("/par", %{
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "authorization_details" => Jason.encode!(details),
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce-2"
        })

      assert par_conn.status == 201
      request_uri = Jason.decode!(par_conn.resp_body)["request_uri"]

      auth_conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "request_uri" => request_uri
        })

      assert auth_conn.status == 302
      location = get_resp_header(auth_conn, "location") |> List.first()
      assert location =~ "/consent/"

      interaction_id = location |> String.split("/") |> List.last()

      {:ok, interaction} = Repository.fetch_interaction(interaction_id)
      refute is_nil(interaction)
      assert interaction.authorization_details == details
    end
  end

  describe "RAR-01: Direct intake" do
    test "small authorization_details on direct /authorize is accepted and carried to Interaction",
         %{client: client, code_challenge: code_challenge} do
      details = [%{"type" => "account_information", "actions" => ["read"]}]

      auth_conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "authorization_details" => Jason.encode!(details),
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce-3"
        })

      assert auth_conn.status == 302
      location = get_resp_header(auth_conn, "location") |> List.first()
      assert location =~ "/consent/"

      interaction_id = location |> String.split("/") |> List.last()

      {:ok, interaction} = Repository.fetch_interaction(interaction_id)
      refute is_nil(interaction)
      assert interaction.authorization_details == details
    end

    test "authorization_details exceeding 2048 bytes is rejected with redirect error", %{
      client: client,
      code_challenge: code_challenge
    } do
      # Build a payload whose JSON byte-size exceeds the 2048-byte direct-request cap.
      bulky_action = String.duplicate("a", 2100)
      details = [%{"type" => "account_information", "actions" => [bulky_action]}]
      encoded = Jason.encode!(details)
      assert byte_size(encoded) > 2048

      auth_conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "authorization_details" => encoded,
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce-4"
        })

      # Length cap surfaces as a redirect-safe `invalid_request` per RFC 6749 + the
      # Plan 55-02 stable `:authorization_details_too_large` reason code.
      assert auth_conn.status == 302
      location = get_resp_header(auth_conn, "location") |> List.first()
      assert location =~ "error=invalid_request"
      refute location =~ "/consent/"
    end

    test "malformed JSON in authorization_details surfaces invalid_authorization_details", %{
      client: client,
      code_challenge: code_challenge
    } do
      auth_conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "authorization_details" => "{not-json",
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce-5"
        })

      # Malformed JSON must surface RFC 9396 §5.4 dedicated error code, not leak
      # internal parser state, and remain redirect-safe to the registered URI.
      assert auth_conn.status == 302
      location = get_resp_header(auth_conn, "location") |> List.first()
      assert location =~ "error=invalid_authorization_details"
      refute location =~ "/consent/"
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
