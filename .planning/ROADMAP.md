# Roadmap

## Phases
- [ ] **Phase 44: API Stabilization & Typespecs** - Finalize and strictly type the public API contract
- [x] **Phase 45: Observability & Operator Seams** - Ensure telemetry and operator workflows are consistent and reliable
- [x] **Phase 46: Documentation & Security Audit** - Complete public documentation and conduct a formal 1.0 readiness audit
- [ ] **Phase 47: 1.0 GA Release Readiness** - Transition package posture from preview to 1.0 GA

## Phase Details

### Phase 44: API Stabilization & Typespecs
**Goal**: The public API contract is finalized and strictly typed.
**Depends on**: None (start of milestone)
**Requirements**: STAB-01
**Success Criteria** (what must be TRUE):
  1. All public modules have complete and accurate Typespecs.
  2. Configuration options are finalized and backwards-incompatible changes are resolved.
  3. Callbacks and host integration seams have a stable, locked signature.
**Plans**: 2 plans
- [ ] 44-01-PLAN.md — Fix Dialyzer errors and create Host Context struct
- [ ] 44-02-PLAN.md — Add complete typespecs to public facades and lock callback signatures

### Phase 45: Observability & Operator Seams
**Goal**: Telemetry and operator workflows are consistent and reliable.
**Depends on**: Phase 44
**Requirements**: STAB-03, STAB-04
**Success Criteria** (what must be TRUE):
  1. All critical domain actions emit standardized telemetry events.
  2. Operator LiveView panels correctly reflect all core data and state.
  3. Configuration and telemetry documentation matches the emitted events and seams.
**Plans**: 3 plans
- [x] 45-01-PLAN.md — Implement missing telemetry emission in Device Authorization
- [ ] 45-02-PLAN.md — Implement Interactions and Logout Deliveries LiveViews
- [ ] 45-03-PLAN.md — Implement Device Authorizations LiveView and telemetry documentation
**UI hint**: yes

### Phase 46: Documentation & Security Audit
**Goal**: The codebase is fully documented and independently audited for 1.0 readiness.
**Depends on**: Phase 45
**Requirements**: STAB-02, STAB-05
**Success Criteria** (what must be TRUE):
  1. All public modules have comprehensive `@moduledoc` and `@doc` coverage.
  2. A formal security and API surface audit is conducted, and any critical findings are addressed.
  3. The project README and guides accurately reflect the 1.0 architecture and capabilities.
**Plans**: 3 plans
- [x] 46-01-PLAN.md — Integrate security auditing tooling
- [x] 46-02-PLAN.md — Finalize public API documentation
- [x] 46-03-PLAN.md — Update 1.0 readiness markdown guides

### Phase 47: 1.0 GA Release Readiness
**Goal**: Lockspire transitions from preview to a stable 1.0 GA release.
**Depends on**: Phase 46
**Requirements**: STAB-06
**Success Criteria** (what must be TRUE):
  1. The `mix.exs` version is prepared for `1.0.0`.
  2. The CHANGELOG reflects the transition to 1.0.
  3. All release assets and documentation correctly present the 1.0 GA posture.
**Plans**: 1 plan
- [ ] 47-01-PLAN.md — Disable preview bumping, update version to 1.0.0, and upgrade documentation to GA posture

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 44. API Stabilization & Typespecs | 0/2 | Not started | - |
| 45. Observability & Operator Seams | 3/3 | Completed | 2026-05-04 |
| 46. Documentation & Security Audit | 3/3 | Completed | 2026-05-04 |
| 47. 1.0 GA Release Readiness | 1/1 | Completed | 2026-05-05 |
