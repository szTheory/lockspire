# Deferred Items

- The focused compatibility baseline contract initially failed because the literal 76cf872 manifest did not classify the new Phase 165 host-recovery arities as additive extensions.
  status: resolved
  **Found during:** 165-07-01 focused guidance verification
  **Historical evidence:** The first exact combined gate failed the baseline assertion. The baseline `rotate_registration_access_token/1` remains unchanged; plans 165-01 and 165-04 explicitly add `read/3`, `delete/3`, and `rotate_registration_access_token/2` as host-side time-control/recovery entrypoints. They are not client-authenticated routes. This is an approved additive extension under the phase contract.
  **Resolution:** Added those three arities to the extension manifest and exact manifest assertion in commit `f91a975a`.
  **Rerun:** The exact combined guidance, architecture, and compatibility gate passed: 21 tests, 0 failures.

  status: resolved
  **Historical evidence:** The first full `mix test.fast` rerun completed with 2,411 tests, 6 failures, 483 excluded, and 6 skipped in 139.4 seconds. Besides compatibility drift, three `ServerPolicyRecordTest` inserts collided on the fixed singleton primary key, one `ClientsLiveTest` assertion used retired wording, and discovery expected `registration_endpoint` absent while a prior persisted `:open` policy made it present.
  **Root causes and resolution:** Commit `f91a975a` isolated the policy-record inserts in per-test rollback-only sandbox ownership, deleting the singleton inside that transaction; seeded discovery's expected disabled registration policy inside a rollback-only sandbox; updated the stale rendered-copy assertion; and declared the approved additive public arities. Discovery protocol behavior was unchanged. The affected suites passed 48 tests with 0 failures, and the exact combined gate passed 21 tests with 0 failures.
  **Rerun:** After the additional environment-isolation fix in `0d2b0051`, the full `mix test.fast` gate passed in 134.0 seconds: 2 properties, 2,411 tests, 0 failures, 483 excluded, and 6 skipped.

- The first corrected full-suite run exposed five additional order-dependent private-key JWT test failures.
  status: resolved
  **Historical evidence:** Five tests in `Lockspire.Protocol.DirectClientAuthPrivateKeyJwtTest` raised `ArgumentError` because the Phase 165 recovery LiveView test module left `:mount_path` set to `""` while the issuer retained `/lockspire`.
  **Resolution:** Commit `0d2b0051` restores the original Lockspire and endpoint application environment after the recovery test module and rolls each test's database writes back with sandbox owner lifecycle.
  **Rerun:** The recovery LiveView and private-key JWT suites passed together: 9 tests, 0 failures. A subsequent full `mix test.fast` passed with zero failures.
