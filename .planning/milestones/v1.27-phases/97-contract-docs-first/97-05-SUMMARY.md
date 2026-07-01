---
phase: 97-contract-docs-first
plan: 05
subsystem: test
tags:
  - phase-97
  - wave-4
  - recipe-01
  - release-readiness-contract
  - content-hash-invariant
  - sha256-canonical-pipeline

# Dependency graph
requires:
  - phase: 97
    plan: 02
    provides: "Canonical-block site #1: docs/protect-phoenix-api-routes.md with BEGIN/END markers wrapping the canonical pipeline declaration"
  - phase: 97
    plan: 03
    provides: "D-11 cross-link state: docs/saas-adoption-recipe.md L50 carries `protect-phoenix-api-routes.md` cross-link instead of plug-name restatement"
  - phase: 97
    plan: 04
    provides: "Canonical-block sites #2-#4 (demo router, install template, Python smoke) all reachable via BEGIN/END markers; D-02 normalization map produces byte-equal interior across all four sites"
provides:
  - "Three new module attributes in `test/lockspire/release_readiness_contract_test.exs` (L84, L88, L92) pointing at the three non-doc carrier files"
  - "Four new private helpers in the same test module: `extract_canonical_pipeline!/2` (L140), `normalize/2` two clauses (L159 + L169), `strip_uniform_indent/1` (L176), `canonical_hash!/2` (L202)"
  - "Three new test clauses in the same test module: canonical-pipeline content-hash invariant (L745), D-11 saas-recipe cross-link invariant (L761), D-15 within-file restatement refute (L772)"
  - "Drift detection contract: any change to the canonical bytes in any one of the four RECIPE-01 carrier files (after D-02 normalization) fails the L745 test with a failure message naming BOTH file paths in the drifted pair"
  - "Sanity guard contract: removing/renaming the canonical region body (e.g., breaking the `Lockspire.Plug.VerifyToken` substring) raises a RuntimeError citing the file and the marker-broken/extraction-broken cause"
  - "EEx-tag guard contract: inserting any EEx tag (`<%` or `<%=`) inside the canonical region of any `.ex` carrier file raises a RuntimeError citing the file and the heredoc-interpolation concern"
  - "Runtime fixture sync (Rule 3 auto-fix): `test/support/generated_host_app_web/router/lockspire.ex` updated to match the Plan-04-extended `priv/templates/lockspire.install/router.ex` template, so `install_generator_test.exs:201` left/right equality assertion stays GREEN"
affects:
  - "98-* (Plug Hardening): the four-site content-hash contract now enforces the runtime/docs/template/smoke canonical alignment going forward — any plug-hardening edit that changes the canonical pipeline declaration must be reflected in all four sites or `mix ci` fails loudly with a named-pair drift message"
  - "101-DEMO-01/02/03: still owns the demo-side reconciliation of the `MyAppWeb.ProtectedApiReplayStore` placeholder; Plan 05 changes nothing about that scope"
  - "102-SCAFFOLD-01: still owns the install-template `# ` prefix removal; Plan 05's content-hash contract pins the bytes that Phase 102 will flip live"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Marker-comment regex extraction (Pattern A from 97-PATTERNS.md) used in a test-time invariant: the regex `~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\\n(.*?)\\n[ \\t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms` extracts interior bytes between markers across host-syntax variants"
    - "Two-step normalization for prefix-stripped carriers: strip uniform leading indent FIRST (so `# ` lands at line start), then per-line `String.replace_prefix(&1, \"# \", \"\")`, then re-strip uniform indent for any inner indent the prefix-strip exposed. Without the leading strip the `# ` is never at line start in indented carriers and the prefix-strip is a no-op."
    - "`Enum.map_join/3` over `Enum.map/2 |> Enum.join/2` per credo strict mode (the project's `mix ci` runs `mix credo --strict` and treats refactoring opportunities as failures)"
    - "Pairwise comparison via `for {path_a, hash_a} <- hashes, {path_b, hash_b} <- hashes, path_a < path_b do ... end` — binary lexicographic compare on path strings keeps the comprehension to exactly N×(N-1)/2 unique pairs (6 pairs for 4 files) and produces deterministic failure-message ordering"

