---
phase: 37-protocol-strictness-conformance
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - .github/workflows/oidf-conformance.yml
  - docs/maintainer-conformance.md
  - docs/supported-surface.md
  - lib/lockspire/domain/interaction.ex
  - lib/lockspire/host/claims.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/protocol/id_token.ex
  - lib/lockspire/protocol/token_exchange.ex
  - lib/lockspire/storage/ecto/interaction_record.ex
  - lib/lockspire/web/controllers/authorize_controller.ex
  - lib/lockspire/web/live/consent_live.ex
  - mix.exs
  - priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs
  - scripts/conformance/phase37-plan.json
  - scripts/conformance/run_phase37_suite.sh
  - test/integration/phase37_protocol_strictness_e2e_test.exs
  - test/lockspire/host/claims_test.exs
  - test/lockspire/protocol/authorization_flow_test.exs
  - test/lockspire/protocol/authorization_request_test.exs
  - test/lockspire/protocol/dpop_test.exs
  - test/lockspire/protocol/id_token_test.exs
  - test/lockspire/protocol/token_endpoint_dpop_test.exs
  - test/lockspire/protocol/token_exchange_test.exs
  - test/lockspire/release_readiness_contract_test.exs
  - test/lockspire/storage/ecto/interaction_record_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/lockspire/web/token_controller_test.exs
  - test/support/generated_host_app/lockspire/test_account_resolver.ex
  - test/support/generated_host_app_web/controllers/session_controller.ex
  - test/support/generated_host_app_web/endpoint.ex
  - test/support/generated_host_app_web/router.ex
findings:
  critical: 4
  warning: 7
  info: 3
  total: 14
status: issues_found
---

# Phase 37: Code Review Report

**Reviewed:** 2026-04-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

This phase adds the Phase 37 OIDC strictness conformance lane: `prompt=none` redirect-safe rejection, durable `max_age`/`auth_time` storage, integer `auth_time` emission in ID tokens, conformance harness scripting, and a GitHub Actions workflow. The core mechanics are sound and the protocol behavior is largely correct. However, several defects were found spanning security, correctness, and quality:

- `decode_term_jwk` in `IdToken` accepts arbitrary Erlang terms from potentially external input, which is a deserialization vulnerability.
- `refresh_scope_policy_allows?/1` in `TokenExchange` is dead-code that always returns `true` regardless of scope, silently defeating the `offline_access` gate.
- `emit_success/2` (arity 2) in `TokenExchange` is a dead private function never called from the public surface.
- The `validate_pkce/2` guard inverts the intended PKCE check — it requires `pkce_required` to be falsy in order to pass, meaning PKCE is rejected for compliant clients.
- Several smaller quality and correctness issues are also documented.

---

## Critical Issues

### CR-01: `decode_term_jwk` deserializes arbitrary Erlang terms from signing key storage

**File:** `lib/lockspire/protocol/id_token.ex:88-92`

**Issue:** `decode_term_jwk/1` calls `:erlang.binary_to_term(binary, [:safe])` on the `private_jwk_encrypted` field of a signing key. The `:safe` flag prevents atoms from being created but does not prevent all code execution vectors. More critically, the function is called as a fallback after JSON decoding fails, meaning _any_ binary retrieved from the key store that is not valid JSON will be passed to `binary_to_term`. Signing keys are infrastructure-controlled data, but the path is still dangerous: if key data is ever attacker-influenced (compromised DB row, import API, migration script), this path executes arbitrary deserialization. The entire `decode_term_jwk` fallback exists only to support the legacy format produced by `run_phase37_suite.sh` line 138 and `test/integration/phase37_protocol_strictness_e2e_test.exs` line 308 which call `:erlang.term_to_binary(jwk_map)`. The test helpers and conformance scripts should encode to JSON, not Erlang terms, and the binary_to_term fallback should be removed.

