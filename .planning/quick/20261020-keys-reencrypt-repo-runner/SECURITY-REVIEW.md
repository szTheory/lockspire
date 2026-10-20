# Security review — keys.reencrypt shared runner

Scope: the task execution-wrapper diff and the existing TaskError/RepoRunner call paths. Reviewed inline after implementation, with no code edits during review. No actionable findings.

The entry point is a host operator's local Mix task, with unchanged strict mode parsing. At lib/mix/tasks/lockspire.keys.reencrypt.ex:109–124 each mode reaches the same Keys domain function as before; the wrapper neither selects a different repo nor changes key material or write policy. No public HTTP/authentication surface or new privilege is added (spoofing/elevation).

At line110 the shared guard suppresses caller-process SQL debug/info logging and maps raised work failures to safe fixed phrases; line112 raises only that phrase. At line150 unknown returned errors pass through TaskError.classify. The existing domain-authored missing/invalid KEK and storage messages at lines137–148 remain unchanged. The guard does not promise to suppress logs emitted by separate DB connection processes (information disclosure boundary).

RepoRunner uses an already-registered repo directly and starts stopped repos temporarily. The three mode tests retain the same pool pid and connection-local table; cold tests prove temporary cleanup. Startup exceptions become fixed Mix errors (availability). Per-row locks/CAS, durable audit and completed telemetry remain in the unchanged domain functions (tampering/repudiation). Existing partial-success and check-event tests pass.

Out of scope: full key cipher/storage re-audit, protocol endpoints, host authorization, unpaged dry-run cost, independent review. Public output redaction and failure semantics are covered by the existing reencryption integration suite. No new web input flow requires an OWASP web pass.
