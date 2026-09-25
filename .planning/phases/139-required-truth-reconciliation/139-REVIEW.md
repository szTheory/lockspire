---
phase: 139-required-truth-reconciliation
reviewed: 2026-09-24T20:04:46Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - scripts/maintainer/baseline_inventory.sh
  - test/support/lockspire/release_proof/package_assertions.ex
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 139: Code Review Report

**Reviewed:** 2026-09-24T20:04:46Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** clean

## Summary

Reviewed commit `bafa4a60` at standard depth in the two scoped files, including the completion classifier's row validation, lifecycle classification call path, and adversarial lifecycle fixtures. The change closes CR-01: `validate_phase_139_completion_state` now requires exactly one top-level body row for each tracked completion field, and the added-line allowlist accepts only the exact canonical Phase 140 and Progress values. The new Phase and Progress fixtures append malformed rows while retaining the original canonical rows, and the enclosing acceptance fixture requires the resulting post-transition relation to fail closed. The commit changes only these row checks and fixtures; it does not alter the exact-SHA acceptance authorization logic. No new defects found in the reviewed scope.

## Narrative Findings (AI reviewer)

All reviewed files meet quality standards. No issues found.

---

_Reviewed: 2026-09-24T20:04:46Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

## Follow-up Review — 2026-09-24 (Quick Task 260924-mhp)

**Scope:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`, and `test/lockspire/release/repository_hygiene_contract_test.exs`.

**Follow-up status:** issues_found. The original review status and CR-01 history above remain unchanged.

### BLOCKER — UAT headings inside code blocks authorize false completion

**File:** `scripts/maintainer/baseline_inventory.sh:1556-1557`
**Issue:** `record_has_line` searches the raw document for `## Current Test` and `## Tests` without recognizing Markdown code fences or comments. A malformed UAT document with frontmatter `status: complete` and those heading-shaped lines only inside a fenced code block passes `classify_active_record` and is proposed as `resolved | already-resolved | direct_current`. This can make the maintained inventory report a malformed/incomplete record as resolved. The added near-miss fixtures cover missing headings but not heading-shaped text that is not a Markdown section.
**Fix:** Parse the Markdown section headings while ignoring fenced code blocks (and other non-rendered regions), and add a fixture whose only matching heading lines are inside a fence; it must remain `unclassified | unclassified | inferred` and make the family/aggregate receipt partial.

---

_Follow-up reviewed: 2026-09-24T20:25:43Z_
_Reviewer: the agent (gsd-code-reviewer)_

## Follow-up Review — UAT heading fix commit 2b0b768b

**Scope:** `scripts/maintainer/baseline_inventory.sh`, its active-record classification caller, and the maintained active-UAT fixtures in `test/support/lockspire/release_proof/package_assertions.ex`.

**Prior blocker:** CLOSED. `classify_active_record` now calls `record_has_markdown_heading` for both required UAT headings. That parser ignores lines inside backtick/tilde fenced blocks and removes HTML comments before checking headings. The new fenced and commented hostile fixtures both retain `status: complete` but are asserted to remain `unclassified/ambiguous`, and the receipt/family must become partial. Existing positive fixtures still assert that rendered headings classify a complete UAT as `resolved | already-resolved` and a partial UAT as `active | defer-with-trigger`.

**Follow-up status:** issues_found. One additional non-rendered region remains accepted.

### BLOCKER — UAT headings in frontmatter still authorize completion

**File:** `scripts/maintainer/baseline_inventory.sh:1524-1573` (heading parser); caller at `1607-1612`
**Issue:** `record_has_markdown_heading` scans the entire record and skips fences and HTML comments, but does not skip the delimited frontmatter block. A record shaped as `---`, `status: complete`, `## Current Test`, `## Tests`, `---`, followed by body text will have its status extracted by `front_matter_value_from_file` and both hidden frontmatter lines accepted as headings. `classify_active_record` then emits `resolved | already-resolved | direct_current` even though the document has no rendered required headings. This preserves the same false-completion authorization failure for malformed UAT records through a different non-rendered region.
**Fix:** Limit heading recognition to the document body after the opening and closing frontmatter delimiters, and add a hostile fixture with both required headings inside frontmatter. It must remain `unclassified | unclassified | inferred` and make the family and aggregate receipt partial.

