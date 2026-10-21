defmodule Lockspire.Integration.AppLifetimeMigrationTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox

  @moduletag :integration

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "the installed expansion has a constant v0 default and nullable authoritative dates" do
    result =
      Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
        Lockspire.TestRepo.query!("""
        SELECT column_name, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'lockspire_clients'
          AND column_name IN ('lifetime_version', 'client_expires_at', 'registration_access_token_expires_at')
        ORDER BY column_name
        """)
      end)

    assert result.rows == [
             ["client_expires_at", "YES", nil],
             ["lifetime_version", "NO", "0"],
             ["registration_access_token_expires_at", "YES", nil]
           ]
  end

  test "actual PostgreSQL DDL lock timeout fails boundedly and succeeds after release" do
    parent = self()
    column = "lockspire_plan13_ddl_probe"

    holder =
      Task.async(fn ->
        Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
          Lockspire.TestRepo.transaction(fn ->
            Lockspire.TestRepo.query!("LOCK TABLE public.lockspire_clients IN ACCESS SHARE MODE")
            %{rows: [[backend_pid]]} = Lockspire.TestRepo.query!("SELECT pg_backend_pid()")
            send(parent, {:ddl_holder_ready, self(), backend_pid})

            receive do
              :release_ddl_holder -> :ok
            after
              5_000 -> raise "DDL holder release timed out"
            end
          end)
        end)
      end)

    assert_receive {:ddl_holder_ready, holder_task_pid, _holder_backend_pid}, 5_000
    started = System.monotonic_time(:millisecond)

    error =
      Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
        try do
          Lockspire.TestRepo.transaction(fn ->
            Lockspire.TestRepo.query!("SET LOCAL lock_timeout = '250ms'")

            Lockspire.TestRepo.query!(
              "ALTER TABLE public.lockspire_clients ADD COLUMN #{column} integer"
            )
          end)

          flunk("ALTER TABLE should wait for the held ACCESS SHARE lock")
        rescue
          error in Postgrex.Error -> error
        end
      end)

    elapsed = System.monotonic_time(:millisecond) - started
    assert error.postgres.code == :lock_not_available
    assert elapsed < 2_000
    send(holder_task_pid, :release_ddl_holder)
    assert {:ok, :ok} = Task.await(holder, 5_000)

    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.query!(
        "ALTER TABLE public.lockspire_clients ADD COLUMN #{column} integer"
      )

      Lockspire.TestRepo.query!("ALTER TABLE public.lockspire_clients DROP COLUMN #{column}")
    end)
  end
end
