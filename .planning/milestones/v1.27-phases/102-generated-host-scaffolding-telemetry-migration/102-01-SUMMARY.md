---
phase: 102-generated-host-scaffolding-telemetry-migration
plan: 01
subsystem: build/test (release-readiness contract)
tags: [scaffold, contract-test, drift-fence, install-template]
requires:
  - "Phases 97/101 shipped install scaffolding (commented :lockspire_protected_api canonical block + no-format-prompt install task)"
provides:
  - "Two SCAFFOLD regression-guard clauses + @install_task_path/@install_generator_path constants in release_readiness_contract_test.exs"
affects:
  - "test/lockspire/release_readiness_contract_test.exs"
tech-stack:
  added: []
  patterns:
    - "Contract-test drift fence over repo source bytes (refute/assert on File.read!)"
    - "RAW-bytes assertion (bypassing the prefix-stripping extract_canonical_pipeline!/2 normalizer) to avoid the commented-state tautology"
key-files:
  created: []
  modified:
    - "test/lockspire/release_readiness_contract_test.exs"
decisions:
  - "Both guard tasks committed as one atomic commit because they are interleaved edits to a single file region (shared @install_task_path/@install_generator_path constants + two adjacent clauses), verified together."
  - "Refute target is the install TASK + GENERATOR source only — never the template, which legitimately carries audience:/enforce_audience: in the commented canonical pipeline."
  - "Uncomment-ready guard asserts against RAW File.read! bytes, not extract_canonical_pipeline!/2 output, because normalize/2 strips the leading '# ' prefix (Pitfall 3 — tautology)."
metrics:
  duration: ~10min
  completed: 2026-05-29
---

# Phase 102 Plan 01: SCAFFOLD Drift Guards Summary

Added two release-readiness contract clauses that fence the already-shipped install scaffolding (SCAFFOLD-01/02) against silent regression: a no-format-prompt refute over the install task + generator source, and a RAW-bytes assertion that the install-template canonical `:lockspire_protected_api` pipeline block stays fully commented.

## What Was Built

- **Two new path constants** (`@install_task_path`, `@install_generator_path`) beside the existing `@install_template_router_path`, using the same `Path.expand("../../...", __DIR__)` idiom.
- **Task 1 — no-format-prompt guard (SCAFFOLD-02, D-02 #1):** iterates `[@install_task_path, @install_generator_path]`, reads each with `File.read!/1`, and `refute`s the source matches `~r/access_token_format|token[_ ]format|:jwt|:opaque/i`. The install template is deliberately excluded (it legitimately carries `audience:`/`enforce_audience:`); the generator renders the template at runtime via `EEx.eval_file`, so the generator source itself stays clean.
- **Task 2 — uncomment-ready guard (SCAFFOLD-01, D-02 #2):** reads `@install_template_router_path` RAW with `File.read!/1`, captures the body between the `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` markers via `Regex.run(..., capture: :all_but_first)`, and asserts every non-blank body line matches `~r/^\s*#/`. It deliberately does NOT route the template through `extract_canonical_pipeline!/2` for the commented-state assertion, because that helper's `normalize/2` (~line 164) strips the leading `# ` prefix — making "every line commented" a tautology.

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs` → **33 tests, 0 failures, exit 0** (the `KeyCache`/`TestRepo` log line is a benign pre-existing async-startup message unrelated to these byte-level guards).
- **Mutation check 1:** inserting `# mutation: access_token_format: :jwt` into `lib/mix/tasks/lockspire.install.ex` made the no-format-prompt guard FAIL (`1 test, 1 failure`); reverted clean.
- **Mutation check 2:** uncommenting one body line (`#   plug Lockspire.Plug.RequireToken` → `plug Lockspire.Plug.RequireToken`) in `priv/templates/lockspire.install/router.ex` made the uncomment-ready guard FAIL (`1 test, 1 failure`); reverted clean.

Both mutation checks confirm the guards are real (not tautologies) and fail loudly on the exact regressions they fence.

## Must-Haves Status

- The contract test fails loudly if any token-format prompt/branch is added to the install task or generator source. (verified via mutation check 1)
- The contract test fails loudly if the install-template canonical block is ever uncommented or de-synced. (verified via mutation check 2)
- A maintainer running `mix test test/lockspire/release_readiness_contract_test.exs` sees the two new SCAFFOLD guard clauses pass against the already-shipped (Phases 97/101) install scaffolding. (verified — 33/0)

## Deviations from Plan

None — plan executed as written. Note: Tasks 1 and 2 modify the same file region (shared new constants + two adjacent clauses) and were committed as a single atomic commit (`ea9e577`) rather than two; they were implemented and verified together, and each was independently mutation-checked.

## Commits

- `ea9e577` — test(102-01): add SCAFFOLD drift guards for install token-format + commented pipeline

## Self-Check: PASSED

- FOUND: test/lockspire/release_readiness_contract_test.exs (contains `@install_task_path`, `@install_generator_path`, both new clauses)
- FOUND: commit ea9e577
