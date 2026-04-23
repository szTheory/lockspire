defmodule Lockspire.Audit.AuditWriterTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Audit.Event
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Validated

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "normalizes actor identity and compacts metadata for durable audit events" do
    event =
      Event.normalize(%{
        action: :token_family_revoked,
        outcome: :succeeded,
        reason_code: :reuse_detected,
        actor: %{
          type: :operator,
          id: "ops_123",
          display: "Ops User"
        },
        resource: %{
          type: :token_family,
          id: "family_456"
        },
        metadata: %{
          "tenant_id" => "tenant_789",
          "count" => 2,
          "empty_map" => %{},
          "empty_list" => [],
          "nil_value" => nil
        }
      })

    assert %Event{} = event
    assert event.actor_type == "operator"
    assert event.actor_id == "ops_123"
    assert event.actor_display == "Ops User"
    assert event.resource_type == "token_family"
    assert event.resource_id == "family_456"
    assert event.action == "token_family_revoked"
    assert event.outcome == "succeeded"
    assert event.reason_code == "reuse_detected"
    assert event.metadata == %{"count" => 2, "tenant_id" => "tenant_789"}
  end

  test "stores action, outcome, reason, resource refs, and compact metadata without snapshots" do
    event =
      Event.normalize(%{
        action: "client_disabled",
        outcome: :succeeded,
        reason_code: "operator_request",
        actor: %{type: :system, id: "scheduler", display: "Scheduler"},
        resource: %{type: :client, id: "client_123"},
        metadata: %{
          changed_fields: ["active", "disabled_at"],
          before: nil,
          after: %{}
        }
      })

    assert {:ok, record} =
             %AuditEventRecord{}
             |> AuditEventRecord.changeset(event)
             |> Lockspire.TestRepo.insert()

    assert record.action == "client_disabled"
    assert record.outcome == "succeeded"
    assert record.reason_code == "operator_request"
    assert record.actor_type == "system"
    assert record.actor_id == "scheduler"
    assert record.actor_display == "Scheduler"
    assert record.resource_type == "client"
    assert record.resource_id == "client_123"
    assert record.metadata == %{"changed_fields" => ["active", "disabled_at"]}

    refute Map.has_key?(record.metadata, "before")
    refute Map.has_key?(record.metadata, "after")
    refute Map.has_key?(record, :snapshot)
    refute Map.has_key?(record, :before_state)
    refute Map.has_key?(record, :after_state)
  end

  test "normalizes timestamp metadata without treating structs as nested maps" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    event =
      Event.normalize(%{
        action: :client_secret_rotated,
        outcome: :succeeded,
        actor: %{type: :operator, id: "ops-123"},
        resource: %{type: :client, id: "client-123"},
        metadata: %{
          rotated_at: now,
          disabled_at: nil
        }
      })

    assert event.metadata == %{"rotated_at" => DateTime.to_iso8601(now)}
  end

  test "repository transaction wrapper commits the durable mutation and audit row together" do
    client = %Client{
      client_id: "client_with_audit",
      client_secret_hash: "argon2id$hash",
      client_type: :confidential,
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }

    audit_event = %{
      action: :client_created,
      outcome: :succeeded,
      actor: %{type: :operator, id: "ops_123", display: "Ops User"},
      resource: %{type: :client, id: client.client_id},
      metadata: %{channel: "test"}
    }

    assert {:ok, %ClientRecord{} = record} =
             Repository.transact_with_audit(audit_event, fn ->
               %ClientRecord{}
               |> ClientRecord.changeset(client)
               |> Lockspire.TestRepo.insert()
             end)

    assert record.client_id == client.client_id

    assert [%AuditEventRecord{} = stored_audit] = Lockspire.TestRepo.all(AuditEventRecord)
    assert stored_audit.action == "client_created"
    assert stored_audit.resource_id == client.client_id
  end

  test "authorization flow persists approval and denial audit rows through the repository boundary" do
    now = DateTime.utc_now()
    {:ok, client} = register_client("audit-flow-client", now)

    assert {:consent_required, %Interaction{} = approved_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(client, state: "approval-state"),
               %{subject_id: "subject-123"},
               interaction_store: Repository,
               consent_store: Repository,
               token_store: Repository,
               now: fn -> now end,
               code_generator: fn -> "approval-code" end,
               interaction_id_generator: fn -> "interaction-approval" end
             )

    assert {:approved, _redirect_uri} =
             AuthorizationFlow.approve_interaction(
               approved_interaction.interaction_id,
               %{subject_id: "subject-123"},
               remember: true,
                interaction_store: Repository,
                consent_store: Repository,
                token_store: Repository,
                now: fn -> now end,
                code_generator: fn -> "approval-code" end
             )

    assert {:consent_required, %Interaction{} = denied_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(client, state: "deny-state", prompt: ["consent"]),
               %{subject_id: "subject-123"},
               interaction_store: Repository,
               consent_store: Repository,
               token_store: Repository,
               now: fn -> now end,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-denied" end
             )

    assert {:denied, _redirect_uri} =
             AuthorizationFlow.deny_interaction(
               denied_interaction.interaction_id,
               %{subject_id: "subject-123"},
                interaction_store: Repository,
                consent_store: Repository,
                token_store: Repository,
                now: fn -> now end
             )

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.sort_by(&{&1.resource_id, &1.action})

    assert Enum.any?(audits, fn audit ->
             audit.action == "consent_approved" and
               audit.resource_id == "interaction-approval" and
               audit.actor_type == "subject" and
               audit.actor_id == "subject-123" and
               audit.reason_code == "consent_approved"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "authorization_completed" and
               audit.resource_id == "interaction-approval" and
               audit.actor_type == "subject" and
               audit.actor_id == "subject-123" and
               audit.reason_code == "consent_approved"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "consent_denied" and
               audit.resource_id == "interaction-denied" and
               audit.actor_type == "subject" and
               audit.actor_id == "subject-123" and
               audit.reason_code == "access_denied"
           end)
  end

  test "token exchange persists redemption and replay audit rows through the repository boundary" do
    now = DateTime.utc_now()
    {:ok, client} = register_client("audit-token-client", now, :client_secret_basic)

    {:ok, authorization_code} =
      seed_authorization_code(client, "audit-code", "audit-verifier", now)

    request = %{
      params: %{
        "grant_type" => "authorization_code",
        "code" => "audit-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "audit-verifier"
      },
      authorization: basic_auth(client.client_id, "secret"),
      opts: [
        client_store: Repository,
        token_store: Repository,
        interaction_store: Repository
      ]
    }

    assert {:ok, _success} = TokenExchange.exchange_authorization_code(request)
    assert {:error, replay_error} = TokenExchange.exchange_authorization_code(request)
    assert replay_error.reason_code == :authorization_code_replayed

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.filter(&(&1.resource_id == Integer.to_string(authorization_code.id)))

    assert Enum.any?(audits, &(&1.action == "authorization_code_redeemed"))
    assert Enum.any?(audits, &(&1.action == "authorization_code_replay_detected"))
  end

  test "refresh reuse and revocation persist audit rows through the repository boundary" do
    now = DateTime.utc_now()
    {:ok, client} = register_client("audit-refresh-client", now, :client_secret_basic)

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("audit-refresh-token"),
        token_type: :refresh_token,
        family_id: "family-audit-refresh",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-123",
        interaction_id: "interaction-audit-refresh",
        scopes: ["email", "offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    assert {:ok, _success} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "audit-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "audit-refresh-access" end,
                 refresh_token_generator: fn -> "audit-refresh-child" end,
                 now: fn -> now end
               ]
             })

    assert {:error, reuse_error} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "audit-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "audit-refresh-access-2" end,
                 refresh_token_generator: fn -> "audit-refresh-child-2" end,
                 now: fn -> now end
               ]
             })

    assert reuse_error.reason_code == :refresh_token_reuse_detected

    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "audit-refresh-child"},
               authorization: basic_auth(client.client_id, "secret"),
               opts: [client_store: Repository, token_store: Repository]
             })

    audits = Lockspire.TestRepo.all(AuditEventRecord)

    assert Enum.any?(audits, &(&1.action == "refresh_token_reuse_detected"))
    assert Enum.any?(audits, &(&1.action == "token_family_revoked"))
    assert Enum.any?(audits, &(&1.action == "token_revoked"))
    assert Enum.any?(audits, &(&1.resource_id == Integer.to_string(refresh_token.id)))
  end

  defp register_client(client_id, now, auth_method \\ :none) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: if(auth_method == :none, do: "argon2id$hash", else: client_secret_hash("secret")),
      client_type: if(auth_method == :none, do: :public, else: :confidential),
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["email", "profile", "offline_access"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: auth_method,
      pkce_required: true,
      subject_type: :public,
      created_at: now,
      metadata: %{}
    })
  end

  defp validated_request(client, overrides) do
    defaults = %{
      client_id: client.client_id,
      client: client,
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      prompt: ["consent"],
      state: "state-123",
      code_challenge: "challenge-123",
      code_challenge_method: :S256
    }

    struct!(Validated, Enum.into(overrides, defaults))
  end

  defp seed_authorization_code(client, raw_code, verifier, now) do
    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: "interaction-#{raw_code}",
        client_id: client.client_id,
        account_id: "subject-123",
        scopes_requested: ["email", "profile"],
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-123",
        code_challenge: code_challenge(verifier),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: "interaction-#{raw_code}",
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    })
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  defp client_secret_hash(secret) do
    salt = "static-salt"
    hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
    "sha256:#{salt}:#{hash}"
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end
end
