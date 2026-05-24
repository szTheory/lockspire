# Phase 44 Validation Plan

## Objectives
Validate that the API stabilization changes (Phase 44) have fully applied strict Dialyzer specs and typing patterns without breaking existing host integrations or internal tests.

## 1. Dialyzer Cleanliness
- Run `mix dialyzer` on the entire codebase.
- **Expected Result:** Zero Dialyzer errors. The 4 previous errors in `dpop.ex` and `backchannel_logout_delivery_worker.ex` are gone, and no new errors have been introduced by adding `@spec` to facades.

## 2. Context Struct Availability and Use
- Inspect `lib/lockspire/host/context.ex` and ensure the `%Lockspire.Host.Context{}` struct is properly defined with strict `@type`s and fields `return_to`, `client_id`, `scopes`, and `interaction_type`.
- Verify `Lockspire.Host.AccountResolver` uses `Lockspire.Host.Context.t()` in its `@callback` definitions instead of generic `map()`.

## 3. Public API Typespecs
- Inspect `Lockspire`, `Lockspire.Admin`, `Lockspire.Clients`, and `Lockspire.Config`.
- **Expected Result:** Every `defdelegate` and public `def` function has a corresponding `@spec` defining correct return types (including union tuples where appropriate).

## 4. Test Suite Execution
- Run `mix test` on the entire test suite.
- Verify `test/lockspire/host/account_resolver_test.exs` is explicitly updated to pass `%Lockspire.Host.Context{}` structs.
- **Expected Result:** The entire test suite passes without errors related to maps instead of context structs.