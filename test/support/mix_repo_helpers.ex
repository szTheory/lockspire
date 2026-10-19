defmodule Lockspire.MixRepoHelpers do
  @moduledoc false

  # Shared helpers for tests that run Lockspire Mix tasks against a stopped (cold) or already
  # running (warm) host repo. Temporary repo starts here are for test setup and cleanup only;
  # task code must go through Lockspire.Install.RepoRunner.

  import Ecto.Query
  import ExUnit.Assertions
  import ExUnit.CaptureIO

  alias Lockspire.Storage.Ecto.ClientRecord

  defmodule RaisingRepo do
    @moduledoc false
    def config, do: []
    def __adapter__, do: Ecto.Adapters.Postgres
    def start_link(_opts), do: raise(DBConnection.ConnectionError, "connection refused")
  end

  def assert_repo_stopped!(repo \\ Lockspire.TestRepo) do
    refute Process.whereis(repo),
           "#{inspect(repo)} is running; the task under test must start the repo itself"

    :ok
  end

  def with_temp_repo(fun) when is_function(fun, 0) do
    {:ok, _apps} = Application.ensure_all_started(:ecto_sql)

    {:ok, result, _apps} =
      Ecto.Migrator.with_repo(Lockspire.TestRepo, fn _repo -> fun.() end, mode: :temporary)

    result
  end

  def pool_fingerprint(repo) do
    %{name_pid: Process.whereis(repo), pool_pid: Ecto.Adapter.lookup_meta(repo).pid}
  end

  def assert_pool_untouched!(repo, fun) when is_function(fun, 0) do
    case Ecto.Adapters.SQL.Sandbox.checkout(repo) do
      :ok -> :ok
      {:already, _owner} -> :ok
    end

    repo.query!("CREATE TEMP TABLE IF NOT EXISTS lockspire_pool_probe (id integer)")
    repo.query!("INSERT INTO lockspire_pool_probe (id) VALUES (1)")

    before = pool_fingerprint(repo)
    name_ref = Process.monitor(before.name_pid)
    pool_ref = Process.monitor(before.pool_pid)

    result = fun.()

    assert pool_fingerprint(repo) == before
    refute_received {:DOWN, ^name_ref, :process, _, _}
    refute_received {:DOWN, ^pool_ref, :process, _, _}
    assert %{rows: [[1]]} = repo.query!("SELECT count(*) FROM lockspire_pool_probe")

    Process.demonitor(name_ref, [:flush])
    Process.demonitor(pool_ref, [:flush])
    result
  end

  def run_task(task, args), do: run_task(task, args, [])

  def run_task(task, args, extra_reenable) do
    Enum.each([task | extra_reenable], &Mix.Task.reenable/1)
    test_pid = self()

    output =
      capture_io(fn ->
        result =
          try do
            Mix.Task.run(task, args)
            :ok
          rescue
            error in Mix.Error -> {:error, error}
          end

        send(test_pid, {:mix_repo_helpers_task_result, result})
      end)

    assert_received {:mix_repo_helpers_task_result, result}
    {output, result}
  end

  def foreign_client_count(prefix_root) do
    pattern = prefix_root <> "%"

    with_temp_repo(fn ->
      Lockspire.TestRepo.aggregate(
        from(c in ClientRecord, where: not like(c.client_id, ^pattern)),
        :count
      )
    end)
  end

  def cleanup_clients_by_prefix!(prefix_root) do
    pattern = prefix_root <> "%"

    with_temp_repo(fn ->
      Lockspire.TestRepo.delete_all(from(c in ClientRecord, where: like(c.client_id, ^pattern)))
    end)
  end
end
