defmodule Lockspire.RAR do
  @moduledoc """
  Public helpers for host RAR validator implementations.
  """

  alias Ecto.Changeset

  @spec error_description(Changeset.t() | String.t()) :: String.t()
  def error_description(%Changeset{} = changeset) do
    changeset
    |> Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
  end

  def error_description(description) when is_binary(description), do: description
end
