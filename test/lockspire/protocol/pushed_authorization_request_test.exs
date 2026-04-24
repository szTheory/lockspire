defmodule Lockspire.Protocol.PushedAuthorizationRequestTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.PushedAuthorizationRequest, as: PushedAuthorizationRequestProtocol
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "openid"])

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "par-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "PAR Public Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    secret = "par-confidential-secret"

    {:ok, confidential_client} =
      Repository.register_client(%Client{
        client_id: "par-confidential",
        client_secret_hash: Policy.hash_client_secret(secret),
        client_type: :confidential,
        name: "PAR Confidential Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{public_client: public_client, confidential_client: confidential_client, secret: secret}
  end

  test "issues opaque PAR references with a 300 second ttl and hashes them for durable lookup" do
    now = DateTime.utc_now()

    request =
      PushedAuthorizationRequest.issue(
        %{
          client_id: "client_123",
          redirect_uri: "https://client.example.com/callback",
          scopes: ["profile", "email"],
          prompt: ["login", "consent"],
          nonce: "nonce-123",
          state: "state-123",
          code_challenge: String.duplicate("a", 43),
          code_challenge_method: :S256
        },
        now: now,
        request_uri_generator: fn -> "opaque-reference" end
      )

    assert request.request_uri == "urn:ietf:params:oauth:request_uri:opaque-reference"
    assert request.request_uri_hash == Policy.hash_token(request.request_uri)
    assert DateTime.diff(request.expires_at, now, :second) == 300

    changeset =
      PushedAuthorizationRequestRecord.changeset(%PushedAuthorizationRequestRecord{}, request)

    assert changeset.valid?
    assert changeset.changes.request_uri_hash == request.request_uri_hash
    refute Map.has_key?(changeset.changes, :request_uri)

    assert {:ok, stored} = Repository.put_pushed_authorization_request(request)
    assert stored.request_uri == request.request_uri

    assert {:ok, fetched} =
             Repository.fetch_active_pushed_authorization_request(request.request_uri_hash)

    assert fetched.request_uri == nil
    assert fetched.request_uri_hash == request.request_uri_hash
    assert fetched.client_id == "client_123"
    assert fetched.redirect_uri == "https://client.example.com/callback"
    assert fetched.scopes == ["profile", "email"]
    assert fetched.prompt == ["login", "consent"]
    assert fetched.code_challenge_method == :S256
  end

  test "expired pushed authorization requests are not returned as active" do
    request =
      PushedAuthorizationRequest.issue(
        %{
          client_id: "client_123",
          redirect_uri: "https://client.example.com/callback",
          scopes: ["profile"],
          code_challenge: String.duplicate("b", 43),
          code_challenge_method: :S256
        },
        now: ~U[2020-04-24 14:00:00Z],
        ttl: -1,
        request_uri_generator: fn -> "already-expired" end
      )

    assert {:ok, _stored} = Repository.put_pushed_authorization_request(request)

    assert {:ok, nil} =
             Repository.fetch_active_pushed_authorization_request(request.request_uri_hash)
  end

  test "push returns a PAR request_uri and expires_in for valid public clients", %{
    public_client: public_client
  } do
    now = DateTime.utc_now()

    assert {:ok, success} =
             PushedAuthorizationRequestProtocol.push(%{
               params: valid_params(public_client.client_id),
               opts: [
                 client_store: Repository,
                 pushed_authorization_request_store: Repository,
                 now: now,
                 request_uri_generator: fn -> "protocol-success" end
               ]
             })

    assert success.request_uri == "urn:ietf:params:oauth:request_uri:protocol-success"
    assert success.expires_in == 300

    assert {:ok, fetched} =
             Repository.fetch_active_pushed_authorization_request(
               Policy.hash_token(success.request_uri)
             )

    assert fetched.client_id == public_client.client_id
    assert fetched.redirect_uri == "https://client.example.com/callback"
    assert fetched.scopes == ["profile", "email"]
  end

  test "push rejects inbound request_uri parameters without creating durable state", %{
    public_client: public_client
  } do
    before_count = Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id)

    assert {:error, error} =
             PushedAuthorizationRequestProtocol.push(%{
               params:
                 valid_params(public_client.client_id)
                 |> Map.put("request_uri", "urn:ietf:params:oauth:request_uri:attacker"),
               opts: [client_store: Repository, pushed_authorization_request_store: Repository]
             })

    assert error.status == 400
    assert error.error == "invalid_request"
    assert error.reason_code == :unsupported_request_uri

    assert Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id) ==
             before_count
  end

  test "push rejects mixed client authentication without creating durable state", %{
    confidential_client: confidential_client,
    secret: secret
  } do
    before_count = Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id)

    assert {:error, error} =
             PushedAuthorizationRequestProtocol.push(%{
               params:
                 valid_params(confidential_client.client_id)
                 |> Map.put("client_secret", secret),
               authorization: basic_auth(confidential_client.client_id, secret),
               opts: [client_store: Repository, pushed_authorization_request_store: Repository]
             })

    assert error.status == 401
    assert error.error == "invalid_client"
    assert error.reason_code == :mixed_auth

    assert Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id) ==
             before_count
  end

  test "push rejects invalid redirect_uri without creating durable state", %{
    public_client: public_client
  } do
    before_count = Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id)

    assert {:error, error} =
             PushedAuthorizationRequestProtocol.push(%{
               params:
                 valid_params(public_client.client_id)
                 |> Map.put("redirect_uri", "https://attacker.example.com/callback"),
               opts: [client_store: Repository, pushed_authorization_request_store: Repository]
             })

    assert error.status == 400
    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_redirect_uri

    assert Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id) ==
             before_count
  end

  test "push rejects missing pkce without creating durable state", %{public_client: public_client} do
    before_count = Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id)

    assert {:error, error} =
             PushedAuthorizationRequestProtocol.push(%{
               params: Map.delete(valid_params(public_client.client_id), "code_challenge"),
               opts: [client_store: Repository, pushed_authorization_request_store: Repository]
             })

    assert error.status == 400
    assert error.error == "invalid_request"
    assert error.reason_code == :missing_pkce

    assert Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id) ==
             before_count
  end

  defp valid_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "profile email",
      "state" => "state-123",
      "prompt" => "login consent",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }
  end

  defp basic_auth(client_id, secret) do
    "Basic " <> Base.encode64("#{URI.encode_www_form(client_id)}:#{URI.encode_www_form(secret)}")
  end
end
