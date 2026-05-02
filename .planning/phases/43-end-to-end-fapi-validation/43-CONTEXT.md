# Phase 43: End-to-End FAPI 2.0 Validation and Release Posture - Context

**Gathered:** 2026-05-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.10 FAPI 2.0 milestone by proving — through repo-truth executable tests, truthful
discovery metadata, and a documented OIDF conformance lane — that Lockspire enforces the FAPI 2.0
Security Profile end-to-end. Phase 43 must:

- Lock zero-tolerance redirect URI matching (FAPI-05) with executable proof, without altering the
  existing exact-match logic.
- Emit RFC 9207 `iss` on every authorization-response redirect (success and error) and publish
  truthful FAPI 2.0 keys in `.well-known/openid-configuration` (FAPI-06).
- Consume the OIDF harness landed in Phase 42 as the proof lane: implement the missing
  `mix lockspire.oidf_conformance` task that `docs/maintainer-conformance.md`,
  `.github/workflows/oidf-conformance.yml`, and `release_readiness_contract_test.exs` already
  reference, and pin the canonical OIDF plan ID and variant axes.
- Extend the install generator to emit at least one host-owned FAPI-aware integration test so
  generated host seams carry executable FAPI proof.
- Update truth-in-docs surfaces (SECURITY.md, README.md, supported-surface.md) and the
  release-readiness contract test so the v1.10 milestone can be archived without overclaiming.

**Explicitly out of scope this phase:**

- Changing redirect URI matching logic (introducing a URI parser is rejected — exact string match
  remains canonical).
- Removing the `String.trim/1` at `end_session.ex:147` for `post_logout_redirect_uri` — this is
  documented behavior, not a bug.
- Emitting RFC 9207 `iss` outside authorization redirects (no changes to `/token`, `/revoke`,
  `/introspect` — RFC 9207 §2 scopes `iss` to authorization responses only).
- Adding `tls_client_certificate_bound_access_tokens` or any mTLS-related metadata (deferred per
  REQUIREMENTS.md "Out of Scope").
- Adding `signed_metadata` (RFC 9101 §2.1) JWT-signed discovery — out of scope for v1.10.
- Building a host test-generator subsystem; the install generator extension is bounded to FAPI
  proof scaffolding only.
- Gating CI green on a live external OIDF Docker suite pass — that remains a documented manual
  maintainer step, per Phase 42 D-13/D-15.
</domain>

<decisions>
## Implementation Decisions

### FAPI-05: Redirect URI Surface

- **D-01:** Do not change matching logic on any redirect-uri surface. The existing exact-string
  comparisons (`redirect_uri in client.redirect_uris` at `authorization_request.ex:236-247` and
  raw `==` at `token_exchange.ex:366-378`) are canonical and remain in place.
- **D-02:** Single-source the write-boundary URI shape via `Lockspire.Clients.validate_redirect_uris/1`
  — already reused by `admin/clients.ex:229-234, 580-583` and `registration.ex:243-254`. Phase 43
  does not introduce a second validator.
- **D-03:** The `String.trim/1` at `end_session.ex:147` (post-logout redirect) is acceptable
  documented behavior. New tests must explicitly assert that internal whitespace, trailing slashes,
  and query-param drift are still rejected; only surrounding whitespace is tolerated.

### FAPI-06: RFC 9207 `iss` Emission

- **D-04:** Append `iss=Config.issuer!()` UNCONDITIONALLY (all clients, not gated on
  `:fapi_2_0_security`) on every authorization-response redirect. This applies to both success
  and error redirects, per RFC 9207 §2.
- **D-05:** Two emission seams must be aligned: `AuthorizationFlow.build_redirect/3`
  (`authorization_flow.ex:390-402`, success + access_denied) and
  `AuthorizeController.redirect_location/1` (`authorize_controller.ex:129-145`, validation /
  protocol error redirects). Missing either creates an `iss`-less bypass.
- **D-06:** `iss` is NOT emitted on `/token`, `/revoke`, or `/introspect` responses. RFC 9207 §2
  scopes the parameter to authorization responses only; FAPI 2.0 Security Profile Final does not
  extend it.

### FAPI-06: Discovery Metadata

- **D-07:** Publish `authorization_response_iss_parameter_supported: true` UNCONDITIONALLY in
  `.well-known/openid-configuration`. This mirrors the unconditional `iss` emission contract from
  D-04 and keeps discovery truth uniform across profile modes.
