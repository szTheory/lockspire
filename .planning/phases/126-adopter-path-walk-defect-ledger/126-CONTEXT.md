# Phase 126: Adopter Path Walk & Defect Ledger - Context

**Gathered:** 2026-07-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A maintainer can run one command that walks the entire documented adopter path against a stock
Phoenix app and gets an attributable verdict plus a written record of every defect the walk
surfaced.

**This phase builds a harness and produces evidence. It does not fix what it finds.**

In scope: the walk harness, its step model, its failure attribution, its token assertion, and the
committed defect ledger. Requirements ADOPT-01 through ADOPT-04.

Out of scope and explicitly deferred to later phases:
- Fixing installer defects → Phase 127
- Fixing guide/wiring defects → Phase 128
- Reconciling `examples/adoption_demo` with the installer path → Phase 129
- Automating the walk in CI / on release → Phase 130

Out of scope for the milestone entirely: new protocol surface, widening
`docs/supported-surface.md`, making the installer inject into host router/config/application,
host-owned seam changes (accounts, login UX, layouts, branding, policy), admin/operator UI work.

**A red first run with a complete ledger is a passing phase. An empty ledger is not.**
</domain>

<decisions>
## Implementation Decisions

### Harness Form & Entry Point

- **D-01:** The walk is a bash script at `scripts/maintainer/adopter_path_walk.sh`, wrapped by a
  `mix adopter.walk` alias in `mix.exs`. It is NOT added to the `ci:` alias in this phase.
  Rationale: `scripts/maintainer/repo_hygiene_check.sh` is the established maintainer lane and
  `mix.exs:71-125` shows every lane is an alias delegating to `cmd bash scripts/...`.
- **D-02:** Not a `Mix.Task` under `lib/mix/tasks/`. That would ship in the Hex package as public
  surface, which `repo_hygiene_check.sh`'s public-surface contract check already BLOCKs for
  maintainer tooling.
- **D-03:** Not an ExUnit integration test. `mix test.integration` runs inside the library's own
  Mix project, `MIX_ENV=test`, and `_build`; ADOPT-02 requires a genuinely external clean-room app
  that boots its own server.
- **D-04:** The generated host app declares `{:lockspire, path: "<absolute repo root>"}`, written by
  the harness. Precedent: `examples/adoption_demo/mix.exs:26`. A Hex pin would prove the last
  release rather than the branch under repair, so Phases 127-129 could not verify their own fixes.

### Generated Host App & Environment

- **D-05:** Generate with `mix phx.new host_app --database postgres`, keeping Ecto, HTML, LiveView,
  and asset defaults. The `--no-ecto --no-html --no-assets --no-mailer` flags used by
  `scripts/publish/verify_install_truth.sh:75` are forbidden by ADOPT-02.
- **D-06:** Pin `phx_new` to exactly `1.8.9` and install it into a harness-local
  `MIX_ARCHIVES=.harness/archives`, never the maintainer's `~/.mix/archives`. Mix archives are keyed
  one-entry-per-app-name, so an unisolated install silently overwrites the maintainer's global
  `phx_new`. `--force` is mandatory or the install blocks on a replace prompt even with stdin closed.
- **D-07:** Assert and print the resolved installer version via `mix phx.new --version`
  (expect `Phoenix installer v1.8.9`); fail the preflight on mismatch.
  `Application.spec(:phx_new, :vsn)` returns `nil` and `Mix.Local.archives_path/0` does not exist in
  Elixir 1.19 — do not use either.
- **D-08:** `.harness/` is gitignored.
- **D-09:** Install assets up front — `mix phx.new --install`, or pre-seeded `_build/esbuild-*` and
  `_build/tailwind-*` caches on rerun. `watchers: []` is a last resort only, and if used must be a
  ledger-recorded workaround.
  **This is a correctness requirement, not an optimization.** Without the esbuild/tailwind binaries
  the endpoint does not fail cleanly: the watcher child is `restart: :transient` and the generated
  MFA form re-raises, exceeding the endpoint supervisor's `max_restarts: 3/5s`. The endpoint enters
  a permanent restart loop — measured at 25 restarts in 60s — surviving only because dev sets
  `start_permanent: false`. HTTP still returns 200, but the listener rebinds every ~4s and kills
  WebSocket connections. Lockspire's consent surface is a LiveView
  (`lib/lockspire/web/live/consent_live.ex`), so a watcher-looping app cannot reliably complete the
  consent click.
