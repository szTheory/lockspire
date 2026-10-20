# Phase 160: Admin Key Protection & Missing-KEK Copy - Research

**Researched:** 2026-10-19
**Domain:** Phoenix LiveView admin copy and read-only status presentation over an existing domain function (no new deps, no schema, no protocol change)
**Confidence:** HIGH (everything below was read from this repo this session; no external libraries involved)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The Key protection line uses the existing public `Lockspire.Admin.encryption_status/0` (-> `Admin.Keys.encryption_status/0` -> `EncryptionStatus.build/2`), the same readiness truth as `mix lockspire.doctor.key_encryption`, `keys.reencrypt --check`, and `Install.Verify`. No new domain/storage function, no second classifier, nothing extracted from the doctor task.
- **D-02:** A small `@moduledoc false` presenter (e.g. `KeysLive.Protection.summarize/1`) maps the status map or error tuple to exactly one of seven states, with this precedence (first match wins):
  1. could-not-check - `{:error, :repo_not_started}`, `{:error, :storage_unavailable}`, or any rescued raise/exit
  2. invalid-config - `{:error, {:invalid_config, _}}` (message text never rendered)
  3. not-set-up - `configured: false`
  4. unreadable - `unknown_kek != %{}` or `undecryptable > 0`
  5. unencrypted - `legacy > 0`
  6. older-key - any `by_kek_id` key other than `current_kek_id`
  7. encrypted - names `current_kek_id`
