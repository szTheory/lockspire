---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 03
subsystem: admin-and-storage
tags:
  - fapi
  - readiness
  - policies
  - administration
requires:
  - 42-01
provides:
  - Durable readiness contracts for FAPI enablement
  - Rejecting incompatible client metadata prior to save
affects:
  - Global server policy strict mode toggle
  - Admin UI for updating clients
  - Durable validation in repository bounds
key-files:
  modified:
    - lib/lockspire/admin/server_policy.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/storage/ecto/repository.ex
metrics:
  duration: 10m
  completed_date: 2026-05-02
---

# Phase 42 Plan 03: Admin and Storage Readiness Rejection Summary

Implemented fail-fast validation in global policy and admin client paths, ensuring strict FAPI mode cannot be enabled without compliant durable signing key posture and valid metadata.

## Execution Outcomes

- **Global Policy Safety:** The global server policy toggle for FAPI now queries `Repository.check_fapi_signing_readiness()`, ensuring both active and publishable keys exist before allowing `:fapi_2_0_security`.
- **Client Metadata Boundaries:** Extended the `ClientRecord` update changeset to enforce algorithm compatibility (e.g., preventing `id_token_signed_response_alg` mismatch) when a client attempts to use `:fapi_2_0_security`.
- **Durable Contracts:** Downstream HTTP registration surfaces can now reuse these durable readiness queries instead of inventing redundant heuristics.
- **Backwards Compatibility:** Legacy clients opting for `:none` profile continue saving without FAPI constraints.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. All validation logic relies on real repository paths and verified durable state.

## Threat Flags

None. No new network endpoints or unmitigated security boundaries were opened.
