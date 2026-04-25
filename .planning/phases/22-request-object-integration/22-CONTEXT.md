# Phase 22: Request Object Integration - Context

**Gathered:** 2026-04-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the Phase 21 JAR primitive (`Lockspire.Protocol.Jar`) into the live authorization path so clients can pass a JWT request object **by value** in `/authorize` and `/par`. This phase delivers `JAR-01` endpoint wiring; it does not add discovery metadata (Phase 23, `JAR-05`), operator/admin policy controls for required-JAR (Phase 23, `JAR-06`), JAR decryption (`JAR-04`, deferred), foreign/external `request_uri` support, request-object lookup over `jwks_uri`, or `request_uri`-based JAR (request-by-reference). Lockspire's `request_uri` semantics remain: Lockspire-issued PAR references only.

</domain>

<decisions>
## Implementation Decisions

### Integration Seam And Module Layout
- **D-01:** Add a new orchestrator module `Lockspire.Protocol.RequestObject` that composes `Lockspire.Protocol.Jar.decode/1`, `verify_signature/2`, and `validate_claims/2`. The primitive (`Jar`) stays policy-free; the orchestrator owns client lookup wiring, error mapping, and projection of JAR claims into the existing flat authorization-param shape.
- **D-02:** Splice JAR consumption into `Lockspire.Protocol.AuthorizationRequest` as a pipeline step that runs **before** `validate_with_client/3`. JAR claims are projected into the same param shape that `pushed_request_to_params/1` already produces, then the existing `validate_with_client/3` pipeline (scopes, PKCE, prompt, redirect_uri, response_type, nonce) runs unchanged on the projected map.
- **D-03:** At `/par`, JAR consumption splices into `validate_pushed/2` immediately after `ClientAuth.authenticate/3` returns the authenticated `%Client{}`. The existing `Lockspire.Protocol.PushedAuthorizationRequest.push/1` orchestration shape is preserved; once JAR is consumed, the same `validate_pushed/2` -> `persist_pushed_request/3` flow continues unchanged so the issued opaque `request_uri` works identically downstream.

### Parameter Precedence And Strict-Mode Posture
- **D-04:** When `request` is present, the only outer authorization params permitted are `client_id` (REQUIRED for client lookup) and `request` itself. Any other outer param is rejected with `error=invalid_request` and `reason_code: :request_object_conflict` — symmetric with the existing `:request_uri_conflict` rule for PAR.
- **D-05:** Outer `client_id` MUST equal the JAR `iss` claim. Mismatch is rejected as `:invalid_request_object_iss` (or fed to `Jar.validate_claims/2` with `expected_client_id: outer_client_id`, which is the existing contract).
- **D-06:** `request` and `request_uri` MUST NOT both be supplied. Both-present is rejected as `error=invalid_request` with `reason_code: :request_object_and_request_uri_conflict`.
- **D-07:** All non-`client_id` authorization params are sourced from the JAR claims. Outer copies are NEVER merged; this preserves the "sealed envelope" property that the JAR signature is meant to guarantee. RFC 9101 §6.1 explicitly permits this stricter behavior; §10.2 recommends it.

### Trust Model And Client-Key Prerequisites
- **D-08:** v1.4 requires the client to have a non-empty inline `Client.jwks` (single JWK or JWK Set) registered to use JAR-by-value. Absence yields `error=invalid_request_object` with `reason_code: :client_jwks_missing`. `Client.jwks_uri` fetching is **deferred** (Phase 23 or later — needs HTTP cache, retry, and operator-visible failure surface).
- **D-09:** No new per-client opt-in field is added in Phase 22. Per-client policy controls (`request_object_signing_alg`, `require_signed_request_object`, etc.) are explicitly Phase 23 (`JAR-06`) scope.
- **D-10:** At `/par`, `ClientAuth.authenticate/3` continues to run unchanged, and JAR signature verification runs as a **separate, additional** step. A valid JAR does NOT substitute as client authentication. RFC 9126 §2.1's optional substitution path is not adopted in v1.4 — it would require a new `token_endpoint_auth_method`, discovery metadata changes, and admin UX work that is out of milestone scope.

