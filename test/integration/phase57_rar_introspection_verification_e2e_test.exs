defmodule Lockspire.Integration.Phase57RarIntrospectionVerificationE2ETest do
  @moduledoc """
  End-to-end coverage for Phase 57 RAR introspection and consent-surface proof.
  """

  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.ConsentLive

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
      "payment_initiation" => Lockspire.Test.Rar.NormalizingValidator
    })

    {:ok, key_view} = Lockspire.Admin.Keys.generate_key()
    key_id = key_view.key.id
    {:ok, _} = Lockspire.Admin.Keys.publish_key(key_id)
    {:ok, _} = Lockspire.Admin.Keys.activate_key(key_id)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase57-client",
        client_type: :confidential,
        client_secret_hash: Policy.hash_client_secret("secret"),
        name: "Phase 57 Client",
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

  test "PAR-backed RAR remains visible through consent, compact token storage, and introspection",
       %{
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

    request_uri =
      push_par!(client, code_challenge, raw_details, ["https://api.one", "https://api.two"])

    interaction_id = authorize_with_request_uri!(client, request_uri)

    assert {:ok, interaction} = Repository.fetch_interaction(interaction_id)
    assert interaction.authorization_details == normalized_details

    assert {:ok, socket} =
             ConsentLive.mount(
               %{"interaction_id" => interaction_id},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    consent_html = rendered_to_string(ConsentLive.render(socket.assigns))

    assert socket.assigns.authorization_details == normalized_details
    assert socket.assigns.authorization_detail_types == ["payment_initiation"]
    assert consent_html =~ "authorization_details"
    assert consent_html =~ "payment_initiation"
    assert consent_html =~ "&quot;validated&quot;: true"

    code = approve_interaction!(interaction_id)
    token_response = redeem_code!(client, code, code_verifier, "https://api.one")

    assert {:ok, %Token{} = access_token} =
             Repository.fetch_active_access_token(
               Policy.hash_token(token_response["access_token"])
             )

    assert {:ok, %Token{} = refresh_token} =
             Repository.fetch_refresh_token(Policy.hash_token(token_response["refresh_token"]))

    assert access_token.audience == ["https://api.one"]
    assert is_integer(access_token.consent_grant_id)
    assert access_token.consent_grant_id == refresh_token.consent_grant_id
    refute Map.has_key?(Map.from_struct(access_token), :authorization_details)
    refute Map.has_key?(Map.from_struct(refresh_token), :authorization_details)

    access_introspection = introspect!(client, token_response["access_token"])

    assert access_introspection["active"] == true
    assert access_introspection["token_type"] == "access_token"
    assert access_introspection["aud"] == ["https://api.one"]
    assert access_introspection["authorization_details"] == normalized_details

    rotated = redeem_refresh!(client, token_response["refresh_token"])

    assert {:ok, %Token{} = rotated_access_token} =
             Repository.fetch_active_access_token(Policy.hash_token(rotated["access_token"]))

    assert {:ok, %Token{} = rotated_refresh_token} =
             Repository.fetch_refresh_token(Policy.hash_token(rotated["refresh_token"]))

    assert rotated_access_token.consent_grant_id == access_token.consent_grant_id
    assert rotated_refresh_token.consent_grant_id == refresh_token.consent_grant_id

    refresh_introspection = introspect!(client, rotated["refresh_token"])

    assert refresh_introspection["active"] == true
    assert refresh_introspection["token_type"] == "refresh_token"
    assert refresh_introspection["authorization_details"] == normalized_details
  end

  defp register_rar_validators(validators) do
    Application.put_env(:lockspire, :rar_validators, validators)
    on_exit(fn -> Application.delete_env(:lockspire, :rar_validators) end)
  end

  defp push_par!(client, code_challenge, details, resources) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/par", %{
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "response_type" => "code",
        "scope" => "openid offline_access",
        "redirect_uri" => List.first(client.redirect_uris),
        "resource" => resources,
        "authorization_details" => Jason.encode!(details),
        "code_challenge" => code_challenge,
        "code_challenge_method" => "S256",
        "state" => "phase57-state",
        "nonce" => "phase57-nonce"
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

  defp redeem_code!(client, code, code_verifier, resource) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "code" => code,
        "redirect_uri" => List.first(client.redirect_uris),
        "code_verifier" => code_verifier,
        "resource" => resource
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

  defp introspect!(client, token) do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/introspect", %{
        "client_id" => client.client_id,
        "client_secret" => "secret",
        "token" => token
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
