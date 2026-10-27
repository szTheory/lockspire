## OPEN_THREATS

Reviewer: Independent security auditor — GPT-6.1-Sol/xhigh; `/root/phase178_execution_workflow/review178_security`

Reviewed commit: 5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32

Date: 2026-10-27

Scope: Independent re-review of SEC-178-01 through SEC-178-10 and corrections after `9cc4c203263015effe0894e76550045b19edee8d`, including provisioning, review/source/package validators, candidate/handoff checks, shared diagnostics and process ownership. Final source, package, hosted CI and main observations remain unexecuted.

**ASVS Level:** 1
**Block on:** high
**Threats closed:** 25/37
**Threats open:** 12/37, all high
**Open non-blocking:** 0

### Findings

| Original finding | Disposition | Evidence |
|---|---|---|
| SEC-178-01 — incomplete freeze | **OPEN** | Expanded coverage and thirteen immutable pins help, but selected inputs remain omitted. |
| SEC-178-02 — review false acceptance | **OPEN** | Structured records reject explicitly open packet findings, but can contradict their preserved reports and omit relevant review scope. |
| SEC-178-03 — source acceptance | **OPEN** | Manifest/package checks were added, but the consumer rejects an actual successful guard-produced manifest. |
| SEC-178-04 — tracer-for-core substitution | **FIXED for original bypass** | Raw scope/case/count checks added at `verifier_delivery.py:535–550` and `clean_room_verifier_upgrade.py:616–620`. |
| SEC-178-05 — unsafe rollout/provenance | **OPEN** | Predecessor and major nested structures are constrained; `fleet_limits` remains unchecked and accepts sensitive nested content. |
| SEC-178-06 — nested-session ownership | **OPEN** | Both actual wrapper timeout and TERM probes left a registered, separately sessioned child alive. |
| SEC-178-07 — unknown diagnostic retention | **PARTIALLY FIXED; OPEN** | Production transaction/HTTP/log paths improved. The CI privacy test still renders unknown child output on assertion failure. |
| SEC-178-08 — dry-run commit witness | **FIXED at implementation depth** | Positive witness now performs top-level `:apply` and requires changed durable ciphertext plus committed audit. Fresh installed execution remains pending. |
| SEC-178-09 — final paths/identity | **OPEN** | `final-*` remains prohibited; exact old-runner equality still prevents the planned later-checkout reconciliation. |
| SEC-178-10 — clean CI/raw upload | **PARTIALLY FIXED; OPEN** | Provisioning and raw uploads were added, but provisioning produces an archive filename refused by its installer and conflicts with a retained frozen manifest. |

**SEC-178-01 — High, blocking: selected inputs still escape freezing.**

`verifier_delivery.py:57–178` still omits, among others:

