# Phase 59: Registration, Policy & Metadata Truth - Research

**Researched:** 2026-05-06
**Scope:** `REG-01`, `REG-02`, `REG-03`, `META-01`, `META-02`
**Overall confidence:** HIGH

## Executive Summary

Phase 59 is mostly a truth-alignment phase, not a new subsystem. The repo already has the right seams:

- `Lockspire.Protocol.Registration` owns RFC 7591 intake validation and self-registered client persistence.
- `Lockspire.Protocol.RegistrationManagement` already reuses the same validator pipeline for RFC 7592 full-replace updates.
- `Lockspire.Protocol.Discovery` already centralizes route-aware metadata publication.
- `Lockspire.Protocol.ClientAuth` is already the shared direct-client auth seam for token-adjacent endpoints.
- `Lockspire.Protocol.SecurityProfile` already owns the effective signing-algorithm posture.

The main work is to remove drift between those seams:

1. admit `jwks_uri` only for the narrow `private_key_jwt` slice, with explicit `invalid_client_metadata` errors;
2. make RFC 7592 updates persist the same `jwks_uri` truth as registration intake;
3. expose operator-facing policy truth without creating a new crypto-policy console;
4. publish endpoint metadata only where runtime behavior is actually aligned.

## Key Findings

### 1. Registration already has most of the right guards, but the `jwks_uri` slice is incomplete

`lib/lockspire/protocol/registration.ex` already enforces:

- `jwks` xor `jwks_uri`
- `private_key_jwt` requires cryptographic material
- explicit `%Registration.Error{field, reason}` failures

What is still missing for Phase 59:

- `jwks_uri` should be admitted only when `token_endpoint_auth_method == "private_key_jwt"`
- the admitted URI should be `https` only
- unsupported combinations should fail as `invalid_client_metadata`, not fall through into generic storage
- persisted self-registered clients should carry `jwks_uri` as a first-class field, not only `jwks`

### 2. RFC 7592 updates currently drift from registration truth

`lib/lockspire/protocol/registration_management.ex` already reuses:

- `DcrPolicy.resolve/3`
- `Registration.validate_intake_metadata/3`
- RAT rotation and audit flow

But `apply_metadata_to_client/2` currently maps `jwks` and does **not** map `jwks_uri`. That means the repo already has a concrete truth gap: an update that validates `jwks_uri` can still fail to persist it durably.

Phase 59 should fix this by mirroring the registration persistence mapping, not by inventing a new management-only code path.

### 3. Discovery is the correct metadata assembly point, but it still publishes a narrower token auth surface

`lib/lockspire/protocol/discovery.ex` already uses the right pattern:

- route-aware endpoint detection
- `maybe_put_*` conditional keys
- centralized `openid_configuration/0`

Today it still advertises:

- `token_endpoint_auth_methods_supported == ["none", "client_secret_basic", "client_secret_post"]`
- no revocation/introspection auth-method metadata
- no revocation/introspection signing-alg metadata

That is the right place to fix Phase 59, but the fix must remain truth-based. The metadata should follow effective endpoint behavior rather than operator intent or UI toggles.

### 4. The signing-algorithm source already exists and should stay derived

`Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms/1` already gives the correct effective algorithm sets:

- `:none` -> `["RS256", "ES256", "PS256", "EdDSA"]`
- `:fapi_2_0_security` -> `["ES256", "PS256"]`

This should remain the single source for published `*_auth_signing_alg_values_supported` fields. Phase 59 should not add a second operator-managed allowlist for JWT client assertions.

### 5. Endpoint capability truth is not uniform today

The repo is already inconsistent in ways that matter for truthful metadata:

- `ClientAuth` structurally recognizes `:private_key_jwt`
- `Revocation` delegates to `ClientAuth.authenticate/3`
- `Introspection` authenticates via `ClientAuth`, but then `validate_confidential_caller/1` narrows accepted callers to `:client_secret_basic` and `:client_secret_post`

