# Phase 139: Required Truth Reconciliation - Pattern Map

**Mapped:** 2026-09-11
**Files analyzed:** 12 likely new/modified files (all existing; one conditional generated-ledger replacement)
**Analogs found:** 12 / 12

## Scope Boundary

Phase 139 is a maintainer-only reconciliation pass. It should modify existing shell, focused ExUnit proof, and maintained prose only. It must not add a Mix task, Phoenix route, LiveView, Ecto schema, Oban job, runtime/public Lockspire API, release publication, Phase 140 cleanup, dependency-PR action, or historical-record rewrite.

`.planning/ROADMAP.md` and `.planning/STATE.md` already identify v1.38 / Phase 139 as active (`.planning/ROADMAP.md:6,13,121`; `.planning/STATE.md:3-8,28-35`), so they are verification authorities rather than planned prose edits. `.planning/MILESTONES.md` is immutable shipped-history evidence for v1.37 / `1.5.0`, not a target.

## File Classification

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` (conditional replacement) | config / evidence ledger | batch, file-I/O | same file + `scripts/maintainer/baseline_inventory.sh` | exact |
| `scripts/maintainer/baseline_inventory.sh` | utility | batch, file-I/O | same file | exact |
| `scripts/maintainer/repo_hygiene_check.sh` | utility | batch, request-response | same file + `.github/workflows/release.yml` | exact |
| `test/support/lockspire/release_proof/package_assertions.ex` | test utility | file-I/O, request-response | same file | exact |
| `test/lockspire/release/repository_hygiene_contract_test.exs` | test | batch, request-response | same file | exact |
| `test/lockspire/release_ci_evidence_contract_test.exs` | test | transform / static contract | same file | exact |
| `test/lockspire/workflow_supply_chain_contract_test.exs` | test | batch, file-I/O | same file | exact |
| `test/support/lockspire/release_proof/workflow_assertions.ex` | test utility | transform / static contract | same file | exact |
| `.planning/REPO-HYGIENE-CHECKLIST.md` | config / maintainer docs | request-response | same file + `scripts/maintainer/repo_hygiene_check.sh` | exact |
| `.planning/RELEASE-TRAIN.md` | config / release docs | event-driven | same file + `.github/workflows/release.yml` | exact |
| `docs/maintainer-release.md` | config / maintainer docs | event-driven | same file + `.github/workflows/release.yml` | exact |
| `.planning/PROJECT.md` | config / planning truth | batch / transform | same file + `.planning/STATE.md` | exact |

All analog paths above were verified with `git ls-files`; no ignored capability/runtime mirror is used.

## Pattern Assignments

### `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` (config/evidence ledger, batch + file-I/O)

**Analog:** the same immutable ledger's currentness contract, backed by `scripts/maintainer/baseline_inventory.sh`.

**Generated replacement pattern** (`baseline-inventory-2026-08-28.md:199-213`):

```markdown
## Post-snapshot currentness relation

This ledger is an immutable snapshot bounded ... at `evidence_base_sha` ...

bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation \
  .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md

