# Phase 16: Verification and Release Runtime Hygiene - Research

**Researched:** 2026-04-24
**Domain:** PAR closure traceability and GitHub Actions release-runtime hygiene
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Scope Boundary
- **D-01:** Phase 16 closes only `PAR-04` and `RELS-04`.
- **D-02:** Missing `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` remain separate planning/process debt and are not part of Phase 16 scope unless a concrete closure blocker is discovered during execution.
- **D-03:** If Nyquist completeness is still desired after v1.2, capture it as a discrete follow-up item rather than blending it into PAR milestone closure.

### PAR Closure Proof Style
- **D-04:** Reuse the existing PAR proof stack instead of creating a new Phase 16-specific test pyramid.
- **D-05:** Phase 16 proof should be traceability-first: `16-VALIDATION.md` and `16-VERIFICATION.md` map requirements to existing commands, files, and observed behavior.
- **D-06:** New tests are allowed only for a demonstrable `PAR-04` gap uncovered by traceability work. Do not duplicate already-proven protocol, web, integration, or discovery/truth-surface coverage for optics.
- **D-07:** Treat `test/integration/phase15_par_authorization_e2e_test.exs` as the canonical end-to-end PAR proof for milestone closure rather than cloning or rebranding it.

### Release Runtime Hygiene
- **D-08:** Preserve the current release policy and trust boundaries: Release Please remains the review-only release-PR engine, and Hex publishing remains a protected `hex-publish` environment action after merge.
- **D-09:** Make the smallest implementation change that removes the deprecated runtime warning while preserving current maintainer behavior and evidence boundaries.
- **D-10:** As of 2026-04-24, a pin-only upgrade of `googleapis/release-please-action` is blocked because the latest published action still declares `runs: using: node20`; plan Phase 16 around replacing the action implementation, not around changing the release policy.
- **D-11:** Do not broaden Phase 16 into release-process redesign, extra branches, or policy changes around trusted publish proof.

### Release Docs And Contract Strictness
- **D-12:** Update maintainer docs and repo-truth tests only where the checked-in release contract actually changes.
- **D-13:** Keep release contract checks focused on durable behavioral invariants: review-only Release Please posture, recovery-only `workflow_dispatch`, protected `hex-publish` environment use, `mix ci` for contributors, and `mix release.preflight` plus `mix hex.publish --yes` inside the trusted lane.
- **D-14:** Avoid over-specifying incidental action internals or brittle literal wording when that wording is not itself part of the maintainer or support contract.
- **D-15:** Do not change README, SECURITY, or supported-surface posture unless the public release claim itself changes. Runtime hygiene must not imply broader product maturity.

### Claude's Discretion
- Downstream agents should prefer research-backed, one-shot recommendations that are coherent across planning artifacts and minimize user interruption.
- Only escalate a decision back to the user when it materially changes Lockspire's trust boundaries, supported surface, or milestone scope.

