# Phase 64: Sigra Golden Path & Generated-Host Proof - Research

**Researched:** 2026-05-06
**Domain:** Generated-host onboarding proof, Sigra-shaped host seam, and doc-truth enforcement for the embedded Phoenix install path. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Keep one canonical generated-host proof topology. `mix lockspire.install` remains the only canonical install path and the generated file set remains the proof anchor.
- **D-02:** Do not create a second Sigra-specific generated host topology, second fixture tree, or alternate install lane for proof.
- **D-03:** Use a narrow Sigra-shaped proof overlay inside the existing generated-host proof instead of a separate topology. The overlay may adjust host test wiring and fixtures only.
- **D-04:** Repo-owned proof must exercise the generated host router and host-owned seams directly, not bypass them through direct `Lockspire.Web.Router`-only shortcuts.
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
- **D-10:** Keep the canonical Sigra claims example narrow and truthful: stable internal `sub` plus a very small illustrative claim set.
- **D-11:** Treat richer org/role/tenant claim examples as non-canonical host extensions, not part of the default golden path.
- **D-12:** Never use email or other mutable login identifiers as canonical `sub` examples.
- **D-13:** Do not imply that Lockspire decides host claim semantics, tenant policy, role semantics, or token payload breadth.
- **D-14:** Claims proof should validate that subject and a minimal common OIDC claim set are correctly emitted while keeping claim destinations and product semantics clearly host-owned.
- **D-15:** Keep `docs/install-and-onboard.md` authoritative for the one canonical install path.
- **D-16:** Keep `docs/sigra-companion-host.md` authoritative for Sigra-specific generated-host wiring details.
- **D-17:** Do not duplicate full install instructions in the Sigra guide. Cross-link back to the canonical install doc instead.
- **D-18:** Keep proof authority maintainer-facing through executable tests and release-contract checks rather than creating a second user-primary onboarding document.
- **D-19:** Documentation must state clearly that `--sigra-host` changes guidance/comments only and does not create a second topology or dependency edge.
- **D-20:** Optimize for least surprise and trustworthy DX over maximum demo fidelity. A narrower honest proof is better than a richer but misleading fake-Sigra demo.
- **D-21:** Add or update executable doc/support-truth checks so the canonical install story, Sigra companion story, and generated-host proof cannot silently drift apart.
- **D-22:** Avoid examples that users are likely to cargo-cult into unsafe defaults, especially email-as-subject, broad ID-token payloads, or product-specific role/tenant semantics.
- **D-23:** For this phase and adjacent adoption-truth work, downstream GSD agents should default to codebase-first decisive recommendations and only escalate to the user for high-impact changes to product boundary, support contract, security posture, or public API shape.
- **D-24:** Medium-value implementation choices should be resolved coherently by researcher/planner agents rather than surfaced as option menus unless new evidence contradicts these locked decisions.

### Claude's Discretion

- Exact host test fixture shape, helper names, and support-module layout.
- Exact `current_scope` struct or map representation used in proof, provided it stays narrow and Sigra-compatible.
- Exact minimal illustrative claims beyond stable `sub`, provided the example remains small and clearly non-normative.
- Exact release-contract wording and test structure, provided the canonical-vs-companion doc authority remains unmistakable.

### Deferred Ideas (OUT OF SCOPE)

- A richer host-pattern appendix for multi-tenant org/role claims, if later demand justifies non-canonical guidance
- Any compile-time glue package or direct Lockspire-to-Sigra dependency
- A second Sigra-specific install or proof topology
- Broader examples that imply Lockspire owns tenant semantics, RBAC policy, or host identity modeling
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGRA-01 | Maintainers can run executable proof for the canonical Sigra-backed embedded authorization-code onboarding path from host session to authorization completion. [VERIFIED: .planning/REQUIREMENTS.md] | Use the existing generated-host endpoint/router topology from Phase 63 and replace the Phase 6 test-local hardcoded resolver with a session-backed `current_scope` overlay in `test/support/generated_host_app*`. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] |
| SIGRA-02 | The generated host path proves the security-sensitive seams Lockspire asks the host to own, including login redirect handoff, `return_to` or `interaction_id` preservation, account resolution, consent handoff, and claims construction. [VERIFIED: .planning/REQUIREMENTS.md] | Extend the generated-host login seam, resolver, and Phase 6 E2E assertions to cover unauthenticated authorize bounce, safe login resume, consent completion, account lookup, and narrow claims emission. [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: priv/templates/lockspire.install/interaction_handler.ex] |
| SIGRA-03 | Companion docs explain exactly how Lockspire integrates with Sigra through generated host code without introducing a compile-time dependency or blurring product ownership boundaries. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `docs/install-and-onboard.md` canonical, keep `docs/sigra-companion-host.md` focused on the Sigra-shaped seam, and add release-contract assertions so both docs describe the same one-topology story. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/sigra-companion-host.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
</phase_requirements>

