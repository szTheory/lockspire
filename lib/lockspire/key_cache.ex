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
  @snapshot_marker :lockspire_keys_snapshot_state

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def get_key(kid) when is_binary(kid) do
    get_key(kid, @table_name)
  end

  @doc false
  def get_key(kid, table_name) when is_binary(kid) and is_atom(table_name) do
    case lookup_key(table_name, kid) do
      {:ok, _jose_jwk} = result ->
        result

      :not_found ->
        case snapshot_status(table_name) do
          :warm -> {:error, :not_found}
          :pending -> {:error, :not_found}
          :disabled -> {:error, :not_found}
          :cold -> cold_lookup(table_name, kid)
        end
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
    initial_refresh? = Keyword.get(opts, :initial_refresh?, true)

    :ets.insert(table_name, {@snapshot_marker, if(initial_refresh?, do: :cold, else: :disabled)})

    if initial_refresh?, do: send(self(), :initial_refresh)

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
       repository_was_ready?: false,
       initial_refresh?: initial_refresh?,
       snapshot_warmed?: false,
       cold_lookup_attempted?: false,
       retry_token: nil,
       retry_timer: nil
     }}
  end

  @impl true
  def handle_call({:cold_lookup, kid, table_name}, _from, %{table_name: table_name} = state)
      when is_binary(kid) do
    case lookup_key(table_name, kid) do
      {:ok, jose_jwk} ->
        {:reply, {:ok, jose_jwk}, state}

      :not_found when state.snapshot_warmed? or not state.initial_refresh? ->
        {:reply, {:error, :not_found}, state}

      :not_found when state.cold_lookup_attempted? ->
        {:reply, {:error, :not_found}, state}

      :not_found ->
        if ready_for_snapshot?(state) do
          state = refresh_keys(%{state | cold_lookup_attempted?: true})
          {:reply, normalize_lookup(lookup_key(table_name, kid)), state}
        else
          :ets.insert(table_name, {@snapshot_marker, :pending})
          state = %{state | cold_lookup_attempted?: true}
          {:reply, {:error, :not_found}, schedule_retry(state)}
        end
    end
  end

  def handle_call(_request, _from, state), do: {:reply, {:error, :not_found}, state}

  @impl true
  def handle_info(:initial_refresh, %{retry_token: token} = state) when not is_nil(token),
    do: {:noreply, state}

  def handle_info(:initial_refresh, %{snapshot_warmed?: true} = state), do: {:noreply, state}

  def handle_info(:initial_refresh, state) do
    if defer_initial_refresh?(state) do
      {:noreply, schedule_retry(state)}
    else
      {:noreply, refresh_keys(state)}
    end
  end

  def handle_info(:refresh, state) do
    if defer_initial_refresh?(state) do
      {:noreply, schedule_retry(state)}
    else
      {:noreply, refresh_keys(state)}
    end
  end

  def handle_info({:retry_refresh, token}, state) do
    if token == state.retry_token do
      state = %{state | retry_token: nil, retry_timer: nil}

      if defer_initial_refresh?(state) do
        {:noreply, schedule_retry(state)}
      else
        {:noreply, refresh_keys(state)}
      end
    else
      {:noreply, state}
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp refresh_keys(state) do
    case load_snapshot(state) do
      {:ok, state} ->
        cancel_retry(state)

      {:error, state} ->
        state.failure_reporter.(:key_storage_unavailable)
        state = %{state | repository_was_ready?: true}

        if state.initial_refresh? and not state.snapshot_warmed? do
          :ets.insert(state.table_name, {@snapshot_marker, :pending})
          schedule_retry(%{state | cold_lookup_attempted?: true})
        else
          state
        end
    end
  end

  defp load_snapshot(state) do
    case state.loader.() do
      {:ok, keys} ->
        objects =
          Enum.map(keys, fn key ->
            {key.kid, JOSE.JWK.from_map(key.public_jwk)}
          end)

        current_kids =
          :ets.select(state.table_name, [{{:"$1", :_}, [{:is_binary, :"$1"}], [:"$1"]}])

        new_kids = Enum.map(keys, & &1.kid)
        :ets.insert(state.table_name, objects)

        for kid <- current_kids, kid not in new_kids do
          :ets.delete(state.table_name, kid)
        end

        :ets.insert(state.table_name, {@snapshot_marker, :warm})

        {:ok,
         %{
           state
           | repository_was_ready?: true,
             snapshot_warmed?: true,
             cold_lookup_attempted?: false
         }}

      {:error, _reason} ->
        {:error, state}
    end
  end

  defp defer_initial_refresh?(%{repository_was_ready?: true}), do: false

  defp defer_initial_refresh?(state), do: not ready_for_snapshot?(state)

  defp schedule_retry(%{retry_token: token} = state) when not is_nil(token), do: state

  defp schedule_retry(state) do
    token = make_ref()
    delay = max(state.initial_retry_interval, 1)
    timer = Process.send_after(self(), {:retry_refresh, token}, delay)
    %{state | retry_token: token, retry_timer: timer}
  end

  defp cancel_retry(state) do
    if state.retry_timer, do: Process.cancel_timer(state.retry_timer)
    %{state | retry_token: nil, retry_timer: nil}
  end

  defp ready_for_snapshot?(state) do
    state.ready?.() == true
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  defp lookup_key(table_name, kid) do
    case :ets.lookup(table_name, kid) do
      [{^kid, jose_jwk}] -> {:ok, jose_jwk}
      _ -> :not_found
    end
  rescue
    ArgumentError -> :not_found
  end

  defp snapshot_status(table_name) do
    case :ets.lookup(table_name, @snapshot_marker) do
      [{@snapshot_marker, :warm}] -> :warm
      [{@snapshot_marker, :pending}] -> :pending
      [{@snapshot_marker, :disabled}] -> :disabled
      _ -> :cold
    end
  rescue
    ArgumentError -> :disabled
  end

  defp cold_lookup(table_name, kid) do
    case :ets.info(table_name, :owner) do
      owner when is_pid(owner) and owner != self() ->
        try do
          GenServer.call(owner, {:cold_lookup, kid, table_name})
        catch
          :exit, _ -> {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  rescue
    ArgumentError -> {:error, :not_found}
  end

  defp normalize_lookup({:ok, _jose_jwk} = result), do: result
  defp normalize_lookup(:not_found), do: {:error, :not_found}

  defp repository_ready?(repo) when is_atom(repo), do: is_pid(Process.whereis(repo))
  defp repository_ready?(_repo), do: false

  defp log_refresh_failure(:key_storage_unavailable) do
    Logger.error("Failed to refresh KeyCache: key storage unavailable")
  end
end
