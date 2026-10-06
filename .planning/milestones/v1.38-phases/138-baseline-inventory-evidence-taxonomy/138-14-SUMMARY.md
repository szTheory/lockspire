---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "14"
subsystem: release-maintenance
tags: [json-lines, git, yaml, utf-8, markdown, fail-closed]
requires:
  - phase: 138-13
    provides: Lock-stable publication and exact working-tree provenance.
provides:
  - Named JSON REC transport that preserves every maintained semantic field under hostile Git paths.
  - Exact tracked-marker exit taxonomy for matched, complete-zero, malformed, and unavailable evidence.
  - Quoted YAML frontmatter, valid UTF-8 output, and reversible invalid-byte display encoding.
affects: [138-15, 138-16, phase-138-verification, phase-139, phase-140, baseline-publication]
actuals:
  tokens: 9472
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [JSON Lines semantic transport, exit-and-buffer evidence taxonomy, format-specific encoding]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-14-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/WINDOWS.md
key-decisions:
  - "Maintained evidence stays as named JSON objects through validation, stable-ID aggregation, and deterministic sorting; Markdown encoding occurs only at the final field boundary."
  - "Tracked-marker exit 1 is complete-zero only with an empty buffer; exit 0 requires valid matched records, and every other or inconsistent result is unavailable."
  - "Valid Unicode is preserved, invalid path bytes are percent-escaped for display, and YAML uses JSON-compatible quoted scalars distinct from Markdown cell encoding."
patterns-established:
  - "Structured REC aggregation: validate invariant named fields by stable ID, merge only reference/rationale/recheck arrays, and suppress contradictory aggregates."
  - "Encoding boundaries: exact Git bytes drive lookup and identity, byte normalization creates safe display values, Markdown escapes cells, and jq quotes YAML scalars."
requirements-completed: [BASE-02, LOOSE-01]
coverage:
  - id: D1
    description: Hostile maintained paths retain one stable REC identity with every lifecycle, disposition, evidence, rationale, confidence, recheck, authority, and execution field attached.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector preserves maintained semantics and valid canonical encoding
        status: pass
    human_judgment: false
  - id: D2
    description: Marker-free repositories produce complete-zero evidence while failed, malformed, and inconsistent marker results remain partial and cannot mask sibling families.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector preserves maintained semantics and valid canonical encoding
        status: pass
    human_judgment: false
  - id: D3
    description: Canonical ledger output has quoted parseable frontmatter, valid UTF-8, intact Unicode, deterministic invalid-byte display, and column-stable Markdown.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector preserves maintained semantics and valid canonical encoding
        status: pass
      - kind: other
        ref: node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query frontmatter.validate .planning/phases/138-baseline-inventory-evidence-taxonomy/138-14-PLAN.md --schema plan-gap-closure
        status: pass
    human_judgment: false
duration: 27min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 14: Structured Maintained Evidence and Canonical Encoding Summary

**Maintained evidence now uses named JSON records, honest marker no-match receipts, quoted YAML scalars, and byte-safe UTF-8/Markdown rendering without changing exact Git identity inputs.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-08-28T23:31:32Z
- **Completed:** 2026-08-28T23:58:29Z
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Replaced the maintained TSV row pipeline with validated JSON Lines objects whose stable-ID aggregation preserves named semantics and merges all discovery references deterministically.
- Distinguished tracked-marker matches, valid zero matches, command failures, malformed records, and impossible exit/buffer combinations without allowing one family to mask another.
- Added Unicode-aware byte normalization, deterministic `%XX` invalid-byte display, separate Markdown cell encoding, jq-backed YAML quoted scalars, and quoted-scalar decoding in the production snapshot reader.
- Added a hostile real-Git fixture covering tabs, newlines, Markdown syntax, shell metacharacters, secrets, `café`, `€`, YAML indicators, quotes, leading/trailing whitespace, and an index-only invalid-byte filename.

## Task Commits

Each TDD task was committed through RED and GREEN gates:

