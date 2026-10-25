<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use the settled OIDC Core 3.1.2.6 outcome: HTTP 400, no Location and no structured OAuth Error Response parameters for unsupported response_mode. Existing escaped human-readable first-party error text is allowed; this is not an OAuth redirect/JSON/form response to the client.
- **D-02:** Select only A171-003 for correction. Reuse the other five authorization cases and their existing owners; do not manufacture additional corrections, flows, mode support, admin copy or host account/session policy.
- **D-03:** Prefer classifying an unsupported binary mode as the existing browser error at the protocol boundary and delivering it through the existing thin controller/HTML path. Avoid a controller-only reason exception or a new error/rendering abstraction. This technical default is selected under delegated authority; preserve the existing error contract, static description and redaction.
- **D-04:** Preserve default/supported/query/JWT mode behavior and the distinct strict_message_signing_requires_jarm rejection. Preserve PAR's backchannel HTTP 400 OAuth JSON representation: validate_pushed already normalizes browser and redirect classifications to the same error. Verify the relevant existing shared-path tests; add only a material uncovered assertion if needed.
- **D-05:** Put the durable regression in the existing authorization-controller suite through Lockspire.Web.Router. Use the exact otherwise-valid OIDC condition: registered callback, authorization code, openid/email, nonce, state, valid S256 and unsupported binary mode. Prove actual RED before the correction and GREEN afterward; do not assert the old 302 as expected behavior. A valid query-mode control follows the existing fixture's normal host-owned handoff, without changing host policy to manufacture a control.
- **D-06:** Keep regression proof source-bound in Phase 172 summary/verification: actual commands, code revision, regression-file identity and before/after results. The older phase-local probe remains historical qualification evidence and is not relabeled as a successful run at new source.
- **D-07:** Declare ownership of the canonical Phase 171 ledger for the intentional regression-file and Phase 172 roadmap-selector changes. Review those diffs, update only affected manifest identities and aggregate digest with the existing old/new/source/reason audit pattern, and run the existing ledger contract. Preserve cases, original source identities, original receipt/probe bytes, frozen timestamp and qualification SHA. No blanket hash refresh or new evidence framework.
- **D-08:** Add no dependency, framework, public API, migration, input refresh or external profile run. Use existing ExUnit, OTP/Phoenix primitives and private helpers. Choose the smallest coherent internal change; strict formatting, lint and focused relevant checks must pass before completion.

### the agent's Discretion
All assumptions were Confident or Likely. Auto mode selected the recommended protocol-boundary approach within the user's explicit autonomous-unblock/follow-recommendations authority. This is recorded agent maintainer judgment, not fabricated human confirmation. Escalate an actually new product boundary, public API, security posture or support decision if evidence requires one. No such decision was identified.

### Deferred Ideas (OUT OF SCOPE)
P171-005 pushed-scope authority is Phase 173. Packaged-host proof, combined candidate/CI gates and delivery are Phase 174. External profiles remain optional/unlaunched until separately selected preparation; no automatic overlap/interruption guarantee or certification is added. SEC-01 and other future milestone candidates retain their existing triggers.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTHR-01 | A client receives the applicable safe response for each qualified authorization-error case, preserving exact registered-redirect validation and returning no attacker-controlled redirect for an invalid client/redirect combination. | Reuse A171-001 exact-redirect proof and A171-003 existing first-party HTTP error route; no duplicate correction. |
| AUTHR-02 | A client receives the specified error/state and supported response-mode representation for each selected valid-callback case, with reserved/error parameters encoded unambiguously and adversarial cases covered. | Correct A171-003 at protocol classification; test browser delivery through Router and preserve existing callback/state tests and strict/JWT mode proof. |
| AUTHR-03 | A client using selected prompt=none or max_age cases receives the applicable protocol outcome and authentication-freshness claims without an inappropriate host login redirect, while account/session authority stays host-owned. | Carry A171-004/005/006 and Phase 37 integration evidence forward; this correction does not enter the host account/session flow. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded companion library; do not make it a required standalone service or a Sigra module. `[VERIFIED: AGENTS.md:17-19]`
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. `[VERIFIED: AGENTS.md:19]`
- Keep account resolution, claims, login redirects, branding, and product policy at the narrow host-owned seam. `[VERIFIED: AGENTS.md:20]`
- Keep this phase within v1's existing OAuth/OIDC scope; do not add SAML, LDAP/AD federation, hosted auth, or CIAM scope. `[VERIFIED: AGENTS.md:21]`
- Preserve existing security defaults: PKCE S256, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh rotation/family revocation, no implicit flow or `alg=none`, and strong redaction. `[VERIFIED: AGENTS.md:43-50]`
- No admin UI copy is in scope. If a future implementation changes admin text, first use PRODUCT.md's personas/vocabulary map, use its “UI says” term, add new concepts there, and record retired wording. `[VERIFIED: AGENTS.md:52-57]`
- Project stack declarations are Phoenix 1.8.5, LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+, Oban 2.21.x, and OpenTelemetry 1.6.0; Bandit is for host/demo/clean-room apps, not a Lockspire dependency. This phase adds none. `[VERIFIED: AGENTS.md:23-31]`

