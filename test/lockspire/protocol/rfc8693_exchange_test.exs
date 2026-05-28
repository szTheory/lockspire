defmodule Lockspire.Protocol.Rfc8693ExchangeTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.Rfc8693Exchange
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Security.Policy

  defmodule MockTokenStore do
    def fetch_lifecycle_token(token_hash) do
      case Process.get({__MODULE__, token_hash}) do
        nil -> {:error, :not_found}
        token -> {:ok, token}
      end
    end

    def store_token(%Token{} = token) do
      Process.put({__MODULE__, token.token_hash}, token)
      {:ok, token}
    end
  end

  defmodule MockValidator do
    def validate(_context) do
      case Process.get({__MODULE__, :result}) do
        nil -> :ok
        result -> result
      end
    end
  end

  defmodule MockKeyStore do
    def fetch_active_signing_key(_opts) do
      jwk = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_map() |> elem(1) |> Jason.encode!()
      {:ok, %{alg: "RS256", kid: "key-1", private_jwk_encrypted: jwk}}
    end
  end

  setup do
    client = %Client{
      client_id: "test_client",
      allowed_grant_types: ["urn:ietf:params:oauth:grant-type:token-exchange"]
    }

    now = DateTime.utc_now()

    request = %{
      "params" => %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
        "subject_token" => "valid_token_string"
      },
      opts: [
        token_store: MockTokenStore,
        token_exchange_validator: MockValidator,
        now: fn -> now end
      ]
    }

    valid_token = %Token{
      token_hash: Policy.hash_token("valid_token_string"),
      token_type: :access_token,
      expires_at: DateTime.add(now, 3600, :second),
      scopes: ["read", "write"]
    }

    MockTokenStore.store_token(valid_token)

    %{client: client, request: request, valid_token: valid_token, now: now}
  end

  test "exchange/2 returns invalid_request if subject_token is missing", %{
    client: client,
    request: request
  } do
    request =
      put_in(request["params"], %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange"
      })

    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 400
    assert error.reason_code == :missing_subject_token
  end

  test "exchange/2 returns invalid_grant if token not found", %{client: client, request: request} do
    request = put_in(request["params"]["subject_token"], "unknown_token")
    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 400
    assert error.reason_code == :invalid_subject_token
  end

  test "exchange/2 returns invalid_grant if token expired", %{
    client: client,
    request: request,
    now: now
  } do
    expired_token = %Token{
      token_hash: Policy.hash_token("expired_token"),
      token_type: :access_token,
      expires_at: DateTime.add(now, -3600, :second),
      scopes: ["read", "write"]
    }

    MockTokenStore.store_token(expired_token)

    request = put_in(request["params"]["subject_token"], "expired_token")
    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 400
    assert error.reason_code == :invalid_subject_token
  end

  test "exchange/2 returns invalid_grant if token revoked", %{
    client: client,
    request: request,
    now: now
  } do
    revoked_token = %Token{
      token_hash: Policy.hash_token("revoked_token"),
      token_type: :access_token,
      expires_at: DateTime.add(now, 3600, :second),
      revoked_at: now,
      scopes: ["read", "write"]
    }

    MockTokenStore.store_token(revoked_token)

    request = put_in(request["params"]["subject_token"], "revoked_token")
    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 400
    assert error.reason_code == :invalid_subject_token
  end

  test "exchange/2 returns invalid_scope if requested scope exceeds subject token scope", %{
    client: client,
    request: request
  } do
    request = put_in(request["params"]["scope"], "read delete")
    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 400
    assert error.reason_code == :invalid_scope
  end

  test "exchange/2 handles downscoping successfully", %{client: client, request: request} do
    request = put_in(request["params"]["scope"], "read")
    assert {:ok, %Success{} = success} = Rfc8693Exchange.exchange(client, request)
    assert success.scope == "read"
    assert success.token_type == "Bearer"
  end

  test "exchange/2 defaults to subject token scope if not requested", %{
    client: client,
    request: request
  } do
    assert {:ok, %Success{} = success} = Rfc8693Exchange.exchange(client, request)
    assert success.scope == "read write"
    assert success.token_type == "Bearer"
  end

  test "exchange/2 returns access_denied if host validator denies exchange", %{
    client: client,
    request: request
  } do
    Process.put({MockValidator, :result}, {:error, :business_logic_failed})
    assert {:error, %Error{} = error} = Rfc8693Exchange.exchange(client, request)
    assert error.status == 403
    assert error.error == "access_denied"
    assert error.reason_code == :access_denied
  end

  test "exchange/2 mints a signed JWT access token when custom claims are provided", %{
    client: client,
    request: request
  } do
    Process.put(
      {MockValidator, :result},
      {:ok,
       %{
         claims: %{
           "custom_role" => "admin",
           "iss" => "ignored",
           "aud" => "attacker-controlled"
         }
       }}
    )

    request = put_in(request.opts, Keyword.put(request.opts, :key_store, MockKeyStore))

    assert {:ok, %Success{} = success} = Rfc8693Exchange.exchange(client, request)
    assert success.token_type == "Bearer"

    # success.access_token should be a signed JWT
    assert [header_b64, payload_b64, _sig_b64] = String.split(success.access_token, ".")
    header = header_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
    payload = payload_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()

    assert header["typ"] == "at+jwt"
    assert payload["custom_role"] == "admin"
    # Restricted claims (iss/aud) cannot be overridden by custom claims (T-99-17).
    assert payload["iss"] == Lockspire.Config.issuer!()
    # AUD-03: the exchange path keeps a bare-STRING aud == client_id.
    assert payload["aud"] == client.client_id
    assert is_binary(payload["aud"])
  end
end
