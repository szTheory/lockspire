---
gsd_state_version: 1.0
milestone: v1.32
milestone_name: Admin Page IA & Interaction Model Polish
current_phase: 124
current_phase_name: Configure Onboarding Propagation Pass
status: verifying
stopped_at: Phase 124 context gathered (assumptions mode)
last_updated: "2026-06-29T21:26:30.838Z"
last_activity: 2026-06-29
last_activity_desc: Phase 123 complete, transitioned to Phase 124
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 11
  completed_plans: 11
  percent: 60
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Phase 123 — Operate Queue Flow Polish

## Current Position

Phase: 124 — Configure Onboarding Propagation Pass
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-06-29 — Phase 123 complete, transitioned to Phase 124

## Most Recent Release

- Version: `1.2.0`
- Release PR: `#41 chore(main): release lockspire 1.2.0`
- Milestone PR: `#40 v1.26 Host Integration & Operator Boundary Hardening`
- Protected publish proof: GitHub Actions run `26502800103`
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.2.0`
- GitHub release: `lockspire-v1.2.0`

## Recently Shipped Milestones

| Milestone | Phases | Plans | Requirements | Status |
|-----------|--------|-------|--------------|--------|
| v1.31 | 116-120 | 14 | 17 | shipped |
| v1.30 | 111-115 | 12 | 17 | shipped |
| v1.29 | 107-110 | 17 | 24 | shipped |
| v1.28 | 103-106 | 2 | 17 | shipped |
| v1.27 | 97-102 | 24 | 28 | shipped |

## v1.31 Phase Plan

| Phase | Name | REQs | Focus |
|-------|------|------|-------|
| 116 | Inventory, Rubric & Lab Contract | 2 | Scope and contracts |
| 117 | Component Lab, Fixtures & Foundation Hardening | 4 | Stress harness and tokens |
| 118 | Primitive & Meta-Component Upgrade | 3 | Shared components |
| 119 | Weak-Page Application & IA/Copy Pass | 5 | Page/group polish |
| 120 | Browser Proof, Docs & Regression Audit | 3 | Verification |

## v1.32 Phase Plan

| Phase | Name | REQs | Focus |
|-------|------|------|-------|
| 121 | Route Scorecards & Judgment Contract | 3 | Baseline and scorecards |
| 122 | Support Investigation Flow Polish | 3 | Tokens and consents |
| 123 | Operate Queue Flow Polish | 3 | Interactions, device auth, logouts |
| 124 | Configure Onboarding Propagation Pass | 3 | Clients, DCR/IAT, keys, policies |
| 125 | Browser Proof, Docs & Adversarial Ratchet | 3 | Fixtures, proof, docs |

## Decisions

- v1.29 is a deliberate second-pass admin UI milestone, not an admin UI rebuild.
- v1.29 treats v1.28 as the baseline and focuses hardest on less-polished support, operations, mobile, and cross-route information architecture.
- The admin journey model remains Orient / Configure / Support / Operate.
- The CSS architecture remains BEM/design-token `lockspire-admin-*`; no Tailwind migration, theming engine, or arbitrary override layer.
- Motion is allowed only when it improves orientation, feedback, or state continuity, and must respect reduced-motion preferences.
- Host-owned seams remain unchanged: Lockspire does not own staff authentication, MFA, role checks, tenant policy, layouts, branding, or developer portal UX.
- v1.30 is an adoption-demo Docker DX and repo-hygiene milestone, not a new protocol or admin UI polish milestone.
- Default local demo access should be direct host-port Docker with Traefik as an optional profile.
- `LOCKSPIRE_DEMO_BASE_URL` should become the single public URL truth for endpoint URL, issuer, seeds, docs, startup output, and smoke proof.
- Phase 113 Plan 01 kept direct Docker as the default path and used Compose project-name precedence for resource isolation.
- Phase 113 Plan 01 kept PostgreSQL host-port exposure absent by default and isolated host access in an explicit override file.
- Phase 113 Plan 01 kept reset scoped to active-project `db_data`, `deps_volume`, and `build_volume` Docker volumes.
- [Phase 113]: Phase 113 Plan 02 kept direct Docker as the default path with optional Traefik isolated in an explicit override file.
- [Phase 113]: Phase 113 Plan 02 attached only web to the external Traefik proxy network while keeping db project-internal.
- [Phase 113]: Phase 113 Plan 02 kept LOCKSPIRE_DEMO_BASE_URL as the hostname smoke truth for Traefik mode.
- [Phase 114]: Plan 01 docker-info uses static allowlisted fixture truth instead of database inspection or seed stdout.
- [Phase 114]: Plan 01 docker-start prints startup information only after wait_for_http succeeds.
- [Phase 114]: Plan 02 kept scripts/demo/adoption_smoke.py as the only black-box OAuth/OIDC proof implementation.
- [Phase 114]: Plan 02 used LOCKSPIRE_DEMO_BASE_URL as the only direct Docker versus optional Traefik smoke switch.
- [Phase 114]: Plan 02 recorded docker compose exec against the running web service as INFO-04 reprint truth.
- [Phase 114]: Plan 03 kept Docker as the default maintainer path with host-local Mix/Postgres as fallback.
- [Phase 114]: Plan 03 documented scripts/demo/adoption_smoke.sh as the maintainer smoke entrypoint while preserving the Python smoke as the black-box proof.
- [Phase 114]: Plan 03 left broader cleanup and hygiene command implementation to Phase 115.
- v1.31 is an admin design-system stress-test milestone, not a protocol, storage, hosted-auth, or public theming milestone.
- The newest brand source is `brandbook/`; older prompt brand guidance is subordinate when it conflicts.
- Keep Phoenix function components and embedded `lockspire-admin-*` BEM/design-token CSS as the default implementation shape.
- Use a lightweight Lockspire-owned component lab/stress surface by default; PhoenixStorybook remains a future option if the bespoke lab stops scaling.
- Adopt Playwright plus axe as quarantined dev/test browser proof unless implementation proves the dependency weight is too high; fallback is Elixir-only contracts plus manual browser evidence with the same matrix.
- Fresh v1.31 browser proof is required after CSS/component/page changes; Phase 110 screenshots are baseline evidence, not current proof.
- No logout retry/discard UI should be added unless an existing domain API backs the action.
- [Phase 120]: Plan 01 derives browser proof route truth from AdminRouter plus only the logout-propagation query workflow. — Keeps Phase 120 route proof source-derived and prevents screenshot filenames from becoming route truth.
- [Phase 120]: Plan 01 keeps browser evidence maintainer-only/manual unless Playwright and axe are human-verified behind checkpoint:human-verify. — Preserves the embedded-library boundary and avoids unverified Node/browser tooling becoming runtime or public support surface.
- [Phase 120]: Plan 02 keeps PROOF-03 blocking guardrails in ExUnit, LiveView, and LazyHTML rather than adding browser or Node tooling. — Preserves the embedded-library/package boundary while making screenshot proof enforceable.
- [Phase 120]: Plan 02 centralizes rendered admin HTML checks in test-only AdminProof helpers for duplicate IDs, ARIA/label references, stable links, generic CTA copy, redaction, and unsupported read-only controls. — Keeps route/component guardrails reusable without exposing new public API.
- [Phase 120]: Operator admin docs explain the v1.31 design-system workflow as maintainer/operator guidance, not a public component API. — Preserves the embedded-library and public-support boundary while giving maintainers the proof workflow they need.
- [Phase 120]: The component lab and stress surface remain internal maintainer proof, not supported admin routes or support-surface truth. — Prevents lab/test infrastructure from becoming runtime behavior, host extension points, or public support claims.
- [Phase 120]: Final proof closes through deterministic Mix guardrails plus explicit manual evidence gaps, without adopting browser package tooling. — Keeps browser tooling weight out of Hex/runtime/package contents while making the remaining manual evidence path explicit.
- [2026-06-27]: The next-roadmap admin coherence pass should stay page-first and narrow: client detail lifecycle safety, DCR policy decision summary, logout queue scanability, and proven shared primitives. — Preserves v1.31's design-system investment without starting a broad redesign.
- [2026-06-27]: Client enable/disable now follows the same explicit confirmation-form pattern as other dangerous admin actions. — Avoids one-click lifecycle mutation while preserving existing admin event semantics and domain APIs.
- [2026-06-27]: `decision_summary` is an internal admin primitive for compact policy/operator posture summaries, not a public theming, storybook, or extension surface. — Keeps admin UI polish inside the embedded-library boundary.
- [2026-06-27]: Logout delivery rows remain read-only support truth with no retry/discard/worker controls unless a backed domain API exists. — Maintains the no-fake-controls operator boundary.
- [2026-06-28]: v1.32 is a page-first admin IA and interaction-model polish milestone, not another foundation rebuild. — Use route scorecards and Support/Operate page evidence before propagating patterns into Configure flows.
- [2026-06-28]: v1.32 persona/JTBD judge artifacts stay deterministic and maintainer-only. — Optional AI reviews may inform taste, but CI and release gates should rely on source/rendered guardrails, fixtures, browser evidence, and human review.
- [2026-06-28]: v1.32 preserves the v1.31 boundary: Phoenix function components, BEM/token CSS, internal lab, no public Storybook/design-system route, and no public theming API. — Prevents design-system polish from becoming new supported product surface.
- [Phase 121]: Plan 121-01 route truth is Lockspire.Web.AdminRouter plus exactly /admin/clients/:client_id/edit?workflow=logout-propagation. — Keeps Phase 121 route judgment deterministic and prevents screenshot filenames or host-specific mounts from becoming route truth.
- [Phase 121]: Plan 121-01 treats dirty admin UI/proof files as candidate evidence only and excludes Docker/demo/Traefik/repo-hygiene dirty work. — Preserves plan scope while keeping useful admin judgment evidence available for later polish.
- [Phase 121]: Phase 121 Plan 02 keeps scorecard route truth source-derived from Phoenix.Router.routes plus one explicit workflow exception. — Prevents screenshot filenames, host mount prefixes, or markdown-only route drift from becoming admin route truth.
- [Phase 121]: Phase 121 Plan 02 keeps scorecard proof test-only with no runtime/package/browser/public theming surface. — Preserves the embedded-library and supported-surface boundary while enabling deterministic CI guardrails.
- [Phase 121]: Plan 121-03 keeps the scorecard workflow maintainer-facing and subordinate to docs/supported-surface.md. — Preserves public support truth while documenting maintainer route judgment workflow.
- [Phase 121]: Plan 121-03 names 121-ROUTE-SCORECARDS.md as the canonical scorecard artifact sourced from AdminRouter plus the logout-propagation query workflow. — Keeps later Support, Operate, and Configure polish anchored to route/judgment guardrails.
- [Phase 122]: Kept token and consent index behavior inside the existing LiveViews and existing Lockspire.Admin list APIs. — Preserves the embedded-library boundary and avoids new storage or route capabilities for support index polish.
- [Phase 122]: Kept raw filter values editable in filter inputs while summaries and rows render redacted account/client/family handles. — Support staff can refine case filters without exposing durable identifiers in decision summaries and dense rows.
- [Phase 122]: Used decision_summary and dense_resource_row instead of adding a new support-row component or table primitive. — Matches Phase 122 design constraints and keeps the admin design-system surface stable.
- [Phase 122]: Token detail uses a four-slot decision summary ahead of metadata. — This preserves the support flow order from the phase UI spec: health, lineage, reuse pressure, and smallest safe action must be visible before raw token fields.
- [Phase 122]: Token and refresh-family destructive actions expose disabled closed-state controls with exact support copy. — This avoids implying retries or broader host actions when the token is already revoked, expired, lacks a family, or the family is already closed.
- [Phase 122]: Consent detail keeps reads and mutation behind existing Lockspire.Admin get/revoke delegations. — Preserves the embedded-library boundary and avoids new storage, route, or protocol capabilities for remembered-grant support polish.
- [Phase 122]: Consent detail derives closed-state UI from remembered grant status with locked copy and disabled controls. — Keeps already-revoked consent UI exact, accessible, and non-action-looking.
- [Phase 122]: Consent revocation consequence copy is limited to future remembered-consent reuse. — Avoids implying host account changes, session termination, token revocation, plaintext recovery, worker control, or broader protocol behavior.
- [Phase 123]: Plan 123-01 kept interaction queue shaping page-local in the existing LiveView and Repository.list_interactions/1 read path. — Preserves the embedded-library boundary while improving /admin/interactions scanability.
- [Phase 123]: Plan 123-01 renders interaction rows with status-derived pressure, safe durable IDs, redacted client/subject handles, prompt, created/activity time, and expiry. — Keeps D-10 allowed fields explicit and protocol-sensitive fixture values hidden.
- [Phase 123]: Plan 123-01 preserved /admin/interactions as read-only support truth with no LiveView command events, routes, storage changes, CSS, or package additions. — Maintains OPERATE-02 and no-fake-controls boundary.
- [Phase 123]: Phase 123 Plan 02 kept device authorization queue shaping page-local in the existing LiveView and Admin.list_device_authorizations/1 read path. — Preserves the embedded-library boundary while improving /admin/device_authorizations scanability.
- [Phase 123]: Phase 123 Plan 02 renders device authorization rows with status-derived pressure, redacted client/subject/authorization handles, expiry, poll interval, next-poll, and lifecycle activity. — Keeps D-11 allowed fields explicit and protocol-sensitive code/hash/verification values hidden.
- [Phase 123]: Phase 123 Plan 02 preserved /admin/device_authorizations as read-only support truth with no LiveView command events, routes, storage changes, CSS, or package additions. — Maintains OPERATE-02 and no-fake-controls boundary.
- [Phase 123]: Plan 123-03 kept logout delivery queue shaping inside the existing LiveView and Repository.list_all_logout_deliveries/0 read path. — Preserves the embedded-library boundary while improving /admin/logouts scanability.
- [Phase 123]: Plan 123-03 renders sanitized logout delivery failure context as HTTP status plus allowlisted failure class only. — Keeps retryable incident context useful without exposing raw response, cookie, endpoint secret, SQL, Oban, logout token, or worker internals.
- [Phase 123]: Plan 123-03 preserved /admin/logouts as read-only support truth with no LiveView command events, worker controls, storage changes, routes, or public APIs. — Maintains OPERATE-02 and no-fake-controls boundary.
- [Phase 123]: Plan 123-04 keeps Phase 123 proof inside design_system_contract_test.exs. — No new shared component, CSS, lab, docs, route, package, browser tooling, or public support surface was added.
- [Phase 123]: Plan 123-04 verifies LiveView route containment with Router path truth plus AdminRouter source module checks. — Phoenix LiveView routes expose Phoenix.LiveView.Plug in route metadata, so source module checks keep the contract deterministic without ad hoc runtime assumptions.
- [Phase 123]: Plan 123-04 asserts dark theme support through color-token-to-semantic-alias remapping. — The admin CSS uses dark --ls-color-* variables to remap semantic --ls-status-* aliases rather than adding new public theme variables.
- [Phase 123]: Plan 123-05 proof stays maintainer-only — Closeout evidence stayed in .planning/123-OPERATE-PROOF.md with no public docs, browser tooling, runtime route, package, source, or test edits.
- [Phase 123]: Plan 123-05 full-suite caveat is scoped outside Operate — Focused Phase 123 route, source-contract, and format checks passed; test.fast failures were in Phase 115 adoption-demo release-readiness assertions and did not name Phase 123 files.

## Blockers/Concerns

- None active.
- `gsd-sdk query init.new-milestone` reported stale helper metadata for latest completed milestone and phase archive path after v1.28 closeout. Do not run destructive phase cleanup from that stale path without rechecking archive targets.

## Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260604-fpq | close v1.29 audit gaps from .planning/v1.29-MILESTONE-AUDIT.md | 2026-06-04 | docs-only | [260604-fpq-close-v1-29-audit-gaps-from-planning-v1-](./quick/260604-fpq-close-v1-29-audit-gaps-from-planning-v1-/) |

## Session Continuity

**Last session:** 2026-06-29T21:26:30.830Z

**Next action:** Execute Phase 123 with `/gsd-execute-phase 123`.
**Resume file:** .planning/phases/124-configure-onboarding-propagation-pass/124-CONTEXT.md
**Stopped at:** Phase 124 context gathered (assumptions mode)
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 107 P01 | 20 min | 1 tasks | 1 files |
| Phase 107 P02 | 8 min | 1 tasks | 1 files |
| Phase 107 P03 | 6 min | 1 tasks | 1 files |
| Phase 108 P01 | 3 min | 3 tasks | 2 files |
| Phase 108 P02 | 3 min | 3 tasks | 3 files |
| Phase 108 P03 | 5 min | 4 tasks | 8 files |
| Phase 109 P01 | 8 min | 2 tasks | 3 files |
| Phase 109 P02 | 5 min | 2 tasks | 3 files |
| Phase 109 P03 | 7 min | 3 tasks | 6 files |
| Phase 109 P04 | 5 min | 2 tasks | 5 files |
| Phase 109 P05 | 6 min | 2 tasks | 6 files |
| Phase 109 P06 | 6 min | 2 tasks | 5 files |
| Phase 110 P05 | 22 min | 3 tasks | 5 files |
| Phase 111 P01 | 24 min | 2 tasks | 2 files |
| Phase 111 P02 | 18 min | 3 tasks | 3 files |
| Phase 113 P01 | 6 min | 3 tasks | 5 files |
| Phase 113 P02 | 4min | 2 tasks | 3 files |
| Phase 114 P01 | 5 min | 2 tasks | 3 files |
| Phase 114 P02 | 4 min | 3 tasks | 3 files |
| Phase 114 P03 | 8 min | 3 tasks | 3 files |
| Phase 118 P01 | 17 min | 3 tasks | 6 files |
| Phase 118 P02 | 17 min | 3 tasks | 6 files |
| Phase 118 P03 | 17 min | 3 tasks | 9 files |
| Phase 120 P01 | 7 min | 3 tasks | 5 files |
| Phase 120 P02 | 13 min | 3 tasks | 10 files |
| Phase 120 P03 | 7 min | 3 tasks | 4 files |
| Phase 121 P01 | 10 min | 2 tasks | 1 files |
| Phase 121 P02 | 7 min | 2 tasks | 2 files |
| Phase 121 P03 | 5 min | 1 tasks | 2 files |
| Phase 122 P01 | 11m45s | 3 tasks | 5 files |
| Phase 122 P02 | 7m23s | 2 tasks | 2 files |
| Phase 122 P03 | 5m | 2 tasks | 4 files |
| Phase 123 P01 | 6 min | 2 tasks | 3 files |
| Phase 123 P02 | 6 min | 2 tasks | 3 files |
| Phase 123 P03 | 8 min | 2 tasks | 3 files |
| Phase 123 P04 | 9 min | 2 tasks | 2 files |
| Phase 123 P05 | 4 min | 2 tasks | 2 files |

## Operator Next Steps

- Discuss Phase 123 with /gsd-discuss-phase 123
