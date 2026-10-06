# Phase 142: Merge the Corrected Main Baseline - Pattern Map

**Mapped:** 2026-10-06  
**Files analyzed:** 3  
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/RELEASE-TRAIN.md` | maintainer document | documentation / evidence record | `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` | role-match |
| `test/lockspire/release/repository_hygiene_contract_test.exs` | test | file-I/O contract | `test/lockspire/release_ci_evidence_contract_test.exs` | role-match; same test area is the exact file to extend |
| `.planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md` (optional) | maintainer document | evidence record | `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` | role-match |

All named analogs are tracked files. This is a small maintainer change; no application controller, service, or runtime data-flow pattern applies.

## Pattern Assignments

### `.planning/RELEASE-TRAIN.md` (maintainer document, documentation / evidence record)

**Analog:** `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`

The release-train file is the existing ledger to edit in place. Preserve its concise bullets, dated evidence attribution, and distinction between public package truth and Release Please metadata. The Phase 141 baseline shows the evidence-record convention:

**Evidence identity and public truth** (`141-BASELINE.md`, lines 7-11):

```markdown
## Accepted source and observation boundary

Phase 140's post-summary terminal receipt accepts source tree `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`. At receipt time, `HEAD`, local `main`, fetched and advertised `origin/main` all matched that full SHA; the worktree and exact binary diff were clean.

This acceptance applies only to that source tree. The Phase 141 branch and commits containing this report or later planning records are documentation commits outside the receipt. A later source-acceptance claim needs evidence for its own exact SHA.
```

For this edit, the current release-train baseline already separates metadata from public package proof at lines 9-15. Correct only the Phase 141 relative target on line 15 to `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`; retain the existing statement that 1.5.0 is latest public unless refreshed public evidence proves otherwise.

### `test/lockspire/release/repository_hygiene_contract_test.exs` (test, file-I/O contract)

**Analog:** `test/lockspire/release_ci_evidence_contract_test.exs`

The destination file already owns release-hygiene contracts and uses synchronous ExUnit tests. Add the focused assertion there, keeping scope limited to local Markdown destinations in `.planning/RELEASE-TRAIN.md`. The closest static repository-file assertion demonstrates root resolution and captured assertion diagnostics:

**Repository path and command assertion** (`repository_hygiene_contract_test.exs`, lines 18-29):

```elixir
@tag :phase139_gate_repair
test "repository-owned workflow and shell lint accepts the inventory collector" do
  repo_root = Path.expand("../../..", __DIR__)

  {output, status} =
    System.cmd("bash", ["scripts/ci/lint_workflows.sh"],
      cd: repo_root,
      stderr_to_stdout: true
    )

  assert status == 0, output
end
```

For a pure local-link contract, reuse the same `repo_root = Path.expand("../../..", __DIR__)` convention, read the single maintained record, extract its local Markdown destinations, and assert each target resolves with the failing destination in the assertion message. Avoid a shared parser, dependency, or repository-wide scan.

The neighboring release CI contract shows the direct static-file read pattern:

**Read and assert maintained repository files** (`release_ci_evidence_contract_test.exs`, lines 4-14):

```elixir
@automerge Path.expand("../../.github/workflows/release-please-automerge.yml", __DIR__)
@release Path.expand("../../.github/workflows/release.yml", __DIR__)

test "release automation dispatches post-merge CI and carries its exact evidence" do
  workflow = File.read!(@automerge)

  assert workflow =~ "CI_EVENT"
  assert workflow =~ ~S([[ "$ci_event" == "push" || "$ci_event" == "workflow_dispatch" ]])
```

No auth, database, or network setup belongs in this test. `repository_hygiene_contract_test.exs` uses `async: false` because its broader shell/Git fixtures require isolation; keep the new small link assertion within the existing module.

### `.planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md` (optional maintainer document, evidence record)

**Analog:** `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`

Follow its compact evidence-led sections and tables (lines 13-31 and 48-64): identify the accepted full source SHA, canonical CI and hygiene result for that same SHA, warning dispositions, public-package observation time, and the Phase 143 boundary. Keep raw logs out. If the result commit differs from the accepted source SHA, label the report-containing commit separately; do not imply the earlier acceptance covers it.

## Shared Patterns

### Evidence and release truth

**Source:** `.planning/RELEASE-TRAIN.md` lines 9-15 and 22-27; `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` lines 7-11, 21-31.

- Join readiness evidence on one full immutable SHA; earlier CI or hygiene evidence does not transfer to a later commit.
- Keep Release Please metadata, a no-publish result, and public package proof as separate claims.
- Attach observation dates to mutable public-release claims and recheck them during execution.
- Phase 142's record stops at readiness; protected publication and public artifact proof remain Phase 143 work.

### Static repository contract tests

**Source:** `test/lockspire/release_ci_evidence_contract_test.exs` lines 4-14; `test/lockspire/release/repository_hygiene_contract_test.exs` lines 18-29.

Resolve repository files from `__DIR__`, read only the target maintained file, and assert the narrowly scoped contract with useful failure context. Keep this regression in the existing release test area.

## No Analog Found

None. The optional result record has a close evidence-record analog; the link check belongs in an existing release-hygiene test module.

## Metadata

**Analog search scope:** `.planning/`, `test/lockspire/release/`  
**Files scanned:** 4 focused candidates  
**Pattern extraction date:** 2026-10-06