- **D-10:** Verified dead ends — do not attempt: `mix phx.server --no-watchers` does not exist;
  `--config override.exs` is deprecated in Elixir 1.19 and clobbers the endpoint config, wiping the
  Bandit adapter (`Plug.Cowboy.child_spec/1 is undefined`).
- **D-11:** Boot in `MIX_ENV=dev` via `mix phx.server > tmp/adopter-walk/server.log 2>&1 &`, capture
  the pid, drive the flow, kill, and `cat` the log on failure. Direct precedent:
  `.github/workflows/ci.yml:313-327`.
- **D-12:** Default port 4200, overridable. Do not reuse 4100 — it is pinned by
  `examples/adoption_demo/docker-compose.yml`, asserted by `repo_hygiene_check.sh`, and Cairnloop
  holds `127.0.0.1:4100` locally. The issuer URL and the registered client's `redirect_uri` must be
  known before boot, so a fixed default with an override beats an ephemeral port.
- **D-13:** PostgreSQL is supplied by the environment, reusing the existing
  `LOCKSPIRE_*_DB_{HOST,PORT,USER,PASSWORD,NAME}` convention with `PGHOST`/`PGPORT`/`PGUSER`
  fallbacks. The walk starts no database itself. Precedent: `.github/workflows/ci.yml:38-56`
  supplies `postgres:16` as a GitHub service with a `pg_isready` wait loop — no Docker daemon,
  matching the v1.35 daemon-free rule.
- **D-14:** Preflight checks `mix`, `python3`, `phx_new`, and Postgres reachability, and hard-fails
  with a distinctly named prerequisite error. A missing prerequisite must never be recorded in the
  ledger as a Lockspire defect.
- **D-15:** Record in the ledger as known residual nondeterminism: Elixir/OTP versions are not
  pinned by the harness, and the generated app's `mix.lock` is not snapshotted.

### Step Model, Attribution & Resumability (ADOPT-03)

- **D-16:** Step IDs mirror `docs/install-and-onboard.md` section numbers — e.g. `step-01-add-dep`,
  `step-02-install`, `step-03-wire`, `step-04-migrate`, `step-05-verify`, `step-06-client`,
  `step-07-flow`. The guide is already numbered 1-8. Phase 128's WIRE-01 drift fence needs this
  guide↔step mapping as its join key; arbitrary names force a rename and dangle every ledger
  reference.
- **D-17:** Each step emits a single `[PASS|FAIL] step-NN <guide section>: <detail>` line, with an
  accumulated summary block and exit-code verdict at the end, following `repo_hygiene_check.sh`'s
  `record_result` / `RESULTS[]` / `Summary:` shape.
- **D-18:** The harness records-and-continues through wiring-class failures rather than aborting at
  the first FAIL. Aborting early would stop at the known compile-error defect and capture one defect
  instead of the seven already visible in source.
- **D-19:** Resumability is delivered by a stable workdir at `tmp/adopter-walk/` (overridable via
  `--workdir`), a `--keep` flag suppressing cleanup, per-step completion markers under
  `<workdir>/.walk/steps/`, and a `--from-step NN` flag that skips completed earlier steps.
- **D-20:** Do NOT copy `verify_install_truth.sh`'s `mktemp -d` + `trap 'rm -rf' EXIT` pattern
  (`verify_install_truth.sh:5-6`). It destroys all evidence on failure — the exact anti-pattern
  ADOPT-03 forbids. `tmp/` is already the repo's evidence location: `.gitignore` has `/tmp/`,
  `ci.yml:314` writes `tmp/adoption_demo.log`, and `repo_hygiene_check.sh` allowlists it and
  preserves `tmp/admin-ui-polish/`.

### Host Login Seam (user-confirmed)

- **D-21:** The walk runs `mix phx.gen.auth Accounts User users --live` on the generated app. This
  is the strongest ADOPT-02 claim — it is Phoenix's own default authentication, which is what a real
  adopter with no accounts would reach for. It also matches the resolver template, which reads
  `conn.assigns.current_scope.user`.
