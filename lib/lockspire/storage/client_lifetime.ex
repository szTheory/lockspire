defmodule Lockspire.Storage.ClientLifetime do
  @moduledoc """
  Validated lifetime support declared by a client storage adapter.

  Adapter declarations are checked once at the host boundary. Protocol consumers
  receive this typed value instead of discovering adapter callbacks themselves.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Config
  alias Lockspire.Storage.Ecto.Repository

  @enforce_keys [:contract_version, :client_store, :transaction_authority]
  defstruct [:contract_version, :client_store, :transaction_authority]

  @type t :: %__MODULE__{
          contract_version: 1,
          client_store: module(),
          transaction_authority: term()
        }

  @doc false
  @spec configured() ::
          {:ok,
           %{
             client_store: module(),
             transaction_store: module(),
             transaction_authority: map(),
             lifetime: t()
           }}
          | {:error, atom()}
  def configured do
    client_store = Config.client_store()
    transaction_store = Config.transaction_store()

    with :ok <- ensure_callbacks(client_store, client_callbacks()),
         :ok <- ensure_callbacks(transaction_store, transaction_callbacks()),
         {:ok, authority} <- transaction_authority(transaction_store),
         :ok <- validate_selected_participants(authority, client_store, transaction_store),
         {:ok, lifetime} <- adapt(client_store, authority) do
      {:ok,
       %{
         client_store: client_store,
         transaction_store: transaction_store,
         transaction_authority: authority,
         lifetime: lifetime
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    _error -> {:error, :client_lifetime_configuration_unavailable}
  catch
    _kind, _reason -> {:error, :client_lifetime_configuration_unavailable}
  end

  defp transaction_authority(transaction_store) when is_atom(transaction_store) do
    _ = Code.ensure_loaded?(transaction_store)
    authority = transaction_store.transaction_authority()

    case authority do
      %{identity: identity, participants: participants}
      when not is_nil(identity) and is_map(participants) ->
        if Enum.all?(participants, fn {role, store} -> is_atom(role) and is_atom(store) end),
          do: {:ok, authority},
          else: {:error, :invalid_transaction_authority}

      _ ->
        {:error, :invalid_transaction_authority}
    end
  rescue
    _error -> {:error, :transaction_authority_unavailable}
  end

  defp transaction_authority(_transaction_store),
    do: {:error, :transaction_authority_unavailable}

  defp validate_selected_participants(
         %{participants: participants},
         client_store,
         transaction_store
       ) do
    required = %{
      client_store: client_store,
      transaction_store: transaction_store,
      token_store: Repository,
      device_authorization_store: Repository,
      ciba_authorization_store: Repository,
      audit_store: Repository
    }

    if Enum.all?(required, fn {role, store} -> Map.get(participants, role) == store end),
      do: :ok,
      else: {:error, :transaction_authority_mismatch}
  end

  defp ensure_callbacks(module, callbacks) when is_atom(module) do
    _ = Code.ensure_loaded?(module)

    if Enum.all?(callbacks, fn {name, arity} -> function_exported?(module, name, arity) end),
      do: :ok,
      else: {:error, :client_lifetime_callback_unavailable}
  end

  defp ensure_callbacks(_module, _callbacks),
    do: {:error, :client_lifetime_callback_unavailable}

  defp client_callbacks do
    [
      {:lifetime_contract, 0},
      {:fetch_client_by_id, 1},
      {:get_client_by_registration_access_token_hash, 1},
      {:lock_clients, 1},
      {:register_client, 1},
      {:replace_client_registration, 4},
      {:rotate_registration_access_token, 3},
      {:rotate_client_secret, 4},
      {:set_client_active, 3}
    ]
  end

  defp transaction_callbacks, do: [{:transaction_authority, 0}, {:transact, 1}, {:rollback, 1}]

  @doc """
  Adapts an adapter-owned v1 declaration and verifies it names the selected
  transaction authority and exports the current-row guard callback.
  """
  @spec adapt(module(), term()) :: {:ok, t()} | {:error, atom()}
  def adapt(client_store, expected_authority) when is_atom(client_store) do
    _ = Code.ensure_loaded?(client_store)
    declaration = client_store.lifetime_contract()

    cond do
      not is_map(declaration) ->
        {:error, :invalid_client_lifetime_declaration}

      Map.get(declaration, :version) != 1 ->
        {:error, :unsupported_client_lifetime_version}

      not function_exported?(client_store, :lock_clients, 1) ->
        {:error, :client_store_guard_unavailable}

      not valid_authority?(Map.get(declaration, :transaction_authority)) ->
        {:error, :transaction_authority_unavailable}

      Map.get(declaration, :transaction_authority) != expected_authority ->
        {:error, :transaction_authority_mismatch}

      true ->
        {:ok,
         %__MODULE__{
           contract_version: 1,
           client_store: client_store,
           transaction_authority: expected_authority
         }}
    end
  rescue
    _error -> {:error, :client_lifetime_declaration_unavailable}
  end

  def adapt(_client_store, _expected_authority),
    do: {:error, :invalid_client_lifetime_adapter}

  @doc "Validates rotation support only when a caller requests secret replacement."
  @spec ensure_secret_rotation_available(module()) ::
          :ok | {:error, :client_secret_rotation_unavailable}
  def ensure_secret_rotation_available(client_store) when is_atom(client_store) do
    _ = Code.ensure_loaded?(client_store)

    if function_exported?(client_store, :rotate_client_secret, 4),
      do: :ok,
      else: {:error, :client_secret_rotation_unavailable}
  end

  def ensure_secret_rotation_available(_client_store),
    do: {:error, :client_secret_rotation_unavailable}

  @doc "Validates explicit lifetime state returned by an adapted client store."
  @spec validate_client(Client.t() | term()) :: {:ok, Client.t()} | {:error, atom()}
  def validate_client(%Client{lifetime_version: 0} = client) do
    if is_nil(client.client_expires_at) and
         is_nil(client.registration_access_token_expires_at) do
      {:ok, client}
    else
      {:error, :invalid_legacy_lifetime_state}
    end
  end

  def validate_client(%Client{lifetime_version: 1} = client) do
    if valid_deadline?(client.client_expires_at) and
         valid_deadline?(client.registration_access_token_expires_at) and
         valid_deadline?(client.client_secret_expires_at) do
      {:ok, client}
    else
      {:error, :invalid_authoritative_lifetime_state}
    end
  end

  def validate_client(%Client{}), do: {:error, :invalid_lifetime_version}
  def validate_client(_client), do: {:error, :invalid_lifetime_client}

  defp valid_deadline?(nil), do: true

  defp valid_deadline?(%DateTime{time_zone: zone, microsecond: {0, _precision}})
       when zone in ["Etc/UTC", "UTC"],
       do: true

  defp valid_deadline?(_deadline), do: false

  defp valid_authority?(%{identity: identity, participants: participants})
       when not is_nil(identity) and is_map(participants) do
    Enum.all?(participants, fn {role, store} -> is_atom(role) and is_atom(store) end)
  end

  defp valid_authority?(_authority), do: false
end
