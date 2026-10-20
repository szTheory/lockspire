---
phase: "161"
slug: "docs-verified-1-6-0-release"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-28; `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5`) |
| **Config file** | `mix.exs` aliases; `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs test/lockspire/documentation_contract_test.exs test/lockspire/web/live/admin/vocabulary_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | quick ~5s; full several minutes |

---

## Sampling Rate

- **After every task commit:** quick run command, plus `mix docs.verify` after any docs edit
- **After every plan wave:** SAFE-02 targeted test list (see RESEARCH.md), `bash scripts/maintainer/repo_hygiene_check.sh --ci`, `mix format --check-formatted`
- **Before `/gsd-verify-work`:** v1.44 PR CI fully green; release verification outputs recorded in `161-RELEASE-EVIDENCE.md`
- **Max feedback latency:** ~60 seconds locally

---

## Per-Requirement Verification Map

| Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|-----------------|-----------|-------------------|-------------|--------|
| DOC-02 | Operator guide lists 7 Key protection labels, read-only, Unknown not healthy, gen.kek, upgrade link | contract | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs` | ❌ W0 (extend) | ⬜ pending |
| DOC-02 | Install/upgrade guides name gen.kek and `{:system, ...}` | contract | `MIX_ENV=test mix test test/lockspire/kek_guidance_contract_test.exs test/lockspire/upgrade_guide_contract_test.exs` | ✅ | ⬜ pending |
| DOC-02 | ExDoc builds without warnings | build | `MIX_ENV=test mix test test/lockspire/documentation_contract_test.exs && mix docs.verify` | ✅ | ⬜ pending |
| REL-01 | Hygiene accepts metadata >= public with consistent public/artifact/tag/SHA; rejects malformed | script + contract | `bash scripts/maintainer/repo_hygiene_check.sh --ci && MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs test/lockspire/release/release_automation_contract_test.exs` | ❌ W0 (edit) | ⬜ pending |
| REL-01 | Simulated post-#121 tree passes hygiene | scripted | scratch `git archive` copy + 1.6.0 edits + hygiene `--ci` | ❌ W0 | ⬜ pending |
| REL-01 | Regenerated #121 proposes 1.6.0 covering v1.40–v1.44 | manual-read | `gh pr view 121 --json title,body` | n/a | ⬜ pending |
| REL-02 | Hex checksum == tarball sha == manifest; tag/release == SHA; HexDocs 200; 3 new tasks in tarball | script | independent verification script (RESEARCH.md) | ❌ | ⬜ pending |
| REL-02 | Fresh HEX_HOME install `== 1.6.0` | script | clean-room snippet (RESEARCH.md) | ❌ | ⬜ pending |
| SAFE-02 | No mix.exs/mix.lock/migrations/protocol/config change in v1.44 diff | diff | `git diff --stat 038df080..<SQUASH> -- mix.exs mix.lock priv/repo/migrations lib/lockspire/protocol config` (empty) | n/a | ⬜ pending |
| SAFE-02 | No key/KEK in logs/telemetry/admin/errors | tests + grep | 8-file targeted test list + grep sweep (RESEARCH.md) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Gate repair in `scripts/maintainer/repo_hygiene_check.sh`; version/SHA-agnostic `test/support/lockspire/release_proof/workflow_assertions.ex` and `package_assertions.ex` (D-16)
- [ ] New operator-guide test in `test/lockspire/kek_guidance_contract_test.exs`
- [ ] Public verification commands (script or inline in evidence plan)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push v1.44 branch, squash-merge PR | REL-01 | Maintainer approval | Checkpoint before push/merge |
| Edit #122 body with commit override | REL-01 | GitHub write | Checkpoint; confirm #121 regenerates |
| Squash-merge #121 | REL-01 | Maintainer approval | Re-read title/body first |
| Set/clear authorized SHA, dispatch release, approve `hex-publish` | REL-02 | Protected release lane | Checkpoint each step |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
