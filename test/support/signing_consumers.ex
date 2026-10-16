defmodule Lockspire.TestSupport.SigningConsumers do
  @moduledoc """
  Drivers for the six consumers of stored signing keys, used by the PROOF-01 upgrade journey.

  Every driver takes a `Lockspire.Domain.SigningKey` that was read back from the database, so
  the bytes on disk are what signs or decrypts. `verify` is the public `JOSE.JWK` that matches
  the stored private key.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.IdToken
  alias Lockspire.Protocol.IntrospectionJwt
  alias Lockspire.Protocol.Jar
  alias Lockspire.Protocol.Jarm
  alias Lockspire.Protocol.LogoutToken

  @issued_at ~U[2026-04-28 15:00:00Z]
  @issuer "https://example.test/lockspire"

  defmodule KeyStore do
    @moduledoc false
    def fetch_active_signing_key(opts) do
      case Process.get(:upgrade_journey_key) do
        nil -> {:ok, nil}
        key -> {:ok, %{key | alg: Keyword.get(opts, :alg, key.alg)}}
      end
    end
  end

  defmodule PolicyStore do
    @moduledoc false
    def get_server_policy, do: {:ok, %ServerPolicy{access_token_format: :jwt}}
  end

  @doc "Runs every consumer; returns a map of consumer name to `:ok` or `{:error, reason}`."
  @spec sign_all(%{sig: SigningKey.t(), enc: SigningKey.t(), verify: JOSE.JWK.t()}) :: map()
  def sign_all(%{sig: sig, enc: enc, verify: verify}) do
    %{
      id_token: id_token(sig, verify),
      logout_token: logout_token(sig, verify),
      jarm: jarm(sig, verify),
      introspection_jwt: introspection_jwt(sig, verify),
      access_token: access_token(sig, verify),
      jar_decrypt: jar_decrypt(enc, verify)
    }
  end

  @spec id_token(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def id_token(%SigningKey{} = key, verify) do
    params = %{
      client_id: "client-123",
      issuer: @issuer,
      host_claims: %Claims{subject: "sub-1", id_token: %{}, userinfo: %{}},
      interaction_nonce: "nonce-123",
      access_token: "access-token-123",
      issued_at: @issued_at,
      signing_key: key
    }

    check(IdToken.sign(params), verify, key)
  end

  @spec logout_token(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def logout_token(%SigningKey{} = key, verify) do
    params = %{
      issuer: @issuer,
      logout_event: %LogoutEvent{event_id: "evt-1", sid: "sid-1", subject: "sub-1"},
      delivery: %LogoutDelivery{
        delivery_id: "d-1",
        client_id: "client-1",
        channel: :backchannel,
        target_uri: "https://snapshot.example.com/backchannel-logout",
        session_required: true
      },
      issued_at: @issued_at,
      signing_key: key
    }

    case LogoutToken.sign(params) do
      {:ok, jwt, _jti} -> check({:ok, jwt}, verify, key)
      other -> check(other, verify, key)
    end
  end

  @spec jarm(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def jarm(%SigningKey{} = key, verify) do
    Process.put(:upgrade_journey_key, key)

    result =
      Jarm.sign(%{code: "c1"}, %{
        client: %Client{
          client_id: "client-1",
          authorization_signed_response_alg: :RS256,
          security_profile: :none
        },
        issuer: "https://auth.example.com",
        key_store: KeyStore
      })

    check(result, verify, key)
  end

  @spec introspection_jwt(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def introspection_jwt(%SigningKey{} = key, verify) do
    Process.put(:upgrade_journey_key, key)

    result =
      IntrospectionJwt.sign(%{
        issuer: "https://auth.example.com",
        issued_at: ~U[2026-05-08 10:00:00Z],
        success: %{
          payload: %{active: true, client_id: "tc", token_type: "access_token", sub: "a"},
          caller: %Client{client_id: "rs-client", security_profile: :none},
          security_profile: :none
        },
        key_store: KeyStore
      })

    check(result, verify, key)
  end

  @spec access_token(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def access_token(%SigningKey{} = key, verify) do
    Process.put(:upgrade_journey_key, key)

    token = %Token{
      token_hash: "placeholder",
      token_type: :access_token,
      client_id: "test_client",
      account_id: "account-123",
      scopes: ["read"],
      audience: [],
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    client = %Client{client_id: "test_client", allowed_grant_types: ["authorization_code"]}

    result =
      AccessTokenSigner.issue(token, client, %{
        opts: [key_store: KeyStore, server_policy_store: PolicyStore]
      })

    case result do
      {:ok, jwt, _hash} -> check({:ok, jwt}, verify, key)
      other -> check(other, verify, key)
    end
  end

  @doc "Encrypts a JWE to the public key and decrypts it with the stored `:enc` row."
  @spec jar_decrypt(SigningKey.t(), JOSE.JWK.t()) :: :ok | {:error, term()}
  def jar_decrypt(%SigningKey{} = key, verify) do
    {_, public_map} = JOSE.JWK.to_public_map(verify)

    jwe =
      JOSE.JWE.block_encrypt(JOSE.JWK.from_map(public_map), "payload", %{
        "alg" => "RSA-OAEP",
        "enc" => "A256GCM"
      })

    {_, compact} = JOSE.JWE.compact(jwe)

    case Jar.decrypt(compact, [key]) do
      {:ok, "payload"} -> :ok
      {:ok, other} -> {:error, {:unexpected_payload, other}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Verifies a compact JWT against a public JWK and returns whether it is valid."
  @spec verify_jwt(String.t(), JOSE.JWK.t(), [String.t()]) :: boolean()
  def verify_jwt(jwt, verify, algs \\ ["RS256"]) do
    {_, public_map} = JOSE.JWK.to_public_map(verify)
    {valid?, _jwt, _jws} = JOSE.JWT.verify_strict(JOSE.JWK.from_map(public_map), algs, jwt)
    valid?
  end

  defp check({:ok, jwt}, verify, %SigningKey{} = key) when is_binary(jwt) do
    header = jwt |> JOSE.JWT.peek_protected() |> JOSE.JWS.to_map() |> elem(1)

    cond do
      not verify_jwt(jwt, verify) -> {:error, :signature_invalid}
      header["kid"] != key.kid -> {:error, {:kid_mismatch, header["kid"]}}
      true -> :ok
    end
  end

  defp check({:error, reason}, _verify, _key), do: {:error, reason}
  defp check(other, _verify, _key), do: {:error, {:unexpected, other}}
end