key-files:
  created:
    - .planning/phases/97-contract-docs-first/97-05-SUMMARY.md
  modified:
    - test/lockspire/release_readiness_contract_test.exs (Task 1 added 3 module attributes + 4 private helpers at L84-92, L140-216; Task 2 added 3 test clauses at L745-783; net +125 / -0 lines)
    - test/support/generated_host_app_web/router/lockspire.ex (Rule 3 Auto-fix: synced runtime fixture with Plan-04-extended install template; net +9 / -0 lines)

key-decisions:
  - "Normalize-then-prefix-strip-then-normalize-again order in `normalize(bytes, kind)` for prefix-stripped carriers (L159-168). The patterns file showed `# `-strip BEFORE `strip_uniform_indent`, which only works when the file has zero leading indent. The install-template carrier has 4-space heredoc-interior indent + the `# ` marker, and the Python carrier has 4-space function-body indent + the `# ` marker — in both, `String.replace_prefix(\"    # ...\", \"# \", \"\")` is a no-op because the line starts with 4 spaces, not `# `. The fix: strip leading uniform indent first (4 spaces gone, line now starts with `# `), then prefix-strip (`# ` gone), then strip remaining uniform indent (handles the inner 2-space indent that `# ` was hiding). Verified all four files produce identical SHA-256 after this normalization."
  - "Sanity-guard preferred over BEGIN-marker-missing for the missing-marker probe. The plan's `<behavior>` block described a missing-marker probe; in practice, removing the BEGIN marker breaks the regex extraction itself and raises `missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in #{path}` from `extract_canonical_pipeline!/2`. The plan's expected message text (`canonical region in ... missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken`) is the more specific Pitfall 4 sanity guard inside `canonical_hash!/2`, which fires when the extraction succeeds but the body is missing the VerifyToken substring (e.g., a plug renamed inside the canonical region). Both probes are correct drift defenses; the SUMMARY records the message text that matches the plan's literal expectation."
  - "Install-fixture sync committed as a separate `fix(97-05)` commit alongside the credo refactor. Task 1 and Task 2 commits keep their narrow test-additive scope; the Rule 3 auto-fix commit isolates the cross-plan blocker (Plan 04 left an unsynced runtime fixture). Future bisects against the test-canonical commits stay clean."

patterns-established:
  - "Four-site content-hash drift invariant: any edit to any one of the four RECIPE-01 carrier files that drifts the canonical bytes (after D-02 normalization) is caught at test time with a failure message naming the file pair. Pattern is reusable for future multi-site canonical-region invariants — write a `extract_canonical_pipeline!/2`-like helper with kind-aware normalization, a `canonical_hash!/2`-like helper with sanity + EEx guards, and a pairwise-compare test clause."

requirements-completed:
  - RECIPE-01

# Metrics
duration: ~25min (active editing, debugging the normalize order, running mix ci twice, fixing the cross-plan install-fixture blocker)
completed: 2026-05-27
---

# Phase 97 Plan 05: Canonical-Pipeline Content-Hash Contract Summary

**Closed the RECIPE-01 drift loop. `test/lockspire/release_readiness_contract_test.exs` now carries three new clauses that pairwise-compare SHA-256 hashes of the canonical pipeline interior across all four RECIPE-01 carrier sites, refute three-plug-name restatement in `docs/saas-adoption-recipe.md`, and refute within-file pipeline restatement in `docs/protect-phoenix-api-routes.md`. All three negative-path probes (drift, sanity-guard, EEx-tag) were executed-and-reverted with verbatim failure-message capture per WARNING #6 enforcement. `mix ci` exits 0 at phase end.**

## Performance

- **Started:** 2026-05-27T22:15:00Z (worktree HEAD-reset; first read after worktree branch check)
- **Completed:** 2026-05-27T22:24:13Z
- **Duration:** ~9 min wall time after `mix deps.get` (the deps fetch ran in background during Task 1 edits and finished before any test was run). Active editing + verifying ~25 min including normalize-order debug and install-fixture Rule-3 fix.
- **Tasks:** 2 / 2 (plus 1 Rule-3 auto-fix commit)
- **Files modified:** 2 (the test file + the install-generator runtime fixture)

## Accomplishments

