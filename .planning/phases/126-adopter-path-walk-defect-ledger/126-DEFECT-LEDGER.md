---
phase: 126-adopter-path-walk-defect-ledger
walk_date: 2026-07-29T02:13:24Z
verdict: RED
pass_count: 19
fail_count: 12
summary_line: "Summary: 19 PASS, 12 FAIL"
result_line: "Result: adopter path is RED"
resolved_versions:
  elixir: "1.19.5 (compiled with Erlang/OTP 28)"
  otp: "28 (erts-16.3)"
  postgresql: "14.17 (Homebrew)"
  phx_new: "1.8.9"
---

# Phase 126 Defect Ledger

This is the committed record of every break `mix adopter.walk` surfaced while walking the
documented path from `mix phx.new` through a completed authorization-code + PKCE flow and the
ADOPT-04 two-layer token proof, against a real generated Phoenix host, real PostgreSQL, and a
real booted Phoenix server. The walk correctly finished **RED**: 19 steps PASS, 12 FAIL, one
continuous run, one report.

That is a passing Phase 126 outcome, not a failing one. Per `126-VALIDATION.md` and this
phase's own `<inversion_warning>`, no gate here asserts `mix adopter.walk` exits 0, that it
reaches its final step, or that this ledger is empty -- doing so would fail the phase for
exactly the reason it exists.

