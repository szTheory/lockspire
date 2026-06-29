# Phase 124: Configure Onboarding Propagation Pass - Context

**Gathered:** 2026-06-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Propagate the strongest v1.32 page patterns into Configure flows without broadening public APIs, rebuilding the admin shell, adding new admin route surface, or changing host-owned seams. This phase covers existing clients, DCR onboarding, initial access tokens, keys, and policy pages. It clarifies page hierarchy, copy-once handoffs, confirmation/action semantics, mobile/accessibility/theme proof, and deterministic guardrails for CONFIG-01, CONFIG-02, and CONFIG-03.

</domain>

<decisions>
## Implementation Decisions

### Surface Boundary
- **D-01:** Phase 124 only polishes existing Configure routes and existing Admin-backed behavior. Do not add public APIs, new admin shell routes, Storybook/lab routes, public theming surface, host-owned auth/layout seams, schemas, migrations, or protocol behavior.
- **D-02:** Keep route truth subordinate to Phase 121 scorecards and `Lockspire.Web.AdminRouter`. Any new support promise, route, or extension point is out of scope unless already backed by existing domain/Admin API behavior and explicitly required by the phase.

### Page Hierarchy
- **D-03:** Configure pages should converge on the page-first v1.32 pattern: `page_hero` for route intent, posture/summary content before dense lists or forms, grouped safe/secondary/destructive actions, and clear follow-up routes using existing AdminComponents.
- **D-04:** Use a hybrid approach rather than forcing every route into one component shape: use `decision_summary` where current posture and next safe action matter, and use dense rows/lifecycle rows where inventory scanability is the primary task.
- **D-05:** Promote only Support/Operate-proven patterns. Avoid speculative shared Configure components unless planning proves unavoidable duplication and source contracts keep the component internal, route-specific, and bounded.

### Copy-Once Handoff
- **D-06:** DCR/IAT/RAT/client-secret handoff remains copy-once: plaintext appears only at creation or rotation, then the UI returns to redacted posture/inventory and durable partner handoff guidance.
- **D-07:** Do not add plaintext recovery, export, reveal-again, or developer portal UX. Durable rows should show redacted identifiers, status, expiry/revocation, provenance, and follow-up route context without secret material.

### Action Semantics
- **D-08:** Configure risky and destructive actions should use `AdminComponents.confirmation_panel` with clear consequence copy when action confirmation is needed. Browser `data-confirm` should not remain the main model for Configure destructive flows when an inline confirmation pattern is practical.
- **D-09:** Safe, secondary, and destructive Configure controls should be grouped with `AdminComponents.action_group` or the existing page-local action grouping pattern. Keep action hierarchy consistent with token, consent, key, and client lifecycle behavior.
- **D-10:** Confirmation copy should name the concrete consequence and closed state. Avoid generic CTAs, fake queue controls, unsupported retry/discard/approve/deny semantics, or host-owned policy implications.

### Claude's Discretion
- Exact copy and grouping can be refined during planning as long as it preserves the decisions above, route scorecard truth, redaction, existing Admin APIs, and deterministic source/rendered proof.
- Whether a page needs `decision_summary` versus existing pane/metric/list hierarchy is a planner judgment, guided by user task and current route anatomy.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Phase 124 goal, success criteria, and implementation notes.
- `.planning/REQUIREMENTS.md` — CONFIG-01, CONFIG-02, CONFIG-03 and v1.32 scope/out-of-scope boundaries.
- `.planning/PROJECT.md` — Active v1.32 context, validated Phase 121-123 patterns, and product boundary.

### Prior v1.32 Decisions
- `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md` — Route scorecard and judgment-rubric decisions that constrain Configure route truth.
- `.planning/phases/122-support-investigation-flow-polish/122-CONTEXT.md` — Support page decision-summary, consequence-copy, and confirmation decisions to reuse where applicable.
- `.planning/phases/123-operate-queue-flow-polish/123-CONTEXT.md` — Operate read-only, dense-row, redaction, mobile/focus/theme/reduced-motion decisions.
- `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md` — Maintainer-only proof pattern and command-outcome matrix to mirror for Configure proof.

