# Phase 178 Current 1,078-Input JOSE Requalification

This record covers the current selected closure at implementation revision `fefe8a7d948252293d7ffac7b8b20748d070d5bb`. The earlier 1,078-input `dda5709` review/freeze/CI epoch and all 1,077/1,076-input evidence remain historical and unchanged.

## Accepted Review Scope

- Current selected-input digest: `45d60561961df678ec1d4a4b81a1f128b5b89cf117db2a91fcff0b94f8331775` (1,078 rows).
- Source report: `178-SOURCE-REVIEW-fefe8a7-corrected.md`, SHA-256 `497c6860239b358be19dcad181ece33f103f6a9ed36600e62af995494b259855`.
- Security report: `178-SECURITY-REVIEW-fefe8a7.md`, SHA-256 `b217a48698ae5d7e6127ef0691138fc055ee629d693855e96bc4a6e0abf41de9`.
- Integration report: `178-INTEGRATION-REVIEW-fefe8a7.md`, SHA-256 `e3adc839d3e97bfc7d318530aa02abf137d787e9afcb70015ae8cdc820c1a501`.
- Packet: `178-INDEPENDENT-REVIEWS.json`, SHA-256 `e28b8c2b6d27617c898d216fe0c425a60485516099ce9603d6ece77507d2d322`. All three author-verified lanes contain 1,078 rows and name implementation revision `fefe8a7`.
- Native review validation against `fefe8a7` exited 0. A prior source-report variant with out-of-scope paths was rejected and retracted by its author; it was not installed. The corrected author report is the source lane recorded above.

## Prior CI Failure and Narrow Correction

The previous frozen execution at `6f9fb7973c6614b2f615bf4859c5bee9d30fdf6e` had actual canonical suite results 15/0, Fast Checks 2,170/0 with two properties, and Integration 261/1. A bounded observer reproduced the failing `phase133_harness_test.exs` path as the integration harness self-test rejecting a confidential-client manifest pinned to JOSE 1.11.12 while the library requires at least 1.11.13; the exact inner command was not observed. No other root cause is inferred.

The narrow correction pins the confidential-client test dependency and its root lock to JOSE 1.11.13. Source review audited all ten tracked Mix manifests/locks and confirmed the protected Phase 175 lock hashes were unchanged. The actual focused Phase 133 guard passed 5/0 with provider/client dependencies present; 34 owned process groups and private test database OID 20474 were independently absent afterward. The detailed bounded investigation is recorded in `.planning/debug/178-confidential-client-jose.md`. This focused result does not substitute for the current canonical CI.

## Current Gate Status

The current 1,078-input closure still needs a fresh authenticated package freeze, post-freeze canonical guarded CI, fresh locked and floor profiles, strict composition, and final source/package validators. The earlier 279/0 Python gate at `69f2579` remains historical with explicit byte applicability; it is not a new run after these Elixir dependency changes. `VPROOF-02`, `VDELIV-01`, and `VDELIV-02` remain pending for this current correction epoch. No hosted result, merge, publication, or phase completion is claimed.