Every entry below carries the six fields D-37 fixes: the walk step ID that surfaced it, the
symptom a maintainer sees, the underlying error, the source, the owning phase, and the
workaround (a `LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker in `scripts/maintainer/`, or
`none`). Every workaround claim here is mechanically reconciled against the harness source by
`test/lockspire/maintainer/defect_ledger_contract_test.exs` -- a marker with no entry, or an
entry claiming a marker that does not exist, both fail that test.

No entry below quotes a raw access token, ID token, authorization code, session cookie, or the
seeded password (`LOCKSPIRE_WALK_PASSWORD` / the literal plan 126-01 seeds). Only error classes,
step IDs, and `file:line` citations are recorded.

## Phase 127 walk delta (recorded 2026-07-29)

Phase 127 closed the installer-attributed defects and plan 127-09 retired the six workarounds they
made obsolete. This is the delta from one real, from-scratch `mix adopter.walk` run against the
frontmatter's recorded 19 PASS / 12 FAIL baseline:

| | Phase 126 | Phase 127 |
|---|---|---|
| Summary | `Summary: 19 PASS, 12 FAIL` | `Summary: 22 PASS, 6 FAIL` |
| Result | `Result: adopter path is RED` | `Result: adopter path is RED` |
| Walk date | 2026-07-29T02:13:24Z | 2026-07-29T18:45:47Z |
| Workaround markers in the harness | 13 | 7 |

Six defects no longer require a harness workaround and their steps now pass unaided: **ADOPT-D02**
and **ADOPT-D03** (router template), **ADOPT-D08** (`mix lockspire.client.create` reaching a started
repo), **ADOPT-D09** (resolver login path), **ADOPT-D15** (`ecto_sql` requirement range), and
**ADOPT-D16** (HEEx attribute interpolation).

Six FAIL rows remain, each with an open disposition below: `step-03a-config-import` (ADOPT-D04),
`step-03c-resolver` (ADOPT-D11), `step-03d-app-tree` (ADOPT-D05), `step-04-migrate` (structural --
the documented bare `mix ecto.migrate` exits 0 having applied none of Lockspire's migrations, which
is the defect), `step-05-verify` (ADOPT-D07), and `step-06a-client` (ADOPT-D06).

The run is still correctly RED. Per this ledger's own inversion warning, that is a passing Phase 127
outcome, not a failing one.

This delta was adjudicated mechanically rather than by eye:
`scripts/maintainer/adopter_walk_baseline.json` records the expected outcome per
`(step_id, occurrence)`, was committed before the run so the run could refute it, and
`scripts/maintainer/adopter_walk_verify.py` compared the two. The full report is archived at
`.planning/phases/127-installer-against-a-real-host/127-WALK-REPORT-20260729.json`.

The first run did refute the prediction, on one row: `step-03b-router-paste` was expected to PASS and
observed FAIL. The cause was a harness defect rather than an adopter-path regression -- the paste
sub-step appended the macro body to a router that still carried the `lockspire_routes()` call, so
`live_session :lockspire_consent` was defined twice. Corrected in the harness (the step now pastes
in place of the call, as its own doc comment always said it did) rather than by restoring a
workaround or editing the expectation.

## Defects

### ADOPT-D01

- **Walk step:** step-03b-router-call
- **Symptom:** Following the guide's first documented reading of §3 ("import the generated
  router helper and call `lockspire_routes/0` where your product wants the Lockspire routes to
  live") compiles cleanly and defines zero Lockspire routes -- `mix phx.routes` shows no
  `/lockspire` mount at all after this step.
- **Underlying error:** `HostAppWeb.Router.Lockspire.lockspire_routes/0`
  (`priv/templates/lockspire.install/router.ex:9`) returns a heredoc `String`, not a `quote
  do ... end` block. Calling a function that returns a String at a router module's top level
  evaluates the expression and discards the result -- no macro expansion happens, so nothing is
  injected into the router.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** none. This step's own PASS/FAIL criterion is exactly this observation: it
  never gates on a clean compile, only on whether `mix phx.routes` shows the mount, and it does
  not. The real wiring is applied separately as ADOPT-D02/ADOPT-D03's workaround under
  `step-03b-router-wire`.
- **Disposition:** Fixed in Phase 127 (plan 127-05). `priv/templates/lockspire.install/router.ex`
  now emits `lockspire_routes/1` as a `defmacro` returning a `quote do ... end` block instead of a
  heredoc `String`, so calling it at a host router's top level injects a real, correctly ordered,
  deny-closed route table. Fenced by `test/integration/install_template_compile_test.exs`, which
  compiles the rendered helper and reads the real route table back via
  `Phoenix.Router.routes/1`.

### ADOPT-D02

- **Walk step:** step-03b-router-paste
- **Symptom:** The other documented reading of §3 -- pasting `lockspire_routes/0`'s own
  rendered body directly into the host router -- fails to compile.
- **Underlying error:** The pasted body's admin scope references a `:require_operator`
  pipeline (`priv/templates/lockspire.install/router.ex:54`) that no stock `mix phx.new` router
  defines, so compilation fails with an undefined-pipeline error.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** none remaining. 127-05's router-template rewrite (D-11) turned
  `lockspire_routes/1` into a `defmacro` that defines its own namespaced
  `:lockspire_require_operator` pipeline, deny-closed by default. No stand-in pipeline is
  defined in the generated host any longer; the harness's `# LOCKSPIRE_WALK_WORKAROUND:
  ADOPT-D02` marker and the block it guarded were removed in the same commit as this retirement.
- **Disposition:** Fixed in Phase 127 (plan 127-05). The macro now defines its own deny-closed
  `:lockspire_require_operator` pipeline, so no stand-in pipeline is needed in a stock host
  router. Plan 127-09 removed the harness's stand-in-pipeline workaround and confirmed the
  extracted paste reading now compiles cleanly. Fenced by
  `test/integration/install_template_compile_test.exs` and
  `test/lockspire/maintainer/defect_ledger_contract_test.exs`.

### ADOPT-D03

- **Walk step:** step-03b-router-wire
- **Symptom:** The template's own general forward (`priv/templates/lockspire.install/router.ex:58-59`,
  `forward "<mount>", Lockspire.Web.Router`) sits in a pipeline-less scope. Session-dependent
  interaction routes and the consent LiveView would get no `fetch_session` and no
  `protect_from_forgery` if wired exactly as templated.
- **Underlying error:** No `pipe_through` on the forward's scope in the generated router
  helper's own template body.
- **Source:** installer and guide
- **Owning phase:** 127 and 128
- **Workaround:** none remaining. 127-05's router-template rewrite (D-11) now emits the
  interaction routes and consent LiveView route already browser-piped, ahead of the
  pipeline-less public forward, directly from `lockspire_routes/1`'s own `quote` body. No harness
  rewiring is required any longer; the guide half (§128) still applies. The consent route's own
  `live_session` on_mount: value remains harness-supplied -- that residual is tracked separately
  under the ADOPT-D18 entry below, which the ADOPT-D03 workaround previously nested inside.
- **Disposition:** Fixed in Phase 127 (plan 127-05) for the installer half: the interaction
  routes and consent LiveView are now emitted already browser-piped, ahead of the
  pipeline-less public forward, so they get real `fetch_session` and `protect_from_forgery`
  without any harness rewiring. The guide half (documenting this wiring for the adopter) remains
  Phase 128's, per the joint source/owning-phase attribution above. Fenced by
  `test/integration/install_template_compile_test.exs`.

### ADOPT-D04

- **Walk step:** step-03a-config-import
- **Symptom:** After `import_config "lockspire.exs"` and a clean compile, the imported config
  is not sufficient to boot: the issuer is a placeholder and `known_scopes`, `signing_alg`,
  `secret_key_base`, and `oban:` are all absent.
- **Underlying error:** `priv/templates/lockspire.install/config.exs:7-13` emits `issuer:
  "https://example.com"` (line 10) and no `known_scopes`, `signing_alg`, `secret_key_base`, or
  `oban:` keys at all.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** `ADOPT-D04` -- narrowed in 127-09 after 127-06's config-template rewrite made
  most of this workaround's original scope unnecessary. The template now emits a
  mount-path-consistent issuer suffix, `known_scopes`, `signing_alg`, and a self-describing
  `secret_key_base` placeholder on its own; only `oban:` is still genuinely absent. What the
  harness still patches is walk-specific value substitution, each guarded independently by
  whether that specific value still needs replacing: the placeholder `https://example.com` issuer
  host is replaced with the walk's own reachable base URL (the mount-path suffix the template now
  emits is left untouched), the `secret_key_base` placeholder is replaced with a freshly generated
  secret (never the committed `examples/adoption_demo/config/config.exs` secret literal, per
  T-126-04), `read:walk` is appended to the template's own `known_scopes` list (the scope this
  harness's own protected-route proof invented, see the "Harness-only correction" note below), and
  `oban:` is appended since the template still omits it.
