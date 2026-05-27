---
phase: 97-contract-docs-first
plan: 04
subsystem: docs
tags:
  - phase-97
  - wave-3
  - recipe-01
  - canonical-block-carriers
  - demo-router
  - install-template
  - python-smoke

# Dependency graph
requires:
  - phase: 97
    plan: 02
    provides: "Canonical pipeline interior bytes + SHA-256 c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172 — the byte-equality target for Plan 04 to mirror across the other three carrier files"
provides:
  - "Three additional canonical-block carrier sites established: live demo router (Elixir, kind :elixir), install template heredoc (Elixir-in-commented-heredoc, kind :elixir_in_commented_heredoc per D-10), Python smoke script (Python-comment, kind :python_commented per D-03/D-14) — each wrapped in `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` / `# END LOCKSPIRE_PROTECTED_PIPELINE` marker comments"
  - "Four-site byte-equality contract honored: all four carrier files extract to byte-identical canonical bytes after D-02 normalization (strip `# ` for :python_commented and :elixir_in_commented_heredoc carriers only; strip uniform leading indent for all; LF normalization; trailing whitespace strip) — verified in-flight via Python sanity check, all four files SHA-256 equal `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172`"
  - "Placeholder names threaded per D-04 + D-13: `MyAppWeb.ProtectedApiReplayStore` (replaces demo's `AdoptionDemo.Repo`) and `audience: \"billing-api\"` (newly introduced; absent pre-Plan-04) — Phase 101 DEMO-01/02/03 owns the demo-side alias that reconciles the placeholder back to a real module reference"
  - "Plan 05 (`release_readiness_contract_test` content-hash clause) is fully unblocked — the four-site canonical-block ground truth is now in place"
affects:
  - 97-05 (consumes the four-site byte-equality contract; the helper test clause hashes all four files post-D-02-normalization against the canonical SHA-256)
  - 101-DEMO-01/02/03 (introduces the demo-side `AdoptionDemo.ProtectedApiReplayStore` alias that reconciles the `MyAppWeb.ProtectedApiReplayStore` placeholder for the running demo BEAM)
  - 102-SCAFFOLD-01 (owns the install-template `# ` prefix removal that flips the canonical region from commented-out to live Elixir in generated host routers)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Marker-comment-anchored canonical region (Pattern A from 97-PATTERNS.md) applied to three new carrier sites — markers visible but excluded from the hashed interior"
    - "Mixed-host-syntax canonical-block carrier: same canonical bytes carried in 4 different host syntaxes (Markdown fenced block, raw Elixir, commented-out Elixir inside an Elixir heredoc, Python-comment-prefixed Elixir-lookalike) with one D-02 normalization map that absorbs the per-host syntactic packaging"
    - "Two-kind comment-prefix strip in D-02 normalization: the `# ` per-line strip applies to both `:python_commented` (the .py file) AND `:elixir_in_commented_heredoc` (the install template), NOT only the Python file — this is the clarification Plan 04 captured in the install-template task"

key-files:
  created:
    - .planning/phases/97-contract-docs-first/97-04-SUMMARY.md
  modified:
    - examples/adoption_demo/lib/adoption_demo_web/router.ex (L23-27 5-line parens-form pipeline → L23-30 8-line marker-wrapped no-parens canonical-byte form; `audience: "billing-api"` added per D-13; `dpop_replay_store: AdoptionDemo.Repo` → `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` per D-04; net 6 insertions / 3 deletions)
    - priv/templates/lockspire.install/router.ex (9 lines inserted between L10 heredoc-open `"""` and the first scope at the new L20; commented-out canonical block per D-10; net 9 insertions / 0 deletions)
    - scripts/demo/adoption_smoke.py (9 lines inserted inside `exercise_authorization_code` between the userinfo assert at L242 and the protected-API exercise at the new L253; Python-comment carrier per D-03 + D-14; net 9 insertions / 0 deletions)

key-decisions:
  - "Kept the canonical-block carrier inside the install-template heredoc commented-out per D-10 (NOT live Elixir). The intent is: install-time generation produces commented-out canonical lines in the generated host router; Phase 102 SCAFFOLD-01 owns the prefix-removal step that flips it live. Live Elixir inside the heredoc would have changed the install-time host-router behavior in Phase 97, which is explicitly out of scope for this wave."
  - "Placed the install-template canonical block AT the top of the heredoc body (between heredoc-open `\"\"\"` and the first `scope`), NOT inside the existing `scope` block. Pipelines must be at module level per Phoenix router semantics (RESEARCH Pitfall 7); after Phase 102 prefix-removal flips the block live, the canonical pipeline lands at module-scope in the generated host router as required. Placement inside a scope would have produced a compile error in the generated host."
  - "Placed the Python carrier inside `exercise_authorization_code` immediately above the protected-API exercise (the L244 `anonymous_api = ...` line), NOT at module-top. This is the per-D-14 placement: keep the canonical block adjacent to where the protected-API exercise actually runs, so the smoke-script reader can trace the contract from doc-page → live router → install template → smoke exercise in one mental hop."

