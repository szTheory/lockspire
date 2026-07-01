# Phase 123: Operate Queue Flow Polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-29T13:06:49-04:00
**Phase:** 123-operate-queue-flow-polish
**Mode:** assumptions with user-requested research expansion
**Areas analyzed:** Route And Surface Boundary, Queue Anatomy, Applicable Data And Redaction, Read-Only Controls And Proof

## Assumptions Presented

### Route And Surface Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 123 should polish only existing Operate routes `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`, plus internal proof/tests; it should not add admin routes, public lab routes, browser-tooling surface, or support-contract expansion. | Confident | `.planning/ROADMAP.md`; `lib/lockspire/web/admin_router.ex`; `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`; `docs/operator-admin.md` |

### Queue Anatomy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Logout deliveries should remain the strongest presentation pattern, and interactions/device authorizations should be aligned toward that scan model using existing row primitives and existing fields, not tables or a new queue component. | Confident | `.planning/ROADMAP.md`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`; `lib/lockspire/web/live/admin/interactions_live/index.ex`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`; `lib/lockspire/web/components/admin_components.ex` |

### Applicable Data And Redaction

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Endpoint, attempts, channel, and support-note details are logout-delivery-specific; prompt is interaction-specific; device authorization polish should expose only existing durable non-secret device-flow fields such as client, subject, handle, expiry, poll/last-activity context, and status. | Confident | `lib/lockspire/domain/logout_delivery.ex`; `lib/lockspire/domain/interaction.ex`; `lib/lockspire/domain/device_authorization.ex`; `test/lockspire/web/live/admin/device_authorizations_live_test.exs` |

### Read-Only Controls And Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 123 should add no retry, discard, approve, deny, logout-now, requeue, or worker-control UI; verification should extend existing LiveView/source/component tests to prove that boundary plus mobile/theme/reduced-motion/long-value states. | Confident | `lib/lockspire/admin.ex`; `lib/lockspire/admin/device_authorizations.ex`; queue LiveView tests; `lib/lockspire/web/admin_css.ex`; `test/support/lockspire/web/admin_lab/fixtures.ex` |

## User Research Expansion Request

The user asked to research each assumption with subagents, compare pros/cons/tradeoffs, evaluate idiomatic Elixir/Phoenix/Plug/Ecto choices, learn from popular libraries/apps in this and adjacent ecosystems, emphasize DX and user-friendly design, apply prompts/ and the newer brandbook where applicable, and produce one cohesive recommendation set so the user did not need to choose between medium-value options.

## Research Findings

### Route And Surface Boundary

| Approach | Pros | Cons / Footguns | Recommendation |
|----------|------|-----------------|----------------|
| Existing Operate routes only | Matches requirements, preserves route truth, keeps host-mounted admin seam explicit, avoids public support creep. | Does not create a broader operations cockpit; future worker controls stay deferred. | Use this. |
| New `/admin/operate` or queue detail routes | Could centralize operations orientation. | Adds route/docs/scorecard drift and widens supported admin IA. | Defer. |
| Public lab/browser-proof route | Easier visual review. | Converts proof into perceived product surface and risks secret evidence. | Do not add. |
| Retry/discard/approve/deny/worker controls | Useful when backed by explicit APIs and access controls. | Unsafe/fake controls without domain APIs, audit, authorization, and telemetry. | Defer to a future action-capable queue phase. |
| Public host customization/theming seam | Helps deep adopters. | Keycloak-style semver/support burden and blurred host seam. | Defer until strong adopter evidence exists. |

### Queue Anatomy And Operate IA

| Approach | Pros | Cons / Footguns | Recommendation |
|----------|------|-----------------|----------------|
| Align all three queues to logout-delivery scan anatomy | Proven local pattern, read-only truthful, works with existing primitives and Phase 122 dense-row patterns. | Requires route-specific copy and pressure semantics. | Use this. |
| Add shared `operate_queue_row`/`operate_queue_page` | Can reduce duplication if anatomy stabilizes. | Premature abstraction can flatten route-specific domain meaning. | Allow only if duplication becomes error-prone. |
| Responsive table/data grid | Good for sorting/comparison/bulk workflows. | Current job is scanning; table overload and mobile/action-affordance risk. | Do not use in Phase 123. |
| Action-capable job console | Matches Oban/Sidekiq style when real commands exist. | Violates read-only boundary today. | Defer. |

