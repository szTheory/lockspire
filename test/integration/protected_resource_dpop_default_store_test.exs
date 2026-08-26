defmodule Lockspire.Integration.ProtectedResourceDPoPDefaultStoreTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Plug.Conn
  import Plug.Test

  alias Lockspire.AccessToken
  alias Lockspire.JarTestHelpers
  alias Lockspire.Plug.EnforceSenderConstraints
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Storage.Ecto.DpopReplayRecord

  @now DateTime.from_unix!(1_777_399_200_000_000, :microsecond)
  @raw_access_token "default-store-resource-dpop-access-token"
  @target_uri "https://api.example.test/resource"

  setup_all do
    previous_repo = Application.get_env(:lockspire, :repo)
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    on_exit(fn -> restore_env(:repo, previous_repo) end)

    unless Process.whereis(Lockspire.TestRepo), do: start_supervised!(Lockspire.TestRepo)

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "omitting the replay-store override persists once and rejects the identical proof" do
    %{proof: proof, jkt: jkt} = dpop_fixture()
    access_token = dpop_bound_access_token(jkt)

    first_conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(now: fn -> @now end)

    assert %AccessToken{error: nil, binding_verified: true} = first_conn.assigns.access_token

    assert [%DpopReplayRecord{jkt: ^jkt, htm: "POST", htu: @target_uri}] =
             Lockspire.TestRepo.all(DpopReplayRecord)

    replay_conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(now: fn -> @now end)

    assert %AccessToken{
             binding_verified: false,
             error: %{category: :sender_constraint, reason_code: :dpop_proof_replayed}
           } = replay_conn.assigns.access_token
  end

  test "a legacy nil replay-store override still uses the configured repository" do
    %{proof: proof, jkt: jkt} = dpop_fixture()

    conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, dpop_bound_access_token(jkt))
      |> EnforceSenderConstraints.call(dpop_replay_store: nil, now: fn -> @now end)

    assert %AccessToken{error: nil, binding_verified: true} = conn.assigns.access_token
    assert [%DpopReplayRecord{jkt: ^jkt}] = Lockspire.TestRepo.all(DpopReplayRecord)
  end

  defp dpop_bound_access_token(jkt) do
    %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "DPoP",
      binding_type: "dpop",
      binding_requirements: %{dpop_jkt: jkt},
      claims: %{"sub" => "integration-user"}
    }
  end

  defp request_conn do
    conn(:post, "/resource")
    |> Map.put(:scheme, :https)
    |> Map.put(:host, "api.example.test")
    |> Map.put(:port, 443)
  end

  defp dpop_fixture do
    keys = JarTestHelpers.generate_ec_keys()

    claims = %{
      "htm" => "POST",
      "htu" => @target_uri,
      "iat" => DateTime.to_unix(@now),
      "jti" => Ecto.UUID.generate(),
      "ath" => DPoP.access_token_ath(@raw_access_token),
      "nonce" => DPoPNonce.issue(:resource_server)
    }

    proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    assert {:ok, validated} =
             DPoP.validate_proof(proof,
               method: "POST",
               target_uri: @target_uri,
               now: @now,
               max_age: 300,
               clock_skew: 30
             )

    %{proof: proof, jkt: validated.jkt}
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
