Reviewer: Codex security auditor /root/review_178_security  
Date: 2026-10-28  
Disposition: accepted  
Scope: offline collector v4 and unchanged v51 orchestration delta. C50 source acceptance remains unchanged.

**SEC-178-COLLECTOR-VOCABULARY-03 — resolved.** Collector v4 registers the exact `stderr_classification` field, restricts its strings to the source-derived enum vocabulary, and adds inert fixtures covering successful startup, nested PostgreSQL metadata, runtime, owner, matrix, cleanup and coordinator events.

**SEC-178-COLLECTOR-PROJECTION-01 and SEC-178-COLLECTOR-STRUCTURE-02 — remain resolved.** Paths, digests and UUIDs are confined to typed fields and permitted forms. Malformed event values, runs and oversized objects produce failed facts without unsafe dereferences. Original identity candidates are validated before persistence.

The collector retains its coordinator handle and original identity, keeps raw child bytes in RAM, and continues native cleanup after observer-journal write failure. Success requires the selected minimum mode, complete matrix, native receipts and custody results, confirmed dependent cleanup, PostgreSQL shutdown, root removal, successful coordinator exit, valid metadata and collector-owned group closure. Final JSON is written atomically with file fsync/readback before the short terminal summary. Persistence failure cannot report success.

The v51 delta remains limited to fresh minimum receipt/cache paths and the coordinator’s driver path. Wrapper v4 is unchanged. The collector’s named output and identity-journal paths were absent and not symlinks at inspection.

Verified hashes:

| File | SHA256 |
|---|---|
| collector v4 | `98c872a35c63fb9e43ee0ef857759e70c3258abcb0c1bb5b93d1fd5da0a38e97` |
| driver v51 | `2b12861794a38aa89a67618690d58f000fe808dedaecadc43409f3481ed9a5c4` |
| coordinator v51 | `b46c5424a4e250b4e5324b09ec37579cec9a7d9b6ac28a75765b29585f7033f1` |
| child wrapper v4 | `f376e3957fd32c78d3aaaeac9ae7dd6cbe7b2808fd77ad8f1dbe57f355fffb00` |

I inspected the inert fixtures but executed no tests, producers, probes or edits. Reported selftest results remain attributed evidence. This accepts the inspected collector correction, not a future minimum-host result. V1/v2/v3 remain preserved and unlaunched. Run 71794’s final PG/root status and all earlier uncertainties remain unqualified and unwaived.
