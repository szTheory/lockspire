# Phase 124: Configure Onboarding Propagation Pass - Research

**Researched:** 2026-06-29
**Domain:** Phoenix LiveView admin Configure IA, copy-once credential handling, and deterministic UI proof
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### the agent's Discretion

- Exact copy and grouping can be refined during planning as long as it preserves the decisions above, route scorecard truth, redaction, existing Admin APIs, and deterministic source/rendered proof.
- Whether a page needs `decision_summary` versus existing pane/metric/list hierarchy is a planner judgment, guided by user task and current route anatomy.

### Deferred Ideas (OUT OF SCOPE)

None - analysis stayed within phase scope.

### Reviewed Todos (not folded)

No pending todos matched Phase 124.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONFIG-01 | Configure operator can move through clients, DCR onboarding, IATs, keys, and policy pages with page hierarchy, summaries, actions, and follow-up routes aligned to one deliberate interaction model. [VERIFIED: .planning/REQUIREMENTS.md] | Current route contracts and code show Configure routes under `AdminRouter`; strongest pattern is client detail plus DCR policy; planner should propagate `page_hero`, posture-first summaries, route-specific CTAs, and action grouping to weaker Configure pages. [VERIFIED: codebase grep] |
| CONFIG-02 | Partner-onboarding operator can complete DCR/IAT copy-once and handoff workflows with clear current posture, short-lived credential guidance, and no plaintext leakage after creation. [VERIFIED: .planning/REQUIREMENTS.md] | IAT minting, client creation, client secret rotation, and RAT rotation already use copy-once primitives or Admin APIs that return plaintext only at create/rotate time; planner must keep durable inventory redacted and extend tests around acknowledgement/clear state. [VERIFIED: codebase grep] |
| CONFIG-03 | Security/platform owner can distinguish safe, secondary, and destructive Configure actions through consistent confirmation forms, consequence copy, status semantics, and action grouping. [VERIFIED: .planning/REQUIREMENTS.md] | Client lifecycle and key lifecycle use inline confirmation forms in the current worktree, while IAT revoke still uses `data-confirm`; planner should replace touched Configure destructive browser confirms with `confirmation_panel` and add source/rendered contracts. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 124 is a repo-local Phoenix LiveView UI propagation pass, not a framework, package, protocol, storage, or route expansion phase. The route surface is already bounded by `Lockspire.Web.AdminRouter`, which exposes existing Configure routes for clients, DCR, IATs, keys, and policies. [VERIFIED: lib/lockspire/web/admin_router.ex] The route scorecards make `AdminRouter` plus exactly `/admin/clients/:client_id/edit?workflow=logout-propagation` the route truth, and they explicitly keep lab/browser/proof evidence maintainer-only rather than public support surface. [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md]

The implementation should use existing Phoenix function components and embedded `lockspire-admin-*` CSS primitives. [VERIFIED: AGENTS.md] The current worktree contains the primitives Phase 124 needs: `page_hero`, `decision_summary`, `pane`, `entity_header`, `dense_resource_row`, `copy_once_secret_panel`, `action_group`, `confirmation_panel`, `long_value`, `status_badge`, and `policy_nav`. [VERIFIED: lib/lockspire/web/components/admin_components.ex] The planning risk is not missing building blocks; it is uneven adoption, especially client inventory filter copy, DCR onboarding sequencing, IAT revoke confirmation, key inventory grouping, and PAR/DPoP/security policy pages that are less page-first than DCR policy. [VERIFIED: codebase grep]

The worktree is dirty in admin components, CSS, client detail, DCR policy, and related tests. [VERIFIED: git status --short] Phase 121 classified dirty admin UI/proof changes as candidate evidence, not accepted v1.32 implementation truth. [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md] The planner should therefore inspect diffs before task slicing, preserve user-owned edits, and plan Phase 124 work as small route-scoped changes that do not stage unrelated Docker/demo/hygiene files. [VERIFIED: git diff --stat]

