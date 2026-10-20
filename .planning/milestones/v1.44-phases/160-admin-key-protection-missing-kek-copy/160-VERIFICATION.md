---
phase: 160-admin-key-protection-missing-kek-copy
verified: 2026-10-19T23:45:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - ".planning/phases/160-admin-key-protection-missing-kek-copy/160-01-PLAN.md"
  - ".planning/phases/160-admin-key-protection-missing-kek-copy/160-01-SUMMARY.md"
  - ".planning/phases/160-admin-key-protection-missing-kek-copy/160-02-PLAN.md"
  - ".planning/phases/160-admin-key-protection-missing-kek-copy/160-02-SUMMARY.md"
  - "PRODUCT.md"
  - "lib/lockspire/admin.ex"
  - "lib/lockspire/web/live/admin/keys_live/index.ex"
  - "lib/lockspire/web/live/admin/keys_live/protection.ex"
  - "test/lockspire/web/live/admin/keys_live/protection_test.exs"
  - "test/lockspire/web/live/admin/keys_live_test.exs"
covered_digest: "v3:sha256:cebab59645347508cdfee058ff204b8f52fcbb59d4c000b1aed54eaaab13e100"
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Read the Key protection line and the missing-key-encryption-key error on the Keys page as the least technical persona"
    expected: "Wording is calm and understandable; the next step is clear"
    why_human: "Copy tone cannot be verified programmatically"
---

# Phase 160: Admin Key Protection & Missing-KEK Copy Verification Report

**Phase Goal:** An operator on the admin Keys page can tell at a glance whether signing keys are protected, and understands why key generation is refused when no encryption key is set up.
**Status:** passed (copy tone is listed as an optional human check)
**Re-verification:** No, initial verification

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Read-only "Key protection" line names current KEK id when encrypted, with distinct wording for older-key, unencrypted, unreadable, not-set-up, invalid-config, could-not-check; could-not-check never reads healthy | VERIFIED | `protection.ex` `summarize/1` is pure and total: `{:error,{:invalid_config,_}}` maps to invalid_config. `configured: false` maps to not_set_up. Configured status maps through `classify/1` (unreadable, then unencrypted, then older_key, then encrypted). Every other term maps to `could_not_check`, with value "Unknown" and the text "does not mean your keys are protected". The id is interpolated only in the :encrypted and :older_key copy. Rendered in `index.ex` via `decision_summary`, `:if={@key_protection}`. Tests in `protection_test.exs` cover each state, precedence, unrecognised input and id-only disclosure. |
| 2 | A failed check leaves the key list visible; no per-KEK counts, no key material, no new controls | VERIFIED | `read_encryption_status/0` rescues and catches exit into `:error`, which reads as could-not-check. It does not log. `load_key_protection` is assigned independently of `assign_inventory_result`. The detail strings contain no counts or ids except the current id. The only addition is a `<code>` command text, with no buttons or events. `keys_live_test.exs` asserts ordering (Key protection before the inventory) and that the list still renders. |
| 3 | Generating a key with no KEK shows that none is set up, that Lockspire will not store keys unencrypted, and how to set one up; other errors keep existing copy | VERIFIED | `index.ex` handles `{:error, :key_encryption_not_configured}` for both Signing and Encryption (`missing_key_encryption_error/1`: "No key-encryption key is set up... will not store private keys unencrypted... mix lockspire.gen.kek ... restart"). `Keys.generate_key` returns that atom at `lib/lockspire/admin/keys.ex` line 87. The invalid-config ArgumentError is rescued with its own message that does not echo the exception. The generic `{:error, _reason}` clause is unchanged. |
| 4 | Wording from PRODUCT.md vocabulary map; new terms and retired phrases added; `vocabulary_contract_test.exs` passes | VERIFIED | The PRODUCT.md diff adds three vocabulary rows (key-encryption key, Key protection, the state labels) and updates "Last reviewed". No phrase was replaced, so no retired-wording row is needed. The vocabulary contract test passes (43 tests, 0 failures across protection_test, keys_live_test and vocabulary_contract_test, run on 1.19.5-otp-28). |

