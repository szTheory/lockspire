# Phase 127: Installer Against A Real Host - Research

**Researched:** 2026-07-28
**Domain:** Elixir/Mix generator correctness, Phoenix router macro injection, ExUnit host-fixture integration proofs
**Confidence:** HIGH (nearly every claim below was reproduced empirically in this session against the real code)

## Summary

This phase is unusual: the discuss-phase already produced a 29-decision CONTEXT.md with file:line citations,
so the research job is not "what stack should we use" but "verify the locked decisions against the running
code, enumerate the exact defect set, and surface the couplings that will bite the plan." That is what this
document does. Every load-bearing mechanism named in CONTEXT.md was executed in this session against the real
generator, the real templates, and a real `mix phx.new` host `mix.exs`.

Three things were **verified by execution**, not by reading: (1) `Mix.Project.in_project/4` really does make
`Lockspire.Generators.Install.build_assigns/1` resolve `HostApp` / `HostAppWeb` / `HostAppWeb.Router` /
`HostApp.Lockspire` from a real host `mix.exs` with no flags, no subprocess, no network, and no compile, and
it is safely re-enterable; (2) a `defmacro lockspire_routes` returning `quote do … end` injects a real,
correctly-ordered eight-route table into a Phoenix router (admin forward before public forward, exactly the
shape `Lockspire.Install.Verify`'s `router_check` demands); (3) a conflicting re-run of `Install.run/1`
genuinely leaves the host half-installed — `account_resolver.ex`, `interaction_handler.ex`, and the manifest
were all missing after the abort, and only the *first* conflict was reported.

Three things were **found that CONTEXT.md does not record**, and all three change the plan. First, the install
manifest's `"version"` field records the **host app's** version, not Lockspire's — the real walk host's
manifest says `0.1.0` while Lockspire is `1.4.0`, and `install_generator_test.exs:46` asserts the value is
correct only because `File.cd!` leaves the Mix project pointed at Lockspire. Switching that proof to
`in_project` will flip this assertion, so the plan must decide whether to fix `Manifest.build/2` or move the
assertion. Second, the walk harness's `extract_lockspire_routes_body` (`adopter_path_walk.sh:272-282`) parses
the router template by matching the heredoc's `"""` delimiter lines — converting the template to a `quote`
block silently breaks that extraction, and `adopter_walk_contract_test.exs:254-260` requires the step it feeds
to keep existing. Third, `mix qa` format-checks and Credo-scans `test/**` and `lib/**`, which is an independent
and stronger reason than the ones CONTEXT.md gives for keeping the `phx.new` snapshot out of `test/` — stock
generated Phoenix code will not survive `mix format --check-formatted` plus `credo --strict`.

**Primary recommendation:** Land the phase as four separable tracks — (A) router/config/HEEx/resolver template
fixes with a compile-level regression fence, (B) the `in_project` host-interaction proof against a committed,
trimmed `phx.new` snapshot copied to a scratch dir, (C) plan-then-apply conflict semantics copied verbatim
from `lockspire.upgrade`, (D) ledger reconciliation + marker removal for exactly the six markers this phase
actually closes. Sequence (A) before (B): the proof asserts the fixed shapes.

## Project Constraints (from AGENTS.md)

`./CLAUDE.md` does not exist; `./AGENTS.md` is the project instruction file. Directives that bind this phase:

| Directive | Source | Bearing on Phase 127 |
|-----------|--------|----------------------|
| "Preserve the embedded-library shape; do not turn this into a required standalone auth service." | AGENTS.md Working Boundaries | Reinforces the no-injection fence — the installer generates *into* the host, never patches host files. |
| "Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces." | AGENTS.md | Router template changes stay in `priv/templates/`; conflict logic stays in `Generators.Install`. |
| "Treat the host seam as explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app." | AGENTS.md | D-22's `login_path: "/users/log-in"` is a *default with a change-me comment*, not an assumption the library owns login. |
| "Install DX for a host Phoenix app" is product priority #1 | AGENTS.md | Justifies the whole phase; also justifies D-16's atomic refusal over partial writes. |
| Security defaults to preserve: "Strong redaction in logs and operator surfaces" | AGENTS.md | D-14: `secret_key_base` must be emitted as an explicit placeholder, never a literal. |
| Tech stack pins named: Phoenix 1.8.5, LiveView 1.1.28, Ecto SQL 3.13.5 | AGENTS.md | AGENTS.md itself names `Ecto SQL 3.13.5`. If D-23 loosens `mix.exs:47`, **AGENTS.md line 26 should be updated in the same commit** or it becomes stale documentation. CONTEXT.md does not mention this. |

## User Constraints (from CONTEXT.md)

### Locked Decisions

Copied verbatim from `.planning/phases/127-installer-against-a-real-host/127-CONTEXT.md` `<decisions>`.

**Proof Shape & Lane (INSTALL-01, INSTALL-02)**

- **D-01:** The integration proof runs against a **committed `mix phx.new` snapshot** — a real generated Phoenix host captured once and checked in — not against an emptied fixture and not against a per-run `mix phx.new`. User-confirmed reading of criterion 1: "freshly generated" means the host is real generator output, not that it is regenerated every run.
- **D-02:** The installer is invoked through `Mix.Project.in_project/4`, **not** `File.cd!`. This is the whole lever for INSTALL-02. `lib/lockspire/generators/install.ex:28-33` derives `app_module` from `Mix.Project.config() |> Keyword.fetch!(:app)` with no CLI override, and `test/integration/install_generator_test.exs:363-368` only `File.cd!`s — which never changes the Mix project. So the fixture is rendered today with `repo: Lockspire.Repo`, the *library's* own app name, and no test asserts the `repo:` line at all (`:38-71` assert everything else). That is literally INSTALL-02's "placeholder rather than the real host." `in_project/4` pushes the snapshot's own `mix.exs`, so app name, web module, router module, and repo module all resolve from the host with no flags, no subprocess, no network, and no compile.
- **D-03:** The proof asserts the resolved-against-host values explicitly — app name, web module, router module, **and the `repo:` line** (`priv/templates/lockspire.install/config.exs:8`), which is currently unasserted. `tmp/adopter-walk/host_app/config/lockspire.exs` from the Phase 126 walk is the evidence that the generator resolves `repo: HostApp.Repo` correctly when the Mix project really is the host — the defect is in the proof, not the generator.
- **D-04:** The snapshot lives **outside `test/`**. Under `test/support/` its `.ex` files are compiled by `elixirc_paths(:test)` (`mix.exs:70`) and collide with the existing `GeneratedHostAppWeb.*` modules; anywhere under `test/`, `phx.new`'s own `*_test.exs` files and the installer-generated `test/<app>/lockspire_fapi_smoke_e2e_test.exs` get swept up by `mix test`'s default glob and fail the suite. `package_files/0` (`mix.exs:479-491`) is an explicit wildlist, so nothing new ships to Hex regardless.
- **D-05:** The new host-interaction test is tagged `@moduletag :integration`. `install_generator_test.exs` is untagged today, so it runs in `test.fast` (`mix.exs:76`) and is *skipped* by `test.integration` (`mix.exs:77`). Untagged host-shaped work would land in three CI jobs including the minimum-Elixir matrix (`.github/workflows/ci.yml:106,176`) and slow every contributor loop.
- **D-06:** Existing content assertions are **extended, not rewritten** (roadmap note). The host-interaction gap is the new surface; the byte-comparison drift fences stay.
- **D-07:** The Phase 126 walk remains the fully-fresh end-to-end proof. Phase 127 does not add a `mix phx.new` shell-out to any automated lane; that stays a Phase 130 concern.

**Router Template (D01, D02, D03)**

- **D-08:** `lockspire_routes` becomes a real `defmacro` returning a `quote do ... end` block, replacing the heredoc `String` at `priv/templates/lockspire.install/router.ex:9-10`. That heredoc is precisely why the guide's documented "call `lockspire_routes/0`" compiles cleanly and injects zero routes — a top-level expression returning a String is evaluated and discarded. This does **not** violate the no-injection rule: the macro body lives in a file the installer generates *into* the host and the manifest tracks, so the adopter still reads and edits the exact routes.
- **D-09:** The macro defines its own **deny-closed** `:require_operator` pipeline (plus a `defp` halt plug) for the admin scope, name overridable via macro opts. The admin mount cannot simply be dropped: `lib/lockspire/install/verify.ex:120-126` hard-errors when it is absent and `:128-134` errors when the public forward shadows it. Deny-closed, not permissive — operator auth stays host-owned, and a stock host compiles out of the box (Least-Surprise Host Seam).
- **D-10:** The template emits an explicit `pipe_through [:browser]` scope carrying the interaction routes and the consent LiveView **before** the pipeline-less forward, per `examples/adoption_demo/lib/adoption_demo_web/router.ex:53-65` — the only place in the repo that gets this right. Without it the consent LiveView gets no `fetch_session` and no `protect_from_forgery`. Phase 128 owns the corresponding guide text; Phase 127 owns the template.
- **D-11:** The template also emits the `live_session` wrapper around the consent route, with the `on_mount:` value left for the host to supply. The *block* is template-shaped (127); the `phx.gen.auth`-specific value (`{HostAppWeb.UserAuth, :mount_current_scope}`) is guide-shaped (128, ADOPT-D18). Emitting the block now gives Phase 128 a structural place to document the value instead of forcing a second router-template edit later.
- **D-12:** While in this file, remove the duplicated admin scope — `router.ex:40-52` renders the identical scope twice, once as a comment labelled "Example:" and once live — and tidy the `LOCKSPIRE_PROTECTED_PIPELINE` commented block.

**Config Template (D04)**

- **D-13:** Emit `issuer` **including the mount path**. Today's bare `issuer: "https://example.com"` (`priv/templates/lockspire.install/config.exs:10`) is guaranteed to raise at `lib/lockspire/policy.ex:104-106`. Add `known_scopes: ["openid", "email", "profile"]` — `authorization_request.ex:967-968` rejects *every* non-openid scope when it is unset — and `signing_alg: "RS256"`.
- **D-14:** `secret_key_base` is emitted as an explicit placeholder, never a literal value. `Lockspire.Config.inferred_secret_key_base/0` (`lib/lockspire/config.ex:255-265`) scans only the `:lockspire` app env and can never see the host endpoint's secret, so it must be emitted — but a committed literal is a security defect (see Phase 126 T-126-04). Consumed by `policy.ex:220` and `dpop_nonce.ex:62`.
- **D-15:** The `oban:` half of ADOPT-D04 is **not** a config-template gap. `Lockspire.Oban.runtime_config!/0` (`lib/lockspire/oban.ex:11-29`) defaults queues on; the walk only needed `queues: false` because of the D05 start-ordering problem. Treat it as D05.

**Conflict & Re-run Semantics (INSTALL-03)**

- **D-16:** `Install.run/1` becomes **plan-then-apply**: classify every destination as `:create | :unchanged | :conflict` before writing anything, print the whole plan, and refuse atomically with the *full* conflict list if any conflict exists. Today `lib/lockspire/generators/install.ex:16-20` runs `Enum.each(&ensure_file!/2)` and writes the manifest afterward, while `ensure_file!` (`:113-119`) raises on the **first** differing file — so a conflicting re-run writes some files, aborts mid-loop, and never writes the manifest. That is the "unclear half-installed state" INSTALL-03 names verbatim. `test/integration/install_generator_test.exs:323-361` only proves it raises, never that the host is left coherent.
- **D-17:** Mirror `lib/mix/tasks/lockspire.upgrade.ex:21,50-118` — it already implements exactly this shape in this codebase: collect all drifts, print `REFUSE <path> (<reason>)` per file, raise once, and offer `--dry-run`. Copy the pattern; do not invent one. `--dry-run` is added to `lockspire.install` for parity.
- **D-18:** A re-run whose `--web` / `--scope` / `--mount-path` differ from the manifest's recorded `inputs` is reported and refused, rather than silently producing a second orphaned file set. `Lockspire.Install.Manifest.build/2` (`lib/lockspire/install/manifest.ex:53-62`) already records `web_module`, `scope_module`, `mount_path`, `storage_prefix`, `oban_prefix` — no new state needed.
- **D-19:** Resolve the manifest inconsistency: `Manifest.write/2` (`manifest.ex:35-38`) silently overwrites a differing manifest while every other file refuses. Make it consistent with the refuse-on-drift rule.
- **D-20:** **No `--force`** and **no interactive prompt.** `--force` would let a re-run clobber host-owned seams (`account_resolver.ex`, `consent_live.ex`) — the exact constraint the phase is bound by. `Mix.Generator.create_file/3`'s prompt would hang the walk harness and CI, both of which run non-interactively.

**Library & Template Point Fixes**

- **D-21 (D08):** `mix lockspire.client.create` wraps its `Clients.register_client/1` call in `Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _ -> ... end)`, exactly as `lib/lockspire/install/verify.ex:202-217` already does. **Not** `@requirements ["app.start"]` — `lockspire.verify.ex:10` also declares `["app.config"]` and works purely because of `with_repo`; `app.start` would boot the host's full endpoint from a CLI task.
- **D-22 (D09):** `priv/templates/lockspire.install/account_resolver.ex:75` becomes `login_path: "/users/log-in"` — Phoenix's own `phx.gen.auth` default — with an explicit "change this to your host's login route" comment. Optionally a `verify.ex` check that the path resolves to a real host route.
- **D-23 (D15):** Loosen `mix.exs:47` to **`">= 3.13.5 and < 4.0.0"`**, not `"~> 3.13"`, with an inline rationale comment. Research verdict (verified against the Hex API and both upstream changelogs): `ecto_sql 3.14.0` has **no** backwards-incompatible changes and no deprecations, and touches nothing Lockspire uses — `Ecto.Migrator` usage is confined to `with_repo/2`, `run/3`, `migrations/2`; `Ecto.Adapters.SQL` to one `query/4`; and the v1.34 prefix-isolated storage (`lib/lockspire/storage/ecto/{migration,prefix}.ex`) reaches no ecto_sql internals at all. The `.5` was never deliberate — `git log -S'ecto_sql' -- mix.exs` returns a single commit (`c839753`, the initial skeleton) and the string has been byte-identical since; it is "latest at scaffold time." The explicit range keeps the PG18 `:restrict_violation` fix as a floor and matches the house style already at `mix.exs:45` for `phoenix_live_view`. **Land it together with one CI run that actually resolves 3.14** — the API analysis is verified, the suite result is not.
- **D-24 (D16):** `priv/templates/lockspire.install/authorized_apps/index.html.heex:19` becomes `<li id={"authorized-app-#{consent.grant.id}"}>` — Elixir interpolation, not a nested EEx tag, inside the HEEx `{...}` attribute. Confirmed the only nested-EEx-in-attribute occurrence; the file's other `<%= %>` uses are body-position and legal.
- **D-25 (D16 regression fence):** Add a test that compiles **every** generated `.heex` via `Phoenix.LiveView.TagEngine.compile/2` (`caller: __ENV__`, `tag_handler: Phoenix.LiveView.HTMLEngine`, `file:`, `line:`), driven off `Generators.Install.rendered_templates/1` (`lib/lockspire/generators/install.ex:63-75`). Do **not** use `EEx.compile_string(engine: TagEngine)` — that route emits a deprecation on the resolved `phoenix_live_view 1.2.8` (`deps/phoenix_live_view/lib/phoenix_live_view/tag_engine.ex:241-267`). `compile/2` is public and documented (`tag_engine.ex:24-52`) and is what `sigil_H` itself calls. **Verified empirically:** the researcher ran this helper against the real template and reproduced ADOPT-D16 at `index.html.heex:19:16`. Note `render_template_content/3` prepends an ownership header, so reported line numbers are offset from the source template.

**Installer Instructions (D05, D06 — installer halves only)**

- **D-26 (D05):** Zero-injection fix. `instructions/1` (`lib/lockspire/generators/install.ex:130-142`) prints the required `included_applications: [:lockspire]`, the `extra_applications` additions (`:oban`, `:cachex`), and Lockspire's three supervision children ordered *after* the host's Repo. The installer does not touch the host's `mix.exs` or `application.ex`. `examples/adoption_demo/mix.exs:16-22` is the reference shape. `mix lockspire.verify` gains a check that the children are actually running. Guide half → Phase 128.
- **D-27 (D06):** `instructions/1` names the existing public three-call key lifecycle by name — `Lockspire.Admin.generate_key/1` → `publish_key/2` → `activate_key/2` (`lib/lockspire/admin/keys.ex:36,80,103`). A new `mix lockspire.key.create` task would widen `docs/supported-surface.md:13-17` and is out of scope. Guide half → Phase 128. The walk proved these are three genuinely separate stages: JWKS-non-empty is **not** sufficient evidence that a key can sign.

**Deferrals Recorded in the Ledger (criterion 4)**

- **D-28 (D07 — user-confirmed):** Fix the **wrong remediation strings**, defer the redesign. `lib/lockspire/install/verify.ex:241` and `lib/lockspire/generators/install.ex:140` both prescribe the bare `mix ecto.migrate` the walk proved runs zero of Lockspire's 37 migrations. Change both to the release-safe `--migrations-path Application.app_dir(:lockspire, "priv/repo/migrations")` form already used internally at `lib/mix/tasks/lockspire.test.setup.ex:34` and `verify.ex:197`. Never a source-tree-relative path — it does not exist inside a compiled release. **Deferred with reason:** the full redesign (a `mix lockspire.migrate` task, or an Oban-pattern host migration generator writing `priv/repo/migrations/<ts>_add_lockspire.exs` against versioned `Lockspire.Migration` modules) requires new public surface, which `.planning/REQUIREMENTS.md`'s Out-of-Scope table forbids for v1.36. Record as a FUTURE candidate, visibly enough that Phase 128's WIRE-02 does not silently inherit an unsolvable doc problem. Adopters still need a flag — that is the accepted cost.
- **D-29 (D14):** Defer to Phase 128. `phx.gen.auth`'s generated `log_in_user/3` ignoring a POSTed `return_to` is host scaffolding the installer cannot and must not patch. Phase 127 fixes only D09; log a FUTURE candidate for session-backed interaction resume.

### Claude's Discretion

- Exact macro option names for the router pipelines (`operator_pipeline:` / `browser_pipeline:` vs positional), and whether the deny-closed pipeline is opt-out.
- The snapshot's on-disk location and how it is refreshed/documented.
- Whether the `verify.ex` login-route check (D-22) is worth its complexity.

### Deferred Ideas (OUT OF SCOPE)

- **Installer injection into the host's router / config / `mix.exs`** — a real design possibility the walk was meant to inform. v1.36 does not act on it. Future candidate.
- **`Lockspire.Migration` + host migration generator (Oban pattern)** — the only shape that makes the guide's bare `mix ecto.migrate` literally true. Widens `docs/supported-surface.md`, converts 37 file migrations to BEAM code, and needs an upgrade path for installs already migrated via `--migrations-path`. Deferred with reason per criterion 4; record in the ledger. Future candidate.
- **`mix lockspire.migrate`** — the smaller version of the same. Still adds a supported-surface entry, still shares `schema_migrations`, still leaves `mix ecto.migrations` printing `** FILE NOT FOUND **`. Deferred alongside the above.
- **`mix lockspire.key.create`** — would make D06 a one-liner but widens the Mix-task support contract. Deferred; D-27 names the existing public functions instead.
- **Session-backed interaction resume through the login POST (ADOPT-D14)** — Phase 128 or later.
- **Fresh `mix phx.new` in an automated lane** — the cold-CI cost (archive install, host `deps.get`, `bcrypt_elixir` NIF compile) is unmeasured; the Phase 126 walk's warm local timings (~1-2 min) are not representative. Phase 130's concern.
- **`tmp/adopter-walk/` joining the repo-hygiene artifact allowlist** — Phase 130 candidate, carried over from Phase 126 (ADOPT-D13).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INSTALL-01 | `mix lockspire.install` is exercised against a freshly generated Phoenix application instead of an empty fixture directory. | § "The Existing Integration Proof" (what `reset_fixture!` does today), § "Pattern 2: `Mix.Project.in_project/4` as the host-resolution lever" (verified), § "Snapshot Placement" (where the committed `phx.new` output may live without breaking `mix qa`, `mix test`, or `hex.build`). |
| INSTALL-02 | Generated files match the host — app name, web module, router module, repo module resolve against the real host, not a placeholder. | § "Host-Resolution Correctness" — empirical output showing `HostApp` / `HostAppWeb` / `HostAppWeb.Router` / `HostApp.Lockspire` / `repo: HostApp.Repo` all resolving from a real `phx.new` `mix.exs` under `in_project`, with **no** `--web` / `--scope` flags. Plus the newly-found manifest `"version"` defect (Pitfall 1) that this switch will expose. |
| INSTALL-03 | Re-run behavior on conflicting/prior output is observable and predictable, leaving no unclear half-installed state. | § "Idempotency and Re-run Semantics" — empirical reproduction of the half-installed abort, the `lockspire.upgrade` pattern to copy, `Mix.Generator.create_file/3`'s prompting semantics read from the local Elixir 1.19.5 doc chunks, and a concrete definition of "observably and predictably." |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deriving host identity (app/web/router/repo modules) | Mix project layer (`Mix.Project.config/0`) | — | `build_assigns/1` reads the *pushed* Mix project. Whoever pushes the project owns the answer; that is why `File.cd!` is insufficient and `in_project` is the fix. |
| Rendering template content | Library — `Lockspire.Generators.Install` + `priv/templates/` | — | Pure `EEx.eval_file/2` over assigns. No host tier involvement. |
| Route definition and pipeline ownership | **Host router module** (generated file, host-owned edits) | Library macro emits the block | The macro expands *inside* the host's router. Operator auth stays host-owned (deny-closed default). |
| Conflict classification and refusal | Library — `Generators.Install` | Mix task layer (`--dry-run` flag parsing) | Must be decidable without host compilation, so it lives beside rendering. |
| Application-start ordering + supervision children | **Host** (`mix.exs`, `application.ex`) | Library only *prints* instructions | Out-of-scope fence: zero injection. `instructions/1` is the entire library-side surface for D05. |
| Migration execution | Host `mix ecto.migrate --migrations-path …` | Library supplies the path via `Application.app_dir/2` | Redesign deferred (D-28); library owns only the correctness of the printed string. |
| HEEx compile validity of generated templates | Library test lane | — | `Phoenix.LiveView.TagEngine.compile/2` needs no host at all. |
| Ledger reconciliation | Maintainer test lane (`defect_ledger_contract_test.exs`) | Walk harness (`scripts/maintainer/`) | Set-equality gate between harness markers and ledger entries; neither side can move alone. |

## The Installer-Attributed Defect Set (research emphasis 1)

The twelve defects Phase 127 owns, fully or in part. `Owning phase` and `Source` are quoted from
`.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md`.
`Marker` is the `LOCKSPIRE_WALK_WORKAROUND` line in `scripts/maintainer/`, verified by `grep` in this session.

| ID | Ledger source | Owning phase | Real root cause (file:line, verified) | Marker location | Marker removable in 127? |
|----|---------------|--------------|----------------------------------------|-----------------|--------------------------|
| **D01** | installer | 127 | `priv/templates/lockspire.install/router.ex:9-10` — `def lockspire_routes` returns a heredoc `String`; a top-level call evaluates and discards it, injecting zero routes. | *none* (ledger says `none`) | n/a — nothing to remove |
| **D02** | installer | 127 | Same file `:54` — pasted body's `pipe_through [:browser, :require_operator]` names a pipeline no stock `phx.new` router defines. | `adopter_path_walk.sh:782` | **Yes** — deny-closed pipeline in the macro removes the need |
| **D03** | installer and guide | 127 and 128 | Same file `:58-60` — `scope "/" do forward … end` has no `pipe_through`, so the forwarded consent LiveView and interaction routes get no `fetch_session` / `protect_from_forgery`. | `adopter_path_walk.sh:790` | **Yes** — template emits the browser-piped scope |
| **D04** | installer | 127 | `priv/templates/lockspire.install/config.exs:10` — `issuer: "https://example.com"` (raises against `mount_path`, see Pitfall 4); no `known_scopes`, `signing_alg`, `secret_key_base`. | `adopter_path_walk.sh:653` | **Partial only** — see Pitfall 8 |
| **D05** | installer and guide | 127 (installer half), 128 (guide half) | `lib/lockspire/generators/install.ex:130-142` — `instructions/1` never mentions `included_applications`, `extra_applications`, or Lockspire's three supervision children. | `adopter_path_walk.sh:1017`, `:1038` | **No** — the harness must still perform host wiring the installer deliberately does not inject |
| **D06** | installer and guide | 127 (installer half), 128 (guide half) | Same `instructions/1` — never names the three-stage key lifecycle (`Lockspire.Admin.Keys.generate_key/1` `:36`, `publish_key/2` `:80`, `activate_key/2` `:103`). | `adopter_path_walk.sh:1355` | **No** — harness must still make the calls |
| **D07** | installer | 127 | Bare `mix ecto.migrate` prescribed at **three** in-scope sites: `lib/lockspire/install/verify.ex:241`, `verify.ex:270`, `lib/lockspire/generators/install.ex:140`. (CONTEXT.md names only two — `verify.ex:270` is a third occurrence.) Plus `docs/install-and-onboard.md:108`, which is Phase 128's. | `adopter_path_walk.sh:1224` | **No** — redesign is deferred (D-28); harness still needs `--migrations-path` |
| **D08** | library | 127 | `lib/mix/tasks/lockspire.client.create.ex:10` declares `@requirements ["app.config"]` and calls `Clients.register_client/1` at `:39` without `Ecto.Migrator.with_repo/2`. Contrast `lib/lockspire/install/verify.ex:202` which wraps identically-declared work. | `adopter_path_walk.sh:1307` | **Yes** — task can reach a running repo after the fix |
| **D09** | installer | 127 | `priv/templates/lockspire.install/account_resolver.ex:75` — `login_path: "/login"`; `phx.gen.auth --live` generates `/users/log-in`. (`:86` also hardcodes `/logout`; worth reviewing in the same edit.) | `adopter_path_walk.sh:930` | **Yes** |
| **D14** | generated scaffolding and guide | 127 **or** 128 | `phx.gen.auth`'s `log_in_user/3` redirects to `:user_return_to` session key; a POSTed `return_to` is inert. Not patchable by the installer. | `adopter_path_flow.py:246` | **No** — D-29 defers to 128 |
| **D15** | installer | 127 | `mix.exs:47` `{:ecto_sql, "~> 3.13.5"}` vs. a stock host that locks `ecto_sql 3.14.0`. | `adopter_path_walk.sh:529` | **Yes** — after the range loosens |
| **D16** | generated scaffolding | 127 | `priv/templates/lockspire.install/authorized_apps/index.html.heex:19` — `<li id={"authorized-app-<%%= consent.grant.id %>"}>`; LV 1.2.8's tokenizer rejects a nested EEx tag inside a HEEx `{…}` attribute. | `adopter_path_walk.sh:582` | **Yes** |

**Six markers are removable in this phase: D02, D03, D08, D09, D15, D16.** Six must stay (D04 partially, D05,
D06, D07, D14), plus D10, D18, D19 which belong to other phases. See Pitfall 3 for the reconciliation
mechanics and Pitfall 9 for the "at least one marker must remain" constraint.

Success criterion 4 requires an explicit disposition for **all twelve**. Nothing may be silent. The plan should
carry a checklist task whose deliverable is the edited ledger, not just code.

## Standard Stack

No new dependencies. Every mechanism this phase needs already exists in the resolved tree.

### Core

| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| `Mix.Project.in_project/4` | Elixir 1.19.5 (stdlib) | Push a foreign `mix.exs` so `Mix.Project.config()` resolves the host, then run the generator. | The only in-process way to make `build_assigns/1` see a different app. `[VERIFIED: executed this session]` |
| `Phoenix.Router` macros (`scope`, `pipeline`, `forward`, `pipe_through`) | phoenix 1.8.9 | Route injection target for the `defmacro lockspire_routes` rewrite. | These are compile-time macros, so a `quote` block containing them expands correctly in a host router. `[VERIFIED: 8-route table produced this session]` |
| `Phoenix.LiveView.Router.live_session/3` + `live/4` | phoenix_live_view 1.2.8 | The consent-route wrapper D-11 requires. | `[VERIFIED: compiled inside the macro probe]` |
| `Phoenix.LiveView.TagEngine.compile/2` | phoenix_live_view 1.2.8 | HEEx compile fence over generated `.heex` (D-25). | Public, documented, and what `sigil_H` itself calls. `[VERIFIED: reproduced ADOPT-D16 this session]` |
| `Ecto.Migrator.with_repo/2` | ecto_sql 3.13.5 | Start the configured repo from a `["app.config"]` Mix task (D-21). | Already the in-repo pattern at `lib/lockspire/install/verify.ex:202-217`. `[VERIFIED: codebase grep]` |
| `ExUnit` | Elixir 1.19.5 | Test framework; `@moduletag :integration` for lane routing. | `[VERIFIED: test/test_helper.exs]` |

### Supporting

| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `Mix.Generator.create_file/3` | Elixir 1.19.5 | **Reference only — do not adopt.** | Read its semantics to justify D-20; it prompts on conflict unless `:force`. |
| `Lockspire.Install.Manifest` | in-repo | Records inputs + checksums; the state D-18 needs. | Already records `web_module`, `scope_module`, `mount_path`, `storage_prefix`, `oban_prefix`. |
| `Mix.Tasks.Lockspire.Upgrade` | in-repo | The plan-then-apply / `REFUSE`-list / `--dry-run` shape to copy. | D-17. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Mix.Project.in_project/4` | Shell out to `mix lockspire.install` as a subprocess in the snapshot | Real end-to-end, but needs the snapshot's `deps` fetched and compiled — minutes of cold CI, network, and a `{:lockspire, path: …}` that must resolve from the snapshot's location. Phase 130's concern per D-07. |
| `Mix.Project.in_project/4` | Add a `--app` CLI override to `build_assigns/1` | Would *reintroduce* the placeholder problem: the test would assert a value it supplied. Defeats INSTALL-02. |
| `defmacro` returning `quote` | `defmacro __using__/1` on the generated module | `use` is idiomatic for whole-module injection, but the guide documents *calling* `lockspire_routes/0` at a chosen point in the router body. A plain macro preserves that documented placement freedom; `__using__` does not. |
| `Phoenix.LiveView.TagEngine.compile/2` | `EEx.compile_string(engine: Phoenix.LiveView.TagEngine)` | Emits a deprecation on LV 1.2.8 and would trip `compile --warnings-as-errors` under `mix qa`. |
| Committed `phx.new` snapshot | Hand-written minimal fake host `mix.exs` | Cheaper, but stops being "a freshly generated Phoenix application" — INSTALL-01 says generated. A trimmed *real* snapshot keeps the claim honest. |

**Installation:** none — no packages added.

**Version verification (authoritative registry, hex.pm API, checked 2026-07-28):**

```
ecto_sql: 3.14.0 (2026-05-19) latest; 3.13.5 (2026-03-03) currently locked
ecto:     3.14.0 (2026-05-19); 3.13.6 currently locked
```

## Package Legitimacy Audit

This phase installs **no new external packages**. The only dependency change under consideration is loosening
an existing version requirement (`mix.exs:47`, `{:ecto_sql, "~> 3.13.5"}` → `">= 3.13.5 and < 4.0.0"`).

`gsd-tools query package-legitimacy check` does not support the `hex` ecosystem (it accepts
`npm|pypi|crates` only), so verification was done directly against the authoritative Hex registry API.

| Package | Registry | Age | Source Repo | Verdict | Disposition |
|---------|----------|-----|-------------|---------|-------------|
| `ecto_sql` 3.14.0 | hex.pm (`api/packages/ecto_sql`) | published 2026-05-19 (~2 mo) | github.com/elixir-ecto/ecto_sql | OK | Approved — already a direct dependency; only the requirement string changes |
| `ecto` 3.14.0 (transitive) | hex.pm (`api/packages/ecto/releases/3.14.0`) | published 2026-05-19 | github.com/elixir-ecto/ecto | OK | Approved — pulled in by `ecto_sql ~> 3.14.0`'s own requirement |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

**Correction to CONTEXT D-23's blast-radius analysis.** D-23 asserts the change is safe because `ecto_sql
3.14.0` has no breaking changes. That is true but incomplete: `ecto_sql 3.14.0` requires
**`ecto ~> 3.14.0`**, so the real change is `ecto 3.13.6 → 3.14.0`, not `ecto_sql` alone.
`[VERIFIED: hex.pm API, ecto_sql/releases/3.14.0 requirements]`

Mitigating facts, both verified:
- `ecto_sql 3.14.0` also requires `decimal ~> 3.0` and `db_connection ~> 2.9`. **Both are already satisfied**
  by the committed lock (`decimal 3.1.1`, `db_connection 2.10.2`). No extra bumps.
- `ecto 3.14.0`'s own changelog documents **no backwards-incompatible changes and no deprecations**.
  `[CITED: raw.githubusercontent.com/elixir-ecto/ecto/master/CHANGELOG.md]`

The one Ecto 3.14.0 entry with real behavior-change potential is
*"[Ecto.Repo] Raise an error on query-like keyword opts to Repo functions"* — it turns a previously-ignored
mistake into a raise. A second entry, *"[mix ecto.create] Set timezone by default when creating new
databases,"* touches CI DB creation. Both are worth a targeted grep + a real suite run rather than a
changelog-only sign-off. Lockspire's Ecto surface is narrow — `Ecto.Changeset`, `Ecto.Schema`, `Ecto.Enum`,
`Ecto.Query`, `Ecto.UUID.generate`, `Ecto.Migration`, and one `Ecto.Adapters.SQL.query/4`
`[VERIFIED: grep over lib/lockspire]` — so the exposure is small, but "small" is not "measured."

## Architecture Patterns

### System Architecture Diagram

```
                  ┌──────────────────────────────────────────────────────────────┐
                  │  ENTRY: adopter runs `mix lockspire.install` inside their app │
                  │  ENTRY: ExUnit proof calls Install.run/1 under in_project     │
                  └──────────────────────────┬───────────────────────────────────┘
                                             │  opts (--web/--scope/--mount-path/--dry-run)
                                             ▼
                        ┌───────────────────────────────────────┐
                        │  build_assigns/1                       │
                        │  reads Mix.Project.config()[:app]      │◄── the PUSHED Mix project
                        └──────────────────┬────────────────────┘    (host under in_project;
                                           │ assigns                  Lockspire under File.cd!)
                                           ▼
                        ┌───────────────────────────────────────┐
                        │  rendered_templates/1                  │
                        │  Templates.all() ×12 → EEx.eval_file   │
                        │  + ownership_header/2 prepended        │
                        └──────────────────┬────────────────────┘
                                           │ [%{destination, rendered, relative_path, template}]
                     ┌─────────────────────┴──────────────────────┐
                     │                                            │
        ═══ TODAY ═══▼                              ═══ TARGET (D-16) ═══▼
     Enum.each(&ensure_file!/2)                   PLAN PHASE (no writes)
       ├─ read destination                          classify each destination:
       ├─ same?   → "* unchanged"                     :create | :unchanged | :conflict
       ├─ differs → Mix.raise  ◄── ABORTS HERE        + manifest-inputs drift (D-18)
       └─ enoent  → write                             + manifest-content drift (D-19)
                     │                                            │
        partial writes, no manifest                   any :conflict ?
        ✗ half-installed host                       ┌──────┴───────┐
                                                   yes             no
                                                    │               │
                                          print REFUSE <path>   --dry-run ?
                                          (reason) for ALL      ┌────┴────┐
                                          raise ONCE           yes        no
                                          ✓ zero writes         │          │
                                                          print plan   APPLY PHASE
                                                          exit 0       write all + manifest
                                                                             │
                                                                             ▼
                                                              ┌──────────────────────────┐
                                                              │  instructions/1 (stdout) │
                                                              │  + config import         │
                                                              │  + router import/call    │
                                                              │  + app-tree wiring (D05) │
                                                              │  + key lifecycle  (D06)  │
                                                              │  + migrate w/ path (D07) │
                                                              └──────────────────────────┘

  GENERATED-INTO-HOST ARTIFACTS                     HOST-OWNED ACTIONS (never injected)
  ───────────────────────────────                   ─────────────────────────────────────
  lib/<web>/router/lockspire.ex ──── import ──────► host router.ex calls lockspire_routes()
       (defmacro → quote)                                    │ expands at compile time
  config/lockspire.exs ──────────── import_config ─► config/config.exs
  lib/<scope>/account_resolver.ex ─ referenced ────► config :lockspire, account_resolver:
  .lockspire/install_manifest.json ─ read by ──────► mix lockspire.upgrade / re-run planning
                                                     host mix.exs + application.ex edits
```

### Recommended Project Structure

```
priv/
├── templates/lockspire.install/     # EDITED: router.ex, config.exs,
│                                    #         account_resolver.ex,
│                                    #         authorized_apps/index.html.heex
└── test_fixtures/                   # NEW (see § Snapshot Placement)
    └── phx_new_host/                #   committed, trimmed `mix phx.new` output
        ├── mix.exs                  #   REQUIRED — the only strictly-needed file
        ├── config/                  #   optional, raises fidelity
        └── lib/host_app{,_web}/     #   optional, raises fidelity

lib/lockspire/generators/install.ex  # EDITED: plan/apply split, instructions/1
lib/lockspire/install/manifest.ex    # EDITED: refuse-on-drift (D-19), version field (Pitfall 1)
lib/mix/tasks/lockspire.install.ex   # EDITED: --dry-run switch
lib/mix/tasks/lockspire.client.create.ex  # EDITED: with_repo wrapper (D-21)
lib/lockspire/install/verify.ex      # EDITED: :241 and :270 remediation strings

test/integration/
├── install_generator_test.exs       # EXTENDED, not rewritten (D-06)
├── install_host_interaction_test.exs   # NEW — @moduletag :integration, in_project
└── install_template_compile_test.exs   # NEW — HEEx + router macro compile fences

test/support/generated_host_app_web/router/lockspire.ex  # REGENERATED (byte-compare fence)
scripts/maintainer/adopter_path_walk.sh                  # 6 markers removed + :272-282 fixed
.planning/phases/126-.../126-DEFECT-LEDGER.md            # 12 dispositions recorded
```

### Pattern 1: `defmacro` returning `quote` for host route injection (D-08)

**What:** Replace `def lockspire_routes do """…""" end` with `defmacro lockspire_routes(opts \\ []) do quote
do … end end`. Phoenix's `scope`/`pipeline`/`forward`/`pipe_through`/`live_session`/`live` are all compile-time
macros, so a `quote` block containing them expands correctly at the call site inside the host router.

**When to use:** Always for library-provided route helpers. A function returning a String can never inject
routes — this is ADOPT-D01's exact root cause.

**Requirements the host must satisfy:** the generated helper module must be compiled *before* the router
(automatic — it is a separate file), the router must `import` it, and any pipeline the macro references by
name must exist. Emitting the operator pipeline from inside the macro is what removes the D02 requirement on
the host.

**Verified example** — this exact code was compiled and its route table read back in this session:

```elixir
# Source: empirically verified this session against phoenix 1.8.9 / phoenix_live_view 1.2.8
defmodule ProbeWeb.Router.Lockspire do
  defmacro lockspire_routes(opts \\ []) do
    operator_pipeline = Keyword.get(opts, :operator_pipeline, :lockspire_require_operator)
    browser_pipeline = Keyword.get(opts, :browser_pipeline, :browser)

    quote do
      pipeline unquote(operator_pipeline) do
        plug(:lockspire_deny_operator_access)
      end

      scope "/", ProbeWeb do
        pipe_through([unquote(browser_pipeline)])
        get("/verify", LockspireVerificationController, :show)
        get("/authorized-apps", AuthorizedAppsController, :index)
      end

      scope "/lockspire/admin" do
        pipe_through([unquote(browser_pipeline), unquote(operator_pipeline)])
        forward("/", Lockspire.Web.AdminRouter)
      end

      scope "/lockspire" do
        pipe_through([unquote(browser_pipeline)])
        get("/interactions/:interaction_id", Lockspire.Web.InteractionController, :show)
        post("/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete)

        live_session :lockspire_consent do
          live("/consent/:interaction_id", Lockspire.Web.ConsentLive, :show)
        end
      end

      scope "/" do
        forward("/lockspire", Lockspire.Web.Router)
      end

      defp lockspire_deny_operator_access(conn, _opts) do
        conn
        |> Plug.Conn.send_resp(403, "Lockspire operator access is not configured")
        |> Plug.Conn.halt()
      end
    end
  end
end
```

Called as `lockspire_routes()` inside a stock router body, `Phoenix.Router.routes/1` returned:

```
get  /                                    ProbeWeb.PageController          (host's own)
get  /verify                              ProbeWeb.LockspireVerificationController
get  /authorized-apps                     ProbeWeb.AuthorizedAppsController
*    /lockspire/admin                     Lockspire.Web.AdminRouter        ◄── before public
get  /lockspire/interactions/:interaction_id   Lockspire.Web.InteractionController
post /lockspire/interactions/:interaction_id/complete  Lockspire.Web.InteractionController
get  /lockspire/consent/:interaction_id   Phoenix.LiveView.Plug
*    /lockspire                           Lockspire.Web.Router             ◄── public last
```

That ordering is exactly what `Lockspire.Install.Verify.router_check/2` requires: admin forward present
(`verify.ex:120-126`) and not shadowed by the public forward (`verify.ex:128-134`).

Note that `defp lockspire_deny_operator_access/2` defined **inside** the quote works — function definitions in
a quote are not name-hygienized, and `plug(:lockspire_deny_operator_access)` resolves it by atom at runtime.
`[VERIFIED: compiled this session]`

### Pattern 2: `Mix.Project.in_project/4` as the host-resolution lever (D-02)

**What:** Wrap the generator call so `Mix.Project.config()` returns the *host's* project during the call.

**When to use:** Any test that must prove host-derived values. It is in-process, needs no `deps`, no compile,
no network, and it restores the previous project and cwd on exit.

**Verified example:**

```elixir
# Source: empirically verified this session (Elixir 1.19.5)
Mix.Project.in_project(:host_app, snapshot_copy_path, fn _module ->
  Lockspire.Generators.Install.run([])   # note: NO --web, NO --scope
end)
```

Observed, against a real `mix phx.new host_app --database postgres` `mix.exs`:

```
app:            :host_app          (was :lockspire outside the block)
cwd:            <snapshot path>    (restored on exit)
app_module:     "HostApp"
web_module:     "HostAppWeb"
router_module:  "HostAppWeb.Router"
scope_module:   "HostApp.Lockspire"
project_root:   <snapshot path>
```

and the generator wrote host-shaped paths — `lib/host_app_web/router/lockspire.ex`,
`lib/host_app/lockspire/account_resolver.ex`, `test/host_app/lockspire_fapi_smoke_e2e_test.exs` — with
`config/lockspire.exs` containing `repo: HostApp.Repo` and
`account_resolver: HostApp.Lockspire.AccountResolver`. A second `in_project` call on the same path succeeded
with no module-redefinition error, so per-test re-entry is safe.

**Two behaviors the plan must accommodate:**
1. `in_project` prints Mix's `==> host_app` project banner to stdout. Any `capture_io` assertion must tolerate
   it (or assert with `=~` rather than equality).
2. On macOS `File.cwd!()` inside the block resolves through the `/tmp → /private/tmp` symlink. Compare paths
   with `Path.expand/1` on both sides, never by raw string equality.

### Pattern 3: Plan-then-apply conflict handling (D-16, D-17)

**What:** Two passes. Pass one classifies every one of the twelve destinations and writes nothing. Pass two
writes, only if pass one produced zero conflicts.

**When to use:** Any generator whose partial application leaves an ambiguous state — which is precisely
INSTALL-03's wording.

**Reference implementation already in this repo:** `lib/mix/tasks/lockspire.upgrade.ex:74-116` — an
`Enum.reduce/3` accumulating `{updates, drifts}`, then `if drifts != []` printing
`REFUSE #{path} (#{reason})` plus a `fix:` line per entry and a single `Mix.raise` at the end. Copy the shape,
including the `--dry-run` label swap at `:122-130`.

### Pattern 4: Compile-level template regression fences (D-25)

**What:** Drive `Generators.Install.rendered_templates/1` and compile each output with the engine that will
actually consume it. No host, no filesystem writes to the repo.

**Verified example:**

```elixir
# Source: empirically verified this session — reproduced ADOPT-D16 exactly
Phoenix.LiveView.TagEngine.compile(source,
  caller: __ENV__,
  tag_handler: Phoenix.LiveView.HTMLEngine,
  file: path,
  line: 1
)
```

Against the real generated `authorized_apps_html/index.html.heex` this raised:

```
Phoenix.LiveView.TagEngine.Tokenizer.ParseError
…index.html.heex:23:16: expected closing `}` for expression
23 |         <li id={"authorized-app-<%= consent.grant.id %>"}>
   |                ^
```

Line 23 in the *rendered* file corresponds to line 19 in the source template — `ownership_header/2`
(`install.ex:144-186`) prepends four lines. If the fence reports source-template line numbers, it must
subtract the header, or (simpler and more honest) report the rendered path and note the offset.

The analogous fence for the router already has a precedent: `install_generator_test.exs:236-240` uses
`Code.compile_string/2` on the rendered FAPI smoke test. Apply the same idea to the generated router helper,
plus a stub host router that imports it and calls the macro, then assert over `Phoenix.Router.routes/1`.

### Anti-Patterns to Avoid

- **`def` returning a String for route injection.** ADOPT-D01. A top-level expression in a module body is
  evaluated and discarded.
- **`File.cd!` as a stand-in for "run in the host."** It changes the working directory but not the Mix
  project, so `Mix.Project.config()` still answers `:lockspire`. This is the whole INSTALL-02 defect.
- **Asserting a value the test itself supplied.** Passing `--web GeneratedHostAppWeb --scope
  GeneratedHostApp.Lockspire` and then asserting the output contains `GeneratedHostAppWeb` proves the flag
  parser works, not that host resolution works. The new proof must pass **no** `--web` / `--scope`.
- **`Enum.each` + raise-on-first-conflict for multi-file generation.** Produces the half-installed state
  (empirically reproduced below).
- **`Mix.Generator.create_file/3` with its default prompt.** Documented behavior: *"If the file already exists
  and the contents are not the same, it asks for user confirmation."* `[VERIFIED: local Elixir 1.19.5 doc
  chunk via Code.fetch_docs/1]` A prompt hangs the non-interactive walk harness and CI.
- **`--force`.** Would let a re-run clobber `account_resolver.ex` and `consent_live.ex`, the host-owned seams
  AGENTS.md and REQUIREMENTS.md both fence off.
- **Committing a real `secret_key_base` literal in the config template.** D-14 / T-126-04.
- **Putting the `phx.new` snapshot under `test/`, `lib/`, or `config/`.** See § Snapshot Placement.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Making the generator resolve a foreign app's identity | An `--app` CLI override, an env var, or parsing the host's `mix.exs` with a regex | `Mix.Project.in_project/4` | It is the sanctioned API, it restores state, and it forces the *real* derivation path rather than a test-only shortcut. Verified re-enterable. |
| Multi-file conflict reporting + atomic refusal | A fresh two-pass design | `lib/mix/tasks/lockspire.upgrade.ex:74-116` verbatim | Already reviewed, already shipped, already produces `REFUSE <path> (<reason>)` + one raise + `--dry-run`. Divergent output shapes make the two tasks look like different products. |
| Starting the repo from a `["app.config"]` Mix task | `@requirements ["app.start"]` | `Ecto.Migrator.with_repo/2`, per `lib/lockspire/install/verify.ex:202-217` | `app.start` boots the host's full endpoint from a CLI task — heavier, and it changes what a `mix lockspire.client.create` run does to a live system. |
| Validating generated HEEx | A hand-rolled tag matcher, or `EEx.compile_string(engine: TagEngine)` | `Phoenix.LiveView.TagEngine.compile/2` | The former misses tokenizer rules; the latter is deprecated on LV 1.2.8 and would fail `compile --warnings-as-errors`. |
| Validating the generated router | String/regex assertions on the rendered file | Compile a stub host router that imports the helper, then read `Phoenix.Router.routes/1` | A regex would have passed happily on the heredoc version that injected zero routes. Only the route table proves injection. |
| Locating Lockspire's own migrations from a host | A source-tree-relative path | `Application.app_dir(:lockspire, "priv/repo/migrations")` | Source-tree paths do not exist inside a compiled release. Already the internal pattern at `lockspire.test.setup.ex:34` and `verify.ex:197`. |
| Recording the generator's version in the manifest | `Mix.Project.config()[:version]` | `Application.spec(:lockspire, :vsn) \|> List.to_string()` | The former reads the *pushed* project, which in real adopter use is the host. See Pitfall 1. `Application.spec(:lockspire, :vsn)` returns a charlist `~c"1.4.0"`. `[VERIFIED: executed this session]` |

**Key insight:** almost every defect in this phase's set is the same failure repeated — *a proof that never
put the code in the position the adopter puts it in*. The heredoc router "worked" because no test ever
expanded it into a router. The config template "worked" because no test ever booted with it. The manifest
version "works" because no test ever ran the generator with a foreign Mix project pushed. Do not fix these
with stronger string assertions; fix them by putting the code in the adopter's position and reading what the
real consumer (the Phoenix router, the HEEx tokenizer, the config validator) says.

## Host-Resolution Correctness (research emphasis 5)

**How the installer derives host identity today** — `lib/lockspire/generators/install.ex:27-61`:

| Assign | Derivation | Overridable? |
|--------|-----------|--------------|
| `app_module` | `Mix.Project.config() \|> Keyword.fetch!(:app) \|> to_string() \|> Macro.camelize()` (`:28-32`) | **No CLI flag** — this is the lever |
| `app_path` | `Macro.underscore(root_module)` (`:43`) | No |
| `web_module` | `Keyword.get(opts, :web, "#{root_module}Web")` (`:34`) | `--web` |
| `scope_module` | `Keyword.get(opts, :scope, "#{root_module}.Lockspire")` (`:35`) | `--scope` |
| `router_module` | `"#{web_module}.Router"` (`:51`) | Indirectly via `--web` |
| repo module | Not an assign — the config template writes `repo: <%= @app_module %>.Repo` (`config.exs:8`) | No |
| `project_root` | `Keyword.get(opts, :path, File.cwd!())` (`:41`) | `--path` |

Because `app_module` has no override, it is the single value that *must* come from the host — and it feeds
`app_path`, the default `web_module`, the default `scope_module`, and the `repo:` line. Proving it resolves
correctly proves the whole chain.

**What the current proof does instead.** `install_generator_test.exs:363-368` wraps the task in `File.cd!` and
passes `--web GeneratedHostAppWeb --scope GeneratedHostApp.Lockspire` (`:370-377`). Under `File.cd!` the Mix
project is still Lockspire, so `app_module` is `"Lockspire"` and the fixture's `config/lockspire.exs` renders
`repo: Lockspire.Repo`. **No assertion in the file reads the `repo:` line** (`:38-71` cover `config
:lockspire`, the ownership header, `import_config`, `account_resolver:`, `storage_prefix:`, `oban_prefix:` —
never `repo:`). The two module values that *are* asserted come from the flags the test supplied.

**Independent evidence the generator itself is correct.** `tmp/adopter-walk/host_app/config/lockspire.exs`,
produced by the Phase 126 walk running the real task inside a real host, contains `repo: HostApp.Repo` and
`account_resolver: HostApp.Lockspire.AccountResolver`. `[VERIFIED: read this session]` The defect is in the
proof, exactly as D-03 states.

**Minimum assertion set for INSTALL-02** — run under `in_project` with **no** `--web`/`--scope`:

| What | Assert |
|------|--------|
| App name | generated paths contain `lib/host_app/` and `test/host_app/`; `assigns.app_module == "HostApp"` |
| Web module | `lib/host_app_web/router/lockspire.ex` exists; its content declares `defmodule HostAppWeb.Router.Lockspire` |
| Router module | `assigns.router_module == "HostAppWeb.Router"`; `instructions/1` output names `lib/host_app_web/router.ex` |
| **Repo module** | `config/lockspire.exs` contains `repo: HostApp.Repo` ← the currently-unasserted line |
| Scope module | `lib/host_app/lockspire/account_resolver.ex` exists; config contains `account_resolver: HostApp.Lockspire.AccountResolver` |
| Negative control | the generated tree contains **no** `Lockspire.Repo`, no `lib/lockspire/`, no `GeneratedHostApp` — i.e. no library-name leakage |

The negative control matters as much as the positives: it is what would have caught this defect class.

## The Existing Integration Proof (research emphasis 3)

**Where it empties a directory.** `test/integration/install_generator_test.exs:379-386`:

```elixir
defp reset_fixture! do
  File.rm_rf!(Path.join(@fixture_root, ".lockspire"))
  File.rm_rf!(Path.join(@fixture_root, "config"))
  File.rm_rf!(Path.join(@fixture_root, "lib"))
  File.rm_rf!(Path.join(@fixture_root, "test"))
  File.mkdir_p!(@fixture_root)
  File.write!(Path.join(@fixture_root, ".keep"), "")
end
```

It runs in `setup` and in `on_exit` (`:9-13`). `test/support/fixtures/generated_host_app/` on disk right now
contains exactly one file: `.keep`. `[VERIFIED: ls this session]` `test/integration/install_upgrade_test.exs`
uses the same fixture and its own `reset_fixture!`.

**What the file already proves and must keep proving (D-06).**

| Lines | Fence | Keep because |
|-------|-------|--------------|
| `:36` | `length(Templates.all()) == 12` | Paired with the comment at `templates.ex:64-66`; catches accidental template add/remove |
| `:38-71` | Config content assertions | Cheap drift detection |
| `:73-95` | Router content assertions incl. the admin-scope regex at `:94-95` | **Will need updating** for the macro rewrite — the regex expects `scope "/lockspire/admin" do\s+pipe_through …` inside a heredoc |
| `:159-210` | Byte-compare of three verification files + `router/lockspire.ex` against `test/support/generated_host_app_web/` | Strongest drift fence in the file; forces the runtime fixture to stay in sync |
| `:236-240` | `Code.compile_string` on the rendered FAPI smoke test | The precedent for compile-level fences |
| `:303-321` | Idempotent re-run prints `* unchanged …` | INSTALL-03's happy path |
| `:323-361` | Conflicting re-run raises | INSTALL-03's sad path — **but only proves it raises**, never that the host is coherent afterward |

**Cost, caching, tagging, CI safety.** The Phase 126 walk (`mix adopter.walk`) already exists as the
fully-fresh `mix phx.new` proof, and D-07 keeps it there. For Phase 127 the relevant facts are:

- `install_generator_test.exs` has **no** `@moduletag`, so it runs in `test.fast` (`mix.exs:76`) and is
  *excluded* by `test.integration` (`mix.exs:77`, `test --only integration`). `[VERIFIED: read]`
- `mix test.fast` runs in **three** CI jobs: the main job (`ci.yml:106`), the Minimum Supported Elixir/OTP
  matrix job (`ci.yml:176`), and the `ci` alias (`mix.exs:118-127`). Anything untagged pays that cost 3×.
- `test/test_helper.exs` excludes `integration: true` unless a `.exs` path is named explicitly, the argv
  contains `"integration"`, or `--include integration` is passed. `[VERIFIED: read]` So a
  `@moduletag :integration` test still runs when someone names the file directly — good for local iteration.
- Under `in_project` the proof is **free of network, deps, and compilation** — measured this session as an
  in-process call returning immediately. The `:integration` tag is therefore about *shape* (it touches a host
  fixture and the filesystem) rather than runtime cost. D-05 stands, and the tag costs nothing in
  responsiveness because `test.integration` also runs in CI (`ci.yml` integration job, `mix.exs:125`).

**Is there a reusable real-host generator from Phase 126 worth extending?** Partially, and the answer is
*"reuse the output, not the code."* `scripts/maintainer/adopter_path_walk.sh:393` runs
`mix phx.new host_app --database postgres --install` with a pinned `phx_new 1.8.9` archive under an isolated
`MIX_ARCHIVES`. That is a shell harness, not an ExUnit-callable generator, and D-07 explicitly keeps it out of
automated lanes. But its *output* — `tmp/adopter-walk/host_app/` — is a real, verified `phx.new 1.8.9` tree
sitting on disk right now, and it is the natural source for the committed snapshot D-01 calls for. Capturing
the snapshot from that tree (rather than re-running `phx.new`) also makes the snapshot's provenance
documentable: "captured from the Phase 126 walk's own host, `phx_new 1.8.9`, Elixir 1.19.5 / OTP 28."

`tmp/` is gitignored (`.gitignore:10`), so the capture is a deliberate copy, not an accident.

### Snapshot Placement

D-04 says "outside `test/`" and gives two reasons (test-env compilation collisions; `mix test`'s default glob
sweeping up `*_test.exs`). **A third, independent, and stronger reason was found in this session:**

| Tool | Scope | Consequence for a snapshot under `test/` |
|------|-------|------------------------------------------|
| `mix format --check-formatted` (part of `mix qa`) | `.formatter.exs` inputs: `"mix.exs"`, `"{config,lib,test}/**/*.{ex,exs}"` | Stock `phx.new` output is formatted by *its* `.formatter.exs`, not Lockspire's. `mix qa` would fail. |
| `credo --strict` (part of `mix qa`) | `.credo.exs:7` `included: ["lib/", "test/"]` | Generated Phoenix code will not be Credo-strict-clean. `mix qa` would fail. |
| `mix test` default glob | `test/**/*_test.exs` | `phx.new`'s own tests plus the installer-generated `test/<app>/lockspire_fapi_smoke_e2e_test.exs` get collected. |
| `elixirc_paths(:test)` (`mix.exs:70`) | `["lib", "test/support"]` | Under `test/support/`, snapshot `.ex` files compile and collide with existing `GeneratedHostAppWeb.*`. |
| `mix hex.build` (`package_files/0`, `mix.exs:479-491`) | `lib/**/*.{ex,heex}`, `priv/repo/migrations/*.exs`, `priv/templates/**/*.{ex,exs,heex}`, `docs/**/*.md`, explicit list | A snapshot under `lib/` **or** `priv/templates/` **would** ship to Hex. Anywhere else in `priv/` would not. |

**Recommendation (this is Claude's-discretion territory per CONTEXT, so it is a recommendation, not a
locked decision): `priv/test_fixtures/phx_new_host/`.** It is outside every formatter/Credo/test/compile scope
above and outside every `package_files/0` wildcard. Alternative acceptable location: a top-level `fixtures/`
directory. Both `lib/` and `priv/templates/` are **disqualified** — they would ship to Hex.

**Second hard constraint: the test must not write into the committed snapshot.**
`scripts/maintainer/repo_hygiene_check.sh:401-406` raises a `BLOCK` when `git status --porcelain` is non-empty.
A test that installs into a tracked directory dirties the tree on every run. The test must copy the snapshot
into a scratch directory first — `System.tmp_dir!()`, or a path under `tmp/` (gitignored, `.gitignore:10`), or
under `Mix.Project.build_path()` — and run `in_project` against the copy, cleaning up via `on_exit`.

**Third consideration: how much of `phx.new`'s output to commit.** Only `mix.exs` is strictly required for
`in_project` to resolve the host — verified this session by running the entire generator against a directory
containing nothing but a copied `mix.exs`. Fidelity rises with more files:

| Snapshot contents | Enables | Cost |
|-------------------|---------|------|
| `mix.exs` only | All of INSTALL-02's module/repo resolution assertions; all of INSTALL-03's conflict semantics | ~1 file. Weakest claim to "a freshly generated Phoenix application." |
| `+ config/`, `+ lib/host_app/application.ex`, `+ lib/host_app_web/{router,endpoint}.ex` | Asserting the generated helper's module namespace matches the host's *actual* web module file; a realistic `import_config` target | ~8 files, still hand-reviewable |
| Full `phx.new` tree minus `assets/`, `deps/`, `_build/` | Highest fidelity | ~40 files of vendored third-party scaffolding to review and keep current |

Middle option recommended. Whatever is chosen, document the capture provenance and refresh procedure in a
`README.md` beside the snapshot — CONTEXT lists this under Claude's discretion and it is the kind of thing that
rots silently.

## Idempotency and Re-run Semantics (research emphasis 4)

### What happens today — reproduced empirically this session

Installed into a snapshot, then edited `config/lockspire.exs` (the **2nd** of 12 templates) and removed the
later outputs, then re-ran:

```
==> host_app
* unchanged lib/host_app_web/router/lockspire.ex
RAISED: Refusing to overwrite modified file: config/lockspire.exs

--- post-abort host state ---
account_resolver exists?:     false
interaction_handler exists?:  false
manifest exists?:             false
```

Three facts, all load-bearing for INSTALL-03:

1. Only the **first** conflict is reported. The adopter fixes it, re-runs, hits the second, and repeats.
2. Files ordered *after* the conflict in `Templates.all/0` are never written — the host is left with a
   partial Lockspire install.
3. The manifest is written *after* the loop (`install.ex:20`), so an aborted run leaves **no manifest at
   all** — `mix lockspire.upgrade` then raises `"Missing install manifest. Run mix lockspire.install first."`
   (`lockspire.upgrade.ex:62`), which is misleading: the install *was* run.

`install_generator_test.exs:323-361` asserts only `assert_raise Mix.Error, ~r/Refusing to overwrite modified
file/`. It never inspects the host afterward.

### What `Mix.Generator` and Igniter-style generators do

| Approach | Conflict behavior | Fit here |
|----------|-------------------|----------|
| `Mix.Generator.create_file/3` | *"If the file already exists and the contents are not the same, it asks for user confirmation."* Options: `:force` (skip prompt), `:quiet`, `:format_elixir`. `[VERIFIED: local Elixir 1.19.5 doc chunk]` | **Rejected (D-20).** Prompting hangs the walk harness and CI. `--force` would clobber host-owned seams. |
| `Mix.Generator.copy_file/3` | Same prompt-or-`:force` semantics. | Same rejection. |
| `phx.new`-style generators | Prompt per conflicting file, or `--force` globally. | Same rejection; also they generate a *new* app, not into an existing one. |
| Igniter-style codemods | Read the host AST, compute a patch, show a diff, apply. | **Out of scope** — that is injection into host files, which REQUIREMENTS.md's Out-of-Scope table and CONTEXT's `<deferred>` both fence off. |
| `mix lockspire.upgrade` (in-repo) | Collect every drift, print `REFUSE <path> (<reason>)` + a `fix:` line per entry, `Mix.raise` once, never write. `--dry-run` labels intended writes `DRY-RUN` instead of `UPDATE`. (`lockspire.upgrade.ex:106-130`) | **Adopt verbatim (D-17).** |

### Concrete definition of "observably and predictably" for success criterion 3

The criterion needs a testable meaning, not a vibe. Proposed contract — every clause is assertable:

| Scenario | Observable behavior | Assertion |
|----------|---------------------|-----------|
| Clean host, no prior output | `* created <path>` for each of 12 + the manifest; exit 0 | file set + stdout, as today |
| Prior output, byte-identical | `* unchanged <path>` for each of 12 + `* unchanged .lockspire/install_manifest.json`; exit 0; zero writes | `install_generator_test.exs:303-321` already covers this |
| One or more files drifted | `REFUSE <path> (host edit detected)` for **every** drifted path (not just the first), one `Mix.raise`, and **zero bytes written** — the host is byte-identical before and after | New: snapshot a checksum map of the whole tree before and after and assert equality |
| Manifest inputs differ from flags (D-18) | `REFUSE .lockspire/install_manifest.json (inputs changed: web_module GeneratedHostAppWeb → OtherWeb)`; one raise; zero writes | New |
| Manifest content drifted (D-19) | Same refuse shape as any other managed file — **not** the current silent `* updated` (`manifest.ex:35-38`) | New |
| `--dry-run` on a clean host | Prints the full `:create` plan, writes nothing, exits 0 | New; mirrors `lockspire.upgrade`'s `DRY-RUN` label |
| `--dry-run` on a conflicted host | Prints the full `REFUSE` list, writes nothing; exit code should be **decided explicitly** — see Open Question 2 | New |

The "zero bytes written" clause is the one that actually discharges INSTALL-03. Everything else is reporting
quality; that clause is the anti-half-install guarantee. Implement it by making the plan pass side-effect-free
(it already can be: `rendered_templates/1` reads templates, `File.read/1` reads destinations, nothing writes).

**Classification note.** `ensure_file!` currently collapses "file missing" into `:create`. For the plan pass
the four `File.read/1` outcomes map cleanly:

| `File.read(destination)` | Classification |
|--------------------------|----------------|
| `{:ok, ^rendered}` | `:unchanged` |
| `{:ok, _other}` | `:conflict` (reason: host edit or version drift) |
| `{:error, :enoent}` | `:create` |
| `{:error, reason}` | `:conflict` (reason: `inspect(reason)`) — currently `Mix.raise`s immediately at `install.ex:125-126` |

One subtlety worth a plan decision: a managed file that drifted because *Lockspire's template changed* is
indistinguishable, by content alone, from one the host edited — unless the manifest checksum is consulted.
`Manifest.build/2` stores per-file checksums (`manifest.ex:62-68`), and `lockspire.upgrade.ex:87-96` already
uses exactly that three-way comparison (`current != expected` → drift; `current == next` → no-op; else →
update). Reusing it in `install` would let the refusal message distinguish *"you edited this"* from *"Lockspire
changed this; run `mix lockspire.upgrade`"* — a materially better adopter experience for the same code.

## Runtime State Inventory

Not applicable in the classic sense — this is not a rename or data migration. But the phase *does* mutate
committed non-source state, and each item must be reconciled in the same commit as its code change:

| Category | Items found | Action required |
|----------|-------------|-----------------|
| Stored data / databases | None. The installer touches no database; `client.create`'s `with_repo` change alters *when* the repo starts, not stored data. | None — verified by reading `Clients.register_client/1`'s call site |
| Live service config | None. No external service holds installer state. | None |
| OS-registered state | None. | None |
| Secrets / env vars | `secret_key_base` becomes an emitted **placeholder** (D-14). No real secret enters the repo. The Phase 126 walk's `tmp/adopter-walk/host_app/config/lockspire.exs` does contain a generated secret — it is gitignored (`.gitignore:10`) and must stay so. | Verify no literal lands in `priv/templates/` |
| Build artifacts / lockfiles | **`mix.lock`** — loosening `mix.exs:47` does *not* by itself change the lock. `ecto_sql` stays at 3.13.5 until `mix deps.update ecto ecto_sql` is run. D-23's "one CI run that actually resolves 3.14" therefore requires **committing an updated `mix.lock`**. | Explicit plan task |
| Committed test fixtures | `test/support/generated_host_app_web/router/lockspire.ex` — byte-compared at `install_generator_test.exs:209-210`. The D-08 rewrite makes it stale. | Regenerate in the same commit |
| Committed docs/planning | `126-DEFECT-LEDGER.md` — twelve dispositions (criterion 4). `AGENTS.md:26` — the `Ecto SQL 3.13.5` line. | Explicit plan tasks |
| Maintainer scripts | `scripts/maintainer/adopter_path_walk.sh` — six markers removed **and** `extract_lockspire_routes_body` (`:272-282`) repaired. | Explicit plan task |

**Correction to CONTEXT.md integration point 4.** CONTEXT states the runtime fixture
`test/support/generated_host_app_web/router/lockspire.ex` is "consumed by `phase6_onboarding_e2e_test.exs`,
`phase31_*`, `phase81_*`, and `phase100_*`." It is not. `grep -rln 'GeneratedHostAppWeb.Router' test/` returns
only four files: `test/support/generated_host_app_web/{router.ex,endpoint.ex,router/lockspire.ex}` and
`controllers/lockspire_verification_html.ex`. `GeneratedHostAppWeb.Router` (`test/support/.../router.ex`)
**never imports or calls** `GeneratedHostAppWeb.Router.Lockspire` — it hand-wires its own routes and forwards
`/lockspire` directly. The fixture `router/lockspire.ex` is compiled but otherwise **inert**; it exists solely
to satisfy the byte-compare at `:209-210`. `[VERIFIED: grep + read this session]`

This is good news: the D-08 rewrite's blast radius on the e2e suite is **zero**. It still must be regenerated
for the byte-compare, but it will not break `phase6_onboarding_e2e_test.exs` or any other consumer.
One caution: the regenerated file will define a `defmacro` that nothing expands. That compiles cleanly (an
unexpanded `quote` body is never type-checked), but `mix compile --warnings-as-errors` under `mix qa` should
be re-run to confirm nothing warns.

## Common Pitfalls

### Pitfall 1: The manifest's `"version"` records the **host's** version, and switching to `in_project` will expose it

**What goes wrong:** `Manifest.build/2` (`manifest.ex:54`) does
`"version" => to_string(Mix.Project.config()[:version])`. Under `File.cd!` in the current test, the pushed Mix
project is Lockspire, so it records `"1.4.0"` and `install_generator_test.exs:46` — which asserts
`manifest["version"] == to_string(Mix.Project.config()[:version])` — passes. Under `in_project` (and in every
real adopter install) the pushed project is the **host**, so it records the host's version.

**Verified:** the real Phase 126 walk host's manifest at
`tmp/adopter-walk/host_app/.lockspire/install_manifest.json:24` reads `"version": "0.1.0"` — the host's
version (`tmp/adopter-walk/host_app/mix.exs:7`) — while Lockspire is `1.4.0` (`mix.exs:12`). Reproduced again
this session by running the generator under `in_project`. `[VERIFIED: executed + read]`

**Why it happens:** the same root cause as INSTALL-02 itself — `Mix.Project.config()` answers about whichever
project is pushed, and the test never pushed a foreign one.

**How to avoid:** decide deliberately. The field is only meaningful to `mix lockspire.upgrade` as "which
Lockspire generated this," so `Application.spec(:lockspire, :vsn) |> List.to_string()` is almost certainly the
intended value (verified to return `~c"1.4.0"` — note the charlist). Whatever is chosen,
`install_generator_test.exs:46` must be rewritten to assert a **literal expectation**, not
`Mix.Project.config()[:version]`, or it will keep passing for the wrong reason.

**Warning sign:** the assertion at `:46` compares the artifact to a value computed the same wrong way. Any
assertion of the form `assert artifact_field == <same expression the code used>` is a tautology, not a test.

**This is not in the ledger and not in CONTEXT.md.** It is a genuine INSTALL-02-class defect the phase should
close, and it is unavoidable: switching to `in_project` forces the decision.

### Pitfall 2: The router-template rewrite breaks the walk harness's body extractor

**What goes wrong:** `scripts/maintainer/adopter_path_walk.sh:272-282`:

```bash
extract_lockspire_routes_body() {
  awk '
    /^    """$/ { marker_count++; next }
    marker_count == 1 { print }
  ' "$1"
}
```

It locates the heredoc by matching lines that are exactly four spaces plus `"""`. Replacing the heredoc with
`quote do … end` makes that match zero lines, so `step-03b-router-paste` (`:742-743`) would paste an empty
string and then record a FAIL for the wrong reason.

**Why it happens:** the ledger records the *defect* but nothing records that the harness's parsing is coupled
to the defective shape.

**How to avoid:** the plan must include a task to update the extractor alongside the template — matching
`quote do` / the matching `end`, or better, extracting the macro body by expanding it rather than by text.
`adopter_walk_contract_test.exs:254-260` hard-asserts that `step-03b-router-call`, `step-03b-router-paste`,
and `step-03b-router-wire` all still appear in the script, so the step cannot simply be deleted.

**Warning sign:** a walk run where `step-03b-router-paste` fails with a compile error that mentions nothing
about pipelines.

### Pitfall 3: The ledger reconciliation test parses only the **first line** of the `Workaround:` field

**What goes wrong:** `defect_ledger_contract_test.exs:69` uses
`~r/-\s*\*\*Workaround:\*\*\s*(.+)/`. Elixir's `.` does not match newlines without the `s` modifier, so only
the field's first line is captured, and only `ADOPT-Dnn` tokens on that first line enter the reconciliation
set (`:103-112`). The test then asserts **set equality in both directions** against the markers found in
`scripts/maintainer/` (`:187-211`).

**Consequences the plan must respect:**

1. Removing a marker without editing its ledger entry fails `"no ledger entry claims a workaround ID that no
   marker … backs"`.
2. Editing a ledger entry to `**Workaround:** removed in Phase 127 — ADOPT-D15's marker deleted` **re-creates
   the phantom claim**, because `ADOPT-D15` is on the first line. The closing text must keep every
   `ADOPT-Dnn` token off the first line of the `Workaround:` field, or omit it entirely (e.g.
   `**Workaround:** none — the harness workaround was removed in Phase 127; see the disposition note below.`).
3. Conversely, *adding* an `ADOPT-Dnn` reference to any other entry's first `Workaround:` line invents a
   phantom claim. ADOPT-D01 currently mentions `ADOPT-D02/ADOPT-D03` safely only because those tokens sit on a
   continuation line (ledger `:56-59`). Reflowing that paragraph would break the suite.

**How to avoid:** treat the ledger edits as code. Run
`mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` after every ledger edit, not once at the
end.

### Pitfall 4: The config template's placeholder issuer is not merely vague — it *raises*

**What goes wrong:** `priv/templates/lockspire.install/config.exs:10-11` emits
`issuer: "https://example.com"` alongside `mount_path: "/lockspire"`.
`lib/lockspire/security/policy.ex:104-106` raises
`ArgumentError: invalid :issuer for :lockspire. Issuer path nil must match mount_path "/lockspire".`
`[VERIFIED: read — note the file is `lib/lockspire/security/policy.ex`, not `lib/lockspire/policy.ex` as
CONTEXT D-13 cites]`

Separately, `Lockspire.Config.known_scopes/0` (`config.ex:110-114`) defaults to `[]`, and
`authorization_request.ex`'s `unknown_scope?/1` returns `true` for every scope except `"openid"` when the list
is empty. `[VERIFIED: read]` So a stock install rejects `email` and `profile`.

**How to avoid:** D-13's fix. When writing the template, make the placeholder issuer *obviously* a placeholder
**and** structurally valid — e.g. `issuer: "https://example.com/lockspire"` with a `# CHANGE ME` comment — so
an adopter who forgets to edit it gets a clear boot failure about the host name rather than a confusing path
mismatch.

### Pitfall 5: `mix qa` format/Credo scope disqualifies `test/` for the snapshot

Covered in § Snapshot Placement. The short version: `.formatter.exs` inputs include `{config,lib,test}/**` and
`.credo.exs:7` includes `["lib/", "test/"]`. Stock `phx.new` output will fail both.

### Pitfall 6: `package_files/0` would ship a snapshot placed under `lib/` or `priv/templates/`

`mix.exs:479-491` wildcards `lib/**/*.ex`, `lib/**/*.heex`, and `priv/templates/**/*.{ex,exs,heex}`. CONTEXT
D-04 says "`package_files/0` is an explicit wildlist, so nothing new ships to Hex regardless" — that is true
only for locations *outside* those two wildcards. Verify with `mix hex.build` after placing the snapshot.

### Pitfall 7: The test must not dirty the git working tree

`scripts/maintainer/repo_hygiene_check.sh:401-406` emits `BLOCK` when `git status --porcelain` is non-empty.
Copy the snapshot to a scratch path before installing into it.

### Pitfall 8: ADOPT-D04's marker cannot be fully removed by this phase

Even after D-13/D-14 land, the walk harness still needs to substitute a **real** issuer
(`${WALK_BASE_URL}${MOUNT_PATH}`), a **freshly generated** `secret_key_base`, and — critically — its own
invented `read:walk` scope into `known_scopes`. `adopter_path_walk.sh:665-668` does all three in one `sed`
block guarded by `if ! grep -Fq 'known_scopes' "$lockspire_config"`. Once the template emits `known_scopes`,
that guard becomes false and the whole block is skipped, including the issuer substitution the walk needs.

**The plan must handle this explicitly**, or the next walk run will boot with `issuer:
"https://example.com/…"` and fail somewhere far downstream. Options: change the guard condition, split the
substitutions, or narrow the marker's scope and update the ledger entry to say the config-shape half is fixed
while the walk-specific value substitution remains (which is not a defect at all — no adopter needs
`read:walk`).

### Pitfall 9: At least one `LOCKSPIRE_WALK_WORKAROUND` marker must remain in `adopter_path_walk.sh`

`adopter_walk_contract_test.exs:237-252` asserts `marker_lines != []` with the message
`"expected at least one workaround marker"`, scoped to `@walk_script_path` (the shell script). With D05, D06,
D07, D19 and the partial D04 marker staying, this holds — but it is a tripwire worth knowing before someone
optimizes marker removal.

### Pitfall 10: `mix ecto.migrate` appears in **three** in-scope places, not two

CONTEXT D-28 names `verify.ex:241` and `install.ex:140`. `grep` also finds
**`lib/lockspire/install/verify.ex:270`** — `"Keep running \`mix ecto.migrate\` before booting new Lockspire
features."` — inside the storage-prefix/table-missing remediation. All three carry the same wrong advice.
(`docs/install-and-onboard.md:108` is the fourth and belongs to Phase 128.) `[VERIFIED: grep this session]`

### Pitfall 11: Removing a marker is an unverified change until a walk runs

D-07 keeps `mix phx.new` out of automated lanes, so nothing in `mix ci` re-runs the walk. Deleting six markers
changes the harness in ways only a real `mix adopter.walk` can validate. Two honest options: run
`mix adopter.walk` manually as part of this phase's verification (Postgres is available locally — `pg_isready`
returned `accepting connections`, and `phx_new-1.8.9` is installed), or defer marker removal to Phase 130 and
close the ledger entries by disposition text alone. **This is a real fork the plan must take deliberately** —
see Open Question 1.

### Pitfall 12: The macro's `unquote(opts)` and the "paste the body" reading are in tension

ADOPT-D02's walk step pastes `lockspire_routes/0`'s *rendered body* into the host router. If the macro body
contains `unquote(operator_pipeline)`, a literal paste raises `unquote called outside quote`. The two
documented readings of guide §3 (call it; paste it) can only both work if the emitted `quote` body is
paste-safe.

Three ways out, all viable, none obviously best:
1. **No macro opts.** Emit literal atoms in the `quote`; the body is paste-safe verbatim. Costs the
   configurability CONTEXT lists under Claude's discretion.
2. **Opts, but resolve them at EEx render time**, not at macro-expansion time — the *template* interpolates
   the pipeline names as literals into the generated file, and the macro takes no runtime opts. The adopter
   reconfigures by editing the generated file, which is exactly the ownership model already in place.
3. **Opts with `unquote`, plus a paste-safe rendering** emitted separately (e.g. in the moduledoc).
   Most code, most drift surface.

Option 2 is the best fit for this codebase's stated model ("the adopter still reads and edits the exact
routes", D-08) and keeps the harness's paste step meaningful. Flagging rather than deciding — CONTEXT assigns
macro option naming to Claude's discretion, but it does not appear to have considered this interaction.

## Code Examples

### Host-resolution proof under `in_project` (INSTALL-01 + INSTALL-02)

```elixir
# Source: pattern verified end-to-end this session
@moduletag :integration

@snapshot Path.expand("../../priv/test_fixtures/phx_new_host", __DIR__)

setup do
  scratch = Path.join(System.tmp_dir!(), "lockspire-host-#{System.unique_integer([:positive])}")
  File.mkdir_p!(scratch)
  File.cp_r!(@snapshot, scratch)
  on_exit(fn -> File.rm_rf!(scratch) end)
  {:ok, host: scratch}
end

test "installs into a real generated Phoenix host with no module flags", %{host: host} do
  capture_io(fn ->
    Mix.Project.in_project(:host_app, host, fn _ ->
      # NOTE: no --web, no --scope. Host resolution is the thing under test.
      Lockspire.Generators.Install.run([])
    end)
  end)

  config = File.read!(Path.join(host, "config/lockspire.exs"))

  assert config =~ "repo: HostApp.Repo"                                     # ← unasserted today
  assert config =~ "account_resolver: HostApp.Lockspire.AccountResolver"
  assert File.exists?(Path.join(host, "lib/host_app_web/router/lockspire.ex"))
  assert File.exists?(Path.join(host, "lib/host_app/lockspire/account_resolver.ex"))

  helper = File.read!(Path.join(host, "lib/host_app_web/router/lockspire.ex"))
  assert helper =~ "defmodule HostAppWeb.Router.Lockspire"

  # Negative control: no library-name leakage into host-shaped output.
  refute config =~ "Lockspire.Repo"
  refute File.exists?(Path.join(host, "lib/lockspire"))
end
```

### Router macro expansion proof (ADOPT-D01)

```elixir
# Source: verified this session — the full probe produced an 8-route table
test "the generated router helper injects real routes into a host router" do
  helper_source = rendered_router_helper()   # from Install.rendered_templates/1

  Code.compile_string(helper_source, "lockspire_router_helper.ex")

  Code.compile_string("""
  defmodule RouterProbeWeb.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    import HostAppWeb.Router.Lockspire

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:protect_from_forgery)
    end

    lockspire_routes()
  end
  """, "router_probe.ex")

  routes = Phoenix.Router.routes(RouterProbeWeb.Router)

  admin_index  = Enum.find_index(routes, &(&1.plug == Lockspire.Web.AdminRouter))
  public_index = Enum.find_index(routes, &(&1.plug == Lockspire.Web.Router))

  assert is_integer(admin_index),  "no /lockspire/admin mount — the macro injected nothing"
  assert is_integer(public_index), "no /lockspire forward"
  assert admin_index < public_index, "public forward shadows the guarded admin mount"
end
```

### HEEx compile fence over every generated template (ADOPT-D16)

```elixir
# Source: verified this session — reproduced the real ParseError
test "every generated .heex template compiles under the LiveView tag engine" do
  assigns = Lockspire.Generators.Install.build_assigns(path: "/nonexistent")

  for rendered <- Lockspire.Generators.Install.rendered_templates(assigns),
      Path.extname(rendered.destination) == ".heex" do
    Phoenix.LiveView.TagEngine.compile(rendered.rendered,
      caller: __ENV__,
      tag_handler: Phoenix.LiveView.HTMLEngine,
      file: rendered.relative_path,
      line: 1
    )
  end
end
```

### Repo access from a `["app.config"]` Mix task (ADOPT-D08)

```elixir
# Source: lib/lockspire/install/verify.ex:202-217 — existing in-repo pattern
{:ok, result, _apps} =
  Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _started_repo ->
    Lockspire.Clients.register_client(attrs)
  end)
```

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| `EEx.compile_string(source, engine: Phoenix.LiveView.TagEngine)` | `Phoenix.LiveView.TagEngine.compile/2` | LV 1.2.x | The `EEx` route emits a deprecation that `compile --warnings-as-errors` (`mix qa`) turns into a failure. |
| `phx.gen.auth` login path `/log_in` | `/users/log-in` in Phoenix 1.8's `phx.gen.auth --live` | Phoenix 1.8 | ADOPT-D09; D-22's chosen default. |
| `conn.assigns.current_user` | `conn.assigns.current_scope.user` (scopes) | Phoenix 1.8 | The generated `account_resolver.ex` already handles both shapes (`:90+`); `mount_current_scope` is the LiveView-side hook (ADOPT-D18, Phase 128). |
| `ecto_sql 3.13.x` / `ecto 3.13.x` | `ecto_sql 3.14.0` / `ecto 3.14.0` | 2026-05-19 | ADOPT-D15's root cause: fresh `phx.new` hosts lock 3.14.0. `[VERIFIED: hex.pm API]` |

**Deprecated/outdated in this phase's surface:**
- `def lockspire_routes` returning a heredoc `String` — never worked; not a deprecation so much as a defect.
- `Mix.Project.config()[:version]` as a stand-in for the *library's* version inside a generator (Pitfall 1).

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Everything | ✓ | 1.19.5 (OTP 28) | — |
| PostgreSQL | `test.integration`, any `with_repo` proof for D-21 | ✓ | accepting connections on :5432 | CI provides `postgres:16` as a service |
| `phx_new` archive | Refreshing the snapshot; `mix adopter.walk` | ✓ | 1.8.9 (pinned, matches the Phase 126 walk) | — |
| `git` | Hygiene checks | ✓ | 2.41.0 | — |
| `python3` | `adopter_path_flow.py` (only if the walk is re-run) | ✓ | 3.14.4 | — |
| Network / hex.pm | `mix deps.update ecto ecto_sql` for D-23 | ✓ | — | None — the lock update requires a fetch |
| `mix adopter.walk` (full path) | Validating marker removals (Pitfall 11) | ✓ locally (Postgres + phx_new both present) | — | Defer marker removal to Phase 130 |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) |
| Config file | `test/test_helper.exs` — excludes `integration: true` unless a `.exs` path is named, argv contains `"integration"`, or `--include integration` is passed |
| Quick run command | `mix test test/integration/install_generator_test.exs` (names a `.exs` path, so `:integration`-tagged modules in it still run) |
| Full suite command | `mix test.fast` then `mix test.integration` (`mix.exs:76-77`) |
| Lanes | `test.fast` = everything untagged; `test.integration` = `test --only integration` |

