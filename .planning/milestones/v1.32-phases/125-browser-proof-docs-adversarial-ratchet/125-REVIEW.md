---
phase: 125-browser-proof-docs-adversarial-ratchet
reviewed: 2026-06-30T18:08:41Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - docs/operator-admin.md
  - test/lockspire/web/live/admin/clients_live/show_test.exs
  - test/lockspire/web/live/admin/clients_live_test.exs
  - test/lockspire/web/live/admin/consents_live_test.exs
  - test/lockspire/web/live/admin/design_system_component_stress_test.exs
  - test/lockspire/web/live/admin/design_system_contract_test.exs
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/iat_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
  - test/lockspire/web/live/admin/keys_live_test.exs
  - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
  - test/lockspire/web/live/admin/overview_live_test.exs
  - test/lockspire/web/live/admin/policies_live/dcr_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  - test/lockspire/web/live/admin/policies_live/index_test.exs
  - test/lockspire/web/live/admin/policies_live/par_test.exs
  - test/lockspire/web/live/admin/policies_live/security_profile_test.exs
  - test/lockspire/web/live/admin/tokens_live_test.exs
  - test/support/lockspire/web/admin_lab/fixtures.ex
  - test/support/lockspire/web/admin_lab/stress_surface.ex
  - test/support/lockspire/web/admin_proof/browser_evidence.ex
  - test/support/lockspire/web/admin_proof/html_assertions.ex
findings:
  critical: 0
  warning: 5
  info: 0
  total: 5
status: issues_found
---

# Phase 125: Code Review Report

**Reviewed:** 2026-06-30T18:08:41Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed the Phase 125 docs, admin route proof tests, fixture/stress helpers, and browser/HTML assertion support modules. No runtime library files were modified in this scope, but the new proof helpers and artifact tests have false-negative paths that can let redaction, stale-route, and browser-evidence regressions pass.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: HTML redaction helper misses common OAuth credential shapes

**Classification:** WARNING
**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:13`
**Issue:** `assert_no_token_like_text/1` only denies JWT-looking strings, live keys, cookie/auth-code/code-verifier/device/user-code assignments, and private keys. It does not deny `access_token=...`, `refresh_token=...`, `id_token=...`, `client_secret=...`, password values, or JSON-style credential fields. Several route tests rely on this helper as a broad rendered-HTML redaction guard, so an admin page could render a raw token parameter and still pass unless that exact page also listed the value in a local denylist.
**Fix:**
```elixir
@token_like_text_patterns [
  {"OAuth credential parameter",
   ~r/(?:^|[?&\s])(?:access_token|refresh_token|id_token|client_secret|password|code_verifier|device_code|user_code)=["']?[A-Za-z0-9._~+%\/=-]{4,}/i},
  {"OAuth credential JSON",
   ~r/"(?:access_token|refresh_token|id_token|client_secret|password|code_verifier|device_code|user_code)"\s*:\s*"[^"]{4,}"/i},
  ...
]
```
Add contract cases for access, refresh, ID token, client secret, and JSON examples.

### WR-02: Generic CTA guard is case-sensitive

**Classification:** WARNING
**File:** `test/support/lockspire/web/admin_proof/html_assertions.ex:179`
**Issue:** `assert_no_generic_cta_text/1` delegates to `assert_no_text/2`, which performs a case-sensitive substring check. Lowercase or case-varied labels such as `submit`, `learn more`, or `Click Here` would pass even though the tests intend to block generic CTA drift across the admin surface.
**Fix:**
```elixir
def assert_no_text(html, denied_values) when is_list(denied_values) do
  source = html_source(html)

  for denied <- denied_values, is_binary(denied), denied != "" do
    refute Regex.match?(~r/\b#{Regex.escape(denied)}\b/i, source),
           "expected rendered HTML to omit denied text #{inspect(denied)}"
  end

  html
end
```
Use an explicit case-insensitive helper or add a dedicated `assert_no_generic_cta_text/1` regex that normalizes casing.

### WR-03: Browser evidence route validation accepts unsupported `/admin*` paths

**Classification:** WARNING
**File:** `test/support/lockspire/web/admin_proof/browser_evidence.ex:177`
**Issue:** `validate_route!/1` accepts any route that starts with `"/admin"`. That admits stale or unsupported evidence rows such as `/administrator`, `/admin-browser-proof`, or `/admin/component-lab`, which undercuts the Phase 125 goal of preventing support-surface expansion and stale route evidence.
**Fix:**
```elixir
defp validate_route!("/admin"), do: :ok
defp validate_route!("/admin/" <> _rest), do: :ok
defp validate_route!("AdminLab.StressSurface"), do: :ok
defp validate_route!(route), do: raise ArgumentError, "malformed Route / Surface #{inspect(route)}"
```
Prefer comparing against source-derived AdminRouter route truth plus the single explicit internal lab surface.

### WR-04: Closeout evidence test allows failing or gap rows outside the representative set

**Classification:** WARNING
**File:** `test/lockspire/web/live/admin/design_system_contract_test.exs:541`
**Issue:** The parser allows `pass`, `fail`, `gap`, and `blocked`, but the closeout artifact test only asserts `Result == "pass"` for five required representative rows. Additional rows for other admin routes can report `fail`, `gap`, or `blocked` and the test still passes, so the final browser evidence artifact can contain known unresolved failures without tripping the ratchet.
**Fix:**
```elixir
unexpected =
  rows
  |> Enum.reject(&(&1["Result"] == "pass" and &1["Gap note"] == "none"))

assert unexpected == [],
       "browser evidence contains non-passing or gap rows: #{inspect(unexpected)}"
```
If gaps are intentionally allowed, require a source-controlled allowlist and assert that every gap is explicitly linked to a follow-up.

### WR-05: Default test suite depends on a maintainer-only planning artifact

**Classification:** WARNING
**File:** `test/lockspire/web/live/admin/design_system_contract_test.exs:518`
**Issue:** The new tests read `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` directly. That makes supplemental browser/manual evidence a default ExUnit dependency even though the project boundary says browser/manual evidence is maintainer-only and supplemental. A missing, renamed, or locally edited planning artifact can fail or bless the normal test suite independently of source behavior.
**Fix:** Keep parser behavior covered with inline fixtures in ExUnit, and move validation of the phase proof artifact into the GSD workflow or a tagged maintainer-only test that is excluded from default `mix test`.

---

_Reviewed: 2026-06-30T18:08:41Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
