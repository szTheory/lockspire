---
phase: 101-adoption-demo-re-wire
verified: 2026-05-28T20:55:00Z
status: passed
score: 3/3 must-haves verified
overrides_applied: 0
runtime_verification:
  - test: "Adoption demo smoke executed locally against the seeded demo app (Postgres + `mix phx.server` on port 4100), per the CI 'Adoption Demo Smoke' recipe."
    result: "PASSED — `python3 scripts/demo/adoption_smoke.py` printed 'adoption demo smoke passed' and exited 0 on 2026-05-28. The GET /api/billing/summary Bearer-token step returned HTTP 200 ('protected API accepts issued at+jwt'); anonymous request returned 401; /userinfo returned 200. End-to-end auth-code -> at+jwt -> /api/billing/summary -> 200 round-trip confirmed at runtime."
---

# Phase 101: Adoption-Demo Re-Wire Verification Report

**Phase Goal:** The adoption demo executes an end-to-end auth-code → at+jwt → host-owned protected route (/api/billing/summary) → HTTP 200 round-trip in CI, replacing the current "401-on-anonymous" half-proof with executable adopter-facing evidence that the blessed path works. The preserved /userinfo stored-opaque assertion stays.
**Verified:** 2026-05-28T20:55:00Z
**Status:** passed
**Re-verification:** No — initial verification (runtime smoke executed locally to close the sole human-needed item)

## Goal Achievement

### Observable Truths

Merged from ROADMAP Success Criteria (3) + PLAN frontmatter truths (deduplicated).

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | (SC-1) Smoke completes auth-code flow, obtains at+jwt, calls /api/billing/summary with the token, asserts HTTP 200, alongside preserved /userinfo assertion | ✓ VERIFIED (static + runtime) | `scripts/demo/adoption_smoke.py:259-264` issues GET /api/billing/summary with `Authorization: Bearer <token_json["access_token"]>` and `assert_status(..., 200, "protected API accepts issued at+jwt")`. /userinfo 200 + email check preserved at lines 238-245. main() at 326-331 invokes exercise_authorization_code(). **Runtime confirmed:** smoke executed locally against the seeded demo (Postgres + `mix phx.server`) on 2026-05-28 → printed `adoption demo smoke passed`, exit 0; /api/billing/summary returned HTTP 200, anonymous 401 + /userinfo 200 preserved. |
| 2 | (SC-2 / DEMO-02) CI Adoption Demo Smoke job fails loudly if either round-trip regresses; smoke no longer satisfied by anonymous-401 alone | ✓ VERIFIED | `.github/workflows/ci.yml:181-266` defines the `adoption-demo` / "Adoption Demo Smoke" job: boots `mix phx.server`, runs `python3 scripts/demo/adoption_smoke.py`, captures `smoke_status=$?`, and `exit "$smoke_status"` on non-zero with log dump. The mandatory `assert_status(..., 200, ...)` (smoke:264) raises (non-zero exit) on any non-200. Anonymous-401 preserved at smoke:256-257 but no longer sole proof. |
| 3 | (SC-3 / DEMO-03) Demo `:lockspire_protected_api` pipeline declares explicit `audience:` matching the `resource=` URI used in the token request | ✓ VERIFIED | Demo router `examples/adoption_demo/lib/adoption_demo_web/router.ex:25` declares `audience: "https://billing.acme-ledger.test"`; pipeline piped onto `/billing/summary` at lines 67-69. Runtime `resource=` literal (`BILLING_RESOURCE`, smoke:15) byte-identical to the audience URI (D-04 match confirmed). |
| 4 | (Plan02) resource= sent on BOTH /authorize and /token | ✓ VERIFIED | `smoke:188` (authorize_params) and `smoke:230` (/token body) both add `"resource": BILLING_RESOURCE`. |
| 5 | (Plan02) anonymous GET /api/billing/summary → 401 assertion preserved | ✓ VERIFIED | `smoke:256-257` `assert_status(anonymous_api, 401, "protected API rejects anonymous request")`. |
| 6 | (Plan02) /userinfo stored-opaque 200 + alice@acme.test check preserved unchanged | ✓ VERIFIED | `smoke:238-245`, unchanged. |
| 7 | (Plan01/DEMO-03) Canonical block declares absolute-URI audience in all four RECIPE-01 sites; `billing-api` gone; hash lock intact | ✓ VERIFIED | All four sites carry `audience: "https://billing.acme-ledger.test"` (doc:18+42, router:25, install-template:13, smoke:249); zero stale `billing-api` in the four files; `release_readiness_contract_test` passes 31/0. |

