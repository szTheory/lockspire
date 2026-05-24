# Lockspire Roadmap

## Active Milestone

### v1.23 DCR Logout Metadata

**Goal:** Let self-service clients manage Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening beyond the current logout truth model.

**Requirements covered:** `DCR-01` through `DCR-05`, `DCRM-01` through `DCRM-03`, `PROOF-01`, `PROOF-02`

#### Phase 85 - DCR Intake And Representation

- Status: Complete on 2026-05-24

- Scope:
  - extend the DCR validation contract to support the four logout propagation metadata fields
  - persist the accepted metadata through the existing registration pipeline
  - expose the stored values truthfully in DCR JSON responses
- Covers:
  - `DCR-01`
  - `DCR-02`
  - `DCR-03`
  - `DCR-04`
  - `DCR-05`
  - `DCRM-01`

#### Phase 86 - RFC 7592 Update Semantics And Proof

- Status: Complete on 2026-05-24

- Scope:
  - support full-replace RFC 7592 updates for the logout propagation fields
  - preserve RAT rotation, provenance, and audit behavior
  - add protocol/controller/integration coverage for positive and negative lifecycle cases
- Covers:
  - `DCRM-02`
  - `DCRM-03`
  - `PROOF-01`

#### Phase 87 - Support Truth And Milestone Closure

- Scope:
  - update supported-surface, DCR, and operator docs
  - verify the final support contract matches shipped behavior and tests
  - prepare milestone-close proof and release-truth updates
- Covers:
  - `PROOF-02`

## Shipped Milestones

- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.