# Phase 172: Authorization Responses — Research

**Researched:** 2026-10-24
**Domain:** Elixir/Phoenix OAuth/OIDC authorization response validation
**Confidence:** HIGH for scoped implementation and repository contracts

## Summary

The only selected code correction is A171-003: unsupported binary `response_mode` currently becomes a redirect-classified protocol error. The qualified source-host probe at source `30e385a33bb2a7f67d94c558dedf7691ecde5863` observed HTTP 302 to the registered callback with OAuth `error`, `error_description`, `iss`, and `state`; its valid OIDC control passed. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json#A171-003; .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json]` OIDC Core 3.1.2.6 requires HTTP 400 without Error Response parameters for an unsupported Response Mode. `[CITED: OIDC Core §3.1.2.6](https://openid.net/specs/openid-connect-core-1_0.html#AuthError)` The first-party HTML error body may contain the existing escaped human-readable description; do not encode the protocol error into a callback, JSON, or form response. `[VERIFIED: lib/lockspire/web/controllers/authorize_html.ex:8-23; .planning/phases/172-authorization-responses/172-CONTEXT.md D-01]`

The smallest coherent correction is to classify only the unsupported binary-mode branch in `AuthorizationRequest.validate_response_mode/1` as the existing browser error. `AuthorizeController.show/2` already maps that disposition to HTTP 400 through `AuthorizeHTML.error_page/1`, which escapes the description and reason. Keep the existing static error description and reason code. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:582-592; lib/lockspire/web/controllers/authorize_controller.ex:18-39,164-169; lib/lockspire/web/controllers/authorize_html.ex:8-23]` This selection follows Phase 172 D-03; it adds no dependency, public contract, host policy, response mode, UI copy, or new renderer. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-03, D-08]`

**Primary recommendation:** Change the unsupported-mode protocol classification, prove the exact controller regression red at the qualified behavior and green after the change, then reuse existing mode, strict-signing, PAR normalization, callback/state, and silent-authentication proof.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Classify supported versus unsupported authorization response modes | API / Backend | — | `AuthorizationRequest` validates protocol inputs before delivery. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:389-408,582-623]` |
| Render unsafe authorization validation errors | Frontend Server (SSR) | API / Backend | The controller delivers the existing browser disposition as a first-party HTTP 400 HTML page. `[VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex:34-38,164-169]` |
| Resolve account, login, and consent handoff | API / Backend | Frontend Server (SSR) | Lockspire delegates account and login authority to the host resolver; this phase must not change it. `[VERIFIED: AGENTS.md:9,20; .planning/phases/172-authorization-responses/172-CONTEXT.md D-02]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Existing project toolchain: Elixir 1.19.5 / OTP 28.5 | Protocol validation and application runtime | Phase 171 used this exact runtime for source-host qualification; no upgrade is in scope. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json]` |
| Phoenix | 1.8.5 | Router, ConnTest, controller and HTML response | The existing authorization controller suite already exercises `Lockspire.Web.Router` and the production delivery path. `[VERIFIED: AGENTS.md:25; test/lockspire/web/authorize_controller_test.exs:674-677]` |
| ExUnit | Existing project test stack | Regression and contract assertions | Existing tests already cover authorization mode validation and HTTP outcomes. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Plug.HTML` | Existing locked dependency | Escape first-party error description and reason in HTML | Reuse `AuthorizeHTML.error_page/1`; do not add rendering helpers. |
| `URI` | OTP | Parse and encode redirect query parameters in existing redirect path | Existing redirect-error path only; unsupported mode must bypass it. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Protocol-level browser disposition for unsupported mode | Controller-only special case keyed on `:invalid_response_mode` | The controller already branches on a stable disposition. A local special case would make delivery behavior depend on a reason code and leave protocol classification misleading; D-03 selects protocol classification. |
| Existing escaped HTML error page | New error renderer or a structured OAuth response | Extra abstraction is unnecessary and could emit structured error parameters prohibited for this case. |