- **D-08:** Publish `require_pushed_authorization_requests: true` ONLY when the resolved global
  `server_policy.security_profile == :fapi_2_0_security`. PAR enforcement is server-wide; per-client
  FAPI overrides do not flip a server-wide discovery key.
- **D-09:** Do not publish mTLS, JARM, or `signed_metadata` keys. Discovery truth must reflect
  actual runtime support — Phase 42 D-11 (truthful publication) governs.

### End-to-End Proof Lane

- **D-10:** Add a NEW `test/integration/phase43_fapi_milestone_e2e_test.exs`. Do NOT extend
  `phase41_fapi_2_0_e2e_test.exs`. Per-phase milestone evidence stays clean, matching the existing
  `phase{N}_*_e2e_test.exs` per-phase precedent.
- **D-11:** The Phase 43 E2E test must cover: (a) zero-tolerance redirect-URI rejection across
  `/authorize`, `/par`, `/token`, `/end_session` for trailing slash and query drift; (b) `iss=`
  appended on success, denial, and error redirects; (c) discovery published correctly under both
  `:none` and `:fapi_2_0_security` global modes (asserting the conditional PAR key flips correctly).
- **D-12:** Update `test/lockspire/release_readiness_contract_test.exs` with new assertions about
  truthful FAPI 2.0 claim language in `SECURITY.md`, `README.md`, and `docs/supported-surface.md`.
  Today these files contain effectively zero positive FAPI 2.0 claims; Phase 43 closes that gap.

### OIDF Conformance Task

- **D-13:** Implement `mix lockspire.oidf_conformance` as a real Mix task in
  `lib/mix/tasks/lockspire.oidf_conformance.ex`. Three referenced-but-orphan call sites must resolve:
  `docs/maintainer-conformance.md:53`, `.github/workflows/oidf-conformance.yml:66`,
  `release_readiness_contract_test.exs:481`.
- **D-14:** The task is a deterministic `--validate-env` shell-out around
  `scripts/conformance/fapi2-check.sh`. It validates env vars, dependencies, and required artifact
  paths. It does NOT execute the external OIDF Docker suite — that remains a documented manual
  step.
- **D-15:** Pin the canonical OIDF FAPI 2.0 plan ID and variant axes verbatim in
  `docs/maintainer-conformance.md` and a new `scripts/conformance/fapi2-plan.json` mirroring the
  `phase37-plan.json` precedent:
  - `planName`: `fapi2-security-profile-final-test-plan`
  - `fapi_profile`: `plain_fapi`
  - `client_auth_type`: `private_key_jwt`
  - `sender_constrain`: `dpop`
  - `fapi_request_method`: `unsigned`
  - `fapi_response_mode`: `plain_response`
- **D-16:** Treat the live Docker OIDF run as a documented manual maintainer step, NOT a CI
  pass-gate. This honors Phase 42 D-13/D-15: pin the harness, but do not block milestone archive on
  external-suite green.

### Generated Host-Seam Tests

- **D-17:** Extend `lib/lockspire/generators/install.ex` and `priv/templates/lockspire.install/`
  to emit ONE host-owned FAPI-aware integration test template. Today the install generator emits
  zero test files. The new template should mirror the Phase 41 E2E shape in the host's namespace
  and exercise PAR + DPoP + iss + redirect rejection through the host wiring.
- **D-18:** Cap the new template scope at one file. If it grows beyond ~200 lines, planning may
  split into two (an auth-code+PKCE smoke + a FAPI 2.0 PAR+DPoP smoke), but the default delivery
  is one cohesive test.

### Truthful Posture and Release Claims

- **D-19:** Add positive FAPI 2.0 claim language to `SECURITY.md`, `README.md`, and
  `docs/supported-surface.md`. Language must describe what is enforced (PAR, DPoP, ES256/PS256,
  exact redirect match, `iss` on auth responses, FAPI 2.0 keys in discovery) and what is NOT
  claimed (no external OIDF suite certification, no mTLS).
- **D-20:** The `release_readiness_contract_test.exs` truth-in-docs gate is the locked validator
  for D-19. New assertions there are required, not optional.

### Claude's Discretion

- The exact module name and signature for the new Mix task may be chosen during planning; only
  the three orphan references must resolve.
- The internal split between `AuthorizationFlow.build_redirect/3` and the controller error
  redirect builder may share a small helper for `iss` injection, or each may add it inline,
  provided both surfaces emit it.
- The internal organization of new discovery keys (helper function vs inline in the doc builder)
  is a planning detail; only the three new keys with the truth split from D-07/D-08 are locked.
- The shape and wording of new assertions in `release_readiness_contract_test.exs` may be chosen
  during planning so long as they match the actual claim text added by D-19.

