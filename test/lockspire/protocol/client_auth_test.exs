defmodule Lockspire.Protocol.ClientAuthTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error

  defp encode_assertion(payload) do
    header = Base.url_encode64(Jason.encode!(%{"alg" => "RS256"}), padding: false)
    payload_b64 = Base.url_encode64(Jason.encode!(payload), padding: false)
    signature = Base.url_encode64("signature", padding: false)
    "#{header}.#{payload_b64}.#{signature}"
  end

  describe "authenticate/3 with private_key_jwt" do
    test "rejects if TTL is greater than 10 minutes (exp - iat > 600)" do
      now = System.system_time(:second)

      payload = %{
        "iss" => "test_client",
        "sub" => "test_client",
        "aud" => "https://lockspire.example.com",
        "jti" => "jti_1",
        "iat" => now - 100,
        # 700 seconds TTL
        "exp" => now + 600
      }

      params = %{
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => encode_assertion(payload)
      }

      client = %Client{
        client_id: "test_client",
        token_endpoint_auth_method: :private_key_jwt
      }

      # Mock store just returns the client
      store_opt = [client_store: mock_store(client)]

      assert {:error, %Error{reason_code: :invalid_client_assertion}} =
               ClientAuth.authenticate(params, nil, store_opt)
    end

    test "rejects if TTL is greater than 10 minutes (exp - nbf > 600)" do
      now = System.system_time(:second)

      payload = %{
        "iss" => "test_client",
        "sub" => "test_client",
        "aud" => "https://lockspire.example.com",
        "jti" => "jti_2",
        "nbf" => now - 100,
        # 700 seconds TTL
        "exp" => now + 600
      }

      params = %{
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => encode_assertion(payload)
      }

      client = %Client{
        client_id: "test_client",
        token_endpoint_auth_method: :private_key_jwt
      }

      store_opt = [client_store: mock_store(client)]

      assert {:error, %Error{reason_code: :invalid_client_assertion}} =
               ClientAuth.authenticate(params, nil, store_opt)
    end

    test "accepts valid assertion and records JTI, rejecting replay" do
      now = System.system_time(:second)

      payload = %{
        "iss" => "test_client",
        "sub" => "test_client",
        "aud" => "https://lockspire.example.com",
        "jti" => "jti_unique_#{now}",
        "iat" => now,
        # 5 minutes
        "exp" => now + 300
      }

      params = %{
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => encode_assertion(payload)
      }

      client = %Client{
        client_id: "test_client",
        token_endpoint_auth_method: :private_key_jwt
      }

      store_opt = [client_store: mock_store(client)]

      # First attempt should succeed
      assert {:ok, ^client} = ClientAuth.authenticate(params, nil, store_opt)

      # Second attempt with same JTI should fail as replay
      assert {:error, %Error{reason_code: :invalid_client_assertion}} =
               ClientAuth.authenticate(params, nil, store_opt)
    end

    test "rejects missing jti" do
      now = System.system_time(:second)

      payload = %{
        "iss" => "test_client",
        "sub" => "test_client",
        "iat" => now,
        "exp" => now + 300
      }

      params = %{
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => encode_assertion(payload)
      }

      client = %Client{
        client_id: "test_client",
        token_endpoint_auth_method: :private_key_jwt
      }

      assert {:error, %Error{reason_code: :invalid_client_assertion}} =
               ClientAuth.authenticate(params, nil, client_store: mock_store(client))
    end

    test "rejects missing exp or iat/nbf" do
      payload = %{
        "iss" => "test_client",
        "sub" => "test_client",
        "jti" => "jti_3"
      }

      params = %{
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => encode_assertion(payload)
      }

      client = %Client{
        client_id: "test_client",
        token_endpoint_auth_method: :private_key_jwt
      }

      assert {:error, %Error{reason_code: :invalid_client_assertion}} =
               ClientAuth.authenticate(params, nil, client_store: mock_store(client))
    end
  end

  defmodule MockStore do
    def fetch_client_by_id("test_client") do
      {:ok,
       %Client{
         client_id: "test_client",
         token_endpoint_auth_method: :private_key_jwt
       }}
    end

    def fetch_client_by_id(_), do: {:ok, nil}

    def record_used_jti(used_jti) do
      # For test "accepts valid assertion and records JTI, rejecting replay"
      if String.starts_with?(used_jti.jti, "jti_unique_") do
        if Process.get(used_jti.jti) do
          {:ok, :replay}
        else
          Process.put(used_jti.jti, true)
          {:ok, :accepted}
        end
      else
        {:ok, :accepted}
      end
    end
  end

  defp mock_store(_client) do
    MockStore
  end
end
