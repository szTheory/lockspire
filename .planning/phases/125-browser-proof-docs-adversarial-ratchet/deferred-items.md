# Deferred Items

## 2026-06-30 - Out-of-scope `mix test.fast` failures

During Plan 125-06 closeout, `MIX_ENV=test mix test.fast --max-failures 5` ran and failed in Phase 115 release-readiness/adoption-demo contracts. The failures referenced:

- `test/lockspire/release_readiness_contract_test.exs`
- `docs/adoption-demo.md`
- `scripts/maintainer/repo_hygiene_check.sh`

The failing assertions did not name Phase 125 files or Plan 06 artifacts. They appear tied to pre-existing user-owned dirty adoption-demo/release-readiness changes in the working tree and were not fixed in Plan 125-06.
