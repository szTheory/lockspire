# Phase 97: Contract + Docs First - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 8 (7 modified, 1 already-modified-as-extension to a shared helper)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `docs/protect-phoenix-api-routes.md` | doc (canonical adopter guide) | static-markdown, contract-shaped | `docs/protect-phoenix-api-routes.md` (itself, current; section preservation) + Phase 92 `assert_protected_routes_guide!/1` contract | exact (section-rewrite-in-place, preserve substrings) |
| `docs/supported-surface.md` | doc (canonical public support contract) | static-markdown, additive | `docs/supported-surface.md` `## Explicitly out of scope` block (L113-138) | exact (append-subsection-after-existing-list) |
| `docs/saas-adoption-recipe.md` | doc (adjacent guide) | static-markdown, cross-link replacement | `docs/protect-phoenix-api-routes.md:5` cross-link form | role-match (cross-link replaces restatement) |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex` | runtime (Phoenix router) | request-pipeline declaration | `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-27` (current pipeline; wrap-with-markers in place) | exact (in-place marker wrap + placeholder reconciliation) |
| `priv/templates/lockspire.install/router.ex` | template (EEx heredoc generator) | install-time string interpolation | `priv/templates/lockspire.install/router.ex` heredoc body L10-52 (4-space heredoc-interior indent, Elixir-comment lines already present at L14-19, L31-43) | exact (commented-Elixir-inside-heredoc precedent already in this file) |
| `scripts/demo/adoption_smoke.py` | test (Python smoke) | Python-comment carrier (inert) | `scripts/demo/adoption_smoke.py:244-245` (`exercise_authorization_code` protected-API exercise) | role-match (no prior Python-comment-block-as-canonical-carrier exists; adjacent placement to smoke target) |
| `test/lockspire/release_readiness_contract_test.exs` | test (cross-file invariant) | regex-extract → normalize → SHA-256 → pairwise compare | `release_readiness_contract_test.exs:111-122` (`release_workflow_job/2` regex-extract) + `lib/lockspire/install/manifest.ex:70-75` (`checksum/1` :crypto.hash) | role-match (regex shape exact; hashing precedent in repo; combination novel) |
| `test/support/advanced_setup_support_truth.ex` | test (shared substring-contract helper) | content-substring assertion list | `test/support/advanced_setup_support_truth.ex:4-29` + L69-80 (Phase 92 `assert_*!/1` helpers) | exact (extend-existing-helper, do not invalidate) |

## Pattern Assignments

### `docs/protect-phoenix-api-routes.md` (doc, contract-shaped)

**Analog:** `docs/protect-phoenix-api-routes.md` itself (D-05 section-level rewrite — lead + canonical-plug-order + failure-table; preserve assigns-contract + ownership-boundary + repo-owned-proof).

**Cross-link pattern to PRESERVE verbatim** (line 5, must remain per D-08):
```markdown
For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md).
```

**Existing canonical fenced-Elixir-block to REWRITE** (lines 11-18 — wrap interior in BEGIN/END markers; reconcile placeholders per D-04 and D-13):
```elixir
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```
(Already byte-identical with D-04 placeholder name and D-13 `audience: "billing-api"`. Wrap interior in BEGIN/END markers inside the existing fenced block; do NOT include the markers in the rendered Elixir example for readers — keep them as adjacent comment lines inside the fence so they are extractable by regex but visibly inert.)

**Secondary fenced blocks to REWRITE per D-15** (lines 41-47 scope-restricted; lines 53-59 audience-restricted). Current form restates the three plug names verbatim — replace with a reference-to-canonical line:
```markdown
## Scope-restricted route example

