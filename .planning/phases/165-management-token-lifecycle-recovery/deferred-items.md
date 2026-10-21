# Deferred Items

- The focused compatibility baseline contract fails because `Lockspire.Protocol.RegistrationManagement` now exports `rotate_registration_access_token/1` and `rotate_registration_access_token/2`, but the literal 76cf872 manifest does not declare these Phase 165 recovery entry points as additive extensions.
  status: open
  **Found during:** 165-07-01 focused guidance verification
  **Evidence:** `mix test test/lockspire/client_lifetime_guidance_test.exs test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` fails the baseline assertion. The export was introduced in plans 165-04/06 and is outside plan 165-07's declared files.
  **Follow-up:** The phase owner should decide whether the recovery functions are an approved additive public API and update the compatibility manifest/test or revise the visibility boundary. Do not claim the compatibility baseline gate passed until rerun.

- The Phase 165 full fast suite still has five additional failures outside plan 165-07's declared files.
  status: open
  **Evidence:** `mix test.fast` completed with 2,411 tests, 6 failures, 483 excluded, and 6 skipped in 139.4 seconds. In addition to the compatibility manifest issue above, three `Lockspire.Storage.Ecto.ServerPolicyRecordTest` cases fail on duplicate `lockspire_server_policies_pkey` inserts; `Lockspire.Web.Live.Admin.ClientsLiveTest` expects the retired text `current token stops working after rotation` after plan 165-06 changed the UI to `The previous app management token stops working immediately`; and `Lockspire.Web.DiscoveryControllerTest` expects `registration_endpoint` to be absent although the endpoint is present.
  **Follow-up:** The phase owner should triage the duplicate policy fixtures, update the stale LiveView assertion to the approved vocabulary, and decide whether discovery metadata expectation or behavior is correct. Do not claim the fast-suite gate passed until the full command is clean.