- **D-22:** `--live` (or `--no-live`) is mandatory. `mix phx.gen.auth` prompts interactively
  ("Do you want to create a LiveView based authentication system?") and the harness hangs without it.
- **D-23:** Obtain a password-capable user non-interactively via `mix run` with this exact four-step
  recipe — order matters:
  ```elixir
  {:ok, user} = Accounts.register_user(%{email: email})
  {encoded, token} = UserToken.build_email_token(user, "login")
  Repo.insert!(token)
  {:ok, {user, _}} = Accounts.login_user_by_magic_link(encoded)   # confirms the user
  {:ok, {user, _}} = Accounts.update_user_password(user, %{password: password})
  ```
  Rationale: `register_user/1` only calls `User.email_changeset/3`, so a fresh registrant has
  `hashed_password: nil` and cannot password-login. `login_user_by_magic_link/1` **raises** on an
  unconfirmed user that already has a password — a deliberate anti-credential-pre-stuffing guard —
  so the user must be confirmed *before* the password is set. Password minimum is 12 characters.
  No mailbox round trip is required.
- **D-24:** Log in over plain HTTP with a cookie jar — no browser, no mailbox. Phoenix 1.8 generates
  *both* magic-link and email+password login; `POST /users/log-in` accepts plain credentials out of
  the box, and `UserSessionController.create/2` pattern-matches `"token"` → magic link,
  `"email"`+`"password"` → password.
- **D-25:** CSRF scraping must use `grep -o 'name="_csrf_token"[^>]*value="[^"]*"'`. LiveView renders
  the attributes as `name="_csrf_token" type="hidden" hidden value="…"`, so the obvious
  `name="_csrf_token" value="…"` pattern misses and the POST returns
  **403 `InvalidCSRFTokenError`**. This was hit and confirmed during research.
- **D-26:** `mix phx.gen.auth` injects `bcrypt_elixir ~> 3.0`, a C NIF. The walk's environment needs
  a build toolchain; note this in the preflight and in Phase 130's CI handoff.
- **D-27:** The `/users/log-in` path generated by `phx.gen.auth` does not match the hardcoded
  `login_path: "/login"` in `priv/templates/lockspire.install/account_resolver.ex`
  (`redirect_for_login/2`). Record this mismatch as a ledger defect attributed to the installer
  templates; do not fix it in this phase.

### Token Proof (ADOPT-04, user-confirmed)

- **D-28:** The walk asserts the token twice: (a) `GET <mount>/userinfo` with
  `Authorization: Bearer <access_token>` returning 200 with a `sub` and the claim the resolver emits,
  and (b) a walk-wired protected host route per `docs/protect-phoenix-api-routes.md`, accepting the
  same token.
- **D-29:** userinfo alone is insufficient. It is mounted inside the forwarded router
  (`lib/lockspire/web/router.ex:38`) so it costs nothing, but it is Lockspire-owned on both ends — a
  bug in `Lockspire.Plug.VerifyToken`'s `at+jwt` acceptance path (the v1.27 resource-server surface)
  would pass there while real adopters' API routes reject the token. That is the ADOPT-04 failure
  mode one layer up.
- **D-30:** Wiring a protected host route is ~10 lines and is a *documented* step —
  `docs/install-and-onboard.md` §3 and §6 present it as optional, so the walk still performs only
  steps the guide tells an adopter to perform, satisfying Phase 128's constraint.
- **D-31:** Introspection is explicitly not used. It requires a confidential client and proves the AS
  validated its own token rather than that a resource server accepted it.

### Flow Driver

- **D-32:** Adapt a new Python module from `scripts/demo/adoption_smoke.py` — its `Browser` class,
  `csrf()`, `code_challenge()`, `assert_status`, `wait_until_ready` — living beside the walk. Do NOT
  modify `adoption_smoke.py` in place.
