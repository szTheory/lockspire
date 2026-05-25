# Phase 89: Registration, Discovery, And Admin Truth - Research

**Researched:** 2026-05-25
**Domain:** persisted `client_secret_jwt` registration truth, endpoint discovery truth, and operator/admin parity
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Registration and persisted client-auth truth
- **D-01:** Treat `token_endpoint_auth_method=client_secret_jwt` and `token_endpoint_auth_signing_alg=HS256` as an explicit persisted pair for the shipped v1.24 slice. Do not silently infer or default the signing algorithm during DCR or operator creation.
- **D-02:** Accept `client_secret_jwt` only for confidential clients. Public-client combinations must fail closed as invalid client metadata.
- **D-03:** Require `token_endpoint_auth_signing_alg` when `token_endpoint_auth_method=client_secret_jwt`, and for v1.24 accept only `HS256`.
- **D-04:** Reject `HS384` and `HS512` for now even though the broader OIDC surface permits them. Phase 88 shipped an `HS256`-only runtime.
- **D-05:** Reject `token_endpoint_auth_signing_alg` when the auth method is neither `client_secret_jwt` nor `private_key_jwt`; do not preserve stray JWT-auth metadata on non-JWT client-auth records.
- **D-06:** Reject `client_secret_jwt` under effective FAPI security profiles so registration truth matches the Phase 88 runtime denial posture.
- **D-07:** Store client-auth signing-alg truth as typed durable client state, not metadata-only spillover.
- **D-08:** RFC 7592 full-replace semantics must stay explicit: switching to `client_secret_jwt` requires the alg field, switching away clears the stored alg, and omitting the alg while remaining on `client_secret_jwt` is an error rather than silent reuse.

### Discovery and endpoint metadata truth
- **D-09:** Preserve Lockspire's existing route-truthful discovery shape. Publish `client_secret_jwt` only on mounted endpoints that actually use the shared direct-client verifier.
- **D-10:** Keep endpoint-local auth-method publication for `/token`, `/revoke`, and `/introspect`; do not collapse Phase 89 into a looser issuer-wide claim.
- **D-11:** When an endpoint publishes either `client_secret_jwt` or `private_key_jwt`, publish the corresponding `*_auth_signing_alg_values_supported` field.
- **D-12:** Published endpoint signing algorithms must be the union of JWT auth methods actually accepted there under the effective issuer posture: `HS256` for `client_secret_jwt`, plus the current asymmetric allowlist for `private_key_jwt`.
- **D-13:** Under FAPI profiles, do not publish `client_secret_jwt` and do not publish `HS256`; keep only the existing asymmetric FAPI posture.

### Admin and operator truth
- **D-16:** Expose `client_secret_jwt` in operator client creation now so admin parity matches DCR/discovery truth.
- **D-17:** Do not expose a broad editable signing-alg chooser in the admin UI for v1.24.
- **D-18:** Show the signing algorithm (`HS256`) explicitly as read-only truth anywhere `client_secret_jwt` is displayed in admin/detail/help copy.
- **D-19:** Preserve current immutable-field posture: auth method remains create-time security truth, later edits stay targeted workflows, and secret-handling/redaction posture remains unchanged.
- **D-20:** Operator wording should present `client_secret_jwt` as a narrow convenience auth method for direct-client endpoints, not as a stronger-trust or FAPI-capable posture.
- **D-21:** Keep secret-handling truth unchanged: raw client secrets and raw assertions are never exposed after initial issuance.

