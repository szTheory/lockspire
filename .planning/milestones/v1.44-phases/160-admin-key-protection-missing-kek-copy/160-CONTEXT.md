# Phase 160: Admin Key Protection & Missing-KEK Copy - Context

**Gathered:** 2026-10-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

An operator on the admin Keys page can tell at a glance whether signing keys are protected, and understands why key generation is refused when no key-encryption key is set up. Covers KEY-UI-01, KEY-UI-02, KEY-UI-03; constrained by SAFE-02 (no protocol, security-default, schema, or dependency changes; no key material or KEKs on admin pages).

Out of scope: new controls (retry, rotate, re-encrypt buttons), per-KEK counts, KMS/Vault providers (KEK-04), changes to `Admin.Keys` domain semantics.
</domain>

<decisions>
## Implementation Decisions

### Data source and state classification
- **D-01:** The Key protection line uses the existing public `Lockspire.Admin.encryption_status/0` (→ `Admin.Keys.encryption_status/0` → `EncryptionStatus.build/2`), the same readiness truth as `mix lockspire.doctor.key_encryption`, `keys.reencrypt --check`, and `Install.Verify`. No new domain/storage function, no second classifier, nothing extracted from the doctor task.
- **D-02:** A small `@moduledoc false` presenter (e.g. `KeysLive.Protection.summarize/1`) maps the status map or error tuple to exactly one of seven states, with this precedence (first match wins):
  1. could-not-check — `{:error, :repo_not_started}`, `{:error, :storage_unavailable}`, or any rescued raise/exit
  2. invalid-config — `{:error, {:invalid_config, _}}` (message text never rendered)
  3. not-set-up — `configured: false`
  4. unreadable — `unknown_kek != %{}` or `undecryptable > 0`
  5. unencrypted — `legacy > 0`
  6. older-key — any `by_kek_id` key other than `current_kek_id`
  7. encrypted — names `current_kek_id`
