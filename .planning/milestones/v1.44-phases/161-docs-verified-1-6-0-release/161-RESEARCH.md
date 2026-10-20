# Phase 161: Docs & Verified 1.6.0 Release - Research

**Researched:** 2026-10-19
**Domain:** Release engineering (Release Please, protected exact-ref Hex publish), reader docs + contract tests, safety sweep
**Confidence:** HIGH on mechanics (each was read in this session or run against the real 1.5.1 artifact); MEDIUM on the gate-repair recommendation (needs a maintainer decision)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Docs (DOC-02)**
- **D-01:** `docs/install-and-onboard.md` and `docs/upgrading/signing-key-encryption.md` already describe `mix lockspire.gen.kek`, `--raw` and `{:system, "VAR"}`. Re-read them against shipped code (`lib/mix/tasks/lockspire.gen.kek.ex`, config KEK handling) and fix drift only; no rewrite.
- **D-02:** Add a short "Key protection" subsection to `docs/operator-admin.md`. Use the PRODUCT.md "UI says" state labels exactly as shipped in `lib/lockspire/web/live/admin/keys_live/protection.ex` (Encrypted / Encrypted, some with an older key-encryption key / Some keys are stored unencrypted / Some keys cannot be read / Not set up / Setup needs attention / Unknown). It must say that the line is read-only, that Unknown is not a healthy result, and that the missing-KEK generate error points to `mix lockspire.gen.kek` and the upgrade guide. Write for the least technical operator persona (AGENTS.md admin-copy rules).
- **D-03:** Lock the new operator-guide content with a contract test alongside `test/lockspire/documentation_contract_test.exs` / `kek_guidance_contract_test.exs`. `vocabulary_contract_test.exs` must stay green.
- **D-04:** Do not change `docs/supported-surface.md`. Adding `gen.kek` there would widen the supported-surface claim.
- **D-05:** Run `mix docs.verify` (ExDoc `--warnings-as-errors`) on Elixir 1.19.5 / OTP 28, matching CI. Local 1.20.4 type warnings are not a docs failure signal.

