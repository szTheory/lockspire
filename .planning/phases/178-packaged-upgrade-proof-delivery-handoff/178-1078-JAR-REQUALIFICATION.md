# Phase 178 Current 1,078-Input Requalification

This record covers the current selected closure at implementation revision `dda570968cbb14e31dd867a25a33bf349a7ab740`. Prior Plan 10 results, the 1,077-input epoch, and the first 1,078-input attempt remain historical and are not retargeted by this record.

## Accepted Review Scope

- Selected-input digest: `b27ff059ef23fad15550be30e1867ca4411564e791931a6a81cf0a02277f54ba` (1,078 rows).
- Source report: `178-SOURCE-REVIEW-dda5709.md`, SHA-256 `09cbd9ad0ca744445f992491e7a942a9b324ab27d7fae3a2a9932ec09f480afd`.
- Security report: `178-SECURITY-REVIEW-dda5709.md`, SHA-256 `65ffedf878f4b52a9108b71774c2a4a0890f6ace062c1f70dddf04ebd90faf2c`.
- Integration report: `178-INTEGRATION-REVIEW-dda5709.md`, SHA-256 `94d17c7426a60d13d7ec660eec2e31aeaa1d515eaf4ed5e616c67880e5a67f68`.
- Packet: `178-INDEPENDENT-REVIEWS.json`, SHA-256 `43493aacdb2f58fc348da349703f810f56d33f05b1b421e34070015ddedaae80`; each lane covers all 1,078 rows and names implementation revision `dda5709`.
- Native review validation against `dda5709` exited 0 for all three lanes. The authors independently verified the expanded coverage and their judgment records.

## Prior Failed Attempt Preserved

The earlier committed freeze at runner `84c2a1fed14f7fb5128f9aba045cb4a896a3dc00` and candidate source `69f2579c19516fd87ff92c812d952d8743998e05` remains immutable. Its frozen manifest SHA-256 was `25e4290dac5fc48e73a145558a5d1b6de0d22f11703a4c606c5c8b34d315c5e1`; its owner SHA-256 was `04e0613f5b53fb41a004106713d38e6d9909bebe12b80c51fad476a59b0205e5`, archive SHA-256 `c33bbff8f4310fedb577ca76ecd086cd10905be677022f6e6de32d3a035b3d44`, and extracted-tree SHA-256 `048587c5db213ba97b446e38e2e709c339637bc071a5d42e7be7f2308cb3a15a`.

That prior post-freeze native CI run at execution checkout `a3882231779ddb55348fac1f07a5452978722af6` exited 1. The first suite recorded 15 tests / 0 failures; Fast Checks recorded 2,169 tests / 2 failures / 2 properties; the integration stage was not reached. The durable typed manifest did not include failure IDs, so the cause was unconfirmed at that epoch. Its manifest, dispatch, custody, actual CI archive, candidate archive/tree, and canonical prior records are retained under `/private/tmp/lockspire178-a388-exactretain-9ztm_mas`; the origin journal SHA-256 is `6fb0dc2bfad72a8c09492fdf29a18ed1d923377d22d98bfc21f3b357f00616d1`. No acceptance is inferred from that failed run.

The bounded source fix at `dda5709` accepts binary plaintext only for the intended JAR decryption result while preserving error/JWE fallback to later keys. Its focused guard was 91/0, and the source qualification record reports strict formatting, Credo, and static Dialyzer gates passing. The earlier canonical CI failure remains part of the history and is not overwritten.

## Current Gate Status

The current 1,078-input closure is pending a fresh authenticated package freeze, post-freeze canonical guarded CI, fresh locked and floor package profiles, strict composition, and final source/package validators. The 279/0 Python gate at `69f2579` remains historical evidence with unchanged Python inputs; it is not a new post-JAR run. `VPROOF-02`, `VDELIV-01`, and `VDELIV-02` remain pending for this current correction epoch. No hosted result, merge, publication, or phase completion is claimed.
