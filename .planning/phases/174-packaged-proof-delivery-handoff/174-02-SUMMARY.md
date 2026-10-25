---
phase: 174-packaged-proof-delivery-handoff
plan: "02"
subsystem: testing
tags: [phoenix, oauth, par, oidc-discovery, package-proof, security-review]

requires:
  - phase: 174-01
    provides: Package-bound selected receipt runner, A171-001–006 observations, redaction and owned cleanup seams
  - phase: 173-01
    provides: Stored PAR authority correction and exact relative consent regression
provides:
  - Real packaged-host P171-001–006 observations with all twelve frozen A/P rows in one complete receipt
  - Strict duplicate-key-safe selected receipt parser and mutation tests
  - Public support guidance for the two corrections and the bounded package evidence boundary
  - Scoped code/security review records and two explicit non-authoritative Phase 174 judgment flags
affects: [174-03, 174-04, packaged-acceptance, delivery-handoff]

actuals:
  tokens: 13224
  tasks: 2
  commits: 10
  plan_head_before: b29326b120b84df87c021818f6acbcd5aac4f75c
  plan_head_after: 9caac49f419b356b8514551a757124fa7cfdd128

tech-stack:
  added: []
  patterns: [strict duplicate-key JSON parsing, bounded persisted PAR equality projection, package-bound complete and partial receipts]

key-files:
  created:
    - scripts/acceptance/clean_room/selected_receipts.py
    - test/acceptance/selected_receipt_test.py
    - .planning/phases/174-packaged-proof-delivery-handoff/174-REVIEW.md
    - .planning/phases/174-packaged-proof-delivery-handoff/174-SECURITY.md
    - .planning/phases/174-packaged-proof-delivery-handoff/174-DISPOSITIONS.md
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
    - docs/supported-surface.md
    - .planning/phases/174-packaged-proof-delivery-handoff/174-01-PLAN.md

key-decisions:
  - "P171-001 and P171-004 may share one required-PAR/S256 lifecycle journey while retaining independent executed assertion rows."
  - "Expiry fixture setup and persisted interaction observation use only the existing private run-owned child-command seam; protocol outcomes are observed over mounted HTTP."
  - "Lockspire 1.6.1 remains the package version; this plan adds proof and does not bump or publish the package."
  - "Only the two Phase 174 prohibitions transition to resolved/judgment after scoped review; both keep their non-authoritative human-review flags, and Phase 173 history remains unchanged."

patterns-established:
  - "JSON receipt parsing rejects duplicate member names recursively before exact-field validation."
  - "Persisted PAR evidence contains allowlisted field-equality booleans and never stores client state, nonce, or request URI values."
  - "A local package receipt is bound to its exact source/archive/tree/vendor/resolution/compiled identities and remains distinct from CI, accepted-main, publication, and external-profile evidence."

requirements-completed: [CPROOF-01, CPROOF-02, DELIV-01]

coverage:
  - id: D1
    description: "Run all twelve frozen authorization and PAR cases through the package-bound disposable Phoenix host."
    requirement: CPROOF-01
    verification:
      - kind: integration
        ref: ".artifacts/phase174/par.json; source 9caac49f419b356b8514551a757124fa7cfdd128; receipt SHA-256 38a836efd4a6b83144ae4d6eda522ac5057bf67993f418b75ce389c0e8872052"
        status: pass
    human_judgment: false
  - id: D2
    description: "Reject malformed, substituted, failed, skipped, unsafe, duplicate-key, and mismatched selected receipts."
    requirement: CPROOF-02
    verification:
      - kind: unit
        ref: "python3 test/acceptance/selected_receipt_test.py (16 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Document delivered behavior and evidence limits; record independent scoped reviews and two prohibition lifecycle judgments."
    requirement: DELIV-01
    verification:
      - kind: other
        ref: ".planning/phases/174-packaged-proof-delivery-handoff/174-REVIEW.md and 174-SECURITY.md; code review clean, security 4/4 dispositions closed"
        status: pass
    human_judgment: true
    rationale: "The two resolved/judgment prohibitions remain explicitly non-authoritative and request human review; no human confirmation is claimed."

