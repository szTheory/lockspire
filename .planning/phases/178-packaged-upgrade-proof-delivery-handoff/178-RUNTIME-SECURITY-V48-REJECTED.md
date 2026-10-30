Reviewer: Codex security auditor /root/review_178_security
Date: 2026-10-28
Disposition: rejected
Scope: offline v48 orchestration candidates; C50 source acceptance remains unchanged.

**SEC-178-ADMIN-OBSERVER-01 — resolved.** Wrapper v2 instruments the actual top-level `package_input` imported by the native journey (`:36–38`). This corrects the module mismatch.

**SEC-178-ADMIN-RETENTION-03 — resolved for dependent data/root retention.** Driver v48 sets cleanup confirmation false before entering the installed matrix and restores it only after confirmed inner closure (`:1249–1256`). Exceptional matrix exits therefore retain the cluster directory.

**SEC-178-ADMIN-CUSTODY-02 — remains high and requires correction.** Wrapper v2 retains the returned process before observer work (`:50–54`), but journal failure still raises before returning that handle to the native journey (`:69–75`). At host startup, native assignment consequently remains `process=None`. Native `stop_owned(None)` returns true, allowing its `finally` to drop the database and remove the run root before wrapper v2’s later cleanup runs. Retaining the handle and stopping it afterward does not correct this ordering.

The correction must ensure post-launch observer failure cannot present a false “no process” state to native cleanup. Establish owned absence before propagating failure, or make native cleanup consult every retained handle and block dependent deletion when closure is uncertain. Store the raw identity before fallible token serialization as well. An inert actual-entry regression should inject journal failure specifically after host creation and verify cleanup ordering, including unsuccessful stop.

My earlier statement requiring PostgreSQL itself to remain running was too broad. The mandatory boundary concerns database/data/root deletion. The independently owned private PostgreSQL process may be stopped through its original identity while its data directory is retained. Report that as **outer-only shutdown**, with inner closure still UNKNOWN. It cannot establish successful overall cleanup. A stronger policy preserving the running backend would additionally require an owner handoff because native `atexit` also stops registered sessions.

For reported run 95249, PostgreSQL shutdown and temporary-root retention are separate observations; neither supplies the missing inner proof. No new runtime cause or closure conclusion is inferred.

Reviewed candidate hashes:

| Helper | SHA256 |
|---|---|
| coordinator v48 | `5bb0037a0a83da15552c14b30338466f3564c11f0b2762d54714b2355ca2a5c4` |
| driver v48 | `2ae9e5ae54878a6ee9823688b76c3be136f749e9fad865cab40414bdc69b98b5` |
| child wrapper v2 | `12a01588a4039ad50261f00fa4e475ff7dcc060799efecc74cf76706e4a137a3` |

No runtime tests, database probes or edits were performed. Prior incidents and uncertainties remain unwaived.
