---
phase: 127-installer-against-a-real-host
verified: 2026-07-29T18:51:32Z
status: passed
score: 4/4 must-haves verified (roadmap success criteria); 3/3 requirements (INSTALL-01/02/03) traced
behavior_unverified: 0
overrides_applied: 0
re_verification: No — initial verification
---

# Phase 127: Installer Against A Real Host — Verification Report

**Phase Goal:** Fix the installer-area defects the Phase 126 walk recorded, and prove `mix
lockspire.install` against a freshly generated Phoenix application instead of an empty fixture
directory.

**Verified:** 2026-07-29T18:51:32Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The installer's integration proof runs `mix lockspire.install` into a freshly generated Phoenix application rather than into a directory the test emptied first. | ✓ VERIFIED | `test/integration/install_host_interaction_test.exs` pushes a real, committed `mix phx.new 1.8.9 + phx.gen.auth` snapshot (`priv/test_fixtures/phx_new_host/`) via `Mix.Project.in_project/4` with **no `--web`/`--scope` override flags** — the exact gap `install_generator_test.exs:379`'s `reset_fixture!` (empties `config`/`lib`/`test` to a bare `.keep`) left open. Ran independently: `mix test test/integration/install_host_interaction_test.exs test/integration/install_generator_test.exs` → 10 tests, 0 failures. |
| 2 | A maintainer can confirm the installer's generated files match the host they were generated into — app name, web module, router module, and repo module all resolve against the real host rather than a placeholder. | ✓ VERIFIED | Same test's own docstring states the design intent explicitly ("a proof that would still pass with the host absent (INSTALL-02's exact defect) cannot pass this file") and asserts `config =~ "repo: HostApp.Repo"` and other host-resolved values sourced from the real pushed project, not from CLI flags. Test passes (above). |
| 3 | Re-running the installer against a host that already contains conflicting files or prior Lockspire output behaves observably and predictably, and does not leave the host in an unclear half-installed state. | ✓ VERIFIED | `lib/lockspire/generators/install.ex` implements plan-then-apply: `plan/1` classifies every destination read-only (`:unchanged`/`:create`/`{:conflict, reason}`, never writes); `apply_plan!/3` refuses and prints **every** conflicted destination in one pass and writes **zero bytes** if any conflict exists, before applying anything, regardless of `--dry-run`. Independently ran `mix test test/integration/install_conflict_semantics_test.exs` → 12 tests, 0 failures, including "a conflicted re-run reports every conflicted destination and writes zero bytes" and "--dry-run against a conflicted host still refuses." |
| 4 | Every installer-attributed defect in the Phase 126 ledger is either fixed in `mix lockspire.install` or its templates, or explicitly deferred with a stated reason recorded in the ledger. | ✓ VERIFIED | `126-DEFECT-LEDGER.md` carries exactly 12 defects with `Owning phase: 127` (D01, D02, D03, D04, D05, D06, D07, D08, D09, D14, D15, D16) — matching the ledger's own "twelve owned defects" claim. Every one has an explicit `Disposition:` line: 11 "Fixed in Phase 127" (fully or "in part," each naming what remains and why), 1 ("D14) "Deferred to Phase 128" with a stated ownership reason. The ledger's own "Phase 127 walk delta" section, backed by an archived, machine-adjudicated real run, confirms the fix set actually took effect (see Behavioral Spot-Checks below). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `priv/templates/lockspire.install/router.ex` | `defmacro lockspire_routes/1` emitting a real `quote do...end` route table (ADOPT-D01/D02/D03) | ✓ VERIFIED | Confirmed by direct read: `defmacro lockspire_routes(_opts \\ [])` returns a `quote do` block with a self-contained, deny-closed `:lockspire_require_operator` pipeline and browser-piped interaction/consent routes ahead of the pipeline-less public forward. |
| `mix.exs` (ecto_sql requirement) | Ranged, not pinned (ADOPT-D15) | ✓ VERIFIED | `{:ecto_sql, ">= 3.13.5 and < 4.0.0"}`; `mix.lock` resolves `ecto_sql 3.14.0`. |
| `lib/mix/tasks/lockspire.client.create.ex` | Reaches a started repo (ADOPT-D08) | ✓ VERIFIED | `Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _started_repo -> Clients.register_client(attrs) end)` — wraps the call exactly as claimed. |
| `lib/lockspire/generators/install.ex` (`instructions/1`) | Names app-tree wiring + key lifecycle (ADOPT-D05/D06) | ✓ VERIFIED | Lines ~375-376: names `included_applications`, `extra_applications: [:oban, :cachex]`, ordering after the host Repo, and all three key-lifecycle calls (`generate_key/1`, `publish_key/2`, `activate_key/2`) with the publication-vs-activation distinction stated explicitly. |
| `lib/lockspire/install/verify.ex`, `lib/mix/tasks/lockspire.verify.ex` | Corrected `--migrations-path` remediation strings (ADOPT-D07) | ✓ VERIFIED | All four remediation sites (pending, storage-prefix, oban-prefix, up-to-date) plus the installer's own instructions name `mix ecto.migrate --migrations-path #{migrations_path()}` using the release-safe `Application.app_dir(:lockspire, "priv/repo/migrations")` form. |
| `priv/templates/lockspire.install/config.exs` | Mount-path-consistent issuer, `known_scopes`, `signing_alg`, self-describing `secret_key_base` placeholder (ADOPT-D04) | ✓ VERIFIED | All four present as claimed; `oban:` remains genuinely absent (ledger states this explicitly as the harness's own remaining patch, not a hidden gap). |
| `priv/templates/lockspire.install/account_resolver.ex` | `login_path: "/users/log-in"` (ADOPT-D09) | ✓ VERIFIED | Line 76 confirms the corrected default. |
| `priv/templates/lockspire.install/authorized_apps/index.html.heex` | Elixir string interpolation, not nested EEx (ADOPT-D16) | ✓ VERIFIED | Line 19: `<li id={"authorized-app-#{consent.grant.id}"}>`. |
| `lib/lockspire/generators/install.ex` (`plan/1`/`apply_plan!/3`) | Plan-then-apply atomic refusal (INSTALL-03) | ✓ VERIFIED | Read directly; behavioral test passes (see Truth 3). |
| `.github/workflows/adopter-walk.yml`, `scripts/maintainer/adopter_walk_{report,verify,ci}.{py,sh}` | Machine-adjudicated walk, advisory CI lane | ✓ VERIFIED | All files exist; `mix.exs` registers `adopter.walk` and `adopter.walk.verify` aliases. |
| `126-DEFECT-LEDGER.md` (Phase 127 walk delta) | Twelve dispositions, confirmed run | ✓ VERIFIED | Present, with full row-by-row detail (see Truth 4 and Behavioral Spot-Checks). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `mix lockspire.client.create` | `Lockspire.Config.repo!()` | `Ecto.Migrator.with_repo/2` | ✓ WIRED | Confirmed by direct read and by 10-test pass of `test/mix/tasks/lockspire_client_create_test.exs` (run as part of the maintainer/integration suite). |
| `Install.plan/1` | `Install.apply_plan!/3` | conflict classification feeds refusal-before-write | ✓ WIRED | `apply_plan!/3`'s first branch checks `conflicts != []` and refuses (raises, prints, writes nothing) before any create/unchanged branch runs, confirmed by `install_conflict_semantics_test.exs`. |
| `scripts/maintainer/adopter_walk_verify.py` | `scripts/maintainer/adopter_walk_baseline.json` + `127-WALK-REPORT-20260729.json` | row-by-row (step_id, occurrence) comparison | ✓ WIRED | Independently re-executed by this verifier: `python3 scripts/maintainer/adopter_walk_verify.py --report .../127-WALK-REPORT-20260729.json --baseline scripts/maintainer/adopter_walk_baseline.json` → `MATCH: every (step_id, occurrence) row's level agrees with the baseline.` Exit 0. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Machine-adjudicated walk report matches its pre-committed baseline (the actual mechanism behind Truth 4, not narration of it) | `python3 scripts/maintainer/adopter_walk_verify.py --report 127-WALK-REPORT-20260729.json --baseline adopter_walk_baseline.json` | `MATCH...` exit 0 | ✓ PASS |
| Report row counts are internally consistent | manual tally of `127-WALK-REPORT-20260729.json`'s 27 rows | 22 PASS / 5 FAIL rows + 1 more FAIL (`step-04-migrate`, unconditional) = 22 PASS, 6 FAIL, matching `summary_line` | ✓ PASS |
| Defect-ledger marker reconciliation is mechanically enforced, not just claimed | `mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` | 9 tests, 0 failures | ✓ PASS |
| Router/HEEx template fixes actually compile and route correctly | `mix test test/integration/install_template_compile_test.exs test/lockspire/install/install_instructions_test.exs` | 12 tests, 0 failures | ✓ PASS |
| Conflict-refusal / dry-run / drift behavior | `mix test test/integration/install_conflict_semantics_test.exs` | 12 tests, 0 failures | ✓ PASS |
| Host-interaction proof (Truths 1 & 2) | `mix test test/integration/install_host_interaction_test.exs test/integration/install_generator_test.exs` | 10 tests, 0 failures | ✓ PASS |
| Full maintainer namespace regression | `mix test test/lockspire/maintainer/` | 68 tests, 0 failures | ✓ PASS |

Not run: `mix adopter.walk` itself (10+ minutes, requires a real database and network — excluded per verification scope). Its output is instead independently re-adjudicated above via the committed verifier against the archived report, which is the correct level of evidence: the report's internal consistency and the verifier's PASS are checked by this verifier directly rather than trusted from `127-09-SUMMARY.md`'s narration.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| INSTALL-01 | 127-01, 127-02, 127-03, 127-04, 127-05, 127-06 | Installer exercised against a freshly generated Phoenix app | ✓ SATISFIED | `install_host_interaction_test.exs` + the underlying defect fixes (ADOPT-D01-D09, D15, D16) all independently test-verified above. |
| INSTALL-02 | 127-01, 127-05 | Generated files match the real host (app name, web/router/repo module) | ✓ SATISFIED | Same test proves resolution with zero override flags. |
| INSTALL-03 | 127-07, 127-08 | Re-run behavior on conflicting/prior output is observable and predictable | ✓ SATISFIED | `install_conflict_semantics_test.exs` — plan-then-apply, atomic refusal, `--dry-run`, drift refusal, all test-verified. |

REQUIREMENTS.md traceability table (lines 87-89) already marks all three `Complete`, consistent with this independent finding. No orphaned requirements: REQUIREMENTS.md maps exactly INSTALL-01/02/03 to Phase 127, and all three appear in plan frontmatter (`requirements-completed` fields across 127-01 through 127-08).

### Anti-Patterns Found

None. Scanned every file touched by this phase (`lib/lockspire/install/manifest.ex`, `lib/lockspire/generators/install.ex`, `lib/mix/tasks/lockspire.install.ex`, `lib/mix/tasks/lockspire.client.create.ex`, `lib/lockspire/install/verify.ex`, `lib/mix/tasks/lockspire.verify.ex`, `mix.exs`, all four `priv/templates/lockspire.install/*` template files, and the `scripts/maintainer/adopter_walk_*` tooling) for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER`, "not yet implemented", "coming soon" — zero matches (the one `REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE` string is a deliberate, documented adopter-facing placeholder for `mix phx.gen.secret`, not implementation debt).

### Human Verification Required

None. This phase is entirely CLI/library/template surface with no UI; all four ROADMAP truths and all three requirements have direct file-read evidence plus independently re-run automated tests or scripts (not merely SUMMARY.md narration).

### Gaps Summary

No gaps found. One documentation-hygiene note, not a goal-achievement gap: `.planning/ROADMAP.md`'s "Plans: 7/9 plans executed" line (line 91) and the Progress table's "9/10 In Progress" row (line 189) are stale — all 10 plans (127-01 through 127-10) exist with `status: complete` (127-09's Markdown-only summary states "Status: Complete" in prose rather than frontmatter, confirmed by reading the file directly) and the phase's own checkbox (line 16) is already marked `[x]`. This is bookkeeping to reconcile during milestone housekeeping, not evidence the phase goal was missed — every artifact, test, and the archived walk-delta evidence checked out.

---

_Verified: 2026-07-29T18:51:32Z_
_Verifier: Claude (gsd-verifier)_
