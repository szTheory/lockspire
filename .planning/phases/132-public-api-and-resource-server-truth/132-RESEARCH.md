# Phase 132: Public API and Resource-Server Truth - Research

**Researched:** 2026-08-26  
**Domain:** Elixir public API design, OAuth/OIDC client registration, and durable DPoP replay protection  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Add documented, additive `Lockspire.AccessToken` accessors for normalized subject, scopes, audiences, expiration, and confirmation data; preserve the public struct fields and raw `claims` map for v1.x compatibility.
- Use one normalization contract across token verification, route enforcement, and public accessors; use accessors in supported examples and leave raw claims as a low-level compatibility path.
- Let direct registration, DCR, and shared validation accept built-in `openid`, confidential `private_key_jwt` with existing key constraints, and device-code-only clients without redirects; redirect-based shapes retain non-empty, exact-match redirect URI validation.
- Keep direct/DCR error contracts coherent, centralized validation, actionable deterministic errors, and no key-material leakage.
- Make configured `Lockspire.Storage.Ecto.Repository` the ordinary durable DPoP replay default, preserve behavior-based custom injection, and fail closed on any persistence failure or duplicate proof.
- Align the resource-server guide, generated comments, supported-surface wording, public API docs, authorization boundary, and deprecation guidance with compiled behavior; evolve only additively in v1.x.
- Prove focused unit, integration, and documentation contracts in this phase; do not build the separate-origin end-to-end journey or Phase 134 topology work.

### the agent's Discretion

- Choose unsurprising accessor names/types and exact nil/empty/malformed semantics.
- Place shared registration-shape and normalization helpers behind small directional public/protocol/storage boundaries.
- Either link generated comments to the canonical guide or summarize it briefly, while retaining one executable source of truth.

### Deferred Ideas (OUT OF SCOPE)

- Separate-origin provider/client/resource-server journey (Phase 133).
- Broader dependency-graph restructuring (Phase 134).
- New grants, hosted authorization, and host product-policy APIs.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| API-01 | Normalized additive access-token accessors | Existing verifier normalization must become public/shared; contract and tests below define it. |
| API-02 | Advertised OIDC, `private_key_jwt`, and device-only shapes register safely | A pure capability matrix must be consumed by direct registration and DCR. |
| API-03 | Durable configured-repository DPoP default plus custom injection | Fix the explicit-nil mask and prove repository default / fail-closed behavior. |
| API-04 | Truthful resource-server docs and deprecation guidance | Replace non-existent struct-field examples with accessors and make doc drift executable. |
</phase_requirements>

## Summary

[VERIFIED: codebase] Phase 132 is a truth-alignment phase, not an endpoint-expansion phase. The verifier already has working private normalizers for `aud` and `scope`, a validated RFC 9068 token has `sub` and integer `exp`, and sender bindings are already derived from `cnf`. The public `%Lockspire.AccessToken{}` deliberately contains only raw `claims` plus pipeline state, while the canonical guide documents non-existent `subject`, `scope`, `audience`, `expires_at`, and `cnf` fields. The implementation should expose small total functions on `Lockspire.AccessToken` and move verifier enforcement onto the same normalizers. [VERIFIED: codebase]

[VERIFIED: codebase] Registration currently has two divergent paths. Direct `Lockspire.Clients.register_client/1` rejects `openid`, rejects `private_key_jwt` through its confidential-auth allowlist, always requires redirect URIs, and does not persist JWKS metadata. DCR accepts `openid` under its policy, validates `private_key_jwt` key material, and persists JWKS/JWKS URI, but also always requires redirects. A neutral pure shape validator should decide capabilities and return boundary-neutral errors; direct registration and DCR translate those into their existing error shapes. [VERIFIED: codebase]

[VERIFIED: codebase] The configured Ecto repository already implements the DPoP store behavior using the shipped replay table and a unique `replay_key`, but `EnforceSenderConstraints` always passes `dpop_replay_store: nil`. That makes `Keyword.get_lazy/3` see a present nil instead of invoking the repository fallback, then attempt `nil.record_dpop_proof/1`. The fix is to omit the option when unset (or resolve nil explicitly to `Repository`) and test the real repository default plus storage failure. [VERIFIED: codebase]

