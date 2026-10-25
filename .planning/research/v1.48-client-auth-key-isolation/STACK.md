# SEC-01 stack and dependency findings

Researched 2026-10-25 at product tree `1917aa61c589d25d3e2668f6ef0672f32ef0a388`; planning-only successor `eb10874d`. Inline research; no subagents, dependency installation or product changes.

## Recommendation

Add no runtime dependency and make no platform upgrade. Use OTP `:crypto` AES-256-GCM through a small internal envelope boundary, borrowing the already-reviewed signing-key implementation while preserving its exact existing format. Keep dedicated verifier key material and configuration separate from signing-key KEKs and endpoint/session secrets. A general vault framework, KMS client and automatic key generation at boot are outside scope.

Current lock: Phoenix 1.8.13, LiveView 1.2.10, Ecto SQL 3.13.5 and plug_crypto 2.2.1. Existing compatibility proof separately pins Phoenix 1.8.5 / LiveView 1.1.28. CI uses Elixir 1.19.5 / OTP 28 and minimum Elixir 1.18.4 / OTP 27. These are source/lock observations, not fresh compatibility acceptance. Use the existing AEAD arity available since OTP 22; no OTP-28-only handle API is needed. The OTP documentation specifically requires the caller to enforce expected tag length; retain fixed 16-byte tags and exact parse bounds. [OTP 28 crypto API](https://www.erlang.org/docs/28/apps/crypto/crypto.html#crypto_one_time_aead/7).

## Representation constraint

The existing signing-key envelope is binary `LSK` v1, with signing-specific AAD. The client verifier migration declares PostgreSQL `:text`, Ecto loads it as `:string`, and custom stores see a string. Use a distinct versioned ASCII representation, with an explicit format marker around encoded authenticated bytes; do not store raw signing-key bytes in the text field or reinterpret the signing label as verifier context. PostgreSQL text rejects NUL and respects the database character set. [PostgreSQL 14 character types](https://www.postgresql.org/docs/14/datatype-character.html).

Recommend in-place conversion with no schema change, subject to a real persistence round trip. Pin exact prefix/layout and maximum input lengths during Phase 175's contract qualification. Preserve signing-envelope fixtures byte-for-byte if a pure common primitive is extracted. Shared cryptographic code must not mean shared key material or a public generic encryption API.

## Legacy dependency fact

The locked Plug.Crypto implementation derives its key from the supplied base and salt, and its higher-level encrypted payload carries an age limit. `Policy` currently calls encrypt/decrypt without lifetime options. Tagged [plug_crypto v2.2.1 source](https://raw.githubusercontent.com/elixir-plug/plug_crypto/v2.2.1/lib/plug/crypto.ex) supplies a one-day default. A fresh synthetic dependency probe reproduced rejection at two days; see [pitfalls](PITFALLS.md). Do not promise that every old ciphertext is currently usable or silently override age during migration.

## Sources and limits

- Local: `mix.lock`, `.github/workflows/ci.yml`, `scripts/ci/run_host_integration_proof.sh`, `lib/lockspire/security/key_encryption.ex`, `lib/lockspire/security/key_encryption/key_set.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `priv/repo/migrations/20260525120000_add_client_secret_jwt_verifier_material_to_lockspire_clients.exs`.
- [NIST SP 800-38D](https://csrc.nist.gov/pubs/sp/800/38/d/final) specifies GCM authenticated encryption. It supports the primitive choice, not a certification or a claim that our implementation is verified.
- No dependency was fetched, upgraded or newly audited. Exact installed-library probe identity is recorded separately from source and package proof.