- **D-33:** Rationale for adapting rather than reusing: `adoption_smoke.py:221-320` already drives
  the exact sequence (authorize → login handoff with `interaction_id`/`return_to` → interaction
  resume → consent page → `POST /lockspire/interactions/:id/complete` → callback `code` →
  `POST /lockspire/token` with `code_verifier`) and is stdlib-only via `http.client`, matching the
  repo's dependency-free posture. But it hardcodes `billingo-dashboard-public`,
  `alice@billingo.test`, `BILLING_RESOURCE`, and admin-shell CSS assertions that exist only in the
  demo.
- **D-34:** Rationale for not editing in place: `repo_hygiene_check.sh` has a hard BLOCK-level "smoke
  wrapper contract" asserting `adoption_smoke.py` contains `exercise_authorization_code` and
  `exercise_discovery_and_admin` and that `adoption_smoke.sh` only delegates. Editing it risks
  tripping the repo's own hygiene gate.
- **D-35:** Do not write the driver in Elixir. It would need a Mix project context outside the
  generated app.

### Defect Ledger

- **D-36:** The ledger is one committed markdown file at
  `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md`.
- **D-37:** Each entry carries: ID (`ADOPT-D01`), walk step ID, symptom, underlying error, **source**
  (installer / generated scaffolding / guide / reference demo / library / environment), **owning
  phase** (127 / 128 / 129 / future), and **workaround** (none | harness workaround ID).
- **D-38:** Not `docs/`. That is the hexdocs extras list (`mix.exs:154-183`), so a ledger there would
  publish Lockspire's own defect list to adopters mid-repair and may fail `mix docs.verify`
  (`docs --warnings-as-errors`, part of `mix ci`) on an unlisted extra. `.planning/` is git-tracked
  with `commit_docs: true`, and `.planning/milestones/*-MILESTONE-AUDIT.md` is the precedent for a
  committed evidence document.
- **D-39:** Not machine-readable JSON. No JSON-evidence precedent exists in `.planning/`, and the
  consumers are Phase 127-129 planners reading prose.
- **D-40:** Every harness workaround is marked in the script source with a grep-able token
  `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D07`, whose ID must appear in the ledger. This makes criterion
  5 mechanically checkable and gives Phase 128 a zero-ambiguity exit test. Precedent: the repo
  already treats grep-able markers as contracts — `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` in
  `priv/templates/lockspire.install/router.ex`, `examples/adoption_demo/.../router.ex:23`, and
  `adoption_smoke.py:301-308`; `repo_hygiene_check.sh` enforces dozens of contracts via `grep -Fq`.
- **D-41:** Prose-only cross-referencing is insufficient. Criterion 5's failure mode is a workaround
  "left silently in the harness," which prose cannot detect.

### Known Defects To Seed The Ledger

These are visible in source before the walk runs. The walk must confirm each empirically; they are
recorded here so an empty or thin ledger is recognizable as a harness failure.

- **D-42:** `priv/templates/lockspire.install/router.ex` — `lockspire_routes/0` returns a **String,
  not a quoted macro**, so `docs/install-and-onboard.md` §3's "call `lockspire_routes/0`" defines
  zero routes. Source: installer.
- **D-43:** That same string does `pipe_through [:browser, :require_operator]`. `:require_operator`
  does not exist in a stock `mix phx.new` router, so **the host will not compile**. Source: installer.
- **D-44:** The string's `forward "<mount>", Lockspire.Web.Router` sits in a pipeline-less scope, so
  the session/CSRF-dependent `/interactions` and `live /consent` routes
  (`lib/lockspire/web/router.ex:29-31`) get no `fetch_session`/`protect_from_forgery`. The demo works
  around this at `examples/adoption_demo/lib/adoption_demo_web/router.ex:53-59` by routing those
  through `:browser` *before* the forward; the template never tells the adopter to. Source:
  installer + guide.
- **D-45:** `priv/templates/lockspire.install/config.exs` emits `issuer: "https://example.com"` and
  omits `known_scopes`, `signing_alg`, `secret_key_base`, and `oban:` that
  `examples/adoption_demo/config/config.exs:62-77` proves are required. Source: installer.