**Primary recommendation:** introduce one pure internal token-claims normalizer and one pure client-capability/registration-shape validator; make public facades, verifier enforcement, DCR, docs, and generated comments all consume those contracts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Token semantic accessors and normalization | API / Backend | — | Verified token claims must have one Elixir-level semantic interpretation. [VERIFIED: codebase] |
| Route audience/scope enforcement | API / Backend | Frontend Server (Plug) | Plug is delivery; claim parsing belongs to neutral token code. [VERIFIED: codebase] |
| Registration capability validation | API / Backend | Database / Storage | The same policy must govern operator/direct and DCR inputs before durable persistence. [VERIFIED: codebase] |
| DPoP replay uniqueness | Database / Storage | API / Backend | Durable uniqueness across nodes is a repository responsibility; protocol decides reject/fail-closed. [VERIFIED: codebase] |
| Adoption guidance | Frontend Server / docs | API / Backend | Phoenix pipelines show use; API contract remains library-owned. [VERIFIED: codebase] |

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded Phoenix companion library; do not create a standalone auth service.
- Preserve directional boundaries between protocol core, storage, generator, Plug/Phoenix integration, and LiveView/admin surfaces.
- Host app retains account resolution, login UX, branding, and product policy; do not add SAML, LDAP/AD, hosted auth, or CIAM scope.
- Preserve PKCE S256 default, exact redirect matching, secret hashing, one-use short codes, refresh-family revocation, no implicit flow / `alg=none`, and redaction.

## Exact Current Mismatches

| Area | Actual behavior | Contradictory/insufficient public surface | Required correction |
|---|---|---|---|
| `%AccessToken{}` | Struct exposes raw `claims`; verifier has private `aud`/`scope` normalizers and private `cnf` binding extraction. [VERIFIED: codebase] | `docs/protect-phoenix-api-routes.md` presents `subject`, `scope`, `audience`, `expires_at`, `cnf` as fields. [VERIFIED: codebase] | Add accessors; document calls, return values, and raw-claims escape hatch. |
| `openid` direct registration | Discovery and authorization treat `openid` as built-in; `Clients.validate_scopes/1` rejects it. [VERIFIED: codebase] | Public direct facade cannot register a documented OIDC client. | Treat `openid` as built-in in shared validation, without requiring it in host `known_scopes`. |
| `private_key_jwt` direct registration | DCR validates and persists exactly-one `jwks`/`jwks_uri`; direct facade rejects auth method and drops key attributes. [VERIFIED: codebase] | Supported-surface and host guide advertise the shape. [VERIFIED: codebase] | Share confidential/key-material rules and persist safe key fields in direct clients. |
| Device-only registration | Token/device flow exists; both paths require non-empty redirects; DCR defaults response type to `code`. [VERIFIED: codebase] | Device-only advertised behavior cannot be registered in the intended shape. | Capability-aware URI requirement, and preserve no-redirect only for no-code/no-redirect shapes. |
| DPoP default | Repository adapter has transaction + unique key; Plug injects nil and masks the lazy default. [VERIFIED: codebase] | Guide requires a host custom store in canonical pipeline. [VERIFIED: codebase] | Omit nil, document repository default; retain custom override. |

## Standard Stack

No new package is needed. Use the existing Elixir/Phoenix, Ecto SQL, PostgreSQL, Plug, and NimbleOptions stack. [VERIFIED: codebase]

| Component | Existing role | Phase use |
|---|---|---|
| `Lockspire.AccessToken` | Public verified-token value object | Add total semantic accessors. [VERIFIED: codebase] |
| `Lockspire.Plug.VerifyToken` | JWT validation and route restrictions | Delegate to shared normalizers. [VERIFIED: codebase] |
| `Lockspire.Clients` / `Protocol.Registration` | Direct and DCR facades | Translate shared capability-validator results. [VERIFIED: codebase] |
| `Lockspire.Storage.DpopReplayStore` / Ecto Repository | DPoP storage port/adapter | Preserve DI and make durable adapter default. [VERIFIED: codebase] |