### Phase requirements → test map

| Req / Defect | Behavior | Test type | Automated command | File exists? |
|--------------|----------|-----------|-------------------|--------------|
| INSTALL-01 | Installer runs into a real generated Phoenix host | integration | `mix test test/integration/install_host_interaction_test.exs` | ❌ Wave 0 |
| INSTALL-02 | app / web / router / **repo** all resolve from the host with no flags | integration | same file | ❌ Wave 0 |
| INSTALL-02 | Negative control: no `Lockspire.Repo` / `lib/lockspire/` leakage | integration | same file | ❌ Wave 0 |
| INSTALL-02 | Manifest `"version"` records the intended value (Pitfall 1) | unit | `mix test test/integration/install_generator_test.exs` (rewrite `:46`) | ✅ exists, assertion wrong |
| INSTALL-03 | Conflicting re-run reports **all** conflicts | unit | `mix test test/integration/install_generator_test.exs` (extend `:323-361`) | ✅ partial |
| INSTALL-03 | Conflicting re-run writes **zero bytes** (tree checksum before == after) | unit | same file | ❌ Wave 0 |
| INSTALL-03 | `--dry-run` on clean host prints plan, writes nothing | unit | same file | ❌ Wave 0 |
| INSTALL-03 | Manifest-inputs drift refused (D-18) | unit | same file | ❌ Wave 0 |
| INSTALL-03 | Manifest content drift refused, not silently overwritten (D-19) | unit | same file | ❌ Wave 0 |
| INSTALL-03 | Idempotent clean re-run still prints `* unchanged` ×12 | unit | `install_generator_test.exs:303-321` | ✅ exists |
| ADOPT-D01/D02/D03 | Macro injects a real route table; admin before public; `:require_operator` needs no host definition | unit | `mix test test/integration/install_template_compile_test.exs` | ❌ Wave 0 |
| ADOPT-D16 | Every generated `.heex` compiles under `TagEngine` | unit | same file | ❌ Wave 0 |
| ADOPT-D04 | Config template emits mount-path-consistent issuer, `known_scopes`, `signing_alg`, `secret_key_base` placeholder; **no secret literal** | unit | `install_generator_test.exs` (extend `:38-71`) | ✅ file exists |
| ADOPT-D08 | `mix lockspire.client.create` reaches a running repo | integration | needs Postgres; `mix test --only integration` | ❌ Wave 0 |
| ADOPT-D09 | Resolver template emits `/users/log-in` | unit | `install_generator_test.exs` (extend `:97-113`) | ✅ file exists |
| ADOPT-D15 | Suite green with `ecto_sql`/`ecto` 3.14 resolved | integration | `mix deps.update ecto ecto_sql && mix ci` | ✅ lane exists |
| ADOPT-D07 | Remediation strings name `--migrations-path` at all three sites | unit | grep-shaped assertion or `verify.ex` unit test | ❌ Wave 0 |
| Criterion 4 | Ledger reconciles with harness markers after every edit | unit | `mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` | ✅ exists |
| Drift fence | Runtime fixture matches the regenerated template | unit | `install_generator_test.exs:209-210` | ✅ exists |

