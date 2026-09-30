---
status: checkpoint
trigger: "Phase 140 gap planning is blocked by its mandatory Phase 139 finalizer gate; determine the safe supported recovery without discarding Phase 140 work or performing unauthorized ref movement."
created: 2026-09-30T07:56:39Z
updated: 2026-09-30T17:56:26Z
---

## Current Focus

hypothesis: An opt-in, digest-bound supersession path can authenticate the current Phase 140 candidate without moving refs; the normal prepare path remains fail-closed, and the separate exact-SHA publication barrier keeps the live gate blocked.
test: Implemented the isolated supersession path and extended the existing lifecycle fixture for archive integrity, stale receipt preservation, drift rejection, code-path rejection, and no-ref movement. Only shell/JavaScript syntax checks and `git diff --check` were run; the lifecycle suite and live finalizer were not run.
expecting: Preserve the pending receipt, Phase 140 work, protected overlays, and refs byte-for-byte. Keep the gate blocked. Finish review before any commit or fixture execution; any future publication remains a separate exact-SHA checkpoint.
next_action: Re-review the five source files through `$gsd-code-review 140 --files=scripts/maintainer/baseline_inventory.sh,scripts/maintainer/finalize_phase_139_acceptance.sh,scripts/maintainer/supersede_phase_139_host_receipt.sh,tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs,tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs`; do not run the finalizer or `$gsd-plan-phase 140 --gaps`.
bug_class: stale-lifecycle-receipt
reasoning_checkpoint:
  hypothesis: The current receipt is unusable because it is bound to an earlier HEAD and worktree snapshot, while prepare intentionally reuses pending receipts; a separately authenticated supersession receipt can rebind the current candidate without changing refs.
  confirming_evidence:
    - The live pending receipt's after.head is 5ad2b2e935556c8f1a91be32605958530b477527, while current HEAD is 280c8a6048ada75b85191ea640f6ccbdabeca6af.
    - The finalizer checks the sealed candidate and porcelain hash before any publish path, and prepare returns a compatible pending plan:pre receipt unchanged.
  falsification_test: In an isolated fixture, a valid successor with exact archive digest and allowed overlays must validate while refs remain unchanged; altering receipt bytes, candidate ancestry, tracking-ref agreement, or overlay contents must cause validation or supersession to fail.
  fix_rationale: A dedicated digest-bound receipt transition makes provenance and compare-and-swap explicit while keeping the existing --publish exact-SHA branch as the sole ref-mutation path.
  blind_spots: This turn will not execute CI or exercise the live Git remote; command correctness is based on isolated fixture design and static review until CI runs.
  candidate_causes:
    - "code: prepare reuses an existing pending receipt and sealed validation requires its old HEAD/porcelain identity"
    - "environment: local main and cached origin/main intentionally lag current HEAD while the advertised remote must remain synchronized"
    - "data: the pending receipt and worktree overlays have drifted since the receipt was sealed"
  and_gate: "yes — the gate remains blocked unless both the stale receipt is replaced through authenticated supersession and the independent exact-SHA publish barrier is explicitly authorized; the replacement alone must not move refs."

## Symptoms

expected: `$gsd-plan-phase 140 --gaps` reaches gap-plan creation after the required prior-phase gate validates, without repeating completed Phase 140 plans.
actual: The blocking `plan:pre` gate calls `bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139`; the first attempt exited 1 with `another final acceptance is active`.
errors:
  - "Pending host receipt: .git/gsd-lifecycle/post-completion-finalizer.json, phase 139 plan:pre, candidate 5ad2b2e935556c8f1a91be32605958530b477527."
  - "Current HEAD: 280c8a6048ada75b85191ea640f6ccbdabeca6af; local main and cached origin/main: 5ad2b2e935556c8f1a91be32605958530b477527."
  - "Durable Phase 139 acceptance receipt baseline: c6332d3a8b716b938f93d978243281764e3eac41."
  - "The `.git/lockspire-phase-139-acceptance.lock` path was absent on later inspection; process listing was denied by the environment."
  - "The phase-finalizer command can fast-forward local main and push origin/main only when given a separate exact `--publish <SHA>` argument; no such authorization is recorded."
