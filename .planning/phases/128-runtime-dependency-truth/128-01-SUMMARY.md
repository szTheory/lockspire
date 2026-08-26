---
phase: 128-runtime-dependency-truth
plan: "01"
subsystem: protocol
tags: [ciba, jwt, ecto, storage]
requires: []
provides: [ordinary host Repo CIBA Push coverage, adapter-backed access-token signer]
affects: [token issuance, CIBA workers]
tech-stack: {added: [], patterns: [protocol defaults use storage adapters]}
key-files: {created: [], modified: [lib/lockspire/protocol/access_token_signer.ex, lib/lockspire/test_repo.ex]}
key-decisions: ["Host Repo remains plain Ecto.Repo; signing defaults to Repository."]
requirements-completed: [RUNTIME-01, RUNTIME-02]
coverage:
  - id: D1
    description: CIBA Push signs and delivers JWT access and ID tokens through an ordinary host Repo.
    requirement: RUNTIME-02
    verification: [{kind: integration, ref: "mix test test/integration/phase53_ciba_delivery_modes_e2e_test.exs", status: pass}]
    human_judgment: false
status: complete
---

# Phase 128 Plan 01: Ordinary Host Repo CIBA Push Summary

**CIBA Push now signs both delivery tokens through the Lockspire storage adapter while the configured test Repo exposes only Ecto behavior.**

## Accomplishments

- Default signing-key lookup uses `Lockspire.Storage.Ecto.Repository`.
- Removed masking storage delegates from `Lockspire.TestRepo`.
- Added regression assertions for compact JWT access and ID token delivery.

## Task Commits

1. `e9b098a` — fix signer fallback and CIBA Push proof.

## Verification

`mix test test/integration/phase53_ciba_delivery_modes_e2e_test.exs test/integration/phase100_sender_constraint_e2e_test.exs test/lockspire/protocol/access_token_signer_test.exs` passed.

## Deviations from Plan

None - plan executed as specified.

## Self-Check: PASSED
