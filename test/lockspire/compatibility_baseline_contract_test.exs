defmodule Lockspire.CompatibilityBaselineContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Architecture.PublicCompatibilityManifest, as: Manifest

  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @fixture Path.expand("../../compatibility/phoenix_1_8_live_view_1_1", __DIR__)

  test "minimum compatibility job compiles the exact host fixture on PostgreSQL 14" do
    compatibility_job = ci_job!(File.read!(@ci), "compatibility")

    assert compatibility_job =~ "elixir-version: ${{ env.MIN_ELIXIR_VERSION }}"
    assert compatibility_job =~ "otp-version: ${{ env.MIN_OTP_VERSION }}"
    assert compatibility_job =~ "postgres:14@sha256:"
    assert compatibility_job =~ "mix compile --warnings-as-errors"
    assert compatibility_job =~ "mix test.fast"
    assert compatibility_job =~ "compatibility/phoenix_1_8_live_view_1_1/mix.lock"
    assert compatibility_job =~ "working-directory: compatibility/phoenix_1_8_live_view_1_1"
    assert compatibility_job =~ "mix deps.get --check-locked"

    assert compatibility_job =~
             "git diff --exit-code -- mix.lock compatibility/phoenix_1_8_live_view_1_1/mix.lock"
  end

  test "fixture pins supported Phoenix and LiveView floors through the Lockspire host seam" do
    mixfile = File.read!(Path.join(@fixture, "mix.exs"))
    lock = File.read!(Path.join(@fixture, "mix.lock"))
    router = File.read!(Path.join(@fixture, "lib/lockspire_compatibility_fixture.ex"))

    assert mixfile =~ "{:lockspire, path: \"../..\"}"
    assert mixfile =~ "{:phoenix, \"== 1.8.5\"}"
    assert mixfile =~ "{:phoenix_live_view, \"== 1.1.28\"}"
    assert lock =~ "\"phoenix\": {:hex, :phoenix, \"1.8.5\""
    assert lock =~ "\"phoenix_live_view\": {:hex, :phoenix_live_view, \"1.1.28\""
    assert router =~ "Lockspire.Web.Router"
    assert router =~ "Lockspire.Web.AdminRouter"
    assert router =~ "use Phoenix.LiveView"
  end

  test "all PostgreSQL workflow services remain immutable" do
    for path <- Path.wildcard(Path.expand("../../.github/workflows/*.yml", __DIR__)) do
      workflow = File.read!(path)

      for [image] <-
            Regex.scan(~r/image:\s+(postgres:[^\s#]+)/, workflow, capture: :all_but_first) do
        assert image =~ "@sha256:", "#{path} has mutable PostgreSQL service image #{image}"
      end
    end
  end

  test "literal public module, arity, and struct baseline remains exported" do
    Enum.each(Manifest.modules(), fn {module, function, arity} ->
      assert Code.ensure_loaded?(module), "#{inspect(module)} is not loadable"

      assert function_exported?(module, function, arity),
             "#{inspect(module)}.#{function}/#{arity} disappeared"
    end)

    Enum.each(Manifest.structs(), fn {module, keys} ->
      assert Code.ensure_loaded?(module), "#{inspect(module)} is not loadable"

      assert Map.keys(struct(module)) |> Enum.sort() == [:__struct__ | keys] |> Enum.sort(),
             "#{inspect(module)} struct keys changed"
    end)
  end

  defp ci_job!(workflow, name) do
    [_, job] = Regex.run(~r/  #{name}:\n(.*?)(?=\n  [a-z][\w-]*:|\z)/s, workflow)
    job
  end
end
