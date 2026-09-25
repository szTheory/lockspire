---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "09"
subsystem: release-maintenance
tags: [git, nul-delimited-paths, sanitization, fail-closed, evidence-ledger]
requires:
  - phase: 138-08
    provides: Fail-closed stable Git evidence identity and partial-domain sibling retention.
provides:
  - Exit-preserving maintained selectors with family-specific unavailable receipts.
  - NUL-delimited tracked-path transport and exact-path REC identity.
  - Sanitized hostile-path rendering with deterministic cross-family deduplication.
  - Fail-closed structural classification for canonical current planning, thread, and train records.
affects: [phase-139, phase-140, phase-141, repository-triage]
actuals:
  tokens: 6374
  tasks: 2
  commits: 5
repair-actuals:
  tokens: 3282
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns: [exit-preserving selector buffers, exact identity versus sanitized display, stable-ID deduplication]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-09-SUMMARY.md"]
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Maintained selector output is buffered to collector-owned files so command exits and NUL-delimited paths remain separate and observable."
  - "REC identity continues to hash the exact normalized tracked path, while only sanitized display values cross TSV and Markdown boundaries."
  - "Maintained deduplication keys by stable REC ID rather than rendered subject text, preserving identity when credentials or controls redact the display."
  - "Canonical roadmap, state, project, release-train, and development-train records require exact paths plus stable structural headings; active roadmap threads require an explicit active cross-session status."
requirements-completed: [LOOSE-01]
coverage:
  - id: D1
    description: Marker, tracked-file, and ambiguity failures downgrade the exact family and aggregate without hiding usable sibling evidence.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed for maintained selectors and hostile paths
        status: pass
    human_judgment: false
  - id: D2
    description: Valid hostile Git paths retain deterministic REC identity without injecting Markdown, controls, temporary filenames, or shell/filesystem side effects.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed for maintained selectors and hostile paths
        status: pass
    human_judgment: false
  - id: D3
    description: Current D-17 planning, thread, and train authorities classify deterministically while structural collisions remain ambiguous and downgrade completeness.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed for maintained selectors and hostile paths
        status: pass
      - kind: other
        ref: bash scripts/maintainer/baseline_inventory.sh --scope maintained --output /tmp/lockspire-138-09-live.tzRelZ/maintained.md
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 09: Maintained Evidence Fail-Closed and Hostile-Path Safety Summary

**Exit-preserving maintained selectors now transport exact Git paths through NUL-delimited buffers while rendering only sanitized, deterministic evidence.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-08-28T18:55:22Z
- **Completed:** 2026-08-28T19:10:02Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Captured real `git grep` and per-family `git ls-files` exit codes before parsing, rendering exact unavailable receipts and partial maintained/snapshot status instead of false complete-zero evidence.
- Made unclassified or taxonomy-invalid candidates durable ambiguous receipts that explicitly require recheck and downgrade aggregate completeness.
- Replaced newline/colon path enumeration with `git ls-files -z` and `git grep -z`, keeping NUL output in files rather than shell variables.
- Preserved exact normalized path bytes for stable REC hashing while sanitizing every displayed subject, selector, evidence reference, archive summary, receipt, and rationale.
- Added a real temporary Git repository containing spaces, colons, tabs, newlines, leading dashes, pipes, backticks, brackets, percent signs, shell metacharacters, credential sentinels, and non-ASCII filenames, plus reversed-order and cross-family aggregation proof.

## Task Commits

1. **Task 1: Preserve selector failures and ambiguity in maintained completeness** — `1ecbf5e6` (RED), `d77dfc11` (GREEN)
2. **Task 2: Make tracked-path transport and rendering hostile-input safe** — `1b983b47` (RED), `53489419` (GREEN)
3. **Authorized focused repair: Classify current maintained planning authorities** — `ef980182` (source and fixture contract)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — captures selector exits, parses NUL-delimited paths, separates exact identity from sanitized display, and deduplicates by stable REC ID.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes the focused maintained fail-closed and hostile-path contract.
- `test/support/lockspire/release_proof/package_assertions.ex` — supplies selector-failure scenarios, real hostile Git paths, order reversal, deterministic ID checks, and no-side-effect assertions.

## Decisions Made

