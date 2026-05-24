# Phase 72: JARM Encryption & Metadata - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 72-jarm-encryption-and-metadata
**Areas discussed:** Encryption key source, Failure behavior, Metadata truth, Algorithm surface

---

## Encryption key source

| Option | Description | Selected |
|--------|-------------|----------|
| Support both inline `jwks` and guarded remote `jwks_uri` | Reuse Lockspire's existing client metadata and guarded fetcher so encrypted JARM follows the same client-key story as `private_key_jwt` | ✓ |
| Inline `jwks` only for Phase 72 | Avoid outbound fetch on the redirect path at the cost of a narrower and less coherent client experience | |

**User's choice:** Recommendation-heavy one-shot synthesis selected the first option.
**Notes:** Preserve xor registration semantics, keep fetch safety Lockspire-owned, and avoid a JARM-only client-key model.

---

## Failure behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Fail closed immediately | Preserve confidentiality with the simplest possible security story, but allow fewer recovery cases | |
| Degrade to signed-only JARM | Preserve availability by weakening the response contract when encryption is unavailable | |
| Bounded recovery, never downgrade confidentiality | Allow safe local/cache/guarded-refresh recovery, then fail closed if no safe key is usable | ✓ |

**User's choice:** Recommendation-heavy one-shot synthesis selected the third option.
**Notes:** No silent downgrade. External behavior should remain explicit and non-leaky.

---

## Metadata truth

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime-derived from one shared authorization-response capability source | Publish stable runtime truth based on mounted authorization surface and effective crypto posture | ✓ |
| Static hard-coded publication | Advertise maximum theoretical support from constants or compile-time lists | |
| Runtime-derived from transient readiness checks | Publish capability based on live state such as key inventory or remote JWKS reachability | |

**User's choice:** Recommendation-heavy one-shot synthesis selected the first option.
**Notes:** Discovery is a runtime contract, not a health dashboard and not a feature brochure.

---

## Algorithm surface

| Option | Description | Selected |
|--------|-------------|----------|
| `RSA-OAEP-256` only + `A256GCM` only | Extremely narrow and simple, but excludes EC recipients and some mainstream interoperability cases | |
| `RSA-OAEP-256` and `ECDH-ES` + `A256GCM` and `A128GCM` | Narrow modern asymmetric surface with GCM-only content encryption | ✓ |
| Full parity with Phase 40 request-object JWE allow-list | Broadest compatibility, including CBC modes and older algorithm baggage | |

**User's choice:** Recommendation-heavy one-shot synthesis selected the second option.
**Notes:** Keep JARM response encryption narrower than inbound request-object JWE and avoid CBC defaults.

---

## the agent's Discretion

- Exact helper/module boundaries for client encryption-key resolution and JARM capability publication
- Exact internal failure reason taxonomy and whether bounded refresh is a separate helper or flag

## Deferred Ideas

- CBC response-encryption support and full parity with the broader request-object JWE surface
- Any JARM-specific second crypto-policy plane
- Discovery capability based on transient remote-JWKS health
- Silent downgrade from encrypted JARM to signed-only JARM
