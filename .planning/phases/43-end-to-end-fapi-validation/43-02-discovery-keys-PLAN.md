---
phase: 43-end-to-end-fapi-validation
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/lockspire/protocol/discovery.ex
  - test/lockspire/protocol/discovery_test.exs
autonomous: true
requirements: [FAPI-06]
must_haves:
  truths:
    - "Discovery doc unconditionally publishes authorization_response_iss_parameter_supported: true (D-07)"
    - "Discovery doc publishes require_pushed_authorization_requests: true ONLY when global server_policy.security_profile == :fapi_2_0_security (D-08)"
    - "Discovery doc does NOT publish mTLS, JARM, or signed_metadata keys (D-09)"
    - "Per-client security_profile overrides do NOT flip the discovery PAR key — discovery is server-wide (D-08)"
    - "When global profile is :none, the require_pushed_authorization_requests key is ABSENT (not false)"
  artifacts:
    - path: "lib/lockspire/protocol/discovery.ex"
      provides: "Two new pipeline steps: put_iss_parameter_metadata/1 and maybe_put_par_required_metadata/1"
      contains: "authorization_response_iss_parameter_supported"
    - path: "lib/lockspire/protocol/discovery.ex"
      provides: "Conditional PAR-required key gated on global server policy"
      contains: "require_pushed_authorization_requests"
    - path: "test/lockspire/protocol/discovery_test.exs"
      provides: "Unit tests for both new keys under both profile modes"
      contains: "authorization_response_iss_parameter_supported"
  key_links:
    - from: "openid_configuration/0 pipeline"
      to: "put_iss_parameter_metadata/1"
      via: "chain after put_bcl_fcl_metadata/1"
      pattern: "\\|> put_iss_parameter_metadata\\(\\)"
    - from: "openid_configuration/0 pipeline"
      to: "maybe_put_par_required_metadata/1"
      via: "chain after put_iss_parameter_metadata/1"
      pattern: "\\|> maybe_put_par_required_metadata\\(\\)"
    - from: "maybe_put_par_required_metadata/1"
      to: "Lockspire.Storage.Ecto.Repository.get_server_policy/0"
      via: "global_security_profile/0 helper"
      pattern: "Repository\\.get_server_policy"
---

<objective>
Add two new keys to the `.well-known/openid-configuration` discovery document so it tells the
truth about what Lockspire actually enforces under FAPI 2.0:

1. `authorization_response_iss_parameter_supported: true` — UNCONDITIONAL (D-07), mirroring
   the unconditional iss emission contract from Plan 01 (D-04).
2. `require_pushed_authorization_requests: true` — CONDITIONAL on the global
   `server_policy.security_profile == :fapi_2_0_security` (D-08). Per-client overrides do NOT
   flip a server-wide discovery key.

Purpose: Truthful discovery — RPs can read the metadata and learn that mix-up mitigation is
in effect (always) and that PAR is mandatory at the server boundary (when FAPI is the global
profile). Aligns with Phase 42 D-11 (truthful publication).

Output: One modified module, two new private helpers chained into the existing builder pipeline.
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
Existing builder pipeline the executor must extend.

From lib/lockspire/protocol/discovery.ex (lines 74-94):
```elixir
def openid_configuration do
  issuer = Config.issuer!()
  endpoint_metadata = mounted_endpoint_metadata()

  %{
    "issuer" => issuer,
    "scopes_supported" => scopes_supported(),
    ...
    "id_token_signing_alg_values_supported" => id_token_signing_alg_values_supported()
  }
  |> Map.merge(endpoint_metadata)
  |> maybe_put_dpop_metadata(endpoint_metadata)
  |> put_bcl_fcl_metadata()
end
```

Existing unconditional-merge precedent (lines 185-192):
```elixir
defp put_bcl_fcl_metadata(metadata) do
  Map.merge(metadata, %{
    "backchannel_logout_supported" => true,
    ...
  })
end
```

Existing conditional-merge precedent (lines 168-178):
```elixir
defp maybe_put_dpop_metadata(metadata, endpoint_metadata) do
  if dpop_supported_surface_mounted?(endpoint_metadata) do
    Map.put(metadata, "dpop_signing_alg_values_supported", DPoP.signing_alg_values_supported())
  else
    metadata
  end
end
```