No installation is required. D-08 prohibits adding packages or framework dependencies. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-08]`

## Architecture Patterns

### System Architecture Diagram

```text
GET /authorize
      |
      v
Lockspire.Web.Router -> AuthorizeController.show/2
      |
      v
AuthorizationRequest.validate/1
      |
      +-- valid response_mode ------> validated request -> existing host resolver / flow
      |
      +-- unsupported binary mode --> {:browser_error, Error}
                                      |
                                      v
                          HTTP 400 + escaped first-party HTML
                          (no Location, no OAuth response params)
```

### Recommended Project Structure

No structural change. Keep the protocol branch in `lib/lockspire/protocol/authorization_request.ex` and the durable HTTP regression in `test/lockspire/web/authorize_controller_test.exs`; use existing controller and HTML helpers. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:582-592; test/lockspire/web/authorize_controller_test.exs:674-694]`

### Pattern 1: Validate disposition before host handoff

**What:** `AuthorizationRequest.validate/1` returns one of the existing validation outcomes; `AuthorizeController.show/2` renders browser errors before calling host account resolution. The browser helper creates an error with no callback or state, while the redirect helper carries the registered callback and normalized state. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:970-987; lib/lockspire/web/controllers/authorize_controller.ex:18-39]`

**When to use:** Errors that cannot safely be encoded with a requested/unsupported response mode. Keep the unsupported binary-mode branch on the browser side of this seam.

**Existing contract (verbatim):** In `lib/lockspire/protocol/authorization_request.ex:970-987`, `browser_error/3` sets `redirect_uri: nil` and `state: nil`; `redirect_error/4` sets `redirect_uri: params["redirect_uri"]` and `state: normalize_optional_string(params["state"])`. In `lib/lockspire/web/controllers/authorize_controller.ex:34-38`, `{:browser_error, %Error{} = error}` calls `render_browser_error(conn, error, :bad_request)`, while `{:redirect_error, %Error{} = error}` calls `redirect(conn, external: redirect_location(error))`.

**Implementation direction:** Preserve the existing error text `"response_mode is invalid or unsupported"` and reason `:invalid_response_mode`; only switch this branch to the browser classification. Those exact values are currently defined at `authorization_request.ex:582-592`. Do not alter default resolution (`nil` to `query`, `jwt` to `query.jwt`) or the supported-mode set (`query`, `fragment`, `form_post`, `jwt`, `query.jwt`, `fragment.jwt`, `form_post.jwt`) at lines 15-24 and 600-602.

### Pattern 2: Exercise the real router for HTTP behavior

`AuthorizeControllerTest.call_authorize/1` builds `GET /authorize` and calls `Lockspire.Web.Router` directly (`test/lockspire/web/authorize_controller_test.exs:674-677`). Add the regression beside the existing authorization validation tests, using this helper. Its `valid_params/1` defaults to `scope=profile email`, `prompt=consent`, state, authorization code, registered callback, and S256 (`:683-693`); it does not supply OIDC `openid` scope or nonce. `[VERIFIED: test/lockspire/web/authorize_controller_test.exs:683-693]` For both the unsupported-mode candidate and query-mode control, explicitly override scope to `openid email` and provide nonce; vary only `response_mode` between candidate and control. Keep the registered redirect URI and valid state/S256 intact. Use the existing login resolver and its ordinary handoff; do not change host resolver policy to synthesize consent. `[VERIFIED: test/lockspire/web/authorize_controller_test.exs:1-11; .planning/phases/172-authorization-responses/172-CONTEXT.md D-05]`

The candidate should assert HTTP 400, no `Location`, and no OAuth response parameters in the body (while permitting the escaped existing first-party explanation). The control should establish that the same valid OIDC request with query mode follows the fixture's regular host-owned handoff. Do not codify the prior 302 as expected behavior. `[CITED: OIDC Core §3.1.2.6](https://openid.net/specs/openid-connect-core-1_0.html#AuthError); [VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-01, D-05]`

### Existing mode and strict-signing contracts

`validate_with_client/3` invokes `validate_response_mode/1` before `validate_strict_message_signing_response_mode/3` (`authorization_request.ex:389-408`). Supported raw modes rejected for strict message signing continue to return `:strict_message_signing_requires_jarm`; supported JWT modes continue to normalize/validate as currently tested. Existing `test/lockspire/protocol/authorization_request_test.exs:288-364` covers raw/omitted strict rejection, JWT acceptance, consumed-PAR strict rejection, and normalization. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:389-408,604-623; test/lockspire/protocol/authorization_request_test.exs:288-364]` Preserve and rerun those tests; do not reinterpret an unsupported binary mode as a raw-but-supported mode.

For PAR, `validate_pushed/3` normalizes both `{:browser_error, error}` and `{:redirect_error, error}` to `{:error, error}` (`authorization_request.ex:133-156`). Preserve the existing PAR backchannel HTTP 400 OAuth JSON response; verify its existing focused path rather than changing PAR delivery. `[VERIFIED: lib/lockspire/protocol/authorization_request.ex:133-156; .planning/phases/172-authorization-responses/172-CONTEXT.md D-04]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Safe handling of an error when its response mode is unsupported | Controller reason-code exception, callback URL, form response, or JSON response | Existing browser disposition and `AuthorizeHTML.error_page/1` | The existing boundary already prevents redirect and supplies HTTP 400 HTML. |
| HTML escaping | String concatenation or custom escaping | `Plug.HTML.html_escape_to_iodata/1` in `AuthorizeHTML.error_page/1` | The helper already escapes the description and reason before rendering. |
| Duplicate qualification framework | New probe runner or copied ledger | Existing Phase 171 frozen case, selective manifest audit format, and ledger contract | Preserve historical observations and keep evidence provenance reviewable. |

