# v1.48 Planning Baseline

**Observed:** 2026-10-25, before milestone-state writes. **Scope:** planning only; no new product behavior, acceptance receipt or publication.

## Selection and preserved decisions

The owner accepted the recommendation at the new-milestone selection gate with “follow ur recs.” Select **v1.48 Client Authentication Key Isolation & Rotation (SEC-01)** first. Carry [UI quality](../ui-quality-engine/MILESTONE-PROPOSAL.md) as the next substantial candidate, preserving Q1–Q10 and the confirmed final summary. No design-interview question is reopened. The owner subsequently selected “Research first (recommended).” Focused research is approved; requirements and roadmap approval remain distinct GSD gates.

## Source and custody

- Planning entry: `1917aa61c589d25d3e2668f6ef0672f32ef0a388`, branch `milestone/v1.47-core-hardening`, clean before writes. New local planning branch: `milestone/v1.48-client-auth-key-isolation`, created at that exact entry revision to preserve archival and owner-confirmed UI decisions.
- Observed local `main` and `origin/main`: `173059a166e9ade0f5f57c9980b7b2400a98538c`. These are locally observed refs, not refreshed exact-main acceptance. The historical v1.47 receipt remains byte-preserved and is not restamped.
- The entry checkout's `lib`, `priv`, `mix.exs`, `mix.lock`, `scripts`, `docs` and `.github` trees match local main. The test-tree difference is the already-recorded archival of `test/lockspire/qualification_ledger_contract_test.exs`, whose frozen bytes live beside Phase 171 evidence. Other differences include retained milestone history and the UI proposal/interview. Reconcile this delivery delta before implementation; do not merge old branch ancestry blindly or discard it.
- Three historical agent worktrees remain registered at `9912702614cf833d5930a8c42b9aab09a4e73e1e`, `5e18d118091a47966bb29300de1fd453bb0880aa` and `5feff7a2e444b9493d4dbea6376403de94c23c10`. Preserve their prior custody/disposition in [Phase 174 delivery](../../milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md); no removal or ownership inference.
- Preserve retained demo data, stopped containers, volumes, build/dependency artifacts and unknown databases. This run owns planning edits only, not historical resource cleanup.

## Fresh planning preflight

`bash scripts/maintainer/repo_hygiene_check.sh --skip-mix-ci` exited 0: **27 PASS, 6 WARN, 0 BLOCK**. This is a planning preflight, not implementation-entry acceptance. Warnings and dispositions:

| Warning | Disposition |
|---|---|
| Worktrees | Retain historical lanes and their recorded custody; recheck before any retirement. |
| Open PRs | Carry to sustaining dependency/security triage and refresh exact PR urgency before implementation. No upgrade/merge selected. |
| `mix ci` skipped | No fresh contributor-gate claim. The existing exact-main gate must run before product edits. |
| Stopped demo containers | Preserve existing operator/demo resources; no cleanup selected. |
| Demo volumes | Preserve data and caches; do not delete to silence hygiene. |
| Demo build/dependency artifacts | Retain for existing maintainer/demo use; not library package evidence. |

## GSD runtime safeguards

Runtime identity is `@opengsd/gsd-core` 1.18.0. `init.new-milestone` reports latest completion v1.44 because `getLatestCompletedMilestone` matches only `(Shipped:)` headings; v1.45–v1.47 use `(Completed:)`. Canonical [milestone history](../../MILESTONES.md), [v1.47 closeout](../../milestones/v1.47-CLOSEOUT.json) and [roadmap](../../ROADMAP.md) establish completion through Phase 174. Continue at 175; do not rewrite history to accommodate the parser.

The two remaining active-tree phase directories are historical **142/143**, not v1.47 leftovers. Skip blanket `phases.clear`: v1.47 phases 171–174 are already archived, and relabeling old history under v1.47 would corrupt provenance. Preserve both directories unchanged.

Use the SDK `state.milestone-switch` for the new frontmatter/body reset. Before it ran, the existing machine projection was preserved byte-for-byte at `/private/tmp/lockspire-v148-machine-state-e0p9um5_/state-before.json`, SHA-256 `6ee584767d7167fffea35a662efaacdb75bfc767ed44051067ee1c3b6a9a9530`. This is a local before-image, not current state or a portable evidence owner. Keep historical accumulated evidence distinct from the new Current Position. The persistent model-bake warning is configuration drift, not a product failure; do not reinstall tools or alter model preferences as part of SEC-01 initialization. Work proceeds inline unless agent use is explicitly authorized.

During initialization, `state.record-session` re-counted retained Phase 142/143 plans into v1.48 before a scoped roadmap existed (2 phases, 10 plans, 7 completed). This was incorrect current progress, not newly completed work. Re-running the SDK milestone switch restored zero new-milestone progress. Do not call a disk-counting state updater until the new scoped phase list exists; verify that only 175–178 are current afterward. Historical directories remain untouched.

**Initialization approved:** The owner approved all 18 requirements with “lgtm,” then explicitly approved the four-phase roadmap on 2026-10-25. Current phases are 175–178, with no plans or implementation completed. The generated state-contract shortcut is `$gsd-progress --next` with a “plan phase 175” label; this does not establish that discussion occurred. The explicit next action is `$gsd-discuss-phase 175`, consistent with configured `skip_discuss: false`, followed by phase planning. No pending todo files require phase tags.

## Implementation entry requirement

Before any product implementation, reconcile the retained planning/delivery delta onto the intended milestone lineage, refresh main/PR/CI evidence and run the existing exact-main acceptance helper with full local contributor checks, matching canonical push CI, matching no-publish Release and explicit warning dispositions. Preserve unknown work and unique commits. Planning progress does not waive this gate. Package publication remains separate through Release Please and protected exact-ref publishing.
