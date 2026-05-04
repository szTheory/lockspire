defmodule Lockspire.Phase38SessionLogoutResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-phase38"}}

  @impl true
  def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

  @impl true
  def build_claims(account, _context) do
    {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, _context) do
    %InteractionResult{login_path: "/sign-in"}
  end

  @impl true
  def redirect_for_logout(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/host/logout",
      return_to: Map.get(context, :return_to),
      params: %{"account_id" => Map.get(context, :account_id)}
    }
  end
end

defmodule Lockspire.Phase38SessionLogoutE2ETest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Protocol.IdToken
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :logout_path, "/fallback/logout")
    Application.put_env(:lockspire, :account_resolver, Lockspire.Phase38SessionLogoutResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    Application.put_env(:lockspire, :account_resolver, Lockspire.Phase38SessionLogoutResolver)

    {:ok, client} = register_public_client()
    signing_key = publish_signing_key("phase38-e2e-kid")

    %{client: client, signing_key: signing_key}
  end

  test "sid is generated at interaction creation and denormalized onto issued tokens", %{
    client: client,
    signing_key: signing_key
  } do
    verifier = String.duplicate("v", 43)

    %{interaction: interaction, success: success} =
      issue_openid_session(client, verifier, signing_key)

    assert is_binary(interaction.sid)

    assert {:ok, %Token{} = access_token} =
             lifecycle_token(interaction.interaction_id, :access_token)

    assert {:ok, %Token{} = refresh_token} =
             lifecycle_token(interaction.interaction_id, :refresh_token)

    assert access_token.sid == interaction.sid
    assert refresh_token.sid == interaction.sid

    claims = decode_id_token(success.id_token, signing_key.public_jwk)
    assert claims["sid"] == interaction.sid
  end

  test "revoke_by_sid/1 revokes all active tokens for the session" do
    now = DateTime.utc_now()

    {:ok, _refresh} =
      Repository.store_token(%Token{
        token_hash: "phase38-refresh-a",
        token_type: :refresh_token,
        family_id: "phase38-family-a",
        generation: 0,
        client_id: "phase38-public-client",
        account_id: "subject-phase38",
        sid: "phase38-sid",
        scopes: ["offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _access} =
      Repository.store_token(%Token{
        token_hash: "phase38-access-a",
        token_type: :access_token,
        family_id: "phase38-family-a",
        generation: 1,
        client_id: "phase38-public-client",
        account_id: "subject-phase38",
        sid: "phase38-sid",
        scopes: ["openid"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _redeemed_code} =
      Repository.store_token(%Token{
        token_hash: "phase38-code-redeemed",
        token_type: :authorization_code,
        client_id: "phase38-public-client",
        account_id: "subject-phase38",
        sid: "phase38-sid",
        redirect_uri: "https://client.example.com/callback",
        scopes: ["openid"],
        code_challenge: code_challenge(String.duplicate("v", 43)),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second),
        redeemed_at: now
      })

    assert {:ok, 2} = Repository.revoke_by_sid("phase38-sid")

    active_revoked =
      TokenRecord
      |> where(
        [token],
        token.sid == ^"phase38-sid" and token.token_type in [:access_token, :refresh_token]
      )
      |> Lockspire.TestRepo.all()

    assert Enum.all?(active_revoked, & &1.revoked_at)

    redeemed_code =
      TokenRecord
      |> where([token], token.token_hash == ^"phase38-code-redeemed")
      |> Lockspire.TestRepo.one!()

    assert is_nil(redeemed_code.revoked_at)
  end

  test "full RP-initiated logout flow: GET /end_session -> host completion -> redirect", %{
    client: client,
    signing_key: signing_key
  } do
    verifier = String.duplicate("w", 43)

    %{interaction: interaction, success: success} =
      issue_openid_session(client, verifier, signing_key)

    conn =
      build_conn(:get, "/end_session", %{
        "client_id" => client.client_id,
        "id_token_hint" => success.id_token,
        "post_logout_redirect_uri" => "https://client.example.com/logged-out",
        "state" => "phase38-logout-state"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status in [302, 303]
    host_redirect = redirect_location(conn)
    assert String.starts_with?(host_redirect, "/host/logout?")

    completion_url =
      host_redirect
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.fetch!("return_to")

    completion_path = String.replace_prefix(completion_url, "/lockspire", "")
    %URI{path: completion_route, query: completion_query} = URI.parse(completion_path)
    completion_params = URI.decode_query(completion_query || "")

    completion_conn =
      build_conn(:get, completion_route, completion_params)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert completion_conn.status in [302, 303]

    assert redirect_location(completion_conn) ==
             "https://client.example.com/logged-out?state=phase38-logout-state"

    revoked_count =
      TokenRecord
      |> where([token], token.sid == ^interaction.sid and not is_nil(token.revoked_at))
      |> Lockspire.TestRepo.aggregate(:count, :id)

    assert revoked_count >= 2
    assert decode_id_token(success.id_token, signing_key.public_jwk)["sid"] == interaction.sid
  end

  defp register_public_client do
    Repository.register_client(%Client{
      client_id: "phase38-public-client",
      client_type: :public,
      name: "Phase 38 Public Client",
      redirect_uris: ["https://client.example.com/callback"],
      post_logout_redirect_uris: ["https://client.example.com/logged-out"],
      allowed_scopes: ["profile"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp publish_signing_key(kid) do
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)
    private_jwk = JOSE.JWK.to_map(keys.private_jwk) |> elem(1)

    {:ok, _stored_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk:
          public_jwk
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{
      kid: kid,
      alg: "RS256",
      private_jwk: keys.private_jwk,
      private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
      public_jwk: public_jwk
    }
  end

  defp issue_openid_session(client, verifier, signing_key) do
    validated = %Validated{
      client: client,
      client_id: client.client_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: ["openid", "profile"],
      prompt: [],
      nonce: "phase38-nonce",
      state: "phase38-state",
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256
    }

    subject_context = %{subject_id: "subject-phase38"}
    opts = [interaction_store: Repository, consent_store: Repository, token_store: Repository]

    assert {:consent_required, interaction} =
             AuthorizationFlow.start_authorization(validated, subject_context, opts)

    assert {:approved, redirect_uri} =
             AuthorizationFlow.approve_interaction(
               interaction.interaction_id,
               subject_context,
               opts
             )

    assert {:ok, %Lockspire.Domain.Interaction{} = issued_interaction} =
             Repository.fetch_interaction(interaction.interaction_id)

    assert URI.parse(redirect_uri).query =~ "code="

    now = DateTime.utc_now()
    family_id = "phase38-family-#{issued_interaction.interaction_id}"
    raw_access_token = "phase38-access-#{issued_interaction.interaction_id}"

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: "phase38-refresh-#{issued_interaction.interaction_id}",
        token_type: :refresh_token,
        family_id: family_id,
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-phase38",
        interaction_id: issued_interaction.interaction_id,
        sid: issued_interaction.sid,
        scopes: ["offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: raw_access_token,
        token_type: :access_token,
        family_id: family_id,
        generation: 1,
        parent_token_id: refresh_token.id,
        client_id: client.client_id,
        account_id: "subject-phase38",
        interaction_id: issued_interaction.interaction_id,
        sid: issued_interaction.sid,
        scopes: ["openid", "profile"],
        issued_at: DateTime.add(now, 5, :second),
        expires_at: DateTime.add(now, 3600, :second)
      })

    assert {:ok, id_token} =
             IdToken.sign(%{
               client_id: client.client_id,
               issuer: "https://auth.example.com",
               host_claims: %Claims{subject: "subject-phase38", id_token: %{}, userinfo: %{}},
               interaction_nonce: issued_interaction.nonce,
               auth_time: issued_interaction.auth_time,
               sid: issued_interaction.sid,
               access_token: raw_access_token,
               issued_at: now,
               signing_key: %{
                 kid: signing_key.kid,
                 alg: signing_key.alg,
                 private_jwk_encrypted: signing_key.private_jwk_encrypted
               }
             })

    %{interaction: issued_interaction, success: %{id_token: id_token}}
  end

  defp lifecycle_token(interaction_id, token_type) do
    case Repository.list_lifecycle_tokens() do
      {:ok, tokens} ->
        tokens
        |> Enum.find(&(&1.interaction_id == interaction_id and &1.token_type == token_type))
        |> case do
          %Token{} = token -> {:ok, token}
          nil -> {:error, :not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode_id_token(jwt, public_jwk_map) do
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)

    claims
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp redirect_location(conn), do: List.first(Plug.Conn.get_resp_header(conn, "location"))
end
