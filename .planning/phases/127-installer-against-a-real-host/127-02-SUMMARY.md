---
phase: 127-installer-against-a-real-host
plan: 02
subsystem: dependencies
tags: [ecto, ecto_sql, mix.lock, adopter-path, hex.pm]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01: priv/test_fixtures/phx_new_host/ real phx.new host snapshot and install-manifest version fix, used elsewhere in the phase but not consumed by this dependency-only plan"
provides:
  - "mix.exs ecto_sql requirement widened from a patch pin (~> 3.13.5) to an explicit range (>= 3.13.5 and < 4.0.0) with an inline rationale comment"
  - "Committed mix.lock resolving ecto_sql 3.14.0 and ecto 3.14.1 against the widened range, proven green through the full mix ci lane"
  - "AGENTS.md Technology Stack Ecto SQL line updated to state the supported range"
affects: [dependency-resolution, adopter-first-deps-get, ci]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rationale-comment-above-dependency house style (three #-prefixed lines) now applied to a second entry (ecto_sql), matching the existing phoenix_live_view precedent"

key-files:
  created: []
  modified:
    - mix.exs
    - mix.lock
    - AGENTS.md

key-decisions:
  - "Accepted the resolver's natural pick of ecto 3.14.1 (not the plan-authored target of ecto 3.14.0) after mix deps.update ecto ecto_sql. ecto_sql 3.14.0 requires ecto ~> 3.14.0, and hex.pm's ecto 3.14.1 (published 2026-07-09 by josevalim, one of the five listed package owners, not retired) satisfies that constraint and is what any stock phx.new host generated today would also resolve. Forcing an artificial downgrade to 3.14.0 via a transitive-dependency override would fight the resolver, add a permanent mix.exs override not requested by the plan, and produce a lock that no longer matches what a real adopter host actually gets -- working against ADOPT-D15's underlying goal. Verified via the hex.pm packages API directly (same authoritative-source method RESEARCH.md's Package Legitimacy Audit used for 3.14.0)."
  - "Deliberately ran the full mix ci lane (qa, docs.verify, deps.audit, package.build, test.fast, test.integration, test.phase3) for Task 2 instead of a fast targeted check, exceeding 127-VALIDATION.md's 30-second quick-lane feedback-latency target. This is the plan's explicit, pre-approved deviation: D-23 requires the range to land 'together with one CI run that actually resolves 3.14', which only the full lane can prove."

requirements-completed: [INSTALL-01]

coverage:
  - id: D1
    description: "ecto_sql widened from a patch pin to an explicit range (>= 3.13.5 and < 4.0.0) with a house-style rationale comment, so a stock phx.new --database postgres host's already-locked ecto_sql no longer breaks an adopter's first mix deps.get"
    requirement: "INSTALL-01"
    verification:
      - kind: other
        ref: "mix compile --warnings-as-errors (exit 0); grep -c '{:ecto_sql, \"~> 3.13.5\"}' mix.exs == 0; grep -c 'Ecto SQL `3.13.5`' AGENTS.md == 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "ecto and ecto_sql resolved and committed at 3.14.x in mix.lock, with the full mix ci lane green against that resolution"
    requirement: "INSTALL-01"
    verification:
      - kind: other
        ref: "mix ci (exit 0): mix qa, mix docs.verify, mix deps.audit (no advisories), mix package.build, mix test.fast (1285 tests, 0 failures), mix test.integration (290 tests, 0 failures), mix test.phase3 (72 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "mix deps.get --check-locked (exit 0); git diff --name-only for Task 2 lists only mix.lock"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 02: ecto_sql Requirement Widened To A Range Summary

**`ecto_sql` moved from a patch-pinned `~> 3.13.5` to an explicit `>= 3.13.5 and < 4.0.0` range with a rationale comment, resolving and committing `ecto_sql 3.14.0` / `ecto 3.14.1` in `mix.lock` against a fully green `mix ci` run, closing ADOPT-D15.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-29T13:08:38Z
- **Tasks:** 2 completed
- **Files modified:** 3 (mix.exs, mix.lock, AGENTS.md)

## Accomplishments

- Closed ADOPT-D15: a stock `mix phx.new --database postgres` host locks the current `ecto_sql`, and Lockspire's old `{:ecto_sql, "~> 3.13.5"}` patch pin made an adopter's very first `mix deps.get` fail. The requirement is now `{:ecto_sql, ">= 3.13.5 and < 4.0.0"}`, with the `>= 3.13.5` floor preserved deliberately since it carries the PostgreSQL 18 constraint-mapping fix.
- Added a three-line `#`-prefixed rationale comment above the `ecto_sql` dependency, matching the house style already used for `phoenix_live_view` three lines earlier.
- Updated `AGENTS.md`'s Technology Stack `Ecto SQL` line from a stale `3.13.5` pin to the supported range, so the agent guide stops asserting a constraint the build no longer enforces.
- Ran `mix deps.update ecto ecto_sql` explicitly (widening the requirement alone does not move an already-locked transitive dependency): `ecto_sql` moved `3.13.5 -> 3.14.0`, `ecto` moved `3.13.6 -> 3.14.1`. `decimal` and `db_connection` were already satisfied by the committed lock and did not move, matching the plan's prediction; `git diff --name-only` for Task 2 confirms only `mix.lock` changed.
- Grepped `lib/lockspire` for `Repo` calls passing query-like keyword options (`where:`, `select:`, `order_by:`, `preload:`, `limit:`) directly to `Repo` functions -- Ecto 3.14's one real behavior-change entry (raising on that previously-ignored mistake). None found, so no code change was needed for that risk.
- Ran the full `mix ci` lane against the new resolution and confirmed it green: `qa` (format, compile --warnings-as-errors, credo --strict "found no issues", sobelow), `docs.verify`, `deps.audit` ("No retired or security advisory packages found", "No vulnerabilities found."), `package.build` (`Building lockspire 1.4.0`), `test.fast` (1285 tests, 0 failures), `test.integration` (290 tests, 0 failures), `test.phase3` (72 tests, 0 failures).

## Task Commits

1. **Task 1: Widen the ecto_sql requirement to an explicit range with rationale** - `b2a4fdf` (feat)
2. **Task 2: Resolve and commit ecto/ecto_sql 3.14.0 and prove the suite against it** - `558139a` (feat)

## Files Created/Modified

- `mix.exs` - `ecto_sql` requirement widened to `">= 3.13.5 and < 4.0.0"` with a three-line rationale comment in the `phoenix_live_view` house style
- `mix.lock` - `ecto_sql` resolved and committed at `3.14.0`; `ecto` resolved and committed at `3.14.1`
- `AGENTS.md` - `Ecto SQL` Technology Stack line now reads `` `>= 3.13.5 and < 4.0.0` `` instead of the stale `3.13.5` pin

## Decisions Made

- Accepted `ecto 3.14.1` (the resolver's natural pick under `ecto_sql 3.14.0`'s `ecto ~> 3.14.0` requirement) rather than forcing exactly `3.14.0` via a transitive override. See `key-decisions` in frontmatter for the full rationale and the hex.pm legitimacy verification performed for `3.14.1`.
- Ran the full `mix ci` lane for Task 2 rather than a fast targeted verify, as a deliberate, plan-mandated exception to `127-VALIDATION.md`'s 30-second quick-lane target -- see `key-decisions` in frontmatter.

## Deviations from Plan

### Auto-fixed Issues

None in the Rule 1-3 sense -- no bug, missing functionality, or blocking issue was found and fixed inline.

### Other Deviations

**1. [Version substitution, deliberate] `ecto` resolved to `3.14.1`, not the plan's stated `3.14.0` target**
- **Found during:** Task 2, immediately after `mix deps.update ecto ecto_sql`
- **Issue:** The plan's acceptance criteria and the phase threat model's Package Legitimacy Audit (T-127-SC) named `ecto 3.14.0` specifically, matching `127-RESEARCH.md`'s audit date. By execution time, hex.pm had published `ecto 3.14.1` (2026-07-09), which also satisfies `ecto_sql 3.14.0`'s `ecto ~> 3.14.0` requirement, so the resolver picked it as the latest matching version.
- **Resolution:** Verified `ecto 3.14.1` directly against the hex.pm packages API (same authoritative-source method the original audit used): published by `josevalim`, one of the five listed package owners (`ericmj`, `josevalim`, `michalmuskala`, `wojtekmach`, `greg-rychlewski`), not retired. Accepted the resolved version rather than forcing a downgrade -- see `key-decisions` in frontmatter for the full rationale.
- **Files affected:** `mix.lock`
- **Verification:** `mix ci` green against the resolved `ecto 3.14.1` / `ecto_sql 3.14.0` pair (see Accomplishments); `git diff --name-only` confirms no other dependency-manifest file changed alongside it.
- **Committed in:** `558139a` (Task 2 commit)

---

**Total deviations:** 1 (deliberate version substitution, not a Rule 1-4 auto-fix)
**Impact on plan:** No scope creep. The substitution keeps the lock aligned with what a real adopter host resolves today, which is the actual goal ADOPT-D15 and D-23 are protecting.

## Issues Encountered

None beyond the version-substitution deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ADOPT-D15 is closed: adding `{:lockspire, path: ...}` to a stock `phx.new --database postgres` host no longer produces a resolver conflict on `ecto_sql`.
- `priv/test_fixtures/phx_new_host/` (from 127-01) and this plan's widened `ecto_sql` range are both now in place for later plans in this phase that exercise the installer against the real host fixture.
- No blockers. `mix ci` is green, `git status --porcelain` is clean apart from the committed changes, and `mix deps.get --check-locked` passes.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 3 modified files (`mix.exs`, `mix.lock`, `AGENTS.md`) and this SUMMARY confirmed present on disk; both task commits (`b2a4fdf`, `558139a`) confirmed in `git log --oneline --all`.