**Primary recommendation:** Plan route-scoped Configure polish using existing AdminComponents and existing Admin/Admin API behavior only; prioritize IAT revoke confirmation, DCR onboarding decision summary, policy overview labels, PAR/DPoP/security posture summaries, key inventory grouping, and source/rendered guardrails for CONFIG-01..03. [VERIFIED: 124-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Build Lockspire as a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape; do not turn Lockspire into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Treat the host seam as explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0` as project stack guidance; local `mix.lock` resolves Phoenix `1.8.7`, LiveView `1.1.30`, Ecto SQL `3.13.5`, Bandit `1.11.1`, Oban `2.21.1`, and OpenTelemetry API `1.5.0`. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs/mix.lock]
- Preserve security defaults: PKCE S256 required by default, exact-match redirect URI validation, client secrets hashed at rest, short-lived single-use auth codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- Use planning references `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/research/SUMMARY.md`. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Configure page hierarchy and copy | Frontend Server (Phoenix LiveView) | Browser / Client | LiveViews render route intent, assign posture state, and handle events; browser behavior is limited to rendered forms/buttons without new hooks. [VERIFIED: codebase grep] |
| Shared visual primitives | Frontend Server (Phoenix function components) | CDN / Static CSS | `AdminComponents` owns reusable markup and `Admin.CSS` owns BEM/token layout, wrapping, focus, theme, and responsive behavior. [VERIFIED: lib/lockspire/web/components/admin_components.ex] [VERIFIED: lib/lockspire/web/admin_css.ex] |
| Client, policy, IAT, and key mutations | API / Backend (`Lockspire.Admin` and existing protocol modules) | Database / Storage | Existing delegates cover client CRUD/rotation/toggle, policies, IAT list/mint/revoke, and key generation/lifecycle; Phase 124 should not add route/API breadth. [VERIFIED: lib/lockspire/admin.ex] |
| Copy-once credential reveal | API / Backend | Frontend Server | Admin/protocol code returns plaintext only when minting or rotating; LiveViews store plaintext in assigns only for the copy-once UI state and clear it on acknowledgement. [VERIFIED: lib/lockspire/admin/initial_access_tokens.ex] [VERIFIED: lib/lockspire/web/live/admin/iat_live/new.ex] |
| Route truth and support boundary | Frontend Server (AdminRouter) | Documentation / Tests | `AdminRouter` defines existing route surface; Phase 121 route scorecards and source tests guard against new routes, public lab/theming, and support-surface creep. [VERIFIED: lib/lockspire/web/admin_router.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Deterministic validation | Test / Maintainer tooling | Frontend Server | Existing proof uses ExUnit, Phoenix LiveViewTest, LazyHTML `HtmlAssertions`, source-contract tests, and component stress tests instead of browser tooling as primary proof. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | Constraint `~> 1.8.5`; locked `1.8.7` | Host-mounted admin router and LiveView shell integration. [VERIFIED: mix.exs/mix.lock] | This is the existing project framework; no route or framework expansion is needed. [VERIFIED: AGENTS.md] |
| Phoenix LiveView | Constraint `~> 1.1.28`; locked `1.1.30` | Server-rendered admin pages, event handling, form submit flows, and LiveView tests. [VERIFIED: mix.exs/mix.lock] | Existing Configure pages are LiveViews; route-scoped polish should stay in LiveView/component boundaries. [VERIFIED: codebase grep] |
| Lockspire AdminComponents | Repo-local | Function-component primitives for heroes, panes, summaries, rows, copy-once panels, action groups, confirmation panels, status badges, and long values. [VERIFIED: lib/lockspire/web/components/admin_components.ex] | Phase 124 decisions explicitly prefer existing AdminComponents over speculative shared Configure components. [VERIFIED: 124-CONTEXT.md] |
| Lockspire Admin CSS | Repo-local | Embedded BEM/design-token CSS for admin layout, dark/system theme aliases, responsive stacking, long-value wrapping, copy-once, and confirmation panels. [VERIFIED: lib/lockspire/web/admin_css.ex] | The UI-SPEC forbids Tailwind/shadcn/public theming migration and keeps `lockspire-admin-*` CSS as the route polish surface. [VERIFIED: 124-UI-SPEC.md] |
| Ecto SQL / PostgreSQL | Ecto SQL locked `3.13.5`; PostgreSQL local `14.17` accepting connections | Existing storage and test repo for clients, IATs, policies, keys, and tests. [VERIFIED: mix.lock] [VERIFIED: local command] | Phase 124 should use existing storage/Admin APIs; no schema or migration work is approved. [VERIFIED: 124-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| LazyHTML | Locked `0.1.11` | Rendered HTML assertions through `HtmlAssertions`. [VERIFIED: mix.lock] | Use in focused LiveView tests for duplicate IDs, ARIA targets, label targets, links, generic CTAs, denied text, and unsupported controls. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| ExUnit / Phoenix.LiveViewTest | Bundled with local Elixir/Mix and LiveView dependency | Focused route tests and event/form proof. [VERIFIED: local command] [VERIFIED: codebase grep] | Use for CONFIG-01..03 rendered behavior, copy-once acknowledgement, and confirmation-form mutation proof. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs] |
| RouteScorecards helper | Repo-local test helper | Parses Phase 121 scorecards and expected AdminRouter route truth. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] | Extend source-contract proof only if Phase 124 needs Configure-specific route/action fences. [VERIFIED: codebase grep] |
| AdminLab fixtures/stress surface | Repo-local test support | Maintainer-only component stress proof for copy-once, confirmation, dense rows, and layout states. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs] | Use only when shared component/CSS changes are touched; do not add public lab routes. [VERIFIED: 124-UI-SPEC.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing AdminComponents | New Configure meta-component | Avoid unless duplication becomes error-prone; new component must remain internal, route-specific, and covered by source contracts. [VERIFIED: 124-CONTEXT.md] |
| LiveView/ExUnit/LazyHTML proof | Browser screenshots/axe as primary proof | UI-SPEC says browser/manual evidence is supplemental only when CSS/layout changes are material; primary proof remains ExUnit/LiveView/LazyHTML/source contracts. [VERIFIED: 124-UI-SPEC.md] |
| Existing LiveViews/Admin APIs | New admin route/API/schema | Phase decisions explicitly forbid public APIs, new admin shell routes, schemas, migrations, and protocol behavior. [VERIFIED: 124-CONTEXT.md] |

**Installation:**

```bash
# No external package installs are approved for Phase 124. [VERIFIED: 124-CONTEXT.md]
```

**Version verification:** Versions were verified locally from `mix.exs`, `mix.lock`, `elixir --version`, `mix --version`, and `psql --version`; no registry lookup or package upgrade is needed. [VERIFIED: local command]

## Package Legitimacy Audit

> Phase 124 installs no external packages. Package legitimacy gate is not required because the approved stack is existing repo-local Phoenix/LiveView/AdminComponents/LazyHTML test infrastructure. [VERIFIED: 124-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | N/A | N/A | N/A | N/A | N/A | No install approved. [VERIFIED: 124-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: 124-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: 124-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Host app staff/operator guard
  -> Lockspire.Web.AdminRouter existing Configure routes
    -> Phoenix LiveView route module
      -> load posture/inventory through Lockspire.Admin or existing protocol module
      -> render AdminComponents page spine
        -> page_hero route intent
        -> decision_summary or metric_grid posture
        -> dense rows / panes / workflow_shell forms
        -> action_group and confirmation_panel where actions coexist
        -> copy_once_secret_panel only for current create/rotate plaintext
      -> LiveView event submit/click
        -> existing Admin API mutation
          -> Repository/storage update or protocol helper
          -> success: reload durable redacted state or reveal copy-once value once
          -> failure: render error_list/error_summary with no backend secret leakage
```

This diagram follows the current embedded admin boundary: host app protects the mount, `AdminRouter` exposes route truth, LiveViews own UI state/events, Admin/protocol modules own mutations, and storage keeps durable state. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/lockspire/web/live/admin/
+-- clients_live/        # Client inventory/detail/forms/secret and RAT flows. [VERIFIED: codebase grep]
+-- dcr_live/            # DCR onboarding hub. [VERIFIED: codebase grep]
+-- iat_live/            # IAT inventory and mint copy-once workflow. [VERIFIED: codebase grep]
+-- keys_live/           # Key inventory/detail/lifecycle actions. [VERIFIED: codebase grep]
+-- policies_live/       # Policy overview and global PAR/security/DPoP/DCR forms. [VERIFIED: codebase grep]

test/lockspire/web/live/admin/
+-- *_live_test.exs                  # Focused rendered/event route proof. [VERIFIED: codebase grep]
+-- design_system_contract_test.exs  # Source/route/component guardrails. [VERIFIED: codebase grep]
+-- design_system_component_stress_test.exs # Internal component stress proof. [VERIFIED: codebase grep]
```

### Pattern 1: Page-First Configure Spine

**What:** Start each touched Configure page with `page_hero`, then show current posture or inventory metrics before rows/forms/actions. [VERIFIED: 124-CONTEXT.md]

**When to use:** Use on clients, DCR onboarding, IATs, keys, and policies when the route is touched for CONFIG-01. [VERIFIED: 124-UI-SPEC.md]

**Example:**

```elixir
# Source: lib/lockspire/web/live/admin/dcr_live/index.ex
<AdminComponents.page_hero
  eyebrow="Configure"
  title="DCR onboarding"
  body="DCR onboarding is the partner intake journey: mint short-lived initial access tokens, review self-registered clients, and route issuer posture changes to DCR policy."
/>
```

### Pattern 2: Decision Summary When Posture Drives Action

**What:** Use `decision_summary` when the operator needs route-level posture plus next safe action before a form or dense content. [VERIFIED: 124-CONTEXT.md]

**When to use:** Strong fit for DCR onboarding and global policy pages; use planner judgment for PAR/DPoP/security so the page does not become card-heavy without reducing ambiguity. [VERIFIED: 124-UI-SPEC.md]

**Example:**

```elixir
# Source: lib/lockspire/web/live/admin/policies_live/dcr.html.heex
<AdminComponents.decision_summary>
  <:item label="Registration gate" value={registration_policy_label(@policy.registration_policy)} />
  <:item label="Token auth methods" value={auth_methods_summary(@policy)} />
</AdminComponents.decision_summary>
```

### Pattern 3: Copy-Once Create/Rotate Flow

**What:** Store plaintext only in the immediate LiveView assign returned from create/rotate/mint and clear it on acknowledgement or navigation; durable rows show redacted posture only. [VERIFIED: 124-CONTEXT.md]

**When to use:** Client secret creation/rotation, IAT mint, and RAT rotation. [VERIFIED: 124-UI-SPEC.md]

**Example:**

```elixir
# Source: lib/lockspire/web/live/admin/iat_live/new.html.heex
<AdminComponents.copy_once_secret_panel
  title="Initial access token minted"
  body="Copy this value now. Lockspire stores only the hash after this response."
  label="Initial access token"
  value={@iat_secret}
/>
```

### Pattern 4: Inline Confirmation Forms For Risky Configure Actions

**What:** Use `confirmation_panel` with checkbox confirmation, consequence copy, explicit errors, and existing Admin API submit events. [VERIFIED: 124-CONTEXT.md]

**When to use:** Client disable/enable, key publish/activate/retire, IAT revoke if the surface is touched, client secret rotation, and RAT rotation where a confirmation is needed. [VERIFIED: 124-UI-SPEC.md]

**Example:**

```elixir
# Source: lib/lockspire/web/live/admin/keys_live/action_component.ex
<AdminComponents.confirmation_panel title="Retire key" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="retire_key">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="retire[confirm]" value="true" />
        <span>Retire key for publication overlap after verifiers have moved off it.</span>
      </label>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

### Anti-Patterns to Avoid

- **Adding routes or public APIs:** Phase 124 only polishes existing Configure routes and Admin-backed behavior. [VERIFIED: 124-CONTEXT.md]
- **Replacing the admin shell:** The UI-SPEC keeps existing navigation and shell stable; do not add shell groups or public component routes. [VERIFIED: 124-UI-SPEC.md]
- **Using `data-confirm` as the final destructive pattern:** IAT revoke currently uses `data-confirm`, but Phase 124 decisions say browser confirms should not remain the main model when inline confirmation is practical. [VERIFIED: lib/lockspire/web/live/admin/iat_live/index.html.heex] [VERIFIED: 124-CONTEXT.md]
- **Inventing a Configure meta-component too early:** Context says only extract a shared internal component if unavoidable duplication appears and source contracts keep it bounded. [VERIFIED: 124-CONTEXT.md]
- **Conflating DCR onboarding and DCR policy:** Operator docs and UI-SPEC keep onboarding at `/admin/dcr`, `/admin/iats`, `/admin/iats/new`, client detail/RAT rotation, and policy at `/admin/policies/dcr`. [VERIFIED: docs/operator-admin.md] [VERIFIED: 124-UI-SPEC.md]
- **Rendering secret-like durable material:** Secret plaintext must appear only during create/rotate/mint copy-once state; durable inventory must use handles/status/timestamps and redacted values. [VERIFIED: 124-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Copy-once credential display | Custom reveal/copy/export/recovery widgets | `AdminComponents.copy_once_secret_panel` plus acknowledgement events | Existing tests already assert IAT plaintext clears after acknowledgement; UI-SPEC bans reveal-again/export/recovery. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs] [VERIFIED: 124-UI-SPEC.md] |
| Dangerous action confirmation | Browser `data-confirm`, modal routes, or one-click `phx-click` mutation | `AdminComponents.confirmation_panel` with checkbox form and consequence copy | Support/Operate and key/client flows already use confirmation forms; Phase 124 specifically targets this for Configure. [VERIFIED: 124-CONTEXT.md] |
| Long identifiers and URLs | Manual truncation or CSS one-offs | `AdminComponents.long_value` | Admin CSS proves `overflow-wrap: anywhere` on long values and copy-once panels. [VERIFIED: lib/lockspire/web/admin_css.ex] |
| Status treatment | New badge classes or color-only state | `AdminComponents.status_badge` and visible text copy | Existing component maps statuses and CSS provides semantic status classes; UI-SPEC requires non-color status meaning. [VERIFIED: lib/lockspire/web/components/admin_components.ex] [VERIFIED: 124-UI-SPEC.md] |
| Route truth | Markdown-only route list or screenshot filename inventory | `Lockspire.Web.AdminRouter` plus Phase 121 `RouteScorecards.expected_routes/0` | Route scorecard tests derive expected routes from `AdminRouter` and one query workflow exception. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Rendered HTML proof | Ad hoc string-only tests for every accessibility condition | `Lockspire.Web.AdminProof.HtmlAssertions` | Helper already covers duplicate IDs, ARIA target references, label targets, links, generic CTAs, denied text, and unsupported controls. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| Admin mutations | Raw Ecto queries in LiveViews or new public functions | Existing `Lockspire.Admin` delegates/protocol helpers | Admin API already covers clients, policies, IATs, and keys; phase forbids broadening Admin/public APIs. [VERIFIED: lib/lockspire/admin.ex] [VERIFIED: 124-CONTEXT.md] |

**Key insight:** Phase 124 is about judgment and propagation, not invention; the dangerous parts are already represented by existing components, Admin APIs, tests, and route scorecards. [VERIFIED: .planning/PROJECT.md]

## Common Pitfalls

### Pitfall 1: Dirty Worktree Becomes Accidental Baseline

**What goes wrong:** Planner treats uncommitted admin component/CSS/client/test diffs as clean baseline and overwrites or stages unrelated work. [VERIFIED: git status --short]

**Why it happens:** Phase 121 allows dirty admin UI/proof files as candidate evidence, while the user explicitly warned there is unrelated dirty work. [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md] [VERIFIED: user prompt]

**How to avoid:** Start planning with a diff inventory for every touched Configure file, then scope tasks to files needed for CONFIG-01..03 and preserve unrelated local edits. [VERIFIED: git diff --stat]

**Warning signs:** Plans that stage broad `lib/lockspire/web/**` or mention Docker/adoption-demo files for this phase are off-scope. [VERIFIED: git status --short]

### Pitfall 2: Route Or API Creep

**What goes wrong:** A page-polish task adds new admin routes, public APIs, schemas, migrations, lab routes, or developer portal affordances. [VERIFIED: 124-CONTEXT.md]

**Why it happens:** Configure onboarding can look like a missing-product problem, but Phase 124 is only existing Configure LiveView/Admin behavior. [VERIFIED: 124-UI-SPEC.md]

**How to avoid:** Every task should name the existing route and existing Admin/protocol function it uses. [VERIFIED: lib/lockspire/web/admin_router.ex] [VERIFIED: lib/lockspire/admin.ex]

**Warning signs:** New `/admin/configure`, `/admin/developer`, Storybook/lab routes, public theming hooks, migrations, or unsupported action labels. [VERIFIED: 124-UI-SPEC.md]

### Pitfall 3: Copy-Once Plaintext Leaks Into Durable States

**What goes wrong:** IAT/RAT/client-secret plaintext remains after acknowledgement, appears in inventory rows, test fixtures, docs, screenshots, logs, or failure copy. [VERIFIED: 124-UI-SPEC.md]

**Why it happens:** Copy-once flows temporarily hold plaintext in LiveView assigns, and tests may capture rendered HTML after mint/rotate. [VERIFIED: lib/lockspire/web/live/admin/iat_live/new.ex]

**How to avoid:** Assert plaintext appears only immediately after create/rotate/mint and is absent after acknowledgement or route return. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs]

