---
phase: 21-jar-foundation
verified: 2026-04-25T15:01:03Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: null
  previous_score: null
  gaps_closed: []
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "JAR-01: JAR-by-value request objects are accepted by /authorize and /par endpoints"
    addressed_in: "Phase 22"
    evidence: "Phase 22 goal: 'Integrate request objects into the authorization path, allowing them to be passed by value in /authorize and via PAR.' Phase 21 ROADMAP entry maps JAR-01 as foundational coverage; the parsing primitive Lockspire.Protocol.Jar.decode/1 is implemented and verified, but endpoint wiring is explicitly scoped to Phase 22."
---

# Phase 21: JAR Foundation and Request Validation Verification Report

**Phase Goal:** Implement the core logic for parsing and validating JWT request objects, including signature verification and security claims checks.
**Verified:** 2026-04-25T15:01:03Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

The phase goal — implementing core logic for JAR parsing, signature verification, and security claims validation — is fully achieved in `lib/lockspire/protocol/jar.ex`. The module exposes three public functions (`decode/1`, `verify_signature/2`, `validate_claims/2`) covering the three sub-phase contracts. All 41 unit tests pass. Endpoint wiring (taking JAR-by-value over `/authorize` and `/par`) is intentionally out of scope for Phase 21 and is addressed in Phase 22 — this is recorded as a deferred item, not a gap.

### Observable Truths

Must-haves merged from PLAN frontmatter (21-01, 21-02, 21-03). ROADMAP success_criteria array was empty.

| #   | Source | Truth   | Status     | Evidence       |
| --- | ------ | ------- | ---------- | -------------- |
| 1   | 21-01  | JWT request objects can be decoded into a structured Lockspire.Protocol.Jar struct | VERIFIED | `decode/1` at jar.ex:38-54; defstruct at jar.ex:11; runtime probe returned `{:error, :invalid_jwt}` for malformed input and tests assert `{:ok, %Jar{claims: ..., header: ...}}` for valid signed JWT (jar_test.exs:7-16) |
| 2   | 21-01  | Invalid JWT strings are rejected with a clear error | VERIFIED | jar.ex:49-50 catches all rescues and returns `{:error, :invalid_jwt}`; non-binary clause at jar.ex:54; tests for malformed, non-JWT, empty, nil, and map inputs all assert `{:error, :invalid_jwt}` (jar_test.exs:18-31) |
| 3   | 21-02  | JWT request object signatures are verified against the client's public keys | VERIFIED | `verify_signature/2` at jar.ex:73-87 calls `JOSE.JWT.verify_strict/3` with normalised JWKs; positive test at jar_test.exs:56-69 (single JWK) and jar_test.exs:71-81 (JWK Set) |
| 4   | 21-02  | Request objects with invalid signatures are rejected | VERIFIED | jar.ex:150-160 returns `{:error, :invalid_signature}` on verify failure; tests cover wrong-key (jar_test.exs:83-95), alg=none (jar_test.exs:97-108), and tampered payload (jar_test.exs:144-158) |
| 5   | 21-02  | Request objects with missing or unknown keys are rejected | VERIFIED | jar.ex:75-76 returns `:no_matching_key` for empty keys list; jar.ex:86-87 returns `:invalid_client_keys` for nil/non-map jwks; tests at jar_test.exs:110-142 cover nil, non-map, empty map, and invalid-structure jwks |
| 6   | 21-03  | JAR request objects are validated for mandatory claims (iss, aud, exp) | VERIFIED | `validate_claims/2` at jar.ex:191-199 pipelines `check_issuer`, `check_audience`, `check_expiration`; runtime probe with empty claims returned `{:error, :missing_issuer}` confirming wiring; positive test (jar_test.exs:192-194) and missing-claim tests (jar_test.exs:211-250) |
| 7   | 21-03  | Request objects with expired claims are rejected | VERIFIED | `check_expiration/3` at jar.ex:265-282 enforces `exp + leeway > now_unix` (strict-future); tests for past exp (jar_test.exs:253-256) and exp == now boundary (jar_test.exs:258-261) both assert `{:error, :expired_token}` |
| 8   | 21-03  | Request objects with incorrect issuer (iss) or audience (aud) are rejected | VERIFIED | `check_issuer/2` at jar.ex:232-243 returns `:invalid_issuer` on mismatch; `check_audience/2` at jar.ex:245-263 returns `:invalid_audience` on string and list mismatch; tests at jar_test.exs:216-244 |

