# Feature Landscape: v1.44 Adopter Polish & Verified 1.6.0

**Domain:** Operator and adopter ergonomics around signing-key encryption at rest in an embedded Phoenix OAuth/OIDC library
**Researched:** 2026-10-18
**Scope:** Only the new v1.44 items. v1.43 features (envelope encryption, reencrypt task, doctor, `--check`) are the base and are not re-researched.
**Confidence:** MEDIUM overall. Repo facts are HIGH (read directly: `config.ex`, `key_set.ex`, `repo_runner.ex`, `admin/keys.ex`, `generators/install.ex`, `keys.reencrypt.ex`, PRODUCT.md). Comparator behavior (phx.gen.secret, Cloak, Rails, Hydra, Keycloak, Zitadel) is from training knowledge, not re-fetched live, so treat it as MEDIUM.

## Repo Facts That Constrain The Design

- KEK format is fixed by `Config.fail_key_encryption!/2` and `KeySet`: each entry is `{id, base64-of-32-random-bytes}`, id matches `~r/\A[A-Za-z0-9._-]{1,32}\z/`, plus `current:` and `legacy_plaintext:`. The error text already says `mix phx.gen.secret` output will NOT work, so a generator task is the obvious fix for that trap.
- The install generator (`lib/lockspire/generators/install.ex`) already uses `Calendar.strftime(utc_now, "%Y-%m")` as the KEK id and `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY")` as the env var. `gen.kek` must reuse both so the snippets are identical.
- `keys.reencrypt` already has the correct Repo pattern: `Application.ensure_all_started(:ecto_sql)` then `Ecto.Migrator.with_repo(Config.repo!(), fun, mode: :temporary)`. `Lockspire.Install.RepoRunner.run/2` wraps the same pattern with a safe branch for an already-running repo and redacted errors. `doctor.key_encryption` already uses RepoRunner. The three broken tasks (`client.create`, `doctor.token_format`, `doctor.remote_jwks`) only declare `@requirements ["app.config"]` and never start the Repo.
- `Keys.encryption_status/0` already returns everything the Key protection line needs (`configured`, `current_kek_id`, `legacy_plaintext`, `legacy` count, `by_kek_id`, `unknown_kek`, `undecryptable`, `pending`, `ready?`). KEY-UI-01 is mostly presentation.
- `Config.key_encryption_keyset/0` caches the validated KeySet in `:persistent_term` at boot; `key_encryption!/0` re-validates fresh from app env (used by tasks and status).
- The admin error mapping today collapses `{:error, :key_encryption_not_configured}` into generic copy (v1.43 accepted debt).

## Comparator Takeaways

