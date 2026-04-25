# Phase 22: Request Object Integration - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `22-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-04-25
**Phase:** 22-request-object-integration
**Mode:** assumptions
**Areas analyzed:** Integration seam & module layout; Parameter precedence & strict-mode posture; Trust model & client-key prerequisites & Phase 21 hardening scope; Error semantics & verification proof shape

## Assumptions Presented

### Integration seam and module layout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `Lockspire.Protocol.RequestObject` orchestrator composes `Jar.*` primitives; spliced into `AuthorizationRequest` before `validate_with_client/3`; JAR claims projected into flat-param shape mirroring `pushed_request_to_params/1` | Likely | `lib/lockspire/protocol/jar.ex` (primitive, no policy); `lib/lockspire/protocol/authorization_request.ex:158-168, 426-466` (PAR projection precedent); `lib/lockspire/protocol/pushed_authorization_request.ex:42-71` (`/par` orchestration shape) |

### Parameter precedence and strict-mode posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Strict posture: outer params other than `client_id` and `request` rejected as `:request_object_conflict`; outer `client_id` MUST equal JAR `iss`; `request` and `request_uri` are mutually exclusive | Likely | `lib/lockspire/protocol/authorization_request.ex:393-411` (existing `:request_uri_conflict` precedent); RFC 9101 §6.1 / §10.2 explicitly permit and recommend stricter posture |

### Trust model, client-key prerequisites, and Phase 21 hardening scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inline `Client.jwks` required (no `jwks_uri` fetch in v1.4); no new per-client opt-in field; `ClientAuth.authenticate/3` runs unchanged at `/par` and JAR signature verification is independent; WR-01 (typ check), WR-02 (aud-list strictness), WR-03 (max_age ceiling) all land in Phase 22 | Likely | `lib/lockspire/domain/client.ex:30-31` (`jwks` and `jwks_uri` fields); `lib/lockspire/protocol/jar.ex:73-87` (`:invalid_client_keys` already returned for nil/non-map); `lib/lockspire/protocol/client_auth.ex:9` (`private_key_jwt` already supported — type-confusion vector real); `.planning/phases/21-jar-foundation/21-REVIEW.md` |

### Error semantics and verification proof shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New JAR failures map to RFC 9101 `error=invalid_request_object` with distinct per-failure `reason_code` atoms; redirect-safety mirrors the `par_required_request_uri` pattern; verification extends `authorization_request_test.exs` + `authorize_controller_test.exs` + `phase15_par_authorization_e2e_test.exs` (no new mega-suite) | Confident | `lib/lockspire/protocol/authorization_request.ex:49-63` (free-form `reason_code` atom); `lib/lockspire/protocol/authorization_request.ex:170-189` (existing redirect-safe classification pattern); locked v1.3 verification posture in prior CONTEXT files |

## Corrections Made

No corrections — all four assumptions confirmed.

## Auto-Resolved

Not applicable — interactive confirmation, no `--auto`.

## External Research

Not performed — codebase + RFC 9101 / 9126 / 7519 references already quoted in `21-REVIEW.md` and prior CONTEXT files were sufficient. `:jose ~> 1.11` already verified in Phase 21.

---

*Logged: 2026-04-25*
