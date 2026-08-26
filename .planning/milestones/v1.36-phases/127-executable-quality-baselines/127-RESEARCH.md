# Phase 127 Research: Executable Quality Baselines

**Discovery level:** 1 — quick verification against repository configuration and locally installed tool documentation.

## Current Evidence

- `.credo.exs` includes `lib/` and `test/`, but relies on Credo's 5,000 ms default parse timeout. Credo represents timed-out files separately and prints `Some source files were not parsed in the time allotted`; that warning does not by itself make a strict run fail. A local run currently parsed 406 files with no issues, so the gate must protect slower CI runners as well as the current machine.
- A fresh `MIX_ENV=test mix test --cover` run on 2026-08-26 completed the non-integration suite at **73.11%**. Mix's built-in coverage summary defaults to a 90% threshold and failed only because no project threshold is configured. The approved rounded-down repository floor is therefore **73%**.
- `.github/workflows/ci.yml` already has a minimum Elixir 1.18.4 / OTP 27 compatibility job, but its database service is PostgreSQL 16. That existing lane is the narrowest place to exercise the declared PostgreSQL 14 floor.
- The root dependency ranges permit Phoenix 1.8.5 and LiveView 1.1.28, while the root lock resolves Phoenix 1.8.9 and LiveView 1.2.8. A separate committed path-dependency fixture is required to prove the lower pair without downgrading the maintainer lock.
- Phase 126 made PostgreSQL service references immutable and lock verification non-mutating. Phase 127 must preserve both properties when adding the PostgreSQL 14 digest and the fixture lockfile.

## Implementation Guidance

1. Set Credo `parse_timeout: 30_000`, route `mix qa` through a repo-owned wrapper, preserve Credo's exit code, and separately fail when the timed-out-source warning appears.
2. Configure Mix's built-in `test_coverage` summary threshold at 73, run the existing fast suite with `--cover` in its required CI step, and do not add exclusions or an external coverage package.
3. Change only the minimum-supported compatibility job to an immutable PostgreSQL 14 service image; current-version, integration, adoption-demo, and conformance lanes stay on their current PostgreSQL version.
4. Commit a small Mix fixture with exact Phoenix `1.8.5` and LiveView `1.1.28` requirements, a path dependency on Lockspire, a lockfile, and source that compiles a Phoenix router mount plus a LiveView module. Compile it in the minimum-supported CI job.

## Source Coverage Audit

| Source | ID | Feature or constraint | Plan | Status |
|--------|----|-----------------------|------|--------|
| GOAL | — | Quality and compatibility claims are measured in required CI lanes | 127-01, 127-02, 127-03 | COVERED |
| REQ | STATIC-01 | Credo analyzes every intended source file with no timeout skips | 127-01 | COVERED |
| REQ | COVER-01 | Required CI enforces the measured built-in ExUnit coverage floor | 127-03 | COVERED |
| REQ | COMPAT-01 | Minimum BEAM lane exercises PostgreSQL 14 | 127-02 | COVERED |
| REQ | COMPAT-02 | Committed Phoenix 1.8.5 / LiveView 1.1.28 fixture compiles | 127-02 | COVERED |
| RESEARCH | — | Preserve Phase 126 immutable service references and non-mutating lock checks | 127-02 | COVERED |
| RESEARCH | — | Preserve current dependency/public runtime behavior | 127-01, 127-02, 127-03 | COVERED |
| CONTEXT | — | No phase-specific CONTEXT.md decisions exist | — | N/A |

## Package Legitimacy Audit

No new npm, pip, or cargo package is introduced. The compatibility fixture resolves the same Hex dependencies already declared by Lockspire, at the explicitly supported Phoenix and LiveView versions.
