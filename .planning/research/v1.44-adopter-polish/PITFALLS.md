# Domain Pitfalls: Adopter Polish and Verified 1.6.0 (v1.44)

**Domain:** Adding repo-starting Mix tasks, KEK generation, `{:system, "ENV"}` KEK resolution, admin "Key protection" line, and a Hex 1.6.0 publish/verify to an existing embedded Phoenix OAuth/OIDC library
**Researched:** 2026-10-18
**Overall confidence:** HIGH for repo-specific findings (read from code and Phase 143 records); MEDIUM for general Mix/OTP behavior (established practice, not re-verified against docs this session)

Phase labels are suggested ownership; map to roadmap numbers later:
**P-TASKS** (repo-starting tasks), **P-KEK** (gen.kek + `{:system, ...}` resolution), **P-ADMIN** (Key protection line + missing-KEK error), **P-DOCS** (docs.verify, guides), **P-RELEASE** (merge #121, publish, verify 1.6.0).

## Repo facts verified (drive the pitfalls below)

- `lib/mix/tasks/lockspire.client.create.ex` and `lockspire.doctor.token_format.ex` call `Clients.*` / admin reads directly and declare no repo startup. This is the bug the milestone fixes: they only work when something else started the repo.
- A safe pattern already exists: `lib/lockspire/install/repo_runner.ex` (`Lockspire.Install.RepoRunner.run/2`). If `Process.whereis(repo)` is a pid it calls the function directly; otherwise it runs `Ecto.Migrator.with_repo(repo, fun, mode: :temporary)`. Its moduledoc states `with_repo` restarts the pool of an already-running repo. It rescues and returns `{:error, :repo_unavailable}` without leaking connection details. `doctor.key_encryption` uses it.
- `lockspire.keys.reencrypt.ex` does NOT use RepoRunner. It calls `Ecto.Migrator.with_repo` directly (line ~112), and `lockspire.test.setup.ex` does likewise. Copying either for the new tasks would reintroduce the live-node hazard. The reencrypt task's moduledoc already says to use `bin/app rpc` on a running release because Mix does not exist there.
- `Lockspire.Config.key_encryption!/0` (lib/lockspire/config.ex ~254) reads `Application.get_env(:lockspire, :key_encryption)` at call time, validates via `KeySet.new/1`, and raises `ArgumentError` naming config keys only. `Lockspire.Application` (lines ~31-35) caches the resolved `%KeySet{}` in `:persistent_term` at boot, or `:unconfigured`. `key_encryption_keyset/0` falls back to fresh validation on a cache miss.
- `KeySet.new/1` (`lib/lockspire/security/key_encryption/key_set.ex`) accepts `[keys: [{id, b64}], current: id, legacy_plaintext: :allow | :reject]`. It requires `is_binary(b64)` per entry, decodes with `Base.decode64(padding: false)`, then url64, then padded fallbacks, requires exactly 32 bytes, rejects repeated-byte keys (`weak_key_material`), and rejects duplicate material. The id must match `~r/\A[A-Za-z0-9._-]{1,32}\z/`. Unknown option keys give `:unknown_option`.
- `fail_key_encryption!` already tells users to run `openssl rand -base64 32`, notes `mix phx.gen.secret` will not work, and says "set it in config/runtime.exs". The new `gen.kek` output and this message must not drift.
- `Lockspire.Redaction` already lists `:kek` / `"kek"`. The key_encryption telemetry events carry `current_kek_id`. `docs/telemetry.md:104` documents `[:lockspire, :key, :legacy_read]` with `kid` metadata.
- `Admin.Keys.encryption_status/0` returns counts (`total`, `by_kek_id`, `pending`, `stranded_retired`) by scanning all signing-key rows. It also checks `Process.whereis(repo)` and returns `{:error, :repo_not_started}` otherwise.
- `test/lockspire/web/live/admin/vocabulary_contract_test.exs` globs `lib/lockspire/web/live/admin/**/*.{ex,heex}`, `admin_layout_live.ex` and `components/admin_components.ex`. It substring-matches (downcased, per line) every phrase in the "Retired wording" table in `PRODUCT.md`. It only reads `PRODUCT.md`; it never checks that new terms were added to the vocabulary map.
- `mix.exs:141`: `"docs.verify": ["docs --warnings-as-errors"]`, part of `release.preflight` (line 145). `mix ci` has its own alias (line 146).
- PR #121 is open: `chore(main): release lockspire 1.6.0`, branch `release-please--branches--main--components--lockspire`, touching `.planning/RELEASE-TRAIN.md`, `.release-please-manifest.json`, `CHANGELOG.md`, `mix.exs`.
- `.planning/RELEASE-TRAIN.md` rules: `workflow_dispatch` publishes one exact 40-hex SHA that must equal current `origin/main` and be backed by a successful canonical CI run. Release Please metadata is "not publication proof". The baseline section is machine-edited by Release Please (`x-release-please-version` markers).
- Phase 143 record (`.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`): run 37689835922 failed before upload at "Mint scoped release freeze token" (missing App id/key secrets, then an unsupported pinned action input fixed in PR #119). Its terminal receipt was not retained because a docs-stage value `absent` did not match the receipt schema (`passed|failed|not_run|unknown`); fixed in PR #120. The later run 37795671282 published 1.5.1, verified checksum `c13dabdd...`, HexDocs, GitHub release and clean-room install, yet the overall run still showed failure from evidence retention. Approval for the failed run was not reused; a one-use `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` variable was set and then deleted; auto-merge was disabled during the attempt and restored afterward.

---

## Critical Pitfalls

### C1: Task starts the repo with `with_repo`, bounces the pool of a host that already runs it
**What goes wrong:** New tasks (`client.create`, `doctor.token_format`, `doctor.remote_jwks`) copy the `Ecto.Migrator.with_repo` call from `keys.reencrypt` or `test.setup`. In dev, hosts commonly run `iex -S mix phx.server` and call the task through `Mix.Task.run` or `mix run`, or the app is already started via `app.start`; `with_repo` then stops and restarts the running repo's pool, killing in-flight connections. In an umbrella, `Mix.Task.run` from the root recurses into children and can run the task once per app, each starting the repo.
**Why it happens:** Two in-repo examples show the naive form; `RepoRunner` is `@moduledoc false` and the newest tasks (`client.create`) predate it.
**Consequences:** Dropped requests on a live dev server, "already started" errors, or flaky tests that call `Mix.Task.run("lockspire.client.create", ...)` inside a DataCase sandbox (the sandbox owner connection is lost).
**Prevention:** Route every new repo-touching task through `Lockspire.Install.RepoRunner.run/2` (or promote a shared helper). Do not add a second implementation. Keep `mode: :temporary` so a failure in the temp repo does not take down the VM. Do not pass `pool_size: 1` blindly: `client.create` may call functions that open a transaction plus a nested read and need at least 2 connections (the default 10 is fine; test with the host's configured value, and note `with_repo` accepts `pool_size:` overrides, which is only worth using for migrations). Add a test that starts the repo first and asserts the pool pid is unchanged after the task runs, and a test with the repo stopped asserting it starts and is stopped again.
**Detection:** `git grep "Ecto.Migrator.with_repo" lib/mix` returns anything other than `RepoRunner` and the pre-existing reencrypt/test.setup sites; "Repo already started" or `:already_started` in task output; DataCase tests that hang or raise `DBConnection.OwnershipError`.
**Owner:** P-TASKS.

### C2: `RepoRunner` rescues everything, hiding the real task failure
**What goes wrong:** `RepoRunner.run/2` has a blanket `rescue`/`catch` returning `{:error, :repo_unavailable}`. For read-only doctors this is intended. For `client.create`, a changeset error, a unique-constraint violation, or a bug inside `Clients.register_client/1` raised inside `fun` is reported as "repo unavailable", sending the operator to debug a database that is fine. Worse, a half-completed write is reported as a connection problem and the operator retries, creating duplicate clients.
**Why it happens:** The helper was written for diagnostics where "never raise" is the contract.
**Consequences:** Misleading error text; duplicate or partial client creation on retry; the task exits 0 or the wrong non-zero code.
**Prevention:** Have the work function return tagged tuples only (`{:ok, client} | {:error, changeset_or_reason}`) and let `RepoRunner` distinguish "could not start" from "fun returned". If you must change it, add a variant that re-raises errors from `fun` and only converts startup failure. Keep the writing task fail-loud (non-zero exit via `Mix.raise`) and the doctors fail-soft (exit 0 with a message), matching their existing moduledocs ("never exits non-zero"). Never print the client secret on retry paths; print it once on success and say it cannot be shown again.
**Detection:** Test `client.create` with an invalid redirect URI and with a duplicate `--client-id`; the output must name the validation error, not the repo.
**Owner:** P-TASKS.

### C3: Task assumes Mix exists in a release
**What goes wrong:** Docs tell adopters to run `mix lockspire.client.create` in production. Releases have no Mix, no source tree and no `Mix.shell()`. The v1.43 reencrypt task already documents the `bin/app rpc` route; the new tasks have none.
**Why it happens:** Mix tasks are the easiest DX but are dev/CI-only by construction.
**Consequences:** Adopters cannot create the first client or run the doctors in prod; or they start a second VM with `bin/app eval` that boots the whole supervision tree (Oban, endpoint port conflict).
**Prevention:** Keep the task a thin shell over a public, documented function in `Lockspire.Admin.*`/`Lockspire.Clients` that a release can call via `bin/app rpc`. Document the rpc form beside the Mix form, and state that tasks need Mix and a compiled dev/test env. For doctors, make `Lockspire.Install.Verify`-style functions callable without `Mix`. The `Mix.shell()` calls must stay in the task layer only.
**Detection:** `Mix.` references inside non-task modules; docs that show only `mix ...` for an operation that is plausible in production.
**Owner:** P-TASKS, doc text in P-DOCS.

### C4: Task runs with config not loaded or with the wrong env
**What goes wrong:** `@requirements ["app.config"]` loads config but does not start apps. If a new task omits it, `Lockspire.Config.repo!()` raises on missing config. If it uses `app.start` instead, it boots the endpoint and Oban (port clash, job processing from a CLI call). `config/runtime.exs` is evaluated by `app.config` so `System.get_env` is available, but only for the current `MIX_ENV`; running `mix lockspire.client.create` in `dev` creates the client in the dev database, which adopters misread as "production".
**Prevention:** Copy `@requirements ["app.config"]` from `doctor.key_encryption` and `keys.reencrypt`; never `app.start`. Start only `:ecto_sql` and the repo (via RepoRunner). Print the repo module and database name (not the URL or password) on success so the operator can see which database was touched. Note that Oban is a Lockspire dependency, so also avoid starting Oban in a task.
**Detection:** Task output includes "Endpoint running"; job rows processed by a CLI invocation.
**Owner:** P-TASKS.

### C5: `gen.kek` leaks the key
**What goes wrong:** (a) Printing the key with `Mix.shell().info` is fine for stdout, but a task that also logs through `Logger`, emits telemetry, or echoes the `argv` writes the secret to log aggregation. (b) A `--key` or `--write` flag puts the value in shell history or `ps` output. (c) Auto-writing into `config/runtime.exs` or `config/dev.exs` puts a real key in a committed file. (d) Printing inside a `Mix.raise` message or `inspect(%KeySet{})` leaks via CI output. (e) The CI/log redaction in `Lockspire.Redaction` only matches known keys; a bare base64 line is never redacted.
**Why it happens:** Generators tend to be "helpful" and write files or print copy-paste snippets with the secret embedded in a config-looking line that ends up pasted into `config/config.exs`.
**Consequences:** KEK in git history means every signing key in every DB backup is decryptable; it cannot be un-leaked, only rotated via the 5-step flow.
**Prevention:**
- Take no secret-bearing arguments. Output exactly the key material on a labelled line (or only the key with `--raw`) to stdout; send guidance text to stderr (`Mix.shell().error` or `IO.puts(:stderr, ...)`) so `mix lockspire.gen.kek > file` or `$(...)` captures only the key.
- Never write files. Print the recommended snippet using the `{:system, "LOCKSPIRE_KEK"}` form with the env var name, not the value, plus `export LOCKSPIRE_KEK=...` guidance that tells users to store it in a secret manager, not shell rc files; suggest a leading space or `HISTCONTROL=ignorespace` only as a footnote.
- No telemetry event, no Logger call, no Mix.Task result struct containing the key.
- Generate the `--id` (key id) only from the regex `[A-Za-z0-9._-]{1,32}`; default a date-based id like `kek-2026-10`. Validate before printing.
- Test: capture stdout and stderr separately; assert the key is on stdout only, and assert that `ExUnit.CaptureLog` of the run is empty.
**Detection:** `Logger` or `:telemetry.execute` in `lockspire.gen.kek.ex`; guidance text on stdout; the key appearing in `argv`.
**Owner:** P-KEK.

### C6: `gen.kek` output not accepted by `KeySet.new/1`
**What goes wrong:** Wrong length (`mix phx.gen.secret` style 64-char strings, hex encoding, 16 or 48 bytes), wrong alphabet, or a format that parses by luck. The parser accepts standard base64, url-safe base64 and padded forms, so a bug in the generator can slip through if only "looks like base64" is tested. Also: `:crypto.strong_rand_bytes(32)` is correct, but `:rand.bytes/1`, `Enum.random`, `:erlang.unique_integer` or a seeded `:rand` are not cryptographically strong; they pass every format check. Weak-material checks only catch repeated bytes.
**Why it happens:** The `check_strength` guard gives false comfort; randomness cannot be tested statistically.
**Prevention:** Generate with `:crypto.strong_rand_bytes(32)` and `Base.encode64/1` (padded, standard alphabet, identical to `openssl rand -base64 32` so docs and the existing `fail_key_encryption!` message remain true). Make the generator call `KeySet.new(keys: [{id, b64}], current: id)` on its own output before printing and refuse to print on `{:error, _}`. Round-trip test: `gen.kek` output fed into `Lockspire.Config.key_encryption!/0` via `Application.put_env` yields a `%KeySet{}` with `byte_size == 32`. A grep-style test that the module contains `strong_rand_bytes` and not `:rand.` is cheap insurance. Print two distinct invocations and assert they differ.
**Detection:** `Base.decode64(key) |> byte_size != 32`; new randomness primitive in the diff.
**Owner:** P-KEK.

### C7: `{:system, "ENV"}` resolved too early (compile time or config.exs)
**What goes wrong:** If the tuple is resolved with `Application.compile_env` or in `config/config.exs`, `System.get_env` runs on the build machine: either nil, or the build host's value baked into the release. If the KEK is read in `config/config.exs`/`prod.exs`, `mix release` bakes it into `sys.config`, so a release image contains the key. The repo currently has no `Application.compile_env` in `lib/` (v1.43 finding); resolution must keep it that way.
**Why it happens:** Phoenix hosts keep most config in `config.exs`; `{:system, ...}` is a legacy idiom that people expect to resolve itself.
**Consequences:** KEK in the image layer or release tarball; or builds silently use "no key", and the node boots in `:unconfigured` mode writing plaintext keys.
**Prevention:** Resolve strictly at runtime, inside `KeySet.new/1` (or a pre-step feeding it), reading `System.get_env/1` when the entry's second element is `{:system, name}`. Keep the call path through `Config.key_encryption!/0` so the boot-time `:persistent_term` cache in `Lockspire.Application` and the fresh-validation path both use it. Docs must say: put it in `config/runtime.exs`, same as the existing guidance. Add a guard: if a `{:system, ...}` tuple is found in compile-time config contexts, nothing can detect it, so document it and rely on the runtime resolution being the only implementation. Do not use `compile_env`, and assert no new `compile_env` appears in `lib/` (`rg compile_env lib`).
**Detection:** `compile_env` or `System.get_env` in `config/config.exs`; image scan finds the key in `releases/*/sys.config` or `runtime.exs` output.
**Owner:** P-KEK.

### C8: Env var missing: silent fallthrough vs boot-time failure
**What goes wrong:** Three bad outcomes. (1) Missing env treated as `nil` and `KeySet.new` returns `:invalid_key_entry` with a message that does not name the variable, so operators cannot tell which of three keys is unset. (2) The config is present but the env var is empty at boot on one node, which falls into `:unconfigured` and writes new keys as plaintext when `legacy_plaintext: :allow`. (3) The env var exists at boot but `Config.key_encryption_keyset/0` re-resolves it at use via the fresh-validation fallback, after an operator mutated it; the persistent_term copy and fresh result then differ.
**Why it happens:** Existing error shape is `{:error, {config_key, reason}}` with atoms only (secret-free by design); a variable name is not secret but the design discourages interpolation.
**Prevention:** Fail at boot (the current `Lockspire.Application` path), never at first use. A configured `:key_encryption` block with an unresolved env var must be an error, never `:unconfigured`: add reasons such as `:env_var_missing` and `:env_var_empty` and put the variable NAME (never the value) in the message, e.g. "environment variable LOCKSPIRE_KEK is not set". Treat the name as a config value that is safe to print only after validating it matches `\A[A-Z_][A-Z0-9_]*\z`, so a mistaken tuple holding the secret as the "name" is not echoed. Resolve once at boot and use the cached `KeySet`; make the fresh-validation path used only by tasks/doctors. For rotation, document that env changes need a restart.
**Detection:** A node started without the variable passes boot; `doctor.key_encryption` says "not configured" instead of "configured but unresolved".
**Owner:** P-KEK, with the admin error wording in P-ADMIN.

### C9: Resolved key values leak through inspect, errors, crash dumps, and telemetry
**What goes wrong:** Resolution produces a plain `%KeySet{keys: %{id => <<32 bytes>>}}`. Anything that inspects the struct, Application env, a `Mix.raise` with `inspect(config)`, a Plug.Debugger/LiveView crash page, an `erl_crash.dump` (v1.43 noted one on disk), or an Oban job argument shows the raw binary. A `{:system, name}` tuple left unresolved in app env is safe; the resolved binary is not, and a helper that writes the resolved value back via `Application.put_env` makes it visible to `Application.get_all_env(:lockspire)` and to observer/remote_console.
**Prevention:** Never write resolved keys back to Application env; hold them only in `:persistent_term` (existing) and the struct. Add `@derive {Inspect, except: [:keys]}` to `KeySet` (`inspect` shows ids only), and test `inspect(keyset)` does not contain the Base64 or raw bytes. Never include the env var's value in an `ArgumentError`. Keep `Redaction` coverage for `"kek"` and add the actual env var name pattern (`*_KEK`) only if you also redact values by key match, which the current approach does not do for raw binaries; do not rely on it. Test error paths: set the env to a short string and a garbage string, capture `Exception.message/1`, assert the secret substring is absent.
**Detection:** `inspect(keyset)` output contains `<<` binaries; grep CI logs for the test KEK.
**Owner:** P-KEK.

### C10: Hex publish is irreversible; verification targets the wrong thing
**What goes wrong:** Hex versions cannot be republished (a retirement or revert window of about an hour applies, but the version number is consumed). Publishing the wrong SHA or a tarball that differs from what CI built consumes 1.6.0 for good. Phase 143 shows the real hazards: the publish job can fail before upload, so contemporaneous public queries correctly showed "no 1.5.1"; and a later run's overall red status came only from evidence retention, not the artifact. Reading the red run as "not published" (or the green receipt as "published") are both wrong without a public query.
**Why it happens:** The release lane is a complex protected workflow (App token, environment approval, exact-ref dispatch, manifest, receipt), and status colour is not artifact truth.
**Consequences:** Burned version, mismatch between tag, CHANGELOG, `mix.exs` and the Hex tarball, or a false "release verified" claim in `RELEASE-TRAIN.md`.
**Prevention:**
- Verify from public sources, independently of the workflow: `GET https://hex.pm/api/packages/lockspire/releases/1.6.0` for the `checksum`, HexDocs `/lockspire/1.6.0`, the `lockspire-v1.6.0` release and tag. Compare the public checksum to `.artifact.sha256` in the release manifest (the workflow does at release.yml ~202/515), and to your own `mix hex.build --unpack`/`shasum -a 256` of the tarball. Download the tarball from `repo.hex.pm/tarballs/lockspire-1.6.0.tar` and hash those exact bytes.
- Dispatch only the exact 40-hex SHA equal to current `origin/main` with green canonical CI on that SHA. Do not merge anything to `main` between merging #121 and dispatching, or the SHA check fails (and, if a later commit is a `feat`, Release Please opens a further PR).
- Record the result in a dated RESULT file with run ids, SHA, checksum and observation time, as 143 did; distinguish "run status" from "artifact status".
- Do not reuse an approval for a failed run; set the one-use authorized-SHA variable only for the attempt and delete it afterward, verifying absence.
**Detection:** Hex API returns 404 for 1.6.0 while the run is green; checksum mismatch; tag points to a different SHA than the published source.
**Owner:** P-RELEASE.

### C11: Merging #121 at the wrong moment or with stale content
**What goes wrong:** PR #121 was generated before v1.43 closeout and the v1.44 work. Merging it blindly: (a) leaves CHANGELOG entries that omit later commits; (b) if v1.44 `feat`/`fix` commits land first, Release Please rewrites the PR (possibly still 1.6.0 since it is the next minor, but its changelog now includes tasks that are not yet verified); (c) if unrelated commits land after the merge, the exact-ref dispatch rule fails. The AGENTS memory also says always squash-merge; a merge-commit or rebase of a normal PR changes the changelog line Release Please reads.
**Prevention:** Decide the order up front. Recommended: merge #121 and verify 1.6.0 first as its own phase (it ships v1.43 key encryption, already merged), then do v1.44 code work, which will ship in 1.6.1 or 1.7.0 via a new release PR. Do not mix "verify the published thing" with "add features to it". If the order is reversed, re-read the regenerated PR diff (`.release-please-manifest.json`, `mix.exs` version, `CHANGELOG.md`, the `x-release-please-version` markers in `RELEASE-TRAIN.md`) before merging. Check the version in `mix.exs` equals the manifest, the CHANGELOG heading and the planned tag `lockspire-v1.6.0`. Note the `autorelease:` label advancing is done by the publish job (#78); confirm the PR is labelled `autorelease: tagged` after publish, or Release Please stops proposing further releases.
**Detection:** `git diff` of PR #121 vs `main` shows version drift; a second release PR is opened; "untagged, merged release PRs outstanding" in Release Please logs.
**Owner:** P-RELEASE.

### C12: Clean-room install verified against a path or cache, not Hex
**What goes wrong:** The clean-room host uses `{:lockspire, path: "../.."}` or a locally built tarball, or Hex serves a cached older package. It passes while the public package would fail (missing `files:` entries in `package()`, e.g. `priv/repo/migrations`, new `lib/mix/tasks/*`, templates for the installer).
**Prevention:** The consumer must depend on `{:lockspire, "== 1.6.0"}` fetched from hex.pm in a directory outside the repo with an empty `deps/`, `~/.hex` caches cleared or `mix deps.get --only` on a fresh `HEX_HOME`, and `mix deps` showing the Hex checksum equal to the published one. Assert `mix hex.info lockspire 1.6.0`. Then run the installer, `mix lockspire.verify`, the new tasks, and a boot with `:key_encryption` set. Check the tarball file list contains each new task file (`mix hex.build --unpack`). Bandit stays a host-only dependency.
**Detection:** `mix.lock` has a `path:` source; `deps/lockspire/.hex` absent; `deps/lockspire/lib/mix/tasks/` missing a new file.
**Owner:** P-RELEASE.

---

## Moderate Pitfalls

### M1: Admin "Key protection" line leaks or over-discloses
**What goes wrong:** Showing the current KEK id, the list of known ids, per-id row counts, or an env var name on a page visible to every operator role gives an attacker with admin read access a rotation map (which old KEK still protects which rows). `kid` is already public (JWKS); the KEK id is not.
**Prevention:** Show a status word and at most the current KEK id (an operator label, not secret) on the single Keys page; keep per-id counts and pending lists in the `doctor` task and the reencrypt `--check` output. Never show the env var value; show its name only if a design decision says so, and treat the name as non-secret but not necessary. Reuse the `Redaction` allowlist path; add a test rendering the page with a known KEK and asserting the raw key and its Base64 are absent. Keep it read-only (no buttons).
**Owner:** P-ADMIN.

### M2: Count queries on every page load
**What goes wrong:** `Admin.Keys.encryption_status/0` scans all signing-key rows and, via `status_rows`, decodes envelope headers. Calling it from each LiveView mount, and again on each `handle_params`/reconnect, repeats it. Key tables are small (tens of rows), but LiveView mounts twice (static + connected) and the page may be polled or patched.
**Prevention:** Prefer a derived status that needs no DB: config-only (`Config.key_encryption_keyset/0`, from `:persistent_term`) answers "protected / not configured / legacy plaintext allowed". Only if a DB-backed "N keys pending re-encryption" is wanted, compute it once in the connected mount (guard with `connected?(socket)`), use a single `COUNT` grouped query or the already-loaded key list on the page, and never run it in the static render. Do not hit `ensure_repo_started` -> `{:error, :repo_not_started}` as an unhandled case: render a calm "status unavailable" instead of crashing the page.
**Detection:** Ecto telemetry shows two identical scans per page view; a test with `Repo` query count assertion.
**Owner:** P-ADMIN.

### M3: Vocabulary contract and copy
**What goes wrong:** The contract test fails on a substring match against any retired phrase (case-insensitive, per line, including inside HEEx attributes and comments). New copy using words like "encrypted at rest" may hit a retired entry, or technical words ("KEK", "envelope", "AES") reach the least technical persona. Conversely the test does not enforce that new terms are in the map, so a missing entry passes silently and drifts.
**Prevention:** Before writing, read `PRODUCT.md` personas and vocabulary map (per AGENTS.md). Add "Key protection" and the missing-KEK concept to the map in the same change, and any replaced phrase to the retired table. Write the admin error as plain action language ("Signing keys cannot be unlocked because the protection key is missing. Ask whoever runs the app to set it up.") with the technical name and fix steps kept in docs and the task output. Run `mix test test/lockspire/web/live/admin/vocabulary_contract_test.exs` early. Describe what Lockspire does (AGENTS.md: "not what a setting's name implies"): e.g. "Private signing keys are stored encrypted" only when true for all rows, else say "N keys still stored unencrypted".
**Owner:** P-ADMIN.

### M4: Admin error for a missing KEK unreachable, or too loud
**What goes wrong:** When the KEK is missing, boot fails (v1.43 fail-fast), so the admin never renders the error; the error only appears for runtime-detected cases (key rows encrypted under an id not in `:keys`, `:unknown_kek`). Designers write copy for a state the app cannot reach, and miss the reachable one.
**Prevention:** Enumerate reachable states before writing: unconfigured and healthy, configured, encrypted rows with unknown KEK id, legacy rows pending, repo unavailable. Test each against a LiveView render. Map `{:error, :unknown_kek}` / decryption failure to the admin message without echoing the id of the missing KEK unless it is deemed fine (it is a label, but keep it off by default for non-owner roles).
**Owner:** P-ADMIN.

### M5: New public functions break `docs.verify` (warnings-as-errors)
**What goes wrong:** `mix docs --warnings-as-errors` fails on: `@doc` text referencing hidden or undefined modules/functions (`Lockspire.Install.RepoRunner` is `@moduledoc false`, so a public `@doc` linking it as `` `Lockspire.Install.RepoRunner` `` warns), `t:` types referencing private types, extras files with broken relative links or anchors (e.g. new sections in `docs/install-and-onboard.md`), and `@spec` types not exported. Mix task `@moduledoc` text is rendered too; code fences with auto-linked `Mod.fun/arity` that do not exist warn. Hidden modules (`@moduledoc false`) are skipped, so mark internal helpers that way.
**Prevention:** Run `mix docs.verify` (not `mix docs`) after each doc-touching change, on the CI Elixir (1.19.5-otp-28 per project memory; local 1.20.4 emits type warnings that fail warnings-as-errors). Use backticks without auto-link syntax for hidden modules. Put new public API under an existing documented group in `mix.exs` `docs:` if groups are configured. Check the extras list includes any newly added guide, or the guide is orphaned.
**Detection:** `warning: documentation references module "..." but it is hidden` in `mix docs` output.
**Owner:** P-DOCS (checked in every phase that adds a public function).

### M6: Doc examples drift from behavior
**What goes wrong:** `docs/install-and-onboard.md:151` shows a `:key_encryption` config; `fail_key_encryption!` repeats the `openssl` command; `docs/saas-adoption-recipe.md:35` shows `mix lockspire.client.create` flags. Changing the task flags, adding `{:system, ...}` or `gen.kek` without updating all three leaves contradictory instructions. Project priorities list "executable docs".
**Prevention:** One canonical snippet per concept; make the error message point to `mix lockspire.gen.kek` first and `openssl` as the alternative. Where an executable docs test exists (check `scripts/` and `test/` for doc snippet tests), extend it with the new command output.
**Owner:** P-DOCS.

### M7: Doctor tasks changing exit semantics
**What goes wrong:** `doctor.token_format` promises "never raises, never exits non-zero". Starting the repo can fail; if the new startup error path raises, the contract breaks and CI scripts that call the doctor in a pipeline start failing, or scripts treat exit 0 as healthy when the DB was unreachable.
**Prevention:** Keep the rule: report content problems with exit 0; but a database that could not be reached should print one calm line and be distinguishable (consistent with `doctor.key_encryption`, which already treats `RepoRunner` errors). Decide and document once, and test it for all three doctors.
**Owner:** P-TASKS.

---

## Minor Pitfalls

### m1: Migration lock and pending migrations
`with_repo` does not run migrations, but a client created before migrations are applied fails with an undefined-table error that `RepoRunner` converts to `:repo_unavailable`. Detect "relation does not exist" and say "run migrations first", or reuse `Lockspire.Install.Verify` checks.

### m2: Test isolation of Mix tasks
Tasks that call `Mix.shell()` need `Mix.shell(Mix.Shell.Process)` and `Mix.Task.reenable/1` in tests; otherwise the second invocation is a no-op and tests pass vacuously. Run them with `async: false`.

### m3: `OptionParser` strict mode and secrets in argv
Do not accept `--client-secret` for `client.create`; secrets are generated and shown once. Verify the existing switches do not already accept one.

### m4: Windows and zsh quoting in docs
Docs that show `export LOCKSPIRE_KEK="$(mix lockspire.gen.kek --raw)"` break if guidance text goes to stdout (see C5). Show the command and test the `--raw` form.

### m5: Version bump drift outside Release Please
Hand-editing `mix.exs` `version` or the manifest to "prepare" 1.6.0 conflicts with Release Please and breaks the `x-release-please-version` markers; only Release Please changes them.

### m6: Evidence retention schema
Phase 143's receipt failure came from a stage value outside the schema enum. Any edit to the release workflow or receipt jobs must run the receipt validator against a fixture for every stage state (`passed`, `failed`, `not_run`, `unknown`) before a real dispatch.

---

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| P-TASKS: client.create, doctors start repo | C1 pool bounce on a running host; C2 blanket rescue hides write errors; C3 no release path; C4 wrong env/app.start; M7 exit semantics | Use `RepoRunner` (extend to separate startup from work failures); `@requirements ["app.config"]`; public function + rpc docs; test with repo already running and stopped |
| P-KEK: gen.kek | C5 leaks via logs/history/files; C6 wrong length or weak RNG | `strong_rand_bytes(32)` + `Base.encode64`; self-validate through `KeySet.new/1`; key on stdout only; no file writes, no telemetry |
| P-KEK: `{:system, "ENV"}` | C7 compile-time resolution; C8 missing env handled silently; C9 value leakage | Runtime resolution inside KeySet/Config only; boot-time failure naming the variable; `@derive {Inspect, except: [:keys]}`; never `put_env` resolved values |
| P-ADMIN: Key protection line, missing-KEK error | M1 over-disclosure; M2 repeated scans; M3 vocabulary; M4 unreachable states | Config-derived status first; connected-mount only for counts; update `PRODUCT.md` map; run vocabulary contract early |
| P-DOCS | M5 `docs.verify` failures; M6 doc drift | Run `mix docs.verify` on CI Elixir; single canonical snippets |
| P-RELEASE: merge #121, publish 1.6.0 | C10 irreversible publish and status vs artifact truth; C11 merge order and stale SHA; C12 clean-room not from Hex; m6 receipt schema | Release first, features after (or re-read the regenerated PR); public Hex checksum compare; exact-SHA dispatch with no intervening merges; clean-room `{:lockspire, "== 1.6.0"}` from fresh HEX_HOME; dated RESULT file |

## Ordering recommendation

Do P-RELEASE (merge #121 and verify 1.6.0) before P-TASKS/P-KEK/P-ADMIN land on `main`. Reason: the exact-ref dispatch rule requires the published SHA to equal `origin/main`, and 1.6.0 already contains v1.43 only. Mixing unverified v1.44 code into the same release adds nothing to the 1.6.0 claim and widens what the clean-room verification must cover. If the roadmap prefers shipping the polish in 1.6.0, then the release phase goes last and must re-read the regenerated release PR (C11).

## Sources

- Repo (HIGH): `lib/install/repo_runner.ex`, `lib/mix/tasks/lockspire.{client.create,doctor.token_format,doctor.key_encryption,keys.reencrypt,test.setup}.ex`, `lib/lockspire/config.ex`, `lib/lockspire/application.ex`, `lib/lockspire/security/key_encryption/key_set.ex`, `lib/lockspire/admin/keys.ex`, `lib/lockspire/redaction.ex`, `mix.exs` (aliases), `test/lockspire/web/live/admin/vocabulary_contract_test.exs`, `docs/install-and-onboard.md`, `docs/telemetry.md`
- Release records (HIGH): `.planning/RELEASE-TRAIN.md`, `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`, `.github/workflows/release.yml`
- Prior pitfalls (HIGH): `.planning/research/v1.43-key-encryption/PITFALLS.md`
- General Ecto/Mix/OTP behavior (MEDIUM, not re-verified against external docs this session): `Ecto.Migrator.with_repo/3` semantics, Hex version immutability and retirement window, `mix docs --warnings-as-errors` behavior
