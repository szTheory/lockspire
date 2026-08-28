# Phase 137 Plan 08: Exact Clean-Room Package Sources Summary

**Completed:** 2026-08-27
**Requirement:** REL-01

## Outcome

The Phase 133 provider/client SaaS journey now prepares one explicit Lockspire package source and shares its audited unpacked tree with both isolated roles. Developer runs retain the checkout-build default; release proof can select either an exact local `lockspire-X.Y.Z.tar` plus optional expected SHA-256 or an exact public Hex version.

Local archives are constrained to a declared root, must be regular non-symlink files with exact versioned names, and are checksum-validated before the installed Hex archive validates and unpacks its own package format. Exact public versions reject ranges, are fetched as tar bytes with `mix hex.package fetch`, and cross the same checksum, metadata-version, inventory, path, and child-dependency provenance checks. Provider and client can no longer rebuild separate package inputs inside one journey.

The maintained shell wrapper preserves the lightweight probe mode and routes package/journey arguments to the real separate-origin acceptance driver.

## Evidence

- Focused package-source contract: 3 tests, 0 failures.
- Python compilation and wrapper shell syntax pass.
- Local tar inspection: `lockspire-1.3.0`, SHA-256 `708b2e8347e1972ea44a625cf9952b61276b9d5e88420129483f4654c365341e`.
- Exact public Hex inspection: `lockspire-1.3.0`, SHA-256 `0946f32eb651c2269547e50c2728f84c92e1c4cd9b93bfca185123d0b82a25db`.
- The real local-tar happy journey completed install, migration, `lockspire.verify`, boot, discovery, authorization code + PKCE, OIDC validation, userinfo, protected resource access, evidence scan, and deterministic cleanup.

## Security Notes

- Package identity is selected before either child exists and cannot resolve to the live checkout.
- Hex validates archive structure/checksum before any package source becomes executable dependency code.
- Retained output is a bounded source/version/checksum identity; existing OAuth sentinel registration and evidence redaction remain active.
