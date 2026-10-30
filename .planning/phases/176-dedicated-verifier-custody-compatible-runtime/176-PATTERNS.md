# Phase 176: Dedicated Verifier Custody & Compatible Runtime - Pattern Map

**Mapped:** 2026-10-25  
**Files analyzed:** 10 planned runtime/test targets, grouped by shared implementation seam  
**Analogs found:** 8 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/security/client_secret_verifier.ex` (new; exact module path discretionary) | service/utility | transform | `lib/lockspire/security/key_encryption/key_set.ex` and `lib/lockspire/security/policy.ex` | role-match |
| `lib/lockspire/config.ex`, `lib/lockspire/application.ex` | config/provider | request-response, boot snapshot | `lib/lockspire/security/key_encryption.ex` | role-match |
| `lib/lockspire/security/policy.ex` | utility | transform | same file, existing verifier wrappers | exact |
| `lib/lockspire/clients.ex`, `lib/lockspire/protocol/registration.ex`, `lib/lockspire/admin/clients.ex` | service/controller | CRUD | `lib/lockspire/clients.ex` and `lib/lockspire/protocol/registration.ex` | exact |
| `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` and existing endpoint caller modules | service/controller | request-response | `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` | exact |
| `test/lockspire/security/client_secret_verifier_test.exs` (new) | test | transform | `test/lockspire/security/client_secret_verifier_contract_test.exs` | role-match |
| `test/lockspire/security/client_secret_verifier_rollout_test.exs` (new) | test | transform | `test/lockspire/security/client_secret_verifier_compatibility_test.exs` | role-match |
| `test/integration/client_secret_verifier_writers_test.exs` (new) | test | CRUD | `test/integration/client_secret_jwt_legacy_age_test.exs` | partial |
| `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` (extend) | test | request-response | same file | exact |
| Phase 175 evidence/qualification sources | frozen input | transform | `test/lockspire/security/client_secret_verifier_contract_test.exs` | reference only; do not modify |

The context/research/validation identify new verifier and rollout unit suites plus a persisted writer integration suite, and call for extending the existing endpoint auth coverage. Config/application and caller changes are inferred implementation targets from the named production seams. No schema, dependency, generic crypto framework, or protocol expansion is in scope. PAR and FAPI remain negative; device and CIBA remain positive as already shipped.

## Pattern Assignments

### Dedicated verifier module and key/context validation

**Analogs:** `lib/lockspire/security/key_encryption/key_set.ex` lines 1-40, 48-123; `lib/lockspire/security/policy.ex` lines 156-212.

`KeySet.new/1` uses tagged errors that do not contain configured values, validates options before decoding, and builds an immutable struct. Reuse its small validators and key-ID/base64 conventions, but adapt them: verifier config has staged reader-only states and must not inherit KeySet's mandatory current key or raising boot behavior. Existing `Policy` verifier functions preserve binary-secret-key-base overloads and public unseal error; retain those wrappers while routing through a dedicated purpose-specific operation.

**Core pattern excerpt** (`key_set.ex`, lines 23-39):

```elixir
def new(config) do
  with {:ok, opts} <- check_options(config),
       {:ok, entries} <- fetch_keys(opts),
       {:ok, keys} <- decode_entries(entries),
       {:ok, current} <- fetch_current(opts, keys),
       {:ok, mode} <- fetch_mode(opts, keys) do
    {:ok, %__MODULE__{current_id: current, ids: Enum.map(keys, &elem(&1, 0)), keys: Map.new(keys), legacy_plaintext: mode}}
  else
    {:error, {_key, _reason}} = error -> error
    _other -> {:error, {:key_encryption, :invalid_shape}}
  end
end
```

**Legacy boundary excerpt** (`policy.ex`, lines 178-211):

```elixir
def unseal_client_secret_jwt_verifier(encrypted, secret_key_base)
    when is_binary(encrypted) and is_binary(secret_key_base) do
  unseal_client_secret_jwt_verifier(encrypted, secret_key_base: secret_key_base)
end

def unseal_client_secret_jwt_verifier(encrypted, opts) when is_binary(encrypted) and is_list(opts) do
  case Plug.Crypto.decrypt(secret_key_base!(opts), @client_secret_jwt_salt, encrypted) do
    {:ok, secret} when is_binary(secret) and secret != "" -> {:ok, secret}
    _other -> {:error, :invalid_client_secret_jwt_verifier}
  end