### Sampling rate

- **Per task commit:** `mix test test/integration/install_generator_test.exs test/integration/install_template_compile_test.exs` plus, for any ledger or harness edit, `mix test test/lockspire/maintainer/`.
- **Per wave merge:** `mix test.fast` + `mix test.integration`.
- **Phase gate:** `mix ci` green (which includes `qa`, `docs.verify`, `deps.audit`, `package.build`, `test.fast`, `test.integration`, `test.phase3`) before `/gsd-verify-work`.

### Wave 0 gaps

- [ ] `priv/test_fixtures/phx_new_host/` (or chosen location) — the committed `phx.new` snapshot + provenance README — covers INSTALL-01
- [ ] `test/integration/install_host_interaction_test.exs` — `@moduletag :integration`, `in_project` — covers INSTALL-01, INSTALL-02
- [ ] `test/integration/install_template_compile_test.exs` — router macro expansion + HEEx `TagEngine` fences — covers ADOPT-D01/D02/D03/D16
- [ ] Shared helper for snapshot→scratch copy + cleanup (a `test/support/` module is fine — it is *code*, not the snapshot)
- [ ] Tree-checksum helper for the "zero bytes written" assertion
- [ ] No framework install needed — ExUnit and Postgres are both present

## Security Domain

`security_enforcement` is not set in `.planning/config.json`, so it is treated as enabled.

