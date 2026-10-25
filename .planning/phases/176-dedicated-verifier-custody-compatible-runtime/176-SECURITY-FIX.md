# Phase 176 Security Fix Record

This record corrects the four independent findings in `176-SECURITY-FINDINGS.md` within the locked Phase 175 configuration, envelope, and lifecycle contract. It does not replace earlier reports or claim Phase 176 security closure.

## Corrections

- **SF01 — canonical application setting:** startup reads only `Application.fetch_env(:lockspire, Lockspire.Security.ClientSecretVerifier)`. Tests prove the internal `Context` key does not activate configuration, and exercise canonical absent, invalid-present, staged legacy, dedicated allow, and dedicated reject states through the startup resolver.
- **SF02 — complete override validation:** a valid Context override must have an exact `key_ids`/`keys` match with unique IDs. Every map entry is converted back through the locked key grammar and checked for ID shape, byte length, duplicate bytes, weak bytes, and startup-known forbidden key reuse. The returned Context contains the newly validated values. Independent AEAD vectors and facade operations reject both unlisted and listed hidden-key material, mismatched sets, malformed IDs, and invalid values.
- **SF03 — improper key-list containment:** improper configuration and `:keys` lists are rejected before keyword traversal or reduction. Startup retains an invalid Context with safe reason codes; verifier operations fail locally with the typed configuration error. The persisted-client integration case confirms Basic/post hash authentication still works.
- **SF04 — authenticated decoded-secret cap:** native and migrated plaintext decoding now require `1..1_048_576` secret bytes. Independent encrypted vectors accept exactly 1 MiB and deny native 1 MiB + 1/+16 and migrated 1 MiB + 1 without returning secret material. The existing decoded-envelope cap remains unchanged, so the migrated +1 vector is rejected by that bound before plaintext decoding.

## Verification

- Focused security/configuration/integration command: 26 tests, 0 failures.
- Final full candidate gate: `mix ci`, exit 0 at tested source `71627f27cdd996cba37122af86a033474e6cd1ff`; exact command and stage results are in `176-SECURITY-FIX-ACCEPTANCE.json`.
- Phase 175 frozen-input manifest: all 13 inputs matched, with 0 mismatches after the final gate.
- Initial failed CI attempts are preserved as logs named in the acceptance record. The successful final run used `ERL_FLAGS='+S 2'` after higher-concurrency attempts encountered PostgreSQL connection exhaustion. It retained the full test selection and race assertions.
- Independent security re-audit is pending. This record makes no claim that the findings are closed by an independent reviewer or that the phase is complete.