**Fix:**
```elixir
# Remove decode_term_jwk/1 entirely. Change decode_private_jwk/1 to:
defp decode_private_jwk(binary) when is_binary(binary) do
  case decode_json_jwk(binary) do
    %{} = jwk -> {:ok, jwk}
    nil -> {:error, :invalid_signing_key}
  end
end

# In run_phase37_suite.sh (line ~138) and publish_signing_key helpers in tests,
# replace :erlang.term_to_binary(jwk_map) with Jason.encode!(jwk_map):
private_jwk_encrypted: Jason.encode!(Map.put(jwk, "kid", kid))
```

---

### CR-02: `validate_pkce/2` guard inverts the PKCE requirement check

**File:** `lib/lockspire/protocol/authorization_request.ex:421-424`

**Issue:** The first `cond` branch inside the matching `validate_pkce/2` clause checks `not client.pkce_required` and returns an error when that condition is true. The intent reads as: "reject if PKCE is not required for this client." But the function has already been reached only because the caller supplied a `code_challenge` and `code_challenge_method=S256` — so this branch fires for the _compliant_ case (client has `pkce_required: true`) and passes for the non-PKCE client. In other words, clients with `pkce_required: true` that supply a correct S256 challenge receive `:pkce_required` error; clients with `pkce_required: false` pass this check. This is the exact inverse of the intended behavior.

**Fix:**
```elixir
defp validate_pkce(
       client,
       %{"code_challenge" => challenge, "code_challenge_method" => "S256"} = params
     )
     when is_binary(challenge) and challenge != "" do
  cond do
    # Clients that do NOT require PKCE should not accept it (or just pass through;
    # adjust policy to taste). For clients that DO require PKCE, proceed to
    # challenge validation:
    not valid_code_challenge?(challenge) ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "code_challenge is invalid", :invalid_code_challenge)}

    true ->
      :ok
  end
end

defp validate_pkce(client, params) do
  # Called when code_challenge/S256 absent — reject if required
  if client.pkce_required do
    {:redirect_error,
     redirect_error(params, :invalid_request, "PKCE S256 is required", :missing_pkce)}
  else
    :ok
  end
end
```

Note: confirm with test suite which direction is intended. The existing tests all use `pkce_required: true` and pass `code_challenge`, which means they currently hit this inverted guard. If tests pass, they are either not exercising this path or the guard condition is accidentally correct due to some other structural reason. This deserves careful manual verification.

---

### CR-03: `refresh_scope_policy_allows?/1` always returns `true` — dead offline_access gate

**File:** `lib/lockspire/protocol/token_exchange.ex:859-865`

**Issue:** Both branches of the `if "offline_access" in scopes` expression return `true`. This means the function never gates on `offline_access` scope, and any client that is allowed the `refresh_token` grant type will receive a refresh token regardless of whether the user granted `offline_access`. This silently defeats the `offline_access` OIDC scope gate and may surprise hosts that rely on it.

```elixir
defp refresh_scope_policy_allows?(scopes) when is_list(scopes) do
  if "offline_access" in scopes do
    true
  else
    true   # <-- always true, the else branch is dead code
  end
end
```

**Fix:**
```elixir
defp refresh_scope_policy_allows?(scopes) when is_list(scopes) do
  "offline_access" in scopes
end
```

---

### CR-04: XSS risk in `SessionController.new/2` — user-controlled values interpolated into raw HTML without escaping

**File:** `test/support/generated_host_app_web/controllers/session_controller.ex:13-27`

**Issue:** `html_escape/1` is called in `new/2` for `return_to`, `login`, and `auth_time_seconds_ago`, which is correct. However, the `password` field value is hardcoded as the string literal `"phase37-password"` directly interpolated into the HTML — this is fine in isolation — but the pattern establishes that user-controlled query params `return_to`, `login`, and `auth_time_seconds_ago` drive the pre-filled form values. If `html_escape` is ever removed or a new param added without escaping, XSS follows immediately. This is test-support code exposed to the conformance suite's browser automation, and the OIDF conformance suite browser sends arbitrary values; a reflected XSS here could produce false conformance passes if the suite's browser auto-submits a crafted payload.

