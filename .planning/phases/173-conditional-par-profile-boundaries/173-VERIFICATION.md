---
phase: 173-conditional-par-profile-boundaries
verified: 2026-10-24T23:48:14Z
status: human_needed
score: 6/8 must-haves verified
covered_files:
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-PLAN.md
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md
  - lib/lockspire/protocol/authorization_request.ex
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
covered_digest: "v3:sha256:423675265409c9afe3f914ee7e3f354a21f1edc5eb2374b13fe1fdbe27b23eb2"
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Choose a disposition for the unresolved frozen-evidence prohibition."
    expected: "Record an explicit resolution or retain it as unresolved after reviewing the scoped ledger evidence."
    why_human: "The plan leaves this must-NOT item unresolved; the canonical prohibition lifecycle treats unresolved items as carried-forward and flagged, and current evidence does not change that lifecycle field."
  - test: "Choose a disposition for the unresolved host-ownership prohibition."
    expected: "Record an explicit resolution or retain it as unresolved after reviewing the scoped source and handoff evidence."
    why_human: "The plan leaves this must-NOT item unresolved; the canonical prohibition lifecycle treats unresolved items as carried-forward and flagged, and current evidence does not change that lifecycle field."
decision_coverage:
  honored: 9
  total: 9
  not_honored: []
---

# Phase 173: Conditional PAR & Profile Boundaries Verification Report

**Phase Goal:** Correct only P171-005's reproduced rejection of a conflicting outer scope for a valid pushed request; carry existing PAR lifecycle, required-PAR and issuer-metadata proof forward.
**Verified:** 2026-10-24T23:48:14Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | P171-005 reaches the exact relative consent route with stored openid/email scopes, state, nonce and client despite outer scope=profile; the regression records source-bound RED/GREEN. | ✓ VERIFIED | The current tagged Phase 15 Router test passed (4 tests, 0 failures) and asserts the persisted interaction after an independent control. Final post-review test hash is 9193f4dbbd075242717293c64dacf8d72c59105e43c196250ed60fb4baee4e30; original RED/GREEN test hash matches at commits d23e05f0 and a15e3974 (9a286e37949857ced7bdf5672d01a9d7d89c4f381d579be7aff6e9a5c3c35413). Protocol source hashes at qualified and corrected commits match recorded 2279206b3c3b27b5f1526b426863089b81b06883d586a97aa3e90fd8cc320e3a and 3dd97834e94398f6f26abae578085e01f70ecb42f8bc4d3235074c62ad7f63da. The summary records the candidate's expected HTTP 400 as RED after controls passed, then GREEN with the same test bytes. |
| 2 | P171-001/002/003 lifecycle cases and P171-004 required-PAR continue to enforce binding, expiry, one-use/replay, wrong-client burn and PKCE behavior. | ✓ VERIFIED | Focused protocol tests for expiry, replay, wrong-client burn, conflict and collision passed (5/0). The Phase 15 required-PAR authorization-code/PKCE flow passed and exercises replay rejection after use. |
| 3 | Stored PAR fields are validated under current client/security policy without weakening exact redirect, S256, strict signing, collision or Phase 172 response-mode behavior. | ✓ VERIFIED | validate/2 resolves current client/profile before stored-request validation; the resolver retains the distinct request-object collision check and calls client-bound consumption before rebuilding a stored-only map. Strict consumed-PAR signing passed (1/0); Phase 37 exact-redirect and Phase 172 response-mode owners passed in the retained-owner run. The conflicting-values and collision protocol tests passed. |
| 4 | P171-006 configured source-host issuer and mounted discovery endpoints remain consistent; external provider-origin, TLS/proxy and browser reachability stay supplemental and unavailable. | ✓ VERIFIED | Configured discovery test passed and asserts issuer https://example.test/lockspire plus mounted authorization, token, userinfo, JWKS, PAR, revocation and introspection endpoints. Dispositions retain external profiles as unlaunched, with no reachability or certification claim. |
| 5 | Qualification history and owned input identities remain auditable without rewriting frozen cases, observations, receipts, probes or prior audit records. | ✓ VERIFIED | The independent preservation command passed: “Frozen content/history preserved; owned manifest audit chain verified”. The frozen-input ledger contract test passed (1/0). Final ordered digest is e09f20b3b3dad59caa1b97179d43b5b9674201de31ba6014deb7f929ebe3d2ee; only the existing Phase 15 test and roadmap selector are audited owned identities. |
| 6 | The selected change does not move host-owned account/session/login/consent or product policy into Lockspire. | ✓ VERIFIED | Implementation diff is limited to the private protocol resolver; host resolver, controller and consent ownership are unchanged. Current interaction assertions verify the host handoff seam. |
| 7 | Frozen qualification observations and unavailable external profiles are not reattributed as current packaged-host proof. | ? UNCERTAIN | The source/ledger audit and scoped dispositions support this result, but the plan's prohibition remains unresolved and has no verification tier. Human disposition is required. |
| 8 | Host-owned account, session, login, consent presentation, claims and product policy are not moved into Lockspire. | ? UNCERTAIN | The source diff and tests support this result, but the plan's prohibition remains unresolved and has no verification tier. Human disposition is required. |