commits: 10
duration: 28min
completed: 2026-10-25
status: complete
---

# Phase 174 Plan 02: Packaged PAR Expansion and Scoped Reviews Summary

**The Lockspire 1.6.1 package passed all twelve selected authorization/PAR HTTP cases with strict receipt binding, persisted-scope authority checks, and reviewable support limits.**

## Performance

- **Duration:** 28 minutes
- **Started:** 2026-10-25T01:37:40Z
- **Completed:** 2026-10-25T02:05:40Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Expanded the package runner to execute P171-001–006 through mounted PAR, authorization, token, and discovery HTTP. The final complete run executed A171-001–006 and P171-001–006, with 12 passed, 0 failed, and 0 skipped.
- Added strict observations for required-PAR direct rejection, `application/json` PAR intake and positive integer expiry, S256 code redemption, one-use replay, wrong-client burn, expired references, pushed-scope authority, persisted client/scopes/state/nonce equality, and mounted discovery.
- Hardened JSON parsing to reject duplicate object members recursively. The receipt suite now has 16 passing behavioral and negative-mutation tests.
- Updated the supported-surface guide with the two delivered corrections and a reproducible package proof command. Preserved the historical compatibility-floor advisory/isolation and patched-production-host recommendation, and the unavailable external-profile limits.
- Obtained a clean scoped code review and an independent ASVS L1 security audit. The security auditor closed all four registered dispositions after a focused recheck of the two scoped judgment lifecycle records.

## Actual Proof Artifact

The final receipt is an ignored run artifact, not a source commit:

| Artifact | Source revision | Receipt SHA-256 | Package identity | Scope/result |
|---|---|---|---|---|
| `.artifacts/phase174/par.json` | `9caac49f419b356b8514551a757124fa7cfdd128` | `38a836efd4a6b83144ae4d6eda522ac5057bf67993f418b75ce389c0e8872052` | Lockspire `1.6.1`; archive `89baff6aaf0549cee541ec9b381798fe502c8be33c71ff894440ec85563598cc`; package/vendor tree `a9d09087d573f309c8dc329706b18b15e8583cad756c9929204b8310b88d7ec1`; compiled candidate `7c3a6f32de5dd5272a30cd4c0dc002711b9b89b2e52f47f22e7e1771eab6c281`; dependency resolution verified | Complete A171-001–006 and P171-001–006; 12 executed, 12 passed, 0 failed, 0 skipped |

The final run reported `processes_stopped`, `databases_removed`, `temporary_roots_removed`, `sentinel_check_passed`, and `evidence_scan_passed` all true. The external receipt checker accepted the exact source revision and byte digest. The package version was not changed.

Focused, explicitly partial diagnostic receipts for P171-003, P171-005, and P171-006 also passed their source/digest checks during debugging; the complete receipt above supersedes them. The clean-room runner used random per-run databases, loopback ports, and temporary roots. Earlier databases with unverified ownership were not touched.

## Verification

- `python3 test/acceptance/selected_receipt_test.py` — 16 tests passed, including rejection of duplicate root and nested keys, skipped/missing P rows, invalid lifecycle statuses, false persisted authority facts, and absolute consent lookalikes.
- Full `selected_authorization_par` package run with Elixir `1.19.5-otp-28` / OTP `28.5` and `LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b` — 12/12 passed from the committed Lockspire 1.6.1 package; cleanup and redaction passed.
- `python3 scripts/acceptance/clean_room_saas_journey.py --check-selected-receipt .artifacts/phase174/par.json --expected-source-revision 9caac49f419b356b8514551a757124fa7cfdd128 --expected-receipt-sha256 38a836efd4a6b83144ae4d6eda522ac5057bf67993f418b75ce389c0e8872052` — selected receipt verified.
- `python3 -m py_compile` for the changed runner, receipt module, and receipt tests — passed.
- `git diff --check` — passed.
- Code review: `174-REVIEW.md`, deep review at source HEAD `5f3fc9b39c096d8355cbba6ade5f5e7a73ca7061`, 0 findings. Its duplicate-key warning was fixed and re-reviewed.
- Security: `174-SECURITY.md`, independent ASVS L1 audit and focused recheck, 4/4 dispositions closed, `threats_open: 0`, no high/critical blocker. The security role did not run tests or package proof.

