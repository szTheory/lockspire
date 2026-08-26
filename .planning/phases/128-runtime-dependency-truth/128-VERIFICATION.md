---
phase: 128-runtime-dependency-truth
verified: 2026-08-26T16:40:30Z
status: passed
score: "4/4 must-haves verified"
behavior_unverified: 0
---

# Phase 128 Verification: Runtime Dependency Truth

**Verdict:** `passed` — ordinary host repos and Lockspire storage adapters have
clear executable boundaries, including CIBA Push issuance and admin reads. This
report records the existing v1.36 evidence; no commands were rerun.

## Roadmap Success Criteria and Requirement Coverage

| Success criterion | Requirements | Status | Existing evidence |
| --- | --- | --- | --- |
| Protocol fallback paths work with an ordinary host Ecto Repo, including CIBA Push JWT/ID issuance. | RUNTIME-01, RUNTIME-02 | VERIFIED | Plans 128-01 through 128-03 moved default storage behavior to `Lockspire.Storage.Ecto.Repository` while preserving explicit overrides. Plan 128-01 removed TestRepo storage delegates and recorded focused CIBA Push JWT/ID-token proof. The milestone matrix confirms module-wide adapter defaults and ordinary-Repo CIBA Push behavior. |
| Narrow ports own client, logout, IAT, transaction, and audit operations. | ARCH-02 | VERIFIED | Plans 128-04 and 128-05 established explicit ClientStore, InitialAccessTokenStore, TransactionStore, AuditStore, and LogoutStore operations, retaining atomic DCR/RAT/logout behavior and named Oban insertion. The milestone matrix confirms the relevant public port operations. |
| DCR and admin modules do not reach through boundaries with direct schema queries. | ARCH-03 | VERIFIED | Plan 128-04 moved DCR/IAT persistence behind ports; Plan 128-06 routed operator queue reads through narrow Admin services and recorded focused LiveView/design proof. The milestone matrix confirms relevant LiveViews and DCR avoid Ecto adapter reach-through. |
| AST/runtime fitness tests fail on future boundary violations. | ARCH-01 | VERIFIED | Plan 128-06 added `architecture_fitness_test.exs` for protocol, admin, and TestRepo boundaries. The milestone matrix confirms its scan rejects `Config.repo!/0`, Ecto record/query imports in protocol surfaces, and boundary violations. |

## Historical Verification Evidence

- Plan 128-01 recorded passing CIBA delivery, sender-constraint, and signer tests.
- Plans 128-02 through 128-05 recorded passing focused protocol, registration,
  IAT, logout, audit, E2E, and worker suites.
- Plan 128-06 recorded passing focused architecture/DCR/CIBA/logout/admin tests,
  `mix qa` with no Credo findings, and a clean Sobelow scan.
- The milestone review independently recorded RUNTIME-01, RUNTIME-02, ARCH-01,
  ARCH-02, and ARCH-03 as verified.

## Caveat

Plan 128-06 corrected an internal logout-service delegate name discovered by
the focused proof. The public delegate remained unchanged; the corrected
service callback and its verification are part of the recorded evidence.
