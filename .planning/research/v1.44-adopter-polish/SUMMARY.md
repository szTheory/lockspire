# Project Research Summary: Lockspire v1.44 Adopter Polish & Verified 1.6.0

**Project:** Lockspire (embedded OAuth/OIDC authorization server library for Phoenix/Elixir)
**Domain:** Operator and adopter ergonomics around signing-key encryption at rest, plus a verified Hex publish
**Researched:** 2026-10-18
**Confidence:** HIGH for code scope; MEDIUM for comparator behavior and for the release-sequencing decision

## Executive Summary

v1.44 is a polish milestone on top of v1.43 (signing-key encryption at rest). It adds no dependencies, no version bumps, no schema migration, and no protocol change. Each item lands on an existing seam: `Lockspire.Install.RepoRunner.run/2` for the repo-start fix; `Lockspire.Config.key_encryption!/0` for `{:system, "ENV"}` resolution; `KeySet` and the install-generator snippet for `mix lockspire.gen.kek`; `Lockspire.Admin.encryption_status/0` for the read-only Key protection line. The release work reuses the protected release lane (`release.yml`, `verify_install_truth.sh`, clean-room harness) with no new machinery.

Recommended approach: fix the three broken DB-touching Mix tasks first (`lockspire.client.create`, `lockspire.doctor.token_format`, `lockspire.doctor.remote_jwks`). They declare only `@requirements ["app.config"]`, so they work only when something else has started the repo and fail in a bare `mix` run. Fix by wrapping their DB work in `RepoRunner.run/2`, never by adding `app.start` (which boots the host endpoint and Oban). Then add `{:system, "ENV"}` resolution, `mix lockspire.gen.kek` (print-only), the admin missing-KEK error copy, and the Key protection line. Each UI change must update `PRODUCT.md` (vocabulary map and retired-wording table) in the same change, since `vocabulary_contract_test.exs` enforces the retired list.

Main risks: (1) the repo-start fix copying raw `with_repo` from `keys.reencrypt`, which restarts a live pool, and `RepoRunner`'s blanket rescue hiding real write failures as "repo unavailable"; (2) key material leaking via `gen.kek` output, logs, errors, or `inspect`; (3) the Hex publish being irreversible, so 1.6.0 must be verified from public sources (Hex checksum, HexDocs, tag), not workflow color.

## Key Findings

### Stack

No stack changes. Reuse pinned Elixir `~> 1.18` (CI 1.19.5 / OTP 28; min 1.18.4 / 27), Ecto SQL 3.13.5, `:crypto`, Mix. Add no Hex packages.

- Repo start in tasks: `RepoRunner.run/2`. It calls the function directly if the repo is already running; otherwise `Ecto.Migrator.with_repo(mode: :temporary)`. Do not copy raw `with_repo` (restarts a live pool).
- Task startup: keep `@requirements ["app.config"]`. Never `app.start`.
- KEK generation: `Base.encode64(:crypto.strong_rand_bytes(32))` (padded, 44 chars), matching the install generator and existing error text. Not `mix phx.gen.secret`.
- `{:system, "ENV"}`: per-entry `{id, {:system, "VAR"}}`, resolved with `System.fetch_env/1`. Not `System.get_env/1` (silent nil), not `fetch_env!/1`, not compile-time, not cached in app env, no default-value form.
- Admin status: reuse `Keys.encryption_status/0` (ids and counts only).
- Release tooling: `release.yml`, `scripts/publish/verify_install_truth.sh`, `scripts/maintainer/repo_hygiene_check.sh`, `.planning/RELEASE-TRAIN.md`, Phase 143 playbook. PR #121 is OPEN and MERGEABLE; squash-merge only.

### Features

Table stakes:

- Repo-start fix for the three tasks, each with a no-repo test. Map `{:error, :repo_unavailable}` to a calm `Mix.raise` naming the repo, without echoing the exception.
- `mix lockspire.gen.kek` with `--id <id>` (validated `[A-Za-z0-9._-]{1,32}`, default `YYYY-MM` UTC) and `--raw` (value only). Output must round-trip through `KeySet.new/1`. Writes no files, touches no Repo, logs nothing.
- `{:system, "ENV"}` accepted as a KEK value, with boot-time errors naming the variable, never its value.
- Admin key-generation error naming the missing KEK (reason `:key_encryption_not_configured` already exists).
- Read-only Key protection line on the Keys index (KEY-UI-01).
- Verified 1.6.0 publish.

