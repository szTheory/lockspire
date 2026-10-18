# Technology Stack

**Project:** Lockspire v1.44 Adopter Polish & Verified 1.6.0
**Researched:** 2026-10-18
**Overall confidence:** HIGH (all findings read from repo and the pinned `deps/ecto_sql` 3.13.5 source)

## Verdict

**No new dependencies. No version bumps. No `mix.exs` change.** Every new capability is built from stdlib/OTP/Ecto APIs already pinned. Do not add Hex deps, `Mix.Generator` templates, `nimble_options`, or an ENV-parsing library.

## Recommended Stack (existing, reuse as-is)

### Core
| Technology | Version (repo) | Purpose | Why |
|---|---|---|---|
| Elixir | `~> 1.18` (mix.exs:14); CI 1.19.5, min matrix 1.18.4 (ci.yml:18,20) | Language floor | All APIs below exist since Elixir 1.0-1.10; nothing needs 1.19 features |
| OTP | CI 28, min 27 (ci.yml:19,21) | `:crypto` | `:crypto.strong_rand_bytes/1` is stable on all supported OTP |
| Ecto SQL | 3.13.5 (mix.lock:11) | `Ecto.Migrator.with_repo/3` | Verified in `deps/ecto_sql/lib/ecto/migrator.ex:149-184` |
| Mix | bundled | `@requirements`, `Mix.Task`, `Mix.shell()` | Same task conventions as the existing `keys.reencrypt` |

### API-by-feature map

