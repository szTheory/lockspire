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

## Milestone: v1.29 — Admin UI Journey & Design-System Deep Polish

**Shipped:** 2026-06-04
**Phases:** 4 | **Plans:** 17

### What Was Built
- Route-by-route journey contracts now map the admin UI to Orient, Configure, Support, and Operate with shared vocabulary across docs and LiveView surfaces.
- Shared BEM/design-token primitives now cover repeated admin heroes, metrics, filters, rows, copy-once secrets, long values, status treatment, focus, and reduced-motion behavior.
- Support, operations, DCR/IAT, key, and client-detail weak spots now have clearer scan paths, safer risky actions, mobile-safe long values, and stronger redaction boundaries.
- Demo seeds, operator docs, screenshot inventory, browser evidence, and contract tests now pin the polished admin route surface, including 390px mobile no-page-overflow proof.

### What Worked
- Starting with the Phase 107 journey contract kept the later component and page polish grounded in operator jobs instead of page-by-page decoration.
- Contract tests were effective at holding the BEM/design-token boundary while allowing localized CSS/component improvements.
- Browser and screenshot evidence exposed mobile overflow issues that static source checks would have missed.

### What Was Inefficient
- Some proof artifacts validated screenshot inventory rows and proof cells before checking referenced screenshot files directly.
- Browser evidence covered route groups after entering through overview, but not every detail and workflow route through a strict scripted click path.
- Quick-task closeout needed a legacy-compatible `SUMMARY.md` because the installed `gsd-sdk` audit scanner lagged the local scanner behavior.

### Patterns Established
- Use the route journey contract as the source of truth for page titles, docs vocabulary, screenshot inventory, and contract tests.
- Keep admin UI polish inside reusable Phoenix components plus `lockspire-admin-*` tokens before adding any one-off route CSS.
- Treat long identifiers, URLs, timestamps, and copy-once secrets as first-class responsive primitives, not incidental table content.

### Key Lessons
1. A second-pass UI milestone can be valuable when it has a contract-first route model and explicit weak-spot target list.
2. Admin UI proof should combine source contracts, route inventory, screenshots, browser checks, and mobile overflow checks; none of those alone is enough.
3. Milestone-close tooling needs compatibility artifacts when installed and local GSD scanners disagree.

### Cost Observations
- Model mix: not recorded.
- Notable: The final audit passed functionally, but retained Nyquist partial warnings because validation matrices still had pending rows despite `nyquist_compliant: true` frontmatter.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.29 | N/A | 4 | Route journey contract became the admin UI source of truth across docs, tests, screenshots, and page polish. |
| v1.27 | ~6 | 6 | Hash-pinned canonical docs as an executable contract before code. |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.29 | Admin LiveView/design-system/browser/screenshot proof | High | BEM/design-token contract tests |
| v1.27 | N/A | High | Contract tests |

### Top Lessons (Verified Across Milestones)

1. **Executable Documentation:** Pinning docs to tests prevents setup guides from drifting from the runtime implementation.
2. **End-to-End Proof:** Smoke tests and generated-host tests are the ultimate arbitrator of feature completion.
3. **Route Contracts for Operator UI:** UI polish scales better when every route has an explicit job, risk state, empty state, and follow-up route before component work starts.
