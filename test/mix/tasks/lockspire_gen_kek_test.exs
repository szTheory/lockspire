defmodule Mix.Tasks.Lockspire.GenKekTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  alias Lockspire.Generators.KekSnippet
  alias Lockspire.Security.KeyEncryption.KeySet

  @task "lockspire.gen.kek"
  @forbidden ~r/\b(phase|plan|wave|D-\d+|MIG-\d+|OPS-\d+|SAFE-\d+)\b/i

  setup do
    Mix.Task.reenable(@task)
    on_exit(fn -> Mix.Task.reenable(@task) end)
    :ok
  end

  defp run_task(args) do
    capture_io(fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, args)
    end)
  end

  describe "KeySet.valid_id?/1" do
    test "accepts allowed ids up to 32 characters" do
      assert KeySet.valid_id?("2026-01")
      assert KeySet.valid_id?(String.duplicate("a", 32))
    end

    test "rejects everything else" do
      for bad <- [String.duplicate("a", 33), "", "bad id", "a\"b", "a\nb", nil, :atom] do
        refute KeySet.valid_id?(bad)
      end
    end

    test "KeySet.new/1 still rejects an id with a space" do
      key = KekSnippet.generate_key()

      assert {:error, {:keys, :invalid_key_id}} =
               KeySet.new(keys: [{"bad id", key}], current: "bad id")
    end
  end

  describe "KekSnippet" do
    test "generate_key/0 is 44 chars of base64 over 32 bytes and differs per call" do
      key = KekSnippet.generate_key()
      assert byte_size(key) == 44
      assert byte_size(Base.decode64!(key)) == 32
      refute key == KekSnippet.generate_key()
    end

    test "default_id/0 is the UTC year and month" do
      assert KekSnippet.default_id() == Calendar.strftime(DateTime.utc_now(), "%Y-%m")
      assert KekSnippet.default_id() =~ ~r/\A\d{4}-\d{2}\z/
    end

    test "prod_block/2 is valid Elixir and names the generator in its raise text" do
      block = KekSnippet.prod_block("2026-01")
      assert {:ok, _} = Code.string_to_quoted(block)
      assert block =~ "mix lockspire.gen.kek"
      assert block =~ ~s{System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") ||}
    end

    test "prod_block/2 indents non-empty lines" do
      assert KekSnippet.prod_block("2026-01", 2) =~ "  if config_env() == :prod do"
    end

    test "prod_block/2 rejects an invalid id without echoing it" do
      error = assert_raise ArgumentError, fn -> KekSnippet.prod_block("bad id") end
      refute error.message =~ "bad id"
    end
  end

  describe "--raw" do
    test "prints exactly one valid key line" do
      output = run_task(["--raw"])
      assert [value] = output |> String.trim() |> String.split("\n")
      assert byte_size(value) == 44
      assert byte_size(Base.decode64!(value)) == 32
      id = KekSnippet.default_id()
      assert {:ok, _} = KeySet.new(keys: [{id, value}], current: id)
    end

    test "two runs print different values" do
      refute run_task(["--raw"]) == run_task(["--raw"])
    end

    test "accepts a 32 character id" do
      assert [_] = run_task(["--raw", "--id", String.duplicate("a", 32)]) |> String.split()
    end

    test "rejects bad ids before printing anything" do
      for bad <- ["", String.duplicate("a", 33), "bad id", "a\"b"] do
        output =
          capture_io(fn ->
            assert_raise Mix.Error, fn ->
              Mix.Task.reenable(@task)
              Mix.Task.run(@task, ["--raw", "--id", bad])
            end
          end)

        assert output == ""
      end
    end
  end

  describe "default output" do
    test "prints the value once on its own env-var line" do
      output = run_task([])
      lines = String.split(output, "\n")

      assert [line] =
               Enum.filter(lines, &String.starts_with?(&1, "LOCKSPIRE_KEY_ENCRYPTION_KEY="))

      value = String.replace_prefix(line, "LOCKSPIRE_KEY_ENCRYPTION_KEY=", "")
      assert byte_size(value) == 44
      assert byte_size(Base.decode64!(value)) == 32
      assert length(:binary.matches(output, value)) == 1
    end

    test "contains the shared prod block and names the generator" do
      output = run_task([])
      assert output =~ KekSnippet.prod_block(KekSnippet.default_id(), 2)
      assert output =~ "mix lockspire.gen.kek"
    end

    test "orders the env-var line, prod block and dev/test note" do
      output = run_task([])
      {a, _} = :binary.match(output, "LOCKSPIRE_KEY_ENCRYPTION_KEY=")
      {b, _} = :binary.match(output, "if config_env() == :prod")
      {c, _} = :binary.match(output, "For dev and test")
      assert a < b and b < c
    end

    test "never prints a dev/test block with the key" do
      refute run_task([]) =~ ~s|System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY", "|
    end

    test "--id is used in the block and round-trips through KeySet" do
      output = run_task(["--id", "2026-q3"])
      assert output =~ ~s|{"2026-q3",|
      assert output =~ ~s|current: "2026-q3"|

      [line] =
        output
        |> String.split("\n")
        |> Enum.filter(&String.starts_with?(&1, "LOCKSPIRE_KEY_ENCRYPTION_KEY="))

      value = String.replace_prefix(line, "LOCKSPIRE_KEY_ENCRYPTION_KEY=", "")
      assert {:ok, _} = KeySet.new(keys: [{"2026-q3", value}], current: "2026-q3")
    end

    test "writes no files and logs nothing" do
      tmp = Path.join(System.tmp_dir!(), "gen-kek-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)
      on_exit(fn -> File.rm_rf!(tmp) end)

      log =
        capture_log(fn ->
          File.cd!(tmp, fn -> run_task([]) end)
        end)

      assert log == ""
      assert File.ls!(tmp) == []
    end
  end

  describe "arguments" do
    test "--help describes the options and generates nothing" do
      output = run_task(["--help"])
      assert output =~ "--id"
      assert output =~ "--raw"
      assert output =~ "--help"
      refute Regex.match?(~r/[A-Za-z0-9+\/]{43}=/, output)
      refute output =~ @forbidden
    end

    test "unknown options and positional arguments raise" do
      for args <- [["--bogus"], ["extra"]] do
        assert_raise Mix.Error, fn ->
          capture_io(fn ->
            Mix.Task.reenable(@task)
            Mix.Task.run(@task, args)
          end)
        end
      end
    end
  end
end
