---
phase: 22-request-object-integration
plan: "01"
subsystem: protocol/jar
tags: [jar, oauth, jwt, security, wr-01, wr-02, wr-03]
reviews_addressed: [WR-01, WR-02, WR-03]

dependency_graph:
  requires: []
  provides:
    - "Jar.verify_signature/2 rejects invalid typ headers (:invalid_typ)"
    - "Jar.validate_claims/2 rejects non-binary aud list entries (:invalid_audience)"
    - "Jar.validate_claims/2 rejects empty aud lists (:invalid_audience)"
    - "Jar.validate_claims/2 enforces :max_age ceiling (:expiration_too_far)"
  affects:
    - "lib/lockspire/protocol/jar.ex"
    - "test/lockspire/protocol/jar_test.exs"

tech_stack:
  added: []
  patterns:
    - "TDD RED/GREEN per-task commit discipline"
    - "Halt-fast on definitive error in Enum.reduce_while (verify_against_keys/2)"
    - "6-tuple parse_opts/1 return for threaded option passing"
    - "Extracted check_not_expired/3 + check_max_age/4 for composability"

key_files:
  modified:
    - lib/lockspire/protocol/jar.ex
    - test/lockspire/protocol/jar_test.exs

decisions:
  - "D-11 (WR-01): check_typ/1 uses case-insensitive whitelist of oauth-authz-req+jwt and jwt; absent typ is permissive (RFC 9101 SHOULD not MUST)"
  - "D-12 (WR-02): strict-list check_audience/2 rejects empty lists and non-binary entries; preserves :invalid_audience atom (no new atom)"
  - "D-13 (WR-03): :max_age threaded as 6th element of parse_opts/1 tuple; check_max_age/4 nil-clause preserves Phase 21 no-ceiling contract"
  - ":invalid_typ halts verify_against_keys/2 immediately (not a try-next-key situation)"

metrics:
  duration_minutes: 5
  tasks_completed: 2
  files_modified: 2
  completed_date: "2026-04-25"
---

# Phase 22 Plan 01: JAR Primitive Security Hardening (WR-01, WR-02, WR-03) Summary

WR-01 typ-header check, WR-02 strict aud-list validation, and WR-03 configurable exp max-age ceiling landed in `Lockspire.Protocol.Jar` via `check_typ/1`, strict `check_audience/2`, and `check_max_age/4` threaded through a 6-tuple `parse_opts/1`.

## What Was Built

### WR-01: typ-header check (T-22-01 — JWT-type confusion)

**Implementation:** `lib/lockspire/protocol/jar.ex` lines 179-183

```elixir
defp check_typ(%{"typ" => typ}) when is_binary(typ) do
  if String.downcase(typ) in ["oauth-authz-req+jwt", "jwt"], do: :ok, else: {:error, :invalid_typ}
end
defp check_typ(_), do: :ok
```

**Splice point:** Inside `verify_with_single_jwk/2` (line ~154), between `JOSE.JWS.to_map/1` call and `{:ok, %__MODULE__{}}` return.

**Halt-fast fix:** `verify_against_keys/2` updated to halt on `{:error, :invalid_typ}` immediately — it is a definitive rejection, not a "try next key" case (important deviation from plan that required a Rule 1 bug fix during GREEN phase).

**Acceptable typ values (case-insensitive):**
- `"oauth-authz-req+jwt"` — canonical RFC 9101 §10.8 value
- `"jwt"` — lowercase legacy interop
- absent `typ` — permissive default (RFC 9101 §10.8 is SHOULD, not MUST)

### WR-02: strict aud-list validation (T-22-05)

**Implementation:** `check_audience/2` list branch replaced at `lib/lockspire/protocol/jar.ex` line ~283

- Rejects `aud == []` with `{:error, :invalid_audience}`
- Rejects lists where `not Enum.all?(aud, &is_binary/1)` with `{:error, :invalid_audience}`
- Preserves existing `:invalid_audience` atom (no new error atom introduced)

### WR-03: :max_age opt / expiration ceiling (T-22-03, T-22-09)