---

_Follow-up reviewed: 2026-09-24_
_Reviewer: the agent (gsd-code-reviewer)_
_Scope: heading fix commit 2b0b768b_

## Follow-up Review — UAT heading scanner fix commit 785b565b

**Scope:** `scripts/maintainer/baseline_inventory.sh` UAT heading recognition and the maintained active-UAT fixtures in `test/support/lockspire/release_proof/package_assertions.ex`.

**Prior blocker — CLOSED:** The frontmatter bypass is closed. `record_has_markdown_heading` enters frontmatter only on an opening delimiter at line 1, skips its contents, and resumes after the closing delimiter (`scripts/maintainer/baseline_inventory.sh:1533-1537`). The new hostile fixture places both required headings before that closing delimiter and is included among unclassified near misses (`test/support/lockspire/release_proof/package_assertions.ex:6470-6471,6569-6570`). The same near-miss set covers fenced and HTML-comment headings. The positive fixtures retain rendered headings: a `complete` UAT is expected to classify as resolved and a `partial` UAT as active/deferred (`test/support/lockspire/release_proof/package_assertions.ex:988-1020,6551-6554`). The classifier continues to gate those dispositions on the parsed frontmatter status (`scripts/maintainer/baseline_inventory.sh:1615-1621`).

**Follow-up status:** issues_found. One additional non-rendered region remains accepted.

### BLOCKER — Indented code headings authorize false UAT completion

**File:** `scripts/maintainer/baseline_inventory.sh:1557-1558,1577-1578` (heading parser); caller at `1616-1617`
**Issue:** The parser removes all leading whitespace before examining the line, then compares the whitespace-stripped line with the requested heading. Under CommonMark, a line indented by four spaces is an indented code block, not a rendered heading. A `status: complete` UAT containing only four-space-indented `## Current Test` and `## Tests` therefore satisfies both checks and is classified as `resolved | already-resolved | direct_current`, despite having neither required rendered section. This is the same false-completion authorization risk as the closed frontmatter bypass. The hostile fixture set checks fences, comments, and frontmatter, but has no indented-code case.
**Fix:** Recognize only valid rendered Markdown headings while excluding indented code blocks (including lines with four or more leading spaces); add a hostile `status: complete` UAT fixture whose only matching headings are four-space-indented and require it to remain unclassified with a partial family/aggregate receipt.

**Verification note:** This was a static review of the current source and fixture assertions; no tests were run, as requested.

---

_Follow-up reviewed: 2026-09-24_
_Reviewer: the agent (gsd-code-reviewer)_
_Scope: UAT heading fix commit 785b565b_

## Follow-up Review — UAT indented-code heading fix commit a736ef7e

**Scope:** `scripts/maintainer/baseline_inventory.sh` UAT heading recognition and the maintained active-UAT fixtures in `test/support/lockspire/release_proof/package_assertions.ex`.

**Prior blocker — CLOSED:** `record_has_markdown_heading` now counts leading spaces and removes at most three before matching the heading. Thus exact level-2 headings with zero through three leading spaces still match, while four or more leading spaces are skipped as indented code; a leading tab is also skipped (`scripts/maintainer/baseline_inventory.sh:1557-1563`). A tab advances indentation to at least four columns in CommonMark, including when preceded by spaces. The existing scanner continues to skip delimited frontmatter, HTML-comment contents, and fenced code before comparing heading text (`scripts/maintainer/baseline_inventory.sh:1533-1555,1564-1583`). The new `status: complete` hostile fixture contains only four-space-indented matching headings and is included in the near-miss inventory whose records are required to remain absent/unclassified (`test/support/lockspire/release_proof/package_assertions.ex:1018-1039,6572-6573`). The four-space check therefore no longer authorizes false completion.

**Follow-up status:** clean. No new correctness or security defect found in the reviewed scanner change. The requested zero-to-three-space and tab cases were confirmed by static inspection; no tests were run.

---

_Follow-up reviewed: 2026-09-24T20:35:56Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Scope: UAT indented-code heading fix commit a736ef7e_
