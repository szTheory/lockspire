# Phase 178 current correction requalification: 1,078 selected inputs

This record distinguishes the new correction epoch from the previously accepted 1,077-input epoch. It records review and source-check evidence available at clean implementation checkout `69f2579c19516fd87ff92c812d952d8743998e05`. It does not claim a fresh freeze, canonical CI, or package acceptance.

## Review gate

The current source section digest is `4d2ce48f43ac729200bb6539c79888b79737fd6177ffc6e347211aa2127aaba3` across 1,078 selected rows. The three authors accepted the exact correction and independently verified the expanded lane records:

| Lane | Report SHA-256 | Reviewed rows |
|---|---|---:|
| Source | `e8e9c37d8faf85960d6c613ba9742fb26cfce79c2ee4b92c421ef8026091e22c` | 1,078 |
| Security | `19c4fc8ce441cbf19991ac0f077f4970719cc39c263bb0a5f99c6986a43ea817` | 1,078 |
| Integration | `cad304c24d25f414c129ebdb77f935833812fd5c8c8c7b9e9185d7cb5f35d54a` | 1,078 |

The active packet is `178-INDEPENDENT-REVIEWS.json`, SHA-256 `4d8caaa3904cf431aaba412931360f6102afe9e49768e793d1677a20c5de40ed`. The native `verifier_delivery.py --check reviews --expected-runner 69f2579c19516fd87ff92c812d952d8743998e05` command exited 0. Original reports and the previous packet/freeze/acceptance files remain retained with their original bytes and modes. The private retention journal is `/private/tmp/lockspire178-69f-preserve-o45sb23u/origin-journal.json`, SHA-256 `8d500b607d45f7033b8a1b10d05acb1e3b21c7d6ce2567e668f762575eb2e229`; it records 396 files and 64 directories with no copy hash or mode mismatch.

## Source qualification already observed

The current full Python gate completed at clean checkout `69f2579c` with 279 tests and zero failures; all recorded failure counters were zero. Its terminal capture is `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire178-python-final-69f-ej1rqdkr/terminal.json`; the collector source SHA-256 is `0df252abbd0435584ddc94ab3e94634d997a4dce593bc75ba6ae4704366c1f4e`. The independently scoped cleanup result is separately documented in `.planning/debug/178-src11-early-cleanup.md`; its direct owned-cleanup scope was not certified. Group 4 recorded 13 checks with no failures and all 65 new process groups absent.

This source observation does not substitute for the post-freeze canonical CI. The previous 1,077-input freeze, source gate, CI, package profiles, and composition remain valid only for their own recorded bytes. Current `VPROOF-02` therefore remains pending until a fresh authenticated freeze, canonical CI, and the serial locked/floor profiles plus strict composition pass for this 1,078-input epoch. `VDELIV-01` and `VDELIV-02` remain pending. The published PR #141 head remains `4d512ae2c6a042e2b4557750eca2d49e57fb7189`; this local correction has not been pushed.