## Summary

Phase 64 should not add a new proof app, Sigra fixture tree, or alternate install lane. The repo already has the correct proof anchor after Phase 63: the generated-host endpoint and router are exercised through `GeneratedHostAppWeb.Endpoint`, the install generator asserts that `--sigra-host` leaves the file set unchanged, and the docs already say Sigra is guidance-only rather than a dependency. [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/sigra-companion-host.md]

The remaining gap is realism at the host seam. `phase6_onboarding_e2e_test.exs` still defines a test-local `GeneratedHostResolver` that returns a hardcoded account from `resolve_current_account/2`, while the reusable generated-host test resolver reads session state directly and never models a `current_scope` assign. That means the repo proves protocol flow through the mounted host router, but it does not yet prove the Sigra-shaped seam Lockspire now documents in `docs/ecosystem-overview.md`. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] [VERIFIED: docs/ecosystem-overview.md]

The implementation-ready move is narrow: keep the existing generated-host topology, add one small support plug that maps the host session into `conn.assigns.current_scope`, update the reusable generated-host resolver to read `current_scope.user`, and rewrite the Phase 6 onboarding proof so it starts unauthenticated, bounces through the host login seam, preserves `return_to` plus `interaction_id`, resumes into consent, completes the auth-code flow, and asserts minimal claims output. Then tighten the install and Sigra docs plus `release_readiness_contract_test.exs` so the canonical install doc and the Sigra companion doc cannot drift. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] [VERIFIED: test/lockspire/host/claims_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Primary recommendation:** Evolve `test/support/generated_host_app*` into the single Sigra-shaped proof lane by inserting a session-to-`current_scope` plug and moving Phase 6 assertions onto the host-owned login, resolver, consent, and claims seams instead of creating any second topology. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Session-backed current user lookup | Browser/host Phoenix pipeline | API/Lockspire router | The host app owns the browser session and must assign the authenticated user shape before Lockspire authorization routes run. [VERIFIED: test/support/generated_host_app_web/router.ex] [VERIFIED: docs/ecosystem-overview.md] |
| OAuth `/authorize` interaction persistence and redirect decisions | API/Lockspire router | Host login seam | Lockspire owns the protocol interaction and can request a login redirect through `Lockspire.Host.AccountResolver`, but the host owns the human login screen and session establishment. [VERIFIED: lib/lockspire/host/account_resolver.ex] [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] |
| Login redirect preservation (`return_to`, `interaction_id`) | Host login seam | API/Lockspire router | Lockspire passes handoff context, and the host login controller must safely preserve and replay it without open redirects. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] |
| Consent UI and completion | Host LiveView/controller seam | API/Lockspire router | The host owns the consent surface and posts the decision back to Lockspire’s finalize route. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] [VERIFIED: priv/templates/lockspire.install/interaction_handler.ex] |
| Subject resolution and claims construction | Host resolver seam | Lockspire token issuance | The host defines account lookup and claim payloads; Lockspire merges protocol claims and emits tokens. [VERIFIED: lib/lockspire/host/account_resolver.ex] [VERIFIED: test/lockspire/host/claims_test.exs] |
| Canonical install truth | Docs (`install-and-onboard`) | Release contract tests | The install doc is the authoritative onboarding lane and should be guarded by executable doc-truth checks. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Sigra companion truth | Docs (`sigra-companion-host`) | Release contract tests | The Sigra guide should only explain the host seam overlay for the same topology and be fenced by release-truth tests. [VERIFIED: docs/sigra-companion-host.md] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir | `~> 1.18` project floor; local env `1.19.5` | Language/runtime for generator, tests, and host proof. [VERIFIED: mix.exs] [VERIFIED: local `elixir --version`] | The repo’s install/proof/test workflow is entirely Mix and ExUnit based. [VERIFIED: mix.exs] |
| Phoenix | `~> 1.8.5` | Host router, endpoint, controllers, and generated seam topology. [VERIFIED: mix.exs] | Phase 64 should continue proving the embedded Phoenix host shape rather than inventing an external example app. [VERIFIED: .planning/PROJECT.md] |
| Phoenix LiveView | `~> 1.1.28` | Host-owned consent surface. [VERIFIED: mix.exs] [VERIFIED: priv/templates/lockspire.install/consent_live.ex] | The generated consent seam already lives in LiveView and should remain the proof surface. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] |
| Ecto SQL / PostgreSQL | `~> 3.13.5` / `14+` | Durable interaction, consent, token, and signing-key state for the E2E flow. [VERIFIED: mix.exs] [VERIFIED: AGENTS.md] | The onboarding proof registers clients, publishes keys, and redeems tokens through the Ecto repository. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |
| Lockspire generated-host fixtures | repo local | Canonical topology under `test/support/generated_host_app*` plus install templates. [VERIFIED: test/support/generated_host_app_web/router.ex] [VERIFIED: priv/templates/lockspire.install/router.ex] | Phase 63 already moved proof authority onto this topology, so Phase 64 should deepen it rather than branch it. [VERIFIED: .planning/phases/63-canonical-install-path-host-diagnostics/63-04-SUMMARY.md] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| Bandit | `~> 1.6` | Shipped endpoint server dependency for Phoenix-native posture. [VERIFIED: mix.exs] | Keep as part of the standard runtime stack; no Phase 64 change needed. [VERIFIED: mix.exs] |
| Oban | `~> 2.21` | Part of the supported embedded host surface and release-truth docs. [VERIFIED: mix.exs] [VERIFIED: docs/install-and-onboard.md] | Mention only where canonical install truth is being fenced; Phase 64 is not adding new Oban behavior. [VERIFIED: docs/install-and-onboard.md] |
| JOSE | `~> 1.11` | ID token verification in the onboarding proof. [VERIFIED: mix.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] | Keep for E2E token assertions. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |
| ExUnit + Phoenix.ConnTest | repo local | Canonical proof harness for generated-host endpoint flows. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] | Use for all Phase 64 proof and release-truth checks. [VERIFIED: mix.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single generated-host topology | Second Sigra-specific fixture tree | Rejected because Phase 64 locked decisions explicitly prohibit a second topology and because Phase 63 already established generated-host proof authority. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [VERIFIED: .planning/phases/63-canonical-install-path-host-diagnostics/63-04-SUMMARY.md] |
| Session-to-`current_scope` overlay in test support | Compile-time Sigra dependency or copied Sigra internals | Rejected because the public compatibility target is the seam shape, not Sigra modules or internals. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |
| Narrow minimal claims example | Broad org/role/tenant canonical example | Rejected because Phase 64 locks a small truthful claim set and forbids implying host policy semantics. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |
| Release-contract doc fences | Separate “real Sigra onboarding” document | Rejected because the canonical install doc must stay primary and the companion doc must stay an overlay. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |

**Installation:**

```bash
mix deps.get
```

**Version verification:** Use the repo’s declared dependency constraints in [mix.exs](/Users/jon/projects/lockspire/mix.exs) and the local toolchain probes for execution planning. [VERIFIED: mix.exs] [VERIFIED: local `elixir --version`] [VERIFIED: local `mix --version`] [VERIFIED: local `psql --version`]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  -> GET /lockspire/authorize on GeneratedHostAppWeb.Endpoint
  -> GeneratedHostAppWeb.Router browser pipeline
  -> Host auth/session plug maps session -> conn.assigns.current_scope
  -> Lockspire.Web.Router /authorize
      -> AccountResolver.resolve_current_account(conn, context)
      -> if no current_scope.user: InteractionResult(login_path, return_to, interaction_id)
  -> GET /login on host SessionController
  -> POST /login stores session and redirects only to safe local return_to
  -> GET resumed /lockspire/authorize
  -> Lockspire consent route
  -> Host-owned consent UI posts /lockspire/interactions/:interaction_id/complete
  -> Lockspire exchanges code at /lockspire/token
  -> AccountResolver.resolve_account/2 + build_claims/2
  -> ID token / userinfo claims emitted
```

The diagram matches the current generated-host endpoint/router proof surface and inserts only the missing `current_scope` overlay before Lockspire routes. [VERIFIED: test/support/generated_host_app_web/endpoint.ex] [VERIFIED: test/support/generated_host_app_web/router.ex] [VERIFIED: lib/lockspire/host/account_resolver.ex]

### Recommended Project Structure

```text
test/
├── integration/
│   ├── phase6_onboarding_e2e_test.exs
│   └── phase37_protocol_strictness_e2e_test.exs
├── support/
│   ├── generated_host_app/lockspire/test_account_resolver.ex
│   └── generated_host_app_web/
│       ├── endpoint.ex
│       ├── router.ex
│       ├── router/lockspire.ex
│       └── controllers/session_controller.ex
docs/
├── install-and-onboard.md
├── sigra-companion-host.md
├── ecosystem-overview.md
└── supported-surface.md
```

This is already the canonical proof/doc layout to evolve in place for Phase 64. [VERIFIED: test/support/generated_host_app_web/router.ex] [VERIFIED: docs/install-and-onboard.md]

### Pattern 1: Sigra-Shaped Overlay Inside The Existing Generated Host

**What:** Add a tiny host support plug that derives `conn.assigns.current_scope` from the existing session-backed host state before requests hit `Lockspire.Web.Router`. Keep the router, endpoint, and generated fixture tree unchanged. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [VERIFIED: test/support/generated_host_app_web/router.ex]

**When to use:** For all generated-host proof paths that need to model Sigra’s public seam shape without importing Sigra. [VERIFIED: docs/ecosystem-overview.md] [VERIFIED: docs/sigra-companion-host.md]

**Example:**

```elixir
# Source: test/support/generated_host_app_web/router.ex + test/support/generated_host_app/lockspire/test_account_resolver.ex
pipeline :browser do
  plug(:accepts, ["html"])
  plug(:fetch_session)
  plug(:fetch_flash)
  plug(:protect_from_forgery)
  plug(:put_secure_browser_headers)
  plug(GeneratedHostAppWeb.AssignCurrentScope)
end

def resolve_current_account(%Plug.Conn{} = conn, context) do
  case conn.assigns[:current_scope] do
    %{user: user} -> {:ok, user}
    _ -> {:redirect, redirect_for_login(conn, context)}
  end
end
```

The plug name and exact shape are discretionary, but the responsibility split is locked. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [ASSUMED]

### Pattern 2: Login Bounce Must Preserve Lockspire Resume Context Safely

**What:** The host login seam should preserve `return_to` and `interaction_id`, but only redirect back to local paths after authentication. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex]

**When to use:** For unauthenticated `/authorize` flows and any future host-owned login bounce that needs to resume a protocol interaction. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: test/support/generated_host_app_web/controllers/session_controller.ex
def create(conn, params) do
  return_to = Map.get(params, "return_to", "/lockspire/authorize")

  conn
  |> put_session("current_account_id", normalize_login(params["login"]))
  |> maybe_put_auth_time(params["auth_time_seconds_ago"])
  |> redirect(to: safe_return_to(return_to))
end
```

Phase 64 should extend this seam to round-trip `interaction_id` explicitly in the proof assertions because the generated resolver template already includes it in `InteractionResult.params`. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex]

