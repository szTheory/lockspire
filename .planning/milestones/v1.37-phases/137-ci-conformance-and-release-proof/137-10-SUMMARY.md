---
phase: 137-ci-conformance-and-release-proof
plan: 10
subsystem: release-proof
tags: [github-actions, hex, clean-room, release-evidence]
requirements-completed: [CI-01, CI-02, CI-03, CONF-01, CONF-02, REL-01, REL-02]
status: complete
completed: 2026-08-27
---

# Phase 137 Plan 10: Exact Release Workflow Summary

**Completed:** 2026-08-27
**Requirements:** REL-01, REL-02

## Outcome

The release workflow now carries one exact package identity through three trust
zones. An unprivileged prepublish job checks out the successful-CI SHA, runs the
release preflight, binds the resulting tar to a strict manifest, and proves
those bytes through the clean-room SaaS HTTP journey. It uploads only the tar,
manifest, and bounded prepublish receipt under a SHA-bound artifact name.

The non-canceling `hex-publish` environment downloads that data beside a fresh
detached checkout of the same SHA, rejects extra files, symlinks, identity
drift, or checksum drift, and passes explicit tar/manifest/SHA arguments to the
publisher. `HEX_API_KEY` exists only on that protected publish step.

After publication, an unprivileged job verifies the exact release-specific Hex
checksum, versioned HexDocs, and public-version clean-room HTTP journey. It
retains only the manifest and schema-bounded pre/post receipts for 90 days;
raw journey logs and configuration are never artifacts.

## Evidence

- Release workflow/artifact, automation, CI-evidence, install-truth, and
  coverage-config contracts: 16 tests, 0 failures.
- Repo-pinned Actionlint and ShellCheck workflow validation passes.
- Strict documentation generation passes with no warnings.
- Workflow diff inspection confirms immutable action pins, read-only
  unprivileged jobs, and one environment-scoped publish secret.

## Security Notes

- Downloaded artifact contents are treated as data; executable code always
  comes from a fresh exact-SHA checkout.
- Recovery reuses the same SHA, CI run ID, version, manifest, and checksum
  rather than rebuilding from a moving branch.
- Registry propagation retries are bounded and checksum mismatch fails
  immediately without replacement or opportunistic republish.