### Configure Source Surfaces
- `lib/lockspire/web/admin_router.ex` — Existing admin route surface and Configure route boundaries.
- `lib/lockspire/admin.ex` — Existing Admin-backed client, policy, initial-access-token, and key behavior.
- `lib/lockspire/web/components/admin_components.ex` — Existing `page_hero`, `decision_summary`, `action_group`, `confirmation_panel`, `copy_once_secret_panel`, `dense_resource_row`, `status_badge`, and `long_value` primitives.
- `lib/lockspire/web/live/admin/clients_live/show.ex` — Client detail posture, support pivots, lifecycle actions, DCR/RAT context, and copy-once RAT behavior.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — Client configuration forms and policy override copy.
- `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` — Copy-once client-secret handoff pattern.
- `lib/lockspire/web/live/admin/dcr_live/index.ex` — Current DCR onboarding overview and partner intake route anatomy.
- `lib/lockspire/web/live/admin/iat_live/index.ex` and `lib/lockspire/web/live/admin/iat_live/index.html.heex` — IAT inventory and current revoke affordance.
- `lib/lockspire/web/live/admin/iat_live/new.ex` and `lib/lockspire/web/live/admin/iat_live/new.html.heex` — IAT minting and copy-once plaintext behavior.
- `lib/lockspire/web/live/admin/keys_live/index.ex` and `lib/lockspire/web/live/admin/keys_live/show.ex` — Key lifecycle posture and action routes.
- `lib/lockspire/web/live/admin/keys_live/action_component.ex` — Existing key lifecycle confirmation panel pattern.
- `lib/lockspire/web/live/admin/policies_live/dcr.ex` and `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` — DCR policy posture and grouped policy form.
- `lib/lockspire/web/live/admin/policies_live/par.ex`, `lib/lockspire/web/live/admin/policies_live/dpop.ex`, and `lib/lockspire/web/live/admin/policies_live/security_profile.ex` — Adjacent policy-page patterns and policy-posture copy.

### Configure Proof Surfaces
- `test/lockspire/web/live/admin/clients_live_test.exs` and `test/lockspire/web/live/admin/clients_live/show_test.exs` — Client route/lifecycle/rendered proof.
- `test/lockspire/web/live/admin/iat_live_test.exs` — IAT copy-once and revoke proof.
- `test/lockspire/web/live/admin/keys_live_test.exs` — Key lifecycle proof.
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs` — DCR policy proof.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` — Source contracts for copy-once, confirmation, route boundary, and v1.32 design-system proof.
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs` — Internal component stress proof for dense/copy-once/confirmation/layout states.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AdminComponents.decision_summary` can carry current posture and next safe action when Configure pages need route-level orientation.
- `AdminComponents.action_group` and `AdminComponents.confirmation_panel` already support safe/secondary/destructive action grouping and inline consequence-oriented confirmations.
- `AdminComponents.copy_once_secret_panel` is already used for IATs, RAT rotation, and client-secret rotation patterns.
- `AdminComponents.dense_resource_row`, `status_badge`, and `long_value` remain the default scanability primitives for inventory-like Configure rows.

### Established Patterns
- Client detail already has the richest Configure anatomy: page hero, entity header, posture sections, support pivots, lifecycle/destructive grouping, DCR/RAT context, and copy-once secret/RAT flows.
- DCR policy already has a decision summary and grouped form, while DCR onboarding, IAT index/new, key index/show, and policy pages show uneven versions of the same model.
- IAT revoke still relies on a browser `data-confirm` pattern, making it the clearest candidate for aligning destructive Configure actions with inline confirmation panels if scope allows.
- Existing tests and design contracts already fence copy-once secret/RAT/IAT flows, risky-action copy, confirmation usage, route boundaries, and public-support boundaries.

### Integration Points
- Existing Admin APIs in `Lockspire.Admin` should remain the integration boundary for Configure behavior.
- Route/source changes should remain within existing LiveViews/components and focused tests.
- Deterministic proof should use ExUnit, Phoenix LiveViewTest, LazyHTML/source contracts, and internal component stress evidence rather than browser tooling as primary proof.
</code_context>

<specifics>
## Specific Ideas

- Treat client detail as the strongest Configure reference pattern, not a contract to copy mechanically into every route.
- Align DCR onboarding, IAT minting/revocation, key lifecycle, and DCR policy around current posture, next safe action, partner/support handoff, and risky action consequences.
- Preserve copy-once plaintext discipline: after acknowledgement or navigation, only redacted durable truth should remain.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

### Reviewed Todos (not folded)

No pending todos matched Phase 124.
</deferred>

---

*Phase: 124-configure-onboarding-propagation-pass*
*Context gathered: 2026-06-29*