- **D-03:** Not-set-up wording must not promise existing keys keep working (sealed rows become unreadable when no keyset is configured). It states that no key-encryption key is set up and new keys cannot be created until one is.
- **D-04:** `stranded_retired` rows do not change the state (matches `ready?` and doctor's non-blocking note). Zero stored keys with a configured KEK reads as the encrypted state ("new keys are encrypted with key-encryption key X"). No extra "no keys yet" state.

### Placement, loading, and failure isolation
- **D-05:** The line renders directly under `page_hero` in `keys_live/index.ex`, outside the `@inventory_state` `case`, so protection-check failure and inventory failure are independent; a failed check never hides the key list.
- **D-06:** Separate assign (e.g. `key_protection`), loaded in `assign_inventory/2` (covers `handle_params` and `retry_inventory`), refreshed after a successful generate. Wrapped so any error or raise becomes could-not-check. No `connected?` guard (matches existing inventory loading and the bare-socket test style).
- **D-07:** Read-only text, reusing the "Status / What we checked" check pattern from `policies_live/security_profile.ex` (or `AdminComponents.decision_summary` with a tone); any new component is a thin wrapper. Meaning carried by text, not colour alone. Could-not-check uses a neutral tone, never success. Optional `<code>mix ...</code>` pointer (gen.kek / doctor) is text, not a control.
- **D-08:** Disclosure limits: show only the current KEK ID (operator-chosen label). Never show configured KEK ID list, per-KEK counts, `unknown_kek` IDs, env var names, `{:invalid_config, msg}` text, or key material. No counts at all; point to `mix lockspire.doctor.key_encryption` for detail.

### Missing-KEK generation error
- **D-09:** Add a `{:error, :key_encryption_not_configured}` clause to `generate_key/3` in `keys_live/index.ex` before the catch-all `{:error, _reason}`, writing to the existing `generation_error` assign (rendered in `<ul class="lockspire-admin-errors" role="alert">`), not flash. Copy says: no key-encryption key is set up; Lockspire will not store private keys unencrypted; set one up with `mix lockspire.gen.kek` and restart. Catch-all copy ("The signing/encryption key could not be generated.") unchanged. Generate buttons stay enabled.
- **D-10:** The clause applies to both "Generate signing key" (`:sig`) and "Generate encryption key" (`:enc`), since both seal private keys and hit the same error; wording names the key use, with the use-neutral fact "private keys are not stored unencrypted".

### Vocabulary (user-confirmed)
- **D-11:** The admin UI calls the KEK a **"key-encryption key"** — never a bare "encryption key", which already means the request-decryption (`use: :enc`) key on this page. "KEK" appears only inside `mix lockspire.gen.kek` / doctor command pointers.
- **D-12:** Add PRODUCT.md vocabulary-map rows in the same change: `key-encryption key` (the key that encrypts stored private keys; `:key_encryption`, gen.kek) and `Key protection` (the read-only status line). Do not retire "KEK" or "encryption key" (contract test is case-insensitive substring per line and would flag `gen.kek` / legitimate JWE copy). Add retired-wording rows only for copy actually replaced — none is planned. `vocabulary_contract_test.exs` must pass.
- **D-13:** Write for the least technical persona that uses the Keys page per PRODUCT.md; describe what Lockspire actually does.

### Claude's Discretion
- Exact sentence wording for each of the seven states and the generation error, within D-03, D-08, D-11 and PRODUCT.md tone.
- Component choice between security-profile check pattern and `decision_summary` (D-07).
- Optional docs-only tightening of `Admin.generate_key` `@spec` to name `:key_encryption_not_configured`.
- Test fixtures: existing keys-live fixtures seed legacy rows (classify as unencrypted); add sealed fixtures via `KeyEncryptionHelpers.seal_private_jwk/2` for the encrypted/older-key states.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 160 entry and success criteria
- `.planning/REQUIREMENTS.md` — KEY-UI-01..03, SAFE-02
- `PRODUCT.md` — personas, vocabulary map (~line 105), retired-wording table (~line 141)
- `AGENTS.md` — Admin UI Copy rules
- `.planning/research/v1.44-adopter-polish/ARCHITECTURE.md` — Items 4–5
- `.planning/research/v1.44-adopter-polish/FEATURES.md` — draft state copy (lines ~68–108; note "Existing keys keep signing" is superseded by D-03)
- `.planning/research/v1.44-adopter-polish/PITFALLS.md` — M1–M4
- `.planning/phases/159-key-encryption-key-setup-dx/159-CONTEXT.md` — gen.kek, `{:system, VAR}`, fail-closed config
- `lib/lockspire/web/live/admin/keys_live/index.ex`, `show.ex`, `action_component.ex`
- `lib/lockspire/admin.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/admin/keys/encryption_status.ex`, `lib/lockspire/admin/keys/reencrypt.ex`
- `lib/lockspire/config.ex`, `lib/lockspire/application.ex`
- `lib/mix/tasks/lockspire.doctor.key_encryption.ex`
- `lib/lockspire/web/components/admin_components.ex`
- `lib/lockspire/web/live/admin/policies_live/security_profile.ex` — read-only check precedent
- `test/lockspire/web/live/admin/vocabulary_contract_test.exs`, `test/lockspire/web/live/admin/keys_live_test.exs`, `test/lockspire/admin/keys_encryption_status_test.exs`, `test/lockspire/security/key_material_leak_test.exs`, `test/support/key_encryption_helpers.ex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Admin.encryption_status/0` (`admin.ex:245-252`) — public, read-only, no telemetry, no Mix dependency; returns status map (`configured`, `current_kek_id`, `configured_kek_ids`, `total`, `legacy`, `by_kek_id`, `unknown_kek`, `undecryptable`, `stranded_retired`, `pending`, `ready?`) or `{:error, :repo_not_started | :storage_unavailable | {:invalid_config, msg}}`. Resolves config fresh via `Config.key_encryption!/0`.
- `Admin.Keys.generate_key/1` returns `{:error, :key_encryption_not_configured}` when `Config.key_encryption_keyset()` (boot cache) is nil (`keys.ex:85-88`).
- Components: `page_hero`, `decision_summary` (tones `:success | :warning | :danger | :info`), `alert`, `description_list`, `info_tooltip`, `empty_state`.
- Test helpers: `KeyEncryptionHelpers.put_key_encryption/1` (nil clears env + persistent_term cache), `seal_private_jwk/2`; test env KEK ids `test-1` (current) and `test-2`.

### Established Patterns
- Read-state assigns `:loading | :loaded | :error` with calm empty-state copy; failed reads never render as zero or healthy (`keys_live/index.ex`, `device_authorizations_live/index.ex:167-177`).
- Generation errors rendered from assigns in `lockspire-admin-errors` list, not flash.
- Tests drive `Index.mount/3`, `handle_params/3`, `handle_event/3` on `socket_for(:index)` and render via `rendered_to_string(Index.render(assigns))`; `async: false`, SQL sandbox; failures simulated with `DROP TABLE lockspire_signing_keys`. `refute_forbidden_key_copy` bans "plaintext key"/"private jwk".

### Integration Points
- `KeysLive.Index.mount/3` (new assign), `assign_inventory/2` (load), `generate_key/3` success branch (refresh) and new error clause.
- `PRODUCT.md` vocabulary map and retired-wording table.
</code_context>

<specifics>
## Specific Ideas

- User chose "key-encryption key" as the UI term to avoid collision with the page's existing "encryption key" (JWE request decryption) copy and to match `gen.kek` and the docs.
- "Could not check" must never read as healthy — neutral tone and explicit "unknown" wording.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

### Reviewed Todos (not folded)
- `2026-10-19-keys-reencrypt-via-repo-runner.md` — Mix task change, not admin Keys page work; stays pending.
- `2026-10-13-audit-dcr-default-lifetime-semantics.md` — protocol/DCR area, unrelated; stays pending.
</deferred>
