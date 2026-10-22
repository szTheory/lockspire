defmodule Lockspire.Protocol.RegistrationManagement do
  @moduledoc """
  RFC 7592 dynamic client registration management — `Plug.Conn`-free orchestrator.

  Public entries:
    - `read/2`       — return current RFC 7591 metadata for the RAT-bound client.
    - `update/2`     — full-replace via the same validator pipeline as `Registration.register/1`;
                       on success rotates the RAT and returns the new plaintext exactly once.
    - `delete/2`     — soft-disable through the neutral client lifecycle.

  All three functions accept `(client_id_from_url, %Domain.Client{} ...)` where `client` is the
  row matched by `Repository.get_client_by_registration_access_token_hash/1`. URL/RAT mismatches
  ALWAYS collapse to `{:error, :invalid_token}` — the discriminator stays in telemetry only,
  defending against client-ID enumeration.
  """

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository

  defmodule UpdateSuccess do
    @moduledoc """
    Successful dynamic-registration update result.

    The rotated registration access token is returned as plaintext exactly once.
    """
    @type t :: %__MODULE__{
            client: Client.t(),
            registration_access_token_plaintext: String.t()
          }
    defstruct [:client, :registration_access_token_plaintext]
  end

  @type update_request :: %{
          required(:metadata) => map(),
          required(:server_policy) => ServerPolicy.t(),
          required(:client) => Client.t(),
          optional(:now) => DateTime.t() | (-> DateTime.t())
        }

  @type update_result ::
          {:ok, UpdateSuccess.t()} | {:error, Registration.Error.t() | :invalid_token}

  @spec read(String.t(), Client.t()) ::
          {:ok, Client.t()} | {:error, :invalid_token | Registration.Error.t()}
  def read(client_id_from_url, %Client{} = client),
    do: read(client_id_from_url, client, [])

  @spec read(String.t(), Client.t(), keyword()) ::
          {:ok, Client.t()} | {:error, :invalid_token | Registration.Error.t()}
  def read(client_id_from_url, %Client{} = client, opts)
      when is_binary(client_id_from_url) and is_list(opts) do
    result =
      with_current_client(client_id_from_url, client, :read, opts, fn current, _now, _prepared ->
        {:ok, current}
      end)

    case result do
      {:ok, current} ->
        Observability.emit(:dcr, :read, %{count: 1}, %{
          status: :success,
          actor_type: :self_registered_client,
          actor_id: current.client_id,
          client_id: current.client_id
        })

        {:ok, current}

      {:error, :invalid_token} = error ->
        emit_unauthorized(client_id_from_url, client)
        error

      {:error, %Registration.Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, %Registration.Error{code: :server_error, reason: reason}}
    end
  end

  @spec update(String.t(), update_request()) :: update_result()
  def update(
        client_id_from_url,
        %{
          metadata: metadata,
          server_policy: %ServerPolicy{},
          client: %Client{} = client
        } = request
      )
      when is_binary(client_id_from_url) and is_map(metadata) do
    decision_clock = if Map.has_key?(request, :now), do: [now: request.now], else: []

    with {new_rat_plaintext, new_rat_hash} <- RegistrationAccessToken.generate(),
         {:ok, updated_client} <-
           with_current_client(
             client_id_from_url,
             client,
             :update,
             Keyword.put(decision_clock, :prepare, &prepare_update(&1, metadata)),
             fn current, now, {current_resolved, mutable_metadata} ->
               with {:ok, deadline} <-
                      Client.management_deadline(
                        current,
                        now,
                        current_resolved.default_registration_access_token_lifetime_seconds
                      ) do
                 persist_update(current, mutable_metadata, new_rat_hash, deadline, now)
               else
                 {:error, :invalid_lifetime_state} ->
                   {:error,
                    %Registration.Error{
                      code: :server_error,
                      reason: :invalid_lifetime_state
                    }}

                 {:error, reason} ->
                   {:error, reason}
               end
             end
           ) do
      emit_updated(updated_client)
      emit_rat_rotated(updated_client)

      {:ok,
       %UpdateSuccess{
         client: updated_client,
         registration_access_token_plaintext: new_rat_plaintext
       }}
    else
      {:error, :invalid_client_metadata, info} ->
        error = %Registration.Error{
          code: :invalid_client_metadata,
          field: info.field,
          reason: info.reason,
          allowed: info[:allowed]
        }

        emit_update_rejected(client, error)
        {:error, error}

      {:error, %Registration.Error{} = error} ->
        emit_update_rejected(client, error)
        {:error, error}

      {:error, reason} ->
        if reason == :invalid_token do
          emit_unauthorized(client_id_from_url, client)
          {:error, :invalid_token}
        else
          error = %Registration.Error{code: :persistence_error, reason: reason}
          emit_update_rejected(client, error)
          {:error, error}
        end
    end
  end

  @spec delete(String.t(), Client.t()) :: :ok | {:error, :invalid_token | term()}
  def delete(client_id_from_url, %Client{} = client),
    do: delete(client_id_from_url, client, [])

  @spec delete(String.t(), Client.t(), keyword()) :: :ok | {:error, :invalid_token | term()}
  def delete(client_id_from_url, %Client{} = client, opts)
      when is_binary(client_id_from_url) and is_list(opts) do
    case with_current_client(
           client_id_from_url,
           client,
           :delete,
           opts,
           fn current, now, _prepared ->
             ClientLifecycle.disable_dcr(current, now)
           end
         ) do
      {:ok, %Client{}} ->
        Observability.emit(:dcr, :delete, %{count: 1}, %{
          status: :success,
          actor_type: :self_registered_client,
          actor_id: client.client_id,
          client_id: client.client_id
        })

        :ok

      {:error, :invalid_token} = error ->
        emit_unauthorized(client_id_from_url, client)
        error

      {:error, reason} ->
        if reason == :invalid_lifetime_state do
          {:error, %Registration.Error{code: :server_error, reason: reason}}
        else
          {:error, reason}
        end
    end
  end

  @spec rotate_registration_access_token(Client.t()) ::
          {:ok, String.t(), Client.t()} | {:error, term()}
  def rotate_registration_access_token(%Client{} = client),
    do: rotate_registration_access_token(client, [])

  @spec rotate_registration_access_token(Client.t(), keyword()) ::
          {:ok, String.t(), Client.t()} | {:error, term()}
  def rotate_registration_access_token(%Client{} = client, opts) when is_list(opts) do
    {new_rat_plaintext, new_rat_hash} = RegistrationAccessToken.generate()

    result =
      with_recovery_client(client, opts, fn current ->
        with {:ok, %ServerPolicy{} = policy} <- Repository.get_server_policy(),
             {:ok, resolved} <- resolve_current_policy(policy, %{}),
             {:ok, now} <- decision_now(opts),
             {:ok, deadline} <-
               Client.management_deadline(
                 current,
                 now,
                 resolved.default_registration_access_token_lifetime_seconds
               ) do
          candidate = %{
            current
            | registration_access_token_expires_at: deadline,
              updated_at: now
          }

          ClientLifecycle.rotate_registration_access_token(candidate, new_rat_hash, %{
            action: :dcr_management_rat_rotated,
            outcome: :success,
            actor: %{type: :operator, id: "admin-ui"},
            resource: %{type: :client, id: current.client_id},
            metadata: %{rotated_at: now}
          })
        else
          {:error, %Registration.Error{} = error} -> {:error, error}
          {:error, reason} -> {:error, %Registration.Error{code: :server_error, reason: reason}}
          _unexpected -> {:error, %Registration.Error{code: :server_error}}
        end
      end)

    case result do
      {:ok, updated_client} ->
        emit_rat_rotated(updated_client, %{type: :operator, id: "admin-ui"})
        {:ok, new_rat_plaintext, updated_client}

      {:error, :invalid_lifetime_state} ->
        {:error, %Registration.Error{code: :server_error, reason: :invalid_lifetime_state}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Helpers

  defp persist_update(%Client{} = client, metadata, new_rat_hash, deadline, now) do
    ClientLifecycle.replace_dcr(client, metadata, new_rat_hash, deadline, now)
  end

  defp prepare_update(%Client{} = current, metadata) do
    with {:ok, %ServerPolicy{} = policy} <- Repository.get_server_policy(),
         {:ok, resolved} <- resolve_current_policy(policy, metadata),
         :ok <- Registration.validate_intake_metadata(metadata, resolved, policy, current),
         {:ok, mutable_metadata} <- validate_management_metadata(metadata, current) do
      {:ok, {resolved, mutable_metadata}}
    else
      {:error, %Registration.Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, %Registration.Error{code: :server_error, reason: reason}}
      _unexpected -> {:error, %Registration.Error{code: :server_error}}
    end
  end

  defp resolve_current_policy(policy, metadata) do
    case DcrPolicy.resolve(policy, nil, metadata) do
      {:ok, resolved} ->
        {:ok, resolved}

      {:error, :invalid_client_metadata, info} ->
        {:error,
         %Registration.Error{
           code: :invalid_client_metadata,
           field: info.field,
           reason: info.reason,
           allowed: info[:allowed]
         }}

      {:error, :server_error, info} ->
        {:error,
         %Registration.Error{
           code: :server_error,
           field: info.field,
           reason: info.reason
         }}
    end
  end

  defp validate_management_metadata(metadata, %Client{} = current) do
    with :ok <- validate_body_client_id(metadata, current),
         :ok <- reject_management_fields(metadata),
         :ok <- validate_included_client_secret(metadata, current),
         :ok <-
           validate_lifecycle_extension(metadata, "lockspire_client_expires_at", current, :app),
         :ok <-
           validate_lifecycle_extension(
             metadata,
             "lockspire_registration_access_token_expires_at",
             current,
             :management
           ) do
      {:ok,
       Map.drop(metadata, [
         "client_id",
         "client_secret",
         "lockspire_client_expires_at",
         "lockspire_registration_access_token_expires_at"
       ])}
    end
  end

  defp validate_body_client_id(metadata, %Client{client_id: client_id}) do
    if Map.get(metadata, "client_id") == client_id,
      do: :ok,
      else: invalid_metadata(:client_id, :unchanged_required)
  end

  defp reject_management_fields(metadata) do
    forbidden_fields = [
      {"registration_access_token", :registration_access_token},
      {"registration_client_uri", :registration_client_uri},
      {"client_secret_expires_at", :client_secret_expires_at},
      {"client_id_issued_at", :client_id_issued_at}
    ]

    case Enum.find(forbidden_fields, fn {field, _atom} -> Map.has_key?(metadata, field) end) do
      nil -> :ok
      {_field, atom} -> invalid_metadata(atom, :not_allowed)
    end
  end

  defp validate_included_client_secret(metadata, %Client{client_secret_hash: hash}) do
    case Map.fetch(metadata, "client_secret") do
      :error ->
        :ok

      {:ok, secret} when is_binary(secret) ->
        if Lockspire.Security.Policy.verify_client_secret(hash, secret),
          do: :ok,
          else: invalid_metadata(:client_secret, :does_not_match)

      {:ok, _other} ->
        invalid_metadata(:client_secret, :does_not_match)
    end
  end

  defp validate_lifecycle_extension(metadata, field, current, kind) do
    case Map.fetch(metadata, field) do
      :error ->
        :ok

      {:ok, supplied} when is_integer(supplied) ->
        with {:ok, deadline} <- effective_lifecycle_deadline(current, kind) do
          expected = if deadline, do: DateTime.to_unix(deadline, :second), else: 0

          if supplied == expected,
            do: :ok,
            else: invalid_metadata(lifecycle_extension_atom(kind), :cannot_be_changed)
        end

      {:ok, _other} ->
        invalid_metadata(lifecycle_extension_atom(kind), :cannot_be_changed)
    end
  end

  defp effective_lifecycle_deadline(current, :app), do: Client.effective_app_deadline(current)

  defp effective_lifecycle_deadline(current, :management),
    do: Client.effective_management_deadline(current)

  defp lifecycle_extension_atom(:app), do: :lockspire_client_expires_at

  defp lifecycle_extension_atom(:management),
    do: :lockspire_registration_access_token_expires_at

  defp invalid_metadata(field, reason),
    do:
      {:error, %Registration.Error{code: :invalid_client_metadata, field: field, reason: reason}}

  defp prepare_current(current, opts) do
    case Keyword.get(opts, :prepare) do
      nil -> {:ok, nil}
      prepare when is_function(prepare, 1) -> prepare.(current)
    end
  end

  defp with_current_client(client_id_from_url, %Client{} = snapshot, operation, opts, callback) do
    with {:ok, stores} <- ClientLifetime.configured() do
      stores.transaction_store.transact(fn ->
        with true <- client_id_from_url == snapshot.client_id,
             {:ok, [current]} <- stores.client_store.lock_clients([snapshot.client_id]),
             true <- current.id == snapshot.id,
             true <-
               current.registration_access_token_hash == snapshot.registration_access_token_hash,
             true <- current.active do
          # Retain preparation before the decision clock so every operation decides against
          # the final post-preparation instant. Defer returning preparation errors until the
          # credential deadline has been checked, so an expired credential cannot learn body
          # validation details.
          preparation = prepare_current(current, opts)

          with {:ok, now} <- decision_now(opts) do
            case Client.management_eligibility(current, now, :registration_management) do
              :ok ->
                with_prepared_current(current, operation, preparation, now, callback)

              {:error, :expired} ->
                {:error, :invalid_token}

              {:error, :invalid_lifetime_state} ->
                {:error,
                 %Registration.Error{code: :server_error, reason: :invalid_lifetime_state}}
            end
          end
        else
          false -> {:error, :invalid_token}
          {:ok, _rows} -> {:error, :invalid_token}
          {:error, %Registration.Error{} = error} -> {:error, error}
          {:error, reason} -> {:error, reason}
        end
      end)
    end
  end

  defp with_prepared_current(current, operation, preparation, now, callback) do
    case Client.app_eligibility(current, now, :registration_management) do
      :ok ->
        apply_prepared_current(current, now, preparation, callback)

      {:error, :expired} when operation in [:read, :delete] ->
        apply_prepared_current(current, now, preparation, callback)

      {:error, :expired} ->
        {:error, %Registration.Error{code: :registration_expired}}

      {:error, :disabled} ->
        {:error, :invalid_token}

      {:error, :invalid_lifetime_state} ->
        {:error, %Registration.Error{code: :server_error, reason: :invalid_lifetime_state}}
    end
  end

  defp apply_prepared_current(current, now, {:ok, prepared}, callback),
    do: callback.(current, now, prepared)

  defp apply_prepared_current(_current, _now, {:error, reason}, _callback), do: {:error, reason}

  defp apply_prepared_current(_current, _now, _unexpected, _callback),
    do: {:error, :invalid_token}

  defp with_recovery_client(%Client{} = snapshot, _opts, callback)
       when is_function(callback, 1) do
    with {:ok, stores} <- ClientLifetime.configured() do
      stores.transaction_store.transact(fn ->
        with {:ok, [current]} <- stores.client_store.lock_clients([snapshot.client_id]),
             true <- current.id == snapshot.id,
             true <- current.client_id == snapshot.client_id,
             true <-
               current.registration_access_token_hash == snapshot.registration_access_token_hash,
             {:ok, current} <- validate_recovery_lifetime(current) do
          callback.(current)
        else
          false -> {:error, :invalid_token}
          {:ok, _rows} -> {:error, :invalid_token}
          {:error, reason} -> {:error, reason}
        end
      end)
    end
  end

  # v0 dates are advisory by contract; credential replacement promotes the current
  # row and clears them. Unknown versions and malformed authoritative v1 state fail closed.
  defp validate_recovery_lifetime(%Client{lifetime_version: 0} = current), do: {:ok, current}

  defp validate_recovery_lifetime(%Client{} = current) do
    case ClientLifetime.validate_client(current) do
      {:ok, validated} -> {:ok, validated}
      {:error, _reason} -> {:error, :invalid_lifetime_state}
    end
  end

  defp decision_now(opts) do
    clock = Keyword.get(opts, :now, fn -> DateTime.utc_now() end)

    value =
      case clock do
        %DateTime{} = now -> now
        fun when is_function(fun, 0) -> fun.()
        _ -> :invalid_clock
      end

    case value do
      %DateTime{} = now ->
        case DateTime.from_unix(DateTime.to_unix(now, :second), :second) do
          {:ok, instant} -> {:ok, instant}
          {:error, _reason} -> invalid_clock()
        end

      _ ->
        invalid_clock()
    end
  rescue
    _error -> invalid_clock()
  catch
    _kind, _reason -> invalid_clock()
  end

  defp invalid_clock,
    do: {:error, %Registration.Error{code: :server_error, reason: :invalid_clock}}

  defp emit_updated(%Client{} = client) do
    Observability.emit(:dcr, :update, %{count: 1}, %{
      status: :success,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id
    })
  end

  defp emit_rat_rotated(client, actor \\ nil)

  defp emit_rat_rotated(%Client{} = client, nil) do
    emit_rat_rotated(client, %{type: :self_registered_client, id: client.client_id})
  end

  defp emit_rat_rotated(%Client{} = client, %{type: actor_type, id: actor_id}) do
    Observability.emit(:dcr, :rotate, %{count: 1}, %{
      status: :success,
      actor_type: actor_type,
      actor_id: actor_id,
      client_id: client.client_id
    })
  end

  defp emit_update_rejected(%Client{} = client, %Registration.Error{} = error) do
    Observability.emit(:dcr, :update, %{count: 1, rejected: 1}, %{
      status: :failure,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id: client.client_id,
      code: error.code,
      field: error.field,
      reason: error.reason
    })
  end

  defp emit_unauthorized(client_id_from_url, %Client{} = client) do
    Observability.emit(:dcr, :unauthorized, %{count: 1}, %{
      status: :failure,
      reason_code: :unauthorized,
      actor_type: :self_registered_client,
      actor_id: client.client_id,
      client_id_from_url: client_id_from_url,
      client_id: client.client_id
    })
  end
end
