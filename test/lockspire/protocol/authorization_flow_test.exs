defmodule Lockspire.Protocol.AuthorizationFlowTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.AuthorizationFlow
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias __MODULE__.Store

  setup do
    {:ok, pid} =
      Agent.start_link(fn ->
        %{
          interactions: %{},
          consents: %{},
          tokens: %{}
        }
      end)

    Store.use_agent(pid)
    :ok
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
             AuthorizationFlow.start_authorization(validated_request(state: "state-2"), %{
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
             AuthorizationFlow.start_authorization(validated_request(scopes: ["email"]), %{
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
               validated_request(scopes: ["email", "profile", "offline_access"], state: "escalated"),
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

  test "approval issues hashed authorization codes, denial redirects safely, and expired or duplicate finalization fails" do
    assert {:consent_required, %Interaction{} = interaction} =
             AuthorizationFlow.start_authorization(validated_request(), %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-123" end,
               interaction_id_generator: fn -> "interaction-approve" end
             )

    assert {:approved, approved_redirect} =
             AuthorizationFlow.approve_interaction(interaction.interaction_id, %{subject_id: "subject_123"},
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

    [remembered_grant] =
      Store.stored_consents()
      |> Enum.filter(&(&1.kind == :remembered))

    assert remembered_grant.scopes == ["email", "profile"]

    assert {:error, :interaction_not_active} =
             AuthorizationFlow.approve_interaction(interaction.interaction_id, %{subject_id: "subject_123"},
               remember: true,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-456" end
             )

    assert {:consent_required, %Interaction{} = denied_interaction} =
             AuthorizationFlow.start_authorization(validated_request(state: "deny-state"), %{
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
             AuthorizationFlow.deny_interaction(denied_interaction.interaction_id, %{subject_id: "subject_123"},
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0
             )

    %{query: denied_query} = parse_redirect(denied_redirect)
    assert denied_query["error"] == "access_denied"
    assert denied_query["state"] == "deny-state"

    assert {:consent_required, %Interaction{} = expired_interaction} =
             AuthorizationFlow.start_authorization(validated_request(state: "expired-state"), %{
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
             AuthorizationFlow.approve_interaction(expired_interaction.interaction_id, %{subject_id: "subject_123"},
               remember: false,
               interaction_store: Store,
               consent_store: Store,
               token_store: Store,
               now: &fixed_now/0,
               code_generator: fn -> "approval-code-789" end
             )
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

  defmodule Store do
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

    def grant_consent(%ConsentGrant{} = grant) do
      stored = %{grant | id: grant.id || next_id(), inserted_at: fixed_now(), updated_at: fixed_now()}

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
         grant.account_id == account_id and grant.client_id == client_id and grant.kind == :remembered and
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
      stored = %{token | id: token.id || next_id(), inserted_at: fixed_now(), updated_at: fixed_now()}

      update(fn state ->
        tokens = Map.put(state.tokens, stored.token_hash, stored)
        %{state | tokens: tokens}
      end)

      {:ok, stored}
    end

    def revoke_token_family(_family_id), do: {:ok, 0}

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

    def stored_tokens, do: stored_values(:tokens)
    def stored_consents, do: stored_values(:consents)

    def force_expire(interaction_id) do
      update(fn state ->
        update_in(state, [:interactions, interaction_id], fn
          nil -> nil
          interaction -> %{interaction | status: :expired, expired_at: fixed_now(), expires_at: DateTime.add(fixed_now(), -1, :second)}
        end)
      end)
    end

    defp ensure_interaction_timestamps(interaction) do
      %{interaction | inserted_at: interaction.inserted_at || fixed_now(), updated_at: fixed_now()}
    end

    defp stored_values(key) do
      pid()
      |> Agent.get(fn state -> state[key] |> Map.values() |> Enum.sort_by(& &1.id) end)
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
