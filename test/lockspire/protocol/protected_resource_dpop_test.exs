defmodule Lockspire.Protocol.ProtectedResourceDPoPTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
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

  test "validates generic protected-resource requests with explicit target uri and binding requirements" do
    %{request: request} = dpop_request_fixture()
    target_uri = "https://api.example.test/resource"
    %{jwt: proof, validated: validated} = proof_fixture(%{"htu" => target_uri, "htm" => "POST"})

    binding_source = %{binding_requirements: %{dpop_jkt: validated.jkt}}

    assert {:ok, validated_proof} =
             ProtectedResourceDPoP.validate_access(binding_source, %{
               request
               | dpop: proof,
                 method: "POST",
                 target_uri: target_uri
             })

    assert validated_proof.jkt == validated.jkt
  end

  test "returns typed invalid_token errors for wrong scheme missing proof missing ath wrong ath and wrong proof key" do
    %{request: request, token: token} = dpop_request_fixture()

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{
        request
        | authorization_scheme: "Bearer"
      }),
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

    %{jwt: wrong_ath_proof} =
      proof_fixture(%{"ath" => DPoP.access_token_ath("other-access-token")})

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | dpop: wrong_ath_proof}),
      :invalid_dpop_ath
    )

    %{jwt: wrong_key_proof} = proof_fixture(%{}, key_seed: :other)

    assert_invalid_token(
      ProtectedResourceDPoP.validate_userinfo_access(token, %{request | dpop: wrong_key_proof}),
      :dpop_binding_mismatch
    )

    assert_invalid_token(
      ProtectedResourceDPoP.validate_access(
        %{binding_requirements: %{dpop_jkt: token.cnf["jkt"]}},
        Map.delete(request, :target_uri)
      ),
      :invalid_dpop_target_uri
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

  test "returns use_dpop_nonce with a new resource nonce when the proof omits nonce" do
    %{request: request, token: token} = dpop_request_fixture(nonce: nil)

    assert {:error, %Error{} = error} = ProtectedResourceDPoP.validate_userinfo_access(token, request)
    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)
  end

  test "returns use_dpop_nonce when the proof carries an authorization-server nonce on the resource surface" do
    %{request: request, token: token} =
      dpop_request_fixture(nonce: DPoPNonce.issue(:authorization_server))

    assert {:error, %Error{} = error} =
             ProtectedResourceDPoP.validate_userinfo_access(token, request)

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :invalid_dpop_nonce
    assert is_binary(error.dpop_nonce)
  end

  defp dpop_request_fixture(overrides \\ []) do
    replay_store = Keyword.get(overrides, :replay_store, AcceptingReplayStore)
    proof_data =
      case Keyword.fetch(overrides, :nonce) do
        {:ok, nonce} -> proof_fixture(%{"nonce" => nonce})
        :error -> proof_fixture()
      end

    token = %Token{cnf: %{"jkt" => proof_data.validated.jkt}}

    request = %{
      authorization_scheme: "DPoP",
      access_token: @raw_access_token,
      dpop: proof_data.jwt,
      method: "GET",
      target_uri: @userinfo_uri,
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
        "ath" => DPoP.access_token_ath(@raw_access_token),
        "nonce" => DPoPNonce.issue(:resource_server)
      }
      |> Map.merge(claim_overrides)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    target_uri = Map.get(claims, "htu", @userinfo_uri)
    method = Map.get(claims, "htm", "GET")

    jwt = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    assert {:ok, validated} =
             DPoP.validate_proof(jwt,
               method: method,
               target_uri: target_uri,
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
