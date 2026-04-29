---
phase: 38-session-tracking-rp-initiated-logout
plan: "02"
subsystem: auth
tags: [oidc, session-tracking, sid, token-store, migration, id-token, ecto]

requires:
  - phase: 38-01
    provides: Phase 38 plan definitions and research context

provides:
  - Nullable sid column + B-tree index on lockspire_interactions and lockspire_tokens
  - sid field on Interaction and Token domain structs
  - InteractionRecord and TokenRecord schema/changeset/to_domain extensions for sid
  - revoke_by_sid/1 callback in TokenStore behaviour (optional) and implementation in Repository
  - sid generated at interaction creation via CSPRNG in authorization_flow.ex
  - sid threaded through authorization_code, access_token, and refresh_token issuance
  - sid carried by rotated refresh/access tokens in refresh_exchange.ex
  - sid OIDC claim emitted in all ID tokens via IdToken.sign/1
  - sid added to Claims protocol_claims drop-list preventing host override

affects:
  - 38-03
  - 38-04
  - 39

tech-stack:
  added: []
  patterns:
    - "sid denormalized on token records (same pattern as interaction_id) for fast lookups without joins"
    - "Optional TokenStore callback pattern for additive extension without breaking existing implementations"
    - "CSPRNG-based sid generation: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)"
    - "nil-safe id_token claim via Map.get + Claims.drop_nil_claims"

key-files:
  created:
    - priv/repo/migrations/20260429000001_add_sid_to_lockspire_interactions.exs
    - priv/repo/migrations/20260429000002_add_sid_to_lockspire_tokens.exs
    - test/lockspire/storage/ecto/repository_sid_test.exs
  modified:
    - lib/lockspire/domain/interaction.ex
    - lib/lockspire/domain/token.ex
    - lib/lockspire/storage/ecto/interaction_record.ex
    - lib/lockspire/storage/ecto/token_record.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/protocol/refresh_exchange.ex
    - lib/lockspire/protocol/id_token.ex
    - lib/lockspire/host/claims.ex
    - test/lockspire/protocol/authorization_flow_test.exs
    - test/lockspire/protocol/id_token_test.exs

key-decisions:
  - "revoke_by_sid nil guard returns {:ok, 0} without querying — prevents accidental full-table revocation on nil sid"
  - "revoke_by_sid guards on both is_nil(revoked_at) AND is_nil(redeemed_at) — excludes consumed auth codes unlike revoke_token_family"
  - "sid added to Claims @protocol_claims drop-list — prevents host override of Lockspire-owned OIDC claim (Rule 2 security fix)"
  - "build_rotated_access_token/build_rotated_refresh_token signatures extended with source_token param to carry sid forward"
  - "authorization_code.sid used as source for ID token sid in maybe_issue_id_token — avoids extra interaction fetch"

patterns-established:
  - "Additive migration pattern: nullable column + index, existing rows get nil, application guarantees value for new rows"
  - "Optional TokenStore callback via @optional_callbacks allows Repository to implement without breaking other store implementations"

requirements-completed:
  - SLO-01

duration: 8min
completed: 2026-04-29
---

# Phase 38 Plan 02: Session ID Schema, Domain, and Protocol Layer Summary

**Durable sid tracking on interactions and tokens with bulk revocation, full token issuance pipeline threading, and OIDC sid claim emission in ID tokens**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-29T16:13:58Z
- **Completed:** 2026-04-29T16:22:00Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Two additive migrations ship nullable sid column + B-tree index on both interaction and token tables
- revoke_by_sid/1 implemented in Repository with nil guard and redeemed_at filter, covered by integration tests
- sid generated via 256-bit CSPRNG at interaction creation time and denormalized onto all token types at issuance
- sid OIDC claim emitted in ID tokens; Claims module updated to prevent host override of the claim

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrations, domain structs, and Ecto record extensions** - `bc60128` (feat)
2. **Task 2: sid generation in authorization_flow.ex, token exchange threading, and ID token sid claim** - `7d779ad` (feat)

**Plan metadata:** committed with SUMMARY.md

## Files Created/Modified