### Applicable ASVS categories

| ASVS category | Applies | Standard control in this phase |
|---------------|---------|-------------------------------|
| V1 Architecture | yes | The out-of-scope fence *is* an architectural control: the installer generates into the host and never patches host files, preserving the host's ownership of its own router/config/application. |
| V2 Authentication | no (host-owned) | Operator and end-user auth stay in the host. D-09's deny-closed pipeline is a *fail-safe default*, not an auth mechanism. |
| V3 Session Management | indirect | D-10's `pipe_through [:browser]` restores `fetch_session` + `protect_from_forgery` for the consent LiveView and interaction routes — without it those surfaces run **without CSRF protection**. This is the security-relevant half of ADOPT-D03. |
| V4 Access Control | **yes** | ADOPT-D02's fix must be **deny-closed**. A permissive stand-in `pipeline :require_operator do end` — which is what the walk harness currently injects — would leave `Lockspire.Web.AdminRouter` reachable by anyone. The generated pipeline must halt with 403 by default, and `verify.ex:120-134`'s admin-mount-before-public-forward ordering must survive the rewrite. |
| V5 Input Validation | yes | `OptionParser.parse(strict: …)` already rejects unknown switches (`lockspire.install.ex:16-32`). The new `--dry-run` switch joins the strict list. Manifest JSON is decoded with `Jason.decode/1` into a plain map; D-18's input comparison must tolerate a malformed/absent `"inputs"` map rather than crashing. |
| V6 Cryptography | **yes** | D-14: `secret_key_base` is emitted as a placeholder, **never** a literal. A committed secret in `priv/templates/` would ship to every adopter via Hex (`package_files/0` includes `priv/templates/**`). Add an explicit assertion that the rendered config contains no high-entropy 64-char literal. |
| V7 Error Handling & Logging | yes | The `REFUSE <path> (<reason>)` output must not echo file *contents* — only paths and reasons. AGENTS.md: "Strong redaction in logs and operator surfaces." |
| V12 File Operations | yes | Destinations are derived from `Path.join |> Path.expand` on assigns (`install.ex:78-82`). `--web` / `--scope` / `--path` are attacker-influenced only in the sense that the operator supplies them; still, the plan should confirm generated paths stay under `project_root` (a `String.starts_with?` guard in the plan pass is cheap insurance). |

