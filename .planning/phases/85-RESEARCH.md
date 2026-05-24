# Phase 85: DCR Intake And Representation - Research

## Overview

Phase 85 sits on an already-shipped logout propagation model. The durable client shape, Ecto schema, admin workflow, and logout delivery pipeline already understand:

- `backchannel_logout_uri`
- `backchannel_logout_session_required`
- `frontchannel_logout_uri`
- `frontchannel_logout_session_required`

The remaining gap is specifically the self-service DCR seam:

1. RFC 7591 registration still rejects all four fields as unsupported.
2. Registration persistence never copies the fields onto the self-registered `Client`.
3. RFC 7591/7592 JSON serialization does not expose the stored values back to the client.

No `CONTEXT.md` exists for this phase, so these recommendations derive from `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and the live codebase.

## Current Evidence

### Already present and should be reused

- `Lockspire.Domain.Client` already carries the four logout propagation fields.
- `Lockspire.Storage.Ecto.ClientRecord` already persists and round-trips them.
- `Lockspire.Storage.Ecto.Repository.snapshot_logout_clients/1` and `build_logout_deliveries/2` already consume them as the truth source for runtime logout propagation.
- `Lockspire.Admin.Clients.update_client/2` already validates operator-managed logout propagation with these rules:
  - absolute `http`/`https` URI
  - no fragment
  - `*_session_required` cannot be true unless the paired URI exists
  - `frontchannel_logout_uri` must share origin with at least one redirect URI

### Current DCR gap

- `Lockspire.Protocol.Registration.validate_unsupported_logout_metadata/1` rejects every logout metadata field with `invalid_client_metadata`.
- `Lockspire.Protocol.Registration.persist_client/5` never assigns the four fields to the new client.
- `Lockspire.Web.RegistrationJSON.base_payload/1` only emits a small subset of DCR-visible state and omits logout propagation fields entirely.
- `Lockspire.Protocol.RegistrationManagement.update/2` reuses `Registration.validate_intake_metadata/4`, so broadening validation in-place would also broaden RFC 7592 update semantics unless Phase 85 is explicit about scope control.

## Gray Area 1: Where should logout metadata validation live?

### Option A: Inline new checks inside `Lockspire.Protocol.Registration`

Pros:

- smallest patch for Phase 85
- fast path to shipping RFC 7591 create support

Cons:

- duplicates rules that already exist in operator update code
- makes Phase 86 harder because RFC 7592 update will need the same parsing and validation semantics
- increases the risk of truth drift between admin-managed and self-service-managed client metadata

### Option B: Extract a shared logout metadata parser/validator used by DCR

Pros:

- one place to define field normalization, boolean parsing, URI validation, and front-channel origin rules
- Phase 86 can reuse the same helper for RFC 7592 full-replace updates
- preserves the existing runtime truth model by making DCR adopt the same constraints as operator-managed clients

Cons:

- slightly larger Phase 85 patch

### Recommendation

Choose **Option B**. Introduce a small protocol-level helper dedicated to wire-format logout metadata parsing and validation. It should:

- accept RFC 7591 JSON metadata input
- return normalized typed attrs suitable for `%Lockspire.Domain.Client{}`
- map failures to `Registration.Error` with `code: :invalid_client_metadata`
- reuse `Lockspire.Clients.validate_logout_uri/1` and `frontchannel_logout_origin_matches_redirect_uri?/2`

This keeps the DCR validator narrow and makes Phase 86 a reuse task instead of a second design task.

## Gray Area 2: How to avoid accidentally widening RFC 7592 update support in Phase 85?

### Risk

`RegistrationManagement.update/2` currently calls `Registration.validate_intake_metadata/4`. If Phase 85 simply removes the unsupported-field guard and expands the validator without any scoping decision, PUT management updates may start accepting logout propagation metadata earlier than the roadmap allows.

### Recommendation

Phase 85 should separate:

- **validation acceptance for RFC 7591 create**
- **representation truth for RFC 7591 create + RFC 7592 read**

from:

- **RFC 7592 full-replace write semantics**, which stay in Phase 86

The safest implementation shape is:

1. Extract shared normalization/validation logic.
2. Use it in `Registration.register/1` now.
3. Keep `RegistrationManagement.update/2` unchanged in behavior for this phase unless the new helper is explicitly gated by call-site intent.

That preserves the roadmap boundary while still satisfying `DCRM-01` through truthful read responses.

## Gray Area 3: What does “truthful DCR JSON responses” need to cover in Phase 85?

### Recommendation

Phase 85 should make `Lockspire.Web.RegistrationJSON` emit the four logout propagation fields whenever they are stored on the `Client`, regardless of whether they were set by:

- self-service registration, or
- an operator/admin workflow

This matters because `DCRM-01` is a **read** requirement. A self-service client reading its current registration should see the same persisted logout metadata even if the operator seeded or corrected it outside DCR.

Scope for this phase:

- `POST /register` success body
- `GET /register/:client_id` read body

Defer:

- RFC 7592 PUT write semantics and full-replace clearing rules
- docs/support-surface wording updates

## Recommended Plan Split

### Plan 85-01

Add shared logout metadata parsing/validation for the RFC 7591 wire contract, including:

- URI shape checks
- boolean semantics
- session-required dependency checks
- front-channel origin matching
- RFC-shaped `invalid_client_metadata` failures

### Plan 85-02

Persist normalized logout metadata during registration create without broadening unrelated client state, and prove the values round-trip into the stored `Client`.

### Plan 85-03

Expose the persisted values truthfully in DCR JSON responses and add proof for:

- registration success responses
- registration management read responses
- negative invalid metadata responses
- operator-seeded read truth

## Key Files For Planning

- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/protocol/registration_management.ex`
- `lib/lockspire/web/registration_json.ex`
- `lib/lockspire/domain/client.ex`
- `lib/lockspire/storage/ecto/client_record.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/clients.ex`
- `test/lockspire/protocol/registration_test.exs`
- `test/lockspire/protocol/registration_management_test.exs`
- `test/lockspire/web/registration_json_test.exs`
- `test/lockspire/web/controllers/registration_controller_test.exs`
- `test/support/fixtures/dcr_fixtures.ex`

