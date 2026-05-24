# Deferred Items (Phase 41)

## Pre-existing test failures discovered during plan 41-01 execution

These failures exist in the working tree from uncommitted scaffolding predating plan 41-01.
They are NOT caused by plan 41-01 changes. They need to be resolved in subsequent plans or
a dedicated fix session.

### 1. DPoP test: `test validate_proof/2 rejects alg=none unsigned proofs`
- File: `test/lockspire/protocol/dpop_test.exs:87`
- Issue: `lib/lockspire/protocol/dpop.ex` (uncommitted changes) added `:unsupported_signing_algorithm`
  error reason, but the test still asserts `{:error, :invalid_signature}` for alg=none proofs.
- Fix needed: Either update the test to expect `:unsupported_signing_algorithm` or ensure alg=none
  falls through to `:invalid_signature` as before.

### 2. JAR tests: Multiple `verify_signature/2` failures
- File: `test/lockspire/protocol/jar_test.exs`
- Issue: `lib/lockspire/protocol/jar.ex` has uncommitted changes; tests fail when run together
  with other test files (possible test isolation issue or behavior change in the uncommitted code).
- Note: Tests pass when run in isolation (`mix test test/lockspire/protocol/jar_test.exs`).

### 3. Admin Keys test: `test generate_key creates new keys for specific use`
- File: `test/lockspire/admin/keys_test.exs`
- Issue: `lib/lockspire/admin/keys.ex` has uncommitted changes that may have altered key generation
  behavior.

### 4. Release readiness contract test failure
- File: `test/lockspire/release_readiness_contract_test.exs:425`
- Issue: Pre-existing from uncommitted scaffolding changes across multiple protocol files.

### 5. SecurityPolicyTest failure
- File: `test/lockspire/protocol/security_policy_test.exs`
- Issue: Pre-existing; `reject helpers return stable reason atoms for unsupported runtime posture`

All of the above should be addressed in plan 41-02 or a dedicated fix pass, not in plan 41-01.