### Deferred Ideas (OUT OF SCOPE)
- Broader `client_secret_jwt` algorithm support beyond `HS256`
- FAPI-compatible `client_secret_jwt`
- Extending `client_secret_jwt` to `POST /par` or any endpoint outside the Phase 88 direct-client surface
- Turning admin into a generic editable JWT client-auth metadata console
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REG-01 | Operator-created and self-service confidential clients can register and persist `token_endpoint_auth_method=client_secret_jwt` only when the metadata includes a supported `token_endpoint_auth_signing_alg` value that matches Lockspire's issuer posture. | Registration intake, RFC 7592 replacement, operator creation normalization, and durable client storage all need one typed auth-method-plus-alg truth. [VERIFIED: `lib/lockspire/protocol/registration.ex`] [VERIFIED: `lib/lockspire/protocol/registration_management.ex`] [VERIFIED: `lib/lockspire/clients.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`] |
| REG-02 | Registration, RFC 7592 management, and admin/operator views preserve current secret-handling truth while `client_secret_jwt` metadata stays coherent with the stored auth method. | Existing secret issuance and redaction seams are already correct; Phase 89 mainly needs stored metadata parity and truthful serialization/display. [VERIFIED: `lib/lockspire/clients.ex`] [VERIFIED: `lib/lockspire/redaction.ex`] [VERIFIED: `test/lockspire/admin/clients_test.exs`] |
| META-01 | Discovery and per-endpoint metadata publish `client_secret_jwt` and corresponding signing-algorithm metadata only on endpoints that actually consume the shared verifier. | `Discovery` already publishes mounted endpoint truth, but its auth-method and signing-alg helpers still assume `private_key_jwt` only. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`] |
</phase_requirements>

## Summary

The repo already shipped the runtime half of `client_secret_jwt` in Phase 88, but the non-runtime truth still diverges in three places. First, DCR and operator creation paths do not fully admit or persist `client_secret_jwt` plus its required signing algorithm. Second, discovery publication still derives JWT signing metadata only from whether `private_key_jwt` is present, so it cannot truthfully publish the mixed `HS256` plus asymmetric union. Third, admin surfaces still present the older auth-method set and only have explanatory helpers for `private_key_jwt`. [VERIFIED: `lib/lockspire/protocol/registration.ex`] [VERIFIED: `lib/lockspire/protocol/registration_management.ex`] [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`] [VERIFIED: `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`]

The narrowest safe implementation is to add one typed stored field for JWT client-auth signing-alg truth on the client record, then drive DCR intake, RFC 7592 replace semantics, admin creation, show-page copy, and discovery publication from that single durable source. That keeps the Phase 88 runtime slice intact while preventing metadata-only drift and avoiding any new generic JWT-auth matrix surface. [VERIFIED: `lib/lockspire/domain/client.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`] [VERIFIED: `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`]

**Primary recommendation:** Split Phase 89 into three slices: persisted registration/DCR truth first, truthful discovery publication second, and admin/operator parity third. Plan 1 should establish the typed field and the validation/replace rules that every other surface depends on. Plan 2 should publish endpoint-local auth methods and JWT signing algorithms from the actual route and profile truth. Plan 3 should expose the same stored truth in admin creation/detail/policy surfaces without turning the UI into a generic JWT editor. [VERIFIED: `.planning/ROADMAP.md`]

## Current Code Truth And Exact Gaps

### 1. Registration and DCR currently drop or mis-handle `client_secret_jwt` metadata

- `Lockspire.Protocol.Registration.validate_intake_metadata/4` already centralizes DCR validation, but it has no dedicated validator for `token_endpoint_auth_signing_alg` coherence with `token_endpoint_auth_method`. [VERIFIED: `lib/lockspire/protocol/registration.ex`]
- `Lockspire.Protocol.RegistrationManagement.apply_metadata_to_client/2` still maps DCR metadata to `:client_secret_basic | :client_secret_post | :private_key_jwt | :none` only. A `client_secret_jwt` update therefore cannot round-trip through RFC 7592 today. [VERIFIED: `lib/lockspire/protocol/registration_management.ex`]
- `Lockspire.Clients.normalize_auth_method/1` still accepts only `:none`, `:client_secret_basic`, `:client_secret_post`, and `:private_key_jwt`, so operator-created clients cannot use `client_secret_jwt` yet. [VERIFIED: `lib/lockspire/clients.ex`]
- `ClientRecord` does not yet allow `:client_secret_jwt` in its Ecto enum and has no typed field for JWT client-auth signing algorithm truth, even though the domain struct already knows about the auth method and stores sealed verifier material. [VERIFIED: `lib/lockspire/domain/client.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`]

