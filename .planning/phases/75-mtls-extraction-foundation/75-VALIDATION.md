---
phase: 75
slug: mtls-extraction-foundation
status: planned
nyquist_compliant: true
wave_0_complete: false
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs`, `mix.exs` (aliases) |
| **Quick run command** | `mix test test/lockspire/mtls` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30s quick / ~2-3 min full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/mtls`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Filled in by gsd-planner after PLAN.md files are written. One row per task, mapping each task to its requirement, threat (T-75-XX from each plan's `<threat_model>`), and concrete test command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-01-00 | 01 | 1 | MTLS-EXT-01 | — | Extractor behaviour requires extract/2 callback returning DER binary | unit | `mix format lib/lockspire/mtls/extractor.ex` | ❌ | ⬜ pending |
| 75-01-01 | 01 | 1 | MTLS-EXT-02 | — | Cowboy direct extraction extracts DER natively without decoding | unit | `mix test test/lockspire/mtls/cowboy_direct_extractor_test.exs` | ❌ | ⬜ pending |
| 75-01-02 | 01 | 1 | MTLS-EXT-03 | T-75-01, T-75-02 | Proxy header extraction returns DER cert from url-encoded PEM & supports Envoy XFCC | unit | `mix test test/lockspire/mtls/proxy_header_extractor_test.exs` | ❌ | ⬜ pending |
| 75-02-01 | 02 | 2 | MTLS-EXT-04 | T-75-03 | Plug halts pipeline with HTTP 400 when cert is invalid or missing, and assigns cert on success | unit | `mix test test/lockspire/mtls/plug_test.exs` | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

> Test files / fixtures that must exist before any feature task can be marked verified. Filled in by gsd-planner from the RESEARCH.md Wave 0 inventory:
>
> - `test/lockspire/mtls/plug_test.exs` — covers MTLS-EXT-04
> - `test/lockspire/mtls/cowboy_direct_extractor_test.exs` — covers MTLS-EXT-02
> - `test/lockspire/mtls/proxy_header_extractor_test.exs` — covers MTLS-EXT-03
> - Valid PEM and DER fixtures in tests for assertions.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none expected) | — | — | — |

*All phase behaviors have automated verification — Phase 75 is greenfield additive code focusing on HTTP headers and connection parsing.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags (`mix test.watch` etc.)
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
