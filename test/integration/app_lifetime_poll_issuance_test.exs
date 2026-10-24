defmodule Lockspire.Integration.AppLifetimePollIssuanceTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  test "approved device request is not consumed when app expires at final issuance" do
    now = future_now()
    {:ok, client} = poll_client("device-equality", "urn:ietf:params:oauth:grant-type:device_code")
    deadline = to_usec(now)
    set_deadline(client, deadline)
    publish_signing_key("kid-device-equality")

    request = device_request(client, now)
    assert {:ok, _} = Repository.put_device_authorization(request)

    assert {:ok, _} =
             Repository.transition_device_authorization(
               request.verification_handle,
               [:pending],
               %{status: :approved, subject_id: "subject-device", approved_at: now}
             )

    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, error} =
             poll_exchange(
               client,
               "urn:ietf:params:oauth:grant-type:device_code",
               request.device_code,
               sequence_clock([
                 DateTime.add(now, -1, :second),
                 DateTime.add(now, -1, :second),
                 now
               ])
             )

    assert error.error == "invalid_client"

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               request.verification_handle
             )

    assert stored.status == :approved
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "approved CIBA request is not consumed when app expires at final issuance" do
    now = future_now()
    {:ok, client} = poll_client("ciba-equality", "urn:openid:params:grant-type:ciba")
    set_deadline(client, to_usec(now))
    publish_signing_key("kid-ciba-equality")

    auth_req_id = "ciba-equality-#{System.unique_integer([:positive])}"

    request =
      CibaAuthorization.issue(
        %{auth_req_id: auth_req_id, client_id: client.client_id, scopes: ["email"]},
        now: now
      )

    assert {:ok, _} = Repository.put_ciba_authorization(request)

    assert {:ok, _} =
             Repository.transition_ciba_authorization(
               request.auth_req_id_hash,
               [:pending],
               %{status: :approved, subject_id: "subject-ciba", approved_at: now}
             )

    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, error} =
             poll_exchange(
               client,
               "urn:openid:params:grant-type:ciba",
               auth_req_id,
               sequence_clock([
                 DateTime.add(now, -1, :second),
                 DateTime.add(now, -1, :second),
                 now
               ])
             )

    assert error.error == "invalid_client"

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(request.auth_req_id_hash)

    assert stored.status == :approved
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "device and CIBA poll outputs use one app-capped expiry for signed and opaque access tokens" do
    for {grant_type, format} <-
          for(
            type <- [
              "urn:ietf:params:oauth:grant-type:device_code",
              "urn:openid:params:grant-type:ciba"
            ],
            format <- [:jwt, :opaque],
            do: {type, format}
          ) do
      now = future_now()
      deadline = DateTime.add(now, 15, :second) |> to_usec()
      id = "poll-#{format}-#{System.unique_integer([:positive])}"
      {:ok, client} = poll_client(id, grant_type, format)
      set_deadline(client, deadline)
      publish_signing_key("kid-#{id}")
      {raw_grant, request_hash, fetch_request} = approved_request(grant_type, client, now)

      assert {:ok, success} = poll_exchange(client, grant_type, raw_grant, fn -> now end)
      assert success.expires_in == 15

      assert {:ok, access} =
               Repository.fetch_lifecycle_token(Policy.hash_token(success.access_token))

      assert DateTime.compare(access.expires_at, deadline) == :eq
      assert {:ok, stored_request} = fetch_request.()
      assert stored_request.status == :consumed

      if format == :jwt do
        {_header, claims} = verify_at_jwt(success.access_token)
        assert claims["exp"] == DateTime.to_unix(deadline)
      else
        refute String.contains?(success.access_token, ".")
      end

      assert is_binary(request_hash)
    end
  end

  defp poll_client(id, grant_type, format \\ :jwt) do
    Repository.register_client(%Client{
      lifetime_version: 1,
      client_id: id,
      name: id,
      client_type: :public,
      token_endpoint_auth_method: :none,
      allowed_grant_types: [grant_type],
      allowed_scopes: ["email"],
      access_token_format: format,
      created_at: DateTime.utc_now()
    })
  end

  defp approved_request("urn:ietf:params:oauth:grant-type:device_code", client, now) do
    request = device_request(client, now)
    assert {:ok, _} = Repository.put_device_authorization(request)

    assert {:ok, _} =
             Repository.transition_device_authorization(
               request.verification_handle,
               [:pending],
               %{status: :approved, subject_id: "subject-#{client.client_id}", approved_at: now}
             )

    {request.device_code, request.device_code_hash,
     fn ->
       Repository.fetch_device_authorization_by_verification_handle(request.verification_handle)
     end}
  end

  defp approved_request("urn:openid:params:grant-type:ciba", client, now) do
    auth_req_id = "#{client.client_id}-auth-req"

    request =
      CibaAuthorization.issue(
        %{auth_req_id: auth_req_id, client_id: client.client_id, scopes: ["email"]},
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_ciba_authorization(request)

    assert {:ok, _} =
             Repository.transition_ciba_authorization(
               request.auth_req_id_hash,
               [:pending],
               %{status: :approved, subject_id: "subject-#{client.client_id}", approved_at: now}
             )

    {auth_req_id, request.auth_req_id_hash,
     fn -> Repository.fetch_ciba_authorization_by_auth_req_id_hash(request.auth_req_id_hash) end}
  end

  defp device_request(client, now) do
    DeviceAuthorization.issue(
      %{
        client_id: client.client_id,
        device_code: "device-#{System.unique_integer([:positive])}",
        user_code: "BCDFGH#{System.unique_integer([:positive])}",
        scopes: ["email"]
      },
      now: DateTime.add(now, -10, :second)
    )
  end

  defp poll_exchange(client, grant_type, raw_grant, clock) do
    param =
      if grant_type == "urn:openid:params:grant-type:ciba", do: "auth_req_id", else: "device_code"

    TokenExchange.exchange(%{
      params: %{"grant_type" => grant_type, "client_id" => client.client_id, param => raw_grant},
      opts: [
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
    })
  end

  defp set_deadline(client, deadline) do
    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )
  end

  defp future_now, do: DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)

  defp sequence_clock(values) do
    counter = :atomics.new(1, [])
    count = length(values)

    fn ->
      index = :atomics.add_get(counter, 1, 1) - 1
      Enum.at(values, min(index, count - 1))
    end
  end

  defp to_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
