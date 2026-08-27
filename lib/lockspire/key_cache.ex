defmodule Lockspire.KeyCache do
  @moduledoc """
  A GenServer that maintains a fast-read ETS table of active signing keys.
  """
  use GenServer
  require Logger

  alias Lockspire.Storage.Ecto.Repository

  @refresh_interval :timer.minutes(5)
  @initial_retry_interval :timer.seconds(1)
  @table_name :lockspire_keys

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def get_key(kid) when is_binary(kid) do
    get_key(kid, @table_name)
  end

  @doc false
  def get_key(kid, table_name) when is_binary(kid) and is_atom(table_name) do
    case :ets.lookup(table_name, kid) do
      [{^kid, jose_jwk}] -> {:ok, jose_jwk}
      [] -> {:error, :not_found}
    end
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    table_name = Keyword.get(opts, :table_name, @table_name)
    :ets.new(table_name, [:set, :named_table, :public, read_concurrency: true])

    interval = Keyword.get(opts, :refresh_interval, @refresh_interval)
    initial_retry_interval = Keyword.get(opts, :initial_retry_interval, @initial_retry_interval)
    repo = Keyword.get(opts, :repo, Application.get_env(:lockspire, :repo))

    if Keyword.get(opts, :initial_refresh?, true), do: send(self(), :refresh)

    if interval > 0 do
      :timer.send_interval(interval, :refresh)
    end

    {:ok,
     %{
       interval: interval,
       initial_retry_interval: initial_retry_interval,
       loader: Keyword.get(opts, :loader, &Repository.list_active_keys/0),
       failure_reporter: Keyword.get(opts, :failure_reporter, &log_refresh_failure/1),
       ready?: Keyword.get(opts, :ready?, fn -> repository_ready?(repo) end),
       table_name: table_name,
       repository_was_ready?: false
     }}
  end

  @impl true
  def handle_info(:refresh, state) do
    if defer_initial_refresh?(state) do
      {:noreply, schedule_initial_retry(state)}
    else
      refresh_keys(state)
    end
  end

  defp refresh_keys(state) do
    case state.loader.() do
      {:ok, keys} ->
        objects =
          Enum.map(keys, fn key ->
            jose_jwk = JOSE.JWK.from_map(key.public_jwk)
            {key.kid, jose_jwk}
          end)

        # Update the ETS table
        # Find which keys are currently in ETS but no longer active
        current_kids = :ets.select(state.table_name, [{{:"$1", :_}, [], [:"$1"]}])
        new_kids = Enum.map(keys, & &1.kid)

        :ets.insert(state.table_name, objects)

        for kid <- current_kids, kid not in new_kids do
          :ets.delete(state.table_name, kid)
        end

        {:noreply, %{state | repository_was_ready?: true}}

      {:error, reason} ->
        _ = reason
        state.failure_reporter.(:key_storage_unavailable)
        {:noreply, %{state | repository_was_ready?: true}}
    end
  end

  defp defer_initial_refresh?(%{repository_was_ready?: true}), do: false

  defp defer_initial_refresh?(state), do: not state.ready?.()

  defp schedule_initial_retry(state) do
    Process.send_after(self(), :refresh, state.initial_retry_interval)
    state
  end

  defp repository_ready?(repo) when is_atom(repo), do: is_pid(Process.whereis(repo))
  defp repository_ready?(_repo), do: false

  defp log_refresh_failure(:key_storage_unavailable) do
    Logger.error("Failed to refresh KeyCache: key storage unavailable")
  end
end
