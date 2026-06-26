defmodule Lockspire.Web.AdminProof.HtmlAssertions do
  @moduledoc false

  import ExUnit.Assertions

  @generic_cta_text [
    "Click here",
    "Learn more",
    "Read more",
    "Submit"
  ]

  def document(html) when is_binary(html), do: LazyHTML.from_fragment(html)
  def document(%LazyHTML{} = html), do: html

  def assert_no_duplicate_ids(html) do
    ids =
      html
      |> document()
      |> LazyHTML.query("[id]")
      |> LazyHTML.attribute("id")
      |> Enum.reject(&(&1 == ""))

    duplicates =
      ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)

    assert duplicates == [],
           "expected rendered HTML to have unique IDs, found duplicates: #{inspect(duplicates)}"

    html
  end

  def assert_describedby_targets_exist(html) do
    assert_aria_targets_exist(html, "aria-describedby")
  end

  def assert_aria_targets_exist(html, attribute)
      when attribute in ["aria-describedby", "aria-labelledby", "aria-controls"] do
    doc = document(html)
    id_set = id_set(doc)

    values =
      doc
      |> LazyHTML.query("[#{attribute}]")
      |> LazyHTML.attribute(attribute)

    blank_values = Enum.filter(values, &(String.trim(&1) == ""))

    assert blank_values == [],
           "expected #{attribute} values to be non-empty"

    missing =
      values
      |> Enum.flat_map(&String.split(&1, ~r/\s+/, trim: true))
      |> Enum.reject(&MapSet.member?(id_set, &1))
      |> Enum.uniq()

    assert missing == [],
           "expected every #{attribute} token to reference an existing ID, missing: #{inspect(missing)}"

    html
  end

  def assert_label_targets_exist(html) do
    doc = document(html)
    id_set = id_set(doc)

    label_targets =
      doc
      |> LazyHTML.query("label[for]")
      |> LazyHTML.attribute("for")
      |> Enum.reject(&(&1 == ""))

    assert label_targets != [], "expected rendered HTML to include explicit label[for] targets"

    missing =
      label_targets
      |> Enum.reject(&MapSet.member?(id_set, &1))
      |> Enum.uniq()

    assert missing == [],
           "expected every label[for] target to reference an existing ID, missing: #{inspect(missing)}"

    unlabeled =
      doc
      |> LazyHTML.query("input, select, textarea")
      |> LazyHTML.attributes()
      |> Enum.reject(&hidden_input?/1)
      |> Enum.reject(&control_labelled?(&1, label_targets, id_set))
      |> Enum.map(fn attrs -> attribute_value(attrs, "id") || inspect(attrs) end)

    assert unlabeled == [],
           "expected every rendered form control to have a label or ARIA label, missing: #{inspect(unlabeled)}"

    html
  end

  def assert_has_selector(html, selector) when is_binary(selector) do
    matches =
      html
      |> document()
      |> LazyHTML.query(selector)
      |> Enum.to_list()

    assert matches != [], "expected rendered HTML to include selector #{inspect(selector)}"

    html
  end

  def assert_no_selector(html, selector) when is_binary(selector) do
    matches =
      html
      |> document()
      |> LazyHTML.query(selector)
      |> Enum.to_list()

    assert matches == [], "expected rendered HTML to omit selector #{inspect(selector)}"

    html
  end

  def assert_has_link(html, href) when is_binary(href) do
    hrefs =
      html
      |> document()
      |> LazyHTML.query("a[href]")
      |> LazyHTML.attribute("href")

    assert href in hrefs, "expected rendered HTML to include link #{inspect(href)}"

    html
  end

  def assert_links_have_hrefs(html) do
    links =
      html
      |> document()
      |> LazyHTML.query("a")
      |> LazyHTML.attributes()

    missing =
      links
      |> Enum.reject(&attribute_value(&1, "href"))

    assert missing == [],
           "expected every rendered link to include href, missing: #{inspect(missing)}"

    html
  end

  def assert_no_generic_cta_text(html) do
    assert_no_text(html, @generic_cta_text)
  end

  def assert_no_interactive_controls(html, opts \\ []) do
    source = html_source(html)

    opts
    |> Keyword.get(:events, ["phx-click", "phx-submit"])
    |> Enum.each(fn event ->
      refute source =~ event, "expected rendered HTML to omit interactive event #{inspect(event)}"
    end)

    opts
    |> Keyword.get(:text, [])
    |> Enum.each(fn text ->
      refute Regex.match?(~r/\b#{Regex.escape(text)}\b/i, source),
             "expected rendered HTML to omit unsupported control text #{inspect(text)}"
    end)

    html
  end

  def assert_no_text(html, denied_values) when is_list(denied_values) do
    source = html_source(html)

    for denied <- denied_values, is_binary(denied), denied != "" do
      refute source =~ denied, "expected rendered HTML to omit denied text #{inspect(denied)}"
    end

    html
  end

  defp id_set(doc) do
    doc
    |> LazyHTML.query("[id]")
    |> LazyHTML.attribute("id")
    |> MapSet.new()
  end

  defp html_source(html) when is_binary(html), do: html
  defp html_source(%LazyHTML{} = html), do: LazyHTML.to_html(html)

  defp hidden_input?(attrs) do
    attribute_value(attrs, "type") == "hidden"
  end

  defp control_labelled?(attrs, label_targets, id_set) do
    id = attribute_value(attrs, "id")
    aria_label = attribute_value(attrs, "aria-label")
    labelledby = attribute_value(attrs, "aria-labelledby")

    cond do
      is_binary(id) and id != "" and id in label_targets ->
        true

      is_binary(aria_label) and String.trim(aria_label) != "" ->
        true

      is_binary(labelledby) and String.trim(labelledby) != "" ->
        labelledby_targets_exist?(labelledby, id_set)

      true ->
        false
    end
  end

  defp labelledby_targets_exist?(labelledby, id_set) do
    labelledby
    |> String.split(~r/\s+/, trim: true)
    |> Enum.all?(&MapSet.member?(id_set, &1))
  end

  defp attribute_value(attrs, name) do
    attrs
    |> Enum.find_value(fn
      {^name, value} -> value
      _ -> nil
    end)
  end
end
