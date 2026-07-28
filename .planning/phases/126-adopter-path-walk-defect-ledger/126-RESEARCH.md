# Phase 126: Adopter Path Walk & Defect Ledger - Research

**Researched:** 2026-07-28
**Domain:** Maintainer-facing clean-room integration harness (bash + Python stdlib) driving a generated Phoenix 1.8.9 host app through the documented Lockspire adopter path
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Harness Form & Entry Point**

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

**Generated Host App & Environment**

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

**Step Model, Attribution & Resumability (ADOPT-03)**

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

**Host Login Seam (user-confirmed)**

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

**Token Proof (ADOPT-04, user-confirmed)**

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

**Flow Driver**

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

**Defect Ledger**

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

**Known Defects To Seed The Ledger**

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

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | A maintainer can run a single command that walks the whole documented adopter path — generate a Phoenix app, install Lockspire, wire it, migrate, boot it, register a client, complete an authorization-code + PKCE flow — and get one pass/fail verdict. | §Architecture Patterns → *Pattern 1: Mix-alias-over-bash-script lane* (verified: every `mix.exs` lane is `cmd bash scripts/...`); §Architecture Patterns → *Pattern 2: Accumulator + verdict* (from `repo_hygiene_check.sh` `record_result`/`RESULTS[]`/`Summary:`/exit code); §Standard Stack (bash + python3 stdlib + `phx_new` 1.8.9). |
| ADOPT-02 | The walk uses a stock `mix phx.new` app with the defaults a real adopter would use, including Ecto and HTML, rather than a stripped-down variant. | §Common Pitfalls → *Pitfall 1 (archive isolation)*, *Pitfall 2 (asset binaries)*; §Code Examples → *Generate the stock host*; §Architecture Patterns → *Pattern 4: phx.gen.auth login seam* (`docs/ecosystem-overview.md:7,15` already names `phx.gen.auth` as the recommended inbound-auth pairing, so it is the adopter-realistic choice). |
| ADOPT-03 | When the walk fails, a maintainer can see which documented step failed and the underlying error without re-running the earlier steps by hand. | §Architecture Patterns → *Pattern 3: Step model, markers, and resume*; §Don't Hand-Roll (do not re-implement `mktemp`+`trap` teardown); §Common Pitfalls → *Pitfall 8 (record-and-continue vs `set -e`)*. |
| ADOPT-04 | The walk asserts that the flow actually issued a usable token, not merely that each command exited zero. | §Architecture Patterns → *Pattern 5: Two-layer token proof*; §Code Examples → *Protected host route pipeline* (verified: `dpop_replay_store` is `required: false`, so the pipeline needs no host replay-store module); §Common Pitfalls → *Pitfall 6 (`at+jwt` vs opaque token split)*. |

</phase_requirements>

---

## Summary

This phase does not need new technology. Every piece the harness needs already exists in the repo
in a proven form: `scripts/maintainer/repo_hygiene_check.sh` supplies the flag-parsing / accumulator
/ verdict shape, `scripts/demo/adoption_smoke.py` supplies a complete stdlib-only authorization-code
+ PKCE driver, `.github/workflows/ci.yml:313-327` supplies the background-boot-and-drive pattern, and
`examples/adoption_demo` supplies a reference for what a *working* Lockspire wiring looks like. The
research task was therefore verification, not discovery: confirm the CONTEXT decisions against
source, and find the failure mechanisms the plan must anticipate so the walk does not stall in a way
that produces a thin ledger.

Verification confirmed all 49 CONTEXT decisions as sound and produced **ten corrections or
additions** the planner must fold in. Four are new, mechanically-verified defects that will dominate
the walk's early steps: (1) `:lockspire` declares `mod: {Lockspire.Application, []}` and starts an
Oban instance with live queues, and as a plain dependency it starts *before* the host's Repo — the
`included_applications: [:lockspire]` line in the demo's `mix.exs` is load-bearing, not cosmetic, and
nothing documents it; (2) `mix lockspire.client.create` declares `@requirements ["app.config"]`,
which replaces Mix's default `app.start`, so the guide's §6 client-registration command cannot reach
a running Repo in a stock host; (3) `Lockspire.Web.ConsentLive` renders raw `<form method="post">`
tags with **no** `_csrf_token` input, so the moment the host adds the `:browser` pipeline the
LiveView needs for `fetch_session`, it also gets `protect_from_forgery` and the consent POST returns
403; (4) D-42 and D-43 are mutually exclusive on any single run — `lockspire_routes/0` returning a
String means "call it" yields zero routes *and no compile error*, while "paste it" yields the
`:require_operator` compile error. The walk must deliberately exercise both interpretations to
record both defects.

The remaining corrections tighten the flow driver's contract: `phx.gen.auth` login params nest under
`user[...]`, `return_to` on `/users/log-in` is ignored because `log_in_user/3` reads session
`:user_return_to` (set only by `require_authenticated_user` on GET), and `mix lockspire.verify`
(guide §5) is the natural, high-signal detector for the §4 migration no-op because it independently
resolves migrations via `Application.app_dir(:lockspire, ...)` and will report 37 pending.

