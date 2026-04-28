defmodule Lockspire.Protocol.ProtectedResourceDPoPTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.ProtectedResourceDPoP
  alias Lockspire.Protocol.Userinfo.Error

  @now ~U[2026-04-28 18:00:00Z]
  @raw_access_token "userinfo-dpop-access-token"
  @userinfo_uri "https://example.test/lockspire/userinfo"

  defmodule AcceptingReplayStore do
    def record_dpop_proof(_replay), do: {:ok, :accepted}
  end

  defmodule ReplayingReplayStore do
    def record_dpop_proof(_replay), do: {:ok, :replay}
  end

  setup_all do
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    :ok
  end

  test "validates a DPoP-bound token with matching scheme proof ath and cnf thumbprint" do
    %{request: request, token: token} = dpop_request_fixture()

    assert {:ok, proof} = ProtectedResourceDPoP.validate_userinfo_access(token, request)
    assert proof.jkt == token.cnf["jkt"]
  end

  test "returns typed invalid_token errors for wrong scheme missing proof missing ath wrong ath and wrong proof key" do
    %{request: request, token: token} = dpop_request_fixture()

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | authorization_scheme: "Bearer"}),
      :invalid_dpop_authorization_scheme
    )

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, Map.delete(request, :dpop)),
      :missing_dpop_proof
    )

    %{jwt: missing_ath_proof} = proof_fixture(%{"ath" => nil})

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | dpop: missing_ath_proof}),
      :missing_dpop_ath
    )

    %{jwt: wrong_ath_proof} = proof_fixture(%{"ath" => DPoP.access_token_ath("other-access-token")})

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | dpop: wrong_ath_proof}),
      :invalid_dpop_ath
    )

    %{jwt: wrong_key_proof} = proof_fixture(%{}, key_seed: :other)

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | dpop: wrong_key_proof}),
      :dpop_binding_mismatch
    )
  end

  test "records replay state durably and rejects replayed proofs deterministically" do
    %{request: request, token: token} = dpop_request_fixture(replay_store: ReplayingReplayStore)

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, request),
      :dpop_proof_replayed
    )
  end

  test "exports signing algorithm truth and shared ath hashing" do
    assert "ES256" in DPoP.signing_alg_values_supported()
    assert DPoP.access_token_ath(@raw_access_token) == DPoP.access_token_ath(@raw_access_token)
    refute DPoP.access_token_ath(@raw_access_token) == DPoP.access_token_ath("different-token")
  end

  defp dpop_request_fixture(overrides \\ []) do
    %{validated: validated, jwt: jwt} = proof_fixture()
    replay_store = Keyword.get(overrides, :replay_store, AcceptingReplayStore)

    token = %Token{cnf: %{"jkt" => validated.jkt}}

    request = %{
      authorization_scheme: "DPoP",
      access_token: @raw_access_token,
      dpop: jwt,
      method: "GET",
      opts: [dpop_replay_store: replay_store, now: fn -> @now end]
    }

    %{request: request, token: token}
  end

  defp proof_fixture(claim_overrides \\ %{}, opts \\ []) do
    keys =
      case Keyword.get(opts, :key_seed, :default) do
        :other -> JarTestHelpers.generate_ec_keys()
        _default -> JarTestHelpers.generate_ec_keys()
      end

    claims =
      %{
        "htm" => "GET",
        "htu" => @userinfo_uri,
        "iat" => DateTime.to_unix(@now),
        "jti" => Ecto.UUID.generate(),
        "ath" => DPoP.access_token_ath(@raw_access_token)
      }
      |> Map.merge(claim_overrides)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    jwt = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    assert {:ok, validated} =
             DPoP.validate_proof(jwt,
               method: "GET",
               target_uri: @userinfo_uri,
               now: @now,
               max_age: 300,
               clock_skew: 30
             )

    %{jwt: jwt, validated: validated}
  end

  defp assert_invalid_token({:error, %Error{} = error}, reason_code) do
    assert error.status == 401
    assert error.error == "invalid_token"
    assert error.reason_code == reason_code
  end
end
