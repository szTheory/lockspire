# Technology Stack: v1.43 Signing Key Encryption at Rest

**Project:** Lockspire (subsequent milestone, closes CR-01)
**Researched:** 2026-10-15
**Scope:** Only the NEW capability. Existing stack (Phoenix, Ecto, JOSE, Jason, Plug.Crypto, Oban, OTel) is validated and not re-researched.
**Overall confidence:** HIGH for primitives and integration points (official OTP docs plus repo inspection), MEDIUM for the comparable-library survey (recalled from library docs and design, not re-fetched).

## Recommendation in One Paragraph

Add zero dependencies. Implement one small internal module (suggested `Lockspire.Security.KeyEncryption`, or a similar name under `Lockspire.Security`) on top of `:crypto.crypto_one_time_aead/7` with `:aes_256_gcm`. Use a 32-byte KEK used directly, with no KDF. Use a random 12-byte IV per encryption and a 16-byte tag. Use a self-describing binary envelope with a magic prefix, a version byte and the KEK id. Bind the envelope header and the signing-key `kid` as AAD. Configure KEKs explicitly as a list of `{id, base64_key}` in `:lockspire` application config, read from env vars in `runtime.exs`. Also accept a host provider module for KMS/Vault-backed hosts, following the existing `account_resolver` module-seam pattern. Validate everything fail-fast in `Lockspire.Application.start/2`, mirroring the existing `Lockspire.Oban.runtime_config!/0` precedent. Keep `Lockspire.Protocol.PrivateJwk.decode` as the single read seam and add the encrypt seam beside it.

## Recommended Stack

### Core Primitive (OTP only)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `:crypto.crypto_one_time_aead/7` with `:aes_256_gcm` | OTP (repo targets OTP 29 / Elixir 1.20; `mix.exs` allows Elixir `~> 1.18`) | Authenticated encryption of the private JWK JSON | Official OTP API, no dependency, AEAD with AAD support. The older `block_encrypt`/`crypto_one_time_aead/6` forms are not needed. /6 is encrypt-only with the default tag length. Use /7 for both directions so encrypt and decrypt share one explicit tag length. |
| `:crypto.strong_rand_bytes/1` | OTP | 12-byte IV per encryption | Already used in `Admin.Keys` for kid generation. Random 96-bit IV is the standard GCM choice. The NIST random-IV limit (about 2^32 encryptions under one key) is irrelevant for a handful of signing keys. |
| `Base.decode64/2` / `Base.url_decode64/2` | Elixir stdlib | Parse the KEK config string | Env vars are text. Base64 is the portable format. |
| `:crypto.hash_equal/2` | OTP 25+ | Constant-time compare, only if comparing key material | Needed only for KEK sanity checks. GCM tag verification is already constant-time inside OpenSSL. |

Verified API facts (erlang.org crypto docs, 2026-10-15):

- Encrypt: `:crypto.crypto_one_time_aead(:aes_256_gcm, key32, iv12, plaintext, aad, 16, true)` returns `{ciphertext, tag}`.
- Decrypt: `:crypto.crypto_one_time_aead(:aes_256_gcm, key32, iv12, ciphertext, aad, tag, false)` returns the plaintext binary or the atom `:error`. It does NOT raise on tag mismatch.
- The decrypt form does NOT validate tag length. The docs warn that a shorter tag matching only a prefix would pass. The envelope parser MUST pattern-match `tag::binary-size(16)` and never accept variable tag lengths.
- AAD of `<<>>` silently degrades to plain AE (no AAD). Always pass non-empty AAD. Add a test asserting that a wrong `kid` AAD fails.
- Bad arguments (wrong key size, non-binary IV) raise `:badarg`. Wrap in `try/rescue` inside the module and return `{:error, :decryption_failed}` with no detail. Do not leak crypto error text (redaction requirement).
- AES-256 requires exactly 32 key bytes. Wrong sizes raise, so validate at config time, not at first use.

### Envelope Format (recommended, decisive)

Binary, stored in the existing `private_jwk_encrypted` `:binary` column. No migration is needed to store it. A migration is optional and only for the rewrap bookkeeping discussed below.

```
<<"LSK", 1::8, kek_id_len::8, kek_id::binary-size(kek_id_len),
  iv::binary-size(12), tag::binary-size(16), ciphertext::binary>>
```

