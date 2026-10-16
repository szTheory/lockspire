---
phase: configure-support-page-refinement
plan: "05"
subsystem: ui
tags: [phoenix, liveview, admin, adoption-demo, close-out]
key-files:
  modified:
    - lib/lockspire/web/components/admin_components.ex
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/interactions_live/index.ex
    - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
    - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
    - examples/adoption_demo/lib/adoption_demo_web/router.ex
    - scripts/demo/adoption_smoke.py
    - test/lockspire/adoption_demo_docker_contract_test.exs
    - test/lockspire/web/live/admin/design_system/route_contract_test.exs
requirements-completed: [UI-01, UI-02, UI-06]
duration: close-out audit (no new implementation)
completed: 2026-10-15
status: complete
---

# Phase 153 Plan 05 Summary (close-out)

**Close-out of work already delivered in squash commit d44b95dd (PR #123, Codex autonomous UX sweep). This records an audit of current source and tests; the plan was not re-implemented. One missing contract test was added.**

## Tasks

| Task | Status | Notes |
|------|--------|-------|
| 1. Client pages and adoption demo route | delivered | No eyebrow in `clients_live/index.ex` or `show.ex`. Demo router declares `live("/clients/new", ...ClientsLive.Index, :new)` before `/clients/:client_id`; the docker contract test asserts that source order. `adoption_smoke.py` fetches `/lockspire/admin/clients/new` and asserts "New app" and `client-create-form` without submitting. |
| 2. Read-only history pages | delivered | Interactions, device authorizations and logout deliveries contain no eyebrow input; their tests pass. |
| 3. Remove hero attr, lock contract | delivered-with-gap-fixed | `page_hero/1` has no eyebrow attr or markup (only title, body, class, summary and actions remain). `RouteContractTest` had no eyebrow assertion, so one was added (see Fixes). |

## Verification

- Task 1 command (clients, client show, adoption demo docker contract tests): 85 tests, 0 failures
- Task 2 command (interactions, device authorizations, logout deliveries): 31 tests, 0 failures
- Task 3 command (`route_contract_test.exs`): 9 tests, 0 failures after the added tests (7 before)
- Docker adoption smoke not run (not required by this plan's verify). The review container serves `/admin/clients/new` with HTTP 200 and the "New app" H1 (read-only GET today).

## Fixes

- Added a `RouteContractTest` case asserting that `admin_components.ex` and every `lib/lockspire/web/live/admin/**/*.ex` file contain no "eyebrow" reference. It was committed together with the plan 06 matrix test in `test(153-06)` because both live in the same file.

## Deviations from Plan

- The plan says "all 19 current call sites"; the current source has 13 `page_hero` call sites after later changes. All compile without the attribute.
- The remaining `eyebrow` CSS class in `lib/lockspire/web/live/consent_live.ex` is the end-user consent page, not an admin `page_hero`, so it is out of scope. The `.eyebrow` rule in the demo `html.ex` is the demo's own CSS.
- Later accepted changes (#123, #124, #128, 5ab166a1) were not reverted.
- `mix test.fast` (phase gate) was not run for this plan.

## Gaps

None remaining.
