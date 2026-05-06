---
phase: "30"
plan: "01"
subsystem: "storage"
tags: ["device-authorization", "ecto", "domain"]
dependency_graph:
  requires: []
  provides:
    - "Lockspire.Domain.DeviceAuthorization"
    - "Lockspire.Storage.DeviceAuthorizationStore"
    - "Lockspire.Storage.Ecto.DeviceAuthorizationRecord"
  affects:
    - "Lockspire.Storage.Ecto.Repository"
tech_stack:
  added: []
  patterns: ["Ecto Schema", "Behaviour", "TDD"]
key_files:
  created:
    - "lib/lockspire/domain/device_authorization.ex"
    - "lib/lockspire/storage/device_authorization_store.ex"
    - "lib/lockspire/storage/ecto/device_authorization_record.ex"
    - "priv/repo/migrations/20260427210707_create_lockspire_device_authorizations.exs"
    - "test/lockspire/domain/device_authorization_test.exs"
    - "test/lockspire/storage/ecto/repository_device_authorization_test.exs"
  modified:
    - "lib/lockspire/storage/ecto/repository.ex"
key_decisions:
  - "Storage of pending device codes uses SHA256 hashing to prevent exposure of bearer tokens on DB leak."
  - "A strict TTL of 300 seconds (5 minutes) is enforced at the domain level and supported by the database."
metrics:
  duration_minutes: 30
  completed_date: "2026-04-27"
---

# Phase 30 Plan 01: Core Device Authorization Endpoint & Storage Summary

**One-liner:** Implemented core domain modeling and Ecto storage with hashed unique records for the OAuth 2.0 Device Authorization flow.

## Task Breakdown

- **Task 1: Core Domain and Store Behaviour** - Created `Lockspire.Domain.DeviceAuthorization` struct and constructor with hashing and TTL. Defined `Lockspire.Storage.DeviceAuthorizationStore` behaviour.
- **Task 2: Schema and Migrations** - Generated migration and created `Lockspire.Storage.Ecto.DeviceAuthorizationRecord` with unique constraints on hashes.
- **Task 3: Repository Implementation** - Implemented `put_device_authorization/1` on `Lockspire.Storage.Ecto.Repository` passing structs to Ecto schemas.

## Deviations from Plan

None - plan executed exactly as written and all tests passed.

## Self-Check: PASSED
- `lib/lockspire/domain/device_authorization.ex` FOUND
- `lib/lockspire/storage/device_authorization_store.ex` FOUND
- `lib/lockspire/storage/ecto/device_authorization_record.ex` FOUND
- `test/lockspire/domain/device_authorization_test.exs` FOUND
- `test/lockspire/storage/ecto/repository_device_authorization_test.exs` FOUND
- `00ebdea` FOUND
- `ab766dd` FOUND
- `255e712` FOUND
- `95de4c5` FOUND
- `206f23e` FOUND