**Primary recommendation:** Build `scripts/maintainer/adopter_path_walk.sh` as a record-and-continue
step machine with `step-00*` preflight/generation steps, `step-01`..`step-08` mapped 1:1 onto
`docs/install-and-onboard.md` sections, sub-lettered steps inside §3 (where six of the nine known
defects live), per-step `.done` markers under `<workdir>/.walk/steps/`, and a stdlib-only Python
driver adapted from `adoption_smoke.py:221-320`. Every step whose only way forward is a local fix
gets a `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker and a matching ledger row.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Preflight, prerequisite detection, env-var resolution | Maintainer shell (`scripts/maintainer/`) | — | `repo_hygiene_check.sh` establishes shell as the maintainer-tooling tier; prerequisite failures must be distinguishable from Lockspire defects (D-14). |
| Clean-room app generation (`phx.new`, `phx.gen.auth`) | Maintainer shell | Harness-local `MIX_ARCHIVES` | Archive install is a filesystem/env concern, not application code. |
| Applying the documented wiring to the generated host | Maintainer shell (file writes into `<workdir>/host_app`) | — | The wiring is what the *adopter* does by hand; the harness is standing in for the adopter, so it must produce the same files an adopter would. |
| DB lifecycle (`ecto.create`, `ecto.migrate`) | Generated host app's Mix project | Maintainer shell (invocation only) | Migrations must run in the host's Mix context to be a truthful adopter reproduction. |
| Non-interactive data seeding (user, signing key, client) | Generated host app via `mix run -e` | — | `mix run` starts the app, which is the only way to reach a live Repo; `@requirements ["app.config"]` tasks cannot. |
| Server boot + lifecycle (pid capture, log redirect, kill) | Maintainer shell | — | Direct precedent `.github/workflows/ci.yml:313-327`. |
| Authorization-code + PKCE flow over HTTP | Python stdlib driver (`http.client`) | — | Already proven in `adoption_smoke.py`; keeps the repo dependency-free (D-32/D-35). |
| Token usability assertions (ADOPT-04) | Python stdlib driver | Generated host app's protected route | Layer (a) is Lockspire-owned on both ends; layer (b) requires a *host* route, so the responsibility genuinely spans both tiers (D-28/D-29). |
| Verdict aggregation + exit code | Maintainer shell | — | One pass/fail verdict is ADOPT-01's literal requirement; the shell owns the process exit code. |
| Defect attribution and durable evidence | Committed markdown in `.planning/` | Grep-able source markers in the harness | Prose is the consumer format for Phase 127-129 planners (D-39); markers make criterion 5 mechanically checkable (D-40/D-41). |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GNU bash | 5.2.37 (present) | Walk harness, step machine, verdict | `scripts/maintainer/repo_hygiene_check.sh` and every `mix.exs` lane already use `cmd bash scripts/...` — this is the established maintainer tier `[VERIFIED: mix.exs:71-125 read directly]` |
| Python 3 stdlib (`http.client`, `hashlib`, `base64`, `re`, `json`, `urllib.parse`, `http.cookies`) | 3.14.4 (present) | Authorization-code + PKCE flow driver | `scripts/demo/adoption_smoke.py` is stdlib-only and already drives the identical sequence; `.github/workflows/ci.yml:321` invokes it with bare `python3` `[VERIFIED: source read]` |
| `phx_new` (Phoenix installer archive) | `1.8.9` | Generates the stock host app | Pinned by D-06; matches the repo's own `{:phoenix, "~> 1.8.5"}` resolving to `1.8.9` in `mix.lock` `[VERIFIED: mix.lock:38; mix phx.new --version → "Phoenix installer v1.8.9"]` |
| PostgreSQL | 14+ (14.17 local; CI uses `postgres:16`) | Host app + Lockspire storage | `AGENTS.md` declares "PostgreSQL 14+"; supplied by the environment per D-13, never started by the walk `[VERIFIED: AGENTS.md:28, ci.yml:38-56]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mix phx.gen.auth` (ships inside `phoenix` 1.8.9) | 1.8.9 | Host login seam in the generated app | Always — `--live` is mandatory (D-22) `[VERIFIED: deps/phoenix/lib/mix/tasks/phx.gen.auth.ex:1143 contains the interactive prompt]` |
| `bcrypt_elixir` | `~> 3.0` (injected by `phx.gen.auth`) | Password hashing in the generated host | Transitively required; C NIF, needs `cc` + `make` (D-26) `[VERIFIED: cc and make both present on this machine]` |
| `esbuild` / `tailwind` Elixir wrappers (in generated app) | phx.new defaults | Asset pipeline the dev endpoint watches | Must be installed before boot (D-09) `[VERIFIED: prior-session artifact /private/tmp/probe2/_build/esbuild-darwin-arm64 exists]` |
| `curl`, `jq`, `pg_isready` | present | Preflight probes | Only `pg_isready` is strictly needed; `curl`/`jq` are optional since the Python driver does its own HTTP |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| bash script + `mix adopter.walk` alias | `lib/mix/tasks/adopter.walk.ex` | **Rejected (D-02) — mechanism corrected.** `mix.exs:477-489` builds the Hex package from `Path.wildcard("lib/**/*.ex")` with only two exclusions, so a new Mix task under `lib/mix/tasks/` would ship to adopters as public surface. `scripts/` is not in `package_files/0` at all. Note: `repo_hygiene_check.sh:273-276` checks four *specific* filenames, not a generic pattern, so the hygiene gate is not the binding constraint — the package manifest is. `[VERIFIED: mix.exs:477-489, repo_hygiene_check.sh:273-282]` |
| Python stdlib driver | `httpx` / `requests` | Rejected — adds a runtime dependency the repo has deliberately avoided; `adoption_smoke.py` proves stdlib suffices. |
| Python driver | Elixir escript / `mix run` driver | Rejected (D-35) — would need a Mix project context outside the generated app, and the generated app's own project would pull the driver into the adopter's tree. |
| `tmp/adopter-walk/` workdir | `mktemp -d` + `trap 'rm -rf' EXIT` | Rejected (D-20) — destroys evidence on failure, the exact anti-pattern ADOPT-03 forbids. |
| Hex-pinned `{:lockspire, "~> 1.4"}` | — | Rejected (D-04) — proves the last release, not the branch Phases 127-129 will repair. |

**Installation:** No new packages are added to `mix.exs`. The harness installs `phx_new` into an
isolated archive directory at runtime:

```bash
MIX_ARCHIVES="$WORKDIR/../.harness/archives" mix archive.install hex phx_new 1.8.9 --force
```

**Version verification (Hex ecosystem):**

```bash
mix hex.info phx_new           # registry lookup
mix phx.new --version          # resolved installer version → "Phoenix installer v1.8.9"
```

`mix phx.new --version` is the correct assertion (D-07): `Application.spec(:phx_new, :vsn)` returns
`nil` for archives and `Mix.Local.archives_path/0` does not exist on Elixir 1.19.
`[VERIFIED: executed locally on Elixir 1.19.5 / OTP 28 — printed "Phoenix installer v1.8.9"]`

---

## Package Legitimacy Audit

The `gsd-tools query package-legitimacy check` seam supports `npm|pypi|crates` only and has no Hex
backend, so the single external package was verified directly against the Hex registry API.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `phx_new` | Hex | first published 2018-09-22 (~7.8 yrs) | 2,160,812 all-time / 7,796 per week | `github.com/phoenixframework/phoenix` | OK | Approved — pinned to `1.8.9` |

`[VERIFIED: https://hex.pm/api/packages/phx_new queried in-session; package is the official Phoenix
project installer, referenced by hexdocs and already resolved as a dependency of this repo's own
{:phoenix, "~> 1.8.5"}]`

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

Transitively, `mix phx.gen.auth` injects `bcrypt_elixir ~> 3.0` into the *generated* host app. That
is Phoenix's own generator output, not a Lockspire dependency choice, and it never enters this
repo's `mix.exs`. No `checkpoint:human-verify` gate is warranted.

**Nothing is added to `mix.exs` deps by this phase.** The only `mix.exs` change is one alias line.

---

## Architecture Patterns

### System Architecture Diagram

```
                    maintainer
                         │  mix adopter.walk [--workdir DIR] [--from-step NN] [--keep] [--port N]
                         ▼
        ┌────────────────────────────────────────────────────────────┐
        │  scripts/maintainer/adopter_path_walk.sh                   │
        │  flag parse → record_result[] accumulator → Summary → exit │
        └───────┬───────────────────────────────────┬────────────────┘
                │                                   │
                │ step-00a preflight                │ reads/writes
                ▼                                   ▼
   ┌──────────────────────────┐        ┌───────────────────────────────┐
   │ ENV probes               │        │ <workdir>/  (tmp/adopter-walk)│
   │ mix · python3 · cc/make  │        │  ├── host_app/     generated  │
   │ pg_isready ──► Postgres  │◄───────┤  ├── server.log    boot output│
   │ MIX_ARCHIVES=.harness/   │        │  └── .walk/steps/  .done marks│
   └──────────────────────────┘        └───────────────┬───────────────┘
                │ FAIL ⇒ "PREREQUISITE" exit,                  │
                │        never a ledger entry (D-14)           │
                ▼                                              │
   step-00b  mix phx.new host_app --database postgres --install│
   step-00c  mix phx.gen.auth Accounts User users --live       │
                │                                              │
                ▼                                              │
   ┌─────────────────── documented adopter path ───────────────┴──────────┐
   │ step-01 §1  add {:lockspire, path: <repo root>} · deps.get           │
   │ step-02 §2  mix lockspire.install                                    │
   │ step-03 §3  wire  ──┬─ 03a import_config "lockspire.exs"             │
   │                     ├─ 03b router: import + lockspire_routes/0       │
   │                     ├─ 03c AccountResolver: resolve_account,         │
   │                     │       build_claims, login_path                 │
   │                     ├─ 03d supervision tree + included_applications  │
   │                     └─ 03e protected API pipeline (docs/protect-…md) │
   │ step-04 §4  mix ecto.create · mix ecto.migrate                       │
   │ step-05 §5  mix lockspire.verify                                     │
   │ step-06 §6  seed signing key · register client  (via mix run -e)     │
   └───────────────────────────────┬──────────────────────────────────────┘
                                   │ each sub-step: PASS ⇒ touch .done
                                   │               FAIL ⇒ record + continue (D-18)
                                   ▼
                       mix phx.server &  (pid captured, log → server.log)
                                   │
                                   ▼
   ┌──────────────────────────────────────────────────────────────────────┐
   │ scripts/maintainer/adopter_path_flow.py   (stdlib http.client)       │
   │                                                                      │
   │ wait_until_ready ──► GET /lockspire/.well-known/openid-configuration │
   │                 ──► GET /lockspire/jwks   (must have ≥1 key)         │
   │  step-07 §6:                                                         │
   │   GET  /lockspire/authorize?…code_challenge=S256   ──302──►          │
   │   POST /users/log-in  (user[email]/user[password] + _csrf_token)     │
   │   GET  <return_to>  ──302──► interaction resume                      │
   │   GET  /lockspire/consent/:id       (LiveView static render)         │
   │   POST /lockspire/interactions/:id/complete  decision=approve        │
   │        ──302──► /oauth/callback?code=…&state=…                       │
   │   POST /lockspire/token  grant_type=authorization_code+code_verifier │
   │  step-08 ADOPT-04:                                                   │
   │   GET  /lockspire/userinfo   Bearer ──► 200 + sub + resolver claim   │
   │   GET  /api/protected        Bearer ──► 200  (host route, at+jwt)    │
   │   GET  /api/protected        anon    ──► 401                         │
   └──────────────────────────────┬───────────────────────────────────────┘
                                  │ nonzero ⇒ cat server.log
                                  ▼
                 kill $server_pid · Summary: N PASS, M FAIL · exit
                                  │
                                  ▼
        126-DEFECT-LEDGER.md  ◄── each FAIL + each # LOCKSPIRE_WALK_WORKAROUND
        (source · owning phase · workaround ID)
```

### Recommended Project Structure

```
scripts/maintainer/
├── repo_hygiene_check.sh          # existing — the template to follow
├── adopter_path_walk.sh           # NEW — step machine, verdict, exit code
└── adopter_path_flow.py           # NEW — stdlib PKCE driver (name at discretion)

.planning/phases/126-adopter-path-walk-defect-ledger/
├── 126-CONTEXT.md
├── 126-RESEARCH.md
└── 126-DEFECT-LEDGER.md           # NEW — committed evidence (D-36)

tmp/adopter-walk/                  # gitignored evidence workdir (D-19/D-20)
├── host_app/                      # generated Phoenix app, preserved on failure
├── server.log
└── .walk/steps/step-03b.done      # resume markers