This evidence is a bounded local package-to-loopback-host result. It does not establish hosted candidate CI, accepted-main status, publication, public issuer/TLS/proxy/browser reachability, or OIDF/FAPI certification.

## Task Commits

1. `6a4c019d` — Add P171-001–006 runner and strict PAR receipt observations.
2. `322c4bee` — Use the actual packaged server-policy API for required PAR.
3. `213a581f` — Keep the consent interaction ID separate from its observed status and contain HTTP transport errors.
4. `f7ed75df` — Give the synthetic expiry fixture a valid S256 challenge.
5. `d4ca3193` — Match the repository's `{:ok, interaction}` persisted-fetch result.
6. `281fcdc9` — Use the source-owned discovery PAR metadata field.
7. `ca74dfe3` — Compare mounted discovery endpoints as configured issuer plus route suffix.
8. `b4c19e82` — Document the bounded package proof and support-surface behavior.
9. `5f3fc9b3` — Reject duplicate JSON receipt members and cover root/nested mutations.
10. `9caac49f` — Record scoped review, security, dispositions, and judgment lifecycle.

The final state/summary metadata commit is made separately after the SDK state updates.

## Files Created/Modified

- `scripts/acceptance/clean_room_saas_journey.py` — Six PAR/discovery cases, private expiry and persisted interaction observation, and safe lifecycle projections.
- `scripts/acceptance/clean_room/selected_receipts.py` — Exact twelve-case observation contract and duplicate-key-safe receipt parsing.
- `test/acceptance/selected_receipt_test.py` — Positive contracts and negative mutations for all twelve IDs and unsafe receipt shapes.
- `docs/supported-surface.md` — Delivered response-mode/PAR behavior, package command, and local-proof limits.
- `.planning/phases/174-packaged-proof-delivery-handoff/174-REVIEW.md` — Actual deep code-review record with exact source-input hashes.
- `.planning/phases/174-packaged-proof-delivery-handoff/174-SECURITY.md` — Actual ASVS L1 dispositions and focused T-174-09 lifecycle recheck.
- `.planning/phases/174-packaged-proof-delivery-handoff/174-DISPOSITIONS.md` — Provenance and non-authoritative flags for the two Phase 174 judgments.
- `.planning/phases/174-packaged-proof-delivery-handoff/174-01-PLAN.md` — Only the two Phase 174 prohibition lifecycle entries updated; Phase 173 history remains unchanged.

## Decisions Made

- P171-001 and P171-004 share one required-PAR lifecycle run, while each retains a separate assertion row. This avoids claiming duplicate independent flow execution.
- PAR expiry fixture setup and persisted interaction reads remain on the existing private child-command seam. The receipt retains only safe equality facts; no product or debug route was added.
- Keep Lockspire `1.6.1`; no package version bump, release dispatch, tag, or publication was selected.
- Resolve only the two Phase 174 prohibitions at the judgment tier after actual reviews. Preserve both required human-review flags and the separate inherited Phase 173 flags.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the required-PAR policy fixture API**
- **Found during:** Task 1, first real package run.
- **Issue:** The harness called nonexistent `put_par_policy/1` in the packaged 1.6.1 API.
- **Fix:** Used the source-owned `Lockspire.Admin.ServerPolicy.put_server_policy/1` API.
- **Files:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Subsequent package run completed required-PAR cases.
- **Commit:** `322c4bee`.

