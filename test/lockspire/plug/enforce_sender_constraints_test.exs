defmodule Lockspire.Plug.EnforceSenderConstraintsTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias Lockspire.AccessToken
  alias Lockspire.JarTestHelpers
  alias Lockspire.Plug.EnforceSenderConstraints
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce

  @now ~U[2026-04-28 18:00:00Z]
  @target_uri "https://api.example.test/resource"
  @raw_access_token "resource-dpop-access-token"

  defmodule AcceptingReplayStore do
    def record_dpop_proof(_replay), do: {:ok, :accepted}
  end

  defmodule ReplayingReplayStore do
    def record_dpop_proof(_replay), do: {:ok, :replay}
  end

  defmodule MTLSExtractor do
    def extract(_conn, opts) do
      case Keyword.fetch!(opts, :scenario) do
        :success -> {:ok, "mtls-cert"}
        :error -> {:error, :invalid_cert}
      end
    end
  end

  test "passes through unconstrained access tokens unchanged" do
    access_token = %AccessToken{token: "plain", claims: %{"sub" => "123"}}

    conn =
      conn(:get, "/resource")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call([])

    assert conn.assigns.access_token == access_token
    refute conn.halted
  end

  test "passes through already-invalid JWTs unchanged" do
    access_token = %AccessToken{token: @raw_access_token, error: :invalid_token}

    conn =
      conn(:get, "/resource")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call([])

    assert conn.assigns.access_token.error == :invalid_token
    refute conn.halted
  end

  test "accepts DPoP-bound tokens only with matching scheme proof ath and key" do
    %{proof: proof, jkt: jkt} = dpop_fixture()

    access_token = %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "DPoP",
      binding_type: "dpop",
      binding_requirements: %{dpop_jkt: jkt},
      claims: %{"sub" => "123"}
    }

    conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        dpop_max_age: 300,
        now: fn -> @now end
      )

    assert %AccessToken{error: nil} = conn.assigns.access_token
    refute conn.halted
  end

  test "records typed sender-constraint failures for wrong scheme and missing proof" do
    %{jkt: jkt} = dpop_fixture()

    bearer_token = %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "Bearer",
      binding_type: "dpop",
      binding_requirements: %{dpop_jkt: jkt}
    }

    bearer_conn =
      request_conn()
      |> assign(:access_token, bearer_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{
             category: :sender_constraint,
             challenge: :dpop,
             reason_code: :invalid_dpop_authorization_scheme
           } = bearer_conn.assigns.access_token.error

    missing_proof_token = %AccessToken{bearer_token | authorization_scheme: "DPoP"}

    missing_proof_conn =
      request_conn()
      |> assign(:access_token, missing_proof_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{reason_code: :missing_dpop_proof} = missing_proof_conn.assigns.access_token.error
    refute missing_proof_conn.halted
  end

  test "records nonce challenges on protected-resource proofs that omit nonce" do
    %{proof: proof, jkt: jkt} = dpop_fixture(%{"nonce" => nil})

    access_token = %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "DPoP",
      binding_type: "dpop",
      binding_requirements: %{dpop_jkt: jkt}
    }

    conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{reason_code: :missing_dpop_nonce, error: "use_dpop_nonce", dpop_nonce: nonce} =
             conn.assigns.access_token.error

    assert is_binary(nonce)
  end

  test "records typed sender-constraint failures for replay ath mismatch and wrong proof key" do
    %{proof: proof, jkt: jkt} = dpop_fixture()

    access_token = %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "DPoP",
      binding_type: "dpop",
      binding_requirements: %{dpop_jkt: jkt}
    }

    replay_conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: ReplayingReplayStore,
        now: fn -> @now end
      )

    assert %{reason_code: :dpop_proof_replayed} = replay_conn.assigns.access_token.error

    wrong_ath_conn =
      request_conn()
      |> put_req_header(
        "dpop",
        dpop_fixture(%{"ath" => DPoP.access_token_ath("other-token")}).proof
      )
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{reason_code: :invalid_dpop_ath} = wrong_ath_conn.assigns.access_token.error

    wrong_key_conn =
      request_conn()
      |> put_req_header("dpop", dpop_fixture(%{}, :other).proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{reason_code: :dpop_binding_mismatch} = wrong_key_conn.assigns.access_token.error
  end

  test "accepts mtls-bound tokens from conn.private or configured extractor and records typed failures otherwise" do
    {:ok, thumbprint} = Lockspire.Protocol.MTLSTokenBinding.thumbprint("mtls-cert")

    access_token = %AccessToken{
      token: "resource-mtls-access-token",
      authorization_scheme: "Bearer",
      binding_type: "mtls",
      binding_requirements: %{mtls_x5t_s256: thumbprint},
      claims: %{"sub" => "123"}
    }

    private_conn =
      conn(:get, "/resource")
      |> put_private(:lockspire_mtls_cert, "mtls-cert")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call([])

    assert %AccessToken{error: nil} = private_conn.assigns.access_token

    extractor_conn =
      conn(:get, "/resource")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(mtls_extractor: {MTLSExtractor, scenario: :success})

    assert %AccessToken{error: nil} = extractor_conn.assigns.access_token

    missing_cert_conn =
      conn(:get, "/resource")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call([])

    assert %{challenge: :bearer, reason_code: :invalid_client_certificate} =
             missing_cert_conn.assigns.access_token.error

    wrong_cert_conn =
      conn(:get, "/resource")
      |> put_private(:lockspire_mtls_cert, "wrong-cert")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call([])

    assert %{reason_code: :invalid_client_certificate} =
             wrong_cert_conn.assigns.access_token.error
  end

  test "dual-bound tokens require both dpop and mtls in the same soft plug" do
    %{proof: proof, jkt: jkt} = dpop_fixture()
    {:ok, thumbprint} = Lockspire.Protocol.MTLSTokenBinding.thumbprint("mtls-cert")

    access_token = %AccessToken{
      token: @raw_access_token,
      authorization_scheme: "DPoP",
      binding_type: "dpop+mtls",
      binding_requirements: %{dpop_jkt: jkt, mtls_x5t_s256: thumbprint}
    }

    missing_mtls_conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %{challenge: :bearer, reason_code: :invalid_client_certificate} =
             missing_mtls_conn.assigns.access_token.error

    valid_conn =
      request_conn()
      |> put_req_header("dpop", proof)
      |> put_private(:lockspire_mtls_cert, "mtls-cert")
      |> assign(:access_token, access_token)
      |> EnforceSenderConstraints.call(
        dpop_replay_store: AcceptingReplayStore,
        now: fn -> @now end
      )

    assert %AccessToken{error: nil} = valid_conn.assigns.access_token
  end

  defp request_conn do
    conn(:post, "/resource")
    |> Map.put(:scheme, :https)
    |> Map.put(:host, "api.example.test")
    |> Map.put(:port, 443)
  end

  defp dpop_fixture(claim_overrides \\ %{}, key_seed \\ :default) do
    keys =
      case key_seed do
        :other -> JarTestHelpers.generate_ec_keys()
        _default -> JarTestHelpers.generate_ec_keys()
      end

    claims =
      %{
        "htm" => "POST",
        "htu" => @target_uri,
        "iat" => DateTime.to_unix(@now),
        "jti" => Ecto.UUID.generate(),
        "ath" => DPoP.access_token_ath(@raw_access_token),
        "nonce" => DPoPNonce.issue(:resource_server)
      }
      |> Map.merge(claim_overrides)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

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
end
