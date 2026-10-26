defmodule Lockspire.TestSupport.ClientVerifierMaintenanceConcurrency do
  @moduledoc false

  alias Ecto.Adapters.SQL.Sandbox

  def run(repo, parent, name, fun) when is_function(fun, 0) do
    Task.async(fn ->
      Sandbox.unboxed_run(repo, fn ->
        backend_pid = backend_pid(repo)
        send(parent, {:operation_ready, name, self(), backend_pid})
        result = fun.()
        send(parent, {:operation_done, name, result})
        result
      end)
    end)
  end

  def hold_transaction(repo, parent, name, fun) when is_function(fun, 0) do
    Task.async(fn ->
      Sandbox.unboxed_run(repo, fn ->
        backend_pid = backend_pid(repo)

        result =
          repo.transaction(fn ->
            send(parent, {:transaction_ready, name, self(), backend_pid})
            provisional = fun.()
            send(parent, {:transaction_provisional, name, provisional})

            receive do
              {:release_transaction, ^name, :commit} -> provisional
              {:release_transaction, ^name, {:rollback, reason}} -> repo.rollback(reason)
            after
              30_000 -> repo.rollback(:test_barrier_timeout)
            end
          end)

        send(parent, {:transaction_done, name, result})
        result
      end)
    end)
  end

  def wait_for_blocker(repo, contender_pid, blocker_pid, attempts \\ 100)
      when is_integer(contender_pid) and is_integer(blocker_pid) do
    blockers =
      Sandbox.unboxed_run(repo, fn ->
        %{rows: [[pids]]} =
          repo.query!("SELECT pg_blocking_pids($1)", [contender_pid],
            log: false,
            telemetry_event: nil
          )

        pids
      end)

    cond do
      blocker_pid in blockers ->
        {:ok, blockers}

      attempts > 0 ->
        Process.sleep(25)
        wait_for_blocker(repo, contender_pid, blocker_pid, attempts - 1)

      true ->
        {:error, blockers}
    end
  end

  def backend_pid(repo) do
    %{rows: [[pid]]} =
      repo.query!("SELECT pg_backend_pid()", [], log: false, telemetry_event: nil)

    pid
  end
end
