explicit_test_target? =
  Enum.any?(System.argv(), fn arg ->
    String.ends_with?(arg, ".exs") or String.contains?(arg, "integration")
  end)

integration_requested? =
  Enum.chunk_every(System.argv(), 2, 1, :discard)
  |> Enum.any?(fn
    ["--include", "integration"] -> true
    _other -> false
  end)

exclude =
  if explicit_test_target? or integration_requested? do
    []
  else
    [integration: true]
  end

ExUnit.start(exclude: exclude)
