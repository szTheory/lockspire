---
status: complete
---
# keys.reencrypt shared repo execution

Route apply, dry-run and check through TaskError/RepoRunner. Preserve committed per-row work, normal summaries, readiness failures, telemetry and temporary cold-repo cleanup. Keep a running repo and connection untouched; classify startup failures without raw exception details. No crypto, protocol, storage-schema or dependency change.

Acceptance: existing cold/exit/telemetry/output tests pass; all three modes preserve a running pool and a temporary connection-local table; a raising repo start becomes a safe Mix.Error. Broader task/install/reencryption tests and required CI must pass before merge.
