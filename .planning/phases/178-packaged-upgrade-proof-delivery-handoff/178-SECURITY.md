## OPEN_THREATS

Reviewer: Independent security auditor — GPT-6.1-Sol, typed dispatch `xhigh`; canonical identity `/root/phase178_execution_workflow/review178_security`.

Reviewed commit: `9cc4c203263015effe0894e76550045b19edee8d`

Implementation base: `4bd35961944d3f70be0db2aadff9664b165264bb`

Date: 2026-10-27

Scope: Phase 178 Plan 10 pre-freeze implementation and evidence-control audit. All twelve plan threat registers and summaries 01–09 were read. This is ASVS Level 1 mitigation verification, with focused adversarial probes of the declared acceptance boundaries. It does not claim fresh frozen package, canonical contributor, hosted candidate, integration, or accepted-main proof.

**ASVS Level:** 1  
**Block on:** high  
**Distinct threats:** 37; all use `mitigate`.  
**Closed at implementation-presence depth:** 21  
**Open:** 16 high; 12 affected by concrete implementation findings and four awaiting later delivery owners.  
**Open non-blocking:** 0

### Findings

Every finding below remains **OPEN — BLOCKER**. No accepted-risk waiver closes it.

**SEC-178-01 — High: frozen coverage omits inputs that determine selected outcomes.**  
Maps to T-178-28.

`verifier_delivery.py:35–64` omits all library source, `mix.exs`, root `mix.lock`, source configuration, `build_provider.py`, group producers, selected host fixtures, redaction/runtime helpers, and the floor lock. It also includes Phase 175’s final-source record without rehashing its thirteen referenced inputs during frozen validation.

`validate_frozen_manifest` checks only that incomplete list. Editing an omitted recovery fixture or producer after freeze therefore leaves the frozen check satisfied. Rebuilding the candidate package does not cover these external proof inputs.

Remediation: derive and freeze the bounded closure of selected package, source-test, host-template, lock, producer, helper, workflow and acceptance inputs. Reject changed selected bytes before execution and acceptance. Preserve explicit reconciliation for later metadata-only commits.

**SEC-178-02 — High: review validation accepts explicit blocking findings and an unrelated reviewed commit.**  
Maps to T-178-29.

`verifier_delivery.py:438–458` checks headings, lane words and date syntax. It does not inspect verdict, severity, unresolved findings, reviewed commit, or applicable input identity.

An in-memory probe supplied all three lanes with an unbound commit and explicit `OPEN HIGH BLOCKER; phase must not ship` / `OPEN_THREATS` text. `validate_reviews` accepted them.

Remediation: validate attributable review identity and scope, bind the reviewed source/input relationship, and explicitly reject unresolved blocking findings. Markdown structure must remain an integrity check.

**SEC-178-03 — High: source acceptance can be asserted without underlying execution evidence.**  
Maps to T-178-29 and T-178-30.

`verifier_delivery.py:509–531` accepts caller-supplied counts and hash-shaped strings. It reads no owned-source manifest or underlying output, requires no canonical stage set, verifies no cleanup/source observation, and does not require complete package acceptance.

An isolated in-memory probe accepted one claimed passing test with an arbitrary digest and no guard manifest, raw evidence or package proof.

Remediation: validate preserved guard evidence and its digest, actual command/stage outcomes, nonzero canonical stage coverage, tested inputs and cleanup. Require the strict package result before granting combined source acceptance. Sensitive output may remain private; invented digest strings cannot establish its existence.

**SEC-178-04 — High: composition accepts the wrong raw scope as a required cell.**  
Maps to T-178-02, T-178-23 and T-178-30.

`verifier_delivery.py:384–400` validates ordinary receipts by pair/store but never binds their actual scope and case IDs to the indexed scope. `_validate_pair_directory` similarly manufactures expected scope/case labels at `clean_room_verifier_upgrade.py:644–651`.

An in-memory composition replaced required `core/locked/builtin` evidence with a valid tracer receipt. The genuine validators accepted it and reported **64 passing cases**.

Remediation: require exact raw schema, scope, pair, store, stable cases and executed count for each expected cell before constructing index labels. Reject unindexed unexpected receipt cells and duplicate JSON keys consistently.

**SEC-178-05 — High: rollout validation neither authenticates predecessor identity nor enforces safe nested fields.**  
Maps to T-178-07 and T-178-21.

`verifier_receipts.py:303–383` checks candidate fields and selected rollout booleans, but does not validate the rollout predecessor/source-proof binding or exact nested field sets.

An in-memory mutation replaced the predecessor with an unproven candidate-substitution object and added a `client_secret` field to observations. Validation succeeded. Pair validation subsequently copies such accepted raw bytes into its `validated` directory.

