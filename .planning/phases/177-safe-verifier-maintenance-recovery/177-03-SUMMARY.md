---
phase: 177-safe-verifier-maintenance-recovery
plan: "03"
subsystem: auth-storage
tags: [elixir, ecto, postgresql, verifier-custody, tdd]

requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Selected-store authority and authenticated verifier custody inspection from Plans 01–02.
provides:
  - Exhaustive exclusive UTF-8 byte-ordered client inventory pages with bounded look-ahead.
  - Mix-free batch preview, apply, and fresh check reports over authenticated verifier custody.
  - Safe no-material, pending, conflict, incomplete, and uninspected outcomes with bounded client details.
affects: [177-04, 177-05, 177-06, 177-08, verifier-maintenance, verifier-recovery]

actuals:
  tokens: 11222
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 0b476e6d47ef6711047c4fd368c6e00532b741d6
plan_head_after: 97b36de0c8e7087136ce43140923794311306955

tech-stack:
  added: []
  patterns: [UTF-8 C-collation cursor symmetry, authenticated custody classification, bounded safe reports, readiness separate from committed progress]

key-files:
  created:
    - lib/lockspire/admin/client_verifier_maintenance.ex
    - test/lockspire/admin/client_verifier_maintenance_test.exs
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-03-01-red-evidence.json
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-03-02-red-evidence.json
  modified:
    - lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
    - test/lockspire/storage/client_verifier_maintenance_test.exs
    - test/support/delegated_verifier_maintenance_store.ex

key-decisions:
  - "Use the same explicit COLLATE \"C\" expressions for cursor comparison and ordering, after confirming PostgreSQL server encoding is UTF8."
  - "Only a complete nil-cursor check can set custody_condition_met?; apply reports committed changes and always directs operators to a separate fresh check."
  - "Return base64url or bounded SHA-256 client identity, fixed classifications/actions, and only authenticated safe key IDs."

patterns-established:
  - "Validate each selected inventory page's size, client shape, bytewise monotonicity, exclusive cursor, and terminal contract before inspecting rows."
  - "Keep scan completion, pending work, committed progress, unresolved outcomes, and fresh custody readiness as separate report facts."
  - "Retain at most 100 detail entries while preserving aggregate counts and an explicit details_truncated? flag."

requirements-completed: [VOPS-01, VOPS-03]
coverage:
  - id: D1
    description: "PostgreSQL inventory traverses all rows once in exclusive unsigned UTF-8 byte order and validates terminal and limit behavior."
    requirement: VOPS-01
    verification:
      - kind: integration
        ref: "test/lockspire/storage/client_verifier_maintenance_test.exs#inventory pages traverse all persisted IDs in exclusive UTF-8 byte order"
        status: pass
      - kind: integration
        ref: "test/lockspire/storage/client_verifier_maintenance_test.exs#inventory accepts default and maximum page sizes and includes unfiltered rows"
        status: pass
    human_judgment: false
  - id: D2
    description: "Batch status distinguishes legitimate public no-material clients from missing, orphan, unknown, malformed, old-key, and current custody."
    requirement: VOPS-03
    verification:
      - kind: integration
        ref: "test/lockspire/admin/client_verifier_maintenance_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview/check remain read-only, apply retains committed progress, malformed pages block completion, and details stay bounded and safe."
    requirement: VOPS-01
    verification:
      - kind: integration
        ref: "test/lockspire/admin/client_verifier_maintenance_test.exs"
        status: pass
      - kind: integration
        ref: "test/lockspire/storage/client_verifier_maintenance_test.exs"
        status: pass
    human_judgment: false

duration: 23min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 03: Exhaustive Verifier Status Summary

**Verifier maintenance now scans every persisted client deterministically and separates safe preview, committed rewrap progress, and a fresh complete custody check.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-10-26T01:32:08Z
- **Completed:** 2026-10-26T01:54:42Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Fixed inventory terminal-page detection and made PostgreSQL UTF-8 encoding an explicit precondition for matching `COLLATE "C"` cursor comparison and ordering.
- Added live PostgreSQL coverage for bytewise ordering across case, dots, combining and non-ASCII IDs; exclusive boundaries; limits 1, 100 and 500; invalid limits/cursors; and rows regardless of active, expiry, auth-method, hash, or verifier state.
- Added the Mix-free `Lockspire.Admin.ClientVerifierMaintenance.run/1` operation with validated modes, complete-page checks, authenticated custody classifications, per-row selected-store rewraps, and bounded safe details.
- Proved public/no-secret `no_material`, dry-run purity, committed apply counts, separate fresh check readiness, partial progress preservation, malformed pages, identity redaction, detail truncation, and distinct missing/orphan/unknown/malformed outcomes.

