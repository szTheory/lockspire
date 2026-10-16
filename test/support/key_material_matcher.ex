defmodule Lockspire.TestSupport.KeyMaterialMatcher do
  @moduledoc """
  The single proof point for "no key material leaked" checks.

  `refute_leak!/3` looks for the given secrets (a private key value, a KEK) in raw, base64,
  base64url and hex form, plus the sealed-envelope header in raw, inspect byte-list, base64
  and hex form. It walks maps, structs, lists and tuples down to binary leaves, and also
  scans the `inspect/2` text of the whole subject, so a term that only shows the bytes when
  printed is still caught.

  Structural walks read real struct fields, including ones an `Inspect` derive hides. To check
  what `inspect/1` shows for a struct, pass `inspect(struct)` as the subject.
  """

  import ExUnit.Assertions, only: [flunk: 1]

  @envelope_header <<"LSK", 1>>
  @inspect_header "<<76, 83, 75, 1"
  @base64_header "TFNLAQ"
  @hex_header "4c534b01"

  @doc "Every searchable form of `raw`: raw, base64, base64url (padded and not) and lowercase hex."
  @spec forms(binary()) :: [binary()]
  def forms(raw) when is_binary(raw) do
    [
      raw,
      Base.encode64(raw),
      Base.encode64(raw, padding: false),
      Base.url_encode64(raw),
      Base.url_encode64(raw, padding: false),
      Base.encode16(raw, case: :lower)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  @doc "The sealed-envelope header markers, in the forms a leak can take."
  @spec markers() :: [{atom(), binary()}]
  def markers do
    [
      {:envelope_header, @envelope_header},
      {:envelope_header_inspect, @inspect_header},
      {:envelope_header_base64, @base64_header},
      {:envelope_header_hex, @hex_header}
    ]
  end

  @doc "All `{kind, needle}` pairs searched for the given secrets."
  @spec needles([binary()]) :: [{atom(), binary()}]
  def needles(secrets) when is_list(secrets) do
    secret_needles =
      for secret <- secrets, is_binary(secret), secret != "", form <- forms(secret) do
        {:secret, form}
      end

    secret_needles ++ markers()
  end

  @doc """
  Fails the test when `subject` holds any of `secrets`, or a sealed-envelope header, in any
  searched form. The failure names the label and the kind of match, never the matched value.
  """
  @spec refute_leak!(String.t(), term(), [binary()]) :: :ok
  def refute_leak!(label, subject, secrets) when is_binary(label) and is_list(secrets) do
    needles = needles(secrets)

    case first_match(subject, needles) do
      nil ->
        :ok

      kind ->
        flunk("key material leaked into #{label} (matched #{kind})")
    end
  end

  defp first_match(subject, needles) do
    walk(subject, needles) || text_match(subject, needles)
  end

  defp text_match(subject, needles) when is_binary(subject), do: scan(subject, needles)

  defp text_match(subject, needles) do
    [
      inspect(subject, limit: :infinity, printable_limit: :infinity, structs: false),
      inspect(subject, limit: :infinity, printable_limit: :infinity),
      inspect(subject)
    ]
    |> Enum.find_value(&scan(&1, needles))
  end

  defp walk(binary, needles) when is_binary(binary), do: scan(binary, needles)

  defp walk(%_{} = struct, needles), do: struct |> Map.from_struct() |> walk(needles)

  defp walk(map, needles) when is_map(map) do
    Enum.find_value(map, fn {key, value} -> walk(key, needles) || walk(value, needles) end)
  end

  defp walk([head | tail], needles), do: walk(head, needles) || walk(tail, needles)
  defp walk(tuple, needles) when is_tuple(tuple), do: tuple |> Tuple.to_list() |> walk(needles)
  defp walk(_other, _needles), do: nil

  defp scan(text, needles) do
    Enum.find_value(needles, fn {kind, needle} ->
      if :binary.match(text, needle) != :nomatch, do: kind
    end)
  end
end
