---
phase: 22
slug: request-object-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-25
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in test framework) |
| **Config file** | `config/test.exs` (Repo + app config); no separate test runner config |
| **Quick run command** | `mix test test/lockspire/protocol/jar_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs --trace` |
| **Full suite command** | `mix test` (excludes `:integration` by default; integration via `mix test --include integration`) |
| **Estimated runtime** | ~3 seconds (quick); ~15 seconds (full); ~45 seconds (incl. integration) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/lockspire/protocol/jar_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/request_object_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs`
- **After every plan wave:** Run `mix test` (full unit + protocol + controller suite)
- **Before `/gsd-verify-work`:** `mix test --include integration` must be green
- **Max feedback latency:** ~5 seconds for protocol-seam quick run

---

## Per-Task Verification Map

> Populated by the planner during plan generation. Each plan task's `<acceptance_criteria>` block must have a corresponding row here.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _to be filled by planner_ | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All proof surfaces already exist (per RESEARCH.md `Wave 0 Gaps`):

- [x] `test/lockspire/protocol/jar_test.exs` — exists (≈370 lines, 41 tests); needs ≈10 new cases for WR-01/02/03
- [x] `test/lockspire/protocol/authorization_request_test.exs` — exists (≈550 lines); needs ≈11 new cases for D-14/D-15 reason-code matrix
- [x] `test/lockspire/protocol/pushed_authorization_request_test.exs` — exists; needs ≈2 new cases for JAR + ClientAuth interleaving at `/par`
- [x] `test/lockspire/web/authorize_controller_test.exs` — exists (≈474 lines); needs ≈2 new cases (rejection page, happy-path handoff)
- [x] `test/integration/phase15_par_authorization_e2e_test.exs` — exists (≈354 lines); needs ≈1 new test branch (JAR-via-PAR-via-/authorize)
- [ ] **NEW (optional):** `test/lockspire/protocol/request_object_test.exs` — only if orchestrator's surface justifies (per D-20). Recommendation in RESEARCH.md is to fold into `authorization_request_test.exs` unless small helpers warrant isolation.
- [ ] **NEW helper:** `sign_jar/2` test helper (either in `authorization_request_test.exs` setup or a shared `Lockspire.JarTestSupport` module under `test/support/`). Without it, every JAR test repeats ~15 lines of JOSE plumbing.

**Framework install:** None — ExUnit ships with Elixir, already configured in `mix.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| _none_ | | | |

*All Phase 22 behaviors have automated verification — `alg=none` rejection, `typ` rejection, signature verification, claim validation, conflict rejection, `/par` interaction with ClientAuth, and the JAR-via-PAR-via-/authorize e2e flow are all in-process tests with deterministic inputs (no external network, no human-perceptible UI changes). Per CONTEXT.md D-19/D-20/D-21, no human UAT for this phase.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the JAR test helper)
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---

## Reference: Phase Requirements → Test Map

> Lifted from `22-RESEARCH.md` § Validation Architecture. Every D-14 / D-15 reason_code has a 1:1 test entry. Planner uses these rows to write `<acceptance_criteria>` blocks.

### A) Jar primitive hardening (WR-01, WR-02, WR-03)
Pinned in `test/lockspire/protocol/jar_test.exs` — see RESEARCH.md table A (10 rows).

### B) Reason-code branches per D-14
Pinned in `test/lockspire/protocol/authorization_request_test.exs` — see RESEARCH.md table B (9 rows, one per `:invalid_request_object_*` and `:client_jwks_missing` atom).

### C) Shape-level conflict reason codes per D-15
Pinned in `test/lockspire/protocol/authorization_request_test.exs` — see RESEARCH.md table C (2 rows: `:request_object_conflict`, `:request_object_and_request_uri_conflict`).

### D) Sealed-envelope projection happy path
Pinned in `test/lockspire/protocol/authorization_request_test.exs` — see RESEARCH.md table D (2 rows: claim projection + telemetry surface).

### E) `request` removed from `@unsupported_params`
Pinned in `test/lockspire/protocol/authorization_request_test.exs` — see RESEARCH.md table E (3 rows: positive handler, `claims` still rejected, external `request_uri` still rejected).

### F) Browser-boundary proof
Pinned in `test/lockspire/web/authorize_controller_test.exs` — exactly 2 new tests (rejection page render, happy-path handoff). Per D-16 the redirect-safe JAR-failure case is unreachable; happy-path test serves as the redirect-safe proof.

### G) `/par` JAR splice + e2e proof
Pinned in `test/integration/phase15_par_authorization_e2e_test.exs` (1 surgical extension, per D-21) and `test/lockspire/protocol/pushed_authorization_request_test.exs` (2 protocol-seam cases proving D-10 ClientAuth-and-JAR independence).