### Task 1 — Module attributes + private helpers (commit `601db4f`)

- Added three module attributes to `test/lockspire/release_readiness_contract_test.exs` at L84-92: `@adoption_demo_router_path`, `@install_template_router_path`, `@adoption_smoke_script_path`. Each uses the same `Path.expand("../../<rel_path>", __DIR__)` shape as the existing 30 module attributes.
- Added four private helpers at L140-216:
  - `extract_canonical_pipeline!/2` (L140): regex-extracts interior bytes between BEGIN/END markers; raises `missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in #{path}` on no-match (RESEARCH Pitfall 4 — `case` + raise, never `List.first()` which returns `nil`).
  - `normalize/2` two clauses (L159 + L169): kind-aware. The prefix-strip clause for `:python_commented` and `:elixir_in_commented_heredoc` carriers; the bare clause for `:elixir_in_markdown_fence` and `:elixir` (catch-all).
  - `strip_uniform_indent/1` (L176): computes minimum leading whitespace across non-blank lines and strips that many characters from every line. Defensive on all-blank input.
  - `canonical_hash!/2` (L202): calls extract, then sanity-guards on `Lockspire.Plug.VerifyToken` substring (Pitfall 4), then EEx-tag-guards for `.ex` carriers (Pitfall 3), then returns `:crypto.hash(:sha256, bytes)`.
- Existing tests still pass (26 tests, 0 failures at the end of Task 1; the new helpers are not yet exercised).

### Task 2 — Three new test clauses (commit `0ee7d40`)

- Added three test clauses to the same file at L745-783:
  - Clause 1 at L745 — "canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites" — builds the `files` list (4-tuple per carrier kind), maps to `{path, canonical_hash!(path, kind)}`, then pairwise-asserts hash equality. Failure message uses `Path.relative_to_cwd/1` to name both files in the drifted pair (D-02 load-bearing requirement).
  - Clause 2 at L761 — "docs/saas-adoption-recipe.md cross-links to the canonical pipeline rather than restating plug names" — asserts `protect-phoenix-api-routes.md` is present; refutes the three-plug-name concatenated restatement (D-11 invariant).
  - Clause 3 at L772 — "docs/protect-phoenix-api-routes.md carries the canonical pipeline declaration exactly once (D-15)" — counts occurrences of `pipeline :lockspire_protected_api do` via `String.split/2 |> length |> Kernel.-(1)`; asserts the count equals exactly 1.
- After Task 2 commit, the test file carries 29 tests, all passing.

### Rule 3 Auto-Fix — Install-fixture sync + credo refactor (commit `c3ed91f`)

- `mix ci` initial run after Task 2 surfaced TWO blocking issues:
  1. Credo strict-mode refactoring-opportunity violations (`Enum.map/2 |> Enum.join/2` should be `Enum.map_join/3`) in `normalize/2` and `strip_uniform_indent/1` — auto-fixed by inlining `Enum.map_join("\n", ...)`.
  2. `test/integration/install_generator_test.exs:201` left/right `File.read!` equality assertion failed — the install-generator runtime fixture at `test/support/generated_host_app_web/router/lockspire.ex` was not updated by Plan 04 when Plan 04 extended `priv/templates/lockspire.install/router.ex` with the 9-line canonical-block carrier. The test compares the template-rendered output against this fixture. Auto-fixed by inserting the same 9-line canonical block (verbatim, with `<%= @web_module %>` expanded to `GeneratedHostAppWeb`) into the fixture at the same heredoc position.
- Post-fix: `mix ci` exits 0 in 32 seconds wall-time after the second full pipeline run.

## Task Commits

| # | Task | Commit | Files | Net |
| - | --- | --- | --- | --- |
| 1 | Add canonical-pipeline extraction + hashing helpers | `601db4f` | `test/lockspire/release_readiness_contract_test.exs` | +87 / -0 |
| 2 | Assert four-file canonical pipeline byte-equality + D-11 + D-15 | `0ee7d40` | `test/lockspire/release_readiness_contract_test.exs` | +38 / -0 |
| 3* | (Rule 3 auto-fix) Refactor normalize/2 to Enum.map_join + sync install fixture | `c3ed91f` | `test/lockspire/release_readiness_contract_test.exs` + `test/support/generated_host_app_web/router/lockspire.ex` | +11 / -5 |

