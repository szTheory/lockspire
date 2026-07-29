---
phase: 126-adopter-path-walk-defect-ledger
plan: 04
subsystem: testing
tags: [bash, elixir, phoenix, oban, oauth, adopter-path, adopt-02, adopt-03, adopt-04]

# Dependency graph
requires:
  - phase: 126-02
    provides: "step-01-add-dep through step-03b-router-wire walk steps; the ADOPT-03 step-ID <-> guide-section mapping gate"
  - phase: 126-03
    provides: "scripts/maintainer/adopter_path_flow.py's ADOPT-04 two-layer token proof, targeting DEFAULT_PROTECTED_PATH=/api/walk/summary and asserting the userinfo email claim"
provides:
  - "step-03c-resolver: implements the generated AccountResolver host seam (resolve_account/2, build_claims/2) in the generated host only, emitting the seeded user's email claim the flow driver asserts at <mount>/userinfo"
  - "ADOPT-D09: the resolver template's hardcoded login_path (\"/login\") vs the real mix phx.gen.auth login route (/users/log-in), recorded and workaround-marked in the generated host's own resolver file (never the template)"
  - "ADOPT-D11: the guide's resolver bullet list supplies no worked example, subject-reference contract, or claim map shape -- recorded, owning phase 128"
  - "step-03d-app-tree: ADOPT-D05 (merged installer+guide defect -- :lockspire starts before the host Repo with live Oban queues) recorded and worked around via included_applications: [:lockspire] plus extra_applications: [:oban, :cachex] plus Lockspire's three supervision children ordered after the host Repo"
  - "step-03e-protected-route: a host-owned /api/walk/summary route behind the canonical VerifyToken -> EnforceSenderConstraints -> RequireToken pipeline (scope-restricted to read:walk), giving ADOPT-04 its second, host-owned acceptance layer"
affects: [126-05, 126-06, 127, 128, 129]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Host-owned seam files (account_resolver.ex, application.ex supervision children, the protected-route pipeline/controller) are written or patched only inside the generated host app under $HOST_APP_DIR -- never lib/lockspire/ or priv/templates/lockspire.install/ -- enforced both by a contract test and by the plan's own git diff --exit-code checks"
    - "included_applications alone does not start a suppressed app's own runtime dependencies (Oban, Cachex): Application.ensure_all_started/1 never walks an included application's dependency chain, so :oban and :cachex must also be named directly in the host's own extra_applications -- confirmed empirically against a real generated host, not assumed from the demo's mix.exs alone"
    - "Protected-route wiring reproduces docs/protect-phoenix-api-routes.md's canonical plug order verbatim (VerifyToken -> EnforceSenderConstraints -> RequireToken) inside BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers, with the route path kept byte-identical to adopter_path_flow.py's DEFAULT_PROTECTED_PATH via a dedicated contract-test assertion"

key-files:
  created: []
  modified:
    - scripts/maintainer/adopter_path_walk.sh
    - test/lockspire/maintainer/adopter_walk_contract_test.exs

key-decisions:
  - "resolve_account/2 looks up HostApp.Repo.get(HostApp.Accounts.User, id) directly rather than adding a new Accounts context function, since mix phx.gen.auth's generated context only exposes get_user!/1 (raising) and no nil-safe by-id lookup; the generated host is throwaway harness output, not a file this plan is asked to extend with new context functions."
  - "The subject reference is the seeded user's bare id rendered as a string (no \"user:\" prefix), following the plan's own text rather than examples/adoption_demo's subject_for/1 convention (which prefixes with \"user:\") -- the plan explicitly names this an open assumption (see flagged_assumptions) that ADOPT-D11 itself covers if a different format is ever required."
  - "Fixed a real defect discovered during manual verification against a real generated host: examples/adoption_demo/mix.exs:17-23's included_applications: [:lockspire] alone is not sufficient. Application.ensure_all_started/1 never walks an included application's own dependency chain, so without also naming :oban and :cachex directly in the host's extra_applications, Oban's own registry never starts and the host crashes with 'unknown registry: Oban.Registry'. Matched the demo's actual extra_applications: [:logger, :runtime_tools, :oban, :cachex] (not just the included_applications line RESEARCH Pitfall 3 highlighted) and folded the fix into the same ADOPT-D05 marker rather than opening a second one -- it's one root cause (the boot-ordering fix is incomplete without it), not two."
  - "step-03e's protected-route wiring narrows VerifyToken to scopes: [\"read:walk\"] with no audience: restriction, matching RESEARCH's own code example and the flow driver's default --scope, which requests read:walk alongside openid/email/profile."

