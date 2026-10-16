---
phase: configure-support-page-refinement
plan: "00"
subsystem: ui
tags: [phoenix, liveview, admin, screenshots, verification]
requires:
  - phase: focused-client-registration-settings
    provides: dedicated client creation route and focused client task pages
provides:
  - complete full-page visual baseline for all 30 current admin routes
  - redaction-checked image index for later comparison and route review
affects: [153-01, 153-02, 153-03, 153-04, 153-05, 153-06, 154]
actuals:
  tokens: 0
  tasks: 1
  commits: 0
tech-stack:
  added: []
  patterns: [synthetic demo screenshots, read-only route navigation, local-only visual artifacts]
key-files:
  created:
    - .planning/phases/153-configure-support-page-refinement/153-BASELINE-SCREENSHOTS.md
    - tmp/admin-ui-polish/v1.42/before/
  modified: []
key-decisions:
  - "Use the isolated lockspire-ui-review demo and its synthetic Billingo seed data; do not reset an existing user demo."
  - "Capture all 30 route-scorecard and client-creation paths before any Phase 153 implementation-source edits."
  - "Keep screenshot PNGs local-only under ignored tmp/ and index them in the tracked manifest."
  - "Record the demo host router's /clients/new shadowing defect for an explicit route-order regression check."
requirements-completed: [UI-01, UI-02, UI-06]
coverage:
  - id: D1
    description: Every current admin path has a pre-edit full-page screenshot.
    verification:
      - kind: manual
        ref: .planning/phases/153-configure-support-page-refinement/153-BASELINE-SCREENSHOTS.md
        status: passed
    human_judgment: true
    rationale: All 30 saved images were visually reviewed for page coverage and sensitive values.
duration: 52min
completed: 2026-10-12
status: completed
---

# Phase 153 Plan 00: Baseline Screenshot Capture

**All 30 current admin routes now have persisted pre-edit screenshots from the synthetic demo.**

## Results

- Captured the 29 route-scorecard paths plus `/admin/clients/new` as full-page PNGs at a consistent desktop scale.
- Saved 30 readable images under `tmp/admin-ui-polish/v1.42/before/`; the tracked manifest records each route, screenshot path, image dimensions, visible sections, and redaction check.
- Reviewed all screenshots. No plaintext credentials, token values, authorization or device codes, or private signing-key material is present.
- Kept the demo read-only and isolated; no user demo database or volume was reset or modified.
- Found an adopter integration defect: the demo's dynamic `/clients/:client_id` route shadows the static `/clients/new` route. The screenshot captures the resulting “Client not found” page for the regression fix.

## Next

Proceed with Phase 153 Plan 01. Plan 05 will include the concrete demo route-order fix and remove repeated headings/instructions found in the client creation and credential-rotation pages.
