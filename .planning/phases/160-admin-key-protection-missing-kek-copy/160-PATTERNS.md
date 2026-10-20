# Phase 160: Admin Key Protection & Missing-KEK Copy - Pattern Map

**Mapped:** 2026-10-19
**Files analyzed:** 6 (1 new lib, 1 modified lib, 1 new test, 1 modified test, 1 modified doc, 1 optional spec tweak)
**Analogs found:** 6 / 6 (all git-tracked; verified via `git ls-files`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/keys_live/protection.ex` (new) | presenter/utility | transform (pure) | `lib/lockspire/web/live/admin/policies_live/security_profile.ex` (`strict_readiness_status/2`, `strict_readiness_summary/2`) | role-match |
| `lib/lockspire/web/live/admin/keys_live/index.ex` (mod) | LiveView component | request-response (read assigns + event) | itself; plus `security_profile.ex` `strict_readiness/0` for fail-closed collapse | exact |
| `test/lockspire/web/live/admin/keys_live/protection_test.exs` (new) | test (pure unit) | transform | `test/lockspire/admin/keys_encryption_status_test.exs` (table-style status maps) | role-match |
| `test/lockspire/web/live/admin/keys_live_test.exs` (mod) | test (LiveView, bare socket) | request-response | itself (lines 13-65 setup, 186-233, 607-659 helpers) | exact |
| `PRODUCT.md` (mod) | docs / vocabulary map | n/a | existing map rows (line 139 `rotate` row) | exact |
| `lib/lockspire/admin.ex` `generate_key` `@spec` (optional) | spec | n/a | `Admin.Keys.generate_key/1` spec (keys.ex:80-82) | exact |

## Pattern Assignments

### `lib/lockspire/web/live/admin/keys_live/protection.ex` (presenter, transform)

**Analog:** `lib/lockspire/web/live/admin/policies_live/security_profile.ex` lines 294-322 (status label + "what we checked" summary as multi-clause private functions; unavailable clause says "Its result is unknown." - same "never healthy" idea).

**Pattern to copy** (security_profile.ex 294-306):
```elixir
defp strict_readiness_status(_profile, %{status: :unavailable}), do: "Unavailable"
defp strict_readiness_status(:fapi_2_0_message_signing, %{ready?: true}), do: "Ready"
...
defp strict_readiness_summary(_profile, %{status: :unavailable}) do
  "The signing-key check could not be completed. Its result is unknown."
end
```
Apply: multi-clause function heads, unavailable/unknown clause first or as catch-all, copy as plain string literals. Module header: `@moduledoc false` (same as every admin LiveView module). Namespace `Lockspire.Web.Live.Admin.KeysLive.Protection` (sibling of `KeysLive.Index`, so vocabulary contract globbing covers it).

**Shape/precedence** (RESEARCH sketch, verified against `Admin.encryption_status/0` returning `{:ok, map} | {:error, _}`):
```elixir
def summarize({:ok, %{configured: false}}), do: build(:not_set_up)
def summarize({:ok, %{} = s}), do: s |> classify() |> build_for(s)   # 4 unreadable -> 5 unencrypted -> 6 older -> 7 encrypted
def summarize({:error, {:invalid_config, _message}}), do: build(:invalid_config)  # discard message
def summarize(_other), do: build(:could_not_check)                    # catch-all, tone :neutral
```
Returns only `%{state, tone, value, detail, command?}`; never the raw map (D-08). Copy table is in RESEARCH "Proposed copy". Do not write "legacy default", "plaintext key", "private jwk" (retired / forbidden); use "key-encryption key" never bare "encryption key" (D-11).

---

### `lib/lockspire/web/live/admin/keys_live/index.ex` (LiveView, request-response)

**Analog:** itself. Excerpts to extend:

**Mount assigns** (lines 14-24): add `key_protection: nil` to the `assign(socket, ...)` list; render guard `:if={@key_protection}` so nil renders nothing, never healthy.

**Loader wired into existing path** (lines 166-178): add `|> assign(key_protection: load_key_protection())` after `assign_inventory_result(load_keys())` in `assign_inventory(socket, :loading)` (covers `handle_params` and `retry_inventory`).

**Fail-closed loader** (new private fn; analog collapse style is security_profile.ex 270-282 `strict_readiness/0`, which maps `{:error, _}` to an "unavailable" value instead of raising). Add `alias Lockspire.Web.Live.Admin.KeysLive.Protection`:
```elixir
defp load_key_protection do
  Admin.encryption_status() |> Protection.summarize()
rescue
  _exception -> Protection.summarize(:error)
catch
  :exit, _reason -> Protection.summarize(:error)
end
```
Do not log the exception.

**Render placement** (lines 53-55): insert between `<AdminComponents.page_hero .../>` and `<section class="lockspire-admin-key-inventory" ...>`, outside the `case @inventory_state` (line 98). Component: `AdminComponents.decision_summary` (admin_components.ex 209-233), per-item `tone` defaults to `:neutral` via `Map.get(item, :tone, :neutral)`:
```heex
<section :if={@key_protection} class="lockspire-admin-key-protection" aria-label="Key protection">
  <AdminComponents.decision_summary>
    <:item label="Key protection" value={@key_protection.value} tone={@key_protection.tone} detail={@key_protection.detail} />
  </AdminComponents.decision_summary>
</section>
```
Slot attrs: `label`, `value` required; `detail`, `tone` optional (`:success | :warning | :danger | :info`; use `:neutral` for could-not-check). Alternative card pattern: security_profile.ex 116-125 (`section_card` + `<p><strong>Status:</strong>` / `<strong>What we checked:</strong>`).

**New generate_key clause** (insert before catch-all at lines 236-242; `key_label` is `"Signing"`/`"Encryption"` from line 199):
```elixir
{:error, :key_encryption_not_configured} ->
  {:noreply,
   assign(socket,
     generation_error: missing_key_encryption_error(key_label),
     generation_notice: nil,
     generated_key_path: nil
   )}

{:error, _reason} ->   # unchanged, byte-identical
  {:noreply,
   assign(socket,
     generation_error: "The #{String.downcase(key_label)} key could not be generated.",
     ...
```
Error renders through existing line 94: `<ul :if={@generation_error} class="lockspire-admin-errors" role="alert"><li>{@generation_error}</li></ul>`. Buttons keep `disabled={@inventory_state != :loaded}` only (lines 76, 85); do not disable on not-set-up.

**Refresh after generate:** in the success branch at lines 205-213, add `|> assign(key_protection: load_key_protection())` to `socket` (after `assign_inventory_result(socket, {:ok, keys})`).

---

### `test/lockspire/web/live/admin/keys_live/protection_test.exs` (new, pure unit)

**Analog:** `test/lockspire/admin/keys_encryption_status_test.exs` (hand-built status shapes); `use ExUnit.Case, async: true` (no DB). Table-driven over `{:ok, %{...}}` maps and error tuples; assert `state`, `tone`, absence of sentinel `{:invalid_config, "SENTINEL_ENV_VAR"}` text, precedence (configured false + non-empty unknown_kek -> not_set_up; unknown + legacy + older -> unreadable; `stranded_retired` alone -> encrypted; total 0 configured -> encrypted).

---

### `test/lockspire/web/live/admin/keys_live_test.exs` (mod, LiveView bare-socket)

**Analog:** itself.

**Harness** (lines 1-24, 607-609): `use ExUnit.Case, async: false`; `setup_all` puts `:repo`, `:mount_path` and starts `Lockspire.TestRepo` with sandbox manual; `setup` checks out sandbox and publishes four rows (`private_jwk_encrypted: :erlang.term_to_binary(%{"kid" => kid, "d" => "private"})`, which classify as legacy -> default page state is unencrypted).
```elixir
defp socket_for(action) do
  %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
end
```

**Drive pattern** (lines 186-201):
```elixir
assert {:ok, s} = Index.mount(%{}, %{}, socket_for(:index))
Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])
assert {:noreply, s} = Index.handle_params(%{}, "/lockspire/admin/keys", s)
html = rendered_to_string(Index.render(s.assigns))
```
Use DROP TABLE for could-not-check (storage_unavailable); assert both "Could not load signing keys" and the Unknown line, and no "Encrypted" / `lockspire-admin-decision-summary__item-success`.

**Generate-event pattern** (lines 205-233): `Index.handle_event("generate", %{"use" => "sig"}, socket)`; for missing-KEK use `Lockspire.KeyEncryptionHelpers.put_key_encryption(nil)` (clears env AND persistent_term cache; env deletion alone leaves generation succeeding), then assert `generation_error =~ "No key-encryption key is set up"`, `=~ "will not store private keys unencrypted"`, `=~ "mix lockspire.gen.kek"`, for both `"sig"` and `"enc"`. Keep the existing catch-all assertion at line 230.

**Fixtures** (test/support/key_encryption_helpers.ex): `sealed_row(kid, kek_id, opts)` (line 134; ids `test-1` current, `test-2` configured), `legacy_json_row/2` (106), `nil_material_row/2` (144), `put_key_encryption/1` (22-38, restores on exit; raises on invalid config because it calls `validate_key_encryption!`). Invalid-config state: `Application.put_env(:lockspire, :key_encryption, keys: [{"bad", "not-base64"}], current: "bad")` with manual `on_exit` restore via `Application.fetch_env`. Seed encrypted state by `DELETE FROM lockspire_signing_keys` then `Repository.publish_key(Helpers.sealed_row("sealed-current", "test-1"))`; older-key adds `sealed_row("sealed-older", "test-2")`; unreadable: `sealed_row("gone", "gone-1")` or `sealed_row("wrong", "test-1", salt: "different")`.

**Assertion helpers** (lines 626-651): reuse `refute_forbidden_key_copy(html)` and `forbidden_key_material_samples()` with `HtmlAssertions.assert_no_text/2` on every state render; extra: protection section has no `button/a/form/input/phx-click`, no digits (no counts), no `test-2`/`gone-1` ids, no KEK material. Do not write "plaintext key" or the words "posture"/"Total keys" (existing refutes).

---

### `PRODUCT.md` (vocabulary map)

**Analog:** table rows at lines 130-139, format `| Internal or protocol term | UI says | Protocol term shown? |`. Insert two rows contiguous in the map (e.g. after the `rotate` row at line 139):
```
| key-encryption key (KEK, `:key_encryption`) | key-encryption key: the key that encrypts the private keys Lockspire stores | Command names only: `mix lockspire.gen.kek` |
| signing-key encryption status (`encryption_status`) | Key protection | No |
```
Bump "Last reviewed" (line 107). Do NOT add retired-table rows (none replaced; retired parser reads only two-cell rows after `### Retired wording`). Contract test `test/lockspire/web/live/admin/vocabulary_contract_test.exs` scans `lib/lockspire/web/live/admin/**/*.{ex,heex}` per line, case-insensitive, so scan new copy for retired phrases (notably "legacy default", "escape hatch", "client ..." phrases).

## Shared Patterns

### Fail-closed status loading (never healthy on failure)
**Source:** `security_profile.ex` 270-282 and 304-306 ("Its result is unknown.").
**Apply to:** `load_key_protection/0`, `Protection.summarize/1` catch-all, could-not-check copy with neutral tone.

### Failure isolation of independent reads
**Source:** `index.ex` `assign_inventory_result/2` (180-196) keeps `inventory_state` independent. Protection gets its own assign and is rendered outside the `case @inventory_state`.

### Errors via assigns, not flash
**Source:** `index.ex` lines 94, 236-242 (`generation_error` in `ul.lockspire-admin-errors[role=alert]`).
**Apply to:** missing-KEK generation error.

### Disclosure minimization
**Apply to:** presenter + template. Only `current_kek_id` may appear (encrypted/older-key states). Assign holds only summarized copy fields; never `configured_kek_ids`, `by_kek_id`, `unknown_kek`, counts, env var names, or `{:invalid_config, msg}`.

### Tracked-source check
All analog paths above are in `git ls-files` (index.ex, security_profile.ex, keys_live_test.exs, key_encryption_helpers.ex confirmed tracked; admin_components.ex, PRODUCT.md, keys_encryption_status_test.exs are standard tracked lib/docs/test files).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | | | `decision_summary` is unused by any LiveView yet (only the component module and design-system stress test); its first LiveView use is here. Run `test/lockspire/web/live/admin/design_system_component_stress_test.exs`. |

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin/`, `lib/lockspire/web/components/admin_components.ex`, `test/lockspire/web/live/admin/`, `test/support/key_encryption_helpers.ex`, `PRODUCT.md`
**Files scanned:** ~8 read directly; remaining details taken from RESEARCH.md verified excerpts
**Pattern extraction date:** 2026-10-19
**Notes:** `Admin.encryption_status/0` returns `{:ok, map}` (not a bare map). Run tests with `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`.
