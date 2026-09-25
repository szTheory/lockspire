# Project Research Summary

**Project:** Lockspire v1.38 Repository Baseline & Reconciliation
**Domain:** Maintenance-baseline reconciliation for an embedded Phoenix/Elixir OAuth/OIDC library
**Researched:** 2026-08-28
**Confidence:** HIGH

## Executive Summary

Lockspire v1.38 is a bounded maintenance milestone for a mature embedded OAuth/OIDC library, not a product, protocol, or platform expansion. The repository already has the right enforcement surfaces: Mix quality aliases, a repository-owned hygiene script, SHA-pinned GitHub Actions, a protected exact-SHA release path, GitHub-native triage, and GSD planning artifacts. The desired outcome is a reproducible evidence chain showing whether every relevant item is clean, current, deliberately deferred, or a concrete correction—not an empty GitHub queue or a cosmetically quiet worktree.

The recommended approach is evidence first, disposition second: inventory local Git/worktrees, remote PRs/issues, workflow runs, release records, and planning truth before mutating anything. Bind every health or release statement to an exact source SHA and corresponding required workflow run; use `mix ci` and `repo_hygiene_check.sh --ci` as the repository-owned proof. Retain Release Please and the protected exact-ref publisher, preserve full-SHA action pins, and keep OIDF receipts redacted, supplemental, and explicitly non-certifying.

The greatest risks are false readiness claims from a green run at the wrong SHA, destructive cleanup without owner/disposition evidence, and release or planning prose drifting from executable contracts. Mitigate them with a dated evidence matrix, one terminal classification per loose end, smallest-authoritative-layer corrections, focused proof followed by full gates, and explicit deferral where the evidence does not authorize a change.

## Key Findings

### Recommended Stack

Do not add tooling in v1.38. Existing repository controls are both sufficient and intentionally integrated; another CI system, bot, scanner, test runner, dashboard, or dependency-refresh campaign would duplicate policy and expand risk. The normal contributor proof is `mix ci`, followed by the existing hygiene check; narrow aliases are diagnostic tools, not replacements for the full closeout gate.

**Core technologies:**

- **Elixir/Mix (CI 1.19.5; supported floor 1.18.4) and OTP (28; floor 27):** preserve the existing compatibility lanes and `mix ci` contributor contract.
- **GitHub Actions with full-SHA-pinned actions:** retain required CI, release, dependency review, and supplemental conformance boundaries without introducing a second hosted system.
- **Git and Git worktrees:** inventory and classify exact local state; never use baseline work to justify broad deletion.
- **GitHub CLI:** use read-only, complete PR/issue/run inventories for maintainer decisions; do not automate closure or merging.
- **Credo, Dialyxir, Sobelow, MixAudit, ExDoc, actionlint/ShellCheck:** retain existing QA, audit, docs, and workflow contracts.
- **Release Please plus protected exact-SHA release workflow:** retain bookkeeping/publisher separation; never manually bump, tag, or publish to repair apparent drift.

### Expected Features

For this maintenance milestone, the table stakes are operational evidence rather than user-facing functionality.

**Must have (table stakes):**

- Clean, synchronized `main` proof plus intentional ref, tag, branch, and worktree inventory.
- Complete open PR/issue disposition and current-SHA required CI/release evidence.
- Local proof from `mix ci` and the repository hygiene contract after applicable corrections.
- Reconciled planning/release truth and an evidence-backed loose-end disposition record.
- Supplemental OIDF findings preserved with redacted, non-certifying wording.

**Should have (only when evidence supports it):**

- One dated baseline report mapping checks, SHA, evidence source, and disposition.
- A deterministic drift fence or narrow hygiene-script improvement only if reconciliation proves a repeatable, repository-owned gap.
- A safe-defer record with evidence, scope boundary, owner/revisit trigger, and no false completion claim.

**Defer (separate milestone):**

- Protocol, host-seam, admin, or CI-platform expansion; broad dependency refreshes; merge-process redesign; and OIDF/FAPI conformance hardening.

### Architecture Approach