- `scripts/ci/provision_verifier_candidate.py`
- `test/clean_room/provider_host/verifier_rollout.exs`
- `test/clean_room/provider_host/verifier_endpoints.exs`
- `lib/lockspire/oban.ex`
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`

The first three directly control provisioning or selected installed outcomes. The frozen owner verifies archived package files against the selected commit; that does not freeze current producer/fixture bytes or establish the complete current source-test closure.

All thirteen Phase 175 pinned inputs independently matched.

Remediation: establish the complete bounded package/build/proof/source-test dependency closure, including the new provisioner and selected fixture files. Add mutation controls against the actual freeze consumer.

**SEC-178-02 — High, blocking: green review packets can contradict blocking reports.**

At `verifier_delivery.py:622–711`, report bytes, reviewer and revision are checked. Classified findings come solely from the packet; the preserved report’s blocking disposition and declared scope are not reconciled.

An on-disk probe supplied reports explicitly stating `OPEN HIGH BLOCKER` and `OPEN_THREATS`, while packets said `accepted`, listed no findings and reviewed only `mix.exs`. The genuine validator accepted all three lanes.

Additionally, `_metadata_only_difference` at `:611–617` permits the original report filenames but excludes the required immutable-report successors, such as `178-SECURITY-REREVIEW.md`. Persisting genuine re-review evidence therefore falls outside its declared metadata reconciliation.

Remediation: bind authoritative structured review judgments to the report’s actual disposition and declared file scope. Require the relevant correction scope. Explicitly support immutable re-review records in metadata reconciliation. Do not permit a green packet to override an open report.

**SEC-178-03 — High, blocking: actual successful guard output cannot pass source acceptance.**

`_owned_source_manifest` requires `commands[-1].stage == "drop"` at `verifier_delivery.py:814–815`.

The actual guard’s cleanup performs:

1. `drop`
2. effective-config preflight
3. independent catalog absence verification

See `run_owned_source_tests.py:319–338`.

The auditor invoked the actual `OwnedSourceTests.run()` with only its OS/process/database boundary replaced by the existing stateful fake. It returned zero, recorded `cleanup=independently_absent`, and emitted a manifest ending in `catalog`. The unmodified source consumer rejected that emitted manifest at its final-command check.

Remediation: test producer and consumer together using actual `OwnedSourceTests.run()` output, mocking only OS/database boundaries. Validate ordered cleanup intent, drop and subsequent absence verification rather than demanding that drop be the last observation. Preserve actual stage captures and package binding.

**SEC-178-05 — High, blocking: unchecked rollout root field remains an unsafe receipt channel.**

The new predecessor pins and nested field checks address the original predecessor substitution. However, `validate_rollout_receipt` never validates the content or type of `fleet_limits`.

An in-memory probe placed an unknown sensitive field inside `fleet_limits`; validation succeeded. Those bytes remain eligible for validated copying and the expanded upload.

Remediation: validate every root value, including exact finite `fleet_limits` content and typed observation values. Reject unknown nested fields before copying or upload.

**SEC-178-06 — High, blocking: actual wrapper interrupts its supervisor before nested cleanup finishes.**

The wrapper’s stop routine allows two seconds before killing its scenario-runner group: `run_verifier_upgrade_proof.sh:188–204`.

Registered session cleanup waits three seconds per child, and some serving cleanup allows ten seconds: `package_input.py:162–192`, `verifier_rollout.py:447–452`. Consequently, the wrapper can kill the supervisor before it kills its separately sessioned children.

Controlled actual-wrapper probes used `start_owned_session`, with the registered child installing SIGTERM handling before readiness:

| Actual path | Wrapper exit | Registered child afterward |
|---|---:|---|
| Overall child timeout | 125 | Still alive |
| External TERM | 125 | Still alive |

Exit 125 truthfully preserves uncertainty; it does not complete descendant cleanup.

A separate syscall-boundary probe also reached **NameError**: `package_input.py:182–191` calls `time.monotonic()`/`time.sleep()` without importing `time`.

Remediation: coordinate the wrapper deadline with bounded cleanup of every registered session. Verify delayed termination and escalation through the actual wrapper, including separately sessioned descendants. Add the missing import and test that branch. Never convert uncertainty into success.

**SEC-178-07 — High, blocking: diagnostic fixes leave an unsafe test-failure rendering path.**

Transaction witness output now persists counts/digests rather than text. Rollout failures discard exception text, HTTP failures withhold bodies, and serving output is discarded. These are substantive corrections.

However, `client_verifier_ci_test.py` still uses assertions such as `assertNotIn(..., stdout + stderr)`. On failure, unittest renders the complete compared value. A controlled invocation of the existing privacy test confirmed that an unregistered child value entered its captured failure representation.

Remediation: privacy assertions must evaluate booleans and use fixed messages. Audit error/RED collection paths so failure formatting cannot reintroduce child output. Preserve the production hash/count approach.

**SEC-178-09 — High, blocking: authorized final paths remain rejected.**

`run_verifier_upgrade_proof.sh:56` still permits only `.artifacts/phase178/ci-$pair`. The exact authorized `final-locked` command again exited **2**, before mutation.

Line 72 still requires current HEAD to equal the expected frozen runner. The consumer does not implement the planned reconciliation of a preserved tested runner with a later metadata-only or synthetic checkout.

Remediation: support narrowly validated final/CI roots and explicit runner/candidate/executed-checkout relationships. Preserve freshness, symlink rejection and independently supplied pins.

**SEC-178-10 — High, blocking: provisioning output does not satisfy its downstream consumer.**

Provisioning now runs in both existing jobs, passes five explicit pins, and uploads validated raw copies alongside indexes. The seven-job structure remains intact.

But `provision_verifier_candidate.py:85` writes `lockspire.tar`. Frozen package preparation still calls `validate_local_tarball`, whose `package_input.py:587–589` contract requires `lockspire-<exact-version>.tar`. The produced archive will be rejected before installation.

Provisioning also calls `create_frozen_manifest` at the canonical phase path (`provision_verifier_candidate.py:112–119`). That function refuses an existing frozen manifest (`verifier_delivery.py:379–381`). A clean checkout containing the retained final manifest therefore cannot provision through this route.

Remediation: exercise actual provisioning output through real package-selection/input validation, with build/OS boundaries mocked where necessary. Preserve the retained manifest and create or materialize explicitly separate job-owned input records. Do not overwrite trusted source evidence.

The reported possible floor-job root-lock overwrite was **not confirmed**. The reviewed workflow has no explicit root `mix.lock` copy; provisioning precedes the separate compatibility-fixture steps. No unknown mutation is classified here.

**SEC-178-11 — High, blocking: new candidate validation accepts invented hosted evidence.**

Maps to T-178-31/T-178-32.

`verifier_delivery.py:942–1088` accepts local candidate/source/observation records and seven claimed jobs. Artifact “authentication” checks digest syntax and declared counts at `:1073–1085`; it never reads those artifact bytes. It also does not establish the claimed source acceptance through `_check_source`.

An independent on-disk probe used the actual reviewed Git commit and **all declared covered-input hashes**, but invented the run, seven job results and artifact digests. There were no actual package artifacts, guard manifest or hosted job observations. `check("candidate")` accepted it.

Remediation: require authoritative observed head/run/attempt ownership, validate actual preserved job observations and downloaded artifact bytes, rehash and semantically inspect their raw receipts, and bind genuine source acceptance. Negative tests for mixed values do not establish authenticity.

**SEC-178-12 — High, blocking: new accepted-main validation accepts a fabricated helper receipt.**

Maps to T-178-35.

`verifier_delivery.py:1120–1137` accepts a minimal helper-shaped JSON object containing three passing subobjects and an ancestor relationship. It does not establish helper execution, synchronized HEAD/local-main/refreshed-origin-main, complete same-head CI/release graphs, warning dispositions or integration authorization.

The on-disk candidate probe then supplied a locally invented minimal helper file. `check("handoff")` returned accepted-main without executing the helper or establishing synchronized main.

Remediation: validate preserved actual helper bytes and their independently observed execution/custody, complete schema, exact synchronized source, graph identities and warning dispositions. Bind accepted integration authorization and current candidate evidence. Explicitly pending integration must remain supported without granting main acceptance.

### Evidence and custody

The auditor performed:

- Actual wrapper timeout and TERM controls with registered, separately sessioned children.
- Actual `OwnedSourceTests.run()` producer-to-consumer control with OS/database execution mocked.
- On-disk review-packet contradiction, fabricated candidate/jobs/artifacts and fabricated helper controls.
- In-memory rollout-field, diagnostic/test-failure and missing-import controls.
- Repeated final-path rejection and thirteen immutable-input hash checks.

No source database, canonical CI, package build/producer, freeze or remote operation ran.

Only probe-owned temporary resources were created. The auditor killed the exact known surviving child sessions, stopped owned wrapper processes, and removed all probe temporary roots, including the guard’s generated manifest directory. No shared/development database, root archive, source file, initial report or peer report was changed.

Final observed HEAD remained `5adf46c1b6b304fcc99fdb9f0ab25194a62d8c32`. Untracked source/integration re-review reports were peer outputs.

### Threat disposition

All threats retain their original `mitigate` disposition.

Closed high threats: **T-178-01, 02, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 23, 26, 27, 33, SC**.

Closed medium threat: **T-178-22**.

These closures verify implementation mechanisms, incorporating the original report’s unchanged evidence and the corrections above. They do not certify fresh final runtime outcomes.

| Open threat | Category | Severity | Reason |
|---|---|---|---|
| T-178-03 | Information disclosure | high | SEC-178-07 test/RED failure rendering |
| T-178-21 | Information disclosure | high | SEC-178-05/07 unsafe receipt/test channels |
| T-178-24 | Tampering | high | SEC-178-06 nested-session cleanup |
| T-178-25 | Repudiation | high | SEC-178-09/10 final/CI producer-consumer gaps |
| T-178-28 | Repudiation | high | SEC-178-01/09 incomplete closure/reconciliation |
| T-178-29 | Repudiation | high | SEC-178-02/03 review/source acceptance |
| T-178-30 | Tampering | high | SEC-178-03/09 required gate execution blocked |
| T-178-31 | Repudiation | high | SEC-178-11 candidate authenticity bypass |
| T-178-32 | Repudiation | high | SEC-178-11 invented hosted graph/artifacts |
| T-178-34 | Tampering | high | SEC-178-06 surviving owned sessions |
| T-178-35 | Elevation of privilege | high | SEC-178-12 false accepted-main claim |
| T-178-36 | Repudiation | high | Final audit/flag/custody owner remains pending |

The four original later-owner IDs—31, 32, 35 and 36—still require actual observations. Three now also have demonstrated unsafe acceptance mechanisms; their findings arise from false acceptance, not merely from absent future observations.

### Disposition

**Rejected for freeze.** Correct the remaining producer/consumer and authenticity gaps, then obtain independent closure before final runtime execution.

Final freeze, guarded canonical CI, fresh successful locked/floor wrappers, strict 26-receipt composition, hosted candidate observation and main acceptance remain pending. Historical incidents and Phase 177 E-09/E-10/prohibition flags retain their original unresolved limits. No human approval, incident waiver or unchanged-development-data claim is made.

**threats_open: 12**