**Warning signs:** `copy_once_secret_panel` rendered in durable inventory, raw `<code>` plaintext saved in planning artifacts, or fixture values that look like real secrets. [VERIFIED: 124-UI-SPEC.md]

### Pitfall 4: Inline Confirmations Without Consequence Copy

**What goes wrong:** A destructive action moves from `data-confirm` to a form but still lacks concrete consequence, closed state, or accessible error handling. [VERIFIED: 124-CONTEXT.md]

**Why it happens:** The component supplies the visual panel, but the LiveView must supply exact copy and error state. [VERIFIED: lib/lockspire/web/components/admin_components.ex]

**How to avoid:** For every confirmation task, add tests for missing confirmation, successful mutation, closed/unavailable state, and text that names what changes and what does not. [VERIFIED: test/lockspire/web/live/admin/keys_live_test.exs]

**Warning signs:** Labels like `Revoke`, `Rotate secret`, `Submit`, `Apply`, or `Open workflow` remain on touched surfaces. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

### Pitfall 5: Over-Uniform Page Shapes

**What goes wrong:** Planner forces every Configure page into `decision_summary` or a new shared meta-component, making inventories slower and forms more decorative. [VERIFIED: 124-CONTEXT.md]

**Why it happens:** v1.32 asks for a deliberate interaction model, not identical components everywhere. [VERIFIED: .planning/ROADMAP.md]

