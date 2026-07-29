# Phase 127: Installer Against A Real Host - Context

**Gathered:** 2026-07-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the installer-area defects the Phase 126 walk recorded, and prove `mix lockspire.install`
against a real generated Phoenix host instead of a directory the test emptied first.

The defect list is not invented here — it is read from
`.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md`. Phase 127 owns
twelve entries, fully or in part: **ADOPT-D01, D02, D03, D04, D05, D06, D07, D08, D09, D14,
D15, D16**. Requirements INSTALL-01, INSTALL-02, INSTALL-03.

In scope: `mix lockspire.install`, its generator (`lib/lockspire/generators/install.ex`), its
templates under `priv/templates/lockspire.install/`, the install manifest, `mix lockspire.verify`'s
remediation strings, `mix lockspire.client.create`'s repo access, the `ecto_sql` version range, and
the installer's own integration proof.

Out of scope and explicitly deferred:
- Making the installer inject into the host's router, config, or `mix.exs`. v1.36 treats this as a
  decision the walk should *inform*, not a conclusion. If evidence argues for it, log a future
  candidate — do not act.
- Host-owned seams: accounts, login UX, layouts, branding, policy.
- Guide/doc corrections → Phase 128. `examples/adoption_demo` reconciliation → Phase 129.
  Automating the walk → Phase 130.
- Widening `docs/supported-surface.md` with new Mix tasks or public modules. This is what
  constrains D06 and D07 (see D-13, D-14).

**Criterion 4 is a completeness gate:** every one of the twelve owned defects is either fixed here
or carries an explicit deferral with a stated reason recorded in the ledger. Silence on a defect
fails the phase.
</domain>

<decisions>
## Implementation Decisions

### Proof Shape & Lane (INSTALL-01, INSTALL-02)

- **D-01:** The integration proof runs against a **committed `mix phx.new` snapshot** — a real
  generated Phoenix host captured once and checked in — not against an emptied fixture and not
  against a per-run `mix phx.new`. User-confirmed reading of criterion 1: "freshly generated"
  means the host is real generator output, not that it is regenerated every run.
- **D-02:** The installer is invoked through `Mix.Project.in_project/4`, **not** `File.cd!`. This is
  the whole lever for INSTALL-02. `lib/lockspire/generators/install.ex:28-33` derives `app_module`
  from `Mix.Project.config() |> Keyword.fetch!(:app)` with no CLI override, and
  `test/integration/install_generator_test.exs:363-368` only `File.cd!`s — which never changes the
  Mix project. So the fixture is rendered today with `repo: Lockspire.Repo`, the *library's* own app
  name, and no test asserts the `repo:` line at all (`:38-71` assert everything else). That is
  literally INSTALL-02's "placeholder rather than the real host." `in_project/4` pushes the
  snapshot's own `mix.exs`, so app name, web module, router module, and repo module all resolve
  from the host with no flags, no subprocess, no network, and no compile.
- **D-03:** The proof asserts the resolved-against-host values explicitly — app name, web module,
  router module, **and the `repo:` line** (`priv/templates/lockspire.install/config.exs:8`), which
  is currently unasserted. `tmp/adopter-walk/host_app/config/lockspire.exs` from the Phase 126 walk
  is the evidence that the generator resolves `repo: HostApp.Repo` correctly when the Mix project
  really is the host — the defect is in the proof, not the generator.
- **D-04:** The snapshot lives **outside `test/`**. Under `test/support/` its `.ex` files are
  compiled by `elixirc_paths(:test)` (`mix.exs:70`) and collide with the existing
  `GeneratedHostAppWeb.*` modules; anywhere under `test/`, `phx.new`'s own `*_test.exs` files and
  the installer-generated `test/<app>/lockspire_fapi_smoke_e2e_test.exs` get swept up by `mix test`'s
  default glob and fail the suite. `package_files/0` (`mix.exs:479-491`) is an explicit wildlist, so
  nothing new ships to Hex regardless.
- **D-05:** The new host-interaction test is tagged `@moduletag :integration`. `install_generator_test.exs`
  is untagged today, so it runs in `test.fast` (`mix.exs:76`) and is *skipped* by `test.integration`
  (`mix.exs:77`). Untagged host-shaped work would land in three CI jobs including the minimum-Elixir
  matrix (`.github/workflows/ci.yml:106,176`) and slow every contributor loop.
