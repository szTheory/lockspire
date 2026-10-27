# Phase 178 Plan 10 Frozen Evidence Reconciliation

## Frozen owner

- Frozen runner and candidate source: `ec2bb1556499091a305fb7c9458e42a7776fed56`.
- Independent implementation review pin: `24bb9c9f49d228d15c7cbe6ebafd5169fbe78651`. The accepted review reports and packet bind this exact revision and 1,071 selected files. The frozen runner is a later descendant whose complete selected input closure and bytes were checked by the frozen validator; the review pin was not restamped.
- Candidate package: Lockspire `1.6.1`, rebuilt from the committed Git source export by `scripts/ci/provision_verifier_candidate.py` and the delivery owner.
- Candidate archive: `.artifacts/phase178/ci-candidate/lockspire-1.6.1.tar`, SHA-256 `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d`.
- Extracted candidate tree: `.artifacts/phase178/ci-candidate/lockspire`, SHA-256 `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475`.
- Frozen manifest: `178-FROZEN-INPUTS.json`, SHA-256 `ae5cfc65d48d51ac14655f08c28d67ecf9d0ba3c6f8920cee902818a16794919`; it records the complete bounded tracked closure and candidate owner digest `d218ae526198287ed187e1a568de4e73b39d114c1dd51f66d34cd02f888300b9`.
- `verifier_delivery.py --check frozen` passed with all five explicit caller pins. The selected runtime profile for local package pairs is `local-current`; expected BEAM is Elixir `1.19.5`, OTP `28.5`. PostgreSQL server identity is captured independently for each pair owner before its producer groups.

## Reconciliation and preserved attempts

All 13 Phase 175 immutable input hashes were rechecked by the freeze owner. The reviewed Plan 10 implementation bytes remain the accepted `24bb9c9f` review subject; `ec2bb155` is the frozen execution runner after evidence and planning metadata commits, with the closure validator proving reviewed-to-frozen selected-byte equality.

An earlier worktree-built archive at `.artifacts/phase178/final-candidate/lockspire-1.6.1.tar` has a different extracted tree and is not the candidate owner. The frozen source-export rebuild is authoritative; the earlier artifact is retained as a failed provenance attempt. The first unpack attempt also lacked the pinned asdf runtime and is not package evidence.

Before the canonical guarded contributor gate, the preexisting root `lockspire-1.6.1.tar` was preserved outside the repository in `/private/tmp/lockspire-17810-root-archive.UCH7VG/lockspire-1.6.1.tar.original`. Original SHA-256: `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`; original mode: `0644`; size: `560128` bytes. Its private backup is mode `0600`, byte-identical, inside a mode `0700` directory. The root package alias may replace the original during canonical CI; only a byte-verified replacement from this run may be restored afterward.

The other preexisting root `lockspire-*.tar` files were inventoried with their mode, size and digest before the run. `mix.exs` reports package version `1.6.1`, and the canonical alias's `package.build` target is therefore the root `lockspire-1.6.1.tar`. No other root archive is a target of this run.

## Limits

This freeze establishes source/archive/tree and bounded-input identity only. It does not establish installed HTTP/PostgreSQL outcomes, canonical source CI, hosted CI, candidate delivery, integration authorization, main acceptance, or Linux process-identity behavior. The recorded Phase 177 database incidents and Phase 175 unresolved findings remain unchanged and non-waived.
