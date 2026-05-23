defmodule Lockspire.Protocol.TokenEndpointDPoPTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Protocol.MTLSTokenBinding
  alias Lockspire.Protocol.TokenEndpointDPoP

  defmodule BearerServerPolicyStore do
    def get_server_policy, do: {:ok, %ServerPolicy{dpop_policy: :bearer}}
  end

  defmodule DpopServerPolicyStore do
    def get_server_policy, do: {:ok, %ServerPolicy{dpop_policy: :dpop}}
  end

  defmodule AcceptingReplayStore do
    def record_dpop_proof(_replay), do: {:ok, :accepted}
  end

  setup_all do
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    :ok
  end

  test "resolves bearer issuance context when effective policy stays bearer" do
    client = %Client{client_id: "client-bearer", dpop_policy: :inherit}

    assert {:ok, issuance_context} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               opts: [server_policy_store: BearerServerPolicyStore]
             })

    assert issuance_context.mode == :bearer
    assert issuance_context.proof == nil
    assert issuance_context.jkt == nil
    assert issuance_context.cnf == nil
    assert issuance_context.token_type == "Bearer"
  end

  test "resolves DPoP issuance context with cnf when effective policy requires proof" do
    client = %Client{client_id: "client-dpop", dpop_policy: :inherit}
    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture()

    assert {:ok, issuance_context} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               dpop: proof_jwt,
               opts: [
                 server_policy_store: DpopServerPolicyStore,
                 dpop_replay_store: AcceptingReplayStore,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert issuance_context.mode == :dpop
    assert issuance_context.proof.jkt == validated_proof.jkt
    assert issuance_context.jkt == validated_proof.jkt
    assert issuance_context.cnf == %{"jkt" => validated_proof.jkt}
    assert issuance_context.token_type == "DPoP"
  end

  test "returns invalid_dpop_proof when effective policy requires DPoP proof but it is missing" do
    client = %Client{client_id: "client-dpop-missing", dpop_policy: :inherit}

    assert {:error, error} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               opts: [server_policy_store: DpopServerPolicyStore]
             })

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :missing_dpop_proof
  end

  test "returns use_dpop_nonce when effective policy requires DPoP proof without nonce" do
    client = %Client{client_id: "client-dpop-missing-nonce", dpop_policy: :inherit}
    %{jwt: proof_jwt} = dpop_proof_fixture(nonce: nil)

    assert {:error, error} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               dpop: proof_jwt,
               opts: [
                 server_policy_store: DpopServerPolicyStore,
                 dpop_replay_store: AcceptingReplayStore,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)
  end

  test "returns use_dpop_nonce when the proof carries a resource-server nonce on the token surface" do
    client = %Client{client_id: "client-dpop-wrong-nonce-purpose", dpop_policy: :inherit}
    %{jwt: proof_jwt} = dpop_proof_fixture(nonce: DPoPNonce.issue(:resource_server))

    assert {:error, error} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               dpop: proof_jwt,
               opts: [
                 server_policy_store: DpopServerPolicyStore,
                 dpop_replay_store: AcceptingReplayStore,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :invalid_dpop_nonce
    assert is_binary(error.dpop_nonce)
  end

  test "returns invalid_dpop_proof when proof iat is a string" do
    client = %Client{client_id: "client-dpop-invalid-iat", dpop_policy: :inherit}

    %{jwt: proof_jwt} =
      dpop_proof_fixture(iat: Integer.to_string(DateTime.utc_now() |> DateTime.to_unix()))

    assert {:error, error} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               dpop: proof_jwt,
               opts: [
                 server_policy_store: DpopServerPolicyStore,
                 dpop_replay_store: AcceptingReplayStore,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :invalid_iat
  end

  defp dpop_proof_fixture(overrides \\ []) do
    keys = JarTestHelpers.generate_ec_keys()
    now = DateTime.utc_now()
    target_uri = "https://example.test/lockspire/token"
    iat = Keyword.get(overrides, :iat, DateTime.to_unix(now))
    nonce = Keyword.get_lazy(overrides, :nonce, fn -> DPoPNonce.issue(:authorization_server) end)

    claims =
      %{
        "htm" => "POST",
        "htu" => target_uri,
        "iat" => iat,
        "jti" => Ecto.UUID.generate(),
        "nonce" => nonce
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    validated =
      case DPoP.validate_proof(proof,
             method: "POST",
             target_uri: target_uri,
             now: now,
             max_age: 300,
             clock_skew: 30
           ) do
        {:ok, %DPoP{} = proof_struct} -> proof_struct
        _other -> nil
      end

    %{jwt: proof, validated: validated}
  end

  test "resolves context with x5t#S256 when mtls_cert is provided" do
    client = %Client{client_id: "client-mtls", dpop_policy: :inherit}
    cert = "dummy_der_cert"
    {:ok, thumbprint} = MTLSTokenBinding.thumbprint(cert)

    assert {:ok, issuance_context} =
             TokenEndpointDPoP.resolve_context(client, %{
               method: "POST",
               opts: [
                 server_policy_store: BearerServerPolicyStore,
                 mtls_cert: cert
               ]
             })

    assert issuance_context.mode == :bearer
    assert issuance_context.cnf["x5t#S256"] == thumbprint
  end
end
