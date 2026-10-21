defmodule Lockspire.ClientLifetimeRaceHelpers do
  @moduledoc false

  alias Ecto.Adapters.SQL.Sandbox

  @default_timeout 5_000
  @poll_interval 10

  def start_session(repo, label, owner, fun) when is_function(fun, 1) do
    Task.async(fn ->
      Sandbox.unboxed_run(repo, fn ->
        backend_pid = backend_pid!(repo)
        send(owner, {:lifetime_race_session, label, self(), backend_pid})
        fun.(backend_pid)
      end)
    end)
  end

  def await_session!(label, timeout \\ @default_timeout) do
    receive do
      {:lifetime_race_session, ^label, task_pid, backend_pid} ->
        {task_pid, backend_pid}
    after
      timeout ->
        raise "timed out waiting for #{inspect(label)} PostgreSQL session"
    end
  end

  def backend_pid!(repo) do
    %{rows: [[pid]]} = repo.query!("SELECT pg_backend_pid()")
    pid
  end

  def await_blocker!(repo, contender_pid, expected_holder_pid, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    deadline = System.monotonic_time(:millisecond) + timeout
    poll_blocker(repo, contender_pid, expected_holder_pid, deadline)
  end

  def assert_available_nowait!(repo, query, params) when is_binary(query) and is_list(params) do
    Sandbox.unboxed_run(repo, fn ->
      repo.query!(query, params)
    end)

    :ok
  end

  def assert_locked_nowait!(repo, query, params) when is_binary(query) and is_list(params) do
    result =
      Sandbox.unboxed_run(repo, fn ->
        try do
          repo.query!(query, params)
          :unlocked
        rescue
          error in Postgrex.Error ->
            case error.postgres do
              %{code: :lock_not_available} -> :locked
              _ -> reraise error, __STACKTRACE__
            end
        end
      end)

    if result != :locked do
      raise "expected NOWAIT probe to fail with PostgreSQL lock_not_available, got #{inspect(result)}"
    end

    :ok
  end

  def release(pid, message \\ :release), do: send(pid, message)

  def barrier_clock(before_wait, after_wait) do
    stage = :atomics.new(1, [])
    clock = fn -> if :atomics.get(stage, 1) == 0, do: before_wait, else: after_wait end
    advance = fn -> :atomics.put(stage, 1, 1) end
    {clock, advance}
  end

  def await_task!(task, timeout \\ @default_timeout) do
    Task.await(task, timeout)
  catch
    :exit, {:timeout, _} ->
      Task.shutdown(task, :brutal_kill)
      raise "timed out waiting for PostgreSQL race task"
  end

  defp poll_blocker(repo, contender_pid, expected_holder_pid, deadline) do
    blockers = blocking_pids(repo, contender_pid)

    cond do
      blockers == [expected_holder_pid] ->
        :ok

      System.monotonic_time(:millisecond) >= deadline ->
        raise "expected contender #{contender_pid} to be blocked only by #{expected_holder_pid}; observed #{inspect(blockers)}"

      true ->
        Process.sleep(@poll_interval)
        poll_blocker(repo, contender_pid, expected_holder_pid, deadline)
    end
  end

  defp blocking_pids(repo, backend_pid) do
    Sandbox.unboxed_run(repo, fn ->
      %{rows: [[pids]]} = repo.query!("SELECT pg_blocking_pids($1)", [backend_pid])
      Enum.sort(pids)
    end)
  end
end
