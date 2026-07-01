# Phase 119: Weak-Page Application & IA/Copy Pass - Context

**Gathered:** 2026-06-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply the strengthened v1.31 admin design system to the highest-drift admin routes and verify each touched page/group serves its operator job. This phase is page/group polish for FLOW-01 through FLOW-05. It must not change OAuth/OIDC protocol behavior, storage schemas, host-owned seams, supported admin router shape, or introduce new operation-queue actions that are not backed by existing domain APIs.
</domain>

<decisions>
## Implementation Decisions

### Component Adoption Boundary

- **D-01:** Phase 119 should consume existing `Lockspire.Web.Components.AdminComponents` primitives instead of inventing a second design-system layer. Use the Phase 118 structural primitives where they materially improve scanability or safety: `pane`, `entity_header`, `workflow_shell`, `status_cluster`, `lifecycle_row`, `dense_resource_row`, `responsive_table`, `action_group`, `form_field`, `long_value`, and `copy_once_secret_panel`.
- **D-02:** LiveViews keep page intent, URL state, form shape, validation, event handlers, and mutation semantics. Do not introduce domain workflow components, broad LiveComponents, new router entries, a Storybook/lab route, or host-editable admin component APIs in this phase.
- **D-03:** This is not a full route rewrite. Preserve already-stable Phase 109 support and operate behavior where the existing page job, safe action, redaction, and destructive confirmation story is already clear.

### Client Detail IA

- **D-04:** Re-group client detail around the existing operator concepts: identity/current status, effective posture, credentials and assertion-key posture, endpoints and logout, DCR/RAT context, support pivots, and lifecycle/destructive actions. Use structural primitives to make those groups scan as intentional panes or rows rather than one large card with many local sections.
- **D-05:** Preserve existing action destinations and events: routine edit, redirect URI edit, post-logout redirect URI edit, logout propagation query workflow, PAR policy edit, security profile edit, secret rotation, RAT rotation, and `toggle_client`. The planner may change markup/chrome, but not the route/event contract.
- **D-06:** Keep the locked vocabulary split visible on client detail: post-logout redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints. Keep DCR onboarding, self-registered-client provenance, and RAT support distinct from DCR policy.

### DCR Policy Workflow

- **D-07:** Keep DCR policy as one submitted policy form with the existing `phx-submit="save_policy"` behavior and current `policy[...]` field names. Visual grouping should not split persistence or rename params.
- **D-08:** Visually separate DCR policy decisions into gate, allowlist, lifetime, auth-method, and risk/posture groups using shared workflow/field chrome. Preserve current policy semantics, casts, validation, private-key-jwt/client-secret-jwt posture copy, and `Admin.put_dcr_policy/1` persistence behavior.
- **D-09:** Do not add new registration modes, auth methods, policy values, automatic risk actions, or storage changes. This route clarifies existing DCR policy decisions; it does not expand Dynamic Client Registration behavior.

### Support And Operate Surfaces

- **D-10:** Token detail and consent detail should receive targeted primitive/copy alignment only where it improves incident hierarchy or mobile/readability. Preserve existing destructive confirmation panels, `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, and `Admin.revoke_consent/2` behavior.
- **D-11:** IAT index/new should keep the existing DCR onboarding job, copy-once IAT secret behavior, metrics, resource rows, redaction, and revocation semantics. Replace remaining raw field wrappers with shared field/workflow primitives where practical without changing submitted field names.
- **D-12:** Device authorization, interaction, and logout delivery queues remain read-only operator queues. They may clarify page job, primary decision, empty/risk state, non-secret context, and next safe action, but must not add retry, discard, approval, logout, or worker-control UI unless existing domain APIs already back the action.
- **D-13:** Where an Operate page renders resource-list rows inside `lockspire-admin-table-wrap` without a real table, migrate to a clearer non-table structure such as `pane`, `resource_list`, or `dense_resource_row` instead of preserving table-like chrome for list content.

### Microcopy, Redaction, And Guardrails

- **D-14:** Microcopy should be concise, domain-accurate, calm under operator stress, and consequence-oriented. Avoid fear language and generic security-dashboard wording.
- **D-15:** Touched pages must continue to avoid plaintext or unredacted sensitive material: client secrets, RAT plaintext after rotation state, IAT plaintext after creation state, access/refresh token plaintext, authorization codes, cookies, private keys, verifier material, user codes, and raw credential material.
- **D-16:** Verification should extend deterministic LiveView/component/design-system contracts and focused route tests for touched pages. Phase 120 owns the full browser, viewport, theme, reduced-motion, docs, and regression audit proof.

### Claude's Discretion

Planner and executor may choose exact pane titles, grouping order, helper names, and whether a stable support detail page needs light structural migration or only copy/test alignment, provided D-01 through D-16 remain true.

### Folded Todos

No matching pending todos were found for Phase 119.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/ROADMAP.md` - Phase 119 goal, success criteria, and implementation notes.
- `.planning/REQUIREMENTS.md` - FLOW-01 through FLOW-05 acceptance requirements.
- `.planning/STATE.md` - current milestone state and locked v1.31 decisions.
- `.planning/METHODOLOGY.md` - assumption-first, least-surprise, and high-threshold escalation lenses.