### Deferred Ideas (OUT OF SCOPE)
- Revisit missing `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` as separate planning debt after v1.2 if full Nyquist completeness remains a project goal.
- Any broader release-lane refactor beyond removing the runtime warning belongs in a separate phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-04 | Maintainers have automated protocol, security, and integration coverage for PAR success, expiry, wrong-client usage, replay rejection, and discovery truth before the milestone can close. [VERIFIED: repo file] | Reuse Phase 15 protocol, web, integration, discovery, and release-contract tests; Phase 16 should add traceability artifacts, not duplicate suites, unless a real evidence gap appears. [VERIFIED: repo file] |
| RELS-04 | Maintainers can run the checked-in preview release path without the known deprecated GitHub Actions runtime warning while keeping release automation and maintainer docs aligned. [VERIFIED: repo file] | Replace the Node 20-bound `googleapis/release-please-action` wrapper with pinned Release Please CLI calls while preserving the current review PR, protected publish, and recovery-only manual dispatch policy. [VERIFIED: repo file] [CITED: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/] [CITED: https://github.com/googleapis/release-please-action] |
</phase_requirements>

## Summary

Phase 16 should close `PAR-04` primarily by documenting why the existing proof is already sufficient, not by creating Phase 16-branded duplicate tests. The repo already has focused PAR protocol coverage in `test/lockspire/protocol/authorization_request_test.exs`, browser-surface coverage in `test/lockspire/web/authorize_controller_test.exs`, canonical end-to-end proof in `test/integration/phase15_par_authorization_e2e_test.exs`, and truth-surface coverage in `test/lockspire/web/discovery_controller_test.exs` plus `test/lockspire/release_readiness_contract_test.exs`. Phase 15’s `VALIDATION.md` and `VERIFICATION.md` establish the house style: task-mapped executable commands in validation, then truth/evidence tables in verification. [VERIFIED: repo file]

The release-runtime change should stay narrow. The checked-in workflow still uses `googleapis/release-please-action@16a9c90856f42705d54a6fda1823352bdc62cf38` (`v4.4.0`), and upstream action metadata for `v4.4.0` still says `runs: using: node20`. GitHub’s current deprecation notice says Node 20 deprecation is underway and runners begin using Node 24 by default on June 2, 2026. That makes a SHA bump insufficient for this phase. The smallest repo-consistent fix is to keep Release Please semantics but replace the JavaScript action wrapper with pinned CLI invocations and explicit output plumbing for the downstream publish gate. [VERIFIED: repo file] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml] [CITED: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/] [VERIFIED: npm registry]