patterns-established:
  - "Four-site canonical-block ground truth now exists. Plan 05's content-hash test will pin all four files to the canonical SHA-256; any future edit to any of the four sites that drifts the canonical bytes will fail the test."

requirements-completed: []  # RECIPE-01 ground truth is now in place across all four carrier files, but the requirement also depends on Plan 05's content-hash test clause landing. RECIPE-01 stays "Pending" in REQUIREMENTS.md until Plan 05 completes. The orchestrator handles REQUIREMENTS.md updates after the full wave/phase completes.

# Metrics
duration: ~5min (active editing) + ~6min (first-run deps.get + mix compile cost for adoption_demo and Lockspire itself)
completed: 2026-05-27
---

# Phase 97 Plan 04: Canonical-Block Carrier Mirroring Summary

**Mirrored the Plan 02 canonical pipeline-declaration bytes into the three remaining RECIPE-01 sites — `examples/adoption_demo/lib/adoption_demo_web/router.ex` (raw Elixir, 2-space module-body indent), `priv/templates/lockspire.install/router.ex` (commented-out Elixir inside a heredoc, 4-space heredoc-interior indent, per D-10), and `scripts/demo/adoption_smoke.py` (Python-comment carrier inside `exercise_authorization_code`, 4-space function-body indent + `# ` per-line prefix per D-03 + D-14) — such that all four carrier files now extract to byte-identical canonical bytes (SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172`) after D-02 normalization, completing the four-site ground truth that Plan 05's `release_readiness_contract_test` hash-compare clause will enforce.**

## Performance

- **Started:** 2026-05-27T22:05:00Z
- **Completed:** 2026-05-27T22:09:39Z
- **Duration:** ~5 minutes of active editing; first-run `mix deps.get` + `mix compile` for both the adoption_demo umbrella and the top-level Lockspire project added another ~4-6 minutes of compile cost (standard fresh-worktree first-run cost — same pattern Plan 02's summary recorded).
- **Tasks:** 3 (Task 1 = demo router; Task 2 = install template; Task 3 = Python smoke)
- **Files modified:** 3
- **Net edits:** 24 insertions / 3 deletions across 3 files

## Accomplishments

### Task 1 — Demo router (commit `57a57bb`)

- Replaced `examples/adoption_demo/lib/adoption_demo_web/router.ex` L23-27 (5-line parens-form pipeline declaration) with the marker-wrapped canonical-byte form at L23-30 (8 lines total: 2 marker lines + 6 canonical body lines).
- Dropped parens on the three `:lockspire_protected_api` plug calls to match the docs-page canonical style established by Plan 02.
- Switched `Lockspire.Plug.EnforceSenderConstraints` from single-line parens form to multi-line no-parens form per the canonical bytes (continuation line `      dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` uses 6-space leading indent: 2 module-body + 4 continuation).
- Added `audience: "billing-api"` per D-13 (previously absent — the demo's pre-edit declaration only specified `scopes:`).
- Swapped `dpop_replay_store: AdoptionDemo.Repo` → `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` per D-04 (placeholder; reconciled in Phase 101 DEMO-01/02/03 via a demo-side alias).
- The rest of the router file is unchanged: `:browser`, `:operator`, `:api` pipelines, all `scope ... pipe_through ... get/post/...` blocks, and the existing `Lockspire.Web.AdminRouter` forward all preserved verbatim.

### Task 2 — Install template heredoc (commit `061fbbf`)

- Inserted 9 lines (8 marker+content + 1 blank) into `priv/templates/lockspire.install/router.ex` between the heredoc-open `"""` at L10 and the first scope (which moved from L11 to L20).
- All marker+content lines carry the 4-space heredoc-interior leading indent (matches the existing heredoc body indent).
- Each canonical-region body line carries the `# ` Python-style comment prefix per D-10 (these are commented-out Elixir lines inside an Elixir heredoc string — inert at install-time; Phase 102 SCAFFOLD-01 owns the prefix removal that flips them live).
- Placement is BEFORE the first `scope "/", <%= @web_module %> do` block — Phoenix-router-correct (pipelines must be at module level per RESEARCH Pitfall 7).
- No EEx tags (`<%`, `<%=`) inside the canonical region — verified via the range-pattern awk pre-flight (RESEARCH Pitfall 3 guard).

### Task 3 — Python smoke (commit `df5458b`)

- Inserted 9 lines (8 marker+content + 1 trailing blank) into `scripts/demo/adoption_smoke.py` between the userinfo assert at L242 and the protected-API exercise (which moved from L244 to L253), inside the `exercise_authorization_code` function per D-14.
- All marker+content lines carry the 4-space Python-function-body leading indent.
- Each canonical-region body line carries the `# ` Python comment prefix per D-03 (these are pure Python comments — inert at runtime; the smoke script's behavior is unchanged).
- The script still parses as valid Python: `python3 -c 'import ast; ast.parse(...)'` exits 0 and prints `python_parse_ok`.

### Cross-cutting four-site byte-equality verification (in-flight sanity check)

Before writing this summary, ran a Python sanity script that:

1. Reads each of the four carrier files.
2. Extracts the interior bytes between `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` (exclusive) and `# END LOCKSPIRE_PROTECTED_PIPELINE` (exclusive).
3. Applies the D-02 normalization map appropriate to each carrier kind.
4. Computes SHA-256 of the normalized bytes.

Result: **all four files produce the identical SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172`** — the same hash Plan 02 pinned. This confirms Plan 04's primary contract (the four-site byte-equality requirement) is honored before Plan 05 builds its automated assertion against it.

## Task Commits

| # | Task | Commit | Files | Net |
| - | --- | --- | --- | --- |
| 1 | Wrap demo router pipeline in BEGIN/END markers and reconcile to canonical bytes | `57a57bb` | `examples/adoption_demo/lib/adoption_demo_web/router.ex` | +6/-3 |
| 2 | Insert commented-out canonical block into install-template heredoc before first scope | `061fbbf` | `priv/templates/lockspire.install/router.ex` | +9/-0 |
| 3 | Insert Python-comment canonical-block carrier into adoption smoke adjacent to protected-API exercise | `df5458b` | `scripts/demo/adoption_smoke.py` | +9/-0 |

The plan-metadata commit (this SUMMARY.md) will be made in a follow-up commit after this file is written.

## Per-File Carrier Details (per output spec requirement a)

### `examples/adoption_demo/lib/adoption_demo_web/router.ex`

| Element | Line |
| --- | --- |
| `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` (2-space module-body indent) | L23 |
| `pipeline :lockspire_protected_api do` (2-space indent) | L24 |
| `plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"` (4-space indent) | L25 |
| `plug Lockspire.Plug.EnforceSenderConstraints,` (4-space indent, multi-line plug call open) | L26 |
| `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` (6-space continuation indent) | L27 |
| `plug Lockspire.Plug.RequireToken` (4-space indent) | L28 |
| `end` (2-space indent) | L29 |
| `# END LOCKSPIRE_PROTECTED_PIPELINE` (2-space module-body indent) | L30 |

### `priv/templates/lockspire.install/router.ex`

| Element | Line |
| --- | --- |
| `def lockspire_routes do` (host-Elixir, outside heredoc) | L9 |
| `"""` heredoc-open (4-space leading indent) | L10 |
| `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` (4-space heredoc-interior indent) | L11 |
| `# pipeline :lockspire_protected_api do` (4-space + `# ` prefix) | L12 |
| `#   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"` (4-space + `# ` prefix + 2-space body indent) | L13 |
| `#   plug Lockspire.Plug.EnforceSenderConstraints,` (4-space + `# ` prefix + 2-space body indent) | L14 |
| `#     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` (4-space + `# ` prefix + 4-space continuation indent) | L15 |
| `#   plug Lockspire.Plug.RequireToken` (4-space + `# ` prefix + 2-space body indent) | L16 |
| `# end` (4-space + `# ` prefix) | L17 |
| `# END LOCKSPIRE_PROTECTED_PIPELINE` (4-space heredoc-interior indent) | L18 |
| (blank line separating canonical block from first scope) | L19 |
| `scope "/", <%= @web_module %> do` | L20 |

### `scripts/demo/adoption_smoke.py`

| Element | Line |
| --- | --- |
| `assert userinfo_json["email"] == "alice@acme.test"` (closing the userinfo block) | L242 |
| (blank line — preserved from pre-edit state) | L243 |
| `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` (4-space Python-function-body indent) | L244 |
| `# pipeline :lockspire_protected_api do` (4-space + `# ` Python-comment prefix) | L245 |
| `#   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"` (4-space + `# ` + 2-space body indent) | L246 |
| `#   plug Lockspire.Plug.EnforceSenderConstraints,` | L247 |
| `#     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` (4-space + `# ` + 4-space continuation indent) | L248 |
| `#   plug Lockspire.Plug.RequireToken` | L249 |
| `# end` | L250 |
| `# END LOCKSPIRE_PROTECTED_PIPELINE` (4-space Python-function-body indent) | L251 |
| (blank line — new) | L252 |
| `anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")` | L253 |

## Canonical Region Interior Bytes Per Carrier File (per output spec requirement b)

Raw extracted interior bytes (before D-02 normalization). Plan 05's executor can use these for byte-level sanity-check ahead of the full hash compare.

### `docs/protect-phoenix-api-routes.md` (kind `:elixir_in_markdown_fence`, established in Plan 02 — unchanged in Plan 04)

```
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```

(Zero leading indent; the canonical seed.)

### `examples/adoption_demo/lib/adoption_demo_web/router.ex` (kind `:elixir`)

```
  pipeline :lockspire_protected_api do
    plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    plug Lockspire.Plug.EnforceSenderConstraints,
      dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    plug Lockspire.Plug.RequireToken
  end
```

(2-space module-body leading indent on every line; the strip-uniform-indent step in D-02 normalization takes this to zero, then it matches the canonical seed.)

### `priv/templates/lockspire.install/router.ex` (kind `:elixir_in_commented_heredoc`)

```
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
```

(4-space heredoc-interior leading indent + `# ` Python-style comment prefix on every line; D-02 normalization first strips the `# ` per line, then strips the uniform 4-space indent, then matches the canonical seed.)

### `scripts/demo/adoption_smoke.py` (kind `:python_commented`)

```
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
```

(4-space Python-function-body leading indent + `# ` Python-comment prefix; identical D-02 normalization path to the install-template carrier kind — the two strip-eligible kinds map to identical helper behavior in Plan 05.)

## D-02 Normalization Map for Plan 05 (per output spec requirement c)

Plan 05's helper applies one normalization function per carrier kind. The kind→transform mapping is:

| Path | Carrier kind | D-02 transforms applied (in order) |
| --- | --- | --- |
| `docs/protect-phoenix-api-routes.md` | `:elixir_in_markdown_fence` | (1) CRLF→LF; (3) strip uniform leading indent; (4) strip trailing whitespace per line |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | `:elixir` | (1) CRLF→LF; (3) strip uniform leading indent; (4) strip trailing whitespace per line |
| `priv/templates/lockspire.install/router.ex` | `:elixir_in_commented_heredoc` | (1) CRLF→LF; (2) strip leading `# ` from each interior line; (3) strip uniform leading indent; (4) strip trailing whitespace per line |
| `scripts/demo/adoption_smoke.py` | `:python_commented` | (1) CRLF→LF; (2) strip leading `# ` from each interior line; (3) strip uniform leading indent; (4) strip trailing whitespace per line |

The two strip-eligible kinds (`:elixir_in_commented_heredoc` and `:python_commented`) get the identical transform sequence. The two non-strip kinds (`:elixir_in_markdown_fence` and `:elixir`) get the same sequence minus the `# ` strip step.

After this normalization map, all four carrier files produce identical bytes equal to the canonical seed bytes pinned at SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172`.

## Compile/Parse Acceptance (per output spec requirement d)

| File | Acceptance command | Result |
| --- | --- | --- |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | `(cd examples/adoption_demo && mix compile --force --warnings-as-errors)` | Exit 0 — clean compile, no warnings emitted. (See "Placeholder Module Reference" section below — the expected `MyAppWeb.ProtectedApiReplayStore` warning did NOT materialize, which is even better than the plan's "at most one warning" tolerance.) |
| `priv/templates/lockspire.install/router.ex` | `mix compile --force` (top-level Lockspire) | Exit 0 — clean compile. (The template file is read by the generator at install-time; Lockspire's own `mix compile` treats it as a plain `.ex` file, and the heredoc string contents are inert at Lockspire-compile-time regardless.) |
| `scripts/demo/adoption_smoke.py` | `python3 -c 'import ast; ast.parse(open("scripts/demo/adoption_smoke.py").read()); print("python_parse_ok")'` | Exit 0, printed `python_parse_ok` — script still parseable Python after the insertion. |

## Placeholder Module Reference (per output spec requirement e)

Plan 04's behavior contract said the demo app's `mix compile` may emit a `MyAppWeb.ProtectedApiReplayStore` undefined-module warning ("warning is expected and is reconciled in Phase 101"). Observed behavior: **no warning was emitted.** The `plug Lockspire.Plug.EnforceSenderConstraints, dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` declaration evidently does not trigger a compile-time module-reference check — the value is a keyword option, not an alias/struct that the compiler would resolve eagerly. This is consistent with Plug's runtime configuration model: the option value is captured at compile time but the module is dereferenced lazily at runtime when the plug actually fires.

This means:
- For Phase 97 purposes, the demo BEAM compiles cleanly with the placeholder name in place.
- The placeholder still needs the Phase 101 reconciliation (the runtime path will fail at first request when `EnforceSenderConstraints` tries to invoke `MyAppWeb.ProtectedApiReplayStore` callbacks); Plan 04 is documentation-canonical, not runtime-canonical.
- No additional alias or stub module was added in this plan — Phase 101 DEMO-01/02/03 owns that work, exactly as the plan specified.

Not a regression; not a deviation. Just a relaxed-vs-stricter expectation that landed on the better side.

## `plug(` Count Verification (per output spec requirement f)

Pre-edit and post-edit `grep -cE 'plug\(' examples/adoption_demo/lib/adoption_demo_web/router.ex` counts:

| Stage | Count | Composition |
| --- | --- | --- |
| Pre-edit (verified 2026-05-27 before Task 1) | `11` | 3 in `:browser` + 1 in `:operator` + 1 in `:api` + 3 in `:lockspire_protected_api` + 3 in scope `pipe_through` declarations |
| Post-edit (verified 2026-05-27 after Task 1) | `8` | 3 in `:browser` + 1 in `:operator` + 1 in `:api` + 0 in `:lockspire_protected_api` (the canonical-region plug calls dropped parens) + 3 in scope `pipe_through` declarations |
| Delta | -3 | Matches expected = pre-edit 11 − 3 parens-dropped on the three `:lockspire_protected_api` plug calls. |

The parens-drop landed on exactly the three `:lockspire_protected_api` plug calls (canonical-region body), as planned. The other 8 parens-form `plug(` calls in non-target pipelines and scope `pipe_through` declarations are unchanged.

## Range-Pattern awk EEx Pre-Flight (per output spec requirement g)

```bash
awk '/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE/,/# END LOCKSPIRE_PROTECTED_PIPELINE/' priv/templates/lockspire.install/router.ex | grep -E '<%|<%='
```

**Observed output:** EMPTY (grep exit code = 1, meaning no match found).

This confirms RESEARCH Pitfall 3 closure: there are no EEx tags (`<%`, `<%=`) inside the canonical region in the install template. The EEx tags `<%= @web_module %>` and `<%= @mount_path %>` that exist elsewhere in the file (at L20, L36/47, L44, L50) are all outside the canonical region.

## Decisions Made

- **Heredoc-canonical block placement (between heredoc-open and first scope).** The plan was explicit but worth recording: pipelines must be at module level (Phoenix router semantics, RESEARCH Pitfall 7), so the canonical block goes between the `"""` heredoc-open at L10 and the first `scope "/", <%= @web_module %> do` at the new L20. After Phase 102 SCAFFOLD-01 flips the `# ` prefix off, the canonical lines land at module-scope in the generated host router as required.

- **Python carrier placement inside `exercise_authorization_code`, immediately above L244.** Per D-14, the canonical block is adjacent to the protected-API exercise so a reader can trace the contract from doc-page → live router → install template → smoke exercise in one mental hop. Module-top placement would have separated the documentation-canonical bytes from the runtime exercise they describe, weakening the smoke script's pedagogical value.

- **No demo-side `AdoptionDemo.ProtectedApiReplayStore` alias added in this plan.** Plan 04 is documentation-canonical, not runtime-canonical. Adding the alias here would have leaked Phase 101 DEMO-01/02/03 scope into Phase 97. The placeholder name `MyAppWeb.ProtectedApiReplayStore` matches the docs and is reconciled at runtime in Phase 101.

## Deviations from Plan

None — plan executed exactly as written. All grep counts matched their predicted values on the first try; both Elixir compiles and the Python parse succeeded on the first run.

The only observation worth flagging is the relaxed-vs-stricter outcome on the `MyAppWeb.ProtectedApiReplayStore` placeholder warning: the plan said "at most one warning is expected"; the actual observation was zero warnings. This is the better-than-expected outcome and required no action.

## Authentication Gates

None — no external service authentication required for this plan (file edits + local `mix compile` + local `python3 -c ast.parse`).

## Stub Tracking

No stubs introduced by this plan. The `MyAppWeb.ProtectedApiReplayStore` placeholder is intentional and is the canonical name across all four carrier sites; Phase 101 DEMO-01/02/03 owns the demo-side reconciliation, which is correctly out-of-scope for Phase 97.

## Issues Encountered

- **Worktree had no `_build`/`deps` for either the adoption_demo umbrella or the top-level Lockspire project.** First-run cost of a fresh worktree. Ran `mix deps.get` once per project before `mix compile`. Standard Phase 97 worktree behavior (Plan 02's summary recorded the same cost for the Lockspire project; this plan added the same cost for the adoption_demo subproject).
- **No other issues.** All three task edits, all grep verifications, both `mix compile` runs, and the Python parse all passed on the first attempt.

## User Setup Required

None — no external service configuration, no env var, no schema change, no secret, no deps change.

## Threat Flags

(none — Phase 97 introduces no new attack surface per `.planning/phases/97-contract-docs-first/97-RESEARCH.md` `## Security Domain`. This plan edits three files: a live Phoenix router (no auth/input handling changes; only the canonical pipeline declaration is restructured into marker-wrapped form with a placeholder module name), an EEx-interpolated install template (commented-out content is inert in any generated host; no EEx tag introduced inside the canonical region — RESEARCH Pitfall 3 guard), and a Python smoke script (comment-prefixed lines change no runtime behavior). Phase 98 (V5 Input Validation for the hardened plug) and Phase 99 (V6 Cryptography for the extracted `Protocol.AccessTokenSigner`) carry the security work for v1.27.)

## Next Phase Readiness

- **Plan 05 (`release_readiness_contract_test` content-hash clause) is fully unblocked.** All four carrier files now extract to the canonical bytes after D-02 normalization (verified in-flight via Python sanity check, SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172` across all four files). Plan 05's content-hash clause can be written confidently against this pin.
- **Phase 101 DEMO-01/02/03 carries the placeholder reconciliation.** When the demo runtime needs the `MyAppWeb.ProtectedApiReplayStore` placeholder to resolve to a real module (e.g., for the demo BEAM to handle actual DPoP requests against the protected route), Phase 101 adds a thin `AdoptionDemo.ProtectedApiReplayStore` alias and/or shipped Repo-backed implementation. The canonical block in `examples/adoption_demo/lib/adoption_demo_web/router.ex` does not need any change in Phase 101 — only the alias module is added.
- **Phase 102 SCAFFOLD-01 owns the install-template `# ` prefix removal.** When the generated host router should carry the canonical block live (not commented-out), Phase 102 strips the `# ` prefix per line inside the canonical region in `priv/templates/lockspire.install/router.ex`. The BEGIN/END markers stay (they become the extraction anchors for future drift detection in generated hosts too).
- **No blockers for Wave 4 (Plan 05).**

## Self-Check: PASSED

- File `.planning/phases/97-contract-docs-first/97-04-SUMMARY.md` exists at the expected path (this file).
- File `examples/adoption_demo/lib/adoption_demo_web/router.ex` exists with BEGIN=1, END=1, `MyAppWeb.ProtectedApiReplayStore`=1, `AdoptionDemo.Repo`=0, `audience: "billing-api"`=1, `plug(`=8 — all expected.
- File `priv/templates/lockspire.install/router.ex` exists with BEGIN=1, END=1, `# pipeline :lockspire_protected_api do`=1, `MyAppWeb.ProtectedApiReplayStore`=1, EEx pre-flight empty — all expected.
- File `scripts/demo/adoption_smoke.py` exists with BEGIN=1, END=1, `# pipeline :lockspire_protected_api do`=1, `MyAppWeb.ProtectedApiReplayStore`=1, and `python3 ast.parse` prints `python_parse_ok` — all expected.
- Commits `57a57bb`, `061fbbf`, `df5458b` all exist in `git log --oneline` (verified via `git rev-parse --short HEAD` after each commit).
- Four-site canonical-region SHA-256 sanity check passes: all four files (docs, demo router, install template, Python smoke) produce `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172` after D-02 normalization.

---
*Phase: 97-contract-docs-first*
*Plan: 04*
*Completed: 2026-05-27*
