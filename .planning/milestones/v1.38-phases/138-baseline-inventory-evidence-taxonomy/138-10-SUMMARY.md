---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "10"
subsystem: release-maintenance
tags: [git, github, immutable-snapshot, concurrency, semantic-drift]
requires:
  - phase: 138-09
    provides: Fail-closed maintained selectors, NUL-safe hostile-path transport, and deterministic REC identity.
provides:
  - Live production-process proof for same-target interruption and held GitHub pagination contention.
  - Fetch-first immutable snapshot capture with normalized receipt fingerprints and immediate pre-publication rechecks.
  - Read-only fail-closed classifier for immutable ledger ancestry and narrowly authorized Phase 138 bookkeeping drift.
  - Unique current-publication resolution across replacement-ledger history plus executable post-snapshot currentness instructions in generated complete ledgers.
affects: [138-11, phase-139, phase-140, phase-141, release-readiness]
actuals:
  tokens: 19355
  tasks: 3
  commits: 8
tech-stack:
  added: []
  patterns: [bounded immutable snapshot, source receipt fingerprint, semantic lifecycle classifier, process-group signal harness]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-10-SUMMARY.md"]
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Treat the canonical ledger as an immutable snapshot anchored by a ledger-only child commit, then classify later bookkeeping instead of requiring the ledger to be the repository's final write."
  - "Authorize post-snapshot movement only from exact ancestry, identity, subject, path, content, and external-receipt proof; all ambiguity requires refresh."
  - "Treat a gaps_found verification as superseded only when its exact four Phase 138 gap mappings have complete 138-07 through 138-10 summaries."
  - "Resolve a ledger publication from the requested HEAD by requiring exactly one reachable exact-path commit whose direct parent, evidence_base_sha, ledger-only diff, and current blob all agree; missing, mixed, rename-derived, or multiple candidates require refresh."
patterns-established:
  - "Snapshot publication: fetch, capture identity, render bounded projections, fingerprint, re-observe, then atomically rename."
  - "Lifecycle currentness: disclose every first-parent commit and working-tree projection with an authorized_bookkeeping or refresh_required verdict."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Live same-target interruption and held-pagination contention preserve prior bytes, clean owned artifacts, and permit stable retry.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector proves live interruption and pagination contention
        status: pass
    human_judgment: false
  - id: D2
    description: Published ledgers are fetch-first source-stable snapshots with immutable identity and normalized Git, GitHub, and maintained receipt fingerprints rechecked before rename.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector publishes only a source-stable snapshot
        status: pass
    human_judgment: false
  - id: D3
    description: Immutable ledger ancestry and later Phase 138 bookkeeping are classified by exact semantic content while hostile near misses fail closed.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation fails closed on semantically relevant post-snapshot drift
        status: pass
    human_judgment: false
duration: 35min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 10: Immutable Snapshot Currentness Summary

**Live contention proof, fetch-first source-stable publication, and a deterministic semantic classifier for immutable Phase 138 evidence snapshots.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-08-28T19:13:36Z
- **Completed:** 2026-08-28T19:48:36Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Replaced simulated locking coverage with synchronized production collector processes held before rename and during GitHub pagination; INT, TERM, HUP, competing scopes, prior-byte preservation, cleanup, retry, and independent-target behavior are executable.
- Moved the allowed fetch ahead of a single immutable snapshot capture, recorded exact refs/repository/scopes/porcelain, fingerprinted bounded source projections, and rechecked refs plus Git, GitHub, and maintained receipts immediately before atomic publication.
- Added `--verify-snapshot-relation LEDGER`, which proves the ledger-only parent relation and unchanged blob, walks a merge-free first-parent chain, discloses every row, authorizes only exact lifecycle bookkeeping, and rejects hostile content, identities, paths, ancestry, dirty state, and external receipt drift.
- Repaired replacement-ledger resolution so the classifier selects the unique self-validating publication of the current ledger blob instead of the oldest rename-following history entry, with deterministic replacement, missing, mixed, renamed, and ambiguous-DAG fixtures.
- Added the generated `## Post-snapshot currentness relation` section with bounded-as-of disclosure, the exact production classifier command, verdict semantics, refresh instructions, D-08 rerun points, and explicit read-only/proposal-only boundaries.

