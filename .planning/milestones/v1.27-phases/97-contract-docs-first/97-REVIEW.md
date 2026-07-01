---
phase: 97-contract-docs-first
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - docs/protect-phoenix-api-routes.md
  - docs/saas-adoption-recipe.md
  - docs/supported-surface.md
  - examples/adoption_demo/lib/adoption_demo_web/router.ex
  - priv/templates/lockspire.install/router.ex
  - scripts/demo/adoption_smoke.py
  - test/lockspire/release_readiness_contract_test.exs
  - test/support/advanced_setup_support_truth.ex
  - test/support/generated_host_app_web/router/lockspire.ex
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 97: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 97 establishes a byte-equality contract for the canonical `lockspire_protected_api` pipeline across four carriers (markdown fence, demo router, install-template heredoc, Python comment) using SHA-256 hashing of a kind-aware normalized region. The implementation is correct for the four current carriers under nominal conditions — I verified end-to-end that all four files produce identical SHA-256 hash `984d0285...169a159829` after normalization, and the failure-path guards (no markers, EEx tag, missing `Lockspire.Plug.VerifyToken` substring) raise the expected errors.

However, the normalization helpers and extraction regex are tightly coupled to several implicit assumptions (no CRLF on disk, no trailing whitespace on marker lines, exactly one canonical block per file, `.ex`-only EEx-tag scope, `String.replace_prefix("# ", "")` strips ONLY `# ` and not bare `#`). Three of these are silent-failure or false-negative shapes that would let drift through; the rest are documented edge cases. No security or correctness blockers. The protect-phoenix-api-routes.md page itself includes a runtime caveat (line 7) that opaque tokens "may still be silently accepted" — this is honest documentation of a known v1.27 gap, not a defect introduced by this phase.

The support fixture at `test/support/generated_host_app_web/router/lockspire.ex` carries the same canonical bytes as the install template but is NOT part of the four-file content-hash check — drift between template and fixture is caught instead by `install_generator_test.exs:201` (a separate byte-equality assertion). This is by design (per `97-05-SUMMARY.md`) but is worth flagging as architectural coupling that's not obvious from the test file alone.

## Warnings

### WR-01: `extract_canonical_pipeline!` regex captures only the FIRST BEGIN/END pair — duplicate canonical blocks would drift silently

**File:** `test/lockspire/release_readiness_contract_test.exs:140-157`
**Issue:** `Regex.run/3` with lazy `(.*?)` returns the FIRST match. If a future contributor adds a SECOND `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE ... # END LOCKSPIRE_PROTECTED_PIPELINE` block to any of the three non-doc carriers (demo router, install template, Python smoke), drift inside that second block would never be detected — the test would silently hash only the first block. The D-15 within-file refute test at line 772 partially mitigates this for `docs/protect-phoenix-api-routes.md` only (it counts `pipeline :lockspire_protected_api do` occurrences), but the other three carriers have no marker-count guard. I verified empirically: a two-pair file passes extraction with only the first pair captured.

**Fix:** Add a multi-occurrence guard inside `extract_canonical_pipeline!/2` before hashing:

```elixir
defp extract_canonical_pipeline!(path, kind) do
  contents = File.read!(path)

  case Regex.scan(~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE/, contents) do
    [_] -> :ok
    matches ->
      raise "expected exactly one BEGIN LOCKSPIRE_PROTECTED_PIPELINE marker in #{path}, found #{length(matches)}"
  end

  # existing Regex.run extraction continues here, using `contents`
end
```

### WR-02: CRLF line endings on disk silently break extraction with a misleading "missing markers" error

**File:** `test/lockspire/release_readiness_contract_test.exs:146`
**Issue:** The extraction regex uses literal `\n` (not `\R` or a CRLF-tolerant pattern). The `normalize/2` helper does `String.replace("\r\n", "\n")`, but this happens AFTER extraction. If a Windows contributor (or git autocrlf=true on Windows checkout) commits any of the four carriers with CRLF endings, the regex fails to match and `extract_canonical_pipeline!/2` raises `"missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in <path>"` — a misleading error because the markers ARE there, just separated by `\r\n` instead of `\n`. I verified empirically: a CRLF-encoded BEGIN/END pair fails extraction.

**Fix:** Apply CRLF normalization BEFORE the regex run, so the rest of the helper sees only `\n`:

```elixir
defp extract_canonical_pipeline!(path, kind) do
  contents = File.read!(path) |> String.replace("\r\n", "\n")
  # ... regex run on normalized contents
end
```

Or, alternatively, change the regex to use `\R` (which matches any line break in PCRE) — but the leading-fix is more defensive because it also feeds the rest of `normalize/2` known-canonical newlines.

### WR-03: EEx-tag guard scope is `.ex`-only; `.eex` files and future template extensions slip through