v1.38 should use a maintenance evidence flow, not create runtime structure: read-only inventory feeds an evidence matrix; each item receives one classification and disposition; only approved narrow corrections enter required repository proof; standard GSD verification then records closure. Authority is ordered as reproducible live repository/GitHub evidence, required repository-owned gate output, current checked-in contracts/runbooks, and archived milestone records. Prose can explain proof but cannot substitute for it.

**Major components:**

1. **Local and GitHub inventory** — captures exact Git/worktree state, open work, runs, and source SHA without mutation.
2. **Classification/disposition matrix** — records source, observed fact, category, owner/authority, action or no-action, and terminal proof.
3. **Repository quality contract** — `mix ci`, hygiene CI mode, and targeted existing checks establish source and lifecycle evidence.
4. **Protected release authority** — Release Please owns release intent; exact-ref workflow owns publishing and artifact provenance.
5. **GSD planning truth** — phase verification, requirements, roadmap, and state carry current milestone evidence without rewriting history.
6. **Supplemental OIDF lane** — preserves immutable/redacted comparison findings outside required baseline acceptance.

### Critical Pitfalls

1. **Using a green run for another SHA** — require `HEAD`, `origin/main`, run ID, trigger, conclusion, and `head_sha` to agree before any readiness claim.
2. **Destructive cleanup without authority** — inventory first; close, defer, or retain unless exact ownership, target, and passing policy justify a bounded action.
3. **Drift between prose, executable gates, and release records** — treat scripts/workflows as authority, correct the smallest proven layer, and preserve historical evidence.
4. **Treating OIDF output as a required gate or certification** — retain redacted receipts and route only independently reproduced regressions to future bounded work.
5. **Breaking the protected release chain** — preserve action pins, exact-SHA CI binding, detached/package proof, manifest/checksum linkage, and Release Please ownership.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Baseline Inventory and Evidence Taxonomy

**Rationale:** All later claims depend on an exact, read-only view of the local/remote state. The local branch being ahead of `origin/main` makes prior green CI insufficient by itself.

**Delivers:** A dated evidence matrix covering Git state, worktrees/refs/tags, PRs/issues, required and supplemental workflow runs, release records, planning records, and current gate outputs.

**Addresses:** Synchronized-main proof, intentional Git inventory, and complete operational work inventory.

**Avoids:** Wrong-SHA readiness claims and irreversible cleanup without ownership or terminal evidence.

### Phase 2: Required Truth Reconciliation

**Rationale:** Reconcile the acceptance spine before triaging peripheral artifacts; executable contracts must agree with current planning and release statements.

**Delivers:** Only evidence-backed corrections to required workflows, runbooks, planning/release truth, or repository contracts, with focused proof and the full existing gates where applicable.

**Uses:** `mix ci`, `repo_hygiene_check.sh --ci`, existing QA/audit/docs aliases, CI workflow linting, and the protected release-chain contract.

**Implements:** Executable-contract authority, exact-SHA evidence binding, and explicit supplemental/non-certifying OIDF classification.

**Avoids:** Prose/gate drift, OIDF shadow gating, manual release repair, and weakened action/release provenance.

### Phase 3: Bounded Operational Loose-End Triage

**Rationale:** PRs, Dependabot updates, draft work, branches, worktrees, TODOs, and historical artifacts can be safely decided only after their evidence and governing rules are known.

**Delivers:** An evidence-backed disposition for every candidate—fix now, defer, retain historical evidence, close, or merge only when separately authorized and fully proven.

**Addresses:** PR/issue disposition and loose-end closure; any dependency update remains an independent compatibility and gate decision.

**Avoids:** Bulk closure/deletion, speculative refactoring, a baseline-wide dependency campaign, and loss of recovery/provenance evidence.

### Phase 4: Maintenance-Baseline Closure

**Rationale:** Closure is a claim about the final post-triage repository, so it must follow all corrections and dispositions.

**Delivers:** Reconciled requirements/roadmap/state and standard phase verification that point to final matrix rows, gate results, exact SHAs/runs, explicit deferrals, and OIDF’s supplemental status.

