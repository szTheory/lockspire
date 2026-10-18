# Architecture Patterns

**Domain:** Embedded OAuth/OIDC server library (Phoenix) - v1.44 Adopter Polish & Verified 1.6.0
**Researched:** 2026-10-18
**Scope:** Integration of the six NEW items only. Line numbers are from the working tree at HEAD `10799172` and will drift; re-grep before editing.
**Overall confidence:** HIGH (all findings read from source; nothing here depends on external docs)

## Recommended Architecture (summary)

No new layer, no new dependency, no schema migration, no protocol change. Every item lands on an existing seam:

| Item | Seam it uses | New files | Modified files |
|------|--------------|-----------|----------------|
| 1. Mix tasks start the repo | `Lockspire.Install.RepoRunner.run/2` (`lib/lockspire/install/repo_runner.ex:15`) | 0 lib, 3 test | 3 task files |
| 2. `mix lockspire.gen.kek` | Mix layer only; shared snippet builder | 1 task, 1 small helper, 1 test | `generators/install.ex`, docs |
| 3. `{:system, "ENV"}` KEK | `Lockspire.Config.key_encryption!/0` (`config.ex:254`) | 0 | `config.ex`, tests, docs |
| 4. "Key protection" line | `Admin.encryption_status/0` -> LiveView assign | 1 presenter, 1 component | `keys_live/index.ex`, `admin_components.ex`, `PRODUCT.md` |
| 5. Missing-KEK error copy | `{:error, :key_encryption_not_configured}` clause in `keys_live/index.ex` | 0 | `keys_live/index.ex`, `admin.ex` @spec |
| 6. Verified 1.6.0 | Existing `release.yml` exact-ref dispatch lane (no change) | planning docs only | `.planning/RELEASE-TRAIN.md`; clean-room journey extended |

Boundary check (what must NOT happen):
- Protocol core (`lib/lockspire/protocol/**`) is untouched. `PrivateJwk` and `KeyEncryption` read through `Config.key_encryption_keyset/0`, which keeps returning a `%KeySet{}`; they do not learn about `{:system, _}`.
- Storage (`lib/lockspire/storage/**`) is untouched. No new callback. The Key protection line reuses the existing `list_signing_keys(sensitive: true)` path through `Admin.Keys.encryption_status/0`.
- Mix tasks stay thin: they call public `Lockspire.Admin.*` / `Lockspire.Clients` functions inside `RepoRunner.run/2`. They never reach into `Repository` directly.
- LiveView calls only `Lockspire.Admin.*` (as it does today). The presenter formats a status map; it does not read config or Repo.

## Item 1: DB-touching Mix tasks do not start the repo

### Root cause (verified)

All three tasks declare `@requirements ["app.config"]` and then call a function that hits `Lockspire.Config.repo!()`:

| Task | File:line | Declares | DB call that fails without a running repo |
|------|-----------|----------|-------------------------------------------|
| `lockspire.client.create` | `lib/mix/tasks/lockspire.client.create.ex:10`, `run/1` at :27, pipeline at :36-40 | `app.config` | `Clients.register_client/1` -> `persist_client` (`lib/lockspire/clients.ex:113`) |
| `lockspire.doctor.token_format` | `lib/mix/tasks/lockspire.doctor.token_format.ex:18`, `report/0` at ~:57 | `app.config` | `ServerPolicy.get_server_policy/0` (`admin/server_policy.ex:41`), `Clients.list_clients/0` |
| `lockspire.doctor.remote_jwks` | `lib/mix/tasks/lockspire.doctor.remote_jwks.ex:12`, pipeline at :33-37 | `app.config` | `Admin.Clients.get_client/1` (`admin/clients.ex:71`) -> `Repository.fetch_client_by_id` |

`app.config` loads and configures apps but starts nothing. The host repo is only started by `app.start`, and `Lockspire.Application` (`application.ex:12`) deliberately does not supervise the host repo. So the tasks work on a developer machine only if something else started the repo, and fail in a bare `mix` invocation.

Why existing tests did not catch it: `test/mix/tasks/lockspire_doctor_token_format_test.exs:11-16` (and the remote_jwks test) call `start_supervised!(Lockspire.TestRepo)` in `setup_all`, which masks the bug. The `reencrypt` integration test (`test/mix/tasks/lockspire_keys_reencrypt_test.exs:84-87`) does the right thing: `refute Process.whereis(Lockspire.TestRepo)` at setup, `@moduletag :integration`, committed-DB guard.

### Audit of ALL `lib/mix/tasks` (11 files)

