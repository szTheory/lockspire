---
phase: 161-docs-verified-1-6-0-release
plan: 07
subsystem: release
tags: [hex, publication, exact-ref]
requires: ["161-06"]
provides: ["Lockspire 1.6.0 published through protected exact-ref lane", "One-use authorization cleared after successful terminal workflow"]
affects: [161-08, 161-09]
requirements-completed: []
actuals:
  tasks: 4
completed: 2026-10-20
status: complete
---

# Phase 161 Plan 07: Protected 1.6.0 publication

Release run 39481079989 completed successfully for source 428a9c53e02bc573376d0fcac313f047fbbea81c, including exact package proof, publication, public-install verification and terminal receipt. The one-use authorized-SHA variable was deleted and its absence verified after completion.

## Evidence

- Fresh preflight: source matches live main and #121 merge, exact main push CI 39478977350 all seven jobs success, version/tag absent, no stale variable or release run, protected hex-publish environment present.
- User explicitly approved setting the exact-SHA variable and dispatch. Variable read-back matched source; dispatched run head and event verified.
- User then explicitly authorized proceeding whenever CI is green without repeated manual confirmations. After checking successful CI, exact package proof, source, live main and variable again, approved the protected environment through the normal deployment API. Existing protections and settings were preserved.
- All five applicable release jobs succeeded; Maintain Release Please PR was correctly skipped on dispatch. Artifacts include release-package-S, release-evidence-S and terminal release outcome evidence.
- After terminal success, deleted LOCKSPIRE_PHASE143_AUTHORIZED_SHA and confirmed it absent. No secrets or generated key material recorded.

## Next

Independent local verification (plan08) and ledger-on-main (plan09) remain. REL-02 stays unchecked until independent verification and the required release record are established. The conditional authorization covers remaining scoped, verified release steps; failed checks still stop progress.
