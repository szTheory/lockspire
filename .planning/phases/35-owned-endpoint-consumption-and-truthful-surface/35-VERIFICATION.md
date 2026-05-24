---
phase: 35-owned-endpoint-consumption-and-truthful-surface
verified: 2026-04-28T19:58:59Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 11/12
  gaps_closed:
    - "Replay, missing `ath`, wrong `ath`, wrong proof key, or malformed proof failures return deterministic `401 invalid_token` userinfo failures with truthful `WWW-Authenticate` headers."
  gaps_remaining: []
  regressions: []
---

# Phase 35: Owned Endpoint Consumption and Truthful Surface Verification Report

**Phase Goal:** The Lockspire-owned protected-resource and support surfaces agree with the shipped DPoP slice.
**Verified:** 2026-04-28T19:58:59Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `userinfo` accepts DPoP-bound access tokens only when the accompanying proof validates against the token's stored confirmation state. | ✓ VERIFIED | `Lockspire.Protocol.Userinfo` still branches on durable `Token.cnf["jkt"]` and delegates bound-token validation to `ProtectedResourceDPoP` at `lib/lockspire/protocol/userinfo.ex:65-75`; HTTP proof remains in `test/lockspire/web/userinfo_controller_test.exs:156-172`. |
| 2 | Bearer access tokens still work on `GET /userinfo` exactly as before. | ✓ VERIFIED | Bearer parsing and unchanged bearer path remain at `lib/lockspire/protocol/userinfo.ex:50-61,77-80`; bearer success still passes in `test/lockspire/web/userinfo_controller_test.exs:119-136`. |
| 3 | Replay, missing `ath`, wrong `ath`, wrong proof key, or malformed proof failures return deterministic `401 invalid_token` userinfo failures with truthful `WWW-Authenticate` headers. | ✓ VERIFIED | `Lockspire.Web.UserinfoController` now treats `:invalid_jwt`, `:invalid_dpop_proof`, `:invalid_access_token_binding`, and `:invalid_claims_options` as DPoP-aware challenge reasons at `lib/lockspire/web/controllers/userinfo_controller.ex:49-75`; malformed-proof regression coverage was added at `test/lockspire/web/userinfo_controller_test.exs:236-248`, while replay/wrong-`ath`/wrong-key coverage remains at `test/lockspire/web/userinfo_controller_test.exs:194-233`. |
| 4 | Discovery advertises the DPoP slice truthfully and only because the mounted repo-proven surface supports it. | ✓ VERIFIED | Discovery still derives metadata from mounted routes and only publishes DPoP metadata when both `token_endpoint` and `userinfo_endpoint` are present at `lib/lockspire/protocol/discovery.ex:157-171`; publish/omit assertions remain in `test/lockspire/protocol/discovery_test.exs:99-122` and `test/lockspire/web/discovery_controller_test.exs:111-140`. |
| 5 | The published DPoP algorithm metadata comes from the validator allowlist, not a hand-maintained second list. | ✓ VERIFIED | `Lockspire.Protocol.Discovery` still reads `DPoP.signing_alg_values_supported/0` directly at `lib/lockspire/protocol/discovery.ex:157-163`, with exact-equality tests unchanged. |
| 6 | Public support docs say Lockspire proves DPoP only on `/token` and Lockspire-owned `userinfo`, not generic host protected resources. | ✓ VERIFIED | Narrow support wording remains at `docs/supported-surface.md:67-69` and is still pinned by `test/lockspire/release_readiness_contract_test.exs:223-230`. |
| 7 | Release contract tests fail if discovery/docs drift ahead of the shipped DPoP slice. | ✓ VERIFIED | Discovery publish/omit tests and the release-readiness contract remain intact; no regression evidence found. |
| 8 | Admin and DCR flows can explicitly place clients into bearer or DPoP mode without repo-internal edits. | ✓ VERIFIED | Global policy, client override, and DCR mapping remain wired through durable DPoP policy state across the same verified seams from the initial pass; no regressions found. |
| 9 | Operators can set a global DPoP policy from a narrow admin page that mirrors the shipped PAR policy workflow. | ✓ VERIFIED | Route and persistence wiring remain in place at `lib/lockspire/web/router.ex:64-66` and `lib/lockspire/web/live/admin/policies_live/dpop.ex:34-40`; no regressions found. |
| 10 | Operators can override an individual client between inherit, bearer, and DPoP without repo-internal edits. | ✓ VERIFIED | The client edit form still exposes/persists DPoP override options via `lib/lockspire/web/live/admin/clients_live/form_component.ex:73-82` and `lib/lockspire/web/live/admin/clients_live/show.ex:45-52,313-323`; no regressions found. |
| 11 | Dynamic Client Registration accepts, persists, returns, and updates `dpop_bound_access_tokens` using RFC 9449 semantics. | ✓ VERIFIED | Registration create/update mapping and outward JSON remain intact in `lib/lockspire/protocol/registration.ex:243,292-296`, `lib/lockspire/protocol/registration_management.ex:278-287`, and `lib/lockspire/web/registration_json.ex:57`; no regressions found. |
| 12 | Self-registered clients that omit or send `false` for `dpop_bound_access_tokens` become explicit bearer clients instead of silently inheriting DPoP. | ✓ VERIFIED | Missing/false metadata still maps to `:bearer` in `lib/lockspire/protocol/registration.ex:292-296` and `lib/lockspire/protocol/registration_management.ex:283-287`; no regressions found. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Protocol-owned DPoP protected-resource validation, replay recording, `ath` checking, and `cnf.jkt` enforcement | ✓ VERIFIED | Exists, remains substantive, and is still wired from `Lockspire.Protocol.Userinfo`; no regression found. |
| `lib/lockspire/protocol/userinfo.ex` | Token-mode-aware userinfo orchestration | ✓ VERIFIED | Exists, remains substantive, and is still wired from the controller; no regression found. |
| `test/lockspire/web/userinfo_controller_test.exs` | HTTP proof for bearer success, DPoP success, downgrade rejection, replay rejection, malformed-proof rejection, and challenge shape | ✓ VERIFIED | Now includes malformed-proof DPoP challenge coverage at `test/lockspire/web/userinfo_controller_test.exs:236-248`. |
| `lib/lockspire/protocol/discovery.ex` | Truth-gated publication of `dpop_signing_alg_values_supported` | ✓ VERIFIED | Exists, remains substantive, and still gates on mounted owned-surface reality. |
| `docs/supported-surface.md` | Canonical preview wording for shipped DPoP surface and explicit limits | ✓ VERIFIED | Exists and still matches the release contract wording. |
| `test/lockspire/release_readiness_contract_test.exs` | Enforcement backstop for public DPoP wording | ✓ VERIFIED | Exists and still asserts the narrow DPoP contract. |
| `lib/lockspire/web/live/admin/policies_live/dpop.ex` | Global DPoP policy admin page with override summary | ✓ VERIFIED | Exists, remains substantive, and still persists global DPoP policy. |
| `lib/lockspire/protocol/registration.ex` | DCR create-path mapping from `dpop_bound_access_tokens` to durable `client.dpop_policy` | ✓ VERIFIED | Exists, remains substantive, and still persists explicit bearer/DPoP policy. |
| `lib/lockspire/protocol/registration_management.ex` | DCR read/update mapping aligned with durable client policy | ✓ VERIFIED | Exists, remains substantive, and still mirrors DCR DPoP mapping. |
| `test/lockspire/web/live/admin/clients_live_test.exs` | Executable proof for client override workflow | ✓ VERIFIED | Exists and still covers DPoP override UI/persistence. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | `lib/lockspire/protocol/userinfo.ex` | Controller forwards raw auth header, raw DPoP header, method, and repo adapters into protocol code | ✓ WIRED | `Userinfo.fetch_claims/1` is still called with `authorization`, `dpop`, `method`, and `opts` at `lib/lockspire/web/controllers/userinfo_controller.ex:16-21`. |
| `lib/lockspire/protocol/userinfo.ex` | `lib/lockspire/protocol/protected_resource_dpop.ex` | Durable token-mode branch for proof enforcement | ✓ WIRED | Bound tokens still branch through `ProtectedResourceDPoP.validate_userinfo_access/2`. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | `lib/lockspire/domain/token.ex` | Compare validated proof `jkt` against persisted `cnf["jkt"]` | ✓ WIRED | Binding enforcement still reads `Token.cnf["jkt"]` and compares it to `proof.jkt`. |
| `lib/lockspire/protocol/discovery.ex` | `lib/lockspire/protocol/dpop.ex` | Published metadata reads validator allowlist from `signing_alg_values_supported/0` | ✓ WIRED | Still uses `DPoP.signing_alg_values_supported()`. |
| `lib/lockspire/protocol/discovery.ex` | `lib/lockspire/web/router.ex` | DPoP metadata only appears when `/token` and `/userinfo` are both mounted | ✓ WIRED | Route-derived gating logic remains in place and consistent with router mounts. |
| `docs/supported-surface.md` | `test/lockspire/release_readiness_contract_test.exs` | Release docs contract pins exact public DPoP wording | ✓ WIRED | Contract assertions still match the support-surface wording. |
| `lib/lockspire/web/live/admin/policies_live/dpop.ex` | `lib/lockspire/admin/server_policy.ex` | Narrow global DPoP page persists `server_policy.dpop_policy` | ✓ WIRED | `AdminServerPolicy.put_dpop_policy/1` remains the persistence seam. |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | `lib/lockspire/admin/clients.ex` | Existing client edit workflow persists `dpop_policy` | ✓ WIRED | Form submission still threads through `Show.handle_event/3` into `Admin.update_client/2`. |
| `lib/lockspire/protocol/registration.ex` | `lib/lockspire/web/registration_json.ex` | Create/read/update paths round-trip `dpop_bound_access_tokens` | ✓ WIRED | Durable `dpop_policy` still drives outward `dpop_bound_access_tokens`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/userinfo.ex` | `access_token`, `claims` | `token_store(request).fetch_active_access_token/1` and host resolver callbacks | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/discovery.ex` | `endpoint_metadata` | `Phoenix.Router.routes(discovery_router())` plus mounted-path reduction | Yes | ✓ FLOWING |
| `lib/lockspire/web/live/admin/policies_live/dpop.ex` | `policy`, `summary` | `Admin.get_server_policy/0` and `Admin.list_clients/0` | Yes | ✓ FLOWING |
| `lib/lockspire/web/registration_json.ex` | `dpop_bound_access_tokens` | Durable `client.dpop_policy` from persisted client state | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| `userinfo` HTTP contract, including malformed DPoP proof regression | `mix test test/lockspire/web/userinfo_controller_test.exs --seed 0` | `6 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DPoP-09` | `35-01` | `userinfo` accepts DPoP-bound access tokens only when the accompanying proof validates against stored binding state | ✓ SATISFIED | Bound-token enforcement remains intact and malformed-proof challenge coverage is now present in `test/lockspire/web/userinfo_controller_test.exs:236-248`. |
| `DPoP-10` | `35-02` | Discovery metadata and support docs advertise only the shipped DPoP slice with truthful algorithm and endpoint behavior | ✓ SATISFIED | Discovery gating and support-doc contract remain unchanged and verified. |
| `DPoP-11` | `35-03` | Operator and DCR flows can explicitly configure client token mode for bearer vs DPoP without repo-internal edits | ✓ SATISFIED | Admin and DCR DPoP policy seams remain intact with no regression evidence. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME/placeholders, empty implementations, or hardcoded stub data found in the phase-35 implementation/test files rechecked during re-verification. | ℹ️ Info | No blocker-level anti-patterns detected. |

---

_Verified: 2026-04-28T19:58:59Z_
_Verifier: Claude (gsd-verifier)_
