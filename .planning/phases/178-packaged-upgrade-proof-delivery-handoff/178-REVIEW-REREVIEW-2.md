# Phase 178 Source Review — Second Re-review

Reviewer: gsd-code-reviewer / source lane (gpt-6-luna, high)
Reviewed commit: 5fcf93276b6ea9bfdffc37baac9e83a960a2f73c
Date: 2026-10-27
Scope: source and harness changes from 4bd35961944d3f70be0db2aadff9664b165264bb through 5fcf93276b6ea9bfdffc37baac9e83a960a2f73c, with rechecks against the initial and first re-review reports, current correction ledger, security re-review, integration re-review and wrapper debug journal. Focused call chains: bounded freeze/review scope, owned-source producer and consumer, package provisioner/input selector, raw receipt validators, hosted candidate observer, handoff helper, and wrapper process custody. No database, package producer/freeze, canonical CI, hosted API, or main acceptance run was performed.

Hashes below bind the reviewed primary files to the reviewed commit:

| File | SHA-256 |
|---|---|
| `.github/workflows/ci.yml` | `a0c73f5e2d579bed957c29b6229df293976bf78747c2907acfbc655990f74e45` |
| `scripts/acceptance/clean_room/verifier_delivery.py` | `fc25a7be656268b0a89bbadbc2a41f8cf46f3745500e8c5c080d5a26baa280c0` |
| `scripts/acceptance/clean_room/verifier_receipts.py` | `f49bf8b9cb0ccf271adfc4ccfe29b3e359bd5721dca8cb1b2f05784e1b94c5c0` |
| `scripts/acceptance/clean_room/package_input.py` | `46e37e16c6b948096d4b9156b88c8fe81cf9ec8f5e5074640b1243583fdfb57a` |
| `scripts/ci/provision_verifier_candidate.py` | `acef9944ebad1b315bb67f1813b95e51691b04ca052ad6e5f894883d4fc0d291` |
| `scripts/ci/run_owned_source_tests.py` | `3ede9dbc11db0615a353914d92e0cfe6aed2722a1ed1fac337d7466cccfb3c8a` |
| `scripts/ci/run_verifier_upgrade_proof.sh` | `48736201647e54cfc5d321bb78e2619509360de90411ac9aa32c0154736a5e59` |
| `scripts/maintainer/repo_hygiene_check.sh` | `9d5a40909a58ff14628947935ddd5c1ee371a5f1fdaf5bc8184da64caeff5042` |
| `scripts/acceptance/clean_room/build_provider.py` | `77540aac1bda1dceeba310b714e589a8401d1bcfc0d7b1557cd08d367799ba19` |
| `test/acceptance/client_verifier_delivery_test.py` | `e2ac77f9f10c52ad6e45f201ad4f0caa808eaf9e172628cd22b6be091f566ed6` |
| `test/acceptance/client_verifier_ci_test.py` | `30c1c6eebb57b63e192ea291fb02555a7710ac67de06ed62871d02518fd5380c` |
| `test/acceptance/client_verifier_wrapper_lifecycle_test.py` | `f7f7cd60cc10fc063ad2ba06998db390a235d27f6d2ecded2dde749c8f96c43b` |

## Findings

### BLOCKER SRC-02 — Frozen input set still omits changed proof inputs

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:58-160`

The checked bounded list now covers the provisioner and more verifier sources, but it still omits the selected host fixture `test/clean_room/provider_host/verifier_rollout.exs`, which `build_provider.py:68-69, 79-109` copies for both rollout and legacy-control proof groups. It also omits six implementation-changed test inputs from the same selected source/harness diff: `test/acceptance/client_lifetime_boundary_test.py`, `test/acceptance/client_verifier_ci_test.py`, `test/acceptance/client_verifier_recovery_test.py`, `test/acceptance/client_verifier_tracer_test.py`, and `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` (as well as the host fixture above). The host fixture directly changes the installed proof result; the missing changed contract tests also leave the test harness outside the manifest/review-required set. `MATRIX_FIXTURE_INPUTS` is discovered from the current filesystem at import time, so it does not replace an explicit list for the selected Elixir fixture or the omitted changed test files.

**Impact:** Frozen validation and `REVIEW_REQUIRED_FILES` can pass without binding all changed inputs that control or guard the promised proof.

**Fix:** Add the selected rollout fixture and all changed in-scope contract tests to the explicit bounded list. Add a closure regression that compares selected fixture/producer dependencies and changed source/test scope against the required set; keep the 13 immutable Phase 175 pins unchanged.

### BLOCKER SRC-04 — Review acceptance still permits report contradiction and blocks immutable re-review applicability

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:654-675, 730-747`