### Phase 21 Hardening Items Landed In Phase 22
- **D-11:** **WR-01 (typ-header check)** lands in Phase 22. `verify_signature/2` (or a follow-up step) MUST accept only `typ=oauth-authz-req+jwt` (RFC 9101 §10.8 SHOULD) or absent `typ`. Lowercase `jwt` is also accepted for legacy interop. Other `typ` values are rejected as `:invalid_request_object_typ`. This closes the JWT-type-confusion vector that becomes reachable the moment JAR is exposed over HTTP — `private_key_jwt` is already a supported `token_endpoint_auth_method`, so the matching `iss`/`aud`/`exp` shape vector is real.
- **D-12:** **WR-02 (aud-list strictness)** lands in Phase 22. `Jar.validate_claims/2`'s `aud` list branch must reject lists containing non-binary entries. One-line filter; cannot ship a known input-validation gap behind an HTTP surface.
- **D-13:** **WR-03 (`exp` max-age ceiling)** lands in Phase 22. Add a `:max_age` option to `Jar.validate_claims/2` and feed it from a Lockspire config knob (e.g. `:jar_max_age_seconds`, default `600`). The orchestrator passes the configured ceiling on every call. New failure atom: `:invalid_request_object_max_age`.

### Error Semantics And Reason Codes
- **D-14:** New JAR failure modes map to RFC 9101 `error=invalid_request_object` with distinct `AuthorizationRequest.Error.reason_code` atoms per failure: `:invalid_request_object_jwt` (malformed), `:invalid_request_object_signature`, `:invalid_request_object_typ`, `:invalid_request_object_expired`, `:invalid_request_object_iss`, `:invalid_request_object_aud`, `:invalid_request_object_max_age`, `:invalid_request_object_claims` (other claim-validation failures), `:client_jwks_missing`. Granular atoms preserve telemetry/admin-UX coherence — coarse single-atom errors regress the v1.3 reason-code observability surface.
- **D-15:** Shape-level failures (both `request` and `request_uri` present, conflicting outer params) map to `error=invalid_request` with `reason_code: :request_object_conflict` or `:request_object_and_request_uri_conflict`. These are not "object validation" failures — the request never gets that far.
- **D-16:** Redirect-safety classification mirrors the existing `par_required_request_uri` pattern (authorization_request.ex:170-189). A JAR error is `{:redirect_error, ...}` iff the outer `redirect_uri` is registered for the authenticated client; otherwise `{:browser_error, ...}`. Note: when JAR is rejected before signature verification (e.g. malformed JWT, missing `jwks`), the AS cannot trust JAR-internal `redirect_uri`, so redirect-safety must be evaluated against the OUTER `redirect_uri` only — but per D-04 outer `redirect_uri` is rejected as a conflict, so this case effectively always classifies as `{:browser_error, ...}`. Document this trade-off explicitly so downstream agents do not try to "improve" it.
- **D-17:** Response classification stays inside `Lockspire.Protocol.AuthorizationRequest` (and the new `RequestObject` orchestrator). `AuthorizeController` and `PushedAuthorizationRequestController` remain thin and unchanged in their dispatch shape.

### Unsupported-Params List Handling
- **D-18:** Remove `request` from `Lockspire.Protocol.AuthorizationRequest.@unsupported_params` and replace with a positive handler. `claims`, `resource`, `response_mode`, and **external** `request_uri` (any value not prefixed with `PushedAuthorizationRequest.request_uri_prefix()`) remain rejected exactly as today. The existing `validate_lockspire_request_uri/1` guard is the canonical seam for the "Lockspire-issued only" rule.

