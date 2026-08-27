Mix.start()
Mix.Local.append_archives()

case System.argv() do
  [tarball] ->
    Hex.start()
    bytes = File.read!(tarball)

    case Hex.API.Release.publish("hexpm", bytes, [], fn _ -> nil end, false) do
      {:ok, {status, _headers, _body}} when status in 200..299 ->
        IO.puts("Exact release artifact accepted by Hex (HTTP #{status}).")

      {:ok, {status, _headers, _body}} ->
        Mix.raise("Hex rejected the exact release artifact (HTTP #{status})")

      {:error, _reason} ->
        Mix.raise("Hex exact-artifact upload failed")
    end

  _ ->
    Mix.raise("usage: elixir scripts/publish/upload_hex_artifact.exs PACKAGE_TAR")
end
