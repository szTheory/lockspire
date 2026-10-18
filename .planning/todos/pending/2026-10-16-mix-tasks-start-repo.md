---
created: 2026-10-16T00:00:00Z
title: DB-touching Mix tasks do not start the repo
area: install-dx
resolves_phase: 158
files:
  - lib/mix/tasks/lockspire.client.create.ex
  - lib/mix/tasks/lockspire.doctor.token_format.ex
  - lib/mix/tasks/lockspire.doctor.remote_jwks.ex
audit_acknowledged:
  milestone: v1.43
  at: 2026-10-16
---

## Problem

Found during Phase 156 research. These tasks declare `@requirements ["app.config"]`, which loads config but starts nothing, then call Admin/Repository functions that need a running Repo. Their tests start `TestRepo` by hand (`test/mix/tasks/lockspire_doctor_token_format_test.exs:10-15`), so the gap is hidden. In a real host they probably fail with "could not lookup Ecto repo". Unconfirmed: verify in a clean-room host first.

## Solution

Follow the `ecto.migrate` pattern that Phase 156 adopts for `mix lockspire.keys.reencrypt`: `Application.ensure_all_started(:ecto_sql)` then `Ecto.Migrator.with_repo(Config.repo!(), fun, mode: :temporary)`. Add a test that runs each task without a pre-started repo.
