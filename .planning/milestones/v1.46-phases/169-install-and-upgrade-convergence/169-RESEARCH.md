# Phase 169: Install and Upgrade Convergence - Research

**Researched:** 2026-10-23
**Domain:** Phoenix host integration, generated install/upgrade safety, and structural diagnostics
**Confidence:** HIGH for current repository seams, official LiveView security guidance, the selected generated denial contract and historical manifest provenance; implementation/runtime results remain pending execution.

## User Constraints

No Phase 169 `CONTEXT.md` exists. Research follows the approved Phase 169 goal, requirements, roadmap constraints, and the project constraints below; no additional product decision is inferred.

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded companion library; do not turn it into a required standalone auth service or a Sigra module. `[VERIFIED: AGENTS.md:17-21]` Exact directive: “Preserve the embedded-library shape; do not turn this into a required standalone auth service.”
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. `[VERIFIED: AGENTS.md:17-21]` Exact directive: “Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces.”
- Keep host account schema, staff identity, login, layout, branding, and product policy under host ownership. `[VERIFIED: AGENTS.md:9-10,20]` Exact text: “the host app keeps ownership of accounts, login UX, layouts, branding, and product-specific policy.”
- Do not expand this phase into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. `[VERIFIED: AGENTS.md:21]` Exact directive: “Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite.”
- Preserve the stack floors and project security defaults; the declared versions include Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, and PostgreSQL `14+`. `[VERIFIED: AGENTS.md:23-31]` Verbatim values: “Phoenix `1.8.5`”, “Phoenix LiveView `1.1.28`”, “Ecto SQL `3.13.5`”, “PostgreSQL `14+`”.
- For admin-visible copy changes, read `PRODUCT.md`, use its “UI says” vocabulary, add new concepts to the map, and retire replaced wording in the vocabulary contract. `[VERIFIED: AGENTS.md:52-56]` Exact directive: “Before writing or changing admin UI text, read the personas and vocabulary map in `PRODUCT.md`”. This phase has no planned UI redesign; read it if any admin-visible copy is changed.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HDX-01 | “A newly installing host receives scaffolding and instructions for the canonical route/session integration, required host authorization and endpoint/browser wiring, without an assumed account schema or an allow-all staff-policy default.” `[VERIFIED: .planning/REQUIREMENTS.md:28]` | Existing generator templates and route macro; fail-closed host policy seam; generated-host compile and denial tests. |
| HDX-02 | “An existing host can migrate from the generated forwarded-admin integration through explicit guidance and safe managed-file upgrade behavior; dry runs write nothing, repeat runs are safe, drift is refused and host-owned policy files are preserved.” `[VERIFIED: .planning/REQUIREMENTS.md:29]` | Existing manifest ownership, immutable operation plan, transactional writes and upgrade tests; add a legacy generated fixture and migration guidance. |
| HDX-03 | “A maintainer can use `mix lockspire.verify` to distinguish complete canonical admin route/session/hook wiring from incomplete, shadowed or legacy forward-only wiring, with actionable secret-safe guidance and an explicit limit that structural checks do not prove arbitrary host policy.” `[VERIFIED: .planning/REQUIREMENTS.md:30]` | Replace the current forward-only check with compiled native route metadata inspection and add positive, negative, shadowing, legacy, and redaction cases. |
| HDX-04 | “Adopters can follow consistent supported-surface, installation, admin and upgrade guidance, and the demo and maintained host fixtures consume the same reusable admin integration without duplicated live-route inventories.” `[VERIFIED: .planning/REQUIREMENTS.md:31]` | Reuse `Lockspire.Web.AdminRoutes`; converge generated helper, adoption demo, generated fixture, clean-room overlay, and docs on it. |

The roadmap's four success criteria match these requirements: fresh generated compile with explicit route/session, endpoint/browser and host authorization wiring; safe conversion of old generated hosts; structural verification with actionable bounded claims; and demo/fixture/docs convergence. `[VERIFIED: .planning/ROADMAP.md:91-105]` The roadmap also says to preserve manifest/file-transaction and drift checks, never silently overwrite editable host hooks, never claim static introspection proves host policy, and remove duplicated demo routes that mask the supported path. `[VERIFIED: .planning/ROADMAP.md:104-105]`

## Summary

Phase 167 already provides the reusable route source: `Lockspire.Web.AdminRoutes` expands the library-owned admin inventory into native Phoenix routes, applies the fixed `:lockspire_admin` LiveView session, requires a host HTTP pipeline and host `on_mount` hook, and places Lockspire's mount-alignment guard after host authorization. The test's exact assertions include `assert live_session.name == :lockspire_admin` and `assert hook_modules(live_session) == [AdminRouteHost.LiveAuthorization, Lockspire.Web.AdminMount]`. `[VERIFIED: lib/lockspire/web/admin_routes.ex:69-105; test/lockspire/web/admin_route_inventory_test.exs:81-87]` The inventory test also states `assert length(@inventory) == 29` and `assert length(Enum.uniq(@inventory)) == 29`. `[VERIFIED: test/lockspire/web/admin_route_inventory_test.exs:53-54]` The generator helper, demo, and fixtures should call this macro rather than keep copied route lists or a forwarded-admin fallback.