Final state: 29 tests in `release_readiness_contract_test.exs`, 0 failures; full `mix ci` pipeline exit 0.

*Commit 3 is a follow-up auto-fix per Rule 3, not a planned task. The orchestrator's plan-metadata commit for this SUMMARY follows separately.

## Final Line Numbers (per output spec requirement a)

### Module attributes added in Task 1

| Element | Line |
| --- | --- |
| `@adoption_demo_router_path Path.expand(...)` | L84-87 (multi-line) |
| `@install_template_router_path Path.expand(...)` | L88-91 (multi-line) |
| `@adoption_smoke_script_path Path.expand(...)` | L92 (single line) |

### Private helpers added in Task 1 (and refactored in commit `c3ed91f`)

| Helper | Line |
| --- | --- |
| `defp extract_canonical_pipeline!(path, kind)` | L140 |
| `defp normalize(bytes, kind) when kind in [:python_commented, :elixir_in_commented_heredoc]` | L159 |
| `defp normalize(bytes, _kind)` (catch-all) | L169 |
| `defp strip_uniform_indent(bytes)` | L176 |
| `defp canonical_hash!(path, kind)` | L202 |

### Test clauses added in Task 2

| Clause | Line | Status |
| --- | --- | --- |
| "canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites" | L745 | GREEN |
| "docs/saas-adoption-recipe.md cross-links to the canonical pipeline rather than restating plug names" | L761 | GREEN |
| "docs/protect-phoenix-api-routes.md carries the canonical pipeline declaration exactly once (D-15)" | L772 | GREEN |

## Negative-Path Probe Evidence (WARNING #6 Enforcement — Required by Output Spec c)

All three probes executed against the post-Task-2 state of the worktree. Each probe: edit a carrier file to break exactly one invariant, run `mix test test/lockspire/release_readiness_contract_test.exs:748`, capture the EXACT failure-message text from ExUnit, revert the edit via `git checkout --`, confirm `git status --porcelain` is empty for the file.

### Negative path probe 1: drift detection

`negative_path_drift_check`

**Edit applied:** changed `audience: "billing-api"` to `audience: "different"` on L25 of `examples/adoption_demo/lib/adoption_demo_web/router.ex`.

**Observed test-failure message text (exact, from ExUnit):**

```
canonical pipeline block drifted between docs/protect-phoenix-api-routes.md and examples/adoption_demo/lib/adoption_demo_web/router.ex
```

Both file paths are named in the failure message (D-02 load-bearing requirement satisfied). The pair returned is the lexicographically-first drifted pair (`docs/...` < `examples/...`); ExUnit's `assert hash_a == hash_b` short-circuits on the first failing iteration of the `for` comprehension.

**Revert command:**

```
git checkout -- examples/adoption_demo/lib/adoption_demo_web/router.ex
```

Reverted: confirmed clean

### Negative path probe 2: missing marker / extraction broken

`negative_path_missing_marker_check`

**Edit applied:** changed `plug Lockspire.Plug.VerifyToken,` to `plug Lockspire.Plug.SomethingElse,` on L25 of `examples/adoption_demo/lib/adoption_demo_web/router.ex` — this leaves the BEGIN/END markers intact (the regex extracts successfully) but the captured body no longer contains `Lockspire.Plug.VerifyToken`, so the Pitfall 4 sanity guard inside `canonical_hash!/2` fires.

**Observed raised-RuntimeError message text (exact, from ExUnit):**

```
canonical region in /Users/jon/projects/lockspire/.claude/worktrees/agent-af0bce5ebe5602e5d/examples/adoption_demo/lib/adoption_demo_web/router.ex missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken
```

Matches the plan's expected sanity-guard message text verbatim modulo absolute-path expansion (the `#{path}` interpolation produces the absolute path from `Path.expand`; the plan's literal `canonical region in <path>` substring is present). The guard defends RESEARCH Pitfall 4 (silent-rename / extraction-broken) at the canonical-bytes-content layer; the regex itself also defends at the marker layer (`extract_canonical_pipeline!/2` raises `missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in #{path}` if the BEGIN marker is removed instead).

**Revert command:**