### Pattern 3: Claims Proof Should Stay Minimal And Host-Owned

**What:** Validate a stable string `sub` plus a very small OIDC claim set such as `email`, `email_verified`, and `name`, while keeping richer product semantics out of the canonical example. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex]

**When to use:** In the reusable generated-host resolver, the Sigra companion doc, and the Phase 6 onboarding E2E assertions. [VERIFIED: docs/sigra-companion-host.md] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

**Example:**

```elixir
# Source: test/support/generated_host_app/lockspire/test_account_resolver.ex
%Claims{
  subject: to_string(account.id),
  id_token: %{"email" => "#{account.id}@example.test"},
  userinfo: %{
    "email" => "#{account.id}@example.test",
    "email_verified" => true,
    "name" => "Generated Host User"
  }
}
```

Phase 64 should keep the shape narrow and should not move mutable identifiers such as email into `subject`. [VERIFIED: test/lockspire/host/claims_test.exs] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

### Pattern 4: Doc Authority Must Be Enforced In Tests

**What:** Treat `docs/install-and-onboard.md` as canonical install truth and `docs/sigra-companion-host.md` as the companion overlay, then assert both in `release_readiness_contract_test.exs`. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/sigra-companion-host.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**When to use:** Whenever docs describe generated-host Sigra wiring, `--sigra-host`, or canonical onboarding proof. [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/supported-surface.md]