### Admin Journey And Inventory

- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md` - locked journey vocabulary and weak-spot priority decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - route jobs, primary decisions, empty/risk states, follow-up routes, and weak/mobile assessments.
- `.planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md` - v1.31 inventory/rubric/lab boundary decisions.
- `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` - route/workflow inventory including logout-propagation query workflow.
- `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` - component API, usage points, missing states, and direct-markup exceptions.

### Design-System Baseline

- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md` - v1.29 token/component decisions and migration boundaries.
- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md` - previous weak-page polish decisions and redaction/copy guardrails.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-CONTEXT.md` - browser/demo/proof baseline and Phase 110 closeout boundaries.
- `.planning/phases/118-primitive-meta-component-upgrade/118-CONTEXT.md` - Phase 118 structural primitive, status, form, and verification decisions.
- `.planning/phases/118-primitive-meta-component-upgrade/118-UI-SPEC.md` - approved UI contract for new primitives and stress proof.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/lockspire/web/components/admin_components.ex` - existing shared Phoenix function components to consume for structural grouping, rows, actions, fields, long values, copy-once material, status badges, and confirmations.
- `lib/lockspire/web/admin_css.ex` - embedded BEM/design-token CSS source for admin layout, component classes, mobile behavior, themes, focus, and motion.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - primary deterministic design-system and route-contract fence to extend for Phase 119.
- Focused route tests under `test/lockspire/web/live/admin/*_test.exs` - route behavior proof for clients, DCR policy, IATs, tokens, consents, device authorizations, interactions, and logout deliveries.

### Established Patterns

- Admin pages use `page_hero` with journey labels and page-job copy before dense content.
- Support pages are investigation surfaces; Operate pages are read-only queue surfaces unless backed by explicit domain APIs.
- Risky actions use confirmation panels or explicit `data-confirm` copy that names non-secret durable context and consequence.
- Long identifiers, URLs, timestamps, account/client handles, family handles, delivery IDs, and redacted values should render through `long_value` or equivalent wrapping treatment.
- Existing tests already fence generic CTAs, inline layout styles, raw admin class drift, redaction-sensitive phrases, and no unsupported browser/screenshot dependency in implementation phases.

### Integration Points

- `lib/lockspire/web/live/admin/clients_live/show.ex` - main FLOW-01 target for client detail regrouping while preserving actions/events.
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`, `lib/lockspire/web/live/admin/policies_live/dcr.ex`, and `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` - FLOW-02 target; one-form semantics must remain stable.
- `lib/lockspire/web/live/admin/iat_live/index.html.heex` and `lib/lockspire/web/live/admin/iat_live/new.html.heex` - FLOW-03 IAT targets; preserve copy-once and submitted field names.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` and `lib/lockspire/web/live/admin/consents_live/show.ex` - FLOW-03 support detail targets; preserve revoke behavior and redaction.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `lib/lockspire/web/live/admin/interactions_live/index.ex`, and `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - FLOW-03/FLOW-04 Operate queue targets; preserve read-only truth and avoid unsupported controls.
</code_context>

<specifics>
## Specific Ideas

- Prefer structural primitives over new abstractions: panes, entity headers, workflow shells, dense rows, and lifecycle rows are the intended Phase 119 vocabulary.
- DCR policy should feel like one coherent workflow with grouped decisions, not a raw vertical field list and not multiple independent forms.
- Operate queue pages should answer what is waiting, risky, failed, completed, or safely reviewable without implying operators can manually retry/discard unless code already supports it.
- No user corrections were applied. The interactive question tool was unavailable in this runtime; all surfaced assumptions were Confident and grounded in current codebase/planning evidence.
</specifics>

<deferred>
## Deferred Ideas

- Full browser, viewport, theme, reduced-motion, docs, and regression proof belongs to Phase 120.
- PhoenixStorybook, public component lab route, React/JS Storybook, public theming engine, and host-editable component registry remain out of scope.
- New retry/discard/approval/logout worker controls for operation queues are deferred unless a later phase adds explicit domain APIs.
- OAuth/OIDC protocol breadth, storage schema changes, hosted admin/service behavior, and public support-surface expansion are out of scope.

### Reviewed Todos (not folded)

None.
</deferred>

---

*Phase: 119-weak-page-application-ia-copy-pass*
*Context gathered: 2026-06-26*