- **D-06:** Existing content assertions are **extended, not rewritten** (roadmap note). The
  host-interaction gap is the new surface; the byte-comparison drift fences stay.
- **D-07:** The Phase 126 walk remains the fully-fresh end-to-end proof. Phase 127 does not add a
  `mix phx.new` shell-out to any automated lane; that stays a Phase 130 concern.

### Router Template (D01, D02, D03)

- **D-08:** `lockspire_routes` becomes a real `defmacro` returning a `quote do ... end` block,
  replacing the heredoc `String` at `priv/templates/lockspire.install/router.ex:9-10`. That heredoc
  is precisely why the guide's documented "call `lockspire_routes/0`" compiles cleanly and injects
  zero routes — a top-level expression returning a String is evaluated and discarded.
  This does **not** violate the no-injection rule: the macro body lives in a file the installer
  generates *into* the host and the manifest tracks, so the adopter still reads and edits the exact
  routes.
- **D-09:** The macro defines its own **deny-closed** `:require_operator` pipeline (plus a `defp`
  halt plug) for the admin scope, name overridable via macro opts. The admin mount cannot simply be
  dropped: `lib/lockspire/install/verify.ex:120-126` hard-errors when it is absent and `:128-134`
  errors when the public forward shadows it. Deny-closed, not permissive — operator auth stays
  host-owned, and a stock host compiles out of the box (Least-Surprise Host Seam).
- **D-10:** The template emits an explicit `pipe_through [:browser]` scope carrying the interaction
  routes and the consent LiveView **before** the pipeline-less forward, per
  `examples/adoption_demo/lib/adoption_demo_web/router.ex:53-65` — the only place in the repo that
  gets this right. Without it the consent LiveView gets no `fetch_session` and no
  `protect_from_forgery`. Phase 128 owns the corresponding guide text; Phase 127 owns the template.
- **D-11:** The template also emits the `live_session` wrapper around the consent route, with the
  `on_mount:` value left for the host to supply. The *block* is template-shaped (127); the
  `phx.gen.auth`-specific value (`{HostAppWeb.UserAuth, :mount_current_scope}`) is guide-shaped
  (128, ADOPT-D18). Emitting the block now gives Phase 128 a structural place to document the value
  instead of forcing a second router-template edit later.
- **D-12:** While in this file, remove the duplicated admin scope — `router.ex:40-52` renders the
  identical scope twice, once as a comment labelled "Example:" and once live — and tidy the
  `LOCKSPIRE_PROTECTED_PIPELINE` commented block.

### Config Template (D04)

- **D-13:** Emit `issuer` **including the mount path**. Today's bare `issuer: "https://example.com"`
  (`priv/templates/lockspire.install/config.exs:10`) is guaranteed to raise at
  `lib/lockspire/policy.ex:104-106`. Add `known_scopes: ["openid", "email", "profile"]` —
  `authorization_request.ex:967-968` rejects *every* non-openid scope when it is unset — and
  `signing_alg: "RS256"`.
- **D-14:** `secret_key_base` is emitted as an explicit placeholder, never a literal value.
  `Lockspire.Config.inferred_secret_key_base/0` (`lib/lockspire/config.ex:255-265`) scans only the
  `:lockspire` app env and can never see the host endpoint's secret, so it must be emitted — but a
  committed literal is a security defect (see Phase 126 T-126-04). Consumed by `policy.ex:220` and
  `dpop_nonce.ex:62`.
- **D-15:** The `oban:` half of ADOPT-D04 is **not** a config-template gap.
  `Lockspire.Oban.runtime_config!/0` (`lib/lockspire/oban.ex:11-29`) defaults queues on; the walk
  only needed `queues: false` because of the D05 start-ordering problem. Treat it as D05.

### Conflict & Re-run Semantics (INSTALL-03)