**Landing v1.44 and Release Please PR #121 (REL-01)**
- **D-06:** Local `main` holds v1.44 unpushed (about 100 commits ahead of `origin/main` at `038df080`). Follow the v1.43 precedent (PR #131): put the work on a `milestone/v1.44-<slug>` branch, open one PR, get CI green, and squash-merge it with one conventional title (e.g. `feat(keys): ... (v1.44)`). Then reset local `main` to `origin/main`. Never push the phase commits straight to main, because each one would become a changelog entry.
- **D-07:** The v1.44 PR title and body must not claim that "every DB-touching task" starts the repo, because `mix lockspire.keys.reencrypt` still uses raw `Ecto.Migrator.with_repo`.
- **D-08:** Fix the missing v1.40/v1.41 changelog coverage with a `BEGIN_COMMIT_OVERRIDE ... END_COMMIT_OVERRIDE` block in the body of the merged PR #122. Use conventional lines for the v1.40 admin operator UI refinement and the v1.41 language/docs work, then let Release Please regenerate #121. Do not hand-edit #121, because regeneration overwrites it. Before acting, check the vendored release-please (`.github/actions/release-please/runtime/node_modules/release-please/build/src/commit.js` ~line 376) to confirm that an override on an already-merged PR's body is picked up and how multiple lines render.
- **D-09:** Re-read the regenerated #121. Confirm that it proposes 1.6.0 and that the changelog covers v1.40–v1.44, then squash-merge it manually. Keep the `Release Please Auto Merge` workflow disabled until 1.6.0 is verified. Leave the Dependabot Actions PRs #125–#127 unmerged until after publish.

**Publish & Independent Verification (REL-02)**
- **D-10:** Reuse the Phase 143 procedure exactly, with no workflow changes. Start from the #121 squash SHA, which must equal `origin/main` and have its own successful CI push run:
  1. Set `LOCKSPIRE_PHASE143_AUTHORIZED_SHA`.
  2. Dispatch `release.yml` with `recovery_ref`, `source_ci_run_id` and `recovery_reason`.
  3. The maintainer approves the `hex-publish` environment.
  4. Clear the variable afterwards.
- **D-11:** Verify independently from public sources:
  - The Hex API checksum matches both the manifest and the SHA-256 of the downloaded outer tarball.
  - HexDocs serve `/lockspire/1.6.0`.
  - The `lockspire-v1.6.0` tag (peeled) and the GitHub release target equal the source SHA.
  - An explicit tarball listing shows `lib/mix/tasks/lockspire.gen.kek.ex` and the other new Mix tasks. This step is new because no existing script lists tarball contents.
  - A clean-room host installs `{:lockspire, "== 1.6.0"}` in a fresh `HEX_HOME`.
- **D-12:** Record the result in `.planning/RELEASE-TRAIN.md` using the existing Current Baseline / Current Main Readiness format, and refresh the 1.5.1-era lines.

**Safety Sweep (SAFE-02)**
- **D-13:** "Milestone diff" means the v1.44 diff (`038df080..<v1.44 squash commit>`), not the full 1.5.1→1.6.0 range. v1.43's intentional Bandit/`mix.lock` change is outside the check.
- **D-14:** The proof has two parts:
  1. Diff checks that `mix.exs`, `mix.lock`, `priv/repo/migrations`, `lib/lockspire/protocol` and security-default config keys are unchanged.
  2. Re-run and cite the existing redaction/no-leak tests, plus a grep of the v1.44 `lib/` diff for `Logger`, `:telemetry`, `IO.puts`, `Mix.shell` and raise sites near key or KEK values.

  The only allowed key output is `gen.kek` stdout.

**Maintainer-Only Actions**
- **D-15:** These are the user's to approve or perform, and plans must checkpoint before each one:
  - Pushing the v1.44 branch and squash-merging its PR.
  - Editing the body of #122.
  - Squash-merging #121.
  - Setting and clearing the authorized-SHA variable.
  - Dispatching `release.yml`.
  - Approving `hex-publish`.
  - Deciding when to re-enable auto-merge.

### Claude's Discretion
- Exact wording of the operator-guide subsection and the override lines, within the vocabulary map and conventional-commit format.
- Exact `milestone/v1.44-<slug>` branch name and the v1.44 squash title.

### Deferred Ideas (OUT OF SCOPE)
- `2026-10-13-audit-dcr-default-lifetime-semantics.md`: protocol work, owned by a later DCR lifetime milestone (DCR-01).
- `2026-10-19-keys-reencrypt-via-repo-runner.md`: Mix task behavior change. Deferred to a post-1.6.0 quick task so the release diff stays quiet (see D-07).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-02 | Install, upgrade and operator guides describe `gen.kek`, `{:system, "VAR"}` and the Key protection line; `mix docs.verify` passes on CI Elixir | Docs already carry gen.kek and `{:system,...}` (see "Docs drift audit"); operator guide gap = Key protection subsection; `mix docs.verify` exit 0 at HEAD on 1.19.5-otp-28 (run this session) |
| REL-01 | After v1.44 is on main with CI green, regenerated #121 is re-read and squash-merged | Override mechanics proven offline; **release-train gate blocker found** (see Critical Finding 1) |
| REL-02 | 1.6.0 published via protected exact-ref lane and independently verified | Full command list below, every public-side command exercised against 1.5.1 |
| SAFE-02 | No protocol/security-default/schema/dependency change; no key material or KEK in output other than gen.kek | Path checks and grep sweep already run (results below); 109 targeted tests green |
</phase_requirements>

## Summary

All five research targets resolve cleanly, but I found one hard blocker that CONTEXT.md did not anticipate. `scripts/maintainer/repo_hygiene_check.sh --ci` (the required "Release Hygiene Drift" check) and two test-support assertions pin `.planning/RELEASE-TRAIN.md` to the **post-publish** state: metadata version must equal the "Latest public package" version. Release Please's #121 bumps the metadata line to 1.6.0 on merge while the public line still (truthfully) says 1.5.1. I simulated that state in a scratch copy and the hygiene gate returns `[BLOCK] release train ledger`. The exact-ref publish lane requires a successful CI push run on the exact publish SHA, so the #121 squash SHA would never be publishable as-is. #122 (e67a4898) removed the old "pending publication" ledger form that used to allow this. The fix has to land **before** #121 is merged (see Critical Finding 1 and Open Question 1).

The Release Please override works as hoped. The vendored release-please 17.11.2 reads the **current** PR body of the merged PR through GraphQL `associatedPullRequests` on every run, and #122's squash commit `e67a4898` sits after tag `lockspire-v1.5.1` (`0b565038`), so it is inside the release range. I ran the vendored `parseConventionalCommits` offline against a fake #122 body and confirmed multi-line overrides expand into separate conventional commits, blank-line separated. Today, with no override, #122 parses as type `Lockspire` and is dropped, which is why #121 omits v1.40/v1.41. Best trigger: edit #122's body **before** squash-merging the v1.44 PR, so the push to main that merges v1.44 regenerates #121 once with everything in it.

The publish and verification procedure is the Phase 143 lane unchanged. Every public-side verification command below was run against the real 1.5.1 release this session (Hex API checksum equals the outer tarball sha256 and equals the outer-checksum field Hex writes into a clean host's `mix.lock`). One correction to CONTEXT: of the Mix tasks in the working tree, `lockspire.test.setup` is excluded from the package, so the 1.6.0 tarball should gain exactly three tasks over 1.5.1: `lockspire.doctor.key_encryption`, `lockspire.gen.kek`, `lockspire.keys.reencrypt`.

**Primary recommendation:** Add a "release-train gate" wave before any push (make the hygiene gate and the two pinned test helpers tolerate `metadata > public` while public/artifact/tag/source-SHA stay mutually consistent, and derive pinned strings from the file instead of hardcoding 1.5.1), land it in the v1.44 PR, edit #122's body, then squash v1.44, re-read the regenerated #121, squash #121, and run the Phase 143 lane from that SHA.

## Critical Findings

### Critical Finding 1: Merging #121 breaks three CI gates (blocker, needs a decision)

[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:676-694, read this session] `release_train_has_consistent_versions` ends with:

```
[[ "$public_version" == "$metadata_version" && "$public_version" == "$artifact_version" && "$public_version" == "$tag_version" && "$public_source_sha" == "$artifact_source_sha" ]]
```

[VERIFIED: scratch simulation, this session] Copying HEAD to a scratch dir, setting `mix.exs` to 1.6.0, the manifest to 1.6.0, the top CHANGELOG heading to `## [1.6.0]` and the metadata line to `1.6.0` (exactly what #121 changes) while leaving "Latest public package ... `1.5.1`" yields:

```
[PASS] release versions: mix.exs, manifest, and top changelog entry all point at 1.6.0
[BLOCK] release train ledger: RELEASE-TRAIN.md is missing, malformed, or out of sync with mix.exs=1.6.0
Summary: 17 PASS, 0 WARN, 1 BLOCK
Result: not ready
```

On HEAD today the same script is `18 PASS, 0 WARN, 0 BLOCK`. `Release Hygiene Drift` is a required status check on main [VERIFIED: `gh api .../branches/main/protection` contexts list: "Adoption Demo Smoke","Complete Coverage Evidence","Dialyzer","Fast Checks","Integration Checks","Minimum Supported Elixir/OTP","Release Hygiene Drift"].

Two more places hardcode the 1.5.1 ledger and will fail in `Fast Checks` the moment metadata becomes 1.6.0:

- `test/support/lockspire/release_proof/workflow_assertions.ex:114` `assert release_train =~ "Release Please version metadata: `1.5.1`"`, plus lines 117 and 131 (public line with `0b56503859b69531ff86d8e4a465a0e75f963594`, the `lockspire-v1.5.1` link). Invoked by `assert_current_release_truth!` from `test/lockspire/release/release_automation_contract_test.exs:11`.
- `test/support/lockspire/release_proof/package_assertions.ex:116-122` (`assert_phase_139_release_train_fail_closed!`) builds its negative cases with `String.replace` on the literal 1.5.1 lines.

Why it worked for 1.5.1: the pre-#122 script accepted a "pending" public line (`Hex lists X as latest ...; the exact Y release query returned HTTP 404`) and compared Y to metadata. [VERIFIED: `git diff 0b565038 HEAD -- scripts/maintainer/repo_hygiene_check.sh`, removed `release_train_public_query_version`]. The 1.5.1 publish SHA `0b565038` was also a later fix commit, not the release-PR squash `3e682caf`, so a repair commit between "release PR merged" and "publish" has precedent.

**Options (planner must present to the user; this edits CI gates, so it is a maintainer decision):**

1. **Recommended: pre-land the repair in the v1.44 PR.** Relax the hygiene equality to "public == artifact == tag and public_source_sha == artifact_source_sha, and metadata_version >= public_version (semver compare), and metadata == mix.exs" (a pending release is a legitimate state; the public line stays truthful at 1.5.1 until publish). Rewrite the two test-support helpers to read versions/SHAs from the file (regex capture) instead of literals, keeping each negative case. After this, the #121 squash SHA is green by itself and D-10 ("start from the #121 squash SHA") holds unchanged. Cost: the v1.44 diff then contains `scripts/` and `test/support/` changes (none of them in the SAFE-02 forbidden categories, but say so in the PR body).
2. Squash #121 anyway, then land a small `chore(release):` fix PR and publish the fix commit's SHA (the 0b565038 precedent). Costs an extra PR and deviates from D-10's "start from the #121 squash SHA". The gate repair is identical, only later.
3. Not viable: editing #121 (regeneration overwrites it) or pre-claiming 1.6.0 in the public line (publication proof would be false).

After publish, the D-12 ledger refresh must keep the exact line templates the script parses (see "RELEASE-TRAIN.md refresh" below).

### Critical Finding 2: Local state differs slightly from CONTEXT

[VERIFIED: `git status -sb`, `git log origin/main..main --oneline | wc -l`, this session] `## main...origin/main [ahead 102]`, one tracked file modified and uncommitted (`.planning/state.json`). `git rev-parse origin/main` = `038df080748c046829f9f98297da8403c47b4d89`. A bare `git reset --hard origin/main` after the squash would **discard the uncommitted `state.json` edit**; stash or commit it first.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reader guides (install, upgrade, operator) | Docs (ExDoc extras in package) | CI contract tests | Guides ship in the Hex package and HexDocs; contract tests lock wording |
| Changelog/version generation | GitHub (Release Please via `release.yml` push job) | PR bodies on merged PRs | Commit message or PR-body override feeds `parseConventionalCommits` |
| Publish | Protected GitHub Actions lane (`release.yml` dispatch, `hex-publish` env, main freeze) | Maintainer approvals | Exact-ref, SHA-authorized, one-use variable |
| Independent verification | Public sources (Hex API, repo.hex.pm, HexDocs, git remote, GitHub release) | Clean-room host with fresh `HEX_HOME` | Must not trust workflow output alone |
| Safety sweep | Git diff + existing ExUnit tests | grep over v1.44 `lib/` diff | Proves absence of protocol/security/schema/dep change and of key output |
| Release-train ledger | `.planning/RELEASE-TRAIN.md` (parsed by hygiene script and tests) | Release Please extra-files markers | Machine-parsed lines; wording is a contract |

## Standard Stack

No new libraries or packages are installed by this phase.

### Core (tools used)
| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| Elixir/OTP (CI-equivalent) | 1.19.5-otp-28 (+ Erlang 28.5) | `mix docs.verify`, tests | [VERIFIED: `.github/workflows/ci.yml` env `ELIXIR_VERSION: "1.19.5"`, `OTP_VERSION: "28"`; `asdf list` shows 1.19.5-otp-28 and 28.5 installed] |
| release-please (vendored) | 17.11.2 | Changelog/version generation | [VERIFIED: `.github/actions/release-please/runtime/node_modules/release-please/package.json`] |
| gh CLI | authenticated (read calls succeeded) | PR/run/variable operations | [VERIFIED: gh calls this session] |
| curl, python3, tar, shasum, jq, git | system | Verification scripts | [VERIFIED: used this session except jq, which `verify_install_truth.sh` itself requires] |

Local env for every mix command: `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` [VERIFIED: ran `mix docs.verify` and 109 tests with this env, both green].

## Package Legitimacy Audit

No external packages are installed in this phase (docs, scripts, tests, release operations only). The clean-room host fetches `lockspire` and its transitive deps from Hex via `mix deps.get`; those are the project's own published package and its already-locked ecosystem.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### Release flow (data flow)

```
local main (102 ahead of origin/main@038df080)
   |  [checkpoint A: maintainer pushes branch]
   v
milestone/v1.44-<slug>  --PR-->  CI (7 required checks, strict up-to-date)
   |
   |  [checkpoint B: maintainer edits body of merged PR #122: BEGIN/END_COMMIT_OVERRIDE]
   |  [checkpoint C: maintainer squash-merges v1.44 PR; title = one feat line]
   v
push to main --> release.yml "release-please" job (push-only) --> regenerates PR #121
   |  (reads PR bodies via GraphQL associatedPullRequests; override on #122 applies)
   |  [agent: gh pr view 121; confirm 1.6.0 + v1.40..v1.44 entries]
   |  [checkpoint D: maintainer squash-merges #121]
   v
push to main (SHA = S) --> CI push run on S must be success  (needs Critical Finding 1 repair)
   |  [checkpoint E: set LOCKSPIRE_PHASE143_AUTHORIZED_SHA=S]
   |  [checkpoint F: gh workflow run release.yml --ref main -f recovery_ref=S -f source_ci_run_id=<CI run> -f recovery_reason=...]
   v
recovery-validation -> prepublish-proof -> [hex-publish approval, checkpoint G] -> publish (main freeze, tag guard, Hex upload, GH release)
   -> post-publish-install-truth (verify_install_truth.sh) -> terminal-outcome receipt
   |  [checkpoint H: clear variable]
   v
independent verification (public sources) -> RELEASE-TRAIN.md refresh PR -> [checkpoint I: auto-merge decision]
```

### Recommended file layout for plan outputs
```
.planning/phases/161-docs-verified-1-6-0-release/
├── 161-RESEARCH.md          # this file
├── 161-NN-PLAN.md           # planner output
├── 161-SAFE02-EVIDENCE.md   # sweep results (commands + outputs, no secrets)
└── 161-RELEASE-EVIDENCE.md  # run IDs, SHAs, checksum, verification outputs
scripts/release/verify_public_release.sh   # optional new helper (see Verification script); NOT a workflow change
```

### Pattern: Release Please PR-body override

**What:** A `BEGIN_COMMIT_OVERRIDE ... END_COMMIT_OVERRIDE` block in the body of the PR associated with a commit replaces that commit's message for changelog purposes. [VERIFIED: vendored `commit.js` `preprocessCommitMessage`, lines 376-388 as read]

```js
function preprocessCommitMessage(commit) {
    // look for 'BEGIN_COMMIT_OVERRIDE' section of pull request body
    if (commit.pullRequest) {
        const overrideMessage = (commit.pullRequest.body.split('BEGIN_COMMIT_OVERRIDE')[1] || '')
            .split('END_COMMIT_OVERRIDE')[0]
            .trim();
        if (overrideMessage) {
            return overrideMessage;
        }
    }
    return commit.message;
}
```

**Multiple lines:** `splitMessages` splits the override text on `\r?\n\r?\n(?=(?:feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(?:\(.*?\))?: )` [VERIFIED: commit.js:331]. So each entry must be a conventional header and **entries must be separated by a blank line** (a single newline would glue them into one commit body).

**Fetch path:** [VERIFIED: `github.js` lines 244-370] `mergeCommitsGraphQL` queries `associatedPullRequests(first: 10)` including `body` and `mergeCommit { oid }`; the PR is attached only when `pr.mergeCommit.oid === graphCommit.sha` and the merge commit is associated with exactly one PR (squash merge satisfies this; `gh pr view 122` shows `mergeCommit.oid` = `e67a4898db129086f871c0d62f910cfd1bda87a6`, and `e67a4898` is the commit SHA). The body is read live from GitHub on every run, so a later edit is picked up on the next run. No cache.

**Range:** [VERIFIED: git] `lockspire-v1.5.1` is a lightweight tag at `0b56503859b69531ff86d8e4a465a0e75f963594`; `git rev-list --count lockspire-v1.5.1..origin/main` = 8; `e67a4898` is in that range and `git merge-base --is-ancestor e67a4898 3e682caf` is false (it is after the previous release PR commit). #121 currently lists #123, #129, #131, #124, #128, #120 [VERIFIED: `gh pr view 121`] and omits #122 because its title `Lockspire: release, admin UI, ...` parses as type `Lockspire` [VERIFIED: offline run, `"type":"Lockspire"`].

**Offline proof (run this session with the vendored module):** a fake #122 with the block below produced three parsed commits, all with `sha: e67a4898`:

```
feat/admin  refine the operator UI across apps, security, keys, consents and tokens (v1.40)
feat/admin  describe admin pages in task and object language (v1.41)
docs/-      group install, verification and maintenance guides by reader task (v1.41)
```

**Changelog visibility caveat:** `release-please-config.json` sets no `changelog-sections`, so release-please defaults apply: `docs`, `chore`, `test`, etc. are hidden [ASSUMED: release-please default sections, not re-verified in source this session]. If v1.41's docs work should appear in the changelog, give it a `feat` or `fix` type. A `docs:` line is parsed but will not show.

**Recommended override text (append to #122's existing body; keep the existing summary above it):**

```
BEGIN_COMMIT_OVERRIDE
feat(admin): refine the operator UI across apps, security, keys, consents and tokens (v1.40) (#122)

feat(admin): describe admin pages in task and object language and route adopters through task-grouped guides (v1.41) (#122)
END_COMMIT_OVERRIDE
```

Two `feat` lines keep the minor bump unchanged (1.5.1 -> 1.6.0 is already driven by #123/#129/#131). `(#122)` is rendered as a PR link by the default changelog formatter [ASSUMED: matches how `(#123)` renders in #121 body; not source-verified]. The override replaces the whole commit message, so also keep the text free of the word `BREAKING`. Pure sanity check before editing: `gh pr view 122 --json body --jq .body | grep -c BEGIN_COMMIT_OVERRIDE` should print 0 now.

**Trigger:** Edit #122 first, **then** squash-merge the v1.44 PR. The push to main fires `release.yml` job `release-please` (`if: github.event_name == 'push'`) which regenerates #121 with every entry in one pass. Avoid "re-run workflow" as the trigger: the job's second step (`Retry auto-merge when CI finished before Release Please`) runs `gh workflow run release-please-automerge.yml` whenever a successful CI run exists for the SHA, and that workflow is disabled (`gh workflow list --all` shows `Release Please Auto Merge  disabled_manually`), so a rerun on an old push would likely fail that step [ASSUMED: dispatching a disabled workflow errors; not tested because it would change repo state]. On a fresh push CI has not finished, so the step exits 0 early.

**How the v1.44 squash itself parses:** the squash commit body is `* <message>` bullets (see `038df080`'s body), which do not match the blank-line-plus-type splitter, so v1.43's squash produced exactly one entry in #121. [VERIFIED: `git log -1 --format=%B 038df080`; `git log 038df080..HEAD --format=%B | grep -ci BREAKING` = 0; no `BEGIN_COMMIT_OVERRIDE` in any of the 102 commit messages.] To make the v1.44 entry deterministic, optionally also put a single-line override in the v1.44 PR body; not required by precedent.

## Landing v1.44 (REL-01 precondition)

[VERIFIED: `gh pr view 131 --json ...`] Precedent: head `milestone/v1.43-signing-key-encryption`, title `feat(keys): encrypt private signing keys at rest (v1.43)`, 100 commits, squash-merged as `038df080` on 2026-10-16T19:48:36Z; all 8 checks green (Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP, Release Hygiene Drift, dependency-review).

Repo merge settings [VERIFIED: `gh api repos/szTheory/lockspire`]: squash, merge and rebase all enabled; squash title `COMMIT_OR_PR_TITLE`, body `COMMIT_MESSAGES`. Main protection [VERIFIED]: `strict: true` (branch must be up to date with main), `enforce_admins: true`, `required_linear_history: true`, 0 required approvals. `.planning/DEVELOPMENT-TRAIN.md` mandates `milestone/vNEXT-short-slug` and "one PR".

Commands (all maintainer-checkpointed, shown for the plan):

```bash
git fetch origin
test "$(git rev-parse origin/main)" = 038df080748c046829f9f98297da8403c47b4d89   # strict mode: branch must still be current
# Phase 161 repo work (docs, contract test, gate repair, SAFE-02 evidence) is committed to local main FIRST so it ships in the same PR.
git push origin main:refs/heads/milestone/v1.44-adopter-polish                     # [checkpoint A] pushes HEAD without moving origin/main
gh pr create --base main --head milestone/v1.44-adopter-polish \
  --title "feat(install): add mix lockspire.gen.kek, start the repo for setup tasks and show Key protection (v1.44)" \
  --body-file <file>      # D-07: do NOT say "every DB-touching task starts the repo"
# wait for 7 required checks
# [checkpoint B] edit #122 body, [checkpoint C]:
gh pr merge <N> --squash --subject "<same title> (#<N>)"                           # always squash
# afterwards, local cleanup:
git stash push -m state-json .planning/state.json    # or commit it first
git fetch origin && git diff --stat HEAD origin/main  # expect empty if branch tip == squash tree
git branch backup/local-main-pre-v1.44 HEAD
git reset --hard origin/main && git stash pop
```

Title is Claude's discretion (D-06 allows). `feat` is correct because `gen.kek`, the `{:system, ...}` option and the Key protection line are additive features. Branch tip tree equals the squash tree only if the branch is current with main when merged, which `strict: true` enforces.

## Publish procedure (REL-02), step by step

Sources read: `.github/workflows/release.yml` (dispatch inputs `recovery_reason`, `recovery_ref`, `source_ci_run_id`, all required), `docs/maintainer-release.md` lines 44, 141, 166, 187-193, `143-RESULT.md`, `scripts/publish/verify_install_truth.sh`, `release_artifact.py`. Note: the archived Phase 143 directory contains only `143-RESULT.md` and `receipt-download/` (no PLAN files); the procedure is reconstructed from the workflow and `maintainer-release.md`.

Repository state right now [VERIFIED: gh]: only variable `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED=true` exists (set 2026-10-08), `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` is absent; environment `hex-publish` exists; `Release Please Auto Merge` workflow is `disabled_manually`; `Release` and `CI` are active.

```bash
# --- 0. Preconditions (agent, read-only) ---
export REPO=szTheory/lockspire
git fetch origin --tags
S=$(git rev-parse origin/main)                       # must be the #121 squash commit (or the post-fix SHA under Option 2)
gh pr view 121 --json state,mergeCommit --jq '{state,sha:.mergeCommit.oid}'
test "$(sed -nE 's/^[[:space:]]*version:[[:space:]]*"([^"]+)".*/\1/p' mix.exs | head -1)" = 1.6.0   # on a checkout of $S
CI_RUN=$(gh run list --workflow ci.yml --branch main --event push --commit "$S" --status success --json databaseId --jq '.[0].databaseId')
test -n "$CI_RUN"
gh run view "$CI_RUN" --json jobs --jq '.jobs[]|.name+" "+.conclusion'   # 7 required jobs success
gh variable list | grep -c PHASE143      # expect 0
gh api repos/$REPO/rulesets --jq 'length'                                 # note baseline; freeze rulesets are created/deleted by the job

# --- 1. [checkpoint E] authorize exactly one SHA ---
gh variable set LOCKSPIRE_PHASE143_AUTHORIZED_SHA --body "$S"

# --- 2. [checkpoint F] dispatch (must run from main) ---
gh workflow run release.yml --ref main \
  -f recovery_ref="$S" -f source_ci_run_id="$CI_RUN" \
  -f recovery_reason="Publish Lockspire 1.6.0 (v1.43 + v1.44) from verified main $S"
RUN=$(gh run list --workflow release.yml --event workflow_dispatch -L1 --json databaseId --jq '.[0].databaseId')

# --- 3. [checkpoint G] maintainer approves the hex-publish environment in the Actions UI ---
gh run watch "$RUN" --exit-status || true            # an evidence-retention failure after publish does not invalidate publication (143-RESULT precedent; fixed in #120)

# --- 4. [checkpoint H] clear the one-use variable immediately after the attempt ---
gh variable delete LOCKSPIRE_PHASE143_AUTHORIZED_SHA
gh variable list | grep -c PHASE143                  # expect 0
```

The workflow itself already runs `scripts/publish/verify_install_truth.sh release-input/release-manifest.json "$VERIFIED_SHA" release-input/postpublish-receipt.json` (polls `https://hex.pm/api/packages/lockspire/releases/<version>` up to 12x10s, calls `release_artifact.py verify-hex`, curls `https://hexdocs.pm/lockspire/<version>/supported-surface.html` with `-L`, runs `run_clean_room_saas_journey.sh --hex-version <v> --package-sha256 <sum> --only happy_path`). That output is not independent evidence for D-11, so repeat it from your own machine:

### Independent verification script (commands exercised against 1.5.1 this session; substitute `V=1.6.0`)

```bash
set -euo pipefail
V=1.6.0; TAG=lockspire-v$V; S=<published source SHA>
W=$(mktemp -d); cd "$W"                                         # fresh dir, untrusted download area

# 1. Hex API checksum (lowercase hex, equals outer tarball sha256)
curl -fsS -o rel.json https://hex.pm/api/packages/lockspire/releases/$V
API_SUM=$(python3 -I -c "import json;print(json.load(open('rel.json'))['checksum'])")
python3 -I -c "import json;d=json.load(open('rel.json'));assert d['version']=='$V' and d['has_docs'] is True"

# 2. Download the outer tarball from the CDN and hash it
curl -fsS -o lockspire-$V.tar https://repo.hex.pm/tarballs/lockspire-$V.tar
TAR_SUM=$(shasum -a 256 lockspire-$V.tar | cut -d' ' -f1)

# 3. Compare against manifest (artifact from the release workflow run) and API
gh run download "$RUN" -R szTheory/lockspire -n "release-evidence-$S" -D evidence
MAN_SUM=$(jq -er '.artifact.sha256' evidence/release-manifest.json)
test "$API_SUM" = "$TAR_SUM" && test "$TAR_SUM" = "$MAN_SUM" && test "$(jq -er .source_sha evidence/release-manifest.json)" = "$S"
jq -e '.status=="verified"' evidence/postpublish-receipt.json

# 4. Tarball contents: outer entries, then inner contents.tar.gz listing (NEW step)
tar -tf lockspire-$V.tar                                        # VERSION CHECKSUM metadata.config contents.tar.gz
tar -xOf lockspire-$V.tar contents.tar.gz | tar -tzf - | grep '^lib/mix/tasks/' | sort > tasks.txt
for t in lockspire.gen.kek lockspire.doctor.key_encryption lockspire.keys.reencrypt; do grep -qx "lib/mix/tasks/$t.ex" tasks.txt; done
! grep -q 'lockspire.test.setup' tasks.txt                       # excluded by @package_excluded_files in mix.exs

# 5. HexDocs (note the 301 -> lockspire.hexdocs.pm/<v>/index.html; use -L)
for p in "" supported-surface.html operator-admin.html signing-key-encryption.html Mix.Tasks.Lockspire.Gen.Kek.html; do
  curl -fsSL -o /dev/null -w "%{http_code} %{url_effective}\n" "https://hexdocs.pm/lockspire/$V/$p"; done   # note: guide file names to confirm at execution (see Open Question 4)

# 6. Peeled tag and GitHub release target
git ls-remote https://github.com/szTheory/lockspire.git "refs/tags/$TAG" "refs/tags/$TAG^{}"     # lightweight tag: only the first line appears; its SHA must equal $S
gh release view "$TAG" -R szTheory/lockspire --json tagName,targetCommitish,isDraft,isPrerelease
bash scripts/publish/verify_github_release_target.sh "$TAG" https://github.com/szTheory/lockspire.git "$S"   # existing script, from a checkout of $S
```

For an annotated tag, `^{}` returns the peeled commit and that is the value to compare. The existing 1.5.1 tag is lightweight [VERIFIED: `gh api .../git/ref/tags/lockspire-v1.5.1` -> `"type":"commit"`], so only the non-peeled line prints; the script must compare whichever of `^{}`/plain is present.

### Clean-room host in a fresh HEX_HOME (validated against 1.5.1 this session)

```bash
export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5
W=$(mktemp -d); mkdir -p "$W/hexhome" "$W/mixhome" "$W/host/lib"; cd "$W/host"
export HEX_HOME="$W/hexhome" MIX_HOME="$W/mixhome" MIX_ARCHIVES="$W/mixhome/archives"; unset HEX_API_KEY
cat > mix.exs <<'EOF'
defmodule CleanRoom.MixProject do
  use Mix.Project
  def project, do: [app: :clean_room, version: "0.1.0", elixir: "~> 1.18", deps: [{:lockspire, "== 1.6.0"}]]
  def application, do: [extra_applications: [:logger]]
end
EOF
mix local.hex --force && mix local.rebar --force
mix deps.get
# Outer checksum Hex recorded in mix.lock must equal the Hex API checksum (this held for 1.5.1: c13dabdd...)
grep '"lockspire"' mix.lock | grep -o '"hexpm", "[0-9a-f]*"}'
test -f deps/lockspire/lib/mix/tasks/lockspire.gen.kek.ex
# Optional, slower (compiles Phoenix/Ecto): prove the task runs cold from the Hex package
mix deps.compile && mix lockspire.gen.kek --raw | awk '{print length($0)}'   # expect 44
```

The `mix deps.compile` + `gen.kek --raw` tail was NOT run this session (1.5.1 has no such task) [ASSUMED to work; `scripts/acceptance/clean_room/build_provider.py:447-495` `check_gen_kek` and `test/integration/phase133_provider_install_test.exs:43` already prove the cold run against the vendored package]. The existing `run_clean_room_saas_journey.sh --hex-version 1.6.0 --package-sha256 <sum> --only happy_path` (run by the workflow) additionally exercises the HTTP journey; the `--check-gen-kek` mode is invoked only by that ExUnit integration test, not by the journey.

## RELEASE-TRAIN.md refresh (D-12)

The hygiene script parses these lines with exact-shape regexes [VERIFIED: repo_hygiene_check.sh:647-669, 696-700]; keep the shapes and update the values:

- `- Release Please version metadata: \`1.6.0\` <!-- x-release-please-version -->` and the `date` line are bumped by Release Please (extra-files `generic` marker); do not hand-edit.
- `- Latest public package: Hex \`1.6.0\`, published from source \`<40 hex>\` on YYYY-MM-DD. Release Please metadata above is not publication proof.`
- `- Artifact truth: protected release run [<id>](https://github.com/szTheory/lockspire/actions/runs/<id>) for source \`<40 hex>\` <free text> verified the public Hex checksum \`<64 hex>\`, HexDocs, [lockspire-v1.6.0](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.6.0), and clean-room install. Its terminal receipt records \`release_verified: true\` with no blocker.<free text>`
- Exactly one of each of the three `- ` lines above (counts are checked); the required standing lines (`Lockspire is on a sustaining GA release train.`, `milestone: none` ..., `Patch-eligible merged changes ...`, `The train is ready to move only when ...`) must remain verbatim.
- Move the 1.5.1 truth into the existing "Previous release" bullet, and refresh "Current Main Readiness". Do not put `.planning/` links in public guides (documentation contract).
- Local Markdown links in this file are resolved by `test/lockspire/release/repository_hygiene_contract_test.exs` (every `[..](path)` must exist).

This refresh and the pinned-literal test helpers move together: after the Critical Finding 1 repair, both must read from the file rather than hardcode `1.5.1` or `0b565038`, otherwise the refresh PR itself needs test edits.

## Docs (DOC-02)

### What exists and what is correct

[VERIFIED: `git diff 038df080..HEAD -- docs/`] Phases 158-160 already edited `docs/install-and-onboard.md` and `docs/upgrading/signing-key-encryption.md`; `docs/operator-admin.md` is untouched (grep shows no mention of encryption, Key protection or gen.kek).

Drift audit against shipped code (each item read this session):

| Doc claim | Code | Verdict |
|-----------|------|---------|
| gen.kek "prints it once together with the block below" | `gen.kek.ex` `print_default/1` prints key line, then `KekSnippet.prod_block`, then dev/test note | matches |
| `--raw` prints only the key; ignores `--id` | `gen.kek.ex` moduledoc and `help/0`: "`--id` has no effect with `--raw` (an invalid id is still rejected)" | matches |
| "refuses to boot if it is unset or empty" for `{:system, "VAR"}` | `config.ex` `resolve_env_entries/1`: `_unset_or_empty -> {:halt, {:error, {:keys, :missing_env, var}}}`; whitespace-only -> `:blank_env` | matches |
| "read when the app boots; changing takes effect on restart" | `config.ex` comment: "read from the environment on each call" but resolved key set is cached at boot (`key_encryption_keyset/0`) | matches in effect; do not claim "read on each call" |
| "trailing newline makes it invalid" | `resolve_env_entries/1` comment: "The value is passed through untrimmed (fail closed)" | matches |
| Upgrade guide rotation step uses `--raw` and warns about not copying the full block | `help/0` says the block names `LOCKSPIRE_KEY_ENCRYPTION_KEY` | matches |
| (D-02) missing-KEK generate error "points to gen.kek and the upgrade guide" | `keys_live/index.ex` `missing_key_encryption_error/1`: "...Create one with mix lockspire.gen.kek, add it to your app's configuration, and restart the app." | **drift in the brief, not in the docs**: the in-app message names only `mix lockspire.gen.kek`. Write the operator guide as "names `mix lockspire.gen.kek`" and put the upgrade-guide link in the guide's own prose; do not assert the error links to the upgrade guide |

Net: install and upgrade guides need at most a read-through; the substantive DOC-02 work is the operator-guide subsection and its contract test.

### Key protection subsection (proposed content, place after "Find the admin task you need" or inside the Keys material; avoid `.planning/`, `openssl rand`, `elixir -e`)

State labels, quoted verbatim from `lib/lockspire/web/live/admin/keys_live/protection.ex` (`value:` fields): [VERIFIED: file read this session]
`"Encrypted"`, `"Encrypted, some with an older key-encryption key"`, `"Some keys are stored unencrypted"`, `"Some keys cannot be read"`, `"Not set up"`, `"Setup needs attention"`, `"Unknown"`. The section's `aria-label` and item `label` are `"Key protection"`; commands shown are `mix lockspire.keys.reencrypt` (older key, unencrypted), `mix lockspire.doctor.key_encryption` (cannot be read, orphaned not-set-up, setup needs attention) and `mix lockspire.gen.kek` (not set up). `Unknown` detail: "This does not mean your keys are protected or unprotected. Reload the page to try again."

Suggested text (plain words, least technical operator):

```markdown
### Key protection

The Keys page starts with a **Key protection** line. It tells you whether Lockspire is encrypting the private keys it stores. The line is read-only: it never changes anything, and the Keys page has no button for it. Lockspire encrypts those private keys with a key-encryption key that your app provides in its configuration.

| The line says | What it means | What to do |
| --- | --- | --- |
| Encrypted | Every stored private key is encrypted with the current key-encryption key. | Nothing. |
| Encrypted, some with an older key-encryption key | Lockspire can still read all keys. Some use an older key-encryption key. | Run `mix lockspire.keys.reencrypt` to move them to the current one. |
| Some keys are stored unencrypted | Some private keys are stored without encryption, usually because an older Lockspire version created them. | Run `mix lockspire.keys.reencrypt`. |
| Some keys cannot be read | Lockspire cannot open some stored keys with the key-encryption keys it has. | Do not delete them. Run `mix lockspire.doctor.key_encryption`. |
| Not set up | No key-encryption key is set up, so Lockspire cannot create new keys. | Run `mix lockspire.gen.kek`, add the result to your app's configuration, and restart the app. See the [signing key encryption upgrade note](upgrading/signing-key-encryption.md). |
| Setup needs attention | The key-encryption key setup is not valid. | Run `mix lockspire.doctor.key_encryption`. |
| Unknown | Lockspire could not check right now. This is **not** a healthy result. | Reload the page. If it stays Unknown, run `mix lockspire.doctor.key_encryption`. |

If you try to create a key before a key-encryption key is set up, Lockspire refuses and the page tells you to run `mix lockspire.gen.kek`. It never stores a private key unencrypted.
```

Check before merge: "never stores a private key unencrypted" is supported by `Admin.generate_key/1` doc ("Returns `{:error, :key_encryption_not_configured}` when no key-encryption key is configured") [VERIFIED: v1.44 diff of `admin.ex`] and the in-app text "Lockspire will not store private keys unencrypted." Keep wording to what is shown. Also confirm there is no Overview-page copy to document (not researched; `operator-admin.md` line 12 mentions Overview "key readiness").

Vocabulary: PRODUCT.md rows added in v1.44 [VERIFIED: `git diff 038df080..HEAD -- PRODUCT.md`]: "key-encryption key" -> "key-encryption key: the key that encrypts the private keys Lockspire stores"; "signing-key encryption status" -> "Key protection"; seven state labels. `vocabulary_contract_test.exs` scans only `lib/lockspire/web/live/admin/**`, `admin_layout_live.ex` and `admin_components.ex` against the "Retired wording" table [VERIFIED: file read], so a docs-only change cannot break it, but AGENTS.md says to use the "UI says" terms. Do not call the thing an "encryption status" or "KEK" in operator-facing prose without the plain name first.

### Contract test to extend

Extend `test/lockspire/kek_guidance_contract_test.exs` [VERIFIED: file read]. Style: `ExUnit.Case, async: true`, `@repo_root Path.expand("../..", __DIR__)`, helper `read/1`, plain `assert read(rel) =~ "..."` and `files_containing/1`, no snapshots. Existing tests: no file recommends `openssl rand`; `elixir -e` appears only in the upgrade guide after `mix lockspire.gen.kek`; `@guidance_files` must each contain `mix lockspire.gen.kek`.

Add (one new test, Claude's discretion on names):

```elixir
test "the operator guide documents the read-only Key protection line" do
  guide = read("docs/operator-admin.md")
  labels = ["Encrypted", "Encrypted, some with an older key-encryption key",
            "Some keys are stored unencrypted", "Some keys cannot be read",
            "Not set up", "Setup needs attention", "Unknown"]
  assert guide =~ "Key protection"
  for label <- labels, do: assert(guide =~ label, "operator guide missing state: #{label}")
  assert guide =~ "read-only"
  assert guide =~ ~r/Unknown.*not a healthy result/s
  assert guide =~ "mix lockspire.gen.kek"
  assert guide =~ "upgrading/signing-key-encryption.md"
  refute guide =~ ".planning/"
end
```

Better, derive the labels from the shipped source so the guide cannot drift: read `lib/lockspire/web/live/admin/keys_live/protection.ex` and extract `value: "..."` strings with `Regex.scan(~r/value: "([^"]+)"/, src)`; assert every one appears in the guide. Also add `"docs/operator-admin.md"` to `@guidance_files`. `documentation_contract_test.exs` already forbids `.planning/` in `operator-admin.md` and checks every extra is grouped once; `operator-admin.md` and `signing-key-encryption.md` are already in `extras` and `groups_for_extras` [VERIFIED: mix.exs ~196-246], so no `mix.exs` docs change is needed and none should be made (mix.exs must stay byte-identical for SAFE-02).

Do not touch `docs/supported-surface.md` (D-04). `repo_hygiene_check.sh` blocks "version-pinned docs" if README/supported-surface contain `Lockspire \`X.Y.Z\` is|GA` [VERIFIED: line 930]; avoid pinning versions in guides.

### `mix docs.verify`

[VERIFIED: mix.exs:141] `"docs.verify": ["docs --warnings-as-errors"]`, `:dev` env, part of `release.preflight` and `mix ci`. Run this session with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` on HEAD: exit 0, "Generating docs... View html docs at doc/index.html". Re-run after docs edits with the same env. Also note ExDoc warns on broken relative links to extras, so use `upgrading/signing-key-encryption.md` relative to `docs/`.

## SAFE-02 sweep (concrete)

Results already obtained at HEAD (v1.44 diff `038df080..HEAD`):

```bash
git diff --stat 038df080..HEAD -- mix.exs mix.lock priv/repo/migrations lib/lockspire/protocol config examples compatibility   # empty output = unchanged [VERIFIED: ran, empty]
git diff --name-only 038df080..HEAD -- lib/lockspire/protocol lib/lockspire/domain lib/lockspire/security lib/lockspire/storage   # only lib/lockspire/security/key_encryption/key_set.ex [VERIFIED]
git diff --name-only 038df080..HEAD | grep -v '^\.planning/'   # lib (21 files incl. 1 new Mix task), docs (2), PRODUCT.md, scripts/acceptance (2), tests [VERIFIED]
```

The `key_set.ex` change is a refactor: `@id_pattern` moved and a public `valid_id?/1` exposes the same regex `\A[A-Za-z0-9._-]{1,32}\z` used by `check_id/1` [VERIFIED: diff read]; behavior and the 32-byte/base64 rule are unchanged. `lib/lockspire/application.ex` changed only the boot-warning remediation text; `admin.ex` only a `@doc`/`@spec`; `registration_result.ex` adds `@derive {Inspect, except: [:client_secret]}` (a redaction hardening, not a default change). `lib/lockspire/config.ex` adds `{:system, "VAR"}` resolution; this is feature work on the KEK config, not a change to PKCE, redirect matching, secret hashing, code TTL, refresh rotation, or alg handling. The planner should word the SAFE-02 claim as "no change to protocol code (`lib/lockspire/protocol`), schema, dependencies or security defaults; additive KEK-config feature work only" rather than "no `lib/` change".

Grep sweep of added `lib/` lines [VERIFIED: ran]: no `:telemetry` or `IO.puts`/`IO.inspect` additions; `Logger` appears only in `lib/lockspire/install/task_error.ex` as process-level raising (`Logger.put_process_level(self(), :warning)` / restore) to suppress Ecto info logs, not new log statements; all new `raise`/`Mix.raise` sites use fixed phrases or names (`config.ex` `fail_key_encryption!` names the variable, never the value; `gen.kek.ex` raises on options; `TaskError` classifies without echoing). `Mix.shell().info` additions are the `gen.kek` output (the allowed key output, lines `KekSnippet.env_var()=value`, and `--raw`), `client.create` / `doctor token_format` messages that use `TaskError` phrases. Re-run at execution time on the final squash SHA: `git diff -U0 038df080..<SQUASH> -- lib | grep -E '^\+' | grep -nE 'Logger\.|:telemetry|IO\.(puts|inspect)|Mix\.shell|inspect\(|raise'` and attach the output.

Also sweep for key material in tracked text: `git diff -U0 038df080..<SQUASH> | grep -nE 'BEGIN (RSA|EC|PRIVATE)|"d":|private_jwk|LOCKSPIRE_KEY_ENCRYPTION_KEY=[A-Za-z0-9+/=]{20,}'` should show no real values (docs/tests may contain the variable name and placeholder strings; judge hits manually) [ASSUMED pattern set; adjust at execution].

Existing tests to rerun (CI Elixir 1.19.5-otp-28, Postgres up at `/tmp:5432`) [VERIFIED: ran together this session: `109 tests, 0 failures`]:

```bash
export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5
MIX_ENV=test mix test \
  test/lockspire/redaction/redaction_test.exs \
  test/mix/tasks/lockspire_gen_kek_test.exs \
  test/lockspire/kek_guidance_contract_test.exs \
  test/lockspire/config_key_encryption_test.exs \
  test/lockspire/web/live/admin/vocabulary_contract_test.exs \
  test/lockspire/web/live/admin/keys_live/protection_test.exs \
  test/lockspire/upgrade_guide_contract_test.exs \
  test/lockspire/documentation_contract_test.exs
```

Add for the full proof: `test/lockspire/web/live/admin/keys_live_test.exs`, `test/mix/tasks/lockspire_doctor_key_encryption_test.exs`, `test/mix/tasks/lockspire_keys_reencrypt_test.exs`, `test/mix/tasks/lockspire_client_create_cold_test.exs`, `test/lockspire/install/task_error_test.exs`, `test/integration/phase133_provider_install_test.exs` (needs the integration lane), and cite `158/159/160-SECURITY.md` and `-VERIFICATION.md`. Full gate: `MIX_ENV=test mix test.fast` and `mix test.integration` (the `mix ci` alias).

## Common Pitfalls

### Pitfall 1: #121 merge goes red on the release-train gates
**What goes wrong:** Release Hygiene Drift and Fast Checks fail on the squash commit; the publish lane then refuses (no successful CI push run on that SHA).
**Why:** #122 removed the pending-publication ledger form; hygiene and two test helpers pin 1.5.1 literals (Critical Finding 1).
**How to avoid:** Repair the gates before #121 is merged; simulate with `git archive HEAD` into a scratch dir plus the four #121 edits, then run `bash scripts/maintainer/repo_hygiene_check.sh --ci` (expect `0 BLOCK`) and the two release-truth tests.
**Warning signs:** `[BLOCK] release train ledger` after any bump.

### Pitfall 2: Override separated by single newlines
**What goes wrong:** Two conventional lines on adjacent lines parse as one commit with the second as body, so v1.41 vanishes from the changelog.
**How to avoid:** Blank line between entries [VERIFIED: split regex]; re-read #121 after regeneration.

### Pitfall 3: Override applied too late or not at all
**What goes wrong:** #121 regenerates on the v1.44 push without v1.40/v1.41 and needs another trigger.
**How to avoid:** Edit #122 before merging v1.44. Do not rely on workflow re-run (automerge-dispatch step against a disabled workflow).

### Pitfall 4: `git reset --hard` eats `state.json`
Stash or commit `.planning/state.json` first; keep a backup branch.

### Pitfall 5: Publishing a different SHA than authorized
`recovery-validation` requires `RECOVERY_REF == AUTHORIZED_SHA == origin/main` at validate time [VERIFIED: release.yml]. Any push to main between setting the variable and approval (Dependabot merge, ledger PR) invalidates the run; hold all merges until publish completes, and the job freezes main during publish.

### Pitfall 6: Trusting workflow-internal verification as D-11 evidence
`verify_install_truth.sh` runs inside the privileged workflow's repository checkout. Repeat checks from public endpoints on the maintainer machine with a fresh `HEX_HOME`.

### Pitfall 7: Wrong expected task list
`lockspire.test.setup.ex` is in `@package_excluded_files` [VERIFIED: mix.exs:4-7]. 1.6.0 tarball tasks = the 1.5.1 set (8) + `doctor.key_encryption`, `gen.kek`, `keys.reencrypt` = 11. A checklist that expects `test.setup` will falsely fail.

### Pitfall 8: Misstating the v1.44 PR
D-07: `mix lockspire.keys.reencrypt` still uses raw `Ecto.Migrator.with_repo`; the v1.44 repo-start fix covers `client.create`, `doctor remote-jwks`, `doctor token_format` [VERIFIED: v1.44 diff lists exactly those three tasks plus `RepoRunner`/`TaskError`].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Changelog coverage for v1.40/v1.41 | Hand-edit #121 or CHANGELOG.md | `BEGIN_COMMIT_OVERRIDE` on #122 | #121 regenerates and overwrites hand edits |
| Publish | `mix hex.publish` from a laptop | `release.yml` exact-ref dispatch | Freeze rulesets, tag guard, manifest-bound publisher |
| Tag/release target check | Ad-hoc `git` | `scripts/publish/verify_github_release_target.sh` | Already compares remote tag target to SHA |
| Checksum comparison logic | New parser | `release_artifact.py verify-hex`, `jq` on manifest, `shasum -a 256` | Existing, tested |
| Ledger consistency | New checker | `repo_hygiene_check.sh --ci` | Required CI gate; repair it, do not bypass |
| KEK generation | `openssl`/`elixir -e` recipes | `mix lockspire.gen.kek` | Contract test forbids other recipes in lib/docs |

## Code Examples

### Hex API fields (real 1.5.1 response)
```json
{"version":"1.5.1","checksum":"c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3","has_docs":true,"docs_html_url":"https://lockspire.hexdocs.pm/1.5.1/","inserted_at":"2026-10-08T14:59:08.524960Z"}
```
[VERIFIED: curl https://hex.pm/api/packages/lockspire/releases/1.5.1, this session] The same checksum equals `shasum -a 256` of `https://repo.hex.pm/tarballs/lockspire-1.5.1.tar` and the last field of the `lockspire` entry in a fresh host's `mix.lock`.

### Outer and inner tarball layout (1.5.1)
`tar -tf` shows `VERSION`, `CHECKSUM`, `metadata.config`, `contents.tar.gz`; `tar -xOf <tar> contents.tar.gz | tar -tzf -` lists `lib/mix/tasks/lockspire.client.create.ex`, `lockspire.doctor.ex`, `lockspire.doctor.remote_jwks.ex`, `lockspire.doctor.token_format.ex`, `lockspire.install.ex`, `lockspire.oidf_conformance.ex`, `lockspire.upgrade.ex`, `lockspire.verify.ex` [VERIFIED: ran].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ledger allowed "Hex lists X; exact Y query returned 404" pending form | Only post-publish form accepted | #122 (e67a4898) | Release PR merge now breaks hygiene until gate repaired |
| `openssl rand -base64 32` / `elixir -e` KEK recipes | `mix lockspire.gen.kek` (+ `--raw`) | Phase 159 | `kek_guidance_contract_test` forbids the old recipes outside the upgrade-guide fallback |
| Bare-mix tasks fail without repo | `RepoRunner` + `TaskError` | Phase 158 | Not applied to `keys.reencrypt` (deferred) |

## Runtime State Inventory

Not a rename/refactor phase, but release operations touch hosted state:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None - no schema or data change in v1.44 diff (`priv/repo/migrations` unchanged) | None |
| Live service config | GitHub: variable `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED=true` (set), workflow `Release Please Auto Merge` disabled; variable `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` absent; PR body of #122; Dependabot PRs #125-#127 open | Set then delete the SHA variable; edit #122 body; leave auto-merge disabled until verified; leave Dependabot PRs |
| OS-registered state | None | None |
| Secrets/env vars | `HEX_API_KEY` secret in `hex-publish`, `LOCKSPIRE_RELEASE_FREEZE_APP_ID` var and `..._PRIVATE_KEY` secret (not read or printed) | None (do not echo) |
| Build artifacts | Scratch dirs under the session scratchpad only; `doc/` and `_build` from `mix docs.verify` are git-ignored | None |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP 1.19.5-otp-28 + Erlang 28.5 | docs.verify, tests | yes | via asdf | none needed |
| PostgreSQL | tests | yes | accepting on /tmp:5432 | none |
| gh CLI | all GitHub ops | yes | authenticated | web UI |
| curl, python3, tar, shasum | verification | yes | system | none |
| jq | `verify_install_truth.sh`, evidence checks | not probed | - | install if absent |
| Node | offline override proof only | yes | ran with vendored module | none |
| Network to hex.pm, repo.hex.pm, hexdocs.pm, github.com | verification | yes | 1.5.1 exercised | none |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5-otp-28) |
| Config file | `mix.exs` aliases; `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs test/lockspire/documentation_contract_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` |
| Full suite command | `mix ci` (qa, docs.verify, deps.audit, package.build, `MIX_ENV=test mix test.fast`, `mix test.integration`) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-02 | Operator guide lists all 7 Key protection labels, read-only, Unknown not healthy, names gen.kek, links upgrade note | contract | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs` | extend (new test) |
| DOC-02 | Install/upgrade guides name gen.kek and `{:system,...}`; no openssl recipe | contract | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs test/lockspire/upgrade_guide_contract_test.exs` | yes |
| DOC-02 | Guides are in ExDoc extras/groups; ExDoc builds without warnings | contract + build | `MIX_ENV=test mix test test/lockspire/documentation_contract_test.exs && mix docs.verify` | yes |
| DOC-02 | Admin vocabulary unchanged | contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/vocabulary_contract_test.exs` | yes |
| REL-01 | Gate repair: hygiene accepts metadata > public with consistent public/artifact/tag/SHA; still rejects each malformed case | script + contract | `bash scripts/maintainer/repo_hygiene_check.sh --ci` and `MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs test/lockspire/release/release_automation_contract_test.exs` | yes (needs edits, Wave 0) |
| REL-01 | Simulated post-#121 tree passes hygiene | manual-scripted | scratch copy: `git archive HEAD \| tar -x -C $SCRATCH`, apply 1.6.0 edits, run hygiene `--ci` | no, add as plan step |
| REL-01 | Override parsed into 2 entries | offline script | `node $SCRATCH/ovr.js <vendored build/src>` (script from this research, persisted in plan if wanted) | no (optional) |
| REL-01 | Regenerated #121 proposes 1.6.0, covers v1.40-v1.44 | manual-read | `gh pr view 121 --json title,body --jq '.title,.body'` | n/a |
| REL-02 | Publish run succeeded; evidence artifact present | gh | `gh run view $RUN --json conclusion,jobs` and `gh run download $RUN -n release-evidence-$S` | n/a |
| REL-02 | Hex API == tarball sha == manifest; tag/release == SHA; HexDocs 200; tarball has 3 new tasks | script | Independent verification script above | no, add `scripts/release/verify_public_release.sh` or inline in evidence plan |
| REL-02 | Fresh HEX_HOME install at `== 1.6.0` | script | Clean-room snippet above | no |
| SAFE-02 | No change to mix.exs/mix.lock/migrations/protocol/config in v1.44 diff | diff | `git diff --stat 038df080..<SQUASH> -- mix.exs mix.lock priv/repo/migrations lib/lockspire/protocol config` (empty) | n/a |
| SAFE-02 | No key/KEK in logs/telemetry/admin/errors | tests + grep | targeted test list above + grep sweep | yes |

### Sampling Rate
- **Per task commit:** the Quick run command (3 files, under a second) plus `mix docs.verify` after any docs edit.
- **Per wave merge:** the 8-file SAFE-02 test list, hygiene `--ci`, `mix format --check-formatted`.
- **Phase gate:** PR CI fully green (7 required checks), then release verification script outputs recorded in `161-RELEASE-EVIDENCE.md` before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] Gate repair in `scripts/maintainer/repo_hygiene_check.sh` plus version/SHA-agnostic `workflow_assertions.ex` and `package_assertions.ex` (needs maintainer OK; Critical Finding 1)
- [ ] New test in `test/lockspire/kek_guidance_contract_test.exs` for the operator guide
- [ ] Public verification script (new file or inline commands in the evidence plan)

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json` [VERIFIED: read], so this section applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth change) | n/a |
| V3 Session Management | no | n/a |
| V4 Access Control | yes (release lane) | `hex-publish` environment reviewer gate, main-only policy, one-use authorized-SHA variable, main freeze ruleset |
| V5 Input Validation | yes (workflow inputs) | `release.yml` validates 40-hex SHA, numeric run ID, ancestry, CI workflow identity |
| V6 Cryptography | yes | AES-256-GCM envelopes unchanged in v1.44; never hand-roll, `:crypto` only; do not touch |
| V7 Error handling/Logging | yes | Fixed phrases / variable names only, no values (see sweep) |
| V10 Supply chain / integrity | yes | Manifest-bound tarball sha256 checked against Hex API and CDN download |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing an unreviewed SHA | Tampering | Authorized-SHA variable equals input equals `origin/main`; CI run bound to SHA |
| Leaking `HEX_API_KEY` or the App private key in output | Information disclosure | Keys exist only in the protected job; verification steps are unprivileged; do not echo secrets, do not `gh variable list --json` secrets |
| KEK printed outside `gen.kek` | Information disclosure | `gen.kek` is the only key-printing path; grep sweep + redaction tests |
| Checksum substitution on CDN/registry | Tampering | Three-way compare: Hex API, downloaded tar sha256, signed-in manifest; `mix.lock` outer checksum |
| Stale authorization reuse | Elevation of privilege | Delete variable right after the attempt; confirm absence |
| Tag moved after release | Tampering | Tag freeze ruleset during publish; post-check peeled tag SHA |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | release-please default `changelog-sections` hides `docs`/`chore` entries when no config is set | Architecture Patterns | A `docs:` override line would show (harmless) or not (v1.41 docs missing); mitigated by using `feat` |
| A2 | `(#122)` in override lines renders as a PR link in the changelog | Architecture Patterns | Cosmetic only |
| A3 | Re-running an old push `Release` run would fail on dispatching the disabled automerge workflow | Architecture Patterns | Only affects the fallback trigger; primary trigger is a fresh push |
| A4 | `mix deps.compile && mix lockspire.gen.kek --raw` in the fresh host prints a 44-char key | Clean-room | Optional step; the cold run is separately proven by the existing integration test |
| A5 | grep pattern set for key material in the diff is sufficient | SAFE-02 | A missed pattern; the redaction tests are the main proof |
| A6 | HexDocs page names `operator-admin.html`, `signing-key-encryption.html`, `Mix.Tasks.Lockspire.Gen.Kek.html` exist for the exact version | Verification script | A 404 on a name guess; confirm against `https://lockspire.hexdocs.pm/1.6.0/` sidebar at execution |
| A7 | Option 1 (pre-landing the gate repair) is acceptable to the maintainer | Critical Finding 1 | If rejected, fall back to Option 2 (extra PR, publish the fix commit SHA) |

## Open Questions (RESOLVED)

1. **Gate repair approach (blocking).**
   - Known: hygiene and two test helpers fail after #121's version bump; the publish lane needs CI green on the publish SHA.
   - Unclear: whether the maintainer accepts relaxing the equality in `repo_hygiene_check.sh` (and de-pinning test helpers) inside the v1.44 PR vs a separate PR after #121.
   - Recommendation: Option 1, pre-land. Needs an explicit user decision at a checkpoint before the first push, since it widens the v1.44 diff beyond lib/docs/tests.
   - **RESOLVED:** settled by CONTEXT D-16 (gate repair approach); implemented in the plan set as locked there.
2. **Does the minor bump stay 1.6.0 after the override?** Known: all `feat`; `bump-minor-pre-major: false`, current is 1.5.1, so feat -> 1.6.0 [VERIFIED: release-please-config.json]. Confirm by reading regenerated #121 title.
   - **RESOLVED:** plan 161-06 Task 1 asserts the regenerated #121 title names 1.6.0 and stops if it does not.
3. **Where the squash-merge lands relative to Dependabot PRs.** Known: #125-#127 are GitHub Actions bumps touching `.github/workflows`; with `strict: true` they would need rebases after v1.44 merges. They stay unmerged until after publish (D-09). No action needed beyond not merging them.
   - **RESOLVED:** CONTEXT D-09 (no action; Dependabot PRs stay unmerged until after publish).
4. **HexDocs guide URLs.** Known pattern from `verify_install_truth.sh`: `https://hexdocs.pm/lockspire/<v>/supported-surface.html`. Confirm the operator-admin and upgrade-note page names (A6) when 1.6.0 is live.
   - **RESOLVED:** plan 161-08 Task 1 checks the live 1.6.0 HexDocs page names for the operator-admin guide and the upgrade note.
5. **Manifest availability for verification.** `release-evidence-<sha>` retains 90 days and contains `release-manifest.json` and `postpublish-receipt.json`; confirm the download works for the 1.6.0 run (the 1.5.1 evidence retention had failed once before #120).
   - **RESOLVED:** plan 161-08 Task 1 downloads `release-manifest.json` and compares its artifact sha256 three ways (Hex API, tarball, manifest); a missing manifest is a stop condition.

## Sources

### Primary (HIGH confidence, read or executed this session)
- `.github/actions/release-please/runtime/node_modules/release-please/build/src/commit.js` (override, splitter) and `github.js` (GraphQL, PR association)
- `.github/workflows/release.yml`, `ci.yml`, `release-please-automerge.yml`; `docs/maintainer-release.md`; `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`
- `scripts/publish/verify_install_truth.sh`, `release_artifact.py`, `scripts/maintainer/repo_hygiene_check.sh`
- `lib/mix/tasks/lockspire.gen.kek.ex`, `lib/lockspire/config.ex` (+ v1.44 diff), `lib/lockspire/web/live/admin/keys_live/protection.ex`, `keys_live/index.ex` diff, `PRODUCT.md` diff
- `test/lockspire/kek_guidance_contract_test.exs`, `documentation_contract_test.exs`, `vocabulary_contract_test.exs`, `test/support/lockspire/release_proof/*.ex`
- `mix.exs` (docs.verify, package_files, `@package_excluded_files`), `release-please-config.json`, `.release-please-manifest.json`
- Live GitHub: PR #121, #122, #131; branch protection; repo merge settings; variables; workflows
- Live public: Hex API release JSON, repo.hex.pm tarball, HexDocs redirect, fresh-`HEX_HOME` `mix deps.get` of lockspire 1.5.1
- Executed: `mix docs.verify` (exit 0) and 109 targeted tests (0 failures) on 1.19.5-otp-28; hygiene `--ci` at HEAD (0 BLOCK) and in the simulated 1.6.0 tree (1 BLOCK)

### Secondary / Tertiary
- None relied on. Release-please default changelog sections and changelog link rendering are `[ASSUMED]` (A1, A2).

## Metadata

**Confidence breakdown:**
- Standard stack / procedure: HIGH - workflow and scripts read; public verification commands run against 1.5.1
- Architecture (override, range): HIGH - source read and exercised offline
- Gate-repair recommendation: MEDIUM - blocker is verified by simulation, but the chosen fix is a maintainer call
- Pitfalls: HIGH

**Research date:** 2026-10-19
**Valid until:** 2026-11-02 (workflows and ledger are the fast-moving parts; re-check `git diff` of `.github/` and `scripts/` and `gh variable list` before executing)
