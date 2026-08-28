# CI timing baseline

The baseline runner records the current fast, integration, and historical aggregate commands in JSON. The aggregate command's integration target is selected by `test.integration`; its three non-integration files are selected by `test.fast` because the default test helper excludes only the `:integration` tag. After this proof, CI keeps the focused `test.phase3` alias for maintainers but removes it from the default matrix.

Measured locally on 2026-08-26 with the repository test database: fast completed in 10 seconds, integration completed in 9 seconds, and the historical aggregate completed in 3 seconds. The aggregate proves no unique default-suite ownership, so it is removed from `mix ci` and CI while its focused alias remains available.

Run `MIX_ENV=test bash scripts/ci/run_test_matrix.sh --baseline /tmp/lockspire-ci-timings.json` to refresh measured timings locally. CI emits per-partition JSON artifacts for the post-change fast and integration jobs.
