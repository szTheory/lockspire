## Deferred Items

- The test-host fixture has duplicate `record_trace/2` clauses and emits compiler warnings.
  status: open
  **Found:** Present before Phase 168 edits; unrelated to the authorization behavior.
  **Scope:** Deferred to a fixture cleanup task if warning cleanup is needed.
- A phase-base `git diff --check` reports trailing whitespace already present in `168-PATTERNS.md` and `168-RESEARCH.md`.
  status: open
  **Found:** Final Plan 168-03 source-base whitespace scan; current task files pass `git diff --check`.
  **Scope:** Existing planning artifacts, unrelated to the authorization behavior; defer cleanup to phase-document maintenance.
