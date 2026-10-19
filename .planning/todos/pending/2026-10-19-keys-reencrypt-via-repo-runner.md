---
created: 2026-10-19T00:00:00Z
title: Route mix lockspire.keys.reencrypt through RepoRunner/TaskError
area: install-dx
files:
  - lib/mix/tasks/lockspire.keys.reencrypt.ex
---

## Problem

Phase 158 moved `client.create`, `doctor token_format` and `doctor remote-jwks` onto `Lockspire.Install.TaskError` + `RepoRunner`. `mix lockspire.keys.reencrypt` still calls raw `Ecto.Migrator.with_repo` (line ~112), so it restarts nothing harmful in a bare `mix` run but would restart/clash with an already-running repo pool and reports failures without the TaskError classifier. Deferred by 158-CONTEXT; the phase goal wording ("every DB-touching task") overpromises until this lands (158-VERIFICATION advisory warning).

## Solution

Wrap its DB work in `TaskError.run/2`, keep its exit semantics, add a pool-untouched check and a cold test, mirroring the doctor tasks.
