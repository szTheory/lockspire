defmodule Lockspire.Integration.ClientSecretVerifierGuardedIssuanceTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  setup do
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    context = verifier_context(:crypto.strong_rand_bytes(32))
    :persistent_term.put(cache_key, context)
    Process.delete(:guarded_issuance_mutation)

    on_exit(fn ->
      Process.delete(:guarded_issuance_mutation)

      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)

    %{context: context}
  end

  test "READER-TOKEN-EXCHANGE issues a token from persisted dedicated verifier credentials", %{
    context: context
  } do
    fixture = persisted_jwt_client(context)
    before = effects(fixture.client.client_id)

    assert {:ok, success} = exchange_guarded(fixture, "positive-assertion")
    assert is_binary(success.access_token)
    assert effects(fixture.client.client_id).tokens == before.tokens + 1
    assert effects(fixture.client.client_id).jtis == before.jtis + 1
  end

  test "READER-TOKEN-EXCHANGE rejects ciphertext-only change at the current-authority guard; consumed JTI stays consumed",
       %{context: context} do
    fixture = persisted_jwt_client(context)
    before = effects(fixture.client.client_id)
    replacement = seal(context, fixture.client.client_id, fixture.secret)
    assert replacement != fixture.encrypted
    Process.put(:guarded_issuance_mutation, {fixture.client.client_id, replacement})

    result = exchange_guarded(fixture, "guarded-assertion")

    assert {:error,
            %TokenExchange.Error{error: "invalid_client", reason_code: :credential_changed}} =
             result

    assert {:ok, current} = Repository.fetch_client_by_id(fixture.client.client_id)
    assert current.client_secret_hash == fixture.client.client_secret_hash
    assert current.client_secret_jwt_verifier_encrypted == replacement
    refute current.client_secret_jwt_verifier_encrypted == fixture.encrypted

    after_guard = effects(fixture.client.client_id)
    assert after_guard.jtis == before.jtis + 1
    assert after_guard.tokens == before.tokens
    assert after_guard.code_redeemed_at == before.code_redeemed_at
    assert after_guard.grants == before.grants

    replay = exchange_guarded(fixture, "guarded-assertion")

    assert {:error,
            %TokenExchange.Error{error: "invalid_client", reason_code: :client_assertion_replayed}} =
             replay

    assert effects(fixture.client.client_id) == after_guard

    assert {:ok, success} = exchange_guarded(fixture, "fresh-assertion")
    assert is_binary(success.access_token)
    after_retry = effects(fixture.client.client_id)
    assert after_retry.jtis == after_guard.jtis + 1
    assert after_retry.tokens == after_guard.tokens + 1
    assert %DateTime{} = after_retry.code_redeemed_at
    assert after_retry.grants >= after_guard.grants
  end

  defmodule ClientStore do
    def lifetime_contract,
      do: %{
        version: 1,
        transaction_authority:
          Lockspire.Integration.ClientSecretVerifierGuardedIssuanceTest.TransactionStore.transaction_authority()
      }

    def fetch_client_by_id(client_id) do
      result = Repository.fetch_client_by_id(client_id)

      case Process.get(:guarded_issuance_mutation) do
        {^client_id, replacement} ->
          Process.delete(:guarded_issuance_mutation)

          from(client in ClientRecord, where: client.client_id == ^client_id)
          |> Lockspire.TestRepo.update_all(
            set: [client_secret_jwt_verifier_encrypted: replacement]
          )

          result

        _ ->
          result
      end
    end

    def lock_clients(ids), do: Repository.lock_clients(ids)
    def record_used_jti(jti), do: Repository.record_used_jti(jti)
  end

  defmodule TransactionStore do
    def transaction_authority do
      base = Repository.transaction_authority()

      %{
        base
        | identity: {:client_secret_verifier_guarded_issuance, base.identity},
          participants:
            base.participants
            |> Map.put(
              :client_store,
              Lockspire.Integration.ClientSecretVerifierGuardedIssuanceTest.ClientStore
            )
            |> Map.put(:transaction_store, __MODULE__)
      }
    end

    def transact(fun), do: Repository.transact(fun)
    def rollback(reason), do: Repository.rollback(reason)
  end

  defp persisted_jwt_client(context) do
    suffix = Ecto.UUID.generate()
    secret = "guard-secret-#{suffix}"
    client_id = "guard-client-#{suffix}"
    {:ok, client} = create_client(client_id, :client_secret_jwt, secret)
    publish_signing_key("guard-kid-#{suffix}")
    encrypted = seal(context, client_id, secret)

    from(row in ClientRecord, where: row.client_id == ^client_id)
    |> Lockspire.TestRepo.update_all(set: [client_secret_jwt_verifier_encrypted: encrypted])

    raw_code = "guard-code-#{suffix}"
    code_verifier = "guard-pkce-verifier-#{suffix}"
    {:ok, _} = create_authorization_code(client, raw_code: raw_code, code_verifier: code_verifier)

    %{
      client: client,
      secret: secret,
      encrypted: encrypted,
      raw_code: raw_code,
      code_verifier: code_verifier
    }
  end

  defp exchange_guarded(fixture, jti) do
    assertion = signed_assertion(fixture.client.client_id, fixture.secret, jti)

    TokenExchange.exchange_authorization_code(%{
      params: %{
        "grant_type" => "authorization_code",
        "code" => fixture.raw_code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => fixture.code_verifier,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => assertion
      },
      opts: [
        client_store: ClientStore,
        token_store: Repository,
        transaction_store: TransactionStore,
        audit_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Repository,
        now: fn -> DateTime.utc_now() end,
        access_token_generator: fn -> "guard-access-#{Ecto.UUID.generate()}" end,
        refresh_token_generator: fn -> "guard-refresh-#{Ecto.UUID.generate()}" end
      ]
    })
  end

  defp effects(client_id) do
    %{
      jtis:
        Lockspire.TestRepo.aggregate(
          from(jti in Lockspire.Storage.Ecto.UsedJtiRecord, where: jti.client_id == ^client_id),
          :count
        ),
      tokens:
        Lockspire.TestRepo.aggregate(
          from(token in Lockspire.Storage.Ecto.TokenRecord,
            where: token.client_id == ^client_id and token.token_type != :authorization_code
          ),
          :count
        ),
      grants:
        Lockspire.TestRepo.aggregate(
          from(grant in Lockspire.Storage.Ecto.ConsentGrantRecord,
            where: grant.client_id == ^client_id
          ),
          :count
        ),
      code_redeemed_at:
        Lockspire.TestRepo.one(
          from(token in Lockspire.Storage.Ecto.TokenRecord,
            where: token.client_id == ^client_id and token.token_type == :authorization_code,
            select: token.redeemed_at
          )
        )
    }
  end

  defp signed_assertion(client_id, secret, jti) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    JOSE.JWK.from_oct(secret)
    |> JOSE.JWT.sign(%{"alg" => "HS256"}, %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => "https://example.test/lockspire",
      "jti" => jti,
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.to_unix(DateTime.add(now, 300, :second))
    })
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp seal(context, client_id, secret) do
    {:ok, encrypted} = ClientSecretVerifier.seal(context, client_id, secret)
    encrypted
  end

  defp verifier_context(key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"guarded-issuance", Base.url_encode64(key, padding: false)}],
           current: "guarded-issuance",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end
end