### Anti-Patterns to Avoid

- **Second proof topology:** A Sigra-specific fixture tree or separate example app would conflict with locked decisions and duplicate proof authority. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]
- **Hardcoded current account success:** The Phase 6 test-local resolver currently bypasses host session realism; Phase 64 should remove that shortcut. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]
- **Session-only resolver with no `current_scope`:** The reusable resolver still reads `current_account_id` directly from session and never proves the documented Sigra-shaped seam. [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] [VERIFIED: docs/ecosystem-overview.md]
- **Broad canonical claims examples:** Org, role, or tenant examples in canonical docs would misstate ownership boundaries. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sigra proof lane | Separate Sigra example app or second generated-host tree | Existing `test/support/generated_host_app*` topology with a narrow overlay. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] | The repo already proves the mounted host router path there, and Phase 64 decisions forbid topology drift. [VERIFIED: .planning/phases/63-canonical-install-path-host-diagnostics/63-04-SUMMARY.md] |
| Host auth integration | Fake Sigra clone or compile-time Sigra dependency | One small plug that assigns `current_scope` from session-backed host state. [VERIFIED: docs/ecosystem-overview.md] [ASSUMED] | The compatibility target is the host seam shape, not Sigra internals. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |
| Consent resume path | New custom redirect protocol | Existing generated `InteractionHandler` finalize/consent paths. [VERIFIED: priv/templates/lockspire.install/interaction_handler.ex] | The host already has a generated seam that routes consent back into Lockspire correctly. [VERIFIED: priv/templates/lockspire.install/interaction_handler.ex] |
| Claims merge rules | Ad hoc token-claim composition in tests | `Lockspire.Host.Claims` merge behavior plus minimal host claims. [VERIFIED: test/lockspire/host/claims_test.exs] | The repo already strips host-owned `auth_time` and preserves protocol-owned fields. [VERIFIED: test/lockspire/host/claims_test.exs] |
| Doc-truth enforcement | Manual reviewer memory | `test/lockspire/release_readiness_contract_test.exs` assertions. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Phase 63 already uses release-contract tests to prevent support-story drift. [VERIFIED: .planning/phases/63-canonical-install-path-host-diagnostics/63-04-SUMMARY.md] |

