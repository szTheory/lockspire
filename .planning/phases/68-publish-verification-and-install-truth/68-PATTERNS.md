# Phase 68: Publish Verification & Install Truth - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/verify_install_truth.sh` | utility | file-I/O | `scripts/conformance/run_phase37_suite.sh` | role-match |
| `test/lockspire/publish_verification_test.exs` | test | assertion | `test/lockspire/release_readiness_contract_test.exs` | exact |

## Pattern Assignments

### `scripts/verify_install_truth.sh` (utility, file-I/O)

**Analog:** `scripts/conformance/run_phase37_suite.sh`

**Imports and Strictness pattern** (lines 1-3):
```bash
#!/usr/bin/env bash

set -euo pipefail
```

**Core pattern (Temp directory management)** (line 13):
```bash
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-install-truth.XXXXXX")"
```

**Error handling pattern** (lines 16-35, 62):
```bash
cleanup() {
  local exit_code=$?
  
  if [[ -f "${WORK_DIR}/..." ]]; then
    # cleanup resources
  fi

  rm -rf "${WORK_DIR}"
  exit "${exit_code}"
}

trap cleanup EXIT
```

**Validation pattern** (lines 64-70):
```bash
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}
```

---

### `test/lockspire/publish_verification_test.exs` (test, assertion)

**Analog:** `test/lockspire/release_readiness_contract_test.exs`

**Imports pattern** (lines 1-4):
```elixir
defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
```

**Core assertion pattern** (lines 91-95):
```elixir
  test "maintainer guide keeps the review-only release pr posture and separate evidence buckets" do
    guide = File.read!(@maintainer_guide_path)

    assert guide =~ "run `mix ci`"
    assert guide =~ "`mix ci` is the maintained contributor lane"
```

**Helper method pattern** (lines 53-59):
```elixir
  defp manifest_version do
    @release_please_manifest_path
    |> File.read!()
    |> then(&Regex.run(~r/"\."\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end
```

## Shared Patterns

### Test Organization
**Source:** `test/lockspire/release_readiness_contract_test.exs`
**Apply to:** All verification test files
```elixir
  # Path.expand is used to reliably locate files relative to the test file
  @some_file_path Path.expand("../../path/to/file", __DIR__)
```

## Metadata

**Analog search scope:** `scripts/`, `test/lockspire/`
**Files scanned:** 200+
**Pattern extraction date:** 2026-05-07