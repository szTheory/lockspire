---
phase: 97-contract-docs-first
verified: 2026-05-27T18:40:00Z
status: passed
score: 14/14 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
---

# Phase 97: Contract + Docs First — Verification Report

**Phase Goal:** A single authoritative protected-route doc page exists and is content-hash-pinned across the four canonical locations before any implementation change lands, so the implementation honors a documented contract instead of a doc describing an accident.

**Verified:** 2026-05-27T18:40:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is fully achieved. The canonical protected-route pipeline declaration block now lives identically (after D-02 normalization) in all four canonical locations, every doc-contract substring required by ROADMAP success criteria is present verbatim in the canonical doc page and the supported-surface doc, and the `release_readiness_contract_test` content-hash invariant fails loudly with named-pair drift messages when any carrier file deviates.

## ROADMAP Success Criteria (Primary Contract)

| # | Success Criterion | Status | Evidence |
|---|-------------------|--------|----------|
| SC1 | `docs/protect-phoenix-api-routes.md` names RFC 9068 `at+jwt` as host-API protection shape; explains `/userinfo` and `/introspect` use stored opaque tokens which are not interchangeable | VERIFIED | All four D-06 sentences present verbatim once each: `Lockspire issues RFC 9068`, `Lockspire.Plug.VerifyToken. accepts JWT bearer tokens`, `Lockspire-owned ./userinfo. and ./introspect. use stored opaque tokens`, `To opt a client back to opaque` — all `grep -c` returns 1 |
| SC2 | Same canonical pipeline block appears verbatim in exactly four locations: docs page, demo router, install template, Python smoke | VERIFIED | All four files carry exactly 1 BEGIN/END marker pair; SHA-256 of normalized interior is identical: `984d0285de54e413f62f37d22ee7068ede57598e58a8d880e1b912169a159829` across all four (matches task prompt fact) |
| SC3 | `docs/supported-surface.md` plainly records non-goals: no introspection-at-the-RS, no auto-detection of token shape, no dual-verifier dispatcher, no RAR enforcement at the RS plug | VERIFIED | New H2 `## Explicit non-goals for host-API route protection` at L139, between L113 `## Explicitly out of scope` and L148 `## Trust posture`; all four D-09 non-goal phrases present once each |
| SC4 | `release_readiness_contract_test` clause fails loudly if content hash drifts between any two of the four locations | VERIFIED | Negative-path probe executed: edited `audience: "billing-api"` → `audience: "drifted"` in demo router; test L745 failed with exact message `canonical pipeline block drifted between docs/protect-phoenix-api-routes.md and examples/adoption_demo/lib/adoption_demo_web/router.ex`. Both file paths named per D-02. Reverted clean; 29 tests pass post-revert. |

**ROADMAP Score: 4/4 success criteria verified.**

