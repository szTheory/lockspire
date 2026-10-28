# Phase 178 Plan 11 — Scoped CI cache and timing correction

Observed 2026-10-28 14:37:43 UTC. This is local static evidence for the workflow correction; no hosted execution, timing improvement, package proof, or passing candidate graph is claimed.

The Integration and Minimum root Mix caches now use separate restore/save actions at the existing immutable `actions/cache` revision. Successful warnings-as-errors compilation and unchanged locks precede each save; saves happen before the later long tests or packaged host proof. The original lane-specific OS/toolchain/lock keys, fallback keys, paths and GitHub branch scopes are retained. A cache hit never skips check-locked dependency resolution or current compilation. The existing child dependency caches remain unchanged because there is no separate successful preparation witness before their proof starts.

The coverage job restores the exact Fast test cache with the same current toolchain and root lock, explicitly selects `MIX_ENV=test`, and resolves dependencies and compiles current source before importing coverage. It retains the two producer dependencies and existing SHA/checksum-bound imported coverage validation. No acceptance results, package artifacts, private homes, live processes or credentials were added to cache paths.

Integration uploads its existing timing JSON on both success and failure when the file exists. A failure before the matrix creates that file produces no invented timing artifact. Native cache-hit outputs and step metadata remain available; the matrix's existing partition durations are retained. No new setup/compile duration receipt or percentage saving is asserted.

The Integration suite receives all six authenticated frozen-input path/pin values from the existing provisioner outputs. The lifetime receipt validator uses the candidate source revision; workflow artifact names and coverage continue to use `github.sha` as the job checkout identity. The direct expected-source assertion in `ci_workflow_evidence_contract_test.exs` was updated accordingly. Its ExUnit execution belongs to the owned source runner; it was not run by this worker.

The action's documented standalone restore/save inputs and primary-key output support the explicit boundary. GitHub documents successful-job-only automatic cache creation and branch-scoped cache access. These semantics were read from [the pinned restore action](https://github.com/actions/cache/blob/55cc8345863c7cc4c66a329aec7e433d2d1c52a9/restore/action.yml), [the pinned save action](https://github.com/actions/cache/blob/55cc8345863c7cc4c66a329aec7e433d2d1c52a9/save/action.yml), and [GitHub dependency caching reference](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching). Step conditions were checked against [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsif).

Validation after the last workflow edit:

- `actionlint -no-color .github/workflows/ci.yml`: exit 0, actionlint 1.7.12.
- `bash scripts/ci/lint_workflows.sh`: exit 0; all maintained workflow/shell files passed actionlint 1.7.12 and ShellCheck 0.11.0.
- `node scripts/ci_monitor.cjs check-actions .github/workflows/ci.yml`: exit 0, `PASS action pins .github/workflows/ci.yml`.
- `git diff --check`: exit 0.
- Static comparison to the current HEAD version: seven job IDs unchanged; two saves follow successful preparation and precede their long partition; restore keys/paths unchanged; six pin bindings match provisioner outputs; source identity remains distinct from job identity; coverage SHA validation remains.

Workflow SHA-256 before: `b65f62e3fe449ec6f89d27d50414c2524535424fa7e472887ac80bf65ca87c3f`.
Workflow SHA-256 after: `9c538250915eb70c2d6bc8d76eceed4121c4ce2bad5fd94a2193125133c51950`.

Changed source paths: `.github/workflows/ci.yml`, `test/lockspire/ci_workflow_evidence_contract_test.exs`. No dependency, job graph, required gate, checkout policy, publication, or remote repository mutation was introduced.
