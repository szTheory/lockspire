---
phase: 120-browser-proof-docs-regression-audit
reviewed: 2026-06-26T14:43:45Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - docs/operator-admin.md
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - test/lockspire/web/admin_router_test.exs
  - test/lockspire/web/live/admin/clients_live/show_test.exs
  - test/lockspire/web/live/admin/consents_live_test.exs
  - test/lockspire/web/live/admin/design_system_component_stress_test.exs
  - test/lockspire/web/live/admin/design_system_contract_test.exs
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/iat_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
  - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/live/admin/tokens_live_test.exs
  - test/support/lockspire/web/admin_proof/html_assertions.ex
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 120: Code Review Report

**Reviewed:** 2026-06-26T14:43:45Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the Phase 120 docs, admin LiveView route fix, route assertions, design-system regression contracts, and the new shared HTML assertion helper. The production route change from `/admin/logout-deliveries` to `/admin/logouts` is consistent with `Lockspire.Web.AdminRouter`. The issues found are warning-level defects in the new proof layer and one shipped-doc boundary leak.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Empty ARIA Reference Attributes Pass The Target Check

**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:44`
**Issue:** `assert_aria_targets_exist/2` splits each `aria-describedby`, `aria-labelledby`, or `aria-controls` value and only checks the resulting tokens. An element with `aria-describedby=""` or whitespace-only content produces no tokens, so `missing` remains empty and the assertion passes even though the ARIA relationship is invalid and provides no accessible description. This can let accessibility regressions through the Phase 120 proof contracts.
**Fix:**

```elixir
values =
  doc
  |> LazyHTML.query("[#{attribute}]")
  |> LazyHTML.attribute(attribute)

blank_values = Enum.filter(values, &(String.trim(&1) == ""))
assert blank_values == [], "expected #{attribute} values to be non-empty"

missing =
  values
  |> Enum.flat_map(&String.split(&1, ~r/\s+/, trim: true))
  |> Enum.reject(&MapSet.member?(id_set, &1))
  |> Enum.uniq()
```

### WR-02: Controls Without IDs Are Ignored By The Label Contract

**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:78`
**Issue:** `assert_label_targets_exist/1` only queries `input[id], select[id], textarea[id]` when checking unlabeled controls. A regression that removes a control's `id` and its corresponding `label[for]` target drops that control from the query entirely, so the helper can still pass while rendering an unlabeled form control. This weakens the DCR and IAT form contracts that now rely on this helper.
**Fix:**

```elixir
unlabeled =
  doc
  |> LazyHTML.query("input, select, textarea")
  |> LazyHTML.attributes()
  |> Enum.reject(&hidden_input?/1)
  |> Enum.reject(&control_labelled?(&1, label_targets, id_set))
  |> Enum.map(fn attrs -> attribute_value(attrs, "id") || inspect(attrs) end)
```

Also update `control_labelled?/3` so a `label[for]` path requires a non-empty `id`, while `aria-label` and valid `aria-labelledby` remain acceptable alternatives.

### WR-03: Operator Documentation Leaks Phase-Specific Maintainer Internals

**File:** `docs/operator-admin.md:68`
**Issue:** The operator guide now references "The Phase 120 docs/support-boundary contract" directly. This is shipped operator-facing documentation, but the referenced phase contract is an internal planning artifact and not part of the supported surface or package contract. That couples stable docs to an ephemeral review phase and muddies the support boundary the same paragraph is trying to preserve.
**Fix:** Replace the phase-specific sentence with timeless guidance, for example:

```markdown
This section is maintainer-facing operator guidance. It keeps the public support ceiling in `docs/supported-surface.md` while internal proof artifacts, package contents, and admin route behavior remain bounded.
```

---

_Reviewed: 2026-06-26T14:43:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