- **D-16:** `Install.run/1` becomes **plan-then-apply**: classify every destination as
  `:create | :unchanged | :conflict` before writing anything, print the whole plan, and refuse
  atomically with the *full* conflict list if any conflict exists. Today
  `lib/lockspire/generators/install.ex:16-20` runs `Enum.each(&ensure_file!/2)` and writes the
  manifest afterward, while `ensure_file!` (`:113-119`) raises on the **first** differing file — so
  a conflicting re-run writes some files, aborts mid-loop, and never writes the manifest. That is
  the "unclear half-installed state" INSTALL-03 names verbatim.
  `test/integration/install_generator_test.exs:323-361` only proves it raises, never that the host
  is left coherent.
- **D-17:** Mirror `lib/mix/tasks/lockspire.upgrade.ex:21,50-118` — it already implements exactly
  this shape in this codebase: collect all drifts, print `REFUSE <path> (<reason>)` per file, raise
  once, and offer `--dry-run`. Copy the pattern; do not invent one. `--dry-run` is added to
  `lockspire.install` for parity.
- **D-18:** A re-run whose `--web` / `--scope` / `--mount-path` differ from the manifest's recorded
  `inputs` is reported and refused, rather than silently producing a second orphaned file set.
  `Lockspire.Install.Manifest.build/2` (`lib/lockspire/install/manifest.ex:53-62`) already records
  `web_module`, `scope_module`, `mount_path`, `storage_prefix`, `oban_prefix` — no new state needed.
- **D-19:** Resolve the manifest inconsistency: `Manifest.write/2` (`manifest.ex:35-38`) silently
  overwrites a differing manifest while every other file refuses. Make it consistent with the
  refuse-on-drift rule.
- **D-20:** **No `--force`** and **no interactive prompt.** `--force` would let a re-run clobber
  host-owned seams (`account_resolver.ex`, `consent_live.ex`) — the exact constraint the phase is
  bound by. `Mix.Generator.create_file/3`'s prompt would hang the walk harness and CI, both of which
  run non-interactively.

### Library & Template Point Fixes

- **D-21 (D08):** `mix lockspire.client.create` wraps its `Clients.register_client/1` call in
  `Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _ -> ... end)`, exactly as
  `lib/lockspire/install/verify.ex:202-217` already does. **Not** `@requirements ["app.start"]` —
  `lockspire.verify.ex:10` also declares `["app.config"]` and works purely because of `with_repo`;
  `app.start` would boot the host's full endpoint from a CLI task.
- **D-22 (D09):** `priv/templates/lockspire.install/account_resolver.ex:75` becomes
  `login_path: "/users/log-in"` — Phoenix's own `phx.gen.auth` default — with an explicit
  "change this to your host's login route" comment. Optionally a `verify.ex` check that the path
  resolves to a real host route.
- **D-23 (D15):** Loosen `mix.exs:47` to **`">= 3.13.5 and < 4.0.0"`**, not `"~> 3.13"`, with an
  inline rationale comment. Research verdict (verified against the Hex API and both upstream
  changelogs): `ecto_sql 3.14.0` has **no** backwards-incompatible changes and no deprecations, and
  touches nothing Lockspire uses — `Ecto.Migrator` usage is confined to `with_repo/2`, `run/3`,
  `migrations/2`; `Ecto.Adapters.SQL` to one `query/4`; and the v1.34 prefix-isolated storage
  (`lib/lockspire/storage/ecto/{migration,prefix}.ex`) reaches no ecto_sql internals at all. The
  `.5` was never deliberate — `git log -S'ecto_sql' -- mix.exs` returns a single commit
  (`c839753`, the initial skeleton) and the string has been byte-identical since; it is "latest at
  scaffold time." The explicit range keeps the PG18 `:restrict_violation` fix as a floor and matches
  the house style already at `mix.exs:45` for `phoenix_live_view`.
  **Land it together with one CI run that actually resolves 3.14** — the API analysis is verified,
  the suite result is not.
- **D-24 (D16):** `priv/templates/lockspire.install/authorized_apps/index.html.heex:19` becomes
  `<li id={"authorized-app-#{consent.grant.id}"}>` — Elixir interpolation, not a nested EEx tag,
  inside the HEEx `{...}` attribute. Confirmed the only nested-EEx-in-attribute occurrence; the
  file's other `<%= %>` uses are body-position and legal.
