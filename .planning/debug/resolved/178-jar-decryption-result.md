---
status: resolved
trigger: Current guarded canonical CI at a388 reports two wrong-recipient JWE rejection failures after the JOSE security update.
created: 2026-10-28
updated: 2026-10-30T19:29:56.936128+00:00
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
next_action: Return the clean local correction for independent delta review, fresh freeze and subsequent current qualification under the orchestrator. No full CI/Python/package proof was run by this correction.

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
- 2026-10-28: Minimal source/test/debug commit9062db51efadf2cf6af963b7e2db3664e041b49b preserves the dependency version, both original negatives, and the unchanged envelope telemetry consumer. The new real RSA-OAEP/A256GCM positive places an incorrect key before the matching key and asserts only a fixed boolean result.
- 2026-10-28: Formatter and strict Credo over the two changed Elixir files both exit0. Pre-exec groups71912 and71931 were recorded; later independent read-only absence checks confirmed both absent. Evidence /private/tmp/lockspire178-jar-checks-2s8ga9jv/terminal.json.
- 2026-10-28: Actual clean-9062 source guard using only test/lockspire/protocol/jar_test.exs and test/lockspire/protocol/envelope_signing_consumers_test.exs, include_integration=true and ci=false:91 tests,0 failures, seed743358, native exit0, no classified failures. Manifest /var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-owned-source-tests-smdwgwgq/manifest.json SHA37169c0621b975ad8e4feac75be7e2a28ee3f5dc5f55ff5a56de0ab51f4186a7. Owned DBb21d032a1a7f48dca5544e2acfd2a9af/OID18538 independently absent; outer PID/PGID/SID72771 absent; source clean and tested bytes unchanged. Tool session50795; private evidence /private/tmp/lockspire178-jar-focused-7jbrorto.
- 2026-10-28: The focused collector's supplemental package_input registration hook observed zero entries because the guard has its own imported factory binding. Its vacuous supplemental boolean is not inner-group evidence. Independent signal-zero absence checks against all24 exact manifest-owned groups plus the2 static-control groups confirmed26 absent,0 present,0 unconfirmed. This correction and the original zero-observation limitation remain in /private/tmp/lockspire178-jar-focused-7jbrorto/independent-cleanup.json; no signal or kill authority was derived from diagnostic JSON.
- 2026-10-28: Exact standalone `bash ./scripts/ci/run_dialyzer.sh`, MIX_ENV=dev, selected ASDF/private HEX, on immutable Git-9062 snapshot /private/tmp/lockspire178-jar-static-du17sjar/source: exit0, Total errors0, skipped0, unnecessary skips0, unknown headers0. All3503 source inputs unchanged; PID/PGID/SID73943 absent; tool session73497. This is standalone static analysis with a private build/PLT/dependency cache and no Repo startup, not canonical mix ci. Evidence /private/tmp/lockspire178-jar-static-du17sjar/terminal.json; reused prior10/10-qualified classifier unchanged.

## Resolution

root_cause: A failure tuple from the cryptographic dependency satisfies Jar's overly broad success match.
fix: Require binary plaintext in the JOSE result match; keep existing rescue/catch, fixed rejection, telemetry semantics and key continuation.
oracle_type: specified
verification:
  pre_edit_native_red: Actual a388 guarded canonical CI and its one observer reproduce the two unchanged wrong-key negatives. The newly added positive was not separately run RED; no new pre-edit timestamp or TDD qualification is claimed.
  target_and_adjacent_tests: {result: pass, tests: 91, failures: 0, seed: 743358, tested_source: 9062db51efadf2cf6af963b7e2db3664e041b49b}
  formatter: {exit_code: 0}
  strict_credo: {exit_code: 0}
  standalone_dev_dialyzer: {exit_code: 0, warnings: 0, unknown_headers: 0, source_inputs_unchanged: 3503}
  mutation_and_revert_control: No additional source mutation/revert execution was performed. Existing pre-edit failing negatives and post-edit same-file positives provide the observed before/after evidence; the explicit later-key positive adds regression coverage without claiming an executed counterfactual.
  review_status: Independent source/security/integration delta judgment remains pending; this record does not self-close reviews or historical proof.
  limits: Original a388 failed freeze remains historical; current full CI/Python/installed/hosted proof and fresh canonical freeze remain pending. No remote action, full matrix or additional canonical CI was performed here.
files_changed:
  - lib/lockspire/protocol/jar.ex
  - test/lockspire/protocol/jar_test.exs


## Closeout reconciliation — 2026-10-30

The original `awaiting_human_verify` checkpoint above is superseded for the implemented fix by the later independent source/integration/security review of the complete selected closure, the final declared-threat assessment, actual current/minimum installed-package receipts and accepted main `dc3969302152028e2132759eb9edf5a7d260ac39`. See [closeout reconciliation](../../milestones/v1.48-CLOSEOUT-RECONCILIATION.md), [final phase verification](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-VERIFICATION.md), and [actual main acceptance](../../phases/178-packaged-upgrade-proof-delivery-handoff/178-POSTMERGE-ACCEPTANCE.md).

The native acceptance suite was rerun at this unchanged main during closeout: 301 tests passed, exit 0, owned group closed; [safe result](../../milestones/v1.48-CLOSEOUT-PYTHON.json). These later observations satisfy the earlier review/qualification follow-up for the current correction. For the installed-recovery journal, the later root diagnosis owns the `:inets` cause and subsequent fixture corrections; the original diagnostic-only entry did not establish that cause.

This resolves the current debugging work, not unknown predicates or custody from earlier failed runs. Original diagnostic/TDD limits, unknown historical closures, failed attempts, retained resources and formal PARTIAL/Nyquist-false flags remain unchanged. No historical run is restamped, no unknown process is stopped, and no new database/package/application proof, integration or publication is authorized.

Original checkpoint SHA-256: `d7aa73242563d765a313d319627acdffd3c42a3be9332ef5c29a109f94711942`. The body above remains unchanged; only its leading lifecycle status/updated date and this reconciliation changed.
