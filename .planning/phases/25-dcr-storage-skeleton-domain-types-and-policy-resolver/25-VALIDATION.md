---
phase: 25
slug: dcr-storage-skeleton-domain-types-and-policy-resolver
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-26
updated: 2026-04-28T14:30:00Z
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs`, `mix.exs` (aliases) |
| **Quick run command** | `mix test.fast` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | ~30s quick / ~2-3 min full |

---

## Sampling Rate

- **After every task commit:** Run `mix test.fast`
- **After every plan wave:** Run `mix qa`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Filled in by gsd-planner after PLAN.md files are written. One row per task, mapping each task to its requirement (DCR-06..DCR-10), threat (T-25-XX from each plan's `<threat_model>`), and concrete `mix test path/to/file_test.exs:LINE` command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-02-01 | 02 | 1 | DCR-06 | T-25-01 | DCR policy columns and defaults migrate cleanly onto the singleton policy row | migration | `MIX_ENV=test mix ecto.migrate` | ✅ | ✅ green |
| 25-04-01 | 04 | 1 | DCR-06 / DCR-10 | T-25-02 | Domain structs model DCR server policy, client provenance, and initial access tokens without leaking plaintext secrets | unit | `MIX_ENV=test mix test test/lockspire/domain/initial_access_token_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/storage/ecto/initial_access_token_record_test.exs` | ✅ | ✅ green |
| 25-06-01 | 06 | 2 | DCR-07 | T-25-03 | Admin server-policy commands preserve PAR and DCR state without lost updates | integration | `MIX_ENV=test mix test test/lockspire/admin/server_policy_test.exs` | ✅ | ✅ green |
| 25-07-01 | 07 | 2 | DCR-07 / DCR-08 | T-25-04 | `DcrPolicy.resolve/3` intersects inbound metadata, rejects malformed redirect URIs, and never widens allowlists | unit | `MIX_ENV=test mix test test/lockspire/protocol/dcr_policy_test.exs` | ✅ | ✅ green |
| 25-08-01 | 08 | 2 | DCR-09 | T-25-05 | Discovery-binding invariant stays aligned with the resolver’s accepted token endpoint auth methods | unit | `MIX_ENV=test mix test test/lockspire/protocol/dcr_policy_invariant_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

> Test files / fixtures that must exist before any feature task can be marked verified. Filled in by gsd-planner from the RESEARCH.md Wave 0 inventory:
>
> - `test/lockspire/protocol/dcr_policy_test.exs` — covers DCR-08 intersection semantics
> - `test/lockspire/protocol/dcr_policy_invariant_test.exs` — covers DCR-08/discovery binding
> - `test/lockspire/domain/initial_access_token_test.exs` — covers DCR-09 struct shape
> - `test/lockspire/admin/server_policy_test.exs` extension — covers DCR-07 Admin surface
> - `test/support/fixtures/initial_access_token_fixtures.ex` — IAT factory
> - Migration up/down round-trip test (Repository smoke) — covers DCR-06, DCR-09, DCR-10 schema

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none expected) | — | — | — |

*All phase behaviors have automated verification — Phase 25 is greenfield additive code with no UI, no external services, and deterministic intersection semantics.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags (`mix test.watch` etc.)
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
