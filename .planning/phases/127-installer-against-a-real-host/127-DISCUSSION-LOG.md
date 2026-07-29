# Phase 127: Installer Against A Real Host - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-28
**Phase:** 127-installer-against-a-real-host
**Mode:** assumptions
**Areas analyzed:** Proof Shape & Lane; Router Template Fix Shape; Config Template; Conflict &
Re-run Semantics; Migration Reachability; Library & Template Point Fixes

## Assumptions Presented

### Proof Shape & Lane (INSTALL-01 / INSTALL-02)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Committed `mix phx.new` snapshot + `Mix.Project.in_project/4`, not `File.cd!`, not per-run generation | Likely | `generators/install.ex:28-33` (no CLI override for app name); `install_generator_test.exs:363-368` (`File.cd!` only); `:38-71` (`repo:` line never asserted); `tmp/adopter-walk/host_app/config/lockspire.exs` (generator resolves correctly against a real host) |
| Snapshot lives outside `test/` | Confident | `mix.exs:70` `elixirc_paths(:test)` collides with `test/support/generated_host_app_web/`; `mix test` glob would sweep `phx.new`'s own `*_test.exs` |
| New host-interaction test tagged `@moduletag :integration` | Confident | `install_generator_test.exs` untagged today; `mix.exs:76-77` lane definitions; `ci.yml:106,176` |

### Router Template (D01 / D02 / D03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `lockspire_routes` becomes a `defmacro` returning `quote`, inside the host-generated file | Likely | `priv/templates/lockspire.install/router.ex:9-10` heredoc String |
| Macro defines its own deny-closed `:require_operator` pipeline | Likely | `install/verify.ex:120-126` errors if admin mount absent; `:128-134` if shadowed; `router.ex:54` references an undefined pipeline |
| Explicit `pipe_through [:browser]` scope before the pipeline-less forward | Confident | `examples/adoption_demo/.../router.ex:53-65` — only correct wiring in the repo |
| Template emits the `live_session` block, value left to the host | Likely | `adopter_path_walk.sh:800-812` (ADOPT-D18 workaround) |

### Config Template (D04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `issuer` must include the mount path; add `known_scopes` and `signing_alg` | Confident | `config.exs:10` bare placeholder; `policy.ex:104-106` raises; `authorization_request.ex:967-968` rejects all non-openid scopes when `known_scopes` unset |
| `secret_key_base` emitted as placeholder, never a literal | Confident | `config.ex:255-265` `inferred_secret_key_base/0` scans only `:lockspire` app env |
| `oban:` is D05, not D04 | Confident | `oban.ex:11-29` defaults queues on |

### Conflict & Re-run Semantics (INSTALL-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Plan-then-apply with atomic refusal and full conflict list; add `--dry-run` | Confident | `generators/install.ex:16-20` writes in a loop, manifest after; `:113-119` raises on first conflict; `install_generator_test.exs:323-361` only proves it raises |
| Mirror `lockspire.upgrade.ex:21,50-118` rather than inventing a pattern | Confident | Same codebase, same shape, already shipped |
| Input-drift (`--web`/`--scope`/`--mount-path`) refused | Confident | `manifest.ex:53-62` already records all three |
| No `--force`, no interactive prompt | Confident | host-owned seams constraint; walk + CI run non-interactively |

### Point Fixes

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| D08: `Ecto.Migrator.with_repo/2`, not `@requirements ["app.start"]` | Confident | `verify.ex:202-217` vs `lockspire.verify.ex:10` — both declare `["app.config"]`; only `with_repo` makes it work |
| D09: `login_path: "/users/log-in"` | Confident | `account_resolver.ex:75`; `phx.gen.auth` default |
| D15: loosen `mix.exs:47` to `">= 3.13.5 and < 4.0.0"` | Likely → Confident after research | see External Research |
| D16: `#{consent.grant.id}` interpolation | Confident | `authorized_apps/index.html.heex:19`; only such occurrence |
| D16 fence via `Phoenix.LiveView.TagEngine.compile/2` | Confident after research | see External Research |
| D05/D06 installer halves = `instructions/1` output only, no new Mix tasks | Likely | `docs/supported-surface.md:13-17` is the constraint; `adoption_demo/mix.exs:16-22`; `admin/keys.ex:36,80,103` |
| D14 defers to 128 | Likely | `phx.gen.auth` generated scaffolding, not installer-owned |

### Migration Reachability (D07) — flagged for escalation

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fix the wrong remediation strings; defer the redesign with a stated reason | Unclear → resolved by user | `verify.ex:241` and `install.ex:140` both prescribe the provably-no-op bare `mix ecto.migrate`; `lockspire.test.setup.ex:34` and `verify.ex:197` already use the release-safe form; `docs/supported-surface.md:13-17` + REQUIREMENTS Out-of-Scope forbid widening |

## Corrections Made

No corrections. The user confirmed all three escalated decisions as recommended:

1. **Proof lane** — committed `phx.new` snapshot + `Mix.Project.in_project/4`. Chosen over a
   gated `mix phx.new` shell-out, a both-lanes combination, and declaring the Phase 126 walk the
   proof. This settles how literally criterion 1's "freshly generated" is read: real generator
   output, not regenerated per run.