Differentiators (only with slack): per-key "Protected by encryption key X" on the show page; `gen.kek --rotate` snippet; shared "needs the Repo" table test; published-package smoke check.

Defer: `--format json`; Overview-level posture banner; KMS/Vault (KEK-04).

Anti-features: gen.kek writing any file or editing `runtime.exs`; per-call `{:system}` resolution; silent fallback when env unset; `{:system, "X", "default"}`; admin buttons to generate, rotate, or re-encrypt a KEK, or to generate unprotected keys.

Key protection states (draft; final copy must pass the vocabulary contract):

- All rows under current KEK: "Private signing keys are encrypted with encryption key "X"."
- Rows under older KEK: "N of M signing keys use an older encryption key." Point to the re-encrypt task.
- Unprotected rows: "N signing keys are stored without encryption." Escalate only if `legacy_plaintext: :reject` blocks signing.
- Unknown/undecryptable rows: "N signing keys cannot be read with the configured encryption keys. Do not delete these keys."
- No KEK configured: "Not set up. New signing keys cannot be generated until an encryption key is configured. Existing keys keep signing."
- Invalid config: "The encryption key configuration is invalid." Point to the doctor task.
- Observation unavailable: "Could not check right now." Never render as "all good" or "0 unprotected."

Copy rules: no unexplained KEK, envelope, AES, or `legacy_plaintext` in the primary line; technical detail in an info popover. Avoid retired phrases. Text plus icon, not color alone.

### Architecture

No new layer. Protocol core and storage untouched. Tasks stay thin and call public `Lockspire.Admin.*` / `Lockspire.Clients` inside `RepoRunner.run/2`. Two real data-flow changes: env resolution before `KeySet.new` in `Config.key_encryption!/0`; one extra `encryption_status` read per Keys page load.

- Audit of 11 `lib/mix/tasks` files: exactly three broken (client.create, doctor.token_format, doctor.remote_jwks).
- Test gap: doctor tests call `start_supervised!(Lockspire.TestRepo)` in `setup_all`, masking the bug. Put no-repo cases in a separate module.
- Clean-room proof: add the three task invocations to `scripts/acceptance/clean_room_saas_journey.py` near lines 923-924 first; watch them fail; then fix. Switch `build_provider.py` (~line 243) to gen.kek output.
- New files: `lib/mix/tasks/lockspire.gen.kek.ex`; `Lockspire.Generators.KekSnippet` extracted from `generators/install.ex` (~121-160); `keys_live/protection.ex` presenter; `AdminComponents.key_protection_line/1`.
- Missing-KEK error: `{:error, :key_encryption_not_configured}` is dropped by the catch-all at `keys_live/index.ex:~236-243`; add a clause before it and tighten the `@spec` at `admin.ex:~208`.
- Docs: `docs/upgrading/signing-key-encryption.md`, `docs/install-and-onboard.md`, `docs/operator-admin.md`. CHANGELOG is Release Please-owned.

### Pitfalls

1. Pool bounce (C1): route all repo-touching tasks through RepoRunner; test pool pid unchanged when the repo is already started, and start/stop when stopped.
2. RepoRunner hides failures (C2): the work function returns tagged tuples; print a client secret once after RepoRunner returns; writers fail loud, doctors fail soft.
3. Key leakage (C5, C9): gen.kek takes no secret args, logs nothing, emits no telemetry, writes no files. `@derive {Inspect, except: [:keys]}` on KeySet. Never `put_env` a resolved value. Errors name the env var, never the value.
4. Early or missing-env resolution (C7, C8): never in config.exs or `compile_env`. A configured block with an unset/empty env var must fail at boot, never fall to `:unconfigured`.
5. Irreversible publish (C10-C12): verify 1.6.0 from the Hex API, HexDocs, the `lockspire-v1.6.0` tag, and a hash of the downloaded tarball. Dispatch only an exact SHA equal to origin/main with green CI. The clean-room consumer uses `{:lockspire, "== 1.6.0"}` from Hex in a fresh HEX_HOME.

