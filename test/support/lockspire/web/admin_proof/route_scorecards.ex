defmodule Lockspire.Web.AdminProof.RouteScorecards do
  @moduledoc false

  @workflow_exception "/admin/clients/:client_id/edit?workflow=logout-propagation"

  @required_fields [
    "Route",
    "Source truth",
    "Journey",
    "Persona",
    "JTBD",
    "Top task",
    "Who / What / Where / When / Why",
    "Entry point",
    "Primary decision",
    "Primary action",
    "Earned-place check",
    "Empty state",
    "Error state",
    "Long-data state",
    "Mobile risk",
    "Theme risk",
    "Focus/motion risk",
    "Redaction/security check",
    "Unsupported action check",
    "Follow-up route",
    "Component/group fit",
    "Evidence class",
    "Public support promise",
    "Runtime/package impact",
    "Notes"
  ]

  @allowed_evidence_classes [
    "internal_lab",
    "rendered_guardrail",
    "manual_browser_note",
    "none"
  ]

  @support_promise "This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface."

  def workflow_exceptions, do: [@workflow_exception]

  def required_fields, do: @required_fields

  def allowed_evidence_classes, do: @allowed_evidence_classes

  def support_promise, do: @support_promise

  def expected_routes do
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.map(&mounted_admin_route/1)
    |> Kernel.++(workflow_exceptions())
    |> Enum.sort()
  end

  def parse!(markdown) when is_binary(markdown) do
    {current, parsed} =
      markdown
      |> String.split("\n")
      |> Enum.reduce({nil, %{}}, &parse_line!/2)

    finalize_block!(current, parsed)
  end

  defp parse_line!(line, {current, parsed}) do
    case Regex.run(~r/^### Scorecard: `([^`]+)`\s*$/, line) do
      [_, route] ->
        parsed = finalize_block!(current, parsed)

        {%{route: route, lines: []}, parsed}

      nil ->
        if current do
          {Map.update!(current, :lines, &[line | &1]), parsed}
        else
          {current, parsed}
        end
    end
  end

  defp finalize_block!(nil, parsed), do: parsed

  defp finalize_block!(%{route: route, lines: lines}, parsed) do
    fields =
      lines
      |> Enum.reverse()
      |> Enum.reduce(%{}, fn line, fields ->
        case Regex.run(~r/^- \*\*([^*]+):\*\*\s*(.*)$/, line) do
          [_, field, value] -> Map.put(fields, field, String.trim(value))
          nil -> fields
        end
      end)

    unless Map.has_key?(fields, "Route") do
      raise ArgumentError, "scorecard #{inspect(route)} is missing required Route field"
    end

    if Map.has_key?(parsed, route) do
      raise ArgumentError, "duplicate scorecard route #{inspect(route)}"
    end

    Map.put(parsed, route, fields)
  end

  defp mounted_admin_route(%{path: "/"}), do: "/admin"
  defp mounted_admin_route(%{path: path}), do: "/admin" <> path
end
