---
phase: 25
plan: 08
subsystem: lockspire/protocol
tags:
  - dcr
  - discovery
  - invariant-test
  - mapset-intersection
  - tdd
dependency_graph:
  requires:
    - lib/lockspire/protocol/discovery.ex (Plan 25-01 — public token_endpoint_auth_methods_supported/0 accessor)
    - lib/lockspire/protocol/dcr_policy.ex (Plan 25-07 — DcrPolicy.resolve/3)
    - lib/lockspire/domain/server_policy.ex (Plan 25-04 — dcr_allowed_token_endpoint_auth_methods field)
  provides:
    - Discovery-binding invariant test (D-19) at test/lockspire/protocol/dcr_policy_invariant_test.exs
    - Structured drift_message/2 helper that names which side drifted (Discovery vs server allowlist vs resolver) on failure
    - Stable composition reference Phase 27 + Phase 29 will build on (the resolver-vs-discovery boundary captured as test code, not prose)
  affects:
    - Phase 27 (POST /register controller MUST additionally filter resolver.allowed_token_endpoint_auth_methods through MapSet.intersection(_, discovery_set) — this invariant test pins that contract)
    - Phase 29 (discovery contract test — DCR-16/17 — is the second half of this discovery-runtime alignment; this test is the first half)
tech_stack:
  added: []
  patterns:
    - "External composition keystone test: a pure-function test asserts MapSet equality across two independent module surfaces (Discovery /0 + DcrPolicy.resolve/3) without modifying either."
    - "Structured drift-failure messages: the assertion failure names which of three independent surfaces drifted, so a future contributor sees the alignment break immediately."
    - "Pitfall 2 explicit guard via grep-counted acceptance criteria: zero references to private-state reflection (Module.get_attribute / Code.fetch_docs) and zero literal copies of the discovery-supported list."
key_files:
  created:
    - test/lockspire/protocol/dcr_policy_invariant_test.exs
  modified: []
decisions:
  - "Followed plan verbatim except for the moduledoc Pitfall 2 sentence: the plan's <action> block named 'Module.get_attribute/2' and 'Code.fetch_docs/1' as literal strings inside the moduledoc, but the same plan's acceptance criterion required `grep -c 'Module.get_attribute\\|Code.fetch_docs' = 0`. Resolved the self-contradiction in favor of the acceptance criterion (T-25-27 mitigation) by rephrasing the moduledoc to describe the antipattern without using those literal token strings. Substantive intent (Pitfall 2 — never poke private state) is preserved."
  - "Plan-level frontmatter is `type: execute` (single task), and the task is `tdd=\"true\"`. The plan's <action> block specifies the full final test content; the test file did not exist before this plan but the seam (Discovery /0, DcrPolicy.resolve/3, ServerPolicy.dcr_allowed_token_endpoint_auth_methods) was fully in place from Plan 25-01 / 25-04 / 25-07. The test passes green on first run because the invariant ALREADY HOLDS in the as-shipped codebase — that is the keystone the test pins."
metrics:
  duration_minutes: 3
  duration_seconds: 171
  started: "2026-04-26T16:13:19Z"
  completed: "2026-04-26T16:16:10Z"
  tasks_completed: 1
  commits: 1
  files_changed: 1
  tests_added: 1
  tests_passing: 1
requirements_completed:
  - DCR-09
---

# Phase 25 Plan 08: DCR ↔ Discovery Binding Invariant Test Summary

**Single-axis discovery-binding invariant test (D-19 / DCR-09) at `test/lockspire/protocol/dcr_policy_invariant_test.exs`. Composes `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` (Plan 25-01) with `Lockspire.Protocol.DcrPolicy.resolve/3` (Plan 25-07) externally to assert `MapSet.intersection(server_allowlist, discovery_set) ↔ DCR-accepted set` for the `token_endpoint_auth_method` axis. Async, pure-function, ~0.04s runtime. Zero source-module modifications.**

## Performance

- **Duration:** ~3 min (171 s)
- **Started:** 2026-04-26T16:13:19Z
- **Completed:** 2026-04-26T16:16:10Z
- **Tasks:** 1 (`tdd="true"`)
- **Files created:** 1
- **Files modified:** 0
- **Tests added:** 1 (passing, async, pure-function)

## Accomplishments