- Selector buffers use collector-owned `mktemp` paths only; no untrusted filename contributes to a temporary or durable collector-owned path.
- NUL-delimited path bytes never enter shell variables as path lists. Each exact path is consumed by `read -r -d ''` and passed only to quoted Git commands and identity derivation.
- Sanitized display text is deliberately not an identity or deduplication key because redaction can collapse multiple hostile subjects to the same visible token.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 13 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; the phase declares no external API integration surface.
- Source guards confirmed the D-17 family allowlist and D-19 exclusions remain present, selectors use `git ls-files -z` and `git grep -z`, and maintained sources are read only through quoted `git show` object lookup.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected hostile-fixture C1 validation for UTF-8 paths**
- **Found during:** Task 2 GREEN verification
- **Issue:** The initial assertion inspected raw UTF-8 bytes, so valid continuation bytes in `café.md` were mistaken for standalone C1 control characters.
- **Fix:** Validate decoded Unicode code points while retaining byte-level C0, tab, carriage-return, Markdown-injection, and credential checks.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Commit:** `53489419`

## Issues Encountered

- The expected Task 1 RED run reproduced a swallowed marker exit 31 rendered as `status: complete`.
- The expected Task 2 RED run reproduced Git C-quoted non-ASCII path transport, which caused exact object lookup to exit 128 before publication.

## Known Stubs

None.

## Security and Boundary Notes

- T-138-33 is closed by exit-preserving buffers and exact family failure receipts.
- T-138-34 is closed by NUL-delimited Git output, quoted exact-path lookups, and no untrusted collector-owned filename derivation.
- T-138-35 is closed by sanitizing maintained subjects, selectors, receipts, evidence references, archive summaries, and derived rationale before durable rendering.
- T-138-36 is closed by ambiguity downgrade while retaining the explicit D-17 allowlist, D-18 archive summaries, D-19 exclusions, D-20 aggregation, and proposal-only source preservation.
- No unplanned network endpoint, authentication path, schema boundary, or public/runtime surface was introduced.

## Authorized Focused Repair — 2026-08-28

The user explicitly authorized reopening completed Plan 138-09 to repair the maintained collector classifications that blocked Plan 138-11 live publication. The repair did not edit the canonical ledger, alter Plan 138-11, broaden the D-17 allowlist, or permit partial maintained receipts.

### Root Cause and Repair

- Live collection at evidence base `b70914f503771a73072b046592e19d74ebdf608d` selected six valid D-17 records but classified them from generic content keywords only. Their maintained authority is expressed by canonical source family and stable document structure, so the aggregate ended `partial` with `development-train:ambiguous`.
- Commit `ef980182` adds explicit structural classification for `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/RELEASE-TRAIN.md`, `.planning/DEVELOPMENT-TRAIN.md`, and active cross-session thread records. Canonical planning/train records map to `active / defer-with-trigger / direct_current`; the active roadmap thread maps to `active / defer-with-trigger / corroborated`.
- Singleton planning/train rules require the exact canonical path and two stable headings. The thread rule requires a title, exact `Active cross-session context` status, and purpose line. Swapped train headings, draft headings, wrong milestone structure, and cross-family heading collisions remain `unclassified/ambiguous` and keep the aggregate partial.
- Existing NUL-safe selection, exact-path hashing, sanitization, archive summaries, D-19 exclusions, D-20 aggregation, selector failure receipts, and taxonomy validation remain unchanged.

### Repair Verification

- Expected pre-repair reproduction: live `--scope maintained` receipt reported `status: partial` and one `unclassified/ambiguous` receipt for each of the six records.
- Expected RED fixture run: the new current-planning scenario failed because the receipt was partial before implementation.
- `bash -n scripts/maintainer/baseline_inventory.sh` — passed after the final source edit.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 16 tests and 0 failures, including complete current-record classifications and partial structural near-misses.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `mix ci` — passed: 13 architecture tests, Credo/Sobelow/docs/advisory/package gates, 1385 non-integration tests with 0 failures and 6 skips, and 102 integration tests with 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; no external API integration surface is declared.
- Clean live no-write collection at committed HEAD `ef980182` produced `status: complete`, maintained receipt fingerprint `4ce0c4f30c453366776fa39e3a332b8f7a74c753`, complete receipts for all six source families, one stable REC row per record, no ambiguous receipt, and aggregate maintained exit `0`.
- The live receipt was written only under `/tmp`; the canonical ledger remained unchanged. The external milestone-lock backup at `/tmp/lockspire-milestone-lock.mfrfY0/milestone.lock` remained present.

## Next Phase Readiness

Maintained evidence now fails closed for selector errors and ambiguity and remains safe for hostile valid Git paths. Plan 138-10 can address concurrent publication and interruption proof without inheriting unsafe path parsing or false-complete maintained receipts.

## Self-Check: PASSED

- Confirmed all three changed source/test files and this summary exist.
- Confirmed all four original Task 1/Task 2 RED and GREEN commits plus authorized repair commit `ef980182` exist in Git history.
- Re-ran every original task/plan verification command after the final repair edit and validated the clean live maintained receipt separately.
- Confirmed the changed-file stub scan contains only intentional selector/test literals and no unfinished production behavior.