.harness/archives/                 # gitignored isolated MIX_ARCHIVES (D-06/D-08)
```

### Pattern 1: Maintainer lane = Mix alias delegating to bash

Every lane in `mix.exs` is an alias, and maintainer-tier lanes shell out. Follow it exactly.

```elixir
# mix.exs aliases/0 — add one entry, do NOT add it to ci:
"adopter.walk": ["cmd bash scripts/maintainer/adopter_path_walk.sh"]
```

`[VERIFIED: mix.exs:71-125 — "conformance.phase37" already uses "cmd bash scripts/conformance/run_phase37_suite.sh"]`

**When to use:** all new maintainer tooling.
**Do not** add it to the `ci:` alias in this phase (D-01) — `ci:` is the contributor gate and this
walk generates a full app, compiles a bcrypt NIF, downloads asset binaries, and boots a server.

### Pattern 2: Accumulator + summary + verdict exit code

```bash
declare -a RESULTS=()
PASS_COUNT=0; FAIL_COUNT=0

record_result() {              # level label detail
  RESULTS+=("[$1] $2: $3")
  case "$1" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
  esac
}

# ... at the end
printf 'Lockspire adopter path walk report\n'
printf '%s\n' "${RESULTS[@]}"
printf 'Summary: %s PASS, %s FAIL\n' "$PASS_COUNT" "$FAIL_COUNT"
[[ "$FAIL_COUNT" -gt 0 ]] && { echo "Result: adopter path is RED"; exit 1; }
echo "Result: adopter path is GREEN"
```

`[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:66-82, 503-521 — identical shape with
PASS/WARN/BLOCK]`

**Adaptation note:** the hygiene script uses three levels because it distinguishes advisory drift
from blocking drift. The walk has a binary contract (ADOPT-01: "one pass/fail verdict"), so use
`PASS`/`FAIL` only, plus a distinct non-ledger `PREREQUISITE` exit path for D-14.

### Pattern 3: Step model, markers, and resume (ADOPT-03)

Step IDs mirror the guide's section numbers (D-16). Six of the nine known defects live in guide §3,
so §3 gets sub-lettered steps — that is the difference between "step-03 failed" and "step-03d failed
because the host has no `included_applications: [:lockspire]`".

| Step ID | Guide section | Action |
|---------|---------------|--------|
| `step-00a-preflight` | — (pre-guide) | probe `mix`, `python3`, `cc`, `make`, Postgres, port |
| `step-00b-phx-new` | — (pre-guide) | `mix phx.new host_app --database postgres --install` |
| `step-00c-gen-auth` | — (pre-guide) | `mix phx.gen.auth Accounts User users --live` |
| `step-01-add-dep` | §1 Add Lockspire | write `{:lockspire, path: …}`; `mix deps.get`; `mix compile` |
| `step-02-install` | §2 Generate the host seam | `mix lockspire.install` |
| `step-03a-config-import` | §3 Wire the generated files | `import_config "lockspire.exs"` |
| `step-03b-router` | §3 | import `…Web.Router.Lockspire`, call `lockspire_routes/0` |
| `step-03c-resolver` | §3 | implement `resolve_account/2`, `build_claims/2`, fix `login_path` |
| `step-03d-app-tree` | §3 | supervision children + `included_applications` |
| `step-03e-protected-route` | §3 (+§6) | `:lockspire_protected_api` pipeline + one host route |
| `step-04-migrate` | §4 Run migrations | `mix ecto.create`; `mix ecto.migrate` |
| `step-05-verify` | §5 Verify the install wiring | `mix lockspire.verify` |
| `step-06-client` | §6 Create a client | signing key + `lockspire.client.create` |
| `step-07-flow` | §6 Prove the flow | boot + authorization-code + PKCE |
| `step-08-token-proof` | §6 (ADOPT-04) | userinfo + protected host route |

Guide §7 (`mix lockspire.upgrade`) and §8 (device `/verify` seam) are outside the authorization-code
path. **Record them explicitly as "not walked"** in the ledger rather than leaving them
unaccounted — a reader must be able to tell "checked, out of scope" from "missed".

Resume mechanics:

```bash
step_done()  { [[ -f "$WORKDIR/.walk/steps/$1.done" ]]; }
mark_done()  { mkdir -p "$WORKDIR/.walk/steps"; : > "$WORKDIR/.walk/steps/$1.done"; }
should_run() {
  [[ -n "$FROM_STEP" && "$1" < "$FROM_STEP" ]] && return 1
  step_done "$1" && [[ -z "$FORCE" ]] && { record_result PASS "$1" "skipped (already done)"; return 1; }
  return 0
}
```

### Pattern 4: `phx.gen.auth` login seam over plain HTTP

The generated login is a LiveView (`live "/users/log-in"`) with a companion
`post "/users/log-in"` controller action. The driver never needs JavaScript: it GETs the LiveView's
static render, scrapes the CSRF token, and POSTs the form directly.

`[VERIFIED: deps/phoenix/priv/templates/phx.gen.auth/routes.ex.eex — live? branch emits
live "/<plural>/log-in" plus post "/<plural>/log-in"]`

### Pattern 5: Two-layer token proof (ADOPT-04)

Layer (a) `GET <mount>/userinfo` is free — it is already inside the forwarded router. Layer (b) is
the one that matters, and it is cheap: `dpop_replay_store` is declared `required: false` in
`Lockspire.Plug.EnforceSenderConstraints`'s NimbleOptions schema, so the host needs **no** replay
store module.

`[VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex:15-17 — dpop_replay_store required: false]`

Assert three outcomes, not one:

1. `GET /api/protected` with no header → `401`
2. `GET /api/protected` with the issued bearer → `200`
3. response body/assigns reflect `conn.assigns.access_token` fields

Two and three together are what make "exit code zero" insufficient.

### Anti-Patterns to Avoid

- **`set -e` at the top of the walk.** It converts every step failure into an abort, which is exactly
  what D-18 forbids and would yield a one-entry ledger. Use `set -uo pipefail` and explicit
  `if ! cmd; then record_result FAIL ...; fi` blocks. Reserve `set -e` for the preflight function.
- **`mktemp -d` + `trap 'rm -rf' EXIT`.** Destroys the evidence ADOPT-03 requires (D-20).
- **Editing `scripts/demo/adoption_smoke.py`.** `repo_hygiene_check.sh:262-267` is a BLOCK-level
  contract on that file's contents `[VERIFIED: source read]`.
- **Adding the walk to `ci:`.** Deliberately deferred to Phase 130 (D-01).
- **Silently patching around a defect.** Every workaround needs a `# LOCKSPIRE_WALK_WORKAROUND:
  ADOPT-Dnn` marker (D-40) — criterion 5's failure mode is precisely an unmarked one.
- **Recording a missing prerequisite as a Lockspire defect.** `pg_isready` failing is an environment
  problem, not evidence (D-14).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authorization-code + PKCE flow over HTTP | A new client from scratch | Adapt `adoption_smoke.py:221-320` — `Browser`, `csrf()`, `code_challenge()`, `assert_status`, `json_body`, `location`, `wait_until_ready` | It already handles the cookie jar, redirect chasing (max 8 hops, 303/non-GET method downgrade), and the exact interaction-resume sequence `[VERIFIED: source read]` |
| PASS/FAIL accumulation and verdict | New reporting format | `repo_hygiene_check.sh`'s `record_result`/`RESULTS[]`/`Summary:` | Already the maintainer-facing convention; Phase 130's GUARD-03 will parse it |
| Background boot, log capture, kill, dump-on-failure | New process supervision | `.github/workflows/ci.yml:313-327` verbatim shape | Proven in CI against a real Phoenix server |
| Signing key generation | Hand-built JOSE key + Repository insert | `Lockspire.Admin.generate_key(:sig)` | Public API exists at `lib/lockspire/admin.ex:192-194`; the demo's manual `seeds.exs:78-95` JOSE construction is the thing Phase 127 should *stop* requiring `[VERIFIED: both read]` |
| Migration path resolution | `deps/lockspire/priv/repo/migrations` | `Application.app_dir(:lockspire, "priv/repo/migrations")` | The `deps/` form is structurally broken in releases (D-48/D-49); `lockspire.test.setup.ex:34` and `install/verify.ex:196` both already use the `app_dir` form `[VERIFIED: both read]` |
| Migration-state assertion | Custom `schema_migrations` query | `mix lockspire.verify` | It starts the repo via `Ecto.Migrator.with_repo/2` and independently checks pending migrations, `lockspire_clients`, and `oban_jobs` table existence in the configured prefixes `[VERIFIED: lib/lockspire/install/verify.ex:195-227]` |
| Non-interactive password user | Custom Ecto inserts against `users` | `phx.gen.auth`'s own context functions in D-23's order | `register_user/1` uses `email_changeset/3` only, so a direct insert would silently produce a password-less user `[VERIFIED: deps/phoenix/priv/templates/phx.gen.auth/context_functions.ex.eex:69,156,213,263]` |

**Key insight:** every reusable asset here is already in-repo and already load-bearing in CI. The
research risk in this phase is not "which library" — it is "which of the nine known defects blocks
which step, and what is the smallest marked workaround that keeps the walk moving." That is what the
Common Pitfalls section below is for.

---

## Runtime State Inventory

Not a rename/refactor phase, so the classic inventory does not apply. What *does* apply is the
inverse question: **the harness itself creates runtime state outside the repo, and every one of those
must be isolated or the walk corrupts the maintainer's machine.**

| Category | Items the harness touches | Action required |
|----------|---------------------------|-----------------|
| Mix archives | `phx_new` is keyed one-entry-per-app-name globally in `~/.mix/archives` (confirmed: `hex-2.5.1`, `phx_new-1.8.9` present) | **Must** set `MIX_ARCHIVES="$REPO/.harness/archives"` for every archive-touching command (D-06). An unisolated `archive.install --force` overwrites the maintainer's global installer. |
| PostgreSQL databases | `mix ecto.create` creates `host_app_dev`; migrations create the `lockspire` schema | Use a walk-specific database name (e.g. `lockspire_adopter_walk_dev`) via `LOCKSPIRE_WALK_DB_NAME`; drop-and-recreate on a fresh run, preserve on `--keep`. Never collide with `lockspire_test` or `lockspire_adoption_demo`. |
| TCP ports | Default 4200 (verified free); 4100 is claimed by `examples/adoption_demo` and Cairnloop (D-12); 4000 is `phx.new`'s default and likely contended | Override the generated endpoint port before boot; preflight the port and FAIL as PREREQUISITE if bound. |
| Background processes | `mix phx.server` child; on a crashed walk the pid can outlive the script | `trap` on `EXIT`/`INT`/`TERM` that kills only the captured pid — **not** an `rm -rf` trap (D-20). |
| Filesystem | `tmp/adopter-walk/` (gitignored via `/tmp/`), `.harness/` (needs a new `.gitignore` entry per D-08) | `.gitignore` currently has `/tmp/` but no `.harness/` entry `[VERIFIED: .gitignore read]` — the plan must add it. |
| Asset binaries | `_build/esbuild-*`, `_build/tailwind-*` download from the network on first `--install` | Preflight should note network dependence; on rerun with `--keep` these are already cached in the workdir. |

**Nothing found:** no secrets, env-var renames, OS-registered tasks, or stored-data migrations are
involved — verified by inspection of the phase scope, which adds no library code.

---

## Common Pitfalls

### Pitfall 1: `mix archive.install` silently overwrites the maintainer's global `phx_new`

**What goes wrong:** Mix archives are keyed one entry per app name. Installing `phx_new 1.8.9`
globally replaces whatever the maintainer had, permanently, without a diff.
**Why it happens:** `verify_install_truth.sh:71` does exactly this (`mix archive.install hex phx_new
--force`) because it runs in a disposable CI container. The walk runs on a maintainer's laptop.
**How to avoid:** export `MIX_ARCHIVES` to a repo-local path before any archive command, and add
`.harness/` to `.gitignore`.
**Warning signs:** `mix phx.new --version` outside the walk changes after a run.
`[VERIFIED: ~/.mix/archives listing shows exactly one phx_new entry; verify_install_truth.sh:71 read]`

### Pitfall 2: The dev endpoint enters a watcher restart loop without asset binaries

**What goes wrong:** the generated `config/dev.exs` endpoint declares esbuild/tailwind watchers. If
the binaries are absent the watcher child re-raises, blows past `max_restarts`, and the endpoint
supervisor restarts on a ~4s cycle. The listener rebinds each time.
**How to avoid:** `mix phx.new … --install` up front, or pre-seeded `_build/esbuild-*` /
`_build/tailwind-*` on rerun (D-09). Only if both fail, set `watchers: []` **with** a
`# LOCKSPIRE_WALK_WORKAROUND` marker and a ledger row.
**Correction to D-09's stated rationale:** the operative risk is HTTP-level flakiness from listener
rebinding, *not* a dropped LiveView WebSocket. Lockspire's consent decision is a plain
`<form method="post">` submit, not a `phx-click` event, so the walk never opens a WebSocket at all.
D-09's conclusion (install assets) is correct; its "consent click needs a stable WS" reasoning is not.
`[VERIFIED: lib/lockspire/web/live/consent_live.ex:81-93 — two raw <form action=… method="post"> tags,
no phx-click on the decision path]`