- **D-25 (D16 regression fence):** Add a test that compiles **every** generated `.heex` via
  `Phoenix.LiveView.TagEngine.compile/2` (`caller: __ENV__`, `tag_handler: Phoenix.LiveView.HTMLEngine`,
  `file:`, `line:`), driven off `Generators.Install.rendered_templates/1`
  (`lib/lockspire/generators/install.ex:63-75`). Do **not** use `EEx.compile_string(engine: TagEngine)`
  — that route emits a deprecation on the resolved `phoenix_live_view 1.2.8`
  (`deps/phoenix_live_view/lib/phoenix_live_view/tag_engine.ex:241-267`). `compile/2` is public and
  documented (`tag_engine.ex:24-52`) and is what `sigil_H` itself calls.
  **Verified empirically:** the researcher ran this helper against the real template and reproduced
  ADOPT-D16 at `index.html.heex:19:16`. Note `render_template_content/3` prepends an ownership
  header, so reported line numbers are offset from the source template.

### Installer Instructions (D05, D06 — installer halves only)

- **D-26 (D05):** Zero-injection fix. `instructions/1` (`lib/lockspire/generators/install.ex:130-142`)
  prints the required `included_applications: [:lockspire]`, the `extra_applications` additions
  (`:oban`, `:cachex`), and Lockspire's three supervision children ordered *after* the host's Repo.
  The installer does not touch the host's `mix.exs` or `application.ex`.
  `examples/adoption_demo/mix.exs:16-22` is the reference shape. `mix lockspire.verify` gains a
  check that the children are actually running. Guide half → Phase 128.
- **D-27 (D06):** `instructions/1` names the existing public three-call key lifecycle by name —
  `Lockspire.Admin.generate_key/1` → `publish_key/2` → `activate_key/2`
  (`lib/lockspire/admin/keys.ex:36,80,103`). A new `mix lockspire.key.create` task would widen
  `docs/supported-surface.md:13-17` and is out of scope. Guide half → Phase 128.
  The walk proved these are three genuinely separate stages: JWKS-non-empty is **not** sufficient
  evidence that a key can sign.

### Deferrals Recorded in the Ledger (criterion 4)

- **D-28 (D07 — user-confirmed):** Fix the **wrong remediation strings**, defer the redesign.
  `lib/lockspire/install/verify.ex:241` and `lib/lockspire/generators/install.ex:140` both prescribe
  the bare `mix ecto.migrate` the walk proved runs zero of Lockspire's 37 migrations. Change both to
  the release-safe `--migrations-path Application.app_dir(:lockspire, "priv/repo/migrations")` form
  already used internally at `lib/mix/tasks/lockspire.test.setup.ex:34` and `verify.ex:197`.
  Never a source-tree-relative path — it does not exist inside a compiled release.
  **Deferred with reason:** the full redesign (a `mix lockspire.migrate` task, or an Oban-pattern
  host migration generator writing `priv/repo/migrations/<ts>_add_lockspire.exs` against versioned
  `Lockspire.Migration` modules) requires new public surface, which `.planning/REQUIREMENTS.md`'s
  Out-of-Scope table forbids for v1.36. Record as a FUTURE candidate, visibly enough that Phase
  128's WIRE-02 does not silently inherit an unsolvable doc problem. Adopters still need a flag —
  that is the accepted cost.
- **D-29 (D14):** Defer to Phase 128. `phx.gen.auth`'s generated `log_in_user/3` ignoring a POSTed
  `return_to` is host scaffolding the installer cannot and must not patch. Phase 127 fixes only D09;
  log a FUTURE candidate for session-backed interaction resume.

### Claude's Discretion

- Exact macro option names for the router pipelines (`operator_pipeline:` / `browser_pipeline:` vs
  positional), and whether the deny-closed pipeline is opt-out.
- The snapshot's on-disk location and how it is refreshed/documented.
- Whether the `verify.ex` login-route check (D-22) is worth its complexity.

### Folded Todos

None — `gsd-tools query todo.match-phase 127` returned zero matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

Primary input:
- `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md` — the twelve owned
  defects, verbatim. This phase's scope *is* this file.
- `.planning/phases/126-adopter-path-walk-defect-ledger/126-CONTEXT.md` — prior locked decisions
  D-01..D-49, especially D-48's migration research.