### Known threat patterns for this stack

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Permissive stand-in operator pipeline leaves admin LiveViews open | Elevation of Privilege | Deny-closed `defp` halt plug returning 403 (D-09) |
| Consent LiveView served without `protect_from_forgery` | Tampering (CSRF) | Explicit `pipe_through [:browser]` scope before the forward (D-10) |
| Public forward shadowing the guarded admin mount | Elevation of Privilege | Route ordering, enforced by `verify.ex:128-134` and the new route-table test |
| Committed secret in a shipped template | Information Disclosure | Placeholder-only emission (D-14) + a negative assertion in the test |
| Half-applied install leaving an ambiguous security posture (e.g. router present, resolver absent) | Repudiation / Tampering | Plan-then-apply atomic refusal (D-16) |
| `--force` clobbering a host-owned `account_resolver.ex` that encodes tenant policy | Tampering | No `--force` (D-20) |
| Path traversal via `--path` / `--web` / `--scope` | Tampering | `Path.expand` + a containment check in the plan pass |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | The full test suite passes with `ecto 3.14.0` / `ecto_sql 3.14.0` resolved. Changelog analysis says no breaking changes, but no suite run has confirmed it. | Package Legitimacy Audit | D-23 lands and CI goes red; the one entry to watch is *"[Ecto.Repo] Raise an error on query-like keyword opts to Repo functions."* Mitigation: `mix deps.update ecto ecto_sql && mix ci` as an explicit task. |
| A2 | Removing the six markers (D02, D03, D08, D09, D15, D16) leaves `mix adopter.walk` working. No walk was run in this session. | Defect Set table, Pitfall 11 | The next walk breaks in an unattributed way. Mitigation: Open Question 1. |
| A3 | `priv/test_fixtures/` is an acceptable snapshot home. Verified against formatter inputs, `.credo.exs`, `elixirc_paths`, `mix test` glob, and `package_files/0` — but not against `mix hex.build` empirically. | Snapshot Placement | Snapshot ships to Hex or trips `mix qa`. Mitigation: run `mix hex.build` and `mix qa` once after placement. |
| A4 | The intended value of the manifest's `"version"` field is Lockspire's version, not the host's. Inferred from its only consumer (`lockspire.upgrade`) and from the fact that the current test asserts it equals Lockspire's version. Not stated anywhere. | Pitfall 1 | The "fix" changes behavior an unseen consumer relies on. Mitigation: `grep` for all readers of `manifest["version"]` before changing it (none found in `lib/` this session). |
| A5 | `mix compile --warnings-as-errors` stays clean when `test/support/generated_host_app_web/router/lockspire.ex` becomes an unexpanded `defmacro`. Reasoned from Elixir semantics, not executed. | Runtime State Inventory | `mix qa` goes red. Mitigation: run `mix qa` after regenerating the fixture. |
| A6 | Only `mix.exs` is strictly required in the snapshot for `in_project` to work — verified — and therefore a *trimmed* snapshot still satisfies INSTALL-01's "freshly generated Phoenix application." The *sufficiency* judgment is a reading of the requirement, not a fact. | Snapshot Placement | A reviewer judges a `mix.exs`-only snapshot as not meeting "freshly generated." Mitigation: the middle option (mix.exs + config + application.ex + router.ex + endpoint.ex). |
| A7 | Option 2 in Pitfall 12 (render pipeline names as literals at EEx time, no macro `unquote`) is the best resolution of the macro-opts / paste-ability tension. Reasoned recommendation. | Pitfall 12 | Rework if the plan prefers runtime macro opts. Low cost either way. |