More concretely: `return_to` is rendered directly into a hidden input `value` attribute — if `html_escape` does not encode `"` correctly in this context, the attribute can be escaped by an attacker-controlled redirect URL containing `"`. The `Phoenix.HTML.html_escape/1` call does escape `"` as `&quot;`, so the current code is safe. But the function is using `Phoenix.HTML.html_escape` on a value taken from query params with no validation before rendering into a hidden input that drives a POST redirect. A malicious `return_to` value like `javascript:alert(1)` survives `html_escape` and is rendered verbatim as the `action`-equivalent hidden field. Since the form POSTs to `/login`, the `return_to` is later read by `create/2` and passed directly to `redirect(conn, to: return_to)` — this allows open redirect to any path or scheme.

**Fix:**
```elixir
# In create/2, validate return_to before redirecting:
defp safe_return_to(nil), do: "/lockspire/authorize"
defp safe_return_to(""), do: "/lockspire/authorize"
defp safe_return_to("/" <> _ = path), do: path
defp safe_return_to(_), do: "/lockspire/authorize"

# Replace `redirect(conn, to: return_to)` with:
redirect(conn, to: safe_return_to(return_to))
```

---

## Warnings

### WR-01: `emit_success/2` (arity 2) is an unreachable private function

**File:** `lib/lockspire/protocol/token_exchange.ex:696-708`

**Issue:** `emit_success/3` (arity 3) dispatches to `emit_success/2` only from within its own clauses. The arity-2 clause is defined as a private helper called by the arity-3 clauses, so it is reachable. However, looking more carefully, `emit_success/3` at line 710 calls `emit_success(client, authorization_code)` — this is the 2-arity variant — but line 696 defines `defp emit_success(%Client{} = client, %Token{} = authorization_code)`. These are internally consistent. What is flagged is that `emit_success/2` at line 696 is called _only_ from `emit_success/3` at lines 714 and 723, and `emit_success/3` is called from `handle_code_exchange` at line 112 and `redeem_device_authorization` at line 469. The 2-arity overload means it is not truly unreachable. However, there is still an issue: `emit_success/3` at line 710 takes a `%Token{}` as second argument, but `emit_success/3` at line 727 takes a `%DeviceAuthorizationState{}`. Both call `emit_success/2` — but `emit_success/2` at line 696 only matches `%Token{}`. If `emit_device_authorization_success` calls `emit_success/2` with a `DeviceAuthorizationState` argument, the pattern would fail. Trace shows `emit_device_authorization_success` is called instead of `emit_success/2` for device grants. The code is internally coherent, but the overloading pattern is fragile and any future refactor could silently drop observability events. Flag for clarity.

**Fix:** Consolidate or rename to make the dispatch chain explicit. At minimum, add a `@spec` annotation.

---

### WR-02: `Interaction` struct default for `code_challenge_method` is `:S256` regardless of request

**File:** `lib/lockspire/domain/interaction.ex:55`

**Issue:** The struct default is `code_challenge_method: :S256`. This means any `Interaction` created without explicitly setting `code_challenge_method` silently defaults to `:S256` rather than `nil`. When `code_challenge` is absent (e.g., for flows that somehow bypass PKCE), the `code_challenge_method` field carries a misleading non-nil value. If downstream code checks `authorization_code.code_challenge_method != :S256` to detect unsupported methods, a code with no challenge but the default `:S256` method would pass the check. However, in practice, `build_interaction/5` always sets `code_challenge_method` explicitly from `validated.code_challenge_method`, so this default is never used in the happy path. The risk is latent.

**Fix:**
```elixir
code_challenge_method: nil,  # Default to nil; explicitly set from validated request
```

---

### WR-03: Indentation bug in `start_authorization/3` cond block

**File:** `lib/lockspire/protocol/authorization_flow.ex:32-35`

**Issue:** The second branch of the `cond` at line 32 is misindented:

```elixir
      login_required?(validated, subject_context, now) ->
      validated
      |> build_interaction(interaction_id, nil, :pending_login, now)
      |> persist_login_required(opts)
```