**Key insight:** Phase 64 is a realism-hardening phase, not a new integration-surface phase. The correct strategy is to reuse the existing generator-backed topology and tighten the proof until it matches the docs exactly. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

## Recommended Plan Slices

### Slice 1: Session-To-`current_scope` Proof Overlay

- Add a host support plug in `test/support/generated_host_app_web/` that reads the existing session keys and assigns a minimal `%{user: %{...}}` current scope before Lockspire routes execute. [VERIFIED: test/support/generated_host_app_web/router.ex] [ASSUMED]
- Update `test/support/generated_host_app_web/router.ex` and, if needed, `endpoint.ex` to keep the pipeline order browser-safe and deterministic. [VERIFIED: test/support/generated_host_app_web/router.ex] [VERIFIED: test/support/generated_host_app_web/endpoint.ex]
- Refactor `test/support/generated_host_app/lockspire/test_account_resolver.ex` to read `conn.assigns.current_scope.user` for `resolve_current_account/2` while keeping `resolve_account/2` and `build_claims/2` host-owned and narrow. [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex]

### Slice 2: Onboarding E2E Realism Upgrade

- Rewrite `test/integration/phase6_onboarding_e2e_test.exs` to stop defining its own `GeneratedHostResolver` and instead rely on the generated-host support resolver. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]
- Start the test unauthenticated, assert redirect to `/login`, assert `return_to` and `interaction_id` preservation, post login through `SessionController`, resume the same interaction, and continue through consent and token exchange. [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] [VERIFIED: priv/templates/lockspire.install/account_resolver.ex]
- Keep claims assertions limited to stable `sub`, `nonce`, and a minimal OIDC claim set. [VERIFIED: test/lockspire/host/claims_test.exs] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

### Slice 3: Generated Stub And Doc Alignment

- Tighten `priv/templates/lockspire.install/account_resolver.ex` comments so the Sigra variant names `current_scope.user`, login bounce preservation, and minimal claims posture explicitly without implying a dependency. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: docs/sigra-companion-host.md]
- Update `docs/install-and-onboard.md` to say the canonical path remains one topology and to link to the Sigra companion guide only for host seam wiring specifics. [VERIFIED: docs/install-and-onboard.md]
- Update `docs/sigra-companion-host.md` to describe the same proof seam the repo now executes: session-backed host auth, assigned `current_scope`, resolver reading `current_scope.user`, narrow claims, and no compile-time dependency. [VERIFIED: docs/sigra-companion-host.md]
- Narrow `docs/ecosystem-overview.md` examples if needed so canonical examples stay aligned with the executable proof. [VERIFIED: docs/ecosystem-overview.md]

### Slice 4: Release-Truth Fences

- Extend `test/lockspire/release_readiness_contract_test.exs` to assert that `install-and-onboard.md` remains canonical, `sigra-companion-host.md` remains an overlay, `--sigra-host` is guidance-only, and both docs describe `current_scope`/generated-host behavior consistently. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: docs/install-and-onboard.md] [VERIFIED: docs/sigra-companion-host.md]
- Optionally add one focused generator assertion that the `--sigra-host` stub names `current_scope` guidance directly while still preserving the identical generated file set. [VERIFIED: test/integration/install_generator_test.exs]

### Key Files