The new parser compares the packet with one fenced JSON judgment record, but it never reconciles that record with the rest of the preserved report. I ran a safe temporary-file probe containing all current required source hashes and three distinct lane identities; each report body stated that an open blocker remained while its embedded record said `accepted` with no findings. `validate_reviews` returned successfully for all three lanes. This is a reproducible false-green review packet.

Separately, `_metadata_only_difference` permits only the original `178-REVIEW.md`, `178-SECURITY.md`, and `178-INTEGRATION.md` reports. It excludes the immutable `178-*-REREVIEW*.md` reports now required by the workflow. Committing the new review judgment and packet after the implementation commit therefore makes the reviewed-to-implementation revision difference fail the metadata-only check.

**Fix:** Reconcile the structured judgment against the report's actual disposition and finding sections; reject a report with an open blocker even when its JSON block claims acceptance. Extend the metadata allowlist to the exact approved immutable re-review artifacts and packet, without allowing arbitrary `.planning` changes.

### BLOCKER SEC-178-05 — Legacy-control receipts accept arbitrary `fleet_limits`

**File:** `scripts/acceptance/clean_room/verifier_receipts.py:406-414, 440-500`

The exact `fleet_limits` check is nested under `expected_scope == "rollout"`. The `legacy-control` branch validates its predecessor, source proof, observations and process roles, but does not constrain the required root `fleet_limits` field. An in-memory mutation of the portable legacy-control fixture to replace that field with an arbitrary object was accepted by `validate_rollout_receipt`. That raw receipt can then pass into validated package/index and artifact handling.

**Fix:** Validate `fleet_limits` for every rollout-schema receipt before branching on scope; use one exact finite value or an exact scope-specific schema and reject all unknown nested content.

### BLOCKER SEC-178-06 — A child can register and terminate a process group it does not own

**File:** `scripts/ci/run_verifier_upgrade_proof.sh:174-193, 206-224, 252-275`; `scripts/acceptance/clean_room/package_input.py:42-61, 72-105`

The wrapper passes a writable private registry path to the scenario runner and descendants through `LOCKSPIRE_OWNED_SESSION_REGISTRY`. `registered_groups()` checks only JSON shape and positive numeric PIDs; it does not verify that a registered group was launched by the owned runner or that `parent_pid` is in its process ancestry. Any same-user scenario child can write an arbitrary process-group ID into this directory, after which wrapper cleanup sends it TERM/KILL.

I probed the actual test-mode wrapper with a separately sessioned test-owned sibling process, outside the wrapper process tree. A fake scenario child wrote that sibling's PID into the inherited registry. The wrapper killed the sibling while returning 125 because it could not confirm group absence. The target was created solely for this probe and was reaped; no shared or development process was touched. Exit 125 is honest about cleanup uncertainty, but it does not undo the signal already sent to an unrelated group.

**Fix:** Keep the registry writable only by a trusted session supervisor and accept registrations through a bounded IPC channel tied to launched child identities. Before signalling, verify process/session ownership using authoritative OS identity and retain custody on uncertainty; do not accept caller-authored PID rows as proof of ownership.

### BLOCKER SEC-178-12 — Accepted-main graphs remain self-asserted

**File:** `scripts/acceptance/clean_room/verifier_delivery.py:1406-1461, 1475-1513`

The handoff validator checks synchronized local refs, a helper source hash, structured warning/authorization fields and the shape/consistency of required CI and release graphs. `_validate_helper_graph` does not query GitHub or otherwise authenticate its run IDs, job IDs, attempts, statuses or conclusions. A complete-looking receipt can therefore claim passing main/release graphs without the helper's read-only GitHub observations. The candidate path now performs authoritative API and artifact-byte checks, but the accepted-main graph path does not.

**Fix:** Authenticate each required/release run and job graph through read-only GitHub observations, matching repository, workflow, SHA, event, run attempt, exact job IDs/statuses and release no-publish state to the helper receipt. Bind the authorization bytes and helper execution capture to those observations. Keep `pending` as the only accepted result until this evidence exists.