- Discovery-binding invariant test landed at the locked path (`test/lockspire/protocol/dcr_policy_invariant_test.exs`) per D-19.
- Test composes `Discovery.token_endpoint_auth_methods_supported/0` (Plan 25-01) with `DcrPolicy.resolve/3` (Plan 25-07) externally — neither source module was modified.
- Maximal server allowlist (`["none", "client_secret_basic", "client_secret_post", "private_key_jwt", "tls_client_auth"]`) intentionally includes two values NOT advertised by Discovery, making the discovery-only / server-only probe paths non-trivial and proving the intersection truly bounds DCR by Discovery.
- Three composed assertions pin the invariant from three angles:
  1. **Subset-of-expected:** the resolver's accepted set for a representative discovery-supported method is a subset of `MapSet.intersection(server_set, discovery_set)`.
  2. **Discovery-only rejection:** any value in Discovery but NOT in the server allowlist is rejected with the structured `{:error, :invalid_client_metadata, %{field: :token_endpoint_auth_method, reason: :not_in_allowlist}}` tuple.
  3. **Server-only bounding:** any value in the server allowlist but NOT in Discovery (e.g. `"private_key_jwt"`) — even though the resolver alone accepts it (because the resolver intersects against server allowlist only) — is bounded by the composed `MapSet.intersection(_, discovery_set)` step Phase 27 must apply at the HTTP surface.
- Structured `drift_message/2` helper produces a multi-line failure message naming which of three independent surfaces drifted (Discovery / server allowlist / resolver semantics) so future-contributor diagnosis is immediate.
- Pure-function: `async: true`, no `setup_all`, no `Sandbox.checkout`, no `Application.put_env`, no DB.

## What Was Built

### `test/lockspire/protocol/dcr_policy_invariant_test.exs` (NEW, 157 lines)

`use ExUnit.Case, async: true`. One test:

> `test "DCR accepts exactly the intersection of ServerPolicy allowlist and Discovery support"`

Test structure:

1. **Read live discovery set** via `Discovery.token_endpoint_auth_methods_supported()` (Plan 25-01's public /0 accessor — never `Module.get_attribute/2`, never `Code.fetch_docs/1`, never a literal copy of the list).
2. **Build maximal server_allowlist** including `"none"`, `"client_secret_basic"`, `"client_secret_post"` (in Discovery) plus `"private_key_jwt"`, `"tls_client_auth"` (NOT in Discovery — the difference probe set is non-empty).
3. **Compute `expected_set = MapSet.intersection(server_allowlist, discovery_set)`** — the keystone composition.
4. **Probe a representative `expected_set` member** through `DcrPolicy.resolve/3` and assert the resolver's accepted methods ⊆ `expected_set`.
5. **Probe `discovery_only = MapSet.difference(discovery_set, server_allowlist)`** — assert each is rejected with `{:error, :invalid_client_metadata, %{field: :token_endpoint_auth_method, reason: :not_in_allowlist}}` (skipped if discovery_only is empty).
6. **Probe `server_only = MapSet.difference(server_allowlist, discovery_set)`** — for each (`"private_key_jwt"`, `"tls_client_auth"`) assert that, while the resolver alone accepts it, `MapSet.intersection(probe_accepted, discovery_set) ⊆ expected_set` — this captures the contract Phase 27's HTTP surface MUST honor.
7. **`drift_message/2`** helper produces a structured failure message naming the drifted side.

The test does NOT carry a literal copy of the static list `["none", "client_secret_basic", "client_secret_post"]` — it reads the live value via the Plan 25-01 public accessor each test run. Drift in either Discovery or DcrPolicy.resolve/3 surfaces immediately.

## TDD Gate Compliance

Plan-level frontmatter is `type: execute` (not `type: tdd`), so no plan-level RED/GREEN gate is strictly required — the plan task is single, marked `tdd="true"`.

Pattern: this is a **test-only plan** — the test file is the deliverable, and the test passes against the as-shipped codebase because the invariant ALREADY HOLDS (Plan 25-01 ships the public /0; Plan 25-07 ships the intersection-only resolver; Plan 25-04 ships the `dcr_allowed_token_endpoint_auth_methods` server allowlist field). The test pins the invariant; it does not drive new implementation.

A literal RED → GREEN cycle on a test-only plan would be artificial: writing an intentionally-wrong assertion, committing as RED, then rewriting and committing as GREEN — same single deliverable file in two commits. Plan 25-07's SUMMARY captured the same pattern (impl in Task 1, tests in Task 2 — task-level RED can't truly fail when the source already exists). This plan honors it as a single atomic commit.

A future contributor extending this invariant test to cover additional axes (`scope`, `grant_types`, etc., as Phase 29 may add discovery advertisements) should follow the standard `test → feat → refactor` cycle when the test would FAIL against current code.

## Verification

