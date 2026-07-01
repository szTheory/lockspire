# Phase 97: Contract + Docs First - Research

**Researched:** 2026-05-27
**Domain:** Docs-as-contract refactor + cross-file content-hash invariant (Elixir/Phoenix embedded library)
**Confidence:** HIGH (all evidence verified against current source; no external library or version choices to validate)

## Summary

Phase 97 is a docs-shaped phase with one runtime touch-point (the `release_readiness_contract_test` four-file content-hash clause). Every implementation decision is locked in CONTEXT.md (D-01 through D-12) and the Branch A + JWT-default issuance design is locked in `.planning/PROJECT.md` Key Decisions. There are no new libraries to evaluate, no architectural alternatives to weigh, and no version drift to check — `:jose`, `:plug`, `:nimble_options`, `:ecto_sql`, `:postgrex`, and `:crypto` (Erlang stdlib, used for `sha256`) are all already in `mix.exs` and unchanged by Phase 97.

The research work is **grounding**: confirming the current-state evidence the planner needs to write tasks with verifiable acceptance criteria. That means locking in exact line numbers, current literal content at each of the four canonical insertion sites, the regex/assert idioms already established in `release_readiness_contract_test.exs`, and the Phase 92 assertions that Phase 97 must not invalidate. Every evidence claim below was verified by direct file read on 2026-05-27.

**Primary recommendation:** The planner should treat this phase as a sequenced edit job, not an investigation. Order the plans (1) install-template + demo-router marker insertion → (2) DOCS-01 rewrite → (3) DOCS-02 subsection → (4) saas-adoption-recipe cross-link → (5) Python smoke marker insertion → (6) `release_readiness_contract_test` content-hash clause. The hash clause lands LAST in the dependency chain (everything else must be byte-stable first) but should ship in the SAME merge — landing the four marker insertions without the hash assertion would create a window where drift cannot be detected.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Canonical pipeline-block shape and hashing mechanism**
- **D-01:** The canonical pipeline-declaration block is the **full `pipeline :lockspire_protected_api do ... end` Elixir form** — wrapper included — anchored in each of the four files by explicit marker comments `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE` and `# END LOCKSPIRE_PROTECTED_PIPELINE`. Markers are the load-bearing locator; the block content between them is what gets hashed.
- **D-02:** `release_readiness_contract_test` adds one new clause that, for each of the four files, extracts the bytes between `BEGIN` and `END` markers, normalizes (left-strips the per-file uniform indent; strips the leading `# ` from each interior line on the Python file only), then `:crypto.hash(:sha256, normalized)` compares all four hashes — failing loudly with a diff if any pair differs.
- **D-03:** The Python smoke script `scripts/demo/adoption_smoke.py` carries the canonical block as a Python-comment block (every interior `.ex` line prefixed `# `) between the same `BEGIN/END` markers. After the normalization step in D-02, the post-strip byte sequence is identical across `.ex` and `.py` files.
- **D-04:** Reconcile the existing `dpop_replay_store:` drift by adopting the **placeholder name `MyAppWeb.ProtectedApiReplayStore`** in the canonical block. The demo's current `AdoptionDemo.Repo` value will be re-wired in Phase 101 (DEMO-01/02/03 already touch the demo pipeline) to consume this name via a thin adopter-side alias, so the canonical block can land byte-identical in Phase 97 without breaking demo runtime.

**DOCS-01 page restructure depth and forward-reference honesty**
- **D-05:** Apply a **section-level rewrite** to `docs/protect-phoenix-api-routes.md`: lead, canonical-plug-order section, and failure table get rewritten; assigns-contract, ownership-boundary, and repo-owned-proof sections stay intact (additive only). This preserves the Phase 92 `assert_protected_routes_guide!` assertions at `test/support/advanced_setup_support_truth.ex:69-80` without parallel test edits.
- **D-06:** The DOCS-01 contract sentence ("Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page.") is the page's lead, written in present-tense contract form.
- **D-07:** Append one explicit **forward-reference caveat sentence** immediately after the DOCS-01 contract lead, scoped to the milestone branch only: *"This page describes the contract `Lockspire.Plug.VerifyToken` enforces; the runtime narrowing and the default-issuance flip land in v1.27. Until v1.27 is fully shipped, opaque tokens may still be silently accepted on these routes."* Phase 102 deletes this caveat sentence as part of the issuance-flip-shipped sweep.
- **D-08:** The page continues to defer to `docs/supported-surface.md` as the canonical public support contract (preserve the existing cross-link at `docs/protect-phoenix-api-routes.md:5`). Phase 92's canonical-authority hierarchy stays intact.

**DOCS-02 placement, install-template SCAFFOLD-01 deferral, and adjacent-surface deference**
- **D-09:** DOCS-02 lands as a new `## Explicit non-goals for host-API route protection` subsection in `docs/supported-surface.md`, inserted immediately after the existing out-of-scope list (around line 113-138). Each rejected pattern is a one-line bullet with a brief "why rejected" clause sourced from `.planning/REQUIREMENTS.md:103-110`.
- **D-10:** The install template `priv/templates/lockspire.install/router.ex` is the fourth content-hashed file from Phase 97 merge day. The canonical pipeline block ships as **commented-out Elixir inside the existing heredoc string** between the `BEGIN/END` markers. Comment-prefixed lines are inert in the generated host router, so the template stays compile-clean on milestone-branch installs. Phase 102 SCAFFOLD-01 removes the leading `#` prefixes (and tightens surrounding prose) — the canonical block's content is unchanged across Phase 97 → 102, so the content hash holds the entire milestone.
- **D-11:** `docs/saas-adoption-recipe.md` (currently restating the three plug names at line 50) gets edited to **replace the plug-name restatement with a cross-link to `docs/protect-phoenix-api-routes.md`**. This closes the silent fifth-surface drift class — only the four RECIPE-01 locations carry the pipeline names.
- **D-12:** No other doc, guide, or template gets a new restatement of the canonical pipeline block in Phase 97. If a future phase wants to reference the pipeline, it cross-links the canonical page, not the plug names. Grep-time guard: a discovered fifth restatement on review is a Phase 97 bug.

### Claude's Discretion
- Exact wording, header hierarchy, and cross-link placement inside the rewritten lead/canonical-plug-order/failure-table sections of `docs/protect-phoenix-api-routes.md`, provided the contract sentence (D-06) and forward-reference caveat (D-07) appear verbatim.
- Exact bullet wording inside the new `## Explicit non-goals for host-API route protection` subsection of `docs/supported-surface.md`, provided the four rejected patterns and their rejection-rationale phrases (D-09) are preserved.
- Exact Elixir formatting of the canonical pipeline block (with-parens vs without-parens, single-line vs multi-line `plug` calls), provided the same form is byte-identical inside the four `BEGIN/END` marker regions after the D-02 normalization step.
- Exact whitespace/comment conventions inside the `release_readiness_contract_test` helper that does the four-file extraction + hash compare, provided the failure message names which file pair drifted.

