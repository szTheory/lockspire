# Phase 173: Conditional PAR & Profile Boundaries - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 3 code/test files, plus retained proof owners noted below
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/authorization_request.ex` | service | request-response | same file: `resolve_authorization_params/2` and `pushed_request_to_params/1` | exact |
| `test/lockspire/protocol/authorization_request_test.exs` | test | request-response | same file: required PAR, lifecycle, blanket-conflict and collision tests | exact |
| `test/integration/phase15_par_authorization_e2e_test.exs` | test | request-response | same file: real `/par` then `/authorize` flow | exact |

## Pattern Assignments

### `lib/lockspire/protocol/authorization_request.ex` (service, request-response)

**Analog:** This file's existing resolver and stored-request reconstruction.

The authorization pipeline resolves client and current PAR/security policies before resolving parameters and applying the existing validation pipeline (lines 91-113):

```elixir
{:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
{:ok, resolved_security_profile} <- resolve_effective_security_profile(client),
:ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy, resolved_security_profile),
{:ok, resolved_params} <- resolve_authorization_params(params, client),
:ok <- ensure_app_eligible(resolved_params, client, opts),
{:ok, %Validated{} = validated} <- validate_with_client(resolved_params, client,
  security_profile: resolved_security_profile
)
```

For a `request_uri`, the resolver currently checks distinct `request` collision, then blanket outer conflicts, prefix, and one-use consumption, returning the reconstructed pushed map (lines 318-327). The separate request-object collision is at lines 331-347. The blanket gate is `reject_request_uri_conflicts/1` (lines 871-889); it is the narrow correction point. Preserve the stored-only reconstruction, which creates a fresh map from stored client, redirect, scopes, nonce, state, PKCE, response mode and other accepted fields (lines 930-947). Preserve the existing consume helper and its invalid-reference mapping (lines 904-928).

### `test/lockspire/protocol/authorization_request_test.exs` (test, request-response)

**Analog:** Existing focused protocol PAR tests in this same file.

The required-PAR test demonstrates a valid reference remains accepted and canonical validated fields are asserted (lines 474-486). The single-use and canonical contract tests cover binding, stored fields, and replay (lines 488-529). Reconcile only the obsolete blanket expectation at lines 682-694. Keep the distinct `request` plus `request_uri` rejection at lines 771-790:

```elixir
assert {:browser_error, %Error{} = error} =
         AuthorizationRequest.validate(%{
           "client_id" => client.client_id,
           "request" => request_jwt,
           "request_uri" => pushed_request.request_uri
         })

assert error.reason_code == :request_object_and_request_uri_conflict
```

### `test/integration/phase15_par_authorization_e2e_test.exs` (test, request-response)

**Analog:** The existing Phase 15 real-router PAR flow in this file.

The test module uses synchronous ExUnit, Phoenix connection helpers, and the repository (lines 1-17), with a host account resolver fixture (lines 18-53). Its existing flow sends form parameters through `/par`, checks the returned reference, then calls `/authorize` through `Lockspire.Web.Router` (lines 132-159). It currently recognizes consent by a substring and extracts the final path segment (lines 161-176); the new regression should use exact parsed relative route recognition, then use `Repository.fetch_interaction/1` and assert exact client/scopes/state/nonce.

```elixir
par_conn =
  build_conn(:post, "/par", pushed_params)
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

assert par_conn.status == 201
par_response = Jason.decode!(par_conn.resp_body)
assert request_uri = par_response["request_uri"]

authorize_conn =
  build_conn(:get, "/authorize", %{"client_id" => client.client_id, "request_uri" => request_uri})
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

Use two successful PAR POSTs in sequence: a reference-only positive control, then a distinct candidate reference with conflicting outer `scope`. This avoids consuming the candidate's one-use reference in the control. Compare the persisted projection using `Interaction` fields `client_id`, `scopes_requested`, `state`, and `nonce` (`lib/lockspire/domain/interaction.ex:10-29,43-63`) via `Repository.fetch_interaction/1` (`lib/lockspire/storage/ecto/repository.ex:192-195`).

## Shared Patterns

### PAR lifecycle and policy boundaries

**Sources:** `lib/lockspire/protocol/authorization_request.ex:91-113,904-947`; `test/lockspire/protocol/authorization_request_test.exs:288-364,366-510,488-679`.

Retain current client/policy resolution, reference validation, atomic consume, client binding, expiry, one-use behavior, wrong-client burn behavior, required-PAR, strict profile and S256 PKCE coverage. Validate the reconstructed stored map through the existing policy pipeline. Do not merge outer parameters into that map. The distinct `request` plus `request_uri` guard remains independently enforced.

### Durable evidence and retained owners

The durable regression belongs in the Phase 15 integration owner. Reuse existing P171-001/002/003 lifecycle, P171-004 required-PAR, P171-006 configured issuer/discovery and Phase 172 response-mode owners; selectively check their existing ledger/selector coverage rather than creating a broad proof framework. Intentional regression-file changes and roadmap selector changes follow the append-only Phase 171 ledger audit described in `173-CONTEXT.md` D-07. Covered reports must be regenerated by their verifier owner.

### Profile availability

Reuse the source-host discovery/metadata proof in `test/lockspire/web/discovery_controller_test.exs` (tracked). Treat external provider-origin, TLS/proxy and browser profiles as unavailable and supplemental; they are not implementation analogs or evidence for this phase.

## No Analog Found

None for the three code/test files. Phase summary/verification and qualification ledger updates are evidence artifacts whose procedure is specified by phase context; they do not introduce a source-code pattern.

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/domain`, `lib/lockspire/storage/ecto`, `test/lockspire/protocol`, `test/lockspire/web`, `test/integration`
**Tracked-source check:** All named source/test paths were checked with `git ls-files`; no ignored runtime mirror paths are referenced.
**Pattern extraction date:** 2026-10-24