**Primary recommendation:** Plan `16-01` as artifact-first traceability over existing PAR tests, and plan `16-02` as a minimal workflow swap from `release-please-action` to pinned `release-please` CLI commands with explicit replacement of the current `release_created` job output. [VERIFIED: repo file] [VERIFIED: npm registry]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PAR success and negative-path proof | API / Backend [VERIFIED: repo file] | Frontend Server (Phoenix controllers) [VERIFIED: repo file] | The core secure behavior is enforced in protocol/storage code, while `/authorize` and discovery tests prove the HTTP surface reuses that behavior correctly. [VERIFIED: repo file] |
| Milestone closure traceability | Repo Docs / Planning [VERIFIED: repo file] | API / Backend [VERIFIED: repo file] | `16-VALIDATION.md` and `16-VERIFICATION.md` should point to already-green commands and codepaths instead of adding new runtime behavior. [VERIFIED: repo file] |
| Release PR generation | GitHub Actions / CI [VERIFIED: repo file] | Repo Config [VERIFIED: repo file] | The workflow owns invocation, while `release-please-config.json` and `.release-please-manifest.json` remain the durable checked-in policy inputs. [VERIFIED: repo file] |
| Trusted Hex publish after merge | GitHub Actions / CI [VERIFIED: repo file] | GitHub protected environment [VERIFIED: repo file] | The publish lane is intentionally separated from contributor proof and only runs inside the `hex-publish` environment after merge or recovery dispatch. [VERIFIED: repo file] |
| Release posture truth | Repo Docs / Tests [VERIFIED: repo file] | GitHub Actions / CI [VERIFIED: repo file] | `docs/maintainer-release.md` and `test/lockspire/release_readiness_contract_test.exs` are the durable repo-truth fence around workflow behavior. [VERIFIED: repo file] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `Mix 1.19.5` on `OTP 28` [VERIFIED: local command] | Runs the existing verification aliases and ExUnit suites. [VERIFIED: repo file] | Phase 16 should stay on the repo’s current `mix`-first proof style instead of introducing new test tooling. [VERIFIED: repo file] |
| ExUnit via repo aliases | Built into the current app; Phase 15 uses `MIX_ENV=test mix test ...` and `mix test.fast` [VERIFIED: repo file] | Executes PAR protocol, web, integration, and contract coverage. [VERIFIED: repo file] | Lockspire already standardizes on focused ExUnit entrypoints plus explicit phase artifacts. [VERIFIED: repo file] |
| `release-please` CLI | `17.6.0`, published `2026-04-13T21:15:22.890Z` [VERIFIED: npm registry] | Replaces the Node 20-bound action wrapper while preserving Release Please behavior. [VERIFIED: npm registry] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | It is current, supports manifest config/manifest files, and exposes separate PR/release commands the workflow can call explicitly. [VERIFIED: npm registry] [VERIFIED: local command] |
| GitHub Actions workflow | `release.yml` uses protected `hex-publish` and recovery-only `workflow_dispatch` today. [VERIFIED: repo file] | Orchestrates review PR generation and trusted post-merge publish. [VERIFIED: repo file] | The workflow is already the canonical release lane and should be changed minimally. [VERIFIED: repo file] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `gh` CLI | `2.89.0`, dated `2026-03-26` in local install output [VERIFIED: local command] | Useful for explicit workflow output plumbing or release existence checks if the new workflow needs a boolean gate. [VERIFIED: local command] | Use only to replace the current `release_created` contract cleanly; do not broaden the release policy. [VERIFIED: repo file] |
| `actions/checkout` | `v6.0.2` pin in workflow [VERIFIED: repo file] | Needed if the CLI-based release job checks out the repo before running Release Please or publish steps. [VERIFIED: repo file] | Keep pinned and unchanged unless the CLI swap requires it in the release job. [VERIFIED: repo file] |
| `erlef/setup-beam` | `v1.24.0` pin in workflow [VERIFIED: repo file] | Prepares the trusted publish lane for `mix release.preflight` and `mix hex.publish --yes`. [VERIFIED: repo file] | Keep unchanged; this phase is not a Beam toolchain migration. [VERIFIED: repo file] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing existing PAR tests [VERIFIED: repo file] | New Phase 16-branded PAR suites [VERIFIED: repo file] | Duplicates already-proven behavior, increases maintenance noise, and violates the phase context unless a real gap is found. [VERIFIED: repo file] |
| Pinned Release Please CLI in workflow [VERIFIED: npm registry] | `googleapis/release-please-action@v4.4.0` [CITED: https://github.com/googleapis/release-please-action/releases/tag/v4.4.0] | The published action still runs on Node 20, so it does not remove the warning this phase must close. [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml] |
| Narrow doc/test alignment updates [VERIFIED: repo file] | Broad maintainer-process redesign [VERIFIED: repo file] | A redesign would exceed `RELS-04` and violate the locked phase boundary. [VERIFIED: repo file] |

**Installation:**
```bash
# No repo dependency is required.
# Use a pinned workflow invocation instead:
npx --yes release-please@17.6.0 release-pr --repo-url "$GITHUB_REPOSITORY" --target-branch "$GITHUB_REF_NAME" --config-file release-please-config.json --manifest-file .release-please-manifest.json
```

**Version verification:** `release-please` latest npm version is `17.6.0`, published `2026-04-13T21:15:22.890Z`. [VERIFIED: npm registry] `googleapis/release-please-action` latest GitHub release is `v4.4.0`, published `2025-10-23T18:05:33Z`, and its action metadata still declares `runs: using: node20`. [CITED: https://github.com/googleapis/release-please-action/releases/tag/v4.4.0] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml]

## Architecture Patterns

### System Architecture Diagram

```text
Merged commits on main
  -> Release workflow starts [VERIFIED: repo file]
    -> review-only Release Please step updates/opens release PR when needed [VERIFIED: repo file] [VERIFIED: local command]
    -> merged release PR push triggers release/tag creation path [CITED: https://github.com/googleapis/release-please] [VERIFIED: local command]
    -> explicit workflow output computes "publishable release created?" [ASSUMED] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
    -> publish job crosses protected hex-publish environment [VERIFIED: repo file]
    -> mix release.preflight [VERIFIED: repo file]
    -> mix hex.publish --yes [VERIFIED: repo file]

PAR milestone closure
  -> Phase 16 validation artifact maps commands to requirements [VERIFIED: repo file]
    -> protocol test proves success, expiry, replay, wrong-client burn [VERIFIED: repo file]
    -> web test proves browser-surface success/failure handling [VERIFIED: repo file]
    -> integration test proves /par -> /authorize -> /token [VERIFIED: repo file]
    -> discovery + release contract tests prove truthful support surface [VERIFIED: repo file]
    -> Phase 16 verification artifact records evidence and requirement closure [VERIFIED: repo file]
```

### Recommended Project Structure

```text
.planning/phases/16-verification-and-release-runtime-hygiene/
├── 16-VALIDATION.md      # Task/command traceability over existing proof [VERIFIED: repo file]
├── 16-VERIFICATION.md    # Closure evidence and requirement tables [VERIFIED: repo file]
└── 16-RESEARCH.md        # This research artifact [VERIFIED: repo file]

.github/workflows/
└── release.yml           # Narrow runtime-hygiene swap only [VERIFIED: repo file]

docs/
└── maintainer-release.md # Update only if maintainer-visible workflow contract changes [VERIFIED: repo file]

test/lockspire/
└── release_readiness_contract_test.exs # Update durable contract checks, not incidental internals [VERIFIED: repo file]
```

### Pattern 1: Traceability-First Phase Closure
**What:** Write `16-VALIDATION.md` as a command map over existing PAR harnesses, then write `16-VERIFICATION.md` as an evidence rollup tied to requirement IDs and observable truths. [VERIFIED: repo file]
**When to use:** Use this when implementation already shipped in the immediately prior phase and the current phase closes verification or ledger gaps. [VERIFIED: repo file]
**Example:**
```md
| Requirement | Existing command | Existing proof file | Behavior covered |
|-------------|------------------|---------------------|------------------|
| PAR-04 | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs` | existing | success, expiry, wrong-client, replay, discovery truth |
```
Source: [15-VALIDATION.md](/Users/jon/projects/lockspire/.planning/phases/15-authorization-consumption-and-truthful-surface/15-VALIDATION.md:1) [VERIFIED: repo file]

### Pattern 2: Wrapper Replacement Without Policy Change
**What:** Replace the deprecated JavaScript action wrapper but keep the same checked-in config, manifest, maintainer contract, and protected publish boundary. [VERIFIED: repo file] [VERIFIED: npm registry]
**When to use:** Use this when upstream runtime support lags GitHub runner policy but the underlying release engine remains acceptable. [CITED: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/] [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml]
**Example:**
```yaml
- name: Run Release Please PR update
  run: >
    npx --yes release-please@17.6.0 release-pr
    --repo-url "${{ github.repository }}"
    --target-branch "${{ github.ref_name }}"
    --config-file release-please-config.json
    --manifest-file .release-please-manifest.json
```
Source: [release-please CLI help] [VERIFIED: local command]

### Anti-Patterns to Avoid
- **Duplicate closure suites:** Do not add new PAR tests just to give Phase 16 its own filenames. The repo already has direct proof for every `PAR-04` behavior named in the requirement. [VERIFIED: repo file]
- **Action-pin theater:** Do not replace one `release-please-action` SHA with another and call `RELS-04` closed while upstream still runs on Node 20. [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml]
- **Brittle contract tests:** Do not pin docs/tests to incidental implementation details like exact wrapper names if the maintainer-visible contract stays the same. [VERIFIED: repo file]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PAR closure evidence [VERIFIED: repo file] | A second PAR test pyramid [VERIFIED: repo file] | Existing Phase 15 protocol/web/integration/discovery/contract tests plus Phase 16 traceability artifacts [VERIFIED: repo file] | The required behaviors are already covered; closure work is evidence organization, not behavior reinvention. [VERIFIED: repo file] |
| Release PR automation [VERIFIED: repo file] | Custom version/changelog/tag scripting [VERIFIED: repo file] | `release-please` CLI with existing checked-in config and manifest [VERIFIED: npm registry] [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md] | Lockspire already committed to Release Please policy; hand-rolled release logic would expand risk and review scope. [VERIFIED: repo file] |
| Publish gate signaling [VERIFIED: repo file] | Implicit assumptions that the old `steps.release.outputs.release_created` output will still exist [VERIFIED: repo file] | An explicit workflow step output based on the new CLI path [ASSUMED] [VERIFIED: local command] | The current publish job depends on that boolean, so the plan must replace it deliberately. [VERIFIED: repo file] |

**Key insight:** Phase 16 succeeds by reusing Lockspire’s existing durable proof surfaces and swapping only the deprecated release wrapper, not by broadening either the test stack or the release process. [VERIFIED: repo file]

## Common Pitfalls

### Pitfall 1: Treating verification artifacts as proof creation instead of proof indexing
**What goes wrong:** A planner adds new phase-specific tests even though the repo already proves the behavior. [VERIFIED: repo file]
**Why it happens:** `PAR-04` sounds like new coverage work unless the existing Phase 15 evidence is read together. [VERIFIED: repo file]
**How to avoid:** Start `16-01` by mapping each `PAR-04` clause to an existing command, file, and assertion before proposing any new test file. [VERIFIED: repo file]
**Warning signs:** New tests restate success/replay/expiry/discovery scenarios already covered in Phase 15 files. [VERIFIED: repo file]

### Pitfall 2: Fixing the runtime warning but breaking the publish trigger
**What goes wrong:** The workflow swaps to CLI commands but forgets that `publish` currently depends on `needs.release-please.outputs.release_created`. [VERIFIED: repo file]
**Why it happens:** The old action wrapper hid both behavior and outputs behind one `uses:` line. [VERIFIED: repo file]
**How to avoid:** Make replacement of the output contract an explicit subtask in `16-02`, not an implementation detail left to discovery. [VERIFIED: repo file] [VERIFIED: local command]
**Warning signs:** `release.yml` no longer defines a job output equivalent, or `publish` becomes unconditional on normal pushes. [VERIFIED: repo file]

### Pitfall 3: Expanding repo-truth checks to wrapper-specific internals
**What goes wrong:** Tests and docs start asserting literal `googleapis/release-please-action` usage, forcing unnecessary future churn. [VERIFIED: repo file]
**Why it happens:** Contract tests often drift from behavioral invariants to implementation details. [VERIFIED: repo file]
**How to avoid:** Keep tests asserting review-only PR posture, recovery-only dispatch, protected `hex-publish`, `mix ci`, `mix release.preflight`, and `mix hex.publish --yes`. [VERIFIED: repo file]
**Warning signs:** `release_readiness_contract_test.exs` begins matching specific wrapper names rather than policy behavior. [VERIFIED: repo file]

## Code Examples

Verified patterns from official sources and current repo truth:

### Existing Phase 15 closure pattern
```md
## Per-Task Verification Map
| Task ID | Requirement | Automated Command |
|---------|-------------|-------------------|
| 15-03-01 | PAR-02 | `MIX_ENV=test mix test test/lockspire/web/authorize_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` |
| 15-03-02 | PAR-03 | `MIX_ENV=test mix test test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs` |
```
Source: [15-VALIDATION.md](/Users/jon/projects/lockspire/.planning/phases/15-authorization-consumption-and-truthful-surface/15-VALIDATION.md:1) [VERIFIED: repo file]

### Release Please CLI PR invocation
```bash
npx --yes release-please@17.6.0 release-pr \
  --repo-url "$GITHUB_REPOSITORY" \
  --target-branch "$GITHUB_REF_NAME" \
  --config-file release-please-config.json \
  --manifest-file .release-please-manifest.json
```
Source: `release-please release-pr --help` [VERIFIED: local command]

### Release Please CLI release invocation
```bash
npx --yes release-please@17.6.0 github-release \
  --repo-url "$GITHUB_REPOSITORY" \
  --target-branch "$GITHUB_REF_NAME" \
  --config-file release-please-config.json \
  --manifest-file .release-please-manifest.json
```
Source: `release-please github-release --help` [VERIFIED: local command]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Wrapper-style GitHub Action on Node 20 [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml] | Pinned CLI invocation on a current `release-please` package [VERIFIED: npm registry] | GitHub announced Node 20 deprecation on `2025-09-19`, with Node 24 default beginning `2026-06-02`. [CITED: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/] | Action SHA refresh alone is not enough for `RELS-04`; the wrapper itself is the problem. [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml] |
| Fresh tests for every closure phase [VERIFIED: repo file] | Reuse focused proof and write traceability artifacts over it [VERIFIED: repo file] | Lockspire’s Phase 15 artifacts and current Phase 16 context both encode this pattern on `2026-04-24`. [VERIFIED: repo file] | Smaller review surface, less duplicate maintenance, and clearer requirement closure. [VERIFIED: repo file] |

**Deprecated/outdated:**
- `googleapis/release-please-action` as the Phase 16 fix path: outdated for this repo’s goal because the latest published action still runs on Node 20. [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml]
- `manifest-pr` / `manifest-release` command names as the preferred CLI spelling: current CLI marks them deprecated in favor of `release-pr` / `github-release`. [VERIFIED: local command]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest replacement for `steps.release.outputs.release_created` will likely be a workflow-computed boolean derived from the CLI release path rather than a built-in Release Please CLI output. [ASSUMED] | Architecture Patterns / Don’t Hand-Roll | Medium — if the CLI exposes a simpler stable machine-readable output during implementation, the workflow can be simpler than planned. |

## Open Questions

1. **What is the simplest reliable replacement for the current `release_created` output?**
   - What we know: the old action exposes `release_created`, while the CLI surface is split into `release-pr` and `github-release`. [VERIFIED: repo file] [VERIFIED: local command]
   - What's unclear: whether implementation should derive the boolean from CLI behavior alone or pair the CLI with a small `gh`/API check. [VERIFIED: local command]
   - Recommendation: keep this inside `16-02` implementation discovery, but make “replace output contract explicitly” a planned task rather than hidden work. [VERIFIED: repo file]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `node` | Release Please CLI invocation [VERIFIED: npm registry] | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | — |
| `npm` | Pinned `npx --yes release-please@17.6.0 ...` [VERIFIED: npm registry] | ✓ [VERIFIED: local command] | `11.1.0` [VERIFIED: local command] | — |
| `mix` | Phase validation commands and trusted publish lane [VERIFIED: repo file] | ✓ [VERIFIED: local command] | `Mix 1.19.5` [VERIFIED: local command] | — |
| `gh` | Optional workflow output plumbing / local release inspection [VERIFIED: local command] | ✓ [VERIFIED: local command] | `2.89.0` [VERIFIED: local command] | GitHub REST via `curl` if needed, but `gh` is already present. [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on `Mix 1.19.5` with repo aliases and Ecto SQL Sandbox-backed tests. [VERIFIED: repo file] [VERIFIED: local command] |
| Config file | `test/test_helper.exs`, `config/test.exs`. [VERIFIED: repo file] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: repo file] |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs`. [VERIFIED: repo file] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAR-04 | PAR success, expiry, wrong-client usage, replay rejection, and discovery truth are all already covered. [VERIFIED: repo file] | protocol + web + integration + contract [VERIFIED: repo file] | `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo file] | ✅ existing [VERIFIED: repo file] |
| RELS-04 | Release workflow, maintainer docs, and release contract test stay aligned after the wrapper swap. [VERIFIED: repo file] | contract + workflow review [VERIFIED: repo file] | `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` [VERIFIED: repo file] | ✅ existing [VERIFIED: repo file] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs` for workflow/doc changes, or the focused PAR command above for verification artifact edits. [VERIFIED: repo file]
- **Per wave merge:** `MIX_ENV=test mix test.fast && MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs`. [VERIFIED: repo file]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: repo file]

### Wave 0 Gaps
- None — existing test infrastructure already covers both requirements; Phase 16 mainly needs artifact wiring and narrow workflow/doc/test updates. [VERIFIED: repo file]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: repo file] | Host-owned auth remains out of scope for this phase. [VERIFIED: repo file] |
| V3 Session Management | no [VERIFIED: repo file] | No session model changes are in Phase 16 scope. [VERIFIED: repo file] |
| V4 Access Control | yes [VERIFIED: repo file] | Preserve the protected `hex-publish` environment boundary and recovery-only dispatch posture. [VERIFIED: repo file] |
| V5 Input Validation | yes [VERIFIED: repo file] | Reuse PAR validation/negative-path proof already present in protocol and controller tests. [VERIFIED: repo file] |
| V6 Cryptography | yes [VERIFIED: repo file] | Keep proof for PKCE and secure token/request handling in existing tests; do not weaken release trust boundaries. [VERIFIED: repo file] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replayed or wrong-client `request_uri` accepted again [VERIFIED: repo file] | Tampering [ASSUMED] | Reuse transaction-backed consume tests and end-to-end replay rejection evidence already in Phase 15 proof. [VERIFIED: repo file] |
| Release lane bypasses protected environment [VERIFIED: repo file] | Elevation of Privilege [ASSUMED] | Preserve `environment: hex-publish`, `main`-driven publish path, and recovery-only manual dispatch. [VERIFIED: repo file] |
| Docs/workflow drift causes unsupported release claims [VERIFIED: repo file] | Repudiation [ASSUMED] | Keep `docs/maintainer-release.md` and `release_readiness_contract_test.exs` aligned to durable behavioral invariants. [VERIFIED: repo file] |

