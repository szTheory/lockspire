# v1.47 Planning Baseline

**Observed:** 2026-10-24, before new-milestone writes.
**Verdict:** Remote main is green at the observed SHA; this feature checkout is not an accepted clean implementation baseline.

## Live Remote Observation

GitHub main API returned a1e39a01aca258d0ac5f36414bf47c45686d92c1, dated 2026-10-20T21:24:00Z.
- [Canonical CI 39500039338](https://github.com/szTheory/lockspire/actions/runs/39500039338): push event, matching SHA, seven jobs successful: Fast Checks, Integration Checks, Release Hygiene Drift, Minimum Supported Elixir/OTP, Adoption Demo Smoke, Dialyzer, Complete Coverage Evidence.
- [Release 39500039371](https://github.com/szTheory/lockspire/actions/runs/39500039371): push event, same SHA; Maintain Release Please PR successful; protected validation, package proof, publishing, public verification and terminal release outcome skipped as expected. This is a no-publish observation.
- GitHub connector search returned nine open dependency PRs: #127, #126, #125, #98, #97, #96, #91, #88, #87. They are explicitly deferred to the sustaining dependency/security maintenance triage; inclusion here authorizes no upgrades or merges. Recheck security/adopter urgency before implementation.
- Open issue search returned no issues. Search and run-job observations are dated facts; requery at the next delivery gate. The connector's workflow inventory covers PR runs only, so the installed gh CLI supplied canonical main run inventory and main SHA; job details came from the connector.

## Local Observation

- Branch: feat/164-client-secret-lifetimes.
- HEAD: f8951d74c0e103f697812d070097de262beea25e (v1.46 local archival tag).
- origin/main: a1e39a01aca258d0ac5f36414bf47c45686d92c1; HEAD contains it and is 412 commits ahead, zero behind that observed tracking ref.
- Local main: a1a55de0a931c641fbe176e5c3f9c4737aa62b9d, distinct from remote main; not a synchronized main baseline.
- Three additional registered agent worktrees remain. A fresh read-only check found all three clean. The retry head is contained in the primary branch; the other two heads are not. Retain all three with their existing branch refs until ownership/history disposition is established. Directory age/name is not authorization to discard work.

| Worktree under .claude/worktrees/ | Head | Clean | Head contained in primary | Handoff |
|---|---|---|---|---|
| agent-p02-1791328922 | 9912702614cf833d5930a8c42b9aab09a4e73e1e | Yes | No | Prior agent, ownership unknown; preserve branch/history and reconcile before retirement |
| agent-p142-retry-1791337920 | 5e18d118091a47966bb29300de1fd453bb0880aa | Yes | Yes | Prior agent, ownership unknown; confirm inactivity before normal removal |
| agent-p2-1791320528 | 5feff7a2e444b9493d4dbea6376403de94c23c10 | Yes | No | Prior agent, ownership unknown; preserve branch/history and reconcile before retirement |
- Remaining phase directories 142/143 are historical evidence, not leftover v1.46 phases. v1.46 phases 167–170 were already archived. Do not run blanket phases.clear and relabel older history under v1.46/v1.47.
- init.new-milestone reports latest_completed_milestone v1.44 because newer milestone entries use Completed headings. Authoritative latest completion is v1.46 from MILESTONES.md, archived closeout and tag. Continue at Phase 171; do not infer 162 from that runtime field.

## Preexisting Machine State

The only tracked edit at entry was .planning/state.json, SHA-256 cf20f8428c4777a3e99478b2b4e56750ebed2d74d0761bf74fdc6c28e36b1b80. It describes v1.45, empty phases, and an executing next-step reason; committed HEAD describes v1.44. Both conflict with canonical STATE.md's completed v1.46.

Its author/generating run is unknown. Preserve the complete byte-for-byte before-image in [STATE-JSON-BEFORE.json](STATE-JSON-BEFORE.json) and record the checksum; never pass this snapshot off as current state. The user's new-milestone/state-hygiene instruction authorizes an explicit SDK milestone switch and fresh derived state after preservation. The current task owns only that new generated projection, not the earlier edit. Previous canonical research, strategy/guide and STATE.md are preserved under research/archive/pre-v1.47. Source history/receipts remain unchanged.

## Validation and Pending Entry Work

The fresh repository-owned command bash scripts/maintainer/repo_hygiene_check.sh --ci passed **18 PASS, 0 WARN, 0 BLOCK** on the pre-write checkout. This checks deterministic repository contracts; its generic 'safe to start release prep' message does not establish local/worktree/main acceptance.

No mix ci, external conformance profile, container start, new runtime reproduction, prior-delta PR merge or public release ran during upstream scoping. Run the existing exact-main acceptance gate after reviewed prior delivery reconciliation, with fresh refs, local contributor checks, same-SHA canonical CI and Release no-publish evidence, explicit warning dispositions and worktree ownership. Do not substitute this document for that receipt.
