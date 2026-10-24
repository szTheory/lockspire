defmodule Lockspire.Integration.AppLifetimeRefreshTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query
  import Plug.Test

  alias Lockspire.KeyCache
  alias Lockspire.Plug.VerifyToken
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  test "refresh access and replacement refresh expiries share the app cap" do
    {:ok, client} = refresh_client("refresh-capped")
    publish_signing_key("kid-refresh-capped")
    now = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 20, :second) |> to_utc_datetime_usec()
    {refresh, raw} = seed_refresh(client, "refresh-capped-token", "refresh-capped-family", now)
    set_app_deadline(client, deadline)

    assert {:ok, success} = refresh_exchange(client, raw, fn -> now end)
    assert success.expires_in == 20
    assert {header, claims} = verify_at_jwt(success.access_token)
    assert header["typ"] == "at+jwt"
    assert claims["exp"] == DateTime.to_unix(deadline)

    assert {:ok, access} =
             Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

    assert DateTime.compare(access.expires_at, deadline) == :eq

    assert {:ok, rotated} =
             Repository.fetch_refresh_token(Policy.hash_token(success.refresh_token))

    assert DateTime.compare(rotated.expires_at, deadline) == :eq
    assert {:ok, consumed} = Repository.fetch_refresh_token(refresh.token_hash)
    assert not is_nil(consumed.redeemed_at)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [active: false]
             )

    if Process.whereis(KeyCache) do
      send(KeyCache, :refresh)
      :sys.get_state(KeyCache)
    end

    verified =
      conn(:get, "/")
      |> Plug.Conn.put_req_header("authorization", "Bearer #{success.access_token}")
      |> VerifyToken.call(VerifyToken.init([]))

    assert verified.assigns.access_token.error == nil
  end

  test "app deadline equality rejects without consuming or changing the family or audit" do
    {:ok, client} = refresh_client("refresh-equality")
    publish_signing_key("kid-refresh-equality")
    now = DateTime.add(DateTime.utc_now(), 8, :second) |> DateTime.truncate(:second)

    {refresh, raw} =
      seed_refresh(client, "refresh-equality-token", "refresh-equality-family", now)

    set_app_deadline(client, to_utc_datetime_usec(now))
    before_tokens = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, error} =
             refresh_exchange(client, raw, sequence_clock([DateTime.add(now, -1, :second), now]))

    assert error.error == "invalid_client"
    assert {:ok, current} = Repository.fetch_refresh_token(refresh.token_hash)
    assert is_nil(current.redeemed_at)
    assert is_nil(current.revoked_at)
    assert {:ok, family} = Repository.list_token_family("refresh-equality-family")
    assert length(family) == 1

    assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count) ==
             before_tokens

    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "valid replay still revokes every token in the refresh family" do
    {:ok, client} = refresh_client("refresh-reuse")
    publish_signing_key("kid-refresh-reuse")
    now = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    {refresh, raw} = seed_refresh(client, "refresh-reuse-token", "refresh-reuse-family", now)
    assert {:ok, _success} = refresh_exchange(client, raw, fn -> now end)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, error} =
             refresh_exchange(client, raw, fn -> DateTime.add(now, 1, :second) end)

    assert error.reason_code == :refresh_token_reuse_detected

    assert {:ok, family} = Repository.list_token_family("refresh-reuse-family")
    assert Enum.all?(family, &(not is_nil(&1.revoked_at)))
    assert Enum.any?(family, &(not is_nil(&1.reuse_detected_at)))
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits + 2
    assert {:ok, _presented} = Repository.fetch_refresh_token(refresh.token_hash)
  end

  defp refresh_client(id) do
    create_client(
      id,
      :client_secret_basic,
      "secret-#{id}",
      ["authorization_code", "refresh_token"],
      %{
        allowed_scopes: ["email", "offline_access"],
        access_token_format: :jwt
      }
    )
  end

  defp seed_refresh(client, raw, family_id, now) do
    {:ok, refresh} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw),
        token_type: :refresh_token,
        family_id: family_id,
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-#{client.client_id}",
        scopes: ["email", "offline_access"],
        audience: ["api.example.test"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {refresh, raw}
  end

  defp set_app_deadline(client, deadline) do
    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )
  end

  defp refresh_exchange(client, raw_refresh, now) do
    TokenExchange.exchange(%{
      params: %{"grant_type" => "refresh_token", "refresh_token" => raw_refresh},
      authorization: basic_auth(client.client_id, "secret-#{client.client_id}"),
      opts: [
        client_store: Repository,
        token_store: Repository,
        transaction_store: Repository,
        audit_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Repository,
        now: now,
        refresh_token_generator: fn -> "rotated-#{Ecto.UUID.generate()}" end
      ]
    })
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