end
```

### Credential creation and final identity

**Analogs:** `lib/lockspire/clients.ex` lines 86-105 and registration normalization/persistence; use the existing writer paths rather than introducing another persistence layer.

The current public `rotate_secret_hash/0` derives its pair from `rotate_secret_material/0`; the latter produces a three-key map. Keep both frozen shapes. The hash-only path must stop generating discarded verifier material. For direct registration/DCR choose the final client ID before calling dedicated sealing; operator rotation binds to the existing ID. Persist hash and verifier together through the existing client store/transaction authority, preserving plaintext handoff, lifetimes, and audit behavior.

```elixir
def rotate_secret_hash do
  material = rotate_secret_material()
  {material.client_secret_hash, material.client_secret}
end

def rotate_secret_material(opts \\ []) when is_list(opts) do
  secret = generate_token(@secret_bytes)
  %{client_secret: secret,
    client_secret_hash: Policy.hash_client_secret(secret),
    client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret, opts)}
end
```

### JWT verifier read and protocol boundaries

**Analog:** `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` lines 16-47 and 55-80. Keep the shared verifier policy in this authentication service; endpoint-specific auth-method allowlists remain in endpoint callers. Missing verifier and unavailable verifier already have distinct internal reasons, while outer endpoint responses redact to `invalid_client`.

```elixir
with {:ok, verifier_secret} <- resolve_verifier_secret(client, opts),
     {:ok, allowed_signing_algorithms} <- allowed_signing_algorithms(client, opts),
     {:ok, verified_assertion} <- verify_signature(assertion, verifier_secret, allowed_signing_algorithms),
     :ok <- validate_claims(verified_assertion, client, opts),
     :ok <- record_replay(verified_assertion, client, opts) do
  :ok
else
  {:error, reason} = error ->
    record_failure(reason, client, opts)
    error
end
```

Keep HS256-only, issuer/audience/subject, bounded age, required JTI/replay, lifecycle, and ciphertext-sensitive fingerprint behavior. Preserve positive token exchange, introspection, revocation, device authorization, and CIBA callers; preserve PAR/FAPI rejection.

### Unit, compatibility, and endpoint tests

**Analogs:** `test/lockspire/security/client_secret_verifier_contract_test.exs` lines 1-70; `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` lines 1-45, 50-145, 179-200; `test/lockspire/security/client_secret_verifier_compatibility_test.exs`; `test/integration/client_secret_jwt_legacy_age_test.exs`.

Contract tests use static ledgers, explicit required IDs and assertions to prevent evidence drift; keep Phase 175 source files immutable. The endpoint suite uses `setup`-scoped process stores and real protocol entry points, giving a template for asserting both shipped positive callers and negative method gates. Compatibility and age integration suites are the sources for authenticated historical metadata and deadline boundary fixtures; consume them as qualification inputs, do not rewrite their evidence.

## Shared Patterns

### Safe errors and redaction

**Source:** `lib/lockspire/security/key_encryption/key_set.ex` lines 23-39 and `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` lines 16-47. Configuration validation returns reason codes without raw config; the verifier resolver returns typed internal failure; endpoint auth maps public failures to `invalid_client`. Never include key bytes, plaintext, ciphertext, or assertion material in diagnostics.

### Transaction and identity authority

**Source:** existing `Clients` registration/operator writer paths and `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` store fakes. Continue using the selected client store and transaction store, and choose the final persisted ID before sealing. Hash/verifier pair writes must follow existing atomic persistence conventions.

### Frozen compatibility and evidence

**Source:** `test/lockspire/security/client_secret_verifier_contract_test.exs` and Phase 175 qualification fixtures. Preserve helper arities, legacy overloads, map/tuple shapes, unseal error, accepted historical metadata shapes, and all frozen Phase 175 evidence sources. Phase 177 maintenance and Phase 178 package evidence remain pending.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `test/lockspire/security/client_secret_verifier_test.exs` | test | transform | New dedicated envelope/config behavior has no implementation or suite yet; combine KeySet validation and verifier contract-test conventions. |
| `test/lockspire/security/client_secret_verifier_rollout_test.exs` | test | transform | No existing staged dedicated-key rollout test; use the compatibility test structure and frozen rollout cases. |
| `test/integration/client_secret_verifier_writers_test.exs` | test | CRUD | No equivalent writer integration suite for verifier material; reuse existing client-store integration fixtures and legacy-age suite setup. |

## Metadata

**Analog search scope:** `lib/lockspire/security`, `lib/lockspire/clients.ex`, `lib/lockspire/protocol/client_auth`, `lib/lockspire/protocol`, `test/lockspire/security`, `test/lockspire/protocol`, `test/integration`, `test/support`.  
**Tracked-source check:** all named analogs verified with `git ls-files`; no `.gsd` mirror paths used.  
**Pattern extraction date:** 2026-10-25
