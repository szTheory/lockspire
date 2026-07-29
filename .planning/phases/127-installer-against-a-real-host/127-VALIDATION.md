---
phase: 127
slug: installer-against-a-real-host
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 127 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

> **Framing note (the tautology this phase exists to kill):** the current integration proof passes
> for the wrong reason. `install_generator_test.exs` empties a directory and runs the installer
> inside Lockspire's own Mix project, so `File.cd!` leaves module resolution pointed at Lockspire
> and the assertions confirm themselves. Every gate below must assert against a **real generated
> Phoenix host**, not against a placeholder. A test that would still pass with the host absent is
> not evidence for this phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5, Erlang/OTP 28) |
| **Config file** | `test/test_helper.exs` — excludes `integration: true` unless a `.exs` path is named, argv contains `"integration"`, or `--include integration` is passed |
| **Quick run command** | `mix test test/integration/install_generator_test.exs test/integration/install_template_compile_test.exs` |
| **Full suite command** | `mix test.fast` then `mix test.integration` (`mix.exs:76-77`) |
| **Estimated runtime** | ~10 seconds (quick) / existing `mix ci` runtime (full) |

Lanes: `test.fast` = everything untagged; `test.integration` = `mix test --only integration`.
Naming a `.exs` path on the command line keeps `:integration`-tagged modules in that file runnable
without `--include`.

---

## Sampling Rate

- **After every task commit:** `mix test test/integration/install_generator_test.exs test/integration/install_template_compile_test.exs`; additionally `mix test test/lockspire/maintainer/` for **any** ledger or `scripts/maintainer/` edit (the reconciliation contract fails in both directions).
- **After every plan wave:** `mix test.fast` + `mix test.integration`
- **Before `/gsd-verify-work`:** `mix ci` green (includes `qa`, `docs.verify`, `deps.audit`, `package.build`, `test.fast`, `test.integration`, `test.phase3`)
- **Max feedback latency:** 30 seconds (quick lane)

---

## Per-Task Verification Map

> Seeded from RESEARCH.md `## Validation Architecture`. Task IDs are filled in by the planner /
> executor; the requirement→behavior→command rows below are the binding contract.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | INSTALL-01 | — | Installer runs into a real generated Phoenix host, not an emptied directory | integration | `mix test test/integration/install_host_interaction_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-02 | — | app / web / router / **repo** modules all resolve from the host via `Mix.Project.in_project/4`, no flags | integration | `mix test test/integration/install_host_interaction_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-02 | — | Negative control: no `Lockspire.Repo` / `lib/lockspire/` leakage into host output | integration | `mix test test/integration/install_host_interaction_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-02 | — | Manifest `"version"` records Lockspire's version, not the host app's (Pitfall 1) | unit | `mix test test/integration/install_generator_test.exs` (rewrite `:46`) | ✅ exists, assertion wrong | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | T-127-01 | Conflicting re-run reports **all** conflicts, not just the first | unit | `mix test test/integration/install_generator_test.exs` (extend `:323-361`) | ✅ partial | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | T-127-01 | Conflicting re-run writes **zero bytes** — tree checksum before == after (no half-installed state) | unit | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | — | `--dry-run` on a clean host prints the plan and writes nothing | unit | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | — | `--dry-run` on a conflicted host exits non-zero (mirrors `lockspire.upgrade`) | unit | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | — | Manifest-inputs drift refused (D-18) | unit | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | — | Manifest content drift refused, not silently overwritten (D-19) | unit | `mix test test/integration/install_generator_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-03 | — | Idempotent clean re-run still prints `* unchanged` ×12 | unit | `mix test test/integration/install_generator_test.exs:303-321` | ✅ exists | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D01-D03 | — | Router macro injects a real route table; admin forward ordered before public forward; `:require_operator` needs no host definition | unit | `mix test test/integration/install_template_compile_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D16 | — | Every generated `.heex` compiles under `Phoenix.LiveView.TagEngine` | unit | `mix test test/integration/install_template_compile_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D04 | T-127-02 | Config template emits mount-path-consistent issuer, `known_scopes`, `signing_alg`, `secret_key_base` **placeholder** — no secret literal | unit | `mix test test/integration/install_generator_test.exs` (extend `:38-71`) | ✅ exists | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D08 | — | `mix lockspire.client.create` reaches a running repo | integration | `mix test --only integration` (needs Postgres) | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D09 | — | Resolver template emits `/users/log-in` | unit | `mix test test/integration/install_generator_test.exs` (extend `:97-113`) | ✅ exists | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D15 | — | Suite green with `ecto`/`ecto_sql` 3.14 resolved and `mix.lock` committed | integration | `mix deps.update ecto ecto_sql && mix ci` | ✅ lane exists | ⬜ pending |
| TBD | TBD | TBD | INSTALL-01 / D07 | — | Remediation strings name `--migrations-path` at all **three** sites (`verify.ex:241`, `verify.ex:270`, `install.ex:140`) | unit | grep-shaped assertion or `verify.ex` unit test | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | Criterion 4 | — | Ledger reconciles with harness markers after every edit (both directions) | unit | `mix test test/lockspire/maintainer/defect_ledger_contract_test.exs` | ✅ exists | ⬜ pending |
| TBD | TBD | TBD | Drift fence | — | Runtime fixture matches the regenerated template | unit | `mix test test/integration/install_generator_test.exs:209-210` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `priv/test_fixtures/phx_new_host/` (or chosen location) — the committed `phx.new` snapshot + provenance README. Must sit **outside** `lib/`, `test/`, `config/`, and `priv/templates/`: `.formatter.exs` inputs cover `{config,lib,test}/**`, `.credo.exs` includes `["lib/", "test/"]`, and `package_files/0` would ship a snapshot under `lib/` or `priv/templates/`. Covers INSTALL-01.
- [ ] `test/integration/install_host_interaction_test.exs` — `@moduletag :integration`, drives `Mix.Project.in_project/4`. Covers INSTALL-01, INSTALL-02.
- [ ] `test/integration/install_template_compile_test.exs` — router macro expansion + HEEx `TagEngine` compile fences. Covers D01/D02/D03/D16.
- [ ] Shared helper for snapshot→scratch copy + cleanup (a `test/support/` module is fine — it is *code*, not the snapshot).
- [ ] Tree-checksum helper for the "zero bytes written" assertion.
- [ ] No framework install needed — ExUnit and PostgreSQL 14.17 are both present locally.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Six `LOCKSPIRE_WALK_WORKAROUND` markers (D02, D03, D08, D09, D15, D16) are genuinely removable | Criterion 4 | Removing a marker changes what the walk actually executes; only a real walk proves the fix stands without it. Automating the walk is Phase 130's concern. | Run `mix adopter.walk` once after the marker removals; confirm the previously-worked-around steps now PASS on their own and reconcile the ledger `Workaround:` fields in the same commit. |
| ADOPT-D04's marker cannot be fully removed | Criterion 4 | Its `sed` block is guarded by `if ! grep -Fq 'known_scopes'` — emitting `known_scopes` from the template silently skips the issuer substitution the walk still needs. | Inspect `scripts/maintainer/adopter_path_walk.sh` after the config-template fix; record the residual marker as an explicit deferral with a stated reason in the ledger. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