## Rechecked Findings and limits

| Prior finding | Disposition | Evidence and limit |
|---|---|---|
| SRC-01 independent pins and actual frozen selection | **Resolved at code level** | Wrapper consumes the selected job-owned manifest, supplies five independent pins, checks current manifest and safe receipt paths; the retained canonical manifest is not overwritten by provisioning. No actual package run was done. |
| SRC-02 bounded closure | **Open** | Missing direct selected host fixture and changed test inputs listed above. |
| SRC-03 candidate artifact authenticity | **Resolved at mechanism level; runtime pending** | `_check_candidate` now observes the exact run/attempt, seven API job records and run artifacts; it verifies downloaded ZIP SHA-256 and parses exact raw index/receipt bytes. No GitHub API or actual artifact was accessed in this review. |
| SRC-04 independent review | **Open** | Required file binding and packet/report JSON equality were added, but narrative contradictions pass and immutable re-review metadata is not applicable. |
| SRC-05 guarded source acceptance | **Resolved for the mocked boundary** | Personally ran `client_verifier_delivery_test.py -k actual_owned_source_runner_manifest_is_consumed_with_cleanup_order`: 1 passed. This exercises actual `OwnedSourceTests.run()` and consumer with OS/database boundaries faked; no live database command ran. |
| SRC-06 checked Git blob ownership | **Resolved at code level** | Frozen manifest create and validate now check each `git show` return code; selected package owner verification also checks command success. |
| SEC-178-06 wrapper deadline/final-path regressions | **Original timing/path corrections present; new registry ownership defect open** | Wrapper has longer bounded drain, group reaping, explicit final paths and frozen-check delegation. The injected registry probe above demonstrates a separate kill-authority defect. |
| SEC-178-07 private diagnostics | **Rechecked; no new blocker found** | CI privacy assertions now use boolean expressions with fixed messages; guard/receipt paths retain digests/counts rather than raw output. No raw tails were printed. |
| SEC-178-08 mutating witness | **Resolved at implementation level** | Positive apply path and separate non-mutation control are in the current transaction witness. No database execution was performed. |
| SEC-178-09 final checkout relation | **Resolved at mechanism level** | Wrapper permits only exact `ci-*`/`final-*` locations and delegates runner/current-checkout ancestry plus covered-byte validation. No actual final wrapper was run. |
| SEC-178-10 provisioning producer/consumer | **Resolved at mechanism level** | Provisioner now emits versioned archive and separate job-owned manifest selected by wrapper; contract test mocks OS/package build only. No real package build was run. |
| SEC-178-11 candidate authenticity | **Resolved at mechanism level** | Candidate check reads authoritative run/attempt/jobs/artifact metadata and validates downloaded ZIP bytes. Hosted observations remain pending. |
| SEC-178-12 main/helper provenance | **Open** | Accepted-main graph fields are structurally checked but not independently observed against GitHub. |
| Integration floor lock warning | **Not confirmed as a defect** | Current workflow has no root `mix.lock` copy/overwrite; package source and root lock bytes are part of the source-bound input. No floor runtime was run. |

## Verification performed

- Owned-source producer/consumer contract test: 1 passed; OS/database boundary was mocked.
- Report-contradiction probe: all three lanes were accepted despite an open-blocker narrative and an accepted empty JSON judgment (`report_text_blocker_contradiction_accepted=true`). Required source-file hashes were supplied.
- Legacy-control receipt probe: arbitrary object in `fleet_limits` accepted (`legacy_control_unknown_fleet_limits_accepted=true`).
- Wrapper PID-custody probe: exact test-owned external process group was killed through the inherited registry; wrapper returned 125 and the test-owned process was reaped.
- No database, package producer/freeze, canonical CI, GitHub API, hosted run, or main acceptance operation was performed. The orchestrator reports a clean 213-test Python gate; I did not rerun that full gate.

## Independent source-lane judgment

Verdict: **rejected for freeze**. Open blockers: SRC-02, SRC-04, SEC-178-05, SEC-178-06, SEC-178-12. This report is an independent source judgment, not final package, hosted CI, or main-acceptance evidence. The combined packet must bind this report's final SHA-256 after commit.