## Observable Truths (PLAN frontmatter merged)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All 6 Phase 97 D-06/D-07 substrings present once each in helper `assert_protected_routes_guide!/1` | VERIFIED | `grep -c "Lockspire issues RFC 9068" test/support/advanced_setup_support_truth.ex` = 1; `grep -c "Phase 97 extensions"` = 2 (both separator comments present) |
| 2 | All 8 Phase 97 D-09 substrings present in helper `assert_advanced_setup_support_contract!/1` | VERIFIED | `grep -c "no introspection-at-the-RS as the host-API seam" test/support/advanced_setup_support_truth.ex` = 1 (plus 7 other D-09 substrings) |
| 3 | D-06 contract sentence appears verbatim as lead in `docs/protect-phoenix-api-routes.md` | VERIFIED | All four D-06 sentences `grep -c` = 1; lead paragraph confirmed at L3 by Plan 02 SUMMARY |
| 4 | D-07 caveat appears verbatim, preceded by HTML PHASE-102 sweep marker | VERIFIED | `grep -c "PHASE-102: delete this caveat sentence when issuance flip ships"` = 1; D-07 midphrase `grep -c` = 1; D-07 tail `grep -c` = 1 |
| 5 | All 8 Phase 92 substrings preserved in protect-phoenix-api-routes.md (including re-injected lowercase `tenant checks`) | VERIFIED | `tenant checks` = 1, `business authorization` = 2, `no-op for unconstrained bearer tokens` = 1, `error="use_dpop_nonce"` = 2, three plug names ≥4 each, supported-surface cross-link = 1 |
| 6 | Canonical block wrapped in BEGIN/END marker comments in docs page | VERIFIED | BEGIN=1, END=1; exactly one fenced elixir block (`grep -c '^```elixir'` = 1); exactly one `pipeline :lockspire_protected_api do` declaration (D-15 invariant) |
| 7 | D-15: secondary fenced blocks rewritten to reference-to-canonical prose | VERIFIED | Only one fenced elixir block remains; D-15 within-file restatement refute test (clause 3) GREEN |
| 8 | DOCS-02 non-goals subsection in `docs/supported-surface.md` between out-of-scope list (L113) and Trust posture (L148) | VERIFIED | Heading at L139; four bullets present with em-dash + rejection-rationale phrases per D-09 |
| 9 | D-11: `docs/saas-adoption-recipe.md:50` carries cross-link, no three-plug restatement | VERIFIED | L50 = `- If exposing API routes, follow the canonical pipeline in [\`docs/protect-phoenix-api-routes.md\`](protect-phoenix-api-routes.md).`; concatenated three-plug regex returns 0 matches |
| 10 | All four canonical sites carry BEGIN/END markers; interior bytes byte-identical after D-02 normalization | VERIFIED | Python sanity script (re-run by verifier) confirms all four files produce SHA-256 `984d0285de54e413f62f37d22ee7068ede57598e58a8d880e1b912169a159829` |
| 11 | Demo router carries placeholders `MyAppWeb.ProtectedApiReplayStore` and `audience: "billing-api"`; old `AdoptionDemo.Repo` removed from canonical region; `plug(` count = 8 (= pre-edit 11 − 3 parens-drop) | VERIFIED | `grep -c "MyAppWeb.ProtectedApiReplayStore"` = 1; `grep -c "AdoptionDemo.Repo"` = 0; `grep -c 'audience: "billing-api"'` = 1; `grep -cE 'plug\('` = 8 |
| 12 | Install template canonical block is commented-out per D-10; no EEx tags inside canonical region | VERIFIED | `grep -c "# pipeline :lockspire_protected_api do"` = 1; awk range-pattern + grep for `<%` or `<%=` returns empty output |
| 13 | Python smoke script still parses as valid Python after carrier insertion | VERIFIED | `python3 -c 'import ast; ast.parse(...)'` prints `python_parse_ok`; exit 0 |
| 14 | `release_readiness_contract_test` has three new clauses + four helpers + three module attributes; full 29 tests pass; `mix compile --warnings-as-errors` clean | VERIFIED | All three test clause names `grep -c` = 1 each; helper `defp` count = 5 (4 named + normalize twice); 29 tests pass; clean compile |

**Score: 14/14 truths verified.**

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `docs/protect-phoenix-api-routes.md` | Single authoritative protected-route page with D-06 lead, D-07 caveat, canonical block, D-15 single-restatement | VERIFIED | All substrings present; exactly 1 elixir fence; exactly 1 pipeline declaration |
| `docs/supported-surface.md` | New `## Explicit non-goals for host-API route protection` subsection | VERIFIED | Heading at L139; four D-09 bullets present |
| `docs/saas-adoption-recipe.md` | L50 cross-link to canonical doc, no plug-name restatement | VERIFIED | Cross-link present at L50; three-plug-name concatenation count = 0 |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | Marker-wrapped canonical block with placeholders | VERIFIED | BEGIN/END = 1 each; `MyAppWeb.ProtectedApiReplayStore` = 1; `audience: "billing-api"` = 1; `AdoptionDemo.Repo` = 0 in canonical region; `plug(` count = 8 |
| `priv/templates/lockspire.install/router.ex` | Commented-out canonical block in heredoc, no EEx in canonical region | VERIFIED | BEGIN/END = 1 each; `# pipeline :lockspire_protected_api do` = 1; EEx-tag awk pre-flight empty |
| `scripts/demo/adoption_smoke.py` | Python-comment canonical-block carrier inside `exercise_authorization_code` | VERIFIED | BEGIN/END = 1 each; `# pipeline :lockspire_protected_api do` = 1; `ast.parse` succeeds |
| `test/lockspire/release_readiness_contract_test.exs` | 3 module attrs + 4 helpers + 3 test clauses | VERIFIED | All `grep -c` checks pass; 29 tests run, 0 failures |
| `test/support/advanced_setup_support_truth.ex` | Helper extended with 14 new Phase 97 substrings | VERIFIED | D-06 substring present; D-09 substring present; Phase 92 substrings preserved (representative checks) |
| `test/support/generated_host_app_web/router/lockspire.ex` | Runtime fixture synced with Plan-04-extended template (Rule 3 auto-fix) | VERIFIED | BEGIN/END = 1 each; `MyAppWeb.ProtectedApiReplayStore` = 1; install_generator_test passes (5 tests, 0 failures) |

## Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| Test L745 content-hash clause | docs page + demo router + install template + Python smoke | Regex extraction of BEGIN/END region + kind-aware D-02 normalization + `:crypto.hash(:sha256, ...)` pairwise compare | WIRED | Test reads all four module attributes; verified all 6 pairs equal; negative-path drift probe confirms failure cites both file paths |
| Test L761 D-11 cross-link clause | `docs/saas-adoption-recipe.md` | `File.read!` + assert/refute regex | WIRED | Test reads the file; assert passes, refute passes |
| Test L772 D-15 refute clause | `docs/protect-phoenix-api-routes.md` | `File.read!` + `String.split` count | WIRED | Test reads the file; count = 1; assertion holds |
| `assert_protected_routes_guide!/1` helper | `docs/protect-phoenix-api-routes.md` | `assert_includes_all/2` substring check (Phase 92 idiom) | WIRED | Test 727 ("advanced-setup support contract...") passes; all 14 substrings asserted |
| `assert_advanced_setup_support_contract!/1` helper | `docs/supported-surface.md` | Same idiom | WIRED | Same test (L727) passes; D-09 substrings asserted against the file |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Test L745 four-file hash compare | `files` list + `hashes` list | `@adoption_demo_router_path`, `@install_template_router_path`, `@adoption_smoke_script_path`, `@protect_phoenix_api_routes_path` (all `Path.expand` of real paths) → `File.read!/1` via `extract_canonical_pipeline!/2` | YES — real file reads at runtime; pairwise hash compare runs against actual bytes from all four sites | FLOWING |
| Test L761 D-11 cross-link | `recipe` | `File.read!(@saas_adoption_recipe_path)` (real `docs/saas-adoption-recipe.md`) | YES | FLOWING |
| Test L772 D-15 refute | `page` | `File.read!(@protect_phoenix_api_routes_path)` | YES | FLOWING |
| Phase 92 helper test L727 | content args | `File.read!` of each doc per existing helper invocations | YES (precedent verified via Plan 01 RED state proving the substrings are asserted against live file content) | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Release readiness contract tests | `mix test test/lockspire/release_readiness_contract_test.exs` | `29 tests, 0 failures` (matches task prompt fact) | PASS |
| Project-wide unit tests | `mix test` | `937 tests, 0 failures (272 excluded)` (matches task prompt fact) | PASS |
| Clean compile with warnings-as-errors | `mix compile --force --warnings-as-errors` | exit 0; `Generated lockspire app`; no warnings | PASS |
| Install-generator integration | `mix test test/integration/install_generator_test.exs` | `5 tests, 0 failures` (fixture sync verified) | PASS |
| Phase 92 advanced-setup contract test | `mix test test/lockspire/release_readiness_contract_test.exs:727` | `1 test, 0 failures` (Plan 01 RED state now GREEN per Plans 02/03) | PASS |
| Python smoke script parseability | `python3 -c 'import ast; ast.parse(open(...).read())'` | `python_parse_ok` | PASS |
| Negative-path drift probe | Mutated `audience: "billing-api"` → `audience: "drifted"` in demo router; ran test L745 | Test failed with exact named-pair message: `canonical pipeline block drifted between docs/protect-phoenix-api-routes.md and examples/adoption_demo/lib/adoption_demo_web/router.ex`; reverted; post-revert all 29 tests GREEN | PASS |
| Four-file SHA-256 byte-equality (verifier re-run) | Python script applying D-02 normalization to all four canonical sites and hashing each interior | All four produce `984d0285de54e413f62f37d22ee7068ede57598e58a8d880e1b912169a159829` (single distinct hash) | PASS |
| EEx-tag pre-flight on install template | `awk '/# BEGIN .../,/.../ ...' | grep -E '<%\|<%='` | empty output (no EEx tags in canonical region) | PASS |

## Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| RECIPE-01 | 97-02, 97-03, 97-04, 97-05 | One canonical pipeline-declaration block lives in exactly four places — docs page, demo router, install template, Python smoke — and a release_readiness_contract_test clause fails if content hash drifts between any two | SATISFIED | Four-file SHA-256 byte-equality verified (`984d028...` across all four); negative-path drift probe confirms test fires loudly with named-pair message; test L745 is GREEN in the steady state |
| DOCS-01 | 97-01, 97-02 | `docs/protect-phoenix-api-routes.md` becomes single authoritative protected-route page stating: "Lockspire issues RFC 9068 `at+jwt` access tokens by default..." plus rest of D-06 contract sentence | SATISFIED | All four D-06 sentences present verbatim once each in the doc; D-15 within-file refute clause (L772) confirms exactly one canonical declaration |
| DOCS-02 | 97-01, 97-03 | `docs/supported-surface.md` records explicit non-goals: no introspection-at-the-RS as host-API seam, no auto-detection of token shape, no dual-verifier dispatcher, no RAR enforcement at the RS plug (RAR claims surface via `conn.assigns.access_token`) | SATISFIED | New `## Explicit non-goals for host-API route protection` subsection at L139 carries all four non-goal phrases verbatim; helper test 727 asserts the D-09 substrings against the file |

**No requirements declared in PLAN frontmatter are orphaned.** All three IDs (RECIPE-01, DOCS-01, DOCS-02) declared in `.planning/REQUIREMENTS.md` for Phase 97 are accounted for and satisfied in the codebase. The REQUIREMENTS.md traceability table still shows them as `Pending` — this is a metadata-update concern (the orchestrator updates REQUIREMENTS.md after the phase verification completes), not a code-state gap.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | — |

Scanned all 9 files modified by Phase 97 for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER`. Zero hits. No debt markers introduced. The `MyAppWeb.ProtectedApiReplayStore` placeholder is **canonical documentation**, not a stub — its reconciliation in Phase 101 DEMO-01/02/03 is tracked in the ROADMAP, and Phase 97 SUMMARYs document the deliberate placeholder design (D-04 decision).

## Probe Execution

The verifier executed one runtime probe (the negative-path drift check) plus re-ran the verifier's own four-file Python-equivalent of the D-02 normalization to confirm the SHA-256 claim in the task prompt and Plan 05 SUMMARY. Both probes pass. No declared `scripts/*/tests/probe-*.sh` exist for this phase; the test-suite (run via `mix test`) functions as the canonical probe and exits 0 for all 937 tests.

## Human Verification Required

(none — every must-have was machine-verified through `grep`, file reads, the released `mix test` and `mix compile` invocations, and the negative-path drift probe. There are no visual, real-time, or external-service items that require human attestation.)

## Negative-Path Probe Evidence (Verifier Re-Run)

The verifier did not blindly trust SUMMARY claims; instead, the drift probe documented in 97-05-SUMMARY was re-executed by the verifier itself:

```
Edit applied: sed -i 's/audience: "billing-api"/audience: "drifted"/' examples/adoption_demo/lib/adoption_demo_web/router.ex
Test run: mix test test/lockspire/release_readiness_contract_test.exs:745
Observed failure message (exact, from ExUnit):
  canonical pipeline block drifted between docs/protect-phoenix-api-routes.md and examples/adoption_demo/lib/adoption_demo_web/router.ex
Revert: cp /tmp/router_backup.ex examples/adoption_demo/lib/adoption_demo_web/router.ex
Post-revert grep: grep -c 'audience: "billing-api"' = 1
Re-run: mix test test/lockspire/release_readiness_contract_test.exs → 29 tests, 0 failures
```

This empirically confirms SC4 (the content-hash test fails loudly on drift with a named-pair message) and that the test is not just declaratively present but functionally enforcing.

## Gaps Summary

No gaps. The phase goal is achieved at all four levels:

1. **Existence**: Every required artifact exists at its expected path.
2. **Substantive**: Every artifact carries the required content substrings verbatim (D-06 contract, D-07 caveat, D-09 non-goals, Phase 92 preservation).
3. **Wired**: The new test clauses pull data from the actual canonical files via `File.read!` and assert pairwise byte-equality plus invariants.
4. **Data Flows**: Real bytes flow through the helpers; the negative-path drift probe demonstrates the wiring actually catches drift.

The phase is ready to proceed to Phase 98 (Plug Hardening). The canonical pipeline declaration is now byte-pinned across all four sites with the `release_readiness_contract_test:745` clause serving as the steady-state drift detector.

---
*Phase: 97-contract-docs-first*
*Verifier: Claude (gsd-verifier)*
*Verified: 2026-05-27T18:40:00Z*
