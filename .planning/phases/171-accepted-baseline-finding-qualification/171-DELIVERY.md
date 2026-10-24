# Phase 171 Cumulative Delivery and Ownership Handoff

**Observed:** 2026-10-24, read-only inventory and GitHub reconciliation.
**Operator/purpose:** GSD executor for plan 171-01; establish delivery provenance before exact-main acceptance or protocol qualification.
**Disposition:** Prior delivery and exact-main entry gate accepted at `fe38beee987b135e87c99e7aa7f2488b4c8613e8`. Original successful receipt retained unchanged. Phase 171 qualification proceeds on an owned branch from that base; historical blockers below are superseded by the dated acceptance and delegated-custody record.

## Run and Checkout Identity

| Field | Observation |
|---|---|
| Checkout | `/Users/jon/projects/lockspire` |
| Branch / HEAD | `feat/164-client-secret-lifetimes` / `64500ca4fac30cb85d3fefbcc51b42c01cd1c921` |
| Configured upstream | `origin/feat/164-client-secret-lifetimes`; local tracking ref `f8dd7712af7f3ef906305db549c6312284339dba`; current remote branch from `git ls-remote` had the same SHA |
| Upstream range | 158 commits ahead, 0 behind (`origin/feat/164-client-secret-lifetimes...HEAD`) |
| Intended acceptance base | Current remote `main`, observed by GitHub API and `git ls-remote` as `a1e39a01aca258d0ac5f36414bf47c45686d92c1` |
| Local `origin/main` | `a1e39a01aca258d0ac5f36414bf47c45686d92c1` at observation |
| Local branch `main` | `a1a55de0a931c641fbe176e5c3f9c4737aa62b9d`; differs from remote `main` |
| Feature range from remote main | Merge base is `a1e39a01aca258d0ac5f36414bf47c45686d92c1`; `origin/main..HEAD` contains 415 commits. The range starts at `5c71d694f9f89ff9366211871c8a0565341039b8` (`docs: start milestone v1.45 DCR Lifetime Enforcement`) and ends at the current HEAD. `git diff --name-only origin/main...HEAD` reports 652 paths changed (77,275 insertions, 3,162 deletions). |
| Current branch PR | GitHub search by head `feat/164-client-secret-lifetimes` returned no PR. |
| Worktree inventory | Primary checkout plus the three registered worktrees below; there is no separate local `main` checkout in `git worktree list --porcelain`. |

The current feature checkout is not an accepted implementation baseline. Its 415-commit range and 652-path diff have not been reviewed here as one cumulative delivery, and no PR associates that range with a reviewed base/head. Do not infer that past phase summaries, commit authorship, cleanliness, or overlap with previously merged PRs supplies that review.

## Working-Tree Edits Preserved

At the inventory, `git status --porcelain=v1 --untracked-files=all` showed exactly two modified tracked paths and no untracked paths:

| Path | SHA-256 at observation | Owner/provenance | Disposition |
|---|---|---|---|
| `.planning/STATE.md` | `77ec1c997aea3c9b2ce311bb19398686e51a44c1aafdcaf6db2d8e7ec71c5a7f` | Parent/orchestrator phase-start update, identified in dispatch context; not authored or changed by this executor | Preserved in place; excluded from this task's staging. |
| `.planning/state.json` | `af5f50b4cec5034a481f148e61a3038eb3563b428142c693c18a58ebfd4436e8` | Parent/orchestrator phase-start update, identified in dispatch context; not authored or changed by this executor | Preserved in place; excluded from this task's staging. |

No snapshot or cleanup was made. The two hashes identify the observed current bytes; the files remain parent-owned changes and must not be folded into this handoff commit.

## Registered Worktrees and Unique History

All three secondary worktrees were clean (`git status --porcelain=v1 --untracked-files=all` empty). The branch labels and commit author fields do not identify the responsible agent/operator. Owners, original purposes, and last activity beyond the recorded commit dates remain unknown.

