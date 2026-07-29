---
phase: 126
slug: adopter-path-walk-defect-ledger
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 126 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

> **Framing note (GREEN/RED inversion):** this phase's deliverable *is* a validator. The risk it
> introduces is not "untested code" but "a harness that reports GREEN for the wrong reason" — a walk
> that passes because it skipped a step, or that FAILs on its own bug and gets attributed to
> Lockspire. Every gate below asserts on the **harness's properties**, never on the walk's exit code.
> `mix adopter.walk` is expected to exit non-zero in this phase, and that is a passing phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (repo-native) + `bash -n` / `python3 -m py_compile` static checks |
| **Config file** | `test/test_helper.exs`; lanes in `mix.exs:71-125` |
| **Quick run command** | `bash -n scripts/maintainer/adopter_path_walk.sh && python3 -m py_compile scripts/maintainer/adopter_path_flow.py` |
| **Full suite command** | `mix ci` (must stay green — the phase adds one alias to `mix.exs`) |
| **Estimated runtime** | ~2 seconds (quick) / existing `mix ci` runtime (full) |

The walk itself is deliberately **not** in `mix ci` (D-01). Its "full suite" is a manual
`mix adopter.walk` run whose evidence is the committed ledger plus the preserved
`tmp/adopter-walk/` tree.

---

## Sampling Rate

- **After every task commit:** `bash -n` + `python3 -m py_compile` + the focused contract test file
- **After every plan wave:** `mix test.fast` (the new contract tests live in the normal suite)
- **Before `/gsd-verify-work`:** `mix ci` green **and** one full `mix adopter.walk` run whose report
  is captured in the ledger
- **Max feedback latency:** 30 seconds (quick lane)

---

## Per-Task Verification Map

> Seeded from RESEARCH.md `## Validation Architecture`. Task IDs are filled in by the planner /
> executor; the requirement→behavior→command rows below are the binding contract.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | ADOPT-01 | — | `mix adopter.walk` alias exists and delegates to the script | contract | `mix run -e 'true = Keyword.has_key?(Mix.Project.config()[:aliases], :"adopter.walk")'` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-01 | — | Script is syntactically valid and has a single verdict/exit path | static | `bash -n scripts/maintainer/adopter_path_walk.sh` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-01 | — | Driver is syntactically valid, stdlib-only | static | `python3 -m py_compile scripts/maintainer/adopter_path_flow.py` + grep for non-stdlib imports | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-02 | — | The walk never passes a stripping flag to `phx.new` | contract | `! grep -E '\-\-no-(ecto\|html\|assets\|mailer)' scripts/maintainer/adopter_path_walk.sh` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-02 | — | The walk pins `phx_new` and isolates `MIX_ARCHIVES` | contract | `grep -Fq 'MIX_ARCHIVES' && grep -Fq 'phx_new 1.8.9'` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-03 | — | Every step ID maps to a `docs/install-and-onboard.md` section number | contract | ExUnit test parsing `step-NN` IDs from the script against the guide's `## N.` headings | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-03 | — | The harness does not use the evidence-destroying teardown | contract | `! grep -E "trap .*rm -rf" scripts/maintainer/adopter_path_walk.sh` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-03 | — | Resume markers and `--from-step` exist | contract | `grep -Fq '.walk/steps' && grep -Fq -- '--from-step'` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ADOPT-04 | — | The driver asserts a token *use*, not just presence | contract | grep the driver for a `/userinfo` bearer assertion, a host-route bearer assertion, and an anonymous-401 assertion | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | Criterion 5 | — | Every `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker has a matching ledger row and vice versa | contract | ExUnit set-equality check between markers in `scripts/maintainer/*` and IDs in `126-DEFECT-LEDGER.md` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | Criterion 4 | — | The ledger is non-empty and every entry has all six D-37 fields | contract | ExUnit test parsing the ledger | ❌ W0 | ⬜ pending |
| n/a | n/a | n/a | ADOPT-01..04 | — | End-to-end walk produces a report | manual | `mix adopter.walk` (expected RED — see framing note) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/lockspire/maintainer/adopter_walk_contract_test.exs` — ADOPT-01..04 static/contract
      assertions over the script and driver source
- [ ] `test/lockspire/maintainer/defect_ledger_contract_test.exs` — criterion 4 (non-empty, all
      six D-37 fields) and criterion 5 (marker↔ledger set equality)
- [ ] No framework install needed — ExUnit is already the repo's suite

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end adopter path walk | ADOPT-01..04 | Generates a Phoenix app, compiles a C NIF, downloads asset binaries, and boots a server — cannot run in <30s and must not enter `mix ci` in this phase (D-01) | Run `mix adopter.walk`; expect a non-zero exit with an attributed step failure. Capture the report into `126-DEFECT-LEDGER.md` and preserve `tmp/adopter-walk/`. |

---

## Prohibited Gates

These must **not** be written as validation gates — each would fail the phase for the right reason:

- ❌ `mix adopter.walk` exits 0
- ❌ any assertion that the walk reached the final step on the first run
- ❌ any assertion that the defect ledger is empty

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] No gate asserts on the walk's exit code (GREEN/RED inversion respected)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