- `priv/repo/migrations/20260429000001_add_sid_to_lockspire_interactions.exs` - Adds nullable sid + B-tree index to lockspire_interactions
- `priv/repo/migrations/20260429000002_add_sid_to_lockspire_tokens.exs` - Adds nullable sid + B-tree index to lockspire_tokens
- `lib/lockspire/domain/interaction.ex` - sid field added to @type t() and defstruct
- `lib/lockspire/domain/token.ex` - sid field added to @type t() and defstruct after interaction_id
- `lib/lockspire/storage/ecto/interaction_record.ex` - sid field, changeset cast, to_domain mapping
- `lib/lockspire/storage/ecto/token_record.ex` - sid field, changeset cast, to_domain mapping
- `lib/lockspire/storage/token_store.ex` - @optional_callbacks and @callback revoke_by_sid/1 added
- `lib/lockspire/storage/ecto/repository.ex` - revoke_by_sid/1 implementation after revoke_token_family/1
- `lib/lockspire/protocol/authorization_flow.ex` - generate_sid/0 helper, sid in build_interaction, sid in issue_authorization_code
- `lib/lockspire/protocol/token_exchange.ex` - sid: authorization_code.sid in access_token and refresh_token builds; sid passed to IdToken.sign
- `lib/lockspire/protocol/refresh_exchange.ex` - source_token param added to build_rotated_access_token/build_rotated_refresh_token; sid threaded
- `lib/lockspire/protocol/id_token.ex` - sid extracted via Map.get, build_claims/8 signature extended, "sid" => sid in protocol_claims
- `lib/lockspire/host/claims.ex` - "sid" added to @protocol_claims drop-list
- `test/lockspire/storage/ecto/repository_sid_test.exs` - Integration tests for revoke_by_sid/1 (nil guard, bulk revocation, isolation, persistence)
- `test/lockspire/protocol/authorization_flow_test.exs` - sid generation and uniqueness tests
- `test/lockspire/protocol/id_token_test.exs` - sid claim emission and nil-omission tests

## Decisions Made

- revoke_by_sid nil guard returns {:ok, 0} without querying — prevents accidental full-table revocation
- revoke_by_sid adds is_nil(redeemed_at) guard unlike revoke_token_family — excludes consumed auth codes
- "sid" added to Claims @protocol_claims list so Lockspire owns the claim and hosts cannot override it
- authorization_code.sid used directly as sid source in ID token issuance rather than re-fetching the interaction

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added "sid" to Claims @protocol_claims drop-list**
- **Found during:** Task 2 (ID token sid claim implementation)
- **Issue:** The plan specified emitting sid in ID tokens but did not explicitly call out adding "sid" to the @protocol_claims list that prevents host id_token map claims from overriding protocol-owned claims
- **Fix:** Added "sid" to the `@protocol_claims ~w(...)` list in `lib/lockspire/host/claims.ex`
- **Files modified:** lib/lockspire/host/claims.ex
- **Verification:** Existing Claims tests still pass; ID token tests verify sid is Lockspire-owned
- **Committed in:** 7d779ad (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical security correctness)
**Impact on plan:** Necessary correctness fix — Lockspire must own the sid claim. No scope creep.

## Issues Encountered

- Test migrations were not applied automatically on the test repo — required explicit `MIX_ENV=test mix ecto.migrate`. Resolved before running GREEN tests.
- 3 pre-existing test failures (KeysLive and KeysTest signing key lifecycle transitions) were present on the base commit and unchanged by this plan. Documented as out-of-scope.

## Known Stubs

None — all sid values are generated via CSPRNG at interaction creation time and threaded throughout. No hardcoded or placeholder values.

## Threat Flags

No new network endpoints, auth paths, or unplanned trust boundaries introduced. All changes are additive schema fields and internal protocol threading. The @protocol_claims addition strengthens the existing security posture per threat T-38-02.

## Next Phase Readiness

- Plan 03 can now use `interaction.sid` for the end_session flow — it is guaranteed non-nil for all new interactions
- Plan 03 can call `Repository.revoke_by_sid/1` to bulk-revoke tokens at logout completion
- Plan 03 can extract sid from ID tokens via the "sid" claim for logout token matching
- Plan 04's post_logout_redirect_uris client field does not depend on Plan 02 output

---
*Phase: 38-session-tracking-rp-initiated-logout*
*Completed: 2026-04-29*
