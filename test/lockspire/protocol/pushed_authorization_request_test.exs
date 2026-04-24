defmodule Lockspire.Protocol.PushedAuthorizationRequestTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.PushedAuthorizationRequest
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
  end

  test "issues opaque PAR references with a 300 second ttl and hashes them for durable lookup" do
    now = ~U[2026-04-24 14:00:00Z]

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
end
