---
phase: 126-adopter-path-walk-defect-ledger
plan: 06
subsystem: testing
tags: [bash, python, elixir, ecto, phoenix-liveview, jose, adopter-path, adopt-01, adopt-03, defect-ledger]

# Dependency graph
requires:
  - phase: 126-05
    provides: "the complete guide §1-§8 walk (skeleton through boot/drive/token-proof), its live 8 PASS / 6 FAIL RED run, and the provisional ADOPT-D01..D14 defect IDs recorded across plans 126-01 through 126-05"
provides:
  - "126-DEFECT-LEDGER.md: the committed, fully attributed, secret-free defect ledger -- 17 entries (ADOPT-D01..D11, D13..D16, D18, D19; D12 explicitly dropped as never-observed, D17 never assigned), every workaround claim reconciled against the harness's own LOCKSPIRE_WALK_WORKAROUND markers"
  - "test/lockspire/maintainer/defect_ledger_contract_test.exs: Lockspire.Maintainer.DefectLedgerContractTest -- criterion 4 (completeness) and criterion 5 (two-way marker<->ledger MapSet equality) enforcement, 9 tests"
  - "A stable, reproducible live walk result against a real generated host, real PostgreSQL, and a real booted Phoenix server: 19 PASS, 12 FAIL, RED -- up from plan 126-05's own live run (8 PASS, 6 FAIL), because this plan's own fixes let the walk reach every step for the first time"
  - "Four newly-surfaced real defects (ADOPT-D15, D16, D18, D19), each confirmed empirically and each with a harness-only workaround, never a fix in lib/priv/docs/examples"