### Verification Style
- **D-19:** Extend the three existing focused proof surfaces:
  - `test/lockspire/protocol/authorization_request_test.exs` — primary JAR validation matrix at the protocol seam (happy path, every reason-code branch, conflict cases, max-age ceiling, typ check, missing jwks).
  - `test/lockspire/web/authorize_controller_test.exs` — browser-boundary proof (redirect-safe vs first-party error rendering for JAR rejection paths).
  - `test/integration/phase15_par_authorization_e2e_test.exs` — extend surgically with a `/par` JAR-by-value branch that issues a `request_uri` and is then consumed at `/authorize`. Keep this as the single canonical end-to-end PAR-and-JAR-and-PAR+JAR proof.
- **D-20:** New unit-level coverage for `Lockspire.Protocol.RequestObject` orchestrator and any new `Jar` helpers (typ check, aud-list strictness, max_age) goes in the existing `test/lockspire/protocol/jar_test.exs` plus a new `test/lockspire/protocol/request_object_test.exs` (only if the orchestrator's surface justifies a separate file; otherwise fold into `authorization_request_test.exs`).
- **D-21:** Do NOT create a parallel `phase22_jar_authorization_e2e_test.exs`. The locked v1.3 verification posture (one canonical end-to-end PAR proof, focused protocol matrix) carries forward.

### Decision-Making Posture For Downstream Agents
- **D-22:** Downstream research, planning, and execution agents prefer one decisive recommendation over multiple alternatives presented to the user. Escalate only when a choice materially shifts Lockspire's trust boundaries, supported surface, or milestone scope.

### Claude's Discretion
- The exact internal projection function name, the precise atom for "other claim-validation failures" (suggested `:invalid_request_object_claims`), and whether the orchestrator lives in a sibling module or as a sub-module of `Jar` are all the agent's call as long as the contract above holds.
- The agent may pick the smallest verification matrix that pins each new reason code at the protocol seam plus one redirect-safe and one browser-error proof at the controller seam.
- Lockspire config key naming for the JAR max-age ceiling is the agent's call (suggested `:jar_max_age_seconds`); just keep it consistent with existing `Lockspire.Config` conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Requirements
- `.planning/ROADMAP.md` — Phase 22 goal and v1.4 milestone scope.
- `.planning/REQUIREMENTS.md` — `JAR-01` mapping and `JAR-04` deferral; `JAR-05` and `JAR-06` are explicitly Phase 23, NOT Phase 22.
- `.planning/PROJECT.md` — embedded-library posture, narrow PAR scope, secure-by-default constraints.
- `.planning/STATE.md` — v1.4 milestone state and Phase 21 completion handoff.

### Prior Phase Decisions And Foundations
- `.planning/phases/21-jar-foundation/21-01-SUMMARY.md` — JAR data structure and unverified decoding decisions.
- `.planning/phases/21-jar-foundation/21-02-SUMMARY.md` — signature verification, JOSE `verify_strict`, JWK Set normalization decisions.
- `.planning/phases/21-jar-foundation/21-03-SUMMARY.md` — RFC 9101 security claims validation decisions and per-failure atom taxonomy.
- `.planning/phases/21-jar-foundation/21-VERIFICATION.md` — JAR-01 endpoint-wiring deferral to Phase 22 (canonical scope handoff).
- `.planning/phases/21-jar-foundation/21-REVIEW.md` — WR-01 (typ check), WR-02 (aud-list strictness), WR-03 (max_age) hardening items adopted by Phase 22.
- `.planning/phases/18-authorization-path-enforcement/18-CONTEXT.md` — redirect-safe vs browser-error classification posture and reason-code taxonomy carried forward.
- `.planning/phases/19-operator-ux-and-truthful-surface/19-CONTEXT.md` — admin/discovery truth-surface boundary (do not widen in Phase 22).
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-CONTEXT.md` — proof-style and repo-truth testing posture carried forward.

### Runtime And Web Seams
- `lib/lockspire/protocol/jar.ex` — JAR primitive composed by the new orchestrator; receives WR-01 / WR-02 / WR-03 hardening in Phase 22.
- `lib/lockspire/protocol/authorization_request.ex` — pipeline that gains the JAR consumption step; `@unsupported_params` and `validate_lockspire_request_uri/1` are the relevant seams.
- `lib/lockspire/protocol/pushed_authorization_request.ex` — `/par` orchestrator; `validate_pushed/2` is the splice point.
- `lib/lockspire/protocol/par_policy.ex` — effective PAR policy resolver; unchanged in Phase 22 but referenced for symmetry.
- `lib/lockspire/protocol/client_auth.ex` — PAR client authentication; runs unchanged. JAR is NOT a substitute auth method in v1.4.
- `lib/lockspire/protocol/discovery.ex` — discovery metadata; intentionally untouched in Phase 22 (`JAR-05` is Phase 23).
- `lib/lockspire/domain/client.ex` — `:jwks` (inline) is required for JAR-by-value; `:jwks_uri` deferred.
- `lib/lockspire/web/controllers/authorize_controller.ex` — thin delivery adapter; dispatch shape unchanged.
- `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex` — thin delivery adapter; dispatch shape unchanged.
- `lib/lockspire/config.ex` — host of the new `:jar_max_age_seconds` (or equivalent) configuration key.

### Proof Surfaces To Extend
- `test/lockspire/protocol/jar_test.exs` — extend with WR-01/WR-02/WR-03 cases.
- `test/lockspire/protocol/authorization_request_test.exs` — primary JAR validation matrix at the protocol seam.
- `test/lockspire/web/authorize_controller_test.exs` — browser-boundary proof for JAR rejection paths.
- `test/integration/phase15_par_authorization_e2e_test.exs` — surgical extension for JAR-by-value at PAR plus JAR-by-value at `/authorize`.
- `test/lockspire/protocol/pushed_authorization_request_test.exs` (if present) — `/par` orchestrator coverage for JAR splice.

### External Standards Reference
- RFC 9101 §5 (Request Object), §6.1 (parameter precedence), §10.2 (ignore-outer recommendation), §10.8 (cross-JWT confusion / `typ`).
- RFC 9126 §2.1 (PAR client authentication; substitution path NOT adopted in v1.4).
- RFC 7519 §4.1.3 (`aud` is StringOrURI; list form valid).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Protocol.Jar.decode/1`, `verify_signature/2`, `validate_claims/2` — pure-function primitives ready to compose. No HTTP, no policy, no telemetry inside.
- `Lockspire.Protocol.AuthorizationRequest.pushed_request_to_params/1` (authorization_request.ex:452-466) — canonical projection of structured-request into flat-param map. JAR claims project into the same shape.
- `Lockspire.Protocol.AuthorizationRequest.validate_with_client/3` — runs after either raw-params or PAR-projected-params arrive. Receives JAR-projected params unchanged.
- `Lockspire.Protocol.AuthorizationRequest.reject_request_uri_conflicts/1` (authorization_request.ex:393-411) — established pattern for "sealed-envelope" parameter-conflict rejection. JAR mirrors it.
- `Lockspire.Protocol.AuthorizationRequest.Error` (authorization_request.ex:49-63) — already carries free-form `reason_code` atom; new atoms slot in without struct changes.
- `Lockspire.Protocol.PushedAuthorizationRequest.validate_pushed/2` — splice point at `/par` after `ClientAuth.authenticate/3`.
- `Lockspire.Domain.Client.jwks` and `Client.jwks_uri` (client.ex:30-31) — schema fields already present; only `jwks` is consumed in v1.4.
- `Observability.emit/3` (already used in `AuthorizationRequest.emit_rejection/3`) — feeds reason_code into telemetry; new atoms surface automatically.

### Established Patterns
- Protocol modules own response-shape classification (`{:browser_error, ...}` vs `{:redirect_error, ...}`); Phoenix controllers stay thin.
- Internal atoms / struct fields hold durable / telemetry-relevant truth; the public OAuth wire surface stays narrow.
- Per-failure atoms (one per discriminable cause) — established in Phase 21's `validate_claims/2` taxonomy and the `AuthorizationRequest.Error.reason_code` set.
- One canonical end-to-end test extended surgically; focused protocol-seam matrix; thin web-boundary proof. No duplicated mega-suites.
- Strict, conservative Lockspire-issued-only handling for sealed envelopes (PAR `request_uri`); Phase 22 mirrors this for JAR.

### Integration Points
- New `Lockspire.Protocol.RequestObject` orchestrator composes `Jar.*` primitives, consumes outer `client_id` for client lookup, and projects JAR claims into the existing flat-param shape.
- Phase 22 is the moment three Phase 21 review items (WR-01 typ, WR-02 aud-list, WR-03 max_age) become reachable from an HTTP surface; they land here, not before, not later.
- Configuration: a single new Lockspire config knob for the JAR max-age ceiling (`:jar_max_age_seconds`, default 600). No other config additions; per-client policy fields are Phase 23.
- Client auth at `/par` is independent of JAR signature verification. Both run; both must succeed.

</code_context>

<specifics>
## Specific Ideas

- Project JAR claims through a function shaped like `pushed_request_to_params/1` so the validator surface stays uniform across raw-`/authorize`, PAR-resolved, and JAR-resolved paths. This keeps the test matrix tractable.
- Keep the orchestrator's contract narrow: input is `(outer_params, client, opts)`; output is `{:ok, projected_params}` or `{:browser_error, %Error{}}` / `{:redirect_error, %Error{}}` (matching the existing `validate/1` shape so the outer pipeline can `with`-chain it cleanly).
- Document inside the orchestrator's `@moduledoc` that JAR-by-reference (`request_uri` pointing to a JWT URL) and external `request_uri` are explicitly out of scope for v1.4 — and that this is enforced by `validate_lockspire_request_uri/1`.
- When extending `phase15_par_authorization_e2e_test.exs`, add a single new branch covering: client posts `request=<JWT>` to `/par`, receives `request_uri`, then completes `/authorize` with that `request_uri`. This is the canonical JAR-via-PAR-via-Lockspire flow and is the strongest end-to-end proof.
- Lockspire-config posture: `:jar_max_age_seconds` defaults to `600`. Hosts can override; document that lower values reduce replay window but may break clients with clock drift.

</specifics>

<deferred>
## Deferred Ideas

- `JAR-05` discovery metadata (`request_parameter_supported`, `request_object_signing_alg_values_supported`, etc.) — Phase 23.
- `JAR-06` operator/admin policy controls (per-client `require_signed_request_object`, global "JAR required" policy) — Phase 23.
- `JAR-04` JAR decryption — deferred indefinitely.
- `Client.jwks_uri` HTTP fetch + cache + retry — deferred (needs operator-visible failure surface, not in v1.4).
- JAR-by-reference (RFC 9101 §5.2 — `request_uri` pointing to an external JWT URL) — out of milestone scope; v1.4 keeps Lockspire's `request_uri` semantics as Lockspire-issued PAR references only.
- JAR substituting as client authentication at `/par` (RFC 9126 §2.1 optional path) — would require a new `token_endpoint_auth_method`, discovery changes, and admin UX; deferred.
- New `phase22_jar_authorization_e2e_test.exs` mega-suite — explicitly rejected; extend `phase15_par_authorization_e2e_test.exs` instead.
- Tightening `typ` from "permissive (allow absent or `oauth-authz-req+jwt` or `jwt`)" to "required (`oauth-authz-req+jwt` only)" — defer until Phase 24 or v1.5 once interop is proven; document the choice in `@moduledoc`.

### Reviewed Todos (not folded)
None — no matching todos in the backlog at Phase 22 kickoff.

</deferred>

---

*Phase: 22-request-object-integration*
*Context gathered: 2026-04-25 (assumptions mode)*