### Pitfall 3: `:lockspire` starts before the host Repo, with live Oban queues

**What goes wrong:** the host boots and immediately dies (or crash-loops) inside Oban's queue
producers with a connection error against a Repo that has not started.
**Why it happens:** three facts compose:
1. `mix.exs:31-36` declares `mod: {Lockspire.Application, []}`, and
   `lib/lockspire/application.ex:10-14` starts `{Lockspire.Oban, Lockspire.Oban.runtime_config!()}`,
   `Cachex.child_spec(name: :lockspire_jwks_cache)`, and `Lockspire.KeyCache`.
2. `:lockspire` is a *dependency* of the host, so OTP starts it **before** the host application and
   therefore before the host's `Repo`.
3. `lib/lockspire/oban.ex:19` does `Keyword.put_new(:queues, @default_queues)` where
   `@default_queues = [logout_backchannel: 10, ciba_notification: 10]`. Because the installer's
   `config.exs` template emits no `oban:` key, `Application.get_env(:lockspire, :oban, [])` is `[]`
   and the queues are **live**.

`examples/adoption_demo` neutralises both halves — `included_applications: [:lockspire]` in
`mix.exs:22` suppresses the automatic application start so the host can order
`AdoptionDemo.Repo` first, and `oban: [queues: false, plugins: false]` in `config/config.exs:76`
disables the producers. **Neither appears anywhere in `docs/install-and-onboard.md` or the installer
templates.**
**How to avoid (in the walk):** perform both in `step-03d-app-tree` as the documented "wire the
generated files" work, and record the omission as a ledger defect against the installer + guide
(this is the mechanism behind D-45 and D-46 — the plan should merge them into a single, precisely
attributed entry rather than two vague ones).
**Warning signs:** `server.log` shows `Lockspire.Oban` or `DBConnection` errors before any
`AdoptionDemo.Repo`/`HostApp.Repo` line.
`[VERIFIED: mix.exs:31-36, lib/lockspire/application.ex:9-17, lib/lockspire/oban.ex:7-29,
examples/adoption_demo/mix.exs:17-23, examples/adoption_demo/config/config.exs:62-77]`

### Pitfall 4: D-42 and D-43 cannot both fire on one run — plan to exercise both

**What goes wrong:** the planner writes one `step-03b` expecting "compile error from
`:require_operator`", the walk instead compiles cleanly with zero Lockspire routes, and one of the
two defects goes unrecorded.
**Why it happens:** `lockspire_routes/0` returns a heredoc **String**. The guide and the installer's
own post-run instructions both say *call* it
(`docs/install-and-onboard.md:58`, `lib/lockspire/generators/install.ex:136`). Calling it inside the
router module body evaluates to a discarded string — **zero routes defined, and no compile error,
because `pipe_through [:browser, :require_operator]` is never Elixir code.** The `:require_operator`
compile error only appears if the adopter *pastes* the string's contents, which is what a human
reading the heredoc would naturally do.
**How to avoid:** make `step-03b` two observations:
- `step-03b-router-call` — follow the guide literally. Assert routes are defined. Expect FAIL:
  compiles clean, `mix phx.routes` shows no Lockspire mount. Ledger entry: installer.
- `step-03b-router-paste` — apply the paste interpretation as the marked workaround that lets the
  walk continue. Expect FAIL: `the pipeline :require_operator has not been defined`. Ledger entry:
  installer.
Then apply the real wiring (define an operator pipeline or drop it) as a third marked workaround so
`step-04` can be reached.
`[VERIFIED: priv/templates/lockspire.install/router.ex:9-62 is `def lockspire_routes do """…""" end`;
docs/install-and-onboard.md:58; lib/lockspire/generators/install.ex:136]`

### Pitfall 5: The consent POST is a CSRF trap in both directions

**What goes wrong:** whichever way the host pipeline is wired, one half of the consent exchange
breaks.
**Why it happens:** `Lockspire.Web.Router:31` mounts `live "/consent/:interaction_id"`.
`Phoenix.LiveView.Plug` reads the session, so the route needs `fetch_session` — but the installer
template forwards it through a pipeline-less `scope "/"` (D-44), so the GET raises
"session not fetched". Adding the `:browser` pipeline fixes the GET *and* enables
`protect_from_forgery`. And `ConsentLive`'s decision forms are raw
`<form action={@finalize_path} method="post">` tags with **no** `_csrf_token` input — so the POST
then returns `403 InvalidCSRFTokenError`.

