# Deferred Items

## 2026-06-30 - Plan 124-06 broad-suite caveats

`MIX_ENV=test mix test.fast --max-failures 5` failed after the focused Phase 124 Configure gate passed. These failures are outside Plan 124-06's allowed edit set and were not fixed in this plan.

| Test | File | Note |
| ---- | ---- | ---- |
| `phase 115 adoption demo docs stay repo-local without production Docker claims` | `test/lockspire/release_readiness_contract_test.exs:726` | Existing Phase 115 adoption-demo documentation/source contract drift. |
| `phase 115 CI and docs keep deterministic Docker validation only` | `test/lockspire/release_readiness_contract_test.exs:687` | Existing Phase 115 adoption-demo documentation/source contract drift. |
| `phase 115 local hygiene classifies Docker state with calm exact remediation` | `test/lockspire/release_readiness_contract_test.exs:640` | Existing Phase 115 repo-hygiene source contract drift. |
| `phase 115 CI source contracts prove lifecycle allowlists and public surface boundaries` | `test/lockspire/release_readiness_contract_test.exs:741` | Existing Phase 115 repo-hygiene source contract drift. |
| `security and DCR landing pages orient related workflows` | `test/lockspire/web/live/admin/overview_live_test.exs:157` | Overview page orientation expectation outside Plan 124-06's design-system test scope. |
