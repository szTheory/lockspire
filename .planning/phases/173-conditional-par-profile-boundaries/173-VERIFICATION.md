---
phase: 173-conditional-par-profile-boundaries
verified: 2026-10-24T23:53:28Z
status: passed
score: 6/6 behavioral truths verified
covered_files:
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-PLAN.md
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md
  - lib/lockspire/protocol/authorization_request.ex
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
covered_digest: "v3:sha256:e92957ff84436999ff706650cc3db0fd46bf094c979411f7c9f0d6dc85338203"
behavior_unverified: 0
overrides_applied: 0
flagged_prohibitions:
  count: 2
  items:
    - statement: "MUST NOT reattribute frozen qualification observations, accepted-main evidence, or unavailable external profiles as Phase 173 current-source, packaged-host, transport, or certification proof."
      verification: judgment
      verdict: "Scoped ledger review found no reattribution in this Phase 173 change; non-authoritative."
      flag: "unverified-prohibition — human review recommended"
    - statement: "MUST NOT move host-owned account, session, login, consent presentation, claims, or product policy into Lockspire as a consequence of the PAR authority correction."
      verification: judgment
      verdict: "Scoped source and handoff review found no ownership movement in this Phase 173 change; non-authoritative."
      flag: "unverified-prohibition — human review recommended"
decision_coverage:
  honored: 9
  total: 9
  not_honored: []
---

# Phase 173: Conditional PAR & Profile Boundaries Verification Report

**Phase Goal:** Correct only P171-005's reproduced rejection of a conflicting outer scope for a valid pushed request; carry existing PAR lifecycle, required-PAR and issuer-metadata proof forward.
**Verified:** 2026-10-24T23:53:28Z
**Status:** passed — 6/6 behavioral truths verified; 2 judgment-tier prohibitions flagged for human review
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A valid P171-005 pushed request reaches exact relative consent with stored openid/email scopes, state, nonce and client despite outer scope=profile. | ✓ VERIFIED | The tagged Phase 15 Router regression passed (4 tests, 0 failures); it first proves an independent reference-only control, then asserts the distinct candidate's persisted interaction projection. |
| 2 | The same durable regression records normative RED at the qualified source and GREEN after correction with the same test bytes. | ✓ VERIFIED | Commit contents confirm the original test hash 9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413 at d23e05f0 and a15e3974; qualified/corrected protocol hashes are 2279206b3c3b27b5f1526b426863089b81b06883d586a97aa3e90fd8cc320e3a and 3dd97834e94398f6f26abae578085e01f70ecb42f8bc4d3235074c62ad7f63da. The recorded RED occurs after both PAR controls pass; GREEN passes the same test bytes. |
| 3 | P171-001/002/003 lifecycle cases and P171-004 required-PAR continue to enforce binding, expiry, one-use/replay, wrong-client burn and PKCE behavior. | ✓ VERIFIED | Focused protocol tests for expiry, replay and wrong-client burn passed (5 total with conflict/collision checks, 0 failures). The Phase 15 required-PAR authorization-code/PKCE flow passed and exercises replay rejection after use. |
| 4 | Stored PAR fields are validated under current client/security policy without weakening exact redirect, S256, strict signing, collision or Phase 172 response-mode behavior. | ✓ VERIFIED | validate/2 resolves current client/profile before stored-request validation; the resolver retains the distinct request-object collision check and calls client-bound consumption before rebuilding a stored-only map. Strict consumed-PAR signing passed (1/0); Phase 37 exact-redirect and Phase 172 response-mode owners passed. Conflicting-values and collision protocol tests passed. |
| 5 | P171-006 configured source-host issuer and mounted discovery endpoints remain consistent; external provider-origin, TLS/proxy and browser reachability stay supplemental and unavailable. | ✓ VERIFIED | Configured discovery passed and asserts https://example.test/lockspire plus mounted authorization, token, userinfo, JWKS, PAR, revocation and introspection endpoints. External profiles remain unlaunched, with no reachability or certification claim. |
| 6 | Qualification history and owned input identities remain auditable without rewriting frozen cases, observations, receipts, probes or prior audit records. | ✓ VERIFIED | The independent preservation command passed: “Frozen content/history preserved; owned manifest audit chain verified”. The frozen-input ledger contract test passed (1/0). Final ordered digest is e09f20b3b3dad59caa1b97179d43b5b9674201de31ba6014deb7f929ebe3d2ee; only the existing Phase 15 test and roadmap selector are audited owned identities. |