- Magic `"LSK"` plus version byte `1`. The header is self-identifying and cannot collide with the legacy forms. Legacy JSON starts with `{` (0x7B) and legacy `:erlang.term_to_binary` starts with 131 (0x83). Detection is therefore `match?(<<"LSK", _::binary>>, bin)`. No ambiguity and no try/decode guessing.
- `kek_id` is the wrapping-key id (required by the milestone). It enables rotation without trial decryption.
- AAD = `"lockspire.signing_key.v1" <> 0 <> kid <> 0 <> <header bytes through kek_id>`. Binding the header stops downgrade and kek_id tampering. Binding `kid` stops swapping ciphertext between rows. Use `kid` (unique, immutable, known BEFORE insert) rather than the integer DB `id`, which is unknown at generate time and would force a two-step insert. Consider also binding `tenant_id` only if it is immutable. Default to leaving it out.
- Plaintext = the JWK map as JSON via `Jason.encode!/1`, the same bytes written today. This keeps the decode path identical after unwrapping.
- Do NOT use `:erlang.term_to_binary` for new writes. `PrivateJwk.decode/1` currently has a `Plug.Crypto.non_executable_binary_to_term` legacy branch. Keep it only inside the legacy-plaintext branch, and remove it entirely when strict mode is on.
- Alternative rejected: `Plug.Crypto.encrypt/4` (what `Security.Policy.seal_client_secret_jwt_verifier` uses). It is AES-GCM under the hood, but it derives keys with PBKDF2 from `secret_key_base` plus a salt and has no key-id header. It cannot give explicit KEK ids or the dedicated, non-`secret_key_base` key the milestone requires. Keep it for the existing client_secret_jwt verifier and leave that out of scope. (Note for the roadmap: that is a separate, similar at-rest secret that remains `secret_key_base`-derived. Flag it as a possible follow-up, not part of v1.43.)

### KEK Input Format and Validation

| Decision | Choice | Why |
|----------|--------|-----|
| Accepted form | Base64 string (standard or URL-safe, padded or unpadded) that decodes to exactly 32 bytes | Env vars are text. Raw 32-byte binaries in config are error-prone: a 32-character ASCII string would "work" but carry about 5 bits of entropy per byte. Generation is `openssl rand -base64 32`, and a `mix lockspire.gen.kek` task is a nice-to-have. |
| Raw binary | Reject strings that are not base64-32. Optionally permit `{:raw, <<_::256>>}` only for tests | Avoids ambiguity. |
| Derivation (HKDF / `Plug.Crypto.KeyGenerator`) | NONE. Use the 32 bytes directly as the AES key | `Plug.Crypto.KeyGenerator` is PBKDF2 with 1000 iterations, designed to stretch low-entropy secrets like `secret_key_base`. It adds nothing to a 256-bit random KEK and implies it is safe to pass a passphrase. OTP `:crypto` has no HKDF function. Domain separation is already achieved by AAD (purpose string plus kid), which is the right tool here. Do not hand-roll HKDF. |
| Per-record DEK (true envelope encryption) | Not needed for v1.43 | Rows are few (single digits to tens), each encrypted once with a unique random IV. A per-record DEK would add a second wrapped blob and complexity. Revisit only if a KMS provider needs data-key semantics. |
| Key id | Regex `\A[A-Za-z0-9._-]{1,64}\z`, unique within the list | Fits the 1-byte length prefix. Safe in logs. |
| Weak-key checks | Reject all-identical bytes, such as 32 zero bytes. Reject duplicate key material under different ids | Catches placeholder values like `AAAAAAAA...=`. |
| Validation timing | At `Lockspire.Application.start/2`, before the supervisor starts, raising `ArgumentError` with an actionable message that never prints key material. Also at `mix lockspire.doctor` | Fail-fast requirement. The precedent is `Lockspire.Oban.runtime_config!/0`, already called in `Application.start/2`. |
| Never | Fall back to `secret_key_base`, to an unset/empty key, or to plaintext when a key is missing and encryption is enabled | Silent fallback is the dominant failure mode in this class. |

### Runtime Config Pattern

Follow the existing `Lockspire.Config` shape (`Application.get_env(:lockspire, ...)`, a `fetch_required!`-style raising accessor, module seams like `account_resolver`).

```elixir
# config/runtime.exs  (host app)
config :lockspire, :signing_key_encryption,
  # first entry encrypts new writes (primary); all entries can decrypt
  keys: [
    {"2026-10", System.fetch_env!("LOCKSPIRE_KEK_2026_10")},
    {"2026-04", System.get_env("LOCKSPIRE_KEK_2026_04")}  # old keys optional
  ] |> Enum.reject(fn {_, v} -> is_nil(v) end),
  current: "2026-10",
  legacy_plaintext: :allow   # :allow (migrate) | :reject (strict)
```