**Key insight:** `AuthorizationRequest.Error` already separates protocol error data from delivery disposition. The fix is a one-branch classification correction; delivery and redaction already exist.

## Common Pitfalls

### Pitfall 1: Returning a redirect for a mode that cannot carry an error
**What goes wrong:** The client receives HTTP 302 with OAuth error parameters in its callback despite the requested mode being unsupported.
**Why it happens:** The current `validate_response_mode/1` branch returns `:redirect_error`.
**How to avoid:** Classify unsupported binary values as the existing browser error and assert no `Location`, no structured error parameters, and HTTP 400 through Router.
**Warning signs:** `conn.status` is 302/303 or `Location` points at the registered callback.

### Pitfall 2: An under-specified OIDC regression
**What goes wrong:** The test fails earlier for missing nonce or `openid`, so it does not isolate response-mode behavior.
**Why it happens:** The controller fixture helper defaults to `profile email` without a nonce.
**How to avoid:** Set `scope` to `openid email`, supply nonce and preserve registered callback, authorization code, state, and valid S256; use a query-mode control through the same resolver.
**Warning signs:** The response mentions missing nonce, or the request differs in another authorization input besides `response_mode`.

### Pitfall 3: Broadening behavior while fixing the branch
**What goes wrong:** Supported response-mode defaults, strict message signing, JARM, or PAR representations change unintentionally.
**Why it happens:** The validation branch is near mode normalization and strict profile checks.
**How to avoid:** Keep the supported allow-set and default resolution unchanged; run the existing authorization request mode tests and relevant controller/PAR proof.
**Warning signs:** A supported-mode test changes, `strict_message_signing_requires_jarm` changes, or PAR begins returning HTML.

### Pitfall 4: Making the frozen qualification appear to have changed historically
**What goes wrong:** Hashes or source identities are refreshed wholesale, or a previous counterexample is rewritten as a success.
**Why it happens:** The manifest hashes the whole regression file and a Phase 172 roadmap selector.
**How to avoid:** Review and update only those affected manifest identities plus the ordered aggregate input digest using the existing `input_manifest_audits` old/new/source/reason pattern. Preserve case/probe/source observations, original receipt hash, `frozen_at`, and `qualification_sha`. Run the ledger contract after intentional metadata changes.
**Warning signs:** Unrelated manifest entries change, a historical source observation is restamped, or a manifest failure is mistaken for the new regression's RED.