| Task | Touches DB? | Status |
|------|-------------|--------|
| `lockspire.keys.reencrypt` | Yes | OK - `Ecto.Migrator.with_repo(..., mode: :temporary)` in `execute/1` (~:101-111) |
| `lockspire.doctor.key_encryption` | Yes (status) | OK - `RepoRunner.run/2` at :143 |
| `lockspire.verify` -> `Install.Verify` | Yes | OK - `RepoRunner.run` at `install/verify.ex:376` and :411 |
| `lockspire.client.create` | Yes | **BROKEN** |
| `lockspire.doctor.token_format` | Yes | **BROKEN** |
| `lockspire.doctor.remote_jwks` | Yes | **BROKEN** |
| `lockspire.doctor` (dispatcher) | Delegates via `Mix.Task.run` (:11-21) | OK; inherits sub-task fix |
| `lockspire.test.setup` | Yes | OK - own `Ecto.Migrator.with_repo` at :37 (dev/test only) |
| `lockspire.install`, `lockspire.upgrade` | No (file generators) | OK |
| `lockspire.oidf_conformance` | No Repo reference in file | OK (conformance harness, not host DB) |

Conclusion: exactly the three named tasks; no fourth hidden gap in `lib/mix/tasks`. (Confidence HIGH for the grep; the audit should still re-run `grep -L "RepoRunner\|with_repo"` over tasks that call `Clients.`/`Admin.`/`ServerPolicy.` as a regression guard.)

### Recommended fix pattern (opinionated)

Use `Lockspire.Install.RepoRunner.run/2`, NOT a hand-rolled `with_repo`, for the three tasks. Reasons:
- It is already the shared seam for read-only host diagnostics (doctor key_encryption, Install.Verify). It calls the fun directly when the repo is already running (so `mix run`, a release `rpc`, and the test suite do not get their pool restarted) and uses `Ecto.Migrator.with_repo(mode: :temporary)` only when no process holds the repo name (`repo_runner.ex:23-33`).
- It never raises with connection details; returns `{:error, :repo_unavailable}`. `keys.reencrypt` has its own copy of the `with_repo` call because it must also `Mix.raise` on the result; the other tasks should not copy that.
- Do NOT copy `reencrypt`'s unconditional `with_repo` into `client.create`: it restarts a running pool.

Shape for each task (the `Lockspire.Config.repo!()` lookup happens in the task, inside the `RepoRunner.run` call, never at module attribute time):

```elixir
# client.create, in run/1 replacing the pipeline at :36-40
repo = Lockspire.Config.repo!()
case RepoRunner.run(repo, fn _repo -> opts |> build_attrs() |> Clients.register_client() end) do
  {:ok, result} -> print_result(result)          # existing print_result/1 clauses unchanged
  {:error, :repo_unavailable} -> Mix.raise("could not start the repo; check database connectivity and config")
end
```

Notes per task:
- `client.create`: print/raise AFTER `RepoRunner.run` returns, so `client_secret` printing (`print_result/1` :73-95) happens outside the temporary repo. Keep the secret out of the `{:error, ...}` path. `Mix.raise` text for the unavailable-repo case should match `keys.reencrypt`'s `repo_failure/0` wording for consistency.
- `token_format`: its contract is "never raises, never exits non-zero" (moduledoc :36-38). On `{:error, :repo_unavailable}` print one calm `Mix.shell().info("Could not inspect token formats: ...")` line, matching the existing `else` branch in `report/0`. Do not change exit semantics.
- `remote_jwks`: `print_result/1` already raises `Mix.raise` for `{:error, :not_found}`. Wrap only the `Clients.get_client` call; the `Clients.remote_jwks_summary/1` call at :55 is pure.
- Dependencies: `RepoRunner` does `Application.ensure_all_started(:ecto_sql)` itself (:28), which pulls `db_connection`/`postgrex` as the host's adapter requires. `Clients.register_client` also emits telemetry via `Observability.emit` (clients.ex:~120) - `:telemetry` is not started by `app.config` but its `:telemetry.execute` works with an unstarted app (ETS table is created on module load). Confirm in the clean-room test, not by assumption (MEDIUM).
- Do not widen `@requirements` to `app.start`: that starts `Lockspire.Application`, which boots Oban (`application.ex:19`) and the KeyCache against a repo that is not yet running. That is the wrong fix.

### Tests (new)

- New integration tests mirroring `lockspire_keys_reencrypt_test.exs` setup: `@moduletag :integration`, assert `Process.whereis(Lockspire.TestRepo) == nil` before and after the task, unique-prefixed rows, `on_exit` cleanup. One per task: `test/mix/tasks/lockspire_client_create_test.exs` (new file; none exists - client.create has no task test today), plus new cases appended to the two existing doctor tests in a separate `describe`/module whose setup does NOT call `start_supervised!`.
- The existing doctor tests' `setup_all` (`start_supervised!(Lockspire.TestRepo)`) must stay for the existing cases (they prove behavior when the repo is already running - the `RepoRunner` direct-call branch). Put the "no pre-started repo" cases in a new test module to avoid sharing that setup.
- The authoritative proof is the clean-room harness (Item 6), because it runs real `mix` OS processes against the packaged tar: add `run_child_command(provider_child, provider_environment, "lockspire.client.create", ...)`, `"lockspire.doctor", "token_format"`, `"lockspire.doctor", "remote-jwks", "--client", ...` next to the existing `keys.reencrypt --check` and `doctor key_encryption` calls at `scripts/acceptance/clean_room_saas_journey.py:923-924`. That is the milestone's "confirm in a clean-room host" requirement: write the harness lines FIRST, watch them fail on the unfixed tasks, then fix.

