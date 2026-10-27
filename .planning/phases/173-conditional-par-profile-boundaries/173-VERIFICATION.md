---
phase: 173-conditional-par-profile-boundaries
verified: 2026-10-25T05:35:11Z
status: passed
score: 6/6 behavioral truths verified
covered_files:
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-PLAN.md
  - .planning/phases/173-conditional-par-profile-boundaries/173-01-SUMMARY.md
  - .planning/phases/174-packaged-proof-delivery-handoff/174-INPUT-FREEZE.json
  - .planning/phases/174-packaged-proof-delivery-handoff/174-PACKAGE-PROOF.json
  - .planning/phases/174-packaged-proof-delivery-handoff/174-PROOF-INDEX.json
  - .planning/phases/174-packaged-proof-delivery-handoff/174-SOURCE-PROOF.json
  - lib/lockspire/protocol/authorization_request.ex
  - test/acceptance/selected_receipt_test.py
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/lockspire/clean_room_release_source_contract_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
covered_digest: "v3:sha256:ab0ae8e8cdbe6552a11088016ccb1a813df890ea7538c51d56d4fb258ce0a572"
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
re_verification:
  previous_status: passed
  previous_score: 6/6
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 173: Conditional PAR & Profile Boundaries Verification Report

**Phase Goal:** Correct only P171-005's reproduced rejection of a conflicting outer `scope` for a valid pushed request; carry existing PAR lifecycle, required-PAR and issuer-metadata proof forward.
**Verified:** 2026-10-25T05:35:11Z
**Status:** passed — 6/6 behavioral truths verified; 2 judgment-tier prohibitions retain non-authoritative review flags.
**Re-verification:** Yes — proper-owner freshness reassessment after Phase 174 diagnostic repair and candidate review. Historical test identities remain unchanged.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A valid P171-005 pushed request reaches exact relative consent with stored `openid email`, state, nonce and client despite outer `scope=profile`. | ✓ VERIFIED | Phase 174 `source-01` records 11/11 passing at source revision `a348bf71285cb0ffe9eeba0da94a6c2d46faa477`; its Phase 15 test SHA (`9193f4db…`) and authorization source SHA (`3dd97834…`) match current bytes. The test asserts independent control and candidate persisted interaction projection. |
| 2 | The durable regression preserves the normative same-test RED/GREEN record and current code is GREEN at the frozen source-proof revision. | ✓ VERIFIED | Original Phase 173 RED: commit `79048ed2`, source SHA `2279206b…`; original GREEN: commit `a15e3974`, source SHA `3dd97834…`; both use test SHA `9a286e37…`. Those identities remain in the Phase 173 summary and qualification ledger. The later source-proof GREEN at `a348bf…` covers the current source/test bytes. No historical RED was rerun. |
| 3 | P171-001/002/003 binding, expiry, one-use/replay and wrong-client burn, plus P171-004 required-PAR, remain enforced. | ✓ VERIFIED | Frozen source-proof `source-01` (11/11) and `source-03` (94/94) passed at `a348bf…`; `source-03` hashes match the current authorize/PAR protocol owner tests. These are finite selected cases, not a generic concurrency guarantee. |
| 4 | Stored PAR fields are checked under current client/security policy without weakening redirect, S256, signing, collision or Phase 172 response-mode behavior. | ✓ VERIFIED | `source-02` strictness (5/5) and `source-03` (94/94) passed on the current authorization source SHA. Source keeps current client resolution, bound consume and stored-only reconstruction; the separate request/request_uri collision assertion remains in the protocol test. |
| 5 | Configured source-host issuer and discovery endpoints remain consistent; external origin/TLS/proxy/browser reachability remains supplemental and unavailable. | ✓ VERIFIED | `source-01` includes discovery and Phase 15, 11/11 passing; recorded discovery test asserts configured `https://example.test/lockspire` and mounted endpoints. No external profile or public reachability claim is made. |
| 6 | Frozen qualification history, owned Phase 173 input audits and evidence identities remain auditable without rewriting the counterexample or RED/GREEN records. | ✓ VERIFIED | The ledger’s two Phase 173 owned audit entries are the Phase 15 test identity (`9a286e37…` → current `9193f4db…`) and `phases-172-173-contract` roadmap selector (`a0441aa7…` → `27dab1dd…`). The current manifest contract test passed: `mix test test/lockspire/qualification_ledger_contract_test.exs:304 --trace` — 1 test, 0 failures. The ledger still contains original P171-005 counterexample probe SHA `0f32ab00…` and the original Phase 173 RED/GREEN identities above. |

**Score:** 6/6 truths verified (0 present, behavior-unverified). The two judgment-tier prohibitions are reported separately and are not counted as mechanically verified truths.

### Prohibition Judgments — Autonomous Soft-Gate

Both plan prohibitions are `resolved` / `judgment`. Their scoped dispositions remain non-authoritative and retain the required prominent flags. Under the autonomous judgment soft-gate these flags do not create an awaited human checkpoint. They are not mechanical enforcement, human confirmation, or universal proof.