Remediation: enforce exact, typed nested schemas and expected predecessor/public identities, including their archive/tree/source proofs and process bindings. Reject extra sensitive fields before declaring receipt bytes safe.

**SEC-178-06 — High: wrapper teardown does not own nested sessions.**  
Maps to T-178-24 and T-178-34.

The wrapper launches the scenario runner in a new session at `run_verifier_upgrade_proof.sh:204–205` and stops that process group. Scenario helpers and serving hosts create additional sessions, including `package_input.py:141` and `verifier_core.py:138–145`. Default SIGTERM termination of the outer Python runner does not execute its cleanup blocks.

A controlled probe showed `stop_process_group` reporting success while an owned descendant launched with `start_new_session=True` remained alive. The auditor then killed the exact probe-owned sessions.

Remediation: propagate interruption through an explicit owner that stops and verifies every registered child session, or retain children within the supervised group. Do not report confirmed cleanup from parent-group absence alone. Preserve exit 125 when cleanup is uncertain.

**SEC-178-07 — High: transaction proof persists unregistered child material as “redacted” diagnostics.**  
Maps to T-178-03 and T-178-21.

`verifier_transactions.py:179–184` writes a tail of complete child output into `host-output.log`; `:146–151` similarly retains exception text. That redactor registers the outer encryption key and database URL at `:73–74`, while `_mix_env` generates additional verifier keys independently. Child-generated material can also be unknown to the parent.

An in-memory forced-failure probe confirmed an unregistered child marker reached the durable-write boundary. The write was intercepted; no diagnostic file was created.

Remediation: retain fixed reason categories, counts and hashes instead of diagnostic text. Where structured private handoffs carry required credentials, register them before processing other channels and never render those handoffs as evidence. Top-level fixed-error handling does not sanitize an earlier durable write.

**SEC-178-08 — High: installed commit-order witness uses a non-mutating dry run.**  
Maps to T-178-15.

`verifier_transactions.ex:196–217` correctly exercises nested-report rejection, but its positive `success_report_after_commit` observation comes from `run(mode: :dry_run)` at line 208. There is no selected mutating outer commit in that observation.

Remediation: witness a real successful selected mutation and its commit boundary, then assert the report/event ordering. Retain dry-run and nested rejection as separate controls.

**SEC-178-09 — High: final wrapper paths and runner identity rules contradict the authorized final sequence.**  
Maps to T-178-25, T-178-28 and T-178-30.

The amended Plan 10 and delivery defaults use `final-locked` / `final-floor`; `run_verifier_upgrade_proof.sh:45–46` permits only `ci-$pair`. A privately captured invocation of the exact final-locked command exited **2** before mutation.

Line 82 also requires frozen runner SHA to equal current HEAD. That rejects a later evidence-only commit or normal synthetic merge checkout despite the explicit covered-byte reconciliation policy.

Remediation: support narrowly validated final and CI destinations, retaining freshness and symlink checks. Distinguish executed runner, candidate source and later checkout identities through explicit covered-input relationships.

**SEC-178-10 — High: clean hosted jobs cannot reconstruct the required frozen inputs or independently inspect uploaded raw receipts.**  
Maps to T-178-25 and T-178-32.

The wrapper now requires frozen validation, which requires archive and extracted-tree paths under ignored `.artifacts/phase178`. The existing locked/floor jobs neither construct nor download those inputs before invoking it.

The uploads at `ci.yml:293` and `:407` include only `validated/index.json`, omitting the raw receipt copies required to independently verify the index’s claimed outcomes and digests.

Remediation: materialize and authenticate the frozen package inputs in each clean job, reconcile its actual checkout identity, and upload the exact safe validated raw receipts alongside the index. First tighten rollout safety validation described above.

### Evidence

Auditor execution was limited to read-only inspection and seven controlled probes:

| Probe | Observed result |
|---|---|
| Explicit high blocker / unrelated review commit | Accepted |
| Claimed one-test source record without underlying evidence | Accepted |
| Tracer substituted for required core receipt | Composition accepted; claimed 64 cases |
| Unproven predecessor and extra sensitive rollout field | Accepted |
| Nested owned session during parent-group teardown | Survived reported successful teardown |
| Exact authorized final-locked wrapper path | Exit 2 before mutation |
| Unregistered child material at transaction-log boundary | Reached intercepted durable write |

Additional checks:

- Independently rehashed all **13 Phase 175 frozen inputs**: all matched.
- Parsed five relevant Python files with `ast.parse`: no syntax failures.
- Confirmed **37 distinct threat IDs**, valid severities and mitigation dispositions.
- Confirmed no root `mix.exs` / `mix.lock` dependency delta.
- `git diff --check` reported existing added blank lines at EOF in three Python files; these are not security findings.
- Final observed HEAD remained `9cc4c203263015effe0894e76550045b19edee8d`.

