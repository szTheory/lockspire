defmodule Lockspire.Integration.AppLifetimeCodeRedemptionTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  test "authorization-code tokens share the final app-capped lifetime" do
    {:ok, client} =
      create_client(
        "lifetime-code-capped",
        :client_secret_basic,
        "capped-secret",
        ["authorization_code", "refresh_token"],
        %{allowed_scopes: ["email", "offline_access"], access_token_format: :jwt}
      )

    publish_signing_key("kid-lifetime-code-capped")
    now = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    deadline = now |> DateTime.add(1, :second) |> to_utc_datetime_usec()

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )

    assert {:ok, code} =
             create_authorization_code(client,
               raw_code: "lifetime-code-capped-code",
               code_verifier: "lifetime-code-capped-verifier",
               scopes: ["email", "offline_access"]
             )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "lifetime-code-capped-code",
                 "code_verifier" => "lifetime-code-capped-verifier",
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client.client_id, "capped-secret"),
               now: fn -> now end
             )

    assert success.expires_in == 1

    assert {:ok, access} =
             Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

    assert DateTime.compare(access.expires_at, deadline) == :eq
    assert success.refresh_token

    assert {:ok, refresh} =
             Repository.fetch_refresh_token(Policy.hash_token(success.refresh_token))

    assert DateTime.compare(refresh.expires_at, deadline) == :eq

    assert [payload] = String.split(success.access_token, ".") |> Enum.slice(1, 1)
    claims = payload |> Base.url_decode64!(padding: false) |> Jason.decode!()
    assert claims["exp"] == DateTime.to_unix(deadline)

    assert {:ok, consumed} = Repository.fetch_authorization_code(code.token_hash)
    assert DateTime.compare(consumed.redeemed_at, now) == :eq
  end

  test "redemption at the current app deadline leaves the grant untouched" do
    {:ok, client} =
      create_client("lifetime-code-equality", :client_secret_basic, "equality-secret")

    publish_signing_key("kid-lifetime-code-equality")

    now = DateTime.add(DateTime.utc_now(), 6, :second) |> DateTime.truncate(:second)
    authenticated_at = DateTime.add(now, -1, :second)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: to_utc_datetime_usec(now)]
             )

    assert {:ok, code} =
             create_authorization_code(client,
               raw_code: "lifetime-code-equality-code",
               code_verifier: "lifetime-code-equality-verifier"
             )

    access_before = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count)
    audits_before = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "lifetime-code-equality-code",
                 "code_verifier" => "lifetime-code-equality-verifier",
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client.client_id, "equality-secret"),
               now: sequence_clock([authenticated_at, now])
             )

    assert error.error in ["invalid_client", "invalid_grant"]
    assert {:ok, persisted_code} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(persisted_code.redeemed_at)

    assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count) ==
             access_before

    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audits_before
  end

  test "opaque code grants persist the same app-capped access expiry" do
    {:ok, client} =
      create_client(
        "lifetime-code-opaque",
        :client_secret_basic,
        "opaque-secret",
        ["authorization_code"],
        %{access_token_format: :opaque}
      )

    now = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    deadline = now |> DateTime.add(900, :second) |> to_utc_datetime_usec()

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )

    assert {:ok, _code} =
             create_authorization_code(client,
               raw_code: "lifetime-code-opaque-code",
               code_verifier: "lifetime-code-opaque-verifier"
             )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "lifetime-code-opaque-code",
                 "code_verifier" => "lifetime-code-opaque-verifier",
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client.client_id, "opaque-secret"),
               now: fn -> now end
             )

    refute String.contains?(success.access_token, ".")
    assert success.expires_in == 900

    assert {:ok, access} =
             Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

    assert DateTime.compare(access.expires_at, deadline) == :eq
  end

  defp to_utc_datetime_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)

  defp sequence_clock(values) do
    counter = :atomics.new(1, [])
    count = length(values)

    fn ->
      index = :atomics.add_get(counter, 1, 1) - 1
      Enum.at(values, min(index, count - 1))
    end
  end
end
