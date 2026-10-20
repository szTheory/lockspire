# Roadmap: Lockspire

## Milestones

- 🚧 **v1.44 Adopter Polish & Verified 1.6.0** — active; Phases 158–161; adopter polish on the v1.43 KEK work, then one verified 1.6.0 publish.
- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Direction

v1.44 Adopter Polish & Verified 1.6.0 is active (Phases 158–161). It fixes the three DB-touching Mix tasks that do not start the host repo, ships the cheap key-encryption-key setup wins (`mix lockspire.gen.kek`, `{:system, "VAR"}`), adds a read-only Key protection line and a missing-KEK error to the admin Keys page, then publishes and independently verifies Lockspire 1.6.0. The release runs last: Release Please PR #121 merges only after all v1.44 work is on `main` with CI green (one publish cycle carrying v1.43 + v1.44). SAFE-02 (no protocol, security-default, schema or dependency change; no key material in any output) constrains every phase; Phase 161 owns its final proof.

## Active Milestone: v1.44 Adopter Polish & Verified 1.6.0

- [x] **Phase 158: Mix Task Repo Start** - `client.create`, `doctor.token_format` and `doctor.remote_jwks` start and stop the host repo themselves via `RepoRunner`, with real error reasons (completed 2026-10-19)
- [x] **Phase 159: Key-Encryption Key Setup DX** - `mix lockspire.gen.kek`, `{:system, "VAR"}` runtime resolution, redacted `KeySet` inspect, and guidance that points to the new task (completed 2026-10-19)
- [x] **Phase 160: Admin Key Protection & Missing-KEK Copy** - read-only Key protection line and a calm missing-encryption-key error on the Keys page, with vocabulary map updates (completed 2026-10-19)
- [ ] **Phase 161: Docs & Verified 1.6.0 Release** - guides updated, PR #121 squash-merged last, 1.6.0 published and verified from public sources

### Phase 158: Mix Task Repo Start

**Goal**: A host developer can run every DB-touching Lockspire Mix task in a bare `mix` session and get either the intended result or the real failure reason.
**Depends on**: Nothing (first phase of v1.44; builds on v1.43 main)
**Requirements**: TASK-01, TASK-02, TASK-03
**Success Criteria** (what must be TRUE):
  1. The clean-room SaaS journey first reproduces the failure, then runs `mix lockspire.client.create`, `mix lockspire.doctor.token_format` and `mix lockspire.doctor.remote_jwks` against a real host whose repo is not running, and all three succeed.
  2. Each task has a test that runs it with no pre-started repo, and a check that an already-running repo's pool pid is unchanged after the task runs (RepoRunner, not raw `with_repo`, not `app.start`).
  3. A `client.create` validation or write failure shows the real reason (not "repo unavailable"), and a client secret is printed at most once, only after a successful write.
  4. Doctor tasks keep their existing exit codes and output shape; no task output, error or log carries secret or key material (SAFE-02).

**Plans:** 3/3 plans complete

Plans:
**Wave 1**
- [x] 158-01-PLAN.md — reproduce in the clean room first, then route client.create through TaskError + RepoRunner (tracer), shared test helpers, cold client.create test

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 158-02-PLAN.md — doctor token_format and remote-jwks via TaskError, cold + pool-untouched tests, clean-room journey green

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 158-03-PLAN.md — client.create real failure reasons, Inspect redaction, log-safety proof, RepoRunner comment and pool-check hardening, phase gate

### Phase 159: Key-Encryption Key Setup DX

**Goal**: A host developer can generate and wire up a key-encryption key without openssl and without risking a silent unencrypted fallback.
**Depends on**: Phase 158 (clean-room harness changes land first; independent code seams)
**Requirements**: KEK-03, KEK-05, KEK-06
**Success Criteria** (what must be TRUE):
  1. `mix lockspire.gen.kek` prints a fresh 32-byte base64 key and the same fail-closed `runtime.exs` snippet the installer prints (one shared snippet builder); `--id` validates the key ID (default `YYYY-MM` UTC), `--raw` prints only the value, and the output passes `KeySet` validation. The task writes no files, needs no repo, and emits no logs or telemetry.
  2. A host configuring a key entry as `{:system, "VAR"}` boots with it resolved at runtime in `Lockspire.Config`; nothing is resolved at compile time or written back to app env.
  3. With an unset or empty variable in a configured key list, boot fails with an error naming the variable and never its value, and never falls back to "not configured".
  4. `inspect`ing or logging a key set shows no key bytes, and every guidance message that recommends generating a key (config errors, `mix lockspire.verify`, `mix lockspire.keys.reencrypt`, the upgrade guide) points to `mix lockspire.gen.kek` (SAFE-02).

