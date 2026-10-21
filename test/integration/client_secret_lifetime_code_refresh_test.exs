defmodule Lockspire.Integration.ClientSecretLifetimeCodeRefreshTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  test "a code that reaches secret expiry before its locked finalizer remains unredeemed" do
    secret = "code-final-secret"

    {:ok, client} =
      create_client(
        "secret-code-final-#{Ecto.UUID.generate()}",
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{allowed_scopes: ["email", "offline_access"], access_token_format: :opaque}
      )

    ingress_at = DateTime.utc_now() |> DateTime.add(5, :second) |> DateTime.truncate(:second)
    expires_at = ingress_at |> DateTime.add(1, :second) |> to_utc_datetime_usec()
    set_secret_deadline(client, expires_at)

    raw_code = "secret-code-final-code-#{Ecto.UUID.generate()}"

    {:ok, code} =
      create_authorization_code(client,
        raw_code: raw_code,
        code_verifier: "secret-code-final-verifier"
      )

    tokens_before = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count)
    audits_before = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, %{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => raw_code,
                 "code_verifier" => "secret-code-final-verifier",
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client.client_id, secret),
               now: sequence_clock([ingress_at, expires_at])
             )

    assert {:ok, current_code} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(current_code.redeemed_at)

    assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count) ==
             tokens_before

    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audits_before
    assert {:ok, current_client} = Repository.fetch_client_by_id(client.client_id)
    assert current_client.client_secret_expires_at == expires_at
  end

  test "a refresh token that reaches secret expiry after token-family locks stays unchanged" do
    secret = "refresh-final-secret"
    client_id = "secret-refresh-final-#{Ecto.UUID.generate()}"

    {:ok, client} =
      create_client(
        client_id,
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{allowed_scopes: ["email", "offline_access"], access_token_format: :opaque}
      )

    ingress_at = DateTime.utc_now() |> DateTime.add(5, :second) |> DateTime.truncate(:second)
    expires_at = ingress_at |> DateTime.add(1, :second) |> to_utc_datetime_usec()
    set_secret_deadline(client, expires_at)
    raw = "secret-refresh-final-token-#{Ecto.UUID.generate()}"
    family_id = "secret-refresh-final-family-#{Ecto.UUID.generate()}"

    {:ok, refresh} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw),
        token_type: :refresh_token,
        family_id: family_id,
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-#{client.client_id}",
        scopes: ["email", "offline_access"],
        audience: [],
        issued_at: ingress_at,
        expires_at: DateTime.add(ingress_at, 86_400, :second)
      })

    tokens_before = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count)
    audits_before = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, %{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
             TokenExchange.exchange(%{
               params: %{"grant_type" => "refresh_token", "refresh_token" => raw},
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 transaction_store: Repository,
                 audit_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 server_policy_store: Repository,
                 now: sequence_clock([ingress_at, expires_at]),
                 refresh_token_generator: fn -> "secret-refresh-final-rotated" end
               ]
             })

    assert {:ok, current} = Repository.fetch_refresh_token(refresh.token_hash)
    assert is_nil(current.redeemed_at)
    assert is_nil(current.revoked_at)
    assert {:ok, family} = Repository.list_token_family(family_id)
    assert [^current] = family

    assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count) ==
             tokens_before

    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audits_before
  end

  test "a valid secret JWT code exchange consumes its assertion JTI once" do
    secret = "secret-jwt-final-secret"
    client_id = "secret-jwt-final-#{Ecto.UUID.generate()}"

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_id: client_id,
        client_secret_hash: nil,
        client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret),
        client_type: :confidential,
        name: "Secret JWT Final Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_jwt,
        pkce_required: true,
        access_token_format: :opaque,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    raw_code = "secret-jwt-final-code-#{Ecto.UUID.generate()}"
    jti = "secret-jwt-final-jti-#{Ecto.UUID.generate()}"

    {:ok, _code} =
      create_authorization_code(client,
        raw_code: raw_code,
        code_verifier: "secret-jwt-final-verifier"
      )

    assertion =
      Lockspire.JarTestHelpers.sign_jar(
        JOSE.JWK.from_oct(secret),
        %{
          "iss" => client.client_id,
          "sub" => client.client_id,
          "aud" => Lockspire.Config.issuer!(),
          "jti" => jti,
          "iat" => DateTime.to_unix(now),
          "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
        },
        alg: "HS256"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => raw_code,
                 "code_verifier" => "secret-jwt-final-verifier",
                 "redirect_uri" => "https://client.example.com/callback",
                 "client_assertion_type" =>
                   "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 "client_assertion" => assertion
               },
               now: sequence_clock([now, now])
             )

    assert is_binary(success.access_token)

    assert {:ok, :replay} =
             Repository.record_used_jti(%UsedJti{
               client_id: client.client_id,
               jti: jti,
               expires_at: to_utc_datetime_usec(DateTime.add(now, 600, :second))
             })
  end

  defp set_secret_deadline(client, deadline) do
    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_secret_expires_at: deadline]
             )
  end

  defp sequence_clock(values) do
    counter = :atomics.new(1, [])
    count = length(values)

    fn ->
      index = :atomics.add_get(counter, 1, 1) - 1
      Enum.at(values, min(index, count - 1))
    end
  end

  defp to_utc_datetime_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
