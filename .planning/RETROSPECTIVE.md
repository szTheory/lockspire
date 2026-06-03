# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.27 — Phoenix Resource Server Token Acceptance

**Shipped:** 2026-06-03
**Phases:** 6 | **Plans:** 24 | **Sessions:** ~6

### What Was Built
- `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt` only, with strict `typ`, `iss`, and required claims validation.
- One shared `AccessTokenSigner` now owns RFC 9068 `at+jwt` issuance across all grant paths.
- Default access-token issuance format flipped from opaque to `:jwt` for AC, refresh, device, and CIBA paths, with a runtime-settable server default and nullable per-client override.
- End-to-end sender-constraint proof (DPoP and mTLS) delivered across the canonical pipeline, closing misordered-pipeline bypasses.
- The adoption demo is re-wired to use the blessed `at+jwt` path against the protected route.
- Generated-host scaffolding, operator telemetry, and migration diagnostics all shipped to reflect the new default issuance.

### What Worked
- **Contract-First Development:** Writing the canonical doc block (Phase 97) before writing code anchored the entire implementation on a known target, making subsequent phases predictable.
- **Wave-based execution in Phase 102:** Handling telemetry/scaffolding guards before writing the migration doc correctly unblocked dependent work safely.

### What Was Inefficient
- 9 stale test fixtures were invalidated by the plug hardening, leading to red tests at the end of the milestone that needed manual cleanup via `AccessTokenSigner.issue/3` and key seeding.
- `release_readiness_contract_test` assertions had to be run and fixed multiple times due to slight whitespace or block structure mismatches across the four carrier sites.

### Patterns Established
- **Single Signer Ownership:** `AccessTokenSigner` now handles token format resolution, `aud` derivation, and `cnf` carry-through in one place instead of scattered across grant paths.
- **Strict Verification:** `VerifyToken` acts as a hard gate for RFC 9068 adherence, explicitly rejecting opaque tokens with a helpful challenge rather than failing silently.

### Key Lessons
1. **Docs as a Contract:** Hash-pinning the pipeline declaration block across docs, demo, install template, and smoke tests guarantees the shipped code acts as advertised.
2. **Explicit is Better than Implicit:** Instead of auto-detecting token shapes inside the plug (which leads to security footguns), Lockspire forces the `at+jwt` shape for the host API and opaque for its own endpoints.

### Cost Observations
- Model mix: 100% gemini-2.5-pro
- Notable: TDD and executable testing caught contract drift early.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.27 | ~6 | 6 | Hash-pinned canonical docs as an executable contract before code. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.27 | N/A | High | Contract tests |

### Top Lessons (Verified Across Milestones)

1. **Executable Documentation:** Pinning docs to tests prevents setup guides from drifting from the runtime implementation.
2. **End-to-End Proof:** Smoke tests and generated-host tests are the ultimate arbitrator of feature completion.