## Open Questions

1. **Do the six removable markers get removed in Phase 127, or deferred to Phase 130?**
   - *What we know:* `defect_ledger_contract_test.exs` enforces two-way set equality, so removal and ledger
     reconciliation must be atomic. Six markers (D02, D03, D08, D09, D15, D16) become obsolete once this
     phase's fixes land. `adopter_walk_contract_test.exs:237-252` requires at least one marker to remain, which
     it will. Local Postgres and `phx_new 1.8.9` are both available, so `mix adopter.walk` *can* be run.
   - *What's unclear:* D-07 says Phase 127 does not add `phx.new` to any automated lane, but it does not say
     whether a *manual* walk run is part of this phase's verification. Without one, six marker removals ship
     unverified — and Pitfall 8 shows the D04 workaround's guard condition will silently change behavior.
   - *Recommendation:* remove the markers **and** run `mix adopter.walk` once, manually, as a
     `checkpoint:human-verify`-style task at the end of the phase, recording the resulting PASS/FAIL delta in
     the ledger. It is the only thing that discharges A2, it costs one local run, and it directly serves
     criterion 4's "explicitly deferred with a stated reason" by producing evidence for each disposition. If
     the plan declines, then defer all six removals to Phase 130 and close the ledger entries with
     "fixed in 127; harness workaround retained pending a walk run" — but do **not** remove markers without
     running the walk.