- **Disposition:** Fixed in Phase 127 (plan 127-06) for the template half: the config template now
  emits a mount-path-consistent issuer suffix, `known_scopes`, `signing_alg`, and a
  self-describing `secret_key_base` placeholder, so a stock import no longer raises at boot on a
  bare placeholder issuer. What remains in the harness (plan 127-09's re-scoping) is
  walk-specific value substitution -- a real reachable issuer host, a freshly generated secret,
  and the `read:walk` scope this harness's own proof invented -- none of which is an
  adopter-facing defect; no real adopter needs a scope this harness invented for its own proof.
  Fenced by `test/integration/install_generator_test.exs`.

### ADOPT-D05

- **Walk step:** step-03d-app-tree
- **Symptom:** Nothing documents that the generated host's own `Application.start/2` order
  matters, or that Lockspire needs its own supervision children wired in. A stock generated
  host boots `:lockspire` before the host's own `Repo`, with Lockspire's default Oban queues
  live against a database that has not even run Lockspire's migrations yet.
- **Underlying error:** No installer step touches the generated host's `mix.exs`
  `application/0`, and the guide never mentions `included_applications`, ordering, or
  Lockspire's supervision children. `examples/adoption_demo/mix.exs:16-20` is the only place in
  the repo that gets this right (`included_applications: [:lockspire]` plus
  `extra_applications: [:logger, :runtime_tools, :oban, :cachex]`).
- **Source:** installer and guide
- **Owning phase:** 127 for the installer half, 128 for the guide half
- **Workaround:** `ADOPT-D05` -- `included_applications: [:lockspire]` orders the host's Repo
  first, and `:oban`/`:cachex` are added to `extra_applications` (matching the demo's fuller
  `application/0`, not just its `included_applications` line -- `included_applications` alone
  leaves `:oban`'s own registry unstarted, since `Application.ensure_all_started/1` never walks
  an included application's own dependency chain). Lockspire's three supervision children are
  added after the host's Repo.
- **Disposition:** Fixed in part in Phase 127 (plan 127-04): the installer's printed onboarding
  instructions (`instructions/1`) now name `included_applications: [:lockspire]`, the
  `:oban`/`:cachex` `extra_applications` additions, and Lockspire's three supervision children
  ordered after the host's Repo -- while stating explicitly that Lockspire never touches the
  host's `mix.exs` or `application.ex` itself. The harness's own `ADOPT-D05` markers stay: the
  installer deliberately performs zero injection (host action, by design), so the harness must
  still perform this wiring itself on every run to keep walking. The guide half (a worked,
  narrated example) remains Phase 128's. Fenced by
  `test/lockspire/install/install_instructions_test.exs`.

### ADOPT-D06

- **Walk step:** step-06a-client
- **Symptom:** JWKS and token issuance have nothing to sign with after a stock install. The
  guide's own §6 proof bar claims "JWKS returns the public signing keys"
  (`docs/install-and-onboard.md:135`) but no step anywhere mints one.
- **Underlying error:** `Lockspire.Admin.Keys` (`lib/lockspire/admin/keys.ex`) exposes a
  three-stage lifecycle -- `generate_key/1` (line 36, inserts status `:upcoming`),
  `publish_key/2` (line 80, transitions to `:published`, visible in JWKS), and `activate_key/2`
  (line 103, transitions to `:active`, the only status `fetch_active_signing_key/1`
  (`lib/lockspire/storage/ecto/repository.ex`) will select for actually signing a token) -- but
  the guide documents none of the three. A real live run confirmed this empirically in stages:
  after `generate_key/1` alone, JWKS was still empty; after `generate_key/1` + `publish_key/2`,
  JWKS was non-empty, but the token endpoint then failed with `** (KeyError)` /
  `:signing_key_not_found` on the very first real token exchange, because the key was
  published but never activated.
- **Source:** installer and guide
- **Owning phase:** 127 for the installer half, 128 for the guide half
- **Workaround:** `ADOPT-D06` -- all three calls are made in sequence
  (`generate_key/1`, then `publish_key/2` if JWKS is still empty, then `activate_key/2`
  unconditionally). This resolves RESEARCH Open Question 1 with a stronger answer than the
  question anticipated: publication (JWKS visibility) and activation (signing eligibility) are
  two separate lifecycle stages, and a first live token exchange is what actually surfaces the
  second one -- JWKS-non-empty alone is not sufficient evidence that a key can sign.
- **Disposition:** Fixed in part in Phase 127 (plan 127-04): the installer's printed onboarding
  instructions now name all three key-lifecycle calls by name and arity
  (`Lockspire.Admin.generate_key/1`, `publish_key/2`, `activate_key/2`) as genuinely separate
  stages, stating that a published key still cannot sign until activated. The harness's own
  `ADOPT-D06` marker stays: minting and activating a signing key is a real per-install action
  the harness must still perform on every run to keep walking. The guide half (a worked,
  narrated example) remains Phase 128's. Fenced by
  `test/lockspire/install/install_instructions_test.exs`.

### ADOPT-D07

- **Walk step:** step-04-migrate / step-05-verify
- **Symptom:** The documented `mix ecto.create` + bare `mix ecto.migrate`
  (`docs/install-and-onboard.md:108`) exits 0 against a real generated host and runs zero of
  Lockspire's own migrations. `mix lockspire.verify` (the independent detector, never the
  migrate command's own exit code) reported 37 pending Lockspire/Oban migrations after the
  documented command's exit-zero result.
- **Underlying error:** Lockspire's migrations live under the `:lockspire` dependency's own
  `priv/repo/migrations`, a path the host's default `mix ecto.migrate` never looks at.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** `ADOPT-D07` -- the release-safe `Application.app_dir(:lockspire,
  "priv/repo/migrations")` form (never a source-tree-relative form, which does not exist inside
  a compiled release) is passed as `--migrations-path`, after which `mix lockspire.verify`
  reports zero pending migrations.
- **Disposition:** Fixed in part in Phase 127 (plan 127-04): the wrong migrate-remediation
  strings are corrected at all four in-scope `verify.ex` sites (pending, storage-prefix,
  oban-prefix, and up-to-date), plus the installer's own printed migrate step -- all five now
  name the release-safe `--migrations-path` switch. The underlying redesign (a dedicated migrate
  Mix task, or a host migration generator writing a migration against versioned modules) is
  deferred: both require new public surface, which this milestone's Out of Scope table forbids.
  Logged below as a future candidate so Phase 128 does not silently inherit an unsolvable
  documentation problem; adopters still need to pass `--migrations-path` themselves, and that is
  the accepted cost. `docs/install-and-onboard.md:108`'s bare guide text is Phase 128's. Fenced
  by `test/lockspire/install/install_instructions_test.exs`.

### ADOPT-D08

- **Walk step:** step-06a-client
- **Symptom:** The documented `mix lockspire.client.create` task exits 1 with `**
  (RuntimeError) could not lookup Ecto repo HostApp.Repo because it was not started or it does
  not exist` -- it never reaches a running repo in a stock host.
- **Underlying error:** `lib/mix/tasks/lockspire.client.create.ex:10` declares `@requirements
  ["app.config"]`, which only loads configuration; it never starts the application supervision
  tree the way `mix lockspire.verify`'s `Ecto.Migrator.with_repo/2` wrapper does.
- **Source:** library
- **Owning phase:** 127
- **Workaround:** none remaining. 127-03 wrapped `lib/mix/tasks/lockspire.client.create.ex`'s
  `Clients.register_client/1` call in `Ecto.Migrator.with_repo/2`, the same pattern
  `mix lockspire.verify`'s migrations check already used, so the documented task now reaches a
  running repo in a stock host directly. No `mix run -e` workaround runs in the harness any
  longer.
- **Disposition:** Fixed in Phase 127 (plan 127-03). `lib/mix/tasks/lockspire.client.create.ex`
  now wraps its `Clients.register_client/1` call in `Ecto.Migrator.with_repo/2`, so the
  documented task reaches a running repo directly in a stock host. Plan 127-09 removed the
  harness's `mix run -e` workaround and confirmed the documented task now runs unaided.

### ADOPT-D09

- **Walk step:** step-03c-resolver
- **Symptom:** The generated `AccountResolver`'s `redirect_for_login/2` sends the browser to
  `/login`, a route no `mix phx.gen.auth Accounts User users --live` host has (the real login
  route is `/users/log-in`).
- **Underlying error:** `priv/templates/lockspire.install/account_resolver.ex:75` hardcodes
  `login_path: "/login"`.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** none remaining. 127-06 changed
  `priv/templates/lockspire.install/account_resolver.ex`'s `redirect_for_login/2` default to
  `login_path: "/users/log-in"`, matching `mix phx.gen.auth Accounts User users --live`'s real
  login route. The generated host's own resolver file now ships with the correct default and no
  harness patch is applied.
- **Disposition:** Fixed in Phase 127 (plan 127-06).
  `priv/templates/lockspire.install/account_resolver.ex`'s `redirect_for_login/2` default now
  matches `mix phx.gen.auth Accounts User users --live`'s real login route. Plan 127-09 removed
  the harness's generated-file patch. Fenced by `test/integration/install_generator_test.exs`.

### ADOPT-D10

- **Walk step:** step-06b-flow
- **Symptom:** The consent page's approve/deny forms carry no CSRF token input at all, so a
  form-scraping CSRF strategy finds nothing to extract.
- **Underlying error:** `lib/lockspire/web/live/consent_live.ex:81` and `:90` render raw `<form
  method="post">` decision forms with zero `_csrf_token` input.
- **Source:** library
- **Owning phase:** 128 or 129
- **Workaround:** `ADOPT-D10` -- the flow driver falls back to the root layout's `<meta
  name="csrf-token">` tag, which `protect_from_forgery` also accepts, when no form-embedded
  token is present.

### ADOPT-D11

- **Walk step:** step-03c-resolver
- **Symptom:** The guide's account-resolver checklist (`docs/install-and-onboard.md:64-69`)
  names the callbacks to implement (current-account lookup, account lookup by subject
  reference, claim building, login-redirect behavior, post-login resume) but supplies no
  worked example, no subject-reference format contract, and no claim-map shape anywhere. The
  generated template itself (`priv/templates/lockspire.install/account_resolver.ex:37-49`)
  contains only a `raise` with reminder text, not an example implementation.
- **Underlying error:** No worked example exists in the guide, the template, or any linked doc.
- **Source:** guide
- **Owning phase:** 128
- **Workaround:** none. This is a documentation gap, not a code defect a harness workaround can
  paper over; the walk's own resolver implementation (written from first principles against
  the generated host's own `Accounts.User` schema) is itself the missing worked example this
  entry flags.

### ADOPT-D13

- **Walk step:** (not a single step -- cross-cutting)
- **Symptom:** A future run of this walk may resolve different dependency and toolchain
  versions than this run did.
- **Underlying error:** The harness does not pin Elixir or OTP, and does not snapshot the
  generated app's own `mix.lock` across runs -- each run's `mix phx.new` resolves whatever Hex
  currently publishes as latest for every generator-added dependency.
- **Source:** environment
- **Owning phase:** 130 or future
- **Workaround:** none. This is residual nondeterminism the harness deliberately does not
  control (D-15), not a defect to fix. `tmp/adopter-walk/` joining the repo-hygiene artifact
  allowlist (RESEARCH Open Question 3) is a Phase 130 candidate, not acted on in this plan.

### ADOPT-D14

- **Walk step:** step-06b-flow
- **Symptom:** After a successful login POST, the generated host ignores the `return_to` query
  parameter -- the interaction handoff cannot resume through the login POST's own redirect.
- **Underlying error:** `mix phx.gen.auth`'s generated `log_in_user/3` redirects to a session
  key (`:user_return_to`) that only a GET through `require_authenticated_user` ever writes; a
  `return_to` parameter POSTed to `/users/log-in` is inert.
- **Source:** generated scaffolding and guide
- **Owning phase:** 127 or 128
- **Workaround:** `ADOPT-D14` -- the driver navigates to `return_to` itself with an explicit
  `GET` after the login POST, rather than trusting the login redirect.
- **Disposition:** Deferred to Phase 128 (per CONTEXT decision D-29). The generated login
  function that ignores a posted `return_to` parameter is host scaffolding
  (`mix phx.gen.auth`'s own `log_in_user/3`) that the installer cannot and must not patch --
  patching generated, host-owned authentication code is out of the installer's ownership model.
  Phase 127 fixes only the sibling resolver login-path defect (ADOPT-D09); session-backed
  interaction resume is logged below as a future candidate rather than built here.

### ADOPT-D15

- **Walk step:** step-01-add-dep
- **Symptom:** `mix deps.get` fails immediately after adding `{:lockspire, path: ...}` to a
  freshly generated host's `mix.exs`, with `Because "the lock" specifies "ecto_sql 3.14.0" and
  every version of "lockspire" depends on "ecto_sql ~> 3.13.5", "the lock" is incompatible with
  "lockspire"`. This reproduced on a completely fresh `mix phx.new` host, not merely a stale
  workdir.
- **Underlying error:** A stock `mix phx.new --database postgres` host resolves and locks
  `ecto`/`ecto_sql` to whatever Hex currently publishes as latest (observed: `ecto_sql 3.14.0`
  and its own `ecto ~> 3.13.0` requirement, `mix.exs:47` for Lockspire's own pin). Lockspire's
  `mix.exs:47` pins `{:ecto_sql, "~> 3.13.5"}`. `mix deps.get` never re-resolves an
  already-locked transitive dependency on its own just because a new dependency further
  constrains it -- the documented "fetch deps" instruction is not sufficient by itself.
- **Source:** installer
- **Owning phase:** 127
- **Workaround:** none remaining. 127-02 changed Lockspire's own `mix.exs` from pinning
  `{:ecto_sql, "~> 3.13.5"}` to ranging `{:ecto_sql, ">= 3.13.5 and < 4.0.0"}`, so a stock host's
  own already-resolved ecto/ecto_sql versions now satisfy Lockspire's requirement without an
  unlock step. `mix deps.unlock` no longer runs in the harness.
- **Disposition:** Fixed in Phase 127 (plan 127-02). `mix.exs` now ranges
  `{:ecto_sql, ">= 3.13.5 and < 4.0.0"}` instead of pinning `"~> 3.13.5"`, so a stock host's own
  already-resolved ecto/ecto_sql versions satisfy Lockspire's requirement without an unlock
  step. Plan 127-09 removed the harness's `mix deps.unlock` workaround.

### ADOPT-D16

- **Walk step:** step-02-install
- **Symptom:** The generated host fails to compile immediately after `mix lockspire.install`,
  before config, router, or resolver wiring is ever exercised: `**
  (Phoenix.LiveView.TagEngine.Tokenizer.ParseError) ... expected closing \`}\` for expression`.
- **Underlying error:** `priv/templates/lockspire.install/authorized_apps/index.html.heex:19`
  renders `<li id={"authorized-app-<%%= consent.grant.id %>"}>` (an EEx-escaped
  `<%= consent.grant.id %>` nested inside a HEEx `{...}` attribute expression). The resolved
  `phoenix_live_view 1.2.8` tokenizer rejects a nested EEx tag inside a HEEx attribute
  expression outright.
- **Source:** generated scaffolding
- **Owning phase:** 127
- **Workaround:** none remaining. 127-06 changed
  `priv/templates/lockspire.install/authorized_apps/index.html.heex` to use Elixir string
  interpolation (`#{consent.grant.id}`) instead of the nested EEx tag, so the generated
  authorized-apps page now compiles as rendered. No patch to the generated host's own copy of
  the file is applied.
- **Disposition:** Fixed in Phase 127 (plan 127-06).
  `priv/templates/lockspire.install/authorized_apps/index.html.heex` now uses Elixir string
  interpolation instead of a nested EEx tag inside a HEEx attribute expression, so the generated
  page compiles as rendered. Plan 127-09 removed the harness's generated-file patch. Fenced by
  `test/integration/install_template_compile_test.exs`.

### ADOPT-D18

- **Walk step:** step-06b-flow
- **Symptom:** After a real login, `GET`ting the interaction's own `return_to` (the consent
  page, per `AuthorizeController`'s wiring) rendered "Authorization request rejected -- Sign in
  is required before reviewing this authorization request -- Reason: `authentication_required`"
  even though the same response's root layout showed the logged-in user's own email in the nav
  bar, proving the session cookie itself was valid.
- **Underlying error:** `Lockspire.Web.ConsentLive`'s account-resolver call reads
  `socket.assigns.current_scope`, which the host's `:browser` plug pipeline's
  `fetch_current_scope_for_user` plug populates for ordinary `Plug`-based controller routes --
  but never for a LiveView socket, which only inherits a plain `session` map unless the route
  is wrapped in a `live_session` block declaring `on_mount: [{HostAppWeb.UserAuth,
  :mount_current_scope}]`. A bare `live "/consent/:interaction_id", ...` route outside any
  `live_session` never gets that hook, so `current_scope` is always unset and an actually
  logged-in adopter is treated as anonymous. The guide's account-resolver checklist
  (`docs/install-and-onboard.md:64-69`) never mentions this LiveView-specific requirement.
- **Source:** guide
- **Owning phase:** 128
- **Workaround:** `ADOPT-D18` -- narrowed in 127-09 after 127-05's router-template rewrite
  (D-11) began emitting the consent route's own `live_session :lockspire_consent do ... end`
  block directly from the macro's `quote` body, with `on_mount:` deliberately left absent for
  the host to supply. The harness no longer wraps the route in a `live_session` of its own (that
  would nest a second `live_session` around a route the template already wraps, and fail to
  compile) -- it now patches only the `on_mount: [{HostAppWeb.UserAuth, :mount_current_scope}]`
  value into the generated host's own `lib/host_app_web/router/lockspire.ex`, never into
  `priv/templates/lockspire.install/router.ex`. This is the same shape as ADOPT-D04's re-scoped
  config workaround: the template gained the structure the harness used to supply, and the
  harness narrowed to the one residual value rather than vanishing.

### ADOPT-D19

- **Walk step:** step-06c-token-proof
- **Symptom:** A host-owned protected API route wired exactly per
  `docs/protect-phoenix-api-routes.md`'s own example crashes with `** (KeyError) key :subject
  not found` on the very first real request carrying a real, valid, issued access token.
- **Underlying error:** `docs/protect-phoenix-api-routes.md:42-53` ("Access-token assigns
  contract") documents `conn.assigns.access_token` (`%Lockspire.AccessToken{}`) as exposing
  top-level `subject`, `client_id`, `scope`, `audience`, `expires_at`, and `cnf` fields. The
  real struct (`lib/lockspire/access_token.ex:6-15`) has no `subject`, `scope`, `audience`,
  `expires_at`, or `cnf` fields at all -- only `token`, `claims`, `client_id`,
  `authorization_scheme`, `binding_type`, `binding_requirements`, `error`, and
  `binding_verified`. The real subject and scope live inside `access_token.claims["sub"]` /
  `access_token.claims["scope"]`. Any adopter who copies the documented example verbatim gets
  the same crash on their first real request.
- **Source:** guide
- **Owning phase:** 128
- **Workaround:** `ADOPT-D19` -- the generated host's own protected-route controller reads
  `access_token.claims["sub"]` / `access_token.claims["scope"]` instead of the documented (but
  nonexistent) struct fields. This is a harness workaround, not a fix to the guide or the
  struct; Phase 128 must correct the documented contract (or Phase 127/129 must add real
  accessor functions matching it) so no adopter has to read this workaround to discover the
  real shape.

### ADOPT-D20

- **Walk step:** step-05-verify (and, downstream, step-06b-flow / step-06c-token-proof)
- **Symptom:** `mix ecto.migrate --migrations-path …` applies all 37 of Lockspire's migrations
  and exits 0, and `mix lockspire.verify` -- run seconds later against the same host and the same
  database -- reports all 37 as still pending. The tables plainly exist and are queryable.
  `Phoenix.Ecto` then rejects every request with `PendingMigrationError`, so the host never
  serves and the driven flow cannot start. Re-running the migrations, which is what the
  remediation text told the adopter to do, fails on "table already exists".
- **Underlying error:** PostgreSQL's default `search_path` is `"$user", public`, so a database
  role whose name equals `:storage_prefix` puts Lockspire's own schema ahead of `public` for
  every *unqualified* table name. Lockspire's own DDL is always prefix-qualified and is
  unaffected -- but Ecto's `schema_migrations` bookkeeping is not. Once Lockspire's first
  migration has created the schema, the next connection's `CREATE TABLE IF NOT EXISTS
  schema_migrations` resolves into the prefixed schema, finds nothing there, and creates a
  **second, empty** bookkeeping table that every subsequent reader then consults.
- **Evidence:** adopter-walk run 30499416067, `step_05_migration_state.log`, sampled from psql
  either side of verify. Before: `public.schema_migrations` only, 38 rows. After:
  `lockspire.schema_migrations => 0` alongside `public.schema_migrations => 38`, with
  `current_schemas(true)` = `{pg_catalog,lockspire,public}`. The empty table did not exist until
  `mix lockspire.verify` connected -- verify created the table it then read. Reproduced at the
  SQL level in `install_instructions_test.exs` (`@tag :integration`).
- **Source:** library and environment
- **Owning phase:** 127
- **Workaround:** none -- and none should exist. The trigger was the walk's own PostgreSQL role
  name, and harness scaffolding is not part of the documented adopter path, so the role is set to
  a non-colliding name in `.github/workflows/adopter-walk.yml` (with a comment pointing here) and
  no marker was added to the harness. Suppressing the collision in scaffolding is not the same as
  suppressing the defect: it remains open, detected, and tested.
- **Disposition:** `mix lockspire.verify` now reports the split explicitly, names `search_path` as
  the cause, and states that re-running the migrations will not fix it -- turning a silent,
  undiagnosable wall into a one-line diagnosis with three concrete remedies (point the role at
  `public`, connect as a differently-named role, or change `:storage_prefix`).
- **Not closed by the above:** detection is not prevention. An adopter who never runs
  `mix lockspire.verify` still meets the same wall via `PendingMigrationError` alone. See the
  first Future candidate below.

## Future candidates (Phase 127)

Deferred designs, out of this milestone's scope because each would widen Lockspire's supported
surface -- new installer-injected files, a new public Mix task, or a new host-owned protocol
seam -- which `.planning/REQUIREMENTS.md`'s Out of Scope table forbids for v1.36. Logged here so
a later milestone does not have to rediscover them from a live walk a second time:

- **Preventing ADOPT-D20 structurally, rather than only detecting it.** Three candidate forms, all
  wider than v1.36's surface: qualify Lockspire's migration bookkeeping explicitly (a dedicated
  `migration_source` in a known schema, which changes the shape of an existing adopter's
  database); refuse to boot when `:storage_prefix` is shadowed by the connecting role, promoting a
  diagnosis to a hard failure; or add a walk scenario that runs the whole adopter path under a
  deliberately colliding role name, so the collision is covered continuously instead of only by
  the SQL-level integration test. The last is the cheapest and the most likely right answer, and
  it needs the harness to parameterise the role name it currently hardcodes.
- **Installer injection into the host's router, config, or `mix.exs`.** `mix lockspire.install`
  deliberately writes nothing into these three files (ADOPT-D01/D02/D03/D04/D05's installer
  halves are fixed by making the *generated* templates self-sufficient, not by having the
  installer edit host-owned files). Actually injecting would be a new capability, not a defect
  fix, and was explicitly deferred pending walk evidence per the milestone's `2026-07-28`
  decision log, not assumed away.
- **The `mix ecto.migrate` redesign (ADOPT-D07), in both of its candidate forms:** a dedicated
  `mix lockspire.migrate` Mix task, or a host migration generator that writes a real migration
  file against Lockspire's own versioned migration modules. Either would be new public surface.
  The accepted cost until a future milestone takes this on: adopters must pass
  `--migrations-path Application.app_dir(:lockspire, "priv/repo/migrations")` themselves, as
  `mix lockspire.verify`'s own remediation text now says.
- **Session-backed interaction resume (ADOPT-D14).** Making the login POST's own redirect honor
  a posted `return_to` parameter would require either patching host-owned `phx.gen.auth`
  scaffolding (out of the installer's ownership model) or a new Lockspire-owned session/resume
  primitive (new protocol surface). Phase 128's guide half can narrate the current two-request
  workaround (POST login, then GET `return_to`) as the documented pattern instead.
- **The 127-01 install-manifest version-field change.** Not a numbered defect -- no walk step
  observed a break from it -- but a real behavior change to a generated artifact
  (`.lockspire/install_manifest.json`'s `version` field now reads from
  `Application.spec(:lockspire, :vsn)` instead of the pushed Mix project's own config) found by
  exactly the method this phase exists to apply (running the installer against a real host). It
  belongs in this record so a future manifest-format audit does not have to rediscover it.

## Dropped from the seed list

- **ADOPT-D12** (reference demo shadows the consent route with its own host controller,
  so `Lockspire.Web.ConsentLive` is never exercised by the repo's own demo) is **not** recorded
  as a numbered defect here. This walk never invokes `examples/adoption_demo` at all, so nothing
  about the demo's own routing choices was actually observed by this run -- recording it here
  would violate the ledger's own prohibition against recording a defect the walk did not
  observe. The underlying fact (RESEARCH Pitfall 5 / REF-01) remains real and remains Phase
  129's concern; it belongs in that phase's own scoping input, sourced from RESEARCH directly,
  not from this execution-evidence ledger.

## Not walked

- **`docs/install-and-onboard.md` §7 (Upgrade only the managed scaffolding)** -- not walked.
  This is the existing-install upgrade path, not the first-install path this walk proves.
  Reported as `step-07-upgrade (not walked)` at PASS level in the harness's own report, with a
  label shape (`(not walked)` suffix) that structurally excludes it from the ADOPT-03
  step-ID-to-guide-section mapping gate.
- **`docs/install-and-onboard.md` §8 (Finish the verification seam before shipping device
  login)** -- not walked. The device `/verify` seam sits outside the authorization-code + PKCE
  path this milestone proves. Reported as `step-08-verify-seam (not walked)`, same exclusion
  shape as above.

Both are deliberate scope decisions, not omissions: the harness reports them explicitly so a
reader can tell the difference.

## Harness-only correction (not a ledger defect)

Plan 126-06 also found and fixed one bug in the walk harness's own step-03a-config-import
workaround: `known_scopes` was completed with the reference demo's own scope vocabulary
(`openid`, `email`, `profile`, `read:billing`, `write:reports`), which never included
`read:walk` -- the scope this harness's own `step-03e-protected-route` and
`adopter_path_flow.py` invented for the `/api/walk/summary` proof. Requesting an unrecognized
scope at `/authorize` produced a real `invalid_scope` / "Requested scope is unknown" rejection
that looked, at first, like a missing `interaction_id`/`return_to` handoff defect. Once
`read:walk` was added to the walk's own `known_scopes` completion, the real handoff worked
correctly. This is a bug in this plan's own fixture, not an adopter-facing Lockspire defect --
no adopter would ever request a scope this harness invented for its own proof -- so it carries
no `ADOPT-Dnn` ID and is recorded here for transparency only.

The harness's own `step-03b-router-call` and `step-03b-router-wire` route-detection checks were
also found to false-positive: a bare `grep -F` substring match over `mix phx.routes` output
matched compile-warning file paths that happen to contain the mount-path substring (e.g.
`lib/host_app_web/controllers/lockspire_verification_html/...` contains `/lockspire`), which
initially masked ADOPT-D01's real, documented-and-expected zero-routes outcome. Both checks now
require an actual route-table row (an HTTP verb followed by the mount path), not any line
mentioning it. This is also a harness-only correction, not a ledger defect.
