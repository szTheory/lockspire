---
phase: 09-preview-posture-lock
verified: 2026-04-24T03:44:45Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Contract tests fail when public preview-posture claims drift across docs, security policy, release posture, workflows, and roadmap truth per D-08 through D-10."
    - "Planning metadata consistently records the preview-posture lock and PAR as future-only v1.1 non-support."
  gaps_remaining: []
  regressions: []
---

# Phase 09: Preview Posture Lock Verification Report

**Phase Goal:** Freeze the public preview posture around what the repo proves today and document PAR as the next milestone candidate without starting it here or implying current v1.1 support.
**Verified:** 2026-04-24T03:44:45Z
**Status:** passed
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public-facing docs describe Lockspire as an embedded Phoenix/Elixir library and keep the public claim at `v0.1` preview. | ✓ VERIFIED | [README.md](/Users/jon/projects/lockspire/README.md:3) and [README.md](/Users/jon/projects/lockspire/README.md:7) keep the entrypoint narrow and preview-only; [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:3) and [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:9) define the embedded-library `v0.1` wedge explicitly. |
| 2 | `docs/supported-surface.md` is the canonical support contract, and companion docs stay narrower and refer back to it. | ✓ VERIFIED | Canonical contract is declared at [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:5); companion docs defer back at [README.md](/Users/jon/projects/lockspire/README.md:7), [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:31), [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:60), [docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:3), and [docs/maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:3). |
| 3 | Repo-owned proof is named through checked-in tests, workflows, and runbooks instead of demo-app or aspirational proof stories. | ✓ VERIFIED | [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:39) through [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:48) enumerate repo-owned proof and reject demo-app folklore; onboarding proof stays executable at [docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:57), [test/integration/install_generator_test.exs](/Users/jon/projects/lockspire/test/integration/install_generator_test.exs:1), and [test/integration/phase6_onboarding_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase6_onboarding_e2e_test.exs:1). |
| 4 | Contract tests fail when public preview-posture claims drift across docs, security policy, release posture, workflows, and roadmap truth. | ✓ VERIFIED | The Phase 09 gap is closed: [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:137) through [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:167) now read `docs/install-and-onboard.md` via `@install_and_onboard_path` and assert onboarding posture and proof references; `mix test test/lockspire/release_readiness_contract_test.exs` passed with `7 tests, 0 failures`. |
| 5 | PAR is documented as the next milestone candidate and explicitly not current `v1.1` support. | ✓ VERIFIED | Future-only PAR wording is consistent in [PROJECT.md](/Users/jon/projects/lockspire/.planning/PROJECT.md:47), [PROJECT.md](/Users/jon/projects/lockspire/.planning/PROJECT.md:83), [ROADMAP.md](/Users/jon/projects/lockspire/.planning/ROADMAP.md:52), [ROADMAP.md](/Users/jon/projects/lockspire/.planning/ROADMAP.md:66), and [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:25). |
| 6 | No current support-facing artifact implies PAR or broader protocol support has already started. | ✓ VERIFIED | Public docs keep PAR negative or out-of-scope only at [README.md](/Users/jon/projects/lockspire/README.md:21), [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:24), [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:41), and [docs/maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:67); the contract test rejects present-tense PAR support at [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:170). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docs/supported-surface.md` | Canonical preview contract | ✓ VERIFIED | Substantive contract covering in-scope surface, out-of-scope items, repo-owned proof, preview bar, and `1.0` bar; `gsd-sdk query verify.artifacts` passed. |
| `README.md` | Thin public entrypoint | ✓ VERIFIED | Keeps public summary short, links to the canonical contract, and avoids present-tense unsupported claims; artifact verification passed. |
| `SECURITY.md` | Security disclosure and secure-default posture aligned to preview scope | ✓ VERIFIED | Supported security surface and secure defaults remain explicit and tied back to the canonical contract. |
| `docs/install-and-onboard.md` | Canonical onboarding guide that names executable proof | ✓ VERIFIED | Procedural Phoenix-first guide with host seam and concrete proof links; now also covered by the release-readiness contract suite. |
| `docs/maintainer-release.md` | Maintainer release posture inside the same preview boundary | ✓ VERIFIED | Maintainer-only guidance stays inside the preview wedge and names repo-owned proof boundaries. |
| `test/lockspire/release_readiness_contract_test.exs` | Narrow preview-posture drift checks over trust-bearing claims | ✓ VERIFIED | Reads README, supported surface, security policy, onboarding guide, maintainer guide, workflows, and planning metadata; passed `7 tests, 0 failures`. |
| `.planning/ROADMAP.md` | PAR as future milestone only | ✓ VERIFIED | Phase goal and next milestone candidate keep PAR future-only and out of current support. |
| `.planning/PROJECT.md` | Project-level future PAR framing | ✓ VERIFIED | Active requirements and key decisions record PAR as next and unsupported in `v1.1`. |
| `.planning/REQUIREMENTS.md` | Requirements traceability for POST requirements and current non-support | ✓ VERIFIED | Previous contradiction is closed: [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:23) through [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:25) and [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:45) through [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:57) both mark POST-01 through POST-03 complete, and the footer is current at [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:66). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `README.md` | `docs/supported-surface.md` | Canonical supported-surface link and preview wording | ✓ WIRED | `gsd-sdk query verify.key-links` passed for Plan 09-01; link and preview wording are present at [README.md](/Users/jon/projects/lockspire/README.md:7). |
| `SECURITY.md` | `docs/supported-surface.md` | Shared supported and out-of-scope security surface | ✓ WIRED | Key-link verification passed; security policy points back to the canonical contract at [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:31) and [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:60). |
| `docs/install-and-onboard.md` | `test/integration/install_generator_test.exs` / `test/integration/phase6_onboarding_e2e_test.exs` | Named executable onboarding proof | ✓ WIRED | Key-link verification passed; proof links live at [docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:57). |
| `test/lockspire/release_readiness_contract_test.exs` | `docs/supported-surface.md` | Sentinel assertions on preview-only claims and out-of-scope protocol surface | ✓ WIRED | Key-link verification passed for Plan 09-02; assertions live at [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:116). |
| `test/lockspire/release_readiness_contract_test.exs` | `.planning/ROADMAP.md` | Cross-file consistency for PAR-next but not supported wording | ✓ WIRED | Key-link verification passed; roadmap assertions live at [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:181). |
| `.planning/PROJECT.md` | `.planning/ROADMAP.md` | Shared milestone language for future PAR without current implementation claims | ✓ WIRED | Both artifacts carry matching future-only PAR wording at [PROJECT.md](/Users/jon/projects/lockspire/.planning/PROJECT.md:47) and [ROADMAP.md](/Users/jon/projects/lockspire/.planning/ROADMAP.md:66). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `test/lockspire/release_readiness_contract_test.exs` | `readme`, `supported_surface`, `security`, `onboarding`, `guide`, `project`, `roadmap`, `requirements` | `File.read!/1` over current repo files | Yes | ✓ FLOWING |
| `docs/install-and-onboard.md` | Proof references | Checked-in test files and CI workflow named in the doc | Yes | ✓ FLOWING |
| `.planning/REQUIREMENTS.md` | POST requirement and traceability rows | Markdown content consumed by the contract test | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs build from current repo truth | `mix docs.verify` | Completed successfully | ✓ PASS |
| Preview-posture contract suite enforces current docs and planning invariants | `mix test test/lockspire/release_readiness_contract_test.exs` | `7 tests, 0 failures` | ✓ PASS |
| Generator-backed install proof still passes | `mix test test/integration/install_generator_test.exs` | `4 tests, 0 failures` | ✓ PASS |
| Canonical auth-code + PKCE onboarding proof still passes | `mix test test/integration/phase6_onboarding_e2e_test.exs` | `1 test, 0 failures` | ✓ PASS |
| Full contributor gate | `mix ci` | Blocked locally by Hex re-auth prompt during `mix deps.audit`; CI workflow and `mix ci` alias remain mechanically aligned | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `POST-01` | `09-01` | Public docs describe only the implemented `v0.1` preview scope and avoid unsupported protocol claims. | ✓ SATISFIED | [README.md](/Users/jon/projects/lockspire/README.md:7), [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:9), [SECURITY.md](/Users/jon/projects/lockspire/SECURITY.md:31), [docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:3), and [docs/maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md:61) stay inside the repo-proven preview wedge. |
| `POST-02` | `09-02` | Contract tests fail if release docs, security policy, or workflow files drift from the supported preview posture. | ✓ SATISFIED | [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:137) through [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:203) cover security, onboarding, maintainer release posture, workflows, and planning truth; the suite passed. |
| `POST-03` | `09-02` | The next protocol-expansion milestone is documented as PAR, but PAR is not implemented and not supported during `v1.1`. | ✓ SATISFIED | [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:25), [REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:39), [PROJECT.md](/Users/jon/projects/lockspire/.planning/PROJECT.md:47), and [ROADMAP.md](/Users/jon/projects/lockspire/.planning/ROADMAP.md:66) are consistent, and the contract test rejects present-tense PAR support at [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:192). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME/placeholders, stub returns, or hardcoded-empty posture artifacts found in the verified Phase 09 files. | ℹ️ Info | No blocker or warning-level anti-patterns found in the current Phase 09 surface. |

### Gaps Summary

The two prior blockers are closed in the current tree. The contract suite now reads and asserts against `docs/install-and-onboard.md`, so onboarding posture is inside the executable drift fence, and `.planning/REQUIREMENTS.md` no longer contradicts itself about POST completion or PAR non-support.

I also ran a disconfirmation pass across the broader docs set. I did not find a current support-facing artifact that leaks present-tense PAR support or broader protocol/product claims. The only incomplete spot-check is `mix ci` in this local verifier environment because `mix deps.audit` triggered a Hex re-auth prompt; that does not change the Phase 09 verdict because the relevant posture-lock checks, onboarding proof, and plan-defined artifact/link checks all passed from repo truth, and the CI workflow remains mechanically aligned with the `mix ci` alias.

---

_Verified: 2026-04-24T03:44:45Z_
_Verifier: Claude (gsd-verifier)_
