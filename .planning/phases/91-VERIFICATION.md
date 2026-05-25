# Phase 91 Verification

## Scope

Phase 91 tightened Lockspire's existing remote `jwks_uri` support truth. It did not broaden Lockspire into background remote-key monitoring, federation metadata ingestion, hosted auth, or a generic CIAM surface.

The shipped contract is now explicit:

- one bounded refresh on detectable stale-cache signals;
- preserved last-known-good cache when refresh fails;
- explicit unsupported-rollover classification for ambiguous shapes such as same-`kid` replacement;
- operator and doctor surfaces that expose classified posture without leaking raw JWKS bodies or JWT assertions.

## Requirement Coverage

- `JWKS-01`
  Covered by shared runtime diagnosis classification, admin detail posture rendering, targeted `mix lockspire.verify --remote-jwks-client ...`, updated host/operator/support docs, and end-to-end token endpoint proof.
- `JWKS-02`
  Covered by category-preserving runtime diagnosis (`target_safety`, `transport`, `http`, `payload`, `freshness`, `unsupported_rollover`), operator rendering, verify output, docs-truth assertions, and unit/integration coverage.

## Automated Evidence

Primary quick-path suite:

```bash
mix test test/lockspire/jwks_fetcher_test.exs \
  test/lockspire/protocol/client_auth_test.exs \
  test/lockspire/protocol/jarm_test.exs \
  test/lockspire/admin/clients_test.exs \
  test/lockspire/web/live/admin/clients_live/show_test.exs \
  test/integration/phase62_private_key_jwt_e2e_test.exs \
  test/lockspire/release_readiness_contract_test.exs \
  test/lockspire/install/verify_test.exs
```

Result: `103 tests, 0 failures`

Docs and contract fence:

```bash
mix docs.verify
```

Result: docs generated and verification completed successfully.

## Key Proof Points

- Runtime and telemetry now preserve remote-JWKS posture beyond generic OAuth wire errors.
- Client-auth tests prove supported refresh recovery and explicit unsupported-rollover classification.
- JARM tests prove the same classification contract for shared remote-key lookup.
- Admin tests and LiveView tests prove read-only operator posture and remediation rendering.
- Install verify tests prove the targeted remote-JWKS diagnostic mode remains opt-in.
- Phase 62 integration proof shows supported recovery, unsupported same-`kid` rollover, and failed refresh all remain generic `invalid_client` responses at the token endpoint boundary.
- Release-readiness assertions now fail if docs drift away from the bounded refresh and unsupported-rollover contract.
