# Phase 138: Baseline Inventory & Evidence Taxonomy - Pattern Map

**Mapped:** 2026-08-28  
**Files analyzed:** 4  
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/maintainer/baseline_inventory.sh` | utility (repo-maintainer CLI) | batch / transform | `scripts/maintainer/repo_hygiene_check.sh` | role-match |
| `test/lockspire/release/repository_hygiene_contract_test.exs` | test | batch / transform | same file | exact |
| `test/support/lockspire/release_proof/package_assertions.ex` | utility (test assertion helper) | file-I/O / transform | same file | exact |
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-YYYY-MM-DD.md` | config/document artifact | batch / transform | `138-VALIDATION.md` | partial-match |

## Pattern Assignments

### `scripts/maintainer/baseline_inventory.sh` (utility, batch / transform)

**Analog:** `scripts/maintainer/repo_hygiene_check.sh` (same repo-local maintainer Bash boundary; it is a readiness gate, so do not copy its PASS/WARN/BLOCK semantics into the collector).

**Bootstrap and repository-root pattern** (lines 1-6, 55-56):

```bash
#!/usr/bin/env bash
set -euo pipefail

REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
```

Use the strict shell mode, an overridable remote, and a resolved repository root. The new collector should use its own purpose-specific environment variable name (for example, `LOCKSPIRE_INVENTORY_REMOTE`) rather than inheriting hygiene-gate terminology.

**Argument-validation pattern** (lines 25-52):

```bash
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done
```

Copy this fail-closed CLI style for output-path/replace controls. Default to the UTC-dated ledger and refuse accidental overwrite unless an explicit option authorizes it.

**Required-command and source-status pattern** (lines 54-58, 80-82):

```bash
if ! command -v git >/dev/null 2>&1; then
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi

have_gh() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}
```

Adapt this preflight shape, but render per-source receipts with `complete`, `partial`, `unavailable`, or `not_applicable`; a missing or failed dependency must produce a ledger receipt, not an empty section.

**Safe Git inspection and explicit degradation pattern** (lines 403-430):

```bash
status_output="$(git status --porcelain)"
if [[ -z "$status_output" ]]; then
  record_result "PASS" "working tree" "clean"
else
  record_result "BLOCK" "working tree" "dirty state detected; commit, stash, or discard local changes first"
fi

git fetch "$REMOTE" --prune >/dev/null 2>&1 || true

if git show-ref --verify --quiet "refs/heads/main" && git show-ref --verify --quiet "refs/remotes/$REMOTE/main"; then
  local ahead behind
  read -r behind ahead <<<"$(git rev-list --left-right --count "$REMOTE/main...main")"
  # ... distinguish exact, behind, and ahead states
else
  record_result "WARN" "main divergence" "could not compare local main to $REMOTE/main"
fi
```

Use the command families and explicit unavailable branch, while correcting behavior for this phase: capture the fetch exit status and receipt, use `git fetch --prune --tags "$remote"` (never `--prune-tags`), use porcelain v2, and never reduce a failed fetch/API call to a clean result.

**Deterministic Git-ref/worktree pattern** (lines 432-450):

```bash
worktree_output="$(git worktree list --porcelain)"
worktree_count="$(printf '%s\n' "$worktree_output" | grep -c '^worktree ')"

release_prep_branches="$(git for-each-ref --format='%(refname:short)' refs/heads/release-prep)"
```

Reuse porcelain/ref-iteration interfaces, then normalize and sort all branch, tag, and worktree rows before assigning stable `GIT-BR-*`, `GIT-TAG-*`, and `GIT-WT-*` IDs.

**Boundary to preserve** (lines 271-280):

```bash
if [[ ! -e lib/mix/tasks/lockspire.demo.cleanup.ex &&
      ! -e lib/mix/tasks/lockspire.hygiene.ex &&
      ! -e lib/lockspire/repo_hygiene.ex &&
      ! -e lib/lockspire/docker_cleanup.ex ]]; then
  record_result "PASS" "public surface contract" "no Mix cleanup task, runtime module, protocol/admin behavior, packaged Docker surface, or hosted-auth support expansion"
fi
```

The collector remains under `scripts/maintainer/`; do not add a Mix task, `lib/` module, Ecto schema, Phoenix route, or runtime dependency.

---

### `test/lockspire/release/repository_hygiene_contract_test.exs` (test, batch / transform)

**Analog:** the existing test file (exact entry-point match).

**Minimal async ExUnit wrapper pattern** (lines 1-13):

```elixir
defmodule Lockspire.Release.RepositoryHygieneContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.ReleaseProof.PackageAssertions

  test "repository hygiene stays deterministic and outside the public product surface" do
    PackageAssertions.assert_repository_hygiene!()
  end
end
```

