# Phase 126 Research: Trusted Release Path

**Discovery level:** 1 — quick verification of existing GitHub Actions and npm runtime contracts.
**Date:** 2026-08-26

## Verified Constraints

- GitHub's workflow-run payload and REST workflow-run response expose the evidence this phase needs: run ID, workflow identity/path, `head_sha`, `head_branch`, event, status, conclusion, and repository. The publish validator can compare all of them before exposing a checkout SHA.
- GitHub documents a full commit SHA as the immutable pin for third-party Actions. The only unpinned third-party Action in the current workflows is `actions/upload-artifact@v7`.
- The current automerge workflow dispatches publication using the release PR merge SHA while citing the *pre-merge* CI run. It must instead let the merge create a new `main` push, then dispatch only from the successful CI `workflow_run` for that exact merge SHA.
- Workflow-dispatch expressions must enter shell steps through `env`; direct `${{ inputs.* }}` interpolation inside shell is not an acceptable trust boundary.
- Post-publish install truth can reuse `scripts/publish/verify_install_truth.sh` in an unprivileged job with no `hex-publish` environment or `HEX_API_KEY`, then upload its log as audit evidence.
- Actionlint 1.7.12 and ShellCheck 0.11.0 reproduce the current repository findings. Actionlint reports the OIDF inline `MIX_ENV=test` assignment; ShellCheck warning-level findings are limited to the two conformance scripts. Informational/style findings are not warnings and need not be rewritten to satisfy CI-01.

## Package Legitimacy Audit

No new npm package is introduced. The phase upgrades the two existing direct dependencies of the checked-in Release Please runtime.

| Package | Registry / upstream | Current | Verified candidate | Classification | Evidence |
|---------|---------------------|---------|--------------------|----------------|----------|
| `@actions/core` | npm; `github.com/actions/toolkit` | 1.10.0 | 3.0.1 | VERIFIED | `npm view` reports the official Actions Toolkit repository and maintained package; a clean package-lock resolution with Node 24 runtime peers is audit-clean. |
| `release-please` | npm; `github.com/googleapis/release-please` | 17.3.0 | 17.11.2 | VERIFIED | `npm view` reports the GoogleApis repository and maintainers; the existing runtime API remains within release-please 17.x. |

The tested pair `@actions/core@3.0.1` + `release-please@17.11.2` produced zero npm audit findings at moderate-or-higher severity in a clean lock-only resolution. The executor must regenerate the checked-in lockfile with scripts disabled, run the runtime contract tests, and retain the zero-audit gate; if the registry state has changed, select the lowest compatible versions that restore a zero finding result and record the resolved versions in the plan summary.

## Primary References

- GitHub Actions secure-use reference: https://docs.github.com/en/actions/reference/security/secure-use
- GitHub REST workflow-runs API: https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10
- GitHub workflow-run event reference: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run

## Planning Implications

1. Release commit CI evidence is the tracer and hardest constraint; build it first.
2. Publication, GitHub release creation, and install-truth verification use the validator's exact SHA output, never raw dispatch input.
3. Supply-chain hardening follows the release-flow rewrite so final workflow lint validates the complete end state.
4. Lock checks use `mix deps.get --check-locked` plus `git diff --exit-code` rather than relying on a mutating dependency command.
