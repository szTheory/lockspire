defmodule Lockspire.Integration.ClientSecretLifetimePollExchangeTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.TokenRecord

  @moduletag :integration

  test "device and CIBA polls reject a secret that expires before final issuance" do
    for grant_type <- [
          "urn:ietf:params:oauth:grant-type:device_code",
          "urn:openid:params:grant-type:ciba"
        ] do
      now = future_now()
      suffix = Ecto.UUID.generate()
      secret = "poll-secret-#{suffix}"

      {:ok, client} =
        create_client("poll-secret-#{suffix}", :client_secret_basic, secret, [grant_type], %{
          access_token_format: :opaque,
          allowed_scopes: ["email"]
        })

      deadline = to_usec(now)
      set_secret_deadline(client, deadline)
      {raw_grant, fetch_authorization} = approved_grant(grant_type, client, now, suffix)
      before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
      before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

      assert {:error,
              %{
                status: 401,
                error: "invalid_client",
                reason_code: :client_secret_expired
              }} =
               poll_exchange(
                 client,
                 secret,
                 grant_type,
                 raw_grant,
                 sequence_clock([DateTime.add(now, -1, :second), now])
               )

      assert {:ok, stored} = fetch_authorization.()
      assert stored.status == :approved
      assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
      assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
    end
  end

  test "a supplied authority value cannot turn an authenticated poll into queued push" do
    now = future_now()
    secret = "poll-authority-secret"

    {:ok, client} =
      create_client(
        "poll-authority-#{Ecto.UUID.generate()}",
        :client_secret_basic,
        secret,
        ["urn:openid:params:grant-type:ciba"],
        %{access_token_format: :opaque}
      )

    deadline = to_usec(now)
    set_secret_deadline(client, deadline)

    {auth_req_id, fetch_authorization} =
      approved_grant("urn:openid:params:grant-type:ciba", client, now, Ecto.UUID.generate())

    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)

    assert {:error, %{reason_code: :client_secret_expired}} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "client_id" => client.client_id,
                 "auth_req_id" => auth_req_id,
                 "authentication_authority" => "queued_push"
               },
               authentication_authority: :queued_push,
               authorization: basic_auth(client.client_id, secret),
               opts: exchange_options(sequence_clock([DateTime.add(now, -1, :second), now]))
             })

    assert {:ok, stored} = fetch_authorization.()
    assert stored.status == :approved
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
  end

  test "a valid secret-JWT poll issues and consumes its assertion JTI once" do
    now = future_now()
    suffix = Ecto.UUID.generate()
    secret = "poll-jwt-secret-#{suffix}"
    client_id = "poll-jwt-#{suffix}"

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_id: client_id,
        client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret),
        client_type: :confidential,
        name: client_id,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        allowed_scopes: ["email"],
        token_endpoint_auth_method: :client_secret_jwt,
        access_token_format: :opaque,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {auth_req_id, fetch_authorization} =
      approved_grant("urn:openid:params:grant-type:ciba", client, now, suffix)

    jti = "poll-jti-#{suffix}"

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
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "client_id" => client.client_id,
                 "auth_req_id" => auth_req_id,
                 "client_assertion_type" =>
                   "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                 "client_assertion" => assertion
               },
               opts: exchange_options(fn -> now end)
             })

    assert is_binary(success.access_token)
    assert {:ok, stored} = fetch_authorization.()
    assert stored.status == :consumed

    assert {:ok, :replay} =
             Repository.record_used_jti(%UsedJti{
               client_id: client.client_id,
               jti: jti,
               expires_at: to_usec(DateTime.add(now, 600, :second))
             })
  end

  defp approved_grant("urn:ietf:params:oauth:grant-type:device_code", client, now, suffix) do
    authorization =
      DeviceAuthorization.issue(
        %{
          client_id: client.client_id,
          device_code: "device-#{suffix}",
          user_code: "BCDFGH#{System.unique_integer([:positive])}",
          scopes: ["email"]
        },
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_device_authorization(authorization)

    assert {:ok, _} =
             Repository.transition_device_authorization(
               authorization.verification_handle,
               [:pending],
               %{status: :approved, subject_id: "subject-#{suffix}", approved_at: now}
             )

    {authorization.device_code,
     fn ->
       Repository.fetch_device_authorization_by_verification_handle(
         authorization.verification_handle
       )
     end}
  end

  defp approved_grant("urn:openid:params:grant-type:ciba", client, now, suffix) do
    auth_req_id = "auth-req-#{suffix}"

    authorization =
      CibaAuthorization.issue(
        %{auth_req_id: auth_req_id, client_id: client.client_id, scopes: ["email"]},
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_ciba_authorization(authorization)

    assert {:ok, _} =
             Repository.transition_ciba_authorization(
               authorization.auth_req_id_hash,
               [:pending],
               %{status: :approved, subject_id: "subject-#{suffix}", approved_at: now}
             )

    {auth_req_id,
     fn ->
       Repository.fetch_ciba_authorization_by_auth_req_id_hash(authorization.auth_req_id_hash)
     end}
  end

  defp poll_exchange(client, secret, grant_type, raw_grant, clock) do
    param =
      if grant_type == "urn:openid:params:grant-type:ciba",
        do: "auth_req_id",
        else: "device_code"

    TokenExchange.exchange(%{
      params: %{"grant_type" => grant_type, "client_id" => client.client_id, param => raw_grant},
      authorization: basic_auth(client.client_id, secret),
      opts: exchange_options(clock)
    })
  end

  defp exchange_options(clock) do
    [
      client_store: Repository,
      token_store: Repository,
      transaction_store: Repository,
      audit_store: Repository,
      interaction_store: Repository,
      key_store: Repository,
      server_policy_store: Repository,
      now: clock,
      access_token_generator: fn -> "opaque-access-#{Ecto.UUID.generate()}" end,
      refresh_token_generator: fn -> "opaque-refresh-#{Ecto.UUID.generate()}" end
    ]
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
      Enum.at(values, min(:atomics.add_get(counter, 1, 1) - 1, count - 1))
    end
  end

  defp future_now, do: DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)

  defp to_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
