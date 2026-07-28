---
phase: 126-adopter-path-walk-defect-ledger
plan: 01
subsystem: testing
tags: [bash, phoenix, phx.new, phx.gen.auth, mix-alias, postgres, adopter-path]

# Dependency graph
requires: []
provides:
  - "scripts/maintainer/adopter_path_walk.sh: end-to-end mix adopter.walk harness skeleton (flags, PREREQUISITE preflight, PASS/FAIL accumulator, .walk/steps resume markers, Summary/Result verdict)"
  - "step-00b-phx-new/step-00c-gen-auth/step-00d-seed-user: isolated phx_new 1.8.9 install, stock Phoenix host generation, phx.gen.auth --live, and a confirmed password-capable walker@adopter.test user"
  - "LOCKSPIRE_WALK_EMAIL / LOCKSPIRE_WALK_PASSWORD cross-plan credential contract"
affects: [126-02, 126-03, 126-04, 126-05, 126-06, 127, 128, 129, 130]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Maintainer shell harness following repo_hygiene_check.sh's usage()/flag-parse/record_result/RESULTS[]/Summary shape, adapted to PASS/FAIL-only plus a distinct PREREQUISITE exit path"
    - ".walk/steps/<step-id>.done resume markers with should_run/mark_done/step_done gating re-execution"
    - "Isolated MIX_ARCHIVES under .harness/archives so mix archive.install never touches the maintainer's global phx_new"

key-files:
  created:
    - scripts/maintainer/adopter_path_walk.sh
    - test/lockspire/maintainer/adopter_walk_contract_test.exs
  modified:
    - mix.exs
    - .gitignore

key-decisions:
  - "Deferred the phx_new 1.8.9 pin assertion out of Task 1's contract test (only MIX_ARCHIVES export was testable at that point) and added it in Task 2's extension, matching the plan's own split acceptance criteria between the two tasks"
  - "phx.new 1.8.9's dev.exs template ships no explicit http port key (http: [ip: {127, 0, 0, 1}]) rather than the port: 4000 literal older Phoenix versions emitted -- patched by injecting a port key into that line instead of replacing a non-existent literal"
  - "Folded the host app's own mix ecto.create/mix ecto.migrate into step-00d-seed-user (undocumented as a separate step ID) since seeding a phx.gen.auth user requires the generator's own users/users_tokens migrations to be applied first, and this is distinct from -- and precedes -- guide section 4's later Lockspire migration step"

requirements-completed: [ADOPT-01, ADOPT-02, ADOPT-03]

coverage:
  - id: D1
    description: "One command (mix adopter.walk) parses --workdir/--from-step/--keep/--force/--port/--preflight-only, hard-fails through a distinct PREREQUISITE path (exit 2) before any step is recorded, and ends in a single Summary: N PASS, M FAIL plus Result: adopter path is RED|GREEN verdict"
    requirement: "ADOPT-01"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs (15 tests)"
        status: pass
      - kind: other
        ref: "bash scripts/maintainer/adopter_path_walk.sh --preflight-only (real run against local Postgres) -> Summary: 4 PASS, 0 FAIL / Result: adopter path is GREEN"
        status: pass
      - kind: other
        ref: "mix adopter.walk --preflight-only via the real mix.exs alias"
        status: pass
    human_judgment: false
  - id: D2
    description: "The walk generates a stock mix phx.new host_app --database postgres --install app (Ecto/HTML/LiveView/mailer/assets kept), pins phx_new to 1.8.9 in an isolated archive directory, applies phx.gen.auth Accounts User users --live, and seeds a confirmed password-capable walker@adopter.test user -- with re-runs skipping completed steps via resume markers and the maintainer's global phx_new archive left untouched"
    requirement: "ADOPT-02"
    verification:
      - kind: integration
        ref: "real end-to-end run: bash scripts/maintainer/adopter_path_walk.sh -> Summary: 7 PASS, 0 FAIL / Result: adopter path is GREEN; psql confirms walker@adopter.test has confirmed_at set and hashed_password present"
        status: pass
      - kind: integration
        ref: "second real run of the same command -> step-00b/00c/00d all report 'skipped (already done)' without regenerating tmp/adopter-walk/host_app"
        status: pass
      - kind: other
        ref: "env -u MIX_ARCHIVES mix phx.new --version outside the harness still reports Phoenix installer v1.8.9 (pre-existing global archive), confirming .harness/archives isolation did not overwrite it"
        status: pass
    human_judgment: false
  - id: D3
    description: "Per-step resume/attribution: .walk/steps/<step-id>.done markers plus --from-step/--force flags let a maintainer resume without regenerating completed steps (ADOPT-03 skeleton; full step-01..08 attribution lands in later plans in this phase)"
    requirement: "ADOPT-03"
    verification:
      - kind: unit
        ref: "test/lockspire/maintainer/adopter_walk_contract_test.exs: 'walk script implements the ADOPT-03 resume contract'"
        status: pass
      - kind: integration
        ref: "real second run: step-00b/00c/00d recorded as PASS ... skipped (already done)"
        status: pass
    human_judgment: false