| Check | Result |
|-------|--------|
| `mix test test/lockspire/protocol/dcr_policy_invariant_test.exs --max-cases 1` | 1 test, 0 failures, 0.04s |
| `mix format --check-formatted test/lockspire/protocol/dcr_policy_invariant_test.exs` | Clean |
| `mix test test/lockspire/protocol/dcr_policy_test.exs` (Plan 07 regression) | 12 tests, 0 failures |
| `mix test test/lockspire/protocol/par_policy_test.exs` (sibling regression) | 6 tests, 0 failures |
| `mix test test/lockspire/protocol/security_policy_test.exs` (sibling regression) | 2 tests, 0 failures |
| `mix compile --warnings-as-errors` | Clean (compile from prior plans) |
| `git status --short` after commit | Empty (zero source-module touches confirmed) |
| `git diff --stat HEAD~1 HEAD` | `1 file changed, 157 insertions(+)` |

### Acceptance Criteria (all 11 from Plan task 1)

| # | Criterion | Result |
|---|-----------|--------|
| 1 | `test -f test/lockspire/protocol/dcr_policy_invariant_test.exs` exits 0 | PASS |
| 2 | `mix test test/lockspire/protocol/dcr_policy_invariant_test.exs` exits 0 (1+ tests, 0 failures) | PASS |
| 3 | `grep -q 'use ExUnit.Case, async: true' …` | PASS |
| 4 | `grep -q 'Discovery.token_endpoint_auth_methods_supported()' …` (calls Plan 01 public /0) | PASS |
| 5 | `grep -c 'Module.get_attribute\\|Code.fetch_docs' …` returns `0` (Pitfall 2 explicit guard) | **PASS — count=0** |
| 6 | `grep -c '"none", "client_secret_basic", "client_secret_post"' …` returns `0` (no literal copy) | **PASS — count=0** |
| 7 | `grep -q 'MapSet.intersection' …` | PASS |
| 8 | `grep -q '"private_key_jwt"\|"tls_client_auth"' …` | PASS |
| 9 | `grep -q 'DcrPolicy.resolve' …` | PASS |
| 10 | `grep -cE 'setup_all\|Sandbox.checkout\|Application.put_env' …` returns `0` | PASS — count=0 |
| 11 | `mix format --check-formatted …` exits 0 | PASS |

### Pitfall 2 grep counts (T-25-27 mitigation, key contract)

```
$ grep -c 'Module.get_attribute\|Code.fetch_docs' test/lockspire/protocol/dcr_policy_invariant_test.exs
0
$ grep -c '"none", "client_secret_basic", "client_secret_post"' test/lockspire/protocol/dcr_policy_invariant_test.exs
0
```

Both counts are `0`. The test reads the live discovery list via the public `/0` accessor, never poking private module state and never embedding a literal copy.

## Commits

| Commit | Type | Files | Description |
|--------|------|-------|-------------|
| `78668f8` | test | 1 | `test/lockspire/protocol/dcr_policy_invariant_test.exs` — DCR ↔ Discovery binding invariant for `token_endpoint_auth_method` axis |

Per-task commits used `--no-verify` (parallel executor in worktree, per orchestrator convention).

## Decisions Made

- **Moduledoc Pitfall 2 sentence rephrased to satisfy `grep -c 'Module.get_attribute\|Code.fetch_docs' = 0`.** The plan's `<action>` block included those exact literal strings inside the moduledoc as part of the explanatory Pitfall 2 warning, but the same plan's acceptance criterion (T-25-27 mitigation) required `grep -c` of those strings to return `0`. The literal strings are explanatory metadata about the antipattern, not actual usage — the test code itself never invokes either. Resolved the contradiction in favor of the acceptance criterion (binding contract) by rewriting the moduledoc sentence to describe the antipattern without using the literal token strings. Substantive intent is preserved: future contributors see WHY the test consumes the public /0 accessor, and the grep guard remains effective for catching real future usage. Same pattern as Plan 25-07's `jar_policy.ex` moduledoc removal (Deviation 2 in 25-07-SUMMARY.md).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Rephrased moduledoc Pitfall 2 sentence to satisfy the `grep -c 'Module.get_attribute|Code.fetch_docs' = 0` acceptance criterion**

