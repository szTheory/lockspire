defmodule Lockspire.Protocol.AuthorizationFlowTest do
  use ExUnit.Case, async: false

  alias Lockspire.Audit.Event
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias __MODULE__.Store

  setup do
    Application.put_env(:lockspire, :issuer, "https://issuer.test/lockspire")

    {:ok, pid} =
      Agent.start_link(fn ->
        %{
          audits: [],
          interactions: %{},
          consents: %{},
          tokens: %{}
        }
      end)

    Store.use_agent(pid)

    :telemetry.detach("authorization-flow-test-handler")

    events = start_supervised!({Agent, fn -> [] end})

    :telemetry.attach_many(
      "authorization-flow-test-handler",
      [
        [:lockspire, :consent, :approved],
        [:lockspire, :consent, :denied],
        [:lockspire, :authorization, :completed],
        [:lockspire, :audit, :consent, :approved],
        [:lockspire, :audit, :consent, :denied],
        [:lockspire, :audit, :authorization, :completed]
      ],
      fn event, _measurements, metadata, agent ->
        Agent.update(agent, fn current -> [{event, metadata} | current] end)
      end,
      events
    )

    on_exit(fn -> :telemetry.detach("authorization-flow-test-handler") end)

    %{events: events}
  end

  test "validated requests become login-required or consent-required interactions backed by durable state" do
    assert {:login_required, %Interaction{} = login_interaction} =
             AuthorizationFlow.start_authorization(validated_request(), nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-login" end
             )

    assert login_interaction.status == :pending_login
    assert login_interaction.login_required_at == fixed_now()

    assert {:ok, %Interaction{status: :pending_login}} =
             Store.fetch_active_interaction(login_interaction.interaction_id)

    assert {:consent_required, %Interaction{} = consent_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "state-2"),
               %{
                 subject_id: "subject_123"
               },
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-consent" end
             )

    assert consent_interaction.status == :pending_consent
    assert consent_interaction.account_id == "subject_123"
    assert consent_interaction.consent_requested_at == fixed_now()
  end

  test "validated requests persist max_age and auth_time_requested metadata on the interaction" do
    assert {:login_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(max_age: 120, auth_time_requested?: true),
               nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-auth-metadata" end
             )

    assert interaction.max_age == 120
    assert interaction.auth_time_requested == true

    assert {:ok, %Interaction{} = persisted} =
             Store.fetch_interaction("interaction-auth-metadata")

    assert persisted.max_age == 120
    assert persisted.auth_time_requested == true
    assert persisted.auth_time == nil
  end

  test "validated requests carry authorization_details into the persisted interaction" do
    details = [
      %{"type" => "payment_initiation", "actions" => ["initiate"]}
    ]

    assert {:login_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(authorization_details: details),
               nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-rar" end
             )

    assert interaction.authorization_details == details

    assert {:ok, %Interaction{} = persisted} =
             Store.fetch_interaction("interaction-rar")

    assert persisted.authorization_details == details
  end

  test "validated requests default authorization_details to [] when none are supplied" do
    assert {:login_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(),
               nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-no-rar" end
             )

    assert interaction.authorization_details == []
  end

  test "prompt=none with no subject returns redirect-safe login_required and never starts interactive login" do
    assert {:redirect_error, %Error{} = error} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["none"]),
               nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               interaction_id_generator: fn -> "interaction-prompt-none-login-required" end
             )

    assert error.error == "login_required"
    assert error.redirect_uri == "https://client.example.com/callback"
    assert error.state == "state-123"

    assert {:ok, nil} = Store.fetch_interaction("interaction-prompt-none-login-required")
  end

  test "prompt=none with stale auth_time under max_age returns redirect-safe login_required" do
    stale_auth_time = DateTime.add(fixed_now(), -600, :second)

    assert {:redirect_error, %Error{} = error} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["none"], max_age: 60),
               %{subject_id: "subject_123", auth_time: stale_auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    assert error.error == "login_required"
  end

  test "prompt=none with missing reusable consent returns redirect-safe consent_required" do
    auth_time = DateTime.add(fixed_now(), -30, :second)

    assert {:redirect_error, %Error{} = error} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["none"], max_age: 120),
               %{subject_id: "subject_123", auth_time: auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    assert error.error == "consent_required"
  end

  test "prompt=none maps non-interactive policy blockers to redirect-safe interaction_required" do
    auth_time = DateTime.add(fixed_now(), -30, :second)

    assert {:redirect_error, %Error{} = error} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["none"], max_age: 120),
               %{
                 subject_id: "subject_123",
                 auth_time: auth_time,
                 ui_required: :account_selection
               },
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    assert error.error == "interaction_required"
  end

  test "prompt=none succeeds without UI only when durable truthful state satisfies authentication freshness and consent" do
    auth_time = DateTime.add(fixed_now(), -30, :second)

    assert {:ok, _grant} =
             Store.grant_consent(%ConsentGrant{
               account_id: "subject_123",
               client_id: "client_123",
               scopes: ["email", "profile"],
               granted_at: fixed_now(),
               status: :active,
               kind: :remembered
             })

    assert {:consent_reused, redirect_uri} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["none"], max_age: 120),
               %{subject_id: "subject_123", auth_time: auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "silent-success-code" end
             )

    %{query: query} = parse_redirect(redirect_uri)
    assert query["code"] == "silent-success-code"
  end

  test "remembered consent is reused only for same-or-subset scopes unless prompt=consent forces the screen" do
    assert {:ok, _grant} =
             Store.grant_consent(%ConsentGrant{
               account_id: "subject_123",
               client_id: "client_123",
               scopes: ["email", "profile"],
               granted_at: fixed_now(),
               status: :active,
               kind: :remembered
             })

    assert {:consent_reused, redirect_uri} =
             AuthorizationFlow.start_authorization(
               validated_request(scopes: ["email"]),
               %{
                 subject_id: "subject_123"
               },
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "opaque-code-123" end,
               interaction_id_generator: fn -> "interaction-reused" end
             )

    %{query: reused_query} = parse_redirect(redirect_uri)
    assert reused_query["state"] == "state-123"
    assert reused_query["code"] == "opaque-code-123"

    [stored_code] = Store.stored_tokens()
    assert stored_code.token_hash != reused_query["code"]
    assert stored_code.token_type == :authorization_code
    assert DateTime.diff(stored_code.expires_at, fixed_now(), :second) == 300

    assert {:consent_required, %Interaction{} = forced_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["consent"], state: "forced-state"),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-forced" end
             )

    assert forced_interaction.status == :pending_consent

    assert {:consent_required, %Interaction{} = escalated_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(
                 scopes: ["email", "profile", "offline_access"],
                 state: "escalated"
               ),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-escalated" end
             )

    assert escalated_interaction.status == :pending_consent
  end

  test "consent reuse and silent reuse do not advance auth_time without a fresh end-user authentication event" do
    fresh_auth_time = DateTime.add(fixed_now(), -30, :second)
    reused_session_auth_time = DateTime.add(fixed_now(), -15, :second)

    assert {:ok, _grant} =
             Store.grant_consent(%ConsentGrant{
               account_id: "subject_123",
               client_id: "client_123",
               scopes: ["email", "profile"],
               granted_at: fixed_now(),
               status: :active,
               kind: :remembered
             })

    assert {:login_required, %Interaction{} = login_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(prompt: ["login"], max_age: 120),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-fresh-auth" end
             )

    assert {:consent_reused, _redirect_uri} =
             AuthorizationFlow.resume_interaction(
               login_interaction.interaction_id,
               %{subject_id: "subject_123", auth_time: fresh_auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "reuse-code" end
             )

    assert {:ok, %Interaction{} = resumed} =
             Store.fetch_interaction(login_interaction.interaction_id)

    assert DateTime.compare(resumed.auth_time, fresh_auth_time) == :eq

    assert {:consent_reused, _redirect_uri} =
             AuthorizationFlow.start_authorization(
               validated_request(max_age: 120, state: "silent-reuse"),
               %{subject_id: "subject_123", auth_time: reused_session_auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "reuse-code-2" end,
               interaction_id_generator: fn -> "interaction-silent-reuse" end
             )

    assert {:ok, %Interaction{} = silent_reuse} =
             Store.fetch_interaction("interaction-silent-reuse")

    assert DateTime.compare(silent_reuse.auth_time, reused_session_auth_time) == :eq
    refute DateTime.compare(silent_reuse.auth_time, fixed_now()) == :eq
  end

  test "interactive max_age requests move to pending_login when auth_time is missing or stale" do
    stale_auth_time = DateTime.add(fixed_now(), -600, :second)

    assert {:login_required, %Interaction{} = missing_auth_time} =
             AuthorizationFlow.start_authorization(
               validated_request(max_age: 60, state: "missing-auth-time"),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-missing-auth-time" end
             )

    assert missing_auth_time.status == :pending_login
    assert missing_auth_time.account_id == nil

    assert {:login_required, %Interaction{} = stale_auth_time_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(max_age: 60, state: "stale-auth-time"),
               %{subject_id: "subject_123", auth_time: stale_auth_time},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-stale-auth-time" end
             )

    assert stale_auth_time_interaction.status == :pending_login
    assert stale_auth_time_interaction.account_id == nil
  end

  test "resuming a pending_login interaction stores subject_context auth_time as durable protocol-owned auth_time" do
    auth_time = DateTime.add(fixed_now(), -45, :second)

    assert {:login_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(max_age: 120, auth_time_requested?: true),
               nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-resume-auth-time" end
             )

    assert {:consent_required, %Interaction{} = resumed} =
             AuthorizationFlow.resume_interaction(
               interaction.interaction_id,
               %{"auth_time" => auth_time, subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    assert resumed.status == :pending_consent
    assert DateTime.compare(resumed.auth_time, auth_time) == :eq
    assert resumed.max_age == 120
    assert resumed.auth_time_requested == true
  end

  test "approval issues hashed authorization codes, denial redirects safely, and expired or duplicate finalization fails" do
    assert {:consent_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-123" end,
               interaction_id_generator: fn -> "interaction-approve" end
             )

    assert {:approved, approved_redirect} =
             AuthorizationFlow.approve_interaction(
               interaction.interaction_id,
               %{subject_id: "subject_123"},
               remember: true,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-123" end
             )

    %{query: approved_query} = parse_redirect(approved_redirect)
    assert approved_query["state"] == "state-123"
    assert approved_query["code"] == "approval-code-123"
    assert approved_query["iss"] == "https://issuer.test/lockspire"

    [stored_code] =
      Store.stored_tokens()
      |> Enum.filter(&(&1.token_type == :authorization_code))

    assert stored_code.token_hash != approved_query["code"]
    assert is_nil(stored_code.redeemed_at)
    assert DateTime.diff(stored_code.expires_at, fixed_now(), :second) == 300

    [remembered_grant] =
      Store.stored_consents()
      |> Enum.filter(&(&1.kind == :remembered))

    assert remembered_grant.scopes == ["email", "profile"]

    assert {:error, :interaction_not_active} =
             AuthorizationFlow.approve_interaction(
               interaction.interaction_id,
               %{subject_id: "subject_123"},
               remember: true,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-456" end
             )

    assert {:consent_required, %Interaction{} = denied_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "deny-state", prompt: ["consent"]),
               %{
                 subject_id: "subject_123"
               },
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-denied" end
             )

    assert {:denied, denied_redirect} =
             AuthorizationFlow.deny_interaction(
               denied_interaction.interaction_id,
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    %{query: denied_query} = parse_redirect(denied_redirect)
    assert denied_query["error"] == "access_denied"
    assert denied_query["state"] == "deny-state"
    assert denied_query["iss"] == "https://issuer.test/lockspire"

    assert {:consent_required, %Interaction{} = expired_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "expired-state", prompt: ["consent"]),
               %{
                 subject_id: "subject_123"
               },
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-expired" end
             )

    Store.force_expire(expired_interaction.interaction_id)

    assert {:error, :interaction_expired} =
             AuthorizationFlow.approve_interaction(
               expired_interaction.interaction_id,
               %{subject_id: "subject_123"},
               remember: false,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-789" end
             )
  end

  test "approval, denial, and reused completion append audit events with actor attribution and reason codes",
       %{events: events} do
    assert {:ok, _grant} =
             Store.grant_consent(%ConsentGrant{
               account_id: "subject_123",
               client_id: "client_123",
               scopes: ["email", "profile"],
               granted_at: fixed_now(),
               status: :active,
               kind: :remembered
             })

    assert {:consent_reused, _redirect_uri} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "reused-state"),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "reused-code-123" end,
               interaction_id_generator: fn -> "interaction-reused-audit" end
             )

    assert {:consent_required, %Interaction{} = approved_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "approval-state", prompt: ["consent"]),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-audit-code" end,
               interaction_id_generator: fn -> "interaction-approval-audit" end
             )

    assert {:approved, _redirect_uri} =
             AuthorizationFlow.approve_interaction(
               approved_interaction.interaction_id,
               %{subject_id: "subject_123"},
               remember: true,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-audit-code" end
             )

    assert {:consent_required, %Interaction{} = denied_interaction} =
             AuthorizationFlow.start_authorization(
               validated_request(state: "deny-audit-state", prompt: ["consent"]),
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-deny-audit" end
             )

    assert {:denied, _redirect_uri} =
             AuthorizationFlow.deny_interaction(
               denied_interaction.interaction_id,
               %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    audits = Store.stored_audits()

    assert %Event{
             action: "authorization_completed",
             outcome: "succeeded",
             reason_code: "consent_reused",
             actor_type: "system",
             actor_id: "lockspire",
             resource_type: "interaction",
             resource_id: "interaction-reused-audit"
           } = Enum.find(audits, &(&1.resource_id == "interaction-reused-audit"))

    assert %Event{
             action: "consent_approved",
             outcome: "succeeded",
             reason_code: "consent_approved",
             actor_type: "subject",
             actor_id: "subject_123",
             resource_type: "interaction",
             resource_id: "interaction-approval-audit"
           } = Enum.find(audits, &(&1.action == "consent_approved"))

    assert %Event{
             action: "authorization_completed",
             outcome: "succeeded",
             reason_code: "consent_approved",
             actor_type: "subject",
             actor_id: "subject_123",
             resource_type: "interaction",
             resource_id: "interaction-approval-audit"
           } =
             Enum.find(
               audits,
               &(&1.action == "authorization_completed" and
                   &1.resource_id == "interaction-approval-audit")
             )

    assert %Event{
             action: "consent_denied",
             outcome: "denied",
             reason_code: "access_denied",
             actor_type: "subject",
             actor_id: "subject_123",
             resource_type: "interaction",
             resource_id: "interaction-deny-audit"
           } = Enum.find(audits, &(&1.action == "consent_denied"))

    recorded = recorded_events(events)

    assert {[:lockspire, :consent, :approved], %{reason_code: :consent_approved}} =
             Enum.find(recorded, fn {event, _metadata} ->
               event == [:lockspire, :consent, :approved]
             end)

    assert {[:lockspire, :consent, :denied], %{reason_code: :access_denied}} =
             Enum.find(recorded, fn {event, _metadata} ->
               event == [:lockspire, :consent, :denied]
             end)

    assert {[:lockspire, :authorization, :completed], %{reason_code: :consent_reused}} =
             Enum.find(recorded, fn {event, metadata} ->
               event == [:lockspire, :authorization, :completed] and
                 metadata[:reason_code] == :consent_reused
             end)
  end

  test "sid is generated at interaction creation time and is non-nil" do
    assert {:login_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(validated_request(), nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-sid-test" end
             )

    assert is_binary(interaction.sid)
    assert byte_size(interaction.sid) > 0
  end

  test "each interaction gets a unique sid" do
    assert {:login_required, %Interaction{} = interaction_a} =
             AuthorizationFlow.start_authorization(validated_request(), nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-sid-a" end
             )

    assert {:login_required, %Interaction{} = interaction_b} =
             AuthorizationFlow.start_authorization(validated_request(state: "state-2"), nil,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "unused-code" end,
               interaction_id_generator: fn -> "interaction-sid-b" end
             )

    refute interaction_a.sid == interaction_b.sid
  end

  defp validated_request(overrides \\ []) do
    defaults = %{
      client_id: "client_123",
      client: %Lockspire.Domain.Client{
        client_id: "client_123",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "offline_access"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        client_type: :public,
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        metadata: %{}
      },
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      prompt: [],
      state: "state-123",
      max_age: nil,
      auth_time_requested?: false,
      code_challenge: "challenge-123",
      code_challenge_method: :S256
    }

    struct!(Validated, Enum.into(overrides, defaults))
  end

  defp parse_redirect(uri) do
    parsed = URI.parse(uri)
    %{uri: parsed, query: URI.decode_query(parsed.query || "")}
  end

  defp fixed_now, do: ~U[2026-04-23 02:02:00Z]

  defp recorded_events(agent) do
    agent
    |> Agent.get(&Enum.reverse(&1))
    |> Enum.map(fn {event, metadata} -> {event, Map.take(metadata, [:reason_code])} end)
  end

  defmodule Store do
    alias Lockspire.Audit.Event
    alias Lockspire.Domain.ConsentGrant
    alias Lockspire.Domain.Interaction
    alias Lockspire.Domain.Token

    def use_agent(pid), do: Process.put({__MODULE__, :pid}, pid)

    def put_interaction(%Interaction{} = interaction) do
      stored =
        interaction
        |> ensure_interaction_timestamps()
        |> then(&Map.put(&1, :id, &1.id || next_id()))

      update(fn state ->
        put_in(state, [:interactions, stored.interaction_id], stored)
      end)

      {:ok, stored}
    end

    def fetch_interaction(interaction_id) do
      {:ok, get_in_state([:interactions, interaction_id])}
    end

    def fetch_active_interaction(interaction_id) do
      interaction = get_in_state([:interactions, interaction_id])

      active? =
        match?(%Interaction{}, interaction) and
          interaction.status in [:pending_login, :pending_consent] and
          DateTime.compare(interaction.expires_at, fixed_now()) == :gt

      {:ok, if(active?, do: interaction, else: nil)}
    end

    def transition_interaction(interaction_id, expected_statuses, attrs) do
      case get_in_state([:interactions, interaction_id]) do
        %Interaction{} = interaction ->
          if interaction.status in expected_statuses do
            updated =
              interaction
              |> Map.merge(attrs)
              |> Map.put(:updated_at, attrs[:updated_at] || fixed_now())

            update(fn state ->
              put_in(state, [:interactions, interaction_id], updated)
            end)

            {:ok, updated}
          else
            {:error, :invalid_state}
          end

        nil ->
          {:error, :not_found}
      end
    end

    def transact(fun) do
      case fun.() do
        {:error, reason} -> {:error, reason}
        result -> {:ok, result}
      end
    end

    def append_audit_event(attrs) when is_map(attrs) do
      event = Event.normalize(attrs)

      update(fn state ->
        update_in(state.audits, &[event | &1])
      end)

      {:ok, event}
    end

    def grant_consent(%ConsentGrant{} = grant) do
      stored = %{
        grant
        | id: grant.id || next_id(),
          inserted_at: fixed_now(),
          updated_at: fixed_now()
      }

      update(fn state ->
        consents = Map.put(state.consents, stored.id, stored)
        %{state | consents: consents}
      end)

      {:ok, stored}
    end

    def list_consents_for_account(account_id) do
      {:ok,
       stored_consents()
       |> Enum.filter(&(&1.account_id == account_id))
       |> Enum.sort_by(& &1.id)}
    end

    def list_reusable_consents(account_id, client_id) do
      {:ok,
       stored_consents()
       |> Enum.filter(fn grant ->
         grant.account_id == account_id and grant.client_id == client_id and
           grant.kind == :remembered and
           grant.status == :active and is_nil(grant.revoked_at)
       end)}
    end

    def revoke_consent_grant(grant_id, attrs) do
      case get_in_state([:consents, grant_id]) do
        %ConsentGrant{} = grant ->
          updated =
            grant
            |> Map.merge(Map.new(attrs))
            |> Map.put(:status, :revoked)
            |> Map.put(:updated_at, fixed_now())

          update(fn state ->
            consents = Map.put(state.consents, grant_id, updated)
            %{state | consents: consents}
          end)

          {:ok, updated}

        nil ->
          {:error, :not_found}
      end
    end

    def store_token(%Token{} = token) do
      stored = %{
        token
        | id: token.id || next_id(),
          inserted_at: fixed_now(),
          updated_at: fixed_now()
      }

      update(fn state ->
        tokens = Map.put(state.tokens, stored.token_hash, stored)
        %{state | tokens: tokens}
      end)

      {:ok, stored}
    end

    def revoke_token_family(_family_id), do: {:ok, 0}

    def fetch_authorization_code(token_hash), do: {:ok, get_in_state([:tokens, token_hash])}

    def fetch_refresh_token(token_hash), do: {:ok, get_in_state([:tokens, token_hash])}

    def fetch_active_authorization_code(token_hash) do
      case get_in_state([:tokens, token_hash]) do
        %Token{token_type: :authorization_code, redeemed_at: nil, revoked_at: nil} = token ->
          {:ok, token}

        _other ->
          {:ok, nil}
      end
    end

    def mark_authorization_code_redeemed(token_hash, redeemed_at) do
      case get_in_state([:tokens, token_hash]) do
        %Token{redeemed_at: nil} = token ->
          updated = %{token | redeemed_at: redeemed_at, updated_at: fixed_now()}

          update(fn state ->
            tokens = Map.put(state.tokens, token_hash, updated)
            %{state | tokens: tokens}
          end)

          {:ok, updated}

        %Token{} ->
          {:error, :already_redeemed}

        nil ->
          {:error, :not_found}
      end
    end

    def fetch_active_access_token(token_hash) do
      case get_in_state([:tokens, token_hash]) do
        %Token{token_type: :access_token, revoked_at: nil} = token ->
          {:ok, token}

        _other ->
          {:ok, nil}
      end
    end

    def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token) do
      with {:ok, %Token{} = authorization_code} <-
             mark_authorization_code_redeemed(token_hash, redeemed_at),
           {:ok, %Token{} = stored_access_token} <- store_token(access_token) do
        {:ok, %{authorization_code: authorization_code, access_token: stored_access_token}}
      end
    end

    def rotate_refresh_token(_token_hash, _client_id, _rotated_at, _refresh_token, _access_token) do
      {:error, :not_implemented}
    end

    def stored_tokens, do: stored_values(:tokens)
    def stored_consents, do: stored_values(:consents)
    def stored_audits, do: stored_values(:audits)

    def force_expire(interaction_id) do
      update(fn state ->
        update_in(state, [:interactions, interaction_id], fn
          nil ->
            nil

          interaction ->
            %{
              interaction
              | status: :expired,
                expired_at: fixed_now(),
                expires_at: DateTime.add(fixed_now(), -1, :second)
            }
        end)
      end)
    end

    defp ensure_interaction_timestamps(interaction) do
      %{
        interaction
        | inserted_at: interaction.inserted_at || fixed_now(),
          updated_at: fixed_now()
      }
    end

    defp stored_values(key) do
      pid()
      |> Agent.get(fn state ->
        case state[key] do
          values when is_map(values) -> values |> Map.values() |> Enum.sort_by(& &1.id)
          values when is_list(values) -> Enum.reverse(values)
        end
      end)
    end

    defp get_in_state(path) do
      Agent.get(pid(), &get_in(&1, path))
    end

    defp update(fun) do
      Agent.update(pid(), fun)
    end

    defp next_id do
      System.unique_integer([:positive])
    end

    defp pid do
      Process.get({__MODULE__, :pid}) || raise "missing store agent pid"
    end

    defp fixed_now, do: ~U[2026-04-23 02:02:00Z]
  end
end