affects: [127, 128, 129, 130]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-entry markdown ledger sections (### ADOPT-Dnn plus six **Field:** bullet lines) parsed via a non-greedy multiline regex with a lookahead boundary, rather than a markdown table -- chosen so long prose (underlying-error text, file:line citations) never has to fit in a table cell"
    - "Two-way MapSet reconciliation between a grep-scanned marker set (scripts/maintainer/*) and a parsed ledger workaround-ID set, asserted in both difference directions so neither an unmarked-but-ledgered claim nor a marked-but-unledgered workaround can pass"
    - "Multi-token source-field validation (splitting on ' and '/',' and checking each token against the six-value allowlist) to support genuinely joint attribution (e.g. 'installer and guide') without weakening the allowed-vocabulary gate to a substring check"

key-files:
  created:
    - .planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md
    - test/lockspire/maintainer/defect_ledger_contract_test.exs
  modified:
    - scripts/maintainer/adopter_path_walk.sh
    - scripts/maintainer/adopter_path_flow.py

key-decisions:
  - "ADOPT-D12 (reference demo shadows the consent route with its own controller) is deliberately dropped from the numbered ledger, not ledgered, because this walk never invokes examples/adoption_demo at all -- nothing about the demo's own routing was actually observed by this run, and the ledger's own prohibition forbids recording a defect the walk did not observe. The underlying fact remains real and is recorded in a 'Dropped from the seed list' section instead, pointed at RESEARCH for Phase 129."
  - "ADOPT-D17 was never assigned. The 'authorize handoff: missing interaction_id or return_to' symptom that blocked the walk mid-run turned out to be caused entirely by a harness-fixture bug (this plan's own known_scopes completion never included read:walk, the scope the walk itself invented for its protected-route proof) rather than a genuine Lockspire defect -- fixed inline inside the existing ADOPT-D04 workaround rather than minting a new ledger ID for a bug in this plan's own fixture."
  - "ADOPT-D06's evidence supersedes plan 126-05's own finding. 126-05 recorded 'two undocumented calls required' (generate_key/1 + publish_key/2) based on JWKS visibility alone. This plan's live run reached an actual token exchange for the first time and found generate_key/1 + publish_key/2 alone still fails to sign a token (:signing_key_not_found) -- publication and activation are separate lifecycle stages, and activate_key/2 is a third required call. Same ADOPT-D06 entry, refined evidence, not a new ID."
  - "Two harness-only bugs (not ledger defects) were found and fixed to get the walk running cleanly end to end: the step-03b-router-call/-wire mix phx.routes checks used a bare grep -F substring match that false-positived on compile-warning file paths containing the mount-path substring (masking ADOPT-D01's real, expected zero-routes outcome), and the migrations-path lookup in step-05-verify raced a full-app-boot mix run -e's own async Logger output against its own IO.puts, occasionally capturing a KeyCache warning instead of the real path. Both are documented in the ledger's own 'Harness-only correction' section rather than as ADOPT-D entries, since neither is adopter-facing."

requirements-completed: [ADOPT-01, ADOPT-03]

coverage:
  - id: D1
    description: "126-DEFECT-LEDGER.md exists, is non-empty, and parses into 17 entries, each carrying an ADOPT-D ID plus all six D-37 fields (walk step ID, symptom, underlying error, source, owning phase, workaround) with no field blank"
    requirement: "ADOPT-01"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/defect_ledger_contract_test.exs (9 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "grep -c 'ADOPT-D' .planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md -- 36 (well over the 10-entry floor)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every LOCKSPIRE_WALK_WORKAROUND marker across scripts/maintainer/adopter_path_walk.sh and scripts/maintainer/adopter_path_flow.py (14 unique IDs) has a matching ledger workaround entry, and every ledger workaround claim has a matching marker -- asserted as two separate MapSet.difference/2 checks, both empty"
    requirement: "ADOPT-03"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/defect_ledger_contract_test.exs: two-way reconciliation tests, both pass"
        status: pass
    human_judgment: false
  - id: D3
    description: "A real, live, unflagged mix adopter.walk run against a real generated host, real PostgreSQL, and a real booted Phoenix server reaches every one of its 8 guide-mapped steps and both not-walked accounting lines, ending 19 PASS / 12 FAIL RED, with the evidence tree preserved and the walk port free afterward"
    requirement: "ADOPT-01"
    verification:
      - kind: other
        ref: "Manual: mix adopter.walk (no flags) -- Summary: 19 PASS, 12 FAIL / Result: adopter path is RED; tmp/adopter-walk/host_app, server.log, and .walk/steps/ all present afterward; lsof -ti :4200 empty afterward"
        status: pass
      - kind: other
        ref: "Manual: mix adopter.walk --from-step 04 -- resumes from step-04-migrate without regenerating host_app (three steps report 'skipped (already done)'), ends 11 PASS, 0 FAIL GREEN"
        status: pass
    human_judgment: false
  - id: D4
    description: "No defect recorded in this ledger was fixed in this phase -- git diff --exit-code over lib/, priv/, docs/, and examples/ reports no change; every workaround lives entirely inside scripts/maintainer/"
    requirement: "ADOPT-03"
    verification:
      - kind: other
        ref: "git diff --exit-code -- lib/ priv/ docs/ examples/ -- exits 0, no output"
        status: pass
    human_judgment: false

# Metrics
duration: 70min
completed: 2026-07-29
status: complete
---

# Phase 126 Plan 06: Run the Walk & Author the Committed Defect Ledger Summary

**Ran `mix adopter.walk` end to end against a real generated Phoenix host, real PostgreSQL, and a real booted server -- correctly RED at 19 PASS / 12 FAIL -- and authored `126-DEFECT-LEDGER.md`, a 17-entry committed defect ledger mechanically reconciled against every `LOCKSPIRE_WALK_WORKAROUND` marker in the harness, surfacing four new real defects (ADOPT-D15/D16/D18/D19) that only a live run could find, all confirmed empirically and none fixed in `lib/`, `priv/`, `docs/`, or `examples/`.**

## Performance

- **Duration:** ~70 min
- **Completed:** 2026-07-29T02:23:32Z
- **Tasks:** 3 (Task 3 auto-approved under active auto-mode; see Checkpoint below)
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `test/lockspire/maintainer/defect_ledger_contract_test.exs` (`Lockspire.Maintainer.DefectLedgerContractTest`, 9 tests): a per-entry markdown parser (`### ADOPT-Dnn` sections, six `**Field:**` bullets each), completeness assertions (all six D-37 fields present and non-blank, allowed source vocabulary with multi-token joint-attribution support, allowed owning-phase vocabulary), two-way `MapSet.difference/2` reconciliation between every harness marker and every ledger workaround claim, secret-absence assertions (seeded password literal, bearer-token shape), and a self-check that the test file itself never contains the walk task's own mix-alias name as a literal substring (built at runtime instead, so the check cannot trip on its own search pattern).
- Ran `mix adopter.walk` with no flags against a freshly generated host repeatedly while chasing real failures to their root cause, landing on a final, stable, reproducible result: **19 PASS, 12 FAIL, RED**, up from plan 126-05's own live run (8 PASS, 6 FAIL) -- every additional step this plan reached is new evidence, not a regression.
- `126-DEFECT-LEDGER.md`: YAML front matter (verdict, PASS/FAIL counts, walk date, resolved Elixir/OTP/PostgreSQL/`phx_new` versions) followed by 17 per-entry prose sections (`ADOPT-D01` through `ADOPT-D11`, `D13` through `D16`, `D18`, `D19`), a "Dropped from the seed list" section explaining why `ADOPT-D12` is not ledgered, a "Not walked" section for guide §7/§8, and a "Harness-only correction" section documenting two script bugs that were not ledger defects.
- Four newly-surfaced, previously-unknown-to-this-phase defects, each confirmed against a real generated host and each with a harness-only workaround:
  - **ADOPT-D15**: a stock `mix phx.new --database postgres` host resolves `ecto_sql` to whatever Hex currently publishes as latest (observed `3.14.0`), which is incompatible with Lockspire's own `{:ecto_sql, "~> 3.13.5"}` pin (`mix.exs:47`) -- `mix deps.get` never re-resolves an already-locked transitive dependency on its own. Workaround: `mix deps.unlock ecto ecto_sql && mix deps.get`.
  - **ADOPT-D16**: the generated `authorized_apps_html/index.html.heex` page (from `priv/templates/lockspire.install/authorized_apps/index.html.heex:19`) nests an EEx tag inside a HEEx `{...}` attribute expression, which the resolved `phoenix_live_view 1.2.8` tokenizer rejects outright -- this blocked the generated host from compiling at all, before config/router/resolver wiring was ever exercised. Workaround: the generated host's own copy of the file is patched to use Elixir string interpolation (`#{consent.grant.id}`) instead.
  - **ADOPT-D18**: `Lockspire.Web.ConsentLive`'s account-resolver call always saw `current_scope` as unset -- even for an actually logged-in adopter, proven by the same response's root layout showing the user's own email in the nav bar -- because a bare `live "/consent/:interaction_id", ...` route outside any `live_session` never gets a LiveView-populated session assign the way an ordinary `Plug`-based controller route does. Workaround: the consent route is wrapped in its own `live_session` declaring `on_mount: [{HostAppWeb.UserAuth, :mount_current_scope}]`.
  - **ADOPT-D19**: `docs/protect-phoenix-api-routes.md`'s own documented "Access-token assigns contract" describes `conn.assigns.access_token` as exposing top-level `subject`/`scope`/`audience`/`expires_at`/`cnf` fields; the real `%Lockspire.AccessToken{}` struct (`lib/lockspire/access_token.ex:6-15`) has none of them -- only a `claims` map. A host-owned protected route wired exactly per the guide's own example crashed with `** (KeyError) key :subject not found` on the very first real request carrying a real, valid, issued access token. Workaround: the generated host's own controller reads `access_token.claims["sub"]` / `access_token.claims["scope"]` instead.
- `ADOPT-D06`'s evidence was refined, not replaced: plan 126-05 established "two undocumented calls required" (`generate_key/1` + `publish_key/2`) from JWKS visibility alone; this plan's live token exchange showed that publication and activation are separate lifecycle stages, and a third call (`activate_key/2`) is required before a minted key can actually sign a token -- `publish_key/2` alone left the token endpoint failing with `:signing_key_not_found`.
- Two harness-only bugs (not ledger defects) were found and fixed while getting the walk to run cleanly end to end, documented in the ledger's own "Harness-only correction" section: the `known_scopes` completion never included `read:walk` (the scope this harness's own protected-route proof invented), and `step-03b-router-call`/`step-03b-router-wire`'s `mix phx.routes` checks used a bare `grep -F` substring match that false-positived on compile-warning file paths containing the mount-path substring, masking `ADOPT-D01`'s real, expected zero-routes outcome.

## Task Commits

Each task was committed atomically:

1. **Task 1: Ledger contract test -- completeness and marker reconciliation** - `49c63f0` (test, RED against the absent ledger)
2. **Task 2: Run the walk and author the committed defect ledger** - `84c569a` (feat)

_Note: Task 1's test file received two small corrections during Task 2's own "run the ledger contract test and fix mismatches" step (a regex-flag bug that collapsed all 17 entries into one match, and a source-field validation change to support genuinely joint attribution like "installer and guide") -- both landed in Task 2's commit alongside the ledger itself, since that is exactly the reconciliation step the plan's own action text describes._

## Files Created/Modified

- `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md` - The committed defect ledger: 17 entries, a dropped-seed-entry note, a not-walked section, and a harness-only-correction section
- `test/lockspire/maintainer/defect_ledger_contract_test.exs` - `Lockspire.Maintainer.DefectLedgerContractTest`: 9 tests enforcing criteria 4 and 5
- `scripts/maintainer/adopter_path_walk.sh` - ADOPT-D15/D16/D18/D19 workarounds and markers; the `read:walk`/route-detection/migrations-path harness-only corrections
- `scripts/maintainer/adopter_path_flow.py` - the return_to consent-page assertion fixed from an incorrect 302-then-redirect expectation to the real 200-direct-render behavior (a driver bug found while chasing ADOPT-D18, not a ledger defect)

## Decisions Made

See `key-decisions` in frontmatter for the full list. The two most consequential:

- **ADOPT-D12 dropped, not ledgered.** This walk never invokes `examples/adoption_demo`, so nothing about the demo's own consent-route substitution was actually observed by this run. Recording it as a numbered defect would have violated the ledger's own "must not record what the walk did not observe" prohibition. The fact remains real and is pointed at RESEARCH for Phase 129 in a dedicated "Dropped from the seed list" section instead.
- **ADOPT-D17 never assigned.** The "missing interaction_id or return_to" failure that first looked like a new protocol defect turned out, on investigation, to be a scope-validation rejection caused entirely by this plan's own harness fixture omitting `read:walk` from its `known_scopes` completion -- fixed inline inside the existing `ADOPT-D04` entry rather than minting a new ID for a bug in this plan's own test fixture, not an adopter-facing gap.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two harness route-detection checks false-positived on compile-warning file paths**

- **Found during:** Task 2, while investigating why `step-03b-router-call` recorded PASS ("defines the Lockspire mount") despite the generated router helper being a known String-returning function that should define zero routes
- **Issue:** `grep -Fq "${MOUNT_PATH}"` over `mix phx.routes`'s full captured output (which also includes compile warnings) matched warning lines whose *file paths* contain the mount-path substring (e.g. `lib/host_app_web/controllers/lockspire_verification_html/index.html.heex` contains `/lockspire`), even when zero real routes were registered.
- **Fix:** Both checks now require an actual route-table row (`^[[:space:]]*(GET|POST|PUT|PATCH|DELETE|WS|\*)[[:space:]]+<mount>`), not any line mentioning the mount path.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** Re-ran against a real generated host -- `step-03b-router-call` now correctly records FAIL naming `ADOPT-D01`, and `step-03b-router-wire` still correctly records PASS once the real routes are wired.
- **Committed in:** `84c569a`

**2. [Rule 3 - Blocking] Migrations-path lookup raced its own IO.puts against async Logger output from the just-wired ADOPT-D05 supervision tree**

- **Found during:** Task 2, chasing an intermittent `step-05-verify` failure ("Could not find migrations directory") that only appeared after `step-03d-app-tree`'s workaround was active
- **Issue:** `mix run -e 'IO.puts(Application.app_dir(:lockspire, "priv/repo/migrations"))'` boots the full application (including Lockspire's own Oban/KeyCache supervision children, now wired by `ADOPT-D05`'s workaround), and that boot's own async Logger output occasionally landed after the `IO.puts` line -- `tail -n 1` then captured a KeyCache warning instead of the real path.
- **Fix:** `mix run --no-start -e ...` avoids booting the application entirely (`Application.app_dir/2` only needs the app compiled, not started), plus a `grep -E '/priv/repo/migrations$'` filter as defense in depth.
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** Re-ran three times in a row against a real generated host with no recurrence.
- **Committed in:** `84c569a`

**3. [Rule 1 - Bug] The flow driver's own consent-page assertion expected a 302 that the real system never sends**

- **Found during:** Task 2, chasing a real "interaction resume: expected HTTP 302, got 200" failure at `step-06b-flow` after ADOPT-D18's `live_session` fix let the consent page correctly recognize a logged-in adopter
- **Issue:** `scripts/maintainer/adopter_path_flow.py`'s driver assumed `return_to` was an intermediate resume endpoint that 302-redirects to the consent page. In reality, `AuthorizeController` wires `return_to` directly to `consent_path/1`, and `ConsentLive`'s own `ensure_ready_for_consent/2` transitions a `:pending_login` interaction to `:pending_consent` inline on that same request -- confirmed by reading `lib/lockspire/web/live/consent_live.ex:195-226`. The correct, real behavior is a direct 200 render, never a 302 hop.
- **Fix:** The driver now asserts 200 directly on the `return_to` GET and reads its body as the consent page, with no separate 302-then-redirect step.
- **Files modified:** `scripts/maintainer/adopter_path_flow.py`
- **Verification:** Re-ran against a real generated host -- `step-06b-flow` now correctly reaches "Approve access" and completes the flow.
- **Committed in:** `84c569a`

**4. [Rule 1 - Bug] A `/`-delimited sed substitution for `secret_key_base` intermittently broke when the generated secret itself contained a `/`**

- **Found during:** Task 2, a `sed: 1: "s/secret_key_base: ...": bad flag in substitute command` warning that appeared on roughly half of all runs (whenever `mix phx.gen.secret`'s base64 output happened to contain a `/`)
- **Issue:** `s/secret_key_base: "[^\"]*"/secret_key_base: "${secret}"/` used `/` as the sed delimiter, so a `/` inside the substituted secret broke the command's own delimiter parsing.
- **Fix:** Switched to `#` as the delimiter (never emitted by `mix phx.gen.secret`'s base64 output).
- **Files modified:** `scripts/maintainer/adopter_path_walk.sh`
- **Verification:** Confirmed clean across five consecutive fresh runs.
- **Committed in:** `84c569a`

---

**Total deviations:** 4 auto-fixed (2 false-positive-verification bugs, 1 race-condition bug, 1 incorrect-assertion bug, 1 delimiter bug -- five fixes across four numbered items since the route-detection fix touched two call sites). All five were caught only by actually running the walk repeatedly against a real generated host until it reached a stable, reproducible RED outcome -- exactly the kind of gap `bash -n`/`py_compile`/static contract tests cannot surface on their own, and exactly why this plan performed the live runs it did rather than authoring the ledger from source inspection alone.
**Impact on plan:** All five fixes live entirely inside this plan's own `files_modified` list (`scripts/maintainer/adopter_path_walk.sh`, `scripts/maintainer/adopter_path_flow.py`). None touches `lib/`, `priv/`, `docs/`, or `examples/` -- confirmed by `git diff --exit-code` over those directories reporting no change. No scope creep: every fix was necessary to let a later step reach its own stated PASS/FAIL criterion at all, or to correct a false PASS that was actively masking real defect evidence.

## Known Stubs

None. The ledger's every entry is confirmed against real command output, real error text, and real `file:line` citations from a live run; no entry is speculative or copied from RESEARCH without empirical confirmation (except the explicitly-noted `ADOPT-D13` residual-nondeterminism entry, which is a structural fact about the harness rather than something a single run observes, and the explicitly-dropped `ADOPT-D12`, noted as such rather than silently ledgered).

## Issues Encountered

None beyond the four items documented under Deviations above, all resolved during this plan's own execution.

## User Setup Required

None - PostgreSQL was already reachable locally with `CREATE DATABASE` privilege for the resolved walk user, satisfying Task 2's precondition without manual setup.

## Checkpoint

Task 3 (`checkpoint:human-verify`, `gate="blocking"`) was auto-approved under this run's active auto-mode (`workflow.auto_advance: true`), per this executor's own directive to continue autonomously where the plan's evidence allows and reserve returned checkpoints for cases that genuinely need a human. All of Task 3's own `<how-to-verify>` steps were performed directly rather than merely asserted:

1. Read the ledger: RED verdict, 19 PASS / 12 FAIL, 17 entries -- not thin.
2. Spot-checked three entries against their cited `file:line`s directly (`ADOPT-D01`'s `priv/templates/lockspire.install/router.ex:9`, `ADOPT-D16`'s `.../authorized_apps/index.html.heex:19`, and `ADOPT-D19`'s `lib/lockspire/access_token.ex:6-15` against `docs/protect-phoenix-api-routes.md:42-53`) -- all three citations are accurate and each symptom is something the live run actually produced (real error text, real HTTP status codes), not something inferred from reading source alone.
3. Confirmed no raw token, code, cookie, or password appears anywhere in the ledger (contract test assertions plus a manual read-through).
4. `mix test test/lockspire/maintainer/` -- 58 tests, 0 failures.
5. `mix adopter.walk --from-step 04` -- resumed correctly without regenerating the host app (11 PASS, 0 FAIL, GREEN for the remaining steps).
6. `mix ci` -- exited 0 (1285 + 287 + 72 tests across the full alias, 0 failures).

No entry was found thin, misattributed, or missing.

## Next Phase Readiness

- `.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md` is ready for Phases 127, 128, and 129 to read directly as their own scoping input: every entry names a real `file:line`, a source (installer, generated scaffolding, guide, or library), and an owning phase.
- Phase 127 (installer against a real host) has the clearest, largest slate: `ADOPT-D01`, `D02`, `D04`, `D07`, `D08`, `D09`, `D15`, `D16` are all installer-or-generated-scaffolding defects with real `file:line` citations inside `priv/templates/lockspire.install/` or `mix.exs`.
- Phase 128 (documented wiring truth) has `ADOPT-D03` (partial), `D05` (partial), `D06` (partial), `D10`, `D11`, `D14` (partial), `D18`, and `D19` -- the guide-side half of several jointly-attributed defects, plus two fully guide-attributed ones (`D18`, `D19`) that are both severe enough to crash an adopter's first real request if followed literally.
- Phase 129 (reference artifact alignment) should start from RESEARCH's own Pitfall 5/REF-01 finding (the dropped `ADOPT-D12` note) rather than this ledger, since this walk never exercises `examples/adoption_demo`.
- Phase 130 (adopter path guardrail) has `ADOPT-D13` (residual nondeterminism) as its own explicit candidate, plus the already-flagged `tmp/adopter-walk/` repo-hygiene-allowlist question from RESEARCH Open Question 3.
- No blockers.

## Verification

- `mix compile --warnings-as-errors` -- exits 0
- `mix test test/lockspire/maintainer/` -- 58 tests, 0 failures (9 new in `defect_ledger_contract_test.exs`, 40 unaffected in `adopter_walk_contract_test.exs`, 9 unaffected in `adopter_flow_driver_contract_test.exs`)
- `bash -n scripts/maintainer/adopter_path_walk.sh` -- exits 0
- `python3 -m py_compile scripts/maintainer/adopter_path_flow.py` -- exits 0
- `mix qa` (format / compile --warnings-as-errors / credo --strict / sobelow) -- clean
- `mix test.fast` -- 1285 tests, 0 failures (287 excluded)
- `mix ci` -- exits 0 (deps.get, qa, docs.verify, deps.audit, package.build, test.fast, test.integration, test.phase3 all green)
- `bash scripts/maintainer/repo_hygiene_check.sh --ci` -- 18 PASS, 0 WARN, 0 BLOCK
- `git diff --exit-code -- lib/ priv/ docs/ examples/` -- exits 0, no output
- Manual, against a real generated host (`mix phx.new`, `mix phx.gen.auth --live`, `mix lockspire.install`, real PostgreSQL): `mix adopter.walk` (no flags) -- `Summary: 19 PASS, 12 FAIL` / `Result: adopter path is RED`; evidence tree (`tmp/adopter-walk/host_app/`, `server.log`, `.walk/steps/`) preserved afterward; `lsof -ti :4200` empty afterward (port free); `mix adopter.walk --from-step 04` resumes correctly without regenerating `host_app`, ending `11 PASS, 0 FAIL` GREEN for the remaining steps

## Self-Check: PASSED

- FOUND: .planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md
- FOUND: test/lockspire/maintainer/defect_ledger_contract_test.exs
- FOUND: 49c63f0
- FOUND: 84c569a

---
*Phase: 126-adopter-path-walk-defect-ledger*
*Completed: 2026-07-29*
