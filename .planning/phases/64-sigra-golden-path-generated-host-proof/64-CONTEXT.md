# Phase 64: Sigra Golden Path & Generated-Host Proof - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 64 turns the Sigra companion story into executable repo-owned proof. The phase must prove the canonical generated-host authorization-code onboarding path end to end, including the host-owned seams Lockspire depends on for login redirect preservation, account resolution, consent handoff, and claims construction.

This phase does not introduce a second install topology, a compile-time Lockspire-to-Sigra dependency, a Lockspire-owned login UI, or richer product-policy semantics such as canonical org/role claim shapes.

</domain>

<decisions>
## Implementation Decisions

### Proof Topology

- **D-01:** Keep one canonical generated-host proof topology. `mix lockspire.install` remains the only canonical install path and the generated file set remains the proof anchor.
- **D-02:** Do not create a second Sigra-specific generated host topology, second fixture tree, or alternate install lane for proof.
- **D-03:** Use a narrow Sigra-shaped proof overlay inside the existing generated-host proof instead of a separate topology. The overlay may adjust host test wiring and fixtures only.
- **D-04:** Repo-owned proof must exercise the generated host router and host-owned seams directly, not bypass them through direct `Lockspire.Web.Router`-only shortcuts.

### Host Seam Realism

- **D-05:** The generated-host proof should model a minimal Phoenix/Sigra-shaped auth seam built around `conn.assigns.current_scope`, not a fake Sigra clone and not a purely generic raw-session proof.
- **D-06:** Proof should include a small host auth/session plug that derives `:current_scope` from session-backed host state before Lockspire routes execute.
- **D-07:** `resolve_current_account/2` in proof should read from the assigned host scope, not return a hardcoded fake account independent of host session state.
- **D-08:** Proof must explicitly exercise:
  - unauthenticated `/authorize` redirecting through the host login seam
  - preservation of `return_to` and `interaction_id`
  - post-login resume into consent
  - account resolution from host-owned scope data
  - consent completion back into Lockspire
  - claims construction from host account data
- **D-09:** Do not depend on Sigra modules, compile-time imports, copied Sigra internals, or private struct details. The public compatibility target is the host seam shape, especially `current_scope.user`.

### Claims Example Posture

- **D-10:** Keep the canonical Sigra claims example narrow and truthful: stable internal `sub` plus a very small illustrative claim set.
- **D-11:** Treat richer org/role/tenant claim examples as non-canonical host extensions, not part of the default golden path.
- **D-12:** Never use email or other mutable login identifiers as canonical `sub` examples.
- **D-13:** Do not imply that Lockspire decides host claim semantics, tenant policy, role semantics, or token payload breadth.
- **D-14:** Claims proof should validate that subject and a minimal common OIDC claim set are correctly emitted while keeping claim destinations and product semantics clearly host-owned.

### Documentation Authority

- **D-15:** Keep `docs/install-and-onboard.md` authoritative for the one canonical install path.
- **D-16:** Keep `docs/sigra-companion-host.md` authoritative for Sigra-specific generated-host wiring details.
- **D-17:** Do not duplicate full install instructions in the Sigra guide. Cross-link back to the canonical install doc instead.
- **D-18:** Keep proof authority maintainer-facing through executable tests and release-contract checks rather than creating a second user-primary onboarding document.
- **D-19:** Documentation must state clearly that `--sigra-host` changes guidance/comments only and does not create a second topology or dependency edge.

### DX And Support-Truth Guardrails

- **D-20:** Optimize for least surprise and trustworthy DX over maximum demo fidelity. A narrower honest proof is better than a richer but misleading fake-Sigra demo.
- **D-21:** Add or update executable doc/support-truth checks so the canonical install story, Sigra companion story, and generated-host proof cannot silently drift apart.
- **D-22:** Avoid examples that users are likely to cargo-cult into unsafe defaults, especially email-as-subject, broad ID-token payloads, or product-specific role/tenant semantics.

### Workflow Preference

- **D-23:** For this phase and adjacent adoption-truth work, downstream GSD agents should default to codebase-first decisive recommendations and only escalate to the user for high-impact changes to product boundary, support contract, security posture, or public API shape.
- **D-24:** Medium-value implementation choices should be resolved coherently by researcher/planner agents rather than surfaced as option menus unless new evidence contradicts these locked decisions.

### the agent's Discretion

- Exact host test fixture shape, helper names, and support-module layout.
- Exact `current_scope` struct or map representation used in proof, provided it stays narrow and Sigra-compatible.
- Exact minimal illustrative claims beyond stable `sub`, provided the example remains small and clearly non-normative.
- Exact release-contract wording and test structure, provided the canonical-vs-companion doc authority remains unmistakable.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 64 is:
  - one canonical generated-host topology,
  - a narrow Sigra-shaped proof overlay in tests only,
  - a minimal `current_scope`-shaped host seam,
  - a narrow canonical claims example,
  - canonical install guidance in `install-and-onboard`,
  - companion-specific seam guidance in `sigra-companion-host`,
  - executable support-truth enforcement in tests.
