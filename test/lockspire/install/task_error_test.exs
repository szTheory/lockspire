defmodule Lockspire.Install.TaskErrorTest do
  use ExUnit.Case, async: false

  import Lockspire.MixRepoHelpers

  alias Lockspire.Install.TaskError
  alias Lockspire.MixRepoHelpers.RaisingRepo

  @missing_tables "the Lockspire tables are missing; run mix ecto.migrate, then rerun"

  describe "classify/1" do
    test "undefined_table maps to the migrate phrase" do
      assert TaskError.classify(%Postgrex.Error{postgres: %{code: :undefined_table}}) ==
               @missing_tables
    end

    test "another Postgres code shows the code name but not the message" do
      error = %Postgrex.Error{
        postgres: %{code: :unique_violation, message: "duplicate key value (secret-detail)"}
      }

      phrase = TaskError.classify(error)

      assert phrase ==
               "the database rejected the request (unique_violation); check the application logs"

      refute phrase =~ "secret-detail"
      refute phrase =~ "ecto.migrate"
    end

    test "undefined_column maps to the migrate phrase" do
      assert TaskError.classify(%Postgrex.Error{postgres: %{code: :undefined_column}}) ==
               @missing_tables
    end

    test "pool queue timeouts are not reported as unreachable" do
      error = %DBConnection.ConnectionError{
        message: "connection not available and request was dropped from queue after 50ms",
        reason: :queue_timeout
      }

      phrase = TaskError.classify(error)

      assert phrase ==
               "the database connection pool timed out; rerun, and if it fails again check database load and config :lockspire, :repo"

      refute phrase =~ "50ms"
    end

    test "connection errors become a fixed phrase without host details" do
      error = %DBConnection.ConnectionError{
        message: "tcp connect (localhost:5432): connection refused"
      }

      phrase = TaskError.classify(error)

      assert phrase ==
               "could not reach the database or it timed out; check database connectivity and config :lockspire, :repo"

      refute phrase =~ "localhost"
    end

    test "Lockspire config ArgumentErrors pass through" do
      for message <- [
            "missing Lockspire endpoint secret_key_base required for client_secret_jwt verifier material",
            "missing required config :repo for :lockspire. Set it in config/runtime.exs or config/*.exs."
          ] do
        assert TaskError.classify(%ArgumentError{message: message}) == message
      end
    end

    test "other ArgumentErrors are withheld" do
      error = %ArgumentError{
        message: "invalid argument %{client_secret: \"s3cr3t-attr\", redirect_uris: []}"
      }

      phrase = TaskError.classify(error)
      assert phrase == TaskError.unexpected_phrase()
      refute phrase =~ "s3cr3t-attr"
    end

    test "unwraps error tuples and handles repo_unavailable and unknown terms" do
      conn = %DBConnection.ConnectionError{message: "x"}
      assert TaskError.classify({:error, conn}) == TaskError.classify(conn)
      assert TaskError.classify(:repo_unavailable) == TaskError.repo_unavailable_phrase()
      assert TaskError.classify(:something_else) == TaskError.unexpected_phrase()
    end
  end

  describe "run/2" do
    test "a missing table raised inside the fun is a phrase, and the repo is stopped after" do
      assert_repo_stopped!()

      assert {:error, @missing_tables} =
               TaskError.run(Lockspire.TestRepo, fn repo ->
                 repo.query!("select 1 from lockspire_no_such_table")
               end)

      assert_repo_stopped!()
    end

    test "an exit inside the fun is not a repo-start failure (repo stopped)" do
      assert_repo_stopped!()

      assert {:error, phrase} =
               TaskError.run(Lockspire.TestRepo, fn _ ->
                 exit({:timeout, {GenServer, :call, [:pool, :checkout, 5000]}})
               end)

      assert phrase == TaskError.unexpected_phrase()
      refute phrase == TaskError.repo_unavailable_phrase()
      refute phrase =~ "timeout"
      refute phrase =~ "GenServer"
      assert_repo_stopped!()
    end

    test "a throw inside the fun is not a repo-start failure (repo stopped)" do
      assert_repo_stopped!()

      assert {:error, phrase} = TaskError.run(Lockspire.TestRepo, fn _ -> throw(:boom) end)
      assert phrase == TaskError.unexpected_phrase()
      refute phrase == TaskError.repo_unavailable_phrase()
      assert_repo_stopped!()
    end

    test "an exit inside the fun is not a repo-start failure (repo running)" do
      start_supervised!(Lockspire.TestRepo)

      assert {:error, phrase} =
               TaskError.run(Lockspire.TestRepo, fn _ -> exit(:shutdown_probe) end)

      assert phrase == TaskError.unexpected_phrase()
      refute phrase == TaskError.repo_unavailable_phrase()
    end

    test "a repo that cannot start returns the repo-unavailable phrase" do
      assert {:error, phrase} = TaskError.run(RaisingRepo, fn _ -> :ran end)
      assert phrase == TaskError.repo_unavailable_phrase()
    end

    test "returns the fun's value" do
      assert {:ok, :done} = TaskError.run(Lockspire.TestRepo, fn _ -> :done end)
    end

    test "the process log level is restored: nil stays nil" do
      Logger.delete_process_level(self())

      assert {:ok, :warning} =
               TaskError.run(Lockspire.TestRepo, fn _ -> Logger.get_process_level(self()) end)

      assert Logger.get_process_level(self()) == nil
    end

    test "the process log level is restored: :warning stays :warning" do
      Logger.put_process_level(self(), :warning)
      on_exit(fn -> Logger.delete_process_level(self()) end)

      assert {:ok, :warning} =
               TaskError.run(Lockspire.TestRepo, fn _ -> Logger.get_process_level(self()) end)

      assert Logger.get_process_level(self()) == :warning
    end
  end
end