## Package Legitimacy Audit

No external packages are proposed; package legitimacy verification is not applicable.

## Architecture Patterns

### System Architecture Diagram

```text
verified JWT claims
      |
      v
AccessToken normalization <---- VerifyToken audience/scope enforcement
      |
      v
host controller semantic reads

direct attrs ----> shared registration shape ----> Clients error/result ----> Repository
DCR JSON attrs --> shared registration shape ----> DCR Error/result -------> Repository
                      |              |
                      |              +--> exact runtime redirect membership remains in AuthorizationRequest
                      +--> private_key_jwt/JWKS rules

EnforceSenderConstraints -- (custom store only if supplied) --> ProtectedResourceDPoP
                                                                  |
                                                                  v
                                                        DpopReplayStore behavior
                                                                  |
                                                   configured Ecto Repository unique key
```

### Pattern 1: Total public accessors over verified/raw claims

Use `Lockspire.AccessToken.subject/1`, `scopes/1`, `audiences/1`, `expires_at/1`, and `confirmation/1`; never add duplicate struct fields. These must be total and never raise because host controllers commonly call them after pipeline assignment. [VERIFIED: codebase]

| Accessor | Return type | Missing/malformed contract | Shared enforcement contract |
|---|---|---|---|
| `subject/1` | `String.t() | nil` | trim a binary; blank/non-binary -> `nil` | RFC 9068 verifier still rejects missing/invalid `sub` before a successful assignment. [VERIFIED: codebase] |
| `scopes/1` | `[String.t()]` | binary -> whitespace split, trim, de-duplicate in first-seen order; other -> `[]` | `VerifyToken` uses this exact list for `scopes:`. |
| `audiences/1` | `[String.t()]` | nonblank binary -> one item; nonempty list of nonblank strings -> trimmed/deduped list; all other shapes -> `[]` | verifier needs a paired internal `{:ok, list} | {:error, :missing_audience | :invalid_audience}` helper so empty reader output cannot erase distinction. |
| `expires_at/1` | `DateTime.t() | nil` | integer NumericDate -> UTC `DateTime`; invalid/out-of-range/non-integer -> `nil` | verification remains authoritative for `exp`, never infer expiry from a string. RFC 7519 defines NumericDate in seconds. [CITED: https://datatracker.ietf.org/doc/html/rfc7519#section-2] |
| `confirmation/1` | `%{optional(:dpop_jkt) => String.t(), optional(:mtls_x5t_s256) => String.t()} | nil` | accept only nonblank string `cnf.jkt` and/or `cnf["x5t#S256"]`, trim values; non-map/empty/unknown-only -> `nil` | sender constraints consume the same allowlisted map, not raw nested `cnf`. [VERIFIED: codebase] |

Keep `claims/1` out of scope because `%AccessToken{}.claims` is already public; document it as raw, unnormalized compatibility/extension data. Do not parse string dates, coerce numeric strings, or return arbitrary confirmation members: doing so creates an accidental API where malformed data looks authoritative. [VERIFIED: codebase]

Suggested internal layout: `AccessToken` owns public accessors plus `@doc false` normalization-result helpers (or a neutral `AccessToken.Claims` module); `VerifyToken` calls them. Do not let Plug code become the canonical parser. [VERIFIED: codebase]

### Pattern 2: One registration capability matrix, boundary-specific error translation

Use a pure module such as `Lockspire.Clients.RegistrationShape` that receives normalized attributes/metadata and answers (a) capabilities, (b) persistence-ready normalized key fields, or (c) neutral `{field, reason, detail}` errors. `Clients` maps errors to its list format; `Protocol.Registration` maps them to `%Registration.Error{}`. [VERIFIED: codebase]

| Shape | `openid` | Grants / responses | Redirect URIs | Auth/key rules | Expected result |
|---|---|---|---|---|---|
| OIDC authorization-code | Allowed as built-in | `authorization_code` and `code` | Required, non-empty, validated | public `none` or supported confidential method | Accept. [VERIFIED: codebase] |
| `private_key_jwt` authorization-code | Allowed | code-capable | Required, non-empty, validated | confidential; exactly one inline `jwks` or HTTPS guarded `jwks_uri`; existing allowed alg/profile rules | Accept and persist keys. [VERIFIED: codebase] |
| Device-only | Optional | device-code grant; no `code` response/capability | May be `[]` only | existing supported auth method/type policy applies | Accept. [VERIFIED: codebase] |
| Mixed device + authorization-code | Optional | contains authorization-code or `code` | Required, non-empty, validated | same as code-capable shape | Reject missing redirects. |
| Refresh-only / `code` without auth-code | N/A | incoherent | N/A | N/A | Retain deterministic incoherent-pair rejection. [VERIFIED: codebase] |

Capability predicate: `redirect_based? = authorization_code in grants or "code" in responses` is conservative and preserves protection if malformed/mixed input contains either signal. The registration validator must reject a `code` response without authorization-code before persistence; the runtime `AuthorizationRequest.validate_redirect_uri/2` exact membership guard remains unchanged. [VERIFIED: codebase]

For DCR, keep policy allowlists (`DcrPolicy.resolve/3`) before shape validation, and include `openid` in the effective built-in scope set even when server policy does not list it. RFC 7591 defines `grant_types` and `response_types` metadata and their coherence; its existing `refresh_token`/authorization-code check remains a minimum floor. [CITED: https://datatracker.ietf.org/doc/html/rfc7591#section-2]

For direct registration, add normalized `jwks`/`jwks_uri` attributes to the `%Client{}` construction only after validation; do not put raw JWKS into error detail, logs, telemetry, or docs assertions. Existing remote JWKS protections are HTTPS-only, no redirect, pre-dispatch unsafe-target rejection, bounded body, cached last-known-good material, and closed failure. [VERIFIED: codebase]

### Pattern 3: Optional override, durable default, fail-closed storage

The resolved DPoP store must be `Keyword.get(opts, :dpop_replay_store) || Repository` only if the option validation cannot distinguish deliberate nil; preferably build request options with `Keyword.put_new` only when a custom module is supplied, so `ProtectedResourceDPoP.dpop_replay_store/1` retains its `Keyword.get_lazy(..., Repository)` fallback. Reject an invalid custom store at Plug init or let the current fail-closed protocol error path return `invalid_dpop_proof`; never fall back after a custom store errors. [VERIFIED: codebase]

Repository proof must exercise `Lockspire.Config.repo!/0`: set a non-test configured repo in isolated test setup, invoke the Plug without `dpop_replay_store`, submit one valid proof twice, and assert first acceptance then `:dpop_proof_replayed`. A separate test store returning `{:error, :unavailable}` must produce token failure, never `:ok`; the durable adapter's database uniqueness constraint is the cross-node boundary. [VERIFIED: codebase]

DPoP's replay guidance requires servers to detect replay of proofs and recommends storage of the `jti`/proof identity for an appropriate window. [CITED: https://datatracker.ietf.org/doc/html/rfc9449#section-11.1] The shipped hashed key includes JKT, JTI, method, and canonical HTU and expires after proof max-age plus skew. [VERIFIED: codebase]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Cross-node DPoP replay cache | ETS/process-local set | Existing `DpopReplayStore` + Ecto unique-key adapter | Process state cannot prove replay prevention across nodes/restarts. [VERIFIED: codebase] |
| Remote JWKS fetching | New generic HTTP metadata client | Existing guarded remote-JWKS implementation | Existing slice has SSRF, redirect, bounded-body, cache, and fail-closed controls. [VERIFIED: codebase] |
| Claim interpretation per plug/controller | Separate ad hoc map reads | Shared `AccessToken` normalizer | Divergent parsing alters authorization meaning. |
| Endpoint-specific registration exceptions | Separate direct/DCR validations | Shared pure capability validator | Existing drift already demonstrates the risk. [VERIFIED: codebase] |

## Common Pitfalls

### Nil masks a lazy default

[VERIFIED: codebase] `Keyword.get_lazy/3` only uses its fallback for an absent key. Passing `dpop_replay_store: nil` is therefore materially different from omitting it. Test the omitted path through `EnforceSenderConstraints`, not only `ProtectedResourceDPoP` directly.

### Reader convenience must not weaken verifier errors

[VERIFIED: codebase] `audiences/1 == []` is correct for malformed public reader input, but verifier enforcement still needs to distinguish missing `aud` from invalid `aud`. Keep a result-returning helper for verification and a total accessor for host reads.

### Device exception broadens code clients

[VERIFIED: codebase] Checking only `grant_types == [device]` is brittle. Treat any authorization-code grant or `code` response type as redirect-based, including mixed/partially malformed registrations, and retain exact runtime URI comparison.

### `private_key_jwt` acceptance without persistence is a false capability

[VERIFIED: codebase] Direct `Clients` currently creates a `Client` without `jwks` or `jwks_uri`. Acceptance must include correct field persistence and a later assertion verification test; validation alone is insufficient.

### Docs can lie after a compatible API addition

[VERIFIED: codebase] The guide's field notation looks plausible because claims exist, yet no fields are populated. Use source-level documentation contract tests for accessor calls and generated router comments, plus behavior tests for returned values.

## Security Domain

### Applicable ASVS L1 Verification Ideas

| ASVS category | Applies | Phase proof |
|---|---|---|
| V2 Authentication | Yes | `private_key_jwt` must require confidential client, exactly one valid key source, allowed signing algorithm, and no `alg=none`. [VERIFIED: codebase] |
| V3 Session Management | Yes | DPoP proof replay rejects a duplicate after independent repository calls and survives default-store resolution. [VERIFIED: codebase] |
| V4 Access Control | Yes | Scope/audience route checks use the same normalized semantic view exposed publicly; docs explicitly preserve host tenant/object authorization. |
| V5 Input Validation | Yes | Exhaustive malformed claims, JWKS URI, redirect, grant/response, and mixed-capability cases. |
| V6 Cryptography | Yes | Do not alter existing signature/algorithm allowlists, hash construction, or secret-at-rest rules; assert key material is not surfaced in errors/logs. [VERIFIED: codebase] |

### STRIDE Threat Inventory

| Threat | STRIDE | Severity | Mitigation / executable proof |
|---|---|---:|---|
| DPoP replay accepted after restart/node change | Spoofing | High | Default path reaches configured repository; unique key accepts once, rejects duplicate; custom-store failure fails closed. |
| Nil store masks default and causes accidental unsafe fallback in future repair | Tampering | High | Omit nil option; assert no ETS/in-memory fallback and storage error is token failure. |
| Device-only exception lets code flow omit redirect URI | Spoofing / Elevation | High | Matrix tests direct+DCR: device-only accepted, code/mixed URI-less rejected, runtime exact-match untouched. |
| `private_key_jwt` without trustworthy keys or with malicious JWKS URI | Spoofing / SSRF | High | Exactly-one keys, confidential-only, guarded HTTPS URI controls, algorithm/profile checks, no key detail in errors. |
| Raw/malformed claims interpreted differently by access policy vs controller | Elevation | High | Single normalizer parity tests for scopes/audiences/confirmation; verifier remains stricter where needed. |
| Key material or token claims leak in diagnostics | Information disclosure | Medium | Assert error/telemetry detail does not contain JWKS, raw token, proof, or `cnf`; retain redaction. |
| Registration validation drift hides actor/action evidence | Repudiation | Medium | Preserve existing registration telemetry/audit events and deterministic boundary errors. [VERIFIED: codebase] |
| Repeated invalid replay writes / prune load | Denial of service | Medium | Keep bounded proof age, indexed expiry/replay key, and current generic errors. [VERIFIED: codebase] |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit + Ecto SQL Sandbox [VERIFIED: codebase] |
| Quick run | `mix test.fast` [VERIFIED: codebase] |
| Integration run | `mix test.integration` [VERIFIED: codebase] |
| Quality/doc gate | `mix qa` and `mix docs.verify` [VERIFIED: codebase] |

### Requirement → Test Map

| Req ID | Behavior | Test type / likely files | Command |
|---|---|---|---|
| API-01 | Accessor returns normalized/malformed-safe values and equals enforcement interpretation | Unit `access_token_test`; Plug parity `verify_token_test` | `mix test test/lockspire/access_token_test.exs test/lockspire/plug/verify_token_test.exs` |
| API-02 | Direct/DCR capability matrix and persisted key material | `clients_test`, `registration_test`, registration controller test, authorization request negative tests | `mix test test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs` |
| API-03 | Default repo replay, custom injection, duplicate, and storage failure | sender plug, protocol DPoP, repository replay integration tests | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` plus `mix test.integration` |
| API-04 | Docs/template/public API/support-surface/deprecation contract | new focused docs/release contract test | `mix docs.verify` and focused test |

### Required Negative Cases

- `aud`: nil, empty binary, empty list, list containing non-string; route error preserves `:missing_audience` vs `:invalid_audience`. [VERIFIED: codebase]
- scopes: whitespace/duplicates normalize consistently; non-string never grants a required scope. [VERIFIED: codebase]
- confirmation: only valid nonblank `jkt` and `x5t#S256` are exposed; unknown raw `cnf` members do not become semantic data. [VERIFIED: codebase]
- direct and DCR: `openid` succeeds; device-only/no redirect succeeds; authorization-code/no redirect and mixed/no redirect fail; wildcard/fragment URI still fails; exact runtime mismatch still fails. [VERIFIED: codebase]
- `private_key_jwt`: no keys, both key sources, non-HTTPS URI, public client, unsupported algorithm fail; acceptable inline/remote key source persists and reaches existing verifier. [VERIFIED: codebase]
- DPoP: omitted custom store defaults durably; injected accepting/replay/failing stores preserve behavior; no custom-store error ever downgrades to acceptance. [VERIFIED: codebase]

### Wave 0 Gaps

None in framework infrastructure. Add focused cases to existing test modules; add a small release/documentation contract test only if existing `support_surface_contract_test.exs` cannot express the public-guide assertions cleanly. [VERIFIED: codebase]

## Likely Plan Slices

1. **Token semantic contract (API-01):** add accessors/shared normalizers, refactor verifier use, characterize malformed behavior and Plug parity.
2. **Shared client capability matrix (API-02):** pure validator, direct facade key persistence, DCR adapter, direct/DCR/mixed-shape negative proof, retain runtime redirect guard.
3. **Durable DPoP default (API-03):** fix nil mask, assert configured repository default/unique replay/fail-closed custom errors, correct Plug options/docs.
4. **Truthful supported surface (API-04):** canonical guide + generated comments + ExDoc/support surface + additive migration/deprecation guide, protected by drift tests.

Plans 2 and 3 can execute in parallel after Plan 1's helper boundary is fixed; Plan 4 should consume final names/behavior. Do not create a separate host/client app or broad dependency changes in this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `DateTime.from_unix/2` is the desired precision/return behavior for integer NumericDate accessor output. | Accessor contract | Low; verify through focused unit tests in this repo. |

## Open Questions

1. **Should `expires_at/1` return `DateTime` or Unix seconds?**
   - Recommendation: return `DateTime.t() | nil` because the named method reads as an expiry instant and host policy comparisons become type-safe; raw `claims["exp"]` remains available for integer consumers. [ASSUMED]
2. **Should direct registration accept string-key JWKS attributes identically to atom keys?**
   - Recommendation: yes, normalize both at public boundary just as existing direct fields do, then run the same shared validator. [ASSUMED]

## Sources

### Primary (HIGH confidence)

- [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519#section-2) — NumericDate and JWT claim representation.
- [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591#section-2) — client metadata and grant/response coherence.
- [RFC 9449](https://datatracker.ietf.org/doc/html/rfc9449#section-11.1) — DPoP replay-detection guidance.
- Lockspire code and tests named in `132-CONTEXT.md` / `132-PATTERNS.md` — current implementation behavior.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no dependency change; based on current codebase.
- Architecture: HIGH — direct source inspection identifies each seam and mismatch.
- Pitfalls/security: HIGH — source-backed nil-mask and registration divergence, checked against IETF RFCs.

**Research date:** 2026-08-26  
**Valid until:** 2026-09-25