## Task Commits

1. **Task 1: Prove live same-target interruption and held-pagination contention** — `d32f3785` (RED), `5ae65e4c` (GREEN)
2. **Task 2: Capture and recheck the complete evidence snapshot before publication** — `216ff53c` (RED), `12515211` (GREEN)
3. **Task 3: Classify post-snapshot lifecycle drift by commit shape and semantic content** — `8dbf0632` (RED), `b9ee535b` (GREEN)
4. **Authorized repair: Preserve the proof-quality phase abstraction** — `3786e809` (FIX)
5. **Authorized repair: Restore replacement-ledger and rendered-currentness contracts** — `926292df` (FIX + focused RED/GREEN proof)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — captures and rechecks source-stable snapshots and provides the read-only semantic currentness classifier.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes focused live-writer, snapshot-currentness, and post-snapshot drift contracts.
- `test/support/lockspire/release_proof/package_assertions.ex` — supplies synchronized OS processes, stateful source drift, synthetic lifecycle histories, and hostile near-miss fixtures.

## Decisions Made

- The ledger is immutable evidence, not a perpetual final repository write. Currentness is the exact ledger anchor plus a disclosed, narrowly authorized bookkeeping chain.
- Source fingerprints cover normalized rendered projections only; raw GitHub bodies, logs, credentials, and uncontrolled prose are neither retained nor hashed.
- Todo-close commits remain refresh-required because moving maintained follow-up records changes the collected operational projection.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 16 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; no external product API integration is declared.

### Authorized Repair Verification

- `mix test test/lockspire/quality/proof_quality_baseline_test.exs` — passed, 4 tests and 0 failures; the eight Phase-138-introduced locations are no longer active phase-numbered proof literals.
- `bash -n scripts/maintainer/baseline_inventory.sh && mix test test/lockspire/release/repository_hygiene_contract_test.exs test/lockspire/release_readiness_contract_test.exs` — passed, 18 tests and 0 failures.
- `mix ci` — passed end to end: 13 architecture tests, 1,385 unit/contract tests (6 skipped, 286 excluded), and 102 integration tests (33 excluded), all with 0 failures; formatting, Credo, Sobelow, docs, dependency audit, package build, and migrations also completed successfully.

### Authorized Snapshot Contract Repair Verification

