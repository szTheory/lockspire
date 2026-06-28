---
phase: 121-route-scorecards-judgment-contract
reviewed: 2026-06-28T18:34:24Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - docs/operator-admin.md
  - test/support/lockspire/web/admin_proof/route_scorecards.ex
  - test/lockspire/web/live/admin/design_system_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 121: Code Review Report

**Reviewed:** 2026-06-28T18:34:24Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the Phase 121 operator docs, route-scorecard parser helper, and design-system contract tests. The runtime boundary wording is intact, but the scorecard guardrails have false-pass gaps that can let broken maintainer evidence through.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: [WARNING] Non-route follow-up allowance accepts invalid admin routes

**File:** `test/lockspire/web/live/admin/design_system_contract_test.exs:1744`
**Issue:** `explicit_non_route_follow_up?/1` accepts any follow-up containing the substring `"none"`. That means an invalid admin route such as `/admin/nonexistent` is treated as an explicit non-route follow-up and passes the Phase 121 route-truth contract. Follow-up route correctness is one of the core scorecard guarantees, so this false pass can hide broken scorecard navigation.
**Fix:**
```elixir
defp explicit_non_route_follow_up?(value) do
  value =
    value
    |> trimmed_backtick_value()
    |> String.downcase()

  not String.starts_with?(value, "/admin") and
    (value in ["none", "absent"] or
       Regex.match?(~r/\b(external|documentation-only|docs-only)\b/, value))
end
```

### WR-02: [WARNING] Duplicate scorecard fields are silently overwritten

**File:** `test/support/lockspire/web/admin_proof/route_scorecards.ex:91`
**Issue:** The scorecard parser builds fields with `Map.put/3`, so if a scorecard accidentally repeats a field such as `Follow-up route` or `Public support promise`, the later line silently wins. The tests then validate only the final value while the artifact still contains contradictory maintainer guidance.
**Fix:**
```elixir
case Regex.run(~r/^- \*\*([^*]+):\*\*\s*(.*)$/, line) do
  [_, field, value] ->
    if Map.has_key?(fields, field) do
      raise ArgumentError,
            "duplicate field #{inspect(field)} in scorecard #{inspect(route)}"
    end

    Map.put(fields, field, String.trim(value))

  nil ->
    fields
end
```

### WR-03: [WARNING] Secret-evidence guard misses common OAuth leak shapes

**File:** `test/lockspire/web/live/admin/design_system_contract_test.exs:1759`
**Issue:** `assert_no_phase_121_secret_evidence/1` checks a small literal denylist plus a JWT-looking prefix, but Phase 121 docs ban broader token-looking evidence. A scorecard or doc could include common OAuth leak shapes such as `Authorization: Bearer ...`, `client_secret=...`, `access_token=...`, or `refresh_token=...` and still pass.
**Fix:** Add regex checks for common credential parameter/header shapes and keep them scoped enough to avoid matching ordinary prose.
```elixir
for pattern <- [
      ~r/\bauthorization:\s*bearer\s+[a-z0-9._~+\/=-]{20,}/i,
      ~r/\b(?:client_secret|access_token|refresh_token|id_token|device_code|user_code)=\S{8,}/i,
      ~r/-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/
    ] do
  refute Regex.match?(pattern, source)
end
```

---

_Reviewed: 2026-06-28T18:34:24Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
