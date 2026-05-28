---
phase: 99-signer-extraction-jwt-default-issuance
plan: 06
subsystem: ui
tags: [phoenix-liveview, admin, access-token-format, jwt, opaque, ecto-enum]

# Dependency graph
requires:
  - phase: 99-01
    provides: "access_token_format storage (Ecto.Enum :jwt|:opaque) on client_record + server_policy_record, nil-as-inherit, update_changeset cast"
provides:
  - "Per-client access_token_format override surface on the admin client-detail screen (inherit|jwt|opaque select)"
  - "normalize_mutable_field(:access_token_format, ...) plumbing mapping inherit/nil/\"\" -> nil and jwt/opaque -> atoms"
  - "validate_access_token_format_if_present/1 rejecting unknown values with :invalid_access_token_format (T-99-19)"
  - "Global / override / effective access-token-format display rows on the SHOW page (effective uses signer-aligned per-client -> server-default -> :jwt precedence)"
affects: [99-signer-extraction, 102-generated-host-scaffolding-telemetry-migration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hybrid mutable-field normalizer: select-idiom (dpop_policy) for jwt/opaque atoms + nil-cast idiom (authorization_signed_response_alg) for inherit->nil"
    - "nil-aware select default helper (format_default_for_select/1) for a nullable override that stores no :inherit sentinel"
    - "SHOW global/override/effective trio mirroring security-profile/PAR rows, with nil rendered as inherit instead of Not configured"

key-files:
  created: []
  modified:
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs

key-decisions:
  - "Stored nil is the canonical inherit state — no :inherit sentinel atom is persisted anywhere (D-06)"
  - "Added validate_access_token_format_if_present/1 (mirrors validate_dpop_policy_if_present) so unknown values are rejected with a clean field error instead of a raw changeset error (T-99-19)"
  - "Wired client[access_token_format] through edit_attrs/2 in show.ex — the form select otherwise renders but never persists, because edit_attrs is the LiveView form-submit bridge to Admin.update_client"
  - "Effective resolution implemented inline (per-client -> server-default -> :jwt) since no shared signer resolver exists in the wave-2 worktree base; precedence matches the signer contract"

patterns-established:
  - "Pattern: nullable override select stores nil for inherit and uses a nil-aware default helper for pre-selection, unlike sibling atom-storing overrides (dpop_policy/par_policy/security_profile)"
  - "Pattern: reversible non-destructive override does NOT borrow the lockspire-admin-warning block (reserved for the FAPI mixed-mode security downgrade)"

requirements-completed: [FORMAT-02]

# Metrics
duration: 10min
completed: 2026-05-28
---

# Phase 99 Plan 06: Admin access_token_format Override Surface Summary

**Per-client access_token_format override (inherit|jwt|opaque) on the admin client-detail edit form with a JWT-vs-opaque doclink, inherit->nil normalize plumbing, and global/override/effective SHOW rows with signer-aligned effective resolution.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-28T14:11:42Z
- **Completed:** 2026-05-28T14:21:57Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- `access_token_format` is now an operator-mutable field with a HYBRID normalizer (`inherit`/`nil`/`""` -> `nil`, `jwt`/`opaque` -> atoms) and a boundary validator rejecting forged values.
- The admin edit form renders an `inherit | jwt | opaque` `<select>` (param `client[access_token_format]`) directly after the dpop_policy control, gated to edit mode, with a `lockspire-admin-help` doclink to `docs/protect-phoenix-api-routes.md` and the UI-SPEC help copy.
- The form selection persists end-to-end: the param is bridged through `edit_attrs/2` -> `Admin.update_client` -> `normalize_mutable_field` -> `update_changeset`.
- The SHOW page gains three rows — Global (`<code>`, server default), Client override (`<code>`, `nil` rendered as `inherit`), and Effective (`<strong>`, resolved) — mirroring the security-profile/PAR trios without borrowing the mixed-mode warning block.
- Effective value resolves with the same per-client -> server-default -> `:jwt` precedence the signer uses.

## Task Commits

Each task was committed atomically (TDD: failing test + implementation per task):

1. **Task 1: clients.ex @mutable_fields entry + normalize/validate clauses** - `2d0bcb2` (feat)
2. **Task 2: form_component.ex override select + doclink + nil-aware defaults_for (+ edit_attrs wiring)** - `639db87` (feat)
3. **Task 3: show.ex global/override/effective display rows + helpers** - `b0b3d17` (feat)

_Note: STATE.md / ROADMAP.md are intentionally NOT updated here — the orchestrator owns those writes after the wave merges (worktree-mode execution)._

## Files Created/Modified
- `lib/lockspire/admin/clients.ex` - Added `access_token_format` to `@mutable_fields`; `normalize_mutable_field(:access_token_format, ...)` + private `normalize_access_token_format/1` (hybrid inherit->nil / jwt|opaque->atom); `validate_access_token_format_if_present/1` wired into `validate_safe_update`.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - Added the three-option override `<select>` + help/doclink block after dpop_policy; extended `defaults_for(:edit)` with nil-aware `format_default_for_select/1`.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Added the three display rows; assigned `global_access_token_format` + `effective_access_token_format` in mount/load_client/save_client; added `resolve_effective_access_token_format/2`, `global_access_token_format/1`, `access_token_format_override_label/1`; wired `access_token_format` through `edit_attrs/2`.
- `test/lockspire/admin/clients_test.exs` - Added normalize + update round-trip coverage (jwt/opaque/inherit/nil/blank/atom + unknown-value rejection).
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - Added edit-form render+persist test and the global/override/effective row tests (nil-as-inherit -> jwt, opaque-override -> opaque).

## Decisions Made
- **No `:inherit` sentinel** — `nil` is the inherit state both in storage and in the normalizer, per D-06 / UI-SPEC Anti-Drift Checklist. Confirmed by tests and greps.
- **Boundary validation added** — `validate_access_token_format_if_present/1` mirrors `validate_dpop_policy_if_present` so an out-of-set value yields `{:error, [%{field: :access_token_format, reason: :invalid_access_token_format, detail: value}]}` rather than relying solely on the Ecto.Enum rejection (clearer operator error; T-99-19 mitigation).
- **Inline effective resolution** — the signer's shared resolver is delivered by sibling wave-2 plans not present in this worktree base, so effective resolution is implemented inline with the identical per-client -> server-default -> `:jwt` precedence (T-99-20 coherence).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Wired `client[access_token_format]` through `edit_attrs/2` in show.ex**
- **Found during:** Task 2 (form select implementation)
- **Issue:** The plan's Task 2 lists only `form_component.ex`, but the rendered `<select>` would never persist: the admin edit form submit is bridged to `Admin.update_client` exclusively through `edit_attrs/2` in `show.ex`, which did not extract `access_token_format` from the form params. Without this, the must-have "saving it persists nil/:jwt/:opaque" truth fails (the form select is inert).
- **Fix:** Added `access_token_format: params["access_token_format"]` to `edit_attrs/2`. This is the form-submit plumbing for the new control and is required for the FORMAT-02 round-trip; `show.ex` is already an in-scope file for this plan (Task 3 / `files_modified`).
- **Files modified:** `lib/lockspire/web/live/admin/clients_live/show.ex`
- **Verification:** `show_test.exs` edit-form test submits `access_token_format: "opaque"` and asserts the reloaded client returns `:opaque`; green.
- **Committed in:** `639db87` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical wiring)
**Impact on plan:** The auto-fix is essential for the FORMAT-02 persistence truth; it stays within the plan's declared `files_modified` set. No scope creep.