| Tool | Relevant behavior | Lesson for v1.44 |
|------|-------------------|------------------|
| `mix phx.gen.secret` | Prints one bare value to stdout, no decoration, optional length arg. Designed to be piped or pasted. | Keep `gen.kek` stdout predictable and copyable. But phx.gen.secret prints only the value; operators here also need the id and the config shape, so print a labeled block. |
| Cloak / cloak_ecto | `Cloak.Vault` config uses `tag` + `key: Base.decode64!(...)`. Docs tell you to generate with `:crypto.strong_rand_bytes(32) \|> Base.encode64()` or `mix` one-liner. Old `{:system, "ENV"}` convention was replaced by `init/1` callback that reads env at runtime. There is no generator task. | Adopters expect the one-liner; a task is a small upgrade. Cloak and Phoenix itself moved away from `{:system, ...}` toward `runtime.exs`, so `{:system, "ENV"}` is a convenience, not a convention to lean on. MEDIUM. |
| Rails | `bin/rails db:encryption:init` prints a ready YAML block (primary_key, deterministic_key, key_derivation_salt) with a "add these to your credentials" line. `bin/rails credentials:edit` keeps secrets out of VCS. | Closest prior art for `gen.kek`: print a paste-ready snippet plus a one-line instruction. Rails never writes files on `init`. Copy that. |
| Ory Hydra | `secrets.system` is a list, usually from env (`SECRETS_SYSTEM`). No generator (docs say `export SECRETS_SYSTEM=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom \| head -c 32)`). No status display. | Env-first is the norm for self-hosted auth servers. Env value is read once at process start. |
| Keycloak | Admin console Realm settings > Keys lists providers with priority and status (active/passive/disabled). Encryption of key material is not shown. | Key list pages show state per key; a one-line posture summary above the list is consistent with this. |
| Zitadel | Master key supplied at start (`--masterkey`, `--masterkeyFile`, or `ZITADEL_MASTERKEY` env), exactly 32 bytes. Docs suggest `tr -dc A-Za-z0-9 </dev/urandom \| head -c 32`. No UI status. | Confirms: generate-and-print guidance, env/file sources, read at boot, fail on wrong length. |
| `ecto.migrate`, `phx.gen.*`, `ecto.create` | Ecto tasks declare `@requirements ["app.config"]` and then call `Mix.Ecto.ensure_repo` / `Ecto.Migrator.with_repo`; `phx.gen.*` never touch the Repo. Convention: do not `app.start` a whole host app inside a library task (it boots endpoints and workers). | Fix the three tasks by reusing `RepoRunner` / `with_repo(mode: :temporary)`, not by adding `"app.start"` to `@requirements`. |

## Table Stakes

