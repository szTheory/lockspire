# Phase 64: Sigra Golden Path & Generated-Host Proof - Patterns

**Mapped:** 2026-05-06
**Scope:** generated-host onboarding proof, Sigra-shaped account seam, claims proof, and support-truth enforcement.

## Reusable Patterns

### Host-wired integration proof

- `test/integration/phase6_onboarding_e2e_test.exs` already proves discovery, authorize, consent completion, token exchange, and JWKS through `GeneratedHostAppWeb.Endpoint`.
- `test/integration/phase37_protocol_strictness_e2e_test.exs` already shows how to vary resolver behavior without bypassing the host endpoint.

### Host-owned login seam

- `test/support/generated_host_app_web/controllers/session_controller.ex` is the canonical host login surface for the generated-host fixture.
- The controller already uses a safe local redirect policy; Phase 64 should extend it to preserve `interaction_id`, not replace it.

### Generated-host resolver seam

- `test/support/generated_host_app/lockspire/test_account_resolver.ex` is the right reuse point for the generated-host proof.
- Existing phase tests that need host session realism can compose around this resolver instead of creating new local ad hoc resolvers.

### Support-truth enforcement

- `test/lockspire/release_readiness_contract_test.exs` is the established contract-test hook for keeping docs and repo proof aligned.
- `test/integration/install_generator_test.exs` is the established contract-test hook for generated resolver guidance and generated file contents.

## Established Constraints

- The repo already treats `--sigra-host` as comments-only guidance, not a second topology.
- The canonical proof surface is the generated host router and endpoint, not `Lockspire.Web.Router` directly.
- Companion docs already frame the Sigra seam as `conn.assigns.current_scope.user`; Phase 64 should preserve that exact posture.

## Likely Helper Shape

- Add one narrow generated-host plug that converts session-backed fixture state into `conn.assigns.current_scope`.
- Keep the scope representation small, for example `%{user: %{id: ..., email: ...}}`, with optional auth-time metadata kept outside the user payload if needed.
- Preserve device-flow verification behavior by keeping the resolver's redirect parameter handling generic.

## Primary File Clusters

- Host seam cluster:
  `test/support/generated_host_app_web/controllers/session_controller.ex`
  `test/support/generated_host_app_web/router.ex`
  `test/support/generated_host_app/lockspire/test_account_resolver.ex`
- Proof cluster:
  `test/integration/phase6_onboarding_e2e_test.exs`
  `test/integration/phase37_protocol_strictness_e2e_test.exs`
  `test/integration/phase31_generated_host_verification_e2e_test.exs`
- Truth cluster:
  `priv/templates/lockspire.install/account_resolver.ex`
  `test/integration/install_generator_test.exs`
  `docs/sigra-companion-host.md`
  `docs/install-and-onboard.md`
  `docs/supported-surface.md`
  `test/lockspire/release_readiness_contract_test.exs`
