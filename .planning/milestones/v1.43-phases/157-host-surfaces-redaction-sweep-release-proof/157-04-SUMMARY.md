---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 04
subsystem: docs
tags: [key-encryption, upgrade-guide, telemetry-docs, release-notes]
requires:
  - phase: 157-02
    provides: install step 9 text and env var name
  - phase: 157-05
    provides: decode-then-to_jwk signing shape
provides:
  - operator upgrade and rotation guide registered under HexDocs Upgrade
  - phrase contract test for the guide
  - telemetry docs naming exactly the emitted key events
  - architecture, walkthrough, install and SECURITY updates for envelope storage
  - ready-to-paste release note with version placeholder
affects: [157-03]
actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: 3859dd20f4abdffc7a13931b68a2a136b596704c
plan_head_after: 9b76cffc6e9f54bd55c58c401221327d2c6ffdab
commits: 3
tech-stack:
  added: []
  patterns: ["ordered-phrase contract test that searches forward from the previous match"]
key-files:
  created:
    - docs/upgrading/signing-key-encryption.md
    - test/lockspire/upgrade_guide_contract_test.exs
    - .planning/phases/157-host-surfaces-redaction-sweep-release-proof/157-RELEASE-NOTES.md
  modified:
    - mix.exs
    - docs/telemetry.md
    - SECURITY.md
    - docs/architecture.md
    - docs/code-walkthrough.md
    - docs/install-and-onboard.md
key-decisions:
  - "Guide is version-agnostic (no x.y.z); CHANGELOG linked instead"
  - "Per-row re-encryption telemetry documented as encrypted/rewrapped (what the code emits), not the audit-record names key_encrypted/key_rewrapped"
requirements-completed: [DOC-01, SAFE-01]
coverage:
  - id: D1
    description: "Upgrade guide with before-you-start, four steps, rotation runbook, warnings and hygiene, registered once in extras and Upgrade group"
    requirement: DOC-01
    verification:
      - kind: unit
        ref: "test/lockspire/upgrade_guide_contract_test.exs; test/lockspire/documentation_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Telemetry doc lists exactly the emitted key events with audit-mirror status"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "grep gate over lib/ for each named event (see Deviations for encrypted/rewrapped)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Operator-facing correctness of the commands and expected outputs in the guide"
    requirement: DOC-01
    verification: []
    human_judgment: true
    rationale: "Expected-output wording was derived from task source, not by running an upgrade against a real database"
duration: 25min
completed: 2026-10-16
status: complete
---

# Phase 157 Plan 04: Upgrade Guide and Docs Summary

**A version-agnostic signing-key encryption upgrade guide (four steps, five-step KEK rotation, remanence/rollback/KEK-loss/crash-dump warnings) is registered under HexDocs Upgrade and guarded by a contract test, with telemetry, SECURITY, architecture, walkthrough and install docs aligned to envelope storage and a ready release note.**

## Accomplishments
- Guide at `docs/upgrading/signing-key-encryption.md` with commands and expected results per step, `bin/app rpc` and `Ecto.Migrator.with_repo` forms, `--check` named as the required gate.
- Contract test asserts step order (searching forward so a repeated doctor command cannot hide a reorder), rotation and warning phrases, no `.planning/`, `/Users/`, or `x.y.z`.
- `docs/telemetry.md` line-9 claim corrected; new Signing Key section.
- Architecture (13 headings, 4 mermaid), walkthrough (18 elixir blocks, excerpt edited in place), install guide (runtime KEK step, asserted command order intact), SECURITY bullet.
- `157-RELEASE-NOTES.md` with squash title, `{VERSION}` placeholder, upgrade-notes-first PR body, ship note; no major-bump marker; commit-marker check on `origin/main..HEAD` is empty.

## Verified key events (D-28)
| Event | Emitter | Audit mirror |
|---|---|---|
| `generated`, `published`, `activated`, `retired` | `lib/lockspire/admin/keys.ex:130,154,183,206` via `emit/4` | yes |
| `encrypted`, `rewrapped` | `lib/lockspire/admin/keys/reencrypt.ex:287` (`Observability.emit(:key, info.action, ...)`, actions set at `:151` and `:158`) | yes |
| `reencrypt_failed` | `reencrypt.ex:291` | yes |
| `reencrypt_completed` (mode apply/dry_run/check) | `reencrypt.ex:69` (also `Keys.emit_check_completed`) | yes |
| `legacy_read` | `lib/lockspire/protocol/private_jwk.ex` `emit_legacy_read` | no |
| `decode_failed` | `private_jwk.ex` `emit_decode_failed` | no |

Plaintext refusal surfaces as `decode_failed` with reason `plaintext_key_refused` (policy branch in `decode_stored/2`, passed through `decode/1`). `read_stored/2` and `decode_with_reason/1` emit nothing. The per-row audit record names `key_encrypted`/`key_rewrapped` are persisted audit entries, not telemetry names, and are not documented as events.

## Database statement-logging sentence
Kept, phrased conditionally. Source: postgresql.org runtime-config-logging, `log_parameter_max_length` (default -1 logs bind parameters in full for `log_statement` / `log_min_duration_statement` messages).

## Task Commits
1. Task 1: guide, registration, contract test - `db28270a` (docs)
2. Task 2: rotation, warnings, telemetry, SECURITY - `169b766f` (docs)
3. Task 3: architecture/walkthrough/install, release notes - `9b76cffc` (docs)

## Decisions Made
See key-decisions.

## Deviations from Plan

**1. [Rule 1 - Accuracy] D-28 grep gate false negative for `encrypted` and `rewrapped`**
- **Found during:** Task 2 verification
- **Issue:** The gate's regex matches `emit(:key, :name,` literals; these two events are emitted through `info.action`, so the gate reports them as not emitted although the code emits them (action atoms at reencrypt.ex:151 and :158).
- **Fix:** Kept the accurate docs; verified by reading the emitter. The other eight events pass the gate.
- **Files modified:** none (documentation kept truthful)

**2. [Minor] `mix.exs` diff touches one non-guide line**
- Adding the guide after `storage-prefix.md` in the Upgrade group required adding a trailing comma to the previous list entry. No dependency line changed.

**3. [Rule 1 - Bug] Anchor link in telemetry doc**
- A first draft linked to a heading anchor that may not resolve in HexDocs; committed in Task 2, replaced with plain text in the Task 3 commit (`9b76cffc`).

**Total deviations:** 3 (1 gate false-negative, 2 minor)
**Impact on plan:** None on scope.

## Issues Encountered
None beyond the deviations. Expected-output examples were derived from the task source rather than a live upgrade run.

## Threat Flags
None.

## Known Stubs
None.

## Next Phase Readiness
Ready for 157-03. Release sequencing (PR #121, `{VERSION}` fill-in) remains a ship-time human decision.

## Self-Check: PASSED
- Files exist: guide, contract test, release notes (verified); commits `db28270a`, `169b766f`, `9b76cffc` in history.
- `mix test test/lockspire/upgrade_guide_contract_test.exs test/lockspire/documentation_contract_test.exs`: 14 tests, 0 failures.
- 4 mermaid blocks, 18 elixir blocks in walkthrough, no UI/PRODUCT.md changes.
