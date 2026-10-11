---
phase: "143"
slug: "publish-and-verify-lockspire-1-5-1"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 143 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/lockspire/release_artifact_chain_contract_test.exs test/lockspire/publish_verification_test.exs test/lockspire/release_main_freeze_test.exs test/lockspire/release_workflow_artifact_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~60 seconds for focused contracts; full CI runtime varies by runner |

---

## Sampling Rate

- **After every task commit:** Run the focused release contract tests relevant to the changed scripts/workflow.
- **After every plan wave:** Run `mix ci` when source or workflow code changed.
- **Before `$gsd-verify-work`:** Exact-SHA required CI and protected public release proof must be green.
- **Max feedback latency:** 60 seconds for focused contract tests.

---

## Per-Task Verification Map

The requirement-level checks below are established from RESEARCH.md. Bind each row to the final PLAN task IDs and waves after decomposition.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 143-01-01 | 143-01 | 1 | REL-02 | T-143-01 | Existing lightweight and annotated tags are resolved to the exact source commit. | contract | `mix test test/lockspire/release_artifact_chain_contract_test.exs` | ✅ | ⬜ pending |
| 143-01-02 | 143-01 | 1 | REL-02 | T-143-01 | GitHub release handling requires actual remote-ref verification before release bookkeeping. | contract | `mix test test/lockspire/release_workflow_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 143-02-01 | 143-02 | 2 | REL-02 | T-143-02 | Manifest records the supported publisher Hex version and the protected job checks it before upload. | contract | `mix test test/lockspire/release_artifact_chain_contract_test.exs test/lockspire/release_workflow_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 143-02-02 | 143-02 | 2 | REL-02 | T-143-03 | The direct uploader receives the exact manifest-verified tar bytes. | contract | `mix test test/lockspire/release_artifact_chain_contract_test.exs test/lockspire/release_workflow_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 143-03-01 | 143-03 | 3 | REL-03 | T-143-04 | Terminal receipt schema preserves bounded per-stage states for complete, partial, not-run, and unknown outcomes. | contract | `mix test test/lockspire/release_artifact_chain_contract_test.exs` | ✅ | ⬜ pending |
| 143-03-02 | 143-03 | 3 | REL-03 | T-143-05 | Receipt collection runs for unsuccessful or skipped publication and proof stages without Hex credentials. | contract | `mix test test/lockspire/release_workflow_artifact_contract_test.exs test/lockspire/release_artifact_chain_contract_test.exs` | ✅ | ⬜ pending |
| 143-03-03 | 143-03 | 3 | REL-03 | T-143-05 | Runbook explains public-presence truth, exact artifact retention, and safe same-artifact recovery. | contract | `mix test test/lockspire/release_workflow_artifact_contract_test.exs test/lockspire/release_artifact_chain_contract_test.exs` | ✅ | ⬜ pending |
| 143-04-01 | 143-04 | 4 | REL-01 | T-143-06 | Reviewed source PR passes local contributor gate and exact release regression contracts before opening. | contract | `mix ci` | ✅ | ⬜ pending |
| 143-04-02 | 143-04 | 4 | REL-01 | T-143-06 | Exact PR head has all required checks and review before merge authorization. | live proof | `gh pr checks --required && gh pr view --json state,baseRefName,headRefOid,mergeable,reviewDecision --jq 'select(.state == "OPEN" and .baseRefName == "main" and .mergeable == "MERGEABLE" and .reviewDecision == "APPROVED")' && test "$(gh pr view --json headRefOid --jq '.headRefOid')" = "$(git rev-parse HEAD)"` | ✅ | ⬜ pending |
| 143-04-03 | 143-04 | 4 | REL-01 | T-143-06 | Main acceptance receipt identifies synchronized current main and its matching CI/hygiene evidence, or records an explicit merge blocker. | contract + live proof | `jq -e --arg sha "$(git rev-parse origin/main)" '(.release_hardening_merge.status == "merged" and .source_sha == $sha and .canonical_ci.status == "pass" and .repository_hygiene.status == "pass" and .release_push.outcome == "no_publish") or (.release_hardening_merge.status == "blocked" and has("release_hardening_merge") and .release_hardening_merge.blocker != null and .release_hardening_merge.blocker != "")' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-MAIN-ACCEPTANCE.json` | ✅ | ⬜ pending |
| 143-05-01 | 143-05 | 5 | REL-01 | T-143-07 | Fresh candidate evidence binds current main, canonical CI, hygiene, release metadata, public state, and live controls. | live proof | `jq -e --arg sha "$(git rev-parse origin/main)" '.source_sha == $sha and .canonical_ci.status == "pass" and .repository_hygiene.status == "pass" and .live_controls.release_please_auto_merge == "disabled_manually" and .live_controls.release_automerge_opt_in == "unset" and .live_controls.phase143_authorized_sha == "unset" and .live_controls.hex_publish_approval == "required"' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json` | ✅ | ⬜ pending |
| 143-05-02 | 143-05 | 5 | REL-01, REL-02 | T-143-08 | Staging either proves the exact artifact/API/byte fixture before the decision or records terminal failure truth, clears the one-SHA guard, and writes a no-shipment result. | live proof | `if [ "$(jq -er '.staging_status' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" = "verified" ]; then python3 scripts/publish/release_artifact.py verify-local --tar release-input/lockspire-1.5.1.tar --manifest release-input/release-manifest.json --source-sha "$(jq -er '.source_sha' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" && jq -e '.runtime.hex == .runtime.publisher_hex' release-input/release-manifest.json && jq -e --arg hex "$(jq -er '.runtime.hex' release-input/release-manifest.json)" '.publisher_compatibility.hex_version == $hex and .publisher_compatibility.api_export == "passed" and .publisher_compatibility.exact_byte_fixture == "passed"' release-input/prepublish-receipt.json; else jq -e '.staging_status == "blocked" and .blocker != null and .blocker != "" and (.terminal_receipt_download.status == "passed" or (.terminal_receipt_download.status == "unknown" and .terminal_receipt_download.blocker != null and .terminal_receipt_download.blocker != ""))' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json && gh variable list --repo szTheory/lockspire --json name --jq '[.[] | .name] | index("LOCKSPIRE_PHASE143_AUTHORIZED_SHA") == null' && git diff --check -- .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`; verified path also confirms the protected publisher is waiting at `hex-publish` before the human decision. | ✅ | ⬜ pending |
| 143-05-03 | 143-05 | 5 | REL-01, REL-02 | T-143-08 | Maintainer authorizes or cancels only after comparing exact SHA, CI, manifest, tar, publisher API/byte-fixture evidence, and live state. | human gate | `gh run view "$(jq -er '.workflow_run_id' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" --json status,conclusion,jobs` | ✅ | ⬜ pending |
| 143-06-01 | 143-06 | 6 | REL-02, REL-03 | T-143-09 | Only the exact authorized deployment is approved/canceled, and its run-scoped terminal receipt is downloaded/identity-checked or explicitly recorded unknown. | live proof | `RUN_ID="$(jq -er '.workflow_run_id' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)"; SOURCE_SHA="$(jq -er '.source_sha' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)"; test "$(gh run view "$RUN_ID" --json status --jq '.status')" = completed; if [ "$(jq -er '.terminal_receipt_download.status' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" = passed ]; then gh run download "$RUN_ID" --name "lockspire-release-terminal-receipt-$RUN_ID" --dir .planning/phases/143-publish-and-verify-lockspire-1-5-1/receipt-download && jq -e --arg run "$RUN_ID" --arg sha "$SOURCE_SHA" '.workflow_run_id == $run and .source_sha == $sha' .planning/phases/143-publish-and-verify-lockspire-1-5-1/receipt-download/release-terminal-receipt.json; else jq -e '.terminal_receipt_download.status == "unknown" and .terminal_receipt_download.blocker != null and .terminal_receipt_download.blocker != ""' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json; fi` | ✅ | ⬜ pending |
| 143-06-02 | 143-06 | 6 | REL-02, REL-03 | T-143-10 | Public version and proof state are recorded accurately; milestone remains open when any gate is incomplete. | contract + live proof | `if [ "$(jq -er '.terminal_receipt_download.status' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" = "passed" ]; then jq -e --arg run "$(jq -er '.workflow_run_id' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" --arg sha "$(jq -er '.source_sha' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json)" '.workflow_run_id == $run and .source_sha == $sha and all(.stages[]; .status == "passed" or .status == "failed" or .status == "not_run" or .status == "unknown")' .planning/phases/143-publish-and-verify-lockspire-1-5-1/receipt-download/release-terminal-receipt.json; else jq -e '.terminal_receipt_download.status == "unknown" and .terminal_receipt_download.blocker != null and .terminal_receipt_download.blocker != ""' .planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CANDIDATE-RECEIPT.json; fi` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing release automation and ExUnit contract suites cover the phase. Extend the focused suites; no new framework or Wave 0 harness is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Plan/Task | Why Manual | Test Instructions |
|----------|-------------|------------|------------|-------------------|
| Confirm current `main`, matching CI and hygiene evidence, version metadata, public state, and live protected controls immediately before dispatch. | REL-01 | 143-05-01 | These are mutable remote repository facts that local tests cannot establish. | Capture the full source SHA and canonical CI run, repeat hygiene, inspect the `hex-publish` environment and authorization variable, and stop if any fact differs or cannot be read. |
| Confirm the protected run's Hex checksum, release/tag target, versioned docs, and public clean-room install. | REL-02 | 143-06-01, 143-06-02 | The evidence must come from live public services after the candidate artifact is published. | Query the exact Hex release and docs, resolve `refs/tags/lockspire-v1.5.1` to the source commit, and inspect the protected workflow's clean-room install result. |
| Record any partial outcome truthfully, including whether 1.5.1 is already public. | REL-03 | 143-03-02, 143-06-01, 143-06-02 | A failed workflow may still have changed public Hex state. | Inspect bounded per-stage receipt and live Hex state; report the blocker and next safe action, and leave milestone completion open unless every proof passes. |

---

## Prior-Phase Requirement Scope

The post-planning gap check also lists CI-09 and TRUTH-06 as uncovered in Phase 143. Both are complete under Phase 142 in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`; Phase 143 does not reopen them. Plan 143-05 still refreshes exact-main CI and hygiene evidence as prerequisites to REL-01.

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
