# Phase 176 Initial Security Findings

**Audit source:** Independent `gsd-security-auditor` terminal result `OPEN_THREATS` on 2026-10-25.
**Inspected source:** Candidate `b8cd395dd25ac0918678553aad042e8fd8f05d3c`; metadata HEAD `fc1fba433c8e16f6f9094c66f557680b75e348ec`.
**Result:** 19/22 planned threats closed, three high blocking threats open. No risk acceptance or policy change is selected. Fix the implementation against the already-approved contract.

The initial candidate CI passed its observed tests, but those tests missed the mechanisms below. Preserve that historical result and add source-bound correction evidence; do not present its old passing rows as verification of these missing controls.

## SF-01 — Canonical configuration setting ignored (T-176-04)

`lib/lockspire/application.ex:55` reads the setting under `Lockspire.Security.ClientSecretVerifier.Context`. The frozen contract and published guide configure `Lockspire.Security.ClientSecretVerifier`. An isolated probe using actual compiled modules and Config observed canonical dedicated/reject settings become `:absent/:legacy/:allow`; the identical Context-key setting becomes valid dedicated/reject.

Read only the contracted setting. Add regressions through actual startup resolution for canonical absent, invalid, staged, dedicated/allow and dedicated/reject settings. Correct new tests that use the mistaken module key; do not add a fallback alias that silently preserves the error. Keep a deliberate negative test showing that an internal Context-key setting does not activate custody.

## SF-02 — Complete context can hide an extra unvalidated key (T-176-04)

`lib/lockspire/security/client_secret_verifier/context.ex:98–113` rebuilds configuration only from `key_ids`, then returns the original `keys` map. Config accepts an extra key omitted from `key_ids`, even when its bytes are forbidden; the facade later looks it up and successfully decrypts its envelope.

Require exact agreement between identifiers and the complete key map. Validate all entries and return validated material. Test an independently constructed hidden-key envelope through the actual Config override and facade boundary, including forbidden bytes, extra/missing identifiers, malformed IDs and altered map values. Preserve complete valid struct overrides and immutable startup-known forbidden bytes.

## SF-03 — Malformed key list raises through startup (T-176-06)

`lib/lockspire/security/client_secret_verifier/context.ex:169–187` admits an improper nonempty key list, then enumeration raises `FunctionClauseError`. Actual startup resolution reproduces the raise; it should retain an invalid verifier context and preserve unrelated hash authentication.

Reject improper lists before enumeration and contain malformed validation inputs as safe invalid state. Add canonical-setting startup regressions and affected-operation typed failure assertions. No raw malformed value in diagnostics, no fallback to absence or legacy writes. Preserve unrelated authentication availability.

## SF-04 — Native authenticated reads exceed the exact secret cap (T-176-02)

`lib/lockspire/security/client_secret_verifier.ex:291–304` checks a positive native secret length without the exact 1,048,576-byte maximum. The envelope-wide allowance includes 16 migrated-metadata bytes, so independently authenticated native secrets of 1,048,577 through 1,048,592 bytes open successfully. A 1,048,593-byte secret rejects. This is a bounded 16-byte contract defect, not demonstrated unbounded allocation.

Enforce the exact secret cap when decoding authenticated plaintext, for every age representation. Add independently constructed read vectors at the maximum, maximum+1 and maximum+16, retaining the total envelope cap. Preserve binary-secret compatibility, exact lengths, migrated/native age semantics and fail-closed safe error mapping.

## Existing Closed Controls and Limits

The auditor found concrete evidence for the other 19 planned threats: AAD/AEAD binding and fresh IV/tag checks, redacted errors/inspection, final-ID writers and coherent persistence, hash-only independence, authenticated finite-age preparation, existing lifecycle/transaction/audit behavior, endpoint/replay/fingerprint checks and truthful local rollout/source identity. Recheck affected controls after correction. The 13 frozen Phase 175 inputs match and must remain unchanged.

E02/E14/E15 remain flagged unresolved. Three descriptor-less prohibitions remain flagged-unverified. Phase 177 maintenance/concurrency/full disclosure and Phase 178 packages/delivery remain pending. No new dependency/schema/signing/protocol support is authorized.
