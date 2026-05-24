# Phase 29: Truthful Discovery, SECURITY/Docs, and Milestone Closure - Research

**Researched:** 2024-05-20
**Domain:** Documentation, Discovery Advertising, Integration Testing, Milestone Closure
**Confidence:** HIGH

## Summary

This phase finalizes the Dynamic Client Registration (DCR) milestone (v1.5). It aligns the OIDC discovery document (`openid_configuration`) with runtime DCR enablement, ensures `:disabled` policy responds with a secure 404, updates `SECURITY.md` to precisely scope what's supported vs. what's host-responsibility (e.g., rate limiting), and creates the overarching `dynamic-registration.md` guide. Finally, it implements a comprehensive E2E test covering the full DCR lifecycle including token issuance, and closes the milestone traceability.

**Primary recommendation:** Use `Lockspire.Storage.Ecto.Repository.get_server_policy/0` inside `Lockspire.Protocol.Discovery` to conditionally expose `registration_endpoint`. The `ensure_dcr_enabled` plug in `RegistrationController` already returns 404 for `:disabled` policy, but a contract test MUST assert the alignment of these two.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Discovery Advertising | Protocol | — | `Lockspire.Protocol.Discovery` owns the `openid_configuration` truth. |
| DCR Routing Disabled | API / Backend | — | `Lockspire.Web.RegistrationController` owns 404ing requests when policy is `:disabled`. |
| Rate Limiting (DCR) | API / Backend (Host)| — | Must explicitly push rate limiting to the host app (Plug seam). |
| Milestone Tracing | Docs | — | `REQUIREMENTS.md` and `SECURITY.md` |

## Standard Stack

(No new stack additions. Core Phoenix and Lockspire testing tools.)

## Architecture Patterns

### System Architecture Diagram
(N/A - This phase primarily focuses on aligning existing components rather than adding new ones.)

### Pattern 1: Conditional Endpoint Advertising
**What:** The `registration_endpoint` must only be advertised if the policy allows it.
**When to use:** In `Lockspire.Protocol.Discovery.mounted_endpoint_metadata/0` or `endpoint_metadata_entry/2`.
**Example:**
```elixir
  @endpoint_paths %{
    # ...
    "registration_endpoint" => "/register"
  }

  defp mounted_endpoint_metadata do
    issuer = Config.issuer!()
    {:ok, policy} = Lockspire.Storage.Ecto.Repository.get_server_policy()

    mounted_route_paths()
    |> Enum.reduce(%{}, fn path, acc ->
      case endpoint_metadata_entry(issuer, path, policy) do
        nil -> acc
        {key, value} -> Map.put(acc, key, value)
      end
    end)
  end

  defp endpoint_metadata_entry(issuer, path, policy) do
    Enum.find_value(@endpoint_paths, fn {key, route_path} ->
      if route_path == path do
        # Do not advertise /register if policy is :disabled
        if key == "registration_endpoint" and policy.registration_policy == :disabled do
          nil
        else
          {key, issuer_url(issuer, route_path)}
        end
      end
    end)
  end
```

### Pattern 2: Explicit 404 for Disabled Endpoints
**What:** Ensuring that disabled features do not hint at their existence (404 instead of 403).
**Example:** `Lockspire.Web.RegistrationController.ensure_dcr_enabled/2` already returns 404 when `server_policy.registration_policy == :disabled`. This is correct and requires no changes, but MUST be verified by the new contract test.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DCR E2E Test | Separate test files per feature | Single `phase29_dcr_e2e_test.exs` | End-to-end flow requires state from previous steps (IAT -> Registration -> Token -> Revocation). |

## Common Pitfalls

### Pitfall 1: Rate Limiting
**What goes wrong:** DCR endpoint is subject to abuse (brute-force registration).
**Why it happens:** The library doesn't know the host's infrastructure (Redis, etc.).
**How to avoid:** Explicitly state in `SECURITY.md` that built-in rate limiting is out of scope and document the host-side rate-limit Plug seam.

### Pitfall 2: Discovery and Runtime Drift
**What goes wrong:** `/register` returns 404, but `/.well-known/openid-configuration` still advertises `registration_endpoint`.
**Why it happens:** Discovery currently only checks router mounted paths, not the live policy state.
**How to avoid:** The contract test explicitly sets the three modes (`:disabled`, `:initial_access_token`, `:open`) and checks both the discovery JSON and a `POST /register` call in the same test.

## Code Examples

### Updating `mix.exs` `:extras`
```elixir
  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "SECURITY.md",
        "docs/getting-started.md",
        "docs/install-and-onboard.md",
        "docs/operator-admin.md",
        "docs/dynamic-registration.md", # <- ADDED
        "docs/supported-surface.md",
        "docs/maintainer-release.md",
        "docs/sigra-companion-host.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/getting-started.md",
          "docs/install-and-onboard.md",
          "docs/operator-admin.md",
          "docs/dynamic-registration.md", # <- ADDED
          "docs/supported-surface.md",
          "docs/sigra-companion-host.md"
        ],
        # ...
```

## State of the Art
(No significant changes to the state of the art in this phase, which is purely milestone closure.)

### Open Questions (RESOLVED)
None.

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test` |
| Full suite command | `MIX_ENV=test mix test.integration` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCR-16 | Discovery aligns with mode | contract | `mix test test/lockspire/protocol/discovery_test.exs` | ✅ Wave 0 |
| DCR-17 | E2E Scenario includes Token | e2e | `mix test test/integration/phase29_dcr_e2e_test.exs` | ❌ Wave 0 |
| DCR-24 | SECURITY.md explicitly lists out of scope | manual | `cat SECURITY.md` | ✅ Wave 0 |
| DCR-25 | `docs/dynamic-registration.md` created | manual | `cat docs/dynamic-registration.md` | ❌ Wave 0 |
| DCR-26 | `mix.exs` lists `docs/dynamic-registration.md` | manual | `mix docs` | ✅ Wave 0 |
| DCR-27 | Closure record & trace matrix | manual | `cat REQUIREMENTS.md` | ✅ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | DCR issues Registration Access Tokens |
| V4 Access Control | yes | Disabled policy returns 404 |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Registration Endpoint DoS | Denial of Service | Host application MUST apply rate limiting via Plug pipeline on the Lockspire route. Documented in `SECURITY.md`. |
| Disabled Endpoint Discovery | Information Disclosure | Do not advertise `registration_endpoint` in OIDC discovery if policy is disabled. |

## Sources
### Primary (HIGH confidence)
- Codebase: `lib/lockspire/protocol/discovery.ex`
- Codebase: `lib/lockspire/web/controllers/registration_controller.ex`
- Codebase: `SECURITY.md`
- Codebase: `mix.exs`

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - No new stack.
- Architecture: HIGH - Verified via code review of `Discovery` and `RegistrationController`.
- Pitfalls: HIGH - Documented explicit need to offload rate-limiting to host.

**Research date:** 2024-05-20
**Valid until:** 2024-06-20