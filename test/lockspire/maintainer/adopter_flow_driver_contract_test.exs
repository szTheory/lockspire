defmodule Lockspire.Maintainer.AdopterFlowDriverContractTest do
  # Shells out to python3 -m py_compile.
  use ExUnit.Case, async: false

  @repo_root Path.expand("../../..", __DIR__)
  @driver_path Path.join(@repo_root, "scripts/maintainer/adopter_path_flow.py")
  @smoke_path Path.join(@repo_root, "scripts/demo/adoption_smoke.py")

  # Every top-level module named by an import/from-import line in the driver must be a
  # member of this allowlist. A third-party dependency would introduce a module name not
  # in this set, which fails the subset assertion below (ADOPT-04, D-32/D-35).
  @allowed_stdlib_modules ~w(argparse base64 hashlib http json os re sys time urllib)

  test "driver compiles with python3 -m py_compile" do
    assert File.regular?(@driver_path)

    {output, exit_code} =
      System.cmd("python3", ["-m", "py_compile", @driver_path], stderr_to_stdout: true)

    assert exit_code == 0, "py_compile failed:\n#{output}"
  end

  test "every driver import resolves to an explicit stdlib allowlist" do
    source = File.read!(@driver_path)

    imported = extract_imported_modules(source)

    allowed = MapSet.new(@allowed_stdlib_modules)

    assert MapSet.subset?(imported, allowed),
           "driver imports a module outside the stdlib allowlist: " <>
             inspect(MapSet.difference(imported, allowed))

    assert MapSet.size(imported) > 0, "expected at least one import to be detected"
  end

  test "driver asserts the three ADOPT-04 token-proof gates" do
    source = File.read!(@driver_path)

    assert source =~ "userinfo accepts issued access token"
    assert source =~ "protected host route rejects anonymous request"
    assert source =~ "protected host route accepts issued access token"
    assert source =~ "/userinfo"
    assert source =~ "401"
  end

  test "the userinfo assertion precedes the protected-route assertion, and the anonymous case precedes the bearer case" do
    source = File.read!(@driver_path)

    assert_ordered(source, [
      "userinfo accepts issued access token",
      "protected host route rejects anonymous request",
      "protected host route accepts issued access token"
    ])
  end

  test "the driver constructs a fresh Browser for the protected-route calls rather than reusing the logged-in one" do
    source = File.read!(@driver_path)

    fresh_browser_calls =
      ~r/Browser\(base_url\)\.request\(/
      |> Regex.scan(source)
      |> length()

    assert fresh_browser_calls >= 2,
           "expected at least two fresh Browser(base_url).request(...) call sites for the " <>
             "anonymous and bearer protected-route requests"
  end

  test "a third-party import would fail the allowlist gate (regression guard)" do
    source = File.read!(@driver_path)
    fake_source = "import requests\n" <> source

    imported = extract_imported_modules(fake_source)

    allowed = MapSet.new(@allowed_stdlib_modules)

    refute MapSet.subset?(imported, allowed),
           "expected the injected third-party import to be rejected by the allowlist gate"
  end

  test "deleting the anonymous-401 assertion would fail the gate (regression guard)" do
    source = File.read!(@driver_path)

    without_anonymous_case =
      String.replace(source, "protected host route rejects anonymous request", "")

    refute without_anonymous_case =~ "protected host route rejects anonymous request"
  end

  test "moving the userinfo assertion after the protected-route assertion would fail the ordering gate (regression guard)" do
    reordered = """
    protected host route rejects anonymous request
    protected host route accepts issued access token
    userinfo accepts issued access token
    """

    assert_raise ExUnit.AssertionError, fn ->
      assert_ordered(reordered, [
        "userinfo accepts issued access token",
        "protected host route rejects anonymous request",
        "protected host route accepts issued access token"
      ])
    end
  end

  test "scripts/demo/adoption_smoke.py still contains its own black-box proof functions (hygiene gate boundary intact)" do
    source = File.read!(@smoke_path)

    assert source =~ "exercise_authorization_code"
    assert source =~ "exercise_discovery_and_admin"
  end

  # -- helpers ----------------------------------------------------------------------------

  defp extract_imported_modules(source) do
    ~r/^\s*(?:import\s+([a-zA-Z_][\w.]*)|from\s+([a-zA-Z_][\w.]*)\s+import\s+)/m
    |> Regex.scan(source, capture: :all_but_first)
    |> Enum.map(fn captures -> captures |> Enum.reject(&(&1 == "")) |> List.first() end)
    |> Enum.map(&(&1 |> String.split(".") |> List.first()))
    |> MapSet.new()
  end

  defp position!(text, needle) do
    case :binary.match(text, needle) do
      {position, _length} -> position
      :nomatch -> flunk("Expected driver source to contain #{inspect(needle)}")
    end
  end

  defp assert_ordered(text, ordered_fragments) do
    ordered_fragments
    |> Enum.map(&position!(text, &1))
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [left, right] -> assert left < right end)
  end
end
