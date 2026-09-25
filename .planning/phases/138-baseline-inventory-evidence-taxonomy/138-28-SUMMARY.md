---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "28"
subsystem: release-maintenance
tags: [credential-redaction, evidence-boundaries, bash, adversarial-fixtures, tdd]
requires:
  - phase: 138-27
    provides: Live-source receipt authority, bounded closeout metadata, and exact lifecycle transitions.
provides:
  - One centralized conservative credential predicate for Markdown, YAML, receipt, limitation, URL, and diagnostic rendering.
  - Cross-domain production-CLI fixtures for provider credentials, JWTs, PEM markers, bearer values, and opaque secrets.
  - False-positive controls preserving Git object IDs, evidence IDs, UUIDs, versions, public URLs, release names, and prose.
affects: [138-29, phase-139, repository-reconciliation, release-evidence]
actuals:
  tokens: 4993
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [identity-before-display-redaction, centralized credential predicate, production-CLI adversarial fixtures]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-28-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Canonical evidence identity and deduplication remain exact; credential detection runs only at the final display boundary."
  - "Opaque-secret detection requires a long mixed-case alphanumeric component and exempts exact Git object widths plus word-like public identifiers."
  - "Provider-specific, JWT, PEM, bearer, and keyword detection remains independent of the opaque fallback so tightening false positives cannot reopen known credential leaks."
patterns-established:
  - "Credential boundary: every untrusted rendered value passes through credential_like_value via the existing Markdown/YAML field encoders."
  - "Safe collapse: distinct canonical subjects may render as [REDACTED] while retaining distinct stable evidence IDs."
requirements-completed: [BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: "Git branch, tag, and worktree fields redact supported credential shapes without collapsing stable identity."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector redacts credentials at every display boundary"
        status: pass
    human_judgment: false
  - id: D2
    description: "GitHub pull-request and issue display fields route credentials through the centralized redaction boundary."
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_redaction_gap"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maintained record subjects, references, rationales, receipts, and limitations cannot publish supported credential shapes."
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "test/support/lockspire/release_proof/package_assertions.ex#assert_baseline_inventory_credential_redaction!/0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Benign public identifiers and prose remain visible while all prior source and publication contracts remain green."
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs"
        status: pass
      - kind: other
        ref: "gsd-tools check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy"
        status: pass
    human_judgment: false
duration: 1h 53m
completed: 2026-09-10
status: complete
---

# Phase 138 Plan 28: Durable Evidence Credential Redaction Summary

**Centralized credential-shape detection now protects every evidence rendering boundary while exact internal identities and useful public metadata remain intact.**

## Performance

- **Duration:** 1h 53m
- **Started:** 2026-09-10T16:37:00Z
- **Completed:** 2026-09-10T18:29:43Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added one private credential predicate covering AWS access-key shapes, Slack token families, JWTs, PEM private-key markers, bearer credentials, GitHub tokens, keyword-bearing values, and high-confidence opaque components.
- Exercised Git, GitHub, and maintained-source collectors through production CLI fixture paths and proved raw credential sentinels do not reach ledger bytes or test diagnostics.
- Preserved separate stable IDs when distinct canonical subjects collapse to the same redaction marker.
- Pinned safe controls for 40/64-character Git object IDs, evidence IDs, UUIDs, versions, public URLs, readable release names, and ordinary prose.

## Task Commits

Each task was committed atomically through its TDD gates:

1. **Task 1 RED: expose cross-domain credential rendering leaks** - `9ce6eb29` (test)
2. **Task 1 GREEN: centralize credential display redaction** - `3f5dfd82` (fix)
3. **Task 2 RED: pin benign redaction controls** - `6d309fb5` (test)
4. **Task 2 GREEN: bound opaque credential detection** - `fa1b8c46` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` - Central credential predicate and final-boundary routing for rendered evidence and diagnostics.
- `test/lockspire/release/repository_hygiene_contract_test.exs` - Focused `phase138_redaction_gap` contract entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` - Named credential matrix, production collector fixtures, identity-collapse proof, and benign controls.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-28-SUMMARY.md` - Plan evidence and closeout record.

## Decisions Made

- Redaction occurs after canonical stable-ID and deduplication work, preventing display collapse from changing evidence identity or ordering.
- URL and path components are scanned independently so a readable prefix cannot mask an opaque credential carried in one component.
- Human-readable lower-case word runs bound the opaque heuristic; named credential formats remain covered by independent shape checks.

## Verification

- Focused contract: 1 test, 0 failures; 32 excluded.
- Full repository-hygiene contract: 33 tests, 0 failures.
- API coverage: passed, 8 capabilities integrated, 0 opt-outs, `block: false`.
- Shell syntax: `bash -n scripts/maintainer/baseline_inventory.sh` passed.
- Raw sentinel assertions and benign visibility controls passed across Git, GitHub, and maintained collectors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Performance] Removed per-field external opaque matching**

- **Found during:** Task 2 full regression verification.
- **Issue:** The first opaque implementation spawned an external matcher for every rendered field and pushed existing repository contracts beyond their timeout budgets.
- **Fix:** Replaced it with bounded Bash component matching and cheap provider-shape prefilters while preserving the credential matrix.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** Focused redaction, timing-sensitive maintained/GitHub contracts, and the complete 33-test suite pass.
- **Committed in:** `fa1b8c46`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 performance bug)
**Impact on plan:** The correction preserved the planned security boundary and restored prior contract runtime behavior without adding scope or dependencies.

## Issues Encountered

- Early full-suite attempts exposed the per-render external matcher timeout and a dependency-preflight diagnostic interaction. Both were eliminated by the final builtin-only predicate before the successful full run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 138-29 can run final gap verification against a centralized, cross-domain credential boundary.
- No schema, sidecar, runtime/package API, destructive authority, dependency, or GitHub coverage opt-out was added.
- No blockers remain from this plan.

## Known Stubs

None. The newly referenced tracked-marker text is an executable fixture for the existing maintained-source scanner, not an implementation stub.

## Self-Check: PASSED

- All four task commits exist in repository history.
- All three implementation/test files exist and the required verification gates passed.
- The pre-existing `138-VERIFICATION.md` modification retained its original byte hash and was not staged.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-10*