### Folded Todos

None — phase scope is fully defined by RESEARCH.md + REQUIREMENTS FAPI-05/06.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone state

- `.planning/ROADMAP.md` — Phase 43 goal/success criteria
- `.planning/REQUIREMENTS.md` — FAPI-05, FAPI-06, and v1.10 milestone scope
- `.planning/PROJECT.md` — embedded-library boundaries, truthful posture, operator/DX values
- `.planning/STATE.md` — pending blockers (manual conformance, full-suite regression, code-review gate)
- `.planning/METHODOLOGY.md` — assumption-first / least-surprise / research-first lenses
- `.planning/phases/43-end-to-end-fapi-validation/43-RESEARCH.md` — phase research findings

### Prior phase decisions that constrain this phase

- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md` — FAPI profile model,
  mixed-mode semantics, FAPI20EnforcerPlug boundary
- `.planning/phases/42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep/42-CONTEXT.md` —
  canonical algorithm policy, OIDF harness landed in repo (D-13/D-14: Phase 43 must consume it
  as the proof lane), truthful publication (D-11), no external-suite pass-gate (D-15)
- `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md` — single
  source of truth for advertised algorithms / truthful discovery pattern

### Existing implementation surfaces to extend

- `lib/lockspire/protocol/authorization_request.ex` (lines 236-253) — write-time exact match
- `lib/lockspire/protocol/token_exchange.ex` (lines 366-378) — code-bound exact match
- `lib/lockspire/clients.ex` (lines 310-338) — write-boundary URI shape validation
- `lib/lockspire/admin/clients.ex` (lines 229-234, 580-583) — admin reuses `Clients`
- `lib/lockspire/protocol/registration.ex` (lines 243-254) — DCR reuses `Clients`
- `lib/lockspire/protocol/end_session.ex` (lines 145-170) — post-logout exact match w/ trim
- `lib/lockspire/protocol/authorization_flow.ex` (lines 376-402) — success + denial redirect builder, NEEDS `iss`
- `lib/lockspire/web/controllers/authorize_controller.ex` (lines 129-145) — error redirect builder, NEEDS `iss`
- `lib/lockspire/protocol/discovery.ex` (lines 74-94, 168-178) — discovery doc builder, NEEDS new keys
- `lib/lockspire/config.ex` (lines 20-29) — `Config.issuer!/0` truth source for `iss`
- `lib/lockspire/protocol/security_profile.ex` (lines 26-37) — resolver, gates discovery PAR key
- `lib/lockspire/generators/install.ex` and `priv/templates/lockspire.install/` — extend with FAPI test template

### New surfaces to create

- `lib/mix/tasks/lockspire.oidf_conformance.ex` — Mix task implementing the orphan reference
- `test/integration/phase43_fapi_milestone_e2e_test.exs` — phase-level E2E proof
- `scripts/conformance/fapi2-plan.json` — pinned OIDF plan + variants (mirror `phase37-plan.json`)
- New host-test template under `priv/templates/lockspire.install/` (FAPI-aware integration test)

### Existing tests and docs to update

- `test/integration/phase41_fapi_2_0_e2e_test.exs` — preserved untouched as Phase 41 evidence
- `test/lockspire/release_readiness_contract_test.exs` — line 481 (orphan task ref) + new FAPI claim assertions
- `docs/maintainer-conformance.md` — line 53 (orphan task ref) + pin canonical plan ID/variants
- `.github/workflows/oidf-conformance.yml` — line 66 (orphan task ref) — resolves once D-13 lands
- `scripts/conformance/fapi2-check.sh` — referenced from new Mix task
- `SECURITY.md`, `README.md`, `docs/supported-surface.md` — add truthful FAPI 2.0 claim language

### Specification authority and external ecosystem signals

- RFC 9207 §2 (https://www.rfc-editor.org/rfc/rfc9207.html) — `iss` authorization-response scope
- FAPI 2.0 Security Profile Final — runtime contract this phase closes against
- OIDF conformance-suite `FAPI2SPFinalTestPlan.java`
  (https://gitlab.com/openid/conformance-suite/-/blob/master/src/main/java/net/openid/conformance/fapi2spfinal/FAPI2SPFinalTestPlan.java)
  — canonical plan name `fapi2-security-profile-final-test-plan`
- OpenID Connect Discovery 1.0 — discovery metadata schema for new keys

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Clients.validate_redirect_uris/1` is already the single-sourced write-boundary
  validator — admin updates and DCR both delegate to it. No new validator needed for FAPI-05.