**How to avoid:** Use `decision_summary` for posture/next-action ambiguity; use `metric_grid` and dense rows when scanability is the primary task. [VERIFIED: 124-CONTEXT.md]

**Warning signs:** Key/IAT inventory rows lose scanability, or PAR/DPoP/security pages gain summary cards that repeat the form without clarifying consequence. [VERIFIED: 124-UI-SPEC.md]

### Pitfall 6: Policy And Onboarding Jobs Merge

**What goes wrong:** `/admin/policies/dcr` starts minting IATs or rotating RATs, or `/admin/dcr` becomes a policy form clone. [VERIFIED: 124-UI-SPEC.md]

**Why it happens:** DCR policy, IAT creation, self-registered client review, and RAT rotation are adjacent but separate operator jobs. [VERIFIED: docs/operator-admin.md]

**How to avoid:** Keep DCR onboarding hierarchy as policy posture, intake-token state, self-registered clients, then RAT/support handoff; keep global DCR policy as future registration policy only. [VERIFIED: 124-UI-SPEC.md]

**Warning signs:** Policy route copy says it mints tokens, rotates RATs, mutates existing clients, or delivers credentials to partners. [VERIFIED: lib/lockspire/web/live/admin/policies_live/dcr.html.heex]

## Code Examples

Verified patterns from local sources:

