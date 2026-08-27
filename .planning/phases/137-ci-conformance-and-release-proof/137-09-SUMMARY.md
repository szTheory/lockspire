# Phase 137 Plan 09: Single-Artifact Release Proof Summary

**Completed:** 2026-08-27
**Requirements:** REL-01, REL-02

## Outcome

Release automation now binds one versioned package tar to a deterministic,
schema-versioned manifest containing its source commit, exact SHA-256, byte
size, and an allowlisted Elixir/OTP/Mix/Hex/Phoenix/LiveView/PostgreSQL tool
manifest. Validation rejects unknown fields, malformed identities, substituted
source revisions, and changed bytes before the protected publish boundary.

The idempotent publisher verifies the reviewed tar and manifest before its Hex
lookup. A first publication must reproduce byte-identical output from
`mix hex.build`; a retry succeeds only when the exact release-specific Hex API
checksum matches. Post-publish verification polls that same exact release,
checks versioned HexDocs, and installs the public version with its expected
checksum through the real clean-room SaaS happy-path journey.

## Evidence

- Release artifact and existing automation contracts: 7 tests, 0 failures.
- Python compilation and both publisher/verifier shell syntax pass.
- A real local `lockspire-1.3.0.tar` manifest was created and verified against
  the current detached source identity, with all seven runtime fields present.
- No publish was attempted; the already-public 1.3.0 checksum intentionally
  differs from the local development artifact and would fail closed.

## Security Notes

- Retained manifests and receipts use strict allowlisted schemas and contain no
  environment dump, credentials, absolute temporary paths, or unbounded output.
- Registry propagation retries are bounded; checksum mismatch fails immediately.
- Prepublish and postpublish evidence share the same source/version/checksum
  identity rather than independently rebuilding or inferring package truth.
