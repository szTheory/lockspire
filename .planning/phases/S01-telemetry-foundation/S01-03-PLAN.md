---
phase: S01
plan: 03
type: execute
wave: 2
depends_on: [01]
files_modified: 
  - mix.exs
  - lib/lockspire/live_dashboard_page.ex
autonomous: true
requirements: [S01-DASHBOARD]
must_haves:
  truths:
    - "Lockspire LiveDashboard page is optionally available."
  artifacts:
    - path: "mix.exs"
      provides: "phoenix_live_dashboard optional dependency"
    - path: "lib/lockspire/live_dashboard_page.ex"
      provides: "LiveDashboard PageBuilder implementation"
  key_links:
    - from: "lib/lockspire/live_dashboard_page.ex"
      to: "Phoenix.LiveDashboard.PageBuilder"
      via: "conditional compilation"
---

<objective>
Integrate an optional Lockspire LiveDashboard page for real-time telemetry observation.

Purpose: Allow host apps to mount the Lockspire dashboard page to observe real-time token issuance and protocol events.
Output: Updated `mix.exs` and new `Lockspire.LiveDashboardPage`.
</objective>

<context>
@mix.exs
</context>

<tasks>
<task type="auto">
  <name>Task 1: Add LiveDashboard dependency</name>
  <files>mix.exs</files>
  <action>Add `{:phoenix_live_dashboard, "~> 0.8", optional: true}` to the `deps` list in `mix.exs`. Add it to `extra_applications` if necessary, but since it's optional, simply adding it to `deps` should suffice.</action>
  <verify>
    <automated>mix deps.get</automated>
  </verify>
  <done>Dependency is optionally available.</done>
</task>

<task type="auto">
  <name>Task 2: Implement LiveDashboard Page</name>
  <files>lib/lockspire/live_dashboard_page.ex</files>
  <action>Create `Lockspire.LiveDashboardPage`. Wrap the module definition in `if Code.ensure_loaded?(Phoenix.LiveDashboard.PageBuilder) do ... end`. Implement the `menu_link/2` and `render_page/2` callbacks to display Lockspire metrics (e.g., token issuances, DPoP failures) using the new `[:lockspire, :<entity>, :<action>]` telemetry schema.</action>
  <verify>
    <automated>mix compile</automated>
  </verify>
  <done>Module compiles without errors and conditionally implements the dashboard page.</done>
</task>
</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Dashboard -> Admin User | Exposing telemetry to admins |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-S01-03 | Information Disclosure | LiveDashboard | accept | Dashboard is only mounted by host applications, which control access to it. We accept that admins will see telemetry. |
</threat_model>
