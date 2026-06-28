# Phase 121: Route Scorecards & Judgment Contract - Research Complete

**Researched:** 2026-06-28
**Domain:** Phoenix LiveView admin IA contracts, route scorecards, ExUnit guardrails
**Confidence:** HIGH for codebase-derived findings; MEDIUM for official HexDocs API references

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this section: verbatim from `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions

## Implementation Decisions

### Route Scorecard Truth

- **D-01:** Create one deterministic route scorecard artifact for Phase 121, recommended as `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`, grouped by the locked journeys `Orient`, `Configure`, `Support`, and `Operate`. Prefer one labeled scorecard block per route over one file per route so maintainers can review the whole admin surface without hunting across many small files.
- **D-02:** Derive the required scorecard route set from `Lockspire.Web.AdminRouter` and append exactly one non-router workflow exception: `/admin/clients/:client_id/edit?workflow=logout-propagation`. Publish operator-readable `/admin...` paths only; do not use host-specific mount prefixes or screenshot filenames as route truth.
- **D-03:** Each scorecard must include: route, source truth, journey, persona, JTBD, top task, who/what/where/when/why, entry point, primary decision, primary action, earned-place check, empty state, error state, long-data state, mobile/theme/focus/motion risks, redaction/security check, unsupported-action check, follow-up route, component/group fit, evidence class, public-support promise, runtime/package impact, and notes.
- **D-04:** Follow-up routes in scorecards should resolve to another known admin scorecard route or to the single logout-propagation workflow exception. If a follow-up is external, documentation-only, or deliberately absent, the scorecard must state that explicitly.

### Judgment Rubric And Guardrails

- **D-05:** Use a hybrid proof strategy: human-readable scorecard markdown for judgment, source-derived ExUnit guardrails for route/field/boundary drift, and rendered LiveView/LazyHTML checks for representative route states. Do not rely on markdown alone.
- **D-06:** Phase 121 guardrails should fail on missing or extra scorecards, missing required fields, any second query-workflow exception, unsupported Operate queue actions, generic CTA drift, public lab/theming/storybook/browser-tooling creep, forbidden secret evidence, and follow-up routes that silently point outside the scorecard route set.
- **D-07:** Keep browser/axe/Playwright and optional AI/persona judge review as later maintainer evidence only. They are not Phase 121 requirements, not CI/release gates, not runtime dependencies, and not public support claims.
- **D-08:** The rubric must apply these design pillars to every route: accessibility, responsive reflow, information architecture, security/redaction, theme and motion behavior, performance/tooling weight, maintainability, docs truth, maintainer/developer DX, operator psychology, brand consistency, microcopy, and component fit. `brandbook/` is the current visual/token source of truth; older prompt brand guidance is subordinate if it conflicts.

### Baseline Candidate Boundary

- **D-09:** Treat committed source plus committed planning artifacts as authoritative baseline truth. Treat current dirty admin UI/proof diffs only as baseline candidate evidence to evaluate in scorecards, not as accepted v1.32 implementation.
- **D-10:** The current worktree baseline observed during context capture is branch `milestone/v1.28-admin-ui-operator-experience-polish` at commit `8515245`. Do not infer v1.32 implementation truth from the stale branch name.
- **D-11:** Admin baseline candidates include dirty files under `lib/lockspire/web/admin*`, `lib/lockspire/web/live/admin*`, `test/lockspire/web/live/admin/*`, `test/support/lockspire/web/admin_lab/*`, and the narrow admin refresh text in `.planning/threads/next-roadmap-assessment.md`. They may inform scorecard questions around confirmation-form lifecycle safety, DCR decision summaries, logout queue scanability, theme controls, form-field consistency, and shared component stress coverage.
- **D-12:** Dirty Docker/adoption-demo/Traefik/repo-hygiene files are not Phase 121 truth: `README.md`, `docs/adoption-demo.md`, `Makefile`, `.dockerignore`, `.gitignore`, `examples/adoption_demo/**`, `scripts/demo/**`, `scripts/maintainer/repo_hygiene_check.sh`, `test/lockspire/adoption_demo_docker_contract_test.exs`, `tools/traefik/**`, and `.planning/research/.cache/**`. Do not let them create admin scorecard requirements or v1.32 success criteria.
- **D-13:** Do not stash, revert, clean, or split worktrees as part of Phase 121 context/planning unless separately requested. The planner may recommend branch/worktree cleanup before implementation commits, but this context phase only classifies the dirty work.

### Support Boundary And Lab Creep

- **D-14:** Scorecards may reference internal maintainer proof, but each scorecard must state the support boundary with these fields: `Evidence class`, `Public support promise`, and `Runtime/package impact`.
- **D-15:** Allowed evidence classes are `internal_lab`, `rendered_guardrail`, `manual_browser_note`, and `none`. `internal_lab` can cite `AdminLab.StressSurface`, redaction-safe fixtures, ExUnit/LiveView/LazyHTML guardrails, and maintainer-only browser notes. It must never be classified as `admin_supported`.
- **D-16:** The required boundary wording is: `This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.`
- **D-17:** Forbidden expansions for this phase: public design-system route, PhoenixStorybook/Storybook dependency, public theming API, host component registry, generated host-editable admin components, browser automation support claim, screenshot/trace/report package content, and any `docs/supported-surface.md` claim for lab, browser proof, public theming, or design-system API.

### Ecosystem Lessons To Apply

- **D-18:** Emulate Phoenix LiveDashboard and Oban Web as host-mounted admin surfaces protected by host-owned routing/auth, not standalone products. Keep Lockspire's admin route truth explicit and host seams narrow.
- **D-19:** Preserve Doorkeeper-style install/admin DX, but avoid route-protection ambiguity. Any admin/operator route inventory must be clear about what the host must guard.
- **D-20:** Preserve node-oidc-provider/OpenIddict/Ory/Hydra-style protocol/host seam separation: Lockspire owns protocol/operator state; the host owns account/authentication/product UX. Do not leak backend protocol internals into operator scorecards unless the operator needs them to make a safe decision.
- **D-21:** Apply GOV.UK-style service design: start from user needs, do less, make complex services simple, build services rather than isolated pages, be consistent without forcing uniformity, and make evidence open enough for maintainers to inspect.
- **D-22:** Learn from Cloudscape, GitLab Pajamas, Polaris, WCAG, and WAI-ARIA APG: pair components with patterns, content guidance, accessibility/focus checks, responsive behavior, theme parity, and concrete microcopy rules. Do not treat a design system as colors and cards only.
- **D-23:** Avoid Keycloak-style theming burden and Storybook-style public component/documentation scope creep in v1.32. Internal proof is useful; public theming/component support would become a semver and support burden.

### the agent's Discretion

Planner may choose exact helper names and test module organization, provided the scorecard artifact stays deterministic, route truth remains source-derived from `AdminRouter` plus the single query workflow, and proof stays repo-native. Prefer extracting small test helpers over growing an unreadable omnibus test if implementation pressure warrants it.

### Deferred Ideas (OUT OF SCOPE)

- Public PhoenixStorybook or Storybook route remains deferred to FUTURE-01 only if the internal lab stops scaling.
- Visual snapshot/browser automation remains deferred to later proof phases and requires explicit maintainer approval before package/config/browser artifacts are added.
- Optional AI/persona judge prompts may be documented as maintainer evidence later, but they are not deterministic Phase 121 guardrails.
- Worktree/branch cleanup or splitting dirty admin work from Docker/demo work is not part of this context phase. It can be considered before implementation commits if needed.

### Reviewed Todos (not folded)

None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IA-01 | Maintainer can review a scorecard for every admin route that names persona, JTBD, top task, entry point, primary decision, primary action, empty state, error state, long-data state, mobile/theme/focus risk, and follow-up route. | Use `121-ROUTE-SCORECARDS.md` with one parseable block for each route returned by `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` plus the single query workflow exception. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `lib/lockspire/web/admin_router.ex`; CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| IA-02 | Maintainer can run deterministic guardrails that flag page sections whose hierarchy, redundant actions, generic copy, unsupported affordances, or unearned UI elements violate the v1.32 judgment rubric. | Extend source/read-rendered ExUnit checks in `design_system_contract_test.exs` and reuse `HtmlAssertions` for generic CTA, denied text, links, labels, ARIA targets, and unsupported controls. [VERIFIED: `test/lockspire/web/live/admin/design_system_contract_test.exs`; VERIFIED: `test/support/lockspire/web/admin_proof/html_assertions.ex`] |
| IA-03 | Maintainer can verify v1.32 preserves the v1.31 design-system boundary: Phoenix function components by default, BEM/token CSS, internal lab only, no public design-system route, no required PhoenixStorybook dependency, and no public theming API. | Keep Phase 121 proof in planning markdown plus ExUnit/LiveViewTest/LazyHTML; do not add runtime routes, package files, browser configs, public theming APIs, or support-surface claims. [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `120-BROWSER-PROOF.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `mix.exs`] |
</phase_requirements>

## Summary

Phase 121 should produce a deterministic scorecard contract, not a new UI pass. The core artifact should be `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`, grouped by `Orient`, `Configure`, `Support`, and `Operate`, with one parseable scorecard block per route/workflow. The route set is 28 mounted `Lockspire.Web.AdminRouter` routes plus exactly one query workflow exception, `/admin/clients/:client_id/edit?workflow=logout-propagation`, for 29 total scorecards. [VERIFIED: `MIX_ENV=test mix run -e ... Phoenix.Router.routes(...)`; VERIFIED: `lib/lockspire/web/admin_router.ex`; VERIFIED: `121-CONTEXT.md`]

The recommended proof shape is a focused ExUnit contract that parses the scorecard markdown, derives route truth from the router module, appends only the query workflow exception, and checks required fields, allowed evidence classes, support-boundary wording, follow-up route validity, generic CTA drift, unsupported action drift, secret-denylist drift, and lab/public-surface creep. Rendered checks should reuse the existing `Lockspire.Web.AdminProof.HtmlAssertions` helpers rather than introducing another HTML assertion vocabulary. [VERIFIED: `test/support/lockspire/web/admin_proof/html_assertions.ex`; VERIFIED: `test/lockspire/web/live/admin/design_system_contract_test.exs`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

Existing dirty admin work is useful only as baseline-candidate evidence. Current dirty admin candidates include shared component/CSS expansion, confirmation-form lifecycle safety, DCR decision summary, logout-delivery scanability, theme control, and lab/stress fixture expansion; dirty Docker/adoption-demo/Traefik/repo-hygiene files must not become v1.32 planning truth. [VERIFIED: `git diff --stat`; VERIFIED: `.planning/threads/next-roadmap-assessment.md`; VERIFIED: `121-CONTEXT.md`]

**Primary recommendation:** implement `121-ROUTE-SCORECARDS.md` plus one focused source/rendered ExUnit guardrail path; install no packages and make no public lab, theming, browser-tooling, or support-surface commitments. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`; VERIFIED: `docs/supported-surface.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Route scorecard inventory | Planning artifact | ExUnit source contract | The human judgment lives in markdown, while route completeness is enforced by tests derived from `AdminRouter`. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `design_system_contract_test.exs`] |
| Route extraction | Test suite | Admin router source | `Phoenix.Router.routes/1` can derive compiled router paths; existing tests already use source-derived route helpers, but the router API is less regex-sensitive. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html; VERIFIED: `design_system_contract_test.exs`] |
| Query workflow exception | Planning artifact | Test suite | The logout-propagation workflow is URL/query truth in `ClientsLive.Show`, not a Phoenix route, so tests should append it explicitly and reject any second `?workflow=` scorecard. [VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`; VERIFIED: `docs/operator-admin.md`] |
| Judgment rubric | Planning artifact | Test suite | The rubric is qualitative, but tests can enforce required fields, deny unsupported affordances, and prevent missing earned-place checks. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `116-VISUAL-UX-RUBRIC.md`] |
| Rendered HTML guardrails | Test suite | LiveView components | Existing `HtmlAssertions` covers duplicate IDs, ARIA references, labels, links, generic CTA text, denied text, and unsupported controls. [VERIFIED: `html_assertions.ex`] |
| Lab/support boundary | Public docs and tests | Planning artifact | `docs/supported-surface.md` is the public ceiling, while lab/stress evidence stays maintainer-only and test/support scoped. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `design_system_component_stress_test.exs`] |
| Dirty baseline classification | Planning artifact | Git status/diff | The phase should classify dirty admin candidate evidence and explicitly exclude Docker/demo/Traefik/repo-hygiene changes from scorecard truth. [VERIFIED: `git status --short`; VERIFIED: `121-CONTEXT.md`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 on OTP 28 | Runs ExUnit and source contracts. | Available locally and already used by the project test aliases. [VERIFIED: `elixir --version`; VERIFIED: `mix --version`; VERIFIED: `mix.exs`] |
| Phoenix | Resolved `1.8.7` | Provides `Phoenix.Router.routes/1` for route metadata. | The admin router is Phoenix-based and the current dependency is already resolved in `mix.lock`. [VERIFIED: `mix deps`; VERIFIED: `mix.lock`; CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| Phoenix LiveView | Resolved `1.1.30` | Provides LiveViewTest rendering and component testing. | Existing admin tests already use LiveView and `render_component/2`; official docs expose rendered HTML helpers. [VERIFIED: `mix deps`; VERIFIED: `design_system_component_stress_test.exs`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| LazyHTML | Test dependency via LiveView / explicit test dep | Parses rendered HTML in `HtmlAssertions`. | Existing helper uses `LazyHTML.from_fragment/1`, selectors, attributes, and serialization. [VERIFIED: `mix.exs`; VERIFIED: `html_assertions.ex`] |
| ExUnit | Bundled with Elixir | Runs focused source/rendered contract tests. | Local `mix help test` supports selected test files and `--max-failures`; existing design-system tests are ExUnit. [VERIFIED: `mix help test`; CITED: https://hexdocs.pm/mix/1.12/Mix.Tasks.Test.html] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Jason | Resolved `1.4.5` | Reads brandbook token JSON in existing contract tests. | Use only where existing token contract helpers already decode `brandbook/tokens/tokens.json`. [VERIFIED: `mix deps`; VERIFIED: `design_system_contract_test.exs`] |
| `Lockspire.Web.AdminProof.HtmlAssertions` | Project test helper | Reusable rendered HTML guardrail vocabulary. | Use for representative rendered route/component checks rather than duplicating LazyHTML parsing. [VERIFIED: `html_assertions.ex`] |
| `Lockspire.Web.AdminLab.Fixtures` / `StressSurface` | Project test support | Internal redaction-safe stress evidence. | Cite as `internal_lab` evidence only; never as a supported admin route or public API. [VERIFIED: `fixtures.ex`; VERIFIED: `stress_surface.ex`; VERIFIED: `116-LAB-CONTRACT.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.Router.routes/1` | Regex parse `AdminRouter` source | Regex parsing matches existing tests but is more sensitive to formatting; router metadata avoids multi-line `live(...)` parsing drift. [VERIFIED: `design_system_contract_test.exs`; CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] |
| Existing ExUnit/LazyHTML helpers | Browser automation / visual snapshots | Browser tooling is deferred and would require explicit human package verification; Phase 121 needs deterministic repo-native guardrails. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`] |
| One scorecard file | One file per route | One file keeps all route judgments reviewable together and matches the locked context decision. [VERIFIED: `121-CONTEXT.md`] |

**Installation:**

```bash
# No package install for Phase 121.
```

## Package Legitimacy Audit

Phase 121 should install no external packages, so the package legitimacy gate is not triggered. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | none | none | none | OK | No install recommended. [VERIFIED: `121-CONTEXT.md`] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: phase scope]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: phase scope]

## Architecture Recommendation

Create `121-ROUTE-SCORECARDS.md` as the canonical route judgment artifact, then add a focused contract in `test/lockspire/web/live/admin/design_system_contract_test.exs` or a small adjacent helper module if the parser becomes noisy. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `design_system_contract_test.exs`]

Recommended data flow:

```text
AdminRouter live routes
  -> Phoenix.Router.routes(Lockspire.Web.AdminRouter)
  -> normalize "/" to "/admin" and prefix other paths with "/admin"
  -> append ["/admin/clients/:client_id/edit?workflow=logout-propagation"]
  -> parse 121-ROUTE-SCORECARDS.md scorecard blocks
  -> compare route sets exactly
  -> validate required fields, evidence classes, support promises, follow-up routes, denylists
  -> reuse rendered LiveView/LazyHTML checks for representative source/rendered drift
```

This keeps route truth in source, judgment in markdown, and regressions in deterministic tests. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`; VERIFIED: `html_assertions.ex`]

## Recommended Artifact Structure

Use stable headings and bullet labels instead of free-form paragraphs or markdown tables. Bullet labels avoid pipe escaping problems in long route values and are easy to parse with line-based regex. [VERIFIED: existing markdown tests use string/row matching in `design_system_contract_test.exs`]

Recommended file outline:

```markdown
# Phase 121 Route Scorecards

## Source Truth
- Router source: `Lockspire.Web.AdminRouter`
- Query workflow exceptions: `/admin/clients/:client_id/edit?workflow=logout-propagation`
- Expected scorecards: 29

## Judgment Rubric
### Page
...
### Section
...
### Action
...
### Component Group
...

## Baseline Candidate Classification
...

## Scorecards
### Orient
#### `/admin`
- **Route:** `/admin`
- **Source truth:** `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` `live("/")`
- **Journey:** Orient
- **Persona:** Provider operator
- **JTBD:** ...
- **Top task:** ...
- **Who / What / Where / When / Why:** ...
- **Entry point:** ...
- **Primary decision:** ...
- **Primary action:** ...
- **Earned-place check:** ...
- **Empty state:** ...
- **Error state:** ...
- **Long-data state:** ...
- **Mobile risk:** ...
- **Theme risk:** ...
- **Focus/motion risk:** ...
- **Redaction/security check:** ...
- **Unsupported action check:** ...
- **Follow-up route:** `/admin/clients`
- **Component/group fit:** ...
- **Evidence class:** rendered_guardrail
- **Public support promise:** This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.
- **Runtime/package impact:** None; planning and test proof only.
- **Notes:** ...
```

Required scorecard labels should be treated as exact strings in tests. [VERIFIED: `121-CONTEXT.md`]

## Patterns and Reusable Assets

| Asset | Use in Phase 121 | Notes |
|-------|------------------|-------|
| `107-ROUTE-JOURNEY-CONTRACT.md` | Seed persona, JTBD, entry point, primary decision/action, empty/risk state, follow-up route. | It already covers each admin route plus the logout-propagation query workflow. [VERIFIED: `107-ROUTE-JOURNEY-CONTRACT.md`] |
| `116-ROUTE-WORKFLOW-INVENTORY.md` | Seed `Source truth`, journey, surface classification, and read-only operation queue boundary. | It explicitly states the query workflow is not a Phoenix route. [VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`] |
| `116-VISUAL-UX-RUBRIC.md` | Seed page/section/action/component quality gates and design-pillar vocabulary. | It records theme, focus, motion, redaction, responsive, and no generic security trope floors. [VERIFIED: `116-VISUAL-UX-RUBRIC.md`] |
| `116-COMPONENT-GROUP-INVENTORY.md` | Seed `Component/group fit` with known primitive/meta-component groups and direct-markup exceptions. | Dirty changes currently add `decision_summary`; treat that as candidate evidence unless accepted in Phase 121 planning. [VERIFIED: `116-COMPONENT-GROUP-INVENTORY.md`; VERIFIED: `git diff -- .planning/phases/116...`] |
| `116-LAB-CONTRACT.md` | Seed lab/support boundary wording and evidence classification. | Lab evidence is maintainer/demo/test-only and never `admin_supported`. [VERIFIED: `116-LAB-CONTRACT.md`] |
| `120-BROWSER-PROOF.md` | Seed proof boundary, representative route risks, and browser-tooling deferral. | It keeps browser notes maintainer-only and no Node/browser package files were adopted. [VERIFIED: `120-BROWSER-PROOF.md`] |
| `HtmlAssertions` | Reuse rendered HTML checks. | Provides duplicate-ID, ARIA, label, href, generic CTA, denied text, and unsupported-control helpers. [VERIFIED: `html_assertions.ex`] |
| `AdminLab.Fixtures` / `StressSurface` | Internal lab evidence only. | Provides redaction-safe hostile fixture states for components and long values. [VERIFIED: `fixtures.ex`; VERIFIED: `stress_surface.ex`] |
| `brandbook/` | Brand/token/focus/motion source of truth. | Tokens mirror live `--ls-*` admin CSS vocabulary; dark mode remaps semantic aliases only. [VERIFIED: `brandbook/README.md`; VERIFIED: `brandbook/tokens/tokens.json`] |

## Guardrail Strategy

### Source-Derived Route Set

Recommended helper:

```elixir
@scorecard_path Path.expand(
                  "../../../../../.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md",
                  __DIR__
                )

@workflow_exceptions ["/admin/clients/:client_id/edit?workflow=logout-propagation"]

defp expected_scorecard_routes do
  router_routes =
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.map(& &1.path)
    |> Enum.map(fn
      "/" -> "/admin"
      path -> "/admin" <> path
    end)

  (router_routes ++ @workflow_exceptions)
  |> Enum.sort()
end
```

`Phoenix.Router.routes/1` is the recommended extraction source because it returns router metadata from the compiled router module, while the existing regex helper is a useful fallback if the planner wants to avoid compiled module coupling. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html; VERIFIED: current `mix run` route extraction]

### Query Workflow Exception Handling

Rules:

- Keep `@workflow_exceptions` as a one-element list containing only `/admin/clients/:client_id/edit?workflow=logout-propagation`. [VERIFIED: `121-CONTEXT.md`]
- Assert every route containing `?workflow=` is in `@workflow_exceptions`. [VERIFIED: `121-CONTEXT.md`]
- Assert the workflow exception's base path, `/admin/clients/:client_id/edit`, is present in the router-derived route set. [VERIFIED: `AdminRouter`; VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`]
- Assert the exception scorecard has `Source truth` text that says it is URL/query workflow truth and not a Phoenix route or router expansion. [VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`]

### Markdown Parser Contract

Use route headings as block delimiters:

```elixir
defp scorecard_blocks(markdown) do
  ~r/^#### `(?<route>\/admin[^`]+)`\n(?<body>.*?)(?=^#### `|\z)/ms
  |> Regex.scan(markdown, capture: [:route, :body])
  |> Map.new(fn [route, body] -> {route, body} end)
end

defp scorecard_field!(body, field) do
  case Regex.run(~r/^- \*\*#{Regex.escape(field)}:\*\* (?<value>.+)$/m, body, capture: [:value]) do
    [value] -> String.trim(value)
    nil -> flunk("missing scorecard field #{field}")
  end
end
```

The parser should fail on missing blocks, duplicate route headings, empty field values, `TBD`, `TODO`, `n/a` without justification, and route headings that are not in the expected route set. [VERIFIED: `121-CONTEXT.md`; VERIFIED: existing contract-test style in `design_system_contract_test.exs`]

### Required Field Guardrail

Required fields:

```elixir
@required_scorecard_fields [
  "Route",
  "Source truth",
  "Journey",
  "Persona",
  "JTBD",
  "Top task",
  "Who / What / Where / When / Why",
  "Entry point",
  "Primary decision",
  "Primary action",
  "Earned-place check",
  "Empty state",
  "Error state",
  "Long-data state",
  "Mobile risk",
  "Theme risk",
  "Focus/motion risk",
  "Redaction/security check",
  "Unsupported action check",
  "Follow-up route",
  "Component/group fit",
  "Evidence class",
  "Public support promise",
  "Runtime/package impact",
  "Notes"
]
```

This field list is directly locked by Phase 121 context. [VERIFIED: `121-CONTEXT.md`]

### Rubric Guardrail

The `Judgment Rubric` section should have four scopes: `Page`, `Section`, `Action`, and `Component Group`. Each scope should ask the same five questions: redundant, least-surprising, user-flow-oriented, visually intentional, and on-brand. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `.planning/ROADMAP.md`]

Deterministic tests can assert the exact scope names and five question keywords exist. Human review remains responsible for answering the questions with taste and operator judgment. [VERIFIED: `121-CONTEXT.md`]

### Follow-Up Route Guardrail

Parse `Follow-up route` values and accept only:

- A backticked route present in `expected_scorecard_routes()`. [VERIFIED: `121-CONTEXT.md`]
- `External: ...` with a named destination and reason. [VERIFIED: `121-CONTEXT.md`]
- `Documentation-only: ...` with a named document. [VERIFIED: `121-CONTEXT.md`]
- `Deliberately absent: ...` with a reason. [VERIFIED: `121-CONTEXT.md`]

Reject silent out-of-set routes, screenshot filenames, host mount prefixes such as `/lockspire/admin`, and bare `none` values. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `107-ROUTE-JOURNEY-CONTRACT.md`]

### Unsupported Actions and Generic CTA Drift

Use a narrow denylist so legitimate status words like `retryable` remain allowed while fake controls fail. [VERIFIED: `120-BROWSER-PROOF.md`; VERIFIED: `logout_deliveries_live/index.ex`]

Recommended denylist:

```elixir
@unsupported_operate_action_text ~r/\b(Retry now|Discard|Approve|Deny|Logout now|Worker control|Requeue|Run worker|Pause worker)\b/i
@generic_cta_text ~r/(?:^|>|\n|\*\*)\s*(Click here|Learn more|Read more|Submit|OK)\s*(?:<|\n|$)/i
```

Apply unsupported action checks to Operate route scorecards and operation source files. Apply generic CTA checks to rendered HTML through `HtmlAssertions.assert_no_generic_cta_text/1` and to `Primary action` field values, not to every research/planning sentence that names the guardrail. [VERIFIED: `html_assertions.ex`; VERIFIED: `design_system_contract_test.exs`]

### Unearned Section Guardrail

Make `Earned-place check` and `Component/group fit` mandatory and non-empty for every route. Reject values containing `decorative`, `placeholder`, `nice-to-have`, `TBD`, or `later` unless the scorecard explicitly says `Deliberately absent:` in `Notes`. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `116-VISUAL-UX-RUBRIC.md`]

This does not automate taste; it prevents the scorecard from omitting the judgment that a page section earns its place by serving an operator decision. [VERIFIED: `prompts/lockspire-operator-admin-ia-and-workflows.md`; VERIFIED: `121-CONTEXT.md`]

### Lab/Public Boundary Guardrail

Add assertions:

- `Evidence class` is one of `internal_lab`, `rendered_guardrail`, `manual_browser_note`, or `none`. [VERIFIED: `121-CONTEXT.md`]
- `Public support promise` equals the required D-16 sentence exactly. [VERIFIED: `121-CONTEXT.md`]
- `Runtime/package impact` says no runtime route, package dependency, Hex package surface, browser tooling, public API, host extension point, or public theming interface. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`]
- `docs/supported-surface.md` remains free of lab, stress surface, browser proof, public theming, public design-system, and component API claims. [VERIFIED: `docs/supported-surface.md`; VERIFIED: `design_system_contract_test.exs`]
- `AdminRouter` remains free of lab route strings such as `component_lab`, `component-lab`, `design_system_lab`, and `design-system-lab`. [VERIFIED: `design_system_component_stress_test.exs`; VERIFIED: `AdminRouter`]
- `mix.exs` package files remain limited to the existing allowlist and do not include `.planning`, screenshots, traces, reports, package manager files, or browser configs. [VERIFIED: `mix.exs`; VERIFIED: `design_system_contract_test.exs`]

## Baseline Candidate Classification Strategy

The planner should classify dirty work before creating implementation tasks and should not accept dirty diffs as v1.32 truth by default. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `git status --short`]

| Classification | Current Files / Pattern | Phase 121 Treatment |
|----------------|-------------------------|---------------------|
| Authoritative committed baseline | Source and planning artifacts committed at and after v1.32 initialization. Context capture names branch `milestone/v1.28-admin-ui-operator-experience-polish` at `8515245`; current research observed docs-only commits on top, with source still dirty. | Use committed route/source/planning artifacts as the baseline; note commit drift as docs-only context movement. [VERIFIED: `git log --oneline -5`; VERIFIED: `121-CONTEXT.md`] |
| Admin baseline candidates | `lib/lockspire/web/admin_css.ex`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/live/admin/**`, `test/lockspire/web/live/admin/**`, `test/support/lockspire/web/admin_lab/**`, `.planning/threads/next-roadmap-assessment.md`, and the dirty 116 component inventory line for `decision_summary`. | Scorecards may evaluate these patterns as candidate evidence, but should not call them accepted v1.32 implementation until the phase plan decides. [VERIFIED: `git diff --stat`; VERIFIED: `.planning/threads/next-roadmap-assessment.md`] |
| Admin candidate themes | Confirmation-form client lifecycle, DCR decision summary, logout queue scanability, theme selector/control, form field consistency, expanded status/component stress coverage. | Use these as questions in `Notes` or `Component/group fit`; do not backfill requirements from them. [VERIFIED: `git diff -- lib/lockspire/web/...`; VERIFIED: `.planning/threads/next-roadmap-assessment.md`] |
| Excluded dirty work | `.gitignore`, `.dockerignore`, `Makefile`, `README.md`, `docs/adoption-demo.md`, `examples/adoption_demo/**`, `scripts/demo/**`, `scripts/maintainer/repo_hygiene_check.sh`, `test/lockspire/adoption_demo_docker_contract_test.exs`, `tools/traefik/**`, `.planning/research/.cache/**`. | Keep out of Phase 121 scorecards, v1.32 success criteria, and plan truth. [VERIFIED: `git status --short`; VERIFIED: `121-CONTEXT.md`] |

## Design Pillars For The Rubric

| Pillar | Scorecard Question |
|--------|--------------------|
| Accessibility | Are labels, descriptions, focus, non-color cues, and keyboard paths explicit enough for the operator job? [VERIFIED: `brandbook/notes/accessibility-checks.md`; VERIFIED: `html_assertions.ex`] |
| Responsive reflow | Does the route name long IDs, URLs, scopes, dense rows, and narrow widths as risks? [VERIFIED: `116-VISUAL-UX-RUBRIC.md`; VERIFIED: `120-BROWSER-PROOF.md`] |
| Information architecture | Does the page serve one journey and one top task before showing secondary structure? [VERIFIED: `107-ROUTE-JOURNEY-CONTRACT.md`; VERIFIED: `prompts/lockspire-operator-admin-ia-and-workflows.md`] |
| Security/redaction | Does the page avoid token/plaintext/secret evidence and name destructive consequences? [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `prompts/lockspire-security-posture-and-threat-model.md`] |
| Theme and motion | Does the page preserve light/dark/system parity and reduced-motion behavior? [VERIFIED: `brandbook/tokens/tokens.json`; VERIFIED: `admin_css.ex`; VERIFIED: `design_system_contract_test.exs`] |
| Performance/tooling weight | Does the proof avoid browser/package/runtime dependencies for this phase? [VERIFIED: `120-BROWSER-PROOF.md`; VERIFIED: `mix.exs`] |
| Maintainability and DX | Does the page use known Phoenix function components, BEM/token CSS, and existing test helpers? [VERIFIED: `116-COMPONENT-GROUP-INVENTORY.md`; VERIFIED: `admin_components.ex`] |
| Operator psychology | Is the copy calm, exact, consequence-oriented, and free of fear/marketing/security-console tropes? [VERIFIED: `prompts/lockspire-operator-admin-ia-and-workflows.md`; VERIFIED: `116-VISUAL-UX-RUBRIC.md`] |
| Brand consistency | Does the page respect the brandbook token split, Signal Cyan role, Deep Cyan light-mode actions, and no generic security tropes? [VERIFIED: `brandbook/README.md`; VERIFIED: `brandbook/notes/accessibility-checks.md`] |
| Component fit | Is each component group used because it reduces operator decision load, not because the component exists? [VERIFIED: `116-COMPONENT-GROUP-INVENTORY.md`; VERIFIED: `121-CONTEXT.md`] |

## Risk / Landmine Table

| Risk | Why It Matters | Mitigation |
|------|----------------|------------|
| Treating the query workflow as a router route | It can lead to route expansion in `AdminRouter` and public support drift. | Append exactly one query workflow in tests and assert it is not a Phoenix route. [VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`] |
| Using host mount prefixes as scorecard truth | Host mount paths are integration details; scorecards should publish operator-readable `/admin...` paths. | Normalize router paths to `/admin...` only. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `docs/operator-admin.md`] |
| Markdown parser fragility | Free-form scorecards can pass human review but fail deterministic coverage. | Use exact route headings and exact bullet labels. [VERIFIED: existing string-based artifact tests in `design_system_contract_test.exs`] |
| Generic CTA false positives | The research/planning text must be allowed to name the bad pattern while UI action fields should fail generic copy. | Scope generic CTA checks to rendered HTML and `Primary action` field values. [VERIFIED: `html_assertions.ex`] |
| Over-broad unsupported action denylist | `retryable` and `discarded` are valid queue states, but `Retry now` and `Discard` as controls are unsupported. | Deny control phrases, not state vocabulary. [VERIFIED: `120-BROWSER-PROOF.md`; VERIFIED: `logout_deliveries_live/index.ex`] |
| Dirty admin diffs become accepted truth accidentally | Phase 121 is meant to classify candidate work, not bless uncommitted implementation. | Put baseline classification in the scorecard artifact and plan tasks. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `git diff --stat`] |
| Docker/demo/Traefik drift contaminates v1.32 | Those files are dirty but unrelated to admin scorecards. | Denylist those paths in planning truth and do not derive requirements from them. [VERIFIED: `git status --short`; VERIFIED: `121-CONTEXT.md`] |
| Lab evidence becomes public support | Public lab/theming/storybook support would create semver/support burden. | Exact support promise on every scorecard plus docs/router/mix boundary tests. [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `docs/supported-surface.md`] |
| Adding browser/package tooling in Phase 121 | The phase needs deterministic repo-native proof, not package legitimacy or runtime proof expansion. | No installs; no package files; no browser configs; manual notes only if explicitly kept maintainer-only later. [VERIFIED: `120-BROWSER-PROOF.md`] |
| Current AGENTS stack versions differ from resolved deps | AGENTS names Phoenix 1.8.5 and LiveView 1.1.28, while local deps resolve Phoenix 1.8.7 and LiveView 1.1.30. | Do not change dependencies; run tests against resolved local deps and document the observed versions. [VERIFIED: `AGENTS.md`; VERIFIED: `mix deps`] |

## Canonical Files For Planner To Read

Read these first, in this order:

1. `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md` for locked decisions and scope. [VERIFIED: codebase grep]
2. `lib/lockspire/web/admin_router.ex` for source route truth. [VERIFIED: codebase grep]
3. `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` for route persona/JTBD seed data. [VERIFIED: codebase grep]
4. `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` for source truth and query exception wording. [VERIFIED: codebase grep]
5. `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` for design gates. [VERIFIED: codebase grep]
6. `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` for lab boundary wording. [VERIFIED: codebase grep]
7. `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` for component/group vocabulary. [VERIFIED: codebase grep]
8. `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` for proof boundary and route matrix. [VERIFIED: codebase grep]
9. `test/lockspire/web/live/admin/design_system_contract_test.exs` and `test/support/lockspire/web/admin_proof/html_assertions.ex` for guardrail patterns. [VERIFIED: codebase grep]
10. `docs/operator-admin.md` and `docs/supported-surface.md` for public/admin support boundaries. [VERIFIED: codebase grep]
11. `brandbook/README.md`, `brandbook/tokens/tokens.json`, and `brandbook/notes/accessibility-checks.md` for token, contrast, focus, and motion truth. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. [VERIFIED: `AGENTS.md`]
- Build it as a separate companion library, preserve the embedded-library shape, and do not turn it into a required standalone auth service. [VERIFIED: `AGENTS.md`]
- Keep protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces strongly separated. [VERIFIED: `AGENTS.md`]
- Keep the host seam narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: `AGENTS.md`]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: `AGENTS.md`]
- Preserve security defaults: PKCE S256 by default, exact redirect URI matching, hashed client secrets, short-lived single-use authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: `AGENTS.md`]
- Product priorities put install DX, secure OAuth/OIDC defaults, OIDC endpoints, operator workflows, telemetry/auditability, release hygiene, and executable docs ahead of broad UI support surfaces. [VERIFIED: `AGENTS.md`]

## Common Pitfalls

### Pitfall 1: Markdown-Only Judgment
**What goes wrong:** The scorecard exists but missing routes, missing fields, and unsupported actions do not fail tests. [VERIFIED: `121-CONTEXT.md`]
**How to avoid:** Parse scorecards in ExUnit and compare route sets exactly. [VERIFIED: `design_system_contract_test.exs`]

### Pitfall 2: Source Truth Drift
**What goes wrong:** Screenshot filenames, host mount prefixes, or docs tables become route truth. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`]
**How to avoid:** Derive route truth from `AdminRouter` and append only the query workflow exception. [VERIFIED: `AdminRouter`; VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`]

### Pitfall 3: Lab Creep
**What goes wrong:** Internal lab proof becomes a public route, public API, package surface, or support-surface claim. [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `docs/supported-surface.md`]
**How to avoid:** Use exact support-boundary wording and scan `AdminRouter`, `docs/supported-surface.md`, and `mix.exs`. [VERIFIED: `design_system_component_stress_test.exs`; VERIFIED: `design_system_contract_test.exs`]

### Pitfall 4: Fake Operation Controls
**What goes wrong:** Operate queues gain retry/discard/approval/worker controls that are not backed by domain APIs. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `.planning/REQUIREMENTS.md`]
**How to avoid:** Keep Operate scorecards read-only unless a future phase proves a backed API and scope change. [VERIFIED: `120-BROWSER-PROOF.md`]

### Pitfall 5: Dirty Worktree Confusion
**What goes wrong:** Uncommitted Docker/demo/repo-hygiene edits get mixed into admin IA planning. [VERIFIED: `git status --short`; VERIFIED: `121-CONTEXT.md`]
**How to avoid:** Classify dirty files before planning tasks and keep excluded paths out of Phase 121 truth. [VERIFIED: `121-CONTEXT.md`]

## Code Examples

### Route Truth Extraction

```elixir
# Source: Phoenix.Router official docs plus local AdminRouter proof.
@workflow_exceptions ["/admin/clients/:client_id/edit?workflow=logout-propagation"]

defp expected_scorecard_routes do
  routes =
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.map(& &1.path)
    |> Enum.map(fn
      "/" -> "/admin"
      path -> "/admin" <> path
    end)

  Enum.sort(routes ++ @workflow_exceptions)
end
```

Provenance: [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]; [VERIFIED: `MIX_ENV=test mix run -e ...`]

### Scorecard Block Validation

```elixir
@required_scorecard_fields [
  "Route",
  "Source truth",
  "Journey",
  "Persona",
  "JTBD",
  "Top task",
  "Who / What / Where / When / Why",
  "Entry point",
  "Primary decision",
  "Primary action",
  "Earned-place check",
  "Empty state",
  "Error state",
  "Long-data state",
  "Mobile risk",
  "Theme risk",
  "Focus/motion risk",
  "Redaction/security check",
  "Unsupported action check",
  "Follow-up route",
  "Component/group fit",
  "Evidence class",
  "Public support promise",
  "Runtime/package impact",
  "Notes"
]

test "phase 121 route scorecards cover source route truth" do
  markdown = File.read!(@scorecard_path)
  blocks = scorecard_blocks(markdown)

  assert Map.keys(blocks) |> Enum.sort() == expected_scorecard_routes()

  for {route, body} <- blocks do
    for field <- @required_scorecard_fields do
      value = scorecard_field!(body, field)
      refute value in ["", "TBD", "TODO"]
    end

    assert scorecard_field!(body, "Route") == "`#{route}`"
  end
end
```

Provenance: [VERIFIED: `121-CONTEXT.md`; VERIFIED: `design_system_contract_test.exs`]

### Rendered Guardrail Reuse

```elixir
html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_label_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())
```

Provenance: [VERIFIED: `design_system_component_stress_test.exs`; VERIFIED: `html_assertions.ex`; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Route inventories as human-only planning tables | Source-derived route inventories plus ExUnit route coverage checks | Established across Phases 107, 116, and 120 | Phase 121 should extend the same contract instead of creating a new truth source. [VERIFIED: `107-ROUTE-JOURNEY-CONTRACT.md`; VERIFIED: `116-ROUTE-WORKFLOW-INVENTORY.md`; VERIFIED: `120-BROWSER-PROOF.md`] |
| Browser/screenshot evidence as tempting route truth | Browser/manual evidence is maintainer-only and subordinate to source/rendered guardrails | Phase 120 | Prevents screenshot filenames and browser tooling from becoming runtime or support commitments. [VERIFIED: `120-BROWSER-PROOF.md`] |
| Component lab as possible public design-system surface | Internal lab/stress surface only, never `admin_supported` | Phase 116 | Keeps v1.31/v1.32 design-system proof from becoming public API or package surface. [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `design_system_component_stress_test.exs`] |
| Raw page tables and local buttons | Shared Phoenix function components, BEM/token CSS, and long-value/resource/action primitives | Phases 116-120, with dirty candidate expansion currently present | Scorecards should judge component fit but not accept dirty candidate work automatically. [VERIFIED: `116-COMPONENT-GROUP-INVENTORY.md`; VERIFIED: `git diff --stat`] |

**Deprecated/outdated:**
- Treating operation queues as command centers is out of scope for Phase 121; they remain support-review/read-only unless backed by an existing domain API and explicit future scope. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `121-CONTEXT.md`]
- Treating PhoenixStorybook, browser automation, public theming, or screenshot reports as Phase 121 proof is out of scope. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | All recommendations are grounded in the supplied context, local code/artifacts, local command output, or official HexDocs. | all | No assumed claims logged. [VERIFIED: local research session] |

## Open Questions

1. **Should Phase 121 create a new test file or extend `design_system_contract_test.exs`?**
   - What we know: Existing Phase 107/116/120 artifact guardrails live in `design_system_contract_test.exs`. [VERIFIED: `design_system_contract_test.exs`]
   - What's unclear: The scorecard parser may make that file harder to scan. [VERIFIED: file is already 2040 lines by `wc -l`]
   - Recommendation: Keep one or two focused tests in `design_system_contract_test.exs` if small; extract a test-only helper if parser/support functions would bloat the file. [VERIFIED: `121-CONTEXT.md` discretion]

2. **How should the current docs-only commit drift be described?**
   - What we know: Context captured `8515245` as the v1.32 initialization baseline; current research observed `63cd550` after docs-only context/state commits on the same branch. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `git log --oneline -5`]
   - What's unclear: Whether implementation planning wants to name the source baseline commit or the current HEAD. [VERIFIED: local git state]
   - Recommendation: Treat `8515245` as the source baseline named by context and `63cd550` as the current planning-doc HEAD; rerun `git status --short` before implementation. [VERIFIED: `git status --short`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit and Mix tests | yes | 1.19.5 on OTP 28 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Focused and full test commands | yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| Phoenix / LiveView deps | Route metadata and rendered component tests | yes | Phoenix 1.8.7, LiveView 1.1.30 | Do not change deps in Phase 121. [VERIFIED: `mix deps`] |
| Node/npm | Not required by Phase 121 | yes | Node 22.14.0, npm 11.1.0 | Do not use for this phase. [VERIFIED: `node --version`; VERIFIED: `npm --version`; VERIFIED: `121-CONTEXT.md`] |
| Browser automation | Not required by Phase 121 | not probed | none | Keep deferred; no package/config/browser artifact. [VERIFIED: `120-BROWSER-PROOF.md`] |

**Missing dependencies with no fallback:** none. [VERIFIED: environment probes]

**Missing dependencies with fallback:** browser automation remains intentionally unused; repo-native ExUnit/LiveViewTest/LazyHTML proof is the fallback and the requirement. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `120-BROWSER-PROOF.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit through Mix 1.19.5, with Phoenix LiveViewTest and LazyHTML-backed helpers. [VERIFIED: `mix --version`; VERIFIED: `mix.exs`; VERIFIED: `html_assertions.ex`] |
| Config file | Standard project test setup; no new config required for Phase 121. [VERIFIED: `mix.exs`; VERIFIED: existing tests] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: `mix help test`; VERIFIED: `design_system_contract_test.exs`] |
| Supporting run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` [VERIFIED: `design_system_component_stress_test.exs`] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: `mix.exs`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| IA-01 | Scorecard block exists for each derived route/workflow and contains every required field. | Source/markdown contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Existing file yes; new test needed. [VERIFIED: `design_system_contract_test.exs`; VERIFIED: `121-CONTEXT.md`] |
| IA-02 | Rubric and guardrails reject missing fields, unsupported Operate actions, generic CTA field drift, unearned sections, bad follow-ups, and forbidden secret evidence. | Source/markdown plus rendered helper reuse | Same focused command plus targeted rendered/component stress command. | Existing helpers yes; new scorecard tests needed. [VERIFIED: `html_assertions.ex`; VERIFIED: `design_system_component_stress_test.exs`] |
| IA-03 | Public design-system/lab/theming/browser support surface does not expand. | Source/docs/package boundary contract | Same focused command. | Existing boundary tests yes; extend for scorecard artifact. [VERIFIED: `design_system_contract_test.exs`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `mix.exs`] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: `mix help test`]
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` [VERIFIED: existing test files]
- **Phase gate:** `MIX_ENV=test mix test.fast` before verification, unless the planner explicitly limits Phase 121 to docs-only proof and records why. [VERIFIED: `mix.exs`]

### Wave 0 Gaps

- [ ] `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - required artifact for IA-01. [VERIFIED: `121-CONTEXT.md`]
- [ ] New scorecard parser/guardrail test in `design_system_contract_test.exs` or a small helper module - required for IA-01/IA-02/IA-03. [VERIFIED: `121-CONTEXT.md`; VERIFIED: existing test patterns]
- [ ] Optional parser helper extraction if the route/field/follow-up validation makes the contract test unreadable. [VERIFIED: `121-CONTEXT.md` discretion]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new authentication behavior | Host app owns operator authentication before `AdminRouter`; Phase 121 must not change that seam. [VERIFIED: `AGENTS.md`; VERIFIED: `docs/operator-admin.md`] |
| V3 Session Management | no new session behavior | Phase 121 is planning/test proof only; dirty theme local-storage work is baseline candidate evidence, not a Phase 121 runtime commitment. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `git diff -- lib/lockspire/web/live/admin_layout_live.ex`] |
| V4 Access Control | yes, boundary preservation | Keep admin routes host-guarded and reject public lab/design-system/support-surface expansion. [VERIFIED: `docs/operator-admin.md`; VERIFIED: `docs/supported-surface.md`; VERIFIED: `116-LAB-CONTRACT.md`] |
| V5 Input Validation | yes, artifact validation | Validate scorecard route set, required fields, follow-up route references, evidence class enum, and forbidden text deterministically. [VERIFIED: `121-CONTEXT.md`] |
| V6 Cryptography | no new cryptography | Preserve redaction and avoid plaintext secret/token evidence in scorecards, fixtures, docs, and rendered proof. [VERIFIED: `AGENTS.md`; VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `fixtures.ex`] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public support-surface creep through lab/theming/browser wording | Elevation of privilege / repudiation of support contract | Exact support-promise wording and public docs/package/router denylists. [VERIFIED: `121-CONTEXT.md`; VERIFIED: `docs/supported-surface.md`] |
| Secret/plaintext leakage in planning evidence | Information disclosure | Reuse fixture/source denylist and require redaction/security check per scorecard. [VERIFIED: `116-LAB-CONTRACT.md`; VERIFIED: `fixtures.ex`] |
| Unsupported operation controls implied by scorecards | Tampering / unsafe operations | Operate scorecards must state read-only support truth unless backed APIs are explicitly in scope. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `120-BROWSER-PROOF.md`] |
| Host-owned auth boundary blurred | Elevation of privilege | Scorecards and docs should say host owns staff auth/MFA/role checks before the admin router. [VERIFIED: `docs/operator-admin.md`; VERIFIED: `AGENTS.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md` - locked phase decisions, scope, support boundary, baseline boundary. [VERIFIED: codebase grep]
- `lib/lockspire/web/admin_router.ex` - canonical admin router source. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` - IA-01/IA-02/IA-03 and Phase 121 success criteria. [VERIFIED: codebase grep]
- Phase 107, 116, and 120 planning artifacts - route/persona/JTBD seed, rubric/lab contracts, browser-proof boundary. [VERIFIED: codebase grep]
- `test/lockspire/web/live/admin/design_system_contract_test.exs`, `test/support/lockspire/web/admin_proof/html_assertions.ex`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - existing guardrail patterns. [VERIFIED: codebase grep]
- `docs/operator-admin.md`, `docs/supported-surface.md`, `brandbook/README.md`, `brandbook/tokens/tokens.json`, `brandbook/notes/accessibility-checks.md` - support, host seam, token, contrast, focus, and motion truth. [VERIFIED: codebase grep]
- Local commands: `git status --short`, `git diff --stat`, `git log --oneline -5`, `MIX_ENV=test mix run -e ...`, `mix deps`, `mix help test`, `elixir --version`, `mix --version`. [VERIFIED: local command output]

### Secondary (MEDIUM confidence)

- Phoenix Router official HexDocs for router route metadata. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]
- Phoenix LiveViewTest official HexDocs for rendered HTML and async testing helpers. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Mix task official HexDocs for `mix test` options including `--max-failures`. [CITED: https://hexdocs.pm/mix/1.12/Mix.Tasks.Test.html]

### Tertiary (LOW confidence)

- None. No training-only claims are used as implementation requirements. [VERIFIED: local research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - resolved from local Mix/deps and existing tests. [VERIFIED: `mix deps`; VERIFIED: `mix.exs`]
- Architecture: HIGH - locked by Phase 121 context and prior phase artifacts. [VERIFIED: `121-CONTEXT.md`; VERIFIED: Phase 107/116/120 artifacts]
- Guardrails: HIGH - existing ExUnit/LiveViewTest/LazyHTML helper patterns are present. [VERIFIED: `design_system_contract_test.exs`; VERIFIED: `html_assertions.ex`]
- External API references: MEDIUM - checked via official HexDocs current pages after Context7 CLI was unavailable. [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 for codebase-specific planning; rerun route extraction and `git status --short` immediately before implementation. [VERIFIED: local research date; VERIFIED: current dirty worktree]
