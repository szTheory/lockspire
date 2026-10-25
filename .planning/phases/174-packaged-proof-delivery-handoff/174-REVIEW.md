---
phase: 174-packaged-proof-delivery-handoff
reviewed: 2026-10-25T03:46:02Z
depth: deep
files_reviewed: 8
files_reviewed_list:
  - docs/supported-surface.md
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room/selected_receipts.py
  - scripts/acceptance/clean_room_saas_journey.py
  - test/acceptance/selected_receipt_test.py
  - test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex
  - test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex
  - test/lockspire/clean_room_release_source_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
reviewed_head: 1c8941a427410b475e1027de292d1ec29d5cd0eb
diff_base: 6c4381920af749807ea7bfa591ef3a49f91f6fb3
inputs:
  - path: docs/supported-surface.md
    sha256: 2cd32dee2d0bf1bcc301c26afeea634698e7b0b4a44ee55cf15204705d6f4471
  - path: scripts/acceptance/clean_room/build_provider.py
    sha256: edf8911f96d7fff46fe32d7c0cbce0f8f406d76e33b335d22ca391fdd8083326
  - path: scripts/acceptance/clean_room/selected_receipts.py
    sha256: cf3d5254b39934e2d60c61b8deacbd8f8055b90406693cac8efff7a2a235b52b
  - path: scripts/acceptance/clean_room_saas_journey.py
    sha256: 1fa47489d1c4d2a7a081e629dd14b47cb831be4b96bdd21f12d22d92e43a2af3
  - path: test/acceptance/selected_receipt_test.py
    sha256: 9ff26cbbb50a58abda71e520555a124b775fb8d25370732f3ceec3d4ba665e59
  - path: test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex
    sha256: 1321e9275317bb63f0fcc738aee1a0dc7312b7769b455694ea30ffc7917a94f8
  - path: test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex
    sha256: 905b1db6c0d269db2b8128bd87e8f5e71b7ec0ad18efb1a0477831dfaaef4284
  - path: test/lockspire/clean_room_release_source_contract_test.exs
    sha256: 5f9e123c464ffde23b9017953af09b05dd9b3980b96b5a2cbadef34d68ab58e6
---

# Phase 174: Code Review Report

**Reviewed:** 2026-10-25T03:46:02Z
**Depth:** deep
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the full Phase 174 source scope from baseline `6c4381920af749807ea7bfa591ef3a49f91f6fb3` through exact HEAD `1c8941a427410b475e1027de292d1ec29d5cd0eb`, including the package runner, receipt writer/validator, its tests and CI bridge, clean-room host fixtures, and supported-surface guidance. The `174-01` through `174-04` plans and summaries, context, prior review, security audit, dispositions, package proof, and candidate gates were checked as supporting evidence. The SDK scope file was broader than the phase's actual source set; the eight files listed in this report match the Phase 174 source changes and summaries.

The runner's selected receipt flow binds the source and package identities, validates the exact requested case set and observations, rejects duplicate JSON keys recursively, and requires cleanup and redaction evidence. I found one warning in the substitution test: the replacement receipt is schema-invalid, so it would still be rejected if digest verification were removed. No other actionable source defect was confirmed in this review.

History is preserved: an earlier duplicate-JSON-key warning was fixed in commit `5f3fc9b3` by rejecting repeated object members recursively and adding root/nested mutation checks. The prior four-file review at source HEAD `5f3fc9b39c096d8355cbba6ade5f5e7a73ca7061` was clean. The current finding concerns the distinct receipt-digest substitution test and does not reopen that fixed parser issue.

The phase artifacts record a complete local package receipt with 12/12 selected cases passing, source revision `f01b6ef77889d38b032944eb37069d6d4b3b3171`, and cleanup/redaction checks true. Candidate gates separately record local `mix ci` exit 0 and hosted run `40156252600` attempt 2 with exactly seven successful canonical jobs at candidate `ec6361d9840f2adfda85116d72fec0efe9065c6c`; attempt 1's exact-floor failure remains retained. PR #140 is open and unmerged, and no accepted-main, publication, or certification result is claimed. These are artifact-reported results; this read-only review did not rerun tests, package proof, or CI.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Digest substitution test uses a schema-invalid receipt

**File:** `test/acceptance/selected_receipt_test.py:141-147`
**Issue:** The test named `test_rejects_substitution_of_another_valid_receipt_digest` changes A171-003 `control_status` from `302` to `204`. A171-003 validation only accepts control statuses `302` or `303` (`selected_receipts.py:191-200`), so the substituted receipt is invalid independently of the supplied digest. Because `validate_selected_receipt` checks the digest before decoding (`selected_receipts.py:108-117`), this test still passes if the digest check is removed: schema validation would reject `204` afterward. Thus it does not establish that a different but otherwise valid receipt is rejected by digest binding.

**Fix:** Change the mutation to another schema-valid value, such as `control_status = 303`, and assert that `validate_selected_receipt` accepts the mutated receipt without `expected_receipt_sha256` but rejects it with the original digest. This makes the test fail if digest enforcement is removed.

## Review Evidence and Limits

- `git diff --check` passed for the eight reviewed files. Source hashes are listed in the frontmatter and the review scope is the exact baseline-to-HEAD range above.
- The complete local package proof is bound to its recorded source/archive/tree/vendor/resolution/compiled identities. It establishes only the recorded package-to-loopback-host run.
- The candidate gate record preserves the first hosted failure and reports the successful latest-attempt graph independently. Candidate CI does not establish accepted-main status, publication, external issuer/TLS/proxy/browser reachability, or external profile certification.
- The security audit records 17/17 dispositions closed at its audited scope and explicitly preserves this substitution-test strength limitation as nonblocking. The limitation is represented here as a warning about test effectiveness, not as a missing runtime digest control.

---

_Reviewed: 2026-10-25T03:46:02Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
