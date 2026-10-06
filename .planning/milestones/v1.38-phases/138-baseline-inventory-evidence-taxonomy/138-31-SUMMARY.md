---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "31"
subsystem: release-maintenance
tags: [credential-redaction, safe-identifiers, evidence-boundaries, tdd, fail-closed]
requires:
  - phase: 138-30
    provides: Exact summary-owned authorization for Phase 138 STATE decisions and performance metadata.
provides:
  - Conservative redaction for every 32+ character mixed-case alphanumeric opaque component, including lowercase runs.
  - One closed anchored allowlist for Git object IDs, stable evidence IDs, UUIDs, semantic versions, Lockspire release labels, and component-safe public URLs.
  - Production-path coverage across Git, GitHub, maintained, YAML, receipt, limitation, URL/path, and diagnostic sinks.
affects: [138-32, 138-33, phase-139, repository-reconciliation, release-evidence]
actuals:
  tokens: 8920
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [closed-safe-format-allowlist, component-wise-credential-policy, identity-before-display-redaction]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-31-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Treat semantic versions and public HTTPS URLs as safe only when every 32+ character mixed-case alphanumeric component independently passes the closed public-identifier allowlist."
patterns-established:
  - "Safe identifier boundary: anchored public formats may bypass opaque redaction, but their prefixes and wrappers never authorize an unsafe component."
  - "Cross-sink proof: adversarial values traverse the unchanged production CLI and are rejected by raw-byte assertions after final rendering."
requirements-completed: [BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: "The verifier's exact lowercase-run branch is redacted after stable identity generation and remains proposal-only."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_redaction_gap"
        status: pass
      - kind: other
        ref: "gsd-tools check tdd-red-evidence /tmp/lockspire-138-31-task1-red.json --raw"
        status: pass
    human_judgment: false
  - id: D2
    description: "Lowercase-run opaque values and safe-format near misses are redacted across GitHub, maintained, YAML, URL/path, receipt, limitation, and diagnostic sinks."
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs"
        status: pass
      - kind: other
        ref: "gsd-tools check tdd-red-evidence /tmp/lockspire-138-31-task2-red.json --raw"
        status: pass
    human_judgment: false
  - id: D3
    description: "Named provider, JWT, PEM, bearer, GitHub, and keyword credentials remain independently covered while exact safe identifiers stay visible."
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "test/support/lockspire/release_proof/package_assertions.ex#assert_baseline_inventory_credential_redaction!/0"
        status: pass
    human_judgment: false
  - id: D4
    description: "The external GitHub capability matrix remains fully integrated with no new API surface."
    requirement: LOOSE-01
    verification:
      - kind: other
        ref: "gsd-tools check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy"
        status: pass
    human_judgment: false
duration: 33 min
completed: 2026-09-11
status: complete
---

# Phase 138 Plan 31: Lowercase-Run Credential Redaction Summary

**Opaque OAuth/client credential shapes containing readable lowercase runs now redact at every durable and diagnostic boundary without changing canonical evidence identity.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-09-11T14:52:18Z
- **Completed:** 2026-09-11T15:24:59Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files plus this summary

## Accomplishments

- Reproduced the exact `AbCdEfGhIjKlMnOpQrStUvWxYz012345abcdef` branch leak and removed the generic five-lowercase-character exemption.
- Added a closed anchored public-identifier allowlist while requiring semantic-version and HTTPS URL components to pass the opaque-credential policy independently.
- Exercised the exact value through Git branch/tag/worktree, GitHub PR/issue, maintained subject/reference/rationale, YAML, URL/path, receipt, limitation, and diagnostic renderers.
- Preserved deterministic stable IDs, proposal-only semantics, all named credential families, exact public identifiers, and the existing 8/8 GitHub integration surface.

## Task Commits

Each task used a RED-to-GREEN sequence:

1. **Task 1: Redact one lowercase-run opaque branch through the production collector**
   - `ad557e9b` — RED fixture proving the exact branch leaked raw
   - `d62deaef` — closed safe-format allowlist and conservative opaque redaction
2. **Task 2: Expand the opaque credential vector across every sink and safe control**
   - `4657b248` — RED sink matrix and semantic-version near-miss reproduction
   - `4c177365` — component-wise safe-version validation

**Plan metadata:** final plan metadata commit

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — Adds the anchored safe-public-identifier predicate and removes the lowercase readability escape.
- `test/support/lockspire/release_proof/package_assertions.ex` — Adds exact cross-sink fixtures, independent stable-ID checks, diagnostics, limitations, and safe-format near misses.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-31-SUMMARY.md` — Records implementation, verification, decisions, and traceability.

## Decisions Made

- Semantic-version and HTTPS URL wrappers are safe only when any embedded 32+ character mixed-case/digit component independently matches a closed public format.
- Named AWS, Slack, JWT, PEM, bearer, GitHub, and keyword detection runs before safe-format evaluation, so a public wrapper cannot downgrade a known credential family.
- Canonical stable-ID and deduplication work remains exact and precedes display redaction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented safe HTTPS URLs from masking named provider credentials**

- **Found during:** Task 1 GREEN verification.
- **Issue:** The first allowlist ordering could accept a structurally valid HTTPS URL containing a short AWS access key before provider-specific detection ran.
- **Fix:** Kept every named credential family authoritative by evaluating it before the public-identifier allowlist.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** The focused matrix passed all existing named credential vectors and the new lowercase-run branch.
- **Committed in:** `d62deaef`

**2. [Rule 1 - Bug] Prevented semantic-version prefixes from masking opaque prerelease components**

- **Found during:** Task 2 RED verification.
- **Issue:** A syntactically valid semantic-version wrapper could carry the exact opaque credential as a prerelease identifier.
- **Fix:** Required every credential-shaped semantic-version component to independently pass the closed safe-format allowlist.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** All safe-format near misses redact while exact benign versions remain visible.
- **Committed in:** `4c177365`

**Total deviations:** 2 auto-fixed security bugs.
**Impact on plan:** Both fixes tightened the planned trust boundary without adding dependencies, APIs, or product scope.

## Issues Encountered

- The first UUID near-miss fixture used `A`, which is valid hexadecimal and therefore still formed a valid UUID. The fixture was corrected to non-hexadecimal `G` before recording Task 2 RED evidence.
- The full 33-test hygiene contract took 976.8 seconds because its subprocess-heavy concurrency and relation matrices run in one async module; it completed within the existing bounded test timeouts.

## User Setup Required

None - no external service configuration required.

## Evidence

- `bash -n scripts/maintainer/baseline_inventory.sh` exited 0.
- The focused redaction contract completed with 1 test, 0 failures, and 32 excluded tests.
- The full repository-hygiene contract completed with 33 tests and 0 failures in 976.8 seconds.
- Both TDD RED records returned `RED_EVIDENCE_OK` for the intended assertion-level failures.
- API coverage remained 8/8 integrated, 0 opt-outs, with `block: false`.
- `mix format --check-formatted` passed for the modified ExUnit support file.

## Next Phase Readiness

- Plan 138-32 can publish a fresh immutable ledger containing the complete closeout and redaction fixes.
- Plan 138-33 can then activate the writer-boundary finalizer lifecycle around normal verification.

## Self-Check: PASSED

- All four scoped task commits exist after the recorded pre-plan HEAD.
- Both declared modified source/test files and this summary exist.
- Every task acceptance criterion and the plan-level verification command passed after the final code change.
- No generated or untracked repository file was introduced.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-11*