# Metrics
duration: 23min
completed: 2026-07-28
status: complete
---

# Phase 126 Plan 01: End-to-End Walk Skeleton & Clean-Room Generation Summary

**A single `mix adopter.walk` command now generates a stock, isolated Phoenix 1.8.9 host app with `phx.gen.auth --live` and a confirmed password-capable user, recording every step in a resumable, PASS/FAIL-attributed report ending in one pass/fail verdict.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-07-28T23:07:13Z
- **Completed:** 2026-07-28T23:30:14Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `scripts/maintainer/adopter_path_walk.sh`: flag parsing (`--workdir`, `--from-step`, `--keep`, `--force`, `--port`, `--preflight-only`, `-h`), a `fail_prerequisite` PREREQUISITE path (exit 2) that runs the required-command check (`git`, `mix`, `python3`, `cc`, `make`) in a `set -e` subshell, `pg_isready` reachability, a `CREATE DATABASE` capability probe, and a bash `/dev/tcp` port-bound check -- all before any step ever reaches the ledger
- A PASS/FAIL `record_result`/`RESULTS[]` accumulator, `.walk/steps/<step-id>.done` resume markers via `mark_done`/`step_done`/`should_run`, and a `Summary: N PASS, M FAIL` / `Result: adopter path is RED|GREEN` verdict, with the only `trap` killing just the captured server pid (never `rm -rf`)
- `mix.exs` `adopter.walk` alias wired and deliberately absent from `ci:`; `.gitignore` gained `/.harness/`
- `step-00b-phx-new`: isolated `MIX_ARCHIVES="$REPO_ROOT/.harness/archives"`, pinned `mix archive.install hex phx_new 1.8.9 --force`, version-asserted against the literal `Phoenix installer v1.8.9`, then `mix phx.new host_app --database postgres --install` (no capability-stripping flags), followed by a port/DB-credential patch of `config/dev.exs` and a freshly generated `secret_key_base`
- `step-00c-gen-auth`: `mix phx.gen.auth Accounts User users --live` plus `mix deps.get`
- `step-00d-seed-user`: the host's own `mix ecto.create`/`mix ecto.migrate`, then `register_user` -> `build_email_token` -> `login_user_by_magic_link` -> `update_user_password` in the exact required order, producing a confirmed, password-capable `walker@adopter.test` user
- Verified against a real Postgres instance end-to-end twice: first run generated everything and passed 7/7 steps; second run skipped all three generation steps via resume markers without regenerating

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end `mix adopter.walk` -- one command, one attributed report, one verdict** - `f774d5e` (test, RED), `0a9553c` (feat, GREEN)
2. **Task 2: Clean-room generation -- stock Phoenix host, `phx.gen.auth` seam, password-capable user** - `82a4783` (feat)

_Note: Task 1 is `tdd="true"` and `type="tracer"` -- RED test committed first, then the implementation. The tracer's own `<verify>` was re-run end-to-end and confirmed passing before Task 2 began, per the tracer feedback gate._

