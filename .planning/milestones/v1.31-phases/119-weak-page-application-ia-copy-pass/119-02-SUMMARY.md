---
phase: 119-weak-page-application-ia-copy-pass
plan: "02"
subsystem: ui
tags: [phoenix, liveview, admin-ui, dcr, forms]
requires:
  - phase: 118-primitive-meta-component-upgrade
    provides: workflow_shell and form_field primitives for production form grouping
provides:
  - One-form DCR policy workflow grouped by gate, allowlists, lifetimes, auth methods, and posture
  - Focused LiveView proof for unchanged DCR policy params and persistence
affects: [phase-119-admin-page-polish, phase-120-browser-proof]
tech-stack:
  added: []
  patterns: [one submitted policy form with multiple workflow_shell decision groups]
key-files:
  created:
    - .planning/phases/119-weak-page-application-ia-copy-pass/119-02-SUMMARY.md
  modified:
    - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
key-decisions:
  - "Kept DCR policy as one save_policy form with all existing policy[...] field names unchanged."
  - "Used workflow_shell and form_field chrome only; dcr.ex, PolicyForm.changeset/2, and Admin.put_dcr_policy/1 were not changed."
patterns-established:
  - "DCR policy grouping uses workflow_shell inside a single form rather than splitting persistence by visual section."
requirements-completed: [FLOW-02, FLOW-05]
duration: 4 min
completed: 2026-06-26
status: complete
---

# Phase 119 Plan 02: DCR Policy One-Form Workflow Grouping Summary

**DCR policy now scans as five issuer-policy decision groups while preserving the existing save form, params, validation, and persistence path.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-26T08:18:34Z
- **Completed:** 2026-06-26T08:23:01Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added focused DCR LiveView proof for exactly one `form[phx-submit=save_policy]`, all current `policy[...]` names, five workflow headings, workflow shell chrome, the primary CTA, and calm posture copy.
- Reworked `dcr.html.heex` into `Registration gate`, `Allowlist decisions`, `Lifetime defaults`, `Token endpoint auth methods`, and `Risk and posture` groups inside the existing form.
- Preserved `PolicyForm.changeset/2`, `Admin.put_dcr_policy/1`, `dcr.ex`, current field names, and successful array-field persistence.

## Task Commits

1. **RED:** `eb21d09` - `test(119-02): add failing DCR workflow grouping proof`
2. **GREEN:** `688e085` - `feat(119-02): group DCR policy workflow`

Plan metadata is committed separately with this summary.

## Files Created/Modified

- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` - Groups the existing DCR policy form into workflow sections and replaces remaining practical raw field wrappers with shared form chrome.
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs` - Adds one-form, field-name, workflow-heading, copy, and persistence assertions.
- `.planning/phases/119-weak-page-application-ia-copy-pass/119-02-SUMMARY.md` - Records execution, verification, and dirty-baseline handling.

## Decisions Made

- Kept all form controls explicit in HEEx so field IDs, names, and LiveView submit behavior remain visible.
- Left `lib/lockspire/web/live/admin/policies_live/dcr.ex` and `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` unchanged because tests did not expose a semantic mismatch.
- Kept DCR policy copy issuer-oriented: the page does not mint IATs, rotate RATs, update existing clients, or create credential material.

## TDD Gate Compliance

- RED gate passed: `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs` failed on the missing `Registration gate` workflow heading before implementation.
- GREEN gate passed: the same focused DCR test passed after the template change.
- No refactor commit was needed.

## Deviations from Plan

None - plan executed exactly as written.

## Inherited Dirty Baseline

Before Phase 119 edits, `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` already had Phase 118 changes that wrapped `registration_policy` and `dcr_allowed_scopes` in `form_field`. This plan preserved that local baseline and expanded the same template into grouped workflow sections. Because the existing dirty hunks overlapped the Phase 119 implementation area, commit `688e085` necessarily includes the inherited wrapper delta together with the Phase 119 workflow rewrite.

## Issues Encountered

- The checkout contained unrelated dirty files before execution. Only the DCR template, DCR test, and this summary were staged for this plan.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` were not updated or committed because they were already dirty and the execution prompt explicitly prohibited sweeping them into this plan's commits.

## Verification

- `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs` - RED failed as expected before implementation; GREEN passed with 7 tests, 0 failures.
- `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` - 42 tests, 0 failures.
- `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` - 56 tests, 0 failures.

## Known Stubs

None. Stub scan found no placeholder/TODO/FIXME/coming-soon UI in the touched DCR files. The only `extreme caution` occurrence is a negative test assertion that prevents the phrase from rendering.

## Threat Review

- `T-119-02` mitigated: tests assert one `save_policy` form and unchanged `policy[...]` names.
- `T-119-04` mitigated: no credential or key material was added to rendered copy.
- `T-119-06` mitigated: copy keeps DCR policy distinct from IAT/RAT onboarding and existing-client mutation.
- No new network endpoints, auth paths, file access patterns, schema changes, package installs, or trust-boundary surfaces were introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 119 Plan 03. DCR policy grouping is covered by focused LiveView tests and remains behaviorally unchanged.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/119-weak-page-application-ia-copy-pass/119-02-SUMMARY.md`.
- Required task commits exist: `eb21d09`, `688e085`.
- Created/modified files exist and are limited to the DCR template, DCR test, and this summary.
- Automated verification listed above passed.

---
*Phase: 119-weak-page-application-ia-copy-pass*
*Completed: 2026-06-26*
