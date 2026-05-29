---
phase: 101-adoption-demo-re-wire
plan: "02"
subsystem: auth
tags: [jwt, oauth, resource-indicators, phoenix, smoke-test, audience, at+jwt]

# Dependency graph
requires:
  - phase: 101-01
    provides: Canonical block audience value https://billing.acme-ledger.test baked into all four RECIPE-01 sites
  - phase: 99-signer-extraction-jwt-default-issuance
    provides: Server-default :jwt issuance — acme-ledger-public inherits at+jwt without explicit config
  - phase: 100-sender-constraint-end-to-end-proof
    provides: VerifyToken audience exact-match and bearer path through EnforceSenderConstraints
provides:
  - Auth-code -> at+jwt -> /api/billing/summary -> HTTP 200 round-trip assertion in CI smoke
  - resource= on both /authorize and /token requests binding the token aud to https://billing.acme-ledger.test
  - Preserved anonymous-401 and /userinfo stored-opaque assertions
  - Module-level BILLING_RESOURCE constant preventing runtime literal drift from block URI (D-04)
affects: [102-generated-host-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single module-level constant BILLING_RESOURCE referenced in both runtime resource= sites — prevents literal drift from block URI"
    - "resource= on /authorize AND /token requests — RFC 8707 Resource Indicators; both required for aud binding in issued at+jwt"
    - "assert_status(..., 200, 'protected API accepts issued at+jwt') — distinct label positively sampled by CI, fails loudly on regression"

key-files:
  created: []
  modified:
    - scripts/demo/adoption_smoke.py

key-decisions:
  - "D-04 honored: BILLING_RESOURCE = 'https://billing.acme-ledger.test' at module level — runtime literal equals block URI byte-for-byte"
  - "D-02 honored: resource=BILLING_RESOURCE added to both authorize_params and /token POST body"
  - "D-07 honored: mandatory GET /api/billing/summary with Bearer at+jwt asserting HTTP 200 under distinct label 'protected API accepts issued at+jwt'"
  - "Optional audience-echo assertion included (Claude's discretion, CONTEXT.md:50): BILLING_RESOURCE in authed_api_json['access_token']['audience']"
  - "Existing anonymous-401 and /userinfo assertions preserved unchanged"

requirements-completed: [DEMO-01, DEMO-02]

# Metrics
duration: 5min
completed: 2026-05-28
---

# Phase 101 Plan 02: Auth-Code Resource Binding and 200-with-Token Assertion Summary

**Wired resource=https://billing.acme-ledger.test into both the /authorize and /token requests via a single module-level constant, and added the mandatory GET /api/billing/summary Bearer-token round-trip asserting HTTP 200 — closing the half-proof gap and satisfying DEMO-01 and DEMO-02**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-28T20:35:00Z
- **Completed:** 2026-05-28T20:40:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `BILLING_RESOURCE = "https://billing.acme-ledger.test"` at module level in `scripts/demo/adoption_smoke.py` — single constant referenced in both runtime sites so the value cannot drift from the canonical block URI (D-04)
- Added `"resource": BILLING_RESOURCE` to `authorize_params` dict so the GET /lockspire/authorize request carries the Resource Indicator (D-02)
- Added `"resource": BILLING_RESOURCE` to the POST /lockspire/token body params so the token request echoes the code-request resource, binding the issued at+jwt aud list to the URI (D-02)
- Added mandatory `GET /api/billing/summary` with `Authorization: Bearer <token_json["access_token"]>` asserting `HTTP 200` under the distinct label `"protected API accepts issued at+jwt"` (D-07, DEMO-01, DEMO-02)
- Added optional audience-echo assertion: `assert BILLING_RESOURCE in authed_api_json["access_token"]["audience"]` as additional evidence (Claude's discretion per CONTEXT.md:50)
- Preserved the existing anonymous-401 assertion (`"protected API rejects anonymous request"`) and the existing /userinfo stored-opaque assertion (`"userinfo accepts issued access token"` + email check) unchanged
- The commented `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` block is untouched (Plan 01 owns it)
- All automated verify checks pass: py_compile, resource= grep, assert_status grep, 200-label grep, Bearer expression grep, /api/billing/summary path grep, 401-label grep, userinfo-label grep

## Task Commits

1. **Task 1: Thread resource= into auth-code flow and add mandatory 200 assertion** - `8902684` (feat)

## Files Created/Modified

- `scripts/demo/adoption_smoke.py` — module-level `BILLING_RESOURCE` constant added (line 15); `"resource": BILLING_RESOURCE` added to `authorize_params` dict (line 188) and /token body params (line 230); mandatory 200 assertion block added after the anonymous-401 assertion (lines 259-266, including optional audience-echo)

## Decisions Made

- Module-level constant pattern chosen over inline string literals to make drift between the two runtime sites structurally impossible (D-04)
- Optional audience-echo assertion included: encouraged by CONTEXT.md and straightforward given `authed_api_json` is already in scope; absence would not have failed the task
- New authed_api assertion placed after the existing anonymous-401 assertion, maintaining narrative flow: anonymous rejected first, then authorized accepted

## Deviations from Plan

None - plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The smoke script is a test client only.

## Self-Check

- [x] `scripts/demo/adoption_smoke.py` exists and contains all required changes
- [x] Commit `8902684` exists in git log
- [x] `python3 -m py_compile scripts/demo/adoption_smoke.py` exits 0
- [x] `BILLING_RESOURCE = "https://billing.acme-ledger.test"` at module level, referenced at lines 188, 230, 266
- [x] `"protected API accepts issued at+jwt"` label present
- [x] `"protected API rejects anonymous request"` label preserved
- [x] `"userinfo accepts issued access token"` label preserved
- [x] BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE block untouched

## Self-Check: PASSED

---
*Phase: 101-adoption-demo-re-wire*
*Completed: 2026-05-28*
