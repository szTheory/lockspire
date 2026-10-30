# Phase 177: Safe Verifier Maintenance & Recovery - Pattern Map

**Mapped:** 2026-10-25  
**Files analyzed:** 17 proposed files (6 runtime/docs, 6 tests, 5 docs/config)  
**Analogs found:** 17 / 17 (nearest relevant patterns; no exact maintenance implementation exists)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/storage/client_verifier_maintenance.ex` | storage contract | request-response | `lib/lockspire/storage/transaction_store.ex` | role-match |
| `lib/lockspire/admin/client_verifier_maintenance.ex` | service | batch/transform | `lib/lockspire/admin/keys/reencrypt.ex` | role-match |
| `lib/lockspire/security/client_secret_verifier/maintenance.ex` | utility | transform | `lib/lockspire/security/client_secret_verifier.ex` | role-match |
| `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` | storage adapter | CRUD/batch | `lib/lockspire/storage/ecto/repository/client_store.ex` | role-match |
| `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex` | task | request-response | `lib/mix/tasks/lockspire.keys.reencrypt.ex` | role-match |
| `test/lockspire/security/client_secret_verifier_maintenance_test.exs` | test | transform | `test/lockspire/security/client_secret_verifier_test.exs` | role-match |
| `test/lockspire/storage/client_verifier_maintenance_test.exs` | test | CRUD | `test/lockspire/storage/reencrypt_concurrency_test.exs` | partial |
| `test/lockspire/admin/client_verifier_maintenance_test.exs` | test | batch/transform | `test/lockspire/admin/keys_reencrypt_test.exs` | role-match |
| `test/integration/client_secret_verifier_maintenance_test.exs` | test | CRUD/concurrency | `test/lockspire/storage/reencrypt_concurrency_test.exs` | partial |
| `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | test | event-driven | `test/integration/client_secret_verifier_guarded_issuance_test.exs` | partial |
| `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | test | request-response | `test/mix/tasks/lockspire_keys_reencrypt_test.exs` | role-match |
| `docs/client-secret-verifier-configuration.md` | documentation | request-response | existing file | update |
| `docs/client-secret-jwt-host-guide.md` | documentation | request-response | existing file | update |
| `docs/supported-surface.md` | documentation | request-response | existing file | update |
| `lib/lockspire/storage/ecto/client_record.ex` | schema | CRUD | same file | update |
| `lib/lockspire/domain/client.ex` | model | transform | same file | update |
| `lib/lockspire/clients/registration_result.ex` | model | transform | same file | update |

The implementation file list follows 177-RESEARCH.md's Recommended Project Structure. The schema/domain/result and three docs are additional cross-cutting D-20 disclosure/documentation targets. No admin UI redesign is in scope.

## Pattern Assignments

### Storage capability and repository adapter

**Analogs:** `lib/lockspire/storage/transaction_store.ex`, `lib/lockspire/storage/ecto/repository/client_store.ex`

`TransactionStore` exposes a small callback boundary and delegates transaction ownership (lines 4-22):

```elixir
def transact(repo, fun) when is_function(fun, 0) do
  case repo.transaction(fn -> run(repo, fun) end) do
    {:ok, result} -> {:ok, result}
    {:error, reason} -> {:error, reason}
  end
rescue
  error -> {:error, error}
end
```

In `ClientStore`, row mutation occurs inside `TransactionStore.transact`, locks/reloads current state, and routes sensitive reads/writes through `Support` (lines 194-227). `Support` maps `sensitive: true` to both `log: false` and `telemetry_event: nil` (lines 32-48). Copy those structural choices for verifier maintenance, but implement the Phase 175 optional capability/authority contract and verifier-only CAS. Do not reuse `rotate_client_secret/5`: it intentionally updates hash, rotation time, lifetime and `updated_at`.

**Apply:** preflight selected client/lifetime/transaction/audit authorities before inventory; use the selected transaction wrapper per row; lock/reload and compare exact hash + ciphertext; persist ciphertext only and audit in same transaction. Return changed only after the outer transaction returns committed success. Every query binding or returning verifier material must use the sensitive query option.

### Operation/report engine and Mix task

**Analogs:** `lib/lockspire/admin/keys/reencrypt.ex`, `lib/mix/tasks/lockspire.keys.reencrypt.ex`, `lib/lockspire/install/repo_runner.ex`, `lib/lockspire/install/task_error.ex`

The engine keeps classification pure and reports structured outcomes (`reencrypt.ex` lines 85-120); task work returns values and renders only after `TaskError.run` has finished Repo cleanup (`mix/tasks/lockspire.keys.reencrypt.ex` lines 109-150). `RepoRunner` calls an existing Repo in place and starts a temporary one only when absent (`repo_runner.ex` lines 16-37). `TaskError` converts raised/caught failures to fixed safe phrases before the Mix task renders them (`task_error.ex` lines 68-99).

```elixir
case TaskError.run(Lockspire.Config.repo!(), fn _repo -> work(mode) end) do
  {:ok, result} -> finish(mode, result)
  {:error, phrase} -> Mix.raise(phrase)
end
```

```elixir
if is_pid(Process.whereis(repo)) do
  {:ok, fun.(repo)}
else
  start_and_run(repo, fun)
