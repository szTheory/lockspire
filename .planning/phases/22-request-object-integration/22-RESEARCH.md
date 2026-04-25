# Phase 22: Request Object Integration - Research

**Researched:** 2026-04-25
**Domain:** Embedded OAuth/OIDC authorization-request pipeline; RFC 9101 JAR-by-value wiring at `/authorize` and `/par`
**Confidence:** HIGH

## Summary

Phase 22 takes the policy-free JAR primitive shipped in Phase 21 (`Lockspire.Protocol.Jar` — `decode/1`, `verify_signature/2`, `validate_claims/2`) and wires it into the two live HTTP authorization seams (`/authorize` and `/par`) **by value only**. The structural integration story is unusually clean because Phase 15's PAR consumption already established the canonical pattern: a request-shape that arrives in non-flat form is **projected** into the existing flat-params map (`pushed_request_to_params/1` at `authorization_request.ex:452-466`), then handed unchanged to `validate_with_client/3`. JAR mirrors this precedent — JAR claims are projected to the same shape, and the existing scope/PKCE/prompt/redirect/response_type/nonce machinery runs untouched.

The strict-mode parameter posture (D-04, D-07) is the security spine of this phase. RFC 9101 §6.1 explicitly permits — and §10.2 recommends — that the AS treat the request object as a **sealed envelope**: when `request` is present, *only* `client_id` and `request` are honored; everything else outside the JWT is a conflict. This eliminates the entire class of "outer params override the signed request" smuggling vectors and removes the need to design a precedence table. Phase 22 also lands three Phase 21 hardening items (WR-01 typ-header, WR-02 aud-list strictness, WR-03 max_age ceiling) because they become reachable for the first time at this HTTP surface — `private_key_jwt` is already a supported `token_endpoint_auth_method`, so the cross-JWT-confusion vector is real the moment JAR is exposed.

**Primary recommendation:** Add `Lockspire.Protocol.RequestObject` as a sibling orchestrator (not a sub-module of `Jar`) with a single public function `consume/3` returning the same `{:ok, projected_params} | {:browser_error, %Error{}}` shape that the existing `with`-chain in `AuthorizationRequest.validate/1` already speaks. Splice it into `AuthorizationRequest` between `fetch_client/1` and `resolve_authorization_params/2`, and into `PushedAuthorizationRequest.push/1` between `authenticate_client/3` and `validate_request/2`. Land WR-01/WR-02/WR-03 inside `Lockspire.Protocol.Jar` itself (not in the orchestrator), since they are properties of the primitive, not of the wiring.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Integration Seam And Module Layout**
- **D-01:** Add a new orchestrator module `Lockspire.Protocol.RequestObject` that composes `Lockspire.Protocol.Jar.decode/1`, `verify_signature/2`, and `validate_claims/2`. The primitive (`Jar`) stays policy-free; the orchestrator owns client lookup wiring, error mapping, and projection of JAR claims into the existing flat authorization-param shape.
- **D-02:** Splice JAR consumption into `Lockspire.Protocol.AuthorizationRequest` as a pipeline step that runs **before** `validate_with_client/3`. JAR claims are projected into the same param shape that `pushed_request_to_params/1` already produces, then the existing `validate_with_client/3` pipeline (scopes, PKCE, prompt, redirect_uri, response_type, nonce) runs unchanged on the projected map.
- **D-03:** At `/par`, JAR consumption splices into `validate_pushed/2` immediately after `ClientAuth.authenticate/3` returns the authenticated `%Client{}`. The existing `Lockspire.Protocol.PushedAuthorizationRequest.push/1` orchestration shape is preserved; once JAR is consumed, the same `validate_pushed/2` -> `persist_pushed_request/3` flow continues unchanged so the issued opaque `request_uri` works identically downstream.

**Parameter Precedence And Strict-Mode Posture**
- **D-04:** When `request` is present, the only outer authorization params permitted are `client_id` (REQUIRED for client lookup) and `request` itself. Any other outer param is rejected with `error=invalid_request` and `reason_code: :request_object_conflict` — symmetric with the existing `:request_uri_conflict` rule for PAR.
- **D-05:** Outer `client_id` MUST equal the JAR `iss` claim. Mismatch is rejected as `:invalid_request_object_iss` (or fed to `Jar.validate_claims/2` with `expected_client_id: outer_client_id`, which is the existing contract).
- **D-06:** `request` and `request_uri` MUST NOT both be supplied. Both-present is rejected as `error=invalid_request` with `reason_code: :request_object_and_request_uri_conflict`.
- **D-07:** All non-`client_id` authorization params are sourced from the JAR claims. Outer copies are NEVER merged; this preserves the "sealed envelope" property that the JAR signature is meant to guarantee. RFC 9101 §6.1 explicitly permits this stricter behavior; §10.2 recommends it.

**Trust Model And Client-Key Prerequisites**
- **D-08:** v1.4 requires the client to have a non-empty inline `Client.jwks` (single JWK or JWK Set) registered to use JAR-by-value. Absence yields `error=invalid_request_object` with `reason_code: :client_jwks_missing`. `Client.jwks_uri` fetching is **deferred** (Phase 23 or later — needs HTTP cache, retry, and operator-visible failure surface).
- **D-09:** No new per-client opt-in field is added in Phase 22. Per-client policy controls (`request_object_signing_alg`, `require_signed_request_object`, etc.) are explicitly Phase 23 (`JAR-06`) scope.
- **D-10:** At `/par`, `ClientAuth.authenticate/3` continues to run unchanged, and JAR signature verification runs as a **separate, additional** step. A valid JAR does NOT substitute as client authentication. RFC 9126 §2.1's optional substitution path is not adopted in v1.4 — it would require a new `token_endpoint_auth_method`, discovery metadata changes, and admin UX work that is out of milestone scope.

**Phase 21 Hardening Items Landed In Phase 22**
- **D-11:** **WR-01 (typ-header check)** lands in Phase 22. `verify_signature/2` (or a follow-up step) MUST accept only `typ=oauth-authz-req+jwt` (RFC 9101 §10.8 SHOULD) or absent `typ`. Lowercase `jwt` is also accepted for legacy interop. Other `typ` values are rejected as `:invalid_request_object_typ`. This closes the JWT-type-confusion vector that becomes reachable the moment JAR is exposed over HTTP — `private_key_jwt` is already a supported `token_endpoint_auth_method`, so the matching `iss`/`aud`/`exp` shape vector is real.
- **D-12:** **WR-02 (aud-list strictness)** lands in Phase 22. `Jar.validate_claims/2`'s `aud` list branch must reject lists containing non-binary entries. One-line filter; cannot ship a known input-validation gap behind an HTTP surface.
- **D-13:** **WR-03 (`exp` max-age ceiling)** lands in Phase 22. Add a `:max_age` option to `Jar.validate_claims/2` and feed it from a Lockspire config knob (e.g. `:jar_max_age_seconds`, default `600`). The orchestrator passes the configured ceiling on every call. New failure atom: `:invalid_request_object_max_age`.

**Error Semantics And Reason Codes**
- **D-14:** New JAR failure modes map to RFC 9101 `error=invalid_request_object` with distinct `AuthorizationRequest.Error.reason_code` atoms per failure: `:invalid_request_object_jwt` (malformed), `:invalid_request_object_signature`, `:invalid_request_object_typ`, `:invalid_request_object_expired`, `:invalid_request_object_iss`, `:invalid_request_object_aud`, `:invalid_request_object_max_age`, `:invalid_request_object_claims` (other claim-validation failures), `:client_jwks_missing`. Granular atoms preserve telemetry/admin-UX coherence — coarse single-atom errors regress the v1.3 reason-code observability surface.
- **D-15:** Shape-level failures (both `request` and `request_uri` present, conflicting outer params) map to `error=invalid_request` with `reason_code: :request_object_conflict` or `:request_object_and_request_uri_conflict`. These are not "object validation" failures — the request never gets that far.
- **D-16:** Redirect-safety classification mirrors the existing `par_required_request_uri` pattern (authorization_request.ex:170-189). A JAR error is `{:redirect_error, ...}` iff the outer `redirect_uri` is registered for the authenticated client; otherwise `{:browser_error, ...}`. Note: when JAR is rejected before signature verification (e.g. malformed JWT, missing `jwks`), the AS cannot trust JAR-internal `redirect_uri`, so redirect-safety must be evaluated against the OUTER `redirect_uri` only — but per D-04 outer `redirect_uri` is rejected as a conflict, so this case effectively always classifies as `{:browser_error, ...}`. Document this trade-off explicitly so downstream agents do not try to "improve" it.
- **D-17:** Response classification stays inside `Lockspire.Protocol.AuthorizationRequest` (and the new `RequestObject` orchestrator). `AuthorizeController` and `PushedAuthorizationRequestController` remain thin and unchanged in their dispatch shape.

**Unsupported-Params List Handling**
- **D-18:** Remove `request` from `Lockspire.Protocol.AuthorizationRequest.@unsupported_params` and replace with a positive handler. `claims`, `resource`, `response_mode`, and **external** `request_uri` (any value not prefixed with `PushedAuthorizationRequest.request_uri_prefix()`) remain rejected exactly as today. The existing `validate_lockspire_request_uri/1` guard is the canonical seam for the "Lockspire-issued only" rule.

