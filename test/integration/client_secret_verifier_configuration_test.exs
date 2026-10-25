defmodule Lockspire.Integration.ClientSecretVerifierConfigurationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @moduletag :integration
  @sentinel "INVALID-VERIFIER-CONFIG-SENTINEL"

  alias Lockspire.Clients
  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestSupport.ClientSecretVerifierFixtures, as: Fixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    cache_key = Config.client_secret_verifier_cache_key()
    previous_cache = :persistent_term.get(cache_key, :missing)
    previous_setting = Application.fetch_env(:lockspire, Context)

    on_exit(fn ->
      case previous_cache do
        :missing -> :persistent_term.erase(cache_key)
        context -> :persistent_term.put(cache_key, context)
      end

      case previous_setting do
        {:ok, value} -> Application.put_env(:lockspire, Context, value)
        :error -> Application.delete_env(:lockspire, Context)
      end
    end)

    :ok
  end

  test "invalid verifier configuration fails JWT and sealing locally while persisted hash auth works" do
    jwt = Fixtures.persisted_client()
    {basic_hash, basic_secret} = Clients.rotate_secret_hash()

    basic_id =
      "invalid-config-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

    basic = %Client{
      client_id: basic_id,
      client_secret_hash: basic_hash,
      token_endpoint_auth_method: :client_secret_post,
      client_type: :confidential,
      name: "Persisted post client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }

    assert {:ok, _stored_basic} = Repository.register_client(basic)
    {:ok, before} = Repository.fetch_client_by_id(jwt.client.client_id)
    assert Fixtures.secret_hash_matches?(before.client_secret_hash, jwt.plaintext_secret)

    Application.put_env(:lockspire, Context, keys: [{@sentinel, @sentinel}])

    log =
      capture_log(fn ->
        assert {:ok, %Context{state: :invalid, reason: :invalid_options} = context} =
                 Lockspire.Application.resolve_client_secret_verifier()

        refute inspect(context) =~ @sentinel
      end)

    refute log =~ @sentinel

    {jwt_result, _jti, _issued_at} = Fixtures.authenticate(jwt.client, jwt.plaintext_secret)
    assert result_kind(jwt_result) == {:error, :client_secret_verifier_unavailable}

    context = Config.client_secret_verifier_context()

    assert ClientSecretVerifier.seal(context, jwt.client.client_id, jwt.plaintext_secret) ==
             {:error, :client_secret_verifier_configuration_invalid}

    assert {:ok, after_attempt} = Repository.fetch_client_by_id(jwt.client.client_id)
    assert after_attempt.client_secret_hash == before.client_secret_hash

    assert after_attempt.client_secret_jwt_verifier_encrypted ==
             before.client_secret_jwt_verifier_encrypted

    assert {:ok, authenticated} =
             ClientAuth.authenticate(
               %{"client_id" => basic_id, "client_secret" => basic_secret},
               nil,
               client_store: Repository,
               jti_store: Repository,
               server_policy_store: Repository
             )

    assert authenticated.client_id == basic_id
    assert Fixtures.secret_hash_matches?(authenticated.client_secret_hash, basic_secret)
  end

  defp result_kind({:error, %{reason_code: reason}}), do: {:error, reason}
  defp result_kind({:ok, %Client{}}), do: :ok
  defp result_kind(_other), do: :unexpected
end