- `.planning/ROADMAP.md` "### Phase 127"; `.planning/REQUIREMENTS.md` (INSTALL-01..03 and the
  Out of Scope table); `.planning/METHODOLOGY.md`.

Installer surface:
- `lib/lockspire/generators/install.ex` — `:16-20` write loop, `:28-33` app-name derivation,
  `:63-75` `rendered_templates/1`, `:106-128` `ensure_file!`, `:130-142` `instructions/1`
- `lib/lockspire/generators/templates.ex` — 12-entry inventory and output-path functions
- `lib/lockspire/install/manifest.ex` — `:24-48` write semantics, `:50-62` recorded inputs
- `lib/lockspire/install/verify.ex` — `:96-160` router contract, `:196-217` `with_repo`,
  `:241` the wrong remediation string, `:275` the one `Ecto.Adapters.SQL.query/4`
- `lib/mix/tasks/lockspire.upgrade.ex:21,50-118` — the collect-all-then-refuse + `--dry-run` pattern
- `lib/mix/tasks/lockspire.client.create.ex` and `lib/mix/tasks/lockspire.verify.ex` — both declare
  `@requirements ["app.config"]`; only one wraps its repo call
- `priv/templates/lockspire.install/{router.ex,config.exs,account_resolver.ex,authorized_apps/index.html.heex}`

Tests and fences:
- `test/integration/install_generator_test.exs` — `:6-7`, `:36` (template count == 12), `:38-71`
  (content assertions, no `repo:` line), `:159-210` (byte-compare drift fence), `:236-240`
  (`Code.compile_string` precedent), `:323-361` (conflict test), `:363-386` (`reset_fixture!`)
- `test/integration/install_upgrade_test.exs` — same fixture, same `reset_fixture!`
- `test/lockspire/maintainer/defect_ledger_contract_test.exs` — set-equality gate between
  `LOCKSPIRE_WALK_WORKAROUND` markers and ledger entries
- `test/support/generated_host_app_web/` — the compiled-in-test-env host fixture

Reference wiring (read, do not edit — Phase 129 owns the demo):
- `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-30,49-65`
- `examples/adoption_demo/mix.exs:16-22`, `examples/adoption_demo/lib/adoption_demo/application.ex:7-17`
- `examples/adoption_demo/config/config.exs:64-77`

Walk harness (the workarounds this phase removes):
- `scripts/maintainer/adopter_path_walk.sh` — `:503-551` (D15), `:552-590` (D16), `:600-670` (D04),
  `:726-820` (D02/D03/D18), `:800-812` (D18 `live_session`), `:990-1058` (D05), `:1214-1250` (D07),
  `:1258-1310` (D08), `:1340-1370` (D06)

Constraints:
- `mix.exs` — `:41-47` deps and the range-not-pin precedent at `:45`, `:70` `elixirc_paths(:test)`,
  `:76-77` lane definitions, `:118-127` `ci:`, `:479-491` `package_files/0`
