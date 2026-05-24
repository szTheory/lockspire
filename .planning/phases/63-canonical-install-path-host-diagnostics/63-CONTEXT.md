# Phase 63: Canonical Install Path & Host Diagnostics - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 63 hardens Lockspire's install and upgrade story for its intended embedded Phoenix shape. The phase covers the canonical generator-backed onboarding path, early diagnostics for the most dangerous host integration mistakes, and explicit ownership/upgrade boundaries for generated files.

This phase does not create a second product shape, introduce compile-time coupling to Sigra, or broaden Lockspire into a standalone auth service or generic host-app patcher.

</domain>

<decisions>
## Implementation Decisions

### Canonical Install Contract

- **D-01:** Keep exactly one canonical install entrypoint: `mix lockspire.install`.
- **D-02:** Keep the canonical generated file layout generic to Phoenix hosts. Do not create a separate Sigra-specific topology, dependency, or required file set.
- **D-03:** Keep `--sigra-host` as a thin companion variant that changes guidance, comments, examples, and possibly diagnostics copy only. It must not introduce compile-time Sigra coupling or a second canonical path.
- **D-04:** Public docs should state: Lockspire works with any Phoenix auth stack that can satisfy the host seams; Sigra is the recommended and best-documented companion path.
- **D-05:** The canonical install/onboarding contract must remain embedded-library-first: host apps own accounts, login UX, layouts, branding, and product policy; Lockspire owns protocol correctness, durable protocol state, and narrow host integration contracts.

### Diagnostics Topology

- **D-06:** Use a layered diagnostics model, not a single install-time gate.
- **D-07:** `mix lockspire.install` should stay focused on generation, obvious project-shape validation, and ownership-safe scaffolding. It should not try to prove post-edit router wiring or migration state that only becomes true after host integration work.
- **D-08:** Runtime config validation should continue to fail fast at boot for required Lockspire-owned configuration and subsystems, following the existing `Config.*!` and Oban validation posture.
- **D-09:** Add a dedicated diagnostics command as the canonical verification step after install and host wiring: `mix lockspire.verify`.
- **D-10:** `mix lockspire.verify` should check at minimum:
  - required runtime config presence and consistency
  - host resolver/interaction seam module presence
  - router mount wiring for the Lockspire-owned routes
  - presence of the host-owned `/verify` seam routes
  - pending Lockspire and Oban migrations relevant to shipped features
- **D-11:** Router-wiring diagnostics should inspect the compiled host router rather than infer correctness from generated files alone.
- **D-12:** Migration diagnostics should compare expected migration versions against the host repo's applied migrations rather than relying on indirect runtime failures.
- **D-13:** Request-time failures should be the last resort only. When a host-owned seam is still incomplete, Lockspire should fail with direct install-oriented guidance instead of indirect protocol errors.

### Generated Seam Behavior

- **D-14:** Generated host seam stubs must intentionally fail until implemented for security-sensitive callbacks and behaviors. Do not keep permissive scaffold defaults that can compile and appear healthy while returning fake or placeholder behavior.
- **D-15:** The install path should be bootstrap-safe. `mix lockspire.install` must not require prior Lockspire runtime config to generate the initial config and router seam.
- **D-16:** If generator defaults need mount-path input, use a safe default or explicit install-task option rather than reading config that the generator itself is meant to create.
- **D-17:** Generated proof should validate the real embedded integration contract more truthfully than today's direct `Lockspire.Web.Router` proof. Repo-owned verification should prove host router mount wiring, not only template rendering.

### Upgrade and Regeneration Contract

- **D-18:** Preserve strict non-overwrite semantics for truly host-owned generated files. Reruns must not clobber host edits in files where the host owns business logic, UX, branding, claims, or policy.
- **D-19:** Do not adopt merge-marker regeneration or broad automatic file merging for host-edited Elixir/Phoenix source.
- **D-20:** Split generated artifacts into two conceptual classes:
  - host-owned seams that are copied once and edited freely
  - Lockspire-managed scaffolding that can be safely upgraded when unchanged
- **D-21:** Add explicit ownership annotations to every generated artifact so maintainers can tell whether a file is host-owned or Lockspire-managed without guessing.
- **D-22:** Introduce a separate upgrade command for managed scaffolding rather than overloading `mix lockspire.install` with risky overwrite behavior. The working target is `mix lockspire.upgrade`.
- **D-23:** The upgrade path should be manifest-aware. Track generated file versions or checksums so Lockspire can distinguish unchanged managed files from drifted or host-owned files and produce targeted upgrade guidance.
- **D-24:** The upgrade command should support dry-run or diff-preview behavior before making changes.
- **D-25:** The upgrade command should update unchanged managed files automatically, refuse risky overwrites on drifted host-owned files, and print explicit manual reconciliation steps when safe automation is not possible.
- **D-26:** Prefer narrow, stable composition or structured patching only for clearly bounded integration fragments such as config imports or router helper wiring. Do not attempt general-purpose three-way merges of host-owned code.

### Recommended Artifact Ownership

- **D-27:** Treat the following as host-owned seams by default:
  - `account_resolver.ex`
  - `interaction_handler.ex`
  - generated consent, authorized-apps, and verification browser/controller surfaces
- **D-28:** Treat the following as candidates for Lockspire-managed scaffolding:
  - `config/lockspire.exs`
  - `lib/<web>/router/lockspire.ex`
  - generated smoke/proof test files
  - install manifest metadata

### Workflow Preference

