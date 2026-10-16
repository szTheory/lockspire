---
phase: 155-crypto-core-config-seam-bandit-baseline
verified: 2026-10-16T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-01-PLAN.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-01-SUMMARY.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-02-PLAN.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-02-SUMMARY.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-03-PLAN.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-03-SUMMARY.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-04-PLAN.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-04-SUMMARY.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-05-PLAN.md"
  - ".planning/phases/155-crypto-core-config-seam-bandit-baseline/155-05-SUMMARY.md"
  - "examples/adoption_demo/mix.lock"
  - "lib/lockspire/admin/keys.ex"
  - "lib/lockspire/application.ex"
  - "lib/lockspire/config.ex"
  - "lib/lockspire/domain/signing_key.ex"
  - "lib/lockspire/install/verify.ex"
  - "lib/lockspire/protocol/private_jwk.ex"
  - "lib/lockspire/security/key_encryption.ex"
  - "lib/lockspire/security/key_encryption/key_set.ex"
  - "lib/lockspire/storage/ecto/signing_key_record.ex"
  - "lib/mix/tasks/lockspire.doctor.ex"
  - "lib/mix/tasks/lockspire.doctor.key_encryption.ex"
  - "scripts/acceptance/clean_room/build_provider.py"
  - "test/clean_room/confidential_client/mix.lock"
  - "test/clean_room/provider_host/mix.lock"
covered_digest: "v3:sha256:5451c9307bd7edca3f7775d8b14ed2517a069232e060736b99c6bc2864bcbf92"
behavior_unverified: 0
---

# Phase 155: Crypto Core, Config Seam & Bandit Baseline Verification Report

**Phase Goal:** Hosts on Bandit 1.13.1; with a configured KEK every new private signing key is written only as a sealed envelope that all signing/decrypting consumers read; KEK-less hosts keep booting and signing.
**Status:** passed
**Re-verification:** No, initial verification

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Demo + both clean-room hosts pinned `bandit == 1.13.1`, thousand_island/hpax updated, green before any encryption commit | VERIFIED (static) | `{:bandit, "== 1.13.1"}` in all three mix.exs; all three locks resolve bandit 1.13.1, thousand_island 1.6.0, hpax 1.1.0, mint 1.11.0. Compat lock has no bandit/thousand_island entries, mint 1.11.0. Root mix.exs/mix.lock unchanged since milestone start. Commits 5d85b53a/79f3af8b precede the first encryption commit bcd647b4. Host e2e runs reported by the orchestrator (see Host E2E Evidence). |
| 2 | Valid `:key_encryption` generates a key stored as `LSK\x01` envelope for current KEK id; all six consumers read it with unchanged responses | VERIFIED | `Admin.Keys.generate_key/1` seals via `KeyEncryption.seal/3` before `publish_key`. All six sites (`id_token.ex:36`, `logout_token.ex:35`, `jarm.ex:55`, `introspection_jwt.ex:36`, `access_token_signer.ex:208`, `jar.ex:43`) call map-form `PrivateJwk.decode/1`; no binary clause remains. `envelope_signing_consumers_test.exs` and `keys_test.exs` pass. |
| 3 | Each invalid config case stops boot naming the key, never the value | VERIFIED | `KeySet.new/1` returns atom-only `{:error, {key, reason}}`; `Config.fail_key_encryption!` interpolates only atoms; `Application.start/2` calls `validate_key_encryption!` first. `config_key_encryption_test.exs` (incl. sentinel tests) pass. |
| 4 | No config: boots, legacy keys sign, `generate_key` returns `{:error, :key_encryption_not_configured}` with no row; boot warning, doctor, Verify report | VERIFIED | `generate_key` nil branch; boot Logger.warning observed in test output; `Install.Verify.key_encryption_check` (`:error` when absent); `mix lockspire.doctor key_encryption` task + dispatcher clause; keys_test.exs:248 and verify/doctor tests pass. |
| 5 | Tests reject tamper, row swap, unknown KEK, truncated tag (as `:invalid_signing_key`); property test on classify; JWKS/discovery never decrypt | VERIFIED | `parse/1` binds exact 12/16-byte IV/tag; AAD binds header+kid; post-decrypt kid check (`:kid_mismatch`); 2 properties pass; architecture_fitness_test guards JWKS/discovery/KeyCache. |

**Score:** 5/5 truths verified (0 behavior-unverified).

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase test files (115 tests, 2 properties) | `mix test <security, config, application, private_jwk, consumers, fitness, keys, verify, doctor, inspect, audit_writer>` (CI toolchain) | 0 failures | PASS |
| Full library suite | `mix test` (CI toolchain) | 1655 tests, 0 failures, 6 skipped | PASS |

## Requirements Coverage

| Requirement | Plans | Status | Evidence |
|-------------|-------|--------|----------|
| DEP-01 | 155-01 | SATISFIED | Pins and locks verified |
| KEK-01 | 155-02 | SATISFIED | `KeySet.new/1`, `Config.key_encryption!/0`, boot validation |
| KEK-02 | 155-02/04/05 | SATISFIED | Refusal, boot warning, doctor, Verify all present and tested |
| ENC-01 | 155-04/05 | SATISFIED | Sealed write path; inspect redaction on both structs |
| ENC-02 | 155-03/04 | SATISFIED | Six consumers on map-form decode; legacy rows read under `:allow` |
| ENC-03 | 155-02/03 | SATISFIED | Tamper/swap/unknown-KEK/truncated-tag tests and properties |

No orphaned requirements: REQUIREMENTS.md maps exactly these six IDs to Phase 155, and all appear in plan frontmatter.

## Anti-Patterns / Findings

| Severity | Finding |
|----------|---------|
| WARNING (bookkeeping) | `.planning/REQUIREMENTS.md` still shows KEK-02, ENC-01, ENC-02 as unchecked and "Pending" in the traceability table. Code satisfies them; update the checkboxes/table at phase close. |
| Info | `legacy_plaintext: :reject` is validated but not enforced at read; deferred to Phase 156 (MIG-03) per REVIEW-DISPOSITION WR-01, outside Phase 155 scope. |
| Info | Clean-room KEK literal in `build_provider.py` is a test-only fixture (accepted AR-02, to be replaced in Phase 157). |

No TBD/FIXME/XXX debt markers found in phase-modified lib files. 155-SECURITY.md reports 0 open threats; spot-checked mitigations (IV size binding, AAD, kid check, atom-only errors, no decrypt in KeyCache/JWKS) match the code.

## Host E2E Evidence (orchestrator-reported, local runs mirroring ci.yml at HEAD, no code change since; not re-executed by the verifier)

- Clean-room: `mix test.clean-room.e2e` exit 0 (run by executors after the final code change in 155-03, 155-04, 155-05).
- Adoption demo (Elixir 1.19.5/OTP 28.1): `deps.get --check-locked` ok; lock-drift `git diff --exit-code` on demo and compat locks clean; `compile --warnings-as-errors` ok; `ecto.setup` ok (legacy ETF seed keys sign under :allow); `scripts/demo/adoption_smoke.py` passed.
- Compatibility (Elixir 1.18.4/OTP 27.3.4.15): root and fixture `deps.get --check-locked` + `compile --warnings-as-errors` ok; `mix test.fast` 1941 tests, 0 failures, 6 skipped; lock diff clean.

## Human Verification Required

None.

## Gaps Summary

No code gaps. Phase goal is achieved in the library; SC1 e2e evidence is recorded above; remaining item is REQUIREMENTS.md bookkeeping.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