Any nonzero exit or `refresh_required` means the snapshot must be recollected
from a new clean evidence base and published in a new ledger-only replacement commit.
```

Do not hand-edit a verdict or append Phase 139 acceptance to the old snapshot. If the precondition still returns `refresh_required`, use the existing collector/finalizer protocol to replace the ledger from a clean evidence base, publish only that ledger in its commit, and rerun the production relation verifier. All dispositions remain proposal-only.

---

### `scripts/maintainer/baseline_inventory.sh` (utility, batch + file-I/O)

**Analog:** the same script's explicit branching and fail-closed relation verifier.

**Shell structure pattern** (`scripts/maintainer/baseline_inventory.sh:608-622`):

```bash
validate_github_rows() {
  local collection="$1" combined="$2"
  GITHUB_ROW_FAILURE=""
  if [[ "$collection" == pullRequests ]]; then
    jq -e --arg oid_pattern "$GITHUB_OBJECT_ID_PATTERN" '
      all(.nodes[];
        ((.id | type) == "string" and (.id | length) > 0)
```

Use explicit `if`/`else` assignment instead of the current `[[ ... ]] && kind=pr || kind=issue` at line 865. Remove or actually consume the unused locals at lines 1094, 2853, and 3251; do not add ShellCheck suppressions or weaken `scripts/ci/lint_workflows.sh`.

**Fail-closed core pattern** (`scripts/maintainer/baseline_inventory.sh:2912-2968`):

```bash
verify_snapshot_relation() {
  local ledger="$1" worktree_mode="${2:-standard}" ... verdict=authorized_bookkeeping
  ...
  [[ -n "$committed_blob" && "$committed_blob" == "$current_blob" ]] || verdict=refresh_required
  git merge-base --is-ancestor "$ledger_commit" "$head" 2>/dev/null || verdict=refresh_required
  verify_external_snapshot_receipts "$ledger_commit" "$ledger" "$evidence_base" "$head" || verdict=refresh_required
  ...
  [[ "$class" != unknown ]] || verdict=refresh_required
  ...
  printf 'snapshot_relation: %s\n' "$verdict"
  [[ "$verdict" == authorized_bookkeeping ]]
}
```

The lint-only repair must preserve this relation behavior byte-for-behavior except where a warning proves dead state.

---

### `scripts/maintainer/repo_hygiene_check.sh` (utility, batch + request-response)

**Analogs:** its current result aggregator and `.github/workflows/release.yml` exact-ref validator.

**CLI and result vocabulary** (`scripts/maintainer/repo_hygiene_check.sh:4-23,65-82`):

```bash
MODE="local"
RUN_MIX_CI=1
REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"

declare -a RESULTS=()
PASS_COUNT=0
WARN_COUNT=0
BLOCK_COUNT=0

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"
  RESULTS+=("[$level] $label: $detail")
  case "$level" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    BLOCK) BLOCK_COUNT=$((BLOCK_COUNT + 1)) ;;
  esac
}
```

Add a narrow exact-baseline acceptance mode/helper without removing ordinary `local` or `--ci` diagnostics. Keep one compact receipt in normal stdout; do not create a committed receipt after final SHA capture. Require an explicit disposition for every retained `WARN` in acceptance mode.

**Exact identity validation analog** (`.github/workflows/release.yml:95-117`):

```bash
set -euo pipefail
[[ "$RECOVERY_REF" =~ ^[0-9a-f]{40}$ ]]
git fetch --no-tags origin main
verified_sha="$(git rev-parse --verify "${RECOVERY_REF}^{commit}")"
test "$verified_sha" = "$RECOVERY_REF"
test "$verified_sha" = "$(git rev-parse origin/main)"
ci_run="$(gh api "repos/$GH_REPO/actions/runs/$SOURCE_CI_RUN_ID")"
canonical_ci_workflow_id="$(gh api "repos/$GH_REPO/actions/workflows/ci.yml" --jq '.id')"
test "$(jq -r '.name' <<< "$ci_run")" = "CI"
test "$(jq -r '.path' <<< "$ci_run")" = ".github/workflows/ci.yml"
test "$(jq -r '.workflow_id' <<< "$ci_run")" = "$canonical_ci_workflow_id"
test "$(jq -r '.head_branch' <<< "$ci_run")" = "main"
test "$(jq -r '.status' <<< "$ci_run")" = "completed"
test "$(jq -r '.conclusion' <<< "$ci_run")" = "success"
test "$(jq -r '.head_sha' <<< "$ci_run")" = "$verified_sha"
test "$(jq -r '.repository.full_name' <<< "$ci_run")" = "$GH_REPO"
```

Replace the weak `gh run list --limit 1` substring checks at `repo_hygiene_check.sh:463-487` in the exact mode with `gh api` + `jq -e` field equality. Validate HEAD, local `main`, and `origin/main` against one captured 40-hex baseline before the local gate; capture HEAD before `mix ci` and compare it again afterward (`repo_hygiene_check.sh:492-500`). Missing, malformed, multiple/ambiguous, queued, cancelled, failed, wrong-workflow, wrong-repository, wrong-event, wrong-branch, or wrong-SHA evidence is `BLOCK`, never a convenient fallback.

---

### `test/support/lockspire/release_proof/package_assertions.ex` (test utility, file-I/O + request-response)

**Analog:** the file's existing semantic phase attributes and fake-command fixtures.

**Phase-label pattern** (`test/support/lockspire/release_proof/package_assertions.ex:8-15`):

```elixir
@baseline_phase_number "138"
@next_phase_number "139"
@action_phase_number "140"
@closure_phase_number "141"
@baseline_phase_label "Phase " <> @baseline_phase_number
@action_phase_label "Phase " <> @action_phase_number
@closure_phase_label "Phase " <> @closure_phase_number
@baseline_phase_commit_prefix "docs(phase-" <> @baseline_phase_number <> "): "
```

Repair the thirteen active proof-quality findings by composing fixture text, fixture names, commit subjects, and state labels from these semantic attributes. Do not exclude the helper from `QualityBaseline`, weaken `~r/\bphase(?:[_ -]?\d+)\b/i`, or delete lifecycle assertions. Existing approved examples include `@baseline_phase_commit_prefix <> "record passed verification"` (`:2001-2004`) and `@baseline_phase_label <> " complete"` (`:3606-3610`).

**Process-fixture pattern** (`test/support/lockspire/release_proof/package_assertions.ex:4425-4465`):

```elixir
fixture = unique_tmp_fixture("lockspire-github")
bin = Path.join(fixture, "bin")

