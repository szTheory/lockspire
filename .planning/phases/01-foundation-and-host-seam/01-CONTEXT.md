# Phase 1: Foundation and Host Seam - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 establishes Lockspire's embedded-library shape, internal boundaries, Ecto/Postgres-backed durable storage path, explicit host seam, and generated host integration path. It does not implement the full authorization flow yet; it creates the structural and integration foundation that later protocol, OIDC, operator, and hardening phases will build on.

</domain>

<decisions>
## Implementation Decisions

### Public API and install shape
- **D-01:** Lockspire will use one canonical Phoenix-first install path: add the dependency, run a generator, run migrations, add a router mount, and set compact runtime configuration.
- **D-02:** The real integration contract will be explicit modules and behaviours, not config magic. Runtime config is a locator for host modules, not the primary behavior surface.
- **D-03:** The public API should stay small, explicit, and function-first. Avoid macro-heavy DSLs and compile-time code injection as the primary integration model.
- **D-04:** Phoenix integration is layered on top of a protocol core; Lockspire should feel like a mounted Phoenix component for onboarding, with behaviour-driven wiring underneath.

### Host seam contract
- **D-05:** Phase 1 will center the host seam on one narrow `AccountResolver`-style behaviour rather than several separate behaviours or loose callback config.
- **D-06:** That behaviour should cover only: resolving the current authenticated account during authorization, resolving an account/subject when needed, producing claim material for token/userinfo generation, and returning a structured redirect/handoff result when no authenticated account is available.
- **D-07:** Lockspire must not absorb host-owned concerns such as user schema ownership, session policy, login UX, layouts, branding, or product-specific authorization policy.
- **D-08:** Keep the seam singular and explicit in v1. Additional extension points should only be added later when they represent clearly separate concerns, not as speculative decomposition.

### Storage and adapter boundary
- **D-09:** Ship one production-grade Ecto/Postgres implementation in Phase 1 and treat it as the default and only serious storage path for v1.
- **D-10:** Define thin, domain-level storage behaviours around real OAuth/OIDC concerns such as clients, consents/authorizations/interactions, tokens/grants, keys, and audit, rather than generic CRUD or raw `Repo`-style abstractions.
- **D-11:** Protocol truth and invariants should live in service modules plus Ecto/Postgres constraints and transactions. Lockspire should be Ecto-native, not Ecto-entangled.
- **D-12:** Do not promise multi-backend portability in Phase 1. Adapter seams exist to preserve future options, not to force backend-agnostic design before the domain model is stable.

### Generated host code footprint
- **D-13:** Generate the host-owned glue that must be editable: router mount/pipeline hooks, config scaffold, `AccountResolver` implementation stub, interaction completion modules, and editable consent/interaction UI surfaces.
- **D-14:** Generated host files must be normal Phoenix modules/templates/tests that are easy to diff, edit, and own. Generator reruns should be idempotent or conflict-aware.
- **D-15:** Do not generate broad wrappers, protocol services, storage logic, token logic, admin internals, or macro DSLs into the host app.
- **D-16:** The library should own protocol correctness and durable OAuth domain logic; the host should own login/consent UX integration, copy, layout wrapping, and app-specific policy.

### the agent's Discretion
- Exact module names, namespace layout, and callback naming inside the chosen boundaries.
- Whether consent/interaction surfaces are LiveView-first with controller fallbacks, as long as generated host code remains normal Phoenix code.
- The precise grouping of storage behaviours, as long as they stay domain-level and avoid generic repository abstractions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and phase scope
- `.planning/PROJECT.md` — Product thesis, non-goals, architecture intent, and key project constraints.
- `.planning/REQUIREMENTS.md` — Phase 1 requirements mapping for `INTE-01` through `INTE-04`.
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and plan breakdown.
- `.planning/STATE.md` — Current project status and initialization decisions already in effect.
- `lockspire-idea.md` — Core product shape, architecture intent, and v1 planning target.

### Architecture and research
- `.planning/research/SUMMARY.md` — High-confidence project-level research synthesis and phase ordering rationale.
- `.planning/research/ARCHITECTURE.md` — Recommended layered architecture, project structure, and boundary guidance.
- `.planning/research/FEATURES.md` — Feature dependency relationships, including host seam and install DX expectations.
- `.planning/research/PITFALLS.md` — Known risks for weak host boundaries, scope creep, and install/design mistakes.
- `.planning/research/STACK.md` — Stack rationale and Ecto/Postgres durable-truth guidance.

### Host seam and install DX
- `prompts/lockspire-host-app-integration-seam.md` — Explicit ownership boundary between Lockspire and the host Phoenix app.
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — Recommended install flow, layer boundaries, and host seam posture.
- `prompts/Oauth server jtbd and domain.md` — Product lineage, `AccountResolver` seam, adapter expectations, and generated host-code direction.

### Prior art and ecosystem lessons
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — Comparative lessons from Doorkeeper, node-oidc-provider, OpenIddict, Hydra, Keycloak, and related systems.
- `prompts/lockspire-elixir-oss-library-practices.md` — Elixir OSS library API and configuration guidance relevant to Lockspire's public surface.
- `prompts/lockspire-phoenix-system-design.md` — Phoenix/OTP system design guidance relevant to durable truth, process boundaries, and library architecture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No application code exists yet; Phase 1 is defining the initial library structure and generated integration shape from a greenfield repo.
- The primary reusable assets are the prep corpus in `prompts/` and the architecture/research docs in `.planning/research/`.

### Established Patterns
- Prefer plain modules/functions, narrow behaviours, runtime-explicit configuration, and generated host-owned Phoenix code over macros or hidden callback config.
- Keep protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin delivery as distinct internal boundaries.
- Keep durable protocol truth in Postgres; use bounded runtime helpers only for acceleration or maintenance, not authoritative state.

### Integration Points
- Host Phoenix router mount and pipeline hooks.
- Host-owned `AccountResolver` implementation.
- Generated consent/interaction handoff modules and editable UI surfaces in the host app.
- Lockspire-owned protocol services speaking to thin domain-level storage behaviours with a default Ecto/Postgres implementation.

</code_context>

<specifics>
## Specific Ideas

- The recommended synthesis is: Doorkeeper-style install DX, node-oidc-provider/OpenIddict-style seam discipline, Phoenix generator-style host ownership, and explicit avoidance of Keycloak-style theming/framework weight.
- "A for onboarding, B for the actual contract": mounted Phoenix integration should be the happy path, but the true extension surface must remain explicit behaviours/modules.
- "Generate the seams and the app-facing UX the host must own; keep everything else inside the library."
- "Lockspire should be Ecto-native, not Ecto-entangled; extensible later, not backend-agnostic now."

</specifics>

<deferred>
## Deferred Ideas

- Additional host extension points beyond the primary `AccountResolver` seam — defer until a concrete later-phase need proves the seam is insufficient.
- Alternate storage backends such as Redis, ETS-heavy paths, or non-SQL adapters — defer until real adoption pressure exists.
- Macro/DSL conveniences, if ever considered, are explicitly not part of Phase 1.
- Broader generated admin customization in the host app — out of scope for this phase; Phase 4 owns operator-product depth.

</deferred>

---

*Phase: 01-foundation-and-host-seam*
*Context gathered: 2026-04-22*