1. **Task 1 RED: Expose maintained row field corruption** — `bde3eab8` (test)
2. **Task 1 GREEN: Preserve maintained semantics in JSON records** — `d904e5d4` (feat)
3. **Task 2 RED: Expose tracked-marker exit taxonomy** — `c655e267` (test)
4. **Task 2 GREEN: Distinguish marker no-match from failure** — `c8c6793b` (fix)
5. **Task 3 RED: Expose invalid YAML and UTF-8 output** — `79175d95` (test)
6. **Task 3 GREEN: Emit quoted YAML and valid UTF-8** — `a354e723` (feat)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — structured REC construction/aggregation, marker exit taxonomy, byte normalization, Markdown encoding, YAML quoting, and quoted frontmatter reads.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — focused maintained semantics and canonical encoding entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` — per-ID semantics, marker matrix, GSD frontmatter parsing, Unicode/invalid-byte repository fixture, and Markdown-column assertions.
- `.planning/WINDOWS.md` — fixed deviation entry for the empty structured aggregate correction.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-14-SUMMARY.md` — canonical plan execution evidence.

## Decisions Made

- JSON objects carry exact named REC semantics until rendering. Stable-ID duplicates may merge discovery families, evidence references, rationales, and rechecks only when every decision-bearing field agrees.
- A tracked-marker exit of 1 proves complete-zero only when its collector-owned output buffer is empty. Exit 0 with no valid record, exit 1 with output, malformed records, and exits greater than 1 all remain fail-visible.
- Exact path bytes continue into quoted Git commands and `git hash-object`; only display values cross normalization and Markdown boundaries. Literal percent bytes are escaped so invalid-byte display remains deterministic and reversible.
- YAML frontmatter uses jq's JSON-compatible double-quoted scalar form. The production relation reader decodes quoted values while continuing to accept earlier unquoted fixture ledgers.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 22 tests and 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query frontmatter.validate .planning/phases/138-baseline-inventory-evidence-taxonomy/138-14-PLAN.md --schema plan-gap-closure` — passed.
- TDD gate order is present for all three tasks: each `test(138-14)` RED commit precedes its corresponding GREEN commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Allowed a valid empty structured aggregate**

- **Found during:** Task 2 RED verification
- **Issue:** Task 1's first JSON aggregation used jq's `-e` exit semantics, so a valid zero-record JSONL input emitted no value and was incorrectly classified as a structured-record failure.
- **Fix:** Retained schema validation and contradiction detection while removing `-e`, allowing an empty aggregate to complete successfully and render the explicit `REC-NONE` row.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** The marker-free complete-zero fixture and the full 22-test repository-hygiene contract passed.
- **Committed in:** `c8c6793b`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug). **Impact on plan:** The correction was required for honest complete-zero evidence and introduced no scope expansion.

## Issues Encountered

None. All three planned RED reproductions failed for the intended semantic, marker-taxonomy, and UTF-8/YAML reasons before their GREEN implementations.

## Known Stubs

None. `TODO` and `FIXME` occurrences are maintained-marker selectors or adversarial fixture inputs, not unfinished implementation. No skipped tests or unrun verification steps remain.

## Security and Boundary Notes

- T-138-55 is closed by named JSON transport, decision-field equality checks, stable-ID aggregation, and per-field final encoding.
- T-138-56 is closed by explicit exit/buffer validation and independent family receipts.
- T-138-57 is closed by distinct Markdown and YAML encoders plus parser round-trip and redaction proof.
- T-138-58 is closed by valid-sequence UTF-8 preservation and deterministic invalid/control-byte display escaping.
- No endpoint, authentication path, schema, runtime module, package dependency, public API, or source-record mutation was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 138-15 can consume quoted frontmatter through the backward-compatible production reader while tightening topology and lifecycle authorization.
- Plan 138-16 can regenerate the canonical ledger with structurally safe maintained rows and valid parseable UTF-8 output.
- No blockers remain from Plan 138-14.

## Self-Check: PASSED

- Confirmed all three implementation/test files, the deviation ledger, and this summary exist.
- Confirmed commits `bde3eab8`, `d904e5d4`, `c655e267`, `c8c6793b`, `79175d95`, and `a354e723` exist in RED/GREEN order.
- Confirmed the coverage classifier accepts all three deliverables as fully automated passing evidence.
- Confirmed no goal-blocking stubs, skipped tests, unrun verification commands, unexpected deletions, or unmodeled threat surfaces remain.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-28*