- `test/integration/phase6_onboarding_e2e_test.exs` [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]
- `test/support/generated_host_app/lockspire/test_account_resolver.ex` [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex]
- `test/support/generated_host_app_web/router.ex` [VERIFIED: test/support/generated_host_app_web/router.ex]
- `test/support/generated_host_app_web/controllers/session_controller.ex` [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex]
- `priv/templates/lockspire.install/account_resolver.ex` [VERIFIED: priv/templates/lockspire.install/account_resolver.ex]
- `docs/install-and-onboard.md` [VERIFIED: docs/install-and-onboard.md]
- `docs/sigra-companion-host.md` [VERIFIED: docs/sigra-companion-host.md]
- `docs/ecosystem-overview.md` [VERIFIED: docs/ecosystem-overview.md]
- `docs/supported-surface.md` [VERIFIED: docs/supported-surface.md]
- `test/lockspire/release_readiness_contract_test.exs` [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Proving A Sigra Story With A Non-Sigra Seam

**What goes wrong:** The repo claims a `current_scope`-based Sigra companion story, but the proof still succeeds through a hardcoded or session-only resolver path. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] [VERIFIED: docs/ecosystem-overview.md]

**Why it happens:** Phase 63 moved the proof onto the generated host router, but it did not yet add the `current_scope` overlay. [VERIFIED: .planning/phases/63-canonical-install-path-host-diagnostics/63-04-SUMMARY.md]

**How to avoid:** Reuse the support resolver and support router only; do not keep a test-local resolver inside `phase6_onboarding_e2e_test.exs`. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

**Warning signs:** The test passes without any session/auth plug, or it never touches `/login`. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

### Pitfall 2: Losing `interaction_id` Or `return_to` Across The Login Bounce

**What goes wrong:** The host can authenticate the user but fail to resume the same authorization interaction safely. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** The generated resolver template emits `InteractionResult.return_to` and `interaction_id`, but the current test login controller only persists `return_to` explicitly and defaults redirect behavior locally. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex]

**How to avoid:** Assert the full bounce in the E2E test, including query parameters on the login GET and the resumed authorize/consent path after POST `/login`. [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] [ASSUMED]

**Warning signs:** The test jumps straight from `/authorize` to consent or reissues a fresh interaction after login. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

### Pitfall 3: Canonical Claims Examples Becoming Product Policy

**What goes wrong:** Docs or tests imply org, role, or email-as-subject behavior that belongs to the host product. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

**Why it happens:** Broad examples are easier to demo, but they blur the host seam. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

**How to avoid:** Keep `sub` stable and internal, and keep the illustrative claim set very small in both docs and tests. [VERIFIED: test/lockspire/host/claims_test.exs] [VERIFIED: docs/sigra-companion-host.md]

**Warning signs:** Canonical docs mention org ids, tenant ids, or roles as if Lockspire defines them. [VERIFIED: docs/ecosystem-overview.md]

### Pitfall 4: Doc Drift Between Canonical Install And Sigra Companion Guides

**What goes wrong:** Users see two install stories or contradictory ownership guidance. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]

**Why it happens:** The current release-contract test checks the install doc heavily but does not yet assert the Sigra companion doc’s narrow authority directly. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**How to avoid:** Add explicit assertions for both docs and the `--sigra-host` semantics in release-contract tests. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

**Warning signs:** The Sigra doc starts restating full install steps or suggesting a dependency edge. [VERIFIED: docs/sigra-companion-host.md]

## Code Examples

Verified repo patterns:

### Login Redirect Result Carries Resume State

```elixir
# Source: priv/templates/lockspire.install/account_resolver.ex
%InteractionResult{
  login_path: "/login",
  return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
  params: %{
    "interaction_id" => Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
  }
}
```

### Session Controller Uses Safe Local Redirects

```elixir
# Source: test/support/generated_host_app_web/controllers/session_controller.ex
defp safe_return_to(nil), do: "/lockspire/authorize"
defp safe_return_to(""), do: "/lockspire/authorize"
defp safe_return_to("/" <> _ = path), do: path
defp safe_return_to(_), do: "/lockspire/authorize"
```

### Generated Consent Surface Posts Back Into Lockspire

