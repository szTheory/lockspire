---
status: fixing
trigger: Current guarded canonical CI at a388 reports two wrong-recipient JWE rejection failures after the JOSE security update.
created: 2026-10-28
updated: 2026-10-28
---

## Current Focus

reasoning_checkpoint:
  hypothesis: Jar.decrypt treats the JOSE error/JWE tuple as successful plaintext because its with-pattern does not require a binary, halting the candidate key loop on a wrong key.
  confirming_evidence:
    - Actual unchanged a388 guarded CI reproduced JarTest line35/assertion49 and EnvelopeSigningConsumersTest line534/assertion541; both are valid ciphertext with the wrong recipient key, not valid decryption fixtures.
    - Published jose1.11.13 package HTTP200 matches the locked outer checksum and all three installed upstream source files; it specifies binary success or error/JWE and preserves the error atom through its Elixir wrapper.
    - Jar.ex line45 accepts either first tuple value and its body immediately returns a successful halt. The bounded library callsite audit found no other block_decrypt caller.
  falsification_test: The unchanged wrong-key negatives or a real wrong-key-before-valid-key positive still fail after requiring binary plaintext at the exact success match.
  fix_rationale: Require the success type declared by the dependency contract; all other outcomes retain the existing fixed error normalization and continue to later keys.
  blind_spots: Hosted and installed-package proof is not performed here. The prior observer classified test locations and seeds, not the dynamic returned atom; the erroneous success value is derived from the confirmed source path.
  candidate_causes:
    - code: Consumer conflates the explicit dependency failure tuple with binary plaintext success.
    - environment: A key fixture or cryptographic configuration might prevent a valid decrypt, but both observed failing cases intentionally use the wrong recipient and the primary package contract explains the shared path.
  and_gate: Yes; the dependency's hardened wrong-key path exposes a pre-existing permissive success pattern in Jar.
next_action: Apply only the binary success guard and real wrong-key-before-valid-key regression, format the two files, commit the narrow scope, then run the two known affected files through the owned source guard.

## Symptoms

expected: Wrong recipient keys return the fixed decryption_failed error, while a later matching key can still decrypt valid ciphertext.
actual: Two invalid-recipient assertions fail in current canonical CI; the source pattern also prematurely halts the key loop on the dependency error sentinel.
errors: Actual observer classified both as assertion_or_unclassified without emitting failure values.
reproduction: Existing guarded native failure at a388 plus one authorized guarded observer; no extra full CI is authorized here.
started: Exposed after the approved JOSE1.11.13 security update; the dependency must not be downgraded or its security behavior waived.

## Evidence

- 2026-10-28: Original current native CI failure remains historical. Observer at exact a388 ran architecture15/0 seed451624; Fast2169/2 with2 properties seed512584; Integration did not run. Native guard exit1, diagnostic harness exit0. Manifest /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-z7pphv9y/manifest.json SHA192bd409a661a13b5a9df0c19da40011da5930c27238510a8a1ad4da5099026b.
- 2026-10-28: All22 observer inner groups absent, owned DB/OID18132 independently absent, controller36423 absent and raw custody released. Source a388 remained clean. Observed CI archive df27c8eb7a8db2c5337849dea4ae01e6f2eef6ad59553c1684bba0fd131344d5 was retained; original5626 archive and protected backup verified/restored.
- 2026-10-28: Primary source https://repo.hex.pm/tarballs/jose-1.11.13.tar SHA15d8bd0f01ab29d1771e8da1f60f9c98725b23a17f7312cdd40e8e2757bd98c7 matches the current lock. Published src/jwe/jose_jwe_alg_rsa.erl, src/jwe/jose_jwe.erl, and lib/jose/jwe.ex exactly match installed source. The RSA wrong-key path substitutes a random CEK; authentication failure remains error; its tuple is converted without changing that first value. Primary verification record /private/tmp/lockspire178-current-ci-observer-u8chc1g8/primary-contract.json. Earlier GitHub/raw web requests failed cache fetch and do not support any contract claim.

## Resolution

root_cause: A failure tuple from the cryptographic dependency satisfies Jar's overly broad success match.
fix: Require binary plaintext in the JOSE result match; keep existing rescue/catch, fixed rejection, telemetry semantics and key continuation.
oracle_type: specified
verification: pending
files_changed:
  - lib/lockspire/protocol/jar.ex
  - test/lockspire/protocol/jar_test.exs