So Phase 59 cannot treat token, revocation, and introspection as identical by default. It needs endpoint-specific truth predicates backed by a shared capability source.

### 6. Operator work should stay policy-visible, not workflow-expansive

The current admin surface already supports narrow policy editing through:

- `lib/lockspire/web/live/admin/policies_live/dcr.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`

And read-only client posture visibility through:

- `lib/lockspire/web/live/admin/clients_live/show.ex`

Phase 59 should use those surfaces to explain:

- whether DCR currently allows `private_key_jwt`
- what signing algorithms the effective issuer posture implies
- that `jwks_uri` support is limited to the narrow self-registered `private_key_jwt` slice

It should **not** add operator-created JWT client onboarding, remote JWKS preview buttons, or editable algorithm lists.

## Recommended Implementation Shape

1. Tighten `validate_jwks/1` in `Registration` and mirror the same durable mapping in `RegistrationManagement`.
2. Add one small derived policy helper for admin truth, preferably backed by `ServerPolicy` + `SecurityProfile.allowed_signing_algorithms/1`, not by new persisted fields.
3. Extend `Discovery` with endpoint-specific auth metadata helpers for:
   - `token_endpoint_auth_methods_supported`
   - `token_endpoint_auth_signing_alg_values_supported`
   - `revocation_endpoint_auth_methods_supported`
   - `revocation_endpoint_auth_signing_alg_values_supported`
   - `introspection_endpoint_auth_methods_supported`
   - `introspection_endpoint_auth_signing_alg_values_supported`
4. Keep publication conditional:
   - publish signing algorithms only when the corresponding method set includes `private_key_jwt`
   - permit revocation/introspection to diverge if runtime behavior diverges
   - do not publish metadata that implies Phase 60 fetch hardening or Phase 61 full verifier work already exists

## Concrete Risks To Plan Around

### Drift risk

Registration, management, admin policy, and discovery can each be “individually correct” while still disagreeing. Phase 59 must add tests that pin the same truth across all four.

### Overclaim risk

Publishing `private_key_jwt` too broadly would misstate what the repo can currently enforce. This is the main user-facing security risk of the phase.

### Product-shape risk

It would be easy to turn this into a broader operator key-management feature. That would violate the phase boundary and create UI commitments ahead of the guarded fetcher/verifier phases.

## Test Targets

Primary tests to extend:

- `test/lockspire/protocol/registration_test.exs`
- `test/lockspire/protocol/registration_management_test.exs`
- `test/lockspire/protocol/discovery_test.exs`
- `test/lockspire/web/discovery_controller_test.exs`
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs`
- `test/lockspire/web/live/admin/clients_live/show_test.exs`

Useful support fixture:

- `test/support/fixtures/dcr_fixtures.ex`

## Validation Architecture

Phase 59 is well-served by focused protocol and LiveView tests. No new framework or external service is needed.

- Quick loop per task: run the task-local ExUnit files only.
- Wave-level verification: run the full Phase 59 test matrix plus warnings-as-errors.
- No integration or network tests are required in this phase because guarded remote JWKS fetch behavior is explicitly deferred to Phase 60.

## Recommended Plan Split

- `59-01`: DCR and RFC 7592 `jwks_uri` intake/update rules
- `59-02`: admin/policy truth for `private_key_jwt` and derived signing algorithms
- `59-03`: discovery, revocation, and introspection metadata alignment

## Sources Read

- `.planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/research/SUMMARY.md`
- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/protocol/registration_management.ex`
- `lib/lockspire/protocol/discovery.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/security_profile.ex`
- `lib/lockspire/protocol/introspection.ex`
- `lib/lockspire/protocol/revocation.ex`
- `lib/lockspire/domain/server_policy.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `test/lockspire/protocol/registration_test.exs`
- `test/lockspire/protocol/registration_management_test.exs`
- `test/lockspire/protocol/discovery_test.exs`
- `test/lockspire/web/discovery_controller_test.exs`
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs`
- `test/lockspire/web/live/admin/clients_live/show_test.exs`

## RESEARCH COMPLETE
