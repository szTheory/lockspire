---
phase: 98-plug-hardening
plan: 02
subsystem: auth
tags: [oauth, oidc, jwt, rfc-6750, rfc-9068, plug, verify_token, enforce-audience, contract-test, lockspire]

# Dependency graph
requires:
  - phase: 97-contract-docs-first
    provides: Four-site canonical-pipeline content-hash invariant and extract_canonical_pipeline!/2 helper
  - phase: 98-plug-hardening
    plan: 01
    provides: Structured invalid-token error map taxonomy that Plan 02 builds on at the init/1 boundary (no overlap; Plan 01 is runtime, Plan 02 is compile/boot)
provides:
  - New `enforce_audience: [type: :boolean, default: false]` schema key on `Lockspire.Plug.VerifyToken` NimbleOptions schema
  - New `init/1` ArgumentError raise: "expected :audience or :audiences when :enforce_audience is true (D-07)" fires at compile/boot when `enforce_audience: true` is set AND neither `:audience` nor `:audiences` is supplied
  - `enforce_audience: true` byte-identical across all four RECIPE-01 canonical-pipeline files (docs/protect-phoenix-api-routes.md, examples/adoption_demo router, priv/templates install router heredoc, scripts/demo/adoption_smoke.py canonical comment block)
  - New `release_readiness_contract_test` clause "canonical lockspire_protected_api pipeline declares a non-empty audience: across all four RECIPE-01 sites (D-07)" — loops the same four (path, kind) list, reuses `extract_canonical_pipeline!/2`, asserts `Lockspire.Plug.VerifyToken,[^\n]*\baudience:\s*"([^"]+)"` matches with `String.length(captured) > 0`; on miss flunks naming `Path.relative_to_cwd(path)` of the offender
