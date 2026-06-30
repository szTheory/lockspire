defmodule Lockspire.Web.AdminProof.BrowserEvidence do
  @moduledoc false

  @required_columns [
    "Route / Surface",
    "Journey",
    "Viewport",
    "Theme",
    "Motion",
    "Focus path",
    "State",
    "scrollWidth",
    "clientWidth",
    "Result",
    "Scrubbed notes",
    "Sensitive evidence check",
    "Gap note",
    "Deterministic command outcome"
  ]

  @allowed_results ["pass", "fail", "gap", "blocked"]
  @allowed_journeys ["Orient", "Configure", "Support", "Operate", "Internal lab"]
  @allowed_themes ["light", "dark", "system"]
  @allowed_motion ["default", "reduced-motion"]
  @allowed_viewports ["320px", "390px", "768px", "1024px", "1440px"]

  def required_columns, do: @required_columns

  def allowed_results, do: @allowed_results

  def parse!(markdown) when is_binary(markdown) do
    rows =
      markdown
      |> evidence_tables!()
      |> Enum.flat_map(&parse_table!/1)

    if rows == [] do
      raise ArgumentError, "missing browser evidence table with Route / Surface rows"
    end

    assert_unique_rows!(rows)
  end

  def assert_redaction_safe!(source) when is_binary(source) do
    for {label, pattern} <- sensitive_patterns() do
      if Regex.match?(pattern, source) do
        raise ArgumentError, "sensitive evidence #{label} detected"
      end
    end

    source
  end

  defp sensitive_patterns do
    [
      {"cookie", ~r/\b(?:cookie|session|session_id)=["']?[A-Za-z0-9._~+%\/=-]{12,}/i},
      {"auth code", ~r/\b(?:authorization_code|auth_code)=["']?[A-Za-z0-9._~+%\/=-]{12,}/i},
      {"JWT-looking token",
       ~r/\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]{8,})?\b/},
      {"token parameter",
       ~r/(?:^|[?&\s])(?:access_token|refresh_token|id_token)=["']?[A-Za-z0-9._~+%\/=-]{8,}/i},
      {"plaintext credential",
       ~r/\b(?:client_secret|password|plaintext[_ -]?password)=["']?[A-Za-z0-9._~+%\/=-]{8,}/i},
      {"private key", ~r/-----BEGIN [A-Z ]*PRIVATE KEY-----/},
      {"verifier material",
       ~r/\b(?:code_verifier|verifier_material)=["']?[A-Za-z0-9._~+%\/=-]{8,}/i},
      {"device or user code", ~r/\b(?:device_code|user_code)=["']?[A-Za-z0-9._~+%\/=-]{4,}/i},
      {"copy-once secret",
       ~r/(?:copy[- ]once\s+(?:secret|plaintext|value|credential)|(?:secret|credential).{0,24}copy[- ]once)/i},
      {"production-looking hostname",
       ~r/\b(?:https?:\/\/)?(?:[a-z0-9-]+\.)+(?:com|net|org|io|dev|app|cloud)(?::\d+)?(?:\/|\b)/i}
    ]
  end

  defp evidence_tables!(markdown) do
    lines = String.split(markdown, "\n")

    lines
    |> Enum.with_index()
    |> Enum.reduce([], fn {line, index}, tables ->
      cells = table_cells(line)

      if "Route / Surface" in cells do
        separator = Enum.at(lines, index + 1)

        unless separator && separator_row?(separator) do
          raise ArgumentError, "malformed browser evidence table after Route / Surface header"
        end

        rows =
          lines
          |> Enum.drop(index + 2)
          |> Enum.take_while(&table_row?/1)

        [{cells, rows} | tables]
      else
        tables
      end
    end)
    |> Enum.reverse()
  end

  defp parse_table!({columns, rows}) do
    missing = @required_columns -- columns

    if missing != [] do
      raise ArgumentError, "missing required evidence columns: #{Enum.join(missing, ", ")}"
    end

    Enum.map(rows, &parse_row!(&1, columns))
  end

  defp parse_row!(line, columns) do
    cells = table_cells(line)

    if length(cells) != length(columns) do
      raise ArgumentError,
            "malformed evidence row expected #{length(columns)} cells got #{length(cells)}"
    end

    columns
    |> Enum.zip(cells)
    |> Map.new()
    |> Map.take(@required_columns)
    |> normalize_row!()
  end

  defp normalize_row!(row) do
    row =
      row
      |> Map.update!("Route / Surface", &trim_backticks/1)
      |> Map.update!("scrollWidth", &parse_width!("scrollWidth", &1))
      |> Map.update!("clientWidth", &parse_width!("clientWidth", &1))

    validate_in!("Journey", row["Journey"], @allowed_journeys)
    validate_in!("Viewport", row["Viewport"], @allowed_viewports)
    validate_in!("Theme", row["Theme"], @allowed_themes)
    validate_in!("Motion", row["Motion"], @allowed_motion)
    validate_in!("Result", row["Result"], @allowed_results)
    validate_route!(row["Route / Surface"])

    for column <- @required_columns do
      value = Map.fetch!(row, column)

      cond do
        is_binary(value) and String.trim(value) == "" ->
          raise ArgumentError, "blank required evidence column #{inspect(column)}"

        is_binary(value) ->
          assert_redaction_safe!(value)

        true ->
          :ok
      end
    end

    row
  end

  defp parse_width!(column, value) do
    value = trim_backticks(value)

    unless Regex.match?(~r/^\d+$/, value) do
      raise ArgumentError, "nonnumeric #{column} #{inspect(value)}"
    end

    String.to_integer(value)
  end

  defp validate_in!(column, value, allowed) do
    unless value in allowed do
      raise ArgumentError,
            "invalid #{column} #{inspect(value)}; expected one of #{inspect(allowed)}"
    end
  end

  defp validate_route!(route) do
    unless String.starts_with?(route, "/admin") or route == "AdminLab.StressSurface" do
      raise ArgumentError, "malformed Route / Surface #{inspect(route)}"
    end
  end

  defp assert_unique_rows!(rows) do
    duplicate =
      rows
      |> Enum.map(fn row ->
        {
          row["Route / Surface"],
          row["Journey"],
          row["Viewport"],
          row["Theme"],
          row["Motion"],
          row["Focus path"]
        }
      end)
      |> Enum.frequencies()
      |> Enum.find(fn {_key, count} -> count > 1 end)

    if duplicate do
      {{route, journey, viewport, theme, motion, focus_path}, _count} = duplicate

      raise ArgumentError,
            "duplicate evidence row for #{route} #{journey} #{viewport} #{theme} #{motion} #{focus_path}"
    end

    rows
  end

  defp table_row?(line), do: line |> String.trim() |> String.starts_with?("|")

  defp separator_row?(line) do
    cells = table_cells(line)

    cells != [] and Enum.all?(cells, &Regex.match?(~r/^:?-{3,}:?$/, &1))
  end

  defp table_cells(line) do
    line = String.trim(line)

    if String.starts_with?(line, "|") and String.ends_with?(line, "|") do
      line
      |> String.trim_leading("|")
      |> String.trim_trailing("|")
      |> String.split("|")
      |> Enum.map(&String.trim/1)
    else
      []
    end
  end

  defp trim_backticks(value) do
    value
    |> String.trim()
    |> String.trim_leading("`")
    |> String.trim_trailing("`")
    |> String.trim()
  end
end
