---
phase: 72
plan: 01
title: Persist encrypted-JARM client metadata and validate DCR/RFC 7592 truthfully
status: complete
commits:
  - 7ddf64d
  - e198fe6
key_files:
  - priv/repo/migrations/20260508000000_add_authorization_response_encryption_fields_to_lockspire_clients.exs
  - lib/lockspire/domain/client.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - test/lockspire/storage/ecto/client_record_test.exs
  - test/lockspire/protocol/registration_test.exs
  - test/lockspire/protocol/registration_management_test.exs
requirements-completed: [JARM-03]
---

# Phase 72 Plan 01 Summary

Persisted encrypted-JARM client metadata and made Dynamic Client Registration plus RFC 7592 reject incoherent authorization-response encryption metadata instead of accepting or degrading it.

## Delivered

- Added durable client fields and migration for `authorization_encrypted_response_alg` and `authorization_encrypted_response_enc`.
- Extended `Lockspire.Domain.Client` and `Lockspire.Storage.Ecto.ClientRecord` so create, update, and `to_domain/1` all carry the encrypted-JARM fields.
- Narrowed persisted encrypted-JARM metadata to the Phase 72 allow-list:
  - `alg`: `RSA-OAEP-256`, `ECDH-ES`
  - `enc`: `A256GCM`, `A128GCM`
- Updated DCR and registration-management validation so encrypted JARM now requires:
  - both encryption metadata fields
  - signing metadata via `authorization_signed_response_alg`
  - either inline `jwks` or guarded `jwks_uri`
  - existing `jwks` xor `jwks_uri` behavior
- Threaded `authorization_signed_response_alg`, `authorization_encrypted_response_alg`, and `authorization_encrypted_response_enc` through both registration persistence paths.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Missing critical functionality] Persisted `authorization_signed_response_alg` in DCR and RFC 7592 flows.
- Found during: Task 2
- Issue: encrypted-JARM validation could not be truthful because registration/update flows did not store the signing metadata they were supposed to depend on.
- Fix: added signing-metadata persistence alongside the new encrypted-response fields in `persist_client/5` and `apply_metadata_to_client/2`.
- Commit: `e198fe6`

## Verification

Exact commands run:

```bash
mix test.setup
mix test test/lockspire/storage/ecto/client_record_test.exs
mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs
mix test test/lockspire/storage/ecto/client_record_test.exs && mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs
```

Results:

- `mix test.setup`: migrated `20260508000000_add_authorization_response_encryption_fields_to_lockspire_clients`
- `mix test test/lockspire/storage/ecto/client_record_test.exs`: `13 tests, 0 failures`
- `mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs`: `63 tests, 0 failures`
- Final combined rerun of the exact focused commands: both commands passed again with the same results

## Self-Check

PASSED

- Summary file exists.
- Both task commits exist: `7ddf64d`, `e198fe6`.
- Required migration, domain, storage, and protocol files are present and modified for this plan.
