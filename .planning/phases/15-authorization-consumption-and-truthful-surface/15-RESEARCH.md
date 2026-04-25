# Phase 15: Authorization Consumption and Truthful Surface - Research

**Researched:** 2026-04-24
**Domain:** PAR-backed `/authorize` consumption and truthful discovery/docs in an embedded Phoenix/Elixir authorization server
**Confidence:** HIGH

## User Constraints

- No `15-CONTEXT.md` exists, so planning must treat `AGENTS.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, milestone research, and Phase 14 outputs as the authoritative scope inputs.
- Phase 15 is limited to `PAR-02` and `PAR-03`: consume Lockspire-issued PAR `request_uri` references inside the existing authorization code + PKCE path and publish truthful support metadata/docs for that implemented slice only.
- Phase 15 must not broaden scope into JAR-by-value, generic external `request_uri`, dynamic client registration, device flow, hosted-auth posture, or any wider CIAM claim.
- Lockspire stays an embedded companion library with strong boundaries between protocol core, storage, Plug/Phoenix adapters, generators, and host seams.
- Existing security defaults remain binding: exact-match redirect URI validation, PKCE S256 by default, no implicit flow, no `alg=none`, hashed-at-rest sensitive references, and strong redaction in logs and operator-facing surfaces.
- Phase 14 already established that PAR references are durable, opaque, and stored by `request_uri_hash`, not plaintext.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-02 | OAuth clients can complete the existing authorization code + PKCE flow by presenting a PAR-issued `request_uri`, and Lockspire enforces expiry, client binding, and replay-resistant single use for that reference. | Resolve PAR references in `AuthorizationRequest` before normal `/authorize` validation output reaches `AuthorizationFlow`, consume them atomically through the repository/store layer, and reject expired, missing, replayed, or mismatched-client references with OAuth-safe errors. |
| PAR-03 | Integrators can discover PAR support through truthful metadata and docs that advertise only the implemented PAR slice and do not imply request-object-by-value, dynamic registration, or device-flow support. | Publish `pushed_authorization_request_endpoint` only when `/par` is mounted, update `README.md` and `docs/supported-surface.md` from “PAR unsupported” to “PAR-supported narrow slice,” and extend existing contract tests so repo-owned truth stays aligned. |
</phase_requirements>

## Summary

Phase 15 should finish the narrow PAR wedge by treating a Lockspire-issued `request_uri` as a server-owned pointer back into the existing authorization request path, not as a second flow and not as portable request-object support. The safest shape in this codebase is to resolve the PAR record inside `Lockspire.Protocol.AuthorizationRequest`, merge its validated stored payload into the normal `/authorize` validation pipeline, require the presenting `client_id` to match the issuing client, and mark the reference consumed through an atomic storage operation so replay cannot reopen the same request. That preserves the current `%Validated{}` contract for `AuthorizationFlow` and keeps Phoenix controllers thin.

Discovery and docs should follow the repo’s existing “mounted routes define truth” posture. Once `/par` exists, discovery may add `pushed_authorization_request_endpoint`, but it should still omit request-object and unrelated feature metadata. Public docs and release-readiness contract tests must be updated from “PAR unsupported” to a narrower statement: Lockspire supports PAR only as a server-issued `request_uri` extension of the existing authorization code + PKCE path.

**Primary recommendation:** split execution into three plans: one for atomic `request_uri` consumption in the authorization pipeline, one for discovery/docs truth-surface updates, and one for end-to-end plus contract-test coverage of the PAR-backed flow and truth claims.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `request_uri` resolution at `/authorize` | API / Backend | Database / Storage | The decision belongs in protocol validation before host-account handoff and before `AuthorizationFlow` starts. |
| Single-use and client-binding enforcement | Database / Storage | API / Backend | Replay resistance is only trustworthy if consume/read is atomic at the durable store boundary. |
| Redirect-safe/browser-safe error shaping for bad PAR references | API / Backend | Frontend Server | Existing `/authorize` already distinguishes browser-rendered versus redirect-safe errors; PAR resolution should preserve that split. |
| Discovery metadata truth | API / Backend | Frontend Server | `Lockspire.Protocol.Discovery` already derives truthful metadata from mounted routes. |
| Support-surface documentation and preview claim alignment | Docs / Product Surface | Test / Contracts | README and support docs are currently locked behind explicit contract tests and must be updated together. |

## Recommended Project Structure

```text
lib/
├── lockspire/protocol/authorization_request.ex          # resolve and validate PAR-backed authorize input
├── lockspire/storage/pushed_authorization_request_store.ex
├── lockspire/storage/ecto/repository.ex                 # atomic consume/read semantics
└── lockspire/protocol/discovery.ex                      # conditional PAR discovery metadata

docs/
├── supported-surface.md                                 # truthful PAR support wording
└── install-and-onboard.md or README.md                  # narrow PAR wording where preview surface is described

