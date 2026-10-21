# Deferred Items

- The focused compatibility baseline contract fails because `Lockspire.Protocol.RegistrationManagement` now exports `rotate_registration_access_token/1` and `rotate_registration_access_token/2`, but the literal 76cf872 manifest does not declare these Phase 165 recovery entry points as additive extensions.
  status: open
  **Found during:** 165-07-01 focused guidance verification
  **Evidence:** `mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` fails the baseline assertion. The export was introduced in plans 165-04/06 and is outside plan 165-07's declared files.
  **Follow-up:** The phase owner should decide whether the recovery functions are an approved additive public API and update the compatibility manifest/test or revise the visibility boundary. Do not claim the compatibility baseline gate passed until rerun.