try do
  File.mkdir_p!(bin)
  File.write!(Path.join(bin, "git"), fake_git_script())
  File.write!(Path.join(bin, "gh"), fake_gh_script())
  File.chmod!(Path.join(bin, "git"), 0o755)
  File.chmod!(Path.join(bin, "gh"), 0o755)

  {command_output, status} =
    System.cmd("bash", [Paths.path("scripts/maintainer/baseline_inventory.sh"), ...],
      env: env,
      stderr_to_stdout: true
    )
  assert status == 0, command_output
after
  File.rm_rf(fixture)
end
```

Reuse this isolated `PATH`/fake-`gh` style if hygiene behavior needs executable cases. Cover exact match, wrong SHA, wrong workflow identity/repository, malformed/incomplete JSON, nonterminal/cancelled/failure, WARN disposition, and HEAD movement.

---

### `test/lockspire/release/repository_hygiene_contract_test.exs` (test, batch + request-response)

**Analog:** the same thin focused-suite delegation style (`test/lockspire/release/repository_hygiene_contract_test.exs:1-15`).

```elixir
defmodule Lockspire.Release.RepositoryHygieneContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.ReleaseProof.PackageAssertions

  test "repository hygiene stays deterministic and outside the public product surface" do
    PackageAssertions.assert_repository_hygiene!()
  end
end
```

Keep scenario mechanics in `PackageAssertions`; keep this module as named behavioral entry points. If an executable shell fixture is slow, follow the existing local convention of a focused `@tag timeout: ...` rather than moving it to integration or creating a Mix task.

---

### `test/lockspire/release_ci_evidence_contract_test.exs` (test, static transform)

**Analog:** its current `File.read!` + positive/negative structural assertions (`test/lockspire/release_ci_evidence_contract_test.exs:4-54`).

```elixir
@automerge Path.expand("../../.github/workflows/release-please-automerge.yml", __DIR__)
@release Path.expand("../../.github/workflows/release.yml", __DIR__)

test "publish validator accepts only an exact current main head with matching successful CI metadata" do
  workflow = File.read!(@release)
  assert workflow =~ "[[ \"$RECOVERY_REF\" =~ ^[0-9a-f]{40}$ ]]"
  assert workflow =~ "test \"$(jq -r '.head_sha' <<< \"$ci_run\")\" = \"$verified_sha\""
  refute workflow =~ "recovery_ref: ${{ inputs.recovery_ref }}"
end
```

Add one focused structural test for the push/no-publish graph. Assert push enables only `Maintain Release Please PR`, while exact-ref dispatch exclusively gates `Validate exact main head and CI evidence`, `Prove exact package before publication`, `Publish verified release to Hex`, and `Verify public install truth`. This is structure proof; the final checkpoint must still query actual job outcomes for the final SHA.

**Job-graph authority** (`.github/workflows/release.yml:33-35,70-72,119-122,204-207,312-315`):

```yaml
release-please:
  name: Maintain Release Please PR
  if: ${{ github.event_name == 'push' }}