```
git checkout -- examples/adoption_demo/lib/adoption_demo_web/router.ex
```

Reverted: confirmed clean

### Negative path probe 3: EEx tag in canonical region

`negative_path_eex_tag_check`

**Edit applied:** inserted `<%= some_tag %>` between `#   plug` and `Lockspire.Plug.VerifyToken,` on L13 of `priv/templates/lockspire.install/router.ex` (i.e., inside the canonical region of an EEx-bearing `.ex` carrier file). The install template's canonical region is normally EEx-tag-free; the Pitfall 3 EEx-tag guard inside `canonical_hash!/2` fires for any `.ex` carrier whose extracted region contains `<%`.

**Observed raised-RuntimeError message text (exact, from ExUnit):**

```
canonical region in /Users/jon/projects/lockspire/.claude/worktrees/agent-af0bce5ebe5602e5d/priv/templates/lockspire.install/router.ex contains EEx tag — heredoc interpolation would chew the canonical bytes
```

Matches the plan's expected EEx-tag-guard message text verbatim modulo absolute-path expansion.

**Revert command:**

```
git checkout -- priv/templates/lockspire.install/router.ex
```

Reverted: confirmed clean

### Probe summary

All three probes verified the named drift-defense layer and were cleanly reverted. Three `Reverted: confirmed clean` lines above (one per probe). `git status --short` post-revert showed only the test-file modification (the Task 2 in-flight commit-pending state) with all four canonical carrier files clean.

## Canonical Region Interior Bytes (per output spec requirement d)

Captured via the new helper at runtime against `docs/protect-phoenix-api-routes.md` (kind `:elixir_in_markdown_fence`). `IO.inspect/1`-equivalent representation (the bytes that `:crypto.hash(:sha256, bytes)` consumes):

```
"pipeline :lockspire_protected_api do\n  plug Lockspire.Plug.VerifyToken, scopes: [\"read:billing\"], audience: \"billing-api\"\n  plug Lockspire.Plug.EnforceSenderConstraints,\n    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore\n  plug Lockspire.Plug.RequireToken\nend"
```

Rendered (LF line breaks visible):

```
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```

**SHA-256 of these bytes (raw binary, what `:crypto.hash(:sha256, bytes)` returns Base.encode16 lowercase):**

```
984d0285de54e413f62f37d22ee7068ede57598e58a8d880e1b912169a159829
```

All four carrier files produce this identical SHA-256 after D-02 normalization (verified post-edit via a Python-equivalent one-shot script + by passing the Task 2 clause's pairwise-compare with all 6 pairs equal).

**Note on hash vs. Plan-02-pinned `c79c19d10...`:** Plan 02's summary recorded SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172` for the same bytes-with-trailing-LF (Plan 02's interior includes `end\n`; this plan's regex capture excludes the final `\n` before the END marker). Both pins describe the same canonical region; they differ only on whether the trailing LF is part of the hashed content. The Plan 05 helper's regex-capture shape (`(.*?)\n[ \t]*# END`) excludes the final LF; the Plan 05 hash `984d028...` is what the four-file pairwise compare actually enforces going forward. This is not a regression — it is a one-time hash-format choice that locks in the post-Plan-05 contract.

## `mix ci` Exit Code + Elapsed Time (per output spec requirement e)

| Run | Exit | Elapsed | Notes |
| --- | --- | --- | --- |
| 1 (post-Task-2, pre-fix) | 1 | ~105s | Credo flagged 2 refactor opportunities; install-generator integration test left/right equality failed (Plan 04 left an unsynced runtime fixture) |
| 2 (post-fix commit `c3ed91f`) | **0** | **~32s** | Full pipeline GREEN: `mix test`, `mix test.integration`, `mix qa`, `mix docs.verify`, `mix deps.audit` all green; 72 integration tests, 937 unit tests + 272 excluded (FAPI/conformance/exp-mode tags), no failures |

## Phase 92 Helper Confirmation (per output spec requirement f)

Confirmed: `test/support/advanced_setup_support_truth.ex` was NOT modified by Plan 05. `git diff 7b5d127...HEAD -- test/support/advanced_setup_support_truth.ex` returns empty output. The only test-support edits in Phase 97 were in Plan 01 (per the Phase 97 plan-tree assignment).

## Decisions Made

- **Normalize-then-prefix-strip-then-normalize-again order for prefix-stripped carriers.** The plan's `<interfaces>` block (and the patterns file's L309-317) showed `# `-strip BEFORE `strip_uniform_indent`. Empirically that order does not work for the install-template carrier (4-space heredoc-interior indent + `# ` marker — `String.replace_prefix("    # ...", "# ", "")` is a no-op because the line starts with whitespace). The correct order is: LF-normalize → strip_uniform_indent → split-and-prefix-strip → strip_uniform_indent → trailing-strip. Verified via a one-shot Python+Elixir sanity script ahead of letting the test go GREEN; all four files produce SHA-256 `984d028...` after this five-step normalization.
- **Use Pitfall-4 sanity guard for the missing-marker probe rather than literal BEGIN-marker removal.** Both probes fire correctly but the plan's literal expected-message text matches the sanity guard exactly (`canonical region in ... missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken`); removing the BEGIN marker fires the slightly different `missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in ...` from `extract_canonical_pipeline!/2`. Both messages are correct production behavior; the SUMMARY records the message that matches the plan's literal expectation while noting the alternative defense layer.
- **Commit `Enum.map_join` refactor + install-fixture sync together.** Both are Rule 3 auto-fixes surfaced by the same `mix ci` invocation. Bundling them keeps the bisect surface simple (the post-fix commit `c3ed91f` is the "mix ci green" boundary). The Task 1 and Task 2 commits stay narrow.