affects: [99-signer-extraction, 100-sender-constraint-e2e, 101-adoption-demo-rewire, 102-generated-host-scaffolding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "init/1 invariant raise placement: after NimbleOptions.validate!/2 (so boolean type-check has run), after the existing :audience/:audiences mutual-exclusion raise (preserves precedent order), before the four pipeline-style non-empty validators"
    - "Four-file canonical-pipeline contract clauses sit adjacent in release_readiness_contract_test.exs so the relationship between the byte-identical clause (line 745) and the new audience-substring clause (line 761) is visually obvious"
    - "Test failure messages from contract clauses always name the specific file via Path.relative_to_cwd/1 so the maintainer is pointed at exactly which canonical site drifted"

key-files:
  created: []
  modified:
    - lib/lockspire/plug/verify_token.ex
    - test/lockspire/plug/verify_token_test.exs
    - test/lockspire/release_readiness_contract_test.exs
    - docs/protect-phoenix-api-routes.md
    - examples/adoption_demo/lib/adoption_demo_web/router.ex
    - priv/templates/lockspire.install/router.ex
    - scripts/demo/adoption_smoke.py

key-decisions:
  - "Exact ArgumentError message wording: \"expected :audience or :audiences when :enforce_audience is true (D-07)\" — names both option keys and the D-07 anchor so a maintainer hitting the raise can grep CONTEXT.md directly"
  - "Existing strict-shape pattern-match test at lines 84-88 was restructured to use Keyword.fetch! assertions (option b in the plan) rather than expanding the strict `=` shape — NimbleOptions does NOT actually return defaulted keys in schema order in this version (1.1.1), so the plan's note about ordering was inaccurate. Discovered during Task 1 RED→GREEN; the Keyword.fetch! form is also more robust against future NimbleOptions internal-ordering changes"
  - "Placed the new init/1 raise immediately AFTER the existing :audience/:audiences mutual-exclusion raise rather than weaving it into the validation pipeline — both are option-invariant raises, both sit at the same conceptual layer, adjacent placement makes the precedent obvious"
  - "Used `Keyword.get(opts, :enforce_audience, false)` rather than `Keyword.fetch!/2` even though NimbleOptions defaults the key — defense-in-depth against any future schema-default change accidentally dropping the boolean"
  - "Reused `extract_canonical_pipeline!/2` (line 140-157) with no parallel extraction path — the existing four-file content-hash clause and the new D-07 audience-substring clause share one extraction surface, so a future regex/marker change in the helper updates both clauses consistently"

patterns-established:
  - "Compile/boot-time option-invariant raises in init/1 use the message-anchor pattern: include both the violating option key AND the missing required keys (\"expected :audience or :audiences when :enforce_audience is true\") so the raise is greppable from the test's `~r/.../`"
  - "When a new keyword pair is added to a canonical-pipeline declaration, it MUST land in all four RECIPE-01 sites in the same byte position so the existing content-hash test stays green; the new clause's failure-path verification (delete from one file, observe specific-file failure, restore) becomes the standard quick-check"

requirements-completed: [VERIFIER-06]

# Metrics
duration: ~7min
completed: 2026-05-27
---

# Phase 98 Plan 02: enforce_audience: Option + Four-Site Contract Test Summary

**Add `enforce_audience: [type: :boolean, default: false]` to `Lockspire.Plug.VerifyToken`'s NimbleOptions schema with a new `init/1` raise when `enforce_audience: true` is set and neither `:audience` nor `:audiences` is supplied; propagate `enforce_audience: true` byte-identically across all four RECIPE-01 canonical-pipeline sites; and add a new `release_readiness_contract_test` clause that asserts each canonical block carries a non-empty `audience: "..."` on its `Lockspire.Plug.VerifyToken,` declaration. Closes VERIFIER-06 with both OR-clause mechanisms shipped for defense-in-depth.**

## Performance

- **Duration:** ~7 min
- **Tasks:** 3 (all `type="auto" tdd="true"`)
- **Files modified:** 7
- **Tests:** verify_token_test.exs 31 tests 0 failures; release_readiness_contract_test.exs 30 tests 0 failures

## Accomplishments

- Added `enforce_audience: [type: :boolean, required: false, default: false, doc: ...]` as the fourth schema key in `@options_schema` (verify_token.ex:37-44), bringing schema cardinality to exactly four keys (scopes, audience, audiences, enforce_audience) as required by Task 1 done criterion.
- Added new init/1 raise at verify_token.ex:54-58: `if Keyword.get(opts, :enforce_audience, false) and not Keyword.has_key?(opts, :audience) and not Keyword.has_key?(opts, :audiences) do raise ArgumentError, "expected :audience or :audiences when :enforce_audience is true (D-07)"`. Placed immediately after the existing `:audience`/`:audiences` mutual-exclusion raise (lines 50-52) per the precedent at the same conceptual layer.
- Six new init/1 test cases in verify_token_test.exs covering all D-07 behavior axes: raise on `enforce_audience: true` alone, no-raise on `+audience`, no-raise on `+audiences`, no-raise on `enforce_audience: false`, no-raise on `init([])`, default-false when audience alone is supplied.
- Restructured the existing init/1 shape-preservation test (lines 84-94) from strict `=` pattern-match to `Keyword.fetch!` assertions — the strict form would have failed because NimbleOptions 1.1.1 prepends defaulted keys to the head of the returned Keyword list (not in schema order as the plan's interfaces note assumed).
- Added `, enforce_audience: true` to the `Lockspire.Plug.VerifyToken,` declaration line in all four RECIPE-01 canonical-pipeline files in the same byte position so the existing four-file content-hash test (release_readiness_contract_test.exs:745-759) stays byte-identical.
- Added new contract-test clause "canonical lockspire_protected_api pipeline declares a non-empty audience: across all four RECIPE-01 sites (D-07)" (release_readiness_contract_test.exs:761) immediately adjacent to the byte-identical clause, reusing the same four `(path, kind)` files list and the same `extract_canonical_pipeline!/2` helper.
- Manually verified the new clause's failure path by deleting `audience: "billing-api"` from `examples/adoption_demo/lib/adoption_demo_web/router.ex`, running the suite, and observing both the byte-identical clause AND the new D-07 clause fail naming `examples/adoption_demo/lib/adoption_demo_web/router.ex` specifically; file restored from `/tmp/router.ex.bak` before the Task 3 commit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add enforce_audience: option to VerifyToken.init/1 with raise (D-07)** — `3fffeff` (feat) — `lib/lockspire/plug/verify_token.ex` + the regression-update to the existing shape-preservation test in `verify_token_test.exs:84-94` (which Task 1's `<behavior>` Test 7 explicitly required: the existing strict-match was incompatible with the new default-false key).
2. **Task 2: Add init/1 enforce_audience: test cases (D-07)** — `c651696` (test) — six new test cases at `verify_token_test.exs:96-132` mirroring `<behavior>` Tests 1-6.
3. **Task 3: Propagate enforce_audience: true to four canonical sites and add D-07 audience: substring contract clause** — `eb56075` (feat) — four canonical-pipeline file edits + the new contract clause at `release_readiness_contract_test.exs:761`.

_Note: TDD-flagged tasks in this plan followed the same plan-granularity TDD pattern as Plan 01: each task's `<verify>` block is the RED/GREEN gate; per-task implementation-then-tests sequencing inside a single TDD task is honored by writing tests, watching them fail, implementing, watching them pass, then committing the task atomically. Task 2 is itself a tests-only commit — it adds NEW behavior assertions on top of Task 1's already-shipped raise, so it has no separate RED phase distinct from Task 1's._

## Files Modified

- `lib/lockspire/plug/verify_token.ex` — Added 4th schema key `enforce_audience` to `@options_schema` (lines 37-44); added new init/1 raise at lines 54-58 immediately after the existing `:audience`/`:audiences` mutual-exclusion raise. Total +14/-1 lines.
- `test/lockspire/plug/verify_token_test.exs` — Reshaped the existing init/1 shape-preservation test (lines 84-94) to use `Keyword.fetch!` assertions; added six new init/1 test cases for `enforce_audience:` semantics (lines 96-132). Total +47/-7 lines across the two commits.
- `test/lockspire/release_readiness_contract_test.exs` — Added new test clause "canonical lockspire_protected_api pipeline declares a non-empty audience: across all four RECIPE-01 sites (D-07)" at lines 761-792, adjacent to the existing byte-identical clause at line 745. Total +32 lines.
- `docs/protect-phoenix-api-routes.md` — Added `, enforce_audience: true` to the canonical block's `Lockspire.Plug.VerifyToken` line at line 18.
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` — Added `, enforce_audience: true` to the canonical block's `Lockspire.Plug.VerifyToken` line at line 25.
- `priv/templates/lockspire.install/router.ex` — Added `, enforce_audience: true` to the commented canonical block's `Lockspire.Plug.VerifyToken` line at line 13 (preserved `#   ` heredoc-comment prefix per D-08).
- `scripts/demo/adoption_smoke.py` — Added `, enforce_audience: true` to the canonical-comment block's `Lockspire.Plug.VerifyToken` line at line 246 (preserved `# ` Python-comment prefix).

## Required Output Fields (from `<output>`)

### Exact wording of the new ArgumentError message

```
expected :audience or :audiences when :enforce_audience is true (D-07)
```

This message names both `:enforce_audience` (the violating option) and `:audience` / `:audiences` (the missing-required keys), plus the D-07 anchor for greppability against `.planning/phases/98-plug-hardening/98-CONTEXT.md`.

### Exact regex used by the new contract-test clause

```elixir
~r/Lockspire\.Plug\.VerifyToken,[^\n]*\baudience:\s*"([^"]+)"/
```

The `\baudience:` word-boundary anchor prevents `enforce_audience: true` from falsely satisfying the substring match; the `"([^"]+)"` capture group requires at least one non-quote character inside the quoted form, so vacuous `audience: ""` mounts fail the clause too (T-98-02-01 mitigation).

### The four canonical VerifyToken lines after modification

| File | Line | Excerpt |
|------|------|---------|
| `docs/protect-phoenix-api-routes.md` | 18 | `  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api", enforce_audience: true` |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | 25 | `    plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api", enforce_audience: true` |
| `priv/templates/lockspire.install/router.ex` | 13 | `    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api", enforce_audience: true` |
| `scripts/demo/adoption_smoke.py` | 246 | `    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api", enforce_audience: true` |

### Confirmation: existing four-file content-hash test still passes

`mix test test/lockspire/release_readiness_contract_test.exs:745` → 1 test, 0 failures. The byte-identical clause is intact across the four canonical sites; the new keyword pair was added in the same byte position in all four files so the normalized content hashes still agree.

### Note: enforce_audience: true is byte-identical across all four canonical files

Confirmed by both:
- The existing content-hash clause at release_readiness_contract_test.exs:745 still passes (would fail with a "drift between" message if any file's normalized bytes differed).
- The new D-07 audience-substring clause additionally proves the `audience: "..."` keyword survives in all four files.

## Decisions Made

- **Exact raise message wording: `"expected :audience or :audiences when :enforce_audience is true (D-07)"`** — names both option keys (so the test's `~r/enforce_audience/` AND `~r/audience/` both match the same message), names the missing required keys symmetrically with `or`, and includes the D-07 anchor so a maintainer hitting the raise can grep CONTEXT.md directly. The plan gave the executor discretion on exact wording; this form is greppable, names the violation, and points at the decision record.

- **Test fix strategy for the existing strict-shape test (option b from the plan)** — restructured `verify_token_test.exs:84-94` from `assert [scopes: ..., audience: ...] = VerifyToken.init(...)` strict pattern-match to per-key `Keyword.fetch!` assertions. The plan's interfaces note said "NimbleOptions returns keys in schema order" but in 1.1.1 the library actually prepends defaulted keys to the head — the strict `=` match against `[scopes: ..., audience: ..., enforce_audience: false]` fails because the actual return is `[enforce_audience: false, scopes: ..., audience: ...]`. Per-key Keyword.fetch! is also more robust to future NimbleOptions internal-ordering changes; this is a positive net-improvement to the test design, not a workaround.

- **Placed the new init/1 raise immediately after the existing mutual-exclusion raise (lines 54-58)** — rather than weaving it into the pipeline-style validators (`validate_non_empty_value!`, etc.) at lines 60-63. Both raises are compile/boot-time option invariants at the same conceptual layer; adjacent placement makes the precedent obvious and groups the "init/1 invariants" in one visual block.

- **Used `Keyword.get(opts, :enforce_audience, false)` in the raise condition** — even though NimbleOptions defaults the key to `false`, the explicit default-false fallback in `Keyword.get/3` is defense-in-depth against any future schema change accidentally dropping the default. Cost: one extra default parameter. Benefit: the raise condition reads correctly regardless of NimbleOptions internals.

- **Single Regex.run with `capture: :all_but_first` rather than a two-stage match-then-extract** — the new D-07 clause's regex `~r/Lockspire\.Plug\.VerifyToken,[^\n]*\baudience:\s*"([^"]+)"/` is single-pass: match position confirms the keyword is on the right line, the capture group enforces the non-empty constraint. No need for `Regex.match?` followed by separate extraction.

- **Used `flunk/1` on regex miss, not `assert false`** — `flunk/1` accepts a string message directly, so the failure output shows the specific file name and the D-07 anchor as the failure description rather than the boilerplate "Expected truthy, got false."

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] NimbleOptions key ordering assumption was wrong**

- **Found during:** Task 1 GREEN (running `mix test test/lockspire/plug/verify_token_test.exs` after adding the new schema key + init/1 raise)
- **Issue:** The plan's interfaces note (line 227) said "NimbleOptions returns keys in schema order — it does, per `nimble_options` docs." The plan's behavior Test 7 then specified option (b) — "Update the existing assertion to its actual returned shape, e.g., `assert VerifyToken.init(...) == [scopes: ..., audience: ..., enforce_audience: false]`" — assuming schema order. In NimbleOptions 1.1.1, defaulted-key population happens during validation but the resulting Keyword list places defaulted keys at the HEAD of the list, not at the position implied by schema order. Actual return: `[enforce_audience: false, scopes: ["read:billing"], audience: "billing-api"]`.
- **Fix:** Rather than asserting on the strict ordered shape (which would be brittle anyway), restructured the test to use `Keyword.fetch!` per-key assertions. This is option (a) from the plan, generalized: each test checks each required key independently without making the test depend on internal Keyword ordering. Per-key assertions also future-proof against any NimbleOptions internal-ordering change.
- **Files modified:** `test/lockspire/plug/verify_token_test.exs` (lines 84-94, the existing shape-preservation test)
- **Commit:** `3fffeff` (Task 1)

---

**Total deviations:** 1 auto-fixed (Rule 1 — incorrect assumption in plan's interfaces note about NimbleOptions key ordering)
**Impact on plan:** Zero scope creep. The fix is a more-robust test design that the plan would have arrived at if the planner had run NimbleOptions 1.1.1 hands-on rather than relying on docs.

## Issues Encountered

None significant. The biggest design micro-decision was the per-key Keyword.fetch! assertion form once NimbleOptions key-ordering turned out to be unexpected — but this is a positive shift in test robustness, not a workaround.

## Verification Evidence

Plan-level `<verification>` block results (all clauses pass):

| Clause | Expected | Actual |
|--------|----------|--------|
| `mix test test/lockspire/plug/verify_token_test.exs` | exits 0 | 31 tests, 0 failures |
| `mix test test/lockspire/release_readiness_contract_test.exs` | exits 0 | 30 tests, 0 failures |
| `grep -c "enforce_audience" lib/lockspire/plug/verify_token.ex` | ≥ 2 | 3 (schema key + raise condition + Keyword.get default) |
| `grep -c "enforce_audience: true" priv/templates/lockspire.install/router.ex` | exactly 1 | 1 |
| `grep -c "enforce_audience: true" examples/adoption_demo/lib/adoption_demo_web/router.ex` | exactly 1 | 1 |
| `grep -v '^#' docs/protect-phoenix-api-routes.md \| grep -c "enforce_audience: true"` | ≥ 1 | 1 |
| `grep -c "enforce_audience: true" scripts/demo/adoption_smoke.py` | exactly 1 | 1 |
| Existing test at release_readiness_contract_test.exs:745 (four-file content-hash) still passes | passes | 1 test, 0 failures |
| New audience-substring contract-test clause exists and passes | passes | included in the 30 tests, 0 failures suite total |

Plan-level `<success_criteria>` results (all five satisfied):

1. **VERIFIER-06 option mechanism (D-07 part 1)** — An adopter who mounts `VerifyToken` with `enforce_audience: true` and no audience receives `ArgumentError` from `init/1` at compile/boot. Proved by the new init/1 test cases at verify_token_test.exs:96-104.
2. **Back-compat for no-audience mounts preserved** — `verify_token_test.exs:94-99` (`assigns access_token with missing_token error when no header`) and `:101-108` (`Basic abc` header) still pass with no opts and no `enforce_audience` key; the default-false on the new schema key means these mounts behave identically.
3. **VERIFIER-06 contract-test mechanism (D-07 part 2)** — `release_readiness_contract_test` fails loudly if any of the four canonical-pipeline files drops `audience:` from its VerifyToken declaration. Proved by the manual failure-path check during Task 3: deleting `audience: "billing-api"` from `examples/adoption_demo/lib/adoption_demo_web/router.ex` made the new clause fail with `"missing or empty audience: keyword on the Lockspire.Plug.VerifyToken line in examples/adoption_demo/lib/adoption_demo_web/router.ex"`; restored before commit.
4. **D-08: install-template retains `enforce_audience: true`** — `priv/templates/lockspire.install/router.ex` line 13 now contains the keyword pair inside the commented heredoc. An adopter who later uncomments the pipeline AND deletes the `audience:` line gets the loud `init/1` raise from Plan 02 Task 1.
5. **ROADMAP.md Phase 98 Success Criterion #4: every shipped pipeline declaration declares `audience:`, asserted in CI** — Yes. The new contract-test clause is in `release_readiness_contract_test.exs`, which runs in CI via `mix test`. Any future docs/template PR that drops `audience:` from any of the four canonical sites fails the suite.

## Threat Flags

None new. The plan's `<threat_model>` captured all surface introduced by this change:

- T-98-02-01 (vacuous audience) — `mitigate`, the new clause's `"([^"]+)"` capture group rejects `audience: ""` empty-quoted forms, and the existing `validate_non_empty_value!/2` / `validate_audiences_not_empty!/1` helpers in `verify_token.ex` reject nil/empty-string/empty-list audience values at runtime
- T-98-02-02 (template-audience-deletion) — `mitigate`, the install template's commented heredoc now carries `enforce_audience: true` so deletion-of-audience-after-uncomment produces the loud `init/1` raise; the new contract-test clause additionally fails at PR time if the template's canonical block drifts
- T-98-02-03 (repudiation: "the template didn't include it") — `accept`, the install-template canonical block records the intent in source; documentation is Phase 102's scope
- T-98-02-04 (ArgumentError information disclosure) — `accept`, the raise message names only `:enforce_audience` and `:audience`/`:audiences` which are already publicly-documented option keys
- T-98-02-05 (init/1 raise prevents boot) — `accept`, intended behavior; opt-out via default-false preserves back-compat
- T-98-02-06 (silent docs-only audience deletion in PR) — `mitigate`, the new contract clause names the specific file on failure
- T-98-02-SC (supply-chain) — `n/a`, zero new dependencies (the new clause uses only stdlib `Regex` + the existing `extract_canonical_pipeline!/2` helper)

## Self-Check: PASSED

- `lib/lockspire/plug/verify_token.ex` — FOUND (modified, +14/-1 lines, committed in `3fffeff`)
- `test/lockspire/plug/verify_token_test.exs` — FOUND (modified, +47/-7 lines across `3fffeff` + `c651696`)
- `test/lockspire/release_readiness_contract_test.exs` — FOUND (modified, +32 lines, committed in `eb56075`)
- `docs/protect-phoenix-api-routes.md` — FOUND (modified, +0/-0 net-line change; one keyword pair added inline at line 18, committed in `eb56075`)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` — FOUND (modified, inline at line 25, committed in `eb56075`)
- `priv/templates/lockspire.install/router.ex` — FOUND (modified, inline at line 13, committed in `eb56075`)
- `scripts/demo/adoption_smoke.py` — FOUND (modified, inline at line 246, committed in `eb56075`)
- Commit `3fffeff` (Task 1) — FOUND in `git log --all`
- Commit `c651696` (Task 2) — FOUND in `git log --all`
- Commit `eb56075` (Task 3) — FOUND in `git log --all`
- Test suite — verify_token_test 31 tests 0 failures; release_readiness_contract_test 30 tests 0 failures
- Plan `<verification>` block — all clauses pass
- Plan `<success_criteria>` block — all five criteria proved

## Next Phase Readiness

Plan 03 (`98-03-PLAN.md`) is ready to execute. The init/1 invariant-raise pattern established here ("name both the violating option AND the missing required keys; place after NimbleOptions.validate! and after existing same-layer raises") is the precedent for any further init/1 invariants Plan 03 might add. The four-file canonical-pipeline contract pattern (extract → assert per-site, fail naming the specific file) is the precedent for any further per-site assertions the remaining phase-98 plans might add.

Phase 98 remaining plans inherit:
- The schema fourth key `enforce_audience: :boolean` (default false) and its `init/1` raise
- The new D-07 contract-test clause as the structural backstop against `audience:` drift
- The `, enforce_audience: true` keyword pair now byte-identical across all four canonical sites — any future canonical-block edit must keep the keyword present in all four files or fail both the byte-identical and D-07 audience-substring clauses

---
*Phase: 98-plug-hardening*
*Plan: 02*
*Completed: 2026-05-27*