See the canonical pipeline above; this example narrows it to a single `scopes:` value with no `audience:` restriction.
```
(Concrete content per Claude's discretion in D-05; the load-bearing requirement is: zero restatements of `Lockspire.Plug.VerifyToken | EnforceSenderConstraints | RequireToken` outside the canonical block within this file.)

**Failure table pattern to REWRITE while preserving Phase 92 substring** (`error="use_dpop_nonce"` at L87 — verified Phase 92 asserts this):
```markdown
| DPoP-bound token with proof missing a valid nonce | `401` | `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` plus `DPoP-Nonce: ...` |
```
(Rewrite the table per D-05 — but the substring `error="use_dpop_nonce"` MUST survive somewhere on the page.)

**D-06 contract sentence to insert verbatim** as the lead paragraph (after line 1 title, replacing line 3):
```markdown
Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page.
```

**D-07 forward-reference caveat to append immediately after the contract lead**:
```markdown
<!-- PHASE-102: delete this caveat sentence when issuance flip ships -->
This page describes the contract `Lockspire.Plug.VerifyToken` enforces; the runtime narrowing and the default-issuance flip land in v1.27. Until v1.27 is fully shipped, opaque tokens may still be silently accepted on these routes.
```
(HTML-comment marker is Pitfall-6 defense per RESEARCH; Phase 102 deletes both lines together.)

**Phase 92 substring contract that MUST survive the section rewrite** (8 substrings from `test/support/advanced_setup_support_truth.ex:69-80`):
- `"For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md)."` → at L5, preserve
- `"Lockspire.Plug.VerifyToken"` → still in canonical block
- `"Lockspire.Plug.EnforceSenderConstraints"` → still in canonical block
- `"Lockspire.Plug.RequireToken"` → still in canonical block
- `"no-op for unconstrained bearer tokens"` → currently L22; must reappear somewhere in the rewritten canonical-plug-order prose
- `"error=\"use_dpop_nonce\""` → preserve in rewritten failure table
- `"business authorization"` (lowercase, literal) → CORRECTION (verified 2026-05-27 via direct `grep -n`): exists at L3 (lead — REWRITTEN by Plan 02) AND L22 (canonical-plug-order paragraph — PRESERVED). L100 carries the CAPITALIZED form `Business authorization` which is NOT the literal lowercase substring. Survives the rewrite via the L22 occurrence (preserved per D-05) but Plan 02 Task 1 Step 3 re-injects defensively.
- `"tenant checks"` (lowercase, literal) → CORRECTION (verified 2026-05-27 via direct `grep -n`): exists at L3 (lead — REWRITTEN by Plan 02) ONLY. Prior PATTERNS claim of L77/L102 was WRONG (those lines carry `this tenant`/`internal policy checks` at L77 and `Tenant and account policy` at L101 — none match the literal lowercase substring `tenant checks`). Since the ONLY pre-edit home of `tenant checks` is the rewritten L3, Plan 02 Task 1 Step 3 MUST re-inject this substring into the canonical-plug-order introductory prose or the Phase 92 helper assertion regresses RED. (Source of correction: revision iteration 1 plan-checker BLOCKER #1.)

---

### `docs/supported-surface.md` (doc, additive subsection)

**Analog:** `docs/supported-surface.md` `## Explicitly out of scope` block (L113-138, verified). Append-after-existing-list pattern is the canonical structure for this file.

**Existing out-of-scope list ending** (L137):
```markdown
- External OIDF or FAPI suite certification claims — Lockspire does not treat historical or optional external-suite runs as part of the current public support contract for the embedded Phoenix library path

## Trust posture
```

**D-09 subsection to INSERT** between L138 (blank line after final bullet) and L139 (`## Trust posture`). Each bullet uses the rejection-rationale wording sourced from `.planning/REQUIREMENTS.md:103-110`:
```markdown
## Explicit non-goals for host-API route protection

- no introspection-at-the-RS as the host-API seam — recreates gateway/CIAM productization the canon explicitly rejects
- no auto-detection of token shape — documented ecosystem footgun (Ory oathkeeper #257 class)
- no dual-verifier dispatcher — hides operator-visible complexity inside the library
- no RAR enforcement at the RS plug — RAR claims surface via `conn.assigns.access_token` for host-owned enforcement
```

**Phase 92 substring contract that MUST remain intact** (`assert_advanced_setup_support_contract!/1` 5 substrings at `test/support/advanced_setup_support_truth.ex:22-28`):
- `"Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope"` → L120
- `"broader resource-server integration beyond Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped Phoenix plug pipeline"` → L121
- `"Arbitrary custom `Lockspire.MTLS.Extractor` implementations are not first-class peers"` → L123
- `"Dynamic Client Registration does not add a new logout runtime; it only manages the existing logout propagation metadata"` → L129
- `"proves front-channel logout success remotely"` → in trust posture region
(All five live in the EXISTING out-of-scope list. Appending the new subsection AFTER L138 does not touch them.)