## Issues Encountered
- **Worktree had no deps/`_build`** — fetched with `mix deps.get` and ran `MIX_ENV=test mix ecto.migrate` (test DB `lockspire_test` already present in Postgres) to enable the test suite. (Rule 3 blocking fix; no package substitution.)
- **Edit-form persist test initially failed on an unrelated reserved-scope validation** — the test client's pre-filled `allowed_scopes: ["openid"]` is rejected on update (`"openid"` is a reserved scope per `Clients.validate_scopes/2`). The form submit carries all fields, so the unrelated `allowed_scopes` validation short-circuited the update before the `access_token_format` write. Resolved by submitting a valid `allowed_scopes: "email"` in the test (test-fixture fix, not a code change).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- FORMAT-02 admin surface is complete and green: operators can read and set a per-client `access_token_format` override and see global/override/effective truth.
- The effective-resolution precedence is implemented inline; when the signer's shared resolver lands (sibling wave-2 plans / later phase), `resolve_effective_access_token_format/2` in `show.ex` can be repointed to it for a single source of truth (no behavior change expected — same precedence).
- No new CSS classes, routes, telemetry, or doctor task introduced (those remain Phase 102 scope).

---
*Phase: 99-signer-extraction-jwt-default-issuance*
*Completed: 2026-05-28*
