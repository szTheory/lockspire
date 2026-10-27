# Phase 178 — Third Security Re-review

Reviewer: gsd-security-auditor; configured gpt-6.1-sol/xhigh; `/root/phase178_execution_workflow/review178_security`
Reviewed commit: b021d4422c1b8714f62463d74a6ef2eb42adced5
Date: 2026-10-27
Scope: Independent pre-freeze implementation re-review of corrections since `7c6ff91e0d42e434ef8286e09960425a3f062eb9`, concentrating on SEC-178-01/05/11/12, review authority, registry ownership, and the source-runner factory seam. Prior reports remain immutable.
Disposition: rejected
Active blocking findings: 1

## OPEN_THREATS

**ASVS Level:** 1
**block_on:** high
**Declared threats:** 37 distinct IDs, all `mitigate`
**Mitigations closed at implementation scope:** 35/37
**Blocking open threats:** 2/37
**Non-blocking open threats:** 0
**threats_open:** 2

These counts concern mitigation implementation. They do not certify fresh package, database, hosted CI, integration, or main acceptance.

## Findings

### SEC-178-05 — HIGH — Arbitrary strings remain accepted in fixed release RPC evidence fields

**Threats:** T-178-21, T-178-25.

**Locations:**

- `scripts/acceptance/clean_room/verifier_receipts.py:395–403`
- `scripts/acceptance/clean_room/verifier_receipts.py:981–1002`
- Actual producer literals: `scripts/acceptance/clean_room/verifier_endpoints.py:179–181`
- Verbatim downloaded receipt consumption: `scripts/acceptance/clean_room/verifier_delivery.py:1246–1285`
- Verbatim wrapper raw-copy/upload preparation: `scripts/ci/run_verifier_upgrade_proof.sh`

**Observed defect:** The release RPC validator treats `rpc_invocation`, `check_invocation`, and `task_local_invocation` as nonempty strings. It does not require the fixed strings emitted by the producer.

The actual producer emits:

```text
rpc_invocation:
bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100)

check_invocation:
bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 100)

task_local_invocation:
mix lockspire.clients.verifier.rewrap --check --limit 100
```

**Independent probe:** Replaced all three fields in the established release RPC fixture with a generated opaque private string. `validate_receipt()` accepted the mutated receipt. The value stayed in memory and was never printed or written.

**Impact:** A receipt containing private material in these known fields can pass the safety boundary. Subsequent raw copying and upload preserve the receipt bytes. Correct JSON types, matching digests, and authenticated artifact custody do not make an arbitrary string safe.

The current wrong-type mutation test passed. It does not exercise this same-type substitution.

**Remediation:** Enforce the exact producer literals for these three fields. Complete a finite inventory of remaining string-valued receipt leaves: use exact enums/literals for fixed descriptions and explicit bounded grammars plus independent relationships for genuinely variable identities. Reject unsafe strings before durable copying. Add same-type private-string substitutions, including encoded variants, alongside the existing object/array/boolean mutations. Keep test diagnostics boolean and fixed-message only.

**Disposition:** Open; fix before freeze.

## Original finding dispositions

