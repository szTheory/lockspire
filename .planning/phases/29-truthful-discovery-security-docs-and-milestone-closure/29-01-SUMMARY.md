---
phase: 29
plan: 01
subsystem: protocol
tags:
  - discovery
  - protocol
  - dcr
dependency_graph:
  requires:
    - Phase 27 (HTTP surface)
  provides:
    - Truthful registration endpoint discovery
  affects:
    - Protocol.Discovery
tech_stack:
  added: []
  patterns:
    - Truth-based Discovery
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/discovery.ex
    - test/lockspire/protocol/discovery_test.exs
key_decisions:
  - Contract test directly asserts on router handling and discovery alignment for all three modes.
metrics:
  duration: 5
  completed_date: "2026-04-27"
---

# Phase 29 Plan 01: Truthful Discovery Advertising and Alignment Contract Test Summary

Enabled truthful advertising of the `registration_endpoint` in the `openid-configuration` document, ensuring it is only displayed when the DCR policy allows it. 

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.