- `Config.signing_key_encryption!/0` returns a validated struct or map. Cache the parsed result in `:persistent_term` at boot so the base64 decode and validation do not repeat per request. A `:persistent_term` update triggers a global GC only on change, which is fine because it is written once at boot.
- Do NOT put the KEK in compile-time config (`config.exs`). Document `runtime.exs` only. Releases bake `config.exs` values into the build. Add a doctor check that flags a KEK appearing in compile env.
- Provider seam for KMS/Vault hosts: optional `provider: {MyApp.LockspireKek, opts}` implementing a `Lockspire.KeyEncryption.Provider` behaviour with `keys/0` returning `{:ok, %{current: id, keys: [{id, <<32 bytes>>}]}}`. Resolve it once at boot. A host that fetches from KMS caches the plaintext KEK in memory, exactly as a static list would. This mirrors `account_resolver` and `token_exchange_validator`. Ship the static list first. The provider behaviour can be the same phase if cheap, because it is about 20 lines, but it must not block the milestone.
- Redaction: add `:private_jwk_encrypted`, `:private_jwk`, `:kek`, `:signing_key_encryption`, `:keys` to `Lockspire.Redaction` drop keys (both atom and string forms, following the existing `client_secret_jwt_verifier_encrypted` entries). Implement `Inspect` for the config struct, and add `@derive {Inspect, except: [:private_jwk_encrypted]}` on `SigningKey` and `SigningKeyRecord`. Ecto changeset errors and `inspect(struct)` in crash logs are the real leak vectors. A KEK held in a struct must be redacted in `Inspect` too.

### Integration Points (inspected in repo)

| Location | Today | Change |
|----------|-------|--------|
| `lib/lockspire/admin/keys.ex:62` | `private_jwk_encrypted: Jason.encode!(private_jwk_map)` (the column is already named "encrypted"; plaintext JSON) | Replace with `KeyEncryption.encrypt!(Jason.encode!(map), kid)`. Return `{:error, :key_encryption_not_configured}` rather than writing plaintext. Generation already knows `kid` before insert. |
| `lib/lockspire/protocol/private_jwk.ex` `decode/1` | Tries JSON, then safe `binary_to_term` | Becomes `decode(binary, kid)`. Dispatch on the magic prefix: envelope goes to decrypt, then JSON. Otherwise legacy plaintext is allowed only when `legacy_plaintext: :allow` (emit a telemetry/warn once, with no key data). In strict mode return `{:error, :invalid_signing_key}`. Keep the existing rescue/catch so failures always collapse to `:invalid_signing_key`. |
| Call sites (9) | `id_token.ex:36`, `jar.ex:43`, `introspection_jwt.ex:36`, `logout_token.ex:35`, `jarm.ex:55`, `token_exchange/internal/access_token_signer.ex:208`, plus `token_issuer.ex:226` and `access_token_signer.ex:238` | All have `kid` in the same map or struct. Changing to `decode(binary, kid)` is mechanical. Alternatively accept `decode(%{kid:, private_jwk_encrypted:})`. Prefer the map form to avoid mispairing arguments. |
| `Lockspire.KeyCache` | Caches by kid | Verify whether it caches decoded private JWKs. If it does, a KEK rotation or strict switch must not be masked by stale cached plaintext. Inspect before planning. |
| `strip_private_key_material` in `Admin.Keys` and `signing_key_store.ex:254` | Already nils the column in views | No change. Good redaction precedent. |
| Tests | About 15 integration tests insert `private_jwk_encrypted: Jason.encode!(...)` or `:erlang.term_to_binary(...)` directly | These exercise the legacy path. Default test config should use `legacy_plaintext: :allow` so they keep passing, plus a dedicated strict-mode suite. A `test/support` helper `insert_signing_key/…` that encrypts is a cheap way to cut the fixture duplication. |

### Legacy Migration and Rotation (what the primitives imply)