## Item 2: `mix lockspire.gen.kek` (KEK-03)

### Placement

- New: `lib/mix/tasks/lockspire.gen.kek.ex` -> `Mix.Tasks.Lockspire.Gen.Kek`. No `@requirements` (or only `[]`): it needs neither app config nor a repo. Pure output. Contrast with other tasks which all declare `app.config`; do not copy that.
- Generation: `Base.encode64(:crypto.strong_rand_bytes(32))`. This is exactly what the installer already does (`lib/lockspire/generators/install.ex:127` `dev_kek`). The ID default also mirrors the installer: `Calendar.strftime(DateTime.utc_now(), "%Y-%m")` (install.ex:126). Allow `--id ID` to override; validate against `KeySet`'s `@id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/` (`key_set.ex:~58`, private) - do not duplicate the regex; round-trip the generated pair through `KeySet.new(keys: [{id, b64}], current: id)` in the task and `Mix.raise` on `{:error, _}`. That single call also checks length and the weak-material rule, so a generated key can never be one the app would reject. (`KeySet` is `@moduledoc false` but in the same OTP app, so calling it from a Mix task is within the Mix/protocol-core boundary only if the call goes via a public function: prefer adding no public API and instead asserting the round-trip in the task TEST, not in task code. Recommended: task code just encodes; test does `KeySet.new` round-trip.)
- Shared snippet: the `runtime.exs` block text currently lives inline in `Generators.Install.instructions/1` (install.ex:121-160, lines 142-160 are the block). Extract it to a new tiny module `Lockspire.Generators.KekSnippet` (`lib/lockspire/generators/kek_snippet.ex`, `@moduledoc false`) with `runtime_block(id)` and `dev_block(id, material)`; both `Install.instructions/1` and the new task call it. Without this, the installer and `gen.kek` will drift (the installer text is pinned by `test/integration/install_generator_test.exs`; keep its asserted strings stable).
- Output contract: the task prints key material (necessarily) to stdout ONLY, with the runtime.exs snippet referencing `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY")` and the generated base64 shown once as the value to export. Do not write files, do not log via `Logger`, do not emit telemetry. Add to `Lockspire.Redaction` nothing (stdout, not a log); but add a leak-test assertion that no other task prints it.
- Update existing guidance that currently points to `openssl rand -base64 32` to also name the task: `config.ex:282-290` (`fail_key_encryption!` text), `install/verify.ex:97` (`key_encryption_fix/0`), `mix/tasks/lockspire.keys.reencrypt.ex:145-148`, `docs/upgrading/signing-key-encryption.md:12`. Keep `openssl` as the fallback (the host may not have Lockspire's Mix task available, e.g. in a release). Contract tests that pin those strings: `test/lockspire/config_key_encryption_test.exs`, `test/lockspire/install/verify_test.exs`, `test/lockspire/upgrade_guide_contract_test.exs` - update them in the same commit.
- Test: `test/mix/tasks/lockspire_gen_kek_test.exs` - pure, `async: true` safe, uses `capture_io`; asserts output decodes to 32 bytes, passes `KeySet.new/1`, is different on each call, and the snippet round-trips through `Code.string_to_quoted`.

## Item 3: `{:system, "ENV"}` KEK resolution (KEK-05)

### Where it goes: `Lockspire.Config.key_encryption!/0`, NOT `KeySet.new/1`

`Config.key_encryption!/0` (`lib/lockspire/config.ex:254-266`) is the single fresh-validation entry. Everything funnels through it:
- Boot: `Lockspire.Application.validate_key_encryption!/0` (`application.ex:29`) -> persists the KeySet in `:persistent_term` (:32).
- Hot path: `Config.key_encryption_keyset/0` (`config.ex:270`) returns the cached KeySet or falls back to `key_encryption!/0`.
- Mix/diagnostics: `keys.reencrypt` (`legacy_mode/0`, `Admin.Keys.fresh_keyset/0` keys.ex:~311), `doctor.key_encryption` (`fetch/0` :151), `Install.Verify` (`verify.ex:69`), `Admin.Keys.status_keyset/0` (keys.ex:~298).

Add a resolution step between `Application.get_env` and `KeySet.new` inside `key_encryption!/0`:

```elixir
config -> config |> resolve_system_entries() |> KeySet.new() |> ...
```

where `resolve_system_entries/1` maps `keys: [{id, {:system, var}}]` to `{id, System.get_env(var)}`; a missing/empty variable yields a tagged error. Why Config and not KeySet:
- `KeySet` is a pure validator (struct + decode + strength checks, no environment access). Keeping env reads in `Config` (which already does `Application.get_env`) preserves that.
- `KeySet.decode_entry/2` (`key_set.ex:86`) guards `is_binary(b64)`; `{:system, _}` would hit the `_entry` fallback (:97) as `:invalid_key_entry` today. After resolution it sees a normal binary and all strength/length/duplicate checks apply unchanged. Zero change to `KeySetInspect` (it never prints keys, only ids).

Error handling (important for redaction): keep the `{:error, {atom, atom}}` contract. Add `{:keys, :missing_env}` and a clause in `fail_key_encryption!/2` (`config.ex:282`). The raise message may name the environment variable NAME (not secret) but must never include the value. The current message promise is "names only config keys (never values)" (config.ex comment :248-250): env var names are config, not key material, so naming them is consistent; do it by raising a distinct `ArgumentError` text, not by widening the error tuple (the tuple shape is pinned by `test/lockspire/config_key_encryption_test.exs`).

### Boot-time fail-fast interplay

- `validate_key_encryption!/0` calls `key_encryption!/0` at `application.ex:30`; an unset `{:system, var}` raises `ArgumentError` there, aborting application start. That is the right behavior: a configured-but-unresolvable KEK is "invalid", not "unconfigured". Do NOT map missing env to `nil` (the warning-and-continue branch at :34-41); that would silently let the app boot with encrypted keys it cannot read.
- Caching consequence: boot caches the resolved KeySet in `:persistent_term` (`application.ex:32`). Env var changes after boot are not observed by `key_encryption_keyset/0` (:271) but ARE observed by fresh callers (`key_encryption!/0`: Mix tasks, doctor, verify). Document this; it matches how a plain `System.get_env` in `runtime.exs` already behaves (evaluated once at boot). It also means `mix lockspire.keys.reencrypt --check` in the same environment sees the same value as the node as long as the variable is exported.
- `{:system, _}` in `config/config.exs` (compile-time) is the main value-add: compile-time config cannot call `System.get_env` safely for a release. In `runtime.exs` the existing `System.get_env(...) || raise(...)` block (install.ex:142-152) stays the recommended fail-closed form and the installer text should NOT change to `{:system, _}` (explicit `raise` gives a better message). Mention `{:system, _}` in `docs/upgrading/signing-key-encryption.md` and the `:key_encryption` section of `docs/install-and-onboard.md`.
- Rolling-deploy caveat already documented (AR-156-01): not new.
- `Install.Verify.key_encryption_check/0` (`verify.ex:68-95`) already maps `ArgumentError` to the "invalid" check and `nil` to "missing"; a missing env var will appear as "invalid" with the message, with no code change. Verify text for the fix hint (`verify.ex:97`) should mention the env var.

### Tests
Extend `test/lockspire/config_key_encryption_test.exs` (set env with `System.put_env`, restore in `on_exit`, `async: false`) and `test/lockspire/application_key_encryption_test.exs` (boot raises on missing var). Add a `key_material_leak_test.exs` case: the raised message contains the var name but not the value.

## Item 4: Read-only "Key protection" line (KEY-UI-01)

### Data source: reuse `Lockspire.Admin.encryption_status/0` (no new storage function)

- `Admin.encryption_status/0` (`admin.ex:249-252`, `defdelegate` to `Admin.Keys.encryption_status/0`, `keys.ex:258-267`) already returns `configured`, `current_kek_id`, `legacy_plaintext`, `total`, `legacy`, `by_kek_id`, `ready?` computed by the pure `EncryptionStatus.build/2` over `list_signing_keys(sensitive: true)`. It carries ids and counts only, never bytes. Using it guarantees the admin line cannot disagree with `mix lockspire.keys.reencrypt --check` and `doctor key_encryption` (the module doc at `encryption_status.ex:3-8` states that as its purpose).
- Cost: it opens each row (AES-GCM decrypt, discarded) because `assess/2` calls `PrivateJwk.read_stored` (`keys/reencrypt.ex:116,127`). Key inventories are tiny (single digits to low tens); this runs once per mount/reload, not per render. Acceptable; do not add a cheaper parallel classifier, which would reintroduce drift. If it ever matters, `KeyEncryption.classify/1` + `envelope_kek_id/1` (`key_encryption.ex:15,65`) are the cheap path and `Keys.list_signing_key_refs` (store callback from Phase 156) avoids loading JWK bytes; defer.
- Error shapes: `{:error, :repo_not_started | :storage_unavailable | {:invalid_config, String.t()}}`. In a mounted LiveView the repo is running, so treat any error as "state unknown": omit the line or show a calm "Key protection could not be checked" (never echo the `{:invalid_config, msg}` text into HTML; `msg` is safe by contract but keep admin surfaces redacted).

### Where it renders

- Page: `Lockspire.Web.Live.Admin.KeysLive.Index` (`lib/lockspire/web/live/admin/keys_live/index.ex`), directly under `AdminComponents.page_hero` (:54) and above the key-inventory metric grid (:57), so it is visible whether inventory is empty or loaded.
- Assign: add `key_protection: nil` to `mount/3` assigns (:12-24) and populate it inside `assign_inventory/2` (:166-178) after `assign_inventory_result(load_keys())`, because both mount (`handle_params`:28) and `retry_inventory` (:33) go through it. Also refresh after a successful `generate` (the `:ok` branch of `generate_key/3`, :201-222) so the line moves from "not configured" state if config changed (rare) - cheap to keep it consistent by calling the same helper.
- The Show page (`keys_live/show.ex`, `render/1` at :155 and :191) does not need a new status fetch: per-key protection would require sensitive reads. Scope KEY-UI-01 to the Index page ("admin Keys pages" in the milestone text -> Index only is the minimal slice; flag for the roadmap whether Show is wanted. Recommendation: Index only).
- New function component `AdminComponents.key_protection_line/1` in `lib/lockspire/web/components/admin_components.ex` (alongside `page_hero` :83 and `metric_grid` :197), taking `state`, `kek_id`, and `legacy_count`. Pure presenter in new `lib/lockspire/web/live/admin/keys_live/protection.ex` (`@moduledoc false`) with `summarize(status_or_error) :: %{state: :protected | :mixed | :unprotected | :not_configured | :unknown, ...}` so the copy logic is unit-testable without rendering.

### State -> copy mapping (to be worded from the vocabulary map)

| Status input | State | Meaning shown |
|--------------|-------|---------------|
| `configured: false` | `:not_configured` | Keys are not encrypted; no protection key is set (and generating is blocked - see Item 5) |
| `legacy == 0`, `unknown_kek == %{}`, `undecryptable == 0`, `current_kek_id` set | `:protected` | "Signing keys are encrypted with key `<id>`" |
| `legacy > 0` or `other_kek` pending | `:mixed` | N keys still need encrypting; run `mix lockspire.keys.reencrypt` |
| `broken_now?/1` true (`encryption_status.ex:~46`) | `:attention` | Some keys cannot be read; run `mix lockspire.doctor key_encryption` |
| error tuple | `:unknown` | Could not check |

Show only the current KEK ID (an operator-chosen label, already printed by CLI tools), never material, never per-key ids.

### Vocabulary contract (mandatory per AGENTS.md)

- The least technical persona (see `PRODUCT.md` personas lines 19-47) does not know "KEK". Pick a "UI says" term, e.g. "Key protection" / "protection key", and add a row to the Vocabulary map table (`PRODUCT.md` `### Vocabulary map` starts line 105; table rows run through ~139) in the SAME change: `| key-encryption key (KEK) | protection key | In help text only |`. Also add any retired phrase to `### Retired wording` (line 141) if you replace wording; the enforcing test is `test/lockspire/web/live/admin/vocabulary_contract_test.exs`, which globs `lib/lockspire/web/live/admin/**/*.{ex,heex}`, `admin_layout_live.ex` and `components/admin_components.ex` - so both the presenter and component are scanned automatically. No test edit is needed unless a retired phrase is introduced; confirm the new copy contains no phrase from the table (e.g. avoid "signing key" -> OK; "assertion-key" is retired).
- Describe what Lockspire actually does (AGENTS.md rule): "encrypted at rest in your database with key `2026-10`", not "secure" or "protected".
- Add LiveView tests in `test/lockspire/web/live/admin/keys_live_test.exs` (existing file; uses direct `Index.mount`/`handle_params` calls with `socket_for(:index)` - see :211, :441) for each state. Seed state with `test/support/key_encryption_helpers.ex` / `seeding_helpers.ex`; use `Application.put_env(:lockspire, :key_encryption, ...)` per test with `on_exit` restore. Also assert absence of key material in rendered HTML (the structural matcher in `key_material_leak_test.exs` is the pattern).

## Item 5: Admin key-generation error naming the missing KEK

### Trace (verified)

1. UI click -> `handle_event("generate", %{"use" => use}, socket)` (`keys_live/index.ex:37-39`) -> private `generate_key/3` (:198).
2. `Admin.generate_key(use_atom)` (:201) -> `defdelegate` `lib/lockspire/admin.ex:210` -> `Lockspire.Admin.Keys.generate_key/1` (`admin/keys.ex:85`).
3. `Config.key_encryption_keyset()` (`config.ex:270`): returns `nil` when boot cached `:unconfigured` (`application.ex:35`) -> `Keys.generate_key` returns `{:error, :key_encryption_not_configured}` (`keys.ex:87`). The typespec at keys.ex:83-84 already lists this reason.
4. Back in the LiveView, the only error clause is the catch-all `{:error, _reason}` at `index.ex:236-243`, which assigns `generation_error: "The #{String.downcase(key_label)} key could not be generated."`. The reason is discarded.
5. Render: `@generation_error` is displayed in `<ul class="lockspire-admin-errors" role="alert">` (render ~:100). **It is an assign, not `put_flash`** - the milestone note saying "flash" is loose. No `Phoenix.Flash`/layout change is needed.

### Change

- In `index.ex`, add a clause BEFORE the catch-all at :236: `{:error, :key_encryption_not_configured} -> assign(socket, generation_error: <copy>, generation_notice: nil, generated_key_path: nil)`. Copy names the missing protection key and the fix path, e.g. "No key-encryption key is configured, so Lockspire cannot create a #{label} key. Set `:key_encryption` in config/runtime.exs; `mix lockspire.gen.kek` creates one." Use the vocabulary term decided in Item 4 and mention the config name literally (operators fix it by editing config; AGENTS.md says describe what Lockspire does). Do not mention `openssl`.
- Optional: add `{:error, {:invalid_config, _}}` no - `generate_key` calls `key_encryption_keyset/0`, which can raise `ArgumentError` on the cache-miss path (`config.ex:274` -> `key_encryption!/0`). At runtime the boot cache is always populated, so this only matters in tests; no change, but note it so Item 3's `:missing_env` does not surprise the LiveView (it would be caught at boot first).
- `admin.ex:208-210` `@spec generate_key` currently says `{:error, term()}`; tighten to `{:error, :key_encryption_not_configured | term()}` for docs (the Keys-level spec at keys.ex:83-84 already does).
- Pre-empt the error in the UI as well (small, optional, same change): the Key protection state `:not_configured` (Item 4) can disable the two generate buttons (`index.ex` buttons at ~:70 and ~:82, currently `disabled={@inventory_state != :loaded}`) and show the same sentence inline. Recommendation: keep buttons enabled and let the error clause fire - it is the tested, single source of the copy; disabling duplicates the rule. Revisit only if UX review asks.
- Test: add to `keys_live_test.exs` a case with `Application.put_env(:lockspire, :key_encryption, nil)` plus `:persistent_term.put(Config.key_encryption_cache_key(), :unconfigured)` (restore in `on_exit`), triggering `handle_event("generate", ...)` and asserting the error names the missing key and no generic fallback text; assert the generic copy remains for other reasons.

## Item 6: Verified 1.6.0 publication (map of existing lane; no new machinery)

### Current state
- Release Please PR #121 "chore(main): release lockspire 1.6.0" is OPEN and MERGEABLE (`gh pr view 121`). Branch `release-please--branches--main--components--lockspire`. `.release-please-manifest.json` and `.planning/RELEASE-TRAIN.md` still say 1.5.1.
- Ordering hazard: Release Please recomputes the PR from conventional commits on `main`. Land all `feat(...)`/`fix(...)` v1.44 work on `main` BEFORE merging #121, then re-read the PR diff (CHANGELOG and version) and merge as the LAST step. Merging #121 early would cut 1.6.0 without the adopter-polish changes. Per memory: squash-merge PRs; the title becomes the changelog entry.
- Auto-merge lane is closed unless repo variable `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` is `true` (`.github/workflows/release-please-automerge.yml`); check it, merge #121 by hand otherwise.

### Existing pipeline (read from `.github/workflows/release.yml`, 798 lines, and Phase 143 CONTEXT)

| Stage | Where | What it proves |
|-------|-------|----------------|
| Release Please maintenance (push) | job `release-please` :33 | Opens/updates PR; never publishes |
| Exact-ref validation | job `recovery-validation` :70 (workflow_dispatch only; inputs `recovery_reason`, `recovery_ref`, `source_ci_run_id` at :7-18) | Full 40-hex SHA == current `origin/main`, with matching successful CI push run |
| Prepublish proof | job `prepublish-proof` :125 | Builds ONE tar, writes manifest (`scripts/publish/release_artifact.py`), runs clean-room SaaS HTTP journey against the local tar |
| Protected publish | job `publish` :237, `environment: hex-publish` (human approval) | Main freeze (`release_main_freeze.sh create` :344), tag guard, `publish_hex_idempotently.sh` + `upload_hex_artifact.exs` upload the manifest-verified bytes; GitHub release; cleanup freeze :458-467 |
| Public install truth | job `post-publish-install-truth` :468 | `scripts/publish/verify_install_truth.sh` (Hex checksum, exact-version HexDocs) + clean-room journey from the PUBLIC Hex package, Postgres service container |
| Terminal receipt | job `terminal-outcome` :580 (`always()`) | Bounded redacted receipt: `release_verified` true/false per stage |

Prior precedent (RELEASE-TRAIN.md lines 11-14): 1.5.1 was published and verified by protected run 37795671282 from source `0b56503859b69531ff86d8e4a465a0e75f963594`, with receipt `release_verified: true`. Process doc: `docs/maintainer-release.md` (steps 1-9 at ~:28-40).

### What is NEW for 1.6.0 (the only non-mechanical parts)
1. **Clean-room harness must exercise encryption + the fixed tasks.** The harness already provisions an encrypted host: `scripts/acceptance/clean_room/build_provider.py:82-95` writes the env-sourced KEK `runtime.exs` with `legacy_plaintext: :reject`, and `clean_room_saas_journey.py:923-924` runs `keys.reencrypt --check` and `doctor key_encryption`. Add (Item 1) the three task invocations at that location, and (Item 2) use `mix lockspire.gen.kek` output (or at least assert it runs) in place of `os.urandom(32)` base64 at `build_provider.py:243`. These edits must be on `main` before the 1.6.0 prepublish proof runs, because the proof runs the harness from the exact SHA.
2. **Packaged-task regression.** `lockspire.gen.kek` and any new file must be in the Hex package `files:` list (check `mix.exs` `package/0`) and covered by `test/lockspire/clean_room_release_source_contract_test.exs` / `release_artifact_chain_contract_test.exs` expectations if they enumerate package contents.
3. **Hex package version assertions.** `RELEASE-TRAIN.md` lines 8-9 and 11 carry `x-release-please-version` markers that Release Please bumps; the rest of the baseline text is hand-written and must be rewritten after publish to carry the 1.6.0 run ID, SHA, Hex checksum, tag URL, receipt result (copy the 1.5.1 paragraph structure). `test/lockspire/release_readiness_contract_test.exs` and `release/release_automation_contract_test.exs` likely pin RELEASE-TRAIN text; run them after editing.
4. **Docs:** `docs/upgrading/signing-key-encryption.md` is already in the package extras (mix.exs :196-218 lists docs); update for `{:system, ...}` and `gen.kek` before the release so the published HexDocs for 1.6.0 carry it.

### Procedure (what the roadmap phase should encode)
1. Ensure `main` contains every v1.44 change and canonical CI is green on the exact SHA; run `./scripts/maintainer/repo_hygiene_check.sh` (no `BLOCK`).
2. Re-read PR #121 diff (version 1.6.0, CHANGELOG lists the v1.43 and v1.44 changes); squash-merge it.
3. Wait for CI push run on the merge SHA; the release workflow's exact-ref dispatch (per `docs/maintainer-release.md`) validates it; approve the `hex-publish` environment.
4. Verify: terminal receipt `release_verified: true`; Hex checksum equals manifest SHA-256; HexDocs for 1.6.0 resolve; `lockspire-v1.6.0` tag peels to the source SHA; public clean-room journey passed.
5. Update `.planning/RELEASE-TRAIN.md` baseline and `.planning/STATE.md`. Do not conflate "on Hex" with "verified" (Phase 143 D-08/D-09).

## Data Flow Changes

```
Mix task (client.create / doctor.*)  --RepoRunner.run--> Repo (temp, :temporary)
                                                      \-> Clients/Admin.* -> Storage.Ecto.Repository
Config :key_encryption  --[{:system,V} resolve]--> KeySet.new --> :persistent_term (boot)  --> PrivateJwk / KeyEncryption
                                                              \-> fresh (Mix, doctor, verify, Admin.status)
Admin.encryption_status --> KeysLive.Index assign :key_protection --> Protection.summarize --> AdminComponents.key_protection_line
Admin.generate_key -> {:error, :key_encryption_not_configured} -> Index :generation_error (existing <ul role=alert>)
```

Only two data-flow changes are real: (a) env resolution inserted before `KeySet.new` in `Config.key_encryption!/0`; (b) one extra read (`encryption_status`) per Keys page load.

## Anti-Patterns to Avoid

### Starting the whole app in the Mix tasks
Changing `@requirements` to `app.start` starts Oban/KeyCache and `Lockspire.Application`, which requires the repo to already be running; it also reads the KEK at boot and would abort a diagnostic task on invalid config instead of reporting it. Use `RepoRunner`.

### Resolving `{:system, _}` inside `KeySet` or at every call site
Spreads env reads into the validator and the hot path (`PrivateJwk`). Resolve once in `Config.key_encryption!/0`; the boot cache then serves the hot path.

### Mapping a missing env var to "unconfigured"
Turns a deploy misconfiguration into a silent warning (`application.ex:34-41`) and a later key-generation refusal. Fail at boot.

### A second key-state classifier for the UI
`EncryptionStatus` is explicitly the single readiness truth (`encryption_status.ex` moduledoc). A cheaper admin-only classifier would disagree with `--check`.

### Reusing "KEK" or "envelope" in admin copy
Both are engineer terms; the vocabulary contract and AGENTS.md require plain words from the map. Add the map row first.

### Editing tests that start the repo to cover the new bug
The old tests are correct for the already-running-repo branch. Add separate no-repo tests; do not delete the existing ones.

## Suggested Build Order (with dependencies)

| # | Work | Depends on | Why this position |
|---|------|------------|-------------------|
| 1 | **Harness-first reproduction:** add the three task commands to `clean_room_saas_journey.py:923-924`, run locally against the packaged tar to show failure | none | Satisfies "confirm in a clean-room host" before fixing; this same edit is the final release proof |
| 2 | **Item 1 fix:** `RepoRunner` in `client.create`, `doctor.token_format`, `doctor.remote_jwks` + three no-repo integration tests | 1 | Unblocks every later task/harness step; smallest, highest-value fix |
| 3 | **Item 3:** `{:system, var}` in `Config.key_encryption!/0` (+ `:missing_env` error, boot-fail test) | none (independent of 1-2) | Must precede `gen.kek` docs/snippet text and the Verify fix hint that cite it |
| 4 | **Item 2:** `Lockspire.Generators.KekSnippet` extraction, `lockspire.gen.kek`, update guidance strings (config.ex:282-290, verify.ex:97, reencrypt.ex:145, upgrade guide) and their contract tests | 3 (so the snippet and docs can mention `{:system, _}` correctly) | Mix-only, no repo |
| 5 | **PRODUCT.md vocabulary row** for the protection key term | none; must precede 6 and 7 | AGENTS.md: the map is updated in the same change as UI copy |
| 6 | **Item 5:** `:key_encryption_not_configured` clause in `keys_live/index.ex` + test; tighten `admin.ex:208` @spec | 5 | Tiny, user-visible, isolates the copy decision |
| 7 | **Item 4:** `Protection` presenter, `AdminComponents.key_protection_line/1`, Index assign + tests | 5 (term), 6 (consistent not-configured wording) | Largest UI change; reuses `Admin.encryption_status/0` |
| 8 | Docs: `docs/upgrading/signing-key-encryption.md`, `docs/install-and-onboard.md`, `docs/operator-admin.md` (Key protection line), CHANGELOG is Release Please-owned (do not hand-edit) | 2-7 | Published HexDocs for 1.6.0 must carry these |
| 9 | Harness: switch provisioning key to `gen.kek`/assert it; confirm journey green on `main` CI | 1-4 | The exact-SHA release proof runs this |
| 10 | **Item 6:** hygiene gate -> re-read and squash-merge Release Please PR #121 -> exact-ref dispatch -> approve `hex-publish` -> verify receipt -> update `RELEASE-TRAIN.md`/STATE | everything on `main` and green | Merge #121 LAST; merging earlier ships 1.6.0 without this milestone |

Parallelizable: (2) and (3) are independent; (6) and the docs can proceed alongside (7).

## Phase-count suggestion for the roadmap
Three phases fit the dependency graph: (A) Mix task gap + harness reproduction (steps 1-2); (B) KEK DX: `{:system}` + `gen.kek` + guidance strings (3-4, 8 partially); (C) Admin UI: vocabulary row, error clause, Key protection line (5-7). Then (D) the release/verify phase (9-10), mirroring v1.39 Phase 143. Phase D needs a "research-free" plan (copy Phase 143's playbook); the others are standard patterns.

## Research Flags

| Area | Flag |
|------|------|
| Item 1: `:telemetry`/`Observability.emit` with only `app.config` | MEDIUM - verify in the clean room that `Clients.register_client` has no dependency on a started app other than `:ecto_sql`/`:postgrex` |
| Item 1: does `Ecto.Migrator.with_repo` in a Sandbox-pool test config need `mode: :auto`? | LOW risk - `keys.reencrypt` test already proves it works against the committed test DB |
| Item 4: Show page per-key protection | Out of recommended scope; needs a decision (would require sensitive reads or a store callback) |
| Item 6: Hex client version used by publisher (Phase 143 D-07) | Re-check `upload_hex_artifact.exs` against the latest Hex client at publish time |
| Release Please #121 contents at merge time | Re-read; the PR body and CHANGELOG regenerate as commits land |

## Sources

- Source files read (all HIGH confidence): `lib/mix/tasks/*.ex`, `lib/lockspire/install/repo_runner.ex`, `lib/lockspire/config.ex`, `lib/lockspire/application.ex`, `lib/lockspire/security/key_encryption/key_set.ex`, `lib/lockspire/admin.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/admin/keys/{encryption_status,reencrypt}.ex`, `lib/lockspire/web/live/admin/keys_live/{index,show}.ex`, `lib/lockspire/generators/install.ex`, `lib/lockspire/install/verify.ex`, `PRODUCT.md`, `test/lockspire/web/live/admin/vocabulary_contract_test.exs`, `test/mix/tasks/*`, `.github/workflows/release.yml`, `scripts/acceptance/**`, `scripts/publish/**`, `.planning/RELEASE-TRAIN.md`, `.planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CONTEXT.md`, `docs/maintainer-release.md`.
- `gh pr view 121` (live PR state, 2026-10-18).