**Score:** 3/3 roadmap success criteria verified (all supporting plan truths VERIFIED). Runtime HTTP 200 outcome of SC-1 routed to human/CI confirmation.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `scripts/demo/adoption_smoke.py` | Auth-code → at+jwt → /api/billing/summary → 200 round-trip + preserved 401/userinfo | ✓ VERIFIED | py_compile + AST parse clean; resource= threaded on both requests; mandatory 200 step + audience-echo present; 401/userinfo preserved. |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | Canonical block with absolute-URI audience (site 2), pipeline wired to route | ✓ VERIFIED | Line 25 absolute URI; pipeline piped to /billing/summary (67-69). |
| `priv/templates/lockspire.install/router.ex` | Canonical block, `#`-commented, absolute-URI audience (site 3) | ✓ VERIFIED | Line 13, `#`-prefixed form preserved. |
| `docs/protect-phoenix-api-routes.md` | Canonical block (site 1) + aligned prose example | ✓ VERIFIED | Block line 18 + prose line 42, both absolute URI; no `billing-api` remaining. |
| `test/support/generated_host_app_web/router/lockspire.ex` | Install-generator golden fixture (5th block copy) synced to absolute URI | ✓ VERIFIED | Line 17 absolute URI inside BEGIN/END markers (commit `bc0ace9`, surfaced by regression gate). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Four RECIPE-01 canonical blocks | release_readiness_contract_test normalized SHA-256 | byte-identical audience edit | ✓ WIRED | `mix test test/lockspire/release_readiness_contract_test.exs` → 31 tests, 0 failures (byte-identical + non-empty-audience clauses green). |
| smoke /authorize + /token resource= | minted at+jwt aud claim | resource= == block audience URI (D-04) | ✓ WIRED | `BILLING_RESOURCE` (smoke:15) byte-identical to router audience (D-04 string equality confirmed); referenced at smoke:188 + 230. |
| smoke GET /api/billing/summary | VerifyToken audience exact-match | Authorization: Bearer <access_token> asserting 200 | ✓ WIRED (static) | smoke:259-264; runtime exact-match → 200 confirmed by CI/human. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| smoke audience-echo assertion (line 266) | `authed_api_json["access_token"]["audience"]` | demo `api_controller.billing_summary/2` reads `conn.assigns.access_token.claims["aud"]` (api_controller.ex:15) | Yes — sourced from real verified token claims, not hardcoded | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Smoke byte-compiles | `python3 -m py_compile scripts/demo/adoption_smoke.py` | exit 0 | ✓ PASS |
| Smoke parses (AST) | `python3 -c "ast.parse(...)"` | AST parse OK | ✓ PASS |
| Distinct 200 label present exactly once | grep | 1 | ✓ PASS |
| Anonymous-401 + /userinfo labels present | grep | 1 + 1 | ✓ PASS |
| resource= on both requests | grep `"resource": BILLING_RESOURCE` | 2 | ✓ PASS |
| Contract hash lock intact | `mix test test/lockspire/release_readiness_contract_test.exs` | 31 tests, 0 failures | ✓ PASS |
| End-to-end runtime HTTP 200 | boot server + run smoke | requires server boot | ? SKIP → human/CI |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes declared by this phase. The phase's runtime proof is the CI `Adoption Demo Smoke` job (server-dependent), routed to human/CI verification rather than treated as a local probe.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| DEMO-01 | 101-02 | Demo runs auth-code → at+jwt → host-owned protected route → HTTP 200; /userinfo stays | ✓ SATISFIED (runtime 200 → CI/human) | smoke:188/230/259-264; /userinfo preserved 238-245 |
| DEMO-02 | 101-02 | Smoke adds 200-with-issued-token assertion; 401-on-anonymous no longer sole proof | ✓ SATISFIED | smoke:264 distinct label; anonymous-401 preserved 256-257; CI fails loudly (ci.yml:251-266) |
| DEMO-03 | 101-01 | Demo router declares explicit `audience:` matching the resource URI | ✓ SATISFIED | router.ex:25; D-04 byte-match; contract test green |