- Legacy detection is purely structural (no magic prefix), so a one-shot `Lockspire.Admin.Keys.encrypt_legacy_keys/0` (and `mix lockspire.keys.encrypt`) can scan rows, decode plaintext, encrypt, and update inside `Repository.transact` with an audit event per key (`:key_encrypted`, metadata: kid and kek_id only). It must be idempotent: already-enveloped rows are skipped.
- Strict mode: after migration is verified, set `legacy_plaintext: :reject`. Boot-time check: in strict mode, query for legacy rows at startup (or in `doctor`) and warn or fail. This is a phase decision for the roadmap: fail boot vs doctor-only. Recommend doctor plus runtime refusal, not a boot DB query that complicates start order.
- KEK rotation (re-wrap): read the `kek_id` from the header, decrypt with that key, re-encrypt under `current`, and update. Idempotent, and a no-op if `kek_id == current`. Because the id is in the header there is no trial decryption. Retire an old KEK only when a scan shows zero rows referencing it. Expose "rows per kek_id" in `doctor`. The re-wrap must be atomic per row (update in a transaction, and compare the old ciphertext in the WHERE clause to avoid clobbering a concurrent re-wrap).
- Decrypt must try only the key named by the header. Unknown `kek_id` returns `{:error, :unknown_kek}` internally (log kid and kek_id, not the key) and collapses to `:invalid_signing_key` at the protocol edge.

## How Comparable Systems Do It (MEDIUM confidence, recalled, not re-fetched)

| System | Approach | Lesson for Lockspire |
|--------|----------|----------------------|
| Cloak / cloak_ecto (Elixir) | AES-GCM, keyring of named ciphers, a tag/label stored in the ciphertext prefix, first cipher encrypts and all decrypt, 12-byte IV, 16-byte tag, base64 32-byte key in config, supports re-encrypt migration | The same shape recommended here (prefix id, list of keys, current key first). We avoid the dependency: its core is about 60 lines over `:crypto`, and our envelope needs AAD binding and legacy/strict semantics that Cloak does not model. Do not add it. |
| Rails `ActiveRecord::Encryption` | Primary plus previous keys, a message with a header (key reference, IV, tag), `support_unencrypted_data` for gradual migration, deterministic mode optional, key derivation via HKDF from the primary key | Validates the `legacy_plaintext: :allow/:reject` toggle (their `support_unencrypted_data`) and the multi-key list. Their HKDF exists because their input may be a passphrase. Ours is a 32-byte random KEK, so no KDF. |
| Keycloak | Realm keys stored in DB component config. Secrets can be moved to a Vault SPI (external secret provider) | Confirms hosts want a provider seam (the Vault analog is our optional `provider:` module). Encrypting DB values is not default there, so Lockspire doing so is a differentiator. |
| node-oidc-provider | Signing JWKS are supplied by the host at construction (`jwks` config), with no storage opinions | The host owns keys. Lockspire stores them, hence our obligation. |
| OpenIddict | Signing credentials/certificates are registered by the host (X.509, optionally cert store/HSM) and not persisted by the library | Same as above. |
| Doorkeeper / doorkeeper-openid_connect | `signing_key` is a PEM string from host config or env. Not stored in the DB | Same. Lockspire is unusual in generating and persisting keys, so it needs an at-rest story. |

Conclusion: the established pattern is "ordered key list, key id in the ciphertext, current key encrypts, all keys decrypt, toggle for unencrypted legacy data". It is what we are building.

## Bandit 1.13.1 Notes (verified on hex.pm and CHANGELOG, 2026-10-15)

