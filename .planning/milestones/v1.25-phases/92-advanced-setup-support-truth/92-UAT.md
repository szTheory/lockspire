---
phase: 92-advanced-setup-support-truth
status: complete
completed: 2026-05-26T00:00:00Z
human_steps_required: 0
---

# Phase 92 UAT

## Objective

Record the exact automated proof used to close Phase 92 and the advanced-setup truth each command protects.

## Automated Proof Commands

1. `mix docs.verify`
   Expected evidence:
   - exits `0`
   - regenerated docs keep the mTLS, protected-route, logout, and canonical support pages internally consistent

2. `mix test test/lockspire/release_readiness_contract_test.exs`
   Expected evidence:
   - exits `0`
   - canonical support-contract assertions pin the two-pattern mTLS story, the canonical protected-route pipeline, and the asymmetric logout truth
   - onboarding and maintainer guidance continue to defer to the same public contract

3. `mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs`
   Expected evidence:
   - exits `0`
   - host Phoenix route protection still proves the canonical `VerifyToken -> EnforceSenderConstraints -> RequireToken` path
   - invalid-token, audience-mismatch, insufficient-scope, and DPoP nonce retry behavior remain executable truth

4. `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/clients_test.exs`
   Expected evidence:
   - exits `0`
   - admin surfaces keep logout propagation separate from post-logout redirect URIs
   - admin copy preserves the durable back-channel and best-effort front-channel support boundary
   - remote-JWKS command hints remain pointed at `mix lockspire.doctor remote-jwks --client <client_id>`

5. `mix test test/lockspire/release_readiness_contract_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/clients_test.exs`
   Expected evidence:
   - exits `0`
   - canonical docs, runtime proof, and admin wording stay aligned in one targeted support-truth run

## Manual Review Notes

- `docs/supported-surface.md` must name exactly two shipped mTLS extraction patterns and keep custom extractors out of first-class support-contract status.
- `docs/protect-phoenix-api-routes.md` must treat `Lockspire.Plug.EnforceSenderConstraints` as part of the canonical shipped pipeline, not an optional add-on.
- `docs/install-and-onboard.md`, `docs/operator-admin.md`, and `docs/dynamic-registration.md` must all describe `/end_session/complete` as the protocol-owned fork point and keep front-channel logout framed as best effort only.
- Admin client detail and logout propagation edit surfaces must repeat the same separation between logout propagation URIs and post-logout redirect URIs.