## Evidence and Validation Plan

### Reuse rather than duplicate

The Phase 171 frozen matrix keeps A171-003 as the sole correction for this phase. Reuse A171-001/002 exact callback and state proof and A171-004/005/006 prompt-none, `max_age`, and host-provided `auth_time` proof; use their existing Phase 37 integration owner. Reuse authorization mode/strict-signing unit tests and PAR shared-path tests. Add only an assertion that materially closes a gap in the A171-003 controller regression. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json; .planning/phases/172-authorization-responses/172-CONTEXT.md D-02, canonical_refs]`

The original qualified HTTP counterexample is historical evidence: its recorded command was `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs --seed 0`; it completed two named normative failures, with both controls passed and zero protocol passes. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json]` Do not rerun the combined Phase 171 intentional-red probe as part of Phase 172, or claim its old source/file hash is new-source evidence. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-06]`

### RED/GREEN sequence

1. First reconcile the known intentional planning metadata changes for the Phase 171 ledger (controller regression file and Phase 172–173 roadmap selector) with reviewed selective audits. Preserve frozen case and qualification identities. Run the ledger contract to isolate this known metadata state. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-07; test/lockspire/qualification_ledger_contract_test.exs:1296-1305]`
2. Add the exact regression to `test/lockspire/web/authorize_controller_test.exs`, then run that single named test against the unchanged protocol code and capture its actual normative RED, source revision, and test-file identity. Confirm setup/control passed and that the observed failure is the HTTP response assertion, not compilation, fixture, database, or manifest drift. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-05-D-07]`
3. Change the protocol classification, then rerun the same regression for GREEN and run the focused shared mode/PAR/controller proof. Record commands, source revision, regression-file identity, and actual before/after results in the Phase 172 summary/verification.
4. Run the existing qualification ledger contract, strict Credo, and formatter check after code edits. Do not count manifest failure as regression RED; report actual test counts and results only after execution. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-08; .planning/phases/171-accepted-baseline-finding-qualification/171-04-SUMMARY.md]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / OTP | ExUnit regression and project checks | ✓ in Phase 171 scoped runtime evidence | Elixir 1.19.5 / OTP 28.5 | Use the same explicit `ASDF_*` runtime selection. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json]` |
| PostgreSQL test database | Router and protocol tests using `Lockspire.TestRepo` | ✓ in Phase 171 selected test execution | Dedicated DB name `lockspire_171_main_20261024b` | Use an owned fresh database; do not use shared historical test DB. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json; .planning/phases/172-authorization-responses/172-CONTEXT.md]` |
| Python OIDF/FAPI profile dependencies | Optional external profiles | Not required | — | No fallback needed; external profile runs are explicitly out of scope. |

No package installation, runtime upgrade, migration, or external profile run is required. Phase 171 recorded a successful local runtime preflight and focused test run with the exact runtime/database prefix above; planning work does not claim a fresh check. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-08; .planning/phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.ConnTest (existing project stack; no dependency change) |
| Config file | Existing `mix.exs` / `test/test_helper.exs`; no new config required |
| Quick run command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/web/authorize_controller_test.exs` |
| Shared mode/PAR proof | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs` |

Include `--include integration` when running the Phase 37/15 integration owner; its tag must be explicit. The Phase 171 verified combined command was `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs`; reuse only relevant paths and do not repeat unrelated baseline/profile checks. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md]`

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTHR-01 | Reused invalid redirect rejection and exact callback safety; unsupported mode has no redirect | Router integration/controller | Focused controller test command above | Existing file; add A171-003 regression |
| AUTHR-02 | Unsupported mode gives HTTP 400 without `Location` or OAuth error parameters; supported query control remains on regular host handoff | Router integration/controller | Focused controller test command above | Existing file; new assertions planned, not yet run |
| AUTHR-03 | Prompt-none and freshness outcomes remain valid with host account/session ownership | Integration | `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs` with explicit runtime/database prefix above | Existing owner; reuse current proof, no duplicate case |

### Sampling Rate

