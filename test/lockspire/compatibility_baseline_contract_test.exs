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

  test "literal pre-refactor exported module and arity baseline remains exact" do
    Enum.each(Manifest.modules(), fn {module, expected_functions} ->
      assert Code.ensure_loaded?(module), "#{inspect(module)} is not loadable"

      actual_functions =
        module.__info__(:functions)
        |> Enum.reject(fn {name, _arity} -> String.starts_with?(Atom.to_string(name), "__") end)

      assert actual_functions == expected_functions,
             "#{inspect(module)} public functions drifted from the literal 76cf872 baseline"
    end)

    Enum.each(Manifest.structs(), fn {module, keys} ->
      assert Code.ensure_loaded?(module), "#{inspect(module)} is not loadable"

      assert Map.keys(struct(module)) |> Enum.sort() == [:__struct__ | keys] |> Enum.sort(),
             "#{inspect(module)} struct keys changed"
    end)
  end

  test "representative public result tuples retain their public struct owners" do
    Enum.each(Manifest.result_contracts(), fn {_surface, tags, modules} ->
      Enum.each(modules, fn module ->
        assert Code.ensure_loaded?(module)
        assert is_map(struct(module))
      end)

      assert Enum.all?(tags, &is_atom/1)
    end)
  end

  test "request-object and protected-resource failure boundaries preserve v1.x structs" do
    client = %Lockspire.Domain.Client{client_id: "compatibility-client"}

    assert {:browser_error,
            %Lockspire.Protocol.AuthorizationRequest.Error{reason_code: :missing_request}} =
             Lockspire.Protocol.RequestObject.consume(
               %{"client_id" => "compatibility-client"},
               client
             )

    assert {:error,
            %Lockspire.Protocol.Userinfo.Error{
              reason_code: :invalid_dpop_authorization_scheme
            }} =
             Lockspire.Protocol.ProtectedResourceDPoP.validate_access(
               %{binding_requirements: %{dpop_jkt: "expected"}},
               %{
                 authorization_scheme: "Bearer",
                 access_token: "token",
                 target_uri: "https://resource.test"
               }
             )
  end

  defp ci_job!(workflow, name) do
    [_, job] = Regex.run(~r/  #{name}:\n(.*?)(?=\n  [a-z][\w-]*:|\z)/s, workflow)
    job
  end
end
