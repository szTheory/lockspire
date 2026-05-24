# Deferred Items from Plan 26-02

## Out-of-Scope Fixes

**1. `mix qa` Pre-existing Format and Credo Warning Failures**
- **Trigger:** During execution of Plan 26-02, the final verification step to run `mix qa` failed.
- **Root Cause:** The failure was caused by pre-existing formatting inconsistencies in multiple files across the repository (e.g., `test/lockspire/web/live/admin/policies_live/par_test.exs`, `test/support/endpoint.ex`, `lib/lockspire/protocol/jar.ex`, etc.) and a pre-existing Credo strict warning about `Lockspire.Domain.Client` having more than 31 fields.
- **Action Taken:** Only the files directly authored in Task 1 and Task 2 (`test/lockspire/protocol/registration_access_token_test.exs` and `lib/lockspire/protocol/registration_access_token.ex`) were correctly formatted to keep scope constrained per deviation rule "SCOPE BOUNDARY".
- **Resolution:** Deferred fixing global formatting and pre-existing linting issues. The immediate `RegistrationAccessToken` files are clean and tests pass perfectly.