| Finding | Current disposition | Evidence and limits |
|---|---|---|
| SEC-178-01 | Fixed at implementation scope | `verifier_input_closure.py` selects the committed tracked tree using one finite root/directory/planning rule. Freeze, consumer, review, and provisioner use that rule and compare exact path sets and bytes. Newly tracked selected dependencies invalidate applicability. All seven previously confirmed omissions now fall within the rule. |
| SEC-178-02 | Fixed at implementation scope | `validate_reviews()` binds full selected scope, source bytes, reviewer identity, revision, report digest, embedded judgment and classified findings. It requires one active accepted disposition and rejects contradictory active blocking narrative. Historical quotations are separated explicitly. |
| SEC-178-03 | Fixed; runtime pending | Actual `OwnedSourceTests.run()` output passes the source consumer in the composed chain with only OS/database boundaries replaced. Cleanup order and captured CI stages are consumed rather than reconstructed manually. |
| SEC-178-04 | Retained fixed disposition | Exact raw scope/cell/case bindings remain enforced. |
| SEC-178-05 | **Open — HIGH** | Object/type and fleet-limit holes were corrected, but the fixed invocation strings still accept opaque private strings. |
| SEC-178-06 | Fixed at implementation scope | Caller-writable rows no longer grant signal authority. Kernel-peer IPC, actual ancestry/session identity and cached creation identity control admission and signalling. Independent actual-wrapper sibling injection and selected lifecycle controls passed. Linux execution remains unobserved here. |
| SEC-178-07 | Retained fixed disposition | Corrected shared output handling remains. The unchanged real-child unknown-output privacy test passed through the corrected source-runner factory. This does not close SEC-178-05’s receipt-value channel. |
| SEC-178-08 | Retained fixed disposition; runtime pending | Actual mutating apply witness remains implemented. No fresh installed execution was performed by this audit. |
| SEC-178-09 | Fixed at implementation scope | Final paths remain supported. Executed checkout identity and frozen package ownership remain separate; selected-byte equivalence replaces indiscriminate HEAD equality or evidence restamping. |
| SEC-178-10 | Fixed at implementation scope | Provisioner produces the versioned archive and job-owned manifest while retaining the canonical frozen record. The composed chain consumes actual provisioner output. |
| SEC-178-11 | Ownership/format defects fixed; safety qualified by SEC-178-05 | Actual wrapper output, including `raw-copies.json`, `raw/*`, candidate manifest and archive, is consumed. Raw triple/proof, index, host lock and compiled bindings are checked. Candidate identity invokes authoritative run/PR/ref/commit observations. Artifact digest and exact ZIP contents are checked. |
| SEC-178-12 | Fixed at implementation scope; runtime pending | Actual shell helper collectors, validators and emitter feed handoff successfully in the controlled chain. Main refs, helper/authorization bytes, owned source capture, CI/release job sets, attempts, outcomes and authoritative observations are checked. Explicit pending remains supported. |

The former foreign-registry signalling defect is independently closed by the new authority mechanism. Numeric diagnostic records are output-only and cannot extend the helper’s private signal-authority cache.

The source-runner seam is also corrected: `PrivateProcessRunner` now calls `start_owned_session`; strict cleanup was not weakened.

## Evidence

Independent checks performed at the reviewed source:

- Actual composed source-to-handoff chain passed: actual owned-source producer, source consumer, pair validator tree, wrapper post-copy output, exact uploaded ZIP, candidate identity and graph checks, actual shell helper collectors/validators/emitter, and handoff consumer. External OS/build/database/GitHub boundaries were controlled fixtures.
- Complete selected-tree and all-26-cell wrong-type controls passed.
- Actual-wrapper foreign sibling injection control passed: the unrelated test-owned sibling survived without receiving TERM.
- Five actual-wrapper lifecycle controls passed: timeout escalation, external TERM with two isolated sessions, denial/custody, parent exit, and unfinished-launch custody.
- Creation-reuse, missing-leader and identity-denial controls passed.
- Two corrected source-runner selections passed: real-child unknown-output privacy and registered authority before the started callback.
- Independent opaque-string mutation was accepted in one release RPC cell, confirming SEC-178-05.
- Scoped diff whitespace check passed.

**Test accounting:** Fourteen intended target tests passed across the bounded runs, with no skips. The first selection also produced two loader errors because this reviewer supplied the wrong guard test class name. Those are retained as failed selections; the two correctly named guard targets subsequently passed. No loader error was counted as a passing test.

The initial selected-run process was PID/PGID `60287`; the corrected guard run was PID/PGID `63002`. Both completed. Test-owned wrapper, root, sibling and nested groups were cleaned and absence checked by the passing controls. Their owned temporary roots and custody directories were removed. No unresolved auditor resource remains.

All child diagnostics and the generated private mutation value remained in memory. No raw logs were inspected. No database, freeze, canonical CI, genuine package producer, hosted API, or remote mutation was executed.

The reviewed HEAD remained `b021d4422c1b8714f62463d74a6ef2eb42adced5`. Its changes after `843636c7` are evidence metadata; selected implementation bytes were not restamped as newly executed source. The concurrently created source re-review report is outside this auditor’s ownership.

## Threat verification

All entries retain their declared `mitigate` disposition.

