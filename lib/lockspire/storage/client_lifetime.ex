defmodule Lockspire.Storage.ClientLifetime do
  @moduledoc """
  Validated lifetime support declared by a client storage adapter.

  Adapter declarations are checked once at the host boundary. Protocol consumers
  receive this typed value instead of discovering adapter callbacks themselves.
  """

  alias Lockspire.Domain.Client

  @enforce_keys [:contract_version, :client_store, :transaction_authority]
  defstruct [:contract_version, :client_store, :transaction_authority]

  @type t :: %__MODULE__{
          contract_version: 1,
          client_store: module(),
          transaction_authority: term()
        }

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
