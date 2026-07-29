# Phase 126: Adopter Path Walk & Defect Ledger - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `126-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-07-28
**Phase:** 126-adopter-path-walk-defect-ledger
**Mode:** assumptions
**Areas analyzed:** Harness Form & Environment; Step Model, Attribution & Resumability; Host Login
Seam, Flow Driver & Token Proof; Defect Ledger Format & Workaround Linkage

## Assumptions Presented

### Harness Form, Entry Point & Environment Contract

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Bash script `scripts/maintainer/adopter_path_walk.sh` + `mix adopter.walk` alias, kept out of `ci:` | Confident | `scripts/maintainer/repo_hygiene_check.sh`; `scripts/publish/verify_install_truth.sh`; `mix.exs:71-125`; `test/integration/install_generator_test.exs:363` |
| Not a `Mix.Task` — would ship as public Hex surface, which hygiene already BLOCKs | Confident | `scripts/maintainer/repo_hygiene_check.sh` public-surface contract |
| Not ExUnit — inherits library `MIX_ENV=test` and `_build`, defeating clean-room | Confident | `mix.exs` `test.integration` alias |
| Generated app uses `{:lockspire, path: <repo root>}`, not a Hex version | Confident | `examples/adoption_demo/mix.exs:26` |
| Environment supplies Postgres via `LOCKSPIRE_*_DB_*`; walk starts nothing; named prerequisite failure | Likely | `.github/workflows/ci.yml:38-56,247-290`; `examples/adoption_demo/config/config.exs:29-43`; `verify_install_truth.sh:7-13` |
| `mix phx.new --database postgres` with Ecto/HTML/LiveView/assets defaults; `MIX_ENV=dev`; port 4200 | Likely | `mix help phx.new` (phx_new 1.8.9); `.github/workflows/ci.yml:313-327`; `examples/adoption_demo/docker-compose.yml` |

### Step Model, Failure Attribution & Resumability (ADOPT-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Step IDs mirror `docs/install-and-onboard.md` section numbers; `[PASS\|FAIL] step-NN` lines + summary | Confident | Guide numbered 1-8; `repo_hygiene_check.sh` `record_result`/`RESULTS[]`/`Summary:` |
| Stable workdir `tmp/adopter-walk/`, `--workdir`, `--keep`, step markers under `.walk/steps/`, `--from-step NN` | Likely | `verify_install_truth.sh:5-6` (`mktemp -d` + `trap` destroys evidence); `.gitignore` `/tmp/`; `ci.yml:314`; `repo_hygiene_check.sh` tmp allowlist |

### Host Login Seam, Flow Driver & Token Proof (ADOPT-04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Walk writes a minimal 4-file host login seam rather than running `phx.gen.auth` | **Unclear** | `priv/templates/lockspire.install/account_resolver.ex` raises and hardcodes `login_path: "/login"`; `examples/adoption_demo/.../session_controller.ex`, `plugs/current_account.ex`, `router.ex:36-38` |
| Flow driver is a new Python module adapted from `scripts/demo/adoption_smoke.py`, not an in-place edit | Likely | `adoption_smoke.py:221-320`; `repo_hygiene_check.sh` smoke-wrapper BLOCK contract |
| Token proof is `GET <mount>/userinfo` only; no protected host route in Phase 126 | Likely | `lib/lockspire/web/router.ex:38`; `adoption_smoke.py:292-299`; `docs/install-and-onboard.md` §3/§6 mark the route optional |

### Defect Ledger Format & Workaround Linkage

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single committed markdown ledger under `.planning/phases/126-.../`, not `docs/` | Likely | `.gitignore` (`.planning/` tracked); `.planning/config.json` `commit_docs: true`; `mix.exs:154-183` hexdocs extras; `.planning/milestones/*-MILESTONE-AUDIT.md` precedent |
| Workarounds carry grep-able `# LOCKSPIRE_WALK_WORKAROUND: <ID>` tokens linked to ledger entries | Likely | `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` in installer template, demo router, `adoption_smoke.py:301-308`; `repo_hygiene_check.sh` `grep -Fq` contracts |
| First run's ledger will be substantially non-empty; harness must record-and-continue, not abort | Confident | Seven source-visible defects — see below |

**Seven defects visible in source before any run** (seeded into CONTEXT.md as D-42..D-48):
router template returns a String not a quoted macro; that string references a nonexistent
`:require_operator` pipeline so the host won't compile; the `forward` sits in a pipeline-less scope
so consent/interactions get no session/CSRF; config template emits placeholder `issuer` and omits
`known_scopes`/`signing_alg`/`secret_key_base`/`oban:`; guide §4's `mix ecto.migrate` runs none of
the 37 library migrations; supervision-tree children and `included_applications` are undocumented;
no documented step creates an active signing key.

## Corrections Made

Two assumptions were escalated to the user as genuinely product-shaping. Both were resolved
**against** the analyzer's stated assumption.

### Host Login Seam

