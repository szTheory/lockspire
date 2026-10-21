defmodule Lockspire.Ciba do
  @moduledoc """
  Public API for host applications to manage CIBA (Backchannel Authentication) flows.
  """

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Workers.CibaNotificationWorker

  @doc """
  Approves a pending CIBA authorization request.

  Transitions the authorization status to `:approved` and records the `subject_id` 
  and final `scopes`.

  Returns `{:ok, CibaAuthorization.t()}` on success, or `{:error, reason}` if the 
  authorization is not found or is in an invalid state (e.g., already expired or denied).
  """
  @spec approve_authorization(
          auth_req_id_hash :: String.t(),
          subject_id :: String.t(),
          scopes :: [String.t()]
        ) ::
          {:ok, CibaAuthorization.t()} | {:error, :not_found | :invalid_state | term()}
  def approve_authorization(auth_req_id_hash, subject_id, scopes) do
    approve_authorization_with_opts(auth_req_id_hash, subject_id, scopes, [])
  end

  @doc false
  @spec approve_authorization_with_opts(String.t(), String.t(), [String.t()], keyword()) ::
          {:ok, CibaAuthorization.t()} | {:error, :not_found | :invalid_state | term()}
  def approve_authorization_with_opts(auth_req_id_hash, subject_id, scopes, opts)
      when is_binary(auth_req_id_hash) and is_binary(subject_id) and is_list(scopes) and
             is_list(opts) do
    ciba_store = Keyword.get(opts, :ciba_authorization_store, Repository)
    client_store = Keyword.get(opts, :client_store, Repository)
    audit_store = Keyword.get(opts, :audit_store, Repository)
    transaction_store = Keyword.get(opts, :transaction_store, Repository)
    clock = clock(opts)
    authority = transaction_store.transaction_authority()

    with {:ok, _lifetime} <- ClientLifetime.adapt(client_store, authority),
         :ok <- participants(authority, client_store, ciba_store, audit_store, transaction_store),
         {:ok, %CibaAuthorization{} = request} <-
           ciba_store.fetch_ciba_authorization_by_auth_req_id_hash(auth_req_id_hash),
         {:ok, approved} <-
           transaction_store.transact(fn ->
             with {:ok, [client]} <- client_store.lock_clients([request.client_id]),
                  {:ok, transition} <-
                    ciba_store.transition_ciba_authorization(
                      auth_req_id_hash,
                      [:pending],
                      fn current_request ->
                        decision_time = clock.()

                        cond do
                          current_request.client_id != client.client_id ->
                            {:error, :invalid_state}

                          DateTime.compare(current_request.expires_at, decision_time) != :gt ->
                            {:error, :expired}

                          eligibility(client, decision_time) != :ok ->
                            {:error, eligibility_error(client, decision_time)}

                          true ->
                            %{
                              status: :approved,
                              subject_id: subject_id,
                              scopes: scopes,
                              approved_at: decision_time
                            }
                        end
                      end
                    ),
                  {:ok, _event} <-
                    audit_store.append_audit_event(%{
                      action: "ciba_authorization_approved",
                      outcome: "approved",
                      actor: %{type: "host"},
                      resource: %{type: "ciba_authorization", id: transition.auth_req_id_hash},
                      metadata: %{client_id: transition.client_id}
                    }) do
               {:ok, transition}
             else
               {:ok, []} -> {:error, :not_found}
               {:error, reason} -> {:error, reason}
             end
           end) do
      maybe_enqueue_notification(approved)
      {:ok, approved}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    _error -> {:error, :client_lifetime_unavailable}
  end

  @doc """
  Denies a pending CIBA authorization request.

  Transitions the authorization status to `:denied`.

  Returns `{:ok, CibaAuthorization.t()}` on success.
  """
  @spec deny_authorization(auth_req_id_hash :: String.t(), reason :: String.t() | nil) ::
          {:ok, CibaAuthorization.t()} | {:error, :not_found | :invalid_state | term()}
  def deny_authorization(auth_req_id_hash, _reason \\ nil) do
    attrs = %{
      status: :denied,
      denied_at: DateTime.utc_now()
    }

    case Repository.transition_ciba_authorization(
           auth_req_id_hash,
           [:pending],
           attrs
         ) do
      {:ok, %CibaAuthorization{} = ciba_auth} = result ->
        maybe_enqueue_notification(ciba_auth)
        result

      other ->
        other
    end
  end

  defp maybe_enqueue_notification(%CibaAuthorization{delivery_mode: mode} = ciba_auth)
       when mode in [:ping, :push] do
    %{ciba_authorization_id: ciba_auth.id}
    |> CibaNotificationWorker.new()
    |> then(&Oban.insert(Lockspire.Oban, &1))
  end

  defp maybe_enqueue_notification(_ciba_auth), do: :ok

  defp eligibility(%Client{} = client, %DateTime{} = now) do
    with {:ok, client} <- ClientLifetime.validate_client(client) do
      Client.app_eligibility(client, now, :ciba_approval)
    end
  end

  defp eligibility_error(client, now) do
    case eligibility(client, now) do
      {:error, :expired} -> :expired
      {:error, :disabled} -> :not_active
      {:error, _reason} -> :client_lifetime_unavailable
      :ok -> :invalid_state
    end
  end

  defp participants(%{identity: identity, participants: participants}, client, ciba, audit, tx)
       when not is_nil(identity) and is_map(participants) do
    if Map.get(participants, :client_store) == client and
         Map.get(participants, :ciba_authorization_store) == ciba and
         Map.get(participants, :audit_store) == audit and
         Map.get(participants, :transaction_store) == tx do
      :ok
    else
      {:error, :transaction_authority_mismatch}
    end
  end

  defp participants(_authority, _client, _ciba, _audit, _tx),
    do: {:error, :transaction_authority_unavailable}

  defp clock(opts) do
    case Keyword.get(opts, :now, &DateTime.utc_now/0) do
      %DateTime{} = now -> fn -> now end
      now when is_function(now, 0) -> now
      _other -> fn -> nil end
    end
  end
end