## Sources

### Primary (HIGH confidence)
- Lockspire repo files read directly in this session: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/16-verification-and-release-runtime-hygiene/16-CONTEXT.md`, `.planning/phases/15-authorization-consumption-and-truthful-surface/15-VALIDATION.md`, `.planning/phases/15-authorization-consumption-and-truthful-surface/15-VERIFICATION.md`, `.github/workflows/release.yml`, `docs/maintainer-release.md`, `release-please-config.json`, `.release-please-manifest.json`, `test/lockspire/release_readiness_contract_test.exs`, `test/lockspire/protocol/authorization_request_test.exs`, `test/lockspire/web/authorize_controller_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, `test/integration/phase15_par_authorization_e2e_test.exs`. [VERIFIED: repo file]
- `npm view release-please version time --json` confirming `17.6.0` and publish time. [VERIFIED: npm registry]
- `release-please` CLI help from `npx --yes release-please@17.6.0 ...`. [VERIFIED: local command]
- GitHub changelog: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/ [CITED: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/]
- Release Please action metadata: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml [CITED: https://raw.githubusercontent.com/googleapis/release-please-action/v4.4.0/action.yml]
- Release Please docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md [CITED: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md]
- Release Please action README: https://github.com/googleapis/release-please-action [CITED: https://github.com/googleapis/release-please-action]

### Secondary (MEDIUM confidence)
- Release Please action release page for `v4.4.0`: https://github.com/googleapis/release-please-action/releases/tag/v4.4.0 [CITED: https://github.com/googleapis/release-please-action/releases/tag/v4.4.0]

### Tertiary (LOW confidence)
- None. [VERIFIED: repo file]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo truth, npm registry verification, and direct CLI help agree on the recommended tools. [VERIFIED: repo file] [VERIFIED: npm registry] [VERIFIED: local command]
- Architecture: HIGH - this phase is narrowly constrained by current workflow, current tests, and explicit context decisions. [VERIFIED: repo file]
- Pitfalls: HIGH - they are directly implied by the current workflow gate, prior phase proof shape, and current repo-truth tests. [VERIFIED: repo file]

**Research date:** 2026-04-24
**Valid until:** 2026-05-24
