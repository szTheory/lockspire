"""Safe, host-owned projection for mixed-version rollout evidence.

This script deliberately emits only verifier format, a one-way hash witness,
and authenticated lifetime metadata. It never prints credentials or verifier
bytes. Run it against the run-owned provider database after each process step.
"""

[prefix, client_id] = System.argv()
unless Regex.match?(~r/\A[a-z][a-z0-9_]{0,39}\z/, prefix) and
         Regex.match?(~r/\A[a-zA-Z0-9_.-]{1,160}\z/, client_id) do
  Mix.raise("invalid rollout projection arguments")
end

{:ok, _apps} = Application.ensure_all_started(:ecto_sql)
{:ok, _repo} = CleanRoomProvider.Repo.start_link()
result = Ecto.Adapters.SQL.query!(CleanRoomProvider.Repo,
  "SELECT client_secret_hash, client_secret_jwt_verifier_encrypted, " <>
    "to_char(client_secret_expires_at AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"') " <>
    "FROM #{prefix}.lockspire_clients WHERE client_id = $1",
  [client_id]
)

case result.rows do
  [[hash, verifier, deadline]] when is_binary(hash) ->
    format = if is_binary(verifier) and String.starts_with?(verifier, "LSCV1."), do: "dedicated", else: "legacy"
    digest = Base.encode16(:crypto.hash(:sha256, hash), case: :lower)
    IO.puts("ROW_FORMAT=#{format};HASH_DIGEST=#{digest};DEADLINE=#{deadline || "nil"}")

  [] ->
    IO.puts("ROW_FORMAT=missing;HASH_DIGEST=missing;DEADLINE=missing")

  _ ->
    IO.puts("ROW_FORMAT=invalid;HASH_DIGEST=unavailable;DEADLINE=unavailable")
end
