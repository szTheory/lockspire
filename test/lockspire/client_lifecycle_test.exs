defmodule Lockspire.ClientLifecycleTest do
  use Lockspire.DataCase, async: false

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.AuditEventRecord

  import Ecto.Query

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "DCR creation persists the client and its DCR audit attribution together" do
    client_id = "lifecycle-dcr-#{System.unique_integer([:positive])}"
    actor_id = "iat-#{client_id}"

    client = %Client{
      client_id: client_id,
      client_type: :public,
      redirect_uris: ["https://client.example.test/callback"],
      allowed_scopes: [],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    assert {:ok, persisted} =
             ClientLifecycle.create_dcr(%{
               client: client,
               actor: %{type: :dcr, id: actor_id}
             })

    assert persisted.client_id == client_id

    assert %AuditEventRecord{
             action: "dcr_client_created",
             actor_type: "dcr",
             actor_id: ^actor_id,
             resource_type: "client",
             resource_id: ^client_id,
             metadata: %{"client_id" => ^client_id, "provenance" => "operator"}
           } =
             Lockspire.TestRepo.one!(
               from(audit in AuditEventRecord,
                 where: audit.action == "dcr_client_created" and audit.resource_id == ^client_id
               )
             )
  end
end
