defmodule Lockspire.ConfigCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  @original_values_key {__MODULE__, :original_values}

  using options do
    quote do
      use ExUnit.Case, unquote(options)
      import Lockspire.ConfigCase, only: [delete_lockspire_env: 1, put_lockspire_env: 2]
    end
  end

  setup do
    Process.put(@original_values_key, %{})

    on_exit(fn ->
      @original_values_key
      |> Process.get(%{})
      |> Enum.each(fn {key, original} -> restore(key, original) end)
    end)

    :ok
  end

  def put_lockspire_env(key, value) do
    remember_original(key)
    Application.put_env(:lockspire, key, value)
  end

  def delete_lockspire_env(key) do
    remember_original(key)
    Application.delete_env(:lockspire, key)
  end

  defp remember_original(key) do
    originals = Process.get(@original_values_key, %{})

    unless Map.has_key?(originals, key) do
      Process.put(@original_values_key, Map.put(originals, key, Application.fetch_env(:lockspire, key)))
    end
  end

  defp restore(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore(key, :error), do: Application.delete_env(:lockspire, key)
end
