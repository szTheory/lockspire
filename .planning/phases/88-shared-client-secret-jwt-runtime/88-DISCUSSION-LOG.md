# Phase 88: Shared `client_secret_jwt` Runtime - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `88-CONTEXT.md`; this log preserves the analysis path.

**Date:** 2026-05-25
**Phase:** 88-shared-client-secret-jwt-runtime
**Mode:** assumptions
**Areas analyzed:** shared auth routing, direct-client runtime surface, assertion validation posture, algorithm and security-profile posture

## Assumptions Presented

### Shared auth routing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| JWT client assertions should stop routing implicitly to `private_key_jwt` and instead dispatch explicitly from the stored `token_endpoint_auth_method` after client lookup. | Confident | `lib/lockspire/protocol/client_auth.ex`, `.planning/ROADMAP.md` |

### Direct-client runtime surface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 88 should cover only the currently shipped Lockspire-owned direct-client endpoints: `/token`, `/revoke`, `/introspect`, `/device/code`, and `/bc-authorize`. | Likely | `docs/private-key-jwt-host-guide.md`, `test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs`, `lib/lockspire/protocol/introspection.ex`, `lib/lockspire/protocol/revocation.ex`, `lib/lockspire/protocol/device_authorization.ex`, `lib/lockspire/protocol/backchannel_authentication.ex` |
| `POST /par` should remain out of the shipped `client_secret_jwt` slice for Phase 88. | Likely | `docs/private-key-jwt-host-guide.md`, `lib/lockspire/protocol/pushed_authorization_request.ex`, `.planning/REQUIREMENTS.md` |

### Assertion validation posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `client_secret_jwt` should inherit the existing strict JWT assertion rules where they apply: issuer-string `aud`, `iss`/`sub` binding, bounded lifetime, required `jti`, replay after verified claims only, and fail-closed `invalid_client`. | Confident | `lib/lockspire/protocol/client_auth/private_key_jwt.ex`, `test/lockspire/protocol/client_auth_test.exs`, `docs/private-key-jwt-host-guide.md` |
| Telemetry and audit handling should preserve the current redaction posture for assertions and related JWT material. | Confident | `lib/lockspire/redaction.ex`, `test/lockspire/audit/event_test.exs`, `lib/lockspire/protocol/client_auth/private_key_jwt.ex` |

### Algorithm and security-profile posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The narrowest Phase 88 default is `HS256` only. | Likely | `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `lib/lockspire/protocol/security_profile.ex`, `docs/supported-surface.md` |
| `client_secret_jwt` should remain unavailable under FAPI profiles in v1.24. | Likely | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `lib/lockspire/protocol/security_profile.ex`, `docs/supported-surface.md` |

## Corrections Made

- User confirmed the recommendation bundle without changes by replying `proceed`.

## Outcome

- Assumptions were accepted as locked Phase 88 decisions.
- Context was written to `.planning/phases/88-shared-client-secret-jwt-runtime/88-CONTEXT.md`.
