Reviewer: Codex security auditor /root/review_178_security
Date: 2026-10-28
Disposition: rejected
Scope: external installed-admin orchestration helpers for C50/H1757638a. The accepted C50 source review is unchanged.

Three corrections are required before retry:

1. **Medium — SEC-178-ADMIN-OBSERVER-01: wrong module instrumented.** Child wrapper v1 imports and patches `clean_room.package_input` at lines 37–41 and 76–77. The native admin entry instead imports top-level `package_input` after adding its directory to `sys.path` (`clean_room_admin_journey.py:24–40` at H1757638a). These are distinct module names and registries. Native execution therefore bypasses the observer callbacks, allowing a valid native receipt while the wrapper records no identities or journal and rejects its marker. This is a concrete static defect consistent with the reported result; I have not independently established the runtime cause. Instrument the actual imported module and assert shared function/module identity in an inert fixture exercising the real import entry.

2. **High — SEC-178-ADMIN-CUSTODY-02: fallible publication after launch.** Wrapper v1 starts the owned process at line 49, writes the journal at line 59, and only then stores its original identity locally at line 60. A journal failure loses the wrapper’s handle before returning it to the journey. Its exception path subsequently checks absence but performs no final owned stop (`:82–93`). This callback defect is currently latent behind the module mismatch; activating it without correction would expose the gap. Retain the original process handle and token before fallible observer work. A post-launch observer failure must either establish owned shutdown or preserve custody and resources without presenting “no process” to native cleanup.

3. **High — SEC-178-ADMIN-RETENTION-03: exceptional matrix exit bypasses retention.** Driver v47 initializes `setup_cleanup_confirmed=True` at line 1059, then updates it from `inner_closed` only after `installed_admin_matrix` returns (`:1249–1253`). An exception or interruption before that return leaves cleanup enabled. Its `finally` can remove the cluster directory at `:1656–1661` without confirmed inner closure. Set this boundary to unconfirmed before entering the matrix; enable removal only after validated closure. Exercise exception/interruption paths after child launch, including missing journal and unsuccessful stop.

The normal entry has useful safeguards: exact C/H and frozen pins are checked through the native manifest validator; PostgreSQL readiness verifies the owned data directory, loopback address and selected port before installed-owner capture or journeys; generated URLs are checked against that private endpoint. Current/minimum runtime selection checks Elixir, OTP major and exact OTP patch. Owner capture uses native selected-owner validation. Child and validator commands inherit the explicitly selected Python through `sys.executable`. Current/minimum matrices select three mounts each and require full native receipts plus separate custody evidence.

The reported v47 run 95249 is correctly rejected: a passing 16-scenario native receipt cannot substitute for the missing independent inner journal. Outer process closure does not prove inner closure. I performed no runtime, database or process probes.

Reviewed helper hashes, unchanged across inspection:

| Helper | SHA256 |
|---|---|
| coordinator v47 | `268242d028d0b10b44e55124e2228e6d581c8ebe8e4faccc6afe977c70997102` |
| driver v47 | `32d36126f5d70d4bf24468b9d7e3d58b4f2533c14c915166b4e66f4bb4552fb6` |
| native matrix v3 | `8b1960c61046bac6a8bb0672c160fa1a07d2e01603bc93d66960fe2547adc776` |
| child wrapper v1 | `8bbe566dbcdfef99300f7c03330da4a463e99af552dc83f0cab736c37bdbdb35` |

I also verified incident-ledger SHA `fca866a2e44d660882afd0a37c898e63d812a22013ef7f089a9de72ee2bfdbef`. The accidental v46 fixture retains database contact/mutation UNKNOWN and unavailable original pre-exec journal. Its preserved artifacts are not authority. The 61450 preproducer failure remains separately recorded. Earlier incidents, E-09/E-10, historical review corrections and custody uncertainties remain unwaived. This advisory neither changes C50 source acceptance nor establishes installed-host qualification.
