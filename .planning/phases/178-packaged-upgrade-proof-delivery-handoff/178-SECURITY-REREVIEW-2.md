## OPEN_THREATS

Reviewer: Independent security auditor — GPT-6.1-Sol/xhigh; `/root/phase178_execution_workflow/review178_security`

Reviewed commit: 5fcf93276b6ea9bfdffc37baac9e83a960a2f73c

Date: 2026-10-27

Scope: Second independent re-review of SEC-178-01–12, corrections after `5adf46c1`, the wrapper lifecycle journal, provisioning and source producer/consumer contracts, downloaded artifact validation, and helper/handoff validation.

**ASVS Level:** 1
**Block on:** high
**Threats closed at implementation depth:** 30/37
**Threats open:** 7/37, all high
**Open non-blocking:** 0

### Findings

| Finding | Disposition | Re-review result |
|---|---|---|
| SEC-178-01 | **OPEN — blocking** | The bounded input list still omits selected shipped, fixture and source-test dependencies. |
| SEC-178-02 | **Original false-accept mechanism fixed** | Packet judgments must match an embedded reviewer judgment; required file coverage, duplicate paths and finding-file coverage are checked. Coverage remains dependent on SEC-178-01’s incomplete required set. |
| SEC-178-03 | **Fixed at implementation depth** | Actual guard-produced successful manifest now passes its consumer, including post-drop preflight/catalog verification. |
| SEC-178-04 | **Fixed at implementation depth** | Raw schema/scope/case/count binding remains enforced before matrix acceptance. |
| SEC-178-05 | **OPEN — blocking** | Unsafe values remain accepted inside known rollout/public fields. |
| SEC-178-06 | **Fixed at tested ownership boundary** | Six independently rerun actual-wrapper/escalation controls passed, including delayed TERM, multiple sessions and denial custody. |
| SEC-178-07 | **Original diagnostic/failure-rendering mechanism fixed** | Production diagnostics retain fixed facts or hashes; the previously demonstrated privacy assertions now use boolean checks and fixed messages. |
| SEC-178-08 | **Fixed at implementation depth** | Mutating apply, changed durable ciphertext and committed audit remain required. Fresh installed execution is pending. |
| SEC-178-09 | **Wrapper restrictions fixed** | Narrow final/CI paths are allowed; frozen validation compares preserved runner and executed checkout ancestry/covered blobs instead of requiring identical HEAD. Hosted identity consumption still has SEC-178-11 gaps. |
| SEC-178-10 | **Original provisioning incompatibilities fixed** | Actual provisioner output feeds real package selection with a versioned archive and separate job-owned manifest; canonical evidence remains preserved. |
| SEC-178-11 | **OPEN — blocking** | Genuine upload contents are rejected, while a substituted raw candidate archive is accepted. |
| SEC-178-12 | **OPEN — blocking** | Helper consumer contracts disagree with actual helper output; remaining helper graph authentication is insufficiently demonstrated. |

**SEC-178-01 — High: freeze/review scope remains incomplete.**

Confirmed omissions from `verifier_delivery.py:58–195` include:

- `test/clean_room/provider_host/verifier_rollout.exs`
- `lib/lockspire/storage/ecto/repository/client_store.ex`
- `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex`
- `lib/lockspire/domain/client.ex`
- `test/support/delegated_verifier_maintenance_store.ex`
- `test/acceptance/client_verifier_ci_test.py`
- `test/acceptance/client_verifier_recovery_test.py`

These are selected behavior, safety or verification inputs. Adding earlier examples and the 26 receipt fixtures does not establish complete closure.

Remediation: define a finite rule over the **reviewed commit’s tracked tree**, then persist and validate its exact resulting path set and hashes. Include:

- All shipped `lib`, `config`, `priv` and package/build inputs, including applicable root dotfiles.
- Every canonical source-CI test/support dependency.
- Actual selected acceptance producers and their repository-owned imports, commands, templates, fixtures and locks.
- Applicable workflow/action files and maintainer helper dependencies.
- The thirteen immutable Phase 175 inputs.

Use the same rules at freeze and consumption. Reject missing, extra, changed or uncommitted selected inputs. This requires current-tree enumeration and explicit dependency rules, not history scanning or another list of handpicked omissions.

**SEC-178-05 — High: known fields still accept unsafe nested values.**

`validate_rollout_receipt` now constrains rollout `fleet_limits`, but does not close every value channel.

Actual validator probes accepted:

- A nested sensitive object in `observations.candidate_dedicated_activation_pid` for rollout.
- A nested sensitive object in `fleet_limits` for `legacy-control`.

The first field appears in the finite observation key set but lacks the required scalar/PID type validation. The second is constrained only in the rollout branch. These accepted bytes remain eligible for copying/upload.

Remediation: validate the complete typed value contract for every root and nested field in both schemas, including fixed strings, nullable fields, positive process IDs and their required relationships. Test wrong scalar types and sensitive values inside existing fields, not only insertion of unknown keys.

**SEC-178-11 — High: the downloaded artifact consumer disagrees with its producer and misses candidate substitution.**

At `verifier_delivery.py:1197–1234`, the ZIP consumer expects only its index and flattened receipt files.

The actual wrapper additionally produces `raw-copies.json` and `raw/*`, and the workflow uploads `validated/**`. The auditor ran the **actual wrapper postvalidation copy section** against output from the real pair validator, then zipped that exact upload tree. The copy section exited zero; `_artifact_zip_pair` rejected the resulting ZIP.

