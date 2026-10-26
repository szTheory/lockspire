# Phase 178 Wave 02 Gate Observations

The first post-wave gate ran after Plan 02 source-binding correction `88f6503d`.

- Python build/parse: five changed modules passed; summary-created-file/self-check spot checks passed.
- `PYTHONDONTWRITEBYTECODE=1 node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 1800 -- python3 -m unittest discover -s test/acceptance -p '*_test.py'`: exit 1; 75 tests, one failure and one error.
- Both failing cases are existing `client_lifetime_boundary_test.py` contracts: `test_named_adapter_may_use_only_the_documented_public_storage_seams` and `test_reused_provider_is_audited_before_mix_inspects_it`. The observed error is `PackageInputError: provider lifetime adapter is missing a documented public seam` from `audit_boundary`.
- Schema-drift gate: block false. Codebase-drift gate: skipped (`no-structure-md`). UI safety: block false with degraded scope (`no-task-commit-rows`); no visual proof claimed.

The failure is retained and routed for narrow correction before Wave 03. Neither passing installed core cells nor nonblocking capability results override the failing inherited acceptance contracts. The run-local cumulative failure tally records this failed attempt; later GREEN results must be appended rather than replacing this observation.

## GREEN Correction Evidence

The narrow correction was committed at source `e94dc48c940d8ffaf80ffa59eac572f102a5cdb8` (`fix(178-02): keep verifier adapter seams optional`). The audit now requires the original four public lifetime seams, permits the verifier-maintenance interface and the paired `UsedJtiStore`/`Domain.UsedJti` capability as optional public extensions, and rejects half of the JTI pair. Nested storage implementations, protocol internals, checkout test support, and forbidden host references remain rejected.

- Focused boundary contracts: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test/acceptance -p 'client_lifetime_boundary_test.py' -v` — exit 0, 10 tests.
- Focused verifier core contracts: `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test/acceptance -p 'client_verifier_core_test.py'` — exit 0, 3 tests.
- Full acceptance command at the correction commit: `PYTHONDONTWRITEBYTECODE=1 node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 1800 -- python3 -m unittest discover -s test/acceptance -p '*_test.py'` — exit 0, 77 tests, zero failures/errors. The increase from 75 to 77 is the two added optional-capability contracts.
- The installed core adapter still declares the complete verifier/JTI capability set; this correction changes only whether those verifier-specific seams are mandatory for lifetime-only fixture adapters. No installed rerun was needed.

The original failed 75-test observation and cumulative tally above remain unchanged. This gate record is committed separately from the source correction.

## Orchestrator Recheck

After the executor returned, the orchestrator reran the full wrapped acceptance command at `c062b201`: 77 tests passed, zero failures/errors. All four `core-final` receipts independently passed the documented validator with their selected pair/store and one executed core case each. These receipts retain clean executed runner/candidate `fa61823c`; they are not restamped at the audit correction. The correction's applicability rationale is limited to optional-reference acceptance for lifetime-only adapters; the actual installed verifier adapter still declares the same complete capabilities. Final frozen-source matrix execution remains Plan 10's owner.

Wave 02's test gate is now GREEN; the prior failed attempt remains part of its history.