- **D-03:** Not-set-up wording must not promise existing keys keep working (sealed rows become unreadable when no keyset is configured). It states that no key-encryption key is set up and new keys cannot be created until one is.
- **D-04:** `stranded_retired` rows do not change the state (matches `ready?` and doctor's non-blocking note). Zero stored keys with a configured KEK reads as the encrypted state ("new keys are encrypted with key-encryption key X"). No extra "no keys yet" state.
- **D-05:** The line renders directly under `page_hero` in `keys_live/index.ex`, outside the `@inventory_state` `case`, so protection-check failure and inventory failure are independent; a failed check never hides the key list.
- **D-06:** Separate assign (e.g. `key_protection`), loaded in `assign_inventory/2` (covers `handle_params` and `retry_inventory`), refreshed after a successful generate. Wrapped so any error or raise becomes could-not-check. No `connected?` guard (matches existing inventory loading and the bare-socket test style).
- **D-07:** Read-only text, reusing the "Status / What we checked" check pattern from `policies_live/security_profile.ex` (or `AdminComponents.decision_summary` with a tone); any new component is a thin wrapper. Meaning carried by text, not colour alone. Could-not-check uses a neutral tone, never success. Optional `<code>mix ...</code>` pointer (gen.kek / doctor) is text, not a control.
- **D-08:** Disclosure limits: show only the current KEK ID (operator-chosen label). Never show configured KEK ID list, per-KEK counts, `unknown_kek` IDs, env var names, `{:invalid_config, msg}` text, or key material. No counts at all; point to `mix lockspire.doctor.key_encryption` for detail.
- **D-09:** Add a `{:error, :key_encryption_not_configured}` clause to `generate_key/3` in `keys_live/index.ex` before the catch-all `{:error, _reason}`, writing to the existing `generation_error` assign (rendered in `<ul class="lockspire-admin-errors" role="alert">`), not flash. Copy says: no key-encryption key is set up; Lockspire will not store private keys unencrypted; set one up with `mix lockspire.gen.kek` and restart. Catch-all copy ("The signing/encryption key could not be generated.") unchanged. Generate buttons stay enabled.
- **D-10:** The clause applies to both "Generate signing key" (`:sig`) and "Generate encryption key" (`:enc`), since both seal private keys and hit the same error; wording names the key use, with the use-neutral fact "private keys are not stored unencrypted".
- **D-11:** The admin UI calls the KEK a **"key-encryption key"** - never a bare "encryption key", which already means the request-decryption (`use: :enc`) key on this page. "KEK" appears only inside `mix lockspire.gen.kek` / doctor command pointers.
- **D-12:** Add PRODUCT.md vocabulary-map rows in the same change: `key-encryption key` (the key that encrypts stored private keys; `:key_encryption`, gen.kek) and `Key protection` (the read-only status line). Do not retire "KEK" or "encryption key" (contract test is case-insensitive substring per line and would flag `gen.kek` / legitimate JWE copy). Add retired-wording rows only for copy actually replaced - none is planned. `vocabulary_contract_test.exs` must pass.
- **D-13:** Write for the least technical persona that uses the Keys page per PRODUCT.md; describe what Lockspire actually does.

### Claude's Discretion
- Exact sentence wording for each of the seven states and the generation error, within D-03, D-08, D-11 and PRODUCT.md tone.
- Component choice between security-profile check pattern and `decision_summary` (D-07).
- Optional docs-only tightening of `Admin.generate_key` `@spec` to name `:key_encryption_not_configured`.
- Test fixtures: existing keys-live fixtures seed legacy rows (classify as unencrypted); add sealed fixtures via `KeyEncryptionHelpers.seal_private_jwk/2` for the encrypted/older-key states.

### Deferred Ideas (OUT OF SCOPE)
None. Reviewed todos not folded: `2026-10-19-keys-reencrypt-via-repo-runner.md`, `2026-10-13-audit-dcr-default-lifetime-semantics.md`.
Out of scope per phase boundary: new controls (retry, rotate, re-encrypt buttons), per-KEK counts, KMS/Vault providers (KEK-04), changes to `Admin.Keys` domain semantics.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KEY-UI-01 | Read-only "Key protection" line on Keys page: encrypted (names current KEK id), older-key, unencrypted, unreadable, not-set-up, invalid-config, could-not-check; failed check keeps list; no per-KEK counts/material/controls | Status shapes and precedence table (Section "encryption_status/0 contract"), presenter design, placement in `index.ex`, fixtures per state |
| KEY-UI-02 | Generation with no KEK shows: none set up, Lockspire will not store keys unencrypted, how to set one up; other errors unchanged | `generate_key/3` clause placement; test with `put_key_encryption(nil)` |
| KEY-UI-03 | Wording from PRODUCT.md vocabulary map; new terms and retired phrases added same change; contract test passes | Contract-test mechanics, collision list, map rows to add |
| SAFE-02 (constraint) | No protocol/security-default/schema/dep changes; no key material or KEKs on admin pages | Disclosure rules, leak-test assertions |
</phase_requirements>

## Summary

This is a presentation-only phase. All data comes from `Lockspire.Admin.encryption_status/0`, which already exists, is read-only, and emits no telemetry. The work is: (1) a pure presenter that collapses the status result into one of seven states with copy, (2) one new assign plus one render block in `keys_live/index.ex`, (3) one new `generate_key/3` error clause, (4) PRODUCT.md vocabulary-map rows, and (5) tests. No packages are installed; no Package Legitimacy Audit is needed.

The most important correction to CONTEXT.md wording: `Admin.encryption_status/0` returns `{:ok, status_map}` (not a bare map) or `{:error, reason}`. The presenter must unwrap `{:ok, map}`. Second: the call can raise or exit in ways the function's `@spec` does not advertise, so the loader must `rescue` and `catch :exit` (D-06 already requires this).

**Primary recommendation:** Add `Lockspire.Web.Live.Admin.KeysLive.Protection` (`@moduledoc false`, pure `summarize/1` returning `%{state, tone, value, detail, kek_id}`), a private `load_key_protection/0` in `index.ex` that wraps `Admin.encryption_status/0` in `try/rescue/catch`, and render it with the existing `AdminComponents.decision_summary` (single item, tone-mapped) directly under `page_hero`. Keep copy in the presenter so it is unit-testable without rendering.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Classify protection state | API / Backend (`Admin.Keys.EncryptionStatus`, already exists) | - | Single classifier reused by doctor/verify; do not duplicate (D-01) |
| Map status to 7 states + copy | Frontend Server (LiveView presenter module) | - | Presentation-only, pure function |
| Fail-closed collapse of errors/raises | Frontend Server (`index.ex` loader) | - | Must isolate from inventory (D-05/D-06) |
| Missing-KEK generation refusal | API / Backend (`Admin.Keys.generate_key/1`, exists) | Frontend Server (error copy clause) | Domain already returns the atom; LiveView maps to copy by atom, not string match |
| Vocabulary governance | Docs (PRODUCT.md) + test | - | Contract test reads PRODUCT.md |

## Standard Stack

No new libraries. Existing, in-repo only:

| Item | Source | Purpose |
|------|--------|---------|
| Phoenix LiveView 1.1.28 | AGENTS.md technology stack | Existing `KeysLive.Index` |
| `AdminComponents.decision_summary/1` | `lib/lockspire/web/components/admin_components.ex:209-233` | Labeled value + detail + tone border |
| `AdminComponents.page_hero/1`, `section_card/1`, `alert/1` | same file | Layout (alert/section_card are alternatives) |
| `Lockspire.KeyEncryptionHelpers` | `test/support/key_encryption_helpers.ex` | Test fixtures |

**Package Legitimacy Audit:** Not applicable. No external packages are added; SAFE-02 forbids dependency changes. Packages removed (SLOP): none. Packages flagged (SUS): none.

## encryption_status/0 contract (verified this session)

`Admin.Keys.encryption_status/0` [VERIFIED: lib/lockspire/admin/keys.ex:261-267]:

```elixir
def encryption_status do
  with {:ok, keyset} <- status_keyset(),
       :ok <- ensure_repo_started(),
       {:ok, rows} <- status_rows() do
    {:ok, EncryptionStatus.build(keyset, rows)}
  end
end
```

Spec [VERIFIED: lib/lockspire/admin.ex:258-260 delegate spec]: `{:ok, Lockspire.Admin.Keys.encryption_status()} | {:error, :repo_not_started | :storage_unavailable | {:invalid_config, String.t()}}`.

### Every reachable return shape

| Shape | Producer | Notes |
|-------|----------|-------|
| `{:ok, status}` | `EncryptionStatus.build/2` | Map keys verbatim from `build/2` initial map: `configured`, `current_kek_id`, `configured_kek_ids`, `legacy_plaintext`, `total`, `no_private_key`, `legacy`, `by_kek_id`, `unknown_kek`, `undecryptable`, `stranded_retired`, `pending`, then `ready?` added in `finalize/1` |
| `{:error, {:invalid_config, msg}}` | `status_keyset/0` rescues `ArgumentError` only (keys.ex:298-302) | `msg` is `Exception.message/1`; may name env var names - never render (D-08) |
| `{:error, :repo_not_started}` | `ensure_repo_started/0` (keys.ex:320-322) | `Process.whereis(Config.repo!())` is nil |
| `{:error, :storage_unavailable}` | `status_rows/0` (keys.ex:304-309) | `Repository.list_signing_keys/1` rescues all exceptions into `{:error, error}` (signing_key_store.ex:48-50) - this is what `DROP TABLE` triggers |
| **Raise (not in spec)** | `Config.repo!()` -> `Policy.fetch_required_config!` raises if `:repo` unset; `status_keyset` only rescues `ArgumentError`, so any other exception from `Config.key_encryption!/0` (e.g. `WithClauseError` from an unmatched `with` else in config.ex:262-269) escapes | The loader must `rescue` any exception -> could-not-check |
| **Exit (not in spec)** | DB connection / checkout exits from `Support.all` can escape as exits, not exceptions (rescue does not catch exits) | Loader must also `catch :exit, _` |

[VERIFIED: lib/lockspire/config.ex:257-271 `key_encryption!/0`; lib/lockspire/security/key_encryption/key_set.ex `new/1` returns `{:error, {atom, atom}}` and falls back to `{:error, {:key_encryption, :invalid_shape}}`.]

Consequence for state 1 vs 2: an unusual non-`ArgumentError` raise from config resolution reads as could-not-check, not invalid-config. That is the safe direction (never reads healthy). Treat as LOW-risk, document in a comment.

### Field semantics and precedence edge cases (D-02)

Classification rules read from `EncryptionStatus.classify/4` [VERIFIED: lib/lockspire/admin/keys/encryption_status.ex]:

- `configured` is `keyset != nil`. With **no keyset**: every envelope row is `unknown_kek` (via `assess_envelope(_key, nil, kek_id)` -> `{:unsealable, :unknown_kek, kek_id}`), legacy rows count as `legacy`, and the "stranded" branch is deliberately skipped (`%KeySet{}` match required). So not-set-up sits correctly at precedence 3, **above** unreadable (4): a not-configured host with sealed rows has `unknown_kek != %{}` AND `configured: false`, and must read not-set-up. Verified by existing test "without a key set every envelope counts as unknown and nothing is ready" (keys_encryption_status_test.exs).
- `legacy` counts both readable legacy rows (`:sealable_legacy`) and `:unreadable_legacy`/`:kid_mismatch` legacy rows (classify_unsealable with `kek_id == nil`). A retired legacy row is counted `legacy` too when it is *sealable*; only retired rows the engine cannot seal become `stranded_retired` (when a keyset exists). So unencrypted (5) includes retired sealable legacy rows. That matches `ready?`.
- `undecryptable` covers wrong-material-same-id, tampered envelope, and `kid` swap (`seal_kid:`), plus malformed envelopes.
- `no_private_key` rows are ignored by every state. A table with only nil-material rows and a configured KEK reads as encrypted (consistent with D-04).
- `stranded_retired` never changes state (D-04). Not read by the presenter at all.
- `by_kek_id` only counts rows that read successfully (`{:envelope, id}` from `Reencrypt.assess`). A non-current id key here means "readable under an older configured KEK" -> older-key (6). Rows under an id the keyset does not know go to `unknown_kek`, never `by_kek_id`, under a configured keyset.
- `legacy_plaintext: :reject` with `legacy > 0` is "broken now" per `broken_now?/1`, but D-02 still maps it to unencrypted (5). Do not add an eighth state; optionally keep the copy neutral so it is true in both modes (see copy below).
- Precedence conflict example: configured, legacy row + older-KEK row + unknown_kek row -> unreadable wins (4). Test the precedence order with one multi-condition fixture.
- `current_kek_id` is `nil` only when `configured: false`, so encrypted/older-key states can safely interpolate it. `current_kek_id` charset is constrained by `@id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/` [VERIFIED: key_set.ex:26], so it is a short label; HEEx escapes it regardless.

### Presenter sketch (pure; no raising)

```elixir
defmodule Lockspire.Web.Live.Admin.KeysLive.Protection do
  @moduledoc false

  @type state ::
          :could_not_check | :invalid_config | :not_set_up | :unreadable
          | :unencrypted | :older_key | :encrypted

  @spec summarize(term()) :: %{state: state(), tone: atom(), value: String.t(), detail: String.t()}
  def summarize({:ok, %{configured: false}}), do: build(:not_set_up)
  def summarize({:ok, %{} = s}), do: s |> classify() |> build_for(s)
  def summarize({:error, {:invalid_config, _message}}), do: build(:invalid_config)
  def summarize(_error_or_unexpected), do: build(:could_not_check)   # catch-all = never healthy
  # classify/1 applies precedence 4 -> 5 -> 6 -> 7 using unknown_kek, undecryptable, legacy, by_kek_id
end
```

The catch-all clause (any unexpected term, including `{:error, :repo_not_started}`, `{:error, :storage_unavailable}`, `:error` from a rescue) guarantees "could not check" is the default and never reads healthy. Do not pattern-match `{:error, :storage_unavailable}` explicitly into a different state; leaving it to the catch-all keeps future error atoms safe.

## Architecture Patterns

### Data flow

```
handle_params / "retry_inventory"          successful "generate"
        |                                           |
        v                                           v
assign_inventory(socket, :loading) --------> load_key_protection()   (refresh only; inventory refreshed separately)
        |                                           |
        +--> load_keys() -> inventory assigns       v
        |                                  try Admin.encryption_status()
        |                                   rescue _ / catch :exit -> :error
        v                                           |
 @inventory_state (loaded|error)                    v
        |                                  Protection.summarize/1 -> %{state, tone, value, detail}
        v                                           |
 render: page_hero -> [key protection line] -> inventory <section>   (line OUTSIDE the case)
```

### Recommended structure

```
lib/lockspire/web/live/admin/keys_live/
├── index.ex        # +assign key_protection, +load_key_protection/0, +render block, +generate_key clause
└── protection.ex   # NEW @moduledoc false presenter (pure)
test/lockspire/web/live/admin/keys_live/
└── protection_test.exs   # NEW pure presenter test (async: true)
test/lockspire/web/live/admin/keys_live_test.exs   # extended (async: false)
PRODUCT.md                                           # +2 vocabulary rows
```

Note: `vocabulary_contract_test.exs` globs `lib/lockspire/web/live/admin/**/*.{ex,heex}`, so `protection.ex` copy is scanned (desired).

### Index.ex edits (exact integration points, read this session)

1. `mount/3` assigns list (index.ex ~line 14-21): add `key_protection: nil` is NOT recommended; initialise to the could-not-check summary or a `:loading` marker. Recommendation: initialise `key_protection: :loading`, render nothing for `:loading`... but `handle_params` always runs immediately, and the existing bare-socket tests call `mount` then `handle_params`. Simplest and safest: `mount` assigns `key_protection: nil` and the render block uses `:if={@key_protection}`; `assign_inventory/2` always sets it. A `nil` must never render as healthy (it renders nothing).
2. `assign_inventory(socket, :loading)` (index.ex ~line 160-171): after `assign_inventory_result(load_keys())` add `|> assign(key_protection: load_key_protection())`. This covers `handle_params` and `retry_inventory` (both call it). Note this function also resets `generation_error: nil`, so a generation error is cleared on retry - existing behaviour, keep.
3. `generate_key/3` success branch (index.ex, inside `{:ok, %{key: %{id: generated_id}}}`): after the successful read-back path, also `assign(key_protection: load_key_protection())`. Reason: generating a sealed key changes the counts (e.g. empty -> encrypted). Place it so it runs in both the confirmed-present and read-back-failed sub-branches only if cheap; minimum is the confirmed-present sub-branch.
4. New clause **before** the catch-all `{:error, _reason}`:

```elixir
{:error, :key_encryption_not_configured} ->
  {:noreply,
   assign(socket,
     generation_error: missing_key_encryption_error(key_label),
     generation_notice: nil,
     generated_key_path: nil
   )}
```

   `key_label` is already `"Signing"` / `"Encryption"`; lowercase it as the catch-all does with `String.downcase(key_label)`.
5. Render: directly after `<AdminComponents.page_hero .../>` and **before** `<section class="lockspire-admin-key-inventory">` (or as the first child inside it, but still outside the `case`). Outside the section is cleaner because the section's `aria-label="Key inventory"` describes the inventory, not protection.
6. `load_key_protection/0`:

```elixir
defp load_key_protection do
  Admin.encryption_status()
  |> Protection.summarize()
rescue
  _exception -> Protection.summarize(:error)
catch
  :exit, _reason -> Protection.summarize(:error)
end
```

   Do not log the exception or its message (could contain config text). Do not pass the raw result to the socket (the assign holds only the summarized, copy-only map, so no `configured_kek_ids`/counts ever reach assigns or the template).

### Component choice: recommend `decision_summary` (one item)

Compared (both read this session):

- `security_profile.ex` "Status / What we checked": two `<p><strong>Status:</strong> ...</p>` paragraphs inside a `section_card(title, subtitle)`. Works but needs a card with a heading ("Signing key check") and gives no tone. It is built for a lower-page card, not a status line under the hero. Tone-less -> could-not-check and healthy look identical except for words.
- `AdminComponents.decision_summary/1`: `<dl>` with `dt` label, `dd` value, optional `p` detail, per-item `tone` (`:success | :warning | :danger | :info | default neutral`) that drives a left border colour [VERIFIED: admin_components.ex:218-233 and class fns 1030-1038]. Text carries meaning; the border is only reinforcement (D-07).

**Recommendation: `decision_summary` with a single item** (`label="Key protection"`, `value` = short state headline, `detail` = one or two sentences with the optional `<code>` pointer via the item's inner block). Tone mapping: encrypted `:success`; older-key `:info`; unencrypted `:warning`; unreadable `:danger`; not-set-up `:warning`; invalid-config `:warning`; could-not-check **neutral (omit tone)**. It is the first LiveView use of this component (previously used only in the component module and the admin lab stress surface/design-system stress test), so run `design_system_component_stress_test.exs` to confirm no component regression. If a thin wrapper is wanted, keep it private in `index.ex` rather than adding to `AdminComponents` (avoids touching the shared module scanned by the vocabulary test).

Caveats: `dd` uses the display heading font and `dt` is uppercase via CSS; keep `value` to a short headline (the KEK id can be 32 chars, `overflow-wrap: anywhere` already set). Do not put the KEK id in `dt`.

Because it is static text with no `phx-click`, it satisfies "no new controls". Put `role="status"` off the line (it is not a live announcement); an `aria-label`ed wrapper `<section aria-label="Key protection">` is enough.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protection classification | A second classifier or a re-scan of rows in LiveView | `Admin.encryption_status/0` | Same truth as doctor/Install.Verify; `Reencrypt.assess/2` handles tamper/kid-swap/same-id-wrong-material |
| Status card layout | New component/CSS | `AdminComponents.decision_summary` | Tone + escape + long-value handling exist |
| KEK id handling | Reading config in the LiveView | `status.current_kek_id` | Config resolution is fresh and fail-closed in the domain function |
| Error mapping | String matching on messages | Pattern match on `:key_encryption_not_configured` | Domain returns a stable atom (keys.ex:85-88) |
| Telemetry/audit | Anything | none | `encryption_status/0` is deliberately side-effect free; do not wrap with telemetry |

## Common Pitfalls

### Pitfall 1: `{:ok, map}` vs bare map
**What goes wrong:** Matching `%{configured: false}` directly against the call result fails; every state falls to the catch-all and everything reads "could not check".
**How to avoid:** `summarize({:ok, %{...}})`. Unit test each state through the `{:ok, _}` tuple.

### Pitfall 2: Not-set-up misread as unreadable
**What goes wrong:** With no keyset, sealed rows land in `unknown_kek`, so checking `unknown_kek` first reports "unreadable".
**How to avoid:** Keep `configured: false` ahead of unreadable (already D-02). Test with a sealed row and `put_key_encryption(nil)`.

### Pitfall 3: Boot cache vs fresh resolution in tests
**What goes wrong:** `encryption_status/0` calls `Config.key_encryption!/0` (fresh from app env); `generate_key/1` calls `Config.key_encryption_keyset/0` (persistent_term cache). Deleting the env alone leaves generation succeeding [VERIFIED: key_encryption_helpers.ex header comment].
**How to avoid:** Use `KeyEncryptionHelpers.put_key_encryption(nil)` for not-set-up and missing-KEK-generation tests. For **invalid-config**, set the env directly (`Application.put_env(:lockspire, :key_encryption, keys: [{"bad", "not-base64"}], current: "bad")`) with an `on_exit` restoring the original (`Application.fetch_env` first) - do NOT use `put_key_encryption/1` because it calls `Lockspire.Application.validate_key_encryption!/0`, which raises on invalid config. The persistent_term cache stays valid, so the rest of the page (generation) keeps working, which is exactly what the "failed check leaves list visible" test wants.

### Pitfall 4: Over-disclosure through assigns/templates
**What goes wrong:** Passing the whole status map into assigns invites later template use of `configured_kek_ids`, `by_kek_id`, `unknown_kek`, `pending` kids.
**How to avoid:** Store only the summarized struct. Add a test that renders each state with sentinel KEK ids and asserts they are absent.

### Pitfall 5: Vocabulary contract false positives
Substring, case-insensitive, per line (see next section). Check every new line of copy, including `<code>` text, HEEx attributes and comments in the scanned files.

### Pitfall 6: Existing tests that forbid words
`keys_live_test.exs` asserts `refute html =~ "posture"` and `refute html =~ "Total keys"`; `refute_forbidden_key_copy` bans (case-insensitively) `private jwk`, `private_jwk`, `export key`, `fetch remote key`, `force publish`, `plaintext key`; `HtmlAssertions.assert_no_generic_cta_text` bans `Click here`, `Learn more`, `Read more`, `Submit`; `assert_no_token_like_text` bans JWT-looking strings and `-----BEGIN ... PRIVATE KEY-----`. The phrase "stored unencrypted" / "unencrypted" is safe; do not write "plaintext key".

### Pitfall 7: Generate buttons keep working
D-09 says buttons stay enabled; they are only disabled when `@inventory_state != :loaded`. Do not add a `disabled` for not-set-up.

### Pitfall 8: Stale application log copy
`Lockspire.Application.validate_key_encryption!/0` logs "Existing signing keys keep working, but new signing keys cannot be generated..." [VERIFIED: lib/lockspire/application.ex:37-40]. D-03 says the admin copy must not promise that. This log is out of scope (no behaviour change, SAFE-02) but the planner should not copy that sentence into admin text. Optional follow-up only.

### Pitfall 9: `retry_inventory` clears `generation_error`
`assign_inventory(:loading)` resets `generation_error`. So after a missing-KEK error, pressing retry (only shown on inventory error) clears it. Existing behaviour; no change needed.

## PRODUCT.md and the vocabulary contract

### Personas for the Keys page [VERIFIED: PRODUCT.md "Personas and jobs"]
- **Provider operator** (primary): "Pages: Overview, Apps, App registration, Security, Keys." Knows Phoenix, HTTP, OAuth basics; "May not know RFC names, FAPI, DPoP, PAR, or JARM by sight."
- **Security reviewer**: "Pages: Overview, Tokens, Security, Keys." Knows OAuth/OIDC threats and protocol terms well.
- Rule: "Write for the least technical persona who uses a page." Least technical on Keys = the provider operator (an engineer, but not a crypto specialist). So: plain sentences, concrete next step, command pointers as text; protocol detail (envelope, AES-GCM, `legacy_plaintext` option name) stays out.

### Vocabulary map and retired table format [VERIFIED: PRODUCT.md "Vocabulary map", "Retired wording"]
Map rows: `| Internal or protocol term | UI says | Protocol term shown? |` (markdown table, header "Last reviewed: 2026-10-14" above it - update this date in the same change). Retired rows: `| Retired phrase | Use instead |`.

Rows to add (D-12), placed in the vocabulary map (e.g. after the `rotate` row, keeping the table contiguous):

| Internal or protocol term | UI says | Protocol term shown? |
| --- | --- | --- |
| key-encryption key (KEK, `:key_encryption`) | key-encryption key: the key that encrypts the private keys Lockspire stores | Command names only: `mix lockspire.gen.kek` |
| signing-key encryption status (`encryption_status`) | Key protection | No |

(Match the existing column style: terse cells. The second column for the second row is the label shown on the page; the explanation belongs in the first/third columns. Executor may tighten.)

No retired rows are planned (nothing replaced). If the executor ends up replacing any existing phrase, add it to the retired table.

### How `vocabulary_contract_test.exs` works [VERIFIED: test file read in full]
- Reads `PRODUCT.md` from `File.cwd!()`; takes text after `### Retired wording`, up to the next `\n### `; parses lines matching `^\| ([^|]+?) \| ([^|]+?) \|$` (exactly two cells; header and `---` rows skipped); lowercases phrases.
- Asserts `length(retired) >= 10`.
- Scans files globbed from `lib/lockspire/web/live/admin/**/*.{ex,heex}`, `lib/lockspire/web/live/admin_layout_live.ex`, `lib/lockspire/web/components/admin_components.ex`. For each line, `String.contains?(String.downcase(line), phrase)`. Any match fails with `path:line`.
- It does NOT check that new terms exist in the map (so adding the rows is a manual obligation - include a plan step/verification grep).
- **What would break:** any new line containing a retired phrase. Retired phrases that new copy could plausibly hit: "legacy default" (do not write "legacy default"), "escape hatch", "compatibility-first", "destructive actions", "assertion-key", "login or consent", "logout delivery(ies)", "public client", "confidential client", "initial access token", "registration token", "callback url", "client inventory", "client created", "client not found" and friends (all "Client ..." app phrases). Words "legacy", "client", "key" alone are NOT retired. Two-cell-only parsing means a 3-cell row in the retired table is silently ignored, so keep it to two cells. Adding a map row (3-cell table) does not affect the parser because it only reads after `### Retired wording`.
- Safe to include: "key-encryption key" (not retired), `mix lockspire.gen.kek` (D-12: do not retire "KEK"), `mix lockspire.doctor.key_encryption`, "encryption key" for the JWE request key.

## Proposed copy (discretion; all in presenter, ASCII-safe except existing ellipsis style)

Least-technical, calm, describes what Lockspire does. KEK id shown only for encrypted and older-key (current id only). "Check" pointer text is `mix lockspire.doctor.key_encryption`. The planner may adjust wording; constraints it must keep: D-03, D-08, D-11, "unknown" for could-not-check, no counts.

| State | Tone | value (headline) | detail |
|-------|------|------------------|--------|
| encrypted | success | `Encrypted` | `Lockspire stores private keys encrypted with key-encryption key "{current}". New keys use the same key-encryption key.` |
| older-key | info | `Encrypted, some with an older key-encryption key` | `Lockspire can still read them. New keys use "{current}". Ask whoever runs the app to run mix lockspire.keys.reencrypt to move older keys to it.` |
| unencrypted | warning | `Some keys are stored unencrypted` | `Run mix lockspire.doctor.key_encryption for details, then mix lockspire.keys.reencrypt to encrypt them.` (Do not state whether Lockspire still signs with them: under `legacy_plaintext: :reject` it may not.) |
| unreadable | danger | `Some keys cannot be read` | `Lockspire cannot read some stored keys with the key-encryption keys it has. Do not delete them. Run mix lockspire.doctor.key_encryption for details.` (no ids, no counts) |
| not-set-up | warning | `Not set up` | `No key-encryption key is set up, so Lockspire cannot create new keys. Set one up with mix lockspire.gen.kek, then restart the app.` |
| invalid-config | warning | `Setup needs attention` | `The key-encryption key setup is not valid. Run mix lockspire.doctor.key_encryption for details.` |
| could-not-check | neutral | `Unknown` | `Lockspire could not check key protection right now. This does not mean your keys are protected or unprotected. Reload the page to try again.` |

Facts that must remain true for each claim (verify against code before finalising): `mix lockspire.keys.reencrypt` exists [CITED: doctor task text, lib/mix/tasks/lockspire.doctor.key_encryption.ex:53,122 "run mix lockspire.keys.reencrypt"]; `mix lockspire.gen.kek` exists [CITED: config.ex fail messages]. Older-key "can still read them" holds because `by_kek_id` only counts rows that opened successfully under the keyset. Heading-level `value` for encrypted should not claim "all keys" if any `no_private_key` rows exist; "Lockspire stores private keys encrypted" is a statement about the stored ones, acceptable.

Missing-KEK generation error (D-09/D-10), `{use}` = "signing" or "encryption":

`No key-encryption key is set up, so Lockspire cannot create a {use} key. Lockspire will not store private keys unencrypted. Set one up with mix lockspire.gen.kek, add it to your app's configuration, and restart the app.`

Keep the catch-all `"The #{String.downcase(key_label)} key could not be generated."` byte-identical.

## Code Examples

### Render block (outside the inventory `case`)

```elixir
<AdminComponents.page_hero body="Manage keys used to sign tokens or decrypt encrypted authorization requests." />
<section :if={@key_protection} class="lockspire-admin-key-protection" aria-label="Key protection">
  <AdminComponents.decision_summary>
    <:item label="Key protection" value={@key_protection.value} tone={@key_protection.tone}>
      {@key_protection.detail}
    </:item>
  </AdminComponents.decision_summary>
</section>
<section class="lockspire-admin-key-inventory" aria-label="Key inventory">
```

(`tone` omitted for neutral: build the item with `Map.get(item, :tone, :neutral)` semantics already in the component, so presenter returns `:neutral` for could-not-check. Detail can be passed via `detail` attr instead of inner block if the `<code>` pointer is dropped. If using `<code>mix ...</code>`, split the pointer into a separate presenter field `command` and render `<code>{@key_protection.command}</code>` in the slot.)

Source: component contract read from `lib/lockspire/web/components/admin_components.ex:209-233` [VERIFIED]. No new CSS needed; if spacing under the hero is wrong, the decision-summary class already has `margin: 0 0 var(--ls-space-5)`.

### State fixtures (tests)

```elixir
alias Lockspire.KeyEncryptionHelpers, as: Helpers

# encrypted (current): wipe the 4 legacy setup rows first
Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_signing_keys", [])
{:ok, _} = Repository.publish_key(Helpers.sealed_row("sealed-current", "test-1"))

# older-key: add Helpers.sealed_row("sealed-older", "test-2")  # test-2 is configured
# unencrypted: default setup fixtures (legacy rows) or Helpers.legacy_json_row("legacy-1")
# unreadable (unknown KEK):  Helpers.sealed_row("gone", "gone-1")
# unreadable (undecryptable): Helpers.sealed_row("wrong", "test-1", salt: "different")
# not-set-up: Helpers.put_key_encryption(nil)  # clears env + persistent_term
# invalid-config: Application.put_env(:lockspire, :key_encryption, keys: [{"bad", "not-base64"}], current: "bad") + on_exit restore
# could-not-check: DROP TABLE lockspire_signing_keys  (-> storage_unavailable)
```

Note on the existing fixtures: `setup` in keys_live_test.exs publishes four rows with `private_jwk_encrypted: :erlang.term_to_binary(%{"kid" => kid, "d" => "private"})`, which `assess_legacy` classifies as sealable legacy, so the default page state is **unencrypted**. Existing tests asserting HTML content are unaffected unless they also assert on absence of new words; re-run the whole file.

`Helpers.sealed_row/3` seals with `config/test.exs` material under any given id (formula `lockspire-test-kek-<suffix>`), and `test-1` / `test-2` match the configured keyset [VERIFIED: key_encryption_helpers.ex `sealed_row/3`, `config_material/2`; config/test.exs:36-43]. `Helpers.seal_private_jwk/2` (named in CONTEXT) seals with the cached keyset only and yields a current-id envelope; `sealed_row/3` is the better fixture because it can target any id and returns a ready `%SigningKey{}`.

## Test strategy

Style constraints [VERIFIED: keys_live_test.exs]: `use ExUnit.Case, async: false`; `setup_all` starts `Lockspire.TestRepo` with sandbox manual mode; per-test `Sandbox.checkout`; drive `Index.mount/3`, `Index.handle_params/3`, `Index.handle_event/3` on `socket_for(:index)` (a bare `%Phoenix.LiveView.Socket{assigns: %{live_action: :index, __changed__: %{}}}`); render with `rendered_to_string(Index.render(socket.assigns))`; `HtmlAssertions` helpers for page contract/no duplicate ids/no token-like text; failures simulated with `DROP TABLE`. `DROP TABLE` inside a sandbox transaction works in this suite (existing tests do it).

### Suggested tests

1. **Presenter unit test** (`protection_test.exs`, `async: true`, pure): table-driven over hand-built status maps and error tuples; asserts state, that `{:error, :repo_not_started}`, `{:error, :storage_unavailable}`, `:error`, and an arbitrary term all give could-not-check with neutral tone; invalid-config message never in output (use a sentinel message string); precedence: multi-condition map (unknown_kek + legacy + older id) -> unreadable; `configured: false` with non-empty `unknown_kek` -> not-set-up; `stranded_retired.count > 0` alone -> encrypted; `total: 0, configured: true` -> encrypted; `legacy_plaintext: :reject` with `legacy > 0` -> unencrypted; `current_kek_id` appears only in encrypted/older-key output.
2. **LiveView state matrix** in `keys_live_test.exs`: for each of 7 states, mount + handle_params + render; assert distinct primary phrase; assert `Key protection` present; assert the key list is still rendered (titles present) where the inventory read succeeded.
3. **Failure isolation:** (a) set `socket.assigns.key_protection` to the could-not-check summary on a loaded socket and assert both the line and 4 inventory titles render (bare-socket style; avoids needing to break only one read); (b) invalid-config env with inventory loaded: line says setup needs attention and list renders; (c) `DROP TABLE`: line says Unknown/could not check, inventory shows "Could not load signing keys"; assert neither renders "Encrypted" nor a healthy success wording.
4. **Never healthy:** in the could-not-check render, `refute html =~ "Encrypted"` and the success-tone class `lockspire-admin-decision-summary__item-success` is absent.
5. **No controls / disclosure:** parse the protection `<section>` (LazyHTML `section[aria-label="Key protection"]`) and assert no `button`, `a`, `form`, `input`, no `phx-click`; assert the text contains no digits (no counts) and does not contain `test-2` when current is `test-1` with an older-key row (older id never shown), nor `gone-1` for unknown-KEK, nor sentinel env var name / invalid-config message. Use `HtmlAssertions.assert_no_text/2` with those samples. Also `HtmlAssertions.assert_no_interactive_controls/2` against the extracted fragment.
6. **Generation error:** `put_key_encryption(nil)`, mount + handle_params, `handle_event("generate", %{"use" => "sig"})` and `"enc"`: `generation_error =~ "No key-encryption key is set up"`, `=~ "will not store private keys unencrypted"`, `=~ "mix lockspire.gen.kek"`, names signing/encryption respectively, `generation_notice` nil, inventory assigns unchanged (`total_keys == 4`), rendered inside `ul.lockspire-admin-errors[role=alert]`, and buttons not `disabled`. Regression: existing test at line 205 still gets "could not be generated" via DROP TABLE (catch-all unchanged).
7. **Refresh after generate:** with the sealed-current-only fixture, generate `sig` succeeds and `key_protection.state` remains `:encrypted`; with legacy-only fixture it remains `:unencrypted` (generation adds a sealed row but legacy rows still exist). Demonstrates the assign is refreshed (assert via a change: empty table + configured -> still encrypted; use an `older-key` fixture then verify no change; simplest: assert `key_protection` equals a freshly computed `Protection.summarize(Admin.encryption_status())`).
8. **Leak coverage:** extend `refute_forbidden_key_copy` calls to every state render; add `HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())` to the matrix. Also assert the raw KEK material and its Base64 (`Helpers.config_material("test-1")`) never appear (PITFALLS M1). `test/lockspire/security/key_material_leak_test.exs` covers logs/telemetry/audit for reencrypt/seal paths with sentinel KEKs; it does not render the admin page, so it needs **no change** for this phase (confirm it still passes). Optionally add one sentinel-KEK render assertion in keys_live_test rather than in the leak test, to keep that file's scope (domain/log/telemetry) intact. Phase 161 owns the final SAFE-02 proof.
9. **Vocabulary:** `mix test test/lockspire/web/live/admin/vocabulary_contract_test.exs` early and at the end; plus a grep-style check in verification that PRODUCT.md contains the two new map terms (the contract test does not enforce this).
10. **Design-system regression:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (uses `decision_summary`) must stay green.

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| FEATURES.md draft: "encryption key", "Existing keys keep signing" | D-11 "key-encryption key"; D-03 forbids that promise | Do not copy FEATURES.md draft copy verbatim |
| PITFALLS M2 suggested connected-mount-only scan | D-06 says no `connected?` guard | Table is tiny; LiveView double-mount accepted; matches existing inventory loading |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix lockspire.keys.reencrypt` is the correct command name for moving keys to the current KEK in user-facing copy | Proposed copy | Wrong command in UI. Doctor text at doctor.key_encryption.ex:53,122 references it, so likely correct; executor should `mix help lockspire.keys.reencrypt` |
| A2 | Non-`ArgumentError` raise from `Config.key_encryption!/0` is possible (e.g. `WithClauseError`) | Contract section | Only affects whether rare config corruption shows invalid-config or could-not-check; both safe |
| A3 | DB checkout failures can surface as exits rather than exceptions | Contract section | Harmless: catch clause is extra safety |
| A4 | `decision_summary` renders acceptably as a standalone strip under the hero (visual) | Component choice | Spacing/visual polish only; no functional risk. Check in the admin lab/browser; fallback is `section_card`/`alert` |
| A5 | PRODUCT.md "Last reviewed" date should be bumped when adding rows | Vocabulary | Cosmetic |
| A6 | Exact wording of proposed copy | Proposed copy | Discretion area; tone/claims must be re-checked against facts above |

## Open Questions (RESOLVED)

1. **Is "Reload the page to try again" acceptable without a control?** What we know: SAFE-02/D-07 forbid new controls; `retry_inventory` exists only on inventory error. Recommendation: text-only instruction; no button.
   **RESOLVED (160-01 Task 1):** Yes. The could-not-check detail ends with the text-only sentence "Reload the page to try again." and the Key protection line carries no button, link, form or phx event (D-07, SAFE-02). 160-01 Task 2 `assert_protection_is_text_only/2` enforces it.
2. **Should `Admin.generate_key` `@spec` name `:key_encryption_not_configured`?** Optional docs-only tightening (discretion). `Admin.Keys.generate_key/1` spec already names it (keys.ex:83-84); `admin.ex:208-209` is `{:error, term()}`. If changed, run `mix docs --warnings-as-errors` (PITFALLS M5) on CI Elixir.
   **RESOLVED (160-02 Task 1):** Yes, make the docs-only tightening. The `Admin.generate_key/1` @spec return becomes `{:ok, Lockspire.Admin.Keys.key_view()} | {:error, :key_encryption_not_configured | term()}`, with at most one optional @doc sentence; no other admin.ex change (diff-size gate). `mix ci` in 160-02 Task 2 includes the docs warnings-as-errors check.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP 1.19.5-otp-28 (asdf) | all test commands | Per project memory note (not probed; Bash run limited to read-only inspection this session) | - | Local 1.20.4 has type warnings that fail warnings-as-errors; always set `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` |
| PostgreSQL 14+ | `TestRepo`, sandbox | Not probed | - | Tests need it; same as every other phase |

No new external dependencies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Phoenix LiveViewTest, LazyHTML via `HtmlAssertions`) |
| Config file | `config/test.exs` (KEK ids `test-1` current, `test-2`), `test/test_helper.exs` |
| Quick run command | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/keys_live/protection_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` |
| Full suite command | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5; mix test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| KEY-UI-01 | Seven states map and render with distinct wording; encrypted names current KEK id | unit + LiveView | `mix test test/lockspire/web/live/admin/keys_live/protection_test.exs` and `mix test test/lockspire/web/live/admin/keys_live_test.exs` | Wave 0 (protection_test.exs new; keys_live_test.exs extended) |
| KEY-UI-01 | Could-not-check never healthy; failed check keeps list; no counts/ids/controls | LiveView | `mix test test/lockspire/web/live/admin/keys_live_test.exs` (new describe "key protection") | Wave 0 |
| KEY-UI-02 | Missing-KEK generate error for sig and enc; catch-all unchanged | LiveView | `mix test test/lockspire/web/live/admin/keys_live_test.exs` | Wave 0 (new tests) |
| KEY-UI-03 | No retired wording; new terms in PRODUCT.md | contract | `mix test test/lockspire/web/live/admin/vocabulary_contract_test.exs` plus `rg -n "key-encryption key\|Key protection" PRODUCT.md` | Exists (test); map rows added in phase |
| SAFE-02 | No KEK ids/material/counts/controls on page; no behavior change | LiveView + existing | `mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/security/key_material_leak_test.exs test/lockspire/admin/keys_encryption_status_test.exs` | Exists; assertions added |
| Regression | Shared component and admin proof | existing | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs` | Exists |

### Sampling Rate
- **Per task commit:** the Quick run command above (3 files).
- **Per wave merge:** `mix test test/lockspire/web test/lockspire/admin test/lockspire/security`.
- **Phase gate:** full `mix test` green, plus `mix format --check-formatted` and `mix compile --warnings-as-errors`, on 1.19.5-otp-28, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/lockspire/web/live/admin/keys_live/protection_test.exs` - presenter table tests (KEY-UI-01)
- [ ] New tests and describe block in `test/lockspire/web/live/admin/keys_live_test.exs` for the seven-state matrix, isolation, disclosure, generation error
- [ ] Optional small test-support helper (private, in keys_live_test.exs) to reset rows and publish sealed fixtures
- [ ] No framework install needed

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json` (only `nyquist_validation: true` seen), so ASVS L1 applies.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host-owned operator auth (PRODUCT.md "Operating Context"); no change |
| V3 Session Management | no | No session change |
| V4 Access Control | yes (inherited) | Page sits behind host's operator pipeline via `Lockspire.Web.AdminRouter`; no new route; read-only |
| V5 Input Validation | minimal | No user input added; `generate` event keeps the `use in ["sig","enc"]` guard; KEK id is label-constrained by `KeySet` id pattern and escaped by HEEx |
| V6 Cryptography | yes (non-regression) | No crypto code added; do not hand-roll; show no key material |
| V7 Error handling / logging | yes | Do not log exceptions from the protection loader; never render `{:invalid_config, msg}` |
| V8 Data protection | yes | Disclosure minimization (below) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Admin page discloses a rotation map (which old KEK protects which rows) | Information disclosure | Show only current KEK id; no `configured_kek_ids`, `by_kek_id`, `unknown_kek` ids, counts, or `pending` kids; presenter output carries copy only (PITFALLS M1) |
| Exception/config message echoes env var names or config text | Information disclosure | Invalid-config message never rendered; rescue clause discards the exception without logging |
| A failed check displays as healthy/zero | Spoofing of status / Repudiation of risk | Catch-all -> could-not-check, neutral tone, "does not mean protected or unprotected" |
| Key material in page | Information disclosure | Assigns hold only summary; tests assert no `private_jwk_encrypted`, `BEGIN PRIVATE KEY`, base64 KEK material |
| New mutating control added by mistake (retry/rotate) | Tampering/EoP | Test asserts no button/link/form/phx-* in protection section |
| Unauthenticated access | Spoofing | Unchanged: host pipeline guards admin routes |
| Repeated scans causing load | Denial of service | Table is tiny; status read once per `assign_inventory`; no polling added |

## Sources

### Primary (HIGH confidence, read in repo this session)
- `lib/lockspire/admin/keys/encryption_status.ex` (full), `lib/lockspire/admin/keys.ex` (lines 39-58, 60-90, 246-322), `lib/lockspire/admin.ex` (205-262), `lib/lockspire/config.ex` (257-345), `lib/lockspire/application.ex` (full), `lib/lockspire/admin/keys/reencrypt.ex` (`assess/2`), `lib/lockspire/storage/ecto/repository/signing_key_store.ex` (`list_signing_keys`)
- `lib/lockspire/web/live/admin/keys_live/index.ex` (full), `lib/lockspire/web/live/admin/policies_live/security_profile.ex`, `lib/lockspire/web/components/admin_components.ex` (`page_hero`, `alert`, `decision_summary`), `lib/lockspire/web/admin_css.ex` (decision-summary rules)
- `PRODUCT.md` (full), `test/lockspire/web/live/admin/vocabulary_contract_test.exs` (full), `test/lockspire/web/live/admin/keys_live_test.exs` (setup, tests 67-235, helpers 591-660), `test/support/key_encryption_helpers.ex` (full), `test/lockspire/admin/keys_encryption_status_test.exs` (1-120), `test/lockspire/security/key_material_leak_test.exs` (1-80), `test/support/lockspire/web/admin_proof/html_assertions.ex` (CTA/token-like patterns), `config/test.exs`
- `.planning/REQUIREMENTS.md`, `.planning/research/v1.44-adopter-polish/FEATURES.md` (55-115), `PITFALLS.md` (M1-M5)

### Secondary / Tertiary
- None. No web research was needed; no external libraries.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies; all components verified in repo.
- Architecture: HIGH - integration points read directly from `index.ex`.
- Pitfalls: HIGH - verified against code and test helpers.
- Copy: MEDIUM - discretion area; command names and claims should be re-verified at execution.

**Research date:** 2026-10-19
**Valid until:** 2026-11-18 (stable; invalidated if `EncryptionStatus` or `keys_live/index.ex` change)
