---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
plan: 03
subsystem: auth
tags: [key-encryption, plaintext-refusal, telemetry, logging, leak-test]
status: complete

requires:
  - phase: 156-legacy-migration-kek-rotation-plaintext-refusal
    provides: PrivateJwk.read_stored/2, Admin.Keys.reencrypt/1, encryption_status and the reencrypt Mix task
provides:
  - legacy_plaintext reject mode in PrivateJwk (refusal before any parser)
  - hot-path telemetry legacy_read and decode_failed with deduplicated log lines
  - sentinel leak proof across telemetry, repo query params, audit rows, logs and report
  - corrected ROADMAP and REQUIREMENTS wording
affects: [157 docs sweep, docs/telemetry.md]

actuals:
  tokens: 30000
  tasks: 3
  commits: 6
plan_head_before: 2ad16015d3b46a8ea196cfa7235a5dd3c4a5afe0
plan_head_after: 46cfbdbd58be52cdad476b841952f908affdd633

tech-stack:
  added: []
  patterns:
    - "Hot-path events use :telemetry.execute/3 directly over a fixed allowlisted map through Redaction.for_telemetry/1, never the operator emit helper"
    - "Write-once persistent_term flag keyed by public kid and reason atom gives one log line per node"

key-files:
  created:
    - test/lockspire/security/key_encryption_telemetry_test.exs
    - test/lockspire/security/key_material_leak_test.exs
  modified:
    - lib/lockspire/protocol/private_jwk.ex
    - lib/mix/tasks/lockspire.keys.reencrypt.ex
    - test/support/key_encryption_helpers.ex
    - test/lockspire/protocol/private_jwk_test.exs
    - test/lockspire/protocol/envelope_signing_consumers_test.exs
    - test/mix/tasks/lockspire_keys_reencrypt_test.exs
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "decode_stored/2 refuses on classify == :legacy under a :reject key set before read_stored/2, so neither Jason nor the term parser runs"
  - "decode/1 and decode_with_reason/1 each read the cached key set once; only decode/1 emits events"
  - "Engine queries are sensitive: true, so the leak test proves query logging is active through non-sensitive queries (begin/commit and the key listing) and asserts key material absent from them"

requirements-completed: [MIG-03, OPS-02, MIG-01, MIG-02]

coverage:
  - id: D1
    description: "Under legacy_plaintext reject a non-envelope row is refused before any parser runs; envelope rows keep signing; consumers keep their external error shape"
    requirement: MIG-03
    verification:
      - kind: unit
        ref: "test/lockspire/protocol/private_jwk_test.exs and envelope_signing_consumers_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "legacy_read and decode_failed telemetry with exact metadata, no audit write or mirror, one log line per node per kid and reason"
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "test/lockspire/security/key_encryption_telemetry_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "A refused legacy row is recovered by reencrypt/1 with no config change"
    requirement: MIG-03
    verification:
      - kind: unit
        ref: "test/lockspire/security/key_encryption_telemetry_test.exs#recovery"
        status: pass
    human_judgment: false
  - id: D4
    description: "Sentinel private d and KEK never appear in telemetry, repo query params, audit rows, debug logs or the report"
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "test/lockspire/security/key_material_leak_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "ROADMAP and REQUIREMENTS wording for audit versus telemetry-only events, bin/app rpc and stranded retired keys"
    requirement: MIG-02
    verification: []
    human_judgment: true
    rationale: "Planning prose; checked with grep only"

duration: 14 min
completed: 2026-10-16
---

# Phase 156 Plan 03: Plaintext Refusal and Hot-Path Observability Summary

**`legacy_plaintext: :reject` refuses non-envelope signing keys before any parser runs, with allowlisted `legacy_read` and `decode_failed` telemetry, one log line per node per kid and reason, and a sentinel leak test over every new surface.**

## Accomplishments

