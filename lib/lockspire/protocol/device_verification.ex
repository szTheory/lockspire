defmodule Lockspire.Protocol.DeviceVerification do
  @moduledoc """
  Narrow lookup and approval seam for host-owned device verification UX.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository

  defmodule PendingAuthorization do
    @moduledoc "Pending device authorization context exposed to the host verification seam."

    @enforce_keys [:verification_handle, :user_code, :client_id, :client_name, :scopes]
    defstruct [:verification_handle, :user_code, :client_id, :client_name, :scopes]

    @type t :: %__MODULE__{
            verification_handle: String.t(),
            user_code: String.t(),
            client_id: String.t(),
            client_name: String.t(),
            scopes: [String.t()]
          }
  end

  @type lookup_result ::
          {:ok, PendingAuthorization.t()} | {:error, :not_found | :expired | :not_active | term()}
  @type transition_result ::
          {:ok, DeviceAuthorization.t()} | {:error, :invalid_actor_context | term()}

  @spec lookup_pending_device_authorization(String.t(), keyword()) :: lookup_result()
  def lookup_pending_device_authorization(user_code, opts \\ [])
      when is_binary(user_code) and is_list(opts) do
    normalized_user_code = DeviceAuthorization.canonicalize_user_code(user_code)
    user_code_hash = DeviceAuthorization.hash_user_code(normalized_user_code)

    with {:ok, authorization} <-
           device_authorization_store(opts).fetch_device_authorization_by_user_code_hash(
             user_code_hash
           ) do
      classify_lookup_result(authorization, normalized_user_code, opts)
    end
  end

  @spec approve_device_authorization(String.t(), map(), keyword()) :: transition_result()
  def approve_device_authorization(verification_handle, actor_context, opts \\ [])
      when is_binary(verification_handle) and is_map(actor_context) and is_list(opts) do
    with {:ok, subject_id} <- actor_subject_id(actor_context),
         {:ok, %DeviceAuthorization{} = pending} <-
           device_authorization_store(opts).fetch_device_authorization_by_verification_handle(
             verification_handle
           ),
         {:ok, approved} <- guarded_approval(pending, subject_id, opts) do
      Lockspire.Observability.emit(
        :device_authorization,
        :approved,
        %{},
        %{
          verification_handle: verification_handle,
          client_id: approved.client_id,
          subject_id: subject_id
        }
      )

      {:ok, approved}
    else
      {:ok, nil} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec deny_device_authorization(String.t(), map(), keyword()) :: transition_result()
  def deny_device_authorization(verification_handle, actor_context, opts \\ [])
      when is_binary(verification_handle) and is_map(actor_context) and is_list(opts) do
    with {:ok, _subject_id} <- actor_subject_id(actor_context),
         {:ok, denied} <-
           device_authorization_store(opts).transition_device_authorization(
             verification_handle,
             [:pending],
             %{
               status: :denied,
               denied_at: now(opts)
             }
           ) do
      Lockspire.Observability.emit(
        :device_authorization,
        :denied,
        %{},
        %{
          verification_handle: verification_handle,
          client_id: denied.client_id
        }
      )

      {:ok, denied}
    end
  end

  defp classify_lookup_result(nil, _normalized_user_code, _opts), do: {:error, :not_found}

  defp classify_lookup_result(%DeviceAuthorization{} = authorization, normalized_user_code, opts) do
    cond do
      authorization.status != :pending ->
        {:error, :not_active}

      expired?(authorization, opts) ->
        {:error, :expired}

      true ->
        build_pending_authorization(authorization, normalized_user_code, opts)
    end
  end

  defp build_pending_authorization(
         %DeviceAuthorization{} = authorization,
         normalized_user_code,
         opts
       ) do
    with {:ok, client} <- current_eligible_client(authorization.client_id, opts),
         client_name <- display_client_name(client) do
      {:ok,
       %PendingAuthorization{
         verification_handle: authorization.verification_handle,
         user_code: normalized_user_code,
         client_id: authorization.client_id,
         client_name: client_name,
         scopes: List.wrap(authorization.scopes)
       }}
    end
  end

  defp current_eligible_client(client_id, opts) do
    store = client_store(opts)

    with {:ok, lifetime} <- client_lifetime(opts),
         {:ok, %Client{} = client} <- store.fetch_client_by_id(client_id),
         {:ok, client} <- ClientLifetime.validate_client(client),
         :ok <- Client.app_eligibility(client, clock(opts).(), :device_verification) do
      _ = lifetime
      {:ok, client}
    else
      {:ok, nil} -> {:error, :not_found}
      {:error, :expired} -> {:error, :expired}
      {:error, :disabled} -> {:error, :not_active}
      {:error, reason} -> {:error, reason}
    end
  end

  defp display_client_name(%Client{name: name}) when is_binary(name) and name != "", do: name
  defp display_client_name(%Client{client_id: client_id}), do: client_id

  defp guarded_approval(%DeviceAuthorization{} = pending, subject_id, opts) do
    client_store = client_store(opts)
    device_store = device_authorization_store(opts)
    audit_store = Keyword.get(opts, :audit_store, Repository)
    transaction_store = Keyword.get(opts, :transaction_store, Repository)
    clock = clock(opts)

    with {:ok, _lifetime} <- client_lifetime(opts),
         :ok <-
           participants(
             transaction_store.transaction_authority(),
             client_store,
             device_store,
             audit_store,
             transaction_store
           ),
         {:ok, approved} <-
           transaction_store.transact(fn ->
             with {:ok, [current_client]} <- client_store.lock_clients([pending.client_id]),
                  {:ok, result} <-
                    device_store.transition_device_authorization(
                      pending.verification_handle,
                      [:pending],
                      fn current_authorization ->
                        decision_time = clock.()

                        cond do
                          current_authorization.client_id != current_client.client_id ->
                            {:error, :invalid_state}

                          DateTime.compare(current_authorization.expires_at, decision_time) != :gt ->
                            {:error, :expired}

                          :ok != app_eligibility(current_client, decision_time) ->
                            {:error, eligibility_error(current_client, decision_time)}

                          true ->
                            %{
                              status: :approved,
                              subject_id: subject_id,
                              approved_at: decision_time
                            }
                        end
                      end
                    ),
                  {:ok, _event} <-
                    audit_store.append_audit_event(%{
                      action: "device_authorization_approved",
                      outcome: "approved",
                      actor: %{type: "host", id: subject_id},
                      resource: %{
                        type: "device_authorization",
                        id: result.verification_handle
                      },
                      metadata: %{client_id: result.client_id}
                    }) do
               {:ok, result}
             else
               {:ok, []} -> {:error, :not_found}
               {:error, reason} -> {:error, reason}
             end
           end) do
      {:ok, approved}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    _error -> {:error, :client_lifetime_unavailable}
  end

  defp eligibility_error(client, now) do
    case app_eligibility(client, now) do
      {:error, :expired} -> :expired
      {:error, :disabled} -> :not_active
      {:error, _} -> :client_lifetime_unavailable
      :ok -> :invalid_state
    end
  end

  defp app_eligibility(%Client{} = client, %DateTime{} = now) do
    with {:ok, client} <- ClientLifetime.validate_client(client) do
      Client.app_eligibility(client, now, :device_approval)
    end
  end

  defp client_lifetime(opts) do
    client_store = client_store(opts)
    transaction_store = Keyword.get(opts, :transaction_store, Repository)

    case ClientLifetime.adapt(client_store, transaction_store.transaction_authority()) do
      {:ok, lifetime} -> {:ok, lifetime}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _error -> {:error, :client_lifetime_unavailable}
  end

  defp participants(%{identity: identity, participants: participants}, client, device, audit, tx)
       when not is_nil(identity) and is_map(participants) do
    if Map.get(participants, :client_store) == client and
         Map.get(participants, :device_authorization_store) == device and
         Map.get(participants, :audit_store) == audit and
         Map.get(participants, :transaction_store) == tx do
      :ok
    else
      {:error, :transaction_authority_mismatch}
    end
  end

  defp participants(_authority, _client, _device, _audit, _tx),
    do: {:error, :transaction_authority_unavailable}

  defp actor_subject_id(%{subject_id: subject_id})
       when is_binary(subject_id) and subject_id != "",
       do: {:ok, subject_id}

  defp actor_subject_id(_actor_context), do: {:error, :invalid_actor_context}

  defp expired?(%DeviceAuthorization{expires_at: expires_at}, opts) do
    DateTime.compare(expires_at, now(opts)) != :gt
  end

  defp device_authorization_store(opts),
    do: Keyword.get(opts, :device_authorization_store, Repository)

  defp client_store(opts),
    do: Keyword.get(opts, :client_store, Repository)

  defp clock(opts) do
    case Keyword.get(opts, :now, &DateTime.utc_now/0) do
      %DateTime{} = now -> fn -> now end
      now when is_function(now, 0) -> now
      _other -> fn -> nil end
    end
  end

  defp now(opts), do: clock(opts).()
end