`examples/adoption_demo` sidesteps this entirely by shadowing the route: its router defines
`get("/consent/:interaction_id", AdoptionDemoWeb.ConsentController, :show)` inside a `:browser`
scope *before* the forward, and that host controller explicitly calls
`Plug.CSRFProtection.get_csrf_token()`. **The reference demo therefore never exercises Lockspire's
shipped `ConsentLive` over HTTP** — a REF-01/REF-02 finding for Phase 129 that this walk will be the
first thing to surface.
**How to avoid (in the driver):** scrape the CSRF token with a fallback chain —
(1) a `_csrf_token` form input, then (2) `<meta name="csrf-token" content="…">`, which the stock
phx.new root layout renders and `protect_from_forgery` accepts. Record the missing form token as a
library-source ledger defect.
`[VERIFIED: lib/lockspire/web/router.ex:29-31; lib/lockspire/web/live/consent_live.ex:81-93 —
no csrf input; examples/adoption_demo/lib/adoption_demo_web/router.ex:53-59 and
controllers/consent_controller.ex:24 — Plug.CSRFProtection.get_csrf_token()]`

### Pitfall 6: `mix lockspire.client.create` cannot reach a running Repo

**What goes wrong:** guide §6's documented client-registration command raises an Ecto
"repository is not started" error in a stock host.
**Why it happens:** the task declares `@requirements ["app.config"]`, which **replaces** Mix's
default `app.start`. `app.config` loads configuration but starts nothing, and unlike
`mix lockspire.verify` — which calls `Ecto.Migrator.with_repo/2` and starts the repo itself — the
create task calls `Clients.register_client/1` directly.
**How to avoid:** register the client via `mix run -e '...'` (which does start the app) as a marked
workaround, and record the defect against the installer/library with owning phase 127. The same
applies to the `Lockspire.Admin.generate_key(:sig)` call in `step-06`.
`[VERIFIED: lib/mix/tasks/lockspire.client.create.ex:10,37-39 vs lib/lockspire/install/verify.ex:202]`

### Pitfall 7: `phx.gen.auth` login params nest under `user[...]`, and `return_to` is ignored

**What goes wrong:** the driver POSTs flat `email=`/`password=` and gets a `FunctionClauseError`
or a redirect back to the login page; or it appends `?return_to=…` and lands on `/` instead of the
pending interaction.
**Why it happens (correction to D-24):** `UserSessionController.create/2` matches
`%{"user" => %{"token" => token}}` and `%{"user" => %{"email" => e, "password" => p}}` — the params
are nested. `LoginLive` builds its form with `to_form(%{"email" => email}, as: "user")`, so the
rendered input names are `user[email]`, `user[password]`, `user[remember_me]`.
Separately, `UserAuth.log_in_user/3` redirects to `get_session(conn, :user_return_to) ||
signed_in_path(conn)` and `maybe_store_return_to/1` only writes that session key on a **GET** through
`require_authenticated_user`. A `return_to` query param on `/users/log-in` is therefore inert.
**How to avoid:** POST `_csrf_token`, `user[email]`, `user[password]`; then have the driver navigate
to the `return_to` value it captured from the `/authorize` handoff itself. Record the resulting
resolver mismatch (`login_path: "/login"` vs `/users/log-in`, D-27) and the ignored-`return_to`
behavior as ledger entries against the installer templates.
`[VERIFIED: deps/phoenix/priv/templates/phx.gen.auth/session_controller.ex.eex:11,32-34;
login_live.ex.eex:104; auth.ex.eex:32-40,316-320]`

### Pitfall 8: `mix ecto.migrate` runs zero Lockspire migrations, and §5 is where it surfaces

**What goes wrong:** `step-04` reports PASS (the command exits 0 — the host has its own
`phx.gen.auth` migration to run), and the walk only discovers the missing 37 tables at flow time as
an opaque SQL error.
**Why it happens:** bare `mix ecto.migrate` reads the host's `priv/repo/migrations`. Lockspire's 37
migrations live in the dependency's `priv/repo/migrations` and are never enumerated.
**How to avoid:** do **not** treat `step-04`'s exit code as the assertion. Let `step-05-verify` be
the detector — `mix lockspire.verify` resolves migrations via
`Application.app_dir(:lockspire, "priv/repo/migrations")` and reports pending count plus
`lockspire_clients` / `oban_jobs` table existence in the configured prefixes. That produces a clean,
attributable FAIL. Then apply the `Application.app_dir` `--migrations-path` form as the marked
workaround (D-49) and re-run `step-04`.
**Warning signs:** `mix ecto.migrations` in the host shows 37 rows of `** FILE NOT FOUND **` after
the workaround runs — because `--migrations-path` shares the single `schema_migrations` table.
`[VERIFIED: 37 files in priv/repo/migrations; lib/lockspire/install/verify.ex:196-227;
deps/ecto_sql/lib/ecto/migration/schema_migration.ex:69-72 reads :migration_source from repo config
only; deps/oban/lib/oban/migration.ex:161,182,193 confirms the up/down/migrated_version convention]`

### Pitfall 9: `resolve_account/2` and `build_claims/2` raise by design

**What goes wrong:** the app compiles and boots, then the flow dies at consent or token time with a
`RuntimeError` whose message is the template's own "Implement … before shipping Lockspire" text.
**Why it happens:** both callbacks in `priv/templates/lockspire.install/account_resolver.ex:37-70`
`raise` unconditionally. The guide §3 says "Implement the generated `AccountResolver` with … Account
lookup by subject reference / Claim building for ID token and userinfo" but supplies no code, no
`sub` format contract, and no worked example — only the docstring inside the raise.
**How to avoid:** implement both in `step-03c` (that *is* the documented step) and record the
absence of a worked example as a WIRE-02 guide defect for Phase 128. The good news:
`current_account/1` already pattern-matches `%Plug.Conn{assigns: %{current_scope: %{user: user}}}`,
which is exactly what `phx.gen.auth --live` assigns — so `resolve_current_account/2` works
unmodified. Only `resolve_account/2`, `build_claims/2`, and `login_path` need host code.
`[VERIFIED: priv/templates/lockspire.install/account_resolver.ex:37-70,73-81,94-105]`

### Pitfall 10: `set -e` turns nine defects into one

**What goes wrong:** the walk aborts at `step-03b`'s compile error and the ledger has a single row.
**Why it happens:** the natural bash reflex, and `repo_hygiene_check.sh:2` uses `set -euo pipefail`
— but every one of its checks is a pure predicate inside an `if`, so nothing ever trips it.
**How to avoid:** `set -uo pipefail` only. Wrap every step in
`if run_step_cmd; then record_result PASS …; mark_done …; else record_result FAIL …; fi`. Reserve
`set -e` for the preflight function via a subshell.
`[VERIFIED: scripts/maintainer/repo_hygiene_check.sh:2 and its check bodies]`

---

## Code Examples

### Generate the stock host app with isolated archives

```bash
# Source: adapted from scripts/publish/verify_install_truth.sh:66-75, with D-05/D-06 corrections
export MIX_ARCHIVES="$REPO_ROOT/.harness/archives"
mix local.hex --force --if-missing
mix local.rebar --force --if-missing
mix archive.install hex phx_new 1.8.9 --force

installer_version="$(mix phx.new --version)"
[[ "$installer_version" == "Phoenix installer v1.8.9" ]] || \
  fail_prerequisite "phx_new" "expected 'Phoenix installer v1.8.9', got '$installer_version'"

cd "$WORKDIR"
# ADOPT-02: keep Ecto, HTML, LiveView, mailer, assets. --install fetches deps + asset binaries (D-09).
mix phx.new host_app --database postgres --install --no-install-prompt 2>/dev/null \
  || yes | mix phx.new host_app --database postgres --install
```

> `--no-install-prompt` is not a documented `phx.new` flag; the plan should verify empirically and
> otherwise pipe `yes` or set `MIX_QUIET`. `[ASSUMED]`

### Generate the login seam non-interactively

```bash
# Source: D-21/D-22. --live is mandatory or the generator blocks on
# "Do you want to create a LiveView based authentication system?"
# [VERIFIED: deps/phoenix/lib/mix/tasks/phx.gen.auth.ex:1143]
cd "$WORKDIR/host_app"
mix phx.gen.auth Accounts User users --live
mix deps.get          # pulls bcrypt_elixir ~> 3.0 (C NIF — needs cc + make, D-26)
```

### Seed a password-capable user (D-23, exact order)

```bash
# Source: deps/phoenix/priv/templates/phx.gen.auth/context_functions.ex.eex:69,156,213,263
mix run -e '
  alias HostApp.{Accounts, Repo}
  alias HostApp.Accounts.UserToken

  email = "walker@adopter.test"
  password = "adopter-walk-password"     # >= 12 chars

  {:ok, user} = Accounts.register_user(%{email: email})
  {encoded, token} = UserToken.build_email_token(user, "login")
  Repo.insert!(token)
  {:ok, {user, _}} = Accounts.login_user_by_magic_link(encoded)      # confirms
  {:ok, {_user, _}} = Accounts.update_user_password(user, %{password: password})
  IO.puts("seeded #{email}")
'
```

### Register the client and mint a signing key (Pitfall 6 workaround)