- **D-29:** Shift decision pressure left for this project. Downstream GSD agents should default to coherent recommendations and proceed without re-asking for low- and medium-impact implementation choices.
- **D-30:** Escalate back to the user only for materially high-impact changes to product boundary, security posture, support contract, or public API shape.

### the agent's Discretion

- Exact command names, manifest file path, and manifest schema.
- Exact router-inspection and migration-inspection implementation details for `mix lockspire.verify`.
- Exact ownership-header wording, provided the host-owned vs managed distinction is unmistakable.
- Exact classification of borderline generated artifacts, provided host-owned policy/account/UX seams remain non-overwritable by default.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 63 is:
  - one generic canonical install path,
  - Sigra as the recommended companion path rather than a required or separate topology,
  - a dedicated `mix lockspire.verify` diagnostics task,
  - intentionally failing host seam stubs until implemented,
  - strict host-owned non-overwrite semantics,
  - a separate manifest-aware `mix lockspire.upgrade` path for managed scaffolding.
- This mirrors the strongest adjacent patterns:
  - Phoenix generators emit host-owned code and make upgrade responsibility explicit,
  - Oban fails fast for invalid runtime config,
  - OpenIddict and node-oidc-provider keep protocol core separate from host/framework seams,
  - Doorkeeper is a useful precedent for splitting install concerns, but a caution against making the provider feel overly tied to one auth stack.
- Concrete footguns to avoid:
  - turning Sigra from recommended companion into implied required dependency
  - making `mix lockspire.install` depend on config it is supposed to create
  - permissive generated resolver defaults that look "working" before the host has implemented real account and claim logic
  - claiming generated proof covers router integration when it only proves template rendering
  - treating every generated file as equally host-owned forever when some are really Lockspire-managed scaffolding

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product boundary
- `.planning/ROADMAP.md` — Phase 63 goal, requirements, and success criteria
- `.planning/REQUIREMENTS.md` — `HOST-01`, `HOST-02`, `HOST-03`
- `.planning/PROJECT.md` — embedded-library thesis, host ownership boundaries, and install-DX priority
- `.planning/STATE.md` — current milestone status and v1.16 direction
- `.planning/ECOSYSTEM-SIGRA.md` — ecosystem sequencing and Sigra companion positioning

### Current onboarding and ecosystem docs
- `docs/install-and-onboard.md` — current canonical onboarding flow and generated seam story
- `docs/sigra-companion-host.md` — current Sigra companion guidance
- `docs/ecosystem-overview.md` — current ecosystem positioning and host-boundary explanations
- `docs/supported-surface.md` — support-contract wording that must stay aligned with the install story

### Current generator and config/runtime behavior
- `lib/mix/tasks/lockspire.install.ex` — install-task contract and help text
- `lib/lockspire/generators/install.ex` — current generator behavior, overwrite policy, and next steps
- `lib/lockspire/generators/templates.ex` — generated artifact inventory
- `priv/templates/lockspire.install/config.exs` — generated config seam
- `priv/templates/lockspire.install/router.ex` — generated router seam
- `priv/templates/lockspire.install/account_resolver.ex` — generated account seam behavior to harden
- `priv/templates/lockspire.install/interaction_handler.ex` — generated interaction seam
- `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` — current generated proof shape
- `lib/lockspire/config.ex` — fail-fast config validation precedent
- `lib/lockspire/oban.ex` — boot-time subsystem validation precedent
- `lib/lockspire/host/account_resolver.ex` — host seam contract
- `lib/lockspire/web/router.ex` — Lockspire-owned route surface that host wiring must expose

### Current proof and regression coverage
- `test/integration/install_generator_test.exs` — current generator/idempotence proof and upgrade-safety baseline
- `test/lockspire/application_test.exs` — current startup validation behavior
- `test/lockspire/config_test.exs` — config validation behavior
- `test/lockspire/release_readiness_contract_test.exs` — support-truth guardrail that should eventually reflect the hardened install story

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Generators.Install` already provides a safe no-overwrite baseline and clear next-step messaging.
- `Lockspire.Config` and `Lockspire.Oban` already establish the repo's fail-fast boot-time validation style.
- The generated router/config/helper templates already separate Lockspire-owned protocol routes from host-owned browser and account seams.
- Existing integration tests already verify generator output and idempotence, providing a base to evolve toward real host-router proof.

### Established Patterns

- Host-owned browser, account, and policy seams are generated into the host app instead of being hidden behind library-owned runtime magic.
- Protocol correctness and durable operational concerns stay inside Lockspire-owned modules.
- Truthful support posture is enforced with docs plus executable tests, not with docs alone.
- Safe defaults prefer refusing risky overwrite behavior to silently mutating user code.

### Integration Points

- Phase 63 planning should likely center around:
  - installer bootstrap safety,
  - a new diagnostics Mix task,
  - host seam stub hardening,
  - managed-vs-host-owned artifact classification,
  - upgrade-path scaffolding and manifest design,
  - proof updates that exercise real host router mounting.

</code_context>

<deferred>
## Deferred Ideas

- Turning Sigra into a required runtime or compile-time dependency
- Supporting multiple equally canonical install lanes with different generated topologies
- General-purpose auto-merging of host-edited Elixir/Phoenix files
- Broad host-app patching beyond narrow, stable integration anchor points
- Standalone hosted-auth setup flows or Lockspire-owned login UX

</deferred>

---

*Phase: 63-canonical-install-path-host-diagnostics*
*Context gathered: 2026-05-06*