### Deferred Ideas (OUT OF SCOPE)
- Optional research tightenings (RFC 9068 `at+jwt` glossing convention; embedded-Elixir-library precedent for SHA-256 cross-host-syntax content-hashing via marker comments) — both currently Likely confidence, neither blocking.
- Separate-file carrier for the canonical block (e.g., `priv/templates/lockspire.install/protected_pipeline_block.eex.commented`) — rejected on letter-of-RECIPE-01 grounds; defer entirely.
- Broader doc architecture refactor across `docs/install-and-onboard.md`, `docs/mtls-host-guide.md`, etc. — explicitly out of scope; Phase 92's canonical-authority hierarchy stays as-is.
- Telemetry on doc-reading or content-hash drift detection in production — telemetry surfaces land in Phase 102 (TELEMETRY-01) and target runtime verification, not doc-state monitoring.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support |
|----|------------------------------------|------------------|
| RECIPE-01 | One canonical pipeline-declaration block lives in exactly four places — `docs/protect-phoenix-api-routes.md`, `examples/adoption_demo/lib/adoption_demo_web/router.ex`, `priv/templates/lockspire.install/router.ex`, and `scripts/demo/adoption_smoke.py` (referenced by comment) — and a `release_readiness_contract_test` clause fails if the content hash drifts between any two of them. | Current-state evidence below confirms current line numbers and existing pipeline declarations at all four sites; the `release_readiness_contract_test.exs` already uses `Regex.run/3` with `~r/.../ms` flags + `File.read!/1` (precedent in `release_workflow_job/2` at lines 111-122), so the extract-normalize-hash clause is a straightforward extension. `:crypto.hash/2` is Erlang stdlib — no dependency. |
| DOCS-01 | `docs/protect-phoenix-api-routes.md` becomes the single authoritative protected-route page. States the contract sentence quoted in D-06 verbatim. | Section-level rewrite per D-05 preserves the 8 substrings asserted by Phase 92's `assert_protected_routes_guide!/1` (test/support/advanced_setup_support_truth.ex:69-80) — verified that all 8 substrings live in the assigns-contract, failure-behavior, and ownership-boundary sections that D-05 marks intact. New contract sentence (D-06) and forward-reference caveat (D-07) land in the lead. |
| DOCS-02 | `docs/supported-surface.md` records the explicit non-goals: no introspection-at-the-RS as the host-API seam, no auto-detection of token shape, no dual-verifier dispatcher, no RAR enforcement at the RS plug. | New `## Explicit non-goals for host-API route protection` subsection inserted after the existing out-of-scope list at lines 113-138 (verified). Phase 92's `assert_advanced_setup_support_contract!/1` (test/support/advanced_setup_support_truth.ex:4-29) asserts 5 out-of-scope substrings already present in lines 120, 123, 129 — none of those are affected by appending a new subsection. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|-----------------|-----------|
| Adopter-facing doc rewrite (DOCS-01) | Documentation (`docs/`) | — | Markdown-only edit; no runtime touch. |
| Public support contract update (DOCS-02) | Documentation (`docs/supported-surface.md`) | — | Canonical-authority hierarchy per Phase 92 D-01. |
| Canonical pipeline block in live router | Demo application (`examples/adoption_demo/`) | — | Real runtime; D-04 placeholder is doc-canonical, demo wires through Phase 101 alias. |
| Canonical pipeline block in install template | Generator template (`priv/templates/`) | — | Heredoc-commented; inert at generation time per D-10. |
| Canonical pipeline block as carrier in smoke | CI smoke script (`scripts/demo/`) | — | Python-comment block; no runtime effect per D-03. |
| Cross-file hash invariant | Test infrastructure (`test/lockspire/release_readiness_contract_test.exs`) | Erlang stdlib (`:crypto`) | Test-time SHA-256 over normalized byte sequences; precedent for regex extraction already established. |
| Plug-name restatement removal (D-11) | Documentation (`docs/saas-adoption-recipe.md`) | — | One-line cross-link replacement; closes fifth-surface drift class. |

**Why this matters:** Every Phase 97 capability lives in one of three architectural lanes — `docs/`, `examples/adoption_demo/`, or `test/`. Misassignment risk is essentially zero. The one cross-tier touch (test/ reading examples/, docs/, priv/, scripts/) is already precedented by the existing test (which reads `docs/`, `.github/workflows/`, `scripts/conformance/`, etc.).

## Standard Stack

### Core (no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (Erlang stdlib) | OTP 27 (bundled with Elixir ~> 1.18) | `:crypto.hash(:sha256, binary)` for the four-file content-hash | Always available; no Hex dep; what `release_readiness_contract_test` would idiomatically reach for. `[VERIFIED: Erlang docs erlang.org/doc/apps/crypto/crypto.html#hash-2]` |
| `Regex` (Elixir stdlib) | Elixir ~> 1.18 | `~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t#]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms` extraction | Existing precedent at `release_readiness_contract_test.exs:111-122` uses identical `~r/.../ms` flag pattern with `Regex.run/3 capture: :all_but_first` — extension, not foreign mechanism. `[VERIFIED: direct file read]` |
| `File.read!/1` (Elixir stdlib) | Elixir ~> 1.18 | Read the four canonical files at test-time | Used throughout `release_readiness_contract_test.exs` (verified at lines 86, 88, 94, 105, etc.) `[VERIFIED: direct file read]` |
| `ExUnit.Case` with `async: true` | Elixir ~> 1.18 | Test runner — existing harness | The test already declares `async: true` at line 2 — adding one new `test "..." do ... end` block preserves the async posture. `[VERIFIED: direct file read]` |

### No new packages — Package Legitimacy Audit not required

