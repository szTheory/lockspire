defmodule Lockspire.Protocol.AccessTokenSignerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  # ---------------------------------------------------------------------------
  # Mocks — mirror token_controller.ex opts (key_store + server_policy_store).
  # ---------------------------------------------------------------------------

  defmodule MockKeyStore do
    def fetch_active_signing_key do
      jwk =
        JOSE.JWK.generate_key({:rsa, 2048})
        |> JOSE.JWK.to_map()
        |> elem(1)
        |> Jason.encode!()

      {:ok, %{alg: "RS256", kid: "key-1", private_jwk_encrypted: jwk}}
    end
  end

  defmodule MissingKeyStore do
    def fetch_active_signing_key, do: {:ok, nil}
  end

  # A server policy store whose default format is configured per-test via the
  # process dictionary so the precedence cases can share one module.
  defmodule MockServerPolicyStore do
    def get_server_policy do
      {:ok, %ServerPolicy{access_token_format: Process.get({__MODULE__, :format}, :jwt)}}
    end
  end

  defp put_server_default(format), do: Process.put({MockServerPolicyStore, :format}, format)

  defp request(opts \\ []) do
    base = [
      key_store: MockKeyStore,
      server_policy_store: MockServerPolicyStore
    ]

    %{opts: Keyword.merge(base, opts)}
  end

  defp client(attrs \\ []) do
    struct!(
      %Client{
        client_id: "test_client",
        allowed_grant_types: ["authorization_code"]
      },
      attrs
    )
  end

  defp token(attrs \\ []) do
    struct!(
      %Token{
        token_hash: "placeholder",
        token_type: :access_token,
        client_id: "test_client",
        account_id: "account-123",
        scopes: ["read", "write"],
        audience: [],
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      },
      attrs
    )
  end

  defp decode_jwt_payload(raw) do
    assert [_header_b64, payload_b64, _sig_b64] = String.split(raw, ".")
    payload_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
  end

  defp decode_jwt_header(raw) do
    assert [header_b64, _payload_b64, _sig_b64] = String.split(raw, ".")
    header_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
  end

  # ---------------------------------------------------------------------------
  # (a) :jwt effective format — claims + hash equality.
  # ---------------------------------------------------------------------------

  describe "issue/3 with effective :jwt format" do
    test "produces an at+jwt JWT with the expected claims and matching hash" do
      put_server_default(:jwt)
      tok = token(account_id: "account-123", scopes: ["read", "write"])

      assert {:ok, raw, hash} = AccessTokenSigner.issue(tok, client(), request())

      header = decode_jwt_header(raw)
      assert header["typ"] == "at+jwt"

      payload = decode_jwt_payload(raw)
      assert payload["iss"] == Lockspire.Config.issuer!()
      assert payload["sub"] == "account-123"
      assert payload["client_id"] == "test_client"
      assert is_binary(payload["jti"]) and payload["jti"] != ""
      assert payload["scope"] == "read write"
      assert payload["exp"] == payload["iat"] + 3600

      assert hash == Policy.hash_token(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # (b) Format precedence — per-client override → server default → :jwt.
  # ---------------------------------------------------------------------------

  describe "format precedence" do
    test "per-client :opaque wins over a server default of :jwt" do
      put_server_default(:jwt)
      tok = token()

      assert {:ok, raw, _hash} =
               AccessTokenSigner.issue(tok, client(access_token_format: :opaque), request())

      refute String.contains?(raw, "."), "opaque token must not be a JWT"
    end

    test "per-client nil inherits the server default of :jwt" do
      put_server_default(:jwt)
      tok = token()

      assert {:ok, raw, _hash} =
               AccessTokenSigner.issue(tok, client(access_token_format: nil), request())

      assert [_h, _p, _s] = String.split(raw, "."), "should be a JWT (inherited :jwt default)"
    end

    test "per-client nil inherits a server default of :opaque" do
      put_server_default(:opaque)
      tok = token()

      assert {:ok, raw, _hash} =
               AccessTokenSigner.issue(tok, client(access_token_format: nil), request())

      refute String.contains?(raw, "."), "should be opaque (inherited :opaque default)"
    end

    test "absent per-client and absent server default falls back to :jwt" do
      # No server_policy_store at all → fallback to :jwt.
      tok = token()
      req = %{opts: [key_store: MockKeyStore]}

      assert {:ok, raw, _hash} = AccessTokenSigner.issue(tok, client(access_token_format: nil), req)

      assert [_h, _p, _s] = String.split(raw, "."), "should fall back to :jwt"
    end
  end

  # ---------------------------------------------------------------------------
  # (c) :opaque effective format — delegate to TokenFormatter.
  # ---------------------------------------------------------------------------

  describe "issue/3 with effective :opaque format" do
    test "returns a non-JWT token whose hash equals Policy.hash_token(raw)" do
      put_server_default(:opaque)
      tok = token()

      assert {:ok, raw, hash} =
               AccessTokenSigner.issue(tok, client(access_token_format: :opaque), request())

      refute String.contains?(raw, ".")
      assert hash == Policy.hash_token(raw)
      # Same SHA-256 convention as the TokenFormatter delegate.
      assert hash == TokenFormatter.hash_token(raw)
    end
  end

  # ---------------------------------------------------------------------------
  # (d) aud derivation — list form for grant paths, bare string for exchange.
  # ---------------------------------------------------------------------------

  describe "aud derivation" do
    test "non-empty token audience becomes the list aud" do
      put_server_default(:jwt)
      tok = token(audience: ["https://billing.example.com"])

      assert {:ok, raw, _hash} = AccessTokenSigner.issue(tok, client(), request())

      payload = decode_jwt_payload(raw)
      assert payload["aud"] == ["https://billing.example.com"]
    end

    test "empty token audience becomes [client_id] as a list" do
      put_server_default(:jwt)
      tok = token(audience: [])

      assert {:ok, raw, _hash} = AccessTokenSigner.issue(tok, client(client_id: "abc"), request())

      payload = decode_jwt_payload(raw)
      assert payload["aud"] == ["abc"]
    end

    test "exchange-mode emits a bare client_id string aud (RFC 8693 carve-out)" do
      put_server_default(:jwt)
      tok = token(audience: [])

      assert {:ok, raw, _hash} =
               AccessTokenSigner.issue_exchange(tok, client(client_id: "abc"), %{}, request())

      payload = decode_jwt_payload(raw)
      assert payload["aud"] == "abc", "exchange aud must remain a bare string"
    end

    test "exchange-mode merges custom claims but drops restricted claims" do
      put_server_default(:jwt)
      tok = token()

      custom = %{"custom_role" => "admin", "iss" => "attacker", "aud" => "attacker"}

      assert {:ok, raw, _hash} =
               AccessTokenSigner.issue_exchange(tok, client(client_id: "abc"), custom, request())

      payload = decode_jwt_payload(raw)
      assert payload["custom_role"] == "admin"
      assert payload["iss"] == Lockspire.Config.issuer!()
      assert payload["aud"] == "abc"
    end
  end

  # ---------------------------------------------------------------------------
  # (e) cnf carry-through.
  # ---------------------------------------------------------------------------

  describe "cnf carry-through" do
    test "copies token.cnf into the JWT when present" do
      put_server_default(:jwt)
      tok = token(cnf: %{"jkt" => "x"})

      assert {:ok, raw, _hash} = AccessTokenSigner.issue(tok, client(), request())

      payload = decode_jwt_payload(raw)
      assert payload["cnf"] == %{"jkt" => "x"}
    end

    test "omits cnf when token.cnf is nil" do
      put_server_default(:jwt)
      tok = token(cnf: nil)

      assert {:ok, raw, _hash} = AccessTokenSigner.issue(tok, client(), request())

      payload = decode_jwt_payload(raw)
      refute Map.has_key?(payload, "cnf")
    end
  end

  # ---------------------------------------------------------------------------
  # (f) Missing signing key — 500, no key material in logs.
  # ---------------------------------------------------------------------------

  describe "missing signing key" do
    test "returns a 500 token_signing_failed error" do
      put_server_default(:jwt)
      tok = token()
      req = request(key_store: MissingKeyStore)

      assert {:error, %Error{} = error} = AccessTokenSigner.issue(tok, client(), req)
      assert error.status == 500
      assert error.error == "server_error"
      assert error.reason_code == :token_signing_failed
    end

    test "does not log key material on the error path" do
      put_server_default(:jwt)
      tok = token()
      req = request(key_store: MissingKeyStore)

      log =
        capture_log(fn ->
          assert {:error, %Error{}} = AccessTokenSigner.issue(tok, client(), req)
        end)

      refute log =~ "private_jwk"
      refute log =~ "BEGIN"
      refute String.match?(log, ~r/"d"\s*:/), "no JWK private exponent in logs"
    end
  end
end