**Verification Style**
- **D-19:** Extend the three existing focused proof surfaces (`authorization_request_test.exs`, `authorize_controller_test.exs`, `phase15_par_authorization_e2e_test.exs`).
- **D-20:** New unit-level coverage for `Lockspire.Protocol.RequestObject` orchestrator and any new `Jar` helpers goes in the existing `test/lockspire/protocol/jar_test.exs` plus a new `test/lockspire/protocol/request_object_test.exs` (only if the orchestrator's surface justifies a separate file; otherwise fold into `authorization_request_test.exs`).
- **D-21:** Do NOT create a parallel `phase22_jar_authorization_e2e_test.exs`. The locked v1.3 verification posture (one canonical end-to-end PAR proof, focused protocol matrix) carries forward.

**Decision-Making Posture**
- **D-22:** Downstream research, planning, and execution agents prefer one decisive recommendation over multiple alternatives presented to the user. Escalate only when a choice materially shifts Lockspire's trust boundaries, supported surface, or milestone scope.

### Claude's Discretion
- The exact internal projection function name, the precise atom for "other claim-validation failures" (suggested `:invalid_request_object_claims`), and whether the orchestrator lives in a sibling module or as a sub-module of `Jar` are all the agent's call as long as the contract above holds.
- The agent may pick the smallest verification matrix that pins each new reason code at the protocol seam plus one redirect-safe and one browser-error proof at the controller seam.
- Lockspire config key naming for the JAR max-age ceiling is the agent's call (suggested `:jar_max_age_seconds`); just keep it consistent with existing `Lockspire.Config` conventions.

### Deferred Ideas (OUT OF SCOPE)
- `JAR-05` discovery metadata (`request_parameter_supported`, `request_object_signing_alg_values_supported`, etc.) — Phase 23.
- `JAR-06` operator/admin policy controls (per-client `require_signed_request_object`, global "JAR required" policy) — Phase 23.
- `JAR-04` JAR decryption — deferred indefinitely.
- `Client.jwks_uri` HTTP fetch + cache + retry — deferred (needs operator-visible failure surface, not in v1.4).
- JAR-by-reference (RFC 9101 §5.2 — `request_uri` pointing to an external JWT URL) — out of milestone scope; v1.4 keeps Lockspire's `request_uri` semantics as Lockspire-issued PAR references only.
- JAR substituting as client authentication at `/par` (RFC 9126 §2.1 optional path) — would require a new `token_endpoint_auth_method`, discovery changes, and admin UX; deferred.
- New `phase22_jar_authorization_e2e_test.exs` mega-suite — explicitly rejected; extend `phase15_par_authorization_e2e_test.exs` instead.
- Tightening `typ` from "permissive (allow absent or `oauth-authz-req+jwt` or `jwt`)" to "required (`oauth-authz-req+jwt` only)" — defer until Phase 24 or v1.5 once interop is proven.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JAR-01 | Support JAR-by-value in `/authorize` and `/par` | Standard Stack (no new deps); Architecture Patterns (RequestObject orchestrator, splice points); Code Examples (projection function); Validation Architecture (full reason-code matrix) |
| WR-01 | Reject JAR with non-conformant `typ` header (RFC 9101 §10.8 cross-JWT confusion) | Code Examples (typ-check helper); Common Pitfalls (private_key_jwt cross-confusion); Validation Architecture (typ test cases) |
| WR-02 | Reject `aud` lists containing non-binary entries (RFC 7519 §4.1.3) | Architecture Patterns (one-line filter inside `check_audience/2`); Validation Architecture (mixed-type list test) |
| WR-03 | Enforce a configurable `exp` max-age ceiling on JAR request objects | Standard Stack (`Lockspire.Config` accessor pattern); Code Examples (`:max_age` keyword option); Common Pitfalls (replay-window finiteness) |

JAR-02 (signature verification) and JAR-03 (mandatory claims) were satisfied in Phase 21; Phase 22 *consumes* them via the orchestrator. JAR-04 / JAR-05 / JAR-06 are explicitly out of scope per CONTEXT.md.
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP request intake (`/authorize`, `/par`) | Phoenix Controller | — | Thin delivery adapter; locked by D-17 to stay unchanged |
| Outer-param shape validation (D-04 conflict, D-06 mutual exclusion) | Protocol (`AuthorizationRequest` / `PushedAuthorizationRequest`) | — | Conflict checks must run before client lookup or JAR processing; same tier as existing `reject_request_uri_conflicts/1` |
| Client lookup (by outer `client_id`) | Protocol → Storage (`Repository.fetch_client_by_id/1`) | — | Existing seam at `authorization_request.ex:108-120`; reused unchanged |
| Client authentication at `/par` | Protocol (`ClientAuth.authenticate/3`) | — | D-10 keeps this independent of and unchanged by JAR processing |
| JWT decode → signature verify → claims validate | Protocol (`Jar` primitive) | — | Pure-function library; no HTTP, no policy, no telemetry |
| JAR orchestration (compose Jar primitives, project to flat-params) | Protocol (`RequestObject` orchestrator) | — | New module; owns wiring concern only — it does NOT own protocol policy |
| Projection of JAR claims → flat-params map | Protocol (`RequestObject`) | — | Mirrors `pushed_request_to_params/1` (PAR) shape so `validate_with_client/3` is invariant |
| Scope / PKCE / prompt / redirect_uri / response_type / nonce validation | Protocol (`validate_with_client/3`) | — | Reused **unchanged** — that's the point of the projection contract |
| Redirect-safety classification (`{:browser_error, ...}` vs `{:redirect_error, ...}`) | Protocol (`AuthorizationRequest`) | — | D-16 carries forward Phase 18's classification posture |
| Telemetry emission with reason_code | `Observability.emit/3` | — | Existing seam in `emit_rejection/3`; new atoms surface automatically |
| Configuration (`:jar_max_age_seconds`) | `Lockspire.Config` | — | Standard accessor pattern (`Application.get_env/3` with default) |
| Error rendering (`{:browser_error, ...}` page vs OAuth redirect) | Phoenix Controller | — | Existing surface in `AuthorizeController.render_browser_error/3` and `redirect_location/1` |

## Standard Stack

### Core (already present — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:jose` | `~> 1.11` | JWT/JWS/JWK handling — `decode/1` and `verify_signature/2` already use `JOSE.JWT.peek_payload`, `JOSE.JWS.peek_protected`, and `JOSE.JWT.verify_strict/3` | The Erlang/Elixir JOSE de facto standard; already on hex 1.11.x; chosen and verified in Phase 21 [VERIFIED: mix.exs:42, jar.ex:41-46, jar.ex:144] |
| `:telemetry` | `~> 1.3` | Reason-code emission via `Observability.emit/3` | Already standard for all v1.3 telemetry [VERIFIED: mix.exs:45] |
| `:phoenix` | `~> 1.8.5` | Controller layer (unchanged) | [VERIFIED: mix.exs:37] |
| Elixir | `~> 1.18` | Compiler / language | [VERIFIED: mix.exs:9] |

**No new packages needed.** Phase 22 is pure wiring + three small Phase 21 hardening additions inside the existing `:jose`-backed primitive.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sibling module `Lockspire.Protocol.RequestObject` | Sub-module `Lockspire.Protocol.Jar.Orchestrator` | A sub-module would couple the policy-free primitive's namespace to its single consumer. Sibling cleanly separates "what JAR is" from "how Lockspire uses JAR". CONTEXT.md grants discretion (D-01 final paragraph); recommend sibling. |
| New shape `{:ok, projected_params}` from orchestrator | Mirror full `AuthorizationRequest.validate/1` result tuple `{:ok, %Validated{}} \| {:browser_error, ...} \| {:redirect_error, ...}` | The orchestrator runs *before* `validate_with_client/3`, so it can't yet return a `%Validated{}`. The right shape is `{:ok, projected_params_map} \| {:browser_error, %Error{}} \| {:redirect_error, %Error{}}` — composes cleanly into the existing `with`-chain. Recommend the latter. |
| Land WR-01 (typ check) in `RequestObject` orchestrator | Land in `Jar.verify_signature/2` itself | The typ check is a property of the JAR primitive (RFC 9101 §10.8 says the request object SHOULD have `typ=oauth-authz-req+jwt`), not of how Lockspire wires it. Putting it in the primitive means future consumers (Phase 23 discovery, hypothetical jwks_uri path) get the protection for free. Recommend `Jar.verify_signature/2`. |

**Installation:** No `mix.exs` changes required.

**Version verification:** `:jose ~> 1.11` is already pinned and was verified in Phase 21. No upgrade needed for Phase 22.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       /authorize HTTP request                           │
│         (params: client_id, request=<JWT>, [no other outer params])     │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
            ┌──────────────────────────────────────┐
            │  AuthorizeController.show/2          │
            │  (thin; unchanged shape per D-17)    │
            └──────────────────────────────────────┘
                                   │
                                   ▼
            ┌──────────────────────────────────────┐
            │  AuthorizationRequest.validate/1     │   ← splice point
            │  with-chain (line 69-83)             │
            └──────────────────────────────────────┘
                                   │
       ┌───────────────────────────┼─────────────────────────────────┐
       ▼                           ▼                                 ▼
  fetch_client/1            NEW: detect_request_object/1?  resolve_authorization_params/2
  (line 108-124)            (gate: request present?)        (line 158-168 — PAR path)
       │                           │ request present                  │
       ▼                           ▼                                  ▼
  %Client{}              ┌────────────────────────────────────┐    raw or PAR-projected
                         │  RequestObject.consume(            │    flat-params
                         │     params, client, opts)          │
                         │                                    │
                         │  1. reject_outer_param_conflicts   │ (D-04: only client_id+request)
                         │  2. reject_request_uri_collision   │ (D-06: not both)
                         │  3. assert client.jwks present     │ (D-08: client_jwks_missing)
                         │  4. Jar.decode/1                   │ (jar.ex:38-54)
                         │  5. Jar.verify_signature/2 + typ   │ (jar.ex:73 + WR-01 new)
                         │  6. Jar.validate_claims/2          │ (jar.ex:191 + max_age WR-03)
                         │       expected_client_id, audience │
                         │       max_age: Config knob         │
                         │  7. project_jar_claims_to_params   │ (mirrors pushed_request_to_params/1)
                         │                                    │
                         │  → {:ok, projected_params}         │
                         │  → {:browser_error, %Error{}}      │
                         │  → {:redirect_error, %Error{}}     │ (only when outer redirect_uri trusted)
                         └────────────────────────────────────┘
                                   │
                                   ▼ {:ok, projected_params}
                         ┌──────────────────────────────────────┐
                         │  validate_with_client/3              │
                         │  (UNCHANGED — line 210-224)          │
                         │  scopes, PKCE, prompt, redirect_uri, │
                         │  response_type, nonce                │
                         └──────────────────────────────────────┘
                                   │
                                   ▼
                            %Validated{}  →  AuthorizationFlow.start_authorization/3


┌─────────────────────────────────────────────────────────────────────────┐
│                       /par HTTP request                                 │
│         (params: client_id, request=<JWT>; Authorization: Basic ...)    │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
       ┌──────────────────────────────────────┐
       │  PushedAuthorizationRequest.push/1   │
       └──────────────────────────────────────┘
                                   │
                                   ▼
       ┌──────────────────────────────────────┐
       │  ClientAuth.authenticate/3           │ ← UNCHANGED (D-10)
       └──────────────────────────────────────┘
                                   │ {:ok, %Client{}}
                                   ▼
       ┌──────────────────────────────────────┐  ← splice point (D-03)
       │  NEW: RequestObject.consume(         │
       │     params, client, opts)            │
       │  same orchestrator as /authorize     │
       └──────────────────────────────────────┘
                                   │ {:ok, projected_params}
                                   ▼
       ┌──────────────────────────────────────┐
       │  AuthorizationRequest.validate_pushed │  ← UNCHANGED
       │  (validate_with_client/3 + opts)      │
       └──────────────────────────────────────┘
                                   │
                                   ▼
                          %Validated{} → persist_pushed_request → opaque request_uri
```

### Recommended Project Structure

```
lib/lockspire/protocol/
├── jar.ex                    # primitive (Phase 21) + WR-01/02/03 hardening (Phase 22)
├── request_object.ex         # NEW: orchestrator composing Jar primitives
├── authorization_request.ex  # gain a request-object detection step before validate_with_client/3
└── pushed_authorization_request.ex  # gain a request-object step after ClientAuth.authenticate/3

test/lockspire/protocol/
├── jar_test.exs              # extend with typ, aud-list non-binary, max_age cases
├── request_object_test.exs   # NEW (only if surface justifies; else fold into authorization_request_test)
└── authorization_request_test.exs  # primary JAR validation matrix at the protocol seam

test/lockspire/web/
└── authorize_controller_test.exs  # one redirect-safe + one browser-error proof for JAR

test/integration/
└── phase15_par_authorization_e2e_test.exs  # surgical extension: /par with JAR-by-value → /authorize
```

### Pattern 1: Orchestrator as Pipeline Step (mirrors PAR consumption)

**What:** The orchestrator is a pure-function pipeline step that takes outer params + authenticated client, and returns either a flat-params map (success) or an `Error` struct with redirect classification (failure). It composes lower-level primitives but adds no protocol policy.

**When to use:** Whenever a non-flat request shape (PAR reference, JAR JWT, future request_uri-by-reference) needs to be normalized into the flat-params shape `validate_with_client/3` expects.

**Example (target signature):**

```elixir
# lib/lockspire/protocol/request_object.ex
defmodule Lockspire.Protocol.RequestObject do
  @moduledoc """
  Orchestrates JAR (RFC 9101) request-object consumption for /authorize and /par.

  Composes `Lockspire.Protocol.Jar.{decode/1, verify_signature/2, validate_claims/2}`
  into a single pipeline step that:

  1. Rejects outer-param conflicts (D-04) and `request`/`request_uri` collisions (D-06).
  2. Asserts the client has inline `jwks` registered (D-08).
  3. Decodes, verifies, and validates the request JWT.
  4. Projects JAR claims into the same flat-params shape `pushed_request_to_params/1`
     produces, so `validate_with_client/3` runs unchanged.

  Out of scope: JAR-by-reference (Lockspire keeps `request_uri` semantics as
  Lockspire-issued PAR references only — see `validate_lockspire_request_uri/1`
  in AuthorizationRequest); JAR decryption (JAR-04 deferred); jwks_uri fetching.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.Jar

  @type result ::
          {:ok, map()}
          | {:browser_error, Error.t()}
          | {:redirect_error, Error.t()}

  @spec consume(map(), Client.t(), keyword()) :: result()
  def consume(params, %Client{} = client, opts \\ []) when is_map(params) and is_list(opts) do
    with :ok <- reject_request_uri_collision(params),         # D-06 (shape-level)
         :ok <- reject_outer_param_conflicts(params),         # D-04 (shape-level)
         {:ok, jwt} <- fetch_request(params),                 # require non-empty `request`
         :ok <- require_client_jwks(client),                  # D-08
         {:ok, %Jar{} = jar} <- verify(jwt, client),          # decode + verify_signature + typ
         :ok <- validate(jar, client, opts),                  # validate_claims w/ max_age
         {:ok, projected} <- project_to_params(jar, params, client) do
      {:ok, projected}
    end
  end

  defp project_to_params(%Jar{claims: claims}, _outer_params, %Client{client_id: cid}) do
    # D-07 sealed envelope: outer params (other than client_id) are NEVER merged.
    {:ok,
     %{
       "client_id" => cid,
       "redirect_uri" => claims["redirect_uri"],
       "response_type" => claims["response_type"],
       "scope" => claims["scope"],
       "prompt" => claims["prompt"],
       "nonce" => claims["nonce"],
       "state" => claims["state"],
       "code_challenge" => claims["code_challenge"],
       "code_challenge_method" => claims["code_challenge_method"]
     }
     |> Enum.reject(fn {_k, v} -> is_nil(v) end)
     |> Map.new()}
  end

  # ... helper functions; full reason_code mapping covered in Code Examples below
end
```

### Pattern 2: Splice Step in Existing `with`-Chain (mirrors PAR resolution)

**What:** Add one new conditional pipeline step to `AuthorizationRequest.validate/1`'s `with`-chain that routes through `RequestObject.consume/3` when `params["request"]` is present.

**Example (splice into existing pipeline):**

```elixir
# lib/lockspire/protocol/authorization_request.ex (modified)
def validate(params) when is_map(params) do
  with {:ok, %Client{} = client} <- fetch_client(params),
       {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
       :ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy),
       {:ok, resolved_params} <- resolve_authorization_params(params, client),
       # NEW: JAR consumption splices in here, BEFORE validate_with_client/3 (D-02)
       {:ok, post_jar_params} <- maybe_consume_request_object(resolved_params, client),
       {:ok, %Validated{} = validated} <- validate_with_client(post_jar_params, client) do
    # ... unchanged
  end
end

defp maybe_consume_request_object(%{"request" => req} = params, %Client{} = client)
     when is_binary(req) and req != "" do
  RequestObject.consume(params, client, jar_opts())
end

defp maybe_consume_request_object(params, _client), do: {:ok, params}

defp jar_opts do
  [
    expected_audience: Config.issuer!(),
    max_age: Config.jar_max_age_seconds(),
    leeway: 5  # small clock-skew tolerance; see Phase 21 plan-03 decision
  ]
end
```

For `/par`, the splice goes inside `PushedAuthorizationRequest.push/1`:

```elixir
# lib/lockspire/protocol/pushed_authorization_request.ex (modified)
def push(request) when is_map(request) do
  params = Map.get(request, :params, Map.get(request, "params", request))
  authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
  now = now(request)

  with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
       # NEW: D-03 — splice immediately after ClientAuth, BEFORE validate_request
       {:ok, post_jar_params} <- maybe_consume_request_object(params, client),
       {:ok, %AuthorizationRequest.Validated{} = validated} <- validate_request(post_jar_params, client),
       {:ok, %PushedAuthorizationRequestState{} = pushed_request} <-
         persist_pushed_request(validated, request, now) do
    # ... unchanged
  end
end
```

### Pattern 3: Reason-Code Mapping with Redirect-Safety Classification

**What:** Each Jar failure atom maps 1:1 to an `AuthorizationRequest.Error` reason_code. The error is classified `{:redirect_error, ...}` only if the OUTER `redirect_uri` is registered for this client — but per D-04, an outer `redirect_uri` IS a conflict (rejected at the orchestrator's first step), so JAR-validation failures ALWAYS surface as `{:browser_error, ...}`.

**Example mapping table (apply inside the orchestrator):**

| Jar primitive returns | RequestObject reason_code | OAuth `error` | Classification |
|----------------------|---------------------------|---------------|----------------|
| `Jar.decode/1 → {:error, :invalid_jwt}` | `:invalid_request_object_jwt` | `invalid_request_object` | `:browser_error` |
| `Jar.verify_signature/2 → {:error, :invalid_signature}` | `:invalid_request_object_signature` | `invalid_request_object` | `:browser_error` |
| `Jar.verify_signature/2 → {:error, :invalid_typ}` (NEW WR-01) | `:invalid_request_object_typ` | `invalid_request_object` | `:browser_error` |
| `Jar.verify_signature/2 → {:error, :no_matching_key}` | `:invalid_request_object_signature` | `invalid_request_object` | `:browser_error` |
| `Jar.verify_signature/2 → {:error, :invalid_client_keys}` (when `client.jwks` missing/malformed) | `:client_jwks_missing` | `invalid_request_object` | `:browser_error` |
| `Jar.validate_claims → {:error, :missing_issuer \| :invalid_issuer}` | `:invalid_request_object_iss` | `invalid_request_object` | `:browser_error` |
| `Jar.validate_claims → {:error, :missing_audience \| :invalid_audience}` | `:invalid_request_object_aud` | `invalid_request_object` | `:browser_error` |
| `Jar.validate_claims → {:error, :missing_expiration \| :invalid_expiration \| :expired_token}` | `:invalid_request_object_expired` | `invalid_request_object` | `:browser_error` |
| `Jar.validate_claims → {:error, :expiration_too_far}` (NEW WR-03) | `:invalid_request_object_max_age` | `invalid_request_object` | `:browser_error` |
| `Jar.validate_claims → {:error, :invalid_not_before \| :invalid_issued_at \| :invalid_claims_options}` | `:invalid_request_object_claims` | `invalid_request_object` | `:browser_error` |
| Outer-param conflict (D-04) | `:request_object_conflict` | `invalid_request` | `:browser_error` |
| `request` + `request_uri` both present (D-06) | `:request_object_and_request_uri_conflict` | `invalid_request` | `:browser_error` |

### Anti-Patterns to Avoid

- **Merging outer params into JAR claims.** Breaks the sealed-envelope guarantee (D-07). Project ONLY from JAR claims; outer `client_id` is the sole exception and is used only for client lookup and `iss` cross-check.
- **Hand-rolling JWT decoding.** Phase 21 already chose `:jose`; reuse `Jar` primitives.
- **Adding response classification logic to the controller.** D-17 keeps `AuthorizeController` thin; the orchestrator and `AuthorizationRequest` own classification.
- **Building a parallel e2e test file.** D-21 explicitly forbids `phase22_jar_authorization_e2e_test.exs`. Extend `phase15_par_authorization_e2e_test.exs` surgically.
- **Treating `Jar.validate_claims/2`'s `:invalid_claims_options` as a 4xx user-facing error.** It indicates a programming error in the orchestrator (e.g., not passing `expected_audience`). Should never reach the client; if it does, log it but still return `:invalid_request_object_claims`.
- **Calling the JAR-internal `redirect_uri` "trusted" before signature verification.** D-16: redirect-safety must use the OUTER `redirect_uri`, but D-04 makes outer `redirect_uri` a conflict — so JAR-rejection paths classify as `:browser_error`. Don't try to be clever.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWT segment parsing | Custom base64+JSON splitter | `JOSE.JWT.peek_payload/1`, `JOSE.JWS.peek_protected/1` (in `Jar.decode/1`) | Edge cases around base64url padding, segment count, JSON re-encoding canonicalization. Already done in Phase 21. |
| Signature verification with allow-listed algorithms | Custom alg=none rejection | `JOSE.JWT.verify_strict/3` with explicit `@allowed_algorithms` (in `Jar.verify_signature/2`) | The `verify_strict` variant takes the allow-list as an arg — no risk of accidentally calling a `verify` overload that honors header alg. Already done in Phase 21. |
| Audience claim validation (string OR list) | Custom branching | `Jar.validate_claims/2`'s `check_audience/2` (jar.ex:245-263) | RFC 7519 §4.1.3 allows both forms. Already correct in Phase 21; Phase 22 just tightens list-element typing (WR-02). |
| Clock-skew tolerance | Add seconds in caller | `:leeway` opt on `Jar.validate_claims/2` | Symmetric application to exp/nbf/iat — easy to get wrong by hand. Already in Phase 21. |
| JWK Set vs single JWK normalization | Custom dispatch | `Jar.verify_signature/2`'s `extract_public_keys/1` | Phase 21 plan-02 `21-02-SUMMARY.md` documents this caught a real JOSE behavior gap; reuse it. |
| Reason-code observability | Custom logger | `Lockspire.Observability.emit/3` (in `AuthorizationRequest.emit_rejection/3`) | Already redacts and double-emits to audit + telemetry prefixes. New reason_code atoms surface automatically. |
| OAuth error response shape | Custom error structs | `Lockspire.Protocol.AuthorizationRequest.Error` (line 49-63) | Free-form `reason_code` atom + `error` (wire field) + `error_description` + `redirect_uri` + `state`. New atoms slot in without struct changes (verified explicitly in CONTEXT.md code_context). |
| Configuration accessor | `Application.get_env/2` scattered | `Lockspire.Config` accessor function (`config.ex:38-42` shows the pattern for `known_scopes/0`) | Centralized, testable, defaults visible in one place. Add `jar_max_age_seconds/0` here. |

**Key insight:** Every primitive Phase 22 needs already exists. The phase is wiring + three small primitive additions. No custom JWT, no custom error envelopes, no custom config layer.

## Common Pitfalls

### Pitfall 1: Outer-param smuggling via "merge with JAR claims"

**What goes wrong:** Implementer reads RFC 9101 §6.1 ("the request object is the source of truth") and decides to *merge* outer params into JAR claims, with the JAR winning conflicts. This sounds reasonable but breaks the sealed envelope: an attacker who steals a signed JAR can append outer params (e.g., `prompt=none`) and influence the AS even though the JAR signature is valid.

**Why it happens:** The looser interpretation is permitted by RFC 9101 §6.1; the stricter "ignore outer entirely" is in §10.2 as a recommendation, not a MUST. Implementer doesn't read §10.2.

**How to avoid:** D-07 is non-negotiable: outer copies are NEVER merged. The orchestrator's projection function takes ONLY `client_id` from outer params (for lookup + `iss` cross-check); everything else comes from `jar.claims` exclusively.

**Warning signs:** Code in `project_to_params/2` reads from `outer_params` for any field except `client_id`. Tests that supply both outer and JAR copies of the same param.

### Pitfall 2: JWT-type confusion via `private_key_jwt` token endpoint assertions

**What goes wrong:** Lockspire already supports `private_key_jwt` as a `token_endpoint_auth_method` placeholder (well, the atom is in `Client.token_endpoint_auth_method` type spec — not yet a runtime auth method, but the namespace is reserved). When/if a client signs a `private_key_jwt` for `/token`, the resulting JWT has `iss=client_id`, `aud=server-token-endpoint`, and `exp` in the near future — exactly the JAR shape minus `typ`. Without WR-01, an attacker who replays such a JWT to `/authorize?request=...` would pass `verify_signature` and `validate_claims` and the AS would treat it as a request object.

**Why it happens:** Phase 21 deliberately deferred the typ-header check (21-REVIEW.md WR-01). It only becomes exploitable when JAR is reachable from HTTP — which is exactly Phase 22.

**How to avoid:** Land WR-01 in `Jar.verify_signature/2` (or as an immediate follow-up step). Permissive mode: allow absent `typ`, allow `oauth-authz-req+jwt`, allow lowercase `jwt` (legacy interop). Reject everything else. The 21-REVIEW.md `check_typ/1` snippet is the recommended shape.

**Warning signs:** No test in `jar_test.exs` that signs a JWT with `typ=JWT-bearer` (or any non-`oauth-authz-req+jwt`/`jwt` typ) and asserts rejection.

### Pitfall 3: Treating "missing `client.jwks`" as a generic key-load failure

**What goes wrong:** `Jar.verify_signature/2` returns `{:error, :invalid_client_keys}` for both "client has no `jwks` field configured at all" (operator should register a JWK) AND "client has `jwks` but it's malformed" (debug it). Conflating these gives bad operator UX.

**Why it happens:** The Phase 21 primitive lumps them. The orchestrator MUST disambiguate.

**How to avoid:** In the orchestrator, add an explicit `require_client_jwks(client)` step BEFORE calling `Jar.verify_signature/2`. If `client.jwks` is `nil` or empty, return `:client_jwks_missing` (D-08). Only an `{:error, :invalid_client_keys}` from `Jar.verify_signature/2` after the explicit check passes implies a malformed JWK — log internally; map to `:invalid_request_object_signature` outward to avoid leaking malformedness signal.

**Warning signs:** Any code path where `:invalid_client_keys` from `Jar` reaches the OAuth wire surface as `:client_jwks_missing` *without* the orchestrator's prior nil-check.

### Pitfall 4: Forgetting `request` is currently in `@unsupported_params`

**What goes wrong:** Without removing `request` from `@unsupported_params` (line 15), the existing `reject_unsupported_params/1` (line 472-486) intercepts JAR-by-value before the new orchestrator can run. Tests pass with raw params; integration test fails with `:unsupported_request`.

**Why it happens:** The current code treats `request` as Phase-21-deferred. Phase 22 must change `@unsupported_params` to `~w(claims resource response_mode)` (drop `request` and `request_uri` — `request_uri` is handled separately by `validate_lockspire_request_uri/1` AND it's gating logic earlier in the pipeline at line 158).

**How to avoid:** Plan a single explicit step "remove `request` from `@unsupported_params`" with a unit test that specifically asserts `params["request"] = "<JWT>"` does NOT trigger `:unsupported_request`. D-18 calls this out.

**Warning signs:** Any execution where a happy-path JAR test fails with `error_description = "request is not supported"` and `reason_code = :unsupported_request`.

### Pitfall 5: Using `expires_at - now` instead of `exp - now` for max-age

**What goes wrong:** Implementer of WR-03 conflates the JAR `exp` claim (issued by the client) with Lockspire's PAR `expires_at` (issued by Lockspire). Adds the max-age check on the wrong field, or against the wrong base time.

**Why it happens:** Two adjacent expiration concepts (PAR-issued vs JAR-claim) with similar names.

**How to avoid:** WR-03 belongs entirely inside `Jar.validate_claims/2` and operates on the JAR `exp` claim. The check is `exp - now <= max_age + leeway` (per 21-REVIEW.md WR-03). PAR's `expires_at` is unrelated and untouched.

**Warning signs:** Any code in `RequestObject` (orchestrator) that reads `expires_at`. The orchestrator should pass `max_age:` opt and let `Jar` handle it.

### Pitfall 6: Replay protection assumed to be free

**What goes wrong:** A signed JAR with `exp = now + 600s` is replay-able for 10 minutes by anyone who intercepts it. Implementer assumes signature + claims validation provides replay protection.

**Why it happens:** RFC 9101 doesn't require `jti` for request objects. Phase 21 plan-03 explicitly noted "no jti cache" in 21-REVIEW.md IN-04.

**How to avoid:** v1.4 does NOT add a JTI cache (out of scope). The phase MUST document this in the orchestrator's `@moduledoc` so future readers don't think replay is solved. The mitigation in v1.4 is `:jar_max_age_seconds = 600` (default); shorter values reduce the replay window.

**Warning signs:** None at runtime; this is a documentation discipline issue. Plan must include "add @moduledoc note about jti not being cached".

## Code Examples

Verified patterns from existing Lockspire code (file:line references):

### Example 1: Pipeline composition with `with` and tagged-tuple errors

```elixir
# Source: lib/lockspire/protocol/authorization_request.ex:69-92
def validate(params) when is_map(params) do
  with {:ok, %Client{} = client} <- fetch_client(params),
       {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
       :ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy),
       {:ok, resolved_params} <- resolve_authorization_params(params, client),
       {:ok, %Validated{} = validated} <- validate_with_client(resolved_params, client) do
    validated = %Validated{validated | client: client}

    Observability.emit(:authorization_request_accepted, %{}, %{
      client_id: client.client_id,
      redirect_safe: true
    })

    {:ok, validated}
  else
    {:browser_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, false)
      {:browser_error, error}

    {:redirect_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, true)
      {:redirect_error, error}
  end
end
```

The new `RequestObject.consume/3` MUST return one of three shapes (`:ok`, `:browser_error`, `:redirect_error`) so this `with`-chain absorbs it without restructuring.

### Example 2: Existing PAR projection (the canonical "non-flat → flat-params" pattern)

```elixir
# Source: lib/lockspire/protocol/authorization_request.ex:452-466
defp pushed_request_to_params(%PushedAuthorizationRequest{} = request) do
  %{
    "client_id" => request.client_id,
    "redirect_uri" => request.redirect_uri,
    "response_type" => "code",
    "scope" => Enum.join(request.scopes, " "),
    "prompt" => prompt_param(request.prompt),
    "nonce" => request.nonce,
    "state" => request.state,
    "code_challenge" => request.code_challenge,
    "code_challenge_method" => Atom.to_string(request.code_challenge_method)
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()
end
```

The JAR projection function should produce a map of the same shape, but read from `jar.claims` (which already uses string keys per `JOSE.JWT.to_map/1` — see `jar.ex:45-46`).

### Example 3: Existing conflict-rejection (D-04 mirror)

```elixir
# Source: lib/lockspire/protocol/authorization_request.ex:393-411
defp reject_request_uri_conflicts(params) do
  conflict_keys =
    params
    |> Enum.reject(fn {key, _value} -> key in ["client_id", "request_uri"] end)
    |> Enum.filter(fn {_key, value} -> present?(value) end)

  case conflict_keys do
    [] ->
      :ok

    _other ->
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri cannot be combined with raw authorization parameters",
         :request_uri_conflict
       )}
  end
end
```

D-04's outer-param conflict rejector is structurally identical — replace `"request_uri"` with `"request"` and `:request_uri_conflict` with `:request_object_conflict`. (Recommendation: extract a generic `reject_outer_param_conflicts/2` helper that takes the allowed-key list.)

### Example 4: Existing redirect-safety classification (D-16 mirror)

```elixir
# Source: lib/lockspire/protocol/authorization_request.ex:170-189
defp par_required_error(params, %Client{} = client) do
  case validate_redirect_uri(client, params) do
    {:ok, _redirect_uri} ->
      {:redirect_error,
       redirect_error(
         params,
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}

    {:browser_error, %Error{}} ->
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}
  end
end
```

For JAR, the same dispatch applies — but per D-16, since outer `redirect_uri` is forbidden by D-04, the `{:ok, _}` branch is unreachable for JAR-rejection paths. The orchestrator can therefore unconditionally produce `:browser_error` for JAR-internal failures, and document that the redirect-safe path is a no-op given D-04. Plan recommendation: keep the dispatch shape for symmetry (cheap, future-proof if D-04 is ever loosened), but add a comment noting the practical unreachability.

### Example 5: Lockspire.Config accessor pattern for `:jar_max_age_seconds`

```elixir
# Source: lib/lockspire/config.ex:37-42 (existing pattern for known_scopes/0)
@spec known_scopes() :: [String.t()]
def known_scopes do
  @app
  |> Application.get_env(:known_scopes, [])
  |> List.wrap()
end
```

**Add for Phase 22:**

```elixir
# lib/lockspire/config.ex (new addition)
@jar_max_age_default 600

@doc """
Returns the configured JAR (`request` JWT) maximum age in seconds.

Caps `exp - now` for inbound JAR request objects to bound the replay window
between issuance and use. Default: #{@jar_max_age_default}s (10 minutes).

Hosts can override via `config :lockspire, jar_max_age_seconds: 300`.
Lower values reduce replay risk but may break clients with clock drift.
"""
@spec jar_max_age_seconds() :: pos_integer()
def jar_max_age_seconds do
  Application.get_env(@app, :jar_max_age_seconds, @jar_max_age_default)
end
```

Plus add a default to `config/config.exs`:

```elixir
# config/config.exs (modified)
config :lockspire,
  repo: nil,
  account_resolver: nil,
  issuer: nil,
  mount_path: "/lockspire",
  oban: [],
  jar_max_age_seconds: 600  # NEW
```

Why follow `known_scopes/0` and not `issuer!/0`: `:jar_max_age_seconds` has a sensible default and never causes a startup failure. `issuer!/0` is the pattern for required-with-no-default; `known_scopes/0` is the pattern for optional-with-default.

### Example 6: `typ`-header check for WR-01 (RFC 9101 §10.8)

```elixir
# Source: 21-REVIEW.md WR-01 recommendation, lightly adapted
# Insert into lib/lockspire/protocol/jar.ex after verify_strict succeeds.

defp verify_with_single_jwk(jwt, public_jwk) do
  try do
    case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
        {_modules, header} = JOSE.JWS.to_map(jws_struct)

        case check_typ(header) do          # NEW
          :ok -> {:ok, %__MODULE__{claims: claims, header: header}}
          {:error, _} = err -> err
        end

      {false, _, _} -> {:error, :invalid_signature}
      {:error, _} -> {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_signature}
  catch
    _, _ -> {:error, :invalid_signature}
  end
end

# Permissive: absent typ is allowed (RFC 9101 §10.8 SHOULD, not MUST).
# Recognized values (case-insensitive): "oauth-authz-req+jwt" (canonical), "jwt" (legacy).
# Anything else rejected as :invalid_typ.
defp check_typ(%{"typ" => typ}) when is_binary(typ) do
  if String.downcase(typ) in ["oauth-authz-req+jwt", "jwt"], do: :ok, else: {:error, :invalid_typ}
end
defp check_typ(_), do: :ok
```

The orchestrator maps `:invalid_typ` → `:invalid_request_object_typ` per D-14.

### Example 7: aud-list strictness for WR-02 (RFC 7519 §4.1.3)

```elixir
# Source: 21-REVIEW.md WR-02 recommendation, applied to jar.ex:245-263

defp check_audience(claims, expected_audience) do
  case Map.get(claims, "aud") do
    nil ->
      {:error, :missing_audience}

    aud when is_binary(aud) ->
      if aud == expected_audience, do: :ok, else: {:error, :invalid_audience}

    aud when is_list(aud) ->                                    # CHANGED
      cond do
        aud == [] -> {:error, :invalid_audience}
        not Enum.all?(aud, &is_binary/1) -> {:error, :invalid_audience}  # WR-02
        Enum.member?(aud, expected_audience) -> :ok
        true -> {:error, :invalid_audience}
      end

    _ ->
      {:error, :invalid_audience}
  end
end
```

### Example 8: `:max_age` opt for WR-03

```elixir
# Source: 21-REVIEW.md WR-03 recommendation, applied to jar.ex:191-202 + parse_opts/1 + check_expiration/3

# parse_opts/1 — accept :max_age (positive integer or nil/absent)
defp parse_opts(opts) do
  expected_client_id = Keyword.get(opts, :expected_client_id)
  expected_audience = Keyword.get(opts, :expected_audience)
  now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
  leeway = Keyword.get(opts, :leeway, 0)
  max_age = Keyword.get(opts, :max_age)                           # NEW

  cond do
    not is_binary(expected_client_id) or expected_client_id == "" -> {:error, :invalid_claims_options}
    not is_binary(expected_audience) or expected_audience == "" -> {:error, :invalid_claims_options}
    not match?(%DateTime{}, now) -> {:error, :invalid_claims_options}
    not (is_integer(leeway) and leeway >= 0) -> {:error, :invalid_claims_options}
    not (is_nil(max_age) or (is_integer(max_age) and max_age > 0)) ->
      {:error, :invalid_claims_options}                            # NEW
    true -> {:ok, expected_client_id, expected_audience, now, leeway, max_age}
  end
end

# check_expiration/4 — also verify upper bound when :max_age is set
defp check_expiration(claims, now, leeway, max_age) do
  with {:ok, exp} <- fetch_exp(claims),
       :ok <- check_not_expired(exp, now, leeway),
       :ok <- check_max_age(exp, now, leeway, max_age) do
    :ok
  end
end

defp check_max_age(_exp, _now, _leeway, nil), do: :ok            # no ceiling
defp check_max_age(exp, now, leeway, max_age) do
  now_unix = DateTime.to_unix(now)
  if exp - now_unix <= max_age + leeway, do: :ok, else: {:error, :expiration_too_far}
end
```

The orchestrator maps `:expiration_too_far` → `:invalid_request_object_max_age` per D-14.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat `request` as a flatly-unsupported param | Recognize `request` as JAR-by-value, route through orchestrator | Phase 22 (2026-04-25) | `@unsupported_params` shrinks; positive handler replaces blanket rejection |
| Outer params merge with JAR claims (RFC 9101 §6.1 default) | Strict sealed-envelope: only `client_id` + `request` permitted as outer (RFC 9101 §10.2 recommended) | Phase 22 D-04, D-07 | Eliminates entire smuggling class; trivial test matrix |
| Permissive `typ` header (any/none acceptable) | Reject non-`oauth-authz-req+jwt`/`jwt` typ values (RFC 9101 §10.8) | Phase 22 WR-01 / D-11 | Closes cross-JWT confusion vector; backward-compatible (absent typ still allowed) |
| Unbounded JAR `exp` window | Configurable max-age ceiling (default 600s) | Phase 22 WR-03 / D-13 | Bounds replay window; introduces single config knob `:jar_max_age_seconds` |

**Deprecated/outdated:**
- `request` listed in `@unsupported_params`: outdated as of Phase 22 implementation; D-18 mandates removal.
- 21-REVIEW.md WR-01/WR-02/WR-03 recorded as "warnings deferred to Phase 22": Phase 22 closes them.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The expected JAR `aud` value is `Lockspire.Config.issuer!()` (the AS issuer URL) | Code Examples (Pattern 2: `jar_opts/0`) | If wrong, all valid JARs fail with `:invalid_request_object_aud`. Verifiable by reading RFC 9101 §6 ("aud claim MUST contain the AS issuer identifier as the audience"). [CITED: RFC 9101 §6, lib/lockspire/protocol/discovery.ex:28 — `Config.issuer!()` is what's exposed in discovery as the issuer URL] |
| A2 | A 5-second leeway is the right default for JAR validation | Code Examples (Pattern 2: `jar_opts/0`) | If too generous, slightly widens replay window; if too tight, rejects valid clients on minor clock drift. 5s is conservative — Phase 21 plan-03 chose default `0` for the primitive but documented orchestrator-supplied leeway as the right pattern. [VERIFIED: 21-03-SUMMARY.md Auto-fixed Issue #1] |
| A3 | The orchestrator should be a sibling module (`Lockspire.Protocol.RequestObject`), not a sub-module of `Jar` | Architecture Patterns / Standard Stack | If sub-module is preferred for namespace cleanliness, file path / aliases change but no behavioral impact. CONTEXT.md D-01 grants the agent discretion. |
| A4 | Whether to add a separate `request_object_test.exs` or fold orchestrator tests into `authorization_request_test.exs` | Architecture Patterns / Validation Architecture | Recommend separate file because the orchestrator's surface (consume/3 with multiple failure modes) justifies focused unit coverage. CONTEXT.md D-20 grants discretion. |

**Note:** All other claims in this research were verified against the codebase at file:line precision or cited from RFCs. No additional `[ASSUMED]`-tagged decisions need user confirmation before planning.

## Open Questions

1. **Should the orchestrator's `consume/3` accept the full `params` map or just `{outer_client_id, request_jwt, outer_redirect_uri}` as separate args?**
   - What we know: full map gives flexibility but couples to outer-param shape; tuple is narrow but requires the splice site to extract.
   - What's unclear: Whether future Phase 23 work (per-client policy controls) needs to thread additional outer fields.
   - Recommendation: pass the full `params` map. Reduces churn at the splice site. Matches `pushed_request_to_params/1`'s shape (operates on a struct-shaped map).

2. **Should we extract a generic `reject_param_conflicts/2` helper covering both PAR (`request_uri`) and JAR (`request`) cases?**
   - What we know: D-04 explicitly says "symmetric with the existing `:request_uri_conflict` rule".
   - What's unclear: Whether the duplication is small enough to keep two separate helpers for clarity.
   - Recommendation: do extract. The function is one-liner; allows the planner to write `reject_param_conflicts(params, allowed: ["client_id", "request"])` for JAR and reduces visual diff in the test file. (Plan-level decision; not load-bearing.)

## Environment Availability

Phase 22 has no new external dependencies — pure code edits to existing modules using already-installed packages.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP | All Elixir code | ✓ (assumed; required for compilation) | per asdf/.tool-versions | — |
| Elixir | All code | ✓ | `~> 1.18` (mix.exs:9) | — |
| `:jose` | `Jar.{decode,verify_signature,validate_claims}` | ✓ | `~> 1.11` (mix.exs:42) | — |
| `:jason` | Test signing helpers | ✓ | `~> 1.4` (mix.exs:43) | — |
| `:phoenix` | Controllers (unchanged) | ✓ | `~> 1.8.5` (mix.exs:37) | — |
| `:telemetry` | Observability emission | ✓ | `~> 1.3` (mix.exs:45) | — |
| Postgres test database | Integration & protocol seam tests | ✓ (assumed; v1.3 milestone passes) | per `LOCKSPIRE_TEST_DB_*` env | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

Required because `workflow.nyquist_validation = true` in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in test framework) |
| Config file | `config/test.exs` (Repo + app config); no separate test runner config |
| Quick run command | `mix test test/lockspire/protocol/jar_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs --trace` |
| Full suite command | `mix test` (excludes `:integration` by default; integration via `mix test.integration`) |

### Phase Requirements → Test Map

Each row is precise enough that a planner can lift it into an `<acceptance_criteria>` block.

#### A) Jar primitive hardening (WR-01, WR-02, WR-03) — pinned in `test/lockspire/protocol/jar_test.exs`

| Req ID | Behavior | Test Type | Failure Injection | Automated Command |
|--------|----------|-----------|-------------------|-------------------|
| WR-01 | `verify_signature/2` rejects `typ=JWT-bearer` | unit | sign with `extra_header: %{"typ" => "JWT-bearer"}`; assert `{:error, :invalid_typ}` | `mix test test/lockspire/protocol/jar_test.exs:NNN -t typ_rejection` |
| WR-01 | `verify_signature/2` accepts `typ=oauth-authz-req+jwt` | unit | sign with `extra_header: %{"typ" => "oauth-authz-req+jwt"}`; assert `{:ok, %Jar{}}` | (same file) |
| WR-01 | `verify_signature/2` accepts absent `typ` (legacy) | unit | sign with no `typ`; assert `{:ok, %Jar{}}` (already exists implicitly; make explicit) | (same file) |
| WR-01 | `verify_signature/2` accepts `typ=jwt` (lowercase, legacy) | unit | sign with `typ: "jwt"`; assert `{:ok, %Jar{}}` | (same file) |
| WR-02 | `validate_claims/2` rejects `aud: ["valid-aud", 42]` | unit | claims with mixed-type aud list; assert `{:error, :invalid_audience}` | (same file) |
| WR-02 | `validate_claims/2` rejects `aud: []` (empty list) | unit | claims with `aud: []`; assert `{:error, :invalid_audience}` | (same file) |
| WR-03 | `validate_claims/2` rejects `exp` beyond `:max_age` ceiling | unit | claims with `exp = now + 3600`, opts `max_age: 600`; assert `{:error, :expiration_too_far}` | (same file) |
| WR-03 | `validate_claims/2` accepts `exp` within ceiling | unit | claims with `exp = now + 300`, opts `max_age: 600`; assert `:ok` | (same file) |
| WR-03 | `validate_claims/2` ignores ceiling when `:max_age` not set | unit | claims with `exp = now + 999_999_999`, no `:max_age`; assert `:ok` (preserves Phase 21 contract) | (same file) |
| WR-03 | `validate_claims/2` rejects negative `:max_age` opt | unit | opts `max_age: -1`; assert `{:error, :invalid_claims_options}` | (same file) |

#### B) Reason-code branches per D-14 (orchestrator + protocol seam) — pinned in `test/lockspire/protocol/authorization_request_test.exs`

For each row, setup uses `valid_params(client.client_id)`, then replaces with `%{"client_id" => cid, "request" => signed_jar}` where the JAR is constructed with the failure injection described.

| reason_code (D-14) | OAuth `error` | Failure Injection | Assertion |
|--------------------|---------------|---------------------|-----------|
| `:invalid_request_object_jwt` | `invalid_request_object` | `request: "not.a.jwt"` (malformed) | `{:browser_error, %Error{reason_code: :invalid_request_object_jwt, error: "invalid_request_object"}}` |
| `:invalid_request_object_signature` | `invalid_request_object` | sign with a different RSA key than `client.jwks` | `{:browser_error, %Error{reason_code: :invalid_request_object_signature}}` |
| `:invalid_request_object_typ` | `invalid_request_object` | sign with valid key but `typ: "JWT-bearer"` | `{:browser_error, %Error{reason_code: :invalid_request_object_typ}}` |
| `:invalid_request_object_expired` | `invalid_request_object` | sign with `exp = now - 60` | `{:browser_error, %Error{reason_code: :invalid_request_object_expired}}` |
| `:invalid_request_object_iss` | `invalid_request_object` | outer `client_id = "client_123"`, JAR `iss = "client_456"` | `{:browser_error, %Error{reason_code: :invalid_request_object_iss}}` |
| `:invalid_request_object_aud` | `invalid_request_object` | JAR `aud = "https://other.example.com"` (not the issuer) | `{:browser_error, %Error{reason_code: :invalid_request_object_aud}}` |
| `:invalid_request_object_max_age` | `invalid_request_object` | JAR `exp = now + 7200` with `:jar_max_age_seconds = 600` | `{:browser_error, %Error{reason_code: :invalid_request_object_max_age}}` |
| `:invalid_request_object_claims` | `invalid_request_object` | JAR with `nbf = now + 60` (future nbf) | `{:browser_error, %Error{reason_code: :invalid_request_object_claims}}` |
| `:client_jwks_missing` | `invalid_request_object` | client registered with `jwks: nil`, valid JWT presented | `{:browser_error, %Error{reason_code: :client_jwks_missing}}` |

#### C) Shape-level conflict reason codes per D-15

| reason_code | OAuth `error` | Failure Injection | Assertion |
|-------------|---------------|---------------------|-----------|
| `:request_object_conflict` | `invalid_request` | params `%{"client_id" => cid, "request" => jar, "redirect_uri" => "..."}` (extra outer param) | `{:browser_error, %Error{error: "invalid_request", reason_code: :request_object_conflict}}` |
| `:request_object_and_request_uri_conflict` | `invalid_request` | params `%{"client_id" => cid, "request" => jar, "request_uri" => "urn:..."}` | `{:browser_error, %Error{error: "invalid_request", reason_code: :request_object_and_request_uri_conflict}}` |

#### D) Sealed-envelope projection happy path

| Behavior | Failure Injection | Assertion |
|----------|---------------------|-----------|
| Valid JAR projects to flat-params; existing `validate_with_client/3` runs unchanged | JAR with `redirect_uri`, `scope`, `code_challenge`, `code_challenge_method=S256`, `response_type=code`, `state`, `prompt=login consent`; outer is only `{"client_id", "request"}` | `{:ok, %Validated{}}` with all fields populated from JAR claims; `validated.redirect_uri == jar_claims["redirect_uri"]`, `validated.scopes == String.split(jar_claims["scope"])`, etc. |
| Telemetry emits the new reason_code atoms automatically | Trigger `:invalid_request_object_typ`; attach a `:lockspire/audit/authorization_request_rejected` handler | `assert_received {:telemetry_event, [:lockspire, :authorization_request_rejected], %{reason_code: :invalid_request_object_typ, redirect_safe: false}}` (one such test is sufficient — proves the surface, not every atom) |

#### E) `request` is no longer in `@unsupported_params`

| Behavior | Failure Injection | Assertion |
|----------|---------------------|-----------|
| `params["request"]` does NOT trigger `:unsupported_request` | Trigger an OK JAR; assert no error mentioning "request is not supported" | (subsumed by happy path; explicit regression test recommended) |
| `params["claims"]` STILL triggers `:unsupported_claims` | Add `claims` outer param alongside valid request; expect rejection | `error.reason_code == :unsupported_claims` (or `:request_object_conflict` if it's caught earlier — be precise about ordering) |
| External `request_uri` STILL rejected via `validate_lockspire_request_uri/1` | params with `request_uri: "https://attacker.example.com/req"` | `error.reason_code == :invalid_request_uri` (preserved from Phase 18) |

### Browser-boundary proof — `test/lockspire/web/authorize_controller_test.exs`

Per CONTEXT.md (Claude's Discretion section: "smallest verification matrix … plus one redirect-safe and one browser-error proof at the controller seam"), the controller test gets exactly two new tests:

| # | Behavior | Failure Injection | Assertion |
|---|----------|---------------------|-----------|
| 1 | JAR with bad signature renders the first-party error page (browser-error path; this is the dominant path per D-16) | params `%{"client_id" => cid, "request" => bad_signature_jwt}` | `conn.status == 400`, `refute redirected?(conn)`, `conn.resp_body =~ "Authorization request rejected"` |
| 2 | JAR happy path reuses the normal browser login handoff (proves the projected-params hand off cleanly to `AuthorizationFlow`) | params `%{"client_id" => cid, "request" => valid_jar}` | `conn.status in [302, 303]`, `location =~ "/sign-in?"`, `location =~ "interaction_id="` |

The "redirect-safe" classification per D-16 is unreachable for JAR-validation failures because outer `redirect_uri` is forbidden by D-04. To satisfy the requirement of "one redirect-safe proof": the happy-path test (#2) IS the redirect-safe proof — it proves the OK branch of `with`-chain produces a `Location` redirect, which is the Phoenix-level shape of "redirect-safe handoff to the host login surface". Document this in a comment in the test so future readers don't try to construct an unreachable redirect-safe JAR-failure case.

### `/par` JAR splice + e2e proof — `test/integration/phase15_par_authorization_e2e_test.exs`

ONE new test branch (per D-21 and CONTEXT.md specifics):

| # | Behavior | Steps | Assertion |
|---|----------|-------|-----------|
| 1 | Client posts `request=<JWT>` to `/par`, receives a Lockspire `request_uri`, completes `/authorize` with that `request_uri`, and the canonical PAR auth-code+PKCE flow continues unchanged | (a) register client with valid `jwks`; (b) sign a JAR with `iss=client_id`, `aud=issuer`, `exp=now+300`, claims for redirect_uri/scope/PKCE; (c) `POST /par` with `Authorization: Basic ...` AND body `{client_id, request: jwt}`; (d) read back `request_uri`; (e) `GET /authorize?client_id=...&request_uri=...`; (f) drive consent; (g) `POST /token`; (h) verify id_token | All existing Phase 15 e2e assertions hold (id_token verified, replay rejected, etc.) — proves JAR-by-value at /par produces an identical downstream flow |

`/par`-specific protocol-seam test (in `test/lockspire/protocol/pushed_authorization_request_test.exs`):

| # | Behavior | Failure Injection | Assertion |
|---|----------|---------------------|-----------|
| 1 | `/par` with valid client auth + invalid JAR returns the JAR-mapped error (NOT the ClientAuth error) | valid Basic auth credentials + `request: bad_signature_jwt` | `{:error, %Error{status: 400, error: "invalid_request_object", reason_code: :invalid_request_object_signature}}` (proves D-10: ClientAuth and JAR run independently) |
| 2 | `/par` with INVALID client auth + valid JAR returns the ClientAuth error (proves ClientAuth runs first per D-03 splice ordering) | wrong Basic password + valid JAR | `{:error, %Error{status: 401, error: "invalid_client", reason_code: :invalid_client_secret}}` |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/protocol/jar_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/request_object_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs` — fast (sub-second to a few seconds; protocol seam tests are async-capable but `authorization_request_test.exs` is `async: false` due to global app env mutation)
- **Per wave merge:** `mix test` (full unit + protocol + controller suite, excludes integration)
- **Phase gate:** `mix test --include integration` (full suite incl. `phase15_par_authorization_e2e_test.exs`) green before `/gsd-verify-work`

### Wave 0 Gaps

- [x] `test/lockspire/protocol/jar_test.exs` — exists (370 lines, 41 tests); needs extension for WR-01/02/03 (≈10 new cases)
- [x] `test/lockspire/protocol/authorization_request_test.exs` — exists (550 lines); needs extension for full reason-code matrix (≈11 new cases)
- [x] `test/lockspire/protocol/pushed_authorization_request_test.exs` — exists; needs ≈2 new cases for JAR-at-/par integration with ClientAuth
- [x] `test/lockspire/web/authorize_controller_test.exs` — exists (474 lines); needs ≈2 new cases (one rejection page, one happy-path handoff)
- [x] `test/integration/phase15_par_authorization_e2e_test.exs` — exists (354 lines); needs ≈1 new test branch (JAR-via-PAR-via-/authorize)
- [ ] `test/lockspire/protocol/request_object_test.exs` — NEW file (only if orchestrator surface justifies; per D-20, planner's call). Recommended scope: orchestrator-internal helpers (projection function, conflict detector) at module-private level OR fold into `authorization_request_test.exs`. Recommendation: **fold into `authorization_request_test.exs`** because the orchestrator's only public function (`consume/3`) is exercised end-to-end through `AuthorizationRequest.validate/1`; a separate file would mostly re-test the same behavior at one level lower of abstraction. If a separate file is created, keep it small (≤5 tests focused on the projection + conflict-detection helpers in isolation).
- [ ] Test helper additions: a `sign_jar(claims, opts \\ [])` helper in `authorization_request_test.exs` setup (or a shared `Lockspire.JarTestSupport` module under `test/support/`) that generates a JOSE-signed JWT and registers a `Client.jwks` containing the matching public key. Without this, every JAR test repeats ~15 lines of JOSE plumbing.

**Framework install:** None — ExUnit ships with Elixir, already configured in `mix.exs`.

## Project Constraints (from CLAUDE.md)

No project-level `CLAUDE.md` was found at the repository root or working directory. Project guidance comes exclusively from `.planning/PROJECT.md`:

- **Tech stack:** Embedded Phoenix/Elixir library; must feel native inside a host Phoenix app.
- **Storage:** Ecto/Postgres for durable state; protocol truth lives in durable storage where applicable.
- **Security:** Secure-by-default OAuth/OIDC posture is mandatory — PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived codes, no implicit flow, **no `alg=none`**.
- **Architecture:** Strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and operator UI.
- **Host seam:** Host apps own accounts, login UX, layouts, branding, and policy.
- **Release quality:** Executable docs, warnings-as-errors, CI/CD, changelog hygiene.
- **Verification posture:** Default phase closure to executable proof in tests and CI; human UAT only when automation is blocked by a real external boundary.

These constraints align with all Phase 22 decisions:
- `alg=none` rejection is verified in Phase 21 jar_test.exs:97-108 and preserved unchanged.
- The orchestrator stays inside the protocol-core boundary; controllers stay thin (D-17).
- All phase verification is automated (D-19/20/21 — no human UAT for this phase).

## Sources

### Primary (HIGH confidence) — codebase verified at file:line precision
- `lib/lockspire/protocol/jar.ex` (321 lines) — primitive contract: `decode/1` (38-54), `verify_signature/2` (73-87), `validate_claims/2` (191-202)
- `lib/lockspire/protocol/authorization_request.ex` (561 lines) — splice points: `validate/1` (69-92), `validate_with_client/3` (210-224), `pushed_request_to_params/1` (452-466), `reject_request_uri_conflicts/1` (393-411), `validate_lockspire_request_uri/1` (413-424), `@unsupported_params` (15), `emit_rejection/3` (508-514)
- `lib/lockspire/protocol/pushed_authorization_request.ex` (157 lines) — `/par` splice: `push/1` (43-61), `authenticate_client/3` returning `{:ok, %Client{}}` (73-87), `validate_request/2` (63-71)
- `lib/lockspire/protocol/par_policy.ex` — referenced for symmetry (unchanged in Phase 22)
- `lib/lockspire/protocol/client_auth.ex` (177 lines) — `authenticate/3` runs unchanged at `/par` per D-10; `private_key_jwt` is in the type spec at line 8 (the cross-JWT-confusion vector that motivates WR-01)
- `lib/lockspire/domain/client.ex` (82 lines) — `:jwks` (line 30), `:jwks_uri` (31), `token_endpoint_auth_method` (24, type spec includes `:private_key_jwt`)
- `lib/lockspire/web/controllers/authorize_controller.ex` (175 lines) — thin delivery adapter: `show/2` (17-39), `render_browser_error/3` (152-157), `redirect_location/1` (120-136)
- `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex` (52 lines) — thin /par delivery: `create/2` (14-35)
- `lib/lockspire/config.ex` (52 lines) — accessor pattern: `known_scopes/0` (37-42) is the template for `jar_max_age_seconds/0`
- `lib/lockspire/observability.ex` (35 lines) — `emit/3` redacts and double-emits to `[:lockspire, :audit, ...]` and `[:lockspire, ...]`; new reason_code atoms surface automatically
- `test/lockspire/protocol/jar_test.exs` (370 lines, 41 tests) — Phase 21 coverage; extension targets: lines 97-108 (alg=none), 144-158 (tampered payload), 232-244 (aud cases)
- `test/lockspire/protocol/authorization_request_test.exs` (550 lines) — extension targets: existing `:request_uri_conflict` test at line 473-485 (the structural template for `:request_object_conflict`)
- `test/lockspire/web/authorize_controller_test.exs` (474 lines) — `call_authorize/1` helper at 422-425 is the entry point for new JAR controller tests
- `test/integration/phase15_par_authorization_e2e_test.exs` (354 lines) — extension target: surgical add of one JAR-via-PAR test branch
- `mix.exs` (60 lines verified) — `:jose ~> 1.11` (42), `:jason ~> 1.4` (43), `:phoenix ~> 1.8.5` (37), `:telemetry ~> 1.3` (45)
- `config/test.exs` — issuer config (`https://example.test/lockspire`) used by tests; matches the `aud` value JARs must claim
- `.planning/config.json` — `workflow.nyquist_validation: true` (Validation Architecture section required)

### Primary (HIGH confidence) — RFCs and standards
- RFC 9101 §5 (Request Object) — semantics of `request` parameter and JWT structure [CITED: ietf.org]
- RFC 9101 §6 — `aud` claim MUST contain the AS issuer identifier [CITED]
- RFC 9101 §6.1 — parameter precedence: outer params MAY be ignored; AS MAY require all params come from the JAR [CITED: matches D-04/D-07 strict posture]
- RFC 9101 §10.2 — security recommendation to ignore outer params (the strict posture Phase 22 adopts) [CITED]
- RFC 9101 §10.8 — Cross-JWT confusion: `typ=oauth-authz-req+jwt` SHOULD [CITED: matches WR-01 / D-11]
- RFC 9126 §2.1 — PAR client authentication; substitution-method path explicitly NOT adopted in v1.4 [CITED: matches D-10]
- RFC 7519 §4.1.3 — `aud` is StringOrURI; list form valid [CITED: WR-02 strict-typing rationale]

### Primary (HIGH confidence) — prior planning artifacts
- `.planning/phases/22-request-object-integration/22-CONTEXT.md` (170 lines) — D-01 through D-22 + canonical refs
- `.planning/phases/21-jar-foundation/21-VERIFICATION.md` — JAR-01 endpoint wiring deferral confirmed (line 50-53)
- `.planning/phases/21-jar-foundation/21-REVIEW.md` — WR-01 typ-check fix snippet (line 42-72), WR-02 aud-list-strict snippet (line 86-94), WR-03 max-age fix snippet (line 107-122)
- `.planning/phases/21-jar-foundation/21-01-SUMMARY.md` — JAR struct + `decode/1` decisions
- `.planning/phases/21-jar-foundation/21-02-SUMMARY.md` — `verify_signature/2`, `verify_strict`, JWK Set normalization decisions
- `.planning/phases/21-jar-foundation/21-03-SUMMARY.md` — `validate_claims/2` decisions, leeway rationale, aud StringOrURI rationale
- `.planning/phases/18-authorization-path-enforcement/18-CONTEXT.md` — redirect-safe vs browser-error classification posture (D-01 through D-08)
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-CONTEXT.md` — proof-style and one-canonical-e2e posture (D-04 through D-07)
- `.planning/REQUIREMENTS.md` — JAR-01 in scope; JAR-04 deferred; JAR-05/JAR-06 explicitly Phase 23
- `.planning/PROJECT.md` — embedded-library posture, secure-by-default constraints

### Secondary (MEDIUM confidence) — none required
All claims in this research were verifiable against the local codebase or cited standards. No WebSearch / external tertiary sources were consulted because none were needed; RFCs 9101, 9126, 7519 plus the Phase 21 planning artifacts and the local code provided complete coverage.

### Tertiary (LOW confidence) — none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `:jose ~> 1.11` already on hex, used and tested in Phase 21; no new dependencies.
- Architecture: HIGH — splice points verified at file:line precision; pattern mirrors existing PAR projection/consumption with no novel design.
- Pitfalls: HIGH — every pitfall corresponds to a concrete code path, RFC clause, or deferred Phase 21 review item with a documented fix.
- Validation Architecture: HIGH — every reason_code in D-14 and shape conflict in D-15 has a 1:1 test entry with explicit failure injection and assertion shape.
- Reason-code mapping: HIGH — derived directly from D-14 + Phase 21 atom taxonomy.
- WR-01/WR-02/WR-03 implementation snippets: HIGH — reproduced from `21-REVIEW.md` recommendations; reviewer is an internal previous-phase artifact.

**Research date:** 2026-04-25

**Valid until:** 2026-05-25 (30 days). Stable: codebase, RFCs, and `:jose` library are not fast-moving. Re-research only if (a) Phase 23 introduces metadata that changes the orchestrator surface, (b) a security advisory affects `:jose ~> 1.11`, or (c) the v1.4 milestone scope changes (e.g., elevating `Client.jwks_uri` fetching out of the deferred list).
