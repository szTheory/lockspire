---
phase: 43-end-to-end-fapi-validation
reviewed: 2026-05-03T13:00:35Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - README.md
  - SECURITY.md
  - docs/maintainer-conformance.md
  - docs/supported-surface.md
  - lib/lockspire/generators/templates.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/web/controllers/authorize_controller.ex
  - lib/mix/tasks/lockspire.oidf_conformance.ex
  - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
  - scripts/conformance/fapi2-plan.json
  - test/integration/install_generator_test.exs
  - test/integration/phase43_fapi_milestone_e2e_test.exs
  - test/lockspire/protocol/authorization_flow_test.exs
  - test/lockspire/protocol/discovery_test.exs
  - test/lockspire/release_readiness_contract_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/mix/tasks/lockspire/oidf_conformance_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 43: Code Review Report

**Reviewed:** 2026-05-03T13:00:35Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

The runtime changes for Phase 43 look sound: targeted tests for `iss` redirects, discovery metadata, the new OIDF preflight task, and the phase E2E suite all passed locally. The issues are in the new conformance evidence path: one plan pin contradicts the actual supported client-auth surface, and one maintainer doc line overstates what the new task does.

## Warnings

### WR-01: Pinned OIDF plan uses an unsupported client authentication method

**File:** `docs/maintainer-conformance.md:102-110`, `scripts/conformance/fapi2-plan.json:6-14`, `test/lockspire/release_readiness_contract_test.exs:526-540`

**Issue:** Phase 43 pins `client_auth_type: private_key_jwt` as the canonical OIDF plan variant, and the release-readiness contract test locks that pin in. That does not match the shipped runtime: discovery only advertises `none`, `client_secret_basic`, and `client_secret_post` (`lib/lockspire/protocol/discovery.ex:29-30,44-45`), and token-endpoint auth validation rejects anything outside that set (`lib/lockspire/security/policy.ex:9,105-112`; `lib/lockspire/protocol/client_auth.ex:97-128`).

**Fix:** Change the pinned plan and the contract test to a client auth mode Lockspire actually supports, or explicitly mark the plan artifact as aspirational and not executable against the current runtime. As written, maintainers are told to gather release evidence with a configuration the server cannot satisfy.

### WR-02: Maintainer guide says the new task performs a live check, but it only validates prerequisites

**File:** `docs/maintainer-conformance.md:51-53`, `lib/mix/tasks/lockspire.oidf_conformance.ex:3-9,67-86`

**Issue:** The guide says `mix lockspire.oidf_conformance` can "perform this check" immediately after describing the live probe script, but the task only checks env vars, artifact presence, and PATH commands. It does not execute `scripts/conformance/fapi2-check.sh` or send any HTTP probes.

**Fix:** Reword the guide to say the task validates prerequisites for the check, or extend the task to actually run the smoke script. Right now a maintainer can follow the doc, run the task, and mistakenly believe the boundary probe passed when no protocol traffic was exercised.

---

_Reviewed: 2026-05-03T13:00:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
