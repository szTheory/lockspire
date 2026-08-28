---
phase: 131-executable-installation
plan: "05"
subsystem: installation
tags: [generator, oauth, oidc, pkce, fapi, integration]
requires:
  - phase: 131-01
    provides: executable generated host router and configuration seams
  - phase: 131-04
    provides: atomic migration-aware installer manifests
provides:
  - default-profile generated OAuth/OIDC behavioral smoke
  - explicit opt-in FAPI smoke inventory and command
  - rendered-template execution proof against generated host artifacts
affects: [installation, onboarding, release-readiness]
tech-stack:
  added: []
  patterns: [profile-aware template inventory, executable rendered-test proof, opt-in FAPI test discovery]
key-files:
  created:
    - priv/templates/lockspire.install/default_smoke_e2e_test.exs
  modified:
    - lib/lockspire/generators/templates.ex
    - lib/lockspire/generators/install.ex
    - lib/mix/tasks/lockspire.install.ex
    - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
    - test/integration/install_generator_test.exs
    - docs/install-and-onboard.md
key-decisions:
  - "Every generated host receives a default-discovered smoke that asserts security_profile :none, discovery/JWKS, S256 PKCE, and exact redirect matching."
  - "FAPI proof is generated only with strict --with-fapi-smoke, tagged :fapi, and kept outside ordinary *_test.exs discovery."
  - "Installer integration executes compiled rendered ExUnit test bodies against GeneratedHostAppWeb.Endpoint rather than inspecting substitute modules."
requirements-completed: [INST-05]
coverage:
  - id: D1
    description: "Default installation renders and executes a profile-neutral OAuth/OIDC smoke against the actual generated host endpoint."
    requirement: INST-05
    verification:
      - kind: integration
        ref: "mix test test/integration/install_generator_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "FAPI proof is absent by default, rendered only with the strict opt-in flag, and executes after an explicitly selected FAPI server profile."
    requirement: INST-05
    verification:
      - kind: integration
        ref: "mix test test/integration/install_generator_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Install help and onboarding documentation identify the default and opt-in commands without overstating the default profile."
    requirement: INST-05
    verification:
      - kind: docs
        ref: "mix docs.verify"
        status: pass
    human_judgment: false
duration: 7 min
completed: 2026-08-26
status: complete
---

# Phase 131 Plan 05: Generated Smoke Profile Truth Summary

**A normal Lockspire install now emits an executable default-profile OAuth/OIDC smoke, while FAPI/PAR evidence is an explicit, separately run opt-in.**

## Tasks Completed

1. **Make generated smoke inventory profile-aware** — Added the default `_test.exs` smoke to ordinary generation, made FAPI output conditional on strict `--with-fapi-smoke`, kept selected artifacts manifest-tracked, and documented both commands in CLI output.
2. **Execute default-secure and explicit FAPI generated behavior** — Compiled and invoked the actual rendered ExUnit modules against the generated host endpoint. The default proof covers `security_profile: :none`, discovery/JWKS, authorization-code routing with PKCE S256, and exact redirect rejection. The FAPI proof requires a selected FAPI profile and proves the direct-authorize PAR boundary.

## Verification

- `mix test test/integration/install_generator_test.exs` — passed (12 tests).
- `mix compile --warnings-as-errors` — passed.
- `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/release/support_surface_contract_test.exs` — passed (49 tests).
- `mix test.fast` — passed (1,316 tests; 252 integration tests excluded).
- `mix qa` — passed; Credo reported no issues and Sobelow completed with its existing no-router informational warning.
- `mix docs.verify` — passed.

The named ASVS evidence for T-131-18, T-131-19, and T-131-20 is green through `mix test test/integration/install_generator_test.exs`.

## Decisions Made

- The normal generated test remains in standard Mix discovery and confirms the host stays on the default `:none` security profile; it does not claim FAPI/PAR behavior.
- FAPI proof uses a non-`*_test.exs` filename plus the `:fapi` tag, so it is generated and run only by an adopter who deliberately selects that profile.
- `openid` remains an authorization-request protocol scope while generated registrations use the application scope `profile`.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Truthful protocol assertion] Removed the unsupported FAPI `iss` assertion.**

   - **Found during:** Task 2
   - **Issue:** The rendered FAPI proof expected an `iss` parameter on a direct-authorize PAR rejection, but the shipped FAPI boundary returns the standards-relevant PAR error without that parameter.
   - **Fix:** Kept the executable PAR rejection proof and removed the false `iss` claim from its name and assertion.
   - **Files modified:** `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`, `test/integration/install_generator_test.exs`
   - **Verification:** Rendered FAPI test executes successfully under `:fapi_2_0_security`.
   - **Commit:** `f286916`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Generated FAPI guidance now reflects the behavior the installed endpoint actually provides.

## Known Stubs

None.

## Issues Encountered

None.

## Next Phase Readiness

The packaged installation path now has a truthful executable smoke boundary: default adopters get secure OAuth/OIDC proof by default, while FAPI evidence remains opt-in for the separately configured profile.

## Self-Check: PASSED

- `priv/templates/lockspire.install/default_smoke_e2e_test.exs` exists and is committed.
- Task commits `c53849a`, `a1d98c7`, and `f286916` exist in git history.
- The targeted integration, compile, fast-suite, QA, and documentation gates passed.
