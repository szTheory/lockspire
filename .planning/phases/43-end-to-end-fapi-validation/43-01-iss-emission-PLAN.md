---
phase: 43-end-to-end-fapi-validation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/web/controllers/authorize_controller.ex
autonomous: true
requirements: [FAPI-06]
must_haves:
  truths:
    - "Successful /authorize redirects include iss=<issuer> as a query parameter (D-04, D-05)"
    - "Access-denied /authorize redirects include iss=<issuer> as a query parameter (D-04, D-05)"
    - "Validation/protocol error redirects from AuthorizeController include iss=<issuer> (D-04, D-05)"
    - "iss emission is unconditional — applies to every client regardless of security_profile (D-04)"
    - "iss is NOT added to /token, /revoke, /introspect responses (D-06) — only authorization-response redirects"
  artifacts:
    - path: "lib/lockspire/protocol/authorization_flow.ex"
      provides: "iss appended in approval_redirect/2 and denial_redirect/1 params maps"
      contains: '"iss" => Config.issuer!()'
    - path: "lib/lockspire/web/controllers/authorize_controller.ex"
      provides: "iss appended in redirect_location/1 oauth_params map; alias Lockspire.Config added"
      contains: '"iss" => Config.issuer!()'
  key_links:
    - from: "lib/lockspire/protocol/authorization_flow.ex (approval_redirect/2, denial_redirect/1)"
      to: "Lockspire.Config.issuer!/0"
      via: "Config alias already imported at line 6"
      pattern: '"iss" => Config.issuer!\\(\\)'
    - from: "lib/lockspire/web/controllers/authorize_controller.ex (redirect_location/1)"
      to: "Lockspire.Config.issuer!/0"
      via: "new alias Lockspire.Config in module alias block"
      pattern: "alias Lockspire\\.Config"
---

<objective>
Append RFC 9207 `iss` parameter to every authorization-response redirect — success, denial, and
validation/protocol error paths — across the two emission seams in Lockspire. Per D-04/D-05, this
is unconditional (every client, not gated on `:fapi_2_0_security`) and uniform across both seams,
so a profile flip never creates an `iss`-less bypass.

Purpose: Mitigate RFC 9207 mix-up attacks for all clients and keep discovery truth (D-07: discovery
unconditionally publishes `authorization_response_iss_parameter_supported: true`) aligned with
runtime behavior.

Output: Two modified files; both seams emit `iss` on every authorization redirect.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md
@.planning/phases/43-end-to-end-fapi-validation/43-RESEARCH.md
@.planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md

<interfaces>
Existing redirect-builder seams the executor must extend. Use these directly — no codebase
exploration needed beyond `read_first` files.

From lib/lockspire/protocol/authorization_flow.ex (already aliases Config at line 6):
```elixir
defp approval_redirect(%Interaction{} = interaction, raw_code) do
  build_redirect(interaction.redirect_uri, %{
    "code" => raw_code,
    "state" => interaction.state
  })
end

defp denial_redirect(%Interaction{} = interaction) do
  build_redirect(interaction.redirect_uri, %{
    "error" => "access_denied",
    "state" => interaction.state
  })
end

defp build_redirect(base_uri, params) when is_binary(base_uri) and is_map(params) do
  uri = URI.parse(base_uri)
  existing = URI.decode_query(uri.query || "")

  merged =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> then(&Map.merge(existing, &1))

  %{uri | query: URI.encode_query(merged)}
  |> URI.to_string()
end
```

From lib/lockspire/web/controllers/authorize_controller.ex (Config alias is NOT yet present — must be added):
```elixir
defp redirect_location(%Error{} = error) do
  uri = URI.parse(error.redirect_uri)
  existing_params = URI.decode_query(uri.query || "")

  oauth_params =
    %{
      "error" => error.error,
      "error_description" => error.error_description,
      "state" => error.state
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()

  uri
  |> Map.put(:query, URI.encode_query(Map.merge(existing_params, oauth_params)))
  |> URI.to_string()
end
```

