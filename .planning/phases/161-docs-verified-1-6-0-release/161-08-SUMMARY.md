---
phase: 161-docs-verified-1-6-0-release
plan: 08
subsystem: release
tags: [hex, checksum, clean-room, verification]
requires: ["161-07"]
provides: ["Independent public artifact/docs/tag verification", "Fresh HEX_HOME and MIX_HOME install of exact 1.6.0"]
affects: [161-09]
requirements-completed: []
actuals:
  tasks: 2
completed: 2026-10-20
status: complete
---

# Phase 161 Plan 08: Independently verified public 1.6.0

The Hex API, downloaded tarball, retained release manifest and fresh install lockfile all match SHA256 `9eba2cda3a7d5513399e4bcb0401e2688f98300a3b34b25fe6a568c62d782ed5`, source `428a9c53e02bc573376d0fcac313f047fbbea81c`.

## Verification

- Public version 1.6.0 has docs; mandatory retained manifest downloaded successfully. Postpublish receipt verified; terminal receipt release_verified true, blocker none, every stage passed.
- Outer tar has exactly VERSION, CHECKSUM, metadata.config and contents.tar.gz. Inner tar has exactly the expected 11 Mix tasks (8 prior plus doctor.key_encryption, gen.kek and keys.reencrypt); test.setup absent.
- Versioned HexDocs root and supported-surface, operator-admin, signing-key-encryption pages return 200. Entry page uses a meta refresh to README; guide paths confirmed by reading the published sidebar JSON without executing downloaded JS.
- Tag resolves to source SHA; GitHub release target verified, not draft or prerelease.
- Fresh isolated HEX_HOME, MIX_HOME and MIX_ARCHIVES host installed ==1.6.0 from Hex with HEX_API_KEY unset. Dependency get repeated successfully; exact outer lock checksum matches public checksum. New task file present, dependencies compile, gen.kek --raw executes and only its output length 44 is recorded.
- No stale authorized-SHA variable remains, no generated key in evidence, no new maintained script and no verification fallback.

## Next

Refresh and land the verified ledger in plan09. REL-02 remains pending until that main-branch record and final phase evidence are established.