### Existing IAT Copy-Once Mint

```elixir
# Source: lib/lockspire/web/live/admin/iat_live/new.ex
case InitialAccessTokens.mint_iat(attrs) do
  {:ok, _iat, plaintext_secret} ->
    socket
    |> put_flash(:info, "Initial access token minted. Copy it now.")
    |> assign(iat_secret: plaintext_secret)
end
```

This pattern is valid only for the immediate copy-once state and must be paired with acknowledgement clearing. [VERIFIED: lib/lockspire/web/live/admin/iat_live/new.ex]

### Existing IAT Plaintext Clear Proof

```elixir
# Source: test/lockspire/web/live/admin/iat_live_test.exs
html_after_ack =
  view
  |> element("button[phx-click=\"acknowledge_copy\"]")
  |> render_click()

HtmlAssertions.assert_no_text(html_after_ack, [plaintext | forbidden_secret_samples()])
```

This is the right test shape for CONFIG-02 copy-once proofs. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs]

### Existing Key Confirmation Form

```elixir
# Source: lib/lockspire/web/live/admin/keys_live/action_component.ex
<AdminComponents.confirmation_panel :if={:retire in @key_detail.next_actions} title="Retire key" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="retire_key">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="retire[confirm]" value="true" />
      </label>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

Use this as the reference shape for IAT revoke and other risky Configure confirmations, with route-specific consequence copy. [VERIFIED: lib/lockspire/web/live/admin/keys_live/action_component.ex]

### Current IAT Revoke Gap

```heex
# Source: lib/lockspire/web/live/admin/iat_live/index.html.heex
<AdminComponents.admin_button
  phx-click="revoke"
  phx-value-id={token.id}
  data-confirm={"Revoke initial access token #{redacted_handle(:iat, token.id)}..."}
  variant={:danger}