- **Original assumption:** The walk writes a minimal hand-written 4-file seam mirroring
  `examples/adoption_demo`, rather than running `mix phx.gen.auth`. Confidence: Unclear.
- **User correction:** Run `mix phx.gen.auth Accounts User users --live`.
- **Reason:** External research resolved the blocker that made this Unclear. It empirically generated
  a Phoenix 1.8.9 app, ran the generator, and completed a real HTTP login — proving no mailbox round
  trip is needed. `phx.gen.auth` is Phoenix's own default authentication, so it makes the strongest
  ADOPT-02 "real adopter defaults" claim, and it emits `conn.assigns.current_scope.user`, which is
  exactly what the Lockspire resolver template reads.

### Token Proof (ADOPT-04)

- **Original assumption:** `GET <mount>/userinfo` only; do not wire a protected host route in
  Phase 126. Confidence: Likely.
- **User correction:** userinfo **plus** a walk-wired protected host route.
- **Reason:** userinfo is mounted inside Lockspire's own forwarded router, so it is Lockspire-owned
  on both ends. A regression in `Lockspire.Plug.VerifyToken`'s `at+jwt` acceptance path — the v1.27
  resource-server surface — would pass the userinfo check while real adopters' API routes reject the
  token. That is precisely the "passes on exit codes alone" failure ADOPT-04 exists to prevent, one
  layer up. The protected route is ~10 lines and is documented in `docs/install-and-onboard.md` §3/§6
  and `docs/protect-phoenix-api-routes.md`, so the walk still performs only documented steps.

## External Research

Four gaps were flagged by the analyzer and researched against verified ground truth — the researcher
generated a real Phoenix 1.8.9 app at `/tmp/q1probe/authprobe`, ran `phx.gen.auth`, migrated, seeded,
booted, and completed an authenticated HTTP login, plus offline-boot tests.

### Q1 — Phoenix 1.8 `mix phx.gen.auth` login mechanics

- **Finding:** Phoenix 1.8 generates **both** magic-link and email+password login.
  `POST /users/log-in` accepts plain credentials with no mailbox round trip;
  `UserSessionController.create/2` pattern-matches `"token"` → magic link, `"email"`+`"password"` →
  password. Five non-obvious constraints, each hit during verification: (1) the generator prompts
  interactively without `--live`/`--no-live` and the harness hangs; (2) `register_user/1` only calls
  `User.email_changeset/3`, so a fresh registrant has `hashed_password: nil` and cannot
  password-login; (3) the user must be **confirmed before** the password is set —
  `login_user_by_magic_link/1` raises on an unconfirmed user that already has a password, a
  deliberate anti-credential-pre-stuffing guard; (4) LiveView renders CSRF as
  `name="_csrf_token" type="hidden" hidden value="…"`, so the naive regex misses and the POST returns
  403 `InvalidCSRFTokenError`; (5) `bcrypt_elixir ~> 3.0` is a C NIF requiring a build toolchain.
  Verified seed recipe: `register_user` → `UserToken.build_email_token(user, "login")` →
  `Repo.insert!` → `login_user_by_magic_link` (confirms) → `update_user_password` (12-char minimum).
  Scope assign is `conn.assigns.current_scope.user` via `:fetch_current_scope_for_user`.
- **Source:** `deps/phoenix/priv/templates/phx.gen.auth/*.ex.eex`;
  `deps/phoenix/lib/mix/tasks/phx.gen.auth.ex:231`; generated app at `/tmp/q1probe/authprobe`
- **Confidence impact:** Resolved the Unclear login-seam assumption. "Needs a mailbox round trip" →
  false, high confidence. "Harness can obtain a session cookie non-interactively" → empirically
  demonstrated. Drove the D-21..D-27 correction.

### Q2 — Phoenix dev-mode asset watcher failure behavior

- **Finding:** Without the esbuild/tailwind binaries the server does **not** fail cleanly and is
  **not** benign. HTTP keeps returning 200, but the endpoint enters a permanent restart loop —
  measured at **25 `Running Endpoint` lines in 60s** (~1 per 4s). Cause: the watcher child is
  `restart: :transient` and the generated MFA form re-raises, exceeding the endpoint supervisor's
  `max_restarts: 3/5s`; it survives only because dev sets `start_permanent: false`. The clean
  `Logger.error` + `exit(:shutdown)` path exists only for the *string* watcher form, which stock
  1.8.9 never uses. **Decision-relevant consequence:** the listener rebinds every ~4s, killing
  WebSocket connections — and Lockspire's consent surface is a LiveView, so the consent click cannot
  reliably complete. Also verified: `mix deps.get`/`mix compile` do **not** download the binaries;
  `mix phx.new --install` does (it runs `assets.setup`); `--no-watchers` does not exist;
  `--config override.exs` is deprecated in Elixir 1.19 and clobbers the endpoint config, wiping the
  Bandit adapter. Pre-seeded `_build/esbuild-*` / `_build/tailwind-*` caches gave a clean boot with
  zero restarts.