**Score:** 8/8 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | JAR-01 endpoint wiring: JAR-by-value accepted at `/authorize` and `/par` | Phase 22 | Phase 22 goal in ROADMAP.md: "Integrate request objects into the authorization path, allowing them to be passed by value in `/authorize` and via PAR." Phase 21 implements only the parsing/verification primitive (`Lockspire.Protocol.Jar`); endpoint integration is out of scope per the verification request. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/lockspire/protocol/jar.ex` | JAR data structure, decode logic, signature verification logic, security claims validation logic | VERIFIED | Exists, 321 lines, contains `defstruct [:claims, :header]`, `decode/1`, `verify_signature/2`, `validate_claims/2`. SDK `verify.artifacts` returned `passed: true` for all three plans. |
| `test/lockspire/protocol/jar_test.exs` | Unit tests for JAR decoding (and by extension verification + claims) | VERIFIED | Exists, 371 lines, 41 tests across `describe "decode/1"` (4), `describe "verify_signature/2"` (9), and `describe "validate_claims/2"` (28). `mix test` reports 41 tests / 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `lib/lockspire/protocol/jar.ex` | `jose` | `JOSE.JWT.peek_payload` and `JOSE.JWT.peek_protected` | WIRED | SDK reported "not referenced" because it matches the literal lowercase string `"jose"`; the actual code uses Elixir's qualified module form `JOSE.JWT.peek_payload` (jar.ex:41) and `JOSE.JWT.peek_protected` (jar.ex:42). `:jose` dependency declared in `mix.exs:42` (`{:jose, "~> 1.11"}`). Tests confirm decoding works against JOSE-signed JWTs. |
| `lib/lockspire/protocol/jar.ex` | `Lockspire.Domain.Client` | `client.jwks` | WIRED | `alias Lockspire.Domain.Client` at jar.ex:9; pattern matches `%Client{jwks: jwks}` at jar.ex:73 and `%Client{jwks: _}` at jar.ex:86. SDK `verify.key-links` confirmed. |
| `lib/lockspire/protocol/jar.ex` | `jose` | `JOSE.JWT.verify` | WIRED | SDK literal-string match miss again; actual code uses `JOSE.JWT.verify_strict/3` at jar.ex:144 (the safer variant chosen for explicit algorithm allow-listing — captured in 21-02 SUMMARY decisions). Tests at jar_test.exs:56-159 confirm verify-strict behaviour. |

All three key links are wired in source; the two SDK "not verified" results are false negatives caused by the SDK matching the literal lowercase token `"jose"` rather than the Elixir module form `JOSE.*`.

### Data-Flow Trace (Level 4)

Not applicable. `Lockspire.Protocol.Jar` is a pure-function utility module: it does not render data, fetch from a database, or expose state. Inputs (JWT strings, `%Client{}`, claims maps) are passed in by the caller, and outputs (`{:ok, %Jar{}}` / `{:error, atom}`) are returned. There is no upstream data source to trace inside this phase. Phase 22 will introduce the upstream — request objects taken from HTTP params at `/authorize` and `/par`.

### Behavioral Spot-Checks

| # | Behavior | Command | Result | Status |
| - | -------- | ------- | ------ | ------ |
| 1 | Test suite passes | `mix test test/lockspire/protocol/jar_test.exs` | "41 tests, 0 failures" in 0.6s | PASS |
| 2 | Module compiles cleanly | `mix compile --force` | "Compiling 96 files (.ex); Generated lockspire app" — no errors, only pre-existing unrelated warnings | PASS |
| 3 | Public API is exported | `function_exported?(Jar, :decode, 1)`, `:verify_signature, 2`, `:validate_claims, 2` after `Code.ensure_loaded` | `{true, true, true}` | PASS |
| 4 | `decode/1` rejects malformed input at runtime | `Lockspire.Protocol.Jar.decode("not.a.jwt")` | `{:error, :invalid_jwt}` | PASS |
| 5 | `validate_claims/2` enforces missing iss at runtime | `validate_claims(%Jar{claims: %{}, header: %{}}, expected_client_id: "c", expected_audience: "a")` | `{:error, :missing_issuer}` | PASS |

Note on full project test suite: The user provided context that `test/lockspire/release_readiness_contract_test.exs:250` has a pre-existing failure (stale assertion from v1.3 milestone archival) that is NOT a Phase 21 regression. Phase 21 only modified `lib/lockspire/protocol/jar.ex` and `test/lockspire/protocol/jar_test.exs`; the JAR test file passes 41/41 in isolation, and the release-readiness failure is documented as out-of-scope.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| JAR-01 | 21-01 | "Support JAR-by-value in `/authorize` and `/par`" (REQUIREMENTS.md) | PARTIAL — foundational primitive complete, endpoint wiring deferred to Phase 22 | The parsing primitive `Lockspire.Protocol.Jar.decode/1` exists and is verified. Endpoint wiring (`/authorize` and `/par` accepting `request=<jwt>`) is explicitly scoped to Phase 22 per the verification request and Phase 22's roadmap goal. ROADMAP maps JAR-01 to Phase 21 as foundational coverage. |
| JAR-02 | 21-02 | "Validate request object signatures using client keys" (REQUIREMENTS.md) | SATISFIED | `verify_signature/2` (jar.ex:71-87) uses `JOSE.JWT.verify_strict` with explicit `@allowed_algorithms` (no HMAC, no `none`), normalises single-JWK and JWK-Set client keys, and returns precise error atoms. Tested with 9 cases covering happy paths and every failure mode. |
| JAR-03 | 21-03 | "Enforce mandatory claims (iss, aud, exp) in request objects" (REQUIREMENTS.md) | SATISFIED | `validate_claims/2` (jar.ex:190-202) enforces iss/aud/exp as mandatory, accepts aud as string-or-list per RFC 7519, supports optional nbf/iat with leeway tolerance, and emits per-claim failure atoms. Tested with 28 cases. |

Orphan requirements check: ROADMAP lists JAR-01, JAR-02, JAR-03 for Phase 21. All three are claimed by plans (21-01, 21-02, 21-03 respectively via `requirements:` and `provides:` frontmatter). No orphans.

### Anti-Patterns Found

None. Scans for `TODO|FIXME|XXX|HACK|PLACEHOLDER`, `placeholder|coming soon|not yet implemented`, empty implementations (`return null|return {}`), and stub patterns (`=> {}`) returned no matches in `lib/lockspire/protocol/jar.ex` or `test/lockspire/protocol/jar_test.exs`. The 21-REVIEW.md identifies three hardening warnings (WR-01 typ-header check, WR-02 aud-list strictness, WR-03 max-age bound) and five info-level improvements; per the review, none are critical for the foundation phase, and they are appropriate to address before/during Phase 22 wiring rather than as Phase 21 gaps.

### Human Verification Required

None. All eight observable truths are verifiable through unit tests, source inspection, and runtime probes — none depend on visual rendering, real-time behaviour, or external services. The module is a pure-function library with deterministic inputs/outputs.

### Gaps Summary

No gaps blocking Phase 21 goal achievement.

The phase goal — "Implement the core logic for parsing and validating JWT request objects, including signature verification and security claims checks" — is fully realised in `Lockspire.Protocol.Jar`. The module provides:

1. **Parsing** (`decode/1`) — unverified JWT decoding into a structured `%Jar{}` with claims and header maps.
2. **Signature verification** (`verify_signature/2`) — cryptographic verification against client-registered JWKs with an explicit algorithm allow-list (no `alg=none`, no HMAC algorithm-confusion vector), supporting both single-JWK and JWK-Set client configurations.
3. **Security claims validation** (`validate_claims/2`) — RFC 9101 mandatory-claim enforcement (iss, aud, exp) plus optional nbf/iat with injectable clock and leeway, returning per-claim failure atoms callers can map to OAuth error responses.

The module is not yet wired into `/authorize` or `/par`; that work is scoped to Phase 22 ("Request Object Integration") and is recorded as a deferred item, not a gap. The 21-REVIEW.md highlights three hardening opportunities (typ-header check, aud-list strict-typing, max-age ceiling) that are appropriate to address as Phase 22 prerequisites rather than as foundation-phase gaps.

---

_Verified: 2026-04-25T15:01:03Z_
_Verifier: Claude (gsd-verifier)_