- **RED:** `mix test test/lockspire/release/repository_hygiene_contract_test.exs` failed 2/18 before the source repair: the replacement fixture resolved the original ledger commit and returned `refresh_required`, and the complete candidate omitted `## Post-snapshot currentness relation`.
- `bash -n scripts/maintainer/baseline_inventory.sh` — passed after the repair.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/quality/proof_quality_baseline_test.exs` — passed, 4 tests and 0 failures.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 18 tests and 0 failures, including unique replacement selection and fail-closed missing, mixed, path-renamed, and ambiguous histories.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- Live no-scope collection to `/tmp/lockspire-138-10-repair-live.7L1XCC/baseline-inventory-2026-08-28.md` — passed with `status: complete`, exactly one currentness section, and complete Git branch, tag, worktree, GitHub queue, and maintained-family receipts. The canonical ledger was not written.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; `COVERAGE.md` continues to declare no external product API integration.
- `mix ci` — passed end to end after the final repair: 13 architecture tests, 1,387 unit/contract tests (6 skipped, 286 excluded), and 102 integration tests (33 excluded), all with 0 failures; formatting, Credo, Sobelow, docs, dependency audit, package build, and migrations also completed successfully.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made empty GitHub cleanup a successful no-op on snapshot aborts**

- **Found during:** Task 2 drift-abort verification
- **Issue:** `cleanup_github_temp` returned status 1 when no GitHub temporary directory existed, so `set -e` stopped the explicit snapshot-abort cleanup before its sanitized diagnostic.
- **Fix:** Return success for the empty cleanup case and make owned-file cleanup skip empty paths explicitly.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** All ref/source drift fixtures preserve prior bytes, remove owned artifacts, emit the source-specific diagnostic, and pass stable retry.
- **Committed in:** `12515211`

**2. [Rule 1 - Bug] Replaced phase-numbered proof literals with named phase abstractions**

- **Found during:** Authorized post-completion Plan 138-10 repair after full `mix ci` exposed `ProofQualityBaselineTest` failures at eight Task 3 fixture locations.
- **Issue:** Lifecycle fixture payloads and subjects embedded `Phase 138`, `Phase 139`, and `phase-138` directly, violating the active proof-quality convention even though the synthetic classifier behavior itself was correct.
- **Fix:** Centralized baseline/next phase numbers, labels, and the lifecycle commit prefix, then composed the exact same runtime strings from those named abstractions. No assertion, threshold, exclusion, classifier behavior, or production code changed.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** The narrow quality suite passed 4/4, the combined repository-hygiene and release-readiness suites passed 18/18, and full `mix ci` passed with 1,385 unit/contract plus 102 integration tests at 0 failures.
- **Committed in:** `3786e809`

**3. [Rule 1 - Bug] Kept new currentness assertions inside the proof-quality abstraction**

- **Found during:** Authorized snapshot-contract repair aggregate verification
- **Issue:** Two new assertions embedded future phase labels directly, so the proof-quality baseline correctly rejected them even though the rendered production text was required and correct.
- **Fix:** Added named action and closure phase abstractions and composed the expected strings from those module attributes without weakening any assertion or changing production output.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** The proof-quality suite passed 4/4, the focused repository-hygiene suite passed 18/18, and full `mix ci` passed after the correction.
- **Committed in:** `926292df`

**Total deviations:** 3 auto-fixed bugs.

## Issues Encountered

- The live signal harness needed an isolated process group so INT, TERM, and HUP reached the production collector and its fake child command as a real terminal interruption would. A bounded Python fork wrapper establishes the group while `Port.open` retains deterministic exit/output observation.
- Existing deterministic-output normalization was extended for the new bounded-as-of line after the focused suite correctly detected its timestamp as a second collection-window field.

## Known Stubs

None. TODO/FIXME strings in the changed files are intentional maintained-marker selectors and hostile test fixtures, not unfinished behavior.

## Security and Boundary Notes

- T-138-37 is closed by live process-group holds, all three handled signals, same-target refusal, owned cleanup, retry, and independent-target proof.
- T-138-38 is closed by fetch-first capture, full immutable refs, normalized receipt fingerprints, and immediate pre-rename re-observation.
- T-138-39 and T-138-40 are closed by exact ledger ancestry, bound author/committer identity, semantic lifecycle classes, sanitized disclosures, and hostile near-miss rejection.
- No network endpoint, authentication path, schema boundary, runtime module, Mix task, canonical-ledger write, or disposition action was introduced.

## Next Phase Readiness

Plan 138-11 can publish a replacement canonical ledger from this committed collector, commit it as the direct child of its recorded evidence base, and deterministically resolve that newest valid publication through `--verify-snapshot-relation`. The generated ledger now carries the exact bounded currentness and rerun instructions required by the publication plan.

## Self-Check: PASSED

- Confirmed all three changed source/test files and this summary exist.
- Confirmed all six RED/GREEN task commits plus both authorized repair commits exist in Git history in the required order.
- Re-ran every task and plan verification command against the final committed implementation.
- Re-ran the proof-quality baseline, the combined focused Phase 138/release-readiness suite, and full `mix ci` after the repair.
- Confirmed the authorized snapshot-contract repair commit `926292df` exists, the live no-scope candidate has complete receipts and the currentness section, and the canonical ledger remains untouched.
- Confirmed the stub scan contains only intentional selector/test literals and no unfinished production behavior.