- `PrivateJwk.decode_stored/2` refuses legacy rows under `:reject` (including `use: :enc` and a payload that is neither JSON nor ETF); external errors stay `:invalid_signing_key` (`:decryption_failed` for JAR, the existing `server_error` for the access-token signer). JAR moves on to the next key.
- `decode/1` emits `[:lockspire, :key, :legacy_read]` (`%{count: 1}`, metadata `kid`, `legacy_plaintext: :allow`) and `[:lockspire, :key, :decode_failed]` (`kid`, `reason`, `kek_id` only when the envelope header parses). `decode_with_reason/1` and `read_stored/2` stay silent. No audit write, no audit-prefixed mirror.
- Logger: a warning naming the kid and `mix lockspire.keys.reencrypt` on first legacy read (silent with no KEK) and an error naming kid and reason atom on first failure, each once per node per `{kid, reason}` via a write-once `:persistent_term` flag.
- Recovery proven: a refused row is converted by `Admin.Keys.reencrypt/1` with no config change and then decodes.
- Leak test: sentinel `d` and sentinel KEKs (base64 and raw) are absent from key telemetry, repo query `params` and `cast_params`, audit rows, the debug log with repo query logging on, and the report, across legacy read, refusal, four decode-failure reasons, encrypt and re-wrap.
- ROADMAP criteria 1, 2, 5 and the 156-01 bullet, and REQUIREMENTS MIG-01, MIG-02, OPS-02, now carry the corrected wording.
- Phase gate green: `mix qa`, `mix qa.dialyzer`, `test.fast` (1737 tests, 0 failures), `test.integration` (102 tests, 0 failures), the two :integration files outside test/integration (16 tests), `mix test.clean-room.e2e`, and an empty SAFE-01/redaction diff against `32355619`.

## Events for the next phase's docs/telemetry.md

All six `[:lockspire, :key, ...]` events: `encrypted`, `rewrapped`, `reencrypt_failed`, `reencrypt_completed` (from 156-01, 156-02 adds the `:check` mode; each mirrored on `[:lockspire, :audit, :key, action]`), plus the hot-path `legacy_read` and `decode_failed` (telemetry only, no mirror). Durable audit actions: `key_encrypted`, `key_rewrapped`. `Lockspire.Redaction` must keep `kid` and `kek_id` (no drop-list change was made).

## Task Commits

0. Orchestrator fix: `8d2efdcf` fix (pluralize reencrypt failure message)
1. Task 1 (tracer): `8878f7d7` feat (refusal and decode_failed)
2. Task 2: `e359b72b` feat (legacy_read, deduplicated logging, consumers, recovery)
3. Task 3: `3eaa528d` test (leak test), `038b9ab1` docs (wording), `46cfbdbd` fix (dialyzer and credo)

## TDD Notes (Task 2)

Task 2's tests were written and run first: 3 of the new telemetry/log tests failed on the missing behavior (no `legacy_read` event, no log lines); the consumer `:reject` tests already passed because Task 1 shipped refusal. RED and GREEN were committed together in one commit instead of separate `test`/`feat` commits.

## Deviations from Plan

**1. [Orchestrator request] Pluralized reencrypt failure message**
- Mix task printed "1 key were not re-encrypted"; now "1 key was not re-encrypted" / "N keys were not re-encrypted". The failures test asserts the singular form. Commit `8d2efdcf`.

**2. [Rule 3 - Blocking] Dialyzer and credo failures in the phase gate**
- `mix qa.dialyzer` reported `raise_error/1` as having no local return (in the 156-02 task file) and, after the pluralization change, a `raise_if_failed/3` call that never returns. Replaced the helper with direct `Mix.raise(failure_message(...))` and added `@spec raise_error(term()) :: no_return()`. Credo flagged two `Enum.map |> Enum.join` in the new leak test; switched to `Enum.map_join/3`. Commit `46cfbdbd`.

**3. [Plan adjustment] Leak-test log assertion**
- Engine queries are `sensitive: true`, so Ecto does not log them (this is the mitigation). The "log is not vacuous" check therefore matches `QUERY (OK|ERROR)` plus the non-sensitive `FROM "lockspire_signing_keys"` listing query, not `FOR UPDATE`.

**Total deviations:** 3 (1 requested, 1 blocking auto-fix, 1 test adjustment). **Impact:** none on scope.

## Scope notes

- The `result` field of repo query events is not covered by the leak test: every signing-key read returns the stored column there, which predates this phase.
- `@moduletag :capture_log` was added to `private_jwk_test.exs` to keep the new error lines out of test output.
- Commits landed on local `main` as the orchestrator confirmed; nothing was pushed. Pre-existing uncommitted `.planning/config.json` and `.planning/state.json` changes were left alone.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes; SAFE-01 diff empty.

## Self-Check: PASSED

Files present: both new security tests and this summary. Commits `8d2efdcf`, `8878f7d7`, `e359b72b`, `3eaa528d`, `038b9ab1`, `46cfbdbd` are ancestors of HEAD.