2. **What is `--dry-run`'s exit code when the plan contains conflicts?**
   - *What we know:* `lockspire.upgrade` raises on drift *before* it ever reaches its `--dry-run` branch
     (`upgrade.ex:106-116` precedes `:118-130`), so a drifted `--dry-run` upgrade exits non-zero. Copying the
     pattern verbatim gives `lockspire.install --dry-run` the same behavior.
   - *What's unclear:* an adopter running `--dry-run` to *inspect* a conflicted host arguably wants a report
     and exit 0, not a raise. The two readings are both defensible and the difference is script-visible.
   - *Recommendation:* mirror `lockspire.upgrade` exactly (raise → non-zero) for consistency, and say so in
     `help/0`. Consistency between the two tasks is worth more than the ergonomic nicety, and D-17 says copy
     the pattern rather than invent one.

3. **Does the manifest's `"version"` field change, or does the test's assertion change?**
   - *What we know:* the field currently records the host's version in real use (verified). Its only consumer
     is `mix lockspire.upgrade`, which never reads it. `install_generator_test.exs:46` asserts it tautologically.
   - *What's unclear:* whether any adopter tooling outside this repo reads it. `.lockspire/install_manifest.json`
     is not documented in `docs/supported-surface.md`.
   - *Recommendation:* change the field to `Application.spec(:lockspire, :vsn) |> List.to_string()` and rewrite
     the assertion to a literal comparison against that. Changing the field is a behavior change to a
     generated artifact, so note it in the ledger disposition even though it is not a numbered defect —
     it is INSTALL-02's own defect class, found by INSTALL-02's own method.

