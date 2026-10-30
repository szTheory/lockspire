# Phase 178 Integration Review

Reviewer: Codex (`gpt-6-luna`, low reasoning), independent integration reviewer
Reviewed commit: `9cc4c203263015effe0894e76550045b19edee8d` (implementation base `4bd35961944d3f70be0db2aadff9664b165264bb`)
Scope: Read-only cross-file and cross-phase trace of Phase 178 Plan 10 package, wrapper, CI and source-test guard connections; no source DB, producer, or hosted workflow execution.
Date: 2026-10-27

## Findings

### BLOCKER — Standard CI checkout cannot provision the wrapper's authenticated candidate input

Evidence: The fixed wrapper requires `.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-FROZEN-INPUTS.json` at [run_verifier_upgrade_proof.sh](/Users/jon/projects/lockspire/scripts/ci/run_verifier_upgrade_proof.sh:27) and exits before creating receipts when it is absent or invalid ([lines 58–62]( /Users/jon/projects/lockspire/scripts/ci/run_verifier_upgrade_proof.sh:58 )). The frozen manifest in turn requires a local archive and extracted tree under `.artifacts/phase178` and validates them ([verifier_delivery.py](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:278), [package_input.py](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/package_input.py:287)). The current fresh checkout contains no frozen manifest or candidate package artifact. Yet both canonical workflow callers invoke the production wrapper directly, with no provisioning/download/build step ([ci.yml](/Users/jon/projects/lockspire/.github/workflows/ci.yml:284), [ci.yml](/Users/jon/projects/lockspire/.github/workflows/ci.yml:398)). `create_frozen_manifest` only writes a local manifest after its archive/tree inputs exist; it is not called by either workflow ([verifier_delivery.py](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/verifier_delivery.py:221)).

Impact: On an ordinary clean GitHub checkout the new proof jobs stop at the frozen-input preflight. CI therefore cannot consume the otherwise linked wrappers, and the promised standard fresh-checkout provisioning path is absent. This is a concrete wiring defect, independent of still-pending execution receipts.

Remediation: Add an existing-job provisioning step or a bounded wrapper bootstrap that obtains/authenticates the sealed candidate archive/tree and manifest from committed or workflow-owned immutable inputs, then validates them before invoking either pair. Preserve runner and candidate identities as separate pins. Keep this within the existing job graph as required by the Plan 10 contract.

Disposition: Open; BLOCKER.

### WARNING — Delivery-stage implementation and positive flow are not yet independently demonstrated

Evidence: Plan 10 declares `verifier_delivery.py` stages for reviews, frozen inputs, source, candidate identity, candidate and handoff, but candidate/handoff evidence belongs to Plans 11–12 and final frozen/source/package records are not present at this reviewed commit. `.planning/STATE.md` retains all three requirements as pending and says no fresh fixed-wrapper success, canonical `--ci`, or final review/freeze exists. The wrapper does validate frozen pins, passes `LOCKSPIRE_FROZEN_INPUTS` into `package_input.authenticated_frozen_source`, runs each selected group, and invokes the pair receipt validator with expected runner and candidate source pins ([wrapper lines 63–82, 149–164, 231–240]; [package_input.py](/Users/jon/projects/lockspire/scripts/acceptance/clean_room/package_input.py:234)). This establishes a code path, not a passing end-to-end package flow.

Impact: No assertion can yet be made that authenticated archive → installed package groups → raw receipts → strict 26-cell composition → source acceptance → candidate/handoff completes. The 14/33 locked and 12/31 floor receipts and separate public/RPC, disclosure same-run owner checks remain execution/validator acceptance work, not proven outcomes here.

Remediation: Complete the final frozen inputs and review owners, then produce fresh successful locked and floor fixed-wrapper runs and validate their strict composition before recording source/candidate/handoff acceptance. Preserve prior Plan 08 exit-1 attempts and retained receipts without promotion.

Disposition: Pending required runtime/acceptance work; WARNING, not a claim that planned nonexecution itself is a defect.

## Evidence

### Integration boundary / flow table

| Flow | Trace | Status |
|---|---|---|
| CI → pair wrapper | `ci.yml` calls locked/floor wrapper; wrapper restricts pair and receipt roots, checks frozen manifest before mutation, then calls runner by core/rollout/recovery/endpoints/contention/atomicity/issuance/disclosure and pair-specific groups. | BROKEN in clean checkout: frozen candidate inputs are not provisioned (BLOCKER above). |
| Frozen owner → installed candidate | `verifier_delivery.py` validates covered input hashes and source/archive/tree build relation; wrapper exports frozen-manifest path; `package_input.py` selects that owner and checks archive/tree/source owner before candidate install. | Code-wired; fresh installed positive runs pending. |
| Pair outputs → complete package matrix | Wrapper validates each pair with expected runner and candidate source revision; Plan 10 specifies composition of fresh locked/floor indexes into exact 26 keys / 64 cases and disclosure pairing. | Pending fresh pair outputs and final composition; not counted passed. |
| Source tests → canonical CI | `run_owned_source_tests.py --ci` owns fresh DB creation/identity/cleanup and invokes canonical `mix ci`; Plan 10 names it as the only source gate. | Guarded code path exists; final `--ci` execution is pending. No manual source DB commands run in this review. |
| Package/source → candidate/handoff | Plan 10 defines semantic stages and Plans 11/12 own candidate/main/handoff facts. | Pending; no candidate or main acceptance inferred. |

### Cross-phase / requirement map

| Requirement | Integration path | Status | Issue |
|---|---|---|---|
| VPROOF-02 | Phase 175 compatibility contract and Phase 177 maintenance/source boundaries → Phase 178 authenticated package input → locked/floor installed HTTP/PostgreSQL/release groups → strict pair composition | PARTIAL | Runner-to-owner links exist, but clean-checkout provisioning is missing and final fresh package/source runtime evidence is pending. |
| VDELIV-01 | Phase 177 verification/security owners + Phase 178 independent reviews/freeze → final package and guarded source gates → candidate CI evidence | PARTIAL | Review/freeze/source/candidate evidence chain is unfinished; clean-checkout wrapper caller is blocked as above. |
| VDELIV-02 | Phase 178 candidate identity and handoff stages → actual main/helper acceptance and custody handoff (Plan 12) | PENDING | Later-plan runtime/main facts remain pending by design; no wired accepted-main result exists yet. |

All three scoped requirements have cross-phase wiring intent. None is WIRED end-to-end at this reviewed commit. Requirements state: VPROOF-02, VDELIV-01, VDELIV-02 remain pending.

## Actual checks / limitations

- Inspected the Plan 10 sequencing amendment, wrapper implementation, source DB guard contract and runner, CI callers, package input resolver, frozen-manifest validator, and requirement statuses.
- Confirmed the frozen manifest and candidate archive/tree are absent from this checkout while workflow callers invoke the wrapper without a provisioning step.
- No tests, wrapper, source DB command, package producer, or remote workflow was run. This avoids source DB/resource mutation and does not substitute for Plan 10's required runtime evidence.
- Existing Plan 08 wrapper failures, retained historical receipts, prior source-target incidents, and Phase 177 flags remain historical evidence and are not waived by this review.

## Disposition

Integration review found one concrete BLOCKER: canonical clean-checkout callers cannot provision the authenticated frozen package inputs required by the wrapper. The positive package, strict composition, canonical source CI, candidate and handoff flows remain pending; they must not be reported as passed until their actual evidence is recorded.