```bash
# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn
# `mix lockspire.client.create` declares @requirements ["app.config"], which replaces Mix's
# default app.start, so it never reaches a running Repo. `mix run` does start the app.
# Source: lib/mix/tasks/lockspire.client.create.ex:10
mix run -e '
  {:ok, _key} = Lockspire.Admin.generate_key(:sig)
  {:ok, result} = Lockspire.Clients.register_client(%{
    client_id: "adopter-walk-public",
    name: "Adopter Walk",
    client_type: "public",
    redirect_uris: ["'"$BASE_URL"'/oauth/callback"],
    allowed_scopes: ["openid", "email", "profile", "read:walk"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    token_endpoint_auth_method: "none"
  })
  IO.puts("client_id=" <> result.client.client_id)
'
```

### Protected host route pipeline (ADOPT-04 layer b)

```elixir
# Source: docs/protect-phoenix-api-routes.md "Canonical plug order", narrowed.
# dpop_replay_store is required: false, so no host replay-store module is needed.
# [VERIFIED: lib/lockspire/plug/enforce_sender_constraints.ex:15-17]
# BEGIN LOCKSPIRE_PROTECTED_PIPELINE
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:walk"]
  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end
# END LOCKSPIRE_PROTECTED_PIPELINE

scope "/api", HostAppWeb do
  pipe_through [:api, :lockspire_protected_api]
  get "/walk/summary", WalkApiController, :show
end
```

### CSRF scrape with the fallback chain (Pitfall 5 + D-25)

```python
# Source: adapted from scripts/demo/adoption_smoke.py:99-103.
# The demo's r'name="_csrf_token"\s+value="..."' pattern MISSES LiveView output, which renders
# name="_csrf_token" type="hidden" hidden value="...". Lockspire's ConsentLive emits no token at
# all, so fall back to the root layout's <meta name="csrf-token">.
_FORM_TOKEN = re.compile(r'name="_csrf_token"[^>]*\bvalue="([^"]+)"')
_META_TOKEN = re.compile(r'<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"')

def csrf(body, label="page"):
    for pattern in (_FORM_TOKEN, _META_TOKEN):
        match = pattern.search(body)
        if match:
            return match.group(1)
    raise AssertionError(f"{label}: missing CSRF token")
```

### Login POST with the correct param nesting (Pitfall 7)

```python
# Source: deps/phoenix/priv/templates/phx.gen.auth/session_controller.ex.eex:32-34
#         deps/phoenix/priv/templates/phx.gen.auth/login_live.ex.eex:104 (to_form(..., as: "user"))
def login(browser, email, password):
    page = browser.request("GET", "/users/log-in")
    assert_status(page, 200, "login page")
    return browser.request("POST", "/users/log-in", {
        "_csrf_token": csrf(page["body"], "login page"),
        "user[email]": email,
        "user[password]": password,
    })
```

### Background boot, drive, teardown (D-11)

```bash
# Source: .github/workflows/ci.yml:313-327
mkdir -p "$WORKDIR"
( cd "$WORKDIR/host_app" && MIX_ENV=dev mix phx.server ) > "$WORKDIR/server.log" 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT INT TERM   # NOT rm -rf (D-20)

set +e
python3 scripts/maintainer/adopter_path_flow.py --base-url "$BASE_URL"
flow_status=$?
set -o pipefail

kill "$server_pid" 2>/dev/null || true
if [ "$flow_status" -ne 0 ]; then
  cat "$WORKDIR/server.log"
fi
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Library ships `priv/repo/migrations` and tells adopters to pass `--migrations-path deps/<lib>/…` | Library ships `Lib.Migration.up/1` / `down/1` / `migrated_version/1` and its installer writes one host migration into `priv/repo/migrations/` | Oban has used this since its early 2.x line; adopted by Pow, AshPostgres, Rihanna | Converts DDL from files-on-disk to BEAM code, which is what makes Mix releases work. This is the D-48 fix, owned by Phase 127. `[VERIFIED: deps/oban/lib/oban/migration.ex:161,182,193 + module docs showing the generated host migration calling Oban.Migrations.up()]` |
| `mix phx.gen.auth` produced controller-based auth with `current_user` assigns | Phoenix 1.8 produces LiveView auth with `current_scope` assigns, magic-link + password dual login, and `live_session` on-mounts | Phoenix 1.8 | The installer's `account_resolver.ex` template already reads `current_scope.user`, so it aligns; but the guide never mentions the `/users/log-in` path this produces `[VERIFIED: deps/phoenix/priv/templates/phx.gen.auth/routes.ex.eex, scope.ex.eex]` |
| `Plug.Cowboy` adapter default | `Bandit.PhoenixAdapter` default in Phoenix 1.8 | Phoenix 1.7→1.8 | Underlies D-10's warning that `--config override.exs` clobbers the endpoint config and reintroduces the Cowboy code path |
| Configuring an app with `mix run --config override.exs` | Deprecated in Elixir 1.19 | Elixir 1.19 | Confirms D-10's "do not attempt" list `[ASSUMED — D-10 reports this was verified empirically during discuss-phase; not re-verified here]` |

**Deprecated/outdated in this repo's own tooling:**

- `scripts/publish/verify_install_truth.sh` claims "Install Truth proven" after only
  `mix deps.get` + `mix compile` against a `--no-assets --no-ecto --no-html --no-mailer` app. It
  never runs the installer, migrates, boots, or completes a flow. Correcting the claim is Phase 130's
  GUARD-02; this phase must not touch it. `[VERIFIED: verify_install_truth.sh:73-89]`

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix phx.new --install` completes non-interactively; the exact suppression flag for the "Fetch and install dependencies? [Yn]" prompt is not confirmed | Code Examples → *Generate the stock host* | `step-00b` hangs. Mitigation: pipe `yes`, or run `--install` and accept the default. The plan should include an explicit non-interactivity assertion in `step-00b`. |
| A2 | `mix phx.new` accepts a port override, or the generated `config/dev.exs` can be patched to port 4200 before boot | Runtime State Inventory; D-12 | Walk binds 4000 and collides. Low risk — patching `config/dev.exs` with `sed` is trivially reliable. |
| A3 | The `--config override.exs` deprecation and `mix phx.server --no-watchers` non-existence (D-10) were verified in the discuss-phase session; not re-verified here | State of the Art; D-10 | None material — both are "do not attempt" entries, so a false negative costs nothing. |
| A4 | The esbuild/tailwind restart-loop numbers in D-09 (25 restarts in 60s, `max_restarts: 3/5s`, `restart: :transient`) come from the discuss-phase empirical session | Pitfall 2 | The conclusion (install assets) holds regardless of the exact numbers. Do not quote the figures as fact in the ledger without re-measuring. |
| A5 | The walk's Postgres will accept `mix ecto.create` for a fresh database with the resolved credentials | Environment Availability | `step-04` FAILs as a Lockspire defect when it is really a permissions problem. Mitigation: preflight must probe `CREATE DATABASE` capability, not just `pg_isready` (D-14). |
| A6 | Lockspire's 37 migrations apply cleanly against a database that already contains `phx.gen.auth`'s `users`/`users_tokens` tables | Pitfall 8 | A name collision would masquerade as a migration defect. Low risk — Lockspire prefixes everything `lockspire_*` and defaults to a dedicated `lockspire` schema. |
| A7 | `Lockspire.Admin.generate_key(:sig)` produces a key that is immediately active and published to JWKS without a separate `publish_key/2` call | Code Examples → *Register the client* | `step-07` fails at token signing with an empty JWKS. The demo's `seeds.exs:82` calls `Repository.publish_key/1` with `status: :active` explicitly, which suggests generate-then-publish may be two steps. **The plan should verify `generate_key/1`'s resulting status before relying on it.** |
| A8 | `mix lockspire.verify` runs successfully in a host where the router wiring is still broken (i.e. it degrades to reporting individual check failures rather than crashing) | Pitfall 8; step-05 | `step-05` produces an opaque crash instead of an attributable per-check report. Mitigation: capture stdout regardless of exit code. |

---

## Open Questions

1. **Does `Lockspire.Admin.generate_key/1` publish the key, or only create it?**
   - What we know: `generate_key/1` delegates to `Lockspire.Admin.Keys`; a separate `publish_key/2`
     exists at `lib/lockspire/admin.ex:198-201`; the demo's seeds construct a JOSE key by hand and
     call `Repository.publish_key/1` with `status: :active, published_at: now`.
   - What's unclear: whether `generate_key(:sig)` alone yields a JWKS-visible active key.
   - Recommendation: `step-06` should assert `GET <mount>/jwks` returns at least one key **before**
     proceeding to `step-07`, and call `publish_key/2` if not. Either outcome is a ledger entry —
     if two calls are needed and nothing documents that, it is a D-47 sub-defect.

2. **Which interpretation of `lockspire_routes/0` does Phase 128's WIRE-01 drift fence consume?**
   - What we know: the guide says "call"; the heredoc's contents are what actually work.
   - What's unclear: whether the ledger should record one defect ("the helper is a String") or two
     ("zero routes" + "`:require_operator` undefined").
   - Recommendation: record two, per Pitfall 4. Phase 127 may fix them with one change, but the walk's
     job is evidence, and the two failure modes are observably different.

