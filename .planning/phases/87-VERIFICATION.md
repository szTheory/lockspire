---
phase: 87
status: passed
verified: 2026-05-24
requirements:
  - PROOF-02
---

# Phase 87 Verification

## Goal

Update support-surface, DCR, operator, and release-truth docs so Lockspire's public and operator-facing contract matches the shipped DCR/logout metadata behavior from phases 85 and 86 without broadening the logout runtime claim.

## Automated Checks

- `mix docs.verify`
- `mix test test/lockspire/web/controllers/registration_controller_test.exs test/lockspire/protocol/registration_management_test.exs`
- `rg -n "four existing logout propagation metadata fields|back-channel.*durable|front-channel.*best effort only|does not add a new logout runtime" docs/supported-surface.md`
- `! rg -n "PUT /oauth/register|registration_access_token replaces|client_secret replaces|post-logout redirect URIs are browser destinations" docs/supported-surface.md`
- `rg -n "full-replace|omitted.*clear|registration_access_token.*replaces|client_secret.*replaces" docs/dynamic-registration.md`
- `rg -n "self-service clients|Back-channel logout is the reliable path|Front-channel logout is best effort only|Post-logout redirect URIs|Logout propagation" docs/operator-admin.md`
- `rg -n 'canonical support contract|docs/supported-surface.md|does not define a second public support contract|Public release claims stay anchored to \`docs/supported-surface.md\`' docs/maintainer-release.md`
- `mix docs.verify` completed successfully.
- The targeted DCR/controller test run completed successfully with 37 tests and 0 failures.

## Requirement Coverage

- `PROOF-02` passed: public docs and operator guidance now state that DCR manages the existing logout propagation metadata.
- `PROOF-02` passed: the support contract still preserves Lockspire's asymmetry that back-channel logout is durable and front-channel logout is best effort only.
- `PROOF-02` passed: release and operator wording defer to `docs/supported-surface.md` instead of creating a second support matrix.

## Scope Guard

- No new logout runtime was introduced.
- No new automated doc-drift contract tests were added.
- Post-logout redirect URIs remain documented separately from logout propagation metadata.

## Result

Phase 87 passed verification.
