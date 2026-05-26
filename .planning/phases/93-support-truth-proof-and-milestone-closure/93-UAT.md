# Phase 93 UAT

## Objective

Record the exact automated proof used to close Phase 93 and the support-truth evidence each command must produce for `PROOF-01` and `PROOF-02`.

## Automated Proof Commands

1. `mix test test/lockspire/release_readiness_contract_test.exs`
   Proof target:
   - `PROOF-02`
   Expected evidence:
   - exits `0`
   - advanced-setup release-contract assertions pin the canonical support contract from `docs/supported-surface.md`
   - semantic helper-backed checks fail if the shipped mTLS patterns, protected-route pipeline, bounded reactive remote-`jwks_uri` rollover truth, or logout support boundary drift
   - non-claims stay fenced: no custom extractor parity, no generic protected-resource support, and no durable front-channel logout claim

2. `mix test test/lockspire/jwks_fetcher_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs`
   Proof target:
   - `PROOF-01`
   Expected evidence:
   - exits `0`
   - remote `jwks_uri` proof stays bounded reactive instead of proactive
   - forced refresh can recover stale or unknown key material
   - invalid JWKS content, unavailable `kid`, and refresh failures preserve fail-closed behavior and last-known-good cache truth
   - runtime wire behavior remains generic while safe support detail remains available to diagnostics and operator surfaces

3. `mix test test/mix/tasks/lockspire_doctor_remote_jwks_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs`
   Proof target:
   - `PROOF-01`
   Expected evidence:
   - exits `0`
   - doctor and admin surfaces read from one shared remote-JWKS support model instead of diverging wording
   - healthy and degraded remote-JWKS states preserve stable class, stage, subreason, remediation, and redaction truth
   - install-time `mix lockspire.verify` remains separate from runtime remote-JWKS diagnosis

4. `mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs`
   Proof target:
   - `PROOF-01`
   Expected evidence:
   - exits `0`
   - the generated-host Phoenix route path still proves the canonical `Lockspire.Plug.VerifyToken -> Lockspire.Plug.EnforceSenderConstraints -> Lockspire.Plug.RequireToken` pipeline
   - route protection preserves the shipped `401 invalid_token` versus `403 insufficient_scope` split
   - sender-constrained behavior remains executable truth at the host seam for the representative second advanced-setup surface

5. `mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/jwks_fetcher_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs test/mix/tasks/lockspire_doctor_remote_jwks_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs`
   Proof target:
   - `PROOF-01`
   - `PROOF-02`
   Expected evidence:
   - exits `0`
   - documentation-truth fences and representative runtime proof stay green in one targeted support-truth run
   - Phase 93 closes on repo-native evidence without re-reading the full phase history

## Manual Review Notes

- `PROOF-01` is satisfied only if remote-JWKS runtime proof and the generated-host protected-route seam both stay green on the current tree.
- `PROOF-02` is satisfied only if the release-contract suite still treats `docs/supported-surface.md` as the sole public support-contract authority and rejects broadened support claims from derived guidance.
- The phase-close and milestone-close verification artifacts must cite these exact commands so future milestone audits can reuse the proof chain directly.