**Plans:** 3/3 plans complete

Plans:
**Wave 1**
- [x] 159-01-PLAN.md — gen.kek task with shared KekSnippet builder (tracer), installer refactor, clean-room cold-run proof
- [x] 159-02-PLAN.md — `{:system, "VAR"}` runtime resolution in Lockspire.Config, fail-closed missing_env boot, redaction proof tests

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 159-03-PLAN.md — guidance sweep to `mix lockspire.gen.kek`, docs, pinned tests, D-10 guidance contract test, phase gate

### Phase 160: Admin Key Protection & Missing-KEK Copy

**Goal**: An operator on the admin Keys page can tell at a glance whether signing keys are protected, and understands why key generation is refused when no encryption key is set up.
**Depends on**: Phase 159 (shares the KEK config surface and `gen.kek` setup guidance)
**Requirements**: KEY-UI-01, KEY-UI-02, KEY-UI-03
**Success Criteria** (what must be TRUE):
  1. The Keys page shows a read-only "Key protection" line naming the current encryption key ID when keys are encrypted, with distinct calm wording for older-key, unencrypted, unreadable, not-set-up, invalid-config and could-not-check states; "could not check" never reads as healthy.
  2. A failed protection check leaves the key list visible; the line shows no per-encryption-key counts, no key material and no new controls (SAFE-02).
  3. Trying to generate a signing key with no encryption key configured shows that none is set up, that Lockspire will not store signing keys unencrypted, and how to set one up; other generation errors keep their existing copy.
  4. All new wording comes from the PRODUCT.md vocabulary map, new terms and retired phrases are added in the same change, and `vocabulary_contract_test.exs` passes.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**
- [x] 160-01-PLAN.md — Key protection line: KeysLive.Protection presenter (tracer), page wiring, seven-state matrix, isolation and disclosure tests, PRODUCT.md vocabulary rows

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 160-02-PLAN.md — missing key-encryption key generation error for signing and encryption keys, docs-only generate_key @spec, phase gate (mix ci, stress test, SAFE-02 diff)

**UI hint**: yes

### Phase 161: Docs & Verified 1.6.0 Release