Truth source for the value (`lib/lockspire/config.ex` lines 20-29) — `Config.issuer!/0` reads the
`:lockspire :issuer` env var and raises if unset.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Append iss to AuthorizationFlow approval and denial redirects (D-04, D-05)</name>
  <files>lib/lockspire/protocol/authorization_flow.ex, test/lockspire/protocol/authorization_flow_test.exs</files>
  <read_first>
    - lib/lockspire/protocol/authorization_flow.ex (entire file — confirm Config alias at line 6, find approval_redirect/2 and denial_redirect/1 around lines 376-388)
    - lib/lockspire/config.ex (confirm Config.issuer!/0 signature)
    - test/lockspire/protocol/authorization_flow_test.exs (if it exists — confirm shape; if not, the executor will create a minimal test module)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-04, D-05, D-06 — unconditional, uniform, scope to authorization responses only)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Append iss to success + denial redirects" section)
  </read_first>
  <behavior>
    - approval_redirect/2 returns a URL whose URI-decoded query contains "iss" => "<configured issuer>" alongside "code" and "state"
    - denial_redirect/1 returns a URL whose URI-decoded query contains "iss" => "<configured issuer>" alongside "error" => "access_denied" and "state"
    - iss emission is unconditional: no `if fapi?` branch, no profile resolution
    - Existing query parameters on the registered redirect_uri are preserved (build_redirect/2 merge semantics unchanged)
  </behavior>
  <action>
    Modify TWO existing private helpers in `lib/lockspire/protocol/authorization_flow.ex` (do NOT touch build_redirect/2):

    1. Replace `approval_redirect/2` so the params map becomes:
       ```elixir
       defp approval_redirect(%Interaction{} = interaction, raw_code) do
         build_redirect(interaction.redirect_uri, %{
           "code" => raw_code,
           "state" => interaction.state,
           "iss" => Config.issuer!()
         })
       end
       ```

    2. Replace `denial_redirect/1` so the params map becomes:
       ```elixir
       defp denial_redirect(%Interaction{} = interaction) do
         build_redirect(interaction.redirect_uri, %{
           "error" => "access_denied",
           "state" => interaction.state,
           "iss" => Config.issuer!()
         })
       end
       ```

    Do NOT add a new alias — `alias Lockspire.Config` is already at line 6. Do NOT add any conditional gating around iss — D-04 mandates unconditional emission per RFC 9207 §2.

    Add (or extend) a unit test file `test/lockspire/protocol/authorization_flow_test.exs` with two tests:
    - One that walks an approval redirect path (use the same `start_authorization` -> `accept_consent` style as elsewhere in the test suite, or directly exercise the private helpers via a public seam) and asserts `URI.decode_query(URI.parse(location).query)` contains `"iss" => "https://issuer.test/lockspire"` (set via `Application.put_env(:lockspire, :issuer, "https://issuer.test/lockspire")` in setup).
    - One that walks a denial path (deny consent) and asserts the same iss key/value plus `"error" => "access_denied"`.
  </behavior>
  <verify>
    <automated>mix test test/lockspire/protocol/authorization_flow_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '"iss" => Config.issuer!()' lib/lockspire/protocol/authorization_flow.ex` returns >= 2
    - `grep -E 'if .*fapi.*iss|iss.*if .*fapi' lib/lockspire/protocol/authorization_flow.ex` returns no matches (no conditional gating around iss)
    - `mix test test/lockspire/protocol/authorization_flow_test.exs` exits 0
    - The new test asserts `URI.decode_query` of the approval redirect query contains `"iss"` with the configured issuer value
    - The new test asserts `URI.decode_query` of the denial redirect query contains `"iss"` with the configured issuer value
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    Both authorization_flow redirect builders emit `iss` unconditionally; tests prove it; compilation is warning-free.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Append iss to AuthorizeController error redirect (D-04, D-05)</name>
  <files>lib/lockspire/web/controllers/authorize_controller.ex, test/lockspire/web/controllers/authorize_controller_test.exs</files>
  <read_first>
    - lib/lockspire/web/controllers/authorize_controller.ex (entire file — confirm alias block at lines 1-15, find redirect_location/1 around lines 129-145)
    - lib/lockspire/config.ex (confirm Config.issuer!/0 signature)
    - test/lockspire/web/controllers/authorize_controller_test.exs (if it exists — confirm shape; if not, the executor will create a minimal test module)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-04, D-05 — error redirects MUST also carry iss)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Append iss to error redirect" section)
  </read_first>
  <behavior>
    - redirect_location/1 returns a URL whose URI-decoded query contains "iss" => "<configured issuer>" alongside "error", "error_description", "state"
    - The Lockspire.Config alias is added to the module alias block (it is NOT currently aliased)
    - Existing query parameters on the registered redirect_uri are preserved (Map.merge semantics unchanged)
    - Nil-stripping of error_description/state still works (Enum.reject still drops nil values)
  </behavior>
  <action>
    In `lib/lockspire/web/controllers/authorize_controller.ex`:

    1. Add `alias Lockspire.Config` to the alias block. Place it alphabetically among the existing `alias Lockspire.*` lines (immediately before `alias Lockspire.Host.Claims`). Verify the alias is NOT yet present with `grep "alias Lockspire.Config" lib/lockspire/web/controllers/authorize_controller.ex` returning empty before editing.

    2. Modify `redirect_location/1` (private function around lines 129-145) so the `oauth_params` map includes `"iss"`:
       ```elixir
       defp redirect_location(%Error{} = error) do
         uri = URI.parse(error.redirect_uri)
         existing_params = URI.decode_query(uri.query || "")

         oauth_params =
           %{
             "error" => error.error,
             "error_description" => error.error_description,
             "state" => error.state,
             "iss" => Config.issuer!()
           }
           |> Enum.reject(fn {_key, value} -> is_nil(value) end)
           |> Map.new()

         uri
         |> Map.put(:query, URI.encode_query(Map.merge(existing_params, oauth_params)))
         |> URI.to_string()
       end
       ```

    Do NOT change any other function in this controller. Do NOT add iss to non-error redirect paths in this controller (e.g., `redirect_to_result/2` is for login redirection, NOT an authorization-response — D-06 keeps iss scoped to authorization responses).

    Add (or extend) `test/lockspire/web/controllers/authorize_controller_test.exs` with one test that triggers a validation error redirect through `AuthorizationRequest.validate/1` (e.g., a mismatched redirect_uri or a missing required param while still having a valid registered redirect_uri to redirect to) and asserts the resulting Location header's URI-decoded query string contains `"iss" => "<configured issuer>"`. Use `Application.put_env(:lockspire, :issuer, "https://issuer.test/lockspire")` in setup.
  </action>
  <verify>
    <automated>mix test test/lockspire/web/controllers/authorize_controller_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "alias Lockspire.Config" lib/lockspire/web/controllers/authorize_controller.ex` returns 1
    - `grep -c '"iss" => Config.issuer!()' lib/lockspire/web/controllers/authorize_controller.ex` returns 1
    - `mix test test/lockspire/web/controllers/authorize_controller_test.exs` exits 0
    - The new test asserts `URI.decode_query` of the error redirect Location header contains `"iss"` with the configured issuer value
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    AuthorizeController error redirects emit iss unconditionally; tests prove it; compilation is warning-free.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Authorization Server -> User Agent (browser) -> RP callback | Authorization-response redirect is the canonical mix-up attack surface (RFC 9207 §1) |
| Lockspire -> Phoenix Router -> Plug -> 302 Location header | Where the iss parameter is materialized for the browser to forward |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-01 | Spoofing | RP receiving authorization response | mitigate | Append `iss=Config.issuer!()` to every authorization redirect (success, denial, validation error) so RPs can detect mix-up by comparing iss against the AS they sent the request to (RFC 9207 §2.4). Implemented in both `AuthorizationFlow.{approval_redirect,denial_redirect}` and `AuthorizeController.redirect_location`. Severity: HIGH — this is the only mitigation against mix-up at the authorization-response surface. |
| T-43-02 | Information Disclosure | Issuer URL leaked via Referer/logs to RP | accept | The issuer is already public (advertised in `.well-known/openid-configuration`); echoing it on a redirect adds no new disclosure. Severity: LOW. |
| T-43-03 | Tampering | Attacker rewrites iss in transit | mitigate (defense in depth) | iss travels over TLS to the RP callback (operator-deployed HTTPS). Lockspire does not need additional integrity protection beyond TLS for v1.10. Severity: MEDIUM — covered by transport. Documented in SECURITY.md by Plan 05. |
| T-43-04 | Spoofing (escape hatch) | Per-client `:none` profile leaves iss-less redirects | mitigate | iss emission is UNCONDITIONAL per D-04 (no `if fapi?` branch). A per-client opt-out of FAPI does NOT disable iss emission. Severity: HIGH — addressed structurally by the unconditional design. |
| T-43-05 | Repudiation | RP cannot prove which AS issued the response | mitigate | iss provides authoritative AS identity in the response itself. RP can pin/log iss and detect mix-up post-hoc. Severity: MEDIUM. |
</threat_model>

