---
phase: 101-adoption-demo-re-wire
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - docs/protect-phoenix-api-routes.md
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - priv/templates/lockspire.install/router.ex
  - scripts/demo/adoption_smoke.py
  - test/support/generated_host_app_web/router/lockspire.ex
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 101: Code Review Report

**Reviewed:** 2026-05-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 101 re-wired the adoption demo to prove an end-to-end at+jwt round-trip through `/api/billing/summary`. The audience/resource literal is consistent at `https://billing.acme-ledger.test` across all four RECIPE-01 hash-lock sites plus the 5th golden fixture, and the smoke's new assertions are structurally sound. Two blockers found: a wrong module name in the live adoption demo router that would crash any DPoP-bound request at runtime, and a factually incorrect statement in the documentation that tells integrators `at+jwt` tokens cannot be used with `/userinfo` (the smoke itself contradicts this claim and the code confirms the claim is wrong). Two warnings cover audience assertion fragility and a non-obvious constraint on the Python comment block.

## Critical Issues

### CR-01: Wrong replay-store module in adoption demo router causes runtime crash on DPoP tokens

**File:** `examples/adoption_demo/lib/adoption_demo_web/router.ex:27`

**Issue:** The `dpop_replay_store` option is set to `MyAppWeb.ProtectedApiReplayStore`, but the adoption demo's application namespace is `AdoptionDemoWeb`, not `MyAppWeb`. No module named `MyAppWeb.ProtectedApiReplayStore` is defined anywhere in the adoption demo application. `NimbleOptions.validate!` in `EnforceSenderConstraints.init/1` accepts any atom as a valid value for this option (schema type `{:or, [:atom, :map]}`), so the error is silent at compile/init time. The crash surfaces only when a DPoP-bound access token arrives and `ProtectedResourceDPoP.validate_access/2` calls `dpop_replay_store.record_dpop_proof/1`, raising `UndefinedFunctionError`. Because the smoke script exercises only plain-bearer tokens, the smoke passes despite this latent defect.

**Fix:** Either reference the correct module for the adoption demo, or define the replay store module first. Since no `AdoptionDemoWeb.ProtectedApiReplayStore` module exists in the demo, the canonical fix is to create it (a thin wrapper over `Lockspire.Storage.Ecto.Repository`) and reference it here:

```elixir
  pipeline :lockspire_protected_api do
    plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://billing.acme-ledger.test", enforce_audience: true
    plug Lockspire.Plug.EnforceSenderConstraints,
      dpop_replay_store: AdoptionDemoWeb.ProtectedApiReplayStore
    plug Lockspire.Plug.RequireToken
  end
```

The module `AdoptionDemoWeb.ProtectedApiReplayStore` must implement `record_dpop_proof/1` (or delegate to `Lockspire.Storage.Ecto.Repository`). The equivalent in the test support fixture is `GeneratedHostAppWeb.ProtectedApiReplayStore` defined in `test/support/generated_host_app_web/controllers/protected_api_controller.ex`.

---

### CR-02: Documentation falsely claims at+jwt tokens cannot be used with /userinfo

**File:** `docs/protect-phoenix-api-routes.md:3`

**Issue:** Line 3 states: "Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable." This is factually incorrect. Code analysis shows that both opaque and JWT (`at+jwt`) tokens are persisted in the token store with their SHA-256 hash as the lookup key (see `AccessTokenSigner.issue/3` → `token_exchange.ex` SIGNER-01 comment → `TokenFormatter.hash_token/1`). `Userinfo.fetch_claims/1` calls `TokenFormatter.hash_token(raw_access_token)` and then `token_store.fetch_active_access_token(token_hash)`, which finds the JWT record by hash. The smoke script itself proves this: it issues an `at+jwt` (the default for `acme-ledger-public` whose `access_token_format` falls through to `:jwt`), sends it to `/lockspire/userinfo`, and correctly asserts HTTP 200. The documentation as written would mislead integrators into thinking they need to configure clients to issue opaque tokens to use `/userinfo`, which is false.

