# Phase 178 equivalent-case requalification record

This metadata epoch records the accepted review packet for the bounded equivalent-case correction in the qualification-ledger contract test. It does not change the selected source closure or claim new execution evidence.

- Execution implementation HEAD at review validation: `cd1630ccd1872436d13c0a029f0cb5fa07416a82`.
- Reviewed source revision: `8a90a0a833a25d5a6b5f6af6525ba818e577df61`.
- Selected closure: 1,077 sorted rows, digest `f0b319d52ed30e640029ce983283d2fee4809aad9a3addacb1e7dac05aad5900`; all prior 1,076 selected hashes remain unchanged.
- The sole source delta from the previous reviewed source is two insertions and three deletions changing `frozen_section_hash` from `with/else` to equivalent `case` handling. Current source qualification evidence includes Credo 4 failures followed by 0, formatter 0, five equivalence controls passing, and native source guard 26 tests / 0 failures at `8a90a0a833a25d5a6b5f6af6525ba818e577df61` (manifest SHA-256 `43de64d532b136633d7e4041a17ba26c6e7b799b6fa8847336c929571ee81f3c`).
- The accepted independent review packet SHA-256 is `d88b0214f474106291ed67a6a0a50f41876b5e21c66e071f83112b849360686f`; native review validation passed against the implementation HEAD above. Source and integration reports are the authors’ exact report bytes. The security report contains only the author-authorized applicability update, with findings unchanged.
- Prior 1,077-row freeze evidence remains historical under `178-FROZEN-INPUTS-19f8040.json` (manifest SHA-256 `3910155ec76817b44c2e1a6bb185c25c98bdf35595d6442ad1430479e40ec153`, frozen runner `a5c3714cf01a49b96d2a6223ff94e8f6d09fe53f`). Its failed canonical CI witness remains historical: manifest SHA-256 `2103fdcf7bc0b44054be4a29cfa437774940db7fa0b27ad663234da214e63a21`, 15 tests / 0 failures in the first completed section, then CI failure at Credo; it is not current green evidence.
- The prior 263-test Python gate is inherited evidence from its original source identity, not a fresh run for this source epoch. No package profile was run in this epoch before the new freeze.

Current VPROOF-02 qualification remains pending until the newly reviewed source is freshly frozen and the required post-freeze CI and package evidence closes. VDELIV-01 and VDELIV-02 remain pending. Hosted CI, pull request, main-branch, and publication evidence remains outstanding.