requirements-completed: [ADOPT-02, ADOPT-03, ADOPT-04]

coverage:
  - id: D8
    description: "step-03c-resolver implements resolve_account/2 and build_claims/2 in the generated host (never lib/lockspire/ or priv/templates/), emitting the seeded user's email claim the flow driver asserts at <mount>/userinfo; the resolver template's hardcoded login_path mismatch (ADOPT-D09) and the guide's missing worked-example gap (ADOPT-D11) are each recorded and attributed before the workaround is applied"
    requirement: "ADOPT-02"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (27 tests, includes step-03c-resolver presence, host-only-write assertion, and ADOPT-D09 recording/marker assertions)"
        status: pass
      - kind: static
        ref: "bash -n scripts/maintainer/adopter_path_walk.sh"
        status: pass
      - kind: other
        ref: "Manual: bash scripts/maintainer/adopter_path_walk.sh --from-step 03 against a real mix phx.new + phx.gen.auth + mix lockspire.install generated host -- step-03c-resolver reaches PASS"
        status: pass
    human_judgment: false
  - id: D9
    description: "step-03d-app-tree records ADOPT-D05 (the undocumented application-start ordering and live-Oban-queue defect, RESEARCH Pitfall 3) attributed jointly to the installer and the guide, then applies included_applications: [:lockspire] plus extra_applications: [:oban, :cachex] plus Lockspire's three supervision children after the host Repo, recording PASS only when the generated host actually boots"
    requirement: "ADOPT-03"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs: 'walk script wires application-start ordering and supervision children as step-03d-app-tree (ADOPT-D05)'"
        status: pass
      - kind: other
        ref: "Manual: mix run -e 'IO.puts(\"boot ok\")' against a real generated host with the wiring applied -- succeeds after adding :oban/:cachex to extra_applications (failed with 'unknown registry: Oban.Registry' before that fix)"
        status: pass
    human_judgment: false
  - id: D10
    description: "step-03e-protected-route wires a host-owned /api/walk/summary route behind the canonical VerifyToken -> EnforceSenderConstraints -> RequireToken pipeline (scope-restricted to read:walk, wrapped in BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers), giving ADOPT-04 its second acceptance layer at exactly the path scripts/maintainer/adopter_path_flow.py targets by default"
    requirement: "ADOPT-04"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs: plug-order presence/regression-guard tests and the byte-identical protected-path test"
        status: pass
      - kind: other
        ref: "Manual: mix phx.routes lists /api/walk/summary after step-03e against a real generated host"
        status: pass
    human_judgment: false

# Metrics
duration: 42min
completed: 2026-07-29
status: complete
---

# Phase 126 Plan 04: Guide §3c-§3e -- Host Resolver Seam, App-Tree Wiring & Protected Route Summary

**Three new walk steps (`step-03c-resolver`, `step-03d-app-tree`, `step-03e-protected-route`) implement the generated `AccountResolver` host seam, order Lockspire's application start behind the host's own Repo with its supervision children wired in, and expose a scope-restricted protected host API route -- surfacing and marking three new provisional defects (`ADOPT-D09`, `ADOPT-D11`, `ADOPT-D05`) along the way, with all three PASS paths independently confirmed against a real `mix phx.new` + `phx.gen.auth` + `mix lockspire.install` generated host.**

## Performance

- **Duration:** ~42 min
- **Started:** 2026-07-29T00:19:35Z
- **Completed:** 2026-07-29T00:41:00Z
- **Tasks:** 2
- **Files modified:** 2 (0 created, 2 modified)

## Accomplishments