Add a focused named test in this file that delegates to a `PackageAssertions` function (for example `assert_baseline_inventory_collector!`). Keep it hermetic: test checked-in script text and fixtures/command overrides, not a live GitHub query.

---

### `test/support/lockspire/release_proof/package_assertions.ex` (utility, file-I/O / transform)

**Analog:** the existing `PackageAssertions` helper (exact role and data-flow match).

**Imports and repository-file loading pattern** (lines 1-6, 36-40):

```elixir
defmodule Lockspire.TestSupport.ReleaseProof.PackageAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

  def assert_repository_hygiene! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")
    ci = Paths.read!(".github/workflows/ci.yml")
    adoption_docs = Paths.read!("docs/adoption-demo.md")
```

Put collector source/output-contract assertions here, reading `scripts/maintainer/baseline_inventory.sh` through `Paths.read!/1`. This preserves repo-root resolution and keeps the test module declarative.

**Positive and negative source-contract assertions** (lines 41-50):

```elixir
assert script =~ "ci_source_contract_checks"
assert script =~ "repo_hygiene_check.sh [--ci] [--project NAME]"
refute script =~ "mix lockspire.demo.cleanup"
refute File.exists?(Paths.path("lib/lockspire/repo_hygiene.ex"))
```

Apply this literal-contract style to assert required command/schema strings (pagination, source statuses, stable prefixes, source manifest, redaction) and to refute dangerous strings (`--prune-tags`, destructive Git commands, raw GitHub bodies, Mix/runtime additions). Avoid brittle assertions on live values such as current PR counts or SHAs.

**Package-boundary enumeration pattern** (lines 52-67):

```elixir
defp package_paths(files) do
  files
  |> Enum.flat_map(fn relative_path ->
    path = Paths.path(relative_path)

    cond do
      File.dir?(path) -> Path.wildcard(Path.join(path, "**/*"), match_dot: true)
      File.exists?(path) -> [path]
      true -> []
    end
  end)
  |> Enum.reject(&File.dir?/1)
  |> Enum.map(&Path.relative_to(&1, Paths.path(".")))
end
```

Keep the collector outside package inputs and assert that fact through the existing package-path boundary checks.

---

### `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-YYYY-MM-DD.md` (document artifact, batch / transform)

**Analog:** `138-VALIDATION.md` (partial match: phase-local Markdown with compact YAML front matter and stable semantic headings). No existing generated evidence ledger was found.

**Front-matter and heading pattern** (lines 1-10):

```markdown
---
phase: 138
slug: baseline-inventory-evidence-taxonomy
status: draft
created: 2026-08-28
---

# Phase 138 — Validation Strategy
```

Use the same compact, accessible Markdown opening, then apply the Phase 138 research contract directly: snapshot metadata/collection window; source receipts; ordered Git, GitHub, and maintained-record sections; stable evidence IDs; and explicit `executed: no — Phase 138 proposal only` for every actionable proposal. This artifact is canonical Markdown, not a JSON/YAML sidecar.

## Shared Patterns

### Repo-local maintainer boundary

**Source:** `scripts/maintainer/repo_hygiene_check.sh` lines 271-280; `test/support/lockspire/release_proof/package_assertions.ex` lines 36-50.

**Apply to:** collector and its contract tests.

Maintainer operations live under `scripts/maintainer/`, and release-proof tests must continue to prevent a corresponding Mix task or runtime module. The new script may observe state and perform the specifically authorized metadata fetch only; it must never create a public/library surface.

### Fail-visible evidence collection

**Source:** `scripts/maintainer/repo_hygiene_check.sh` lines 403-430 and 454-489.

**Apply to:** Git, GitHub, and maintained-record source collectors.

Use explicit success/error branches around each source. In the inventory, render the locked completeness values and a command/exit/scope/limitation receipt rather than the hygiene script's gate levels. `gh` absence/auth failure, API errors, and pagination problems must remain visible as `unavailable` or `partial`.

### Deterministic contract tests

**Source:** `test/lockspire/release/repository_hygiene_contract_test.exs` lines 1-13; `test/support/lockspire/release_proof/package_assertions.ex` lines 36-50.

**Apply to:** every Phase 138 requirement.

Keep tests async, delegate substantive checks to the shared assertion helper, inspect repo-relative paths via `Paths.read!/1`, and assert both required safe markers and forbidden unsafe markers. Live GitHub state belongs to manual collection verification, not unit-test fixtures.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-YYYY-MM-DD.md` | document artifact | batch / transform | The repository has phase-local Markdown/front matter, but no prior canonical, collector-generated evidence ledger with source receipts, stable evidence IDs, and proposal-only rows. Use `138-RESEARCH.md`'s deterministic row contract. |

## Metadata

**Analog search scope:** `scripts/maintainer/`, `test/lockspire/release/`, `test/support/lockspire/release_proof/`, `.planning/`  
**Files scanned:** 8  
**Pattern extraction date:** 2026-08-28