recovery-validation:
  name: Validate exact main head and CI evidence
  if: ${{ github.event_name == 'workflow_dispatch' }}
prepublish-proof:
  name: Prove exact package before publication
  needs: recovery-validation
publish:
  name: Publish verified release to Hex
  needs: [recovery-validation, prepublish-proof]
post-publish-install-truth:
  name: Verify public install truth
  needs: [recovery-validation, publish]
```

---

### `test/lockspire/workflow_supply_chain_contract_test.exs` (test, batch + file-I/O)

**Analog:** the existing immutable-reference scan (`test/lockspire/workflow_supply_chain_contract_test.exs:4-19`).

```elixir
for path <- Path.wildcard(Path.expand("../../.github/workflows/*.yml", __DIR__)) do
  workflow = File.read!(path)
  assert workflow =~ "timeout-minutes:", "#{path} is missing a job timeout"

  for [reference] <- Regex.scan(~r/uses:\s+([^\s#]+)/, workflow, capture: :all_but_first) do
    assert String.starts_with?(reference, "./") or
             Regex.match?(~r/@[0-9a-f]{40}$/, reference),
           "#{path} has mutable external action #{reference}"
  end
end
```

Build a deterministic `paths` list containing the workflow glob plus `.github/actions/release-please/action.yml`. Apply the external `uses:` full-40-hex rule to both; continue allowing local `./` actions. Keep workflow-only timeout and PostgreSQL-image assertions scoped to workflow files if the composite has no corresponding concept. The protected composite's current external reference is full-SHA pinned at `.github/actions/release-please/action.yml:121-125`.

---

### `test/support/lockspire/release_proof/workflow_assertions.ex` (test utility, static transform)

**Analog:** its existing shared workflow/docs assertions and explicit order comparison.

**Executable order pattern** (`test/support/lockspire/release_proof/workflow_assertions.ex:8-42`):

```elixir
workflow = Paths.read!(".github/workflows/release.yml")
publish = Paths.final_workflow_job(".github/workflows/release.yml", "publish")

assert publish =~ "needs.recovery-validation.result == 'success'"
assert publish =~ "git checkout --detach \"$VERIFIED_SHA\""

assert byte_offset(publish, "- name: Publish package") <
         byte_offset(publish, "- name: Create matching GitHub release")
```

If adding a prose regression assertion, extend the existing `guide = Paths.read!("docs/maintainer-release.md")` pattern (`:44-59,62-75`) and assert only stable executable truths: exact current-main 40-hex dispatch input, package publish before matching GitHub release, and the absence of a `mix test.phase3` claim. Avoid reading historical `.planning/` archives from active proof; `test/lockspire/release_readiness_contract_test.exs:19-35` explicitly rejects that pattern.

---

### `.planning/REPO-HYGIENE-CHECKLIST.md` (maintainer config/docs, request-response)

**Analog:** the same checklist's concise command-and-verdict form (`.planning/REPO-HYGIENE-CHECKLIST.md:13-30`) plus the implemented exact-SHA hygiene mode.

```markdown
## GitHub

- Check open PRs: `gh pr list -R szTheory/lockspire --state open`.
- Check open issues: `gh issue list -R szTheory/lockspire --state open`.
- Confirm latest `main` CI and Release workflow runs are successful or intentionally skipped/no-op.

## Local Gates

- Run `mix ci`.
- Run `bash ./scripts/maintainer/repo_hygiene_check.sh`.
```

Change “latest” to the exact synchronized baseline SHA and name the exact acceptance command/flag chosen in the script. Document that every `WARN` needs a disposition. Clarify that active planning truth (v1.38 / Phase 139) and latest-shipped truth (v1.37 / `1.5.0`) are distinct coherent facts; do not require `.planning/MILESTONES.md` to pretend the active milestone shipped.

---

### `.planning/RELEASE-TRAIN.md` (release config/docs, event-driven)

**Analog:** `.github/workflows/release.yml`, the executable authority.

**Preserved historical block** (`.planning/RELEASE-TRAIN.md:7-15`): keep version `1.5.0`, source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, CI run `33141161205`, release run `33141484467`, tag `lockspire-v1.5.0`, and tar SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de` unchanged.

**Prose-to-executable reconciliation** (`.planning/RELEASE-TRAIN.md:19-27,46-52`; `.github/workflows/release.yml:33-72,256-284`):

```yaml
release-please:
  if: ${{ github.event_name == 'push' }}
recovery-validation:
  if: ${{ github.event_name == 'workflow_dispatch' }}
...
- name: Publish package
- name: Create matching GitHub release
```

Remove the claims that a push publishes to Hex and that GitHub release creation precedes Hex publication. State that push maintains Release Please PR state; only protected exact-ref dispatch publishes, and it publishes the verified package before creating the matching GitHub release. Replace “latest main CI” eligibility with exact candidate/current-main SHA evidence. Do not alter the release version marker or historical receipt block.

---

### `docs/maintainer-release.md` (maintainer docs, event-driven)

**Analog:** its existing numbered normal-flow description aligned with `.github/workflows/release.yml` (`docs/maintainer-release.md:32-44`).

```markdown
6. Wait for the merge commit's own successful `CI` push run on the current `main` head.
7. Let the validator confirm the exact immutable main SHA, matching successful CI run, and repository identity.
8. Let the unprivileged prepublish job build one tar ...
9. Let the protected publisher validate and consume that same SHA-bound artifact ...
```

Apply three narrow fixes:

1. Remove `mix test.phase3` from the documented `mix ci` members (`docs/maintainer-release.md:58-70`); `mix.exs:147-155` is authoritative.
2. At line 84 and checklist lines 98-107, say dispatch accepts only a lowercase full 40-hex commit equal to current `origin/main`, not “SHA or tag.”
3. Replace “latest successful main CI” with exact candidate/current-main SHA evidence.

Preserve the guide's existing separation of repo-owned, protected-environment, and workflow-run evidence (`:43-54`) and its statement that release work does not define a second public support contract (`:16-18`).

---

### `.planning/PROJECT.md` (planning config, batch transform)

**Analog:** the file's current active-versus-shipped structure and `.planning/STATE.md` active-phase fields.

**Current truth pattern** (`.planning/PROJECT.md:11-20,37-49`):

```markdown
## Current Milestone: v1.38 Repository Baseline & Reconciliation

## Current State

Phase 138 completed the v1.38 evidence foundation. ... Phase 139 now owns
reconciliation of required CI, release, hygiene, and planning truth ...

The most recently shipped work, v1.37 / Lockspire 1.5.0, ...
```

Reconcile only the stale present-tense `## Next Milestone Goals` paragraph at `.planning/PROJECT.md:83-85`; it currently says to return to the sustaining train after archiving v1.37 even though v1.38 / Phase 139 is active. Preserve the current v1.38 heading and Phase 139 ownership, and preserve v1.37 / `1.5.0` as latest shipped truth. Do not rewrite completed-milestone history.

## Shared Patterns

### Capture Once, Compare Everywhere

**Source:** `.github/workflows/release.yml:95-117`
**Apply to:** exact acceptance path in `repo_hygiene_check.sh`, executable fixtures, final live checkpoint.

One lowercase 40-hex `BASELINE_SHA` is the join key for HEAD, local `main`, `origin/main`, pre/post-`mix ci`, canonical CI, and push Release outcome. Never substitute the Phase 138 ledger commit, a branch head, historical `1.5.0` source SHA, or newest green run.

### Structured Remote Evidence

**Source:** `.github/workflows/release.yml:104-115`
**Apply to:** every CI/Release `PASS` claim.

Use `gh api` and `jq -e`/exact field equality. Capture workflow identity/path, repository, branch, event, status, conclusion, head SHA, run ID, and URL. Zero, ambiguous, malformed, incomplete, wrong-identity, or nonterminal results fail closed in acceptance mode.

### Intentional No-Publish Is a Positive Outcome

**Source:** `.github/workflows/release.yml:33-122,204-315`
**Apply to:** CI-07 shell receipt, release CI contract, maintained prose.

For a push at the baseline SHA, require the Release run and `Maintain Release Please PR` job to succeed, while the four dispatch/publication jobs are `skipped`. Do not dispatch `release.yml` to manufacture Phase 139 evidence and do not call this state a published release.

### PASS/WARN/BLOCK and WARN Dispositions

**Source:** `scripts/maintainer/repo_hygiene_check.sh:65-82,512-526`
**Apply to:** hygiene implementation, tests, checklist.

Preserve the aggregator and terminal exit contract. Exact acceptance requires zero `BLOCK` plus a compact explicit disposition for every `WARN`; an undispositioned warning cannot silently become acceptance.

### Focused ExUnit Proof

**Sources:** `test/lockspire/release/repository_hygiene_contract_test.exs:1-15`, `test/lockspire/release_ci_evidence_contract_test.exs:4-54`, `test/support/lockspire/release_proof/package_assertions.ex:4425-4465`
**Apply to:** all Phase 139 executable corrections.

Keep public test modules thin, put reusable fixtures in `test/support`, inject fake `git`/`gh` through an isolated `PATH`, assert both success and fail-closed variants, and clean temporary fixtures in `after`. No application authentication/authorization pattern applies because this phase adds no product request surface.

### Executable Authority Over Prose

**Sources:** `.github/workflows/release.yml:33-315`, `test/support/lockspire/release_proof/workflow_assertions.ex:8-42`
**Apply to:** `.planning/RELEASE-TRAIN.md`, `docs/maintainer-release.md`, `.planning/REPO-HYGIENE-CHECKLIST.md`.

Correct maintained prose to the current workflow's trigger split and publish order. Do not redesign the workflow to match stale prose, and do not touch release-owned `mix.exs` versioning, `.release-please-manifest.json`, `CHANGELOG.md`, tags, GitHub releases, or Hex state.

### Historical and Supplemental Evidence Boundaries

**Sources:** `.planning/RELEASE-TRAIN.md:7-15`, `.planning/MILESTONES.md:16-24`, `test/lockspire/conformance_workflow_contract_test.exs:61-88`
**Apply to:** all receipts and prose.

Keep the `1.5.0` chain immutable. Keep OIDF/FAPI results redacted, supplemental, non-certifying, and outside required acceptance; retained supplemental failures neither satisfy nor block the repository-owned baseline.

## No Analog Found

None. Every likely Phase 139 change extends an existing tracked maintainer, proof, ledger, or prose surface. No new subsystem or runtime file is warranted.

## Explicit Non-Targets

- `.github/workflows/release.yml`, `.github/workflows/ci.yml`, `.github/workflows/release-please-automerge.yml`, and `.github/actions/release-please/action.yml` are executable authorities to test/preserve, not demonstrated implementation gaps requiring redesign.
- `.planning/ROADMAP.md` and `.planning/STATE.md` already carry the active v1.38 / Phase 139 truth; verify them but do not churn them without a newly proven contradiction.
- `.planning/MILESTONES.md`, archived milestone/phase evidence, the `1.5.0` receipts, and supplemental failure history are historical evidence and must not be rewritten.
- `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, release tags, GitHub release state, and Hex publication are release-owned and out of scope.
- Branch/tag/worktree/PR/issue cleanup and dependency triage belong to Phase 140; the Phase 138 inventory remains proposal-only.
- A committed final dated baseline belongs to Phase 141. Phase 139's post-main exact-SHA receipt must remain read-only/external so it does not invalidate itself.

## Metadata

**Analog search scope:** `scripts/maintainer/`, `scripts/publish/`, `.github/workflows/`, `.github/actions/`, `test/lockspire/`, `test/support/lockspire/release_proof/`, `.planning/`, `docs/`
**Strong analogs read:** 5 primary behavior families (hygiene shell, protected release workflow, release-proof helpers, focused ExUnit contracts, maintained truth documents)
**Tracked-source gate:** passed for every named analog
**Pattern extraction date:** 2026-09-11