reproduction: "Run `bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139` from the repository root; initial observed output was `phase 139 acceptance: another final acceptance is active`."
timeline: "Resumed 2026-09-30 after user returned online; phase 140 verifier was gaps_found (6/8), and the recommended `$gsd-plan-phase 140 --gaps` was attempted."

## Evidence

- timestamp: 2026-09-30T07:56:39Z
  checked: Phase 140 plan-phase blocking pre-hook
  found: The installed `lockspire-phase-finalizer` gate runs the Phase 139 `post-transition` command with a 2400-second timeout and halts planning on nonzero exit.
  implication: Gap plans cannot be created through the standard GSD workflow until the lifecycle gate is resolved.
- timestamp: 2026-09-30T07:56:39Z
  checked: Phase 139 finalizer and state helper
  found: The finalizer acquires a `.git` directory lock, reuses an existing pending host receipt, requires its sealed candidate and porcelain hash to match the live checkout, and reaches ref mutation only after an exact `--publish` SHA is supplied.
  implication: The current candidate mismatch must be reconciled before publication; retrying or fabricating a seal could invalidate provenance.
- timestamp: 2026-09-30T07:56:39Z
  checked: Protected worktree state
  found: The four protected overlay hashes still match the execution-entry values, and the initial blocked attempt left git status unchanged.
  implication: Preserve those overlays byte-for-byte during diagnosis and recovery.
- timestamp: 2026-09-30T08:00:00Z
  checked: Full finalizer state transitions and live worktree status
  found: The state helper's `prepare` reuses an existing pending plan:pre receipt rather than refreshing it; recovery issuance requires HEAD == local main, an ancestor baseline, and only whitelisted planning overlays. Current HEAD is 280c8a6048ada75b85191ea640f6ccbdabeca6af, while receipt after.head is 5ad2b2e935556c8f1a91be32605958530b477527. Current status also includes this active debug session file, which is outside the recovery allowlist. `complete` unlinks the pending receipt.
  implication: Retrying `prepare` cannot refresh the receipt, and `complete` would erase lifecycle evidence. The live checkout fails candidate and recovery-path conditions; no safe supported state refresh is evident.

## Resolution

root_cause: The pending host plan:pre receipt is bound to the earlier checkout at 5ad2b2e935556c8f1a91be32605958530b477527, but the active checkout has moved to 280c8a6048ada75b85191ea640f6ccbdabeca6af. The helper's prepare path reuses pending receipts, and finalizer authentication checks current HEAD and porcelain state, so the receipt cannot authorize work from the current checkout. The initially reported `another final acceptance is active` was the lock guard; the lock is now absent, while the stale-receipt condition remains.
fix_direction:
  - Identify a supported way to reconcile the stale host receipt while preserving the current Phase 140 branch and protected overlays.
  - Keep any exact-SHA local-main or origin/main movement behind a separate explicit approval for the candidate SHA.
files_involved:
  - scripts/maintainer/run_lockspire_phase_finalizer.sh
  - scripts/maintainer/finalize_phase_139_acceptance.sh
  - tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs
  - .git/gsd-lifecycle/post-completion-finalizer.json
oracle_type: observed-gate-and-state

## Recovery Checkpoint — 2026-09-30T08:18:16Z

The temporary checkout restoration was attempted with the sealed Phase 139 SHA `5ad2b2e935556c8f1a91be32605958530b477527`. The receipt's exact porcelain hash matched (`70991c2e82962048bf57fca111f8ec9d1fb252b646575d9dd96f742b10496b87`), but the no-publish gate stopped during sealed-candidate authentication with `receipt validation failed: recovery working-tree identity` and `snapshot_relation: refresh_required`.

The receipt expects the untracked Phase 140 verification at 18,986 bytes / SHA-256 `ce1bc239cfde07f1da4e11915ed3c20e58c2cb7f981f9131610ec2a1142281cb`; the current verification report is 23,847 bytes / SHA-256 `33ba4ae04e6776c84a1ea2610d6424103ea9bb40a8652b39f728e1e3557318c4`. The other three preserved overlay identities match. The report was preserved byte-for-byte; no stale copy was substituted.

