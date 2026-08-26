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
    preserve_lockspire_env!()
    :ok
  end

  def preserve_lockspire_env! do
    Process.put(@original_values_key, %{})
    initial = Map.new(Application.get_all_env(:lockspire))

    ExUnit.Callbacks.on_exit(fn ->
      Application.get_all_env(:lockspire)
      |> Keyword.keys()
      |> Enum.reject(&Map.has_key?(initial, &1))
      |> Enum.each(&Application.delete_env(:lockspire, &1))

      Enum.each(initial, fn {key, value} -> Application.put_env(:lockspire, key, value) end)
    end)
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

end