- `docs/supported-surface.md:13-17` — the Mix-task support contract constraining D06 and D07
- `.github/workflows/ci.yml:106,176` — the jobs running `test.fast`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Mix.Project.in_project/4`** — the zero-cost lever for INSTALL-02. Pushes the fixture's own
  `mix.exs` and cds into it, so `app_module`/`app_path` resolve from the host with no flags, no
  subprocess, no network, no compile. This is what makes the router and config fixes verifiable
  without running the full walk.
- **`lib/mix/tasks/lockspire.upgrade.ex`** — already implements the exact collect-all-drifts /
  `REFUSE <path> (<reason>)` / raise-once / `--dry-run` shape INSTALL-03 needs.
- **`lib/lockspire/install/verify.ex:202-217`** — the `Ecto.Migrator.with_repo/2` pattern that fixes
  D08 verbatim.
- **`Phoenix.LiveView.TagEngine.compile/2`** — public and documented on LV 1.2.8; the HEEx
  compile fence. Empirically verified to reproduce D16.
- **`test/integration/install_generator_test.exs:236-240`** — `Code.compile_string` on a rendered
  template. The same idea applied to generated `.heex` would have caught D16 with no host at all.

### Established Patterns

- Refuse-on-drift, never overwrite, never prompt (install and upgrade both).
- Grep-able source markers are contracts (`BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE`,
  `LOCKSPIRE_WALK_WORKAROUND`).
- Lanes are Mix aliases; maintainer tooling never lives under `lib/mix/tasks/` (hygiene BLOCK).
- `mix ci` is daemon-free; Postgres arrives as a CI service, not Docker.
- Version requirements are ranges with rationale comments, not patch pins (`mix.exs:45`).

### Integration Points — these break if ignored

1. **`test/lockspire/maintainer/defect_ledger_contract_test.exs` enforces set equality** between
   harness workaround markers and ledger entries. Every defect fixed here requires deleting its
   `LOCKSPIRE_WALK_WORKAROUND` marker in `scripts/maintainer/` **and** reconciling that entry's
   `Workaround:` field in the ledger, in the same commit. A marker with no entry and an entry
   claiming a missing marker both fail, in both directions.
2. **`install_generator_test.exs:36` asserts `Templates.all/0` length == 12**, with a matching
   comment at `templates.ex:63-66`. Any template added or removed updates both.
3. **`verify.ex:120-134` requires the admin mount present and ordered before the public forward.**
   A router-template change that drops or reorders it turns `mix lockspire.verify` red on a
   correctly-installed host.
4. **`install_generator_test.exs:209-210` byte-compares the generated `router/lockspire.ex`**
   against `test/support/generated_host_app_web/router/lockspire.ex`. The D01/D02/D03 rewrite must
   update that runtime fixture, which is *compiled* into the test env and consumed by
   `phase6_onboarding_e2e_test.exs`, `phase31_*`, `phase81_*`, and `phase100_*`.
5. **`examples/adoption_demo` is the reference the template is aligned to — but Phase 129 owns
   reconciling it.** Read it; do not edit it here.
</code_context>

<specifics>
## Specific Ideas

- The router fix must satisfy both documented readings of guide §3 simultaneously: calling
  `lockspire_routes/0` (D01) *and* pasting its rendered body (D02) must each produce a compiling
  host with real routes. The macro form satisfies the first; the generated pipeline satisfies the
  second.
- `">= 3.13.5 and < 4.0.0"` specifically, matching `mix.exs:45`'s existing style and comment shape —
  not `"~> 3.13"`, which would drop the PG18 constraint-mapping floor.
- The D16 fence should cover *all* generated `.heex`, not just the one known-bad file. Verified
  coverage: it catches nested-EEx-in-attribute and unmatched/mismatched tags; it does not catch
  unknown components, which is correct scope for a generator regression test.
</specifics>

<deferred>
## Deferred Ideas

- **Installer injection into the host's router / config / `mix.exs`** — a real design possibility
  the walk was meant to inform. v1.36 does not act on it. Future candidate.
- **`Lockspire.Migration` + host migration generator (Oban pattern)** — the only shape that makes
  the guide's bare `mix ecto.migrate` literally true. Widens `docs/supported-surface.md`, converts
  37 file migrations to BEAM code, and needs an upgrade path for installs already migrated via
  `--migrations-path`. Deferred with reason per criterion 4; record in the ledger. Future candidate.
- **`mix lockspire.migrate`** — the smaller version of the same. Still adds a supported-surface
  entry, still shares `schema_migrations`, still leaves `mix ecto.migrations` printing
  `** FILE NOT FOUND **`. Deferred alongside the above.
- **`mix lockspire.key.create`** — would make D06 a one-liner but widens the Mix-task support
  contract. Deferred; D-27 names the existing public functions instead.
- **Session-backed interaction resume through the login POST (ADOPT-D14)** — Phase 128 or later.
- **Fresh `mix phx.new` in an automated lane** — the cold-CI cost (archive install, host
  `deps.get`, `bcrypt_elixir` NIF compile) is unmeasured; the Phase 126 walk's warm local timings
  (~1-2 min) are not representative. Phase 130's concern.
- **`tmp/adopter-walk/` joining the repo-hygiene artifact allowlist** — Phase 130 candidate,
  carried over from Phase 126 (ADOPT-D13).

### Reviewed Todos (not folded)

None — no pending todos matched this phase.
</deferred>