```elixir
# Source: priv/templates/lockspire.install/consent_live.ex
<form action={finalize_path(@interaction_id)} method="post">
  <input type="hidden" name="decision" value="approve" />
  <label>
    <input type="checkbox" name="remember" value="true" checked />
    Remember this consent for future matching requests
  </label>
  <button type="submit">Approve access</button>
</form>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Test-local hardcoded resolver in Phase 6 proof. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] | Shared generated-host resolver driven by a session-backed `current_scope` overlay. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [ASSUMED] | Planned for Phase 64. [VERIFIED: .planning/ROADMAP.md] | Makes the Sigra companion story executable instead of documentation-only. [VERIFIED: .planning/ROADMAP.md] |
| Session key read directly by reusable resolver. [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] | Resolver reads `conn.assigns.current_scope.user` and leaves session interpretation to a host plug. [VERIFIED: docs/ecosystem-overview.md] [ASSUMED] | Planned for Phase 64. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] | Preserves one topology while matching the documented host seam. [VERIFIED: docs/sigra-companion-host.md] |
| Release-contract tests fence canonical install truth only indirectly. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Release-contract tests assert canonical-install vs Sigra-companion authority explicitly. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [ASSUMED] | Planned for Phase 64. [VERIFIED: .planning/ROADMAP.md] | Prevents silent doc drift on the companion story. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |

**Deprecated/outdated:**

- Test-local resolver definitions inside onboarding proof files are outdated for the Sigra golden-path phase because they bypass the shared generated-host seam. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best support-module shape is a new `GeneratedHostAppWeb.AssignCurrentScope` plug rather than embedding the logic inside an existing controller or endpoint helper. [ASSUMED] | Architecture Patterns; Recommended Plan Slices | Low. The exact module name/layout can change without changing the phase strategy. |
| A2 | The proof should model `current_scope` as a plain map with a `user` key rather than a custom struct. [ASSUMED] | Architecture Patterns; Recommended Plan Slices | Low. A struct could still satisfy the same seam as long as `current_scope.user` remains the compatibility target. |

## Open Questions

1. **Should the generated `--sigra-host` resolver stub mention an example `current_scope` shape directly in code comments, or keep that example only in docs?**
   - What we know: the template already adds Sigra-oriented guidance and the companion doc already names `current_scope.user`. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: docs/sigra-companion-host.md]
   - What's unclear: how much example shape belongs in the generated file before it starts looking normative. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md]
   - Recommendation: keep one short `current_scope.user` hint in the stub and leave any richer discussion in `docs/sigra-companion-host.md`. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, generator, tests | ✓ [VERIFIED: local `elixir --version`] | `1.19.5` [VERIFIED: local `elixir --version`] | — |
| Mix | Install/verify/test commands | ✓ [VERIFIED: local `mix --version`] | `1.19.5` [VERIFIED: local `mix --version`] | — |
| PostgreSQL CLI/runtime | Ecto-backed integration proof | ✓ [VERIFIED: local `psql --version`] | `14.17` [VERIFIED: local `psql --version`] | — |
| Node.js | Docs/release workflow tooling in contributor lanes | ✓ [VERIFIED: local `node --version`] | `22.14.0` [VERIFIED: local `node --version`] | — |

**Missing dependencies with no fallback:**

- None found. [VERIFIED: local environment probes]

**Missing dependencies with fallback:**

- None found. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases. [VERIFIED: mix.exs] |
| Config file | `config/test.exs`. [VERIFIED: config/test.exs] |
| Quick run command | `MIX_ENV=test mix test.phase6.e2e` for the onboarding proof lane. [VERIFIED: mix.exs] |
| Full suite command | `MIX_ENV=test mix ci` for maintained contributor proof, plus targeted release-contract and generator tests when iterating on doc truth. [VERIFIED: mix.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGRA-01 | Canonical Sigra-shaped auth-code onboarding path runs from host session/login through token issuance. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `MIX_ENV=test mix test --include integration test/integration/phase6_onboarding_e2e_test.exs` | ✅ update existing [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |
| SIGRA-02 | Host-owned seams prove login redirect preservation, resume context, consent handoff, account resolution, and claims. [VERIFIED: .planning/REQUIREMENTS.md] | integration + focused unit | `MIX_ENV=test mix test --include integration test/integration/phase6_onboarding_e2e_test.exs test/lockspire/host/claims_test.exs` | ✅ update existing [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/lockspire/host/claims_test.exs] |
| SIGRA-03 | Canonical install doc and Sigra companion doc stay aligned and truthful. [VERIFIED: .planning/REQUIREMENTS.md] | unit/doc contract | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs test/integration/install_generator_test.exs` | ✅ update existing [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: test/integration/install_generator_test.exs] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test.phase6.e2e` or the smallest touched targeted command. [VERIFIED: mix.exs]
- **Per wave merge:** `MIX_ENV=test mix test test/integration/install_generator_test.exs test/integration/phase6_onboarding_e2e_test.exs test/lockspire/release_readiness_contract_test.exs test/lockspire/host/claims_test.exs` [VERIFIED: test/integration/install_generator_test.exs] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
- **Phase gate:** `MIX_ENV=test mix ci` plus the targeted Phase 64 tests above if `mix ci` does not already include them all. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/support/generated_host_app_web/assign_current_scope.ex` or equivalent support module is missing today and should be added before updating the proof. [ASSUMED]
- [ ] `test/integration/phase6_onboarding_e2e_test.exs` needs unauthenticated login-bounce coverage; the current test starts effectively authenticated. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]
- [ ] `test/lockspire/release_readiness_contract_test.exs` needs explicit assertions for `docs/sigra-companion-host.md` and the one-topology `--sigra-host` story. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: docs/sigra-companion-host.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: .planning/REQUIREMENTS.md] | Host login seam remains host-owned and the proof must preserve the login bounce correctly. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] |
| V3 Session Management | yes [VERIFIED: docs/ecosystem-overview.md] | Session-backed host state is converted into a narrow `current_scope` seam before Lockspire routes run. [VERIFIED: docs/ecosystem-overview.md] [ASSUMED] |
| V4 Access Control | yes [VERIFIED: priv/templates/lockspire.install/consent_live.ex] | Consent approval remains an explicit host-owned action posted back into Lockspire. [VERIFIED: priv/templates/lockspire.install/consent_live.ex] |
| V5 Input Validation | yes [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] | Safe local redirect validation on `return_to`; narrow query-param preservation only. [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] |
| V6 Cryptography | yes [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] | Keep token/JWT proof inside existing JOSE-backed issuance and verification paths; do not alter crypto behavior for Phase 64. [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect on login resume | Spoofing / Tampering | Keep `safe_return_to/1` local-path only and assert it in the host login seam. [VERIFIED: test/support/generated_host_app_web/controllers/session_controller.ex] |
| Lost `interaction_id` across login bounce | Tampering | Preserve `interaction_id` in `InteractionResult.params` and assert full bounce/resume in Phase 6 E2E. [VERIFIED: priv/templates/lockspire.install/account_resolver.ex] [ASSUMED] |
| Session/account mismatch between host session and emitted claims | Elevation of Privilege | Resolve the current account from assigned host scope and resolve subject lookup separately through `resolve_account/2`. [VERIFIED: lib/lockspire/host/account_resolver.ex] [VERIFIED: test/support/generated_host_app/lockspire/test_account_resolver.ex] |
| Mutable identifier used as canonical subject | Spoofing | Keep `sub` derived from a stable internal identifier, not email. [VERIFIED: test/lockspire/host/claims_test.exs] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |
| Overbroad canonical claims examples | Information Disclosure | Keep claims examples minimal and clearly host-owned. [VERIFIED: docs/sigra-companion-host.md] [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md` - locked phase decisions, proof boundaries, doc authority, and discretion areas.
- `.planning/ROADMAP.md` - Phase 64 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - `SIGRA-01` through `SIGRA-03`.
- `.planning/PROJECT.md` - embedded-library thesis and v1.16 adoption-truth direction.
- `.planning/ECOSYSTEM-SIGRA.md` - Sigra companion positioning and no-coupling contract.
- `.planning/phases/63-canonical-install-path-host-diagnostics/63-RESEARCH.md` and `63-04-SUMMARY.md` - current generated-host proof authority established in Phase 63.
- `docs/install-and-onboard.md`, `docs/sigra-companion-host.md`, `docs/ecosystem-overview.md`, `docs/supported-surface.md` - current public onboarding and ecosystem claims.
- `priv/templates/lockspire.install/account_resolver.ex`, `router.ex`, `interaction_handler.ex`, `consent_live.ex` - generated seam contracts.
- `test/integration/install_generator_test.exs`, `test/integration/phase6_onboarding_e2e_test.exs`, `test/integration/phase37_protocol_strictness_e2e_test.exs` - current proof coverage.
- `test/support/generated_host_app/lockspire/test_account_resolver.ex`, `test/support/generated_host_app_web/router.ex`, `endpoint.ex`, `controllers/session_controller.ex` - current host-fixture implementation.
- `test/lockspire/host/claims_test.exs` and `test/lockspire/release_readiness_contract_test.exs` - claims merge posture and doc-truth enforcement.
- `mix.exs` and `config/test.exs` - dependency/test framework definitions.

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None beyond items listed in the Assumptions Log.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - all stack and tooling claims come from `mix.exs`, AGENTS constraints, or local environment probes. [VERIFIED: mix.exs] [VERIFIED: AGENTS.md]
- Architecture: HIGH - the recommendation is tightly constrained by locked Phase 64 decisions and current generated-host test support. [VERIFIED: .planning/phases/64-sigra-golden-path-generated-host-proof/64-CONTEXT.md] [VERIFIED: test/support/generated_host_app_web/router.ex]
- Pitfalls: HIGH - each pitfall is grounded in a concrete mismatch between docs, templates, or current proof files. [VERIFIED: docs/ecosystem-overview.md] [VERIFIED: test/integration/phase6_onboarding_e2e_test.exs]

**Research date:** 2026-05-06
**Valid until:** 2026-06-05
