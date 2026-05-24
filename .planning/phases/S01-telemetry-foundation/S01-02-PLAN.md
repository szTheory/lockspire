---
phase: S01
plan: 02
type: execute
wave: 2
depends_on: [01]
files_modified: 
  - lib/lockspire/protocol/protected_resource_dpop.ex
  - lib/lockspire/protocol/fapi20_enforcer_plug.ex
autonomous: true
requirements: [S01-INSTRUMENT]
must_haves:
  truths:
    - "Protocol failures emit rich telemetry events."
  artifacts:
    - path: "lib/lockspire/protocol/protected_resource_dpop.ex"
      provides: "Telemetry emission on DPoP failure"
    - path: "lib/lockspire/protocol/fapi20_enforcer_plug.ex"
      provides: "Telemetry emission on FAPI 2.0 enforcement failure"
  key_links: []
---

<objective>
Inject rich telemetry into protocol boundary modules for failure conditions.

Purpose: Provide deep insight into DPoP and FAPI 2.0 failures instead of relying on generic Plug exception handlers.
Output: Specific `Observability.emit` calls in protocol failure paths.
</objective>

<context>
@lib/lockspire/protocol/protected_resource_dpop.ex
@lib/lockspire/protocol/fapi20_enforcer_plug.ex
</context>

<tasks>
<task type="auto">
  <name>Task 1: Instrument DPoP failures</name>
  <files>lib/lockspire/protocol/protected_resource_dpop.ex</files>
  <action>Inject `Observability.emit(:dpop, :failed, %{}, metadata)` in `ProtectedResourceDPoP` on failure paths (e.g., missing proof, invalid signature). Include rich context in metadata like Client ID or User ID if available.</action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>DPoP failures emit telemetry events with failure reasons.</done>
</task>

<task type="auto">
  <name>Task 2: Instrument FAPI 2.0 failures</name>
  <files>lib/lockspire/protocol/fapi20_enforcer_plug.ex</files>
  <action>Inject `Observability.emit(:fapi20, :failed, %{}, metadata)` in `FAPI20EnforcerPlug` on failure paths. Include context such as the exact requirement that failed.</action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>FAPI 2.0 failures emit telemetry events.</done>
</task>
</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Client -> Protocol | Malicious client payloads |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-S01-02 | Information Disclosure | Protocol failure telemetry | mitigate | Ensure sensitive data (like raw DPoP proofs or tokens) are not included in the telemetry metadata; only include client IDs and high-level failure reasons. |
</threat_model>
