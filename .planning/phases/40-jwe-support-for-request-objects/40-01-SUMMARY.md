# Phase 40-01 Summary: Key Type Expansion

- `Lockspire.Domain.SigningKey` and `Lockspire.Storage.Ecto.SigningKeyRecord` updated to support `:enc` use type.
- `Lockspire.Storage.KeyStore` behaviour expanded with `list_decryption_keys/0`.
- `Repository` implementation updated to safely isolate `sig` and `enc` queries:
  - `fetch_active_signing_key/0` only returns `:sig` keys.
  - `fetch_active_signing_key_records/1` filters by use type.
  - `list_decryption_keys/0` fetches active/retiring `:enc` keys.
- Admin UI updated to support generating and distinguishing between Encryption and Signing Keys.
- JWKS endpoint verified to correctly publish both `:sig` and `:enc` keys.