A separate probe changed a valid raw core receipt’s candidate archive digest and recomputed its receipt digest/self-binding. The index retained the original frozen candidate tuple. `_artifact_zip_pair` accepted it. The function checks the indexed candidate tuple, but does not compare the raw candidate tuple to that authenticated owner before acceptance.

Remediation: consume the actual producer’s exact upload format. Bind each raw receipt’s runner, candidate source/archive/tree, owner proof, host lock and compiled identity to the authenticated owner and indexed cell. Verify actual package/archive bytes and Git ownership rather than trusting mutually consistent claims.

The candidate-identity-only path also remains based on local claimed observations; authoritative GitHub queries occur in the later candidate path. Its narrower result must not be represented as authenticated hosted identity without the required observation-owner binding.

**SEC-178-12 — High: actual helper output cannot satisfy the handoff consumer.**

The helper’s real `validate_required_ci_jobs` and release validation sort jobs alphabetically:

- `repo_hygiene_check.sh:461`
- `repo_hygiene_check.sh:490`

`_validate_helper_graph` instead zips them against a different fixed order at `verifier_delivery.py:1475–1512`. Both alphabetically sorted CI and Release graphs were independently rejected.

There is also an exact-schema mismatch: the helper emits `release_no_publish.outcome`, while `_validate_helper_graph`’s exact field set excludes `outcome`.

The added emitter test seeds job arrays directly in the consumer’s preferred order and inspects emitted fields; it does not feed actual collected helper output into the handoff consumer. Thus its passing result does not close this producer/consumer gap.

The helper’s own new-main CI/Release graph validation also remains structural in this consumer. Authentication of the candidate’s hosted graph does not by itself authenticate separate claimed main/helper workflow IDs.

Remediation: consume actual helper-produced bytes, preserve its documented fields, and compare complete job sets by stable identity rather than incidental array order. Bind the helper’s own run/attempt/ref/graph and execution custody to authoritative observations, including emitted warning dispositions and integration authorization.

### Required correction contract

Use one actual producer-to-consumer contract chain:

`OwnedSourceTests.run → source gate → pair validator file tree → ZIP of exact validated/** → candidate identity/graph checks → actual helper producer → handoff consumer`.

Fake only external OS/build/database/GitHub boundaries. Do not replace higher-level results, shrink the declared input closure, manually reorder jobs, or construct a ZIP different from the uploaded tree. Include wrong-type/sensitive mutations of known fields and authenticated candidate archive/tree substitution controls.

### Evidence

Independently executed in this re-review:

- **Six actual-wrapper/escalation controls: 6 passed, 0 failures, 0 errors.** These cover delayed TERM-ignoring sessions, external TERM with two registered sessions, timeout, denial custody, escalation/reaping and invalid registry rejection.
- **Two actual producer/consumer controls: 2 passed, 0 failures, 0 errors.** Actual guard emission feeds its consumer; actual provisioner output feeds package selection with OS build/unpack boundaries stubbed.
- Actual wrapper postvalidation copy section: exit zero; its exact uploaded file tree was rejected by the ZIP consumer.
- Raw candidate archive substitution: accepted by the ZIP consumer.
- Unsafe rollout/public known-field values: accepted.
- Actual-producer alphabetical CI and Release job graphs: rejected.
- Thirteen immutable Phase 175 inputs: all matched.
- Reviewed source/test/workflow diff whitespace check: passed.

The orchestrator separately reported 213 Python tests passing. That result was not substituted for the independent probes. Its temporary capture-handling deviation remains recorded; this auditor did not inspect that raw capture or infer absence of exposure.

### Threat disposition

All threats retain `mitigate`; no risk acceptance or transfer closes a gap.

Open threats:

| Threat | Category | Severity | Reason |
|---|---|---|---|
| T-178-21 | Information disclosure | high | SEC-178-05 accepted unsafe receipt values |
| T-178-25 | Repudiation | high | SEC-178-11 hosted artifact producer/consumer mismatch |
| T-178-28 | Repudiation | high | SEC-178-01 incomplete frozen input closure |
| T-178-31 | Repudiation | high | Candidate identity observation-owner binding remains incomplete |
| T-178-32 | Repudiation | high | SEC-178-11 raw candidate substitution and hosted artifact validation |
| T-178-35 | Elevation of privilege | high | SEC-178-12 helper/main acceptance boundary |
| T-178-36 | Repudiation | high | Actual final audit/flag/custody owner remains pending |

The other **30 declared threats** are closed at mitigation-presence depth, including medium T-178-22. This incorporates unchanged evidence from the prior reports and the independently verified corrections above.

### Limits and custody

No actual database, freeze, canonical CI, package producer, hosted workflow or main acceptance ran. No remote mutation occurred.

All auditor probe output and failure representations remained private. Temporary fixture archives, local fixture repositories and manifests were removed. The custody-aware lifecycle controls verified absence of their exact owned groups and removed their exact temporary roots/registries. No uncertain auditor-owned resource remains.

The historical EPERM reconciliation, prior secret/database incidents, wrapper failures and unresolved Phase 177 flags remain separate preserved records. They are not erased or converted into acceptance.

Delivery corrections missed qualified native pre-edit RED evidence. A later historical-source false-green reproduction is not qualified original RED; this workflow limitation remains visible.

### Disposition

**Rejected for freeze.** Resolve SEC-178-01, 05, 11 and 12 through the actual end-to-end producer/consumer chain, then obtain independent closure. Fresh final source/package runs and later hosted/main observations remain with their assigned owners.

**threats_open: 7**