| Prohibition | Scoped judgment | Required flag |
|---|---|---|
| Do not reattribute frozen observations, accepted-main evidence, or unavailable external profiles. | Ledger/history and source-proof review found no reattribution within the Phase 173 change. | `unverified-prohibition — human review recommended` |
| Do not move host-owned identity, login, consent, claims or policy into Lockspire. | Runtime diff and host handoff owners show no ownership movement from the PAR correction. | `unverified-prohibition — human review recommended` |

### Adjacent Phase 174 Package Evidence (Local Only)

The refreshed Phase 174 package proof and index record 12/12 selected scenarios at frozen source revision `73bb46811f4b76b2372b4af2b4e21aaf42893ac1`; package proof SHA-256 is `9ec9de15ccdb3522a6dd179da1f58e8d700e2502e8885782899152700e900844`. The index SHA-256 is `fefc13619dda61b0617cc2fad445f887652edaba42ffaad5d988cb43650e8fb8`; it binds input-freeze SHA `3c1e0b62…`, the package receipt, and the test/review evidence. The receipt records archive SHA `89baff6a…`, tree SHA `a9d09087…`, compiled candidate SHA `ecc72eca…`, and successful cleanup/redaction checks. It maps P171-005 to the Phase 173 correction and retains the original qualification counterexample separately.

The package evidence was strengthened by test-only commit `a00f0d0a`: the receipt-substitution test now substitutes a valid alternate `control_status=303`, verifies that the same-bound receipt is otherwise accepted, then asserts rejection specifically for mismatch with the externally supplied digest. The proof index records 16/16 Python validator tests and 7/7 ExUnit bridge tests passing at that test identity and retains historical clean review hash `8a64f3278571d3cb1359003ea690de6c7adaad7976db3cee6a792d3d774f04a4`. The original eight-file review bytes at package revision `73bb46811f4b76b2372b4af2b4e21aaf42893ac1` independently match that hash; all eight historical input hashes still match current bytes. These checks establish receipt-validator behavior, not a new Phase 173 protocol behavior. The intervening `38a19a29` clean-room resolver/session fixture edits were formatting-only. Phase 173 source-owner files remain byte-identical to the source-proof GREEN at `a348bf…`, so that source evidence remains applicable. The package run is local package-clean host evidence only; it does not establish hosted candidate CI, accepted-main, publication, external transport, or certification.

### Freshness Reassessment — Phase 174 Diagnostic Repair and Candidate Review

The Phase 174 repair changed only `scripts/ci/run_host_integration_proof.sh` and `test/clean_room/test_admin_journey.py`, both outside the 63-file freeze. All frozen file hashes and the 18 indexed source-owner hashes still match current bytes. The package proof remains 12/12, bound to source `73bb46811f4b76b2372b4af2b4e21aaf42893ac1`; the 132 source-owner GREEN tests remain bound to `a348bf71285cb0ffe9eeba0da94a6c2d46faa477`. The wrapper repair affects failure diagnostics and child-exit preservation only. Ten focused wrapper tests are recorded passing, and the focused security recheck is SECURED with zero open threats. The package owner assessed the existing receipt as applicable because the successful 12/12 run did not enter those failure branches; no package execution at either repair commit is claimed. The failed exact-floor attempt at candidate `1a34011c` (run `40160485083`, lifecycle exit 2, inner log unavailable) remains failed history and is not converted into the later candidate result.

