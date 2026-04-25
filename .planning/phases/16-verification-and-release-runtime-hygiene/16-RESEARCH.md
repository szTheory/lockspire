# Phase 16: Verification and Release Runtime Hygiene - Research

**Researched:** 2026-04-24
**Domain:** PAR milestone closure proof and preview-release runtime hygiene in an embedded Phoenix/Elixir authorization server
**Confidence:** HIGH

## User Constraints

- Phase 16 is limited to `PAR-04` and `RELS-04`: close the PAR wedge with explicit automated proof and traceability, and remove the known deprecated GitHub Actions release runtime warning without redesigning the release process.
- The embedded-library shape, host-owned authentication seam, and narrow preview posture remain binding. Phase 16 must not widen Lockspire into hosted auth, CIAM, or broader protocol support claims.
- Existing PAR proof should be reused first. New tests are justified only for a concrete `PAR-04` gap, not for optics.
- Existing release policy remains fixed: Release Please creates review-only PRs, trusted release proof starts only after merge in the protected `hex-publish` environment, and `workflow_dispatch` remains recovery-only.
- Missing `10/12/13-VALIDATION.md` artifacts remain deferred process debt unless Phase 16 execution proves they block v1.2 closure.
- As captured in `16-CONTEXT.md`, planning should assume that simply moving to a newer `googleapis/release-please-action` pin is insufficient because the published action metadata still targets Node 20 as of 2026-04-24.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-04 | Maintainers have automated protocol, security, and integration coverage for PAR success, expiry, wrong-client usage, replay rejection, and discovery truth before the milestone can close. | Reuse the Phase 15 proof stack as the canonical evidence surface, add only a targeted gap test if traceability reveals one, and record the closure proof explicitly in `16-VALIDATION.md` plus execution-produced verification artifacts. |
| RELS-04 | Maintainers can run the checked-in preview release path without the known deprecated GitHub Actions runtime warning while keeping release automation and maintainer docs aligned. | Replace the Node-20-bound Release Please action usage with a checked-in implementation that preserves the existing release contract, then update maintainer docs and repo-truth tests to pin the unchanged trust boundaries. |
</phase_requirements>

## Summary

Phase 16 is a closure phase, not a feature phase. The safest route is to treat the existing Phase 15 PAR tests as the proof surface to be traced and affirmed, then add only the smallest missing executable evidence needed to satisfy `PAR-04`. On the release side, the work is similarly narrow: remove the deprecated runtime warning from the checked-in release workflow while preserving the current review-only Release Please posture, protected Hex publish lane, and maintainer guidance already enforced by repo-truth tests.

The codebase already contains the core PAR proof harnesses Phase 16 needs: protocol coverage in `test/lockspire/protocol/authorization_request_test.exs`, browser-path coverage in `test/lockspire/web/authorize_controller_test.exs`, discovery truth coverage in `test/lockspire/web/discovery_controller_test.exs`, public-surface contract coverage in `test/lockspire/release_readiness_contract_test.exs`, and the canonical end-to-end proof in `test/integration/phase15_par_authorization_e2e_test.exs`. The planning problem is therefore traceability and closure, not breadth.

For release runtime hygiene, the checked-in workflow shows the warning source clearly: `.github/workflows/release.yml` still invokes `googleapis/release-please-action@16a9c90856f42705d54a6fda1823352bdc62cf38`. Given the Phase 16 context that the published action remains Node-20-based, the most coherent plan is to replace that action step with a repo-controlled invocation path that still reads `release-please-config.json` and `.release-please-manifest.json`, preserves the same branch/event semantics, and keeps publish authority entirely inside the existing protected `hex-publish` job.

**Primary recommendation:** create two plans. `16-01` should be a proof-and-traceability plan that reuses the Phase 15 PAR harnesses, fills only real gaps, and produces milestone-closure evidence. `16-02` should be a narrow release-workflow plan that removes the deprecated runtime dependency while keeping docs and repo-truth tests aligned with the unchanged release contract.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PAR closure traceability | Planning / Verification | Test harnesses | The behavior already exists; Phase 16 must prove sufficiency and map requirements to executable evidence. |
| Additional PAR regression coverage, if needed | Test / Contracts | Protocol or web layers | Any new test should target a specific uncovered truth rather than broaden the runtime surface. |
| Release workflow runtime hygiene | CI / Workflow config | Docs / contract tests | The warning comes from workflow implementation, and repo truth must move with that implementation. |
| Maintainer release contract alignment | Docs / contract tests | CI / Workflow config | `docs/maintainer-release.md` and `test/lockspire/release_readiness_contract_test.exs` define the durable release posture in-repo. |

## Existing Evidence Surface

### PAR Proof Assets To Reuse

- `test/lockspire/protocol/authorization_request_test.exs`
  Already covers PAR success, expiry rejection, replay rejection, wrong-client burn, and mixed-input rejection.
- `test/lockspire/web/authorize_controller_test.exs`
  Already covers browser-surface PAR success and rejection behavior.
