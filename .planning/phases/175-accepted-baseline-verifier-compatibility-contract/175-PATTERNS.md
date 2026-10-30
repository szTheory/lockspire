# Phase 175: Accepted Baseline & Verifier Compatibility Contract - Pattern Map

**Mapped:** 2026-10-25
**Files analyzed:** 5 likely Phase 175 qualification/evidence artifacts
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/integration/client_secret_jwt_legacy_age_test.exs` (candidate; adjacent to lifetime integration test) | test | request-response / persisted storage | `test/integration/client_secret_lifetime_registration_test.exs` | strong role + caller/store match |
| `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.md` (finite ledger/API-policy disposition; filename to be selected in planning) | utility / evidence artifact | transform / qualification record | `175-CONTEXT.md` decisions and Phase 174 delivery record | role-match |
| `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-MAIN-ACCEPTANCE.json` (only after execution; immutable helper stdout) | utility / evidence artifact | request-response / receipt capture | existing helper receipt contract in `scripts/maintainer/repo_hygiene_check.sh` | exact process-pattern match |
| `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CUSTODY.md` (adjacent resource/checkout annotations) | utility / evidence artifact | transform / inventory | `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md` | strong role match |
| `test/lockspire/security/client_secret_verifier_compatibility_test.exs` (candidate for exported helper and metadata-shape boundaries) | test | transform / request-response | `test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs` | role-match |

These are likely qualification/evidence artifacts, not a settled task list. New runtime implementation, downstream Phase 176–178 work, acceptance execution and policy feasibility are outside this map. The native storage-age policy and metadata-reader support remain open qualification gates.

## Pattern Assignments

### Persisted legacy-age caller qualification test

**Target:** `test/integration/client_secret_jwt_legacy_age_test.exs`
**Analog:** `test/integration/client_secret_lifetime_registration_test.exs` (tracked)

The persisted integration test uses a real `TestRepo`, manual SQL Sandbox, repository reads and actual `ClientAuth.authenticate` calls:

```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  start_supervised!(Lockspire.TestRepo)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
  :ok
end

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  :ok
end
```
Source: `test/integration/client_secret_lifetime_registration_test.exs:13-23`.

Its caller pattern fetches the persisted client and authenticates using the real repository adapter with a controllable Lockspire clock:

```elixir
assert {:ok, stored} = Repository.fetch_client_by_id(success.client.client_id)
assert {:ok, _client} =
  ClientAuth.authenticate(%{}, authorization,
    client_store: Repository,
    now: fn -> DateTime.from_unix!(109) end
  )
```
Source: `test/integration/client_secret_lifetime_registration_test.exs:45-64`.

Use this DB-backed seam for legacy verifier qualification; create authentic old Plug ciphertext and unique assertion JTIs per attempt. Keep Plug payload wall-clock age separate from the injected `now` used for client/secret expiry. The existing in-memory JWT boundary test is useful only as a configured-expiry/replay control: `test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs:15-48,50-72`.

### Exported verifier helper and metadata compatibility test

**Target:** `test/lockspire/security/client_secret_verifier_compatibility_test.exs`
**Analogs:** `lib/lockspire/security/policy.ex` and `lib/lockspire/clients.ex` (tracked); tests should follow the existing ExUnit boundary test above.

The current API preserves both binary endpoint-secret-base and keyword-option overloads, with a single tagged unseal error:

```elixir
def seal_client_secret_jwt_verifier(secret, secret_key_base)
    when is_binary(secret) and is_binary(secret_key_base) do
  Plug.Crypto.encrypt(required_secret_key_base!(secret_key_base), @client_secret_jwt_salt, secret)
end

def unseal_client_secret_jwt_verifier(encrypted, secret_key_base)
    when is_binary(encrypted) and is_binary(secret_key_base) do
  unseal_client_secret_jwt_verifier(encrypted, secret_key_base: secret_key_base)