| Threat IDs | Category | Severity | Implementation status and evidence |
|---|---|---|---|
| T-178-01, 07, SC | Tampering | high | Closed: package/source owner checks, rebuilt source tree, per-file Git ownership, archive/tree inspection and separately pinned predecessors/public control. |
| T-178-02 | Repudiation | high | Closed: finite receipt identities and raw/index reconciliation. |
| T-178-03, 06 | Information Disclosure | high | Closed for declared child/CLI output mechanisms; prior implementation evidence retained, real-child privacy control rechecked. |
| T-178-04 | Elevation of Privilege | high | Closed: declared adapter authority and pre-access rejection mechanisms retained. |
| T-178-05, 08 | Tampering | high | Closed: fresh inventory reconciliation and writer activation sequencing retained. |
| T-178-09 | Repudiation | high | Closed: predecessor/public scope separation and failed-attempt preservation retained. |
| T-178-10 | Spoofing | high | Closed: installed assertion and lifecycle controls retained. |
| T-178-11 | Elevation of Privilege | high | Closed: unsupported PAR/FAPI method rejection controls retained. |
| T-178-12 | Repudiation | high | Closed for live-release/compiled identity mechanism; invocation-string privacy remains under T-178-21/25. |
| T-178-13, 14 | Tampering | high | Closed: blocker, durable row and reached audit-failure mechanisms retained. |
| T-178-15 | Repudiation | high | Closed: provisional rollback and committed reporting controls retained. |
| T-178-16, 17 | Tampering | high | Closed: preservation and repeat/partial/indeterminate reconciliation retained. |
| T-178-18 | Elevation of Privilege | high | Closed: stale authenticated identity issuance controls retained. |
| T-178-19 | Spoofing | high | Closed: key restoration and authorized credential replacement remain separate. |
| T-178-20 | Information Disclosure | high | Closed for observed diagnostic-channel mechanisms; historical limitations remain recorded. |
| **T-178-21** | **Information Disclosure** | **high** | **Open, blocking:** arbitrary private strings pass fixed release invocation fields. |
| T-178-22 | Repudiation | medium | Closed: logging/host instrumentation limitations remain explicit. |
| T-178-23 | Repudiation | high | Closed: exact 26-cell/64-case composition mechanism. |
| T-178-24 | Tampering | high | Closed: validated paths, isolated test mode and authenticated process ownership; actual adversarial controls passed. |
| **T-178-25** | **Repudiation** | **high** | **Open, blocking:** CI receipt safety validation accepts the SEC-178-05 string substitution before verbatim copying/upload. |
| T-178-26 | Elevation of Privilege | high | Closed: custody, host responsibility and operational authority remain distinct. |
| T-178-27 | Repudiation | high | Closed: support/release claims remain bounded to recorded evidence. |
| T-178-28, 29 | Repudiation | high | Closed: complete tracked closure, selected-byte applicability and genuine embedded review judgment mechanism. |
| T-178-30 | Tampering | high | Closed: fixed source CI stages and complete raw package matrix checks. |
| T-178-31, 32 | Repudiation | high | Closed at mechanism scope: actual Git relations, authoritative run/attempt/job/ref/commit observations and authenticated archive consumption. Hosted observations pending. |
| T-178-33, 35 | Elevation of Privilege | high | Closed at mechanism scope: explicit authorization and pending state; full helper/main custody validation. Genuine integration/main acceptance pending. |
| T-178-34 | Tampering | high | Closed: exact authenticated process identities, bounded cleanup and retained uncertainty custody. |
| T-178-36 | Repudiation | high | Closed at mechanism scope: immutable historical reports, active independent judgment and explicit unresolved observations remain preserved. Final audit observations pending. |

No new unmapped product surface was identified. Registry IPC maps to T-178-24/34; closure/review changes map to T-178-28/29; hosted/helper observations map to T-178-31/32/35.

## Limits and historical disposition

Actual final freeze, guarded canonical source CI, fresh successful fixed package wrappers, hosted candidate evidence, integration authorization and accepted-main helper execution remain later-owner work. Controlled fixtures establish implementation behavior only. Their absence is not an additional pre-freeze code defect.

The Linux `/proc` creation-identity and `SO_PEERCRED` branches were inspected but not executed on this macOS host. No Linux runtime acceptance is claimed.

Historical secret exposures, wrong-target database incidents, unexplained stage transition, missing original RED evidence, failed wrapper exits, process-custody incidents and parent capture-handling deviation remain unchanged. This report does not certify development data as unaffected. Phase 177 E09/E10 remain unresolved and provide no waiver.

The original delivery pre-edit RED gap remains. The later native delivery regressions and subsequently qualified checker record do not create an earlier checker timestamp or replace the missing original evidence.

## Disposition

Freeze remains blocked by SEC-178-05. Correct the finite known-string channels and add same-type sensitive-string controls, then request a scoped independent re-review. No runtime or human approval is granted.