- **D-46:** Nothing in the installer or guide tells the host to add `{Lockspire.Oban,
  Lockspire.Oban.runtime_config!()}`, `Cachex.child_spec(name: :lockspire_jwks_cache)`, or
  `Lockspire.KeyCache` to its supervision tree, or `included_applications: [:lockspire]` to
  `mix.exs` — all required per `examples/adoption_demo/lib/adoption_demo/application.ex:9-14` and
  `examples/adoption_demo/mix.exs:22`. Source: installer + guide.
- **D-47:** No documented step creates an active signing key. `Lockspire.Admin.generate_key/1` exists
  (`lib/lockspire/admin.ex:192-194`) but the demo seeds one manually
  (`examples/adoption_demo/priv/repo/seeds.exs:82`), so JWKS and token issuance have no key after a
  stock install. Source: installer + guide.
- **D-48:** **Migrations — the guide's documented command silently no-ops.**
  `docs/install-and-onboard.md:108` tells adopters to run bare `mix ecto.migrate`, which runs **zero
  of Lockspire's 37 migrations**. This is an *installer* gap owned by Phase 127, not a doc gap:
  - `--migrations-path deps/lockspire/priv/repo/migrations` **cannot work in a Mix release** —
    `deps/` is not packaged and the stock release migrator resolves
    `Application.app_dir(repo_otp_app, "priv/repo/migrations")`, the *host*, so Lockspire's
    migrations are structurally unreachable.
  - `--migrations-path` shares `schema_migrations` unconditionally
    (`deps/ecto_sql/lib/ecto/migration/schema_migration.ex:69-72` reads `:migration_source` from
    repo config only). A colliding version across paths raises `Ecto.MigrationError` when both paths
    are given, and is **silently filtered as "not pending" and never run** when the paths are run in
    separate commands. `mix ecto.rollback --step N` can roll back a Lockspire migration.
  - `mix ecto.migrations` will show 37 rows of `** FILE NOT FOUND **` forever.
  - The dominant ecosystem convention (Oban, Pow, PowAssent, AshPostgres, Rihanna) is a host
    migration generator: a public `Lockspire.Migration.up/1` / `down/1` / `migrated_version/1` with
    an internal version counter, plus `mix lockspire.install` writing
    `priv/repo/migrations/<ts>_add_lockspire.exs` into the **host**. That converts DDL from
    files-on-disk to BEAM code, which is what makes releases work.
  - Telling detail for the ledger: `lib/mix/tasks/lockspire.test.setup.ex:34` already uses the
    release-safe `Application.app_dir(:lockspire, "priv/repo/migrations")` form internally, while
    adopters are given nothing.
- **D-49:** Phase 126's harness uses the release-safe `Application.app_dir(:lockspire, ...)` form as
  a marked workaround (per D-40) to get past the migrate step. It does not use the `deps/` form,
  which would teach a pattern that breaks in releases.

### Claude's Discretion

- Exact step count and boundaries within the 1-8 guide sections, provided D-16's guide↔step mapping
  holds.
- Shell function decomposition, flag parsing details, and summary formatting, provided they follow
  `repo_hygiene_check.sh` conventions.
- Ledger table-vs-section markdown layout, provided every field in D-37 is present per entry.
- Naming of the Python flow-driver module and its internal structure.

### Folded Todos

None — `todo.match-phase 126` returned zero matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

Phase inputs and contracts:
- `.planning/ROADMAP.md` — Phase 126 goal, success criteria, implementation notes
- `.planning/REQUIREMENTS.md` — ADOPT-01..04, plus the Out of Scope table
- `.planning/METHODOLOGY.md` — assumption-first / decisive-defaults lenses
- `.planning/DEVELOPMENT-TRAIN.md` — milestone branch and merge model
- `.planning/MILESTONE-ARC.md` — the adoption-before-protocol ordering rule

The adopter path under test:
- `docs/install-and-onboard.md` — the documented path; §3 "Wire the generated files" and §4 migrate
  are the highest-risk sections
- `docs/protect-phoenix-api-routes.md` — the protected host route the walk wires for D-28
- `lib/mix/tasks/lockspire.install.ex` — installer behavior
- `priv/templates/lockspire.install/router.ex` — D-42, D-43, D-44
- `priv/templates/lockspire.install/config.exs` — D-45
- `priv/templates/lockspire.install/account_resolver.ex` — D-27; `resolve_account/2` and
  `build_claims/2` raise until the host implements them
