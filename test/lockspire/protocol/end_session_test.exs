defmodule Lockspire.Protocol.EndSessionTest.ClientStore do
  def fetch_client_by_id(client_id) do
    {:ok, Process.get({__MODULE__, client_id})}
  end
end

defmodule Lockspire.Protocol.EndSessionTest.KeyStore do
  def list_publishable_keys do
    {:ok, Process.get(__MODULE__, [])}
  end
end

defmodule Lockspire.Protocol.EndSessionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.EndSession

  describe "validate/1 - id_token_hint" do
    test "valid signature with non-expired token passes and extracts sid and sub" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{"id_token_hint" => id_token_hint(key.private_jwk, %{"aud" => "client-123"})})

      assert {:ok, %EndSession.Result{} = result} = EndSession.validate(request)
      assert result.sid == "sid-123"
      assert result.account_id == "subject-123"
    end

    test "valid signature with expired token passes" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{
          "id_token_hint" =>
            id_token_hint(key.private_jwk, %{
              "aud" => "client-123",
              "exp" => DateTime.utc_now() |> DateTime.add(-300, :second) |> DateTime.to_unix()
            })
        })

      assert {:ok, %EndSession.Result{} = result} = EndSession.validate(request)
      assert result.sid == "sid-123"
      assert result.account_id == "subject-123"
    end

    test "invalid signature returns error" do
      register_signing_key()

      other_key = JarTestHelpers.generate_keys()

      request =
        request(%{
          "id_token_hint" => id_token_hint(other_key.private_jwk, %{"aud" => "client-123"})
        })

      assert {:error, %EndSession.Error{} = error} = EndSession.validate(request)
      assert error.reason_code == :invalid_id_token_hint
      assert error.status == 400
    end

    test "FAPI-effective behavior rejects RS256 id_token_hint" do
      key = register_signing_key()
      register_client("client-123")

      # Generate an RS256 token
      compact_jwt = id_token_hint(key.private_jwk, %{"aud" => "client-123"})

      # Request with FAPI security profile
      fapi_request =
        request(%{"id_token_hint" => compact_jwt})
        |> put_in([:opts, :security_profile], %Lockspire.Protocol.SecurityProfile.Resolved{
          effective_profile: :fapi_2_0_security
        })

      assert {:error, %EndSession.Error{} = error} = EndSession.validate(fapi_request)
      assert error.reason_code == :invalid_id_token_hint
      assert error.status == 400
    end

    test "missing id_token_hint proceeds with nil sid" do
      assert {:ok, %EndSession.Result{} = result} = EndSession.validate(request(%{}))
      assert is_nil(result.sid)
      assert is_nil(result.account_id)
    end
  end

  describe "validate/1 - post_logout_redirect_uri" do
    test "registered URI passes exact match and is returned in result" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{
          "id_token_hint" => id_token_hint(key.private_jwk, %{"aud" => "client-123"}),
          "post_logout_redirect_uri" => "https://client.example.com/logged-out"
        })

      assert {:ok, %EndSession.Result{} = result} = EndSession.validate(request)
      assert result.post_logout_redirect_uri == "https://client.example.com/logged-out"
    end

    test "unregistered URI is rejected" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{
          "id_token_hint" => id_token_hint(key.private_jwk, %{"aud" => "client-123"}),
          "post_logout_redirect_uri" => "https://evil.example.com/logout"
        })

      assert {:error, %EndSession.Error{} = error} = EndSession.validate(request)
      assert error.reason_code == :unregistered_post_logout_redirect_uri
    end

    test "missing post_logout_redirect_uri returns nil in result" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{"id_token_hint" => id_token_hint(key.private_jwk, %{"aud" => "client-123"})})

      assert {:ok, %EndSession.Result{} = result} = EndSession.validate(request)
      assert is_nil(result.post_logout_redirect_uri)
    end
  end

  describe "validate/1 - client_id / aud cross-check" do
    test "client_id present in id_token_hint aud passes" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{
          "client_id" => "client-123",
          "id_token_hint" =>
            id_token_hint(key.private_jwk, %{"aud" => ["client-123", "other-client"]})
        })

      assert {:ok, %EndSession.Result{sid: "sid-123"}} = EndSession.validate(request)
    end

    test "client_id not in id_token_hint aud is rejected" do
      key = register_signing_key()
      register_client("client-123")

      request =
        request(%{
          "client_id" => "client-123",
          "id_token_hint" => id_token_hint(key.private_jwk, %{"aud" => ["other-client"]})
        })

      assert {:error, %EndSession.Error{} = error} = EndSession.validate(request)
      assert error.reason_code == :client_id_not_in_aud
    end
  end

  defp request(params) do
    %{
      params: params,
      opts: [
        client_store: Lockspire.Protocol.EndSessionTest.ClientStore,
        key_store: Lockspire.Protocol.EndSessionTest.KeyStore
      ]
    }
  end

  defp register_signing_key do
    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)

    signing_key = %SigningKey{
      kid: "kid-123",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: Map.put(public_jwk, "kid", "kid-123")
    }

    Process.put(Lockspire.Protocol.EndSessionTest.KeyStore, [signing_key])
    %{private_jwk: keys.private_jwk, signing_key: signing_key}
  end

  defp register_client(client_id) do
    Process.put(
      {Lockspire.Protocol.EndSessionTest.ClientStore, client_id},
      %Client{
        client_id: client_id,
        post_logout_redirect_uris: ["https://client.example.com/logged-out"]
      }
    )
  end

  defp id_token_hint(private_jwk, overrides) do
    claims =
      %{
        "aud" => "client-123",
        "sub" => "subject-123",
        "sid" => "sid-123",
        "exp" => DateTime.utc_now() |> DateTime.add(300, :second) |> DateTime.to_unix()
      }
      |> Map.merge(overrides)

    private_jwk
    |> JOSE.JWT.sign(%{"alg" => "RS256", "typ" => "JWT"}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