The replacement candidate `9b8cf54dc7e457e2264a15901b011d0c70a1ed8c` has recorded local `mix ci` exit 0 and hosted run `40161576115` attempt 1 with seven successful canonical jobs. PR #140 remains open and unmerged; these candidate gates do not establish accepted-main, publication, or certification. The current expanded ten-file `174-REVIEW.md` (SHA-256 `14277f07ff7c13e36464ba9a47e18e7de8251c2a7c54c0c3cd5fdc366d3c2475`) reports clean at reviewed head `9ee03ab63d33793b60dcc942ba79eccaa6a19180`, but its recorded `scripts/acceptance/clean_room_saas_journey.py` hash (`1fa47489d1c4d2a7a081c26afeea634698e7b0b4a44ee55cf15204705d6f4471`) does not match actual/current and frozen bytes (`1fa47489d1c4d2a7a081e629dd14b47cb831be4b96bdd21f12d22d92e43a2af3`). This is pending proper-owner correction; its current clean verdict is not used as evidence. The expanded review is excluded from the current fingerprint as a derivative artifact with a source-inventory correction pending. The earlier review remains independently hashed by the proof index, while the Phase 173 plan, qualification ledger, source proof, package proof, and proof index remain covered. The original P171-005 counterexample and Phase 173 RED/GREEN identities remain distinct. Both Phase 173 judgment-tier flags and all three generic unresolved fallback assumptions remain unchanged.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/lockspire/protocol/authorization_request.ex` | Stored-only PAR authority resolution | ✓ VERIFIED | Artifact query passed; resolver validates and consumes the bound reference, then rebuilds parameters from the stored request. |
| `test/integration/phase15_par_authorization_e2e_test.exs` | Real Router P171-005 control/candidate regression | ✓ VERIFIED | Artifact query passed; current bytes match source-proof `source-01`. |
| `test/lockspire/protocol/authorization_request_test.exs` | Conflicting outer values and distinct collision behavior | ✓ VERIFIED | Artifact query passed; explicit conflicting-value and collision cases are present. |
| `171-QUALIFICATION.json` | Frozen content and attributed input identity history | ✓ VERIFIED | Artifact query passed; current frozen-input named contract test passed. |
| `173-01-SUMMARY.md` | Original RED/GREEN identities and evidence limits | ✓ VERIFIED | Artifact query passed; the historical entries were checked against the current ledger and proof index. |
| Phase 174 freeze, source/package proof, index and validator evidence | Current source GREEN plus bounded local package evidence and strengthened receipt validation | ✓ VERIFIED | Exact freeze, receipt, index, validator test, bridge test and clean review are fingerprinted. Package result is local-only and does not extend Phase 173 into candidate/main/certification proof. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `authorization_request.ex` | `repository.ex` | Bound PAR consume then stored-request projection | ✓ WIRED | Manual trace at `resolve_authorization_params/2` → `consume_pushed_authorization_request/2` → `Repository.consume_pushed_authorization_request/2` → `pushed_request_to_params/1`. Generic lexical query missed the imported alias. |
| Phase 15 integration test | `interaction.ex` | Real Router PAR/authorize flow then persisted interaction assertions | ✓ WIRED | Tagged P171-005 test calls Router, fetches via `Repository.fetch_interaction/1`, and asserts client, scopes, state and nonce. |
| Qualification ledger | ledger contract test | Frozen path/selector identities and ordered digest | ✓ WIRED | Current named frozen-input contract test passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Phase 15 authorization regression | persisted interaction | `Repository.fetch_interaction/1` after actual `/par` and `/authorize` Router requests | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Current P171-005 source GREEN and configured discovery | Phase 174 frozen `source-01` exact hashes at `a348bf…` | 11 passed, 0 failed; current relevant bytes match | ✓ PASS |
| Current strictness and Phase 172 behavior | Phase 174 frozen `source-02` / `source-03` | 5/5 and 94/94; relevant authorization/PAR owner hashes match | ✓ PASS |
| Frozen qualification input manifest | `mix test test/lockspire/qualification_ledger_contract_test.exs:304 --trace` | 1 test, 0 failures | ✓ PASS |

The Phase 173 RED/GREEN run identities remain historical evidence and were not replayed. No exact-main authority was rerun or inferred.

### Probe Execution

No Phase 173 probe was declared. Historical Phase 171 probes were preserved and not rerun.

| Probe | Result | Status |
|---|---|---|
| N/A | No Phase 173 probe declared | N/A |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PARB-01 | `173-01-PLAN.md` | Selected binding, expiry and one-use semantics | ✓ SATISFIED | Current source proof `source-01` and `source-03`; finite selected lifecycle cases only. |
| PARB-02 | `173-01-PLAN.md` | Pushed authority, required-PAR/PKCE/security boundaries | ✓ SATISFIED | Current Phase 15, protocol and strictness source proof; current P171-005 GREEN bytes match. |
| PARB-03 | `173-01-PLAN.md` | Configured issuer/endpoints and honest external attribution | ✓ SATISFIED | Current source-host discovery proof; external profiles remain unavailable and supplemental. |

All three roadmap requirements map to the plan; no orphaned Phase 173 requirement was found.

### Test Quality Audit

| Test File | Linked Requirement | Active | Disabled/circular | Assertion level | Verdict |
|---|---|---:|---|---|---|
| `phase15_par_authorization_e2e_test.exs` | PARB-01, PARB-02 | Yes | None found | Behavioral + value | ✓ PASS |
| `authorization_request_test.exs` | PARB-01, PARB-02 | Yes | None found | Behavioral + value | ✓ PASS |
| `qualification_ledger_contract_test.exs` | PARB-03 | Yes | None found | Contract/value | ✓ PASS |

### Anti-Patterns Found

None in the changed runtime/test artifacts. Targeted scans found no unresolved debt markers, placeholder implementations, empty handlers, disabled requirement tests, or test-generated expected values.

### Decision Coverage

All 9 trackable CONTEXT decisions are honored by shipped artifacts.

### Human Verification Required

None as a blocking checkpoint. This is an infrastructure/library phase. The two judgment-tier flags remain visible review recommendations under the autonomous soft-gate. The three generic fallback assumptions remain explicitly unresolved: generic interruption/parallel PAR behavior, the unclassified PARB-02 edge, and generic external-profile interruption/parallel behavior. External provider-origin, TLS/proxy, and browser profiles were not launched.

### Gaps Summary

No selected implementation or requirement gap was found. Current source-proof GREEN covers the exact relevant source/test bytes at its recorded revision, and the current frozen-input contract check passes. The original Phase 171 counterexample and Phase 173 RED/GREEN identities remain distinct and preserved. Generic fallback assumptions, external profiles, and certification-level claims remain outside the verified scope. There is no universal concurrency, accepted-main, hosted candidate, publication, reachability, or certification proof.

---
_Verified: 2026-10-25T05:35:11Z_
_Verifier: the agent (gsd-verifier)_
