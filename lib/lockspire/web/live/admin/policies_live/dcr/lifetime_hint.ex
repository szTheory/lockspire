defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dcr.LifetimeHint do
  @moduledoc false

  # Turns a lifetime in seconds into a readable duration shown under the input.
  # Months and years are not fixed lengths, so the largest unit is days; long
  # durations add an approximate year count.

  @units [{86_400, "day"}, {3_600, "hour"}, {60, "minute"}, {1, "second"}]
  @year_seconds 31_536_000
  @secret_field :dcr_default_client_secret_lifetime_seconds
  @secret_already_expired "Apps will be told their secret has already expired"

  @spec describe(atom(), term()) :: String.t() | nil
  def describe(field, value) do
    case parse(value) do
      :blank -> blank_text(field)
      0 when field == @secret_field -> @secret_already_expired
      seconds when is_integer(seconds) -> duration(seconds)
      :invalid -> nil
    end
  end

  @spec duration(non_neg_integer()) :: String.t()
  def duration(0), do: "0 seconds"

  def duration(seconds) when is_integer(seconds) and seconds > 0 do
    {unit_seconds, unit} = Enum.find(@units, fn {size, _unit} -> seconds >= size end)
    text = amount(seconds, unit_seconds, unit)

    if seconds >= @year_seconds do
      "#{text} (#{amount(seconds, @year_seconds, "year")})"
    else
      text
    end
  end

  defp amount(seconds, unit_seconds, unit) do
    if rem(seconds, unit_seconds) == 0 do
      count = div(seconds, unit_seconds)
      "#{delimit(count)} #{pluralize(unit, count)}"
    else
      rounded = Float.round(seconds / unit_seconds, 1)

      count_text =
        if rounded == trunc(rounded),
          do: delimit(trunc(rounded)),
          else: decimal(rounded)

      "≈ #{count_text} #{pluralize(unit, rounded)}"
    end
  end

  defp blank_text(@secret_field), do: @secret_already_expired

  # A blank box already says "not set"; only explain blanks with a surprising effect.
  defp blank_text(_field), do: nil

  defp parse(nil), do: :blank
  defp parse(value) when is_integer(value) and value >= 0, do: value

  defp parse(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        :blank

      trimmed ->
        case Integer.parse(trimmed) do
          {seconds, ""} when seconds >= 0 -> seconds
          _ -> :invalid
        end
    end
  end

  defp parse(_value), do: :invalid

  defp pluralize(unit, count) when count == 1, do: unit
  defp pluralize(unit, _count), do: unit <> "s"

  defp decimal(float) do
    [whole, fraction] = float |> :erlang.float_to_binary(decimals: 1) |> String.split(".")
    "#{delimit(String.to_integer(whole))}.#{fraction}"
  end

  defp delimit(integer) do
    integer
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
