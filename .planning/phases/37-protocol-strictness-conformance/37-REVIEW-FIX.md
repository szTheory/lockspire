---
phase: 37-protocol-strictness-conformance
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/37-protocol-strictness-conformance/37-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 10
skipped: 1
status: partial
---

# Phase 37: Code Review Fix Report

**Fixed at:** 2026-04-28T00:00:00Z
**Source review:** .planning/phases/37-protocol-strictness-conformance/37-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (CR-01 through CR-04, WR-01 through WR-07)
- Fixed: 10
- Skipped: 1

## Fixed Issues

### CR-01: decode_term_jwk Erlang deserialization fallback removed

**Files modified:** `lib/lockspire/protocol/id_token.ex`, `test/integration/phase37_protocol_strictness_e2e_test.exs`, `scripts/conformance/run_phase37_suite.sh`
**Commit:** a980b8b
**Applied fix:** Removed `decode_term_jwk/1` and the `binary_to_term` fallback path from `decode_private_jwk/1`. The function now only accepts JSON-encoded JWK data and returns `{:error, :invalid_signing_key}` for any non-JSON binary. Updated `publish_signing_key/1` in the E2E test helper and the conformance script to use `Jason.encode!` instead of `:erlang.term_to_binary`.

---

### CR-02: validate_pkce guard inversion fixed

**Files modified:** `lib/lockspire/protocol/authorization_request.ex`
**Commit:** 4cc2d61
**Applied fix:** Removed the inverted `not client.pkce_required` guard from the S256-present clause — this guard incorrectly rejected clients with `pkce_required: true` when they correctly supplied a challenge, and silently passed clients with `pkce_required: false`. The first clause now validates only the challenge itself. The fallback clause (no S256 challenge present) checks `client.pkce_required` and returns `:missing_pkce` only when the client requires PKCE.

Note: requires human verification — this is a logic inversion fix and the test suite uses `pkce_required: true` throughout, so tests pass under both the buggy and fixed code. Manual confirmation of the intended policy is recommended.

---

### CR-03: refresh_scope_policy_allows?/1 always-true fixed

**Files modified:** `lib/lockspire/protocol/token_exchange.ex`
**Commit:** 6492fca
**Applied fix:** Replaced the `if/else` expression where both branches returned `true` with a direct `"offline_access" in scopes` membership check. Clients without `offline_access` in their granted scopes will no longer receive a refresh token.

---

### CR-04: safe_return_to guard added to SessionController

**Files modified:** `test/support/generated_host_app_web/controllers/session_controller.ex`
**Commit:** 03ac58b
**Applied fix:** Added `safe_return_to/1` private function with four clauses: `nil` and `""` fall back to `/lockspire/authorize`; paths starting with `/` are accepted as-is; all other values (absolute URLs, javascript: schemes, etc.) fall back to `/lockspire/authorize`. Replaced the direct `redirect(conn, to: return_to)` call in `create/2` with `redirect(conn, to: safe_return_to(return_to))`.

---

### WR-01: @spec added to emit_success/2

**Files modified:** `lib/lockspire/protocol/token_exchange.ex`
**Commit:** ac3f3db
**Applied fix:** Added `@spec emit_success(Client.t(), Token.t()) :: :ok` annotation above the arity-2 `emit_success` private function in `TokenExchange`.

---

### WR-02: Interaction code_challenge_method default changed to nil

**Files modified:** `lib/lockspire/domain/interaction.ex`
**Commit:** 533caaf
**Applied fix:** Changed the `Interaction` struct default for `code_challenge_method` from `:S256` to `nil`. All call sites set the field explicitly from validated request data, so the default is never used in normal flow.

---

### WR-03: start_authorization/3 cond branch indentation fixed

**Files modified:** `lib/lockspire/protocol/authorization_flow.ex`
**Commit:** 3209941
**Applied fix:** Indented the pipeline body of the `login_required?` cond branch by two additional spaces so it is visually subordinate to the arrow, matching standard Elixir cond formatting.

---

### WR-04: else clause added to exchange_refresh_token/1

**Files modified:** `lib/lockspire/protocol/token_exchange.ex`
**Commit:** 2e2d3cc
**Applied fix:** Added an `else` clause to the `with` expression in `exchange_refresh_token/1` that matches `{:error, %Error{} = error}`, calls `emit_failure/3` for observability, and returns `{:error, error}`. Also aligned the two `with` arms to consistent four-space indentation.

---

### WR-05: Migration module renamed from TestRepo to Repo namespace

**Files modified:** `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs`
**Commit:** 9dacccc
**Applied fix:** Changed the module name from `Lockspire.TestRepo.Migrations.AddLockspireInteractionOidcFields` to `Lockspire.Repo.Migrations.AddLockspireInteractionOidcFields` to follow Ecto conventions for production migrations.

---

### WR-06: ensure_supported_claims_structure map_size guard removed

**Files modified:** `lib/lockspire/protocol/authorization_request.ex`
**Commit:** e7d5dde
**Applied fix:** Removed the `when map_size(claims) == 1` guard from `ensure_supported_claims_structure/1`. The function now accepts any claims document that contains `id_token.auth_time.essential=true`, regardless of what other top-level keys (such as `userinfo`) are present. This matches OIDC Core § 5.5 compliant requests.

---

## Skipped Issues

### WR-07: Phase 37 E2E tests already included in test.integration

**File:** `mix.exs:94-103`
**Reason:** Verified — no fix required. `phase37_protocol_strictness_e2e_test.exs` has `@moduletag :integration` at line 4, and `test.integration` is defined as `["test.setup", "test --only integration"]` which picks up all files tagged `:integration`. The phase 37 E2E test is already exercised by `mix test.integration` and therefore by the `ci` alias which calls `test.integration`. The OIDF Docker conformance portion (`conformance.phase37`) is correctly excluded from contributor CI.
**Original issue:** CI alias `conformance.phase37` is absent from `mix ci` — conformance lane is not run in contributor CI.

---

_Fixed: 2026-04-28T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
