defmodule Lockspire.Web.AdminProof.CssAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.Web.AdminProof.Paths

  def assert_namespaced_controls! do
    for source <- Paths.admin_live_sources() do
      refute source =~ ~r/\sstyle=/
      refute Regex.match?(~r/class="(?:button|[^"]*\sbutton(?:\s|"))/, source)
      refute Regex.match?(~r/<button(?![^>]*lockspire-admin-btn)/, source)
    end
  end

  def assert_component_primitives! do
    css = css()
    components = components()

    for primitive <- [
          "page_hero",
          "metric_grid",
          "filter_bar",
          "action_group",
          "long_value",
          "confirmation_panel",
          "dense_resource_row",
          "responsive_table"
        ] do
      assert components =~ "def #{primitive}"
    end

    for class <- [
          "lockspire-admin-page-hero",
          "lockspire-admin-metric-grid",
          "lockspire-admin-filter-bar",
          "lockspire-admin-action-group",
          "lockspire-admin-long-value",
          "lockspire-admin-confirmation-panel",
          "lockspire-admin-dense-resource-row",
          "lockspire-admin-responsive-table"
        ] do
      assert css =~ ".#{class}"
    end
  end

  def assert_semantic_tokens! do
    css = css()
    tokens = Paths.brandbook_tokens() |> File.read!() |> Jason.decode!()

    for token <- [
          "--ls-surface-page",
          "--ls-text-strong",
          "--ls-border-subtle",
          "--ls-border-control",
          "--ls-status-success-bg",
          "--ls-focus-ring-color",
          "--ls-motion-duration-fast"
        ] do
      assert css =~ token
    end

    for {token, path} <- %{
          "--ls-color-brand-500" => ["color", "brand", "500", "value"],
          "--ls-color-gray-100" => ["color", "neutral", "100", "value"],
          "--ls-color-info-bg" => ["status", "light", "info", "bg"],
          "--ls-color-info-bg-dark" => ["status", "dark", "info", "bg"]
        } do
      assert css =~ "#{token}: #{get_in(tokens, path)};"
    end

    assert css =~ "--ls-status-success-bg: var(--ls-color-success-bg-dark);"
  end

  def assert_theme_focus_and_motion! do
    css = css()

    for selector <- [":root[data-theme=\"light\"]", ":root[data-theme=\"dark\"]"] do
      assert css =~ selector
    end

    assert css =~ "@media (prefers-color-scheme: dark)"
    assert css =~ ":focus-visible"
    assert css =~ "outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);"
    refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "transform: none;"
  end

  def assert_responsive_layout! do
    css = css()

    assert rule(css, ".lockspire-admin-long-value") =~ "overflow-wrap: anywhere"
    assert rule(css, ".lockspire-admin-responsive-table__list") =~ "display: none"

    secondary_nav = rule(css, ".lockspire-admin-secondary-nav")
    assert secondary_nav =~ "overflow-x: auto"
    refute secondary_nav =~ "flex-wrap: wrap"
    assert rule(css, ".lockspire-admin-secondary-nav a") =~ "white-space: nowrap"

    collapsed_nav = media_rule(css, "@media (max-width: 1119px)")

    assert rule(collapsed_nav, ".lockspire-admin-nav-toggle") =~ "display: flex"
    assert rule(collapsed_nav, ".lockspire-admin-nav-menu") =~ "display: none"

    assert rule(
             collapsed_nav,
             ~s(.lockspire-admin-nav[data-open="true"] .lockspire-admin-nav-menu)
           ) =~
             "display: grid"

    assert rule(collapsed_nav, ".lockspire-admin-nav-item") =~ "min-height: 2.75rem"

    mobile = media_rule(css, "@media (max-width: 800px)")

    assert rule(mobile, ".lockspire-admin-responsive-table .lockspire-admin-table-wrap") =~
             "display: none"

    assert rule(mobile, ".lockspire-admin-responsive-table__list") =~ "display: grid"
    assert rule(mobile, ".lockspire-admin-action-group__destructive") =~ "border-top:"
  end

  def assert_redaction_safe_presentation! do
    components = components()
    long_value = component_block(components, "long_value")

    assert long_value =~ "{@value}"
    assert long_value =~ "Redacted"
    assert long_value =~ "lockspire-admin-redacted-value"
    assert components =~ "defp status_metadata(:approved, :device_authorization)"
  end

  def assert_theme_control! do
    layout = File.read!(Paths.admin_layout())
    css = css()

    assert layout =~ "data-lockspire-theme-select"
    assert layout =~ ~s(<option value="system">System</option>)
    assert layout =~ ~s(<option value="light">Light</option>)
    assert layout =~ ~s(<option value="dark">Dark</option>)
    assert css =~ ".lockspire-admin-theme-control"

    assert rule(css, ".lockspire-admin-theme-control select") =~
             "padding: var(--ls-space-2) var(--ls-select-text-clearance) var(--ls-space-2) var(--ls-space-3)"

    # The caret keeps at least 16px (--ls-space-4) from the right border.
    assert css =~ "--ls-select-icon-inset: var(--ls-space-4);"

    assert rule(css, ".lockspire-admin-select-field svg") =~
             "inset-inline-end: var(--ls-select-icon-inset)"
  end

  # Computed WCAG contrast over the compiled stylesheet. Token values are read
  # from the :root block (light) and the dark theme block merged over it.
  def assert_contrast_pairs! do
    themes = theme_tokens()

    for {theme, tokens} <- themes, {fg, bg, minimum} <- contrast_pairs(theme) do
      ratio = contrast_ratio(resolve_color(tokens, fg, theme), resolve_color(tokens, bg, theme))

      assert ratio >= minimum,
             "#{theme} theme: #{fg} on #{bg} is #{format_ratio(ratio)}:1, needs at least #{minimum}:1"
    end
  end

  defp contrast_pairs(theme) do
    surfaces = ["--ls-surface-panel", "--ls-surface-page", "--ls-surface-muted"]

    text =
      for fg <- ["--ls-text-body", "--ls-text-muted"], bg <- surfaces, do: {fg, bg, 4.5}

    accent =
      for bg <- ["--ls-surface-panel", "--ls-surface-muted"], do: {"--ls-text-accent", bg, 4.5}

    status =
      for kind <- ["success", "warning", "danger", "info"],
          do: {"--ls-status-#{kind}-text", "--ls-status-#{kind}-bg", 4.5}

    # Primary button label: panel on brand-600 in light (.lockspire-admin-btn-primary),
    # page on the accent in dark (@dark_btn).
    primary_button =
      case theme do
        "light" -> {"--ls-surface-panel", "--ls-color-brand-600", 4.5}
        "dark" -> {"--ls-surface-page", "--ls-text-accent", 4.5}
      end

    text ++
      accent ++
      status ++
      [
        primary_button,
        {"--ls-focus-ring-color", "--ls-surface-panel", 3.0},
        # Visible control boundaries (WCAG 1.4.11).
        {"--ls-border-control", "--ls-surface-panel", 3.0},
        {"--ls-border-control", "--ls-surface-page", 3.0},
        {"--ls-border-control", "--ls-surface-muted", 3.0}
      ]
  end

  defp theme_tokens do
    css = Lockspire.Web.Admin.CSS.get()
    light = css |> declaration_block(~r/(?:^|\n)\s*:root\s*\{([^}]*)\}/) |> parse_tokens()

    dark =
      css
      |> declaration_block(~r/:root\[data-theme="dark"\]\s*\{([^}]*)\}/)
      |> parse_tokens()

    [{"light", light}, {"dark", Map.merge(light, dark)}]
  end

  defp declaration_block(css, regex) do
    [_, body] = Regex.run(regex, css)
    body
  end

  defp parse_tokens(block) do
    ~r/(--ls-[a-z0-9-]+)\s*:\s*([^;]+);/
    |> Regex.scan(block)
    |> Map.new(fn [_, name, value] -> {name, String.trim(value)} end)
  end

  defp resolve_color(tokens, name, theme, depth \\ 0) do
    value = Map.get(tokens, name) || flunk("#{theme} theme: token #{name} is not defined")

    cond do
      depth > 8 ->
        flunk("#{theme} theme: token #{name} has a reference loop")

      Regex.match?(~r/\A#[0-9a-fA-F]{6}\z/, value) ->
        value

      match = Regex.run(~r/\Avar\((--ls-[a-z0-9-]+)\)\z/, value) ->
        resolve_color(tokens, Enum.at(match, 1), theme, depth + 1)

      true ->
        flunk("#{theme} theme: token #{name} is not a #rrggbb color (#{value})")
    end
  end

  defp relative_luminance("#" <> hex) do
    [r, g, b] =
      for <<channel::binary-size(2) <- hex>> do
        c = String.to_integer(channel, 16) / 255
        if c <= 0.04045, do: c / 12.92, else: :math.pow((c + 0.055) / 1.055, 2.4)
      end

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp contrast_ratio(a, b) do
    {la, lb} = {relative_luminance(a), relative_luminance(b)}
    (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  end

  defp format_ratio(ratio), do: :erlang.float_to_binary(ratio, decimals: 2)

  defp css, do: File.read!(Paths.admin_css())
  defp components, do: File.read!(Paths.admin_components())

  defp media_rule(css, media_query) do
    [_, body] = Regex.run(~r/#{Regex.escape(media_query)}\s*\{(.*)\z/s, css)
    body
  end

  defp rule(css, selector) do
    [_, body] = Regex.run(~r/#{Regex.escape(selector)}\s*\{([^}]*)\}/s, css)
    body
  end

  defp component_block(source, function_name) do
    [block] = Regex.run(~r/def #{function_name}\([^\n]+\).*?(?=\n  def |\n  defp |\z)/s, source)
    block
  end
end
