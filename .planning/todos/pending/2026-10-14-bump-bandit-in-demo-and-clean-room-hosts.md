---
created: 2026-10-14T00:00:00Z
title: Bump Bandit in demo and clean-room hosts after the fix ships
area: deps
files:
  - examples/adoption_demo/mix.exs
  - examples/adoption_demo/mix.lock
  - test/clean_room/provider_host/mix.exs
  - test/clean_room/confidential_client/mix.exs
audit_acknowledged:
  milestone: v1.42
  at: 2026-10-15
---

## Problem

EEF-CVE-2026-105659 (GHSA-69m6-wcv4-rwcf) affects Bandit 1.4.0 through 1.12.5. When it was published, the fix existed only as a git commit (d88b2195) and no patched version was on Hex.

Lockspire no longer depends on Bandit, so the library's `mix.lock` and `mix deps.audit` are clean. The local-only host apps still use 1.12.5: the adoption demo and the clean-room harness hosts. CI does not audit their lock files.

## Solution

When Bandit releases a version after 1.12.5:

- Bump the adoption demo's lock file.
- Update the `== 1.12.5` pins in both clean-room host `mix.exs` files.