## Files Created/Modified
- `scripts/maintainer/adopter_path_walk.sh` - The walk harness: flags, preflight, accumulator, resume machinery, clean-room generation, and verdict
- `test/lockspire/maintainer/adopter_walk_contract_test.exs` - `Lockspire.Maintainer.AdopterWalkContractTest`: 15 ADOPT-01/02/03 harness-property assertions over the script and `mix.exs`
- `mix.exs` - Added the `"adopter.walk": ["cmd bash scripts/maintainer/adopter_path_walk.sh"]` alias, kept out of `ci:`
- `.gitignore` - Added `/.harness/`

## Decisions Made
- Deferred the `phx_new 1.8.9` pin assertion out of Task 1's contract test since Task 1's own acceptance criteria don't grep for it (only `MIX_ARCHIVES`); added it correctly in Task 2's test extension alongside the actual pin implementation. This matches the plan's split acceptance criteria across the two tasks exactly.
- `phx.new` 1.8.9's generated `config/dev.exs` no longer emits an explicit `port: 4000` literal (just `http: [ip: {127, 0, 0, 1}]`), so the port patch injects a `port:` key into that line rather than replacing a literal that doesn't exist in this Phoenix version. Confirmed empirically against a real generated app.
- Folded the host app's own `mix ecto.create`/`mix ecto.migrate` into `step-00d-seed-user` rather than a separate step ID, since seeding requires the generator's own `users`/`users_tokens` migrations and this precedes -- and is distinct from -- guide section 4's later Lockspire migration step landed in a subsequent plan. Within "Claude's Discretion" per RESEARCH.md (pre-guide step boundaries are not part of the D-16 guide-section mapping).

## Deviations from Plan

None - plan executed exactly as written. The pin-assertion test placement and the dev.exs port-key adjustment above are implementation-detail corrections discovered while making Task 1's and Task 2's own acceptance criteria pass, not deviations from the plan's required behavior.

## Issues Encountered
- `mix local.rebar --force --if-missing` (as drafted from the plan's `phx_new` mechanics text) fails: `mix local.rebar` does not accept `--if-missing` (only `mix local.hex` does). Fixed to `mix local.rebar --force` before running the script for real; caught immediately by manual `mix help local.rebar` verification rather than a failed harness run.
- The generated `config/dev.exs` template for Phoenix 1.8.9 omits the `port: 4000` literal the plan's `sed` pattern assumed; fixed by patching the `http: [ip: {127, 0, 0, 1}]` line to inject a port key instead. Confirmed via a real `mix phx.new` run before finalizing the harness.

## User Setup Required

None - no external service configuration required. PostgreSQL was already reachable locally with `CREATE DATABASE` privilege for the resolved walk user, satisfying Task 1's and Task 2's preconditions without any manual setup.

## Next Phase Readiness
- The walk harness skeleton, resume machinery, and clean-room generation (through a confirmed, password-capable seeded user) are proven end-to-end against a real Postgres instance and are ready for plan 126-02 to add the guide-mapped `step-01`..`step-08` sequence (installer wiring, migration, verify, client registration, flow, token proof) on top of this foundation.
- `LOCKSPIRE_WALK_EMAIL`/`LOCKSPIRE_WALK_PASSWORD` are exported by the script exactly as the cross-plan contract requires, ready for plan 126-03's flow driver and plan 126-06's secret-absence ledger assertion to consume unchanged.
- No blockers. The one flagged assumption in the plan (RESEARCH A1: `--install` suppresses the "Fetch and install dependencies?" prompt non-interactively) was confirmed empirically -- the real `mix phx.new host_app --database postgres --install` run completed with no interactive prompt and no `yes` piping needed.

## Self-Check: PASSED

- FOUND: scripts/maintainer/adopter_path_walk.sh
- FOUND: test/lockspire/maintainer/adopter_walk_contract_test.exs
- FOUND: .planning/phases/126-adopter-path-walk-defect-ledger/126-01-SUMMARY.md
- FOUND: f774d5e, 0a9553c, 82a4783, 7f6aad6

---
*Phase: 126-adopter-path-walk-defect-ledger*
*Completed: 2026-07-28*
