defmodule Lockspire.KeyCache do
  @moduledoc """
  A GenServer that maintains a fast-read ETS table of active signing keys.
  """
  use GenServer
  require Logger

  alias Lockspire.Storage.Ecto.Repository

  @refresh_interval :timer.minutes(5)
  @table_name :lockspire_keys

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_key(kid) when is_binary(kid) do
    case :ets.lookup(@table_name, kid) do
      [{^kid, jose_jwk}] -> {:ok, jose_jwk}
      [] -> {:error, :not_found}
    end
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true])

    interval = Keyword.get(opts, :refresh_interval, @refresh_interval)

    send(self(), :refresh)

    if interval > 0 do
      :timer.send_interval(interval, :refresh)
    end

    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:refresh, state) do
    case Repository.list_active_keys() do
      {:ok, keys} ->
        objects =
          Enum.map(keys, fn key ->
            jose_jwk = JOSE.JWK.from_map(key.public_jwk)
            {key.kid, jose_jwk}
          end)

        # Update the ETS table
        # Find which keys are currently in ETS but no longer active
        current_kids = :ets.select(@table_name, [{{:"$1", :_}, [], [:"$1"]}])
        new_kids = Enum.map(keys, & &1.kid)

        :ets.insert(@table_name, objects)

        for kid <- current_kids, kid not in new_kids do
          :ets.delete(@table_name, kid)
        end

      {:error, reason} ->
        Logger.error("Failed to refresh KeyCache: #{inspect(reason)}")
    end

    {:noreply, state}
  end
end
