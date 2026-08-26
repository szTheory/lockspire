---
phase: 126-trusted-release-path
verified: 2026-08-26T16:40:30Z
status: passed
score: "4/4 must-haves verified"
behavior_unverified: 0
---

# Phase 126 Verification: Trusted Release Path

**Verdict:** `passed` — the protected publication path is authorized by CI for
the exact post-merge `main` commit, validates recovery inputs fail-closed, and
retains publish/install and supply-chain proof. This is a canonicalization of
the existing v1.36 evidence; it does not record new test execution.

## Evidence Sources

- `.planning/milestones/v1.36-VERIFICATION.md` — independent milestone review,
  which recorded all six assigned requirements as verified.
- `126-01-SUMMARY.md` through `126-05-SUMMARY.md` — plan-level implementation
  and focused verification evidence.
- Historical Phase 126 aggregate evidence below — release-path command results,
  commits, and follow-up retained from the retired aggregate summary.

## Roadmap Success Criteria

### 1. Release-PR merge waits for matching post-merge CI

**Status:** VERIFIED

`RELEASE-01` is satisfied by the two-stage Release Please flow: merge is
separate from publication dispatch, and only the merged commit's successful
canonical `CI` push run can authorize publication. The validator checks the
canonical workflow identity, exact SHA, and source run metadata rather than
using a pre-merge run. Plan 126-01 recorded the
`release_ci_evidence_contract_test.exs` pass; the milestone review independently
confirmed the exact post-merge canonical-CI path.

### 2. Manual recovery validates immutable ancestry and CI metadata safely

**Status:** VERIFIED

`RELEASE-02` is satisfied by recovery dispatch inputs passed only through
environment variables, with validation of a lowercase 40-hex SHA, current
`origin/main`, main ancestry, matching successful CI evidence, and quoted
expansions. The same exact-SHA contract from Plan 126-01 and the milestone
review establish that recovery cannot shell-inject inputs or publish an
unrelated ref.

### 3. GitHub release, Hex publish, and install truth are one audited flow

**Status:** VERIFIED

`RELEASE-03` is satisfied by detached publication from the validated exact SHA,
GitHub release target validation/creation at that SHA, Hex publication, and an
unprivileged post-publish install-truth log artifact. Plan 126-02 recorded
`publish_verification_test.exs` and ShellCheck passing; the milestone review
confirmed the complete exact-ref publish and install-truth sequence.

### 4. Release dependencies and CI checks fail safely

**Status:** VERIFIED

`SUPPLY-01`, `SUPPLY-02`, and `CI-01` are satisfied by the checked-in audited
Release Please runtime and nested Dependabot coverage; fail-closed dependency
review; immutable action and PostgreSQL references; bounded workflow jobs;
checksum-verified Actionlint/ShellCheck; and non-mutating lock verification.
Plans 126-03 through 126-05 recorded the audit, supply-chain, lint, and static
contract proof. The milestone review independently confirmed these gates.

## Requirement Coverage

| Requirement | Status | Existing evidence |
| --- | --- | --- |
| RELEASE-01 | VERIFIED | Exact post-merge canonical-CI identity and SHA contract (Plan 126-01; milestone matrix). |
| RELEASE-02 | VERIFIED | Typed environment inputs; 40-hex SHA, ancestry, current-head, and matching-CI validation (Plan 126-01; milestone matrix). |
| RELEASE-03 | VERIFIED | Detached validated SHA, GitHub target validation, Hex publish, and unprivileged install truth (Plan 126-02; milestone matrix). |
| SUPPLY-01 | VERIFIED | Audited checked-in Release Please runtime, lock verification, and Dependabot coverage (Plan 126-03; milestone matrix). |
| SUPPLY-02 | VERIFIED | Fail-closed dependency review, immutable workflow inputs, and job timeouts (Plan 126-04; milestone matrix). |
| CI-01 | VERIFIED | Checksum-verified Actionlint/ShellCheck plus non-mutating lock checks (Plan 126-05; milestone matrix). |

## Historical Focused Proof

The following focused command completed successfully on 2026-08-26; it is
recorded historical evidence, not a command rerun by this report:

```text
55 tests, 0 failures
bash scripts/ci/lint_workflows.sh
npm audit --prefix .github/actions/release-please/runtime --omit=dev --audit-level=moderate
mix deps.get --check-locked
git diff --exit-code -- mix.lock examples/adoption_demo/mix.lock .github/actions/release-please/runtime/package-lock.json
```

The prior aggregate verification also recorded zero warning-or-higher workflow
lint findings, zero production runtime npm audit vulnerabilities, and passing
lockfile verification.

## Delivered

- Split Release Please merge from publication dispatch so the merged commit's
  own successful `CI` push run is required.
- Made dispatch validation fail closed on a lowercase full SHA, current
  `origin/main`, main ancestry, and matching CI metadata.
- Published from the detached validated SHA with exact GitHub release target,
  Hex publication, and unprivileged install-truth artifact.
- Updated the checked-in Release Please runtime to `@actions/core` 3.0.1 and
  `release-please` 17.11.2 with a zero-vulnerability production audit and
  nested Dependabot coverage.
- Pinned workflow actions/services, bounded jobs, made dependency review fail
  closed, and added checksum-verified workflow/shell lint and lock checks.

## Historical Commits

- `8792498` — release runtime RED contract
- `05fcc4f` — audited runtime pins and Dependabot
- `9a7e000` — ignore local npm runtime installs
- `15455bb` — trusted release flow, workflow supply chain, and CI lint/lock gates

## Follow-up

The historical `mix deps.get --check-locked` output reported advisories in
Bandit, Phoenix LiveView, and Postgrex. They predated this release-path change,
were outside the approved Phase 126 dependency scope, and remain actionable
dependency-upgrade work.