**Score:** 6/6 behavioral truths verified (0 present, behavior-unverified). Two judgment-tier prohibitions are separately flagged below; they are not counted as mechanically verified truths.

### Prohibition Judgments — Autonomous Soft-Gate

Both plan items are now status resolved, verification judgment. The two scoped verdicts below are non-authoritative and remain flagged exactly as required by the autonomous soft-gate. They are not human confirmation, wired enforcement evidence, or universal claims.

| Prohibition | Non-authoritative scoped judgment | Required flag |
|---|---|---|
| MUST NOT reattribute frozen qualification observations, accepted-main evidence, or unavailable external profiles as Phase 173 current-source, packaged-host, transport, or certification proof. | Frozen-content/history and owned-input audits found no reattribution in this Phase 173 change. | unverified-prohibition — human review recommended |
| MUST NOT move host-owned account, session, login, consent presentation, claims, or product policy into Lockspire as a consequence of the PAR authority correction. | Source diff and host handoff tests found no ownership movement in this Phase 173 change. | unverified-prohibition — human review recommended |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| lib/lockspire/protocol/authorization_request.ex | Stored-only PAR resolution without blanket outer-parameter rejection | ✓ VERIFIED | Artifact query passed. Resolver retains collision guard, reference validation, client-bound consumption and stored-only reconstruction. |
| test/integration/phase15_par_authorization_e2e_test.exs | Durable real-PAR P171-005 control/candidate regression | ✓ VERIFIED | Artifact query passed. Two PAR requests, reference-only control, then exact relative consent and persisted projection for the distinct candidate. |
| test/lockspire/protocol/authorization_request_test.exs | Conflicting outer values cannot change stored request; request-object collision remains rejected | ✓ VERIFIED | Artifact query passed. Both focused tests passed. |
| .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json | Selective audit preserves frozen qualification content and records owned identities | ✓ VERIFIED | Artifact query passed. Frozen-content/history and ordered audit-chain invariant passed independently. |
| .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md | Source-bound execution evidence and evidence limits | ✓ VERIFIED | Artifact query passed. Recorded identities match commit contents; review fix keeps original RED/GREEN evidence distinct from final reviewed test bytes. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| authorization_request.ex | repository.ex | Consume client-bound PAR reference, then project stored request | ✓ WIRED | Manual trace: Repository.consume_pushed_authorization_request/2 is called from the resolver helper; success flows to pushed_request_to_params/1. Generic key-link query returned a lexical false negative because the module is imported by alias. |
| phase15_par_authorization_e2e_test.exs | interaction.ex | Real Router request, fetch and assert persisted interaction | ✓ WIRED | Test calls Lockspire.Web.Router, then Repository.fetch_interaction/1, asserting client, scopes, state and nonce. The generic query did not resolve the repository return type; the call and assertions are present. |
| 171-QUALIFICATION.json | qualification_ledger_contract_test.exs | Validate manifest identity and digest contract | ✓ WIRED | Contract test consumes the ledger; its frozen-input drift test passed. The preservation check also verified ordered identities and digest. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Phase 15 authorization regression | interaction | Persisted interaction returned by Repository.fetch_interaction/1 after real /par and /authorize Router flow | Yes | ✓ FLOWING |