3. **Should `tmp/adopter-walk/` be added to `repo_hygiene_check.sh`'s artifact allowlist?**
   - What we know: the hygiene script WARNs on `tmp/adoption_demo.log` and preserves
     `tmp/admin-ui-polish/`; `tmp/adopter-walk/` matches neither, so it is currently invisible to the
     gate.
   - What's unclear: whether a stale multi-hundred-MB `host_app/` tree left by `--keep` should trip a
     WARN.
   - Recommendation: out of scope for Phase 126 — flag it as a Phase 130 (GUARD) candidate. Do not
     edit `repo_hygiene_check.sh` in this phase.

4. **Does the walk need `mix lockspire.install --storage-prefix public`?**
   - What we know: the installer defaults to `storage_prefix: "lockspire"`, and the first migration
     calls `ensure_lockspire_schema()`, so the schema is created by the migration itself.
   - What's unclear: whether Oban's migration (`20260429194500_add_oban_jobs.exs`) creates the
     `oban_prefix` schema when it differs from the storage prefix.
   - Recommendation: keep the default (that is what a real adopter gets) and let any schema failure
     become a ledger entry. Do not pass `--storage-prefix public` to make the walk easier — that
     would be the same mistake `verify_install_truth.sh` makes with `--no-ecto`.

---

## Environment Availability

Probed on this machine (darwin 25.5.0, arm64) on 2026-07-28.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | walk harness | ✓ | GNU bash 5.2.37 | — |
| `mix` / `elixir` | every step | ✓ | Elixir 1.19.5 / OTP 28 (erts-16.3) | — |
| `python3` | flow driver | ✓ | 3.14.4 | — |
| `phx_new` archive | `step-00b` | ✓ | 1.8.9 (global `~/.mix/archives`) | Harness installs into `.harness/archives` regardless (D-06) |
| PostgreSQL | `step-04` onward | ✓ | 14.17 (Homebrew), accepting connections at `/tmp:5432` | — |
| `pg_isready` | preflight | ✓ | 14.17 | — |
| `cc` + `make` | `bcrypt_elixir` NIF (D-26) | ✓ | Apple clang 21.0.0 / GNU make | — |
| `curl` | optional preflight | ✓ | 8.7.1 | Python driver does its own HTTP |
| `jq` | optional | ✓ | 1.7.1 | Python `json` module |
| Network access | `mix deps.get`, esbuild/tailwind binary download | assumed ✓ | — | `--keep` reuses a warm workdir on rerun |
| TCP port 4200 | `step-07` boot | ✓ free | — | `--port` override (D-12) |

**Missing dependencies with no fallback:** none on this machine.

**Notes for Phase 130's CI handoff:**
- Local Postgres is **14.17** while CI supplies **postgres:16**. `AGENTS.md` declares 14+ support, so
  a 14-only failure would itself be a finding worth recording.
- The `cc`/`make` requirement (D-26) is satisfied by `ubuntu-latest` runners but must be named in the
  preflight so a container without build-essential fails as PREREQUISITE, not as a Lockspire defect.
- `.harness/` needs a new `.gitignore` entry — the current file has `/tmp/` but nothing matching
  `.harness/`. `[VERIFIED: .gitignore read]`

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json`, so this section applies.

**Framing note:** this phase's deliverable *is* a validator. The risk it introduces is not
"untested code" but "a harness that reports GREEN for the wrong reason" — a walk that passes because
it skipped a step, or that FAILs on its own bug and gets attributed to Lockspire. The validation
below targets that risk.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (repo-native) + `bash -n` / `python3 -m py_compile` static checks |
| Config file | `test/test_helper.exs`; lanes in `mix.exs:71-125` |
| Quick run command | `bash -n scripts/maintainer/adopter_path_walk.sh && python3 -m py_compile scripts/maintainer/adopter_path_flow.py` |
| Full suite command | `mix ci` (must stay green — the phase adds one alias to `mix.exs`) |

The walk itself is deliberately **not** in `mix ci` (D-01). Its "full suite" is a manual
`mix adopter.walk` run.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ADOPT-01 | `mix adopter.walk` alias exists and delegates to the script | contract | `mix run -e 'true = Keyword.has_key?(Mix.Project.config()[:aliases], :"adopter.walk")'` | ❌ Wave 0 |
| ADOPT-01 | Script is syntactically valid and has a single verdict/exit path | static | `bash -n scripts/maintainer/adopter_path_walk.sh` | ❌ Wave 0 |
| ADOPT-01 | Driver is syntactically valid, stdlib-only | static | `python3 -m py_compile …` + grep for non-stdlib imports | ❌ Wave 0 |
| ADOPT-02 | The walk never passes a stripping flag to `phx.new` | contract | `! grep -E '\-\-no-(ecto\|html\|assets\|mailer)' scripts/maintainer/adopter_path_walk.sh` | ❌ Wave 0 |
| ADOPT-02 | The walk pins `phx_new` and isolates `MIX_ARCHIVES` | contract | `grep -Fq 'MIX_ARCHIVES' && grep -Fq 'phx_new 1.8.9'` | ❌ Wave 0 |
| ADOPT-03 | Every step ID maps to a `docs/install-and-onboard.md` section number | contract | ExUnit test parsing `step-NN` IDs from the script against the guide's `## N.` headings | ❌ Wave 0 |
| ADOPT-03 | The harness does not use the evidence-destroying teardown | contract | `! grep -E "trap .*rm -rf" scripts/maintainer/adopter_path_walk.sh` | ❌ Wave 0 |
| ADOPT-03 | Resume markers and `--from-step` exist | contract | `grep -Fq '.walk/steps' && grep -Fq -- '--from-step'` | ❌ Wave 0 |
| ADOPT-04 | The driver asserts a token *use*, not just presence | contract | grep the driver for both a `/userinfo` bearer assertion and a host-route bearer assertion, plus an anonymous-401 assertion | ❌ Wave 0 |
| **Criterion 5** | Every `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker has a matching ledger row, and every ledger row citing a workaround has a matching marker | contract | ExUnit test doing a set-equality check between markers grepped from `scripts/maintainer/*` and IDs parsed from `126-DEFECT-LEDGER.md` | ❌ Wave 0 |
| **Criterion 4** | The ledger is non-empty and every entry has all six D-37 fields | contract | ExUnit test parsing the ledger | ❌ Wave 0 |
| ADOPT-01..04 | End-to-end walk produces a report | manual | `mix adopter.walk` (expected RED — see below) | n/a |

**Manual-only justification:** the end-to-end walk generates an app, compiles a C NIF, downloads
asset binaries, and boots a server. It cannot run in `< 30s` and must not enter `mix ci` in this
phase (D-01). Its evidence is the committed ledger plus the preserved `tmp/adopter-walk/` tree.

### Sampling Rate

- **Per task commit:** `bash -n` + `python3 -m py_compile` + the focused contract test file.
- **Per wave merge:** `mix test.fast` (the new contract tests live in the normal suite).
- **Phase gate:** `mix ci` green **and** one full `mix adopter.walk` run whose report is captured in
  the ledger.

### The GREEN/RED inversion — plan for it explicitly

Every other phase's exit test is "the suite is green". Here the *walk* is expected to exit non-zero,
and that is a passing phase. The contract tests above must therefore assert on the **harness's
properties**, never on the walk's exit code. Concretely:

- ✅ "the ledger has ≥ 1 entry and every entry is fully attributed"
- ✅ "every workaround marker is reconciled"
- ❌ "`mix adopter.walk` exits 0" — this would fail the phase for the right reason and must not be
  written as a gate.

### Wave 0 Gaps

- [ ] `test/lockspire/maintainer/adopter_walk_contract_test.exs` — ADOPT-01..04 static/contract
      assertions over the script and driver source
- [ ] `test/lockspire/maintainer/defect_ledger_contract_test.exs` — criterion 4 (non-empty, all D-37
      fields) and criterion 5 (marker↔ledger set equality)
- [ ] No framework install needed — ExUnit is already the repo's suite

---

## Security Domain

`security_enforcement` is not set to `false` in `.planning/config.json`, so this section applies.
The phase adds **no runtime surface**: no library code, no routes, no schema, no dependencies. The
threat surface is entirely the harness and the credentials it handles.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes (harness-side) | Use `mix phx.gen.auth`'s own context functions (D-23); never insert a `hashed_password` by hand. Test credentials must be obviously non-production (`walker@adopter.test`) and confined to `tmp/adopter-walk/`. |
| V3 Session Management | yes (driver-side) | The Python `Browser` cookie jar is per-process and never persisted. Do not write cookies or session tokens to `server.log` or the ledger. |
| V4 Access Control | yes (assertion target) | ADOPT-04's anonymous-`401` assertion is itself an access-control test. Assert the negative case (`no header → 401`) as well as the positive. |
| V5 Input Validation | no | The harness accepts only maintainer-supplied flags; there is no untrusted input path. |
| V6 Cryptography | yes | PKCE `S256` via `hashlib.sha256` + `base64.urlsafe_b64encode` (`adoption_smoke.py:113-115`). Signing keys via `Lockspire.Admin.generate_key/1` — never hand-roll JOSE key material in the harness. |
| V7 Error Handling & Logging | yes | `server.log` may contain authorization codes, access tokens, and the seeded password. It lives under gitignored `tmp/` — **the ledger must never quote raw token or code values.** Excerpt error classes and messages, redact secrets. |
| V14 Configuration | yes | `MIX_ARCHIVES` isolation (D-06) prevents the harness from mutating the maintainer's global toolchain. `secret_key_base` for the generated host must be locally generated per run, never copied from `examples/adoption_demo/config/config.exs` (which contains a committed literal). |

### Known Threat Patterns for a clean-room generation harness

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Global archive overwrite clobbers the maintainer's `phx_new` | Tampering | `MIX_ARCHIVES` scoped to `.harness/archives` (D-06) |
| Evidence destroyed on failure, hiding the defect | Repudiation | Stable workdir + no `rm -rf` trap (D-20) |
| Orphaned `mix phx.server` keeps port 4200 bound after a crash | Denial of Service | `trap` killing only the captured pid on `EXIT`/`INT`/`TERM` |
| Tokens/codes/passwords leaked into a **committed** artifact | Information Disclosure | Ledger records error classes and step IDs only; raw values stay in gitignored `tmp/` |
| Walk drops a database the maintainer cares about | Tampering | Walk-specific database name; never reuse `lockspire_test` or `lockspire_adoption_demo` |
| Copying the demo's committed `secret_key_base` into the generated host | Spoofing | Generate per run via `mix phx.gen.secret` |
| An unmarked workaround makes a broken path look healthy | Repudiation | `# LOCKSPIRE_WALK_WORKAROUND` markers reconciled by a contract test (D-40/D-41, criterion 5) |

---

## Project Constraints (from AGENTS.md)

This repo has no `CLAUDE.md`; `AGENTS.md` is the project instruction file. Directives relevant to
this phase:

- **Preserve the embedded-library shape.** Do not turn Lockspire into a standalone auth service. The
  walk must generate a *host* app that embeds Lockspire, not run Lockspire as a server.
- **Keep strong internal boundaries** between protocol core, storage, generators, Plug/Phoenix
  integration, and LiveView/admin surfaces. The harness is none of these — it lives in `scripts/`.
- **The host seam is explicit and narrow:** account resolution, claims, login redirects, branding,
  and product policy belong to the host app. The walk implements `resolve_account/2` and
  `build_claims/2` in the *generated app*, never in the library.
- **Do not broaden v1** into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite.
- **Stack pins to respect:** Phoenix `1.8.5`+ (resolves to 1.8.9), LiveView `>= 1.1.28 and < 2.0.0`,
  Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`+, Oban `2.21.x`.
- **Security defaults to preserve** (all are assertion targets for the walk, not things to weaken):
  PKCE S256 required by default, exact-match redirect URI validation, short-lived single-use
  authorization codes, no implicit flow, no `alg=none`, strong redaction in logs and operator
  surfaces.
- **Product priority #1 is "Install DX for a host Phoenix app."** This phase is a direct measurement
  of that priority; a thin ledger understates a known problem.

Additional repo-level constraints verified in-session:

- `mix ci` is the contributor gate (`mix.exs:118-127`). Adding one alias must not break it.
- The Hex package is built from `Path.wildcard("lib/**/*.ex")` plus `docs/**/*.md`
  (`mix.exs:477-489`) — this is why the harness goes in `scripts/` (D-02) and the ledger goes in
  `.planning/` (D-38). Both would otherwise ship to adopters.