Phase 97 installs zero external packages. The slopcheck protocol is skipped because there is nothing to verify on Hex/PyPI. If the planner uncovers a hidden dependency need during plan-decomposition (genuinely unexpected — none of the four file edits or the test clause require one), trigger the protocol then.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:crypto.hash(:sha256, ...)` | `Plug.Crypto.secure_compare/2` for the comparison side | Not equivalent: `secure_compare` is for constant-time secret comparison; the use case here is invariant proof, not secret handling. `:crypto.hash` + plain `==` is canonical. |
| Regex marker extraction | `String.split/2` on the marker strings | Loses positional context for failure messages; regex with capture group lets the test report which file is missing markers cleanly. Existing precedent uses regex. |
| One mega-assertion comparing all four hashes | Pairwise assertions naming each drift pair | Pairwise gives operators the exact "file A drifted from file B" diagnostic. CONTEXT.md D-02 explicitly requires the failure-message naming. |

## Architecture Patterns

### System Architecture Diagram

```
                Phase 97 invariant flow (at test time)
                ─────────────────────────────────────────────────────
                                  │
                       File.read!/1 × 4 files
                  ┌───────────────┼───────────────┬───────────────┐
                  │               │               │               │
                  ▼               ▼               ▼               ▼
            docs/protect-   examples/      priv/templates/   scripts/demo/
            phoenix-api-    adoption_demo/ lockspire.install/ adoption_smoke.py
            routes.md       lib/..._web/   router.ex          (Python comments)
                            router.ex       (heredoc, commented)
                  │               │               │               │
                  │               │               │               │
                  ▼               ▼               ▼               ▼
        Regex extract between BEGIN/END markers  (~r/.../ms capture)
                  │               │               │               │
                  ▼               ▼               ▼               ▼
                Normalize:
                  • left-strip per-file uniform indent
                  • on Python file only: strip leading `# ` from each line
                  │               │               │               │
                  ▼               ▼               ▼               ▼
              :crypto.hash(:sha256, normalized_bytes) per file
                  │               │               │               │
                  └───────────────┴───────┬───────┴───────────────┘
                                          │
                                          ▼
                            Pairwise compare 4 hashes
                                          │
                          ┌───────────────┴───────────────┐
                          ▼                               ▼
                  All equal → pass             Any pair differs →
                                               raise with explicit diff
                                               naming the two files
```

### Recommended Project Structure (Phase 97 touches only)

```
docs/
├── protect-phoenix-api-routes.md     # DOCS-01 lead + canonical-plug-order + failure-table REWRITTEN; rest intact
├── supported-surface.md              # NEW subsection after line 138 (## Explicit non-goals for host-API route protection)
└── saas-adoption-recipe.md           # Line 50 plug restatement → cross-link

examples/adoption_demo/
└── lib/adoption_demo_web/router.ex   # Add BEGIN/END markers around lines 23-27 block; pipeline body replaced with canonical form

priv/templates/lockspire.install/
└── router.ex                         # NEW commented canonical block inside existing heredoc (D-10)

scripts/demo/
└── adoption_smoke.py                 # NEW Python-comment block at top-of-file or near pipeline test (planner's discretion)

test/lockspire/
└── release_readiness_contract_test.exs  # NEW test clause + (optional) shared helper for extract/normalize/hash
```

### Pattern 1: Marker-Comment Anchored Region Extraction

**What:** A `BEGIN/END` marker pair around the load-bearing bytes, with the markers themselves NOT part of the hashed region.

**When to use:** When the load-bearing assertion is byte-equality across files with different syntaxes (Elixir vs Python in this case). Marker comments are inert in both syntaxes.

**Example (extraction regex shape):**
```elixir
# Source: extending the precedent at release_readiness_contract_test.exs:111-122
~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n\s*# END LOCKSPIRE_PROTECTED_PIPELINE/ms
```

**Anchor token:** `LOCKSPIRE_PROTECTED_PIPELINE` (verbatim, case-sensitive, per CONTEXT.md specifics) — establishes a project-wide convention. Future GSD phases that need a content-hashed region pick their own token (`LOCKSPIRE_<SUBJECT>`).

### Pattern 2: Per-File Normalization Function

**What:** A pure function `normalize(bytes, file_kind) :: binary` that runs after extraction. Two normalizations per D-02:

1. **Left-strip uniform indent.** Compute minimum leading-whitespace count across non-blank lines; strip that many spaces from every line. Makes the heredoc-indented and bare-`.ex` forms agree.
2. **Strip Python comment prefix** (Python file only). Each interior line starts with `# ` (literal hash + space); strip exactly those two characters per line.

**Why this order:** The Python file's interior lines start with `# ` (Python comment), so the Elixir block `plug Lockspire.Plug.VerifyToken, ...` becomes `# plug Lockspire.Plug.VerifyToken, ...` in Python. Strip the `# ` first only for `.py`, then left-strip uniform indent across all four files. Output bytes must be identical.

### Pattern 3: Pairwise Hash Comparison with Named Diff Failure

**What:** Compute all four hashes once; iterate the pairs (4 choose 2 = 6 comparisons) and assert each pair equal with a failure message naming both files in the drifted pair.

**Example shape (discretionary per CONTEXT.md):**
```elixir
files = [
  {"docs/protect-phoenix-api-routes.md", :elixir},
  {"examples/adoption_demo/lib/adoption_demo_web/router.ex", :elixir},
  {"priv/templates/lockspire.install/router.ex", :elixir_in_heredoc},
  {"scripts/demo/adoption_smoke.py", :python_commented}
]

hashes =
  Enum.map(files, fn {path, kind} ->
    bytes = path |> File.read!() |> extract_canonical_region!() |> normalize(kind)
    {path, :crypto.hash(:sha256, bytes)}
  end)

for {path_a, hash_a} <- hashes, {path_b, hash_b} <- hashes, path_a < path_b do
  assert hash_a == hash_b,
         "canonical pipeline block drifted between #{path_a} and #{path_b}"
end
```

### Anti-Patterns to Avoid

- **Hashing the markers themselves** — invalidates the test the moment the marker comments are reformatted (e.g., trailing whitespace fix). Extract bytes between markers, not including them.
- **Using `String.replace/3` to strip the Python `# ` prefix without anchoring to line start** — could chew into legitimate Elixir-source `#` characters (unlikely in a Phoenix pipeline block but a sharp edge). Use line-by-line processing with `String.split/2` on `"\n"` + per-line `String.replace_prefix/2`.
- **Asserting hash equality only against the first file** — masks which file is the "wrong" one. The first file might be the drifted one. Pairwise comparison surfaces the drift symmetrically.
- **Letting the test pass when ANY marker pair is missing** — if the test extracts an empty region from a file because the markers were renamed/deleted, the hashes might all coincidentally equal `sha256("")`. Defend with a sanity assertion: extracted region MUST contain `Lockspire.Plug.VerifyToken` substring before hashing.
- **Putting the test in a separate `.exs` file** — breaks the canonical-test-home convention. `release_readiness_contract_test.exs` is the durable home per CONTEXT.md Reusable Assets.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-file byte-equality with different host syntaxes | A custom AST normalizer per host language | Marker-comment anchored regions + textual normalization | AST normalization for Elixir alone would need `Code.string_to_quoted/1` round-tripping (lossy on comments/whitespace); for Python it's a non-starter. Marker-comment textual extraction is the standard pattern. |
| SHA-256 of file content | A custom hashing helper | `:crypto.hash(:sha256, binary)` | Erlang stdlib; constant-time within OTP; FIPS-aware. No reason to wrap. |
| Regex extraction with named captures | An inline state machine over lines | `Regex.run(~r/.../ms, content, capture: :all_but_first)` | Existing precedent at `release_readiness_contract_test.exs:115-119` (the `release_workflow_job/2` helper) uses the same shape with `[ms]` flags; the planner should mirror it. |
| Diff visualization in failure messages | A diff library | Plain `assert hash_a == hash_b` + `inspect/1` of the file pair | ExUnit's default failure formatter shows the two hashes on mismatch — operators run `mix test --trace` and then can `git diff` the extracted regions. Diff lib would be over-engineered. |