- **Per task commit:** Focus the named A171-003 HTTP regression (`mix test test/lockspire/web/authorize_controller_test.exs:LINE`, replacing `LINE` with the actual test line after adding it).
- **Per wave merge:** Controller suite plus authorization request and pushed authorization request suites.
- **Phase gate:** Relevant Phase 37 integration, ledger contract, `mix credo --strict`, and `mix format --check-formatted` for edited files green; record exact output and source identity in phase evidence. `[VERIFIED: .planning/phases/171-accepted-baseline-finding-qualification/171-04-SUMMARY.md]`

### Wave 0 Gaps

- No framework/configuration gap. The new A171-003 regression is a planned implementation change in the existing controller suite, not an existing passing test. Run it red before protocol correction and green afterward.
- Existing integration and ledger-contract owners are present. Do not claim their Phase 171 results as execution at Phase 172 source.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve host-owned account resolution; no authentication-policy change. |
| V3 Session Management | yes | Preserve host-owned sessions and login redirect seam. |
| V4 Access Control | yes | Preserve exact registered redirect validation and no attacker-controlled callback. |
| V5 Input Validation | yes | Reject unrecognized response-mode values before host handoff; no broadened allow-list. |
| V6 Cryptography | yes | Preserve S256 and existing strict-signing/JARM checks; do not change cryptographic policy. |

### Known Threat Patterns for Phoenix / OAuth authorization

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Redirecting an OAuth error when response mode is unsupported | Spoofing / Information disclosure | Browser error disposition, HTTP 400, and no callback `Location` or structured response parameters. |
| Unsafe first-party error HTML interpolation | Cross-site scripting | Reuse `Plug.HTML.html_escape_to_iodata/1` through `AuthorizeHTML.error_page/1`. |
| Changing callback or host authentication ownership during response fix | Spoofing / Elevation of privilege | Preserve registered redirect validation and host account/session resolver boundary. |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Send unsupported-mode OAuth errors to the callback using a redirect | Return HTTP 400 without OAuth Error Response parameters | OIDC Core §3.1.2.6; current phase corrects reproduced A171-003 behavior | The requested response mode cannot safely represent the error. |

**Deprecated/outdated:** Redirecting A171-003's unsupported binary mode with OAuth error parameters is the reproduced behavior being corrected; do not retain it as a test expectation.

## Assumptions Log

No unresolved product, API, security, or support assumptions remain. The exact new regression still requires its prescribed RED/GREEN execution as implementation evidence; this is not an open planning decision. `[VERIFIED: .planning/phases/172-authorization-responses/172-CONTEXT.md D-05-D-08]`

## Open Questions

None. The protocol outcome, narrow implementation location, test owner, carried-forward proof, and ledger update rules are settled by CONTEXT.md and the inspected source.

## Sources

### Primary (HIGH confidence)

- [OIDC Core 1.0, §3.1.2.6 Authorization Endpoint Error Response](https://openid.net/specs/openid-connect-core-1_0.html#AuthError) — normative HTTP 400/no Error Response parameter rule, as already browsed and verified for Phase 171 on 2026-10-24.
- `lib/lockspire/protocol/authorization_request.ex:389-408, 582-623, 970-987` — current validation order, unsupported-mode disposition, strict signing branch, and browser/redirect error structures.
- `lib/lockspire/web/controllers/authorize_controller.ex:18-39, 164-169` and `lib/lockspire/web/controllers/authorize_html.ex:8-24` — existing disposition delivery and escaped error page.
- `test/lockspire/web/authorize_controller_test.exs:674-694` — real Router helper and fixture defaults.
- `test/lockspire/protocol/authorization_request_test.exs:288-364` — strict-signing and supported JWT-mode regression owners.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` (A171-003 case and `input_manifest_audits`) and `171-QUALIFICATION-PROBE.json` — qualified counterexample and original source-bound observation.
- `.planning/phases/172-authorization-responses/172-CONTEXT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/METHODOLOGY.md`, `.planning/STATE.md`, and `AGENTS.md` — locked scope, host seam, project constraints, and phase requirements.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — reuses locked project stack and existing tested runtime.
- Architecture: HIGH — directly inspected the protocol, controller, HTML renderer, and regression owners.
- Pitfalls: HIGH — tied to the frozen A171-003 counterexample and existing fixtures/contracts.

**Research date:** 2026-10-24
**Phase 172 tests run during research:** None. Counts and results above are either explicitly historical Phase 171 evidence or planned validation; they are not new executions.
**Valid until:** 2026-11-23 for repository patterns; OIDC source remains normative unless superseded.