- `test/integration/phase15_par_authorization_e2e_test.exs`
  Already provides the canonical `/par -> /authorize -> /token` proof.
- `test/lockspire/web/discovery_controller_test.exs`
  Already pins truthful publication of `pushed_authorization_request_endpoint` and omission of broader request-object metadata.
- `test/lockspire/release_readiness_contract_test.exs`
  Already asserts the narrow PAR public claim and the release-lane invariants that Phase 16 must preserve.

### Release Contract Assets To Reuse

- `.github/workflows/release.yml`
  Defines the release-please job, protected publish job, and recovery-only manual dispatch posture.
- `docs/maintainer-release.md`
  Defines the maintainer contract, evidence buckets, and protected publish lane semantics.
- `release-please-config.json` and `.release-please-manifest.json`
  Define the checked-in release policy that any replacement implementation must continue to honor.

## Architecture Patterns

### Pattern 1: Traceability-First Closure

Phase 15 already proved the PAR slice in code and tests. Phase 16 should not duplicate those tests under a new phase name. Instead:

- map each `PAR-04` truth to an existing command, file, and observed behavior;
- run the existing focused commands as closure checks;
- add a new test only if one requirement truth is genuinely unpinned today;
- produce Phase 16 validation/verification artifacts that explain why the reused proof is sufficient.

This mirrors the evidence-heavy verification style already used in `15-VERIFICATION.md`.

### Pattern 2: Repo-Truth Moves With Workflow Truth

Lockspire already treats release posture as a contract between:

- `.github/workflows/release.yml`
- `docs/maintainer-release.md`
- `test/lockspire/release_readiness_contract_test.exs`

Any runtime-warning fix must update all three surfaces together if the checked-in implementation changes in a durable way. The tests should keep pinning invariant behavior, not incidental wording.

### Pattern 3: Minimal Release-Lane Change

The warning belongs to the `release-please` implementation detail, not to the publish job. Keep these stable:

- `push` on `main` remains the normal trigger;
- `workflow_dispatch` remains recovery-only;
- Release Please remains review-only;
- `publish` still depends on `release_created == 'true'` or recovery dispatch;
- trusted commands remain `mix release.preflight` and `mix hex.publish --yes` inside `hex-publish`.

The implementation change should therefore stay inside the release-please job and any supporting checked-in files it needs.

## Recommended Project Structure

```text
.planning/phases/16-verification-and-release-runtime-hygiene/
├── 16-01-PLAN.md
├── 16-02-PLAN.md
├── 16-VALIDATION.md
└── 16-VERIFICATION.md      # produced/updated during execution for closure proof

.github/workflows/
└── release.yml

docs/
└── maintainer-release.md

test/lockspire/
└── release_readiness_contract_test.exs
```

## Concrete File Targets

- `.planning/phases/16-verification-and-release-runtime-hygiene/16-01-PLAN.md`
  Plan the PAR closure proof package: focused spot-checks, traceability artifacts, and only gap-driven test additions.
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-02-PLAN.md`
  Plan the release-runtime hygiene change with narrow workflow/doc/test scope.
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-VALIDATION.md`
  Define the focused verification commands and closure-suite cadence for both plans.
- `.github/workflows/release.yml`
  Replace the warning-producing Release Please action usage while keeping the publish lane unchanged.
- `docs/maintainer-release.md`
  Update only the implementation-facing guidance that actually changed.
- `test/lockspire/release_readiness_contract_test.exs`
  Extend repo-truth assertions to pin the new warning-free implementation and the unchanged release contract.
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-VERIFICATION.md`
  During execution, record milestone closure evidence tying `PAR-04` and `RELS-04` to observed proof.

## Anti-Patterns To Avoid

- Do not create a second, duplicated PAR end-to-end suite just to make Phase 16 look substantial.
- Do not broaden the phase into release-policy redesign, extra branches, or maintainer-process experimentation.
- Do not relax the release contract tests into vague wording that would allow posture drift.
- Do not pull the publish commands or `HEX_API_KEY` boundary out of the protected `hex-publish` environment.
- Do not treat missing historical validation docs as implicit scope creep unless Phase 16 execution proves they block milestone closure.

## Validation Recommendations

- `16-01` should use focused commands built from the existing PAR proof harnesses, then a wave/closure command that reruns the canonical integration and truth-surface tests together.
- `16-02` should use focused repo-truth assertions for workflow/docs/config changes and, if execution can observe it, one trusted run or equivalent evidence showing the deprecated runtime warning is gone from the checked-in release lane.
- `16-VALIDATION.md` should explicitly mark reused proof artifacts as existing harnesses rather than pretending they are new work.

## Key Insight

Phase 16 is only successful if it resists the instinct to "prove more" by duplicating proof and instead closes the milestone by showing that the current PAR wedge is already sufficiently proven. The release-runtime work follows the same rule: remove the warning by swapping the implementation detail that causes it, while leaving the trusted release boundary and public preview posture exactly where the repo already says they are.