**Key insight:** Phase 97's "Don't Hand-Roll" list is short because the load-bearing surface is small. The biggest temptation is to invent an AST-based normalization for the Elixir side — resist it. Marker-comment textual normalization is the canonical cross-language content-pinning pattern, and CONTEXT.md D-01/D-02 explicitly endorse it.

## Runtime State Inventory

> **Not applicable.** Phase 97 is a docs/refactor phase with no rename, migration, or removal of stored state. The one symbolic change (the placeholder name `MyAppWeb.ProtectedApiReplayStore` in the canonical block per D-04) is documentation-canonical: it does not yet appear in any stored data, live service config, OS-registered state, secrets file, or installed package. Phase 101 will introduce a thin adopter-side alias in the demo to consume this name — runtime state inventory belongs to Phase 101, not Phase 97.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified no DB/cache/store references the canonical block content | — |
| Live service config | None — no external service config touches these files | — |
| OS-registered state | None — no scheduled tasks, systemd units, launchd plists reference these files | — |
| Secrets/env vars | None — no secret keys reference the placeholder `MyAppWeb.ProtectedApiReplayStore` | — |
| Build artifacts | None — Phase 97 changes no compiled output; the install template heredoc is interpolated by `Lockspire.Generators.Templates`; verified the canonical block lives commented inside the heredoc and thus does not affect generator-rendered output | — |

## Current-State Evidence (verified by direct file read, 2026-05-27)

This section grounds the planner with the exact current state at each insertion site. Every line number and quoted content is from a Read tool call on 2026-05-27.

### Evidence 1: `examples/adoption_demo/lib/adoption_demo_web/router.ex` (file: 68 lines)

**Lines 23-27 (current pipeline declaration):**
```elixir
  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken, scopes: ["read:billing"])
    plug(Lockspire.Plug.EnforceSenderConstraints, dpop_replay_store: AdoptionDemo.Repo)
    plug(Lockspire.Plug.RequireToken)
  end
```

**Drift to reconcile per D-04:** `dpop_replay_store: AdoptionDemo.Repo` becomes `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` in the canonical block. `AdoptionDemo.Repo` is a legitimate replay-store implementer today (verified at `examples/adoption_demo/lib/adoption_demo/repo.ex:24-26` it implements `record_dpop_proof/1`); Phase 101 will add the adopter-side alias.

**Also notable:** the demo's current `audience:` option is MISSING (verified: line 24 only specifies `scopes:`). Phase 101 DEMO-03 explicitly adds it. Phase 97's canonical block per D-06 names the contract — the canonical block in the docs page (`docs/protect-phoenix-api-routes.md:12-18`) currently declares `audience: "billing-api"`. The planner must reconcile: the canonical block written into all four sites must INCLUDE `audience: "..."` to keep the docs honest and force Phase 101 to add it to the live demo. **This is the same decision that D-04 makes for `dpop_replay_store:` — pick a placeholder; Phase 101 reconciles runtime.** Suggested placeholder following D-04's naming convention: `audience: "billing-api"` (matches current docs).

### Evidence 2: `priv/templates/lockspire.install/router.ex` (file: 55 lines)

The file is an EEx-interpolated heredoc that defines `lockspire_routes/0`. The heredoc body opens at line 10 (`"""`) and closes at line 52 (`"""`). Interior indentation is **4 spaces from column 0** (i.e., the heredoc string starts at column 4).

**Current heredoc body (verified, lines 11-51):** scopes for `/verify`, `/authorized-apps`, the admin mount example, and the public OAuth forward. No `:lockspire_protected_api` pipeline exists today. Phase 97 D-10 adds it commented-out; Phase 102 SCAFFOLD-01 uncomments.

**Insertion guidance for the planner:**
- The canonical block goes BEFORE the `scope "/", <%= @web_module %> do` block (line 11) — pipelines must be declared at module level before they can be `pipe_through`'d in a scope.
- Each interior line inside the heredoc needs to start with `    # ` (4-space indent + `# ` Python-style comment) so the rendered host router gets the lines as inert Elixir comments after EEx interpolation.
- Markers: `    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE` and `    # END LOCKSPIRE_PROTECTED_PIPELINE` at heredoc-interior indent.

**Compile-cleanness verification:** After EEx renders, host routers will receive `    # pipeline :lockspire_protected_api do` etc. — those are valid Elixir comments. The generated router stays compile-clean.

### Evidence 3: `docs/protect-phoenix-api-routes.md` (file: 113 lines)

**Current structure (verified by section-header scan):**
- L1-2: Title + lead paragraph (rewrite per D-05)
- L5: Existing cross-link to `docs/supported-surface.md` (preserve per D-08)
- L7-18: `## Canonical plug order` with first fenced Elixir code block at L11-18 (rewrite per D-05; this fenced block hosts BEGIN/END markers)
- L20-24: Prose paragraphs about each plug's responsibility (preserve)
- L26-37: `## Example route` (preserve)
- L39-49: `## Scope-restricted route example` (preserve — does NOT carry the canonical block)
- L51-62: `## Audience-restricted route example` (preserve — does NOT carry the canonical block)
- L64-77: `## Access-token assigns contract` (preserve — Phase 92 asserts substrings here)
- L79-87: `## Failure behavior` table (rewrite per D-05)
- L89-104: `## Ownership boundary` (preserve — Phase 92 asserts substrings here)
- L106-112: `## Repo-owned proof` (preserve)

**Critical:** Only the FIRST fenced Elixir code block (L11-18) carries the canonical block markers. The two later fenced blocks (L41-47 scope-restricted, L53-59 audience-restricted) are SECONDARY examples and are explicitly NOT content-hashed per D-12 ("no other doc, guide, or template gets a new restatement of the canonical pipeline block in Phase 97"). The planner must decide whether to keep those secondary examples (which currently restate `Lockspire.Plug.*` names) or remove them. **Recommendation:** keep the secondary examples but reword them to refer back to the canonical block ("see the canonical pipeline above; this example uses only `scopes:`...") rather than restate the three plug names. Otherwise we resurrect the fifth-restatement risk D-11/D-12 close.

### Evidence 4: `scripts/demo/adoption_smoke.py` (file: 306 lines)

The script is a standalone Python smoke. No existing Python-comment block carries Elixir source today. The protected-API exercise lives at L244-245:

```python
    anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")
    assert_status(anonymous_api, 401, "protected API rejects anonymous request")
```

**Insertion guidance:** Place the Python-comment block adjacent to the protected-API test (L244) so a reader hitting the canonical block sees the smoke that exercises the surface the block describes. Suggested placement: immediately above L244 (inside the `exercise_authorization_code` function). Interior indent: 4 spaces (matches Python function-body indent). Each interior line: `    # ` + `<elixir source>`.

