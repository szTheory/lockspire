---
phase: 92-advanced-setup-support-truth
plan: 01
subsystem: documentation
tags: [mtls, support-truth, maintainer-guidance, docs]
requires: []
provides:
  - canonical two-pattern mTLS setup story with explicit host prerequisites
  - maintainer guidance that defers advanced setup claims to the canonical support contract
affects: [92-03, docs-supported-surface, release-contracts]
tech-stack:
  added: []
  patterns: [canonical-contract-deference, explicit-host-responsibility-split]
key-files:
  created: []
  modified:
    - docs/mtls-host-guide.md
    - docs/maintainer-release.md
key-decisions:
  - "The default supported mTLS story names exactly two shipped extractor patterns and keeps custom extractors as an escape hatch only."
  - "Maintainer release guidance must defer advanced setup wording back to docs/supported-surface.md instead of restating a second support matrix."
patterns-established:
  - "Advanced setup guides front-load host or infrastructure prerequisites before any Lockspire-owned verification claims."
  - "Maintainer docs can acknowledge advanced setup surfaces but leave canonical wording enforcement to contract tests."
requirements-completed: [GUIDE-01, TRUTH-01, TRUTH-02]
duration: 3min
completed: 2026-05-25
---

# Phase 92 Plan 01: Reconcile MTLS Setup Truth And Maintainer Guidance Summary

**The mTLS host guide and maintainer release guide now teach one narrow advanced-setup story with explicit host-versus-Lockspire ownership.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-25T19:29:00Z
- **Completed:** 2026-05-25T19:31:58Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Reworked the mTLS host guide so it names the two shipped extractor patterns up front, links back to the canonical support contract, and makes TLS termination, trusted forwarding, and anti-spoofing explicit host or infrastructure responsibilities.
- Preserved and strengthened the proxy-header spoofing warning while clarifying that Lockspire only takes over after certificate extraction reaches the request seam.
- Tightened the maintainer release guide so advanced setup claims such as mTLS and protected-route support defer back to `docs/supported-surface.md` and proof-focused contract tests.

## Task Commits

1. **Task 1: Tighten the mTLS host guide around shipped patterns and host responsibilities** - `153185f` (`docs`)
2. **Task 2: Align maintainer guidance to the narrow mTLS support contract** - `6ae1d32` (`docs`)

## Verification

- `mix docs.verify` - PASS
- `rg -n "Lockspire\\.MTLS\\.Extractor\\.CowboyDirect|Lockspire\\.MTLS\\.Extractor\\.ProxyHeader|host app or infrastructure owns TLS termination|trusted forwarding|does not hide or absorb this deployment risk|strip or overwrite" docs/mtls-host-guide.md` - PASS
- `rg -n "docs/supported-surface.md|automatic proxy trust|generic deployment automation|Canonical wording enforcement belongs in the proof-focused contract tests" docs/maintainer-release.md` - PASS

## Files Created/Modified

- `docs/mtls-host-guide.md` - canonical two-pattern mTLS setup story, explicit host prerequisites, and ownership split
- `docs/maintainer-release.md` - advanced setup wording now defers to the canonical support contract and proof-focused contract tests

## Decisions Made

- The canonical contract remains terse while the host guide carries the extraction prerequisites and anti-spoofing detail.
- Custom `Lockspire.MTLS.Extractor` implementations remain supported as an escape hatch without being elevated to first-class support-contract parity.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Known Stubs

None.

## Next Phase Readiness

- Plan `92-03` can now pin the mTLS support contract in `docs/supported-surface.md` and release-readiness assertions using the narrowed wording already established here.

## Self-Check: PASSED

- Found `.planning/phases/92-advanced-setup-support-truth/92-01-SUMMARY.md`
- Verified task commits `153185f` and `6ae1d32` in git history

---
*Phase: 92-advanced-setup-support-truth*
*Completed: 2026-05-25*
