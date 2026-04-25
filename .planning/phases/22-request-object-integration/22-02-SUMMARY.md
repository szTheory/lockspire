---
phase: 22-request-object-integration
plan: "02"
subsystem: config
tags: [config, jar, replay-bound, tdd]
dependency_graph:
  requires: []
  provides: [Lockspire.Config.jar_max_age_seconds/0]
  affects: [22-04-request-object-orchestrator]
tech_stack:
  added: []
  patterns: [optional-with-default accessor, Application.get_env/3 with module attribute default]
key_files:
  created: []
  modified:
    - lib/lockspire/config.ex
    - test/lockspire/config_test.exs
    - config/config.exs
decisions:
  - "Followed known_scopes/0 optional-with-default pattern (not issuer!/0 bang pattern) — jar_max_age_seconds has a sensible default and never raises (D-13)"
  - "Default of 600s (10 minutes) chosen as the replay-window ceiling per WR-03"
  - "Module attribute @jar_max_age_default used (not inline literal) to keep default DRY in spec, doc, and implementation"
metrics:
  duration: "131 seconds"
  completed_date: "2026-04-25"
  tasks_completed: 1
  files_modified: 3
---

# Phase 22 Plan 02: jar_max_age_seconds Config Accessor Summary

**One-liner:** Config accessor `jar_max_age_seconds/0` returning Application.get_env default 600 (WR-03 replay-window ceiling).

## What Was Built

Added `Lockspire.Config.jar_max_age_seconds/0` as a new optional-with-default config accessor following the `known_scopes/0` shape. The function returns the configured `:jar_max_age_seconds` application env value or falls back to `@jar_max_age_default` (600). This accessor is the config seam that Plan 22-04's `RequestObject` orchestrator will consume to thread a `:max_age` opt into `Jar.validate_claims/2`.

## New Accessor

- **Function:** `Lockspire.Config.jar_max_age_seconds/0` at `lib/lockspire/config.ex:60`
- **Default:** 600 (via `@jar_max_age_default` at line 44)
- **Spec:** `@spec jar_max_age_seconds() :: pos_integer()`
- **Config key:** `:jar_max_age_seconds` set in `config/config.exs:9`

## Decisions Implemented

- **D-13 / WR-03:** Configurable replay-window ceiling for JAR request objects. Default 600s provides bounded replay window even when hosts forget to configure it.

## Test Coverage

- **Test count delta in config_test.exs:** +1 (total: 7 tests)
- **New test:** "jar_max_age_seconds/0 returns 600 by default and honors configured override"
  - Covers default path (delete env, assert 600)
  - Covers override path (put_env 300, assert 300)
  - Uses `on_exit/1` cleanup pattern consistent with existing tests

## TDD Gate Compliance

- RED commit: `5d6026d` — test(22-02): add failing test for jar_max_age_seconds/0 default and override
- GREEN commit: `e6ce7a8` — feat(22-02): add jar_max_age_seconds/0 config accessor with 600s default
- REFACTOR: Not needed — implementation is minimal and clean

## Deviations from Plan

None — plan executed exactly as written.

Note: `mix compile --warnings-as-errors` produced 2 warnings from `lib/lockspire/protocol/authorization_request.ex` referencing `Lockspire.Protocol.ParPolicy` and `Lockspire.Storage.Ecto.Repository.get_server_policy/0`. These are pre-existing out-of-scope issues from other parallel wave plans (22-01, 22-03) and are not caused by this plan's changes. The new `config.ex` code itself compiles cleanly.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. The accessor reads application env only; invalid host-configured values surface downstream at `Jar.validate_claims/2` as documented in the threat model.

## Self-Check

**Files exist:**
- lib/lockspire/config.ex: FOUND
- test/lockspire/config_test.exs: FOUND
- config/config.exs: FOUND

**Commits exist:**
- 5d6026d (RED): FOUND
- e6ce7a8 (GREEN): FOUND

## Self-Check: PASSED