- `lib/lockspire/web/router.ex` — mounted routes; `:38` userinfo, `:29-31` session/CSRF-dependent
  interactions and consent LiveView
- `lib/lockspire/web/live/consent_live.ex` — the LiveView that makes D-09 a correctness requirement
- `lib/lockspire/admin.ex:192-194` — `generate_key/1`, relevant to D-47

Harness analogs to follow:
- `scripts/maintainer/repo_hygiene_check.sh` — flag parsing, `record_result`, PASS/WARN/BLOCK
  summary, grep-based contract checks, public-surface BLOCK
- `scripts/publish/verify_install_truth.sh` — clean-room generation; follow its preflight, reject its
  `mktemp`+`trap` cleanup (D-20) and its `--no-*` flags (D-05)
- `scripts/demo/adoption_smoke.py` — the PKCE flow driver to adapt (`:221-320`), not to edit
- `scripts/demo/adoption_smoke.sh` — wrapper delegation contract
- `.github/workflows/ci.yml:38-56, 247-290, 313-327` — Postgres service, boot-and-drive precedent
- `mix.exs:71-125` — alias conventions; `:154-183` — the hexdocs extras list that D-38 avoids

Reference wiring that proves what a working install needs:
- `examples/adoption_demo/mix.exs:22,26,42`
- `examples/adoption_demo/config/config.exs:29-43,62-77`
- `examples/adoption_demo/lib/adoption_demo/application.ex:9-14`
- `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-30,36-38,53-59`
- `examples/adoption_demo/priv/repo/seeds.exs:82`

Existing installer proof to extend rather than replace:
- `test/integration/install_generator_test.exs` — content assertions are thorough; `:363` and `:379`
  (`reset_fixture!`) are the host-interaction gap
- `lib/mix/tasks/lockspire.test.setup.ex:34` — release-safe migrations-path form
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`scripts/demo/adoption_smoke.py`** — already drives the complete authorization-code + PKCE
  sequence including the login handoff, interaction resume, consent POST, callback code capture, and
  token exchange with `code_verifier`. Stdlib-only (`http.client`). Its `Browser` class, `csrf()`,
  `code_challenge()`, `assert_status`, and `wait_until_ready` are the highest-value reusable pieces.
- **`scripts/maintainer/repo_hygiene_check.sh`** — the maintainer-script template: `usage()`, `--flag`
  parsing, `record_result` accumulator, `printf '%s\n' "${RESULTS[@]}"`, `Summary:` line, exit code
  from verdict.
- **`scripts/publish/verify_install_truth.sh`** — clean-room generation mechanics:
  `mix archive.install hex phx_new --force`, required-command preflight, temp workspace.
- **`.github/workflows/ci.yml:313-327`** — background-boot-and-drive: redirect to `tmp/*.log`, capture
  pid, run driver, kill, cat log on failure.
- **`examples/adoption_demo`** — a working end-to-end wiring reference. Every divergence between it
  and the installer's output is a candidate ledger entry.

### Established Patterns

- **Lanes are Mix aliases delegating to shell scripts.** `mix.exs:71-125`. New maintainer tooling
  follows this rather than introducing a Mix task.
- **Grep-able source markers are treated as contracts.**
  `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` appears in the installer template, the demo router, and
  the smoke driver; `repo_hygiene_check.sh` enforces dozens of contracts with `grep -Fq`. D-40's
  workaround token follows this established mechanism.
- **CI is Docker-daemon-free** (v1.35). Postgres arrives as a GitHub service with `pg_isready`, never
  via `docker compose`. `repo_hygiene_check.sh` BLOCKs `docker compose` in CI paths.
- **`tmp/` is the evidence directory.** Gitignored, allowlisted by hygiene, already used for
  `tmp/adoption_demo.log` and `tmp/admin-ui-polish/`.
- **Public surface is guarded.** `repo_hygiene_check.sh` asserts maintainer tooling does NOT appear
  under `lib/mix/tasks/`.
- **Env-var config convention:** `LOCKSPIRE_<CONTEXT>_DB_*` with `PGHOST`/`PGPORT`/`PGUSER` fallbacks
  (`examples/adoption_demo/config/config.exs:29-43`, `config/test.exs`).

