defmodule Lockspire.Integration.AppLifetimeDeviceTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Protocol.DeviceAuthorization, as: DeviceAuthorizationProtocol
  alias Lockspire.Protocol.DeviceVerification
  alias Lockspire.Storage.Ecto.Repository

  @moduletag :integration
  @before ~U[2026-04-28 10:59:59Z]
  @deadline ~U[2026-04-28 11:00:00Z]
  @equal @deadline

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_expires_at: @deadline,
        client_id: "app-lifetime-device-#{System.unique_integer([:positive])}",
        name: "Living Room TV",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
        created_at: @before
      })

    %{client: client}
  end

  test "device creation that passes authentication but reaches the client lock at app expiry writes no request",
       %{
         client: client
       } do
    Process.put(:device_clock_calls, 0)

    clock = fn ->
      call = Process.get(:device_clock_calls)
      Process.put(:device_clock_calls, call + 1)
      if call == 0, do: @before, else: @equal
    end

    assert {:error, %{reason_code: :client_app_expired}} =
             authorize_device(client, clock)

    assert scalar("SELECT COUNT(*) FROM lockspire_device_authorizations WHERE client_id = $1", [
             client.client_id
           ]) == 0

    assert scalar("SELECT COUNT(*) FROM lockspire_tokens WHERE client_id = $1", [client.client_id]) ==
             0
  end

  test "verification approval rechecks a disabled app after client and request locks", %{
    client: client
  } do
    request = pending_request(client, @before)
    assert {:ok, _} = Repository.put_device_authorization(request)
    assert {:ok, _} = Repository.set_client_active(client, false, %{disabled_at: @before})

    assert {:error, :not_active} =
             DeviceVerification.approve_device_authorization(
               request.verification_handle,
               %{subject_id: "user-123"},
               now: @before
             )

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               request.verification_handle
             )

    assert stored.status == :pending
    assert audit_count("device_authorization_approved") == 0

    assert scalar("SELECT COUNT(*) FROM lockspire_tokens WHERE client_id = $1", [client.client_id]) ==
             0
  end

  test "verification lookup rejects a pending request when the app deadline is reached", %{
    client: client
  } do
    request = pending_request(client, @before)
    assert {:ok, _} = Repository.put_device_authorization(request)

    assert {:error, :expired} =
             DeviceVerification.lookup_pending_device_authorization(
               request.user_code,
               client_store: Repository,
               device_authorization_store: Repository,
               now: @equal
             )

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               request.verification_handle
             )

    assert stored.status == :pending
  end

  test "device approval at app deadline preserves pending state and writes no approval audit", %{
    client: client
  } do
    request = pending_request(client, @before)
    assert {:ok, _} = Repository.put_device_authorization(request)

    assert {:error, :expired} =
             DeviceVerification.approve_device_authorization(
               request.verification_handle,
               %{subject_id: "user-123"},
               now: @equal
             )

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               request.verification_handle
             )

    assert stored.status == :pending
    assert audit_count("device_authorization_approved") == 0
  end

  defp authorize_device(client, clock) do
    DeviceAuthorizationProtocol.authorize(%{
      params: %{"client_id" => client.client_id, "scope" => "openid"},
      opts: [
        client_store: Repository,
        device_authorization_store: Repository,
        now: clock
      ]
    })
  end

  defp pending_request(client, now) do
    DeviceAuthorization.issue(
      %{
        client_id: client.client_id,
        device_code: "device-#{System.unique_integer([:positive])}",
        user_code: "BCDFGHJK",
        scopes: ["openid"]
      },
      now: now
    )
  end

  defp audit_count(action) do
    scalar("SELECT COUNT(*) FROM lockspire_audit_events WHERE action = $1", [action])
  end

  defp scalar(sql, params) do
    %{rows: [[count]]} = Ecto.Adapters.SQL.query!(Lockspire.TestRepo, sql, params)
    count
  end
end
