defmodule Lockspire.Protocol.AuthorizationFlow do
  @moduledoc """
  Orchestrates durable authorization interactions, consent decisions, and code issuance.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Protocol.ConsentPolicy

  @authorization_code_ttl 300

  @spec start_authorization(Validated.t(), map() | nil, keyword()) ::
          {:login_required, Interaction.t()}
          | {:consent_required, Interaction.t()}
          | {:consent_reused, String.t()}
          | {:error, term()}
  def start_authorization(%Validated{} = validated, subject_context, opts \\ []) do
    now = now(opts)
    interaction_id = generate_interaction_id(opts)

    cond do
      login_required?(validated.prompt, subject_context) ->
        validated
        |> build_interaction(interaction_id, nil, :pending_login, now)
        |> persist_login_required(opts)

      true ->
        subject_id = subject_id!(subject_context)

        interaction =
          build_interaction(validated, interaction_id, subject_id, :pending_consent, now)

        with {:ok, persisted} <- interaction_store(opts).put_interaction(interaction) do
          emit(:interaction_started, persisted, subject_id)

          case consent_store(opts).list_reusable_consents(subject_id, validated.client_id) do
            {:ok, grants} ->
              case ConsentPolicy.reusable_grant(grants, validated.scopes, validated.prompt) do
                {:reuse, _grant} ->
                  emit(:consent_reused, persisted, subject_id)
                  finalize_reused_consent(persisted, subject_id, opts)

                :consent_required ->
                  emit(:consent_shown, persisted, subject_id)
                  {:consent_required, persisted}
              end

            {:error, reason} ->
              {:error, reason}
          end
        end
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
          transition_pending_login(interaction, subject_id, opts)

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

      case interaction_store(opts).transact(fn ->
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
           end) do
        {:ok, {completed, redirect_uri}} ->
          emit(:consent_approved, completed, subject_id)
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

      case interaction_store(opts).transact(fn ->
             with {:ok, denied} <-
                    interaction_store(opts).transition_interaction(
                      interaction_id,
                      [:pending_consent],
                      %{
                        status: :denied,
                        denied_at: now(opts),
                        denial_reason: "access_denied"
                      }
                    ) do
               denied
             end
           end) do
        {:ok, %Interaction{} = denied} ->
          emit(:consent_denied, denied, subject_id)
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

  defp finalize_reused_consent(%Interaction{} = interaction, subject_id, opts) do
    case interaction_store(opts).transact(fn ->
           with {:ok, completed} <-
                  interaction_store(opts).transition_interaction(
                    interaction.interaction_id,
                    [:pending_consent],
                    %{status: :completed, completed_at: now(opts)}
                  ),
                {:ok, redirect_uri} <- issue_authorization_code(completed, subject_id, opts) do
             {completed, redirect_uri}
           end
         end) do
      {:ok, {_completed, redirect_uri}} -> {:consent_reused, redirect_uri}
      {:error, :invalid_state} -> {:error, :interaction_not_active}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_interaction(%Validated{} = validated, interaction_id, subject_id, status, now) do
    %Interaction{
      interaction_id: interaction_id,
      client_id: validated.client_id,
      account_id: subject_id,
      scopes_requested: validated.scopes,
      prompt: validated.prompt,
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
    token_hash = hash_secret(raw_code)

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

  defp transition_pending_login(%Interaction{} = interaction, subject_id, opts) do
    case interaction_store(opts).transact(fn ->
           with {:ok, pending_consent} <-
                  interaction_store(opts).transition_interaction(
                    interaction.interaction_id,
                    [:pending_login],
                    %{
                      status: :pending_consent,
                      account_id: subject_id,
                      consent_requested_at: now(opts)
                    }
                  ) do
             pending_consent
           end
         end) do
      {:ok, %Interaction{} = pending_consent} ->
        case consent_store(opts).list_reusable_consents(subject_id, interaction.client_id) do
          {:ok, grants} ->
            case ConsentPolicy.reusable_grant(
                   grants,
                   interaction.scopes_requested,
                   interaction.prompt
                 ) do
              {:reuse, _grant} ->
                emit(:consent_reused, pending_consent, subject_id)
                finalize_reused_consent(pending_consent, subject_id, opts)

              :consent_required ->
                emit(:consent_shown, pending_consent, subject_id)
                {:consent_required, pending_consent}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :invalid_state} ->
        {:error, :interaction_not_active}

      {:error, reason} ->
        {:error, reason}
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
        cond do
          interaction.status == :expired or DateTime.compare(interaction.expires_at, now) != :gt ->
            {:error, :interaction_expired}

          true ->
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
    observability_module()
    |> apply(:emit, [
      event,
      %{},
      Map.merge(extra, %{
        client_id: interaction.client_id,
        interaction_id: interaction.interaction_id,
        subject_id: subject_id,
        status: interaction.status
      })
    ])
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

  defp hash_secret(secret) when is_binary(secret) do
    :sha256
    |> :crypto.hash(secret)
    |> Base.encode16(case: :lower)
  end

  defp now(opts) do
    opts
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end

  defp login_required?(prompt, nil) when is_list(prompt), do: true
  defp login_required?(prompt, _subject_context), do: "login" in prompt

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

  defp default_return_to(interaction_id), do: "/lockspire/interactions/#{interaction_id}"

  defp interaction_store(opts), do: Keyword.get(opts, :interaction_store, Config.repo!())
  defp consent_store(opts), do: Keyword.get(opts, :consent_store, Config.repo!())
  defp token_store(opts), do: Keyword.get(opts, :token_store, Config.repo!())
  defp observability_module, do: Observability
end
