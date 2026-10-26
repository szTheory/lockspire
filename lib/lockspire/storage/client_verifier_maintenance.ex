defmodule Lockspire.Storage.ClientVerifierMaintenance do
  @moduledoc """
  Optional, verifier-only custody maintenance for a selected client store.

  The adapter declaration binds inventory and compare-and-rewrap callbacks to
  the same client, transaction, and audit participants selected by the host.
  """

  alias Lockspire.Config, as: HostConfig
  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Storage.ClientLifetime

  @type declaration :: %{
          version: 1,
          transaction_authority: map(),
          participants: %{
            client_store: module(),
            transaction_store: module(),
            audit_store: module()
          }
        }

  @callback verifier_maintenance_contract() ::
              {:ok, declaration()}
              | {:error,
                 :client_secret_verifier_maintenance_unsupported
                 | :client_secret_verifier_maintenance_authority_mismatch}
  @callback verifier_inventory_page(nil | String.t(), pos_integer()) ::
              {:ok, %{clients: [Client.t()], next_cursor: String.t() | nil, complete?: boolean()}}
              | {:error, atom()}
  @callback compare_and_rewrap(
              String.t(),
              String.t(),
              String.t(),
              String.t(),
              map()
            ) :: {:ok, :changed | :already_current | :material_conflict} | {:error, atom()}

  defmodule MaintenanceConfig do
    @enforce_keys [:client_store, :transaction_store, :audit_store, :authority]
    defstruct [:client_store, :transaction_store, :audit_store, :authority]

    @type t :: %__MODULE__{
            client_store: module(),
            transaction_store: module(),
            audit_store: module(),
            authority: map()
          }
  end

  @doc false
  @spec configured() :: {:ok, MaintenanceConfig.t()} | {:error, atom()}
  def configured do
    selected_client_store = HostConfig.client_store()
    selected_transaction_store = HostConfig.transaction_store()

    with :ok <- ensure_maintenance_callbacks(selected_client_store),
         {:ok, lifetime} <- ClientLifetime.configured(),
         true <- lifetime.client_store == selected_client_store,
         {:ok, authority} <- transaction_authority(selected_transaction_store),
         true <- authority == lifetime.transaction_authority,
         {:ok, declaration} <- selected_client_store.verifier_maintenance_contract(),
         :ok <-
           validate_declaration(
             declaration,
             selected_client_store,
             selected_transaction_store,
             authority
           ) do
      {:ok,
       %MaintenanceConfig{
         client_store: selected_client_store,
         transaction_store: selected_transaction_store,
         audit_store: declaration.participants.audit_store,
         authority: authority
       }}
    else
      false -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
      {:error, :client_secret_verifier_maintenance_unsupported} = error -> error
      {:error, :client_secret_verifier_maintenance_authority_mismatch} = error -> error
      {:error, _reason} -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
      _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
  catch
    _, _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
  end

  @doc false
  @spec rewrap_client(String.t(), keyword()) ::
          {:ok, :changed | :already_current | :material_conflict}
          | {:error, atom()}
  def rewrap_client(client_id, opts \\ [])

  def rewrap_client(client_id, opts) when is_binary(client_id) and is_list(opts) do
    context = HostConfig.client_secret_verifier_context(opts)

    with {:ok, config} <- configured(),
         {:ok, context} <- validate_context(context),
         {:ok, %Client{} = client} <- fetch_client(config.client_store, client_id),
         hash when is_binary(hash) <- client.client_secret_hash,
         verifier when is_binary(verifier) <- client.client_secret_jwt_verifier_encrypted,
         {:ok, outcome} <- run_rewrap(config, context, client, hash, verifier) do
      {:ok, outcome}
    else
      {:ok, nil} ->
        {:error, :client_secret_verifier_client_not_found}

      {:error, reason}
      when reason in [
             :client_secret_verifier_maintenance_unsupported,
             :client_secret_verifier_maintenance_authority_mismatch,
             :client_secret_verifier_client_not_found,
             :client_secret_verifier_maintenance_failed
           ] ->
        {:error, reason}

      _ ->
        {:error, :client_secret_verifier_maintenance_failed}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_failed}
  catch
    _, _ -> {:error, :client_secret_verifier_maintenance_failed}
  end

  def rewrap_client(_client_id, _opts),
    do: {:error, :client_secret_verifier_maintenance_failed}

  defp run_rewrap(config, context, client, expected_hash, expected_verifier) do
    with {:ok, replacement, audit_attrs} <-
           rewrap_material(context, client, expected_hash, expected_verifier),
         {:ok, outcome} <-
           config.transaction_store.transact(fn ->
             config.client_store.compare_and_rewrap(
               client.client_id,
               expected_hash,
               expected_verifier,
               replacement,
               audit_attrs
             )
           end),
         true <- outcome in [:changed, :already_current, :material_conflict] do
      {:ok, outcome}
    else
      {:error, reason}
      when reason in [
             :client_secret_verifier_maintenance_unsupported,
             :client_secret_verifier_maintenance_authority_mismatch,
             :client_secret_verifier_client_not_found,
             :client_secret_verifier_maintenance_failed
           ] ->
        {:error, reason}

      _ ->
        {:error, :client_secret_verifier_maintenance_failed}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_failed}
  catch
    _, _ -> {:error, :client_secret_verifier_maintenance_failed}
  end

  defp rewrap_material(context, client, expected_hash, expected_verifier) do
    with {:ok, replacement_or_current, old_key_id, new_key_id} <-
           ClientSecretVerifier.rewrap_native(
             context,
             client.client_id,
             expected_hash,
             expected_verifier
           ) do
      replacement =
        if replacement_or_current == :already_current,
          do: expected_verifier,
          else: replacement_or_current

      {:ok, replacement,
       audit_attrs(client.client_id, old_key_id, new_key_id, DateTime.utc_now())}
    else
      {:error, :client_secret_verifier_key_unknown} ->
        {:error, :client_secret_verifier_maintenance_failed}

      {:error, _reason} ->
        {:error, :client_secret_verifier_maintenance_failed}

      _ ->
        {:error, :client_secret_verifier_maintenance_failed}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_failed}
  end

  defp audit_attrs(client_id, old_key_id, new_key_id, now) do
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{old_key_id: old_key_id, new_key_id: new_key_id, maintenance_at: now}
    }
  end

  defp fetch_client(client_store, client_id) do
    case client_store.fetch_client_by_id(client_id) do
      {:ok, client} -> {:ok, client}
      {:error, _reason} -> {:error, :client_secret_verifier_maintenance_failed}
      _ -> {:error, :client_secret_verifier_maintenance_failed}
    end
  end

  defp validate_context(context) do
    case Lockspire.Security.ClientSecretVerifier.Context.validate(context) do
      {:ok,
       %Lockspire.Security.ClientSecretVerifier.Context{state: :valid, write_mode: :dedicated} =
           valid} ->
        {:ok, valid}

      _ ->
        {:error, :client_secret_verifier_maintenance_failed}
    end
  end

  defp transaction_authority(transaction_store) when is_atom(transaction_store) do
    if function_exported?(transaction_store, :transaction_authority, 0) do
      case transaction_store.transaction_authority() do
        %{identity: identity, participants: participants} = authority
        when not is_nil(identity) and is_map(participants) ->
          {:ok, authority}

        _ ->
          {:error, :client_secret_verifier_maintenance_authority_mismatch}
      end
    else
      {:error, :client_secret_verifier_maintenance_authority_mismatch}
    end
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
  end

  defp transaction_authority(_),
    do: {:error, :client_secret_verifier_maintenance_authority_mismatch}

  defp ensure_maintenance_callbacks(client_store) when is_atom(client_store) do
    _ = Code.ensure_loaded?(client_store)

    if function_exported?(client_store, :verifier_maintenance_contract, 0) and
         function_exported?(client_store, :verifier_inventory_page, 2) and
         function_exported?(client_store, :compare_and_rewrap, 5) do
      :ok
    else
      {:error, :client_secret_verifier_maintenance_unsupported}
    end
  end

  defp ensure_maintenance_callbacks(_),
    do: {:error, :client_secret_verifier_maintenance_unsupported}

  defp validate_declaration(
         %{version: 1, transaction_authority: authority, participants: participants},
         client_store,
         transaction_store,
         selected_authority
       )
       when is_map(participants) do
    audit_store = Map.get(participants, :audit_store)

    selected_participants = %{
      client_store: client_store,
      transaction_store: transaction_store,
      audit_store: audit_store
    }

    with true <- authority == selected_authority,
         true <- participants == selected_participants,
         true <- Map.get(authority, :participants, %{})[:client_store] == client_store,
         true <- Map.get(authority, :participants, %{})[:transaction_store] == transaction_store,
         true <- is_atom(audit_store),
         true <- Map.get(authority, :participants, %{})[:audit_store] == audit_store,
         true <- Code.ensure_loaded?(audit_store),
         true <- function_exported?(audit_store, :append_audit_event, 1) do
      :ok
    else
      _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
    end
  end

  defp validate_declaration(_, _, _, _),
    do: {:error, :client_secret_verifier_maintenance_authority_mismatch}
end
