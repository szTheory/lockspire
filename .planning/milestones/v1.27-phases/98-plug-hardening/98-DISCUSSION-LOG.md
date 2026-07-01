# Phase 98: Plug Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 98-plug-hardening
**Mode:** assumptions
**Areas analyzed:** Opaque-token rejection (VERIFIER-01); RFC 9068 claim/header enforcement (VERIFIER-02/03/04); WWW-Authenticate scheme derivation (VERIFIER-05); `audience:` enforcement shape (VERIFIER-06)

## Assumptions Presented

### Area A — Opaque-Token Rejection Mechanism (VERIFIER-01)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Detect opaque tokens by structural shape at front of `verify_token/3` (three non-empty Base64URL segments split by `.`), classify as `:opaque_token_not_accepted`, short-circuit to structured invalid-token error with the required `WWW-Authenticate: Bearer error="invalid_token", error_description="opaque tokens not accepted on this route"` shape. Sits in front of current silent `:malformed` rescue path. | Confident | `verify_token.ex:325-335` (silent `:malformed` rescue path); `verify_token_test.exs:323-333` (existing `reason=malformed` assertion); `protocol/token_formatter.ex:29-33` (opaque shape = 32 bytes Base64URL, no dots) |

### Area B — RFC 9068 Claim/Header Enforcement (VERIFIER-02, 03, 04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `validate_rfc9068_compliance/2` after `JOSE.JWT.verify_strict/3` and before `apply_restrictions/2`. Five ordered checks: `typ`, `iss`, `exp`, `iat`, `sub`. Each emits a distinct `reason_code` flowing through the structured error map shape. | Confident | `verify_token.ex:39-51, 184-204, 253-261, 344-358, 360-377` (line 366 comment "Missing exp is currently treated as valid" — explicit acknowledgment of the VERIFIER-04 gap); `require_token.ex:48-77` (already handles structured-map error path); `config.ex:49-59` (`issuer!/0`); `rfc8693_exchange.ex:317-361` (current `at+jwt`-signing site, claim shape baseline) |
| `typ` comparison is case-insensitive on the header value, normalized by lowercasing and stripping any `application/` prefix; accept `at+jwt`, `application/at+jwt`, `AT+JWT`; reject `JWT`, missing. Intentionally more permissive than issuance-side `dpop.ex:168` and `rfc8693_exchange.ex:343` exact-match. | Likely | RFC 8725 §3.11 and RFC 9068 §2.1 both permit the `application/` prefix; verifier-permissive-than-signer guards against Phase 99 signer-extraction evolution |

### Area C — WWW-Authenticate Scheme Derivation (VERIFIER-05)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Derive `challenge:` on every VerifyToken-produced error map from token's binding claim via existing `binding_type/1` helper, with request's auth scheme as tiebreaker for no-binding case. Mapping: `cnf.jkt` → `:dpop`; only `cnf["x5t#S256"]` → `:bearer` (RFC 8705 §3 mTLS reuses Bearer); no `cnf` + DPoP scheme → `:dpop`; else `:bearer`. Replaces hardcoded `challenge: :bearer` at `verify_token.ex:187, 198` and implicit `:bearer` defaults in `require_token.ex:81, 99, 113`. | Confident | `verify_token.ex:187, 198, 288-300` (hardcoded `:bearer` and `binding_type/1` helper that already exists); `enforce_sender_constraints.ex:58, 130-149` (gate on `access_token.error` proves VerifyToken-side derivation is necessary; existing `sender_error(:dpop, ...)` taxonomy to match); `web/protected_resource_challenge.ex:37-44, 57-70` (downstream emission already correct); RFC 9449 §7.1 + RFC 8705 §3 |

### Area D — `audience:` Enforcement Shape (VERIFIER-06)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Close VERIFIER-06's OR-clause with **both** mechanisms: add `enforce_audience: true \| false` to `VerifyToken.init/1` (default false for back-compat) raising `ArgumentError` when true and no `:audience`/`:audiences`; AND add a `release_readiness_contract_test` clause asserting every RECIPE-01 canonical-pipeline file carries `audience:` substring via the existing `extract_canonical_pipeline!/2` helper. Install template keeps `enforce_audience: true`. | Likely | `verify_token.ex:42-44` (existing `NimbleOptions` + `ArgumentError` raise pattern on `:audience`/`:audiences` mutual exclusion); `release_readiness_contract_test.exs:140-214, 745-759` (Phase 97 four-file extraction + hash-compare machinery — D-07 extends with audience-substring clause); `examples/adoption_demo/lib/adoption_demo_web/router.ex:25`, `scripts/demo/adoption_smoke.py:246`, `docs/protect-phoenix-api-routes.md:18`, `priv/templates/lockspire.install/router.ex:13` (all four already carry `audience: "billing-api"` per Phase 97 D-13); `verify_token_test.exs:111-114` (existing no-audience mounts that default-false protects) |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

None performed. The codebase analyzer flagged no blocking research gaps. One optional confirmation (RFC 9449 §7.1 tiebreaker wording for the "no `cnf` + DPoP scheme" edge case) is captured in `<deferred>` for the planner if belt-and-suspenders is wanted.

## Methodology Application

- **Assumption-First Recommendation Mode** fired across all four areas — every recommendation reused existing primitives (`binding_type/1`, `NimbleOptions` + raise pattern, structured error map, extract helpers) so no area required external research to form a decisive recommendation.
- **Least-Surprise Host Seam** fired in Areas A, B, C — durable protocol state (RFC 9068 conformance) moved from implicit/silent to explicit/distinct; D-05 composes with EnforceSenderConstraints' existing `challenge:` taxonomy rather than introducing a parallel one.
- **Research-First Decisive Defaults** fired in Areas B and C — RFC 9068 §4, RFC 8725 §3.11, RFC 9449 §7.1 each leave essentially zero design space; recommendations are decisive single-shot, not menus.
- **One-Shot Recommendation Bundles** fired in Areas B and D — Area B bundles five claim/header checks into one validation step with one reason_code taxonomy extension; Area D bundles option + install-template default + contract-test backstop into one cohesive shape.
- **High-Threshold Escalation** fired in Area D only — VERIFIER-06's literal OR-clause is the requirement's own signal that this is an in-workflow choice. No area triggered product-boundary escalation; Phase 98 is pure hardening of a shipped plug surface.