**Goal**: Adopters can read accurate guides for the new setup path and install a publicly verified Lockspire 1.6.0 that carries v1.43 and v1.44.
**Depends on**: Phases 158, 159, 160 (release runs last: all v1.44 work on `main` with CI green)
**Requirements**: DOC-02, REL-01, REL-02, SAFE-02
**Success Criteria** (what must be TRUE):
  1. The install, upgrade and operator guides describe `mix lockspire.gen.kek`, the `{:system, "VAR"}` option and the Key protection line, and `mix docs.verify` passes on CI Elixir 1.19.5 / OTP 28.
  2. The milestone diff shows no protocol behavior, security default, schema or dependency change, and a final sweep finds no private key material or key-encryption key in task output (other than `gen.kek`'s own key), logs, telemetry, admin pages or errors.
  3. After v1.44 is on `main` with CI green, the regenerated Release Please PR #121 is re-read, its version and changelog cover v1.40–v1.44, and it is squash-merged.
  4. 1.6.0 is published through the protected exact-ref lane and independently verified: Hex API checksum matches the manifest and downloaded tarball, HexDocs serve 1.6.0, the `lockspire-v1.6.0` tag and GitHub release point at the published source SHA, and the tarball includes the new Mix tasks.
  5. A clean-room host installs `{:lockspire, "== 1.6.0"}` from Hex in a fresh `HEX_HOME`, and the result is recorded in `.planning/RELEASE-TRAIN.md`.

**Plans:** 9 plans

Plans:
**Wave 1**
- [x] 161-01-PLAN.md — operator guide Key protection subsection + contract test, install/upgrade drift audit, docs.verify (DOC-02)
- [x] 161-02-PLAN.md — release-train gate repair (metadata >= public), file-derived test helpers, simulated post-#121 proof (REL-01, D-16)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 161-03-PLAN.md — SAFE-02 evidence, full pre-push gate, v1.44 PR text and #122 override with offline parse proof

**Wave 3**
- [x] 161-04-PLAN.md — maintainer-gated push of milestone/v1.44 branch, open PR, all required checks green

**Wave 4**
- [x] 161-05-PLAN.md — maintainer-gated #122 override edit, v1.44 squash merge as its own step (S1 recorded)

**Wave 5**
- [x] 161-06-PLAN.md — SAFE-02 rebound to S1 and safe local reset; re-read regenerated #121 (1.6.0, v1.40-v1.44) and simulate its head tree (D-21), maintainer-gated squash merge, CI push run green on publish SHA (REL-01)

**Wave 6**
- [x] 161-07-PLAN.md — protected exact-ref publish of 1.6.0: authorize SHA, dispatch, hex-publish approval, clear variable (REL-02)

**Wave 7**
- [ ] 161-08-PLAN.md — independent public verification: checksum three-way, tarball tasks, HexDocs, tag/release, fresh HEX_HOME install

**Wave 8**
- [ ] 161-09-PLAN.md — RELEASE-TRAIN.md 1.6.0 record via squash-merged docs PR, auto-merge and Dependabot decision

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 158. Mix Task Repo Start | 3/3 | Complete    | 2026-10-19 |
| 159. Key-Encryption Key Setup DX | 3/3 | Complete    | 2026-10-19 |
| 160. Admin Key Protection & Missing-KEK Copy | 2/2 | Complete    | 2026-10-19 |
| 161. Docs & Verified 1.6.0 Release | 7/9 | In progress | - |

## Phases

<details>
<summary>✅ v1.43 Signing Key Encryption at Rest (Phases 155–157) — completed 2026-10-16</summary>

- [x] Phase 155: Crypto Core, Config Seam & Bandit Baseline (5/5 plans) — Bandit 1.13.1 hosts; KEK config seam; every new signing key sealed as an `LSK` envelope that all six consumers read.
- [x] Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal (3/3 plans) — locked, CAS-guarded re-encryption and KEK rotation, `--check` readiness, opt-in `legacy_plaintext: :reject`.
- [x] Phase 157: Host Surfaces, Redaction Sweep & Release Proof (6/6 plans) — fail-closed install KEK block, structural redaction sweep, upgrade-journey and CI proof, HexDocs upgrade guide.

**Audit:** [v1.43 milestone audit](milestones/v1.43-MILESTONE-AUDIT.md) — 16/16 requirements, 15/15 integration, 4/4 flows; `tech_debt`, no blockers; override closeout for stale 155/156 reports.

</details>

<details>
<summary>✅ v1.42 Admin UI Clarity & Workflow Refinement (Phases 151–154) — completed 2026-10-15</summary>

- [x] Phase 151: Focused Client Registration & Settings (2/2 plans) — its own registration route, focused app task pages, and a primary/secondary/danger action rule.
- [x] Phase 152: Overview & Queue State Clarity (5/5 plans) — overview counts open exact read-only queue subsets, with hedged reuse and sign-out evidence.
- [x] Phase 153: Configure & Support Page Refinement (7/7 plans) — plain language and clear page hierarchy across all 30 admin paths.
- [x] Phase 154: Responsive, Theme & Route Proof (7/7 plans) — contrast, focus and layout fixes with redaction-safe evidence across 7 widths and 3 themes.

**Audit:** [v1.42 milestone audit](milestones/v1.42-MILESTONE-AUDIT.md) — 9/9 requirements, no gaps; bounded UI polish and pre-existing debt accepted.

</details>

<details>
<summary>✅ v1.41 Product Language & Repository Clarity (Phases 148–150) — completed 2026-10-11</summary>

- [x] Phase 148: User-Facing Admin Language (7/7 plans) — task-centered copy that preserves OAuth/OIDC meaning and truthful outcomes.
- [x] Phase 149: Repository Ownership and Lifecycle (1/1 plan) — lifecycle map and evidence-backed preservation decisions.
- [x] Phase 150: Adopter and Maintainer Documentation (2/2 plans) — canonical adoption path and task-grouped HexDocs.

**Audit:** [v1.41 milestone audit](milestones/v1.41-MILESTONE-AUDIT.md) — no requirement or integration gaps; bounded maintenance debt accepted.

</details>

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
