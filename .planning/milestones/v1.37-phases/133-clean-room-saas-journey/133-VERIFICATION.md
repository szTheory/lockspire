---
phase: 133-clean-room-saas-journey
verified: 2026-08-28T04:41:30Z
milestone_reverified: 2026-08-28T04:41:30Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/5
  gaps_closed:
    - "Refresh rotation, reuse-triggered family revocation, authenticated introspection, and revocation work with truthful JWT lifetime semantics."
  gaps_remaining: []
  regressions: []
---

# Phase 133: Clean-Room SaaS Journey Verification Report

**Phase Goal:** A separate-origin SaaS client can safely consume an embedded Lockspire provider and protected API from the built package.
**Verified:** 2026-08-28T04:41:30Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A clean Phoenix/Ecto host installs packaged Lockspire, applies only documented host-owned edits, migrates, verifies, tests, and boots without internal modules or replacement routes. | ✓ VERIFIED | The maintained command rebuilt both clean-room children, emitted provider/client provenance and readiness receipts, and completed teardown. `prepare_provider` uses the public package install/verify surface and boundary-audits host seams. |
| 2 | A separate-origin confidential client persists random state, nonce, and PKCE material, completes authorization, and rejects callback state mismatches. | ✓ VERIFIED | The run completed authorization/callback then emitted `callback state rejected before exchange`. `OAuthTransaction` persists random state/nonce/verifier/challenge and `Transactions.consume/2` is an atomic pending-to-consumed transition. |
| 3 | The client validates discovery, JWKS, ID-token signature and claims, and userinfo subject before calling an audience-and-scope-protected API. | ✓ VERIFIED | The run emitted `discovery complete`, `oidc complete`, `userinfo complete`, and `resource complete` in order. `OIDCVerifier` validates discovery, signature, issuer, audience, expiry, nonce, and subject. |
| 4 | Refresh rotation, reuse-triggered family revocation, authenticated introspection, and revocation work with truthful JWT lifetime semantics. | ✓ VERIFIED | `9368cde` resolves the lifecycle resource at dynamic-origin runtime. Fresh execution emitted rotation, reuse-containment, inactive-introspection, and idempotent-revocation receipts without claiming instant offline JWT invalidation. |
| 5 | The journey rejects documented redirect, code, token, audience, scope, nonce, and DPoP replay failures without retaining or logging secrets or tokens. | ✓ VERIFIED | Fresh execution emitted every named negative, DPoP nonce/replay receipt, `dpop provider restart ready`, and exact-proof rejection after restart, followed by `evidence scan complete`. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Plans 01–06 declared artifacts | Package provenance, two fixtures, transaction/OIDC/DPoP code, runner, tests, alias, and CI script | ✓ VERIFIED | `verify.artifacts` reports all 20 declared artifacts present and substantive. |
| `scripts/acceptance/clean_room_saas_journey.py` | Real-listener lifecycle/negative/DPoP orchestration | ✓ VERIFIED | Current maintained execution passed every group. |
| `test/integration/phase133_clean_room_saas_journey_test.exs` | Acceptance wrapper | ✓ VERIFIED | Deliberately skipped in normal suites to avoid duplicated expense; the maintained Mix alias is the CI executable proof. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Provider builder | packaged `lockspire.install` | fresh child public install/verify and provenance audit | ✓ WIRED | Runtime reached provenance and readiness. |
| OAuth controller | durable transactions | atomic `consume/2` before token exchange | ✓ WIRED | State mismatch receipt proves the terminal pre-exchange path. |
| OIDC verifier | discovery/JWKS | metadata/key fetch and strict claims | ✓ WIRED | Happy execution reached discovery/OIDC/userinfo/resource in order. |
| Client DPoP session | provider protected API | opaque encrypted session and exact proof replay | ✓ WIRED | The focused run proved token/userinfo/resource nonce paths; after restart a newly signed proof established protected-resource readiness, then the original stored proof was rejected. |
| CI integration lane | `mix test.clean-room.e2e` | one direct maintained command | ✓ WIRED | `mix.exs`, CI, and matrix script invoke the same passing alias. |

### Data-Flow Trace (Level 4)

No dynamic UI artifact is in scope. The executed server-side flow is browser redirects → durable client transaction → discovery/JWKS/ID-token/userinfo validation → host protected API; DPoP keeps key/token/nonce/proof material in its opaque server-side session. Both bearer and DPoP branches ran successfully.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused post-restart DPoP proof | `python3 scripts/acceptance/clean_room_saas_journey.py --only dpop` | Exit 0; DPoP token/userinfo/resource nonce flow, initial exact replay rejection, `dpop provider restart ready`, post-restart exact replay rejection, evidence scan, and cleanup emitted. | ✓ PASS |
| Full package-clean SaaS journey | `mix test.clean-room.e2e` | Exit 0; all happy, boundary, lifecycle, negative, CSRF, DPoP nonce/replay/restart, evidence-scan, and cleanup markers emitted. | ✓ PASS |
| Real-run origin isolation | `python3 scripts/acceptance/clean_room_saas_journey.py --verify-concurrent-origins` | Exit 0: `concurrent real journeys complete`. | ✓ PASS |
| Signal-safe teardown | `python3 scripts/acceptance/clean_room_saas_journey.py --verify-signal-cleanup` | Exit 0: `signal cleanup complete`. | ✓ PASS |

### Probe Execution

No `probe-*.sh` artifact is declared. The maintained Mix alias is the executable phase probe and passed above.

### Requirements Coverage

| Requirement | Source plan | Status | Evidence |
| --- | --- | --- | --- |
| E2E-01 | 01, 02, 06 | ✓ SATISFIED | Package-clean public installer/verify/boot, provenance/readiness, concurrent and signal-cleanup probes. |
| E2E-02 | 03, 04 | ✓ SATISFIED | Separate origins, durable PKCE transaction, completed callback, and pre-exchange state rejection. |
| E2E-03 | 03, 04 | ✓ SATISFIED | Executed discovery/JWKS/ID-token/userinfo/resource validation chain. |
| E2E-04 | 05 | ✓ SATISFIED | Executed rotation, reuse containment, inactive introspection, and idempotent revocation. |
| E2E-05 | 05, 06 | ✓ SATISFIED | Executed redirect/code/state/nonce/token/audience/scope rejections. |
| E2E-06 | 01, 06 | ✓ SATISFIED | Executed DPoP nonce retries, replay and durable post-restart rejection, redaction scan, and teardown. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| Phase 133 implementation set | — | No unreferenced `TBD`, `FIXME`, `XXX`, `HACK`, or placeholder markers found in scanned phase files. | ℹ️ Info | No debt-marker blocker. |

### Gaps Summary

None. The previous blocker was a Python default argument binding the stale fixed-port resource URI before dynamic origins were allocated. It is resolved at journey runtime. The post-restart readiness probe accepts only a new proof to establish the protected-resource pipeline is live; the runner then retains the original exact proof and separately requires its rejection. Current execution covers all six E2E requirements.

_Verified: 2026-08-28T04:41:30Z after canonical CI and milestone integration audit_
_Verifier: the agent (gsd-verifier)_
