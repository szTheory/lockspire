# Phase 45: Observability & Operator Seams - Strategy

## Goals & Requirements
- **Goal:** Telemetry and operator workflows are consistent and reliable.
- **Requirements:** 
  - **STAB-03:** Ensure telemetry events are consistent, documented, and properly emitted across all domain actions.
  - **STAB-04:** Ensure operator seams (UI, admin panels, generated config) are consistent, fully functional, and well-documented.

## Context & Assumptions Analyzed
1. **Telemetry Centralization:** Lockspire standardizes on a unified emission pipeline via `Lockspire.Observability.emit/4`. Audit logs and standard telemetry use identical payloads, properly redacted.
2. **Metadata Safety:** `Lockspire.Redaction` drops sensitive keys before any emission. 
3. **Operator UI Independence:** Admin LiveViews delegate domain mutations to the `Lockspire.Admin` boundary, which handles database transactions and telemetry emission.
4. **Out-of-the-Box Dashboards:** Telemetry ties natively into `Phoenix.LiveDashboard` via `Lockspire.LiveDashboardPage`.

## User Alignment & Decisions
1. **Telemetry Migration:** Residual raw `:telemetry.execute/3` calls found in `lib/lockspire/admin/tokens.ex` will be migrated to the standardized `Lockspire.Observability.emit` pipeline.
2. **Documentation Strategy:** The existing `docs/operator-admin.md` guide will be expanded to include detailed information about telemetry events and audit logging instead of creating a standalone document.
3. **Mutation Audit:** A comprehensive audit of all `Admin` context modules (`clients.ex`, `consents.ex`, `initial_access_tokens.ex`, `keys.ex`, `server_policy.ex`, `tokens.ex`) will be performed to ensure every mutation (create, update, delete, revoke) emits a standardized observability event.

## Next Steps (Plan Phase)
- Formulate the implementation plan targeting `lib/lockspire/admin/*.ex` modules for the observability audit and migration.
- Plan the documentation updates for `docs/operator-admin.md`.