- `repo_hygiene_check.sh:262-267` is a BLOCK-level contract over `scripts/demo/adoption_smoke.py`'s
  contents — do not edit that file (D-34).
- v1.35's daemon-free rule: no `docker compose` in CI paths.

---

## Sources

### Primary (HIGH confidence — in-repo source and vendored dependency source, read directly)

- `scripts/maintainer/repo_hygiene_check.sh` — flag parsing, `record_result`, `RESULTS[]`, `Summary:`,
  exit-code verdict, public-surface contract, smoke-wrapper contract, tmp allowlist
- `scripts/publish/verify_install_truth.sh` — clean-room generation mechanics, `mktemp`+`trap`
  anti-pattern, `--no-*` flags
- `scripts/demo/adoption_smoke.py` — `Browser`, `csrf()`, `code_challenge()`, `assert_status`,
  `wait_until_ready`, full authorization-code + PKCE sequence at `:221-320`
- `mix.exs` — aliases (`:71-125`), `package_files/0` (`:477-489`), `application/0` (`:31-36`)
- `.github/workflows/ci.yml` — Postgres service (`:38-56`), boot-and-drive (`:313-327`)
- `.gitignore`, `.planning/config.json`, `AGENTS.md`
- `docs/install-and-onboard.md` — the path under test, §§1-8
- `docs/protect-phoenix-api-routes.md` — canonical protected-route pipeline
- `docs/ecosystem-overview.md:7,15,110,146` — `phx.gen.auth` as the recommended inbound-auth pairing
- `priv/templates/lockspire.install/{router,config,account_resolver,consent_live,interaction_handler}.ex`
- `lib/lockspire/{application,oban,config,admin}.ex`, `lib/lockspire/web/router.ex`,
  `lib/lockspire/web/live/consent_live.ex`, `lib/lockspire/install/verify.ex`,
  `lib/lockspire/generators/install.ex`, `lib/lockspire/plug/enforce_sender_constraints.ex`
- `lib/mix/tasks/{lockspire.install,lockspire.client.create,lockspire.test.setup}.ex`
- `priv/repo/migrations/` (37 files), `20260422000100_create_lockspire_core_tables.exs`
- `examples/adoption_demo/{mix.exs, config/config.exs, lib/adoption_demo/application.ex,
  lib/adoption_demo_web/router.ex, lib/adoption_demo_web/controllers/consent_controller.ex,
  priv/repo/seeds.exs}`
- `test/integration/install_generator_test.exs:355-395` — `reset_fixture!` host-interaction gap
- `deps/phoenix` 1.8.9 — `priv/templates/phx.gen.auth/{routes.ex.eex, session_controller.ex.eex,
  login_live.ex.eex, auth.ex.eex, context_functions.ex.eex}`, `lib/mix/tasks/phx.gen.auth.ex:1143`
- `deps/ecto_sql` 3.13.5 — `lib/ecto/migration/schema_migration.ex:69-72`
- `deps/oban` — `lib/oban/migration.ex:161,182,193` and module docs
- Executed in-session: `mix phx.new --version`, `mix archive`, `elixir --version`, `pg_isready`,
  `command -v` probes for `cc`/`make`/`python3`/`jq`/`curl`, `lsof` port checks
- `https://hex.pm/api/packages/phx_new` — registry metadata for the legitimacy audit

### Secondary (MEDIUM confidence)

- `gsd-tools query research-plan` routed three questions to `context7`/`websearch`. Context7 MCP was
  not available in this session; all three were instead answered from the **vendored dependency
  source in `deps/`**, which is the authoritative artifact for the exact resolved versions
  (`phoenix 1.8.9`, `ecto_sql 3.13.5`, `oban 2.21.x`) rather than version-ambiguous documentation.
  Digests were cached under keys `27346d4c…`, `b4013441…`, `be6e1fd6…`.

### Tertiary (LOW confidence)

- D-09's restart-count figures and D-10's Elixir 1.19 deprecation details originate from the
  discuss-phase empirical session and were not re-measured here. Logged as A3/A4.

---

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Standard stack | HIGH | No new packages. Every tool is already installed and version-verified in-session; `phx_new` legitimacy confirmed against the Hex registry API. |
| Architecture | HIGH | Every pattern has a direct in-repo precedent that was read line by line (`repo_hygiene_check.sh`, `adoption_smoke.py`, `ci.yml:313-327`, `mix.exs` aliases). |
| Pitfalls | HIGH | All ten are grounded in source read this session. Pitfalls 3, 5, 6, and 7 are new findings not present in CONTEXT.md, each traced to a specific file and line. |
| Known-defect list (D-42..D-49) | HIGH, with one correction | All confirmed by source. D-42/D-43 corrected: they are mutually exclusive on a single run (Pitfall 4). |
| Validation architecture | MEDIUM | The contract-test shapes are sound, but the GREEN/RED inversion means the gates are unusual for this repo; the planner should review them against `mix ci` behavior. |
| Environment | HIGH | All probes executed on the target machine. |
| A7 (`generate_key/1` publish semantics) | LOW | Open Question 1 — must be resolved during execution, not assumed. |

**Research date:** 2026-07-28
**Valid until:** 2026-08-27 (30 days — the codebase is the primary source and is stable; re-verify if
`phoenix`, `ecto_sql`, or `oban` are bumped in `mix.lock`)
</content>
</invoke>
