import Config

# Same shape `mix lockspire.install` prints for a host's config/runtime.exs.
if config_env() == :prod do
  config :lockspire, :key_encryption,
    keys: [
      {"demo-1",
       System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") ||
         raise(
           "LOCKSPIRE_KEY_ENCRYPTION_KEY is missing. Generate one with: openssl rand -base64 32"
         )}
    ],
    current: "demo-1",
    legacy_plaintext: :reject
else
  # Demo-only fallback. This literal is public in this repository and must
  # never be used in a real deployment. Set LOCKSPIRE_KEY_ENCRYPTION_KEY to
  # your own value (openssl rand -base64 32) to override it.
  config :lockspire, :key_encryption,
    keys: [
      {"demo-1",
       System.get_env(
         "LOCKSPIRE_KEY_ENCRYPTION_KEY",
         "waN46rX4PTjdAL+Tqf87o634p8MoF/61jp6OwwM4d+I="
       )}
    ],
    current: "demo-1",
    legacy_plaintext: :reject
end
