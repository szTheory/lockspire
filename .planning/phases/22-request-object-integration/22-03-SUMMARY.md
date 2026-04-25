---
phase: 22-request-object-integration
plan: "03"
subsystem: test-infrastructure
tags: [test-helper, jar, jose, rsa]
one_liner: "Shared JOSE plumbing module for JAR test signing and Client JWK construction"

dependency_graph:
  requires: []
  provides:
    - "Lockspire.JarTestHelpers (test/support/jar_test_helpers.ex) — shared test helper for Plans 22-04..22-07"
  affects:
    - "mix.exs — elixirc_paths(:test) now includes test/support"

tech_stack:
  added: []
  patterns:
    - "Plain defmodule test helper (no use ExUnit.Case) — mirrors test/support/endpoint.ex shape"
    - "Keyword opts for sign_jar/3 avoids positional-arg overload ambiguity"

key_files:
  created:
    - test/support/jar_test_helpers.ex
  modified:
    - mix.exs

decisions:
  - "Used keyword opts (:alg, :extra_header) in sign_jar/3 instead of promoting the 4-arity positional sign_jwt/4 from jar_test.exs — avoids callers needing to pass alg just to set extra_header"
  - "mix.exs elixirc_paths(:test) fixed to include test/support — required for the module to compile in the :test env"

metrics:
  duration_minutes: 8
  tasks_completed: 1
  files_created: 1
  files_modified: 1
  completed_at: "2026-04-25T16:16:42Z"
---

# Phase 22 Plan 03: JarTestHelpers Shared Test Module Summary

Shared JOSE plumbing module for JAR test signing and Client JWK construction.

## What Was Built

Created `test/support/jar_test_helpers.ex` (66 lines) — a plain Elixir module with four
public functions that eliminate ~75 lines of duplicated JOSE keypair generation and signing
code across the five upcoming JAR test files (Plans 22-04 through 22-07).

### New File

**`test/support/jar_test_helpers.ex`** — 66 lines

Public API:
- `generate_keys/0` — Generates RSA-2048 keypair, returns `%{private_jwk:, pub_jwk_map:, priv_jwk_map:}`
- `sign_jar/3` — Signs claims map as compact JWT; accepts `:alg` and `:extra_header` opts
- `client_with_single_jwk/1` — Returns `%Client{}` with single inline JWK
- `client_with_jwks_set/1` — Returns `%Client{}` with JWK Set (`%{"keys" => [pub_jwk_map]}`)

### Reuse Footprint

Planned consumers (Wave 2 and 3 plans that will `alias Lockspire.JarTestHelpers`):
- Plan 22-04: `authorization_request_test.exs` JAR validation tests
- Plan 22-05: `pushed_authorization_request_test.exs` JAR-over-PAR tests
- Plan 22-06: `authorize_controller_test.exs` controller integration tests
- Plan 22-07: `phase15_par_authorization_e2e_test.exs` end-to-end tests

Plan 22-01 (Wave 1 parallel) deliberately keeps its existing inline private helpers — it is
independent and out of scope for this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed mix.exs elixirc_paths(:test) to include test/support**
- **Found during:** Task 1 (verification)
- **Issue:** The plan's context stated `elixirc_paths(:test) → ["lib", "test/support"]` at mix.exs:53, but the actual worktree (at base commit a8102eb) had `["lib"]` only. Without the `test/support` path, `jar_test_helpers.ex` would not compile in the :test env.
- **Fix:** Changed `defp elixirc_paths(:test), do: ["lib"]` to `defp elixirc_paths(:test), do: ["lib", "test/support"]`
- **Files modified:** `mix.exs`
- **Commit:** ccd10ed

## Verification Results

- `mix compile` (test env): compiles with 91 files including the new helper (pre-existing warnings in `authorization_request.ex` are out-of-scope, caused by untracked files from parallel worktree agents)
- `Lockspire.JarTestHelpers.__info__(:functions)`: returns all 4 exported functions
- `function_exported?/3` checks: all pass when module is pre-loaded
- `mix test test/lockspire/protocol/jar_test.exs`: 41 tests, 0 failures (no regressions)
- File line count: 66 (under 100-line limit per plan verification criteria)

## Threat Surface Scan

No new production trust boundaries introduced. The module is compiled only in `:test` env
via `elixirc_paths(:test)`. Ephemeral RSA-2048 keypairs are generated at test-time only and
never persisted. No new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- [x] `test/support/jar_test_helpers.ex` exists (66 lines)
- [x] `mix.exs` modified with `test/support` in elixirc_paths(:test)
- [x] Commit `ccd10ed` exists in git log
- [x] `defmodule Lockspire.JarTestHelpers` — 1 match on line 1
- [x] `def generate_keys` — 1 match
- [x] `def sign_jar` — 1 match
- [x] `def client_with_single_jwk` — 1 match
- [x] `def client_with_jwks_set` — 1 match
- [x] `alias Lockspire.Domain.Client` — 1 match
- [x] No unexpected file deletions in commit