The Phase 140 branch was restored at `280c8a6048ada75b85191ea640f6ccbdabeca6af`; local and cached `origin/main` remain at `5ad2b2e935556c8f1a91be32605958530b477527`; the finalizer lock is absent. The no-publish gate did not reach the exact-SHA publication checkpoint, so no ref update or push occurred. The Phase 139 pending receipt remains unchanged.

- timestamp: 2026-09-30T14:44:49Z
  checked: Tracked Phase 139 finalizer routing and state-helper transitions, including recovery issuance guards
  found: The routed finalizer exposes no supported receipt-refresh command. `begin` rejects an existing pending receipt, `prepare` reuses a compatible pending `plan:pre` receipt unchanged, and `complete` removes pending lifecycle evidence. Fresh recovery issuance requires `HEAD == main`, descent from the accepted baseline, and an allowed worktree; the current HEAD is `280c8a6048ada75b85191ea640f6ccbdabeca6af` while local main and the receipt candidate are `5ad2b2e935556c8f1a91be32605958530b477527`. Restoring the earlier candidate already failed `recovery working-tree identity` validation because the preserved Phase 140 verification report differs from its receipt-bound snapshot.
  implication: No safe supported refresh is available in the tracked protocol. Leave the pending receipt, Phase 140 files, protected overlays, and refs intact; planning remains blocked pending a maintainer-supported refresh/supersession procedure. Publication remains a separate, unreached checkpoint.

## Recovery Checkpoint — 2026-09-30T14:44:49Z

No safe supported stale-receipt refresh path is exposed by the tracked protocol. A maintainer decision is required: provide or approve a documented receipt refresh/supersession procedure that authenticates the current Phase 140 worktree and retains lifecycle provenance, or keep the gate blocked pending such a procedure. No receipt, Phase 140 file, overlay, or ref was changed during this investigation. The no-publish finalizer has not reached the exact-SHA publication checkpoint.

- timestamp: 2026-09-30T14:49:05Z
  checked: Maintainer response to the stale-receipt recovery checkpoint
  found: Maintainer chose to keep the Phase 139 finalizer gate blocked.
  implication: Preserve the pending receipt, Phase 140 work, protected overlays, and refs unchanged. Resume only when a documented maintainer-supported receipt refresh/supersession procedure is available; exact-SHA publication remains a separate, unauthorized checkpoint.

- timestamp: 2026-09-30T15:26:33Z
  checked: Read-only review of lifecycle helper, finalizer, existing lifecycle tests, and CI wiring
  found: No documented or implemented stale-receipt refresh/supersession procedure exists. Existing CI already runs the lifecycle suite; it covers pending receipt preservation and recovery snapshot/drift rejection, but lacks a focused regression for replaying a compatible stale plan:pre receipt and proving its identity is preserved while refs remain untouched.
  implication: A focused fixture regression belongs in the existing CI suite and needs no new workflow job. This is preventive coverage only; it cannot refresh the live receipt or unblock Phase 140.

- timestamp: 2026-09-30T15:30:20Z
  checked: Added a focused stale-receipt replay regression to the existing lifecycle fixture
  found: The fixture now changes a preserved planning overlay after sealing, reruns `prepare`, asserts the pending receipt object and bytes remain unchanged, confirms finalizer relation validation rejects the changed snapshot, and asserts Git refs did not move. Existing CI already runs this test file.
  implication: The regression makes the fail-closed behavior repeatable in CI without adding a job or changing the live gate. It does not provide incident recovery; the Phase 139 gate remains blocked until a provenance-preserving supersession procedure is separately designed and implemented.

- timestamp: 2026-09-30T15:40:20Z
  checked: Read the finalizer's no-publish control flow after sealed-candidate authentication
  found: Even with a valid sealed receipt, the ordinary gate invocation has no `--publish` argument. The finalizer intentionally stops at the exact-SHA publication checkpoint before moving refs; the separate publication argument must match the authenticated candidate SHA.
  implication: Refreshing the stale receipt alone would not advance Phase 140. Keep both the current receipt and publication gate blocked; do not repeat `$gsd-plan-phase 140 --gaps` until the receipt protocol is supported and the separate exact-SHA checkpoint is authorized.

