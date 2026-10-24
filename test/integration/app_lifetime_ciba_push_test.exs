defmodule Lockspire.Integration.AppLifetimeCibaPushTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Workers.CibaNotificationWorker

  @moduletag :integration

  setup context do
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)
    :ok
  end

  test "queued push reloads current app state and refuses app equality before delivery" do
    now = future_now()
    {:ok, client} = push_client("push-expired")
    publish_signing_key("kid-push-expired")
    set_deadline(client, to_usec(now))
    auth = approved_push(client, now)
    Application.put_env(:lockspire, :ciba_notification_now, fn -> now end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, __MODULE__},
      retry: false
    )

    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, {:token_issuance_failed, %TokenExchange.Error{error: "invalid_client"}}} =
             CibaNotificationWorker.perform(%Oban.Job{
               args: %{"ciba_authorization_id" => auth.id}
             })

    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(auth.auth_req_id_hash)

    assert stored.status == :approved
  end

  test "push uses the unified app cap and delivery runs after issuance transaction" do
    now = future_now()
    {:ok, client} = push_client("push-capped")
    publish_signing_key("kid-push-capped")
    deadline = DateTime.add(now, 20, :second) |> to_usec()
    set_deadline(client, deadline)
    auth = approved_push(client, now)
    Application.put_env(:lockspire, :ciba_notification_now, fn -> now end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, __MODULE__},
      retry: false
    )

    Req.Test.expect(__MODULE__, fn req ->
      body = req.body_params
      assert body["expires_in"] == 20
      assert Plug.Conn.get_req_header(req, "authorization") == ["Bearer notification-token"]

      {:ok, access} =
        Repository.fetch_lifecycle_token(
          Lockspire.Security.Policy.hash_token(body["access_token"])
        )

      assert DateTime.compare(access.expires_at, deadline) == :eq
      {_header, claims} = verify_at_jwt(body["access_token"])
      assert claims["exp"] == DateTime.to_unix(deadline)

      Req.Test.json(req, %{status: "ok"})
    end)

    assert :ok =
             CibaNotificationWorker.perform(%Oban.Job{
               args: %{"ciba_authorization_id" => auth.id}
             })

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(auth.auth_req_id_hash)

    assert stored.status == :consumed
  end

  test "queued push remains eligible after its shared secret expires" do
    now = future_now()
    {:ok, client} = push_client("push-secret-expired")

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [
                 lifetime_version: 1,
                 client_secret_expires_at: DateTime.add(now, -1, :second)
               ]
             )

    publish_signing_key("kid-push-secret-expired")
    auth = approved_push(client, now)
    Application.put_env(:lockspire, :ciba_notification_now, fn -> now end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, __MODULE__},
      retry: false
    )

    Req.Test.expect(__MODULE__, fn req -> Req.Test.json(req, %{status: "ok"}) end)

    assert :ok =
             CibaNotificationWorker.perform(%Oban.Job{
               args: %{"ciba_authorization_id" => auth.id}
             })

    assert {:ok, stored} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(auth.auth_req_id_hash)

    assert stored.status == :consumed
  end

  defp push_client(id) do
    Repository.register_client(%Client{
      lifetime_version: 1,
      client_id: id,
      client_secret_hash: client_secret_hash("push-secret"),
      client_type: :confidential,
      name: id,
      allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
      allowed_scopes: ["email"],
      token_endpoint_auth_method: :client_secret_basic,
      backchannel_token_delivery_mode: :push,
      backchannel_client_notification_endpoint: "https://rp.example.test/push",
      access_token_format: :jwt,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp approved_push(client, now) do
    auth_req_id = "#{client.client_id}-#{System.unique_integer([:positive])}"

    authorization =
      CibaAuthorization.issue(
        %{
          auth_req_id: auth_req_id,
          client_id: client.client_id,
          scopes: ["email"],
          delivery_mode: :push,
          client_notification_endpoint: "https://rp.example.test/push",
          client_notification_token_encrypted: "notification-token"
        },
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_ciba_authorization(authorization)

    assert {:ok, approved} =
             Repository.transition_ciba_authorization(
               authorization.auth_req_id_hash,
               [:pending],
               %{status: :approved, subject_id: "subject-#{client.client_id}", approved_at: now}
             )

    approved
  end

  defp set_deadline(client, deadline) do
    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client.client_id),
               set: [lifetime_version: 1, client_expires_at: deadline]
             )
  end

  defp future_now, do: DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)

  defp to_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