**Fix:** Replace the misleading sentence on line 3. The accurate statement is that `/userinfo` performs a hash-based token store lookup and works with both opaque and JWT access tokens. A replacement:

```markdown
Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken`
accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and
`/introspect` validate tokens via a hash-based token store lookup and work with both
`at+jwt` and opaque tokens; they do not accept tokens issued for a different resource
server (audience mismatch) or tokens that have been revoked.
```

The PHASE-102 marker on line 5 appears to be about a separate caveat sentence on line 7 and is unrelated to fixing line 3.

---

## Warnings

### WR-01: Audience assertion in smoke uses Python `in` without type guard — raises TypeError instead of AssertionError on null audience

**File:** `scripts/demo/adoption_smoke.py:266`

**Issue:** The assertion `assert BILLING_RESOURCE in authed_api_json["access_token"]["audience"]` uses Python's `in` operator directly. `api_controller.ex` sets `audience: token.claims["aud"]`, which will be JSON `null` if the `aud` claim is absent from `conn.assigns.access_token.claims`. If `null` reaches Python, `authed_api_json["access_token"]["audience"]` is `None`, and `in None` raises `TypeError: argument of type 'NoneType' is not iterable` rather than an `AssertionError`. The outer `try/except Exception` catches it and exits non-zero, but the error message will be confusing and won't point to the audience assertion. Under normal operation the signer always sets `aud`, so this is a diagnostic quality problem rather than a silent-pass risk. However, it becomes a real problem if the server returns an unexpected response shape (e.g., a non-200 snuck through, or the controller adds a feature flag that omits `audience`).

**Fix:** Wrap the assertion with an explicit type check, or use `assert_contains` idiom:

```python
    audience_list = authed_api_json.get("access_token", {}).get("audience")
    if not isinstance(audience_list, list):
        raise AssertionError(
            f"billing summary: expected access_token.audience to be a list, got {audience_list!r}"
        )
    assert BILLING_RESOURCE in audience_list, (
        f"billing summary: {BILLING_RESOURCE!r} not in audience {audience_list!r}"
    )
```

---

### WR-02: Commented-out Elixir pipeline block in Python smoke script is a required RECIPE-01 hash-lock site with no inline explanation

**File:** `scripts/demo/adoption_smoke.py:247-254`

**Issue:** Lines 247–254 contain a commented-out Elixir pipeline block inside Python source. There is no inline comment explaining why Elixir appears inside Python code. The block is required: `release_readiness_contract_test.exs` extracts it as the `:python_commented` RECIPE-01 site and byte-compares it against the three other canonical sites. Editing or deleting this block (a natural reflex for anyone cleaning up "dead code" in the Python file) would silently break the hash-lock invariant. The `adoption_smoke.py` file will fail the `canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites` contract test, but only when that test suite is run — not at smoke execution time.

**Fix:** Add an explanatory comment immediately before the `BEGIN` marker so the constraint is visible to future editors:

```python
    # RECIPE-01 hash-lock: the pipeline block below must stay byte-identical to the three other
    # canonical sites (docs/protect-phoenix-api-routes.md, adoption_demo router, install template).
    # release_readiness_contract_test.exs extracts this block and verifies consistency.
    # Do NOT edit or delete these lines without updating all four RECIPE-01 sites in lockstep.
    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    # ...
```

---

## Info

### IN-01: Token presence assertion does not verify token_type or format

**File:** `scripts/demo/adoption_smoke.py:235`

**Issue:** `assert token_json["access_token"]` checks only that the field is truthy. It does not verify that the token is a syntactically valid JWT (`header.payload.signature` dot-separated) even though phase 101's stated goal is to prove the end-to-end `at+jwt` round-trip. A server bug that returns an opaque token would pass this assertion, and the audience check at line 266 would also pass if the server embedded the right audience in the response body independently of the token itself.

**Fix:** Add a minimal structural check after the existing assertion:

```python
    assert token_json["access_token"]
    parts = token_json["access_token"].split(".")
    assert len(parts) == 3, (
        f"token exchange: expected a three-part JWT, got {len(parts)}-part token"
    )
```

This ensures the at+jwt contract is verified, not just that some non-empty token was returned.

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