- timestamp: 2026-09-30T15:55:35Z
  checked: Refreshed the GSD progress snapshot, verification statuses, Phase 140 plan counts, STATE, and ROADMAP
  found: STATE and ROADMAP name Phase 140 as current and mark Phases 138/139 complete. Plan 140-04 has a blocked summary, so roadmap analysis counts 3 successful summaries for 4 plans; `find-phase 140` sees all 4 summary files. Verification queries call Phases 138/139 stale and Phase 140 gaps_found. STATE explicitly says not to replay Plans 140-01 through 140-04 and names gap planning as the next phase action, but that action was already blocked by the Phase 139 gate.
  implication: Do not blindly follow the generic count-based `$gsd-execute-phase 140` route or rerun Phase 138/139 verification. Resume the active debug session to design the supported receipt protocol; Phase 140 remains blocked.

- timestamp: 2026-09-30T16:08:30Z
  checked: Read-only inspection of current refs, pending receipt, worktree paths, finalizer ordering, and `validate_phase_140_recovery_chain`
  found: `refs/heads/main` and cached `refs/remotes/origin/main` remain at `5ad2b2e935556c8f1a91be32605958530b477527`, an ancestor of active HEAD `280c8a6048ada75b85191be32605958530b477527`. Recovery validation nevertheless requires `local_main == candidate` before it reaches the finalizer's separate `--publish <exact SHA>` check. The current porcelain also includes a modified lifecycle test source and the untracked debug file, both outside the Phase 140 recovery overlay allowlist. The live pending receipt bytes remain SHA-256 `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`.
  implication: A successor receipt can preserve provenance without changing refs in principle, but the current gate cannot authenticate this branch state without either moving local main or changing the preauthorization policy. The dirty test source also needs an explicit treatment rule. Do not make either policy change implicitly.

## Recovery Checkpoint — 2026-09-30T14:49:05Z

Maintainer decision: keep the gate blocked pending a documented receipt refresh/supersession procedure that authenticates the current Phase 140 worktree while retaining lifecycle provenance. The Phase 139 pending receipt, Phase 140 files, protected overlays, and local/remote refs remain untouched. Do not retry the no-publish finalizer until such a procedure exists. The exact-SHA publication checkpoint has not been reached and remains unauthorized.

## Recovery Checkpoint — 2026-09-30T15:26:33Z

Follow-up investigation found no supported incident recovery procedure. The current stale receipt remains unchanged and the gate remains blocked. A focused lifecycle fixture regression now checks stale receipt replay, drift rejection, receipt-byte preservation, and no ref movement; existing CI runs this suite. This is auditable prevention only, not recovery or authorization to run the finalizer. Static review also confirmed that a valid receipt alone would stop at a separate exact-SHA publication checkpoint. No receipt, Phase 140 artifact, protected overlay, ref, or finalizer state was changed. The new regression was not run locally; no finalizer/publication command was run.

## Recovery Checkpoint — 2026-09-30T15:52:13Z

Maintainer requests continued progress while keeping the gate blocked. The next debugging step is to design a provenance-preserving supersession protocol and test it in isolated fixtures. The live pending receipt and refs stay untouched; even a future valid receipt must not bypass the separate exact-SHA publication checkpoint. Resume with `$gsd-debug continue phase-139-finalizer-stale-seal`.

## Recovery Checkpoint — 2026-09-30T16:08:30Z

Protocol design (not implemented): a future `supersede` operation should require the expected digest of the current pending receipt, preserve those exact bytes in an exclusive immutable archive, revalidate the current hook identity and Phase 139 baseline, capture the successor's exact candidate/worktree identities, bind the successor to the archived receipt digest, and atomically replace the pending receipt only after compare-and-swap rechecks. Its validator must keep the current `--publish <exact SHA>` check as a later, separate gate; only that explicit argument may reach local-main/origin-main mutation.