### Integration Points

- **Repo root → generated app:** via `{:lockspire, path: ...}` written into the generated `mix.exs`.
- **Guide sections → walk steps:** the `step-NN` ↔ `docs/install-and-onboard.md` section mapping
  (D-16) is the join key Phase 128's WIRE-01 drift fence will consume.
- **Walk → ledger:** the `LOCKSPIRE_WALK_WORKAROUND: <ID>` token (D-40) is the mechanical link
  Phase 128 uses to prove workarounds were removed.
- **Ledger → Phases 127/128/129:** the `source` and `owning phase` fields (D-37) are those phases'
  scoping input. Phase 127's success criterion 4 reads this ledger directly.
- **Walk → Phase 130:** `mix adopter.walk` is the entry point Phase 130 automates. Deliberately kept
  out of `ci:` here.
- **Generated app → Lockspire:** the forwarded router mount, `AccountResolver` implementation, the
  supervision-tree children, and the protected-route pipeline are the four seams the walk must
  successfully wire.
</code_context>

<specifics>
## Specific Ideas

- **Login seam (user-selected):** `mix phx.gen.auth --live` over a hand-written minimal seam. The
  reasoning that decided it: research empirically generated a Phoenix 1.8.9 app, ran the generator,
  seeded a password-capable user, and completed a real HTTP `POST /users/log-in` returning 302 with a
  session cookie, then `GET /users/settings` returning 200. Since it works non-interactively and is
  Phoenix's own default, it makes the strongest ADOPT-02 claim — a real adopter with no accounts
  reaches for `phx.gen.auth`, not a hand-rolled controller.

- **Token proof (user-selected):** userinfo *plus* a wired protected host route, over userinfo alone.
  The reasoning: userinfo is Lockspire-owned on both ends, so it cannot catch a regression in the
  v1.27 resource-server acceptance path that would break real adopters' API routes.

- **Declined researcher recommendation, recorded deliberately:** the research agent argued the
  migration fix (D-48) should be sequenced ahead of or alongside the harness, since a harness built
  before that fix proves a path no adopter can walk. Declined — the roadmap explicitly locks "do not
  fix defects in this phase," and success criterion 5 exists precisely for this case. The workaround
  is marked per D-40 and the defect is attributed to Phase 127. Noted here so a later reader can see
  the tension was considered rather than missed.
</specifics>

<deferred>
## Deferred Ideas

- **Ship `Lockspire.Migration.up/1` + a host migration generator** (the Oban pattern) — the correct
  fix for D-48, but it is installer work owned by **Phase 127**, not Phase 126.
- **Fix the `/users/log-in` vs `/login` resolver-template mismatch** (D-27) — installer templates,
  **Phase 127**.
- **Make the guide's `mix ecto.migrate` instruction true rather than adding a flag adopters will
  forget** — **Phase 128**.
- **Point `mix lockspire.verify` at `Lockspire.Migration.migrated_version/1`** — follows the D-48 fix,
  **Phase 127/128**.
- **Add the walk to a scheduled/release CI lane and make its failure distinctly attributable** —
  **Phase 130** (GUARD-01, GUARD-03).
- **Correct `scripts/publish/verify_install_truth.sh`'s "Install Truth proven" claim** —
  **Phase 130** (GUARD-02).
- **Pin Elixir/OTP and snapshot the generated `mix.lock`** — residual nondeterminism recorded per
  D-15; hardening it is Phase 130 territory if it proves to matter.
- **Extend the walk to device flow, DCR, and CIBA** — `FUTURE-01`, out of milestone.
- **Prove the path against the minimum supported Elixir/OTP pair** — `FUTURE-02`, out of milestone.
- **Prove the Sigra companion path** — `FUTURE-03`, out of milestone.
- **`mix archive.install github --sparse installer` is structurally broken**
  (`installer/templates/phoenix-usage-rules` is not in git, copied at Hex publish time). Not a
  Lockspire concern; recorded so nobody re-investigates it.

### Reviewed Todos (not folded)

None — `todo.match-phase 126` returned zero matches.
</deferred>