| Feature | Use | Do NOT use |
|---|---|---|
| **Mix task Repo fix** (client.create, doctor.token_format, doctor.remote_jwks) | `Lockspire.Install.RepoRunner.run(repo, fun)` (lib/lockspire/install/repo_runner.ex:12-39), already used by `lockspire.doctor.key_encryption.ex:19,143`. It wraps `Ecto.Migrator.with_repo(repo, fun, mode: :temporary)` after `Application.ensure_all_started(:ecto_sql)` and returns `{:ok, result} \| {:error, :repo_unavailable}`. Repo is `Lockspire.Config.repo!()` (config.ex:15). Keep `@requirements ["app.config"]` | `@requirements ["app.start"]` (starts the host's whole tree: endpoint, Oban, ports; wrong for a CLI); calling `Repo.start_link` by hand |
| **`mix lockspire.gen.kek`** | `Base.encode64(:crypto.strong_rand_bytes(32))` (the exact recipe already in the error text, config.ex:~284). Needs only `use Mix.Task`, no `app.config`, no repo, no app start. Print id suggestion plus a `config :lockspire, :key_encryption, keys: [{id, key}], current: id` snippet using `Mix.shell().info/1` | `:crypto.strong_rand_bytes` outside the task; any dep; writing to files (print only, so the key never lands in a repo file); `mix phx.gen.secret` (not 32 bytes of base64, config.ex warns) |
| **`{:system, "ENV"}` KEK (KEK-05)** | Extend `KeySet.decode_entry/2` (key_set.ex:~86): accept `{id, {:system, var}}` when `is_binary(var)`; resolve with `System.fetch_env/1` (`{:ok, v} \| :error`), then pass `v` to the existing `decode_base64/1`, `check_length/1`, `check_strength/1`, `check_unique_material/2` unchanged. Add a tagged error (e.g. `{:keys, :env_var_missing}`) that never contains the value; the var NAME is safe to mention | `System.get_env/1` (silently nil, hides misconfig); `System.fetch_env!/1` (raises with its own message, bypasses the redaction-safe `{config_key, reason}` error contract); resolving at compile time or `Application.compile_env` (prior research C9); caching the resolved string in app env |
| **Admin "Key protection" line (KEY-UI-01)** | Existing read-only `Lockspire.Admin.Keys.encryption_status/0` (used by keys.reencrypt.ex:~95 and doctor) and/or `Config.key_encryption_keyset/0` (config.ex:270, persistent_term cached). Render only KEK ids/counts, never key material | New Admin context function that reads the DB per render beyond what `encryption_status/0` already does; any decrypt in the LiveView |
| **Admin key-gen error naming a missing KEK** | `Admin.Keys.generate_key` already returns `{:error, :key_encryption_not_configured}` (keys.ex:87, 313; admin.ex:241). Only the LiveView flash mapping is new; follow the vocabulary map in PRODUCT.md and the retired-wording table (AGENTS.md rule) | New error atoms in the domain layer |

### Ecto.Migrator.with_repo semantics (verified, ecto_sql 3.13.5)

- Signature `with_repo(repo, fun, opts)`; `fun` receives `repo`; returns `{:ok, fun_result, started_apps} \| {:error, reason}` (migrator.ex:149-184).
- Always `Application.ensure_all_started(:ecto_sql)` + `start_apps_before_migration` + adapter apps (`:postgrex`, `:ssl`...), then `repo.start_link(pool_size: 2)` (default `pool_size: 2`).
- If repo not running (the mix-task case): starts it, runs `fun`, then `repo.stop()` in an `after` (migrator.ex:854-856). If already running (live node): returns `:restart`, which RESTARTS the pool child (migrator.ex:822-823, 847-851), which is why `RepoRunner` short-circuits when `Process.whereis(repo)` is a pid. **Use `RepoRunner`, not raw `with_repo`, for the three diagnostic/client tasks.**
- `mode: :temporary` is what keeps started apps from taking the VM down on exit; keep it.
- `fun`'s result is wrapped; raises inside `fun` propagate after cleanup. `RepoRunner` rescues and returns `{:error, :repo_unavailable}`, deliberately hiding exceptions that may carry connection details. For `client.create` the changeset/validation errors from `Clients.register_client/1` are returned as tuples (not raised), so compute inside the fun and print AFTER `RepoRunner.run` returns (matches the comment "Only computes. Printing and raising happen after the repo has been stopped", keys.reencrypt.ex:~114).
- Caveat: `RepoRunner` collapses every failure (including a genuine bug in `fun`) to `:repo_unavailable`. For `client.create`, return domain errors as values from `fun`, not raises, or users get a misleading "repo unavailable" message. Map `{:error, :repo_unavailable}` to a calm message via `Mix.raise`.
- Reference pattern in repo: keys.reencrypt.ex:~107-121 (raw `with_repo`, justified because it needs `{:error, reason}` mapping); doctor.key_encryption.ex:143 (`RepoRunner`). Prefer `RepoRunner` for the three new fixes.

### Mix.Task requirements notes
- `@requirements ["app.config"]` loads/compiles and applies config but starts neither the app nor the Repo. That is the exact bug: `Clients.register_client/1` etc. call `Repo.*` with no running pool. Confirm in a clean-room host first (`test/clean_room/*`), per the milestone plan.
- `@requirements` has been supported since Elixir 1.11; fine on the 1.18 floor.
- `mix lockspire.gen.kek` should declare NO `@requirements` (or `["app.config"]` only if it reads config to avoid colliding ids); simplest is none, so it works in a host that is not yet configured.
- Mix tasks ship in `lib/mix/tasks/` and are in the package (only `test.setup` and `test_repo.ex` are excluded, mix.exs `@package_excluded_files`). A new `lockspire.gen.kek.ex` ships automatically.

### Version-specific behaviors (Elixir 1.19.5 / OTP 28)
- Local Elixir 1.20.4 type warnings fail `--warnings-as-errors`; run qa on 1.19.5-otp-28 (memory: project_ci_elixir_for_qa). New code should avoid patterns the 1.20 type checker flags: do not pattern-match on `{:ok, _}` results that can't occur; write `with` else clauses that are reachable.
- `Base.decode64/2` with `padding: false`: existing KeySet already handles padded/unpadded and url-safe (key_set.ex ~99-120). Reuse it; do not re-implement. Note the generated key from `Base.encode64/1` is padded (32 bytes -> 44 chars with one `=`); KeySet already accepts it.
- `System.fetch_env/1` is unchanged across supported versions. Treat empty string as missing (an empty value fails `decode_base64`/`check_length` anyway, but map to the same `env_var_missing`-style tag to give a better message).
- Env resolution timing: `config/runtime.exs` is evaluated at boot, so `{:system, ...}` is resolved when `Config.key_encryption!/0` runs (application.ex boot validation and the persistent_term cache, config.ex:246-280), not at compile time. `key_encryption!/0` re-validates from app env on every call; with `{:system, ...}` that re-reads the env each time, which is cheap but means `key_encryption_keyset/0` (cached) is the hot-path accessor. Mix tasks that call `key_encryption!/0` directly (keys.reencrypt.ex `legacy_mode/0`) get the same resolution with no change.
- Redaction: the unresolved `{:system, "VAR"}` tuple in app env is not secret; the resolved binary lives only in the `KeySet` struct (redacted `Inspect`, key_set_inspect.ex). This is an improvement over the v1.43 residual (raw KEK in app env), as noted in the v1.43 SUMMARY ("`{:system, "ENV"}` resolution is a follow-up").
- Security consideration: a `{:system, var}` form should be validated like inline keys (length 32, not all-identical, unique material) so env typos fail at boot with the tagged error, not at first sign.

## Release verification tooling (already in repo; reuse, do not rebuild)

| Asset | Path | Use for 1.6.0 |
|---|---|---|
| Release Please PR | GitHub PR #121 "chore(main): release lockspire 1.6.0", state OPEN, MERGEABLE (checked via `gh`) | Merge by SQUASH only (memory: feedback_always_squash_merge); title is the changelog entry |
| Protected release workflow | `.github/workflows/release.yml` (publish + verify jobs) | Publishes the manifest-verified artifact; verifies Hex checksum, HexDocs, GitHub release/tag, clean-room install |
| Install-truth verifier | `scripts/publish/verify_install_truth.sh <manifest> <source_sha> [receipt]` | Polls Hex API (12 retries x 10s), compares `artifact.sha256` from the manifest to Hex, writes `install-truth-receipt.json`. Needs `curl jq mix python3` |
| Other publish scripts | `scripts/publish/{publish_hex_idempotently.sh, release_artifact.py, release_main_freeze.sh, release_tag_guard.sh, upload_hex_artifact.exs, verify_github_release_target.sh}` | Idempotent upload, tag/target guard, main-freeze hold |
| Hygiene check | `scripts/maintainer/repo_hygiene_check.sh` | Exact-SHA BLOCK/WARN check before merge (v1.39 Phase 142 used it) |
| CI gating | `.github/workflows/ci.yml` (ELIXIR 1.19.5 / OTP 28; min 1.18.4 / 27) | Canonical CI must pass on the exact release SHA before publish |
| Record of truth | `.planning/RELEASE-TRAIN.md` (lines 9-14 show the 1.5.1 record format: version, source SHA, CI run, publish run, checksum, GitHub release, install-truth) | Update with 1.6.0 values ONLY after verification; no record may say 1.6.0 shipped before then |
| v1.39 precedent | `.planning/milestones/v1.39-ROADMAP.md`, `v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md` | Template for plans and evidence; note the 1.5.1 run had a known post-publish evidence-retention failure fixed in PR #120 |

Notes: `mix.exs` `version` is `1.5.1` and RELEASE-TRAIN carries an `x-release-please-version` marker; Release Please PR #121 bumps both. The 1.6.0 bump covers v1.40-v1.43 content (including encryption), so the changelog/PR body should be checked for the v1.43 upgrade steps before merging. `.tool-versions` pins only nodejs; Elixir/OTP come from CI env vars, not asdf.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| Task repo startup | `RepoRunner.run/2` | Raw `Ecto.Migrator.with_repo` (as in keys.reencrypt) | Restarts a live pool if repo is already running; RepoRunner guards that and hides connection details |
| Task startup | `app.config` + RepoRunner | `@requirements ["app.start"]` | Boots the host endpoint/Oban; heavy, side-effectful, can bind ports |
| KEK generation | `:crypto.strong_rand_bytes(32) \|> Base.encode64()` | `mix phx.gen.secret`, `openssl` shell-out, `Mix.Generator` file writes | Wrong size/format; not portable; writing secrets to files invites commits |
| ENV KEK | `System.fetch_env/1` inside `KeySet` | `System.get_env/1`, `Config.Reader` helpers, `Application.compile_env` | Silent nil; helper forms are runtime.exs-only and would not help the `{:system, ...}` contract; compile-time breaks releases (prior research C9) |
| ENV KEK form | `{id, {:system, "VAR"}}` per entry | Whole-block `{:system, ...}` | A per-key tuple keeps ids explicit and rotation (multiple env vars) working |
| UI data | `Keys.encryption_status/0` | New query/Ecto join | Status function exists and already counts per KEK id |

## Installation

```bash
# No dependency changes.
# Verify nothing drifted:
mix deps.get   # lockfile unchanged
mix lockspire.gen.kek   # after implementation
```

## What NOT to add
- No Hex packages (cloak, vapor, dotenvy, nimble_options, req).
- No `compile_env` reads of KEK or env var names.
- No new storage/schema migration (KEK-05/KEY-UI-01 are read-only).
- No new telemetry/audit event names unless the generator must report; `gen.kek` is local-only and offline.
- No change to the Bandit pins (done in v1.43).

## Confidence

| Item | Level | Basis |
|---|---|---|
| Repo-start semantics | HIGH | Read ecto_sql 3.13.5 source in `deps/` |
| RepoRunner reuse | HIGH | Read module and existing consumer |
| `{:system, ...}` integration point | HIGH | Read KeySet/Config; exact function names cited (line numbers approximate for key_set.ex) |
| Release tooling | MEDIUM-HIGH | Listed and sampled scripts; did not run them; PR #121 state from `gh` |
| Elixir 1.20 type warning guidance | MEDIUM | From project memory, not re-verified |

## Sources
- `/Users/jon/projects/lockspire/deps/ecto_sql/lib/ecto/migrator.ex:149-184, 817-860`
- `/Users/jon/projects/lockspire/lib/lockspire/install/repo_runner.ex`
- `/Users/jon/projects/lockspire/lib/mix/tasks/lockspire.keys.reencrypt.ex`, `lockspire.doctor.key_encryption.ex`, `lockspire.client.create.ex`, `lockspire.doctor.token_format.ex`, `lockspire.doctor.remote_jwks.ex`
- `/Users/jon/projects/lockspire/lib/lockspire/config.ex:246-292`, `lib/lockspire/security/key_encryption/key_set.ex`
- `/Users/jon/projects/lockspire/mix.exs:12-14`, `.github/workflows/ci.yml:18-21`, `scripts/publish/`, `.planning/RELEASE-TRAIN.md`
- `/Users/jon/projects/lockspire/.planning/research/v1.43-key-encryption/SUMMARY.md`