- `step-03c-resolver`: writes a real implementation of `resolve_account/2` and `build_claims/2` into the generated host's `lib/host_app/lockspire/account_resolver.ex` -- never into `lib/lockspire/` or `priv/templates/lockspire.install/`. `resolve_account/2` looks up `HostApp.Repo.get(HostApp.Accounts.User, id)` by the seeded user's id (rendered as a string, coerced back to an integer); `build_claims/2` emits `%{"email" => account.email}` as both the ID-token and userinfo claim set -- the exact claim `scripts/maintainer/adopter_path_flow.py` asserts at `<mount>/userinfo`. Records `ADOPT-D11` (the guide names the callbacks to implement but supplies no worked example, subject-reference contract, or claim map shape) before writing the implementation, and detects+records `ADOPT-D09` (the template's `redirect_for_login/2` hardcodes `login_path: "/login"`, but `mix phx.gen.auth --live` generates `/users/log-in`) before overriding the login path in the generated host's own resolver file behind `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D09`.
- `step-03d-app-tree`: records `ADOPT-D05` -- a single, precisely attributed entry merging the installer half (no `included_applications`) and the guide half (no documented `oban:` disabling instruction) of RESEARCH Pitfall 3, owned by phases 127 and 128 respectively. Applies `included_applications: [:lockspire]` to order the host's own Repo first, **and** adds `:oban`/`:cachex` to the host's `extra_applications` -- a real gap discovered during manual verification: `included_applications` alone leaves Oban's own registry unstarted (`Application.ensure_all_started/1` never walks an included application's dependency chain), which is not visible from reading `examples/adoption_demo/mix.exs` in isolation without also checking its `extra_applications` line. Adds Lockspire's three supervision children (named Oban runtime, JWKS cache, key cache) to the generated host's `application.ex` after its Repo. Records PASS only when `mix run -e 'IO.puts("boot ok")'` actually succeeds.
- `step-03e-protected-route`: wires a `:lockspire_protected_api` pipeline (`VerifyToken` scoped to `read:walk` -> `EnforceSenderConstraints` -> `RequireToken`, in `docs/protect-phoenix-api-routes.md`'s canonical order) and a `GET /api/walk/summary` route through the host's `:api` pipeline, wrapped in `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` markers, plus a small `HostAppWeb.WalkApiController` reflecting only `access_token.subject`/`access_token.scope` -- never the raw bearer token. The route path is kept byte-identical to `scripts/maintainer/adopter_path_flow.py`'s `DEFAULT_PROTECTED_PATH` via a dedicated contract-test assertion so the two sides cannot silently drift apart.
- `adopter_walk_contract_test.exs` gained 7 new tests: step-03c-resolver presence and its host-only-write guarantee (with `git diff --exit-code` checks over both `priv/templates/lockspire.install/` and `lib/lockspire/`), the ADOPT-D09 recording+marker assertion, step-03d-app-tree's `ADOPT-D05` marker and the `extra_applications` fix, step-03e-protected-route's plug presence and a reordering regression guard, and the harness<->driver protected-path byte-identity check.

## Task Commits

Each task was committed atomically:

1. **Task 1: Guide §3c -- host account resolver seam and ADOPT-D09 login-path mismatch** - `98cfbbd` (feat)
2. **Task 2: Guide §3d/§3e -- application-start ordering and protected host API route (ADOPT-D05)** - `4a2107a` (feat)

## Files Created/Modified

- `scripts/maintainer/adopter_path_walk.sh` - Three new step functions (`run_step_03c_resolver`, `run_step_03d_app_tree`, `run_step_03e_protected_route`) and their calls in the main sequence
- `test/lockspire/maintainer/adopter_walk_contract_test.exs` - 7 new tests covering the three new steps' presence, host-only-write guarantee, and marker/plug-order/path-identity contracts

## Decisions Made

- **`resolve_account/2` reaches `HostApp.Repo.get/2` directly rather than adding a new `Accounts` context function.** `mix phx.gen.auth`'s generated context only exposes `get_user!/1` (which raises on a miss) and no nil-safe by-id lookup. Since the generated host is throwaway harness output and this plan does not ask for new context functions, the resolver reaches the Repo directly -- exactly the shape the plan's own `<read_first>` pointed at (`examples/adoption_demo`'s resolver similarly reaches its own context's `get_by_id/1`, which itself wraps a Repo lookup).
- **Subject reference is the bare user id rendered as a string, no `"user:"` prefix.** The plan's action text says "the subject reference for this walk is the generated user's id rendered as a string," which differs from `examples/adoption_demo`'s own `"user:" <> account.id` convention. Followed the plan's explicit instruction; the `<flagged_assumptions>` block already names this as an open question that `ADOPT-D11`'s own existence covers if a different format turns out to be required.
- **Found and fixed a real gap in the `included_applications` workaround during manual verification: `:oban` and `:cachex` must also be named in the host's `extra_applications`.** RESEARCH Pitfall 3 and the plan's action text both point at `examples/adoption_demo/mix.exs:17-23`'s `included_applications: [:lockspire]` line as the fix, but reading only that line (without also reading the demo's `extra_applications: [:logger, :runtime_tools, :oban, :cachex]`) produces a host that still crashes with `** (ArgumentError) unknown registry: Oban.Registry`, because `Application.ensure_all_started/1` never walks an included application's own dependency chain. Verified empirically against a real generated host: the crash reproduced with `included_applications` alone, and disappeared once `:oban`/`:cachex` were added to `extra_applications`. Folded into the same `ADOPT-D05` marker (one root cause, not two) rather than opening a new provisional ledger ID -- this is Rule 1 (bug found and fixed before it shipped), not an out-of-scope defect, since it's part of making `step-03d-app-tree`'s own stated PASS criterion ("the generated host boots") actually achievable.
- **`step-03e`'s route narrows `VerifyToken` to `scopes: ["read:walk"]` with no `audience:` restriction**, matching both RESEARCH's own code example and `scripts/maintainer/adopter_path_flow.py`'s default `--scope` (which requests `read:walk` alongside `openid email profile`) -- no narrowing or dropping of the scope restriction, per the plan's own prohibition.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug found before it shipped] `included_applications: [:lockspire]` alone leaves `:oban`'s own registry unstarted**
- **Found during:** Task 2, manual verification of `step-03d-app-tree` against a real generated host
- **Issue:** Applying only `included_applications: [:lockspire]` (the literal fix RESEARCH Pitfall 3 and the plan's action text point at) produced `mix run -e 'IO.puts("boot ok")'` crashing with `** (ArgumentError) unknown registry: Oban.Registry`, because `Application.ensure_all_started/1` never walks an included application's own dependency chain -- `:oban` (a regular, non-included dependency of `:lockspire`) never gets auto-started.
- **Fix:** Added `:oban` and `:cachex` directly to the generated host's `extra_applications`, matching `examples/adoption_demo/mix.exs`'s actual (fuller) `application/0` definition, not just its `included_applications` line.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh` (the `run_step_03d_app_tree` sed patch), `test/lockspire/maintainer/adopter_walk_contract_test.exs` (new assertion locking in the fix)
- **Verification:** Re-ran the walk against a real generated host with the fix applied -- `step-03d-app-tree` now records PASS and `mix run -e 'IO.puts("boot ok")'` succeeds.
- **Committed in:** `4a2107a` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug found and fixed before it shipped).
**Impact on plan:** Necessary for `step-03d-app-tree`'s own stated PASS criterion (the generated host actually boots) to be achievable at all. No scope creep -- both fixes live entirely inside the plan's own `files_modified` list and the same `ADOPT-D05` marker the plan specifies.

## Known Stubs

None. All three new steps write real, functioning implementations into the generated host (resolver logic, application supervision children, protected-route pipeline and controller), each independently confirmed to reach PASS against a real `mix phx.new` + `mix phx.gen.auth --live` + `mix lockspire.install` generated host with a real PostgreSQL database.

## Issues Encountered

- An unrelated, pre-existing installer-template defect (`priv/templates/lockspire.install/authorized_apps_html/index.html.heex`'s nested `<%= %>` inside a `{...}` HEEx attribute expression, which the resolved `phoenix_live_view 1.2.8` tokenizer rejects) blocked full end-to-end compilation of the manually-verified host until a scratch-only patch was applied directly in the disposable `tmp/adopter-walk/host_app/` workdir (gitignored, never committed, and outside this plan's `files_modified` scope). This is an out-of-scope discovery -- it belongs to `step-03a-config-import`'s domain (already implemented and committed in plan 126-02) and to a different template file entirely (`authorized_apps_html`, not `account_resolver`). Logged to `deferred-items.md` below rather than fixed in-tree; Phase 127/129 should investigate whether this HEEx nesting pattern needs correcting across all affected installer templates.
- A stale local `mix.lock` in the disposable, gitignored `tmp/adopter-walk/host_app/` workdir (left over from an earlier session, resolved against an incompatible `ecto_sql` version) blocked `step-01-add-dep`'s `mix deps.get` during manual verification; resolved locally via `mix deps.unlock ecto ecto_sql` + `mix deps.get` in the scratch workdir. This is local environment staleness in disposable harness state, not a code change and not part of this plan's deliverable.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `scripts/maintainer/adopter_path_walk.sh` now walks guide §3's full "wire the generated files" sequence: `step-03a-config-import` through `step-03e-protected-route`, all attributed and record-and-continue. `step-04` (Lockspire migrations) onward remains for plan 126-05.
- Three new provisional defect IDs are now walk-observable and marked: `ADOPT-D09` (resolver template's hardcoded login path), `ADOPT-D05` (undocumented application-start ordering and supervision children, including the newly-discovered `extra_applications` half), `ADOPT-D11` (resolver seam's missing worked example/subject-reference/claim-shape guidance). Plan 126-06 reconciles these marker IDs against the committed ledger via set-equality, alongside the four from plan 126-02.
- All three new steps' PASS paths were independently confirmed against a real `mix phx.new` + `mix phx.gen.auth --live` + `mix lockspire.install` generated host with a real PostgreSQL database (not just synthetic fixtures): `step-03c-resolver` compiles and resolves the corrected login path in `mix phx.routes`; `step-03d-app-tree` boots successfully via `mix run -e 'IO.puts("boot ok")'`; `step-03e-protected-route` lists `/api/walk/summary` in `mix phx.routes`. Their FAIL paths (missing precondition files, compile failures cascading from step-03a's own pre-existing HEEx defect) were also exercised and confirmed to record-and-continue correctly.
- Full end-to-end verification of the authorization-code + PKCE flow actually reaching and succeeding against `step-03e`'s protected route (i.e. `scripts/maintainer/adopter_path_flow.py`'s `step-06c-token-proof` passing for real) was **not** performed in this plan -- that requires guide §4's Lockspire migrations (plan 126-05) and client registration (also plan 126-05), which are out of this plan's scope per the phase's own plan boundaries.
- No blockers.

## Verification

- `bash -n scripts/maintainer/adopter_path_walk.sh` -- exits 0
- `mix test test/lockspire/maintainer/adopter_walk_contract_test.exs` -- 27 tests, 0 failures
- `mix test test/lockspire/maintainer/adopter_flow_driver_contract_test.exs` -- 9 tests, 0 failures (unaffected)
- `git diff --exit-code -- lib/lockspire/ priv/templates/lockspire.install/` -- no change
- `mix qa` (format / compile --warnings-as-errors / credo --strict / sobelow) -- clean
- `mix test.fast` -- 1263 tests, 0 failures (287 excluded; +7 from the new contract tests, baseline was 1256)
- `bash scripts/maintainer/repo_hygiene_check.sh --ci` -- 18 PASS, 0 WARN, 0 BLOCK
- `mix ci` (deps.get, qa, docs.verify, deps.audit, package.build, test.fast, test.integration, test.phase3) -- exits 0
- Manual, against a real generated host (`mix phx.new host_app --database postgres --install`, `mix phx.gen.auth Accounts User users --live`, `mix lockspire.install`, real PostgreSQL): `step-03c-resolver`, `step-03d-app-tree`, and `step-03e-protected-route` each independently reach PASS; `mix run -e 'IO.puts("boot ok")'` succeeds with the full supervision tree wired; `mix phx.routes` lists `/api/walk/summary`

## Self-Check: PASSED

- FOUND: scripts/maintainer/adopter_path_walk.sh
- FOUND: test/lockspire/maintainer/adopter_walk_contract_test.exs
- FOUND: 98cfbbd
- FOUND: 4a2107a

---
*Phase: 126-adopter-path-walk-defect-ledger*
*Completed: 2026-07-29*
</content>