end
```
Source: `lib/lockspire/security/policy.ex:178-212`. The public zero-argument helper currently returns `{hash, plaintext}` and delegates to material generation, which also encrypts verifier material: `lib/lockspire/clients.ex:86-105`. Compatibility cases should pin those current shapes and explicit outcomes for missing identity/config; do not assume a changed API or successful metadata-reader policy.

### Finite ledger and policy/API disposition

**Target:** concise phase evidence ledger/disposition (suggested `175-COMPATIBILITY.md`)
**Analogs:** `175-CONTEXT.md` D-05–D-25 and `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md` (tracked).

Use stable case IDs and one row per meaningful boundary. Preserve the context's fields: requirement, actual caller/source seam, persisted client/lifecycle state, material/config/key/write stage, store composition, operation and expected outcome, allowed mutations/preserved fields, redaction, proof owner, evidence identity/status and blocker. Phase 174's delivery record demonstrates distinct evidence and custody sections, explicit unknown ownership, and separated failed attempts (lines 46-69). Do not turn the ledger into an unbounded matrix or downstream implementation plan.

The tracked `ClientStore` contract is the closest adapter-boundary analog. It declares explicit transaction authority and current-row locking (`lib/lockspire/storage/client_store.ex:10-25`); the new ledger should record the proposed maintenance capability and supported composition as unresolved/frozen contract fields, not claim that this interface already exists.

### Immutable acceptance receipt and adjacent custody record

**Receipt target:** `175-MAIN-ACCEPTANCE.json`, captured byte-for-byte from existing helper stdout only after an actual successful run.
**Analog:** `scripts/maintainer/repo_hygiene_check.sh:563-594,597-629` (tracked).

The helper emits one compact allowlisted JSON object containing baseline SHA, local gate, hygiene counts, canonical CI, no-publish Release, and observed warning dispositions. Its exact flow revalidates identity between gates and emits only after all checks and warning disposition validation pass. Preserve stdout bytes, actual exit, invocation, timestamp and digest as adjacent metadata; failed attempts remain separate. Do not modify or duplicate the helper's receipt schema.

**Custody target:** adjacent phase note, separate from receipt bytes.
**Analog:** `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md:46-69` (tracked).

Copy the table's concrete fields: resource, observed state, custodian/purpose, next review action; include final checkout status. Preserve unknown original ownership as unknown and retain historical Phase 142/143 work and immutable prior receipt. No cleanup or re-stamping is implied.

## Shared Patterns

### Separate evidence from interpretation

**Sources:** helper receipt flow and Phase 174 delivery record above. Keep canonical helper output immutable; place annotations, custody, failed-attempt history and compatibility interpretation in adjacent artifacts. The existing accepted Phase 174 receipt SHA is historical evidence and must not be regenerated or altered.

### Actual caller and independent clocks

**Source:** `test/integration/client_secret_lifetime_registration_test.exs:13-23,45-74` plus `test/lockspire/protocol/client_secret_lifetime_jwt_boundary_test.exs:25-47`. Persist the client and invoke `ClientAuth`; use new JTIs; record Plug's authenticated payload timestamp separately from injected client/secret decision time and durable effects.

### Explicit adapter boundary

**Source:** `lib/lockspire/storage/client_store.ex:10-25`. Record the built-in Ecto store and specifically declared shared-PostgreSQL composition only. Ordinary client callbacks do not establish a maintenance capability or justify fallback to a default Repo.

## No Analog Found

No code analog exists for a finite VBASE compatibility ledger or a newly frozen maintenance capability/error contract. Use the CONTEXT.md decisions and RESEARCH.md artifact schema as the source; do not model an unimplemented API as existing behavior.

## Metadata

**Analog search scope:** `lib/lockspire/{security,clients,protocol,admin,storage}`, `test/{integration,lockspire}`, `scripts/maintainer`, and Phase 174 delivery artifacts.
**Tracked-source check:** All named analogs were confirmed by `git ls-files`; no runtime/install mirror paths are used.
**Pattern extraction date:** 2026-10-25
