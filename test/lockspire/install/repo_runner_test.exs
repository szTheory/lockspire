defmodule Lockspire.Install.RepoRunnerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Install.RepoRunner

  defmodule RaisingRepo do
    def config, do: []
    def __adapter__, do: Ecto.Adapters.Postgres
    def start_link(_opts), do: raise(DBConnection.ConnectionError, "connection refused")
  end

  test "calls the function directly and keeps the pool when the repo is already running" do
    start_supervised!(Lockspire.TestRepo)

    assert {:ok, :ran} =
             Lockspire.MixRepoHelpers.assert_pool_untouched!(Lockspire.TestRepo, fn ->
               RepoRunner.run(Lockspire.TestRepo, fn repo ->
                 assert repo == Lockspire.TestRepo
                 :ran
               end)
             end)
  end

  test "starts a stopped repo temporarily and stops it afterwards" do
    refute Process.whereis(Lockspire.TestRepo)

    assert {:ok, true} =
             RepoRunner.run(Lockspire.TestRepo, fn _repo ->
               is_pid(Process.whereis(Lockspire.TestRepo))
             end)

    refute Process.whereis(Lockspire.TestRepo)
  end

  test "reports an unavailable repo without raising" do
    assert {:error, :repo_unavailable} = RepoRunner.run(Lockspire.NoSuchRepo, fn _ -> :ran end)
    assert {:error, :repo_unavailable} = RepoRunner.run(RaisingRepo, fn _ -> :ran end)
  end
end
