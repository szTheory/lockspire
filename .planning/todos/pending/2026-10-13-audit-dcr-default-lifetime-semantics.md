---
created: 2026-10-13T23:28:13Z
title: Audit DCR default lifetime semantics
area: protocol
resolves_phase: 166
files:
  - lib/lockspire/client_metadata.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/client_auth.ex
  - lib/lockspire/protocol/client_auth/client_secret_jwt.ex
  - lib/lockspire/protocol/registration_access_token.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/web/registration_json.ex
audit_acknowledged:
  milestone: v1.42
  at: 2026-10-15
---

## Problem

The focused source audit completed during Phase 153. Its evidence is in [the archived Phase 153 trace](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md).

- App lifetime is stored/resolved but does not expire registrations. The built-in client has no expiry field or pruning path for it.
- App-management-token lifetime is stored/resolved but unused for issuance, lookup, rotation or management. These tokens have no built-in expiry. Replacing their hash or disabling the client blocks the prior token's use.
- Client-secret lifetime sets persisted and advertised expiry metadata for new secret-bearing registrations. Positive values add seconds to registration time; blank/nil and zero currently report registration time itself. Authentication does not enforce that expiry; assertion expiry is a separate check. Operator rotation does not renew the reported date.
- No automatic global lifetime fallback or dedicated host expiry callback was found. Storage comments and previous UI descriptions overstated the built-in behavior.

The current UI provides examples and explicitly states these enforcement limits. It no longer claims blank means unlimited or that the stored lifetimes provide automatic protection. This supersedes the earlier conservative “keep the default behavior” description. The protocol gap remains open, not accepted or fixed by microcopy.

## Solution

Use the completed trace rather than repeat the audit. Define intended unset/zero/positive semantics, including registration-token lifecycle and safe host/storage migration boundaries. Implement the agreed enforcement or remove unsupported configuration promises, and test issuance, authentication, management, rotation, expiry and registration-response metadata together. Cover existing records and advertised dates. Update storage comments and public guidance only after executable proof.

Standards to retain: [RFC 7591 registration response](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) distinguishes the wire value `client_secret_expires_at=0` from an expiry timestamp; do not confuse that with a zero-second policy duration. [RFC 7592 security considerations](https://www.rfc-editor.org/rfc/rfc7592.html#section-5) explains why registration-access-token expiry can strand app management; choose that policy deliberately rather than invent a universal timeout.

This requires protocol work separate from the authorized UI refinement. Preserve host ownership, existing security defaults and redaction. It does not block unrelated Phase 153 progress and must not be silently marked complete.

## v1.45 Roadmap Link

The approved v1.45 roadmap addresses this protocol gap across Phases 162–166. Phase 162 resolves semantics and upgrade compatibility; Phases 163–165 implement the selected lifecycles. `resolves_phase: 166` identifies the final cross-phase host/security proof needed to close this todo, not a claim that the audit or initialization fixed enforcement. Requirements DCR-02–19 provide the acceptance contract. Keep this todo pending until the implemented lifecycle and compatibility behavior is verified.