- The strongest adjacent precedents all reinforce this shape:
  - Phoenix `phx.gen.auth` generates host-owned code and leaves ownership with the host app.
  - OpenIddict and `oidc-provider` mount into existing host apps and let the host own interactive auth/session handling.
  - Doorkeeper is a useful reminder that example/provider apps can help adoption but easily become a shadow canonical topology if not tightly bounded.
  - Rodauth and similar generated-auth integrations show that multiple customization lanes create upgrade confusion fast.
- Specific proof footguns to avoid:
  - a second Sigra fixture tree becoming the de facto “real” path
  - a resolver that fakes success without host-session realism
  - losing `interaction_id` or `return_to` during login bounce
  - open redirect behavior in the proof login controller
  - storing full account or claim payloads in session
  - examples that turn org/role claim shapes into implied product contract

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product boundary
- `.planning/ROADMAP.md` — Phase 64 goal, requirements, and success criteria
- `.planning/REQUIREMENTS.md` — `SIGRA-01`, `SIGRA-02`, `SIGRA-03`
- `.planning/PROJECT.md` — embedded-library thesis, host seam boundaries, and v1.16 adoption-truth direction
- `.planning/STATE.md` — current milestone status and sequencing
- `.planning/ECOSYSTEM-SIGRA.md` — authoritative Sigra ecosystem positioning and sequencing
- `.planning/phases/63-canonical-install-path-host-diagnostics/63-CONTEXT.md` — locked install-path, diagnostics, ownership, and `--sigra-host` decisions that Phase 64 must preserve

### Current docs and support-truth surfaces
- `docs/install-and-onboard.md` — canonical install story and generated seam ownership language
- `docs/sigra-companion-host.md` — current Sigra companion wiring guidance
- `docs/ecosystem-overview.md` — ecosystem positioning and `current_scope`-oriented companion framing
- `docs/supported-surface.md` — support contract and shipped-surface wording
- `README.md` — public doc entrypoint that should stay aligned
- `CHANGELOG.md` — release posture/support-truth touchpoint

### Current generator and generated-host seam behavior
- `lib/mix/tasks/lockspire.install.ex` — install-task contract and `--sigra-host` help text
- `lib/lockspire/generators/install.ex` — generator behavior, ownership headers, and next-step messaging
- `priv/templates/lockspire.install/account_resolver.ex` — generated resolver seam and Sigra-oriented stub copy
- `priv/templates/lockspire.install/router.ex` — generated host router mount seam

### Current proof and regression coverage
- `test/integration/install_generator_test.exs` — guarantees that `--sigra-host` keeps the canonical generated file set unchanged
- `test/integration/phase6_onboarding_e2e_test.exs` — current generated-host onboarding proof to evolve into the Sigra golden path
- `test/integration/phase37_protocol_strictness_e2e_test.exs` — existing generated-host proof patterns for redirect/auth-time/session-sensitive behavior
- `test/support/generated_host_app_web/controllers/session_controller.ex` — current host login seam fixture
- `test/support/generated_host_app_web/router/lockspire.ex` — current generated host router fixture
- `test/lockspire/host/claims_test.exs` — host-claims merge and hygiene guardrails
- `test/lockspire/release_readiness_contract_test.exs` — support-truth and doc-contract enforcement surface

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The generated-host support app and onboarding proof in `test/integration/phase6_onboarding_e2e_test.exs` already provide the right base topology.
- `test/integration/install_generator_test.exs` already enforces that `--sigra-host` does not branch the generated file set.
- The generated resolver template already contains the correct ownership boundary and Sigra-oriented comments without a dependency edge.
- Existing strictness proof around login/session behavior in `phase37_protocol_strictness_e2e_test.exs` can inform the login-bounce and resume assertions Phase 64 needs.
- Release-readiness contract tests already provide an enforcement point for doc-truth alignment.

### Established Patterns

- Lockspire generates host-owned seams into the host app and expects the host to own login UX, claims, policy, and browser surfaces.
- Canonical paths are generator-first and Phoenix-first; companion integrations are guidance overlays, not alternate product shapes.
- Support truth is enforced with executable docs/tests, not prose alone.
- Phase 63 already locked “one canonical path, Sigra guidance only, no second topology” as a foundational milestone decision.

### Integration Points

- Phase 64 planning should likely center around:
  - upgrading the generated-host onboarding proof to use a `current_scope`-shaped seam,
  - tightening the host login/session fixture and resolver realism,
  - narrowing and clarifying the canonical claims example,
  - aligning Sigra companion docs with the evolved proof,
  - adding release-contract assertions so docs and proof cannot drift.

</code_context>

<deferred>
## Deferred Ideas

- A richer host-pattern appendix for multi-tenant org/role claims, if later demand justifies non-canonical guidance
- Any compile-time glue package or direct Lockspire-to-Sigra dependency
- A second Sigra-specific install or proof topology
- Broader examples that imply Lockspire owns tenant semantics, RBAC policy, or host identity modeling

</deferred>

---

*Phase: 64-sigra-golden-path-generated-host-proof*
*Context gathered: 2026-05-06*
