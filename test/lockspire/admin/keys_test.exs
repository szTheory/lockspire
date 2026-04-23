defmodule Lockspire.Admin.KeysTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin.Keys
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = attach_events(self())

    now = DateTime.utc_now()

    {:ok, active_key} =
      Repository.publish_key(
        signing_key("kid-active", :active, now,
          published_at: now,
          activated_at: now
        )
      )

    {:ok, upcoming_key} =
      Repository.publish_key(signing_key("kid-upcoming", :upcoming, now))

    on_exit(fn -> :telemetry.detach(handler_id) end)

    %{active_key: active_key, upcoming_key: upcoming_key, now: now, handler_id: handler_id}
  end

  test "lists keys in operator lifecycle order and hides private key material" do
    assert {:ok, [active_entry, upcoming_entry]} = Keys.list_keys()

    assert active_entry.key.status == :active
    assert active_entry.publishable
    assert is_nil(active_entry.key.private_jwk_encrypted)

    assert upcoming_entry.key.status == :upcoming
    refute upcoming_entry.publishable
    assert upcoming_entry.next_actions == [:publish]
  end

  test "publish, activate, and retire enforce guided transitions", %{
    active_key: active_key,
    upcoming_key: upcoming_key,
    now: now
  } do
    active_key_id = active_key.id
    upcoming_key_id = upcoming_key.id

    assert {:ok, published_key} =
             Keys.publish_key(upcoming_key.id, %{
               published_at: DateTime.add(now, 10, :second),
               actor: %{type: :operator, id: "ops-publish", display: "Publish Admin"}
             })

    assert published_key.published
    assert published_key.publishable
    assert published_key.next_actions == [:activate]

    assert_received {:telemetry_event, [:lockspire, :key_published],
                     %{key_id: ^upcoming_key_id, actor_id: "ops-publish"}}

    assert %AuditEventRecord{} = published_audit = latest_audit!("key_published")
    assert published_audit.resource_id == Integer.to_string(upcoming_key_id)
    assert published_audit.actor_id == "ops-publish"

    assert {:error, :already_published} = Keys.publish_key(upcoming_key.id)

    assert {:ok, active_view} =
             Keys.activate_key(upcoming_key.id, %{
               activated_at: DateTime.add(now, 20, :second),
               actor: %{type: :operator, id: "ops-activate", display: "Activate Admin"}
             })

    assert active_view.key.status == :active
    assert active_view.next_actions == []

    assert_received {:telemetry_event, [:lockspire, :key_activated],
                     %{key_id: ^upcoming_key_id, actor_id: "ops-activate"}}

    assert %AuditEventRecord{} = activated_audit = latest_audit!("key_activated")
    assert activated_audit.resource_id == Integer.to_string(upcoming_key_id)
    assert activated_audit.actor_id == "ops-activate"

    assert {:ok, previous_active} = Keys.get_key(active_key.id)
    assert previous_active.key.status == :retiring
    assert previous_active.next_actions == [:retire]

    assert {:ok, retired_view} =
             Keys.retire_key(active_key.id, %{
               retired_at: DateTime.add(now, 30, :second),
               actor: %{type: :operator, id: "ops-retire", display: "Retire Admin"}
             })

    assert retired_view.key.status == :retired
    assert retired_view.next_actions == []
    assert {:error, :invalid_state} = Keys.activate_key(active_key.id)

    assert_received {:telemetry_event, [:lockspire, :key_retired],
                     %{key_id: ^active_key_id, actor_id: "ops-retire"}}

    assert %AuditEventRecord{} = retired_audit = latest_audit!("key_retired")
    assert retired_audit.resource_id == Integer.to_string(active_key_id)
    assert retired_audit.actor_id == "ops-retire"
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "admin-keys-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :key_published],
          [:lockspire, :audit, :key_published],
          [:lockspire, :key_activated],
          [:lockspire, :audit, :key_activated],
          [:lockspire, :key_retired],
          [:lockspire, :audit, :key_retired]
        ],
        &__MODULE__.handle_event/4,
        pid
      )

    handler_id
  end

  defp latest_audit!(action) do
    Lockspire.TestRepo.one!(
      from(audit in AuditEventRecord,
        where: audit.action == ^to_string(action),
        order_by: [desc: audit.id],
        limit: 1
      )
    )
  end

  defp signing_key(kid, status, now, attrs \\ []) do
    attrs = Enum.into(attrs, %{})

    %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => kid, "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: :erlang.term_to_binary(%{"kid" => kid}),
      status: status,
      inserted_at: now
    }
    |> Map.merge(attrs)
  end
end