No rendered UI artifacts are in this phase.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| P171-005 conflicting-scope authority through Router | mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs --trace --only phase173_par_authority | 4 tests, 0 failures; control and candidate reached the asserted consent path | ✓ PASS |
| Expiry, replay, wrong-client burn, pushed conflict and request-object collision | mix test --include integration test/lockspire/protocol/authorization_request_test.exs:543 test/lockspire/protocol/authorization_request_test.exs:610 test/lockspire/protocol/authorization_request_test.exs:642 test/lockspire/protocol/authorization_request_test.exs:682 test/lockspire/protocol/authorization_request_test.exs:790 --trace | 5 tests, 0 failures | ✓ PASS |
| Required-PAR plus PKCE, configured discovery, exact redirects and Phase 172 response mode | mix test --include integration test/integration/phase15_par_authorization_e2e_test.exs:92 test/lockspire/web/discovery_controller_test.exs:96 test/integration/phase37_protocol_strictness_e2e_test.exs:105 test/lockspire/web/authorize_controller_test.exs:116 --trace | 4 tests, 0 failures | ✓ PASS |
| Strict message signing on consumed PAR | mix test --include integration test/lockspire/protocol/authorization_request_test.exs:326 --trace | 1 test, 0 failures | ✓ PASS |
| Frozen qualification-input contract | mix test test/lockspire/qualification_ledger_contract_test.exs:304 --trace | 1 test, 0 failures | ✓ PASS |

All Mix commands used Elixir 1.19.5, OTP 28.5 and the scoped test database lockspire_171_main_20261024b.

### Probe Execution

No Phase 173 probe was declared in the plan or summary, and no scripts/*/tests/probe-*.sh exists. Historical Phase 171 probes were preserved and not rerun.

| Probe | Command | Result | Status |
|---|---|---|---|
| N/A | None declared for Phase 173 | No Phase 173 probe execution required | N/A |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PARB-01 | 173-01-PLAN.md | Selected pushed-request binding, expiry and one-use semantics; mismatched/reused references fail per contract | ✓ SATISFIED | Focused expiry, wrong-client burn and replay tests passed; Phase 15 flow passed. |
| PARB-02 | 173-01-PLAN.md | Pushed/front-channel conflict and required-PAR cases preserve PKCE/security-profile boundaries | ✓ SATISFIED | P171-005 candidate and conflicting protocol test passed; required-PAR, S256 and strict-signing owners passed; collision guard remains covered. |
| PARB-03 | 173-01-PLAN.md | Configured discovery surface supports distinguishing selected protocol cases from unavailable transport/browser profiles | ✓ SATISFIED | Configured issuer and mounted-endpoint discovery test passed. Unavailable external profiles remain supplemental and non-certifying, matching roadmap scope. |

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| phase15_par_authorization_e2e_test.exs | PARB-01, PARB-02 | Yes | 0 found | 0 found | Behavioral + value | ✓ PASS |
| authorization_request_test.exs | PARB-01, PARB-02 | Yes | 0 found | 0 found | Behavioral + value | ✓ PASS |
| authorize_controller_test.exs, pushed_authorization_request_controller_test.exs, pushed_authorization_request_test.exs | PARB-01, PARB-02 | Yes | 0 found | 0 found | Behavioral + value | ✓ PASS |
| discovery_controller_test.exs, phase37_protocol_strictness_e2e_test.exs | PARB-02, PARB-03 | Yes | 0 found | 0 found | Value + behavioral | ✓ PASS |

Disabled-test and expected-value-writer scans found no matches in requirement-linked owners. No circular expected-value generation was found.

### Anti-Patterns Found

None. Changed implementation and test files contain no unresolved TBD, FIXME, XXX, TODO, HACK, placeholder implementation or empty-handler patterns. mix format --check-formatted and git diff --check passed.

### Decision Coverage

All 9 trackable CONTEXT decisions are honored by shipped artifacts.

### Human Verification Required

None as a blocking checkpoint. Autonomous mode is active (mode=yolo, auto_advance=true). The two resolved/judgment prohibitions carry non-authoritative scoped judgments and the explicit “unverified-prohibition — human review recommended” flag; this is a soft recommendation, not human confirmation or a hard halt. Provider-origin, TLS/proxy and browser profiles remain supplemental and unlaunched; no reachability or certification claim is made.

### Gaps Summary

No implementation or requirement gaps were found. The selected P171-005 correction is present and connected through the real Router handoff; lifecycle, required-PAR, strictness, discovery and provenance owners remain intact. Six behavioral truths are verified. Two resolved/judgment prohibitions remain prominently flagged for human review and are not counted as mechanically verified truths. The three generic edge assumptions remain unresolved and flagged; unavailable external profiles remain supplemental. None of these limits creates a universal concurrency, reachability or certification claim.

---

_Verified: 2026-10-24T23:53:28Z_
_Verifier: the agent (gsd-verifier)_