| Feature | Why Expected | Complexity | Depends On | Notes |
|---------|--------------|------------|------------|-------|
| Fix `lockspire.client.create`, `doctor.token_format`, `doctor.remote_jwks` to start the Repo | A command that works only inside `iex -S mix` is a broken command. `ecto.migrate` sets the bar. | LOW-MED (3 tasks, one shared pattern) | `Lockspire.Install.RepoRunner`, `Config.repo!/0` | Wrap each task body in `RepoRunner.run/2`; map `{:error, :repo_unavailable}` to a `Mix.raise` that names `Config.repo!()` and says "could not start the repo, check database config and that the database is reachable" without echoing the underlying exception (can carry connection details). Pure calls (remote_jwks may only need the Repo for the client lookup; only wrap the DB part) must still work when Repo is already running (RepoRunner handles this). Cover each with a mix-task test that runs with the Repo stopped. Do NOT add `"app.start"`. |
| `mix lockspire.gen.kek` prints a valid fresh KEK | The v1.43 error message and install snippet already tell adopters to generate one by hand; `phx.gen.secret` output is a known wrong-format trap. | LOW | `KeySet` format, install generator id convention | Requirements below. |
| `gen.kek` output round-trips through `KeySet.new/1` | A generator whose output fails validation is worse than none. | LOW | `KeySet` | Test: generated value decodes to exactly 32 bytes and `KeySet.new(keys: [{id, value}], current: id)` is `{:ok, _}`. Use `Base.encode64(:crypto.strong_rand_bytes(32))` (standard base64 with padding, 44 chars), matching the existing error text and install snippet. |
| `{:system, "ENV"}` accepted as a key value in the KEK list | KEK-05. Host that cannot use `runtime.exs` (or prefers declarative config) can name the env var. | LOW-MED | `KeySet.decode_entry/2`, `Config.key_encryption!/0` | See "Resolution timing" below. |
| Admin key generation error names the missing KEK | Today the operator hits generic copy and cannot tell what to do. | LOW | `Admin.Keys` returns `:key_encryption_not_configured`; `keys_live/index.ex` | See copy below. Must be distinguishable from other failures; keep the generic fallback for unknown reasons. |
| Read-only Key protection line on Keys index and show pages | KEY-UI-01. v1.43 made encryption real but invisible in the UI. | MED | `Keys.encryption_status/0`, vocabulary map update, `vocabulary_contract_test` | See states below. |
| Verified publish of lockspire 1.6.0 (Release Please PR #121) | The v1.43 encryption feature is not delivered to adopters until Hex has it. | LOW-MED (process, not code) | Release Please, squash-merge rule, CI Elixir 1.19.5-otp-28 | Verification means: PR squash-merged (title becomes changelog), tag and GitHub release exist, Hex package page shows 1.6.0, a clean-room `mix deps.get` of `{:lockspire, "~> 1.6"}` compiles. Existing phase-68 publish verification doc is the template. |

### gen.kek: recommended behavior

- **Output (stdout):** a labeled block, no ANSI, no prompts:
  1. One header line: `Generated key-encryption key "2026-10" (32 random bytes, base64).`
  2. The runtime.exs snippet using `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY")` with a fail-closed `raise`, **identical** to the install generator's prod block, with the real generated value shown once as the env value to export: `export LOCKSPIRE_KEY_ENCRYPTION_KEY=<base64>`.
  3. A one-line reminder: store it in your secret manager, back it up separately from database backups, and losing it makes encrypted signing keys unrecoverable (links docs/upgrading/signing-key-encryption.md).
- **Flags (keep to three):**
  - `--id <id>`: KEK id, validated against the `KeySet` id pattern (`[A-Za-z0-9._-]{1,32}`); default `YYYY-MM` UTC to match install.
  - `--raw` (or `--quiet`): print only the base64 value, phx.gen.secret style, for `export X=$(mix lockspire.gen.kek --raw)`. This is the one place Rails' `init` and phx.gen.secret conventions combine.
  - `--rotate` (snippet shape only): emits a two-entry `keys:` list with the new id first and `current:` set to the new id, with a comment that the old entry stays until `mix lockspire.keys.reencrypt --check` reports no stranded keys. Optional; cheap since it is only string formatting. Defer if it grows.
- **Does not:** write files, read or modify existing config, touch the Repo, require `app.config`'s repo, or log the value. Requires no running app, so it works in a fresh checkout (`@requirements []` or `["app.config"]` is fine; it needs neither DB nor KEK).
- **Safety:** warn that the printed value lands in terminal scrollback and CI logs; do not run in CI. The key printed is secret material, but this is the one place it is intentionally shown (copy-once), consistent with the product's copy-once secret behavior.
- **Redaction note:** the value must never pass through `Logger`, telemetry or audit. Print via `Mix.shell().info/1` only.

### `{:system, "ENV"}` resolution timing: resolve once at boot (validation time), not per call

Recommendation: resolve inside `KeySet.new/1` so the resolved bytes are in the cached KeySet that `Config.key_encryption_keyset/0` already holds in `:persistent_term`.

Reasons:
1. The existing design caches the KeySet at boot and documents rolling-restart semantics (AR-156-01). Per-call resolution would let a mutated env change behavior mid-run, defeating the fail-fast boot self-check and creating a read path that can start failing at request time.
2. Per-call resolution on every sign/decrypt adds `System.get_env` plus base64 decode plus validation on a hot path for no benefit; env vars are fixed for a process lifetime in releases anyway.
3. Hydra, Zitadel, and Rails all read secret config once at process start.
4. Fail-fast: a missing or empty env var must fail at boot validation naming the **variable name** (not secret) and reason atom (`:env_missing`, `:env_empty`), then fall through the same 32-byte/base64 checks. Mix tasks that call `key_encryption!/0` fresh will resolve at task start, which is also fine.
5. Behavior with an absent block vs an unset env var: if the whole `:key_encryption` block is absent, v1.43 behavior stands (boot, warn, refuse generation). If the block is present but a referenced env var is unset, **fail** (the host declared intent; silently treating it as unconfigured would hide a deploy mistake and could leave `legacy_plaintext: :reject` operators with surprise behavior).
6. Mind compile-time vs runtime: `{:system, ...}` is only meaningful when evaluated at runtime. Document that placing it in `config/config.exs` is fine because it is a tuple resolved at boot, not a call evaluated at compile time, and that `runtime.exs` with `System.get_env` remains the primary recommended form (matching install output).
7. Redaction: the error must name the variable, never any value. The variable name is deliberately safe to show.

## Key protection line: states and copy

PRODUCT.md rules that apply: write for the least technical persona (operator/support), "Key protection" is not yet in the vocabulary map, so add it in the same change. Distinguish unavailable observation from a successful empty result. Do not use "KEK" unexplained; expand as "key-encryption key (KEK)" in a secondary line or info popover for the Security reviewer. Retired-wording risk: avoid "legacy default" and "escape hatch". Consequence text must say what Lockspire actually does.

Add to the vocabulary map:

| Internal or protocol term | UI says | Protocol term shown? |
|---|---|---|
| KEK / `:key_encryption` | encryption key (for signing keys at rest) | "key-encryption key (KEK)" in info popover and the setup-error line only |
| `legacy_plaintext: :reject` | refuses unprotected keys | No |
| `legacy_plaintext: :allow` | still reads unprotected keys | No |

Proposed line states (primary line, plus optional secondary line in smaller text). These are drafts for the roadmap; final copy is subject to the vocabulary test.

| State (from `encryption_status/0`) | Primary line | Secondary / consequence | Tone |
|---|---|---|---|
| Configured, current KEK id X, all rows under X, `:allow` or `:reject` | `Key protection: Private signing keys are encrypted with encryption key "X".` | (`:reject`) `Lockspire refuses to read any unprotected key.` / (`:allow`) `Lockspire would still read an unprotected key if one appeared.` | neutral/positive, with text and an icon, not color alone |
| Configured, some rows under older KEK id (`pending` state `:other_kek`) | `Key protection: N of M signing keys use an older encryption key.` | `Run mix lockspire.keys.reencrypt to move them to "X".` | attention, not alarm |
| Configured, legacy plaintext rows remain (`legacy > 0`) | `Key protection: N signing keys are stored without encryption.` | `Run mix lockspire.keys.reencrypt --dry-run to preview, then without --dry-run to encrypt them.` If `:reject` is on: `Lockspire refuses to sign with these keys until they are encrypted.` | attention; escalated wording only in `:reject` because signing is actually blocked |
| Configured, `unknown_kek` or `undecryptable` rows | `Key protection: N signing keys cannot be read with the configured encryption keys.` | `Add the encryption key they were sealed with back to your configuration. Do not delete these keys.` | error |
| No KEK configured | `Key protection: Not set up. New signing keys cannot be generated until an encryption key is configured.` | `Existing keys keep signing. Run mix lockspire.gen.kek to create one.` | attention (matches v1.43: boot ok, signing ok, generation refuses) |
| Invalid config (`{:invalid_config, _}`) | `Key protection: The encryption key configuration is invalid.` | `Run mix lockspire.doctor.key_encryption for details.` Never echo the exception message (it names config keys; treat as safe but unnecessary in UI). | error |
| Observation unavailable (`:repo_not_started`, `:storage_unavailable`) | `Key protection: Could not check right now.` | Do not render as "all good" or as "0 unprotected"; mirrors the product rule on failed observations. | neutral |
| Zero keys exist yet | `Key protection: No signing keys yet.` (plus the configured/not-configured sentence) | | neutral |

Implementation notes:
- **Cheap on the index page:** `encryption_status/0` scans all key rows. Key tables are tiny (tens of rows) so a per-mount call is fine, but do it once per mount, not per row, and tolerate failure independently of the key inventory (a failed status must not blank the key list).
- **Per-row detail:** the show page can add `Protected by encryption key "X"` / `Not encrypted` per key, derived from the ciphertext prefix without decrypting (v1.43 envelope carries the kek id, and `by_kek_id` already counts it). Differentiator, see below.
- **Read-only:** no buttons. Commands appear as plain text `<code>` (the UI points to a mix task; it never runs one). Matches anti-feature rule from v1.43.
- **Security reviewer vs support:** primary line plain; the technical text (`LSK` envelope, AES-256-GCM, `legacy_plaintext` setting name) goes in an info popover.

### Admin error on key generation with no KEK

Replace the generic string for `{:error, :key_encryption_not_configured}` with a specific one, in the same `generation_error` slot (`role="alert"` already present):

`Could not generate the key: no encryption key is configured, and Lockspire does not store private signing keys unencrypted. Set up an encryption key (run mix lockspire.gen.kek), restart the app, then try again.`

- Keep other reasons on the generic fallback.
- Do not offer a "generate anyway" path (anti-feature).
- Add a LiveView test that asserts the message, and that it contains no key material.
- Map from the reason atom in the LiveView, not by string matching in `Admin.Keys`.

## Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Per-key "Protected by encryption key X" on Key details | No comparator exposes this; gives the Security reviewer proof without a shell. | LOW-MED | Reuse prefix-based kek id derivation from v1.43. Optional for KEY-UI-01; include only if the roadmap has slack. |
| `gen.kek --rotate` two-entry snippet | Makes rotation copy-pasteable; Hydra and Cloak make you hand-edit lists. | LOW | String formatting only. |
| `gen.kek` snippet also prints the `dev.exs`/`test.exs` variant | Aligns with the install output so adopters get both in one place. | LOW | Reuse a shared snippet builder so the install generator and gen.kek cannot drift; add a test asserting both emit the same prod block. |
| Shared "needs the Repo" helper for all DB-touching tasks (and a lint/test that fails if a new task touches Repo without it) | Prevents regression of the exact bug being fixed. | LOW-MED | A test that scans `lib/mix/tasks/*.ex` for modules calling admin/DB APIs without `RepoRunner` or `with_repo` is brittle; prefer a table-driven test that runs each DB task with the Repo stopped. |
| Doctor/Verify mention the admin Key protection state | Single vocabulary across mix and UI. | LOW | Only if wording is shared; avoid duplicating strings across layers. |
| Published-package smoke check (clean-room dep on the Hex release) in the 1.6.0 verification | Proves adopters can actually consume 1.6.0, not just that CI is green. | MED | Reuses clean-room host from v1.43. |

## Anti-Features

| Anti-Feature | Why Avoid | Instead |
|--------------|-----------|---------|
| `gen.kek` writing the key into `config/*.exs`, `.env`, or any file | Puts the lock in version control or beside the data; Rails `db:encryption:init` also only prints. | Print only. |
| `gen.kek` auto-editing `runtime.exs` | Breaks the "host owns config" boundary. | Snippet + instruction. |
| Per-call `{:system, "ENV"}` resolution | Mid-run drift, hot-path cost, defeats boot validation. | Resolve at boot via KeySet. |
| Silent fallback when the env var is unset (treat as unconfigured, or empty key) | Hides deploy mistakes; can leave `:reject` installs confused. | Fail with a message naming the variable. |
| `{:system, ...}` with a default value (`{:system, "X", "default"}`) | Invites a hard-coded fallback KEK in committed config. | No default form. |
| Reading KEK from `secret_key_base` or other config as fallback | Already rejected in v1.43. | n/a |
| `"app.start"` in `@requirements` of the three tasks | Boots the host endpoint and workers from a CLI task; slow, port conflicts, side effects. | `RepoRunner` / `with_repo(mode: :temporary)`. |
| Showing KEK ids as secrets or hiding them | KEK ids are non-secret labels (e.g. `2026-10`); they are needed for operators to reason about rotation. | Show ids, never values. |
| Admin button to generate/rotate/re-encrypt a KEK or "generate unprotected key anyway" | KEK is host infrastructure; unprotected keys defeat CR-01. | Read-only status; point to mix tasks. |
| Alarmist banner on Overview for every non-ideal state | Violates "calm operator workflows" and PRODUCT.md tone. | One line on Keys pages; escalate wording only where signing is actually blocked. |
| Redefining `mix lockspire.doctor.key_encryption` output as a UI source | Couples a CLI formatter to UI. | UI reads `encryption_status/0` directly. |

## Feature Dependencies

```
RepoRunner / with_repo pattern (exists)
    -> fix client.create, doctor.token_format, doctor.remote_jwks

KeySet.new/1 (exists) + install snippet (exists)
    -> gen.kek output format and id convention
    -> {:system, "ENV"} resolution (extends KeySet.decode_entry)
        -> gen.kek snippet may show the {:system, ...} form as an alternative
        -> doctor.key_encryption must treat resolved env the same (reports ids, never values)

Keys.encryption_status/0 (exists)
    -> Key protection line (Index + Show)
        -> vocabulary map entries (same change)
        -> vocabulary_contract_test (enforces)

:key_encryption_not_configured reason (exists)
    -> specific admin generation error (mapping in keys_live/index.ex)
    -> references gen.kek (so gen.kek should land first or in the same phase)

Release Please PR #121 (merged after code lands)
    -> release 1.6.0 verification (must follow all code changes; PR #121 may need regeneration once new feat/fix commits land on main)
```

Ordering note for the roadmap: ship the code fixes first, then verify the publish. A Release Please PR opened before these commits will not include them unless it is refreshed by the new merges, so decide explicitly whether 1.6.0 is cut from PR #121 as-is (v1.43 content only) or after the v1.44 fixes (likely 1.6.1 or 1.7.0 for the new feat commit). Flag this as a decision for requirements.

## MVP Recommendation

Prioritize (all in v1.44):
1. Repo-start fix for the three tasks (bug fix, highest adopter pain, `fix:` commit).
2. `gen.kek` with `--id` and `--raw`, output round-trip tested against `KeySet`.
3. `{:system, "ENV"}` boot-time resolution with fail-fast variable-named errors.
4. Admin key generation error naming the missing KEK.
5. Key protection line with the states above (primary line states: protected, older key, unprotected rows, unreadable, not set up, check unavailable).
6. Verified 1.6.0 publish (last).

Defer:
- `gen.kek --rotate` and per-key "Protected by X" detail: nice, not needed to close the v1.43 debt.
- Overview-level posture banner: not requested; risks alarm fatigue.
- Machine-readable (`--format json`) for gen.kek: the `--raw` flag covers scripting.
- KMS/Vault provider (KEK-04): remains deferred.

## Complexity Summary

| Item | Complexity | Risk |
|------|-----------|------|
| Task Repo fix (3 tasks) | LOW-MED | Tests need the Repo stopped; avoid breaking the already-running-Repo case |
| gen.kek | LOW | Drift from install snippet; use a shared builder |
| `{:system, "ENV"}` | LOW-MED | Redaction of errors; interaction with `:persistent_term` cache and `--check`; doctor output |
| Admin KEK error | LOW | None |
| Key protection line | MED | Vocabulary contract test; failure-isolated status; copy review for least technical persona |
| 1.6.0 verification | LOW-MED | Release Please timing relative to new commits; squash-merge title |

## Sources

- Repo (HIGH): `/Users/jon/projects/lockspire/lib/lockspire/config.ex`, `lib/lockspire/security/key_encryption/key_set.ex`, `lib/lockspire/install/repo_runner.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/generators/install.ex`, `lib/mix/tasks/lockspire.keys.reencrypt.ex`, `lib/mix/tasks/lockspire.doctor.key_encryption.ex`, `PRODUCT.md`, `.planning/PROJECT.md`, `.planning/research/v1.43-key-encryption/FEATURES.md`.
- Comparator behavior (MEDIUM, from training knowledge, not re-fetched this session): Phoenix `mix phx.gen.secret`; Cloak / cloak_ecto docs (vault config, key generation, move from `{:system, ...}` to runtime `init/1`); Rails Active Record Encryption guide (`bin/rails db:encryption:init`, `credentials:edit`); Ory Hydra `secrets.system` docs; Zitadel masterkey docs; Keycloak Realm Keys admin console; Ecto `ecto.migrate` and `Ecto.Migrator.with_repo/3` docs.