<verification>
- `mix test test/lockspire/protocol/authorization_flow_test.exs` exits 0
- `mix test test/lockspire/web/controllers/authorize_controller_test.exs` exits 0
- `mix compile --warnings-as-errors` exits 0
- `grep -c '"iss" => Config.issuer!()' lib/lockspire/protocol/authorization_flow.ex` returns >= 2
- `grep -c '"iss" => Config.issuer!()' lib/lockspire/web/controllers/authorize_controller.ex` returns 1
- `grep -c "alias Lockspire.Config" lib/lockspire/web/controllers/authorize_controller.ex` returns 1
- No conditional gating around iss in either file (`grep -nE 'if.*fapi.*iss|iss.*if.*fapi' lib/lockspire/protocol/authorization_flow.ex lib/lockspire/web/controllers/authorize_controller.ex` returns nothing)
</verification>

<success_criteria>
- Both authorization-response emission seams unconditionally append `iss=Config.issuer!()` to the redirect query string (success + denial + validation/protocol error)
- No iss is added to /token, /revoke, /introspect, or login-redirect paths (D-06 scope respected)
- Targeted unit tests in both files prove iss appears in the URI-decoded query of every authorization-response location
- Phase 43 E2E test in Plan 06 will rely on this behavior; this plan must complete before Plan 06 runs
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-01-SUMMARY.md`
</output>
