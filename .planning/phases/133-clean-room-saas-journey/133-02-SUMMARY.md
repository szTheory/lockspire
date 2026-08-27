---
phase: 133-clean-room-saas-journey
plan: 02
subsystem: acceptance
tags: [clean-room, provider, package-boundary, bootstrap, dpop]
requires:
  - phase: 133-clean-room-saas-journey
    provides: copied-package child dependency provenance
provides:
  - package-clean provider builder and source-boundary audit
  - host-owned account/login/resource overlays
  - public bearer and DPoP client enrollment with separate secret handoffs
affects: [133-03, 133-04, 133-05, 133-06]
key-files:
  created:
    - scripts/acceptance/clean_room/build_provider.py
    - test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex
    - test/clean_room/provider_host/lib/clean_room_provider_web/router_patch.exs
    - test/integration/phase133_provider_install_test.exs
  modified: []
decisions:
  - "The provider overlay uses only public Lockspire facades and generated routes."
  - "Bearer and DPoP credentials use distinct mode-0600 handoff files and distinct fixed callbacks."
metrics:
  completed: 2026-08-27
status: partial
---

# Phase 133 Plan 02: Clean Provider Bootstrap Summary

**A package-clean provider fixture now owns its account, login, protected-resource, and dual confidential-client boundaries.**

## Accomplishments

- Added a child-provider builder that copies the local packaged input into its fixed vendor path, verifies locks/provenance, and rejects internal/test seams.
- Added host-owned account resolution, interaction/login handling, and a protected billing API using the canonical `VerifyToken -> EnforceSenderConstraints -> RequireToken` order and every public semantic token reader.
- Added public signing-key lifecycle and separate bearer/DPoP confidential registrations. The DPoP policy is set and re-read via `Lockspire.Admin`; each plaintext secret is written only to its own mode-0600 handoff file.
- Added package-clean integration coverage and static acceptance checks for boundary, enrollment, secret separation, semantic readers, and no replay-store override.

## Task Commits

1. **Task 1 RED: package-clean provider proof** — `6229aa3`
2. **Task 1 GREEN: provider builder and host seams** — `a8d04ba`
3. **Task 2 GREEN: public dual-client bootstrap and protected route** — `0ac5764`
4. **Rule 1 correction: compile-safe host overlays** — `1b2f744`
5. **Formatting** — `111b186`

## Verification

- Passed: `mix test --include integration test/integration/phase133_provider_install_test.exs --only package_clean`
- Passed: `python3 scripts/acceptance/clean_room/build_provider.py --self-test`
- Passed: `python3 scripts/acceptance/clean_room/build_provider.py --check-bootstrap`
- Passed: `mix format --check-formatted` for every Plan 02 Elixir file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected an unclosed map in the host-owned interaction seam.**

- **Found during:** final formatting/compile check.
- **Fix:** expanded and closed the returned interaction map, then formatted the overlays.
- **Commit:** `1b2f744`

## Deferred Verification

The full child `mix lockspire.install`/compile step cannot complete on this workstation: a fresh dependency compile of the package-pinned `jose 1.11.12` fails under the installed Elixir 1.19.5 because `jose_jwt.hrl` is absent while Elixir extracts its record. Root dependencies were already compiled under the project’s supported toolchain, but a copied clean child necessarily recompiles them. The builder retains the real installer path for a compatible CI/runtime; the local self-test performs only the package/provenance/boundary half and does not claim a live listener.

## Self-Check: PASSED

- All Plan 02 source, test, and builder files exist.
- Commits `6229aa3`, `a8d04ba`, `0ac5764`, `1b2f744`, and `111b186` exist.