All declared requirement IDs (DEMO-01, DEMO-02, DEMO-03) accounted for and mapped to Phase 101 in REQUIREMENTS.md (lines 50-52, 138-140, 161). No orphaned requirements — REQUIREMENTS.md maps exactly these three IDs to Phase 101, all claimed by plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none in phase-101-modified files) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER | — | Clean |
| `test/support/generated_host_app_web/router.ex` | 20 | `audience: "billing-api"` (bare string) | ℹ️ Info | Pre-existing Phase 81 e2e test fixture (last touched 2026-05-25, commit `eaa1eb8`, NOT in Phase 101 diff). Not a RECIPE-01 hash-locked site and not the install-generator golden output (that fixture, `router/lockspire.ex`, was correctly synced). Out of scope for Phase 101. |
| `docs/protect-phoenix-api-routes.md` | 3 | (CR-02 from 101-REVIEW.md) stored-opaque "not interchangeable" doc claim | ℹ️ Info | Flagged outside phase 101 diff per verification guidance; recommended follow-up, not a phase-101 failure. |

### Human Verification Required

#### 1. End-to-end adoption demo smoke round-trip

**Test:** Boot the seeded demo app (`cd examples/adoption_demo && mix phx.server`) and run `python3 scripts/demo/adoption_smoke.py`, or rely on the CI `Adoption Demo Smoke` job (`.github/workflows/ci.yml` `adoption-demo`).
**Expected:** Smoke prints `adoption demo smoke passed`; the new `GET /api/billing/summary` Bearer step returns HTTP 200 (label `protected API accepts issued at+jwt`); anonymous request still 401; `/userinfo` still 200 with `alice@acme.test`.
**Why human:** The auth-code → at+jwt → /api/billing/summary → 200 round-trip requires a live Phoenix server + Postgres. All static wiring is VERIFIED in code; only the runtime 200 outcome needs execution to confirm.

### Gaps Summary

No blocking gaps. All three ROADMAP success criteria and all three requirement IDs (DEMO-01/02/03) are satisfied in the codebase:

- The four-file RECIPE-01 hash lock survives the audience edit (`release_readiness_contract_test`: 31 tests, 0 failures), and a 5th block copy (install-generator golden fixture) was correctly synced (`bc0ace9`).
- The smoke threads `resource=https://billing.acme-ledger.test` (via the single `BILLING_RESOURCE` constant, byte-identical to the router audience — D-04) onto both /authorize and /token, and adds the mandatory `assert_status(..., 200, "protected API accepts issued at+jwt")` step while preserving the anonymous-401 and /userinfo assertions.
- The CI `Adoption Demo Smoke` job exits non-zero (with log dump) on any regression.

Status is `human_needed` (not `passed`) solely because the actual runtime HTTP 200 outcome — the literal round-trip — can only be observed by executing the smoke against a booted server (CI's job), which is outside static verification. Every locally-verifiable signal passed.

Two informational follow-ups (neither blocks Phase 101): (a) the pre-existing Phase 81 fixture `test/support/generated_host_app_web/router.ex:20` still carries the bare `audience: "billing-api"` — outside this phase's diff and not a canonical/hash-locked block; (b) CR-02 doc claim on `docs/protect-phoenix-api-routes.md:3`, also outside this phase's diff.

---

_Verified: 2026-05-28T20:55:00Z_
_Verifier: Claude (gsd-verifier)_
