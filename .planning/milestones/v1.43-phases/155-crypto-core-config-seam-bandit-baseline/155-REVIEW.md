---
phase: 155-crypto-core-config-seam-bandit-baseline
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 40
files_reviewed_list:
  - config/test.exs
  - examples/adoption_demo/mix.exs
  - lib/lockspire/admin/keys.ex
  - lib/lockspire/application.ex
  - lib/lockspire/config.ex
  - lib/lockspire/domain/signing_key.ex
  - lib/lockspire/install/verify.ex
  - lib/lockspire/protocol/id_token.ex
  - lib/lockspire/protocol/introspection_jwt.ex
  - lib/lockspire/protocol/jar.ex
  - lib/lockspire/protocol/jarm.ex
  - lib/lockspire/protocol/logout_token.ex
  - lib/lockspire/protocol/private_jwk.ex
  - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
  - lib/lockspire/security/key_encryption.ex
  - lib/lockspire/security/key_encryption/key_set.ex
  - lib/lockspire/security/key_encryption/key_set_inspect.ex
  - lib/lockspire/storage/ecto/signing_key_record.ex
  - lib/mix/tasks/lockspire.doctor.ex
  - lib/mix/tasks/lockspire.doctor.key_encryption.ex
  - scripts/acceptance/clean_room/build_provider.py
  - test/clean_room/confidential_client/mix.exs
  - test/clean_room/provider_host/mix.exs
  - test/lockspire/admin/keys_test.exs
  - test/lockspire/application_key_encryption_test.exs
  - test/lockspire/architecture_fitness_test.exs
  - test/lockspire/audit/audit_writer_test.exs
  - test/lockspire/config_key_encryption_test.exs
  - test/lockspire/domain/signing_key_inspect_test.exs
  - test/lockspire/install/verify_test.exs
  - test/lockspire/protocol/envelope_signing_consumers_test.exs
  - test/lockspire/protocol/jar_test.exs
  - test/lockspire/protocol/private_jwk_test.exs
  - test/lockspire/security/key_encryption_test.exs
  - test/lockspire/security/sealed_seeders_test.exs
  - test/mix/tasks/lockspire_doctor_key_encryption_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
  - test/support/key_encryption_helpers.ex
  - test/support/seeding_helpers.ex
  - test/support/token_exchange_case.ex
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 155: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 40
**Status:** issues_found

## Summary

The cipher core is sound. Verified against the focus areas:

- IV: 12 fresh bytes from `:crypto.strong_rand_bytes/1` per `seal/3`.
- Tag size: exact 16 bytes. Parse uses `binary-size(12)` and `binary-size(16)`, and `decrypt/5` guards both sizes plus a 32-byte key.
- AAD: binds label, the full header (magic, version, id_len, kek_id) and the row kid.
- Post-decrypt: `PrivateJwk.decode_envelope` requires the decrypted JWK `kid` to equal the row kid.
- Classify: an `LSK` prefix is never routed to the legacy decoder, so there is no fall-through on envelope failure.
- No KEK fallback: nothing reads `secret_key_base`, and there is no `compile_env`. `Admin.Keys.generate_key/1` returns `{:error, :key_encryption_not_configured}` when the keyset is nil, so plaintext is never written.
- Redaction:
  - `KeySet` has a custom Inspect that omits key material.
  - Config errors carry only atom tags.
  - Verify and doctor print ids and mode only.
  - `SigningKey` and `SigningKeyRecord` exclude `private_jwk_encrypted` from Inspect.
- Consumer error shapes: all consumers still receive `{:error, :invalid_signing_key}` from `decode/1`, and Jar still maps failures to `:decryption_failed`.

No blockers. Two warnings and three info items follow.

## Warnings

### WR-01: `legacy_plaintext: :reject` is accepted and reported as active but is not enforced

**File:** `lib/lockspire/protocol/private_jwk.ex:29-33` (also `lib/lockspire/install/verify.ex:68`, `lib/mix/tasks/lockspire.doctor.key_encryption.ex:53-55`)
**Issue:**
- `decode_with_reason/1` routes any non-`LSK` binary to `decode_legacy/1` without consulting `keyset.legacy_plaintext`.
- A host that sets `legacy_plaintext: :reject` still has plaintext private JWKs decoded and used for signing.
- `mix lockspire.verify` and `mix lockspire.doctor key_encryption` print `legacy_plaintext=reject` and report success, which gives false assurance.
- CONTEXT.md defers `:reject` enforcement to Phase 156, so this is a known gap. The risk is that the option is accepted and advertised in the interim.

**Fix:** Either enforce it now:
```elixir
:legacy ->
  case Config.key_encryption_keyset() do
    %{legacy_plaintext: :reject} -> {:error, :legacy_plaintext_rejected}
    _ -> decode_legacy(bin)
  end
```
Or, if enforcement stays in 156, reject `:reject` in `KeySet.fetch_mode/2` until it is implemented. Alternatively, have doctor and verify print "reject (not yet enforced)".

### WR-02: Boot-cached `:persistent_term` keyset can diverge from the config that verify and doctor validate

**File:** `lib/lockspire/config.ex:272-278`, `lib/lockspire/install/verify.ex:63`
**Issue:**
- Runtime signing and sealing use the boot-time cache. A cached `:unconfigured` stays nil for the life of the VM.
- Verify and doctor intentionally re-validate fresh from app env.
- `Application.put_env` after boot (a host `runtime.exs` hot-reload, or a remote console) therefore makes verify and doctor report "present" while signing still uses the old or absent keyset. The mismatch is silent.
- The cache-miss branch also lets `ArgumentError` escape `key_encryption_keyset/0`. `PrivateJwk.decode_with_reason/1` swallows it into `:invalid_signing_key` with no log, so a config fault looks like a bad key row.

**Fix:** Document that the cache is boot-only. Consider logging once on a cache-miss validation failure. Consider having `PrivateJwk` rescue only the expected exceptions rather than all of them.

## Info

### IN-01: Failure reasons are discarded and nothing is logged

**File:** `lib/lockspire/protocol/private_jwk.ex:16-20`
**Issue:** `decode/1` collapses `:kek_not_configured`, `:unknown_kek`, `:kid_mismatch` and `:decryption_failed` into `:invalid_signing_key`. This preserves the existing wire shape, but operators get no signal at runtime on why signing fails (for example a removed KEK id).
**Fix:** Emit a redacted `Logger.error` or telemetry event carrying only the reason atom and the kid handle. This belongs with the Phase 156 audit work.

### IN-02: `decode_padded/1` is more permissive than needed

**File:** `lib/lockspire/security/key_encryption/key_set.ex:121-128`
**Issue:**
- `String.trim_trailing(b64, "=")` accepts any number of trailing `=` characters (for example `AAAA====`).
- A trailing newline from `openssl rand -base64 32` copied into an env var is rejected as `:invalid_base64`. The error is correct but unfriendly.

**Fix:** Allow at most the expected padding count. Consider `String.trim/1` on the input, or add a hint to the error message.

### IN-03: Hardcoded KEK in the clean-room provider config

**File:** `scripts/acceptance/clean_room/build_provider.py:75`
**Issue:** The generated host config embeds a fixed base64 KEK (`clean-room-1`). This is acceptable for a throwaway acceptance harness, but the value must never be copied into the generator output shipped to hosts (Phase 157).
**Fix:** Add a comment marking the key as test-only.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
