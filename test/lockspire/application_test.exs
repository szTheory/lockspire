defmodule Lockspire.ApplicationTest do
  use ExUnit.Case, async: false

  alias Lockspire.Oban

  setup do
    original_env =
      for key <- [:repo, :oban], into: %{} do
        {key, Application.get_env(:lockspire, key)}
      end

    on_exit(fn ->
      Enum.each(original_env, fn {key, value} ->
        if is_nil(value) do
          Application.delete_env(:lockspire, key)
        else
          Application.put_env(:lockspire, key, value)
        end
      end)
    end)

    :ok
  end

  describe "start/2" do
    test "starts the Lockspire-owned Oban supervision child when valid queue config is present" do
      assert is_pid(Process.whereis(Lockspire.Oban))

      assert Enum.any?(Supervisor.which_children(Lockspire.Supervisor), fn
               {Lockspire.Oban, pid, :worker, [Lockspire.Oban]} when is_pid(pid) -> true
               _other -> false
             end)

      assert Oban.config!().repo == Lockspire.TestRepo
    end

    test "fails fast with a clear error when required Oban repo config is missing" do
      Application.delete_env(:lockspire, :repo)
      Application.put_env(:lockspire, :oban, [])

      assert_raise RuntimeError,
                   ~r/Lockspire\.Oban requires :lockspire repo config before startup/,
                   fn ->
                     Oban.runtime_config!()
                   end
    end

    test "fails fast with a clear error when Oban config shape is invalid for Lockspire startup" do
      Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
      Application.put_env(:lockspire, :oban, repo: :not_a_repo)

      assert_raise RuntimeError, ~r/invalid :lockspire, :oban config/, fn ->
        Oban.runtime_config!()
      end
    end
  end
end
