# Phase 61 Validation

## Scope

Phase 61 delivers shared `private_key_jwt` verification for Lockspire-owned direct-client surfaces:

- `61-01` shared verifier pipeline split
- `61-02` claim policy, algorithm allowlists, and replay ordering
- `61-03` direct-client endpoint/runtime truth plus discovery/introspection drift cleanup
- `61-04` telemetry, audit, and redaction proof

## Wave Plan

| Wave | Plans | Why |
|---|---|---|
| 1 | `61-01` | Establishes the shared staged verifier architecture |
| 2 | `61-02` | Hardens claim, algorithm, and replay policy on top of the new shared seam |
| 3 | `61-03` | Rolls the verified capability through endpoint/runtime truth and metadata truth |
| 4 | `61-04` | Adds shared observability/audit/redaction proof after runtime behavior is settled |

## Nyquist Validation Matrix

| Plan | Automated validation |
|---|---|
| `61-01` | `mix test test/lockspire/protocol/client_auth_test.exs` |
| `61-02` | `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/storage/ecto/repository_used_jti_test.exs` |
| `61-03` | `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs test/lockspire/protocol/backchannel_authentication_test.exs test/lockspire/web/ciba_authorization_json_test.exs` |
| `61-04` | `mix test test/lockspire/audit/event_test.exs test/lockspire/redaction/redaction_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs` |

## Phase Exit Commands

Run these after all four plans complete:

```bash
mix test test/lockspire/protocol/client_auth_test.exs \
  test/lockspire/audit/event_test.exs \
  test/lockspire/redaction/redaction_test.exs \
  test/lockspire/storage/ecto/repository_used_jti_test.exs \
  test/lockspire/protocol/discovery_test.exs \
  test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs \
  test/lockspire/protocol/backchannel_authentication_test.exs \
  test/lockspire/web/ciba_authorization_json_test.exs \
  test/lockspire/web/discovery_controller_test.exs
```

```bash
mix test test/lockspire/protocol/token_endpoint_dpop_test.exs
```

The second command is a regression guard: Phase 61 intentionally copies replay-ordering semantics from DPoP and should not break that existing precedent.

## Source Audit

### GOAL coverage

| Source item | Covered by |
|---|---|
| All Lockspire-owned direct-client surfaces enforce full `private_key_jwt` verification consistently | `61-01`, `61-02`, `61-03` |
| Shared behavior is truthful and embedded-library shaped | `61-01`, `61-03` |
| Telemetry/audit/redaction proof closes the internal trust story | `61-04` |

### REQ coverage

| Requirement | Covered by |
|---|---|
| `PKJWT-01` | `61-01` |
| `PKJWT-02` | `61-02` |
| `PKJWT-03` | `61-02` |
| `PKJWT-04` | `61-02` |
| `PKJWT-05` | `61-02`, `61-04` |
| `PKJWT-06` | `61-03` |
| `OBS-01` | `61-04` |

### RESEARCH coverage

| Research constraint | Covered by |
|---|---|
| Reuse shared `ClientAuth` seam rather than endpoint-local verification | `61-01`, `61-03` |
| Reuse Phase 60 guarded fetcher and existing JOSE verification patterns | `61-01`, `61-02` |
| Use issuer-identifier audience binding | `61-02` |
| Keep metadata/runtime truth aligned | `61-03` |
| Keep public errors generic while preserving internal observability detail | `61-03`, `61-04` |

### CONTEXT coverage

| Decision set | Covered by |
|---|---|
| D-04 to D-08 staged verifier architecture and trusted ordering | `61-01`, `61-02` |
| D-09 to D-17 algorithm, claim, and replay rules | `61-02` |
| D-18 to D-22 generic public errors plus internal observability/redaction | `61-04` |
| D-23 to D-27 shared direct-client capability and drift cleanup | `61-03` |

## Acceptance Checklist

- [ ] `ClientAuth` uses explicit stages and no longer authenticates from unverified payload claims
- [ ] `private_key_jwt` rejects unsupported algorithms and wrong issuer-bound audiences
- [ ] Replay state is written only after signature and trusted-claim validation succeed
- [ ] Introspection and discovery truth match the shipped shared verifier capability
- [ ] Representative direct-client surfaces have regression proof for shared `private_key_jwt`
- [ ] CIBA public JSON does not expose internal `reason_code` values for shared client-auth failures
- [ ] Telemetry and durable audit capture stable failure reasons without leaking raw assertion or JWKS material

## Notable Risks

- `61-03` relies on existing endpoint thin-adapter behavior staying intact; if execution finds a hidden endpoint-local carveout, the plan must fix it rather than masking it in metadata.
- `61-04` assumes the shared verifier can append focused audit events through existing repo seams; if an endpoint-specific audit store contract blocks that, execution should standardize the seam instead of duplicating per-endpoint logic.