No source database command, canonical CI, installed package producer, remote write, branch, worktree or persistent audit artifact was created. No raw child diagnostics or sensitive marker values were emitted. Concurrent untracked source/integration reports belong to the peer reviewers.

### Threat mitigation map

“CLOSED” below means the declared implementation mechanism was found. It does **not** grant fresh final runtime acceptance.

| Threat ID | Category | Severity | Disposition | Status and evidence |
|---|---|---|---|---|
| T-178-01 | Tampering | high | mitigate | CLOSED, bounded frozen path: `verifier_delivery.py:118,140,247,310` checks Git blobs, rebuilds source package and verifies archive/tree; `package_input.py:525` selects frozen candidates. |
| T-178-02 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-04; raw scope is not bound to indexed scope. |
| T-178-03 | Information disclosure | high | mitigate | OPEN-blocking — SEC-178-07; unregistered child material can be retained. |
| T-178-04 | Elevation of privilege | high | mitigate | CLOSED: `lifetime_client_store.ex:80,106,137`; exact declaration modes and callback witnesses; `verifier_core.py:215–219` requires pre-access rejection. |
| T-178-05 | Tampering | high | mitigate | CLOSED: separate installed task calls and typed outcomes in `verifier_core.py:251–267`; fresh-check/unknown/partial validation in `verifier_receipts.py:597`. |
| T-178-06 | Information disclosure | high | mitigate | CLOSED for declared maintenance CLI mechanism: `verifier_core.py:333–346` and finite core receipt schema. Wider diagnostic gap remains under T-178-03/21. |
| T-178-07 | Tampering | high | mitigate | OPEN-blocking — SEC-178-05. Producers contain independent predecessor/public checks at `verifier_rollout.py:87,559`, but the receipt acceptance boundary does not require the predecessor binding. |
| T-178-08 | Tampering | high | mitigate | CLOSED: `verifier_rollout.py:190–242` retains legacy overlap, observed drain, dedicated activation and isolated old-code rejection. |
| T-178-09 | Repudiation | high | mitigate | CLOSED: locked/builtin public-control restriction at `verifier_rollout.py:64`; separate scope/provenance and immutable attempt identities. |
| T-178-10 | Spoofing | high | mitigate | CLOSED: `verifier_endpoints.py:374–418` invokes mounted HTTP, negative assertion controls and lifecycle observations; strict endpoint facts required by `verifier_receipts.py`. |
| T-178-11 | Elevation of privilege | high | mitigate | CLOSED: actual PAR request and both FAPI controls at `verifier_endpoints.py:390–396`; required exclusion fields are validated. |
| T-178-12 | Repudiation | high | mitigate | CLOSED: `verifier_endpoints.py:126–186` assembles/boots a release, invokes RPC and checks loaded module location/digest. |
| T-178-13 | Tampering | high | mitigate | CLOSED: `verifier_transactions.ex:293,327` uses in-transaction backend IDs and actual `pg_blocking_pids`; both lock-order paths inspect durable rows. |
| T-178-14 | Tampering | high | mitigate | CLOSED: `verifier_transactions.ex:147–169,343–345` reaches valid audit INSERT failure using a sequence witness, then compares ciphertext/audit state. |
| T-178-15 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-08; dry-run cannot witness mutating commit/report ordering. |
| T-178-16 | Tampering | high | mitigate | CLOSED: `verifier_recovery.ex:44–48,547–556,618` compares protected fields and authenticated age metadata. Exact arithmetic remains with retained source owners. |
| T-178-17 | Tampering | high | mitigate | CLOSED: recovery repeat, interruption and indeterminate reconciliation mechanisms at `verifier_recovery.ex:59–69`; finite recovery outcomes required. |
| T-178-18 | Elevation of privilege | high | mitigate | CLOSED: `verifier_recovery.ex:102–208` correlates mounted HTTP/JTI and pre-guard barriers, independent maintenance, durable effects and replay/fresh controls. |
| T-178-19 | Spoofing | high | mitigate | CLOSED: separate restore/rotation controls in recovery producer/fixture; `verifier_recovery.py:75–89` requires distinct HTTP consequences. |
| T-178-20 | Information disclosure | high | mitigate | CLOSED for representative disclosure mechanism: `verifier_disclosure.py:121–146,395–441,565–595` registers keys/private handoffs before decoding captured channels; finite capture contracts require nonzero witnesses. |
| T-178-21 | Information disclosure | high | mitigate | OPEN-blocking — SEC-178-05/07; unsafe nested fields and unknown diagnostic material bypass evidence safety. |
| T-178-22 | Repudiation | medium | mitigate | CLOSED: explicit host/server instrumentation limits in guidance and Plan 07 record; no broader logging certification claimed. |
| T-178-23 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-04; indexed case labels can overstate actual raw scope. |
| T-178-24 | Tampering | high | mitigate | OPEN-blocking — SEC-178-06; nested sessions escape wrapper-group cleanup. Argument/fake-mode checks exist. |
| T-178-25 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-09/10; final path, checkout reconciliation and clean CI input/artifact gaps. |
| T-178-26 | Elevation of privilege | high | mitigate | CLOSED: verifier guide `:82–91` separates local custody, fleet decisions, restoration and authorized credential replacement. |
| T-178-27 | Repudiation | high | mitigate | CLOSED: `docs/maintainer-release.md:37–57` preserves pending main and protected publication authority. |
| T-178-28 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-01/09; incomplete covered inputs and incompatible runner-equality rule. |
| T-178-29 | Repudiation | high | mitigate | OPEN-blocking — SEC-178-02/03; blocking reviews and unsupported source claims are accepted. |
| T-178-30 | Tampering | high | mitigate | OPEN-blocking — SEC-178-03/04/09; canonical/package gate completeness is not established by current acceptance checks. |
| T-178-31 | Repudiation | high | mitigate | OPEN, later acceptance owner: candidate identity validation is an unconditional refusal at `verifier_delivery.py:544–551`; genuine observed checkout relationship remains pending. |
| T-178-32 | Repudiation | high | mitigate | OPEN, later acceptance owner, also affected by SEC-178-10: no hosted graph observed; raw hosted artifacts unavailable under current upload configuration. |
| T-178-33 | Elevation of privilege | high | mitigate | CLOSED for present deny-by-default boundary: future-stage checks refuse acceptance and guidance retains separate exact-head merge/publication authorization. No remote action performed. |
| T-178-34 | Tampering | high | mitigate | OPEN-blocking — SEC-178-06. Source guard has generated-name, creation/OID and pre-drop checks, but package session cleanup is incomplete; final custody reconciliation remains pending. |
| T-178-35 | Elevation of privilege | high | mitigate | OPEN, later acceptance owner: actual integration/helper bytes and semantic accepted-main validation remain unavailable. Current unconditional refusal grants no acceptance. |
| T-178-36 | Repudiation | high | mitigate | OPEN, later acceptance owner: canonical final audit/handoff preservation has not executed; existing flags remain unresolved. |
| T-178-SC | Tampering | high | mitigate | CLOSED for declared no-addition and frozen-package mechanisms: no dependency delta; source rebuild/blob/archive checks present. This is not a dependency vulnerability scan. |