The pipeline starting with `validated` at line 33 is not indented under the cond arrow — it aligns with the arrow itself rather than being indented by two more spaces. This is a style violation but more importantly risks being misread as a separate expression. In Elixir this is valid syntax because the parser treats the entire thing as the branch body, but the formatter would rewrite it. Since the project enforces `mix format --check-formatted` in CI (`qa` alias), this suggests `mix format` has not been run on this specific change, or the formatter does not flag this particular layout. If `--check-formatted` passes despite this indentation, it is because Elixir's formatter permits the pipeline on separate lines aligned this way. Still, it is a readability concern for a security-sensitive branch.

**Fix:** Run `mix format` on the file, or manually indent to:
```elixir
      login_required?(validated, subject_context, now) ->
        validated
        |> build_interaction(interaction_id, nil, :pending_login, now)
        |> persist_login_required(opts)
```

---

### WR-04: `exchange_refresh_token/1` swallows all errors without conversion

**File:** `lib/lockspire/protocol/token_exchange.ex:122-129`

**Issue:** The `with` in `exchange_refresh_token/1` has no `else` clause:

```elixir
defp exchange_refresh_token(request) do
  ...
  with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
    {:ok, %Success{} = success} <- RefreshExchange.exchange_refresh_token(client, request) do
    {:ok, success}
  end
end
```

When `authenticate_client/3` returns `{:error, %Error{}}` or `RefreshExchange.exchange_refresh_token/2` returns any error tuple, the `with` falls through and returns the raw error tuple from the failed step. This raw result propagates back to `exchange/1` which expects `{:ok, Success.t()} | {:error, Error.t()}`. If `RefreshExchange` returns a different error shape (e.g., `{:error, :some_atom}`), the caller receives an unexpected shape. The `exchange_authorization_code/1` function properly handles errors with an `else` clause; this function does not.

**Fix:**
```elixir
defp exchange_refresh_token(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))
  authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

  with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
       {:ok, %Success{} = success} <- RefreshExchange.exchange_refresh_token(client, request) do
    {:ok, success}
  else
    {:error, %Error{} = error} ->
      emit_failure(error, params, request)
      {:error, error}
  end
end
```

---

### WR-05: Migration uses `Lockspire.TestRepo.Migrations` module name, not the canonical repo module

**File:** `priv/repo/migrations/20260428220000_add_lockspire_interaction_oidc_fields.exs:1`

**Issue:** The migration module is named `Lockspire.TestRepo.Migrations.AddLockspireInteractionOidcFields`. Ecto migration module names must be unique across the application and conventionally follow `MyApp.Repo.Migrations.*`. Using `TestRepo` in the production migration module name is misleading and will cause confusion when both test and production repos run migrations from the same `priv/repo/migrations/` directory. If the host application runs `mix ecto.migrate` against the production repo, this migration will execute but the module name says `TestRepo`, which is confusing and suggests the migration was only intended for tests.

**Fix:**
```elixir
defmodule Lockspire.Repo.Migrations.AddLockspireInteractionOidcFields do
```

---

### WR-06: `ensure_supported_claims_structure/1` accepts only exact single-key structure — rejects valid OIDC claims documents

**File:** `lib/lockspire/protocol/authorization_request.ex:639-643`

**Issue:**

```elixir
defp ensure_supported_claims_structure(%{
       "id_token" => %{"auth_time" => %{"essential" => true}}
     } = claims)
     when map_size(claims) == 1 do
  :ok
end
```

The guard `map_size(claims) == 1` means that any `claims` document containing both `id_token` and `userinfo` (a perfectly valid OIDC Core § 5.5 structure) is rejected. A request with `{"id_token": {"auth_time": {"essential": true}}, "userinfo": {"email": {"essential": true}}}` would fail with `:invalid_claims_parameter`. The supported-surface doc states that only `id_token.auth_time.essential=true` is supported, but the validation also rejects requests that have that claim present alongside other claims, which is unnecessarily strict and could confuse compliant OIDC clients.