>
  Revoke initial access token
</AdminComponents.admin_button>
```

This is the clearest CONFIG-03 refactor candidate because Phase 124 says Configure destructive flows should use inline confirmation forms when practical. [VERIFIED: lib/lockspire/web/live/admin/iat_live/index.html.heex] [VERIFIED: 124-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw or weak admin inventories | Page-first route heroes, posture summaries, dense resource rows, and route-specific CTAs | v1.31/v1.32 Support and Operate work | Configure should copy proven patterns without adding new primitives by default. [VERIFIED: .planning/PROJECT.md] |
| Browser `data-confirm` for destructive actions | Inline `confirmation_panel` forms with checkbox, consequence copy, and accessible errors | Support/Operate and current client/key candidate work | IAT revoke should not remain browser-confirm-only if touched. [VERIFIED: 124-CONTEXT.md] |
| Durable credential visibility ambiguity | Copy-once panel only at create/rotate/mint, followed by redacted durable posture | Existing IAT/client/RAT/client-secret flows | CONFIG-02 should be proven with rendered tests and no plaintext fixtures. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs] |
| DCR as mixed policy/onboarding settings | Separate DCR onboarding hub and DCR policy route | Operator docs and UI-SPEC | Planner should preserve policy/creation/review/rotation separation. [VERIFIED: docs/operator-admin.md] [VERIFIED: 124-UI-SPEC.md] |
| Generic policy overview CTAs | Route-specific `Review ... policy` labels | Phase 124 UI-SPEC target | Replace current `Open workflow` on touched policy overview cards. [VERIFIED: lib/lockspire/web/live/admin/policies_live/index.ex] [VERIFIED: 124-UI-SPEC.md] |

**Deprecated/outdated:**

- `data-confirm` as the main destructive Configure model is outdated for touched practical Configure flows. [VERIFIED: 124-CONTEXT.md]
- Generic labels such as `Apply`, `Open workflow`, one-word `Revoke`, and `Rotate secret` are disallowed for touched Configure surfaces. [VERIFIED: 124-UI-SPEC.md]
- New public Storybook/design-system/lab/theming surfaces remain out of scope. [VERIFIED: 124-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Research validity is estimated at 30 days because this is a repo-local UI planning artifact and no external package/API decision is being made. [ASSUMED] | Metadata | Planner may need to re-run local grep if Phase 124 starts after more admin UI changes land. |

## Open Questions

1. **How should planner handle existing uncommitted admin diffs?**  
   - What we know: The worktree has uncommitted changes in `admin_css.ex`, `admin_components.ex`, client LiveViews, DCR policy files, and design-system tests. [VERIFIED: git status --short]  
   - What's unclear: Which dirty changes are user-owned work to preserve versus intended baseline candidates for Phase 124. [VERIFIED: git diff --stat]  
   - Recommendation: Add a Wave 0 task to inspect diffs for touched files and avoid staging unrelated Docker/demo/hygiene changes. [VERIFIED: user prompt]

2. **Should PAR/DPoP/security policy pages receive `decision_summary` or lighter hero/pane polish?**  
   - What we know: DCR policy already uses a four-item decision summary; PAR/DPoP/security pages currently use policy nav plus section cards and summary grids. [VERIFIED: codebase grep]  
   - What's unclear: Whether summaries reduce ambiguity enough on each page to justify added structure. [VERIFIED: 124-CONTEXT.md]  
   - Recommendation: Plan route-specific decisions: use `decision_summary` where posture plus next safe action is ambiguous; otherwise keep metric/section hierarchy. [VERIFIED: 124-CONTEXT.md]

3. **Does Phase 124 need shared component edits?**  
   - What we know: Existing primitives already cover the approved page patterns, but some primitives are dirty in the worktree. [VERIFIED: lib/lockspire/web/components/admin_components.ex] [VERIFIED: git diff --stat]  
   - What's unclear: Whether Phase 124 can land entirely in route LiveViews/tests without touching shared components/CSS. [VERIFIED: 124-UI-SPEC.md]  
   - Recommendation: Prefer route-only changes; touch shared components/CSS only if a route cannot meet mobile/accessibility/copy-once/confirmation requirements with existing primitives. [VERIFIED: 124-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | yes | 1.19.5 with Erlang/OTP 28 | None needed. [VERIFIED: local command] |
| Mix | Format/tests | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| PostgreSQL | `Lockspire.TestRepo` and LiveView tests | yes | `psql` 14.17; `pg_isready` accepting on `/tmp:5432` | None needed for local focused tests. [VERIFIED: local command] |
| Node | Not required by Phase 124 primary proof | yes | 22.14.0 | Do not add browser/Node proof as primary evidence. [VERIFIED: local command] [VERIFIED: 124-UI-SPEC.md] |
| External web/docs | Not required | not used | N/A | Use local code/planning artifacts. [VERIFIED: user prompt] |

**Missing dependencies with no fallback:**
- None found for the local ExUnit/LiveView/LazyHTML proof path. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest and LazyHTML-backed `HtmlAssertions`. [VERIFIED: mix.exs] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| Config file | `.formatter.exs` for formatting; test setup is via Mix aliases and test support modules. [VERIFIED: .formatter.exs] [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| Full suite command | `MIX_ENV=test mix test.fast --max-failures 5` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CONFIG-01 | Clients, DCR onboarding, IATs, keys, and policies share page-first hierarchy, route-specific CTAs, posture before rows/forms, and follow-up routes. [VERIFIED: .planning/REQUIREMENTS.md] | rendered/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, but needs Phase 124 additions for weaker routes. [VERIFIED: codebase grep] |
| CONFIG-02 | DCR/IAT/client-secret/RAT plaintext appears only at creation/rotation and clears after acknowledgement or route return. [VERIFIED: .planning/REQUIREMENTS.md] | rendered/event | `MIX_ENV=test mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs --max-failures 1` | yes, but extend for RAT/client-secret durable redaction if touched. [VERIFIED: codebase grep] |
| CONFIG-03 | Risky Configure actions use confirmation forms, consequence copy, visible errors, status semantics, and action grouping. [VERIFIED: .planning/REQUIREMENTS.md] | rendered/event/source | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, but IAT revoke confirmation is a Wave 0/implementation gap. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Focused route test(s) for the touched LiveView plus `mix format --check-formatted` on touched `.ex` files. [VERIFIED: mix.exs]
- **Per wave merge:** Focused Configure suite plus `design_system_contract_test.exs`. [VERIFIED: codebase grep]
- **Phase gate:** `MIX_ENV=test mix test.fast --max-failures 5`; Phase 123 proof records known unrelated Phase 115 adoption-demo failures, so planner should document any remaining full-suite caveat precisely. [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md]

### Wave 0 Gaps

- [ ] `test/lockspire/web/live/admin/iat_live_test.exs` - replace IAT revoke click proof with inline confirmation form proof, missing-confirmation error, successful revoke, and no plaintext leakage. [VERIFIED: lib/lockspire/web/live/admin/iat_live/index.html.heex]
- [ ] `test/lockspire/web/live/admin/design_system_contract_test.exs` - add Phase 124 source fence for no `data-confirm` on touched Configure destructive actions, no generic Configure CTAs, no unsupported reveal/export/bulk controls, and route boundary unchanged. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
- [ ] Policy route tests for `policies_live/index`, `par`, `dpop`, and `security_profile` - add page-first hierarchy and route-specific CTA assertions if those pages are touched. [VERIFIED: codebase grep]
- [ ] DCR onboarding test coverage - strengthen `/admin/dcr` proof for policy posture, intake-token state, self-registered clients, and next safe action if adding `decision_summary`. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | No direct implementation change | Host app owns staff/operator authentication before mounting `AdminRouter`; Phase 124 must not add host-owned auth seams. [VERIFIED: AGENTS.md] |
| V3 Session Management | No direct implementation change | Existing Phoenix/LiveView session behavior remains unchanged; no session/token UI or host login behavior is in scope. [VERIFIED: 124-CONTEXT.md] |
| V4 Access Control | Yes | Preserve `AdminRouter` route boundary, host-guarded mount assumption, and existing Admin API behavior; do not add public routes/APIs. [VERIFIED: lib/lockspire/web/admin_router.ex] [VERIFIED: 124-CONTEXT.md] |
| V5 Input Validation | Yes | Keep LiveView forms using existing field labels/help/errors and existing Admin validation paths; add rendered assertions for label/ARIA targets and error copy. [VERIFIED: lib/lockspire/web/components/admin_components.ex] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| V6 Cryptography | Yes, preserve only | Do not hand-roll crypto or reveal private/secret material; IAT/RAT/client-secret hashing/generation stay in existing Admin/protocol/security modules. [VERIFIED: lib/lockspire/admin/initial_access_tokens.ex] [VERIFIED: lib/lockspire/protocol/registration_access_token.ex] |

### Known Threat Patterns for Phoenix LiveView Configure UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret/plaintext disclosure through rendered HTML, fixtures, docs, or screenshots | Information Disclosure | Copy-once panel only during create/rotate/mint, acknowledgement clears plaintext, tests assert denied secret samples. [VERIFIED: test/lockspire/web/live/admin/iat_live_test.exs] |
| Unauthorized surface expansion through new routes or public APIs | Elevation of Privilege | Route truth stays `AdminRouter` plus one query workflow exception; source contracts guard route/support boundary. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Accidental destructive mutation from one-click controls | Tampering | Use `confirmation_panel` checkbox forms and existing Admin APIs; missing confirmation renders error and no mutation. [VERIFIED: test/lockspire/web/live/admin/clients_live/show_test.exs] |
| Backend internals or sensitive storage fields leaking into operator copy | Information Disclosure | Render redacted handles/status/timestamps only; forbid raw hashes, tokens, private keys, request objects, cookies, SQL/Oban internals. [VERIFIED: 124-UI-SPEC.md] |
| Misleading policy/action copy causing unsafe operator decisions | Repudiation / Tampering | Confirmation copy names concrete consequence and closed state; policy pages state future/global scope and do not imply existing client or host-owned changes. [VERIFIED: 124-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack guidance, security defaults, planning references. [VERIFIED: AGENTS.md]
- `.planning/phases/124-configure-onboarding-propagation-pass/124-CONTEXT.md` - locked decisions, discretion, deferred scope, canonical refs, and Configure code insights. [VERIFIED: 124-CONTEXT.md]
- `.planning/phases/124-configure-onboarding-propagation-pass/124-UI-SPEC.md` - approved UI design contract, route contract, copy, interaction, proof, responsive/accessibility/security constraints. [VERIFIED: 124-UI-SPEC.md]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` - requirements, milestone state, phase goal, and prior decisions. [VERIFIED: planning docs]
- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - route truth and Configure scorecards. [VERIFIED: route scorecards]
- `lib/lockspire/web/admin_router.ex` - existing route surface. [VERIFIED: codebase grep]
- `lib/lockspire/web/components/admin_components.ex` and `lib/lockspire/web/admin_css.ex` - component/CSS primitives and responsive/focus/theme/copy-once/confirmation support. [VERIFIED: codebase grep]
- Configure LiveViews under `lib/lockspire/web/live/admin/{clients_live,dcr_live,iat_live,keys_live,policies_live}` - current route anatomy and gaps. [VERIFIED: codebase grep]
- Configure/admin tests under `test/lockspire/web/live/admin/**` and `test/support/lockspire/web/admin_proof/**` - proof stack and existing gaps. [VERIFIED: codebase grep]
- `mix.exs`, `mix.lock`, `.formatter.exs`, local `elixir`, `mix`, `psql`, `pg_isready`, `node` commands - stack and environment availability. [VERIFIED: local command]

### Secondary (MEDIUM confidence)

- None used; no external web/docs research was needed for this local UI propagation planning task. [VERIFIED: user prompt]

### Tertiary (LOW confidence)

- Validity window estimate only. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Existing dependencies and versions were verified from local `mix.exs`, `mix.lock`, and command probes. [VERIFIED: mix.exs/mix.lock] [VERIFIED: local command]
- Architecture: HIGH - Route/component/Admin API boundaries were verified from local source and Phase 121/124 planning artifacts. [VERIFIED: codebase grep] [VERIFIED: 124-CONTEXT.md]
- Pitfalls: HIGH - Risks are visible in local source/tests, UI-SPEC decisions, and dirty worktree status. [VERIFIED: git status --short] [VERIFIED: 124-UI-SPEC.md]

**Research date:** 2026-06-29
**Valid until:** 2026-07-29 [ASSUMED]