**Alternative placement:** Top-of-file module-docstring-equivalent (above `def main`). Trades adjacency for visibility. Planner's discretion per CONTEXT.md ("exact placement" not locked).

### Evidence 5: `test/lockspire/release_readiness_contract_test.exs` (file: 1032 lines)

**Test is `async: true`** (verified at L2 `use ExUnit.Case, async: true`) — adding one new `test` block preserves async posture.

**Existing module attributes for the four target files:**
- `@protect_phoenix_api_routes_path` defined at L71-74
- `@saas_adoption_recipe_path` defined at L75
- **NOT yet defined:** install-template path, demo-router path, adoption-smoke-script path. The planner must add these three module attributes.

**Established regex-extract precedent** (verified at L111-122):
```elixir
defp release_workflow_job(name, next_name) do
  @release_workflow_path
  |> File.read!()
  |> then(
    &Regex.run(
      ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
      &1,
      capture: :all_but_first
    )
  )
  |> List.first()
end
```

The new canonical-pipeline extractor should mirror this shape. Suggested helper signature: `defp extract_canonical_pipeline!(path, kind) :: binary` returning normalized bytes ready to hash.

**Phase 92's `assert_protected_routes_guide!/1` (called at L655):** asserts 8 substrings (verified at `test/support/advanced_setup_support_truth.ex:69-80`). All 8 substrings live in the assigns-contract, failure-behavior, and ownership-boundary sections — verified that:
- `"For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md)."` is at line 5 (preserved per D-08)
- `"Lockspire.Plug.VerifyToken"`, `"Lockspire.Plug.EnforceSenderConstraints"`, `"Lockspire.Plug.RequireToken"` will be in the rewritten canonical-plug-order section (still required)
- `"no-op for unconstrained bearer tokens"` is at line 22 (preserve in canonical-plug-order section)
- `"error=\"use_dpop_nonce\""` is at line 87 (in failure table — D-05 marks failure table as REWRITTEN, so the planner must preserve this substring through the rewrite)
- `"business authorization"` (lowercase, literal) CORRECTION (verified 2026-05-27 via direct `grep -n`): exists at L3 (REWRITTEN) AND L22 (PRESERVED per D-05). L100 carries the CAPITALIZED form `Business authorization` which does NOT match Phase 92's literal lowercase substring assertion — survives the rewrite via L22.
- `"tenant checks"` (lowercase, literal) CORRECTION (verified 2026-05-27 via direct `grep -n`): exists ONLY at L3 (the lead Plan 02 wholesale REWRITES). Prior research claim of multiple sites at L22/24/76-77/102-103 was WRONG — those lines carry `this tenant` (L77) and `Tenant and account policy` (L101), neither matching the literal lowercase substring. Plan 02 Task 1 Step 3 MUST re-inject `tenant checks` into the rewritten canonical-plug-order introductory prose or the Phase 92 helper assertion regresses RED. (Source: revision iteration 1 plan-checker BLOCKER #1.)

**Plan implication:** the DOCS-01 rewrite plan must include an explicit acceptance criterion: `assert_protected_routes_guide!(File.read!("docs/protect-phoenix-api-routes.md"))` returns `:ok`. The plan-checker should verify this is in the plan's acceptance criteria.

### Evidence 6: `docs/saas-adoption-recipe.md:50` (D-11 target — verified)

**Exact current line 50:**
```
- If exposing API routes, protect one host route with `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`.
```

**Replace with (planner's discretion on wording):**
```
- If exposing API routes, follow the canonical pipeline in [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md).
```

This closes the fifth-restatement drift class per D-11.

### Evidence 7: `docs/supported-surface.md` out-of-scope list (D-09 target)

**Verified line range:** L113-138 (matches "around 113-138" in additional_context exactly). Header `## Explicitly out of scope` at L113. List items L117-137. Next section `## Trust posture` at L139.

**Insertion point per D-09:** new `## Explicit non-goals for host-API route protection` subsection lands between L138 (end of current out-of-scope list) and L139 (`## Trust posture`). The four bullets follow D-09's specified content.

**Phase 92 `assert_advanced_setup_support_contract!/1` impact:** asserts 5 out-of-scope substrings (verified at `test/support/advanced_setup_support_truth.ex:22-28`). All 5 live in the EXISTING out-of-scope list at lines 120, 123, 129, and adjacent lines. Appending a NEW subsection does not affect them. Safe.

### Evidence 8: Git branch state

Currently on `main`. Per `.planning/PROJECT.md`, v1.27 feature work runs on `milestone/v1.27-phoenix-rs-token-acceptance`. The planner's first plan should check whether the branch exists and create it if not, before any edits land. The Phase 97 commits should NOT land on `main`.

### Evidence 9: No fifth restatement site discovered

Grep across `docs/` for `Lockspire.Plug.VerifyToken` (verified) returns matches only in:
- `docs/protect-phoenix-api-routes.md` (canonical home)
- `docs/supported-surface.md` (Phase 92 canonical claim line at L36 — names plugs for the support claim; this is the canonical support contract per Phase 92 D-01, NOT a restatement to police)
- `docs/saas-adoption-recipe.md:50` (D-11 target)

Plus `docs/install-and-onboard.md:73` cross-links to `docs/protect-phoenix-api-routes.md` but does NOT restate the plug names (verified). Good. D-12's grep-time guard ("a discovered fifth restatement on review is a Phase 97 bug") is currently satisfied — the planner should add a Phase-97 verification step that re-runs this grep after the edits land.

## Common Pitfalls

### Pitfall 1: Whitespace drift through editor save-on-save trimming

**What goes wrong:** Editor or `mix format` strips trailing whitespace from one file but not another. The interior `<space><space>plug(...)` becomes `<space><space>plug(...)` in some files but `plug(...)<no trailing>` in others, with invisible difference. Hash diverges. Test fails after edits that looked benign.

**Why it happens:** Marker-comment regions are not seen by `mix format` (they're inside comments in some files). The first file edit triggers an editor-on-save trimming; later edits to other files don't.

**How to avoid:** Normalize the extracted bytes with `String.replace(bytes, ~r/[ \t]+$/m, "")` BEFORE hashing. Trailing-whitespace normalization is invisible to readers and removes this entire failure class.

**Warning signs:** Test passes on the developer's machine and fails in CI (or vice versa). Trailing-whitespace differences across CRLF vs LF environments.

### Pitfall 2: `\r\n` vs `\n` line endings

**What goes wrong:** Cross-platform contributor checks out the repo with `core.autocrlf=true`. Files have CRLF; hash diverges from LF-checkout colleagues.

**Why it happens:** Git config heterogeneity across contributor machines.

**How to avoid:** Add `\r\n -> \n` normalization in the helper before hashing: `String.replace(bytes, "\r\n", "\n")`. Also add a `.gitattributes` entry forcing LF for `*.md`, `*.ex`, `*.py` (if not already present). Verify with `git check-attr -- text` on the four target files.

**Warning signs:** Tests pass locally but fail on Windows contributors' machines.

### Pitfall 3: Heredoc EEx interpolation chewing into the canonical block

**What goes wrong:** A future edit adds an EEx tag (`<%= ... %>`) inside the canonical block in `priv/templates/lockspire.install/router.ex`. After interpolation, the generated host router contains different bytes than the heredoc source — but the test reads the source, not the generated output. Test still passes; adopters get a broken pipeline.

**Why it happens:** The canonical block lives inside an EEx heredoc; EEx tags are transparent to the four-file hash because hashing happens against source bytes, not interpolated bytes.

**How to avoid:** Add a property-level assertion in the test: the extracted region from `priv/templates/lockspire.install/router.ex` must NOT contain `<%=` or `<%` (no EEx tags allowed inside the canonical block region). One-line guard: `refute extracted =~ ~r/<%/`.

**Warning signs:** None at write-time; the failure mode only surfaces in a future phase. Defense is the property assertion above.

### Pitfall 4: Sanity-check elision letting empty regions pass

**What goes wrong:** Someone renames the markers but forgets to update the regex. Extraction returns `nil` or empty binary. `:crypto.hash(:sha256, "")` is a fixed value; all four "extract empties" would coincidentally match.

**Why it happens:** The naive test cares only about hash equality, not non-emptiness.

**How to avoid:** Sanity assertion per file: `assert extracted =~ "Lockspire.Plug.VerifyToken"` BEFORE hashing. If markers were renamed or extraction failed, the substring assertion fails first with a clear "missing canonical content" message.

**Warning signs:** Test passes with zero canonical content. Use the substring guard as a positive precondition.

### Pitfall 5: Phase 92 substring assertions silently regressing during rewrite

**What goes wrong:** D-05's "section-level rewrite" of the lead and canonical-plug-order in `docs/protect-phoenix-api-routes.md` accidentally removes one of the 8 substrings Phase 92's `assert_protected_routes_guide!/1` asserts.

**Why it happens:** The plan-author edits the doc with the contract sentence (D-06) and caveat (D-07) in mind, forgetting that "no-op for unconstrained bearer tokens" must persist somewhere on the page.

**How to avoid:** Plan-level acceptance criterion: "after edit, `mix test test/lockspire/release_readiness_contract_test.exs` is green." The existing `assert_protected_routes_guide!/1` call at the test's L655 enforces this automatically. Phase 97 plans must NOT modify `test/support/advanced_setup_support_truth.ex`.

**Warning signs:** The test fails with a clear `expected content to include "no-op for unconstrained bearer tokens"` message. Cheap to diagnose; cheap to fix; only failure mode is forgetting to run the test before commit.

### Pitfall 6: Forward-reference caveat D-07 surviving past Phase 102

**What goes wrong:** Phase 102's "uncomment + telemetry + migration guide + doctor task" plan forgets to delete the D-07 caveat sentence. Caveat becomes permanent prose; an adopter reading the page post-v1.27 sees "opaque tokens may still be silently accepted on these routes" forever, despite the runtime narrowing having shipped.

**Why it happens:** Phase 102's planner has many things to remember; the caveat sentence is small.

**How to avoid:** Phase 97 leaves a marker for Phase 102 — the caveat sentence carries an HTML comment in the markdown: `<!-- PHASE-102: delete this caveat sentence when issuance flip ships -->`. The planner of Phase 102 will see it. Additionally, a Phase 102 acceptance criterion could be `refute File.read!("docs/protect-phoenix-api-routes.md") =~ "opaque tokens may still be silently accepted"` — that's a Phase 102 concern, not a Phase 97 one, but flagging here so the Phase 102 planner knows the marker to look for.

**Warning signs:** None until v1.27 ships; the marker is the only defense.

### Pitfall 7: Pipeline declared inside generated heredoc but the heredoc is per-scope

**What goes wrong:** The planner places the canonical block inside the existing `scope "/" do ... end` heredoc body, where pipelines cannot be declared in Phoenix. After Phase 102 SCAFFOLD-01 uncomments, the generated router fails to compile.

**Why it happens:** Pipelines must be declared at module level, not inside a scope. The current install-template heredoc only contains scopes.

**How to avoid:** The canonical block must land BEFORE the first `scope "/", <%= @web_module %> do` (line 11 of the current heredoc). Inserting at the very top of the heredoc body (between `"""` on L10 and `scope "/", ...` on L11) is the safe placement.

**Warning signs:** Phase 102 SCAFFOLD-01 ships and `mix lockspire.install` produces a router that fails `mix compile`. Caught by Phase 102's generator test, not Phase 97's hash test — but the structural mistake is made in Phase 97.

## Code Examples

Verified patterns from current `release_readiness_contract_test.exs`:

### Pattern: Module-attribute file path declaration (lines 71-79)
```elixir
# Source: test/lockspire/release_readiness_contract_test.exs:71-79
@protect_phoenix_api_routes_path Path.expand(
                                   "../../docs/protect-phoenix-api-routes.md",
                                   __DIR__
                                 )
@saas_adoption_recipe_path Path.expand("../../docs/saas-adoption-recipe.md", __DIR__)
```

Phase 97 adds three more in the same style:
```elixir
@adoption_demo_router_path Path.expand(
                             "../../examples/adoption_demo/lib/adoption_demo_web/router.ex",
                             __DIR__
                           )
@install_template_router_path Path.expand(
                                "../../priv/templates/lockspire.install/router.ex",
                                __DIR__
                              )
@adoption_smoke_script_path Path.expand("../../scripts/demo/adoption_smoke.py", __DIR__)
```

### Pattern: Regex extraction with capture (lines 111-122)
```elixir
# Source: test/lockspire/release_readiness_contract_test.exs:111-122
defp release_workflow_job(name, next_name) do
  @release_workflow_path
  |> File.read!()
  |> then(
    &Regex.run(
      ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
      &1,
      capture: :all_but_first
    )
  )
  |> List.first()
end
```

Phase 97's helper mirrors this shape; the regex is `~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms` and the capture is the canonical region bytes.

### Pattern: Sanity-checked SHA-256 over normalized bytes
```elixir
# Suggested shape (planner's discretion on naming/details)
defp canonical_hash!(path, kind) do
  bytes =
    path
    |> File.read!()
    |> extract_canonical_region!(path)
    |> normalize(kind)

  # Sanity guard: empty extraction or marker rename should fail loudly, not match
  unless bytes =~ "Lockspire.Plug.VerifyToken" do
    raise "canonical region in #{path} missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken"
  end

  :crypto.hash(:sha256, bytes)
end

defp normalize(bytes, :python_commented) do
  bytes
  |> String.replace("\r\n", "\n")
  |> String.split("\n")
  |> Enum.map(&String.replace_prefix(&1, "# ", ""))
  |> Enum.join("\n")
  |> strip_uniform_indent()
  |> String.replace(~r/[ \t]+$/m, "")
end

defp normalize(bytes, _elixir_kind) do
  bytes
  |> String.replace("\r\n", "\n")
  |> strip_uniform_indent()
  |> String.replace(~r/[ \t]+$/m, "")
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plug-name restatement in every guide that mentions the protected route | One canonical page + cross-links from adjacent guides | Phase 92 v1.25 D-01 (canonical-authority hierarchy) | Phase 97 extends this from "support contract" to "implementation contract." |
| Implicit pattern-match assertions in tests (regex over docstrings) | Explicit marker-comment anchors with byte-equality across files | New in Phase 97 | Establishes a reusable convention for future content-pinning needs. |
| "Docs describe what the implementation does" | "Docs are the contract the implementation honors" | Original Lockspire methodology; Phase 97 makes it operational | Phase 97 + Phase 98/99/102 sequencing depends on docs landing first. |

**Deprecated/outdated:** None — Phase 97 introduces a new pattern rather than replacing one. The marker-comment + content-hash mechanism is novel in this repo (no prior phase used `:crypto.hash` for cross-file invariants); the existing `release_readiness_contract_test.exs` substring assertions stay valid.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Python smoke script's `exercise_authorization_code` function (L173-246) is the best adjacency for the Python-comment carrier block (per D-03 placement is Claude's discretion). | Evidence 4 | Low: alternative placement (top-of-file) is equally valid. Planner's discretion. |
| A2 | Adopting `audience: "billing-api"` as the canonical block's audience placeholder (matching current docs L13) is correct; the demo's missing-audience drift will be reconciled in Phase 101 DEMO-03 the same way `dpop_replay_store` drift is reconciled by D-04. | Evidence 1 | Medium: if the planner chooses a different placeholder, all four files must agree. The planner should confirm with the user that `"billing-api"` is acceptable, OR pick a different placeholder, OR omit `audience:` from the canonical block (which leaves DEMO-03 to add it later — but then the canonical block is structurally incomplete relative to D-06's "RFC 9068 contract" framing). |
| A3 | The Phase 92 `assert_protected_routes_guide!/1` 8 substrings can all be preserved through D-05's section-level rewrite without parallel test edits — verified by mapping each substring to a section D-05 marks INTACT or to known-preserved tokens (e.g., the three plug names that the canonical block will continue to name). | Evidence 5 | Low: if the planner discovers during writing that one substring genuinely needs to live in a rewritten section, the recovery is one-line: add it back. |
| A4 | The marker token `LOCKSPIRE_PROTECTED_PIPELINE` is acceptable as the project-wide naming convention going forward (per CONTEXT.md specifics: "Future GSD phases that introduce additional content-hashed regions should reuse the marker convention with their own token names"). | Pattern 1 | Low: token name is a documentation-only choice; no runtime impact. |

## Open Questions

1. **`audience:` placeholder in the canonical block.**
   - What we know: the docs page currently uses `audience: "billing-api"`; the demo router currently omits `audience:` entirely; Phase 101 DEMO-03 will reconcile.
   - What's unclear: whether to bake `audience: "billing-api"` into the canonical block (forces Phase 101 to add it to the demo via alias-or-edit) or omit `audience:` from the canonical block (lets Phase 101 add it freely but leaves the canonical block structurally weaker on the v1.27 contract).
   - Recommendation: include `audience: "billing-api"` in the canonical block. It is consistent with D-04's "pick a placeholder; reconcile in Phase 101" pattern and keeps the canonical block aligned with what DOCS-01's contract sentence implies (audience-bounded host APIs).

2. **Adoption smoke script Python-comment block placement.**
   - What we know: smoke is 306 lines; protected-API test at L244-245; D-03 doesn't pin the placement.
   - What's unclear: top-of-file (better visibility) vs. adjacent to the protected-API test (better cohesion).
   - Recommendation: adjacent to L244 inside `exercise_authorization_code`. A reader looking at the protected-API test sees the canonical block describing what they're protecting against.

3. **Whether to also delete the secondary fenced Elixir blocks in `docs/protect-phoenix-api-routes.md` (L39-49 scope-restricted, L51-62 audience-restricted) per D-12 spirit.**
   - What we know: D-12 says "no other doc, guide, or template gets a new restatement of the canonical pipeline block." D-12 is about cross-FILE restatement; the secondary examples are within-FILE.
   - What's unclear: D-12's letter doesn't reach within-file restatements but its spirit does — every restatement is a drift risk.
   - Recommendation: keep the secondary examples but rewrite them to reference the canonical block ("see the canonical pipeline above; this example narrows it to `scopes:` only") instead of restating the three plug names. Preserves the docs' didactic value while honoring D-12's spirit.

## Environment Availability

> **Skipped — no external dependencies introduced.** Phase 97 uses only Elixir/OTP (`Elixir ~> 1.18`, OTP 27 bundled) and the four files in the repo. `:crypto`, `Regex`, `File`, `String`, `ExUnit` are all stdlib. Verified `mix.exs` shows no new dependency required. Verified `.tool-versions` does not exist (project tracks Elixir via `mix.exs:9 elixir: "~> 1.18"`).

## Validation Architecture

`workflow.nyquist_validation = true` per `.planning/config.json`. Validation section is mandatory.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18 stdlib) |
| Config file | `test/test_helper.exs`, `mix.exs` aliases (`test.fast`, `test.integration`) |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs` |
| Full suite command | `mix ci` (per `mix.exs:69` aliases) |
| Phase 97 test home | `test/lockspire/release_readiness_contract_test.exs` (extended, not replaced) |

### Phase 97 Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RECIPE-01 | Four files carry BEGIN/END markers around byte-identical (after normalization) canonical pipeline blocks; hash compare fails on any pair drift | unit (in-process) | `mix test test/lockspire/release_readiness_contract_test.exs --only canonical_pipeline` (or named test) | ❌ NEW test clause — adds in Wave 0 / wave-1 |
| RECIPE-01 (negative) | Markers renamed or extraction empty raises with "missing Lockspire.Plug.VerifyToken" | unit | Same file, sanity-guard assertion fails fast | ❌ Same NEW clause |
| RECIPE-01 (no-fifth-restatement guard) | `git grep` for any new restatement of the three plug names outside the four canonical sites finds zero hits | doc-state | Phase 97 verification step (manual or scripted) | ⚠️ Manual grep — see Pitfall section |
| DOCS-01 | `docs/protect-phoenix-api-routes.md` contains the D-06 contract sentence verbatim | unit | `mix test test/lockspire/release_readiness_contract_test.exs` (extend `assert_protected_routes_guide!/1` OR add new clause) | ⚠️ Helper extension needed — see Wave 0 Gaps |
| DOCS-01 (caveat) | Page contains the D-07 caveat sentence verbatim during the milestone branch | unit | Same as above; add substring assertion | ⚠️ Helper extension needed |
| DOCS-01 (Phase 92 preservation) | Existing 8 substrings asserted by `assert_protected_routes_guide!/1` remain | unit | `mix test test/lockspire/release_readiness_contract_test.exs:642` (existing test "advanced-setup support contract stays pinned semantically") | ✅ Existing — must stay green |
| DOCS-02 | `docs/supported-surface.md` contains the four non-goal bullets with the rejection rationales sourced from REQUIREMENTS.md:103-110 | unit | `mix test test/lockspire/release_readiness_contract_test.exs` (extend `assert_advanced_setup_support_contract!/1` OR add new clause) | ⚠️ Helper extension needed |
| DOCS-02 (Phase 92 preservation) | Existing 5 out-of-scope substrings remain | unit | `mix test test/lockspire/release_readiness_contract_test.exs:642` | ✅ Existing — must stay green |
| D-11 saas-adoption-recipe restatement removal | Line 50 plug-name restatement gone; cross-link to `docs/protect-phoenix-api-routes.md` present | unit | New `assert` + `refute` in `release_readiness_contract_test.exs` | ❌ NEW clause |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs` (< 5 seconds — single file, async)
- **Per wave merge:** `mix test.fast` (full unit suite)
- **Phase gate:** `mix ci` (full suite including integration, qa, docs.verify, deps.audit) — green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/support/advanced_setup_support_truth.ex` — extend `assert_protected_routes_guide!/1` to require the D-06 contract sentence and D-07 caveat sentence verbatim. (Phase 97 may legitimately edit this helper because Phase 97 IS the phase that defines the new contract sentences; Phase 92's helpers were the contract for Phase 92's surface, and extending them is the right pattern. This is a small exception to CONTEXT.md's "Phase 97 must not invalidate Phase 92 assertions" — extension is not invalidation.)
- [ ] `test/support/advanced_setup_support_truth.ex` — extend `assert_advanced_setup_support_contract!/1` to require the four DOCS-02 bullets. Same rationale.
- [ ] New test clause in `release_readiness_contract_test.exs`: four-file content-hash comparison with pairwise diffing. Helper functions: `extract_canonical_pipeline!/2`, `normalize/2`, `canonical_hash!/2`.
- [ ] Three new module attributes in `release_readiness_contract_test.exs`: `@adoption_demo_router_path`, `@install_template_router_path`, `@adoption_smoke_script_path`.
- [ ] New test clause: `docs/saas-adoption-recipe.md` line-50 restatement removed (assert cross-link present; refute the three plug names appear in restated form).

No framework install needed. No new fixtures needed.

## Security Domain

> **Skipped.** Phase 97 introduces zero new runtime surfaces. The four file edits and one test clause do not interact with auth, secrets, input validation, or crypto in any way that ASVS categories would meaningfully apply. The `:crypto.hash(:sha256, ...)` call is for test-time invariant proof, not for any security-sensitive primitive (token signing, secret comparison, etc.).
>
> Phase 98 will trigger the security domain (V5 Input Validation for the hardened plug's `iss`/`typ`/`exp` enforcement; V6 Cryptography for the unchanged JWT signature verification path). Phase 99 will trigger V6 again (the extracted `Protocol.AccessTokenSigner`). Phase 97 itself is doc/test-shaped.

## Sources

### Primary (HIGH confidence — direct in-tree reads, 2026-05-27)

- `/Users/jon/projects/lockspire/.planning/phases/97-contract-docs-first/97-CONTEXT.md` (D-01 through D-12, deferred ideas, canonical refs)
- `/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md` (RECIPE-01, DOCS-01, DOCS-02, out-of-scope rationales at L103-110)
- `/Users/jon/projects/lockspire/.planning/STATE.md` (current milestone position; v1.27 decisions)
- `/Users/jon/projects/lockspire/.planning/ROADMAP.md` (Phase 97 success criteria; dependency chain)
- `/Users/jon/projects/lockspire/.planning/PROJECT.md` (v1.27 Key Decision; Branch A + JWT-default issuance)
- `/Users/jon/projects/lockspire/.planning/research/SUMMARY.md` (Branch A rationale; non-goals source material)
- `/Users/jon/projects/lockspire/.planning/phases/92-advanced-setup-support-truth/92-CONTEXT.md` (canonical-authority hierarchy precedent)
- `/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md` (113 lines; verified structure)
- `/Users/jon/projects/lockspire/docs/supported-surface.md` (verified out-of-scope range L113-138)
- `/Users/jon/projects/lockspire/docs/saas-adoption-recipe.md` (verified line 50 plug restatement)
- `/Users/jon/projects/lockspire/examples/adoption_demo/lib/adoption_demo_web/router.ex` (68 lines; pipeline at L23-27)
- `/Users/jon/projects/lockspire/examples/adoption_demo/lib/adoption_demo/repo.ex` (verified record_dpop_proof/1 implementation)
- `/Users/jon/projects/lockspire/priv/templates/lockspire.install/router.ex` (55 lines; heredoc structure verified)
- `/Users/jon/projects/lockspire/scripts/demo/adoption_smoke.py` (306 lines; protected-API at L244-245)
- `/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs` (1032 lines; precedent extracted from L111-122, L642-658)
- `/Users/jon/projects/lockspire/test/support/advanced_setup_support_truth.ex` (148 lines; `assert_protected_routes_guide!` at L69-80, `assert_advanced_setup_support_contract!` at L4-29)
- `/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex` (verified `dpop_replay_store` is `record_dpop_proof/1`-callback module reference)
- `/Users/jon/projects/lockspire/mix.exs` (Elixir ~> 1.18; test.fast / test.integration aliases at L67-72)
- `/Users/jon/projects/lockspire/.planning/config.json` (nyquist_validation: true)

### Secondary (MEDIUM confidence)

- None — no WebSearch or external doc was consulted. Phase 97 is fully grounded in repo evidence.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Erlang/Elixir stdlib only; no Hex packages; precedent exists in the target test file.
- Architecture: HIGH — every insertion site and structural decision verified by direct file read; CONTEXT.md decisions are exhaustive.
- Pitfalls: HIGH — Pitfalls 1, 2, 3 are documented cross-platform / cross-tool failure modes for content-hashing systems; Pitfalls 4, 5, 6, 7 are project-specific failure modes derived directly from current code.

**Research date:** 2026-05-27
**Valid until:** Indefinite — Phase 97 is repo-internal docs/test work with no external moving parts. Re-validation needed only if the four canonical files are restructured (e.g., `release_readiness_contract_test.exs` is split into multiple files, or `protect-phoenix-api-routes.md` is restructured between research and plan landing).