### 2. Discovery is route-truthful but JWT signing metadata is still asymmetric-only

- `Lockspire.Protocol.Discovery` already computes mounted endpoint metadata and filters revocation/introspection publication by mounted route truth. That is the correct seam to preserve. [VERIFIED: `lib/lockspire/protocol/discovery.ex`]
- `published_direct_client_auth_methods/0` currently delegates to `ClientAuth.supported_auth_method_names/0`, which means once `client_secret_jwt` is made publishable it will appear broadly on token and revocation, while introspection will continue filtering by its local allowlist. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- `maybe_put_endpoint_auth_signing_algorithms/3` only checks whether `private_key_jwt` is published and then emits the asymmetric allowlist. That is insufficient once `client_secret_jwt` also becomes a published method. [VERIFIED: `lib/lockspire/protocol/discovery.ex`]
- The tests already pin both the static seam and the actual HTTP discovery document, so they are the right proof layer for endpoint-local method lists and mixed signing-alg unions. [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`]

### 3. Admin and operator surfaces still present the older auth-method truth

- The admin creation form exposes `client_secret_basic`, `client_secret_post`, and `none` only. There is no `client_secret_jwt` option or read-only `HS256` truth. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]
- The client detail page has a dedicated read-only `private_key_jwt` panel but no equivalent explanatory truth for `client_secret_jwt`. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] [VERIFIED: `test/lockspire/web/live/admin/clients_live/show_test.exs`]
- The global DCR policy page currently explains only `private_key_jwt` registration posture through `Admin.ServerPolicy.private_key_jwt_registration_truth/1`. That helper needs a generalized JWT-auth truth story or an adjacent `client_secret_jwt` helper. [VERIFIED: `lib/lockspire/admin/server_policy.ex`] [VERIFIED: `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`] [VERIFIED: `test/lockspire/web/live/admin/policies_live/dcr_test.exs`]

## Recommended Durable Modeling

### Typed field, not metadata spillover

- Add a typed client field for JWT client-auth signing algorithm truth and round-trip it through `Domain.Client`, `ClientRecord`, persistence, DCR serialization, and admin surfaces. This must be distinct from `id_token_signed_response_alg`, which is a client-facing response preference, not a client-auth setting. [VERIFIED: `lib/lockspire/domain/client.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`] [VERIFIED: `lib/lockspire/web/registration_json.ex` via current DCR tests]
- The field should accept `:HS256` for `client_secret_jwt` and the current asymmetric allowlist for `private_key_jwt`, while still enforcing per-method coherence rules at validation time. [INFERRED from OIDC metadata naming plus current runtime and context constraints]

### Full-replace DCR semantics

- `Registration.register/1` and `RegistrationManagement.update/2` should share one metadata validator for JWT client-auth coherence.
- Switching to `client_secret_jwt` in RFC 7592 must require `token_endpoint_auth_signing_alg=HS256`.
- Remaining on `client_secret_jwt` while omitting the alg must be an error.
- Switching away from JWT auth should clear the stored client-auth signing alg.
- Supplying `token_endpoint_auth_signing_alg` for `client_secret_basic`, `client_secret_post`, or `none` should fail closed rather than linger in `metadata`. [VERIFIED: `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`] [VERIFIED: `lib/lockspire/protocol/registration_management.ex`]

### FAPI posture

- Registration truth must explicitly reject `client_secret_jwt` when the effective profile is `:fapi_2_0_security` or `:fapi_2_0_message_signing`, because Phase 88 runtime already denies that slice there. [VERIFIED: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`] [VERIFIED: `lib/lockspire/protocol/security_profile.ex`]
- Discovery publication must likewise omit both `client_secret_jwt` and `HS256` under FAPI profiles, while preserving the existing asymmetric publication for `private_key_jwt`. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`]

## Validation Architecture

- **Framework:** ExUnit
- **Fast registration/admin path:** `mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs`
- **Fast discovery path:** `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`
- **Full suite:** `mix test`
- **Why this is sufficient:** the phase is pure repo-native storage, protocol, discovery, and LiveView truth; no external service or browser-only validation path is required. [VERIFIED: current test layout]

## Risks And Pitfalls

### Metadata-only drift

- The biggest risk is storing `token_endpoint_auth_signing_alg` only in `client.metadata`. That would let registration, discovery, and admin views diverge from the actual record shape and would be easy to lose under RFC 7592 replace semantics. [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`] [VERIFIED: `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`]

