---
phase: "163"
slug: "app-lifetime-compatible-host-storage"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 163 — Validation Strategy

ExUnit with real PostgreSQL14+ and Ecto Sandbox; config/test.exs. Select installed compatible Elixir/OTP through task-local ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15, without changing host tool configuration.

Quick sampling: focused ExUnit files specified by each plan after every task. Full sampling: MIX_ENV=test mix test.fast after each wave. Real independent PostgreSQL transactions and observed pg_blocking_pids are mandatory for issuance waits. Tests are paired with implementation slices, not deferred to166.

| Requirement | Proof | Command owner |
|---|---|---|
| DCR-05 | v1 registration, zero/unlimited/finite, exact equality, disabled/public state | Registration and eligibility slice |
| DCR-06 | Every selected consumer, final guarded token issuance, signed/opaque caps, no failed-redemption side effects | Consumer and issuance slices |
| DCR-13 | v0 historical dates and atomic promotion; pinned old/candidate package across additive schema | Storage and upgrade slices |
| DCR-14 | Fresh/custom-prefix migrations, custom-store conformance, failclosed dropped state/transaction mismatch | Storage and upgrade slices |

## Wave 0 requirements

New focused tests must be created by their implementing slices: lifetime domain/adapter/registration, consumer matrix, real PostgreSQL concurrency and isolated package upgrade. Existing ExUnit/PostgreSQL infrastructure suffices; no dependencies are added. Planner must replace generic test paths from research with exact executable paths and pair every automated command with observable fails_when.

## Sign-off

Pending independent verification. All phase behavior requires automated evidence, including durable row counts and concrete upgrade processes; no visual/UI verification is applicable. The umbrella lifetime todo remains pending until166.