- Bandit 1.13.1 was published 2026-10-15, today. 1.13.0 was published earlier the same day and 1.12.5 on 2026-08-20. Very fresh: apply the "wait for a soak period" judgement, but the user has chosen the bump.
- 1.13.1 only reverts the 1.13.0 stale-conn check, which broke valid Phoenix paths such as `Plug.Parsers` errors rendered through `Phoenix.Endpoint.RenderErrors`. **Do not pin 1.13.0.** Pin `== 1.13.1` (or `~> 1.13.1`).
- Requirements of 1.13.1: `plug ~> 1.18`, `thousand_island ~> 1.6`, `hpax ~> 1.1`, `websock ~> 0.5`, `telemetry`. Current locks use thousand_island 1.5.0 and hpax 1.0.4 (examples/adoption_demo and the clean-room hosts). `mix deps.update bandit thousand_island hpax` must update all three. Updating only bandit fails to resolve. Plug 1.20.3 is already locked in the demo, which satisfies `~> 1.18`.
- Current pins: `examples/adoption_demo/mix.exs:33` has `{:bandit, "~> 1.11"}` (locked 1.12.5). `test/clean_room/provider_host/mix.exs:22` and `test/clean_room/confidential_client/mix.exs:22` have `{:bandit, "== 1.12.5"}`. Bump all three mix.exs files and their three mix.lock files. Lockspire itself has no Bandit dependency (AGENTS.md), so there is no change in the library `mix.exs`.
- Behavior changes with 1.13.0 that could touch tests: stricter HTTP/1.1 Host validation, stricter HTTP/2 validation, idle connections closed silently instead of a 408, `conn.port` an integer for CONNECT. Clean-room and adoption-demo e2e tests that hand-craft HTTP requests (raw Host headers, absent Host) are the candidates to watch. Rerun the clean-room and demo suites after the bump. Treat it as a mechanical independent phase or plan with no coupling to the encryption work.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Cipher lib | OTP `:crypto` | `cloak` / `cloak_ecto` | Hard constraint (no new deps), and the envelope needs custom AAD and legacy semantics. |
| Cipher lib | OTP `:crypto` | `Plug.Crypto.encrypt/4` | PBKDF2 off `secret_key_base`, no key id, no per-row AAD binding. It conflicts with the explicit-KEK requirement. |
| Key derivation | None (32-byte KEK direct) | `Plug.Crypto.KeyGenerator` / hand-rolled HKDF | Wrong tool for high-entropy keys, and it invites passphrase use. |
| Key format | Base64 32 bytes | Raw binary, hex | Raw is error-prone in env vars. Hex doubles length and offers no advantage. |
| Mode | AES-256-GCM | AES-256-GCM-SIV, XChaCha20-Poly1305 | Not in OTP `:crypto` reliably (XChaCha20 is not exposed, ChaCha20-Poly1305 has 12-byte nonce). GCM is universally supported and what the milestone specifies. |
| Binding | `kid` in AAD | DB `id` in AAD | `id` is unknown before insert. |
| Config | `runtime.exs` list + optional provider module | `secret_key_base` derived, env var read inside the library | Explicit requirement. Reading `System.get_env` inside a library hides config and breaks tests. |
| Envelope | Custom binary with magic and version | JWE (`JOSE.JWE`, `A256GCMKW`) | JOSE is present and could do `dir`+`A256GCM` with a `kid` header. It would work, but the compact JWE is larger and string-typed, and decrypt-time algorithm confusion (`alg` header from stored data) is an avoidable attack surface. Custom fixed-layout binary is simpler to audit. Reasonable fallback only if the team prefers a standards format. |

## Installation

```bash
# Nothing to install for the library. No new Hex deps.

# Host: generate a KEK (32 random bytes, base64)
openssl rand -base64 32

# Bandit bump (adoption demo and both clean-room hosts, plus matching locks)
# edit mix.exs pins to 1.13.1, then in each project directory:
mix deps.update bandit thousand_island hpax
```

## What NOT to Add

- No `cloak`, `cloak_ecto`, `ex_crypto`, `kms`/`ex_aws_kms`, `vault` clients, or any other Hex dependency. A host that wants KMS implements the provider behaviour itself.
- No HKDF or PBKDF2 for the KEK.
- No `secret_key_base` fallback or derivation.
- No per-record data keys, no deterministic encryption, no new Ecto custom type. A custom `Ecto.Type` that auto-encrypts would hide the AAD `kid` dependency, because the type cannot see sibling fields. Do the encryption explicitly in the domain or Keys layer.
- No new table for keys. The existing `private_jwk_encrypted` binary column is sufficient. A schema migration is only warranted if a queryable `kek_id` column is wanted for rotation reporting (optional). Without it, reporting scans the header bytes in Elixir, which is fine at this row count.

## Sources

- Erlang/OTP crypto module docs, `crypto_one_time_aead/6,7` (https://www.erlang.org/doc/apps/crypto/crypto.html), HIGH. Signatures, `:error` on decrypt failure, no tag-length check on decrypt, empty AAD degrading to AE.
- Hex.pm Bandit package API and release 1.13.1 requirements (https://hex.pm/packages/bandit), HIGH.
- Bandit CHANGELOG (https://github.com/mtrudel/bandit/blob/main/CHANGELOG.md), HIGH.
- Repo inspection: `lib/lockspire/protocol/private_jwk.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/config.ex`, `lib/lockspire/application.ex`, `lib/lockspire/oban.ex`, `lib/lockspire/security/policy.ex` (existing `Plug.Crypto.encrypt` use), `lib/lockspire/redaction.ex`, the three bandit mix.exs/mix.lock files, HIGH.
- Cloak, Rails ActiveRecord::Encryption, Keycloak, node-oidc-provider, OpenIddict and Doorkeeper design summaries are from prior knowledge and were not re-fetched this session, MEDIUM. They support a pattern the OTP docs independently justify, so no requirement hinges on them.