**File:** `test/lockspire/release_readiness_contract_test.exs:209`
**Issue:** The EEx-tag guard fires on `String.ends_with?(path, ".ex") and bytes =~ ~r/<%/`. Verified empirically: `"foo.eex"` does NOT end with `".ex"` (Elixir's `String.ends_with?` checks the literal trailing characters; `.eex` ends in `.eex`, not `.ex`). If a future contributor adds a `.eex` carrier (e.g., a Phoenix view template demonstrating the protected pipeline), it would bypass the guard and any EEx interpolation inside the canonical region would chew the canonical bytes at compile time.

**Fix:** Broaden the guard to all Elixir-source-like extensions, or — better — apply the EEx-tag guard unconditionally to ALL carriers (the four current carriers' normalized canonical regions never contain `<%`, so an unconditional guard wouldn't false-positive on any of them):

```elixir
if bytes =~ ~r/<%/ do
  raise "canonical region in #{path} contains EEx tag — interpolation would chew the canonical bytes"
end
```

The `.ex`-only scoping was a Phase 97 RESEARCH Pitfall 3 mitigation, but the .eex blind spot was not anticipated. An unconditional check is strictly safer with no observed downside.

## Info

### IN-01: Support fixture at `test/support/generated_host_app_web/router/lockspire.ex` carries the canonical bytes but is not in the four-file hash check

**File:** `test/support/generated_host_app_web/router/lockspire.ex:15-22`
**Issue:** This fixture is hand-maintained to match `priv/templates/lockspire.install/router.ex` (verified: same canonical hash `984d0285...`). Per `97-05-SUMMARY.md`, the team consciously chose to keep the four-file test at four files and rely on `test/integration/install_generator_test.exs:201`'s separate byte-equality assertion to catch template/fixture drift. The current behavior is correct, but the coupling is non-obvious from the test file alone; a future contributor editing the template might forget the fixture exists.

**Fix:** Either extend the canonical-pipeline content-hash test to five files (lowest-cost, highest-coverage option) OR add a brief comment in both `priv/templates/lockspire.install/router.ex` and `test/support/generated_host_app_web/router/lockspire.ex` pointing at each other and at `install_generator_test.exs:201` as the byte-equality enforcer.

### IN-02: `String.replace_prefix(&1, "# ", "")` does not strip bare `#` lines

**File:** `test/lockspire/release_readiness_contract_test.exs:164`
**Issue:** The per-line comment-strip uses `String.replace_prefix(line, "# ", "")` (with trailing space). A line that's just `#` (no trailing space, no content) is left as `#`. The four current carriers don't have such lines inside their canonical regions, but a future contributor adding a `#`-only separator to the Python or commented-heredoc carrier would create a normalization mismatch — the markdown-fence carrier (which doesn't strip `#`) would emit `#` while the commented carriers would also emit `#`, BUT the demo-router carrier (also fence-kind) would NOT have a `#` line to emit. Result: silent drift survives normalization between fence kinds and commented kinds if a `#`-only line appears in one but not the other.

**Fix:** Also strip bare `#` lines OR pre-canonicalize by appending a space to bare `#` lines before the prefix-strip. Lower-impact alternative: document this constraint as a comment in `normalize/2`.

### IN-03: `String.replace(~r/[ \t]+$/m, "")` does not strip Unicode whitespace (NBSP, etc.)

**File:** `test/lockspire/release_readiness_contract_test.exs:166, 173`
**Issue:** The trailing-whitespace strip only matches ASCII space and tab. A copy-paste from a rendered web page or an editor with smart quotes/spaces could introduce U+00A0 (no-break space) or other Unicode whitespace, which would survive normalization and cause a silent drift between carriers. Verified: NBSP is not in the `[ \t]` class.

**Fix:** Document this as a known constraint, or broaden the regex to `[\s]+$` (matches all whitespace including NBSP) — but be aware `\s` in Elixir Regex also matches `\n`, which would collapse blank lines. Safer: `[[:space:]]+$` with the `u` flag, or explicit character class `[ \t\x{00A0}]+$`.

### IN-04: D-11 refute regex in `release_readiness_contract_test.exs:768` is order-and-formatting-specific

**File:** `test/lockspire/release_readiness_contract_test.exs:768`
**Issue:** The refute pattern requires `VerifyToken` THEN `EnforceSenderConstraints` THEN `RequireToken` in that order, each wrapped in markdown backticks, with `.*` between them. A regression that restates the plug names in a different order, or without backticks, or in a bulleted list with intervening prose, would slip past the refute. Current state is clean, so no immediate bug.

**Fix:** Strengthen the refute to a disjunction across plug-name pairs OR a simpler `refute recipe =~ "Lockspire.Plug.VerifyToken"` (matches any restatement). The disjunction is more permissive but the simple-substring refute is more defensible.

### IN-05: Trailing whitespace on the BEGIN/END marker line silently breaks extraction

**File:** `test/lockspire/release_readiness_contract_test.exs:146`
**Issue:** The regex anchors `# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n` and `# END LOCKSPIRE_PROTECTED_PIPELINE` literally. A common editor artifact — trailing space on the BEGIN line — causes a no-match. The sanity-guard at line 153 then raises `"missing BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE markers in <path>"` — loud and clear, but the actual cause (trailing whitespace) is invisible in the error message. Verified empirically.

**Fix:** Add `[ \t]*\n` after both marker literals in the regex to absorb trailing whitespace, or normalize trailing whitespace on the read contents BEFORE the regex run (combine with WR-02's CRLF fix).

### IN-06: `mix_version/0`, `manifest_version/0`, `newest_changelog_version/0`, and `release_workflow_job/2` use `|> List.first()` which silently returns `nil` on no-match

**File:** `test/lockspire/release_readiness_contract_test.exs:96-138`
**Issue:** This is pre-existing (not introduced by Phase 97), but the Phase 97 helpers explicitly avoid this pattern (per RESEARCH Pitfall 4, they use `case` + raise). The existing helpers in the same file still use `|> List.first()`, which would silently return `nil` if `Regex.run` finds no match — leading to obscure later failures like `nil =~ "..."` or `nil == nil` succeeding when the assertion was supposed to compare versions. Mentioning here for consistency; not a Phase 97 regression.

**Fix:** Out of Phase 97 scope. Could be a follow-up cleanup to convert all `Regex.run` callers in this file to `case` + raise on no-match.

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
