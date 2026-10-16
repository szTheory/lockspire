---
phase: 157-host-surfaces-redaction-sweep-release-proof
verified: 2026-10-16T17:30:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-01-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-01-SUMMARY.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-02-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-02-SUMMARY.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-03-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-03-SUMMARY.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-04-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-04-SUMMARY.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-05-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-05-SUMMARY.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-06-PLAN.md"
  - ".planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-06-SUMMARY.md"
  - "docs/upgrading/signing-key-encryption.md"
  - "lib/lockspire/generators/install.ex"
  - "lib/lockspire/protocol/private_jwk.ex"
  - "lib/lockspire/redaction.ex"
  - "lib/lockspire/storage/ecto/repository/signing_key_store.ex"
  - "lib/lockspire/storage/ecto/signing_key_record.ex"
  - "test/integration/signing_key_upgrade_journey_test.exs"
covered_digest: "v3:sha256:85442889e7a89c1be836565bf5880673090cae22b1a8b9580f28990b642468bc"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 157: Host Surfaces, Redaction Sweep and Release Proof Verification Report

**Phase Goal:** A fresh install, the adoption demo and the clean-room provider host store only envelopes by default; no private key material, ciphertext or KEK value is visible anywhere an operator or log reader looks; and CI plus docs prove the full upgrade path.
**Status:** passed
**Re-verification:** No (initial verification)

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix lockspire.install` emits `runtime.exs` `:key_encryption` block (env var, `legacy_plaintext: :reject`); demo and clean-room boot with demo/test KEK and store envelopes | VERIFIED | `lib/lockspire/generators/install.ex:142-156` prints env-var block with `raise` when missing, and a dev/test block. `examples/adoption_demo/config/runtime.exs` sets `:reject` (prod raises without env). `build_provider.py:86-92` writes the env-sourced `:reject` block and `:387-394` asserts it. Install generator test passes. |
| 2 | No private JWK members, ciphertext or KEK in logs, telemetry, audit, inspect, changeset errors, admin pages, LiveView assigns; Redaction covers new fields (atom and string) | VERIFIED | `redaction.ex` drops `private_jwk_encrypted`/`private_jwk` etc. in atom and string sets (lines 9-10, 55-56, 104-105, 150-151) plus an `LSK` value clause (line 242). Schema field is `redact: true`, store reads are sensitive or column-free. `key_material_leak_test.exs` (structural matcher sweep over admin, six consumers, tasks, KeysLive/OverviewLive HTML and assigns, malformed-key leg) re-run: green. |
| 3 | CI signs from encrypted rows for all six token types, asserts envelope prefix and no plaintext `d`/`k`, runs plaintext, re-encrypt, `--check`, `:reject` | VERIFIED | `test/integration/signing_key_upgrade_journey_test.exs` re-run green. `ci.yml:492,496` run `keys.reencrypt --check` and `doctor key_encryption` on the demo. Clean-room journey runs the same commands. |
| 4 | Docs: four-step order, rotation runbook, remanence and rollback warnings, separate KEK backup; walkthrough, architecture, SECURITY updated; release note ready | VERIFIED | `docs/upgrading/signing-key-encryption.md` has the four steps (Step 4 at line 97), rotation runbook, Backup remanence, rollback and KEK-backup sections. `SECURITY.md:66`, `architecture.md:331,355`, `code-walkthrough.md:463` updated. `157-RELEASE-NOTES.md` exists. Contract test green. |
| 5 | SAFE-01 gate passes | VERIFIED | See SAFE-01 section. |

**Score:** 5/5 truths verified, 0 behavior-unverified.

## SAFE-01 Section (final milestone proof)

I checked this independently against the pre-v1.43 baseline `09e45afa` (plan_head_before of 155-01), not only the 157-03 SUMMARY.

| Constraint | Result | Evidence |
|------------|--------|----------|
| No new Hex deps | PASS | `git diff 09e45afa HEAD -- mix.exs mix.lock` shows only the docs `extras`/`groups` entry for the new upgrade guide. No `deps` or lock change. |
| No schema migration | PASS | `git diff --name-status 09e45afa HEAD -- priv` is empty. |
| No rename of `private_jwk_encrypted` | PASS | Column still defined in the original core-tables migration; Redaction and store reference the same name. |
| No decrypted-key cache | PASS | `lib/lockspire/key_cache.ex` unchanged since baseline (public JWK only). |
| No KEK in compile-time config / no `secret_key_base` fallback | PASS | Host KEKs live in `config/runtime.exs`; the only `config/*.exs` hit is the `config/test.exs` fixed test KEK. |
| No OAuth/OIDC behavior change; security defaults preserved | PASS | Orchestrator re-run after review fixes (9247292c, 657b60b1, 65f1ce5b), Elixir 1.19.5-otp-28: `MIX_ENV=test mix test --include integration` gives 2 properties, 2088 tests, 0 failures, 6 skipped. `mix qa` exit 0. `mix qa.dialyzer` 0 errors. Diff shows no added implicit-flow or `alg=none` paths. |
| 157-03 SUMMARY "SAFE-01 gate" | Consistent | Matches the above. |

Own re-run (targeted: leak sweep, upgrade journey, upgrade-guide contract, install generator, redaction, PrivateJwk): 78 tests, 0 failures.

Supporting audits: 157-SECURITY.md 21/21 threats closed; 157-VALIDATION.md `nyquist_compliant: true`; 157-REVIEW-DISPOSITION.md 3 warnings fixed, 3 info accepted (the info items are recorded locked decisions, not gaps).

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| RED-01 | 157-01, 157-05, 157-06 | SATISFIED | Redaction, schema, store, `PrivateJwk.to_jwk/sign`, leak sweep. |
| HOST-01 | 157-02 | SATISFIED | Install generator, demo runtime and seeds, clean-room provider. |
| PROOF-01 | 157-03 | SATISFIED | Upgrade journey test, CI steps, clean-room commands. |
| DOC-01 | 157-04 | SATISFIED | Upgrade guide, telemetry, SECURITY, architecture, walkthrough, release notes. |
| SAFE-01 | all six plans | SATISFIED | SAFE-01 section above. |

All five IDs appear in plan frontmatter and in REQUIREMENTS.md (mapped to Phase 157, marked Complete). No orphaned requirements.

## Anti-Patterns

None blocking. No unreferenced TBD/FIXME/XXX introduced in verified files that I found. The three review warnings were fixed and the three info items are accepted per locked decisions D-07, D-24 and the journey-only redactor registration.

## Human / CI Follow-up (non-blocking)

1. The adoption-demo GitHub Actions job's new `--check` and doctor steps only run in CI. They were verified locally against Postgres in 157-02 and again after WR-02. Confirm green on the PR.
2. Release version (1.6.0 vs 1.7.0) is a ship-time decision (D-21). `157-RELEASE-NOTES.md` carries a version placeholder, and the squash title drives Release Please.
3. Standalone `build_provider.py` KEK is not registered with the redactor (IN-03). It is informational: no evidence scan runs in that mode.

## Gaps Summary

No gaps. The phase goal is achieved: envelope-only storage by default on fresh install, demo and clean-room hosts; redaction proven by a structural canary sweep; end-to-end upgrade proof in tests and CI; docs complete; SAFE-01 holds.

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