### Runtime and historical limits

Task 3 remains legitimately pending: final freeze, guarded canonical contributor execution, fresh successful fixed-wrapper locked/floor runs, and strict composition of those exact 14 + 12 raw receipts. Their absence is not itself a reason to demand runtime before freeze. The implementation findings above must be corrected before freezing the affected inputs.

The later candidate/handoff branches currently fail unconditionally. That safely prevents false acceptance, but does not implement the promised successful semantic validation of genuine expected head, attempt, complete jobs or helper bytes.

Historical incidents remain unresolved records, separate from product-control verification:

- Three synthetic-secret exposures: Plan 03 retained JWT/code/PKCE material later scrubbed, and separate Plan 04/06 failed-tool disclosures.
- Two wrong-target database incidents: shared unboxed fixture mutation and development migrations. No unchanged-data certification, repair or cleanup is inferred.
- First guard OID-string refusal and exact owned cleanup/cast correction.
- Unexplained Plan 07 post-capture failure followed by stage-only fresh success, without a causal fix.
- Historical aggregate/wrapper exit-1 attempts and later corrected offline validation.
- Unconfirmed EACCES cause; direct-child termination does not establish descendant cleanup.

Phase 177 E-09/E-10 and descriptorless prohibition flags retain their unresolved, non-authoritative status. No dedicated `## Threat Flags` section exists in summaries 01–09; the actual surfaces examined here map to declared threats rather than creating an unmapped blocker.

### Disposition

**Do not approve the current evidence controls or freeze them as settled.** Return the concrete findings to their implementation owners, correct them, and rerun focused adversarial checks before freeze. Then perform the already-planned final runtime sequence. Later hosted/main observations remain with their assigned owners.

**threats_open: 16**

This full-register count includes twelve high threats affected by concrete implementation defects and four high threats whose later acceptance owners remain pending. No missing severity, non-blocking open threat, accepted risk, transfer or human approval was used.