## Task Commits

1. **177-03-01: Prove all-row bytewise cursor traversal** — `9dd8bd96` (RED), `9d326fc9` (GREEN).
2. **177-03-02: Expose exhaustive safe status and separate completion facts** — `28c871f2` (RED), `97b36de0` (GREEN).

Measured production/task commit count: 4, from `plan_head_before` through `plan_head_after` in the frontmatter. Summary and state metadata commits are recorded separately by the GSD closeout.

## Files Created/Modified

- `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` — UTF-8 encoding check, bytewise exclusive page validation, and correct look-ahead terminal handling.
- `lib/lockspire/admin/client_verifier_maintenance.ex` — Mix-free exhaustive batch engine with safe status, progress, and readiness reports.
- `test/lockspire/storage/client_verifier_maintenance_test.exs` — PostgreSQL page ordering, boundaries, limits, cursor errors, and unfiltered inventory cases.
- `test/lockspire/admin/client_verifier_maintenance_test.exs` — Mode, custody, partial-run, malformed-page, report-bounds, and redaction coverage.
- `test/support/delegated_verifier_maintenance_store.ex` — Deterministic fixed and sequenced page responses for malformed and interrupted-page cases.
- `177-03-01-red-evidence.json`, `177-03-02-red-evidence.json` — Captured TAP RED records validated by `gsd_run check tdd-red-evidence`.

## Verification

All runs used the required local runtime and the plan-owned PostgreSQL database; the shared `lockspire_test` database was not used:

`ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned MIX_ENV=test`

| Command | Result |
|---|---|
| `mix test --include integration test/lockspire/admin/client_verifier_maintenance_test.exs test/lockspire/storage/client_verifier_maintenance_test.exs` | Exit 0; 17 tests, 0 failures. |
| `MIX_ENV=test mix format --check-formatted` | Passed. |
| `git diff --check` | Passed. |
| `gsd_run check tdd-red-evidence 177-03-01-red-evidence.json --raw` | `RED_EVIDENCE_OK`; target page assertion failed before implementation. |
| `gsd_run check tdd-red-evidence 177-03-02-red-evidence.json --raw` | `RED_EVIDENCE_OK`; target report assertion failed before implementation. |

## TDD Evidence

| Task | RED evidence | GREEN evidence |
|---|---|---|
| 177-03-01 | PostgreSQL paging target failed with exit 2 because the inventory passed `Enum.split/2`'s remainder list to boolean `not`, instead of returning the expected page. The single-target TAP record passed the evidence checker. | Storage suite passed with 7 tests, 0 failures after deriving terminal state from whether the bounded look-ahead remainder is empty. |
| 177-03-02 | The no-material fresh-check target failed its successful-report match before the batch operation existed. The single-target TAP record passed the evidence checker. | Combined Admin and storage targets passed with 17 tests, 0 failures. |

Both RED commits precede their corresponding GREEN commits. The RED failures were target behavior assertions, not compilation, loading, discovery, or fixture errors.

## Decisions Made

- Kept current verifier custody distinct from authentication eligibility: expired migrated material remains visibly expired while authenticated current-key custody can still be reported accurately.
- Used the immutable serving-node startup context and the existing endpoint secret-key-base only for qualified legacy custody inspection/rewrap; no task-local context is installed into runtime state.
- Treated resumed scans as progress only and kept readiness exclusive to a complete check beginning at a nil cursor.

## Deviations from Plan

None. UTF-8 cursor validation was tightened to return the frozen invalid-cursor outcome for malformed byte sequences.

## Issues Encountered

- The initial RED paging run exposed that `Enum.split/2` returns a list remainder, so using it as a boolean raised instead of terminating the page correctly. The target failure was retained as validated TAP evidence and fixed in the GREEN commit.
- Test cleanup initially attempted a sandbox-owned database delete from ExUnit's separate on-exit process. The fixtures now rely on the test transaction rollback, preserving the isolated owned database.

## User Setup Required

None.

## Next Phase Readiness

Plans 04 onward can consume exhaustive safe status and complete-mode reports over the selected maintenance capability. A successful apply remains progress only; key retirement decisions require a separate fresh check after host-owned quiescence and deployment checks. No Phase 177 or Phase 178 completion is claimed.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*

## Self-Check: PASSED

- All created implementation, test, and RED evidence files listed in the summary exist.
- All four task commits are ancestors of the production plan head.
- The persisted plan ledger measures four task commits from `0b476e6d47ef6711047c4fd368c6e00532b741d6` through `97b36de0c8e7087136ce43140923794311306955`.
- The plan evaluation-scope check resolves to the same four task commits.