**Score:** 4/4 truths verified

## Locked decisions (CONTEXT D-01..D-13), spot-checked

- D-01: `lib/lockspire/admin/keys.ex` is not in the `dda81e8d..HEAD` diff. `admin.ex` changed only by a doc line and a `@spec` widening. Protection data comes only from `Admin.encryption_status/0`.
- D-02: precedence is first-match in the stated order. The WR-02 orphaned case keeps state `:not_set_up` and varies only the guidance text. WR-01 and WR-04 add `unsealable_legacy` and reject-mode legacy to unreadable, consistent with `EncryptionStatus.broken_now?/1`.
- D-02/D-06: the fallback clause returns `:could_not_check`. After the IN-01 fix, the rescue wraps only the status read and the summarizer runs unguarded. The input is a closed set of recognised shapes, so this is safe.
- D-03: the not-set-up copy says new keys cannot be created. It does not claim existing keys keep working.
- D-04: stranded retired rows do not change the state (test "stranded retired rows do not change the state").

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/lockspire/web/live/admin/keys_live/protection.ex` | VERIFIED | Substantive (174 lines), `@moduledoc false`, wired from `index.ex` (alias plus `Protection.summarize`) |
| `lib/lockspire/web/live/admin/keys_live/index.ex` | VERIFIED | Protection assign on mount/reload and after a successful generate; error clauses present |
| `lib/lockspire/admin.ex` | VERIFIED | Docs and spec only |
| `PRODUCT.md` | VERIFIED | Vocabulary rows added |
| Tests | VERIFIED | `protection_test.exs` (189 lines), `keys_live_test.exs` (+392 lines); pass |

## Data-Flow Trace

`Admin.encryption_status/0` (real DB-backed status) goes to `Protection.summarize/1`, then to the `@key_protection` assign, then to `decision_summary`. The data is real, with no static fallback other than the deliberate could-not-check.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Protection presenter, LiveView and vocabulary tests | `mix test` on the three files above | 43 tests, 0 failures | PASS |
| Full CI (supplied by the orchestrator, not re-run) | `mix ci` | exit 0; 1873 fast and 105 integration tests, 0 failures; credo clean | PASS (reported) |

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| KEY-UI-01 | 160-01 | SATISFIED | Truths 1 and 2 |
| KEY-UI-02 | 160-02 | SATISFIED | Truth 3 |
| KEY-UI-03 | 160-01 | SATISFIED | Truth 4 |
| SAFE-02 (constraint; Phase 161 owns the final proof) | n/a | HELD for this phase | See below |

All three IDs are checked in REQUIREMENTS.md and mapped to Phase 160. No orphaned requirements.

## SAFE-02 constraint

The diff since `dda81e8d` for `lib`, `mix.exs`, `mix.lock`, `priv` and `config` covers only `admin.ex` (doc and spec), `index.ex` and the new `protection.ex`. There are no protocol, schema, dependency or security-default changes. The copy exposes no key material, only the current KEK id in the encrypted and older-key states. Exceptions are not logged or echoed. SAFE-02 stays Pending in REQUIREMENTS.md for Phase 161, as intended.

## Anti-Patterns

No TBD/FIXME/XXX debt markers in the modified files (the "drop planning marker" commit removed the last one). The `[]`/nil assigns are initial state that is overwritten on mount.

## Review disposition

WR-01..WR-04 and IN-01 are fixed in code, confirmed by reading `protection.ex` and `index.ex`. IN-02 (decrypting on every page load) is deferred with a reason: a non-decrypting variant would be a domain change that conflicts with SAFE-02. This is an informational item and does not block.

## Human Verification (optional, non-blocking)

1. **Copy tone for the least technical persona.** Read the seven states and the missing-KEK error on the Keys page. They should be calm and the next step should be clear. The automated checks cannot judge tone.

## Gaps Summary

None. All four roadmap success criteria and the three requirement IDs are satisfied in the codebase.

---

_Verified: 2026-10-19T23:45:00Z_
_Verifier: Claude (gsd-verifier)_