2. **D07** — fix the wrong strings, formally defer the `Lockspire.Migration` / host-migration-generator
   redesign with a reason recorded in the ledger. Chosen over shipping `mix lockspire.migrate` and
   over building the Oban-pattern generator now. Accepted cost: adopters still need a
   `--migrations-path` flag until a future phase.
3. **Remainder of the bundle** — accepted as presented.

## External Research

Two topics were flagged as unanswerable from the codebase alone. Both resolved decisively.

**1. Is loosening `{:ecto_sql, "~> 3.13.5"}` safe? (ADOPT-D15)**
- **Finding:** `ecto_sql 3.14.0` has **no** backwards-incompatible changes and no deprecations —
  purely additive (UNLOGGED tables, MySQL `insert_mode: :ignore`, sandbox owner labeling, etc.).
  Nothing touches `Ecto.Migrator`, migration prefix resolution, or `Ecto.Adapters.SQL.query/4`.
  It requires `ecto ~> 3.14.0`, whose only breakage-capable changes are raising on query-like
  keyword opts to Repo functions, and requiring decimal v3 — the lock already satisfies both
  (`mix.lock:7,8,11,12,46`). Lockspire passes only `prefix:` and `log:` to Repo functions
  (`storage/ecto/repository.ex:2274-2283`), both legitimate Repo options. The v1.34 prefix-isolated
  storage reaches no ecto_sql internals: `storage/ecto/migration.ex` only `Keyword.put_new`s
  `prefix:` into public `Ecto.Migration` calls, and `storage/ecto/prefix.ex` is pure string
  validation. `git log -S'ecto_sql' -- mix.exs` returns a single commit (`c839753`, the initial
  skeleton) with the string byte-identical since — the `.5` is "latest at scaffold time," not a
  requirement.
- **Source:** `https://hex.pm/api/packages/ecto_sql/releases/3.14.0`; upstream `ecto_sql` and `ecto`
  CHANGELOGs on GitHub; greps over `lib/`, `test/`, `priv/`.
- **Confidence impact:** D15 Likely → Confident. Recommendation refined from `"~> 3.13"` to
  `">= 3.13.5 and < 4.0.0"`, keeping the PG18 `:restrict_violation` fix as a floor and matching the
  `phoenix_live_view` house style at `mix.exs:45`.
- **Caveat (reasoned, not verified):** the suite was not run against 3.14 — that requires touching
  `mix.lock`, out of scope for research. Phase 127 should land the range change with one CI run that
  actually resolves 3.14.

**2. Is there a stable API to assert generated `.heex` compiles in-test? (ADOPT-D16 fence)**
- **Finding:** resolved `phoenix_live_view` is 1.2.8 (`mix.lock:47`). The
  `EEx.compile_string(engine: Phoenix.LiveView.TagEngine)` route is **deprecated** on that version —
  `tag_engine.ex:241-267` emits "Using Phoenix.LiveView.TagEngine as an EEx.Engine is deprecated!"
  and points at `TagEngine.compile/2`, which is public, `@doc`'d with its option list
  (`tag_engine.ex:24-52`), and is what `Phoenix.Component.sigil_H/2` itself calls
  (`phoenix_component.ex:929-935`). Alternatives were all worse: `HTMLEngine.compile/1` is
  `@doc false`; `~H` breaks on templates containing `#{`; `embed_templates` needs a temp dir plus
  `Code.compile_string` for no extra signal.
- **Verified by running it:** the helper reproduced ADOPT-D16 at `probe.html.heex:19:16` against the
  real rendered template, passed on the corrected form, and also caught unmatched/mismatched tags.
  Unknown components do *not* raise — a compile-to-AST fence, not link-time, which is correct scope.
- **Source:** `deps/phoenix_live_view/lib/phoenix_live_view/tag_engine.ex`,
  `deps/phoenix_live_view/lib/phoenix_component.ex`; live `mix run --no-start` probe.
- **Confidence impact:** D16 fence Unclear → Confident, with an implementation sketch and two notes
  (the ownership header offsets reported line numbers; `caller: __ENV__` inside a test function is
  fine since no macro expansion occurs for plain markup).

**3. Cost of `mix phx.new` in a cold CI job** — flagged but **not researched**. It only decides
between proof-lane alternatives the user did not choose, and it is unmeasurable without actually
running a cold CI job. Carried into CONTEXT.md's deferred list as a Phase 130 concern.

## Methodology Lenses Applied

- **Assumption-First / Research-First Decisive Defaults** — all twelve owned defects received a
  codebase-grounded default before anything was surfaced to the user. Only D07 lacked one, and
  because it collided with an explicit out-of-scope rule, not for want of evidence.
- **Least-Surprise Host Seam** — decided two things: the admin pipeline is deny-closed by default
  rather than undefined (today) or silently permissive; and `secret_key_base`/`known_scopes` are
  emitted explicitly rather than inferred from ambient host state, since
  `Config.inferred_secret_key_base/0` demonstrably cannot see the host endpoint.
- **High-Threshold Escalation** — flagged exactly two items for the user: the proof-lane reading of
  criterion 1, and D07's support-contract fork. Everything else resolved in-workflow.
- **One-Shot Recommendation Bundles** — the four assumption areas plus the disposition table were
  presented as one coherent bundle. The `in_project` proof is what makes the router and config fixes
  verifiable without the full walk, so they reinforce each other.