The generator currently emits a helper with a `:require_operator` forward to `Lockspire.Web.AdminRouter`, while `examples/adoption_demo` hand-copies the admin declarations and retains the forward. The verifier explicitly searches for that forward. `[VERIFIED: priv/templates/lockspire.install/router.ex:41-57; examples/adoption_demo/lib/adoption_demo_web/router.ex:58-64,137-138; lib/lockspire/install/verify.ex:221-240,313-316]` So the most important implementation work is a coordinated shape change: generate explicit host pipeline and authorization hook wiring, give a fresh host a safe deny-until-configured seam, teach verification to inspect route metadata, and update old generated hosts through the existing managed upgrade contract.

**Primary recommendation:** Use `Lockspire.Web.AdminRoutes.lockspire_admin_routes/2` everywhere, make the generated staff plug and LiveView hook deny until the host implements its own policy, and update the existing verifier to check compiled native route/action/session/pipeline/hook metadata while explicitly stating that it cannot validate arbitrary host authorization behavior.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin route declaration and session grouping | Frontend Server (SSR) | — | Routes and LiveView session are compiled by the host Phoenix router; host plugs/hooks are composed at this boundary. `[CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html]` |
| Staff identity, login, and current authorization decision | API / Backend | Frontend Server (SSR) | The host owns identity and policy; its HTTP pipeline protects the initial request and its host hook resolves current authority at LiveView entry/navigation boundaries. `[VERIFIED: AGENTS.md:9-10,20; lib/lockspire/web/admin_routes.ex:3-7]` |
| Install and upgrade | API / Backend | — | Mix tasks render host artifacts, preflight file and migration changes, then apply a filesystem transaction. `[VERIFIED: lib/lockspire/generators/install.ex:83-105; lib/lockspire/install/operation_plan.ex:1-8,95-102]` |
| `mix lockspire.verify` | API / Backend | Frontend Server (SSR) | It reads runtime config and compiled router metadata; it can report structural facts but cannot execute every host's policy semantics. `[VERIFIED: lib/lockspire/install/verify.ex:214-250,293-316]` |
| OAuth/OIDC protocol endpoint | API / Backend | — | The separate public router remains a host-mounted forward and stays independent of the admin LiveView session. `[VERIFIED: priv/templates/lockspire.install/router.ex:64-70]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `1.20.4` / Mix `1.20.4` in the current verified research environment | Mix tasks, generator, router macro, tests | Phase 168 records `Runtime was ASDF Elixir `1.20.4-otp-29` and Erlang/OTP `29.1.1``. `[VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md:136]` |
| Phoenix | `1.8.5` minimum supported floor | Host router compilation and route metadata | Project's explicit supported floor. `[VERIFIED: AGENTS.md:23-31]` Exact source value: “Phoenix `1.8.5`”. |
| Phoenix LiveView | `1.1.28` minimum supported floor | Native LiveView routes, `live_session`, and host `on_mount` integration | Project's explicit supported floor; official security documentation describes the separate HTTP and stateful mount checks. `[VERIFIED: AGENTS.md:23-31; CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html]` Exact source value: “Phoenix LiveView `1.1.28`”. |
| ExUnit / Phoenix.ConnTest / Phoenix.LiveViewTest | Repository locked versions | Generator, route compile, request and connected server lifecycle regressions | These are already used by the current route/auth suite; no new test dependency is needed. `[VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md, Test Infrastructure]` |

### Supporting

| Library / subsystem | Version | Purpose | When to Use |
|---------------------|---------|---------|-------------|
| `Lockspire.Web.AdminRoutes` | In-repo | One shared view/action inventory and protected native host route macro | Use in the generated helper, demo, and maintained fixtures. The exact count is asserted by `assert length(@inventory) == 29`. `[VERIFIED: lib/lockspire/web/admin_routes.ex:9-41,69-105; test/lockspire/web/admin_route_inventory_test.exs:53-54,62-88]` |
| `Lockspire.Install.OperationPlan` + `FileTransaction` + `Manifest` | In-repo | Preflight, drift-aware updates, transactional writes and managed-file inventory | Reuse for generated upgrades; do not add a second write mechanism. `[VERIFIED: lib/lockspire/install/operation_plan.ex:1-8,95-145,188-255; lib/lockspire/install/manifest.ex:1-12]` |
| `Phoenix.Router.routes/1` / route metadata | Phoenix project dependency | Inspect compiled routes, including `plug`, `plug_opts`, `pipe_through`, route pattern, and LiveView metadata | Use for structural verification rather than parsing source strings. The source lists `:pipe_through`, `:plug`, `:plug_opts`, and `:route` as returned metadata keys; Phase 167 tests assert selected compiled metadata. `[VERIFIED: deps/phoenix/lib/phoenix/router.ex:1411-1448; test/lockspire/web/admin_route_inventory_test.exs:72-88]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Lockspire.Web.AdminRoutes` as the shared route inventory | Keep hand-copied `live/3` declarations in each host | Copies can drift and contradict HDX-04. The shared macro already preserves native route metadata and is covered by independent route/action inventory tests. `[VERIFIED: lib/lockspire/web/admin_routes.ex:9-55; test/lockspire/web/admin_route_inventory_test.exs:62-88]` |
| Inspect compiled router metadata in verify | Regex or source-string scanning of router files | Source parsing misses macro expansion and route shadowing, while compiled route metadata is what Phoenix dispatches. Prefer compiled metadata. `[CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html#route_info/4; VERIFIED: deps/phoenix/lib/phoenix/router.ex:1431-1458]` |
| Existing checksummed managed-file upgrade | Overwrite the generated helper regardless of manifest state | This would erase host edits; current operation plan detects checksum drift and refuses. `[VERIFIED: lib/lockspire/install/operation_plan.ex:221-245]` |

The phase scope appears implementable with existing APIs and fixtures; do not add a router-inspection, authorization, or templating dependency without new evidence that the current stack cannot support the work. `[ASSUMED]`

## Architecture Patterns

### System Architecture Diagram

```text
mix lockspire.install / mix lockspire.upgrade
        │ render + preflight
        ▼
managed router helper ── imports host pipeline + fail-closed host hook
        │ calls canonical macro
        ▼
Lockspire.Web.AdminRoutes ── emits native host Phoenix routes
        │                           │
        │                           ├─ host HTTP pipeline checks current staff policy
        │                           ├─ fixed admin LiveView session
        │                           └─ host on_mount checks current authority before Lockspire mount guard
        ▼
host app router ───────────────────────────────────────────────► admin LiveViews
        │
        ├─ mix lockspire.verify ── inspect compiled route/action/session/pipeline/hook metadata
        │                           └─ report structural status and policy-proof limit
        └─ separate public OAuth/OIDC forward ──────────────────► protocol router
```

Native `live_session` groups LiveView navigation; same-session navigation can skip the regular Plug pipeline, which is why host policy belongs both in the HTTP pipeline and a host `on_mount` hook. `[CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html]` The current Lockspire macro appends its own mount-path guard after the host hook(s). `[VERIFIED: lib/lockspire/web/admin_routes.ex:77-105]`

### Recommended Project Structure

Keep the current ownership split. The generated `lib/<web>/router/lockspire.ex` remains Lockspire-managed, while the host's staff plug/hook implementation is a host-owned seam. Keep demo and fixture host policy in their own host files. `[VERIFIED: lib/lockspire/generators/templates.ex:10-42; lib/lockspire/generators/install.ex:155-174]`

### Pattern 1: One Native Host Route Declaration

**What:** The generated helper should invoke the reusable route macro with the host's browser/staff pipeline and its staff authorization hook. Preserve native session/layout/session options and keep the public protocol router separate. `[VERIFIED: lib/lockspire/web/admin_routes.ex:69-105; priv/templates/lockspire.install/router.ex:59-70]` Installation guidance must also call out the host's normal `:browser` setup (`fetch_session`, CSRF/security plugs), LiveView endpoint socket with session `connect_info`, and served LiveView JavaScript. Keep these endpoint/static-asset edits host-owned; the adoption demo shows the socket/session and static asset seams explicitly. `[VERIFIED: examples/adoption_demo/lib/adoption_demo_web/endpoint.ex:4-28,40-43; docs/install-and-onboard.md:80-101]`

**When to use:** Fresh installs, upgrades to an unmodified managed helper, demo router, generated-host fixture, and clean-room host source.

**Verified option shape:** `AdminRoutes.lockspire_admin_routes("/lockspire/admin", pipe_through: [:host_auth], on_mount: LiveAuthorization)` `[VERIFIED: test/lockspire/web/admin_routes_compile_test.exs:11-20]` The test source states the accepted shape verbatim: `pipe_through: [:host_auth]` and `on_mount: LiveAuthorization`. Host-specific names in this example are illustrative; they are not requirements for adopter naming.

### Pattern 2: Safe First-Run Authorization Seam

**What:** Generate a host-owned HTTP authorization plug and LiveView hook that both deny/redirect until a developer replaces the stub with current host session and policy checks. Make the helper pass both to the shared admin macro, and call out the file to edit in install instructions. Do not emit an allow-all plug, a copied session boolean, account table, role schema, or Lockspire-owned host identity service. This satisfies the stated fail-closed requirement without inventing an account schema. `[VERIFIED: .planning/REQUIREMENTS.md:28; AGENTS.md:9-10,20; .planning/phases/168-host-owned-liveview-authorization/168-VERIFICATION.md, Goal Achievement truth 4]`

The guidance should also state that the host owns authorization inside sensitive LiveView actions/events and any logout/disconnect behavior. A mount hook does not establish continuous permission revocation for an already-connected socket. `[VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VERIFICATION.md, Deferred Items; .planning/ROADMAP.md:88-89,121]`

**Status: Resolved implementation choice.** Plan 169-01 selects a compiling host-owned `OperatorAuthorization`: its Plug sends 403 and halts; its `on_mount/4` returns a halted socket redirected to the host-local root `/`. Both always deny until the host implements current policy; no assumed login route or account schema is generated. This implements HDX-01 without adding a product approval requirement. Rendered-output HTTP/hook/connected regressions in Plan 169-01 must prove the behavior during execution. `[VERIFIED: .planning/phases/169-install-and-upgrade-convergence/169-01-PLAN.md, Task 1; test/support/lockspire/web/admin_route_host.ex:158-170,234-243]`

### Pattern 3: Verify Compiled Route Contract and Bound the Claim

**What:** Match every canonical relative path to its expected LiveView module/action in compiled Phoenix route metadata; require the protected pipeline, fixed session and ordered host hook(s) followed by `Lockspire.Web.AdminMount`. Detect a forward-only route, absent/empty hooks, wrong/shadowed route target, duplicate/incomplete inventory, or the public forward taking precedence. Return actionable findings without exposing cookie/session/key material.

**Policy boundary:** Route metadata can show which plugs/hooks are declared, not whether those host modules correctly validate identity, MFA, roles, tenant rules, session freshness, or event actions. Say so in both command output and docs; require host-owned request tests for actual policy. `[VERIFIED: lib/lockspire/install/verify.ex:214-250; .planning/ROADMAP.md:104-105; CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html]`

**Current gap:** The current verifier identifies the admin mount as `forward` to `Lockspire.Web.AdminRouter` and passes the unguarded-admin test, whose exact assertion is `assert result.ok?`. It therefore cannot distinguish complete native route/session/hook integration from the old forward-only shape or prove authorization behavior. `[VERIFIED: lib/lockspire/install/verify.ex:221-240,309-316; test/lockspire/install/verify_test.exs:583-594]`

### Pattern 4: Upgrade Only Under Existing Manifest Authority

**What:** Convert an old generated install by updating the checksummed managed helper/template and manifest through `OperationPlan`. Preserve all host-owned policy modules and host router changes; if a managed file has drifted, refuse and give a manual reconciliation path. Add a legacy manifest/install fixture to prove the intended conversion. `[VERIFIED: lib/lockspire/install/operation_plan.ex:188-255; lib/lockspire/generators/install.ex:155-174]`

**Dry-run invariant:** Build and report the same immutable operation plan used for apply, but do not stage or write changes. Verify byte hashes of all fixture files and manifest before and after dry-run. `[VERIFIED: lib/lockspire/install/operation_plan.ex:47-54,95-102; test/integration/install_upgrade_test.exs:17-30]`

### Anti-Patterns to Avoid

- **Keep both direct route declarations and `forward("/", Lockspire.Web.AdminRouter)` as a fallback:** duplicate route inventory masks whether the canonical integration works and violates the roadmap's no-fallback constraint. `[VERIFIED: .planning/ROADMAP.md:105; examples/adoption_demo/lib/adoption_demo_web/router.ex:58-64,137-138]`
- **Treat nonempty pipeline/hook metadata as proof of policy:** a named module can still allow everyone or be a no-op. Structural verification must state its limit. `[VERIFIED: lib/lockspire/install/verify.ex:214-250; .planning/ROADMAP.md:105]`
- **Overwrite modified generated files or host-owned hooks:** let the existing manifest checksum/drift check refuse; preserve host-owned files. `[VERIFIED: lib/lockspire/install/operation_plan.ex:221-245; test/integration/install_upgrade_test.exs:129-162]`
- **Generate an allow-all staff policy or infer a host account schema:** hosts own this seam; the initial implementation must deny until configured. `[VERIFIED: .planning/REQUIREMENTS.md:28; AGENTS.md:9-10,20]`
- **Keep an old forward as a success condition in verify:** classify it as legacy/incomplete, even if it remains a compatibility API elsewhere. `[VERIFIED: lib/lockspire/install/verify.ex:227-240; .planning/ROADMAP.md:97-100]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Admin route inventory | A second copy in templates, demo, or fixtures | `Lockspire.Web.AdminRoutes` shared macro/inventory | One inventory prevents route/action drift; compiled route tests already establish parity. `[VERIFIED: lib/lockspire/web/admin_routes.ex:9-55; test/lockspire/web/admin_route_inventory_test.exs:62-88]` |
| Safe generated-file replacement | Direct `File.write!` update logic in the Mix task | `OperationPlan` + `FileTransaction` + `Manifest` | Existing path preflight, checksums, drift refusal, recovery journal, rollback and manifest-last behavior are already implemented. `[VERIFIED: lib/lockspire/install/operation_plan.ex:1-8,95-145; lib/lockspire/install/file_transaction.ex:1-9]` |
| Route verification | Router-source regex or searching for `forward` text | Phoenix compiled router metadata plus explicit canonical route/action inventory | Checks the actual compiled target, selected action, pipeline and LiveView session metadata. `[VERIFIED: test/lockspire/web/admin_route_inventory_test.exs:62-88; deps/phoenix/lib/phoenix/router.ex:1431-1458; CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html#route_info/4]` |
| Host authorization | Lockspire role tables, account resolution, or custom auth framework | Host-owned Plug and LiveView `on_mount` implementations | Preserves the embedded-library boundary and avoids assuming the host's account model. `[VERIFIED: AGENTS.md:9-10,20; lib/lockspire/web/admin_routes.ex:3-7]` |

**Key insight:** This phase should converge callers on the route macro and transaction system that already exist. The significant risk is false confidence at the seam: generation must fail closed, and static verification must stop at structure.

## Common Pitfalls

### Pitfall 1: Router-level HTTP protection without LiveView entry protection

**What goes wrong:** Initial requests are gated by a Plug but connected entry or same-session navigation does not re-run that Plug.

**Why it happens:** LiveView uses its own stateful connection and same-session navigation can bypass the normal pipeline.

**How to avoid:** Generate explicit host authorization wiring in both the HTTP pipeline and LiveView `on_mount`; preserve host-first ordering. `[CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html; VERIFIED: lib/lockspire/web/admin_routes.ex:77-105]`

**Warning signs:** Admin macro with missing or empty `pipe_through`/`on_mount`; compile tests already reject these values. `[VERIFIED: lib/lockspire/web/admin_routes.ex:112-159; .planning/phases/168-host-owned-liveview-authorization/168-VERIFICATION.md, truth 4]`

### Pitfall 2: Dry-run that shares planning but still mutates state

**What goes wrong:** An upgrade dry-run changes a generated file, transaction journal, manifest, or migration output.

**Why it happens:** Dry-run accidentally enters `OperationPlan.apply/1` or stages artifacts while only intending to report.

**How to avoid:** Keep dry-run on report-only branch and assert exact pre/post bytes for managed files, host-owned files, migrations and manifest. `[VERIFIED: lib/mix/tasks/lockspire.upgrade.ex, do_run/1; lib/lockspire/install/operation_plan.ex:47-54,95-102; test/integration/install_upgrade_test.exs:17-30]`

**Warning signs:** Tests only assert console output, without byte equality for all affected files.

### Pitfall 3: Generated migration quietly clobbers host work

**What goes wrong:** A managed helper was edited, or a migration path exists with different bytes, and upgrade overwrites it.

**Why it happens:** Treating the manifest as overwrite authorization instead of expected-checksum evidence.

**How to avoid:** Preserve `OperationPlan` preflight and `FileTransaction`; test managed drift and same-path migration collision with zero partial writes. `[VERIFIED: lib/lockspire/install/operation_plan.ex:221-245; test/integration/install_upgrade_test.exs:129-143,258-316]`

**Warning signs:** Any new upgrade implementation calls `File.write` before complete preflight.

### Pitfall 4: Static diagnostic claims host policy works

**What goes wrong:** An adopter sees “verify passed” and assumes the staff policy correctly rejects unauthorized users.

**Why it happens:** Structural checks establish route declarations and hook identities, not arbitrary callback semantics or database-backed current authorization.

**How to avoid:** Separate structural status from behavioral policy proof; output and docs must say host request tests remain the proof of policy. `[VERIFIED: .planning/ROADMAP.md:104-105; lib/lockspire/install/verify.ex:214-250]`

**Warning signs:** Wording such as “admin authorization verified” when the command only inspects compiled metadata.

### Pitfall 5: Demo fallback hides canonical route failure

**What goes wrong:** The shared macro is broken but the demo continues to work through its copied direct routes. Its independent inventory is guarded by `assert length(@inventory) == 29`. `[VERIFIED: test/lockspire/web/admin_route_inventory_test.exs:53-54]`

**Why it happens:** Demo declares a copied route inventory and also forwards to `AdminRouter`.

**How to avoid:** Replace both with exactly one call to the canonical macro, retain host pipelines/hooks, and test complete route/action inventory and demo host access. `[VERIFIED: examples/adoption_demo/lib/adoption_demo_web/router.ex:58-64,137-138; lib/lockspire/web/admin_routes.ex:9-55]`

## Code Examples

The current test fixture demonstrates the supported macro call shape with an explicit host pipeline and ordered hook list: `pipe_through: [:host_auth]`, `on_mount: [LiveAuthorization, SecondHook]`. `[VERIFIED: test/lockspire/web/admin_routes_compile_test.exs:11-20]`

```elixir
require Lockspire.Web.AdminRoutes

Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
  pipe_through: [:host_auth],
  on_mount: [LiveAuthorization, SecondHook]
)
```

Source: [test/lockspire/web/admin_routes_compile_test.exs:11-20](/Users/jon/projects/lockspire/test/lockspire/web/admin_routes_compile_test.exs:11). A production host should use its own pipeline and current-policy hook modules. The current AdminRoutes macro appends `Lockspire.Web.AdminMount` after supplied hooks. `[VERIFIED: lib/lockspire/web/admin_routes.ex:77-105]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generated helper forwards admin to `Lockspire.Web.AdminRouter`; demo duplicates its routes to sign host paths correctly | One shared native host route macro expands the library-owned route/action inventory | Phase 167 (2026-10-22) added `Lockspire.Web.AdminRoutes`; Phase 169 converges generated installs, verifier, demo, fixtures and guidance | Avoids hand-maintained duplicate inventories and exercises the real host route/session contract. `[VERIFIED: .planning/phases/167-host-expanded-admin-routing/167-01-SUMMARY.md; examples/adoption_demo/lib/adoption_demo_web/router.ex:58-64,137-138]` |
| Verifier accepts a forward route and reports only its mount shape | Verify native route/action/session/pipeline/hook metadata and explicitly bound claims | Phase 169 planned scope; not implemented yet | Detects legacy, missing, incomplete and shadowed wiring without treating static checks as policy proof. `[VERIFIED: lib/lockspire/install/verify.ex:214-250,313-316; .planning/ROADMAP.md:97-105]` |

**Deprecated/outdated:** Generated forward-only admin integration and the demo's duplicate `live/3` list are legacy for the Phase 169 canonical path. Keep `AdminRouter` only where compatibility APIs or tests require it; do not let it define fresh install success.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 — resolved | Plan 169-01 selects a compiling host-owned Plug that sends 403 and halts, plus an always-deny LiveView hook that halts with a local-root redirect. | Architecture Pattern 2; resolved question 1 | Implementation tests remain pending; an allow-all implementation would violate HDX-01. |
| A2 | Structural verification can reliably inspect the host's compiled route inventory and LiveView metadata for all canonical paths, hooks, pipeline ordering, and public-route separation on supported Phoenix versions. | Architecture Pattern 3 | Exact metadata shape can vary by Phoenix/LiveView version; Phase 170 must prove package behavior on exact floor and locked pair. |
| A3 — resolved for selected shapes | Historical source at `v1.45^{}` and `77d5ad90` marks the router helper managed and records per-file SHA-256 checksums; Plan 169-02 covers the v1.45 shape and older omitted optional fields. | Architecture Pattern 4; resolved question 2 | This is not blanket support for every historical inventory; missing, drifted or unsupported ownership states require refusal and manual reconciliation. |

## Open Questions — Resolved

Both Phase 169 planning questions are resolved below as implementation decisions within the approved requirements. They do not assert new user/product approval or passing implementation tests.

1. **Resolved: first-run denial contract.** Generate the compiling host-owned Plug/hook selected in Plan 169-01: HTTP sends 403 and halts; disconnected/connected LiveView entry halts with a redirect to `/`. The root is a local denial destination, not an invented login convention. The untouched seam never authorizes, including with nil/empty session data or fabricated assigns. The host replaces it with its own current-policy checks; installer guidance names the file and responsibility. Evidence: Plan 169-01 Task 1 specifies these exact behaviors; the existing host fixture demonstrates the 403/halt and `{:halt, redirect(...)}` contracts. Plan 169-01's rendered-output regressions establish implementation evidence during execution. `[VERIFIED: .planning/phases/169-install-and-upgrade-convergence/169-01-PLAN.md, Task 1; test/support/lockspire/web/admin_route_host.ex:158-170,234-243]`
2. **Resolved: historical fixture coverage and authority.** Plan 169-02 uses one pinned forward-only router template and tests two manifest field shapes, plus drift/refusal cases:
   - `v1.45` is annotated tag object `0f45d0c603c31d814cd9003848f6af508bb4e72c`, peeling to source commit `69c05922b880d1ee6e257e5a78f06a4e5755efcc`; that source's `mix.exs` declares package version `1.6.1`. Its router template forwards admin through `[:browser, :require_operator]`; `Templates` marks `lib/<web_path>/router/lockspire.ex` managed. `Install.render_template_content/3` prepends the ownership header, so fixture checksums must cover those complete rendered installed bytes. Its manifest contains `managed_files` path/checksum entries, `migrations`, and input `with_fapi_smoke`.
   - Commit `77d5ad902cd401effdc106873d35712a64d19b3d` supplies the actual older field shape: generator/version, five mount/storage/Oban/web/scope inputs and managed path/checksum entries, with neither `migrations` nor `with_fapi_smoke`. Its `Templates` also marks the router helper managed and `Manifest.checksum/1` uses lowercase SHA-256. Use this shape to prove optional-field compatibility with valid installed-file checksum evidence; it does not certify every file inventory or generated-host behavior from that commit. In particular, its older FAPI managed filename differs from the current inventory; an unshipped tracked path remains unsupported and must refuse rather than gain authority from the release label.
   - The manifest checksum matching actual installed managed bytes grants update authority, never a filename, version or fixture label. Missing tracked files, malformed/duplicate entries, drift, unsupported managed paths and unsafe/conflicting destinations refuse before writes with manual reconciliation guidance. Existing host policy/configuration stays preserved; a new authorization seam is create-only when absent and stays host-owned. Plan 169-02 owns conversion, omission compatibility, dry-run/retry/preservation and refusal regressions; these results remain pending execution.
   - Evidence inspected: `git cat-file -p v1.45`, `git rev-parse 'v1.45^{}'`, and historical `mix.exs`, router template, `Templates`, `Install.ownership_header` and `Manifest.build/checksum` at the revisions above. The tag describes milestone completion and explicitly separates package publication; no publication claim follows from its package version. `[VERIFIED: v1.45:mix.exs; v1.45:priv/templates/lockspire.install/router.ex; v1.45:lib/lockspire/generators/templates.ex; v1.45:lib/lockspire/generators/install.ex; v1.45:lib/lockspire/install/manifest.ex; 77d5ad90:lib/lockspire/generators/templates.ex; 77d5ad90:lib/lockspire/install/manifest.ex; .planning/phases/169-install-and-upgrade-convergence/169-02-PLAN.md, Task 1]`

**Evidence boundary:** No unresolved Phase 169 research question remains. A2 remains the distinct supported-version runtime uncertainty: Phase 170 owns exact Phoenix `1.8.5` / LiveView `1.1.28` and current-pair runtime proof, actual candidate-package adoption, browser/socket transport and required CI evidence. Source inspection and selected mechanisms do not establish those results. `[VERIFIED: .planning/ROADMAP.md, Phase 170 and Verification and Scope Boundaries]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| asdf | Proven runtime selection | ✓ | installed at `/opt/homebrew/bin/asdf`; selects Elixir `1.20.4`, OTP `29.1.1` | — |
| Mix | Focused ExUnit and generator tests | ✓ | `1.20.4` | — |
| PostgreSQL | Repository integration tests | ✓ | local server accepts connections at `/tmp:5432`; project phase records use PostgreSQL 14+ | Isolated test database only; do not run against host production data. |
| Phoenix / LiveView deps | Router and lifecycle tests | ✓ | Current lockfile pair is Phoenix `1.8.13` / LiveView `1.2.10`; Phase 168 records `locked versions were Phoenix `1.8.13`, Phoenix LiveView `1.2.10``; exact supported floor deferred to Phase 170 | Use compatibility fixture only for Phase 170 floor proof. |

No package installation or external service is required for this source-phase work. Browser/socket, packaged candidate, and exact-floor runtime proof belongs to Phase 170. `[VERIFIED: .planning/ROADMAP.md:107-121; .planning/phases/168-host-owned-liveview-authorization/168-VERIFICATION.md, Deferred Items]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, Phoenix.ConnTest, Phoenix.LiveViewTest, compiled Phoenix route metadata `[VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md, Test Infrastructure]` |
| Config file | `mix.exs`, `config/test.exs`, existing generated-host fixtures |
| Quick run command | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs` |
| Focused phase union | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/adoption_demo_operator_guard_test.exs test/lockspire/clean_room_release_source_contract_test.exs` |
| Broad gate | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` |
| Format | `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` |

These are real existing test paths. Extend the generator/upgrade/verifier suites to assert the new behavior; the command names remain directly runnable as tests are added. `HEX_HOME=/tmp/lockspire-phase169-hex` may be needed for repository release-artifact tests when the default Hex cache is not writable, as observed in Phase 168. `[VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VALIDATION.md, Final Source Audit and Regression Gate]`

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HDX-01 | Fresh generated helper compiles through shared route macro; endpoint/browser/session setup is documented; HTTP and connected hooks are explicitly required; generated staff policy denies until edited; no assumed account table | integration + compile | Focused union above, especially `test/integration/install_generator_test.exs` and `test/lockspire/web/admin_routes_compile_test.exs` | ✅ extend existing |
| HDX-02 | Legacy generated forward helper dry-run preserves all bytes; apply upgrades an unmodified managed helper; repeated run is byte-identical; managed drift and migration collision refuse; host-owned hook bytes stay unchanged | integration | Focused union above, especially `test/integration/install_upgrade_test.exs` | ✅ extend existing |
| HDX-03 | `mix lockspire.verify` recognizes complete native route/action/session/pipeline/hook metadata; rejects legacy forward, missing hooks/pipeline, missing/duplicate/shadowed routes, and avoids leaking sentinel secrets; output states policy limits | unit/integration | Focused union above, especially `test/lockspire/install/verify_test.exs` and `test/mix/tasks/lockspire_verify_test.exs` | ✅ extend existing |
| HDX-04 | Demo and maintained generated/clean-room hosts call the shared macro without duplicate inventory or fallback; supported-surface/install/admin/upgrade docs agree | source contract + compile + route integration | Focused union above plus `mix test test/lockspire/clean_room_release_source_contract_test.exs`; include existing fixture checks where relevant | ✅ existing paths; extend assertions |

### Sampling Rate

- Per task: run the owning test file(s) from the focused union.
- Per wave: rerun the entire focused union after generator, upgrade/verifier, and host/docs convergence waves.
- Phase gate: focused union, format check, and `mix test.fast`; report exact source revision and outcomes. No manual visual approval is needed for this mechanical integration phase. `[VERIFIED: .planning/VERIFICATION-POLICY.md:1-19]`

### Wave 0 Gaps

- No test framework, fixture, or dependency setup gap exists. Existing route compile/inventory, generator, upgrade, verifier, adoption demo, and clean-room checks are reusable. `[VERIFIED: test/integration/install_generator_test.exs; test/integration/install_upgrade_test.exs; test/lockspire/install/verify_test.exs; test/lockspire/web/admin_route_inventory_test.exs; test/lockspire/clean_room_release_source_contract_test.exs]`
- Add acceptance cases to those existing files for legacy-forward conversion, fail-closed generated authorization, verifier metadata/sensitive-output boundaries, and canonical helper use in demo/clean-room. Phase 169 verifies repository source and current locked runtime; candidate-package/browser/exact-floor execution remains owned by Phase 170. `[VERIFIED: .planning/ROADMAP.md:107-121]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host pipeline and host LiveView hook resolve the host's actual current staff identity; Lockspire adds no identity store. `[VERIFIED: AGENTS.md:9-10,20; lib/lockspire/web/admin_routes.ex:3-7]` |
| V3 Session Management | yes | Keep host session cookie/signing and endpoint/browser session wiring host-owned; check both regular HTTP and LiveView mount. `[CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html]` |
| V4 Access Control | yes | Fail-closed generated policy seam; require host policy hooks; verify declaration structure only; host tests prove allow/deny behavior. `[VERIFIED: .planning/REQUIREMENTS.md:28-30; .planning/ROADMAP.md:104-105]` |
| V5 Input Validation | yes | Preserve compile-time validation of static admin path and nonempty host pipeline/hooks; do not introduce dynamic route-path string parsing. `[VERIFIED: lib/lockspire/web/admin_routes.ex:112-159]` |
| V6 Cryptography | yes | No new cryptography; preserve existing OAuth/OIDC security defaults and do not expose secrets in verify diagnostics. `[VERIFIED: AGENTS.md:41-50; .planning/REQUIREMENTS.md:30]` |

### Known Threat Patterns for Phoenix Host Integration

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| HTTP pipeline guards initial request but not LiveView stateful entry/navigation | Elevation of privilege | Host Plug plus host `on_mount` in the same admin session; test missing and withdrawn authority independently. `[CITED: https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html; VERIFIED: .planning/phases/168-host-owned-liveview-authorization/168-VERIFICATION.md]` |
| Static verifier mistakes module presence for correct authorization | Elevation of privilege | State structural limit; do not claim policy correctness. Verify with host-authenticated/denied request tests. `[VERIFIED: .planning/ROADMAP.md:104-105; lib/lockspire/install/verify.ex:214-250]` |
| Install/upgrade follows a symlink, clobbers host modifications, or partially writes artifacts | Tampering / denial of service | Preserve lstat path checks, preflight, checksums, journal/recovery, rollback and manifest-last commit. `[VERIFIED: lib/lockspire/install/file_transaction.ex:1-9; lib/lockspire/install/operation_plan.ex:95-145]` |
| Verify diagnostics disclose session or secret material | Information disclosure | Report only structural metadata and safe module/path guidance; add sentinel-redaction assertions. Existing verifier already redacts sensitive key details. `[VERIFIED: lib/lockspire/install/verify.ex:68-93; test/lockspire/install/verify_test.exs:343-355]` |

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md` — Phase 169 goal, requirements, success criteria, and explicit constraints.
- `.planning/REQUIREMENTS.md` — exact HDX requirement text and assignment.
- `AGENTS.md` — host ownership, embedded-library shape, stack floors and security defaults.
- `lib/lockspire/web/admin_routes.ex`, `test/lockspire/web/admin_routes_compile_test.exs`, and `test/lockspire/web/admin_route_inventory_test.exs` — current canonical macro and compiled route/action/session/hook contracts.
- `lib/lockspire/install/operation_plan.ex`, `lib/lockspire/install/file_transaction.ex`, `lib/lockspire/install/manifest.ex`, and `test/integration/install_upgrade_test.exs` — current dry-run, checksum, drift, transaction and ownership behavior.
- `lib/lockspire/install/verify.ex` and `test/lockspire/install/verify_test.exs` — current forward-only structural check and false-positive proof boundary.
- `priv/templates/lockspire.install/router.ex`, `examples/adoption_demo/lib/adoption_demo_web/router.ex`, generated-host fixtures, and clean-room router overlay — current convergence targets.
- Phoenix LiveView 1.1.28 [Security considerations](https://phoenix-live-view.hexdocs.pm/1.1.28/security-model.html) — regular HTTP and stateful LiveView security boundary and hook guidance.
- Phoenix [Router `route_info/4` docs](https://phoenix.hexdocs.pm/Phoenix.Router.html#route_info/4) — compiled route metadata API; exact floor runtime validation remains Phase 170.

### Secondary (MEDIUM confidence)

- Phase 167 summaries and verification — native route integration implementation and evidence limits.
- Phase 168 summaries, verification and validation — current host-policy hook contract, denial coverage, and explicit package/browser/exact-floor boundaries.
- `docs/install-and-onboard.md`, `docs/supported-surface.md`, `docs/adoption-demo.md` — current adopter instructions to converge.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions are read from project AGENTS.md; runtime command prefix confirmed in Phase 168 and this environment.
- Architecture: HIGH — source and compiled route tests establish current API and duplication points; generated denial and historical coverage choices are resolved above, with implementation tests pending and exact-floor runtime proof owned by Phase 170.
- Pitfalls: HIGH — evidenced by current generated forward, demo duplication, verifier tests, and existing manifest/transaction checks.

**Research date:** 2026-10-23
**Valid until:** 2026-11-22 (stable repository architecture; re-check supported versions when planning Phase 170).