**Implementation:**
- `parse_opts/1` (`lib/lockspire/protocol/jar.ex` line ~240): reads `:max_age`, validates `is_nil(max_age) or (is_integer(max_age) and max_age > 0)`, returns 6-tuple
- `validate_claims/2` with-chain (line ~219): destructures `{:ok, ..., max_age}` from `parse_opts/1`
- `check_expiration/3` → `check_expiration/4` (line ~297): accepts `max_age` arg, delegates to `check_not_expired/3` + `check_max_age/4`
- `check_max_age/4` nil-clause (line 319): `defp check_max_age(_exp, _now_unix, _leeway, nil), do: :ok`
- `check_max_age/4` active clause (line 321): `if exp - now_unix <= max_age + leeway, do: :ok, else: {:error, :expiration_too_far}`

## New Atoms

- `:invalid_typ` — returned by `verify_signature/2` when typ header is present but not in the allowed whitelist
- `:expiration_too_far` — returned by `validate_claims/2` when `exp - now > max_age + leeway`

Both atoms are added to the respective type specs:
- `verify_signature/2 @spec` includes `| :invalid_typ`
- `validate_claims_reason` union includes `| :expiration_too_far`

## Test Count Delta: 41 → 51

| Task | Tests Added | Purpose |
|------|-------------|---------|
| Task 1 (WR-01) | 4 | typ=JWT-bearer rejection, typ=oauth-authz-req+jwt acceptance, typ=jwt acceptance, no-typ permissive |
| Task 2 (WR-02) | 2 | mixed-type aud list rejection, empty aud list rejection |
| Task 2 (WR-03) | 4 | exp exceeds max_age ceiling, exp within ceiling, no max_age opt (Phase 21 contract), negative max_age validation |

## Reviews Addressed

| Review Item | Status |
|------------|--------|
| WR-01 (RFC 9101 §10.8 typ-header check) | Implemented — `check_typ/1` + splice in `verify_with_single_jwk/2` |
| WR-02 (RFC 7519 §4.1.3 aud-list strictness) | Implemented — strict `check_audience/2` list branch |
| WR-03 (configurable exp max-age ceiling) | Implemented — `check_max_age/4` threaded via `parse_opts/1` |

## Decisions Implemented

- **D-11:** WR-01 lands in Phase 22 primitive before HTTP wiring goes live. Maps to `:invalid_typ` (orchestrator maps to `:invalid_request_object_typ` in Plan 22-04).
- **D-12:** WR-02 reuses `:invalid_audience` atom — no new atom added.
- **D-13:** WR-03 threaded through `parse_opts/1` 6-tuple. Default 600s ceiling will be applied by Plan 22-04's orchestrator (configured via Plan 22-02's `Lockspire.Config.jar_max_age_seconds/0`). New `:expiration_too_far` maps to `:invalid_request_object_max_age` in orchestrator (D-14).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `verify_against_keys/2` CaseClauseError on `:invalid_typ`**
- **Found during:** Task 1 GREEN phase (first test run)
- **Issue:** `verify_against_keys/2` only matched `{:ok, _}` and `{:error, :invalid_signature}` in its `case` expression. When `verify_with_single_jwk/2` returned `{:error, :invalid_typ}`, the `case` raised a `CaseClauseError` instead of propagating the error.
- **Fix:** Added `{:error, :invalid_typ} = err -> {:halt, err}` clause to halt-fast on typ rejection (definitive, not try-next-key).
- **Files modified:** `lib/lockspire/protocol/jar.ex`
- **Commit:** 7d9683e (included in GREEN commit)

## Known Stubs

None — all new behavior is fully implemented and pinned by tests.

## Threat Flags

None — all changes are within the plan's stated threat model (T-22-01, T-22-03, T-22-05, T-22-09).

## Self-Check: PASSED

- `lib/lockspire/protocol/jar.ex` — exists and modified
- `test/lockspire/protocol/jar_test.exs` — exists with 51 tests
- Commits 300c696, 7d9683e, 6cefd1a, 2d9a72f — all present in git log
- `mix test test/lockspire/protocol/jar_test.exs` exits 0 with 51 tests, 0 failures
