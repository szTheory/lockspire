# Phase 86: RFC 7592 Update Semantics And Proof - Research

## Overview

Phase 86 starts from a partially completed DCR logout metadata slice:

- Phase 85 already made RFC 7591 registration accept, persist, and read the four logout propagation fields.
- RFC 7592 management read already exposes the stored values truthfully.
- RFC 7592 management update still rebuilds the client without applying those four fields, so self-service updates cannot yet replace or clear them through the shipped management seam.

No `CONTEXT.md` exists for this phase, so these recommendations derive from `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, Phase 85 artifacts, and the live codebase.

## Current Evidence

### Already present and should be reused

- `Lockspire.Protocol.Registration.validate_intake_metadata/4` already validates logout metadata for management update callers via `Admin.Clients.validate_logout_metadata/3` with strict boolean semantics.
- `Lockspire.Admin.Clients.normalize_logout_metadata/1` already defines the typed normalization needed for URI trimming, boolean coercion, and omission-to-`nil`/`false` behavior.
- `Lockspire.Domain.Client`, `Lockspire.Storage.Ecto.ClientRecord`, and the operator/admin surfaces already persist and display the four logout propagation fields as first-class client state.
- `Lockspire.Web.RegistrationJSON.update_response/1` already serializes logout metadata from the persisted `%Client{}` if the update path supplies those fields.

### Current RFC 7592 gap

- `Lockspire.Protocol.RegistrationManagement.apply_metadata_to_client/2` rebuilds the managed client from incoming metadata but never copies:
  - `backchannel_logout_uri`
  - `backchannel_logout_session_required`
  - `frontchannel_logout_uri`
  - `frontchannel_logout_session_required`
- Because the update path omits those assignments, RFC 7592 PUT cannot currently replace or clear the stored logout propagation metadata even though validation already understands the fields.
- `persist_update/3` rotates the registration access token and appends the `:dcr_management_updated` audit event already; the gap is payload application and proof, not a missing transaction shell.

## Gray Area 1: What does full-replace mean for optional logout metadata?

### Risk

RFC 7592 PUT is modeled here as full replacement of client metadata. If Phase 86 only sets fields when present, omitted logout fields could linger from prior state and violate replacement semantics.

### Recommendation

Treat logout propagation fields exactly like the rest of the DCR-managed typed client surface:

- normalize all four fields from the request body on every update
- assign the normalized values onto `%Client{}`
- when a logout URI is omitted, clear it to `nil`
- when a paired `*_session_required` field is omitted or its URI is absent, store `false`

The cleanest implementation is to reuse `Admin.Clients.normalize_logout_metadata/1` inside `apply_metadata_to_client/2` and thread its output directly into the rebuilt client struct.

## Gray Area 2: How should Phase 86 preserve RAT rotation, provenance, and audit truth?

### Recommendation

Keep the current transaction envelope intact:

- validation still happens before RAT generation
- successful updates still rotate the RAT exactly once
- persistence still goes through `ClientRecord.changeset/2`
- the stored client keeps `provenance: :self_registered`
- `Repository.append_audit_event/1` continues to emit `:dcr_management_updated`

Phase 86 should add explicit proof for these invariants instead of redesigning them. The likely code change is small; the proof burden is the real milestone work.

## Gray Area 3: What proof is needed for `PROOF-01` and `DCRM-03`?

### Recommendation

Phase 86 should prove positive and negative lifecycle cases at the seams users actually touch:

- protocol-level update success when setting logout metadata
- protocol-level update success when replacing existing values with different ones
- protocol-level update success when clearing existing logout metadata by omission under full-replace semantics
- protocol-level rejection for malformed URI, invalid boolean shape, missing paired URI, and front-channel origin mismatch
- integration proof that `PUT /register/:client_id` returns rotated RAT plus the persisted logout metadata
- reuse-prevention proof that the previous RAT is invalid immediately after update
- audit/provenance proof that operator/admin truth still comes from the same typed client fields and update audit path

## Recommended Plan Split

### Plan 86-01

Apply normalized logout propagation metadata during RFC 7592 update persistence, including explicit full-replace clearing semantics.

### Plan 86-02

Prove lifecycle invariants for management update: RAT rotation, update response truth, persisted state, provenance retention, and audit continuity.

### Plan 86-03

Broaden automated proof for positive and negative management cases across protocol and controller seams so `PROOF-01` is satisfied inside the repo-native suite.

## Key Files For Planning

- `lib/lockspire/protocol/registration_management.ex`
- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/web/registration_json.ex`
- `test/lockspire/protocol/registration_management_test.exs`
- `test/lockspire/web/controllers/registration_controller_test.exs`
- `test/support/fixtures/dcr_fixtures.ex`
