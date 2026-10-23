## Deferred Items

- The test-host fixture has duplicate `record_trace/2` clauses and emits compiler warnings.
  status: open
  **Found:** Present before Phase 168 edits; unrelated to the authorization behavior.
  **Scope:** Deferred to a fixture cleanup task if warning cleanup is needed.
- A phase-base `git diff --check` reports trailing whitespace already present in `168-PATTERNS.md` and `168-RESEARCH.md`.
  status: resolved
  **Found:** Final Plan 168-03 source-base whitespace scan; current task files pass `git diff --check`.
  **Resolution:** The orchestrator removed trailing spaces from both newly authored phase documents after Plan 03. The complete source-base `git diff --check 66fa5c7aa5ee873ecfb2746f52190d03fda97f5f` then passed. No tested source changed.