**Score:** 6/8 must-haves verified (0 present, behavior-unverified; 2 prohibition declarations need human disposition)

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

This protocol/library phase has no user-facing UI. The following two plan prohibitions remain unresolved and descriptor-less. Scoped evidence is recorded above, but a human must choose whether to resolve or retain each item.

| Plan prohibition | Lifecycle | Scoped evidence | Routing |
|---|---|---|---|
| MUST NOT reattribute frozen qualification observations, accepted-main evidence, or unavailable external profiles as Phase 173 current-source, packaged-host, transport, or certification proof. | unresolved | Frozen content/history and owned-input audit passed; external profiles remain unlaunched and non-certifying. | Human disposition |
| MUST NOT move host-owned account, session, login, consent presentation, claims, or product policy into Lockspire as a consequence of the PAR authority correction. | unresolved | Source diff changes only the private protocol resolver; host resolver/controller/consent seam remains in place. | Human disposition |

Canonical routing: /Users/jon/.codex/gsd-core/references/prohibition-probe.md defines unresolved as carried forward and flagged, with a verification tier only when resolved. /Users/jon/.codex/gsd-core/agents/gsd-verifier.md requires flagged prohibitions to route to human_verification or gaps_found, never silently into passed. The missing verification value is consistent with the unresolved lifecycle state; no resolved test or judgment tier is recorded.

#### 1. Frozen-evidence provenance prohibition

**Test:** Choose a disposition for the first unresolved prohibition after reviewing the canonical ledger and Phase 173 append records.

**Expected:** Record an explicit resolution or retain it as unresolved; the frozen records remain unchanged.

**Why human:** The plan marks this prohibition unresolved. The canonical prohibition lifecycle requires the unresolved state to remain flagged until a disposition is made.

#### 2. Host-ownership prohibition

**Test:** Choose a disposition for the second unresolved prohibition after reviewing the implementation diff and integration handoff.

**Expected:** Record an explicit resolution or retain it as unresolved; account, session, login, consent, claims and product policy remain host-owned.

**Why human:** The plan marks this prohibition unresolved. The canonical prohibition lifecycle requires the unresolved state to remain flagged until a disposition is made.

Provider-origin, TLS/proxy and browser profiles remain supplemental and unlaunched; these are not human-verification requirements for this selected phase and no reachability or certification claim is made.

### Gaps Summary

No implementation or requirement gaps were found. The selected P171-005 correction is present and connected through the real Router handoff; lifecycle, required-PAR, strictness, discovery and provenance owners remain intact. Overall status is human_needed because the two plan prohibitions are unresolved and lack verification tiers. Generic concurrency/unclassified edges and unavailable external profiles remain scoped limits, not new universal guarantees or certification claims.

---

_Verified: 2026-10-24T23:48:14Z_
_Verifier: the agent (gsd-verifier)_
