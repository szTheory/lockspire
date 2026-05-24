# Phase 29 Validation Strategy

## Success Criteria Mapping

**1. Discovery truthful advertising and alignment**
- Strategy: Validated via automated contract test `test/lockspire/protocol/discovery_test.exs` that sets the three policy modes and tests `openid_configuration/0` output against HTTP responses for `POST /register`.

**2. SECURITY.md correctly scoped**
- Strategy: Validated by `grep` within the task verification and manual review to ensure the unsupported surfaces and host responsibilities (like rate limiting) are explicitly listed.

**3. Dynamic Registration guide exists and configured**
- Strategy: Validated by running `MIX_ENV=docs mix docs` and verifying that `docs/dynamic-registration.md` compiles and appears correctly in the generated HexDocs output.

**4. End-to-end DCR scenario test passes**
- Strategy: Validated by running the automated integration suite via `MIX_ENV=test mix test test/integration/phase29_dcr_e2e_test.exs`, ensuring all lifecycle steps succeed correctly.

**5. Milestone closure and 100% traceability**
- Strategy: Validated by regex/grep verification on `REQUIREMENTS.md` ensuring no empty checkboxes exist `[ ]` for v1.5 requirements, and all 27 DCR requirements are mapped.
