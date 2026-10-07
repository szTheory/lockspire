---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "20"
subsystem: release-maintenance
tags: [maintained-records, hostile-paths, yaml, utf8, fail-closed]
requires:
  - phase: 138-19
    provides: Complete snapshot authority and positive lifecycle validation.
provides:
  - Per-ID semantic proof for hostile maintained paths and cross-family duplicate aggregation.
  - Exclusion-first marker and archive receipts derived from one included-path set.
  - Repository-owned YAML scalar parsing with Unicode and invalid-byte coverage.
affects: [phase-138-verification, phase-139, phase-140, maintained-evidence]
actuals:
  tokens: 3405
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [named JSON record transport, exclusion-before-accounting, repository-owned frontmatter proof]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-20-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Derive every maintained family count, zero receipt, archive summary, and expansion from one collector-owned included-path buffer."
  - "Keep hostile path identity byte-exact while asserting every displayed semantic field by stable REC ID."
  - "Validate generated frontmatter through repository-owned parsing of JSON-compatible YAML scalars rather than a personal GSD installation."
patterns-established:
  - "Excluded maintained candidates never contribute to counts, identities, receipts, or expansion."
  - "Portable frontmatter proof rejects duplicate keys and decodes every emitted scalar without an external developer-home path."
requirements-completed: [BASE-02, LOOSE-01]
coverage:
  - id: D1
    description: Hostile maintained paths retain all named semantics and aggregate by stable REC ID.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes maintained evidence integrity gaps
        status: pass
    human_judgment: false
  - id: D2
    description: Marker and archive receipts use exact exit semantics and one exclusion-filtered path set.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes maintained evidence integrity gaps
        status: pass
    human_judgment: false
  - id: D3
    description: YAML scalars and complete output remain valid UTF-8 under hostile repository and path bytes.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes maintained evidence integrity gaps
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 20: Maintained Evidence Integrity Summary

**Maintained evidence now preserves named semantics from exact Git path bytes through deterministic REC aggregation, exclusion-aware receipts, and portable valid frontmatter.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-09T16:46:46Z
- **Completed:** 2026-09-09T16:57:19Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Added a focused `:phase138_maintained_gap` contract that asserts all twelve named semantic columns for hostile paths, including tabs, newlines, Markdown indicators, shell metacharacters, Unicode, and invalid bytes.
- Proved cross-family duplicate records retain both evidence references and supersession rationale under one stable REC identity.
- Added a collector-owned NUL-delimited included-path buffer and derived complete-zero, counts, archive identities, summaries, and expansion only after D-19 exclusions.
- Covered marker exit 0/1/2/42 matrices, family independence, all-excluded archives, mixed archives, and reverse-order idempotency.
- Replaced a personal absolute GSD invocation with strict repository-owned parsing of the collector's JSON-compatible YAML scalar subset.

## Task Commits

1. **Task 1 RED: Focused maintained gap entry point** — `f26b0d8d` (test)
2. **Task 1 GREEN: Per-ID hostile semantic and duplicate aggregation proof** — `971b77a9` (test)
3. **Task 2 RED: Archive exclusion accounting fixtures** — `8507e64f` (test)
4. **Task 2 GREEN: One included-path set before archive accounting** — `cf7b3a5d` (fix)
5. **Task 3 RED: Developer-local parser path rejection** — `cebd01a4` (test)
6. **Task 3 GREEN: Repository-owned frontmatter parser** — `b89f529d` (test)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — filters every maintained family into one NUL-delimited included-path buffer before count, zero, archive summary, or expansion decisions.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds the hostile semantic, marker/archive, YAML/UTF-8, ordering, and parser portability matrix.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes the focused `:phase138_maintained_gap` contract with a bounded timeout.

## Decisions Made

- Exclusion is part of evidence selection, not a presentation filter; excluded paths never enter any evidence-bearing count or identity.
- Existing named JSON aggregation remains the semantic boundary because it rejects malformed or contradictory records before rendering any row.
- JSON-compatible quoted YAML scalars can be verified hermetically with Jason, keeping YAML proof repository-owned without a new dependency or personal executable path.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_gap` — passed, 1 test and 0 failures (26 excluded).
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.

## Deviations from Plan

None - the plan executed within its three declared files and focused maintained-evidence scope.

## Issues Encountered

- The unrelated untracked `.tool-versions` selects only Node.js, so verification used the installed Elixir 1.19.5 / OTP 28 toolchain through explicit ASDF version environment variables. The file was not modified or committed.

## Known Stubs

None. No placeholder, skipped test, incomplete receipt, or unrun verification was introduced.

## Security and Boundary Notes

- T-138-80 is closed by named JSON records, per-ID semantic assertions, stable-ID aggregation, and fail-closed structured validation.
- T-138-81 is closed by exact marker exit/buffer taxonomy and exclusion-before-accounting from one included-path buffer.
- T-138-82 is closed by distinct YAML and Markdown encoders, exact Unicode preservation, deterministic invalid-byte display, redaction, and parser round-trips.
- T-138-83 is closed by repository-owned scalar parsing with no personal absolute Codex or GSD dependency.
- No endpoint, runtime module, schema, dependency, public API, excluded-tree read, or destructive repository operation was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Verification gaps 8, 9, and 11 and review findings WR-02 and WR-03 now have focused regressions.
- Plan 138-21 can rely on hostile maintained semantics, complete-zero marker behavior, exclusion-correct archive receipts, and portable canonical encoding.

## Self-Check: PASSED

- Confirmed all three implementation/test files and this summary exist.
- Confirmed all six task commits exist in the expected task order.
- Re-ran every plan-required syntax, formatting, and focused test verification after the final changes; all passed with a nonzero test count.
- Confirmed no unexpected deletion, goal-blocking stub, skipped test, unrun plan verification, developer-home dependency, or unmodeled threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
