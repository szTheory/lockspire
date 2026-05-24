---
phase: S01
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: 
  - lib/lockspire/observability.ex
autonomous: true
requirements: [S01-TELEMETRY]
must_haves:
  truths:
    - "Observability module supports 3-part event schema"
  artifacts:
    - path: "lib/lockspire/observability.ex"
      provides: "New emit function signatures"
  key_links: []
---

<objective>
Refactor `Lockspire.Observability` to use the new hierarchical schema `[:lockspire, :<entity>, :<action>]` instead of flat events.

Purpose: Pre-1.0 breaking change to prepare telemetry for GA users and LiveDashboard integration.
Output: Updated `Observability.ex` and any immediate call sites modified.
</objective>

<context>
@lib/lockspire/observability.ex
</context>

<tasks>
<task type="auto">
  <name>Task 1: Update Observability module schema</name>
  <files>lib/lockspire/observability.ex</files>
  <action>Refactor `emit`, `emit_dcr`, `emit_iat`, `emit_logout` to take `entity` and `action` instead of a single `event_name` (or map existing single names to the new tuple where appropriate). Ensure that `:telemetry.execute/3` emits `[:lockspire, entity, action]`. Update any tests for `Observability`.</action>
  <verify>
    <automated>mix test</automated>
  </verify>
  <done>Observability module cleanly emits hierarchical tuples.</done>
</task>

<task type="auto">
  <name>Task 2: Update existing call sites</name>
  <files>lib/lockspire/**/*.ex</files>
  <action>Find and replace all flat event emissions in the codebase (e.g., `emit(:access_token_issued)`) to use the new hierarchical schema (e.g., `emit(:token, :issued)`). This includes domain models, controllers, and protocols. Ensure that the codebase compiles cleanly.</action>
  <verify>
    <automated>mix compile</automated>
  </verify>
  <done>All tests pass and no flat events are emitted.</done>
</task>
</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Codebase -> Telemetry | Internal telemetry emission |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-S01-01 | Information Disclosure | Observability | mitigate | Ensure `redact/1` is still called on all metadata before emission. |
</threat_model>