This is a behavior-correctness issue: the rejection may cause conformance failures if a suite test sends a broader but still valid claims document that includes the required `auth_time` claim.

**Fix:** If the intent is to support only `id_token.auth_time.essential=true` and ignore everything else, parse the specific claim and set `auth_time_requested?` accordingly rather than requiring the entire document to be a single-key map. If strict rejection is intentional, document it explicitly.

---

### WR-07: CI alias `conformance.phase37` is absent from `mix ci` — conformance lane is not run in contributor CI

**File:** `mix.exs:94-103`

**Issue:** The `ci` alias (the contributor gate) does not include `conformance.phase37`. The conformance lane is run only by the separate `oidf-conformance.yml` workflow (scheduled or manually triggered). This means a contributor can break `prompt=none` semantics, `max_age` validation, or `auth_time` emission and the breakage will not be caught in normal PR CI. The `mix ci` alias runs `test.fast`, `test.integration`, and `test.phase3`, but not the phase 37 integration tests (`test/integration/phase37_protocol_strictness_e2e_test.exs`). The conformance script requires Docker, which explains why it is not in CI, but the integration test file itself has no such dependency and could be included in `test.integration`.

**Fix:** Add the phase 37 E2E test to `test.integration`:
```elixir
"test.integration": ["test.setup", "test --only integration"],
```
This already picks up `@moduletag :integration` tests. Confirm that `phase37_protocol_strictness_e2e_test.exs` has `@moduletag :integration` (it does, line 3). So the test is already included in `test.integration` — but the `ci` alias runs `test.integration` only once and does not separately call `conformance.phase37`. The OIDF Docker portion is reasonably excluded from PR CI, but verifying this is expected behavior is warranted.

---

## Info

### IN-01: Private signing key stored as Erlang term binary in test helpers and conformance scripts

**File:** `test/integration/phase37_protocol_strictness_e2e_test.exs:308`, `scripts/conformance/run_phase37_suite.sh:138`

**Issue:** Both the integration test helper `publish_signing_key/1` and the bash fixture script use `:erlang.term_to_binary/1` to serialize the JWK map for `private_jwk_encrypted`. This is consistent with the `decode_term_jwk` fallback in `IdToken` (see CR-01), but it creates a tight coupling between serialization format and runtime. If the Erlang/OTP version changes, `binary_to_term` may fail to deserialize older term binaries (version skew). JSON encoding is portable across OTP versions.

**Fix:** Use `Jason.encode!/1` for `private_jwk_encrypted` in all test helpers and the conformance script, and remove the `decode_term_jwk` fallback (see CR-01).

---

### IN-02: `run_phase37_suite.sh` downloads scripts from `master` branch of external repository at runtime

**File:** `scripts/conformance/run_phase37_suite.sh:200-203`

**Issue:** The script fetches `run-test-plan.py`, `conformance.py`, and `test_plan_parser.py` directly from `https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/` at runtime. Pinning to `master` means each run may pick up different versions of the conformance runner, making results non-reproducible across runs. If the upstream conformance suite changes its script interface or adds breaking changes, this will fail without warning.

**Fix:** Pin to a specific tagged release or commit SHA of the conformance suite, or vendor the scripts.

---

### IN-03: `GeneratedHostAppWeb.Router` duplicates `fetch_session` plug — session fetched twice

**File:** `test/support/generated_host_app_web/endpoint.ex:20` and `test/support/generated_host_app_web/router.ex:5`

**Issue:** `GeneratedHostAppWeb.Endpoint` plugs `GeneratedHostAppWeb.FetchSession` (which calls `Plug.Conn.fetch_session/1`) unconditionally on every request. The `:browser` pipeline in the router also plugs `:fetch_session`. This means every browser-pipeline request fetches the session twice. In test context this is harmless but redundant and could cause subtle issues if session state is mutated between the two calls.

**Fix:** Remove `GeneratedHostAppWeb.FetchSession` from the endpoint and rely on the router pipeline's `:fetch_session`, or remove `:fetch_session` from the browser pipeline.

---

_Reviewed: 2026-04-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