4. **Does `AGENTS.md:26` ("Ecto SQL `3.13.5`") get updated with D-23?**
   - *What we know:* AGENTS.md declares the technology stack with exact versions. Loosening `mix.exs:47`
     makes that line describe a floor rather than a pin.
   - *Recommendation:* update it to `Ecto SQL >= 3.13.5, < 4.0.0` in the same commit. Cheap, and AGENTS.md is
     read by every agent that touches this repo.

5. **How is the snapshot refreshed, and who notices when it goes stale?**
   - *What we know:* CONTEXT assigns this to Claude's discretion. The Phase 126 walk pins `phx_new 1.8.9`.
   - *Recommendation:* a `README.md` beside the snapshot recording the exact `mix phx.new` command, the
     `phx_new`/Elixir/OTP versions, the capture date, and the refresh procedure. Do not add an automated
     staleness check — that is Phase 130's territory.

## Sources

### Primary (HIGH confidence — executed or read in this session)

- **Empirical execution** — `Mix.Project.in_project/4` + `Lockspire.Generators.Install.run/1` against a real `mix phx.new host_app --database postgres` `mix.exs`; host resolution, generated file set, config `repo:` line, manifest `"version"`, and re-entrancy all observed directly.
- **Empirical execution** — `defmacro lockspire_routes` + `quote` compiled into a stock Phoenix router; `Phoenix.Router.routes/1` route table read back (8 routes, admin before public).
- **Empirical execution** — `Phoenix.LiveView.TagEngine.compile/2` against the rendered `authorized_apps/index.html.heex`; reproduced ADOPT-D16's `ParseError` at rendered line 23:16.
- **Empirical execution** — conflicting re-run of `Install.run/1`; half-installed state (missing resolver, handler, manifest) observed directly.
- **Local Elixir 1.19.5 doc chunks** via `Code.fetch_docs(Mix.Generator)` — `create_file/3` and `copy_file/3` prompt-unless-`:force` semantics.
- **hex.pm registry API** — `api/packages/ecto_sql`, `api/packages/ecto_sql/releases/3.14.0`, `api/packages/ecto/releases/3.14.0` — versions, publish dates, and transitive requirements.
- **Codebase reads** — `lib/lockspire/generators/{install,templates}.ex`, `lib/lockspire/install/{manifest,verify}.ex`, `lib/mix/tasks/lockspire.{install,upgrade,client.create,verify}.ex`, `lib/lockspire/{oban,config}.ex`, `lib/lockspire/security/policy.ex`, `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/web/router.ex`, all four `priv/templates/lockspire.install/` files under change, `test/integration/install_generator_test.exs`, `test/lockspire/maintainer/{defect_ledger,adopter_walk}_contract_test.exs`, `test/test_helper.exs`, `test/support/generated_host_app_web/`, `scripts/maintainer/{adopter_path_walk.sh,repo_hygiene_check.sh}`, `examples/adoption_demo/{mix.exs,lib/adoption_demo_web/router.ex,lib/adoption_demo/application.ex}`, `mix.exs`, `mix.lock`, `.formatter.exs`, `.credo.exs`, `.gitignore`, `.github/workflows/ci.yml`, `AGENTS.md`, `docs/{supported-surface,install-and-onboard}.md`.
- **Phase artifacts** — `126-DEFECT-LEDGER.md`, `126-VERIFICATION.md`, `127-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/config.json`.
- **Real walk output** — `tmp/adopter-walk/host_app/{mix.exs,config/lockspire.exs,.lockspire/install_manifest.json}`.

### Secondary (MEDIUM confidence)

- `raw.githubusercontent.com/elixir-ecto/ecto/master/CHANGELOG.md` — Ecto v3.14.0 entries; "no documented backwards incompatible changes or deprecations." Read via summarizer, not line-by-line.

### Tertiary (LOW confidence)

- None. Every claim in this document is either executed, read from repo source, or fetched from an authoritative registry/changelog.

## Metadata

**Confidence breakdown:**

| Area | Level | Reason |
|------|-------|--------|
| Defect set enumeration | HIGH | Twelve entries cross-checked against the ledger, the harness markers (`grep`), and the cited source lines. Three CONTEXT citation corrections found (`policy.ex` path, `verify.ex:270`, runtime-fixture consumers). |
| Router macro approach (D-08) | HIGH | Compiled and route table read back this session. |
| `in_project` host resolution (D-02) | HIGH | Executed; all five derived values observed. |
| Conflict semantics (INSTALL-03) | HIGH | Half-installed state reproduced; `Mix.Generator` semantics read from the local doc chunks; `lockspire.upgrade` pattern read line by line. |
| HEEx fence (D-25) | HIGH | Reproduced the exact ParseError. |
| Snapshot placement | HIGH for the constraints (formatter/Credo/glob/`package_files` all read), MEDIUM for the recommended path (not yet exercised by `mix hex.build`). |
| `ecto_sql`/`ecto` 3.14 upgrade | MEDIUM | Registry facts and changelog verified; suite result not. See A1. |
| Marker removal safety | MEDIUM | Reasoned from harness source; no walk run. See A2 and Open Question 1. |

**Research date:** 2026-07-28
**Valid until:** 2026-08-27 (30 days — the stack is stable; the one moving part is `ecto_sql`/`ecto`, and the
Phase 126 walk's own resolved versions are pinned in the ledger front-matter)
