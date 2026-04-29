defmodule Lockspire.Protocol.AuthorizationFlow do
  @moduledoc """
  Orchestrates durable authorization interactions, consent decisions, and code issuance.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Protocol.ConsentPolicy
  alias Lockspire.Security.Policy

  @authorization_code_ttl 300

  @spec start_authorization(Validated.t(), map() | nil, keyword()) ::
          {:login_required, Interaction.t()}
          | {:consent_required, Interaction.t()}
          | {:consent_reused, String.t()}
          | {:redirect_error, Error.t()}
          | {:error, term()}
  def start_authorization(%Validated{} = validated, subject_context, opts \\ []) do
    now = now(opts)
    interaction_id = generate_interaction_id(opts)

    cond do
      silent_prompt?(validated.prompt) ->
        start_silent_authorization(validated, subject_context, interaction_id, now, opts)

      login_required?(validated, subject_context, now) ->
        validated
        |> build_interaction(interaction_id, nil, :pending_login, now)
        |> persist_login_required(opts)

      true ->
        start_subject_authorization(validated, subject_context, interaction_id, now, opts)
    end
  end

  @spec resume_interaction(String.t(), map(), keyword()) ::
          {:consent_required, Interaction.t()}
          | {:consent_reused, String.t()}
          | {:error, term()}
  def resume_interaction(interaction_id, subject_context, opts \\ [])
      when is_binary(interaction_id) and is_map(subject_context) do
    with {:ok, %Interaction{} = interaction} <- load_active_interaction(interaction_id, opts),
         :ok <- ensure_resume_subject(interaction, subject_context) do
      subject_id = subject_id!(subject_context)

      case interaction.status do
        :pending_login ->
          transition_pending_login(interaction, subject_id, subject_context, opts)

        :pending_consent ->
          {:consent_required, interaction}

        _other ->
          {:error, :interaction_not_active}
      end
    end
  end

  @spec approve_interaction(String.t(), map(), keyword()) ::
          {:approved, String.t()} | {:error, term()}
  def approve_interaction(interaction_id, subject_context, opts \\ [])
      when is_binary(interaction_id) and is_map(subject_context) do
    with {:ok, %Interaction{} = interaction} <-
           load_pending_consent_interaction(interaction_id, opts),
         :ok <- ensure_subject_match(interaction, subject_context) do
      subject_id = subject_id!(subject_context)
      remember? = Keyword.get(opts, :remember, false)

      audit_events = [
        consent_approved_event(interaction, subject_id, remember?),
        authorization_completed_event(interaction, subject_actor(subject_id), :consent_approved)
      ]

      case approve_with_audit(interaction_id, subject_id, remember?, audit_events, opts) do
        {:ok, {completed, redirect_uri}} ->
          emit(:consent_approved, completed, subject_id, %{reason_code: :consent_approved})
          emit(:authorization_completed, completed, subject_id, %{reason_code: :consent_approved})
          {:approved, redirect_uri}

        {:error, :invalid_state} ->
          {:error, :interaction_not_active}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec deny_interaction(String.t(), map(), keyword()) :: {:denied, String.t()} | {:error, term()}
  def deny_interaction(interaction_id, subject_context, opts \\ [])
      when is_binary(interaction_id) and is_map(subject_context) do
    with {:ok, %Interaction{} = interaction} <-
           load_pending_consent_interaction(interaction_id, opts),
         :ok <- ensure_subject_match(interaction, subject_context) do
      subject_id = subject_id!(subject_context)

      audit_event = consent_denied_event(interaction, subject_id)

      case deny_with_audit(interaction_id, audit_event, opts) do
        {:ok, %Interaction{} = denied} ->
          emit(:consent_denied, denied, subject_id, %{reason_code: :access_denied})
          {:denied, denial_redirect(interaction)}

        {:error, :invalid_state} ->
          {:error, :interaction_not_active}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp persist_login_required(%Interaction{} = interaction, opts) do
    with {:ok, persisted} <- interaction_store(opts).put_interaction(interaction) do
      emit(:interaction_started, persisted, nil)
      emit(:login_required, persisted, nil)
      {:login_required, persisted}
    end
  end

  defp start_silent_authorization(validated, subject_context, interaction_id, now, opts) do
    cond do
      login_required?(validated, subject_context, now) ->
        {:redirect_error, silent_error(validated, "login_required", :login_required)}

      ui_required?(subject_context) ->
        {:redirect_error,
         silent_error(validated, "interaction_required", :interaction_required)}

      true ->
        start_silent_subject_authorization(validated, subject_context, interaction_id, now, opts)
    end
  end

  defp start_silent_subject_authorization(validated, subject_context, interaction_id, now, opts) do
    subject_id = subject_id!(subject_context)
    auth_time = subject_auth_time(subject_context)

    interaction =
      validated
      |> build_interaction(interaction_id, subject_id, :pending_consent, now)
      |> Map.put(:auth_time, auth_time)

    case silent_consent_outcome(interaction, validated, subject_id, opts) do
      :consent_required ->
        {:redirect_error, silent_error(validated, "consent_required", :consent_required)}

      {:ok, %Interaction{} = persisted} ->
        emit(:interaction_started, persisted, subject_id)
        emit(:consent_reused, persisted, subject_id)
        finalize_reused_consent(persisted, subject_id, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_subject_authorization(validated, subject_context, interaction_id, now, opts) do
    subject_id = subject_id!(subject_context)
    auth_time = subject_auth_time(subject_context)

    validated
    |> build_interaction(interaction_id, subject_id, :pending_consent, now)
    |> Map.put(:auth_time, auth_time)
    |> persist_subject_authorization(validated, subject_id, opts)
  end

  defp persist_subject_authorization(%Interaction{} = interaction, validated, subject_id, opts) do
    with {:ok, persisted} <- interaction_store(opts).put_interaction(interaction) do
      emit(:interaction_started, persisted, subject_id)

      handle_subject_consent(
        persisted,
        validated.client_id,
        validated.scopes,
        validated.prompt,
        subject_id,
        opts
      )
    end
  end

  defp silent_consent_outcome(%Interaction{} = interaction, validated, subject_id, opts) do
    case consent_store(opts).list_reusable_consents(subject_id, validated.client_id) do
      {:ok, grants} ->
        case ConsentPolicy.reusable_grant(grants, validated.scopes, validated.prompt) do
          {:reuse, _grant} ->
            interaction_store(opts).put_interaction(interaction)

          :consent_required ->
            :consent_required
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_subject_consent(
         %Interaction{} = interaction,
         client_id,
         scopes,
         prompt,
         subject_id,
         opts
       ) do
    case consent_store(opts).list_reusable_consents(subject_id, client_id) do
      {:ok, grants} ->
        case ConsentPolicy.reusable_grant(grants, scopes, prompt) do
          {:reuse, _grant} ->
            emit(:consent_reused, interaction, subject_id)
            finalize_reused_consent(interaction, subject_id, opts)

          :consent_required ->
            emit(:consent_shown, interaction, subject_id)
            {:consent_required, interaction}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp finalize_reused_consent(%Interaction{} = interaction, subject_id, opts) do
    audit_event =
      authorization_completed_event(interaction, system_actor(), :consent_reused)

    case transact_with_audit(interaction_store(opts), [audit_event], fn ->
           complete_reused_consent(interaction, subject_id, opts)
         end) do
      {:ok, {%Interaction{} = completed, redirect_uri}} ->
        emit(:authorization_completed, completed, subject_id, %{reason_code: :consent_reused})
        {:consent_reused, redirect_uri}

      {:error, :invalid_state} ->
        {:error, :interaction_not_active}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_interaction(%Validated{} = validated, interaction_id, subject_id, status, now) do
    %Interaction{
      interaction_id: interaction_id,
      client_id: validated.client_id,
      account_id: subject_id,
      scopes_requested: validated.scopes,
      prompt: validated.prompt,
      nonce: validated.nonce,
      auth_time: nil,
      max_age: validated.max_age,
      auth_time_requested: validated.auth_time_requested?,
      redirect_uri: validated.redirect_uri,
      return_to: default_return_to(interaction_id),
      state: validated.state,
      code_challenge: validated.code_challenge,
      code_challenge_method: validated.code_challenge_method,
      status: status,
      login_required_at: if(status == :pending_login, do: now),
      consent_requested_at: if(status == :pending_consent, do: now),
      expires_at: DateTime.add(now, @authorization_code_ttl, :second)
    }
  end

  defp issue_authorization_code(%Interaction{} = interaction, subject_id, opts) do
    raw_code = generate_code(opts)
    now = now(opts)
    token_hash = Policy.hash_token(raw_code)

    token = %Token{
      token_hash: token_hash,
      token_type: :authorization_code,
      client_id: interaction.client_id,
      account_id: subject_id,
      interaction_id: interaction.interaction_id,
      redirect_uri: interaction.redirect_uri,
      scopes: interaction.scopes_requested,
      code_challenge: interaction.code_challenge,
      code_challenge_method: interaction.code_challenge_method,
      issued_at: now,
      expires_at: DateTime.add(now, @authorization_code_ttl, :second)
    }

    with {:ok, stored_token} <- token_store(opts).store_token(token) do
      emit(:authorization_code_issued, interaction, subject_id, %{token_id: stored_token.id})
      {:ok, approval_redirect(interaction, raw_code)}
    end
  end

  defp maybe_store_consent(%Interaction{} = interaction, subject_id, remember?, opts) do
    grant = %ConsentGrant{
      account_id: subject_id,
      client_id: interaction.client_id,
      scopes: interaction.scopes_requested,
      granted_at: now(opts),
      status: :active,
      kind: ConsentPolicy.approval_kind(remember?)
    }

    consent_store(opts).grant_consent(grant)
  end

  defp transition_pending_login(%Interaction{} = interaction, subject_id, subject_context, opts) do
    case move_login_to_pending_consent(interaction, subject_id, subject_context, opts) do
      {:ok, %Interaction{} = pending_consent} ->
        handle_subject_consent(
          pending_consent,
          interaction.client_id,
          interaction.scopes_requested,
          interaction.prompt,
          subject_id,
          opts
        )

      {:error, :invalid_state} -> {:error, :interaction_not_active}
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_pending_consent_interaction(interaction_id, opts) do
    case interaction_store(opts).fetch_active_interaction(interaction_id) do
      {:ok, %Interaction{status: :pending_consent} = interaction} ->
        {:ok, interaction}

      {:ok, %Interaction{}} ->
        {:error, :interaction_not_active}

      {:ok, nil} ->
        classify_inactive_interaction(interaction_id, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp classify_inactive_interaction(interaction_id, opts) do
    now = now(opts)

    case interaction_store(opts).fetch_interaction(interaction_id) do
      {:ok, %Interaction{} = interaction} ->
        if interaction_expired?(interaction, now) do
          {:error, :interaction_expired}
        else
          {:error, :interaction_not_active}
        end

      {:ok, nil} ->
        {:error, :interaction_not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_subject_match(%Interaction{account_id: nil}, _subject_context), do: :ok

  defp ensure_subject_match(%Interaction{account_id: subject_id}, %{subject_id: subject_id}),
    do: :ok

  defp ensure_subject_match(_interaction, _subject_context), do: {:error, :subject_mismatch}

  defp ensure_resume_subject(%Interaction{account_id: nil}, _subject_context), do: :ok

  defp ensure_resume_subject(%Interaction{} = interaction, subject_context),
    do: ensure_subject_match(interaction, subject_context)

  defp approval_redirect(%Interaction{} = interaction, raw_code) do
    build_redirect(interaction.redirect_uri, %{
      "code" => raw_code,
      "state" => interaction.state
    })
  end

  defp denial_redirect(%Interaction{} = interaction) do
    build_redirect(interaction.redirect_uri, %{
      "error" => "access_denied",
      "state" => interaction.state
    })
  end

  defp build_redirect(base_uri, params) when is_binary(base_uri) and is_map(params) do
    uri = URI.parse(base_uri)
    existing = URI.decode_query(uri.query || "")

    merged =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
      |> then(&Map.merge(existing, &1))

    %{uri | query: URI.encode_query(merged)}
    |> URI.to_string()
  end

  defp emit(event, %Interaction{} = interaction, subject_id, extra \\ %{}) do
    observability_module().emit(
      event,
      %{},
      Map.merge(extra, %{
        client_id: interaction.client_id,
        interaction_id: interaction.interaction_id,
        subject_id: subject_id,
        status: interaction.status
      })
    )
  end

  defp transact_with_audit(store, audit_events, fun)
       when is_atom(store) and is_list(audit_events) and is_function(fun, 0) do
    store.transact(fn ->
      fun.()
      |> maybe_append_audit_events(store, audit_events)
    end)
    |> normalize_transaction_result()
  end

  defp append_audit_events(_store, []), do: :ok

  defp append_audit_events(store, [event | rest]) do
    if function_exported?(store, :append_audit_event, 1) do
      case store.append_audit_event(event) do
        {:ok, %Lockspire.Audit.Event{}} -> append_audit_events(store, rest)
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :audit_append_unsupported}
    end
  end

  defp maybe_append_audit_events({:error, reason}, _store, _audit_events), do: {:error, reason}

  defp maybe_append_audit_events(result, store, audit_events) do
    case append_audit_events(store, audit_events) do
      :ok -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_transaction_result({:ok, {:ok, result}}), do: {:ok, result}
  defp normalize_transaction_result(result), do: result

  defp approve_with_audit(interaction_id, subject_id, remember?, audit_events, opts) do
    transact_with_audit(interaction_store(opts), audit_events, fn ->
      approve_pending_interaction(interaction_id, subject_id, remember?, opts)
    end)
  end

  defp deny_with_audit(interaction_id, audit_event, opts) do
    transact_with_audit(interaction_store(opts), [audit_event], fn ->
      deny_pending_interaction(interaction_id, opts)
    end)
  end

  defp approve_pending_interaction(interaction_id, subject_id, remember?, opts) do
    with {:ok, completed} <-
           interaction_store(opts).transition_interaction(
             interaction_id,
             [:pending_consent],
             %{status: :completed, completed_at: now(opts)}
           ),
         {:ok, _grant} <- maybe_store_consent(completed, subject_id, remember?, opts),
         {:ok, redirect_uri} <- issue_authorization_code(completed, subject_id, opts) do
      {completed, redirect_uri}
    end
  end

  defp deny_pending_interaction(interaction_id, opts) do
    interaction_store(opts).transition_interaction(
      interaction_id,
      [:pending_consent],
      %{
        status: :denied,
        denied_at: now(opts),
        denial_reason: "access_denied"
      }
    )
  end

  defp complete_reused_consent(%Interaction{} = interaction, subject_id, opts) do
    with {:ok, completed} <-
           interaction_store(opts).transition_interaction(
             interaction.interaction_id,
             [:pending_consent],
             %{status: :completed, completed_at: now(opts)}
           ),
         {:ok, redirect_uri} <- issue_authorization_code(completed, subject_id, opts) do
      {completed, redirect_uri}
    end
  end

  defp move_login_to_pending_consent(%Interaction{} = interaction, subject_id, subject_context, opts) do
    interaction_store(opts).transition_interaction(
      interaction.interaction_id,
      [:pending_login],
      %{
        status: :pending_consent,
        account_id: subject_id,
        consent_requested_at: now(opts)
      }
      |> maybe_put_auth_time(subject_context)
    )
  end

  defp interaction_expired?(%Interaction{} = interaction, now) do
    interaction.status == :expired or DateTime.compare(interaction.expires_at, now) != :gt
  end

  defp consent_approved_event(%Interaction{} = interaction, subject_id, remember?) do
    audit_event(
      :consent_approved,
      :succeeded,
      interaction,
      subject_actor(subject_id),
      :consent_approved,
      %{remember: remember?}
    )
  end

  defp consent_denied_event(%Interaction{} = interaction, subject_id) do
    audit_event(
      :consent_denied,
      :denied,
      interaction,
      subject_actor(subject_id),
      :access_denied
    )
  end

  defp authorization_completed_event(%Interaction{} = interaction, actor, reason_code) do
    audit_event(:authorization_completed, :succeeded, interaction, actor, reason_code)
  end

  defp audit_event(
         action,
         outcome,
         %Interaction{} = interaction,
         actor,
         reason_code,
         metadata \\ %{}
       ) do
    %{
      action: action,
      outcome: outcome,
      reason_code: reason_code,
      actor: actor,
      resource: %{type: :interaction, id: interaction.interaction_id},
      metadata:
        Map.merge(metadata, %{
          client_id: interaction.client_id,
          status: interaction.status
        })
    }
  end

  defp subject_actor(subject_id) do
    %{type: :subject, id: subject_id, display: subject_id}
  end

  defp system_actor do
    %{type: :system, id: "lockspire", display: "Lockspire"}
  end

  defp generate_code(opts) do
    opts
    |> Keyword.get_lazy(:code_generator, fn -> &default_generator/0 end)
    |> then(& &1.())
  end

  defp generate_interaction_id(opts) do
    opts
    |> Keyword.get_lazy(:interaction_id_generator, fn -> &default_generator/0 end)
    |> then(& &1.())
  end

  defp default_generator do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp now(opts) do
    opts
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end

  defp login_required?(%Validated{} = validated, subject_context, now) do
    is_nil(subject_context) or
      "login" in validated.prompt or
      stale_auth_time?(validated.max_age, subject_context, now)
  end

  defp stale_auth_time?(nil, _subject_context, _now), do: false

  defp stale_auth_time?(max_age, subject_context, now) when is_integer(max_age) do
    case subject_auth_time(subject_context) do
      %DateTime{} = auth_time -> DateTime.diff(now, auth_time, :second) > max_age
      nil -> true
    end
  end

  defp load_active_interaction(interaction_id, opts) do
    case interaction_store(opts).fetch_active_interaction(interaction_id) do
      {:ok, %Interaction{} = interaction} ->
        {:ok, interaction}

      {:ok, nil} ->
        classify_inactive_interaction(interaction_id, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp subject_id!(%{subject_id: subject_id}) when is_binary(subject_id) and subject_id != "",
    do: subject_id

  defp subject_id!(_subject_context) do
    raise ArgumentError, "missing required :subject_id in authenticated subject context"
  end

  defp subject_auth_time(subject_context) when is_map(subject_context) do
    case Map.get(subject_context, :auth_time, Map.get(subject_context, "auth_time")) do
      %DateTime{} = auth_time -> auth_time
      _other -> nil
    end
  end

  defp subject_auth_time(_subject_context), do: nil

  defp maybe_put_auth_time(attrs, subject_context) do
    case subject_auth_time(subject_context) do
      %DateTime{} = auth_time -> Map.put(attrs, :auth_time, auth_time)
      nil -> attrs
    end
  end

  defp silent_prompt?(["none"]), do: true
  defp silent_prompt?(_prompt), do: false

  defp ui_required?(subject_context) when is_map(subject_context) do
    not is_nil(Map.get(subject_context, :ui_required, Map.get(subject_context, "ui_required")))
  end

  defp ui_required?(_subject_context), do: false

  defp silent_error(%Validated{} = validated, error, reason_code) do
    %Error{
      error: error,
      error_description: "Unable to complete the authorization request without user interaction",
      reason_code: reason_code,
      state: validated.state,
      redirect_uri: validated.redirect_uri
    }
  end

  defp default_return_to(interaction_id), do: "/lockspire/interactions/#{interaction_id}"

  defp interaction_store(opts), do: Keyword.get(opts, :interaction_store, Config.repo!())
  defp consent_store(opts), do: Keyword.get(opts, :consent_store, Config.repo!())
  defp token_store(opts), do: Keyword.get(opts, :token_store, Config.repo!())
  defp observability_module, do: Observability
end