### Applicable Data, Domain Language, And Redaction

| Approach | Pros | Cons / Footguns | Recommendation |
|----------|------|-----------------|----------------|
| Queue-specific internal Operate read models/private helpers | Truthful per route, hides secrets, avoids public API creep, keeps operator nouns precise. | Small internal shaping layer and label/test sync burden. | Use this or equivalent private helpers. |
| Page-local helpers only | Smallest change. | Redaction/domain-language rules stay scattered. | Acceptable for narrow implementation, but keep tests strong. |
| Storage-level projections/selects | Reduces overfetching and sensitive loads. | Broadens repository/admin contracts for UI polish. | Defer unless leak tests demand it. |
| Generic cross-queue row model | Consistent scan anatomy. | Can imply false fields across queues. | Defer unless more queues prove shared lifecycle vocabulary. |

### Read-Only Controls, Verification, And DX

| Approach | Pros | Cons / Footguns | Recommendation |
|----------|------|-----------------|----------------|
| Source/API read-only fence | Fast, deterministic, protects OPERATE-02. | Does not prove rendered branch/layout behavior. | Use as baseline. |
| Focused LiveView + LazyHTML route matrix | Idiomatic, user-observable, stable for Hex CI. | Cannot compute actual browser overflow/focus paint. | Use as primary proof. |
| AdminLab/stress fixture expansion | Good maintainer DX for shared primitives. | Lab creep if route proof becomes indirect. | Use only if shared primitives change. |
| Maintainer-only browser/axe evidence | Verifies computed layout, focus, color scheme, reduced motion. | Node/browser weight, flake risk, sensitive reports. | Supplemental only. |

## Corrections Made

The user did not correct any original assumption. The research expansion strengthened the assumptions into explicit decisions and added ecosystem/DX/UI guidance.

## External Research

- Phoenix function components and slots: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix LiveView testing: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- Phoenix LiveDashboard embedded/admin precedent: https://hexdocs.pm/phoenix_live_dashboard
- Ecto schema redaction: https://hexdocs.pm/ecto/Ecto.Schema.html
- OAuth 2.0 Device Authorization Grant: https://datatracker.ietf.org/doc/html/rfc8628
- OIDC Back-Channel Logout: https://openid.net/specs/openid-connect-backchannel-1_0.html
- OIDC Front-Channel Logout: https://openid.net/specs/openid-connect-frontchannel-1_0.html
- Oban Web dashboard/access-control precedent: https://oban.pro/docs/web/overview.html
- Sidekiq Web retry/dead queue precedent: https://github.com/sidekiq/sidekiq/wiki/Error-Handling
- Sidekiq API race/mutation lessons: https://github.com/sidekiq/sidekiq/wiki/API
- Keycloak admin breadth/theming caution: https://www.keycloak.org/docs/latest/server_admin/index.html
- Django admin internal-management/action-permission precedent: https://docs.djangoproject.com/en/6.0/ref/contrib/admin/
- Cloudscape status indicator: https://cloudscape.design/components/status-indicator/
- Cloudscape table-view guidance: https://cloudscape.design/patterns/resource-management/view/table-view/
- GOV.UK Service Manual: https://www.gov.uk/service-manual
- WAI-ARIA Authoring Practices Guide: https://www.w3.org/WAI/ARIA/apg/
- WCAG reduced-motion technique: https://www.w3.org/WAI/WCAG22/Techniques/css/C39

## Local Prompt And Brand Inputs Applied

- `prompts/lockspire-operator-admin-ia-and-workflows.md`: calm infrastructure software, exact low-anxiety operator copy, no marketing copy in admin, expose enough information for real operations.
- `prompts/lockspire-operator-ux-liveview.md`: thin LiveViews over contexts, function components first, LiveComponents only for local state/event needs, test user-observable behavior, avoid LiveView as a job system.
- `prompts/lockspire-auth-domain-language-field-guide.md`: use account, client, operator, interaction, consent grant, and canonical OAuth/OIDC nouns precisely.
- `prompts/lockspire-security-posture-and-threat-model.md`: redact secrets by default, avoid overbroad token visibility, make unsafe admin workflows impossible without explicit backing.
- `brandbook/`: current visual truth; use `--ls-*` tokens, Signal Cyan/Deep Cyan contrast rules, text status labels, no color-only state, visible focus rings, and reduced-motion behavior.
