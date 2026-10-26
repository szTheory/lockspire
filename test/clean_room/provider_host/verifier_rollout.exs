# Safe, host-owned projection for mixed-version rollout evidence.
# Emits verifier format, one-way hash witness, and authenticated age metadata only.

args = case System.argv() do ["--" | rest] -> rest; values -> values end
[prefix, client_id] = args
unless Regex.match?(~r/\A[a-z][a-z0-9_]{0,39}\z/, prefix) and
         Regex.match?(~r/\A[a-zA-Z0-9_.-]{1,160}\z/, client_id) do
  Mix.raise("invalid rollout projection arguments")
end

{:ok, _apps} = Application.ensure_all_started(:ecto_sql)
{:ok, _repo} = CleanRoomProvider.Repo.start_link()
result = Ecto.Adapters.SQL.query!(CleanRoomProvider.Repo,
  "SELECT client_secret_hash, client_secret_jwt_verifier_encrypted " <>
    "FROM #{prefix}.lockspire_clients WHERE client_id = $1",
  [client_id]
)

case result.rows do
  [[hash, verifier]] when is_binary(hash) and is_binary(verifier) ->
    format = if is_binary(verifier) and String.starts_with?(verifier, "LSCV1."), do: "dedicated", else: "legacy"
    digest = Base.encode16(:crypto.hash(:sha256, hash), case: :lower)
    inspection_config = [
      keys: [{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
      current: "verifier-old",
      write_mode: :dedicated,
      legacy_read: :allow
    ]
    {:ok, context} = Lockspire.Security.ClientSecretVerifier.Context.resolve({:present, inspection_config}, [])
    opts = [legacy_secret_key_base: System.fetch_env!("SECRET_KEY_BASE")]
    age = Lockspire.Security.ClientSecretVerifier.inspect_custody(context, client_id, verifier, hash, opts)

    case age do
      {:ok, metadata} ->
        IO.puts("ROW_FORMAT=#{format};HASH_DIGEST=#{digest};AGE_KIND=#{metadata.age_kind};" <>
                  "SIGNED_AT_MS=#{metadata.signed_at_ms || "nil"};DEADLINE_MS=#{metadata.deadline_ms || "nil"}")

      {:error, _reason} ->
        IO.puts("ROW_FORMAT=invalid;HASH_DIGEST=unavailable;AGE_KIND=unavailable;" <>
                  "SIGNED_AT_MS=unavailable;DEADLINE_MS=unavailable")
    end

  [] ->
    IO.puts("ROW_FORMAT=missing;HASH_DIGEST=missing;AGE_KIND=missing;SIGNED_AT_MS=missing;DEADLINE_MS=missing")

  _ ->
    IO.puts("ROW_FORMAT=invalid;HASH_DIGEST=unavailable;AGE_KIND=unavailable;SIGNED_AT_MS=unavailable;DEADLINE_MS=unavailable")
end
