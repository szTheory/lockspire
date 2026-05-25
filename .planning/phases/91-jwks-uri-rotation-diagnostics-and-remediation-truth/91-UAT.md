# Phase 91 UAT

## Objective

Record the exact automated proof used to close Phase 91 plan `91-03` and the evidence each command must produce.

## Automated Proof Commands

1. `mix docs.verify`
   Expected evidence:
   - exits `0`
   - regenerates docs without warnings that block completion

2. `mix test test/lockspire/release_readiness_contract_test.exs`
   Expected evidence:
   - exits `0`
   - release-contract assertions pin the bounded reactive remote-`jwks_uri` support wording
   - host-guide and onboarding assertions pin the runtime diagnosis and ownership split wording

3. `mix test test/integration/phase62_private_key_jwt_e2e_test.exs`
   Expected evidence:
   - exits `0`
   - proves inline `jwks` success
   - proves remote `jwks_uri` rollover recovery after one forced refresh
   - proves remote `jwks_uri` failure still returns generic `invalid_client`

4. `mix test test/lockspire/release_readiness_contract_test.exs test/integration/phase62_private_key_jwt_e2e_test.exs`
   Expected evidence:
   - exits `0`
   - combined support-truth and end-to-end proof stays green in one run

## Manual Review Notes

- `docs/supported-surface.md` must describe remote `jwks_uri` rollover as bounded reactive support.
- `docs/private-key-jwt-host-guide.md` must teach the remediation sequence, ownership split, and inline `jwks` as a deliberate fallback only.
- `docs/install-and-onboard.md` must keep `mix lockspire.verify` scoped to install wiring and point runtime remote-key incidents to `mix lockspire.doctor remote-jwks --client <client_id>`.