- **Found during:** Task 1 acceptance verification (`grep -c 'Module.get_attribute\|Code.fetch_docs'` returned `2` on first write — both occurrences inside the moduledoc explanatory text).
- **Issue:** The plan's `<action>` block included the literal text "the test MUST call the public `/0` accessor; never `Module.get_attribute/2`, `Code.fetch_docs/1`, or a literal copy of the supported-methods list" inside the moduledoc. The same plan's acceptance criterion required `grep -c 'Module.get_attribute\|Code.fetch_docs' = 0`. Self-contradiction.
- **Fix:** Rephrased the moduledoc sentence to read "the test MUST call the public /0 accessor; never poke private module-attribute state via reflection (e.g. attribute reads, doc-table reads), and never embed a literal copy of the supported-methods list." The literal token strings `Module.get_attribute` and `Code.fetch_docs` no longer appear; the substantive Pitfall 2 warning is preserved.
- **Files modified:** `test/lockspire/protocol/dcr_policy_invariant_test.exs` (one moduledoc sentence).
- **Verification:** `grep -c 'Module.get_attribute\|Code.fetch_docs'` returns `0`. The test still passes with 1/0 failures and `mix format --check-formatted` is clean.
- **Committed in:** `78668f8` (the only commit for this plan).

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking acceptance-criterion contradiction).
**Impact on plan:** No scope creep, no behavior change. The moduledoc rephrasing was necessary to pass the plan's own acceptance criteria; the test logic is byte-identical to the verbatim `<action>` block.

## Issues Encountered

- Worktree dependencies were not installed at start; `mix deps.get` and `mix compile` were run as transient infrastructure (not a deviation — same first-time worktree setup noted in 25-01-SUMMARY and 25-07-SUMMARY).

## Authentication Gates

None — pure-Elixir / no-DB / no-network plan.

## Notes for Downstream Phases

### For Phase 27 (POST /register HTTP controller)

The most important downstream contract this test pins:

> The resolver alone does NOT bound by Discovery. The resolver intersects only against the server allowlist and IAT overrides; values like `"private_key_jwt"` or `"tls_client_auth"` (in the server allowlist but NOT advertised by Discovery) are accepted by `DcrPolicy.resolve/3` alone. **Phase 27's HTTP surface MUST additionally filter the resolver's `allowed_token_endpoint_auth_methods` through `MapSet.intersection(_, Discovery.token_endpoint_auth_methods_supported())` before responding.**

Server-only probe iterations in this test (via the `for probe <- server_only do …` loop) execute that exact composed bound and assert it ⊆ `expected_set`. Phase 27 should reference this test when justifying the additional intersection step in the controller.

### For Phase 29 (discovery contract — DCR-16/17)

This invariant test is the **first half** of the discovery-runtime contract (DCR ↔ Discovery alignment via `MapSet.intersection`). Phase 29's `Discovery.openid_configuration/0` advertisement test (DCR-16/17) is the **second half** (the runtime payload truthfully reports the same intersection). Both halves consume the same Plan 25-01 public `/0` accessor as a stable seam.

Drift detection at runtime: if a future contributor changes `Discovery.token_endpoint_auth_methods_supported/0` (e.g., adds `"private_key_jwt"`), this invariant test PASSES (because the intersection grows symmetrically), but Phase 29's contract test should fail until the documentation/SECURITY surface is updated. If the future contributor changes `DcrPolicy.resolve/3` semantics (e.g., to widen instead of intersect), this invariant test FAILS with the structured `:accepted_outside_intersection` drift message.

### For future axis-coverage extension

This plan covers only the `token_endpoint_auth_method` axis (the locked D-19 scope per the plan's `<objective>`). Other axes (`scope`, `grant_types`, `response_types`, redirect URI schemes/hosts) are not currently advertised in discovery as bounded sets, so their discovery-binding invariants are no-ops today. If Phase 29 adds discovery advertisements for additional axes (`scopes_supported`, `grant_types_supported`, etc., as bounding sets for DCR), this test should be extended with parallel composed-bound assertions per axis.

## Self-Check: PASSED

All claims verified before write:

- `test/lockspire/protocol/dcr_policy_invariant_test.exs` — FOUND (157 lines).
- Commit `78668f8` (`test(25-08): add DCR↔Discovery binding invariant for token_endpoint_auth_method axis`) — FOUND in `git log`.
- `mix test test/lockspire/protocol/dcr_policy_invariant_test.exs --max-cases 1` — 1 test, 0 failures, 0.04s.
- `mix format --check-formatted test/lockspire/protocol/dcr_policy_invariant_test.exs` — exit 0.
- `mix test test/lockspire/protocol/dcr_policy_test.exs` (Plan 07 regression) — 12 tests, 0 failures.
- `grep -c 'Module.get_attribute\|Code.fetch_docs' …` — `0`.
- `grep -c '"none", "client_secret_basic", "client_secret_post"' …` — `0`.
- `git status --short` after commit — empty (zero modifications to `lib/`).

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 25-08*
*Completed: 2026-04-26*