- `Config.issuer!/0` (`config.ex:20-29`) is the canonical issuer truth source for `iss` emission.
- `SecurityProfile.Resolved` (`security_profile.ex:26-37`) gives discovery a clean way to gate
  the conditional `require_pushed_authorization_requests` key.
- `DPoP.signing_alg_values_supported/0` (already published at `discovery.ex:172-173`) is the
  template pattern for "publish what we actually enforce" — Phase 43's new keys follow it.
- `scripts/conformance/phase37-plan.json` is the precedent shape for a pinned OIDF plan JSON
  artifact — Phase 43's `fapi2-plan.json` mirrors it.
- `test/integration/phase41_fapi_2_0_e2e_test.exs` is the precedent E2E shape for the new
  `phase43_fapi_milestone_e2e_test.exs`.

### Established Patterns

- Truthful metadata sourced from the same code that enforces behavior (Phase 42 D-11)
- Per-phase `phase{N}_*_e2e_test.exs` for milestone evidence trails
- Thin Phoenix/Plug adapters over protocol-owned correctness
- Generated host code as the canonical onboarding seam (install generator)
- Release/support wording protected by executable contract test

### Integration Points

- `iss` injection composes with the existing redirect-builder seams without changing their public
  contract.
- New discovery keys plug into the existing `Discovery.build/1` composition without restructuring.
- The new Mix task wraps the existing `fapi2-check.sh` shell script — no new external deps.
- The host-test template plugs into the existing install-generator template-copy mechanism — no
  new generator framework.
- Truth-in-docs assertions plug into the existing `release_readiness_contract_test.exs` shape.

### Important Drift to Fix

- Three orphan references to `mix lockspire.oidf_conformance` exist (`docs/maintainer-conformance.md:53`,
  `.github/workflows/oidf-conformance.yml:66`, `release_readiness_contract_test.exs:481`) but the
  task is not defined under `lib/mix/tasks/` — Phase 42 left this as the residual closure work.
- `SECURITY.md`, `README.md`, and `docs/supported-surface.md` carry effectively zero positive
  FAPI 2.0 claim language despite the milestone shipping the full enforcement stack.
- `AuthorizationFlow.build_redirect/3` and `AuthorizeController.redirect_location/1` both emit
  client-bound redirects but neither emits `iss` today — both must be aligned.

</code_context>

<specifics>
## Specific Ideas

- Pin OIDF plan: `fapi2-security-profile-final-test-plan` with variants `fapi_profile=plain_fapi`,
  `client_auth_type=private_key_jwt`, `sender_constrain=dpop`, `fapi_request_method=unsigned`,
  `fapi_response_mode=plain_response`. Source verbatim in `docs/maintainer-conformance.md` and
  `scripts/conformance/fapi2-plan.json`.
- Keep `iss` injection unconditional and uniform across both authorization-redirect seams. Adding
  it only on FAPI mode would create a worse failure mode (split discovery truth + integration drift
  on profile flip).
- The new Phase 43 E2E test must assert discovery output under BOTH `:none` and `:fapi_2_0_security`
  global modes to lock D-08's conditional `require_pushed_authorization_requests` flip.
- The new host-seam test template should match the host's idiomatic Phoenix.ConnTest +
  Sandbox conventions but stay within the install-generator's existing template-copy contract.
- Treat the v1.10 archive as truth-anchored: claim what's enforced, document the manual OIDF live
  run as a maintainer step, do NOT claim certified pass.
</specifics>

<deferred>
## Deferred Ideas

- mTLS client authentication and `tls_client_certificate_bound_access_tokens` discovery key —
  permanent out-of-scope per `REQUIREMENTS.md:29`.
- JARM and signed JWT response modes — belong to FAPI 2.0 Message Signing plan, not Security Profile.
- `signed_metadata` (RFC 9101 §2.1) JWT-signed discovery — possible future hardening; not v1.10.
- Broader test-generator subsystem for host apps — out of scope; v1.10 ships one bounded template.
- Making CI green-gated on external OIDF Docker suite pass — explicitly rejected per Phase 42
  D-15; remains a documented manual maintainer step.
- Removing the post-logout `String.trim/1` for surface uniformity with `authorization_request.ex`
  — interop regression risk outweighs the cosmetic uniformity benefit.

### Reviewed Todos (not folded)

None — `gsd-sdk query todo.match-phase 43` returned zero matches.
</deferred>

---

*Phase: 43-end-to-end-fapi-validation*
*Context gathered: 2026-05-02 (assumptions mode)*