**2. [Rule 1 - Bug] Unpacked the consent handoff tuple correctly**
- **Found during:** Task 1, second real package run.
- **Issue:** `_par_consent_handoff` returned `(interaction_id, status)`, but the approval path used the pair as the interaction ID.
- **Fix:** Unpacked the interaction ID/status separately and routed HTTP transport failures through the redacted failure summary.
- **Files:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Subsequent P171-001 package flow passed.
- **Commit:** `213a581f`.

**3. [Rule 1 - Bug] Replaced an invalid synthetic PKCE fixture challenge**
- **Found during:** Task 1, second full package run at P171-003.
- **Issue:** The expired-reference fixture's live neighbor used a placeholder challenge rejected by the real authorization path.
- **Fix:** Generate a valid S256 challenge from a registered run-owned verifier.
- **Files:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Focused P171-003 package receipt passed and validated.
- **Commit:** `f7ed75df`.

**4. [Rule 1 - Bug] Matched the persisted-interaction result contract**
- **Found during:** Task 1, full package run at P171-005.
- **Issue:** `Repository.fetch_interaction/1` returns `{:ok, interaction}`; the observer treated it as a bare struct.
- **Fix:** Match the repository tuple and emit only the allowlisted equality projection.
- **Files:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Focused P171-005 receipt passed with exact consent and all persisted fields true.
- **Commit:** `d4ca3193`.

**5. [Rule 1 - Bug] Matched the actual configured PAR discovery key and mount semantics**
- **Found during:** Task 1, successive full package runs at P171-006.
- **Issue:** The runner first queried a non-source key, then appended `/lockspire` even though the configured issuer already contained the mount path.
- **Fix:** Assert `pushed_authorization_request_endpoint` exactly equals issuer plus `/par`, and compare all other endpoints as issuer plus their route suffix.
- **Files:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** Focused P171-006 package receipt passed with issuer match and all seven endpoint booleans true.
- **Commits:** `281fcdc9`, `ca74dfe3`.

**6. [Rule 2 - Missing critical receipt strictness] Rejected duplicate JSON members**
- **Found during:** Task 2 independent code review.
- **Issue:** Python's default JSON decoder collapses duplicate object member names before exact field validation, allowing ambiguous serialized receipts.
- **Fix:** Add recursive `object_pairs_hook` duplicate rejection and root/nested duplicate mutation tests.
- **Files:** `scripts/acceptance/clean_room/selected_receipts.py`, `test/acceptance/selected_receipt_test.py`.
- **Verification:** 16 receipt tests passed; the reviewer re-reviewed the fix and reported zero findings.
- **Commit:** `5f3fc9b3`.

**Total deviations:** 6 auto-fixed issues (1 blocking API mismatch, 4 runner bugs, 1 receipt strictness gap). **Impact:** All were required to produce valid real package observations and strict receipts; no Lockspire product policy/API/schema or dependency changed.

## Issues Encountered

- A package attempt made while the reviewer report was untracked failed the runner's clean-source precondition before candidate execution. It was not accepted as proof. The review/lifecycle artifacts were committed, then the complete package run passed against the resulting clean HEAD.
- Earlier package attempts stopped at the fixture/API issues listed above. Each runner completed its owned process/database/temp-root cleanup; only the final complete receipt is treated as acceptance evidence.
- The existing compatibility-floor advisory remains as written. The new package evidence does not recommend that historical floor for production.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 174-03 can perform the later frozen-input selective manifest audit, prior-owner refresh, and final package/candidate gates. This plan does not execute those gates or mark the full phase complete. Release auto-merge remains false, and no PR, merge, accepted-main result, release tag, Hex publication, external profile, or dispatch is claimed.

---
*Phase: 174-packaged-proof-delivery-handoff*
*Plan: 02*
*Completed: 2026-10-25*

## Self-Check: PASSED

- Summary, runner, validator, tests, guidance, and all three role/disposition reports exist.
- All ten task commits are ancestors of plan head `9caac49f`.
- Stub-pattern scan found no TODO, FIXME, placeholder, or coming-soon markers in plan-owned implementation and guidance files.
- `git diff --check` passed; the only untracked file before the metadata update is this summary.