The current implementation blocks that no-ref flow: `validate_phase_140_recovery_chain` requires `refs/heads/main == candidate` before the finalizer reaches its exact-SHA checkpoint. The active candidate is `280c8a6048ada75b85191be32605958530b477527`, while local main remains `5ad2b2e935556c8f1a91be32605958530b477527`. Current dirty paths also include `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` and this debug file, which are outside the recovery overlay allowlist. Changing the main-ref precondition or admitting the modified test source requires maintainer policy direction; no isolated supersession fixture was added before that design decision. No tests, finalizer, planner, publication, ref update, or live receipt write was performed. Phase 140 remains blocked.


## Recovery Checkpoint — 2026-09-30T16:10:40Z

Maintainer policy direction: “Keep the gate blocked.” Accordingly, this session does not change the `main == candidate` precondition or recovery overlay allowlist, does not modify the live receipt, and does not edit implementation or lifecycle tests. The supersession protocol remains proposal-only. Phase 140 remains blocked.

Outstanding protocol questions for a future maintainer-supported design:
- How should a successor receipt authenticate a candidate when local `main` remains the candidate’s ancestor, while preserving the separate exact-SHA publication barrier?
- How should the modified lifecycle test source and active debug document be handled in worktree identity/overlay policy without weakening recovery authentication?
- What archive, compare-and-swap, and failure-recovery guarantees are required before any live receipt supersession is supported?

No tests, planner, finalizer, publication, ref update, or live receipt write was performed in this continuation.

## Recovery Checkpoint — 2026-09-30T17:56:26Z

The user clarified to follow the recommendations autonomously while keeping the gate blocked. Implemented a dedicated opt-in `supersede` operation requiring the exact pending-receipt digest, archival of the exact prior bytes, lineage/remote/overlay checks, compare-and-swap replacement, and no ref movement. The ordinary `prepare` behavior remains unchanged. The independent `--publish <exact SHA>` barrier remains in place and the supersede operation was not invoked.

The Phase 140 code review found one blocker: the new lifecycle commit class was not accepted by the recovery-chain and post-transition suffix validators. The implementation now accepts that class only as a single terminal suffix under recovery protocol v2, then validates the preceding sequence against the existing allowlist. Shell syntax checks, JavaScript syntax checks, and `git diff --check` pass. The fixture suite was not run; CI already runs that suite. The review report still needs a focused re-review.

Current branch remains Phase 140 Bounded Operational Loose-End Triage, with gap planning blocked by the Phase 139 finalizer gate. Phase 139 Required Truth Reconciliation is complete; Phase 141 Maintenance-Baseline Closure follows. Preserve the stale live receipt and all refs. The immediate next GSD command is the explicit five-file `$gsd-code-review 140 --files=...` command in `next_action`. Do not repeat Phase 140 gap planning, invoke receipt supersession, or pass a publication SHA.

## Recovery Checkpoint — 2026-09-30T16:17:31Z

Continuation closed at the existing checkpoint. The maintainer's decision to keep the Phase 139 gate blocked remains in force. Receipt supersession remains proposal-only pending documented policy for (1) authenticating a candidate while local `main` is its ancestor, (2) handling the modified lifecycle test source and active debug file in worktree identity/overlay rules, and (3) preserving the separate exact-SHA publication checkpoint. The pending receipt, Phase 140 artifacts, protected overlays, and refs were not changed. No tests, planner, finalizer, or publication commands were run. Resume only when new documented policy is available; do not re-ask the prior decision.

## Recovery Checkpoint — 2026-09-30T17:26:04Z

The user clarified to follow the conservative recommendation autonomously. Decision: retain the existing `main == candidate` guard and recovery overlay allowlist; keep the Phase 139 gate blocked; do not modify the live receipt or refs. The earlier stale-replay lifecycle regression remains the only code change for this issue and is already wired into CI. No supersession implementation was made in this continuation, and no tests, planner, finalizer, or publication commands were run. Do not repeat Phase 140 gap planning. Resume this debug session only after a reviewed supersession implementation exists; then the next phase command may be `$gsd-plan-phase 140 --gaps` after the gate is safely resolvable.