- **Source:** `/tmp/q1probe/offline.log`, `/tmp/q1probe/cfg.log`;
  `deps/phoenix/lib/phoenix/endpoint/watcher.ex`; `deps/phoenix/lib/mix/tasks/phx.server.ex`
- **Confidence impact:** "Offline boot is safe" → false as stated; safe only for pure-HTTP checks,
  unsafe for the LiveView consent step. Upgraded asset installation from a nice-to-have to a harness
  **correctness requirement** (D-09, D-10).

### Q3 — `phx_new` version pinning

- **Finding:** `mix archive.install hex phx_new 1.8.9 --force` is valid; `--force` is mandatory in CI
  or it blocks on a replace prompt even with stdin closed. `--timeout INTEGER` is available;
  `--no-compile` does not exist. Requirement strings like `~> 1.8.0` are accepted but drift.
  Version detection: `mix phx.new --version` → `Phoenix installer v1.8.9`;
  `Application.spec(:phx_new, :vsn)` returns `nil` and `Mix.Local.archives_path/0` does not exist in
  Elixir 1.19. **Archives are keyed one-entry-per-app-name**, so a harness using the default
  `MIX_ARCHIVES` would silently overwrite the maintainer's global `phx_new`; `MIX_ARCHIVES`
  isolation was verified working. phx_new 1.8.9 declares `elixir: "~> 1.17"`; Elixir 1.19.5 verified
  green (generated app passes `compile --warnings-as-errors`, `format --check-formatted`, and
  `mix test`); Phoenix's own CI at v1.8.9 runs 1.19.5/OTP 28.5 and does not cover 1.20.
  `mix archive.install github --sparse installer` is structurally broken — the
  `installer/templates/phoenix-usage-rules` directory is not in git.
- **Source:** `mix help archive.install`; Phoenix v1.8.9 CI config; local probe
- **Confidence impact:** "Pinning is reproducible without clobbering the maintainer's environment" →
  confirmed, high. Newly surfaced residual risk: unpinned Elixir and an unpinned generated `mix.lock`
  (recorded as D-15).

### Q4 — Ecosystem convention for running a library's migrations from a host app

- **Finding:** Stronger than a doc gap — the documented command silently no-ops.
  `docs/install-and-onboard.md:108` tells adopters to run bare `mix ecto.migrate`, which runs **zero
  of Lockspire's 37 migrations**, and adding `--migrations-path` to the docs **cannot work in a Mix
  release**: `deps/` is not packaged and the stock release migrator resolves
  `Application.app_dir(repo_otp_app, "priv/repo/migrations")` — the *host* — so Lockspire's
  migrations are structurally unreachable. `--migrations-path` also shares `schema_migrations`
  unconditionally (`schema_migration.ex:69-72` reads `:migration_source` from repo config only): a
  colliding version or name across paths raises `Ecto.MigrationError` when both are given, and is
  **silently filtered as "not pending" and never run** when the paths are run in separate commands;
  `mix ecto.rollback --step N` can roll back a Lockspire migration; `mix ecto.migrations` shows 37
  rows of `** FILE NOT FOUND **` forever. The dominant convention (Oban, Pow, PowAssent, AshPostgres,
  Rihanna) is a host migration generator: a public `Lockspire.Migration.up/1` / `down/1` /
  `migrated_version/1` with an internal version counter, plus the installer writing
  `priv/repo/migrations/<ts>_add_lockspire.exs` into the host — converting DDL from files-on-disk to
  BEAM code, which is what makes releases work. Telling detail:
  `lib/mix/tasks/lockspire.test.setup.ex:34` already uses the release-safe
  `Application.app_dir(:lockspire, ...)` form internally while adopters get nothing.
- **Source:** `deps/ecto_sql/lib/ecto/migration/schema_migration.ex:69-72`;
  `deps/ecto_sql/lib/ecto/migrator.ex:193-199,380-382,648-652,709-722`;
  `deps/ecto_sql/lib/mix/tasks/ecto.migrations.ex:43-45`; `deps/oban/lib/oban/migration.ex`;
  `docs/install-and-onboard.md:108`; `lib/mix/tasks/lockspire.install.ex`
- **Confidence impact:** Resolved the guide-vs-installer classification **decisively toward installer
  gap**, high confidence, and escalated its severity. Recorded as D-48, attributed to Phase 127.

### Declined researcher recommendation

The researcher's cross-cutting note argued the Q4 migration fix should be sequenced ahead of or
alongside the harness, since a harness built before that fix proves a path no adopter can walk.
**Declined.** The ROADMAP explicitly locks "do not fix defects in this phase," and Phase 126 success
criterion 5 exists precisely for this case: the walk uses the release-safe `Application.app_dir` form
as a marked workaround (D-49), records the defect with Phase 127 attribution, and lets Phase 127
remove the workaround. Logged here so a later reader can see the tension was weighed rather than
missed.
