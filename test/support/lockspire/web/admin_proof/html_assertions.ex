defmodule Lockspire.Web.AdminProof.HtmlAssertions do
  @moduledoc false

  import ExUnit.Assertions

  @generic_cta_text [
    "Click here",
    "Learn more",
    "Read more",
    "Submit"
  ]

  @token_like_text_patterns [
    {"JWT-looking text", ~r/\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]{8,})?\b/},
    {"live-key-looking text", ~r/\b(?:sk|pk)_live_[A-Za-z0-9]{8,}\b/},
    {"cookie/auth-code-like text",
     ~r/\b(?:cookie|session|authorization_code|auth_code|code_verifier|device_code|user_code)=["']?[A-Za-z0-9._~+%\/=-]{12,}/i},
    {"private-key-like text", ~r/-----BEGIN [A-Z ]*PRIVATE KEY-----/}
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
    {labels, controls} = labels_and_controls(doc)

    all_targets = for %{for: target} <- labels, is_binary(target) and target != "", do: target

    labelling_targets =
      for %{for: target, text?: true} <- labels, is_binary(target) and target != "", do: target

    assert all_targets != [] or Enum.any?(controls, & &1.wrapped?),
           "expected rendered HTML to include a label: a label[for] target or a control wrapped in a label"

    missing =
      all_targets
      |> Enum.reject(&MapSet.member?(id_set, &1))
      |> Enum.uniq()

    assert missing == [],
           "expected every label[for] target to reference an existing ID, missing: #{inspect(missing)}"

    unlabeled =
      controls
      |> Enum.reject(fn %{attrs: attrs, wrapped?: wrapped?} ->
        hidden_input?(attrs) or wrapped? or
          control_labelled?(attrs, labelling_targets, id_set)
      end)
      |> Enum.map(fn %{attrs: attrs} -> attribute_value(attrs, "id") || inspect(attrs) end)

    assert unlabeled == [],
           "expected every rendered form control to have a label (a non-empty label[for] or wrapping label) " <>
             "or an ARIA label, missing: #{inspect(unlabeled)}"

    html
  end

  # One walk over the parsed tree, so each control is judged as its own node
  # rather than by an attribute list that an identical control elsewhere could
  # share. A label counts only when it has text of its own; a wrapping label
  # with a `for` attribute labels only the control that `for` names.
  defp labels_and_controls(doc) do
    {labels, controls} = doc |> LazyHTML.to_tree() |> walk_labels(nil, {[], []})
    {Enum.reverse(labels), Enum.reverse(controls)}
  end

  defp walk_labels(nodes, label, acc) when is_list(nodes) do
    Enum.reduce(nodes, acc, &walk_label_node(&1, label, &2))
  end

  defp walk_label_node({"label", attrs, children}, _label, {labels, controls}) do
    label = %{for: attribute_value(attrs, "for"), text?: label_text(children) != ""}
    walk_labels(children, label, {[label | labels], controls})
  end

  defp walk_label_node({tag, attrs, children}, label, {labels, controls})
       when tag in ["input", "select", "textarea"] do
    control = %{attrs: attrs, wrapped?: wraps?(label, attrs)}
    walk_labels(children, label, {labels, [control | controls]})
  end

  defp walk_label_node({_tag, _attrs, children}, label, acc),
    do: walk_labels(children, label, acc)

  defp walk_label_node(_text_or_comment, _label, acc), do: acc

  defp wraps?(nil, _attrs), do: false
  defp wraps?(%{text?: false}, _attrs), do: false
  defp wraps?(%{for: target}, _attrs) when target in [nil, ""], do: true
  defp wraps?(%{for: target}, attrs), do: attribute_value(attrs, "id") == target

  defp label_text(children) do
    children
    |> Enum.map_join(" ", fn
      text when is_binary(text) -> text
      {tag, _attrs, _children} when tag in ["input", "select", "textarea"] -> ""
      {_tag, _attrs, nested} -> label_text(nested)
      _comment -> ""
    end)
    |> String.trim()
  end

  @doc """
  Bundled structural contract for a rendered admin page.

  Checks unique IDs, resolvable ARIA targets, hrefs on every link, no token-like
  text, exactly one h1, and explicit label targets. The h1 is rendered by the
  admin shell, so it is present in the HTML returned by `live/2`.

  Options: `:labels` is `:when_present` (default; label check runs when the
  page renders any visible form control) or `:required`. Returns `html` for
  piping.
  """
  def assert_page_contract!(html, opts \\ []) do
    assert_no_duplicate_ids(html)
    assert_describedby_targets_exist(html)
    assert_aria_targets_exist(html, "aria-labelledby")
    assert_aria_targets_exist(html, "aria-controls")
    assert_links_have_hrefs(html)
    html |> strip_liveview_plumbing() |> assert_no_token_like_text()

    h1_count = html |> document() |> LazyHTML.query("h1") |> Enum.count()
    assert h1_count == 1, "expected exactly one h1, found #{h1_count}"

    # Decided by the rendered controls, not by labels: a page whose controls
    # have no labels at all is exactly the case the label check must catch.
    has_controls? =
      html
      |> document()
      |> LazyHTML.query("input:not([type=hidden]), select, textarea")
      |> Enum.count() > 0

    case Keyword.get(opts, :labels, :when_present) do
      :required -> assert_label_targets_exist(html)
      :when_present -> if has_controls?, do: assert_label_targets_exist(html)
    end

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

  def assert_disabled_links_have_semantics(html) do
    disabled_links =
      html
      |> document()
      |> LazyHTML.query("a, [role=\"link\"]")
      |> LazyHTML.attributes()
      |> Enum.filter(&disabled_link_like?/1)

    missing_semantics =
      disabled_links
      |> Enum.reject(&disabled_link_semantic?/1)

    assert missing_semantics == [],
           "expected disabled link actions to expose role=\"link\" and aria-disabled=\"true\" without href, found: #{inspect(missing_semantics)}"

    html
  end

  def assert_no_generic_cta_text(html) do
    assert_no_text(html, @generic_cta_text)
  end

  def assert_no_token_like_text(html) do
    source = html_source(html)

    for {label, pattern} <- @token_like_text_patterns do
      refute Regex.match?(pattern, source), "expected rendered HTML to omit #{label}"
    end

    html
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

  # live/2 output carries Phoenix-signed data-phx-session/static tokens on the
  # LiveView root. They are framework plumbing, not leaked secrets.
  defp strip_liveview_plumbing(html) do
    html
    |> html_source()
    |> String.replace(~r/\sdata-phx-(?:session|static|parent-id|main)="[^"]*"/, "")
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

  defp disabled_link_like?(attrs) do
    class = attribute_value(attrs, "class") || ""
    aria_disabled = attribute_value(attrs, "aria-disabled")

    String.contains?(class, "disabled") or aria_disabled == "true"
  end

  defp disabled_link_semantic?(attrs) do
    attribute_value(attrs, "role") == "link" and
      attribute_value(attrs, "aria-disabled") == "true" and
      is_nil(attribute_value(attrs, "href"))
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