### Silent defaults

- Defaulting `HS256` when a client chooses `client_secret_jwt` would violate the explicit metadata contract and hide operator mistakes. Validation should force the pair to be explicit. [VERIFIED: `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`]

### Discovery overstatement

- If discovery simply reuses one issuer-wide signing algorithm list for every JWT client-auth method, it will falsely imply that `HS256` is valid for `private_key_jwt` or that asymmetric algorithms are valid for `client_secret_jwt`. Publication must build the union from the methods actually advertised on each endpoint. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`]

### Admin surface widening

- Adding a generic editable signing-alg select would imply broader support than the runtime ships. The admin surface should expose `client_secret_jwt` as a create-time choice and render `HS256` as read-only explanatory truth. [VERIFIED: `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`]

## Recommended Plan Split

1. **Persisted registration and RFC 7592 truth**: add typed client-auth signing-alg storage, validation, and replace semantics across DCR and operator creation. [VERIFIED: `lib/lockspire/protocol/registration.ex`] [VERIFIED: `lib/lockspire/protocol/registration_management.ex`] [VERIFIED: `lib/lockspire/clients.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`]
2. **Route-truthful discovery publication**: publish `client_secret_jwt` and mixed JWT signing algorithms only where the shared verifier actually runs and only under non-FAPI posture. [VERIFIED: `lib/lockspire/protocol/discovery.ex`] [VERIFIED: `test/lockspire/protocol/discovery_test.exs`] [VERIFIED: `test/lockspire/web/discovery_controller_test.exs`]
3. **Admin/operator parity**: expose the new method in operator creation and detail/help surfaces, keep read-only `HS256` truth, and align the DCR policy explanation with the actual registration posture. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] [VERIFIED: `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`]

## Key Files For Planning

- `.planning/phases/89-registration-discovery-and-admin-truth/89-CONTEXT.md`
- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/protocol/registration_management.ex`
- `lib/lockspire/protocol/dcr_policy.ex`
- `lib/lockspire/domain/client.ex`
- `lib/lockspire/storage/ecto/client_record.ex`
- `lib/lockspire/clients.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/admin/server_policy.ex`
- `lib/lockspire/protocol/discovery.ex`
- `lib/lockspire/web/live/admin/clients_live/form_component.ex`
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`
- `test/lockspire/protocol/registration_test.exs`
- `test/lockspire/protocol/registration_management_test.exs`
- `test/lockspire/protocol/discovery_test.exs`
- `test/lockspire/web/discovery_controller_test.exs`
- `test/lockspire/admin/clients_test.exs`
- `test/lockspire/web/live/admin/clients_live/show_test.exs`
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs`

## Metadata

**Confidence breakdown:**
- Registration/storage modeling: HIGH - the gaps are direct and already localized in the current validator, normalizer, and Ecto enum seams. [VERIFIED: `lib/lockspire/protocol/registration.ex`] [VERIFIED: `lib/lockspire/protocol/registration_management.ex`] [VERIFIED: `lib/lockspire/storage/ecto/client_record.ex`]
- Discovery publication: HIGH - route truth is already correct; only method and signing-alg composition needs extension. [VERIFIED: `lib/lockspire/protocol/discovery.ex`]
- Admin/operator parity: HIGH - the needed surfaces and proof modules already exist and just need the new narrow truth added. [VERIFIED: `lib/lockspire/web/live/admin/clients_live/form_component.ex`] [VERIFIED: `lib/lockspire/web/live/admin/clients_live/show.ex`] [VERIFIED: `test/lockspire/web/live/admin/policies_live/dcr_test.exs`]

## RESEARCH COMPLETE
