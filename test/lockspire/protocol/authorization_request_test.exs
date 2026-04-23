defmodule Lockspire.Protocol.AuthorizationRequestTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "offline_access"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_123",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Acme Integrations",
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

    %{client: client}
  end

  test "accepts a valid authorization request and returns a typed validated contract", %{
    client: client
  } do
    handler_id = attach_events(self())
    client_id = client.client_id

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
    assert validated.scopes == ["profile", "email"]
    assert validated.prompt == ["login", "consent"]
    assert validated.nonce == nil
    assert validated.code_challenge_method == :S256

    assert_received {:telemetry_event, [:lockspire, :authorization_request_accepted],
                     %{client_id: ^client_id, redirect_safe: true}}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request_accepted],
                     %{client_id: ^client_id, redirect_safe: true}}

    :telemetry.detach(handler_id)
  end

  test "invalid client_id returns a browser error and never becomes redirect-safe" do
    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(valid_params("missing"))

    assert error.error == "invalid_client"
    assert error.reason_code == :invalid_client
    assert error.redirect_uri == nil
  end

  test "mismatched redirect_uri returns a browser error" do
    params =
      valid_params("client_123")
      |> Map.put("redirect_uri", "https://attacker.example.com/callback")

    assert {:browser_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :invalid_redirect_uri
  end

  test "unknown scopes return redirect errors with preserved state" do
    handler_id = attach_events(self())

    params =
      valid_params("client_123")
      |> Map.put("scope", "profile admin")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.error == "invalid_scope"
    assert error.reason_code == :unknown_scope
    assert error.state == "state-123"

    assert_received {:telemetry_event, [:lockspire, :authorization_request_rejected],
                     %{reason_code: :unknown_scope, redirect_safe: true}}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request_rejected],
                     %{reason_code: :unknown_scope, redirect_safe: true}}

    :telemetry.detach(handler_id)
  end

  test "openid requests require a nonce and persist it when present", %{client: client} do
    missing_nonce_params =
      valid_params(client.client_id)
      |> Map.put("scope", "openid email profile")

    assert {:redirect_error, %Error{} = error} =
             AuthorizationRequest.validate(missing_nonce_params)

    assert error.reason_code == :missing_nonce

    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("scope", "openid email profile")
             |> Map.put("nonce", "nonce-123")
             |> AuthorizationRequest.validate()

    assert validated.scopes == ["openid", "email", "profile"]
    assert validated.nonce == "nonce-123"
  end

  test "invalid prompt returns a redirect error" do
    params =
      valid_params("client_123")
      |> Map.put("prompt", "login login")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :duplicate_prompt
  end

  test "missing pkce returns a redirect error" do
    params =
      valid_params("client_123")
      |> Map.delete("code_challenge")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :missing_pkce
    assert error.error == "invalid_request"
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

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "authorization-request-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :authorization_request_accepted],
          [:lockspire, :audit, :authorization_request_accepted],
          [:lockspire, :authorization_request_rejected],
          [:lockspire, :audit, :authorization_request_rejected]
        ],
        &__MODULE__.handle_event/4,
        pid
      )

    handler_id
  end
end