## Deviations from Plan

### Rule 3 Auto-Fixes

**1. [Rule 3 — Blocking issue] Refactored `Enum.map/2 |> Enum.join/2` to `Enum.map_join/3`**

- **Found during:** First `mix ci` after Task 2 commit.
- **Issue:** Credo strict-mode flagged two refactor opportunities at `test/lockspire/release_readiness_contract_test.exs:165` (in `normalize/2`) and `:201` (in `strip_uniform_indent/1`). The project's `mix ci` runs `mix credo --strict` and treats refactor opportunities as failures (`** (exit) 8`).
- **Fix:** Inlined `Enum.map_join/3` at both sites — semantic equivalent, fewer allocations, credo-clean.
- **Files modified:** `test/lockspire/release_readiness_contract_test.exs` (2 lines refactored).
- **Commit:** `c3ed91f`.

**2. [Rule 3 — Blocking issue] Synced install-generator runtime fixture with Plan-04-extended template**

- **Found during:** First `mix ci` after Task 2 commit.
- **Issue:** `test/integration/install_generator_test.exs:201` asserts `File.read!(@fixture_root + "lib/.../router/lockspire.ex") == File.read!(@runtime_fixture_root + "router/lockspire.ex")`. The `@fixture_root` content is the template-rendered output (which now contains the Plan-04-added 9-line canonical block); the `@runtime_fixture_root` is the canonical expected-output fixture, which was NOT updated when Plan 04 extended `priv/templates/lockspire.install/router.ex`.
- **Fix:** Inserted the same 9-line canonical block (verbatim, with `<%= @web_module %>` already expanded to `GeneratedHostAppWeb` because the fixture is post-rendering) into `test/support/generated_host_app_web/router/lockspire.ex` at the same heredoc position. The install-generator test now passes; the canonical block is also extractable from this fixture, so Plan 05's four-file content-hash compare could be extended to five files in a future phase if desired (out of scope for Plan 05).
- **Files modified:** `test/support/generated_host_app_web/router/lockspire.ex` (+9 lines).
- **Commit:** `c3ed91f`.
- **Rationale for treating this as a Rule 3 auto-fix rather than a Rule 4 architectural change:** The fixture sync is the obvious, mechanical follow-up to Plan 04's template edit; the install-generator test was always going to fail until both files moved together. There is no architectural decision to be made (no library swap, no schema change, no auth-approach change) — just a missed file in Plan 04's scope.

### Auth Gates

None — no external service authentication required for this plan.

## Issues Encountered

