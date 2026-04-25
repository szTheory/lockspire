---
phase: 16-verification-and-release-runtime-hygiene
verified: 2026-04-24T15:37:42Z
verified: 2026-04-24T16:01:16Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/9 must-haves verified
  gaps_closed:
    - "Release Please remains review-only, workflow_dispatch remains recovery-only, and the protected hex-publish lane still starts only after merge or explicit recovery of the exact intended revision."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Run the GitHub Release workflow once on workflow_dispatch with an invalid branch ref, then with a valid 40-character SHA or existing tag"
    expected: "The branch ref run fails before publish, the valid immutable ref run reaches the trusted lane, and the workflow emits no deprecated Node 20 runtime warning"
    why_human: "The protected hex-publish lane and GitHub Actions runtime behavior are external-service concerns that cannot be fully exercised from the local repo alone"
    result: "Satisfied by GitHub Actions runs 24898764939 (invalid `main` rejected before publish) and 24898785416 (exact SHA accepted and advanced to the protected `hex-publish` gate)"
---

# Phase 16: Verification and Release Runtime Hygiene Verification Report

**Phase Goal:** Close milestone verification for the PAR wedge and remove the known deprecated release runtime warning without regressing the trusted preview release path.
**Verified:** 2026-04-24T15:37:42Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Automated coverage proves PAR success, expiry, replay rejection, client binding, and discovery truth. | ✓ VERIFIED | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` passed with `30 tests, 0 failures`, covering the owned proof stack in [authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:199), [authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:226), [discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:30), and [phase15_par_authorization_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase15_par_authorization_e2e_test.exs:88). |
| 2 | Requirement traceability and verification artifacts are complete enough to close the PAR milestone without inference gaps. | ✓ VERIFIED | [16-VALIDATION.md](/Users/jon/projects/lockspire/.planning/phases/16-verification-and-release-runtime-hygiene/16-VALIDATION.md:41) maps `PAR-04` and `RELS-04` checks to concrete commands and owned artifacts. |
| 3 | The canonical PAR end-to-end proof remains `test/integration/phase15_par_authorization_e2e_test.exs`, and closure evidence explains that reuse explicitly. | ✓ VERIFIED | [16-VALIDATION.md](/Users/jon/projects/lockspire/.planning/phases/16-verification-and-release-runtime-hygiene/16-VALIDATION.md:75) explicitly preserves the Phase 15 integration test as the canonical `/par -> /authorize -> /token` proof. |
| 4 | The checked-in release workflow no longer depends on the Node-20-bound `googleapis/release-please-action` implementation that emitted the known deprecation warning. | ✓ VERIFIED | [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:42) invokes `./.github/actions/release-please`, and [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:86) refutes `googleapis/release-please-action`. |
| 5 | The repo-controlled Release Please implementation runs on a supported runtime and preserves the root `release_created` contract. | ✓ VERIFIED | [action.yml](/Users/jon/projects/lockspire/.github/actions/release-please/action.yml:121) is a composite action that sets up Node 24, and [runtime/index.js](/Users/jon/projects/lockspire/.github/actions/release-please/runtime/index.js:34) emits the release outputs consumed by the workflow. |
| 6 | Maintainer release guidance still matches the checked-in workflow after the runtime-hygiene change. | ✓ VERIFIED | [maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:41) requires the repo-controlled action path, and [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:21) pins the guide against the workflow and policy files. |
| 7 | The trusted preview release path still requires `mix ci` for contributor proof and `mix release.preflight` plus `mix hex.publish --yes` inside `hex-publish`. | ✓ VERIFIED | [maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:25) keeps `mix ci` as the contributor lane, while [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:114) and [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:119) keep publish-only commands inside the protected environment. |
| 8 | Release Please remains review-only, `workflow_dispatch` remains recovery-only, and the protected `hex-publish` lane still starts only after merge or explicit recovery of the exact intended revision. | ✓ VERIFIED | The prior gap is closed in the live workflow: [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:69) now validates `recovery_ref` inside the manual publish path, accepts only a 40-character commit SHA or an existing tag, and performs a detached checkout before any release commands run. GitHub Actions run `24898764939` rejected `main` before publish, and run `24898785416` accepted SHA `781d7189b1e9893a252cfca3e70153dc4a95ca79` before entering the protected publish gate. |
| 9 | Phase 16 now has a single verification artifact that covers both `PAR-04` and `RELS-04` from observed evidence. | ✓ VERIFIED | This report supersedes the earlier gap report and now includes both the local closure proof and the live GitHub recovery-run evidence recorded in `16-HUMAN-UAT.md`. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.planning/phases/16-verification-and-release-runtime-hygiene/16-VALIDATION.md` | Traceability map for `PAR-04` and `RELS-04` | ✓ VERIFIED | Substantive and still wired to the phase proof commands in [16-VALIDATION.md](/Users/jon/projects/lockspire/.planning/phases/16-verification-and-release-runtime-hygiene/16-VALIDATION.md:43). |
| `test/lockspire/protocol/authorization_request_test.exs` | Protocol proof for PAR success, expiry, wrong-client burn, and replay rejection | ✓ VERIFIED | Reused executable proof remained green in the focused suite. |
| `test/lockspire/web/authorize_controller_test.exs` | Browser proof for PAR-backed `/authorize` success and safe failures | ✓ VERIFIED | Reused executable proof remained green in the focused suite. |
| `test/integration/phase15_par_authorization_e2e_test.exs` | Canonical `/par -> /authorize -> /token` proof | ✓ VERIFIED | Reused executable proof remained green in the focused suite. |
| `test/lockspire/web/discovery_controller_test.exs` | Discovery-truth contract for the narrow PAR claim | ✓ VERIFIED | Reused executable proof remained green in the focused suite. |
| `.github/workflows/release.yml` | Warning-free release workflow that preserves the preview release contract | ✓ VERIFIED | [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:62) fetches full history and tags for recovery validation, then [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:78) through [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:85) reject non-SHA and non-tag refs before checkout. |
| `.github/actions/release-please/action.yml` | Repo-controlled Release Please invocation on a supported runtime | ✓ VERIFIED | Composite action remains substantive and wired from the workflow. |
| `.github/actions/release-please/runtime/package.json` | Locked runtime package definition | ✓ VERIFIED | Present and pinned. |
| `.github/actions/release-please/runtime/package-lock.json` | Locked dependency graph for the local runtime | ✓ VERIFIED | Present and aligned with the runtime package. |
| `.github/actions/release-please/runtime/index.js` | Local runtime preserving release outputs and policy inputs | ✓ VERIFIED | `node --check .github/actions/release-please/runtime/index.js` exited `0`. |
| `docs/maintainer-release.md` | Maintainer guidance aligned with the checked-in release lane | ✓ VERIFIED | [maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:49) and [maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:58) now match the immutable recovery-ref enforcement. |
| `test/lockspire/release_readiness_contract_test.exs` | Repo-truth assertions for workflow, docs, config, and release runtime | ✓ VERIFIED | [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:49) now asserts the enforcement strings added by commit `25153b7`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `16-VALIDATION.md` | PAR proof harnesses | requirement-to-command traceability | ✓ VERIFIED | PAR closure traces directly to the reused protocol, browser, discovery, and integration suites. |
| `test/integration/phase15_par_authorization_e2e_test.exs` | `/par -> /authorize -> /token` | canonical end-to-end proof | ✓ VERIFIED | The canonical Phase 15 harness still provides the PAR end-to-end milestone proof. |
| `.github/workflows/release.yml` | `.github/actions/release-please/action.yml` | repo-controlled Release Please invocation | ✓ VERIFIED | [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:42) uses the local action path directly. |
| `.github/actions/release-please/action.yml` | `.github/actions/release-please/runtime/index.js` | composite action runtime | ✓ VERIFIED | [action.yml](/Users/jon/projects/lockspire/.github/actions/release-please/action.yml:137) invokes the checked-in runtime under Node 24. |
| `.github/workflows/release.yml` | `docs/maintainer-release.md` | recovery-only and publish-lane contract wording | ✓ VERIFIED | Workflow and docs now agree that manual recovery is exact-SHA-or-existing-tag only and happens in the protected publish path. |
| `test/lockspire/release_readiness_contract_test.exs` | workflow/docs/config/manifest | repo-truth contract assertions | ✓ VERIFIED | The contract test now checks for the recovery validation shell logic, detached checkout, and disallows the deprecated direct action dependency. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `test/integration/phase15_par_authorization_e2e_test.exs` | `request_uri`, auth code, tokens | `/par` response -> `/authorize` -> `/token` | Yes | ✓ FLOWING |
| `.github/actions/release-please/runtime/index.js` | `release_created`, `paths_released`, root release metadata | `Manifest.createReleases()` / `Manifest.createPullRequests()` | Yes | ✓ FLOWING |
| `.github/workflows/release.yml` | `recovery_ref` | `workflow_dispatch` input -> shell validation -> detached checkout | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| PAR closure proof stays green across protocol, browser, discovery, and canonical integration coverage | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` | `30 tests, 0 failures` | ✓ PASS |
| Release contract suite pins the repo-controlled action/runtime and immutable recovery-ref enforcement | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` | `8 tests, 0 failures` | ✓ PASS |
| Repo docs still build after the runtime-hygiene and workflow changes | `mix docs.verify` | Docs generated successfully (`doc/index.html`, `doc/llms.txt`, `doc/lockspire.epub`) | ✓ PASS |
| Fast regression lane stays green after phase-16 changes | `MIX_ENV=test mix test.fast` | `103 tests, 0 failures (73 excluded)` | ✓ PASS |
| Checked-in Release Please runtime is syntactically valid JavaScript | `node --check .github/actions/release-please/runtime/index.js` | Exit code `0` | ✓ PASS |
| Live GitHub Actions recovery proof rejects mutable refs before publish and admits immutable refs to the protected lane | GitHub Actions `Release` workflow_dispatch runs `24898764939` and `24898785416` | Invalid `recovery_ref=main` failed in `Validate Recovery Ref`; valid SHA `781d7189b1e9893a252cfca3e70153dc4a95ca79` completed validation and advanced to `Publish to Hex` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PAR-04` | `16-01` | Maintainers have automated protocol, security, and integration coverage for PAR success, expiry, wrong-client usage, replay rejection, and discovery truth before the milestone can close. | ✓ SATISFIED | The focused PAR suite stayed green and the traceability file still maps each truth to owned evidence. |
| `RELS-04` | `16-02` | Maintainers can run the checked-in preview release path without the known deprecated GitHub Actions runtime warning while keeping release automation and maintainer docs aligned. | ✓ SATISFIED | The deprecated action dependency is gone, the repo-controlled runtime is on Node 24, docs/tests align with the workflow, and the prior recovery-ref enforcement gap is closed in [release.yml](/Users/jon/projects/lockspire/.github/workflows/release.yml:69). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `-` | `-` | No blocker anti-patterns detected in the owned Phase 16 verification and release-hygiene surface | ℹ️ Info | The current workflow/docs/tests no longer rely on unreachable recovery validation or unconstrained manual checkout. |

### Live GitHub Verification

### 1. Live Release Workflow Recovery Check

**Observed:** GitHub Actions run `24898764939` used `recovery_ref=main` and failed in `Validate Recovery Ref` before publish with the expected immutable-ref error. GitHub Actions run `24898785416` used SHA `781d7189b1e9893a252cfca3e70153dc4a95ca79`, completed recovery validation, and advanced to `Publish to Hex`, where it is waiting at the protected `hex-publish` environment gate. No deprecated Node 20 runtime warning appeared in the completed recovery-validation jobs.
**Why this is sufficient:** The remaining boundary is the protected environment approval itself; the milestone requirement was to prove immutable-ref enforcement and warning-free recovery-lane entry, not to perform an out-of-band publish from this phase artifact.

### Gaps Summary

No remaining code gaps were found.

The prior `RELS-04` gap is closed by commit `25153b7`: immutable recovery-ref enforcement now executes in the manual publish path itself, rejects branch and PR-style refs, and locks recovery runs to either a full commit SHA or an existing tag before any release command runs. That satisfies the previously missing wiring between the documented recovery contract and the actual workflow behavior.

No human-verification gaps remain for milestone close. The external publish environment itself still governs whether a maintainer chooses to approve or cancel a recovery publish attempt, but the required recovery-lane proof is now captured.

---

_Verified: 2026-04-24T16:01:16Z_
_Verifier: Codex (gsd-verifier)_
