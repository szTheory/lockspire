---
status: complete
completed: 2026-10-20
---
# Shared runner follow-up

keys.reencrypt now uses TaskError.run, which delegates to RepoRunner. Only the computed result reaches finish, preserving existing output and failure semantics. Unknown domain errors use the shared safe classifier rather than incorrectly claiming repo startup failed.

Reproduction: the new startup-exception test failed before the change (23tests/1failure): expected Mix.Error, got raw DBConnection.ConnectionError. After the change:42targeted tests/0failures; broader task/install/reencryption gate171tests/0failures; format check and strict Credo pass. All three running-pool tests passed on the old implementation too: pool preservation is a regression contract, not a reproduced restart failure. Existing cold integration coverage remains in use rather than duplicated.

Security review is inline by the executing agent, not an independent audit. Required PR CI remains the merge gate. This source change is not yet a published package.

## Landing and publication

PR135 merged as170428a7 after all eight checks passed. ReleasePR136 then merged asd04be402; protected run39496849388 published and verified1.6.1, and independent public/fresh-install checks passed. See [release evidence](../../releases/1.6.1-EVIDENCE.md). The earlier awaiting-CI/package statements above describe the pre-merge observation.