test/
├── lockspire/protocol/authorization_request_test.exs    # request_uri resolution and negative paths
├── lockspire/web/authorize_controller_test.exs          # browser path behavior with PAR
├── lockspire/web/discovery_controller_test.exs          # discovery truth metadata
├── lockspire/release_readiness_contract_test.exs        # docs/support truth contract
└── integration/phase15_par_authorization_e2e_test.exs   # PAR-backed auth-code + PKCE flow
```

## Architecture Patterns

### Pattern 1: Resolve PAR Before Building the Canonical `%Validated{}`

`AuthorizationRequest.validate/1` already owns the typed `%Validated{}` output that `AuthorizeController` and `AuthorizationFlow` depend on. Phase 15 should preserve that contract. Add a resolution step ahead of the normal validation pipeline so a request containing Lockspire-issued `request_uri` becomes a normal validated authorization request with the stored payload and the presenting `client_id`.

Use this shape:

- If no `request_uri` is present, keep today’s path unchanged.
- If `request_uri` is present, reject any conflicting unsupported modes and resolve only Lockspire-issued PAR references.
- Require the presenting `client_id` to match the client bound to the stored PAR row.
- Convert the resolved data back into the same canonical params/validated form already used by `/authorize`.

### Pattern 2: Consume Once in Storage, Not in the Controller

`fetch_active_pushed_authorization_request/1` is not sufficient for replay resistance because it allows read-then-use races. The store contract should grow an atomic consume/read operation that locks the row, checks expiry, and marks it consumed or deletes it inside a transaction. The repository already has a transaction/locking pattern in interaction state transitions; Phase 15 should reuse that style for PAR references.

Expected semantics:

- First valid use returns the stored PAR request.
- Expired rows behave like missing/invalid references.
- Second use of the same `request_uri` is rejected as replay.
- A wrong-client attempt must not make the row reusable again.

### Pattern 3: Keep `/authorize` Error Semantics Stable

`AuthorizeController` currently renders first-party browser errors for missing/unsafe redirect context and uses redirect-safe errors when a valid redirect target exists. PAR resolution should feed into the same error model rather than inventing a new HTTP shape. Bad or stale `request_uri` values should fail safely without exposing stored payloads or widening redirect behavior.

### Pattern 4: Mounted-Route Discovery Truth

`Lockspire.Protocol.Discovery` already derives endpoint metadata from mounted routes. Phase 15 should add `pushed_authorization_request_endpoint` only when `/par` is mounted, and should not publish `request_object_signing_alg_values_supported`, `request_parameter_supported`, or unrelated metadata that would imply JAR or broader request-object support.

### Pattern 5: Docs Claims Must Move with Contract Tests

`README.md`, `docs/supported-surface.md`, and `test/lockspire/release_readiness_contract_test.exs` already encode the repo’s public-truth posture. Phase 15 should update them together. The wording should remain narrow:

- PAR is supported as a server-issued `request_uri` extension of the existing authorization code + PKCE flow.
- Unsupported items still include device flow, dynamic client registration, hosted auth, SAML, LDAP, and broader request-object modes.
- Avoid language that suggests complete request-object support or broad certification claims.

## Anti-Patterns to Avoid

- Do not keep honoring a full raw authorization request alongside `request_uri` if that would create ambiguity about which request data wins.
- Do not resolve PAR in the Phoenix controller or host seam; it belongs in protocol/storage layers.
- Do not store plaintext `request_uri` durably just to make consume logic easier.
- Do not publish discovery keys that imply JAR-by-value or external `request_uri` support.
- Do not update docs to “PAR supported” without qualifying the supported slice and preserving the rest of the preview boundary.

## Concrete File Targets

- `lib/lockspire/protocol/authorization_request.ex`
  Extend validation to resolve Lockspire-issued `request_uri` references into canonical authorization params and preserve current typed output plus telemetry/error behavior.
- `lib/lockspire/storage/pushed_authorization_request_store.ex`
  Add an atomic consume/read callback for single-use PAR resolution.
- `lib/lockspire/storage/ecto/repository.ex`
  Implement transaction-backed consume semantics with expiry and client-binding enforcement.
- `lib/lockspire/protocol/discovery.ex`
  Publish `pushed_authorization_request_endpoint` only when the route is mounted.
- `README.md`
  Update preview support wording from “PAR not included” to the narrow PAR-backed auth-code + PKCE slice.
- `docs/supported-surface.md`
  Move PAR from unsupported to supported, while explicitly excluding JAR-by-value, device flow, DCR, and broader CIAM claims.
- `test/lockspire/protocol/authorization_request_test.exs`
  Add request-uri success and negative-path coverage.
- `test/lockspire/web/authorize_controller_test.exs`
  Cover controller behavior for PAR-backed `/authorize`.
- `test/lockspire/web/discovery_controller_test.exs`
  Assert conditional `pushed_authorization_request_endpoint` truth.
- `test/lockspire/release_readiness_contract_test.exs`
  Update public-claim contract expectations.
- `test/integration/phase15_par_authorization_e2e_test.exs`
  Prove the end-to-end PAR-backed authorization code + PKCE flow.

## Validation Recommendations

- Plan-level verification should run the focused protocol/controller/discovery/doc contract tests after each relevant task.
- Wave-end verification should include the new PAR E2E test plus `MIX_ENV=test mix test.fast`.
- Negative-path coverage must include expired, replayed, and wrong-client `request_uri` usage in executable tests before the phase can close.

## Key Insight

The core risk in Phase 15 is not adding one more `/authorize` branch. It is preserving a single source of truth for authorization-request state while making a stored PAR reference one-time, client-bound, and honest in discovery/docs. The safest implementation is to make PAR disappear into the existing validated authorization-request contract as early as possible, and to make replay resistance a repository-level guarantee rather than a controller convention.
