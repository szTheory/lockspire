# Phase 67 Research: Release Candidate & Trusted Publish Prep

**Date:** 2026-05-07
**Phase:** 67
**Requirements:** REL-01, REL-02, REL-03

## Objective

Identify what Phase 67 must preserve and what it must change so Lockspire can cut one coherent release candidate and enter the trusted publish lane without widening the embedded-library support contract.

## Current Truth Surface

The repo is already aligned around a checked-in `1.0.0` story:

- `mix.exs` declares version `1.0.0`.
- `.release-please-manifest.json` declares `1.0.0`.
- `CHANGELOG.md` leads with `1.0.0` and preserves historical `0.x` entries.
- `README.md`, `SECURITY.md`, and `docs/maintainer-release.md` all defer public support truth to `docs/supported-surface.md`.
- `docs/supported-surface.md` describes the canonical embedded Phoenix support contract for the current release.
- `.github/workflows/release.yml` defines one protected `hex-publish` lane.
- `.github/actions/release-please/action.yml` keeps Release Please repo-controlled rather than calling a third-party action directly.
- `test/lockspire/release_readiness_contract_test.exs` already fences the checked-in release truth hierarchy and workflow shape.

This means Phase 67 is not about inventing a release posture. It is about turning the aligned repo posture into an executable, maintainer-safe release candidate workflow.

## Evidence Boundaries To Preserve

`docs/maintainer-release.md` already establishes the three-bucket evidence model:

1. Repo-owned proof: checked-in workflow, action, docs, and release-readiness contract tests.
2. GitHub settings proof: live `hex-publish` environment restrictions and secret placement.
3. Workflow-run proof: one successful protected publish run that executes `mix release.preflight` and `mix hex.publish --yes`.

Phase 67 must keep these buckets separate. It should strengthen repo-owned preparation and operator guidance, but it must not claim protected-environment proof that can only exist after an actual publish run.

## Existing Enforcement

The strongest current automated fence is `test/lockspire/release_readiness_contract_test.exs`. It already verifies:

- version agreement across `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md`
- repo-controlled Release Please wiring
- protected `hex-publish` workflow shape
- contributor-lane versus trusted-release-lane separation
- canonical support-contract hierarchy across README, security docs, and maintainer docs
- narrow release claims that stay inside the embedded Phoenix wedge

This test is the natural place for additional Phase 67 repo-owned assertions if release-candidate prep introduces new checked-in contracts.

## Likely Gaps Phase 67 Should Close

### 1. Release-candidate checklist truth may still live partly as prose

The repo has strong wording in `docs/maintainer-release.md`, but Phase 67 likely still needs a single explicit release-candidate checklist that makes it easy for maintainers to confirm:

- which files must agree before merge
- which commands belong in contributor proof versus trusted publish proof
- which steps are review-only versus authenticated publish-only
- what to record before crossing the protected environment boundary

### 2. Trusted publish preparation may be defined but not fully indexed

The workflow, repo-controlled action, manifest, changelog, and maintainer guide all participate in the release lane. Phase 67 should probably produce one narrow maintainer-facing index or audit path that ties them together so no hidden step lives only in maintainer memory.

### 3. Release-only cleanup could accidentally broaden claims

Any edits to changelog, README, release notes posture, package metadata, or maintainer docs can accidentally:

- create a second support matrix outside `docs/supported-surface.md`
- imply broader certification or hosted-auth posture
- turn Release Please PR output into release proof
- blur the line between repo-owned proof and protected-environment proof

Phase 67 should explicitly guard against this in both docs and tests.

## Recommended Plan Shape

The phase is best split by trust boundary rather than by file type.

### Slice A: Release-candidate artifact alignment

Focus on the checked-in artifact chain for REL-01:

- `mix.exs`
- `.release-please-manifest.json`
- `CHANGELOG.md`
- any package metadata exposed through `mix.exs`
- release workflow/config references that must agree with the checked-in version story

Goal: prove one coherent release-candidate story with no `rc` shadow versioning or metadata drift.

### Slice B: Trusted publish lane preparation and maintainer runbook

Focus on REL-02:

- `docs/maintainer-release.md`
- `.github/workflows/release.yml`
- `.github/actions/release-please/action.yml`
- any maintainer-facing scripts or Mix aliases involved in release preflight

Goal: make every non-secret step explicit, keep publish proof inside the protected environment boundary, and preserve recovery-only manual dispatch semantics.

### Slice C: Release-boundary drift fences

Focus on REL-03:

- `test/lockspire/release_readiness_contract_test.exs`
- possibly a focused docs/release contract test expansion if new checked-in guidance is added

Goal: fail fast if release prep broadens the supported surface, introduces shadow truth sources, or turns protected-release evidence into a checked-in claim.

## Verification Strategy

Phase 67 should default to repo-owned proof and avoid pretending to complete Phase 68 work early.

Recommended verification:

- `mix test test/lockspire/release_readiness_contract_test.exs`
- any targeted tests that verify package/install/release aliases if Phase 67 changes them
- direct inspection of `docs/maintainer-release.md`, `docs/supported-surface.md`, `README.md`, `SECURITY.md`, `.github/workflows/release.yml`, and `.github/actions/release-please/action.yml`

Recommended explicit non-claim:

- Do not mark actual publish success, Hex package visibility, or public install-from-Hex proof as complete in Phase 67. Those belong to Phase 68.

## Risks

### High risk

- Conflating checked-in `1.0.0` truth with authenticated publish proof.
- Broadening public support claims during release cleanup.
- Adding undocumented maintainer steps that live outside repo-owned guidance.

### Medium risk

- Treating Release Please PR output as more than review evidence.
- Letting changelog or release notes language imply unsupported product breadth.
- Adding verification steps that require protected credentials but presenting them as contributor- or pre-merge proof.

## Planning Implications

- Keep Phase 67 narrow and preparatory.
- Prefer strengthening the existing release-readiness contract test over introducing ad hoc manual verification.
- Separate "ready to publish" proof from "published and publicly verifiable" proof.
- If new release guidance is added, make `docs/supported-surface.md` remain canonical and keep subordinate docs subordinate.

## Suggested Canonical Inputs For Planner

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `.planning/phases/65-release-truth-support-contract-reconciliation/65-01-SUMMARY.md`
- `.planning/phases/65-release-truth-support-contract-reconciliation/65-02-SUMMARY.md`
- `.planning/phases/65-release-truth-support-contract-reconciliation/65-03-SUMMARY.md`
- `docs/maintainer-release.md`
- `docs/supported-surface.md`
- `README.md`
- `SECURITY.md`
- `.github/workflows/release.yml`
- `.github/actions/release-please/action.yml`
- `release-please-config.json`
- `.release-please-manifest.json`
- `mix.exs`
- `CHANGELOG.md`
- `test/lockspire/release_readiness_contract_test.exs`

## Research Conclusion

Phase 67 should behave like a release-prep hardening phase, not a publish-verification phase. The repo already contains the canonical version and support-contract story; the remaining work is to make the release-candidate path explicit, reviewable, and guarded against support-boundary drift.