| Path / branch | HEAD | Merge base with current `origin/main` | Range vs `origin/main` | Relationship and review/disposition |
|---|---|---|---|---|
| `.claude/worktrees/agent-p2-1791320528` / `worktree-agent-p2-1791320528` | `5feff7a2e444b9493d4dbea6376403de94c23c10` | `877a0f758aa0bbd5433cbe3d70f1476fa0e12223` | 77 commits unique to this branch; 23 current-main commits absent | Contains a Phase 142 correction/review line. No PR was found for this branch. The 77-commit range has no owner-confirmed review or disposition. Preserve branch and worktree; do not merge, rebase, reset, or remove. |
| `.claude/worktrees/agent-p02-1791328922` / `worktree-agent-p02-1791328922` | `9912702614cf833d5930a8c42b9aab09a4e73e1e` | `877a0f758aa0bbd5433cbe3d70f1476fa0e12223` | 85 commits unique to this branch; 23 current-main commits absent | Descends from the p2 HEAD and adds 8 commits (`5feff7a2..99127026`). No PR was found for this branch. This larger range has no owner-confirmed review or disposition. Preserve branch and worktree; do not merge, rebase, reset, or remove. |
| `.claude/worktrees/agent-p142-retry-1791337920` / `worktree-agent-p142-retry-1791337920` | `5e18d118091a47966bb29300de1fd453bb0880aa` | `5e18d118091a47966bb29300de1fd453bb0880aa` | 0 commits unique to this branch; 22 current-main commits absent | The head is contained in current `origin/main` and in the primary feature checkout. No unique commit is at risk relative to current main, but owner, purpose, and authorization to retire the worktree are unknown. Preserve until its owner confirms normal removal. |

The 77- and 85-commit ranges overlap; they must not be added as if they were separate deliveries. Git records `szTheory` as author/committer for the sampled tip commits, but that identity does not establish ownership of the worktrees or approval of their ranges.

## Remote PR and Main History

Read-only GitHub API/CLI observations and local ancestry checks establish:

| PR | Actual head/base and outcome | Relevance and limit |
|---|---|---|
| [#112](https://github.com/szTheory/lockspire/pull/112) | `gsd/phase-141-maintenance-baseline-closure` head `9d38928be44a7f137bb8f39fd1bd29f84ddf06b1`, base `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; merged 2026-10-07 | Restored the corrected Phase 141 maintenance baseline. Its review does not establish review of the separate 77/85-commit Phase 142 worktree ranges. |
| [#113](https://github.com/szTheory/lockspire/pull/113) | `fix/release-main-freeze-guard` head `084e2849a584c5d287add7693e41af37d7abd5d9`, base `5e18d118091a47966bb29300de1fd453bb0880aa`; merged 2026-10-07 | Release guard maintenance; not a disposition for the Phase 142 worktree ranges. |
| [#114](https://github.com/szTheory/lockspire/pull/114) | `gsd/phase-143-lockspire-1-5-1` head `0d8b8db3e9625b9934122abd8a72d181b716cd0e`, base `6f1a19b39999f96eb24352c75c2a0628375175ae`; merged 2026-10-07 | Phase 143 release-publication changes were merged. This preserves a historical delivery fact; it does not authorize edits to archived Phase 143 evidence or settle the separate Phase 142 owner/history. |
| [#122](https://github.com/szTheory/lockspire/pull/122) | `gsd/phase-141-maintenance-baseline-closure-pr` head `20375dc91dae5237b155e32dcb15e2d6fbc389e8`, base `ef6e33be2d8bc8ac438390495990b231b475466c`; merged 2026-10-11 | Later maintenance-baseline PR; no head matches the current feature branch or the two Phase 142 worktree branches. |

The primary checkout contains the Phase 143 PR head and the Phase 142 retry head, but ancestry alone does not establish human ownership of the worktrees. GitHub search found no PR for either `worktree-agent-p2-1791320528` or `worktree-agent-p02-1791328922`, and none for the current `feat/164-client-secret-lifetimes` head. PR history therefore identifies merged historical slices but no reviewed cumulative candidate for the present 415-commit range. Historical phase directories 142 and 143 remain intact and are not relabeled, cleared, or treated as current evidence.

## Checks and Actions

- Read-only runtime precondition passed: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix --version` reported Mix 1.19.5 / Erlang OTP 28.
- Read-only database prerequisite passed: `pg_isready` reported `/tmp:5432 - accepting connections`.
- Remote `main` identity was observed through GitHub API and `git ls-remote`; no fetch or ref mutation was done for this inventory.
- No acceptance script, `mix ci`, case test, contract test, profile, merge, rebase, reset, branch switch, stash, worktree removal, or publication ran. No `171-MAIN-ACCEPTANCE.json` or `171-QUALIFICATION.json` is claimed.

## Blocking Decision and Exact Next Action

**Blocker:** There is no owner-confirmed review/disposition for the current feature branch's 415-commit cumulative range or for the overlapping 77/85-commit Phase 142 worktree line. The existing Phase 141/143 merged PRs do not settle those later deltas. Current local `main` (`a1a55de0a931c641fbe176e5c3f9c4737aa62b9d`) is also not synchronized to remote `main` (`a1e39a01aca258d0ac5f36414bf47c45686d92c1`), and the current checkout is not a clean owned main checkout.

**Next owner:** Repository maintainer / owners of the Phase 142 agent worktrees. The recorded worktree owners are unknown and must be identified by a responsible maintainer; branch names and commit author metadata are insufficient.

**Required decision:** Confirm whether `feat/164-client-secret-lifetimes` is the intended cumulative delivery candidate. If so, identify its exact reviewed PR/head/base and disposition, and explicitly account for the Phase 142 worktree ranges (including whether they are included, superseded, or remain separate). If not, name the intended delivery candidate and exact PR/head/base. Separately, identify the owners/purposes of the three retained worktrees and authorize a specific preserve/hand-off/retirement disposition for each. No merge/rebase/reset/cleanup choice is implied by this record.

**Resume sequence after that decision:** (1) responsible maintainer reviews and records the exact cumulative delivery range and worktree dispositions; (2) use an intentionally owned clean checkout of `main`, refresh `origin/main`, and verify `HEAD`, `refs/heads/main`, and `refs/remotes/origin/main` all equal the freshly observed 40-character SHA; (3) only then run the existing `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$LOCKSPIRE_ACCEPT_SHA" --format json` and retain its original successful stdout; (4) continue the Phase 171 tracer and case qualification on the implementation branch only after the acceptance gate passes.

**Continuation state:** Plan 171-01 is blocked in task 171-01-01 before accepted-main acceptance and before case qualification. `BASE-01` and `FIND-01` are not complete. Do not dispatch plan 171-02, create a SUMMARY claiming completion, mark requirements complete, or treat this handoff as authorization to integrate or publish.

## Maintainer delegation and reconciliation — 2026-10-24

After this checkpoint, the maintainer instructed this run to unblock delivery,
follow its recommendations, fan out relevant reviews, and continue. The current
authorized run therefore takes custody of the preservation and delivery
decisions. Historical operators remain unknown; their identities are not a
prerequisite to preserving their exact refs under current delegated custody.

The three independent reviews and their coherent disposition are recorded in
[`../../DELIVERY-RECONCILIATION.md`](../../DELIVERY-RECONCILIATION.md). All three
secondary worktrees and the original local main are retained unchanged. The
completed v1.45/v1.46 candidate at `f8951d74c0e103f697812d070097de262beea25e`
will use a reconciliation PR; unfinished v1.47 planning stays on this branch
until an owned implementation branch can start from accepted main. Two narrow
prerequisite corrections are required: Release graph drift in the sole
acceptance script and current contributor lint failures. Neither is protocol
implementation. Automatic Release Please merging has been explicitly paused
using the existing repository variable, verified `false`, to keep integration
from triggering publication.

The original observation and blocker text above is retained as history. Its
missing decision has now been supplied; fresh checks, reviewed integration and
exact-main acceptance remain mandatory before task 171-01-01 qualification.

### Reviewed reconciliation PR

Opened [PR #138](https://github.com/szTheory/lockspire/pull/138) from owned
`milestone/v1.46-cumulative-delivery`, head
`3413d0854abb5d7aab778db42276c0588b78ce84`, base
`a1e39a01aca258d0ac5f36414bf47c45686d92c1`. The owned checkout is
`/tmp/lockspire-171-delivery`. It starts at the completed v1.46 archival, carries
only attributed gate/lint/security corrections and the reconciliation record,
and excludes unfinished v1.47 planning. All non-planning tracked bytes were
verified identical to the successful contributor source in the preserved
original checkout (`b825beaa`, source corrections through `ddb9237d`).

Complete contributor evidence: `LOCKSPIRE_TEST_DB_NAME=lockspire_171_delivery_20261024a ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix ci`
exited zero: 15 architecture, 2,031 fast, and 199 integration tests; two
properties; zero failures. This is candidate evidence, not main acceptance.
The original shared database was retained; its historical rows were not deleted
to make tests pass. Protected checks at the exact PR head and normal squash
integration remain pending. Keep the remote reconciliation branch after merge
to preserve original commits under enforced linear main history.

### Hosted prerequisite corrections

The first PR run `40117908804` blocked on the release runtime's existing
`undici 6.29.0` advisories and the clean test-environment fixture warnings.
These were corrected separately, not suppressed: only the `undici` lock entry
advanced to 6.29.1; duplicate trace clauses were removed; the empty router scope
became `/` while its logical session prefix stayed unchanged. npm audit reports
zero vulnerabilities; all three runtime contracts and the actual ESM import
pass; forced test compilation with warnings-as-errors passes; 34 admin-route
regressions pass. See the reconciliation record for upstream primary sources.

Current PR head is `ae78be8c07e0e3df5b1dd2e156b72758df607798`, still based on
`a1e39a01aca258d0ac5f36414bf47c45686d92c1`. Current canonical PR CI run:
[`40118254627`](https://github.com/szTheory/lockspire/actions/runs/40118254627).
Release Hygiene Drift has passed at this head; the other protected checks are
pending. No earlier partial run authorizes this head. Release auto-merge was
read back `false` again after the update. No main integration, acceptance
receipt, qualification or publication has yet occurred.

### Final corrected delivery candidate

The original package-only failures are now reproduced and fixed in the proof
host, with no library/generator/CSRF-policy change. Original full regressions
passed (3 tests / 0 failures, 244.7 seconds), and hosted run `40120980612`
subsequently passed its complete Integration job, including packaged-host
browser proof. Its only failed required job was the minimum-runtime lint
contract scanning an untracked generated dependency Git hook. The tracked-file
inventory correction and positive call-marker regression are committed and
verified; existing hygiene suite 11/11 and strengthened focused test 1/1 pass.

Current published PR #138 head:
`6283537530f7c48cc5e982665ea0ed28852ca7a2`, base unchanged at
`a1e39a01aca258d0ac5f36414bf47c45686d92c1`.
Fresh canonical PR CI:
[`40122695863`](https://github.com/szTheory/lockspire/actions/runs/40122695863).
The source-review scope and root/candidate non-planning tree equality were
checked again. All seven checks must pass at this head; older partial or
successful jobs are corroboration only. No main merge or acceptance receipt
exists yet. Keep the source fixed while these final checks run.

### Reviewed integration and fresh main acceptance in progress

All seven protected checks and dependency review passed at exact PR head
`6283537530f7c48cc5e982665ea0ed28852ca7a2`; fresh protection observation
confirmed strict checks, administrator enforcement, linear history, conversation
resolution and zero required human approvals. No review threads were unresolved.
The normal exact-head squash merge completed on 2026-10-24T19:18:04Z:
[PR #138](https://github.com/szTheory/lockspire/pull/138), main
`fe38beee987b135e87c99e7aa7f2488b4c8613e8`. The delivery branch remains remote
and preserves original cumulative history. No admin bypass, branch deletion,
release dispatch or publication was performed.

The owned acceptance clone inherited an `origin/main` tracking identity from
its local source clone (`a1a55de0`), which differs in ancestry after squash.
That identity was preserved as `archive/cloned-main-a1a55de0` with no upstream,
then the owned tracking ref was refreshed from the actual remote. No original
primary ref or worktree was reset. The clone's clean `HEAD`, local `main` and
`origin/main` independently equal the fresh full merged SHA above; its full tree
also matches reviewed candidate `62835375`.

The existing sole authority is now running on that synchronized main with
Elixir 1.19.5 / OTP 28.5 and new owned database
`lockspire_171_main_20261024a`. It runs `mix ci` itself and polls the canonical
same-SHA push CI using the documented bounded `--wait-seconds 3600` option;
no duplicate contributor gate is launched. Original stdout is captured outside
the clean checkout, and will be retained as `171-MAIN-ACCEPTANCE.json` only after
zero exit. External identity observation is also outside the checkout. Existing
stopped demo containers and three demo volumes remain untouched, with exactly
one bounded disposition for each observed warning.

Canonical push CI is [40124665878](https://github.com/szTheory/lockspire/actions/runs/40124665878).
Same-SHA push Release [40124665919](https://github.com/szTheory/lockspire/actions/runs/40124665919)
completed successfully; its actual six-job no-publish shape remains for the
sole authority to verify. Release auto-merge was read back `false` again.
Acceptance is not yet claimed; no qualification or phase summary exists.

### Acceptance caller correction — original failed attempt retained

The first sole-authority attempt exited 1 after its local contributor gate,
canonical push CI and Release no-publish checks passed. Its exact result was
22 PASS, 2 WARN, 1 BLOCK: the caller supplied prose warning dispositions, while
the existing CLI requires `^[a-z0-9][a-z0-9._-]{0,63}$` tokens. The failed text
report and first identity observation are retained externally as attempt 1;
no accepted JSON was created or copied from that attempt.

The unchanged authority is rerunning on the same fresh synchronized main with
new owned database `lockspire_171_main_20261024b`. The two observed-warning
values now satisfy the existing grammar:

- `adoption demo stopped containers=retained_maintainer_review_before_demo`
- `adoption demo volumes=preserved_data_review_before_demo`

These codes retain the already reviewed meaning: preserve preexisting stopped
containers and all demo data/cache volumes; the repository maintainer reviews
them before the next demo run. No cleanup, script validation relaxation, new
acceptance implementation or separate contributor command was used. Original
JSON is still gated on the rerun's zero exit. Lesson: validate the documented
CLI's actual data grammar before a long attestation run, and keep explanatory
prose in the delivery record instead of its bounded receipt fields.

### Accepted entry and owned implementation branch

The corrected invocation of the **unchanged** sole authority exited zero.
Original stdout is retained byte-for-byte as `171-MAIN-ACCEPTANCE.json`:
1,933 bytes, SHA-256
`be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`.
Its original schema remains `lockspire-phase-139-acceptance-v1`; it was not
renamed, reconstructed or supplemented with another acceptance verdict.

Accepted SHA: `fe38beee987b135e87c99e7aa7f2488b4c8613e8`.
The receipt records the complete local `mix ci` gate as pass with 199 executed
integration tests in its existing counter, all seven canonical same-SHA push CI
jobs as pass (run `40124665878`), and the six-job push Release no-publish result
as pass (run `40124665919`). Hygiene is 22 PASS, 2 WARN, 0 BLOCK; both warnings
have the exact bounded dispositions recorded above. No package was published
by this run; release auto-merge remains paused for the release-owner handoff.

After acceptance, primary `origin/main` was freshly advanced to that same SHA.
The old primary local main identity `a1a55de0` was preserved losslessly as
`archive/main-a1a55de0-before-171` with no upstream, and local `main` was recreated
tracking the accepted remote main. Original feature branch
`feat/164-client-secret-lifetimes` remains at
`c74d1552877e1c9507fa19d6c07a18eedfa27bc7` and is not deleted or rebased. The
remote reconciliation branch still retains the cumulative original history;
squash integration does not claim the old commits became main ancestors.

Owned implementation branch: `milestone/v1.47-core-hardening`, created directly
from the accepted full SHA. Exactly 44 attributed planning paths were restored
from the preserved feature branch; no product, dependency or integration code
was transported over accepted main. The original receipt was then copied.
No ledger, qualification contract or plan summary exists yet: entry is complete,
and the remaining tracer/contract work in task 171-01-01 must actually execute.

Fresh secondary-worktree inventory after acceptance: all three are clean and
unchanged at their recorded tips. Relative to accepted main, p2 retains 77
unique commits / 24 main commits absent; p02 retains 85 / 24; retry retains 0 / 23.
Current custodian remains this delegated maintainer run, with preserve-in-place
and no integration/cleanup selected. Original operator identities remain
historically unknown. Their preservation is not an unresolved acceptance-owner
decision. Existing shared test DB and all preexisting demo resources are retained;
only new task databases were used for this work.

Planning transport normalized seven preexisting Markdown hard-break trailing-space
lines for the staged whitespace check. Original bytes remain in the preserved
feature branch; no recorded facts, JSON before-images or original receipt bytes
were changed.

## Current qualification tracer — 2026-10-24

The accepted entry is unchanged: `171-MAIN-ACCEPTANCE.json` remains the original
1,933-byte stdout receipt with SHA-256
`be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39` and
`baseline_sha` `fe38beee987b135e87c99e7aa7f2488b4c8613e8`. It was verified in
place; the exact-main authority was not rerun for ledger bookkeeping.

At source SHA `5cefc4ea31c812ac19f513fb3ee0c5dcc275cf83`, the named repository
test `test/integration/phase37_protocol_strictness_e2e_test.exs:106` ran with
`mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs:106`.
Result: 1 test, 0 failures, 4 excluded. A request whose redirect URI differed
from its registered URI by a trailing slash returned HTTP 400, a browser-safe
error body, and no `Location` header. This records A171-001 against OIDC Core
3.1.2.6 and the exact-match support statement in `docs/supported-surface.md`;
it does not establish behavior for valid callbacks.

This is source-host evidence for Lockspire's generated Phoenix endpoint. No
package was installed or tested and no external conformance suite ran; those
evidence categories are explicitly `not_applicable` in the draft qualification
ledger. Phase 171 Plan 01 is still in progress until its contract and negative
fixtures pass; the full finite FIND-01 inventory and frozen matrix remain for
the later phase plan.

## Custody and path handoff

The current delegated maintainer run owns this qualification work on
`milestone/v1.47-core-hardening`, now descended from the accepted implementation
base. Its newly created ledger and contract test live in this primary checkout;
they are not copied into the retained historical feature branch or the original
acceptance clone. The accepted receipt path above is a byte-preserved artifact
copied into this checkout after acceptance, not an acceptance rerun. The original
feature branch and three secondary worktrees remain preserved at the identities
and dispositions recorded above. Their historical operator identities remain
unknown, so no worktree ownership is transferred by this handoff. Next owner for
the finite inventory is the Phase 171 maintainer; next action is to complete
plan 171-02 after this plan's contract and closeout pass. No other retained path
is being merged, rebased, reset, or retired here.

## Frozen FIND-02 handoff — 2026-10-24

Plan 171-03 completed on `milestone/v1.47-core-hardening`, based on accepted
main `fe38beee987b135e87c99e7aa7f2488b4c8613e8`. The frozen qualification
source revision is `6d9a5db65f8cc3cb8c64ea0dd51ad022a6b18945`; the selected-input
manifest has 29 ordered entries and digest
`d8c54d497be1a2e6a6a5a5e2a2bb3da311253a4c4a5ad62a87931755f2996fad`.
The original accepted receipt remains byte-identical (1,933 bytes; SHA-256
`be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`). No
product runtime, dependency, migration, public API, runner or default test
discovery files changed. No external suite or Python wrapper was launched; its
exact-environment prerequisite and original owner/action remain recorded as a
nonblocking supplemental limitation. Existing historical worktrees and shared
resources remain preserved; this execution created no worktree and performed
no cleanup or publication action. Release auto-merge remains paused.

The explicitly invoked qualification probe ran two controlled HTTP cases and
exited 2 with 2 tests, 2 failures, 0 skipped: both valid-path controls passed,
then the expected normative assertions failed. A171-003 observed HTTP 302 to
the registered callback with `error`, `error_description`, `iss`, and `state`
parameters where HTTP 400 without Error Response parameters was required.
P171-005 observed HTTP 400 rather than consent with pushed `openid email`,
unchanged state/nonce and no outer `profile`. These are source-bound protocol
counterexamples assigned to Phases 172 and 173, not passes or unresolved
qualification blockers. The earlier matrix-contract run passed 18 tests. The
final post-metadata-audit run passed 19 tests with 0 failures, including
negative drift/blocker/disposition checks and a valid empty-scope frozen fixture
that requires explicit requirement and roadmap amendments without inventing
passing case evidence. The frozen artifact preserves all twelve case IDs,
the seven-category coverage, all six downstream requirement dispositions,
and the case-backed references and owners. A-EDGE-FIND-02 remains unclassified;
descriptorless prohibitions remain `flagged-unverified`.

The requirement and roadmap amendments narrow Phase 172 to A171-003's unsupported
`response_mode` correction while carrying forward the existing authorization
proof. Phase 173 is narrowed to P171-005's pushed-scope authority correction
while carrying forward existing PAR lifecycle, required-PAR and source-host
metadata proof. Both corrections require the existing regression owner to show
RED at the qualified source and GREEN after correction. Phase 174's CPROOF and
DELIV proof obligations remain intact. Planning may proceed against this frozen
scope after the existing accepted-main prerequisite; this handoff does not
claim milestone integration or publication.

Two durable lessons: follow normative reference chains before treating a
behavior as discretionary policy; and model deliberate normative RED as an
observation task rather than a green-tracer expansion gate. Preserve the actual
expected failures visibly so correction owners can reproduce them.