Also: M1 (status line shows only the current KEK id and status); M2 (guard the status read with `connected?/1`); M3 (vocabulary row in the same change); M5 (`mix docs.verify` on CI Elixir 1.19.5-otp-28); M7 (doctor exit semantics unchanged).

## Implications for Roadmap

- **Phase A — Mix task repo-start fix:** harness reproduction first, then RepoRunner wrapping and no-repo tests.
- **Phase B — KEK developer experience:** `{:system}` resolution, KekSnippet extraction, `gen.kek`, guidance strings and contract tests.
- **Phase C — Admin Key protection and missing-KEK copy:** vocabulary row, error clause, Protection presenter and component, LiveView tests per state.
- **Phase D — Docs and verified release:** following `docs/maintainer-release.md` and the v1.39 Phase 143 playbook.

### Decision Required: Release sequencing

- **Option 1 — ship 1.6.0 first from PR #121 as-is** (PITFALLS). 1.6.0 carries v1.43 encryption only; v1.44 polish ships in a later release (1.7.0 if `feat` commits). Pros: verified in isolation, small surface, clean exact-SHA window. Cons: 1.6.0 ships with the broken tasks and openssl-only guidance; two publish cycles.
- **Option 2 — land v1.44 first, merge PR #121 last** (ARCHITECTURE, FEATURES). Pros: one publish cycle; 1.6.0 carries the polish; the clean-room proof exercises the fixed tasks, gen.kek and `{:system}` on the published artifact. Cons: release gated on all v1.44 work; PR #121 must be re-read after it regenerates.

### Research Flags

- Phase A: confirm in a clean room that `Clients.register_client` needs nothing beyond `:ecto_sql`/`:postgrex`. Decide whether RepoRunner's blanket rescue stays for writers.
- Phase D: re-check `upload_hex_artifact.exs` against the current Hex client; re-read PR #121 at merge.

## Conflicts Between Research Files

1. Where `{:system}` resolves: KeySet (STACK, FEATURES) vs `Config.key_encryption!/0` (ARCHITECTURE). Recommendation: Config.
2. Tagged error names differ across files. Pick one set and pin it in tests; treat empty as missing.
3. Env var name: `LOCKSPIRE_KEY_ENCRYPTION_KEY` (installer) vs `LOCKSPIRE_KEK`. Recommendation: `LOCKSPIRE_KEY_ENCRYPTION_KEY`.
4. gen.kek output channel: labeled block on stdout by default; `--raw` prints only the value.
5. Key protection data source: `encryption_status/0` once per connected mount, failure isolated from the key inventory.
6. Show page scope: Index only for v1.44.
7. RepoRunner for writers: resolve in Phase A planning.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | No new deps; ecto_sql 3.13.5 `with_repo` read from deps/. |
| Features | MEDIUM | Repo facts HIGH; comparators from training knowledge. |
| Architecture | HIGH | Seams read from source; line numbers will drift. |
| Pitfalls | HIGH (repo) / MEDIUM (general) | Repo and Phase 143 records read. |
| Release sequencing | MEDIUM | A maintainer decision, not a research finding. |

## Sources

- Repo: `deps/ecto_sql/lib/ecto/migrator.ex`; `lib/lockspire/install/repo_runner.ex`; `lib/lockspire/config.ex`; `lib/lockspire/application.ex`; `lib/lockspire/security/key_encryption/key_set.ex`; `lib/lockspire/admin/keys.ex`; `lib/mix/tasks/*.ex`; `lib/lockspire/generators/install.ex`; `lib/lockspire/install/verify.ex`; `lib/lockspire/web/live/admin/keys_live/index.ex`; `test/lockspire/web/live/admin/vocabulary_contract_test.exs`; `PRODUCT.md`; `.github/workflows/release.yml`; `scripts/publish/`; `scripts/acceptance/clean_room_saas_journey.py`; `.planning/RELEASE-TRAIN.md`; `docs/maintainer-release.md`.
- `gh pr view 121` (2026-10-18): OPEN, MERGEABLE.
- `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md`.
- `.planning/research/v1.43-key-encryption/`.

---
*Research completed: 2026-10-18*
