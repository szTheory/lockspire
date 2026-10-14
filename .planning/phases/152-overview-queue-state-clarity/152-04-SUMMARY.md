---
phase: overview-queue-state-clarity
plan: "04"
subsystem: ui
tags: [phoenix-liveview, admin, logout-deliveries, ux-copy, redaction]

# Dependency graph
requires:
  - phase: 152-02
    provides: Read-only needs-review filter and filtered-history navigation.
provides:
  - Plain-language explanations for each recorded logout-delivery state.
  - Concise delivery-record layout with useful application settings pivots.
affects: [overview-queue-state-clarity, admin-ui]

# Actuals (#2632)
actuals:
  tokens: 1840
  tasks: 2
  commits: 0
plan_head_before: 067235ab818c957b72446eca75c8965581ea7b45
plan_head_after: 067235ab818c957b72446eca75c8965581ea7b45

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Delivery copy describes recorded attempts and responses without claiming a person signed out.
    - Keep one concise explanation beside each status; omit repeated support boilerplate.

key-files:
  created:
    - .planning/phases/152-overview-queue-state-clarity/152-04-task1-red.json
  modified:
    - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
    - test/lockspire/web/live/admin/logout_deliveries_live_test.exs

key-decisions:
  - "Use application and sign-out language for the page; describe server and browser delivery in plain terms."
  - "Keep Retryable and Discarded as recorded status labels while explaining their consequence beside each record."
  - "Preserve the read-only queue and client-detail pivot; do not add a retry or worker control."
  - "Keep the needs-review allowlist from Plan 02 intact."

requirements-completed: [UI-03]
coverage:
  - id: D1
    description: "Logout delivery rows explain what Lockspire tried and what response it recorded in plain language."
    requirement: UI-03
    verification:
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#logout deliveries index renders operate queue buckets and resource rows"
        status: pass
    human_judgment: true
    rationale: "Tests verify the exact copy and its factual limits; how well the wording serves administrators is best judged from the Phase 154 rendered preview."
  - id: D2
    description: "Delivery statuses remain distinct, response details stay sanitized, and loading, failed, empty, and read-only states remain accurate."
    requirement: UI-03
    verification:
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#logout delivery review keeps incident evidence sanitized and read-only"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#failed logout reads show unavailable and a same-route retry"
        status: pass
      - kind: integration
        ref: "test/lockspire/web/live/admin/logout_deliveries_live_test.exs#successful empty logout read shows measured zero"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-10-12
status: complete
---

# Phase 152 Plan 04: Logout Delivery Copy Summary

**Logout delivery records now explain what Lockspire tried and what response the application reported, while preserving uncertainty about whether a person signed out.**

## Performance

- **Duration:** 9 min (approximate)
- **Started:** 2026-10-12T14:21:00Z (approximate)
- **Completed:** 2026-10-12T14:30:00Z (approximate)
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced the queue-implementation hero with “Logout deliveries” and a short explanation of what records show.
- Replaced “Back-channel” and “Front-channel” labels with “Server-to-server” and “Browser,” and described pending, queued, attempted, retryable, discarded, skipped, accepted, and rendered outcomes in plain language.
- Removed repeated support notes and “Failure class” wording. Sanitized HTTP and transport details remain available beside the record.
- Changed the row pivot to “Review application settings”; records remain read-only and no worker action was added.
- Preserved Plan 02’s needs-review filter, exact subset, count, and return-to-history link.

## Task Commits

No task or plan commits were created. The parent orchestrator requested a workspace-only result because Git index writes are blocked; `HEAD` remains `067235ab818c957b72446eca75c8965581ea7b45`.

1. **Task 1: Clarify retryable and discarded delivery outcomes** — workspace-only change; no commit.
2. **Task 2: Keep every logout channel outcome distinct and concise** — workspace-only change; no commit.

## Files Created/Modified

- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` — clarifies titles, channel names, delivery outcomes, and the application-settings pivot; removes repeated support notes.
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` — verifies wording, status distinctions, read states, redaction, read-only behavior, and the retained filtered subset.
- `.planning/phases/152-overview-queue-state-clarity/152-04-task1-red.json` — machine-validated TAP RED evidence for the title assertion before implementation.

## Decisions Made

- Keep “Retryable” and “Discarded” as visible record labels, then explain what happened in the row so they are not mistaken for controls.
- Describe endpoint acceptance and a rendered browser page as delivery facts only; neither proves the relying-party user session ended.
- Keep the shared hero eyebrow because its component API currently requires one, and use “History” rather than the generic section name “Operate.”

## Deviations from Plan

None. The shared hero component requires an eyebrow attribute, so “History” supplies non-duplicative context while retaining the planned single page title.

## Issues Encountered

- The default ExUnit report is not a format accepted by the GSD RED evidence checker. A temporary local TAP formatter was used with the actual `mix test` command; the checker returned `RED_EVIDENCE_OK` for the target heading assertion. The temporary formatter lives under `/private/tmp` and is not part of the project.
- Existing warnings in unrelated modules remain unchanged.

## User Setup Required

None - no external service configuration required.

## Verification

- RED evidence: `gsd check tdd-red-evidence .../152-04-task1-red.json --raw` returned `RED_EVIDENCE_OK` for the named filtered-view test.
- GREEN: `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs --max-failures 1` — 11 tests passed.
- `mix format --check-formatted` passed for the two modified code/test files.
- `git diff --check` passed for the two modified code/test files.

## Next Phase Readiness

Plan 04 is complete in the shared workspace. Phase-level regression checks and the rendered UI review remain with the orchestrator after the sibling plans finish.

---
*Phase: overview-queue-state-clarity*
*Completed: 2026-10-12*

## Self-Check: PASSED (workspace-only)

- Summary, RED evidence, source, and test files exist.
- Coverage metadata validates with no errors; D2 is fully automated and D1 is correctly reserved for preview judgment.
- Focused tests, formatting, and whitespace checks passed.
- No commits were expected; `HEAD` remains `067235ab818c957b72446eca75c8965581ea7b45` per parent orchestration.
