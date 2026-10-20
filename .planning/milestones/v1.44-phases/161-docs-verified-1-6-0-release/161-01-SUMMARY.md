---
phase: 161-docs-verified-1-6-0-release
plan: 01
subsystem: docs
tags: [docs, operator-guide, key-protection, contract-test]
requires: []
provides:
  - "docs/operator-admin.md Key protection subsection (7-row state table)"
  - "Contract tests locking operator guide labels and install/upgrade pointers"
affects: [161-04]
tech-stack:
  added: []
  patterns: ["labels derived from protection.ex source by Regex.scan in the contract test"]
key-files:
  created: []
  modified:
    - docs/operator-admin.md
    - docs/install-and-onboard.md
    - docs/upgrading/signing-key-encryption.md
    - test/lockspire/kek_guidance_contract_test.exs
key-decisions:
  - "Drift audit found no drift; guides edited only with the D-20 pointer sentence"
requirements-completed: [DOC-02]
duration: 10 min
completed: 2026-10-20
status: complete
commits: 2
plan_head_before: 9284d191d17fadee08fe89880caf82e20c4b2e92
plan_head_after: a9f06d8461cb4c92d0cf54fa319804712565603d
actuals:
  tokens: 2600
  tasks: 2
  commits: 2
---

# Phase 161 Plan 01: Key protection operator guide Summary

Operator guide now documents all seven shipped Key protection states, derived-from-source contract test keeps it honest, and the install and upgrade guides point to it.

## Tasks

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 Key protection subsection + contract test | 31a291ca | `### Key protection` table; test derives 7 labels from protection.ex; RED failed first (2 failures), GREEN 13 tests 0 failures; deleting the Unknown row fails the test |
| 2 Pointers + drift audit | a9f06d84 | One sentence in each guide; pointer test failed first, then green; removing the install pointer makes it fail |

`mix docs.verify` exits 0 on 1.19.5-otp-28 with no warnings. `docs/supported-surface.md`, `mix.exs` and `mix.lock` are unchanged.

## D-01 drift audit

| Claim | Code location | Verdict | Assertion added | Failing-first run | Edit made |
| ----- | ------------- | ------- | --------------- | ----------------- | --------- |
| gen.kek prints key once with config block | lockspire.gen.kek.ex print_default/1 | match | none | n/a | none |
| `--raw` prints only the key; `--id` no effect with `--raw` | gen.kek.ex run/1, moduledoc | match | none | n/a | none |
| `{:system, "VAR"}` refuses boot when unset or empty | config.ex resolve_env_entries/1 (:missing_env) | match | none | n/a | none |
| Value read at boot; change applies on restart | config.ex key_encryption_keyset/0 (persistent_term cache populated at boot) | match | none | n/a | none |
| Value untrimmed, trailing newline invalid | config.ex resolve_env_entries/1 comment; KeySet validation | match | none | n/a | none |
| Rotation step uses `--raw`, full output would overwrite current var | gen.kek.ex, KekSnippet.env_var/0 | match | none | n/a | none |
| `mix lockspire.doctor key_encryption` form | lockspire.doctor.ex dispatches to doctor.key_encryption | match | none | n/a | none |

No drift, so the D-20 pointer test is the failing-first proof for Task 2. Minor note, not drift: guides say "unset or empty"; whitespace-only values are also rejected (more strict than documented, not contradicted).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

Both commits exist (31a291ca, a9f06d84); modified files present; five-file test run 74 tests 0 failures; docs.verify exit 0.
