defmodule Lockspire.Web.Live.Admin.DesignSystem.PageContractTest do
  @moduledoc """
  The bundled page contract and the local route-proof harness's route list must
  catch the defects they claim to catch.

  These tests read files and render strings only. No browser and no Node process
  runs here, so the local-only capture harness stays out of CI (D-05).
  """

  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.AdminProof.RouteScorecards

  @harness Path.expand("../../../../../browser/admin_route_proof.mjs", __DIR__)

  @valid """
  <main><h1>Apps</h1>
  <label for="name">Name</label><input id="name" name="name">
  <a href="/admin/clients">Apps</a></main>
  """

  test "a well-formed page passes and is returned for piping" do
    assert HtmlAssertions.assert_page_contract!(@valid, labels: :required) == @valid
  end

  test "page contract rejects duplicate ids" do
    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!(~s(<h1 id="x">A</h1><p id="x">B</p>))
    end
  end

  test "page contract rejects aria references to missing elements" do
    for attr <- ["aria-describedby", "aria-labelledby", "aria-controls"] do
      assert_raise ExUnit.AssertionError, fn ->
        HtmlAssertions.assert_page_contract!(~s(<h1>A</h1><button #{attr}="missing">Go</button>))
      end
    end
  end

  test "page contract rejects links without an href" do
    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!("<h1>A</h1><a>Open</a>")
    end
  end

  test "page contract rejects token-like text even when LiveView session plumbing is stripped" do
    jwt =
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890"

    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!(
        ~s(<div data-phx-session="SFMyNTY.abc" data-phx-static="SFMyNTY.def"><h1>A</h1><p>#{jwt}</p></div>)
      )
    end
  end

  test "page contract rejects an unlabeled control on a page that has labels" do
    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!("""
      <h1>A</h1><label for="name">Name</label><input id="name">
      <input id="orphan" name="orphan">
      """)
    end
  end

  test "page contract rejects form controls that have no labels at all by default" do
    for control <- [
          ~s(<input id="q" name="q">),
          ~s(<select name="s"></select>),
          "<textarea></textarea>"
        ] do
      assert_raise ExUnit.AssertionError, fn ->
        HtmlAssertions.assert_page_contract!("<h1>A</h1>#{control}")
      end
    end
  end

  test "page contract skips the label check by default when a page has no visible controls" do
    html = ~s(<h1>A</h1><input type="hidden" name="_csrf_token" value="x">)
    assert HtmlAssertions.assert_page_contract!(html) == html
  end

  test "page contract rejects a label pointing at a missing control when labels are required" do
    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!(~s(<h1>A</h1><label for="ghost">Name</label>),
        labels: :required
      )
    end
  end

  test "page contract accepts a control wrapped in its label" do
    html = ~s(<h1>A</h1><label><input type="checkbox" name="confirm"> I understand</label>)
    assert HtmlAssertions.assert_page_contract!(html, labels: :required) == html
  end

  test "a wrapping label exempts only the control it wraps, not an identical one outside it" do
    html = """
    <h1>A</h1>
    <label><input type="checkbox" name="x[]"> First</label>
    <input type="checkbox" name="x[]">
    """

    error =
      assert_raise ExUnit.AssertionError, fn ->
        HtmlAssertions.assert_page_contract!(html, labels: :required)
      end

    assert error.message =~ "non-empty label[for] or wrapping label"
  end

  test "an empty label does not label a control" do
    for html <- [
          ~s(<h1>A</h1><label><input type="checkbox" name="confirm"></label>),
          ~s(<h1>A</h1><label for="name"> </label><input id="name" name="name">)
        ] do
      assert_raise ExUnit.AssertionError, fn ->
        HtmlAssertions.assert_page_contract!(html, labels: :required)
      end
    end
  end

  test "a wrapping label with a for attribute labels only the control it names" do
    html =
      ~s(<h1>A</h1><label for="other">Name <input id="name" name="name"></label><input id="other">)

    error =
      assert_raise ExUnit.AssertionError, fn ->
        HtmlAssertions.assert_page_contract!(html, labels: :required)
      end

    assert error.message =~ ~s("name")
  end

  test "route proof harness lists exactly the mounted admin routes" do
    source = File.read!(@harness)

    [_, block] = Regex.run(~r/const ROUTE_TEMPLATES = \[(.*?)\];/s, source)
    templates = ~r/"([^"]+)"/ |> Regex.scan(block) |> Enum.map(&List.last/1) |> Enum.sort()

    assert templates == RouteScorecards.expected_routes(),
           "harness ROUTE_TEMPLATES drifted from the admin router: " <>
             "missing #{inspect(RouteScorecards.expected_routes() -- templates)}, " <>
             "extra #{inspect(templates -- RouteScorecards.expected_routes())}"

    assert length(templates) == 30
  end
end