end
```

Use the engine/task boundary, tuple-returning expected failures, strict option parsing, and Repo lifecycle handling. Resolve verifier context operation-locally in bare Mix, include signing-key reuse exclusions, and keep it separate from serving-node persistent startup context. Signing reencrypt has retired-row exemptions and preview behavior that Phase 177 explicitly rejects; do not copy its readiness/exit decisions or scan model.

### Authenticated verifier custody transform

**Analog:** `lib/lockspire/security/client_secret_verifier.ex`

Existing `open/4` validates context and identity, then normalizes unsafe failures (`client_secret_verifier.ex` lines 63-98). The format parser validates bounded ASCII envelope data (lines 257-289), and the decoder distinguishes native from migrated metadata (lines 291-313):

```elixir
defp decode_plaintext(
       <<1, secret_length::unsigned-big-32, secret::binary-size(secret_length), 1,
         signed_at_ms::signed-big-64, deadline_ms::signed-big-64>>
     )
     when secret_length > 0 and secret_length <= @max_identity_or_secret_bytes and
            deadline_ms >= signed_at_ms,
     do: {:ok, secret, {:migrated, signed_at_ms, deadline_ms}}
```

Build maintenance as a separate internal authenticated custody decoder/rewrapper. Verify AEAD AAD/client/purpose and hash agreement before accepting classification; preserve native/migrated discriminator and original migrated timestamps exactly while generating a fresh IV. Keep `open/4` authentication expiry checks intact. Do not implement `open → ordinary seal`, expose plaintext, or accept a public expiry bypass. Legacy promotion must retain the existing finite age qualification.

### PostgreSQL concurrency and issuance evidence

**Analogs:** `test/lockspire/storage/reencrypt_concurrency_test.exs`, `test/integration/client_secret_verifier_guarded_issuance_test.exs`

The persisted concurrency tests use independent tasks, barriers, explicit lock observation and audit counts (`reencrypt_concurrency_test.exs` lines 41-88, 126-165). Guarded issuance asserts a ciphertext change invalidates the authenticated identity, consumes JTI, creates no token/grant effects, and requires a fresh assertion for retry (`client_secret_verifier_guarded_issuance_test.exs` lines 43-82).

```elixir
assert {:error, %TokenExchange.Error{reason_code: :credential_changed}} = result
assert after_guard.jtis == before.jtis + 1
assert after_guard.tokens == before.tokens
assert effects(fixture.client.client_id) == after_guard
assert {:ok, success} = exchange_guarded(fixture, "fresh-assertion")
```

Adapt the explicit barrier pattern to independent PostgreSQL connections, recording blocker/contender relationships. Prove both lock orders, concurrent unrelated edits, audit failure and enclosing rollback, idempotent repeat, partial convergence, bytewise page boundaries, authority rejection before access and a real maintenance-vs-issuance race. Do not treat the guarded test's synthetic mutation as equivalent evidence or use sleep-only assertions.

### Disclosure inspection seams

**Analogs:** `lib/lockspire/storage/ecto/repository/support.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `lib/lockspire/domain/client.ex`, `lib/lockspire/clients/registration_result.ex`

`RegistrationResult` explicitly excludes one-time secret from Inspect (`registration_result.ex` lines 8-14). Add idiomatic Ecto field redaction for verifier ciphertext and safe inspection for domain/nested result structs; this complements, not replaces, sensitive query suppression. `Support`'s two-channel suppression excerpt appears above. Map Postgrex/transaction errors to fixed safe codes before formatting or inspection; `TaskError` is only a caller-process logging layer, not complete disclosure proof.

Sentinel tests should capture plaintext, key bytes and ciphertext across returned params/results, Logger and telemetry, raw storage failures, nested Inspect, audit/report/task output and protocol responses. Include forced crypto/runtime/task/storage failures, missing schema, pool/connection failures and hostile identifiers. Preserve host instrumentation and PostgreSQL server logging boundaries in docs.

## Shared Patterns

### Safe expected failures

**Source:** `lib/lockspire/install/task_error.ex` lines 39-66. Use fixed reason atoms/phrases, allowlist PostgreSQL error codes where useful, and never include raw exception messages, values, query text, or changesets in reports.

### Sensitive persistence

**Source:** `lib/lockspire/storage/ecto/repository/support.ex` lines 32-48. Sensitive queries suppress both Ecto Logger SQL logging and raw result telemetry. Ensure verifier fetch/list/page/lock/update paths all opt in.

### Progress versus readiness

**Source:** `lib/lockspire/admin/keys/reencrypt.ex` lines 25-55 (report lifecycle only; semantics differ). Keep scan completion, committed progress and requested readiness independent. A check is read-only and begins at nil cursor; only complete fresh inventory with all required material current may pass. A resume cursor is progress, not readiness. Do not adopt signing-specific retired exclusions.

### Cursor ordering

**Source:** `lib/lockspire/storage/ecto/repository/client_store.ex` lines 46-55 shows ordinary list ordering is name/client ID, so it is not suitable. New inventory should use the frozen exclusive client-ID cursor and identical explicit `COLLATE "C"` expressions in both comparison and order. Bound page size 1–500, default 100, and test UTF-8 byte boundaries.

## No Analog Found

The exact optional verifier maintenance capability, authenticated expired-migrated custody rewrap, exhaustive client inventory/readiness semantics, and authority-specific verifier-only CAS are new. Use 175-CONTRACT and 177-CONTEXT decisions as the source contract; the analogs above supply implementation mechanics only.

## Metadata

**Analog search scope:** `lib/lockspire/{admin,security,storage,install}`, `lib/mix/tasks`, `test/{lockspire,integration,mix/tasks}`  
**Tracked-source gate:** all cited existing analog paths were confirmed by `git ls-files`; no ignored worktree/install mirror paths are used.  
**Pattern extraction date:** 2026-10-25
