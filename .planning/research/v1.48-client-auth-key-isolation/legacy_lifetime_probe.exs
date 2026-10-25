# Synthetic dependency probe only. Prints booleans/reasons, never key or ciphertext.
# ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 \
#   elixir -pa '_build/test/lib/plug_crypto/ebin' \
#   .planning/research/v1.48-client-auth-key-isolation/legacy_lifetime_probe.exs
Application.load(:plug_crypto)
{:ok, _} = Application.ensure_all_started(:plug_crypto)
key = :crypto.strong_rand_bytes(64)
salt = "lockspire client_secret_jwt verifier"
value = "synthetic-verifier-probe"
fresh = Plug.Crypto.encrypt(key, salt, value)
aged = Plug.Crypto.encrypt(key, salt, value, signed_at: System.system_time(:second) - 172_800)

observed = %{
  plug_crypto: Application.spec(:plug_crypto, :vsn) |> to_string(),
  fresh_default_read: Plug.Crypto.decrypt(key, salt, fresh) == {:ok, value},
  aged_default_result: Plug.Crypto.decrypt(key, salt, aged),
  aged_explicit_unbounded_read:
    Plug.Crypto.decrypt(key, salt, aged, max_age: :infinity) == {:ok, value}
}

IO.inspect(observed, label: "synthetic_lifetime_probe")
true = observed.plug_crypto == "2.2.1"
true = observed.fresh_default_read
{:error, :expired} = observed.aged_default_result
true = observed.aged_explicit_unbounded_read