Existing global-profile-resolution precedent inside this module (lines 96-104):
```elixir
defp id_token_signing_alg_values_supported do
  profile =
    case Lockspire.Storage.Ecto.Repository.get_server_policy() do
      {:ok, policy} -> policy.security_profile
      _ -> :none
    end

  Lockspire.Protocol.SecurityProfile.allowed_signing_algorithms(profile)
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add unconditional iss-parameter discovery key (D-07)</name>
  <files>lib/lockspire/protocol/discovery.ex, test/lockspire/protocol/discovery_test.exs</files>
  <read_first>
    - lib/lockspire/protocol/discovery.ex (entire file — confirm openid_configuration/0 pipeline, put_bcl_fcl_metadata/1 precedent)
    - test/lockspire/protocol/discovery_test.exs (read fully to understand existing test setup, fixture clients, and assertion style)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-07 — unconditional, D-09 — do NOT publish mTLS/JARM/signed_metadata)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Publish FAPI 2.0 keys" section)
  </read_first>
  <behavior>
    - `Discovery.openid_configuration/0` returns a map containing `"authorization_response_iss_parameter_supported" => true` for ANY caller, regardless of server policy or profile resolution
    - The new key appears alongside existing keys (issuer, dpop_signing_alg_values_supported, etc.)
    - No mTLS, JARM, or signed_metadata keys are introduced
  </behavior>
  <action>
    In `lib/lockspire/protocol/discovery.ex`:

    1. Add a new private helper following the `put_bcl_fcl_metadata/1` shape:
       ```elixir
       defp put_iss_parameter_metadata(metadata) do
         Map.put(metadata, "authorization_response_iss_parameter_supported", true)
       end
       ```
       Place it immediately after `put_bcl_fcl_metadata/1` (around line 192).

    2. Chain it into the `openid_configuration/0` pipeline at the end of the existing chain:
       ```elixir
       |> Map.merge(endpoint_metadata)
       |> maybe_put_dpop_metadata(endpoint_metadata)
       |> put_bcl_fcl_metadata()
       |> put_iss_parameter_metadata()
       ```
       (The next task adds one more `|> maybe_put_par_required_metadata()` step after this.)

    3. Add a unit test in `test/lockspire/protocol/discovery_test.exs`:
       ```elixir
       test "publishes authorization_response_iss_parameter_supported unconditionally" do
         metadata = Discovery.openid_configuration()
         assert metadata["authorization_response_iss_parameter_supported"] == true
       end
       ```
       Also add a refute test to lock D-09 negative claims:
       ```elixir
       test "does NOT publish mTLS, JARM, or signed_metadata keys (D-09)" do
         metadata = Discovery.openid_configuration()
         refute Map.has_key?(metadata, "tls_client_certificate_bound_access_tokens")
         refute Map.has_key?(metadata, "authorization_signing_alg_values_supported")
         refute Map.has_key?(metadata, "signed_metadata")
       end
       ```

    Do NOT make this key conditional. D-07 is explicit: unconditional, mirroring Plan 01's
    unconditional iss emission contract.
  </action>
  <verify>
    <automated>mix test test/lockspire/protocol/discovery_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "authorization_response_iss_parameter_supported" lib/lockspire/protocol/discovery.ex` returns >= 1
    - `grep -c "put_iss_parameter_metadata" lib/lockspire/protocol/discovery.ex` returns >= 2 (one definition, one pipeline call)
    - `grep -E "tls_client_certificate_bound_access_tokens|authorization_signing_alg_values_supported|^.*signed_metadata.*=>" lib/lockspire/protocol/discovery.ex` returns no matches (D-09 — these keys are NOT introduced)
    - `mix test test/lockspire/protocol/discovery_test.exs` exits 0
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    Discovery unconditionally publishes the iss-parameter key; D-09 negative claims locked by tests; compilation warning-free.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add conditional PAR-required discovery key (D-08)</name>
  <files>lib/lockspire/protocol/discovery.ex, test/lockspire/protocol/discovery_test.exs</files>
  <read_first>
    - lib/lockspire/protocol/discovery.ex (re-read after Task 1 edits — confirm new helper landed and pipeline updated)
    - lib/lockspire/protocol/security_profile.ex (confirm SecurityProfile.Resolved struct + global vs per-client distinction)
    - test/lockspire/protocol/discovery_test.exs (re-read after Task 1 edits)
    - lib/lockspire/storage/ecto/repository.ex (lines 100-115 — confirm Repository.update_client/2 signature for per-client override test)
    - lib/lockspire/clients.ex (lines 85-150 — confirm Lockspire.Clients.register_client/1 returns {:ok, %{client: ..., client_secret: ...}})
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-08 — gated on GLOBAL server policy only, NOT per-client)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Publish FAPI 2.0 keys" — conditional helper)
  </read_first>
  <behavior>
    - When global `server_policy.security_profile == :fapi_2_0_security`, `Discovery.openid_configuration/0` includes `"require_pushed_authorization_requests" => true`
    - When global `server_policy.security_profile == :none` (or any other value, or repo lookup fails), the key is ABSENT from the map (not present with value `false`)
    - When the GLOBAL profile is `:none` AND a per-client override sets `security_profile: :fapi_2_0_security` on a registered client, the discovery output STILL omits `require_pushed_authorization_requests` (discovery reads global, not per-client — this is the proof)
  </behavior>
  <action>
    In `lib/lockspire/protocol/discovery.ex`:

    1. Add a private helper that resolves the GLOBAL profile (mirror lines 96-104, but as a reusable helper):
       ```elixir
       defp global_security_profile do
         case Lockspire.Storage.Ecto.Repository.get_server_policy() do
           {:ok, policy} -> policy.security_profile
           _ -> :none
         end
       end
       ```
       If the executor wishes to dedupe `id_token_signing_alg_values_supported/0` to call this new helper, that is acceptable refactoring (Claude's Discretion per CONTEXT). Otherwise leave it duplicated for minimal churn.

    2. Add the conditional discovery helper following `maybe_put_dpop_metadata/2` shape:
       ```elixir
       defp maybe_put_par_required_metadata(metadata) do
         if global_security_profile() == :fapi_2_0_security do
           Map.put(metadata, "require_pushed_authorization_requests", true)
         else
           metadata
         end
       end
       ```

    3. Chain into the pipeline as the FINAL step:
       ```elixir
       |> Map.merge(endpoint_metadata)
       |> maybe_put_dpop_metadata(endpoint_metadata)
       |> put_bcl_fcl_metadata()
       |> put_iss_parameter_metadata()
       |> maybe_put_par_required_metadata()
       ```

    4. Add three tests in `test/lockspire/protocol/discovery_test.exs`. Use the existing test
       setup pattern that registers a `Lockspire.Domain.ServerPolicy` and toggles its profile via
       `Repository.put_server_policy/1` (mirror the pattern in
       `test/integration/phase41_fapi_2_0_e2e_test.exs:438-441`):
       ```elixir
       test "publishes require_pushed_authorization_requests when global profile is :fapi_2_0_security" do
         put_server_security_profile!(:fapi_2_0_security)
         metadata = Discovery.openid_configuration()
         assert metadata["require_pushed_authorization_requests"] == true
       end

       test "OMITS require_pushed_authorization_requests key when global profile is :none" do
         put_server_security_profile!(:none)
         metadata = Discovery.openid_configuration()
         refute Map.has_key?(metadata, "require_pushed_authorization_requests")
       end

       test "per-client :fapi_2_0_security override does NOT flip discovery PAR key when global is :none" do
         # This is the LOCK for D-08: discovery is SERVER-WIDE. A per-client opt-in must
         # NOT change the discovery shape. We prove it by ACTUALLY registering a per-client
         # override and verifying the discovery key remains absent.
         put_server_security_profile!(:none)

         {:ok, %{client: client}} =
           Lockspire.Clients.register_client(%{
             name: "discovery per-client override fixture",
             client_type: :confidential,
             redirect_uris: ["https://override.example.com/cb"],
             allowed_scopes: ["openid"],
             allowed_grant_types: ["authorization_code"],
             allowed_response_types: ["code"],
             token_endpoint_auth_method: :client_secret_basic
           })

         {:ok, _updated} =
           Lockspire.Storage.Ecto.Repository.update_client(client, %{
             security_profile: :fapi_2_0_security
           })

         metadata = Discovery.openid_configuration()
         refute Map.has_key?(metadata, "require_pushed_authorization_requests")
       end
       ```

       Add a small `put_server_security_profile!/1` helper inside the test module (or reuse an
       existing analog from `test/lockspire/storage/ecto/repository_test.exs` if present) that
       reads the current policy, updates `:security_profile`, and persists it.

       NOTE: The third test must ACTUALLY register a per-client override (not just duplicate
       the second test). If the executor finds during implementation that
       `Lockspire.Clients.register_client/1` does not accept `:security_profile` directly in
       attrs and the override must be applied via `Repository.update_client/2` afterward (as
       shown above), use that two-step flow. If `register_client/1` accepts `:security_profile`
       in attrs directly (verify by reading lib/lockspire/clients.ex), prefer the single-call
       form. Either way, the test MUST trigger a code path that creates a client with
       per-client `security_profile: :fapi_2_0_security` while the global profile is `:none`.

    Do NOT publish `false` when the profile is `:none` — D-08 says ABSENT vs PRESENT, not
    `true` vs `false`. The `if/else` returning `metadata` unchanged is the correct shape.
  </action>
  <verify>
    <automated>mix test test/lockspire/protocol/discovery_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "require_pushed_authorization_requests" lib/lockspire/protocol/discovery.ex` returns >= 1
    - `grep -c "maybe_put_par_required_metadata" lib/lockspire/protocol/discovery.ex` returns >= 2 (one definition, one pipeline call)
    - `grep -c "global_security_profile" lib/lockspire/protocol/discovery.ex` returns >= 2 (one definition, one caller)
    - `mix test test/lockspire/protocol/discovery_test.exs` exits 0
    - All three new tests pass: positive emission under :fapi_2_0_security, ABSENT key under :none, per-client override does NOT flip
    - The third test contains a real per-client override registration (grep for `register_client` AND (`update_client.*security_profile` OR `security_profile.*register_client`) in the new test block — the test must NOT be a structural duplicate of the second test)
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    Discovery conditionally publishes the PAR-required key gated only on global server policy; tests prove the key is ABSENT (not false) under :none; per-client override test ACTUALLY registers an override and proves the discovery shape is unchanged.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Lockspire -> any HTTP client (RP, conformance suite, browser dev tools) | `.well-known/openid-configuration` is an unauthenticated public document |
| Lockspire runtime enforcement -> Lockspire discovery output | The "publish only what is enforced" contract (Phase 42 D-11) — drift here is a discovery overclaim attack vector |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-06 | Information Disclosure (overclaim) | Discovery doc claiming features not actually enforced | mitigate | Discovery keys are wired to actual runtime behavior: `authorization_response_iss_parameter_supported: true` matches Plan 01's unconditional iss emission; `require_pushed_authorization_requests` is gated on the same global profile that drives `FAPI20EnforcerPlug` PAR rejection. Severity: HIGH — overclaiming compliance is itself a security incident under FAPI 2.0 governance. |
| T-43-07 | Spoofing (mix-up via discovery drift) | RP trusts discovery iss capability but Lockspire silently stops emitting iss | mitigate | Plan 06 E2E test asserts both behaviors are aligned end-to-end; release_readiness_contract_test (Plan 07) pins documentation truth. Severity: HIGH — addressed structurally by unconditional design + tests. |
| T-43-08 | Tampering (per-client override misuse) | Client-level FAPI opt-out flips global discovery shape, confusing other RPs | mitigate | `maybe_put_par_required_metadata/1` reads ONLY `Repository.get_server_policy()` (global), never per-client. Test "per-client override does NOT flip" actually registers a per-client `:fapi_2_0_security` override and asserts the discovery key remains absent — locks server-wide gating with real evidence (not a structural duplicate). Severity: MEDIUM — addressed by design and proof-test. |
| T-43-09 | Information Disclosure | Discovery falsely advertises mTLS or signed_metadata | mitigate | D-09 forbids these keys; refute test in Task 1 locks their absence. Severity: HIGH — false mTLS claim would let RPs pin to a non-existent surface. |
| T-43-10 | Repudiation | Operator cannot prove discovery output matched runtime at a given moment | accept | Lockspire does not snapshot discovery; the live endpoint is the source of truth. Severity: LOW. |
</threat_model>

<verification>
- `mix test test/lockspire/protocol/discovery_test.exs` exits 0 (covers all 5 new test cases)
- `mix compile --warnings-as-errors` exits 0
- `grep -c "authorization_response_iss_parameter_supported" lib/lockspire/protocol/discovery.ex` returns >= 1
- `grep -c "require_pushed_authorization_requests" lib/lockspire/protocol/discovery.ex` returns >= 1
- `grep -c "tls_client_certificate_bound_access_tokens" lib/lockspire/protocol/discovery.ex` returns 0 (D-09)
- `grep -c "signed_metadata" lib/lockspire/protocol/discovery.ex` returns 0 (D-09)
</verification>

<success_criteria>
- Discovery doc unconditionally includes `authorization_response_iss_parameter_supported: true`
- Discovery doc conditionally includes `require_pushed_authorization_requests: true` only when global server policy is `:fapi_2_0_security`
- When global is `:none`, the PAR-required key is ABSENT (not `false`)
- Per-client security_profile overrides have ZERO effect on discovery output (proven by an actual override registration in the test, not a structural duplicate)
- Phase 43 E2E test in Plan 06 will rely on this behavior
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-02-SUMMARY.md`
</output>