---

### `docs/saas-adoption-recipe.md` (doc, cross-link replacement)

**Analog:** `docs/protect-phoenix-api-routes.md:5` cross-link pattern (the canonical "see X for the contract" form already established at Phase 92).

**Existing line 50 to REPLACE per D-11** (current — restates three plug names):
```markdown
- If exposing API routes, protect one host route with `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`.
```

**Replacement** (planner's discretion on exact wording; load-bearing requirement is "zero plug-name restatement outside the four canonical sites"):
```markdown
- If exposing API routes, follow the canonical pipeline in [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md).
```

---

### `examples/adoption_demo/lib/adoption_demo_web/router.ex` (runtime, in-place marker wrap)

**Analog:** The pipeline declaration at L23-27 itself. Wrap-with-markers in place; reconcile placeholders per D-04 and D-13.

**Current state** (L23-27, verified by direct read):
```elixir
  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken, scopes: ["read:billing"])
    plug(Lockspire.Plug.EnforceSenderConstraints, dpop_replay_store: AdoptionDemo.Repo)
    plug(Lockspire.Plug.RequireToken)
  end
```

**Target state** (after Phase 97 edit; markers at module-level 2-space indent; canonical bytes between BEGIN/END):
```elixir
  # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
  pipeline :lockspire_protected_api do
    plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    plug Lockspire.Plug.EnforceSenderConstraints,
      dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    plug Lockspire.Plug.RequireToken
  end
  # END LOCKSPIRE_PROTECTED_PIPELINE
```

**Drift to reconcile in Phase 97 (per D-04, D-13):**
- `dpop_replay_store: AdoptionDemo.Repo` → `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` (placeholder; Phase 101 DEMO-01/02/03 wires the demo-side alias)
- Add `audience: "billing-api"` (currently absent from L24; Phase 101 DEMO-03 will reconcile demo runtime)

**Style note:** Current router uses `plug(Foo, ...)` (parens) form. Canonical block per D-01 freedom may use either; the load-bearing constraint is byte-identity across the four files AFTER D-02 normalization. Pick one style (recommendation: no-parens to match the existing doc's L11-18 form so the docs site renders without parens churn) and apply it identically to all four sites.

---

### `priv/templates/lockspire.install/router.ex` (template, commented-Elixir-inside-heredoc)

**Analog:** The same file's heredoc body (L10-52). The heredoc already contains commented-Elixir lines as a routine pattern — verified at L14-19 and L34-43.

**Existing precedent inside the heredoc** (L34-43, `## Mount Lockspire's operator UI behind your host-owned operator auth` block):
```elixir
    # Mount Lockspire's operator UI behind your host-owned operator auth
    # pipeline before the general public OAuth/OIDC forward below.
    #
    # Example:
    #
    #   scope "<%= @mount_path %>/admin" do
    #     pipe_through [:browser, :require_operator]
    #     forward "/", Lockspire.Web.AdminRouter
    #   end
    #
```
The 4-space indent + `#` prefix is exactly the form D-10's commented canonical block uses.

**Target insertion point** (per RESEARCH Pitfall-7: pipelines must be at module level; insert BEFORE the first `scope "/", <%= @web_module %> do` at heredoc L11):
```elixir
  def lockspire_routes do
    """
    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
    # END LOCKSPIRE_PROTECTED_PIPELINE

    scope "/", <%= @web_module %> do
      ...
```
(Comment-prefixed lines are inert in the generated host router per D-10. Phase 102 SCAFFOLD-01 removes the leading `# ` prefixes from the interior canonical lines only — markers stay commented; canonical bytes after normalization are unchanged.)

**Compile-cleanness invariant** (per RESEARCH Pitfall-3): the extracted region MUST NOT contain `<%=` or `<%` — refute-test in the content-hash clause.

---

### `scripts/demo/adoption_smoke.py` (test, Python-comment carrier)

**Analog:** No prior Python-comment-block-as-Elixir-canonical-carrier exists in the repo. Closest cohesion target is the protected-API exercise at L244-245 (verified). D-14 locks placement to "adjacent to `exercise_authorization_code`".

**Existing target** (L243-245, current state):
```python
    assert userinfo_json["email"] == "alice@acme.test"

    anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")
    assert_status(anonymous_api, 401, "protected API rejects anonymous request")
```

**Insertion** (immediately above L244 inside `exercise_authorization_code`, 4-space Python-function-body indent; each interior line uses `# ` Python-comment prefix per D-03):
```python
    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
    # END LOCKSPIRE_PROTECTED_PIPELINE

    anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")
    assert_status(anonymous_api, 401, "protected API rejects anonymous request")
```
Note: each interior line starts with `    # ` (4 spaces + `# `). The 4-space indent is stripped by D-02 normalization (left-strip uniform indent); the `# ` is stripped by D-02 normalization (Python-only `# ` prefix strip per line). Result equals the same bytes the Elixir files produce.

---

### `test/lockspire/release_readiness_contract_test.exs` (test, cross-file invariant)

**Primary analog (regex extraction):** `release_readiness_contract_test.exs:111-122` — `release_workflow_job/2` regex-extract precedent.

**Existing precedent — extract-by-regex-with-capture pattern**:
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
Use this shape for `extract_canonical_pipeline!/2`. The regex becomes `~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms` — same `[ms]` flags, same `capture: :all_but_first`.

**Secondary analog (hashing):** `lib/lockspire/install/manifest.ex:70-75` — `checksum/1` :crypto.hash precedent.

**Existing precedent — SHA-256 hashing**:
```elixir
@spec checksum(binary()) :: String.t()
def checksum(contents) when is_binary(contents) do
  :sha256
  |> :crypto.hash(contents)
  |> Base.encode16(case: :lower)
end
```
For Phase 97's pairwise compare, drop the Base.encode16 step (raw `<<...>>` binary compare via `==` is fine; ExUnit's diff is fine; optional `Base.encode16/2` only for failure-message readability).

**Module attribute pattern** (existing in this file, L20-83 — 30 module attributes of identical shape; Phase 97 adds 3 more):
```elixir
# Existing precedent at lines 71-79
@protect_phoenix_api_routes_path Path.expand(
                                   "../../docs/protect-phoenix-api-routes.md",
                                   __DIR__
                                 )
@saas_adoption_recipe_path Path.expand("../../docs/saas-adoption-recipe.md", __DIR__)
```

**Phase 97 ADDS three module attributes in the same form**:
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

**New helper functions** (canonical shape — Claude's discretion on naming/whitespace per CONTEXT.md):
```elixir
defp extract_canonical_pipeline!(path, kind) do
  bytes =
    path
    |> File.read!()
    |> then(
      &Regex.run(
        ~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms,
        &1,
        capture: :all_but_first
      )
    )
    |> case do
      [captured] -> captured
      _ -> raise "missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in #{path}"
    end

  normalize(bytes, kind)
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

defp canonical_hash!(path, kind) do
  bytes = extract_canonical_pipeline!(path, kind)

  unless bytes =~ "Lockspire.Plug.VerifyToken" do
    raise "canonical region in #{path} missing Lockspire.Plug.VerifyToken — markers renamed or extraction broken"
  end

  if path |> String.ends_with?(".ex") and bytes =~ ~r/<%/ do
    raise "canonical region in #{path} contains EEx tag — heredoc interpolation would chew the canonical bytes"
  end

  :crypto.hash(:sha256, bytes)
end
```
(Sanity guards from RESEARCH Pitfalls 3 and 4 baked in.)

**New test clause shape** (Claude's discretion on whitespace; load-bearing requirement is failure-message naming the drifted pair):
```elixir
test "canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites" do
  files = [
    {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
    {@adoption_demo_router_path, :elixir},
    {@install_template_router_path, :elixir_in_commented_heredoc},
    {@adoption_smoke_script_path, :python_commented}
  ]

  hashes =
    Enum.map(files, fn {path, kind} -> {path, canonical_hash!(path, kind)} end)

  for {path_a, hash_a} <- hashes, {path_b, hash_b} <- hashes, path_a < path_b do
    assert hash_a == hash_b,
           "canonical pipeline block drifted between #{Path.relative_to_cwd(path_a)} and #{Path.relative_to_cwd(path_b)}"
  end
end

test "docs/saas-adoption-recipe.md cross-links to the canonical pipeline rather than restating plug names" do
  recipe = File.read!(@saas_adoption_recipe_path)

  assert recipe =~ ~r/protect-phoenix-api-routes\.md/,
         "expected docs/saas-adoption-recipe.md to cross-link to docs/protect-phoenix-api-routes.md"

  refute recipe =~ ~r/`Lockspire\.Plug\.VerifyToken`.*`Lockspire\.Plug\.EnforceSenderConstraints`.*`Lockspire\.Plug\.RequireToken`/s,
         "expected docs/saas-adoption-recipe.md to no longer restate the three plug names"
end
```

**Note on `Path.relative_to_cwd/1`:** failure messages should show short paths, not absolute paths; precedent at `release_readiness_contract_test.exs` uses bare module-attribute paths in messages — Phase 97 may continue that style. Naming the file pair is the load-bearing requirement (D-02).

---

### `test/support/advanced_setup_support_truth.ex` (test, shared-helper extension)

**Analog:** L4-29 (`assert_advanced_setup_support_contract!/1`) and L69-80 (`assert_protected_routes_guide!/1`) — both already use the `assert_includes_all/2` list-of-substring pattern at L132-138.

**Existing shared-helper pattern** (L132-138):
```elixir
defp assert_includes_all(content, snippets) do
  Enum.each(snippets, fn snippet ->
    unless String.contains?(content, snippet) do
      raise "expected content to include #{inspect(snippet)}"
    end
  end)
end
```

**Existing `assert_protected_routes_guide!/1` (L69-80)** — extend by adding NEW substrings; do not remove or alter existing ones (Phase 92 contract is extension-not-invalidation per CONTEXT.md D-05 and RESEARCH Wave 0 Gaps):
```elixir
def assert_protected_routes_guide!(content) do
  assert_includes_all(content, [
    "For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md).",
    "Lockspire.Plug.VerifyToken",
    "Lockspire.Plug.EnforceSenderConstraints",
    "Lockspire.Plug.RequireToken",
    "no-op for unconstrained bearer tokens",
    "error=\"use_dpop_nonce\"",
    "business authorization",
    "tenant checks",
    # --- Phase 97 extensions begin ---
    # D-06 contract sentence (exact verbatim)
    "Lockspire issues RFC 9068 `at+jwt` access tokens by default.",
    "Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes.",
    "Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable.",
    "To opt a client back to opaque, see the admin Client Detail page.",
    # D-07 forward-reference caveat
    "the runtime narrowing and the default-issuance flip land in v1.27",
    "opaque tokens may still be silently accepted on these routes"
  ])
end
```

**Existing `assert_advanced_setup_support_contract!/1` (L22-28)** — extend the second `assert_includes_all/2` list with the four D-09 non-goal bullets:
```elixir
assert_includes_all(content, [
  # ... existing 5 substrings preserved ...
  "Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope",
  "broader resource-server integration beyond Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped Phoenix plug pipeline",
  "Arbitrary custom `Lockspire.MTLS.Extractor` implementations are not first-class peers",
  "Dynamic Client Registration does not add a new logout runtime; it only manages the existing logout propagation metadata",
  "proves front-channel logout success remotely",
  # --- Phase 97 extensions begin ---
  # D-09 four non-goal bullets (rejection-rationale phrases sourced from REQUIREMENTS.md:103-110)
  "no introspection-at-the-RS as the host-API seam",
  "recreates gateway/CIAM productization the canon explicitly rejects",
  "no auto-detection of token shape",
  "documented ecosystem footgun",
  "no dual-verifier dispatcher",
  "hides operator-visible complexity inside the library",
  "no RAR enforcement at the RS plug",
  "RAR claims surface via `conn.assigns.access_token` for host-owned enforcement"
])
```

**Failure-message convention** (preserve as-is — already in the existing helper):
`"expected content to include #{inspect(snippet)}"` (L135). No change to the helper's diagnostic shape; only the substring lists grow.

---

## Shared Patterns

### Pattern A: Marker-Comment Anchored Region (new convention, Phase 97 establishes)

**Source:** RESEARCH Pattern 1 + CONTEXT.md specifics. No prior repo precedent — Phase 97 establishes this as a reusable convention for future GSD phases that need cross-file content-pinning.

**Apply to:** All four canonical sites (`docs/protect-phoenix-api-routes.md`, `examples/adoption_demo/lib/adoption_demo_web/router.ex`, `priv/templates/lockspire.install/router.ex`, `scripts/demo/adoption_smoke.py`).

**Shape:**
```
# BEGIN LOCKSPIRE_<SUBJECT>
... canonical bytes (interior content; possibly comment-prefixed in cross-syntax carriers)
# END LOCKSPIRE_<SUBJECT>
```

**Convention details (per CONTEXT.md specifics + D-02):**
- Marker token is `LOCKSPIRE_PROTECTED_PIPELINE` verbatim, case-sensitive
- Markers are NOT part of the hashed region (extracted bytes are interior-only)
- Future GSD phases pick their own `LOCKSPIRE_<SUBJECT>` token; the regex helper signature is reusable

### Pattern B: Regex-Extract-with-Capture (preserve)

**Source:** `test/lockspire/release_readiness_contract_test.exs:111-122` (existing precedent, verified).

**Apply to:** New `extract_canonical_pipeline!/2` helper in `release_readiness_contract_test.exs`.

**Shape:**
```elixir
target_path
|> File.read!()
|> then(&Regex.run(~r/<pattern>/ms, &1, capture: :all_but_first))
|> List.first()
```
(Phase 97 replaces `List.first()` with a `case` clause that raises on `nil` extraction per Pitfall 4. Otherwise identical.)

### Pattern C: SHA-256 Content Hashing (preserve)

**Source:** `lib/lockspire/install/manifest.ex:70-75` (existing precedent, verified). Same primitive is used in `lib/lockspire/redaction.ex:188`, `lib/lockspire/security/policy.ex:149`, `lib/lockspire/protocol/dpop.ex:60`, and others.

**Apply to:** New `canonical_hash!/2` helper.

**Shape:**
```elixir
:crypto.hash(:sha256, bytes)
```
(Raw binary for comparison; optional `Base.encode16(case: :lower)` only if failure-message readability calls for it.)

### Pattern D: Substring-Contract Helper Extension (preserve)

**Source:** `test/support/advanced_setup_support_truth.ex:4-29, 69-80, 132-138` — Phase 92 idiom.

**Apply to:** `assert_protected_routes_guide!/1` and `assert_advanced_setup_support_contract!/1` extensions for D-06, D-07, D-09.

**Key constraint:** Phase 97 may legitimately EXTEND these helpers (add substrings); Phase 97 must NOT INVALIDATE them (remove or alter existing substrings). Extension is not invalidation per CONTEXT.md D-05 and RESEARCH Wave 0 Gaps note.

### Pattern E: Module-Attribute Path Declaration (preserve)

**Source:** `test/lockspire/release_readiness_contract_test.exs:20-83` — 30 existing module attributes; Phase 97 adds 3 more in the identical shape.

**Apply to:** New `@adoption_demo_router_path`, `@install_template_router_path`, `@adoption_smoke_script_path`.

**Shape:**
```elixir
@name Path.expand("../../<relative_path>", __DIR__)
```

### Pattern F: Cross-Link-Replaces-Restatement (preserve)

**Source:** `docs/protect-phoenix-api-routes.md:5` cross-link to `docs/supported-surface.md` — the Phase 92 canonical-authority hierarchy idiom.

**Apply to:** D-11 replacement at `docs/saas-adoption-recipe.md:50`.

**Shape:**
```markdown
For <context>, see [`docs/<target>.md`](<target>.md).
```
Replaces inline plug-name restatements with a cross-link to the canonical home.

### Pattern G: Forward-Reference Caveat with HTML-Comment Sweep-Marker (new, narrow)

**Source:** RESEARCH Pitfall 6 defense + CONTEXT.md D-07.

**Apply to:** D-07 caveat in `docs/protect-phoenix-api-routes.md`.

**Shape:**
```markdown
<!-- PHASE-102: delete this caveat sentence when issuance flip ships -->
<single-sentence caveat scoped to the milestone branch>
```
The HTML comment is invisible in rendered markdown but greppable for the Phase 102 sweep planner.

---

## Patterns to Preserve

- **Phase 92's helper-extension idiom.** `test/support/advanced_setup_support_truth.ex` helpers are extended (substring lists grow); they are NEVER edited to remove a substring or alter a failure message. Phase 92's contract on Phase 97 surfaces remains valid post-Phase-97.
- **The canonical-authority deference pattern.** `docs/supported-surface.md` stays the canonical public support contract per Phase 92 D-01. Phase 97 honors this by placing DOCS-02 INSIDE `supported-surface.md`, not as a parallel claim in `protect-phoenix-api-routes.md`.
- **The failure-message-names-the-file-pair convention.** Per CONTEXT.md Claude's Discretion bullet 4 (and D-02): when the four-file hash compare fails, the failure message MUST name both files in the drifted pair. ExUnit's default formatter on `assert hash_a == hash_b, "<message>"` honors this directly.
- **Regex `[ms]` flags + `capture: :all_but_first` shape** for any new in-test extraction (Pattern B). Do not introduce `String.split/2` state machines (RESEARCH "Don't Hand-Roll" advice).
- **`async: true` test posture** at `release_readiness_contract_test.exs:2`. The new test clause MUST preserve this — pure file-reads + in-process hashing have no race risk.
- **Module-attribute-as-path-declaration convention** (Pattern E). All file paths used by `release_readiness_contract_test.exs` go through `Path.expand("../../...", __DIR__)` module attributes; no inline string paths.
- **Compile-cleanness of the install template** (RESEARCH Pitfall 3 and Pitfall 7). The canonical block in `priv/templates/lockspire.install/router.ex` is comment-prefixed Elixir, lives ABOVE the first `scope` (module-level), and contains no EEx tags. The content-hash clause refute-tests for `<%` to defend.

---

## No Analog Found

No files in this phase fall into "no analog found" — every Phase 97 file has at least a role-match analog. The closest "novel" surfaces are:

| File | Surface | Notes |
|------|---------|-------|
| `scripts/demo/adoption_smoke.py` (Python-comment carrier) | First Python-comment-as-Elixir-canonical-carrier in the repo | No prior precedent; the closest cohesion target is the smoke's protected-API exercise at L244 (D-14). Inert by Python syntax. |
| `test/lockspire/release_readiness_contract_test.exs` (cross-file content-hash clause) | First :crypto.hash use in this test file; first cross-syntax byte-equality invariant in the repo | Components (regex extract + :crypto.hash) have separate strong precedents; their composition is new. |

Both are flagged in RESEARCH State of the Art as "novel in this repo" — the planner should treat them as establishing convention, not breaking it.

---

## Metadata

**Analog search scope:**
- `docs/` (all eleven `.md` files for cross-link and substring-contract precedents)
- `test/lockspire/release_readiness_contract_test.exs` (regex/extraction precedent)
- `test/support/advanced_setup_support_truth.ex` (substring-helper precedent)
- `lib/lockspire/install/manifest.ex` (:crypto.hash precedent)
- `lib/lockspire/{redaction,security,protocol}` (`:crypto.hash` corroborating uses)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` (live pipeline shape)
- `priv/templates/lockspire.install/router.ex` (heredoc comment-line precedent)
- `scripts/demo/adoption_smoke.py` (smoke structure)

**Files scanned:** ~12 source files directly read; ~50 files grep-scanned for `:crypto.hash`, `BEGIN`/`END` markers, `Regex.run.*ms`, `String.replace_prefix`.

**Pattern extraction date:** 2026-05-27

**Confidence:** HIGH — every analog excerpt above was read directly on 2026-05-27 against the same files RESEARCH verified. No external lookups performed.
