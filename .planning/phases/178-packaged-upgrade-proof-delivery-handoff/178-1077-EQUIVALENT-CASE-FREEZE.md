# Phase 178 equivalent-case fresh freeze record

A new package archive and extracted tree were built from the accepted source revision and bound to the committed execution runner. This freeze supersedes the historical 19f epoch for current qualification; it does not retroactively repair that epoch’s failed CI run.

- Freeze runner: `6b1fc33cec26560601628c6e44f8c41ac3aa064b`.
- Candidate source: `8a90a0a833a25d5a6b5f6af6525ba818e577df61`.
- Package version: `1.6.1`.
- Selected source rows: 1,077.
- Artifact root: `.artifacts/phase178/refreeze-equivalent-8a90-vfz7yy_8`.
- Archive: `.artifacts/phase178/refreeze-equivalent-8a90-vfz7yy_8/lockspire-1.6.1.tar`, SHA-256 `f6f49878f81adb27493a3de4027b00e14995a13bb79b690b4bbf9c21e9d7423d`.
- Extracted tree: `.artifacts/phase178/refreeze-equivalent-8a90-vfz7yy_8/lockspire`, tree SHA-256 `edef4f97132d62cefa7816ef9daeb8f826bc3a2b5c591e2a8c592a45e453b475`.
- Authenticated candidate owner SHA-256: `b5dc88de4fa124c8b42f198bfa7a92dab43ba66f660b09945acd06c4588a8f39`.
- Frozen manifest SHA-256: `0ca0a43d1d2bb6bc8b73cdcb0076b446e0e04c431c8d61c3d5330c3d08d973a4`.
- The source export, tar unpack, and initial Hex build each exited 0. The helper rebuilt the package from the committed source and the frozen-manifest validator passed for all 1,077 rows before commit.
- The exact previous canonical manifest bytes were retained first as `178-FROZEN-INPUTS-19f8040.json` (SHA-256 `3910155ec76817b44c2e1a6bb185c25c98bdf35595d6442ad1430479e40ec153`).
- The accepted current review packet SHA-256 is `d88b0214f474106291ed67a6a0a50f41876b5e21c66e071f83112b849360686f`. Its source, security, and integration lanes bind the reviewed 1,077-row bytes. The previous 19f packet is retained as `178-INDEPENDENT-REVIEWS-19f8040.json`.

Post-commit frozen validation and the canonical native source CI are required before package profiles. The prior Python 263/0 and the failed 16c CI remain historical evidence with their original source identities. VPROOF-02 remains pending current epoch completion; VDELIV-01 and VDELIV-02 remain pending.
