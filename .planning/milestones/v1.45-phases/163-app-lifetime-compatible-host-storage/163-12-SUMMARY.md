---
phase: 163-app-lifetime-compatible-host-storage
plan: "12"
subsystem: storage
tags: [postgres, concurrency, client-lifetime, rollback]
dependency_graph:
  requires: [163-04, 163-08, 163-09, 163-10, 163-11]
  provides: [client-lifetime-race-proof, issuance-rollback-proof]
  affects: [storage-tests, phase-163-verification]
tech_stack:
  added: []
  patterns: [independent-postgresql-sessions, pg_blocking_pids-barriers, injected-clock]
key_files:
  created:
    - test/lockspire/storage/client_lifetime_client_wait_test.exs
    - test/lockspire/storage/client_lifetime_grant_wait_test.exs
    - test/lockspire/storage/client_lifetime_rollback_test.exs
    - test/support/client_lifetime_race_helpers.ex
  modified: []
decisions:
  - Correlate concurrent RFC 8693 validator observations by request label so assertions do not depend on scheduler arrival order.
metrics:
  duration: focused execution
  completed_date: 2026-10-20
  tasks: 2
  files: 4
  commits: 0
  plan_head_before: 1ba71750f51f4431baba23ac3d6e43ba184d055f
  plan_head_after: 1ba71750f51f4431baba23ac3d6e43ba184d055f
status: complete
actuals:
  tokens: 0
  tasks: 2
  commits: 0
---

# Phase 163 Plan 12: App-Lifetime Storage Race Proof Summary

Independent PostgreSQL sessions now prove client and later-grant wait behavior, stale-identity rejection, issuance delivery lock release, and transactional rollback outcomes.

## Completed Work

- Added bounded race helpers that report backend PIDs, confirm the exact `pg_blocking_pids` relation, coordinate clock advancement only after blocker confirmation, and bound task cleanup.
- Added client-lock tests for deadline equality, committed disablement, and verified-credential rotation. They assert authorization-code, token, and audit state remains unchanged after rejection.
- Added a later grant-row wait test, a network-delivery callback with independent `FOR UPDATE NOWAIT` probes for client and CIBA rows, and opposing RFC 8693 subject/actor orders. RFC validator results are correlated by request label.
- Added write/audit failure injection for code redemption, device polling, CIBA polling, refresh rotation, RFC 8693 token exchange, and promotion. Tests compare relevant durable grant, token, credential, verifier, lifetime-version, deadline, and audit state after rollback.

## Verification

Exact fresh focused command:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/lockspire/storage/client_lifetime_client_wait_test.exs test/lockspire/storage/client_lifetime_grant_wait_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs --max-failures 1 --timeout 55000
```

Result: **13 tests, 0 failures**.

The race cases use distinct PostgreSQL backend PIDs and require the expected holder to be the contender's observed blocker before advancing the test clock or releasing the holder. The push-delivery callback independently acquires the client and CIBA rows with `NOWAIT`, establishing that delivery occurs after issuance locks are released. Failure-injection assertions verify rollback state and durable counts.

## Execution Tracking

No plan-local commits were created. HEAD remains `1ba71750f51f4431baba23ac3d6e43ba184d055f`; parent-level tracking and final plan integration are pending. This executor did not update STATE.md, ROADMAP.md, or REQUIREMENTS.md. The broader phase verification remains with the parent execution workflow; the assigned focused files were rerun together successfully.

## Deviations from Plan

- The concurrent RFC 8693 test initially assumed validator arrival order. The assertion was made scheduler-independent by tagging each request and matching its validator context to that tag.
- No full `mix test.fast` run was performed in this assigned focused execution; parent workflow owns broader phase verification.

## Self-Check: PASSED

- All four assigned test/helper files exist.
- The recorded parent HEAD matches the current plan base; no plan-local commits were made.
- The exact combined focused test command passed with 13 tests and 0 failures.

Parent implementation commit: `4d2490192204b064a5cbb150f9fb5d427ed189af`; freshparent13tests0failures.