**Addresses:** Durable handoff, coherent release/milestone truth, and honest supplemental-conformance retention.

**Avoids:** “Looks done” documentation, historical rewrites, artifact-only claims, and certification overstatement.

### Phase Ordering Rationale

- Inventory precedes all edits so stale history and local/remote SHA divergence cannot create false work or false success.
- Required truth reconciliation precedes operational triage, establishing the authoritative rules against which each loose end is judged.
- Triage is deliberately separate from release/protocol changes: GitHub-state disposition is not permission for destructive or product-affecting action.
- Closure comes last because planning records must describe verified final state, not forecast it.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 1:** Fresh GitHub inventory and branch-protection/run data are time-sensitive; validate live facts and exact SHAs at execution time.
- **Phase 2:** Research only if a concrete CI/release/OIDF contract defect is discovered; changes to release authority or workflow triggers require focused primary-source validation.
- **Phase 3:** Research each proposed dependency update or remote disposition individually; no aggregate upgrade or cleanup authorization follows from the inventory.

Phases with standard patterns (skip research-phase unless evidence changes):

- **Phase 4:** Standard GSD reconciliation and existing repository gates; it needs fresh verification evidence, not design research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Versions and existing contracts are repository-verified; remote state and operational guidance are time-sensitive. |
| Features | HIGH | Scope and acceptance needs are directly derived from repository planning and maintenance boundary. |
| Architecture | HIGH | The recommended flow maps to existing scripts, workflows, release controls, and GSD artifacts. |
| Pitfalls | HIGH | Core risks are demonstrated by repository state and reinforced by official GitHub operational guidance. |

**Overall confidence:** HIGH

### Gaps to Address

- **Live state freshness:** Re-fetch and re-inventory branches, PRs/issues, workflow runs, and protection requirements before recording final claims; research observations from 2026-08-28 are not evergreen.
- **Current-head CI:** The local v1.38 planning-start commit was ahead of `origin/main` during research; obtain required CI for the exact final source SHA rather than reusing prior-release evidence.
- **Remote authority:** Decide PR closure, merge, branch/worktree removal, and dependency updates only with owner/policy authorization and item-specific proof.
- **OIDF findings:** Preserve redacted receipts and classify them; only a reproducible repository regression warrants a scoped corrective task in this milestone.
- **Potential drift fences:** Add an automated assertion only after a concrete, deterministic drift mechanism is observed; do not create a speculative dashboard or new maintenance subsystem.

## Sources

### Primary (HIGH confidence)

- Lockspire repository evidence: `mix.exs`, `mix.lock`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `.github/workflows/oidf-conformance.yml`, `scripts/maintainer/repo_hygiene_check.sh`, `REPO-HYGIENE-CHECKLIST.md`, `RELEASE-TRAIN.md`, and current GSD planning records.
- Research inputs: [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PITFALLS.md](PITFALLS.md).

### Secondary (MEDIUM confidence)

- GitHub documentation on protected/required status checks, merge queues, workflow-artifact retention, and secure full-SHA action pinning.
- GitHub CLI documentation for complete read-only PR, issue, and workflow-run inventories.

## Files Created/Modified

- `.planning/research/SUMMARY.md` — canonical v1.38 research synthesis and roadmap guidance.
- `.planning/research/STACK.md` — source research retained and committed with the synthesis.
- `.planning/research/FEATURES.md` — source research retained and committed with the synthesis.
- `.planning/research/ARCHITECTURE.md` — source research retained and committed with the synthesis.
- `.planning/research/PITFALLS.md` — source research retained and committed with the synthesis.

## Task Commits

1. **Synthesize v1.38 research** — `83b6b4cc` (`docs: complete project research`)

## Self-Check: PASSED

- Confirmed the four research inputs were synthesized and all cited workflow filenames exist in `.github/workflows/`.
- `git diff --check` passed during this validation repair.
- This summary preserves the bounded maintenance scope: evidence-led reconciliation, existing gates, and no protocol or tooling expansion.

---
*Research completed: 2026-08-28*
*Ready for roadmap: yes*