- **Worktree had no `_build`/`deps`.** First-run cost of a fresh worktree. Ran `mix deps.get` in the background while editing Task 1; it completed before any `mix test` was run. Standard Phase 97 worktree behavior.
- **First `mix ci` run failed twice over.** Surfaced via the Credo strict-mode refactor opportunities + the install-fixture sync miss. Both auto-fixed in commit `c3ed91f`; the second `mix ci` run was clean.
- **`[error] Failed to refresh KeyCache: ... could not lookup Ecto repo Lockspire.TestRepo`** appears on every `mix test` startup. Pre-existing repo-startup log line; not caused by Phase 97 (Plan 02's summary recorded the same line). Not actionable in this plan.

## Stub Tracking

No stubs introduced by this plan. The `MyAppWeb.ProtectedApiReplayStore` placeholder canonical-block content is intentional and tracked by Phase 101 DEMO-01/02/03; Phase 102 SCAFFOLD-01 owns the install-template `# ` prefix removal. Both are correctly out of scope for Plan 05.

## User Setup Required

None — no external service configuration, no env var, no schema change, no secret, no deps change.

## Threat Flags

(none — Phase 97 introduces no new attack surface per `.planning/phases/97-contract-docs-first/97-RESEARCH.md` `## Security Domain`. This plan edits one test file + one test-support fixture. The `:crypto.hash(:sha256, ...)` call is for test-time invariant proof only — no token signing, no secret comparison, no constant-time requirement; the use case is byte-equality assertion across plaintext doc/test fixtures. Phase 98 V5 Input Validation and Phase 99 V6 Cryptography carry the security work for v1.27.)

## Next Phase Readiness

- **Phase 97 verification gate (`/gsd:verify-work 97`) is unblocked.** `mix ci` is GREEN end-to-end; all 5 plans (01 + 02 + 03 + 04 + 05) have landed; the four-site canonical-block ground truth is enforced at test time.
- **Wave 4 is complete.** No follow-up plans inside Phase 97.
- **Phase 98 (Plug Hardening) preconditions met.** The canonical pipeline declaration is now byte-pinned across all four sites; any future plug-hardening edit that changes the canonical bytes will fail the L745 content-hash test with a named-pair drift message, forcing a synchronized update across all four carrier files. This is exactly the public-contract anchor Phase 98 needs.
- **Phase 101 DEMO-01/02/03 unblocked.** The placeholder `MyAppWeb.ProtectedApiReplayStore` name is in place across the docs page + demo router + install template + Python smoke; Phase 101 adds the demo-side `AdoptionDemo.ProtectedApiReplayStore` alias that resolves it.
- **Phase 102 SCAFFOLD-01 unblocked.** The install-template canonical region carries the `# ` prefix today (commented-out); Phase 102 strips it to flip live; the L745 content-hash test will continue to pass as long as the rest of the canonical region stays byte-identical post-prefix-removal (the strip-`# ` normalization step absorbs it).

## Self-Check: PASSED

- File `.planning/phases/97-contract-docs-first/97-05-SUMMARY.md` exists at the expected path (this file).
- File `test/lockspire/release_readiness_contract_test.exs` carries all three module attributes (verified via `grep -c "@adoption_demo_router_path\|@install_template_router_path\|@adoption_smoke_script_path"` = 3 total occurrences).
- File `test/lockspire/release_readiness_contract_test.exs` carries all four named helpers (verified via `grep -cE "defp (extract_canonical_pipeline!|normalize|strip_uniform_indent|canonical_hash!)"` = 5, where `normalize` appears twice — the two pattern-match clauses).
- File `test/lockspire/release_readiness_contract_test.exs` carries all three test clauses (verified via `grep -c` on each clause's first-line literal = 1 each).
- Commits `601db4f`, `0ee7d40`, `c3ed91f` all exist in `git log --oneline` (verified via `git rev-parse --short HEAD` after each commit).
- All three negative-path probe markers (`negative_path_drift_check`, `negative_path_missing_marker_check`, `negative_path_eex_tag_check`) are present in this SUMMARY.
- Three `Reverted: confirmed clean` lines are present in this SUMMARY (one per probe).
- `mix test test/lockspire/release_readiness_contract_test.exs` exits 0 with 29 tests, 0 failures.
- `mix ci` exits 0 in ~32 seconds wall-time.

---
*Phase: 97-contract-docs-first*
*Plan: 05*
*Completed: 2026-05-27*
