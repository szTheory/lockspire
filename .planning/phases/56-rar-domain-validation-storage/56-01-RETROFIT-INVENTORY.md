# Phase 56 Retrofit Inventory

This inventory tracks the Phase 55 test surfaces that originally asserted raw
`authorization_details` round-trip behavior and therefore needed review once
Phase 56 switched the contract to "validator output replaces raw input" (D-08).

## Retrofit Targets

| File | Evidence | Original Risk | Phase 56 Retrofit |
| --- | --- | --- | --- |
| `test/integration/phase55_rar_intake_e2e_test.exs` | `136`, `185`, `215` | PAR and `/authorize` assertions compared persisted `authorization_details` against the request payload verbatim. | `setup/1` now registers `Lockspire.Test.Rar.PassthroughValidator` for the Phase 55 RAR types so the end-to-end expectations remain truthful without weakening D-08. |
| `test/lockspire/protocol/authorization_request_test.exs` | `895`, `959`, `979` | Validation-path assertions expected decoded details to survive unchanged, even though direct and PAR validation now dispatch through host validators. | Test setup now registers passthrough validators for the exercised types; the PAR normalization case explicitly asserts the validator-expanded payload. |
| `test/lockspire/protocol/pushed_authorization_request_test.exs` | `250-254` | PAR persistence assertion expected the stored request to equal the decoded input payload. | Test setup now registers `Lockspire.Test.Rar.PassthroughValidator` so persisted PAR state still matches the validated output for that scenario. |

## Notes

- `test/lockspire/protocol/authorization_flow_test.exs` continues to assert
  `Interaction.authorization_details` directly because those tests inject
  already-validated `Validated` structs rather than exercising the host-validator
  seam. They were reviewed but did not require a D-08 retrofit.
- The dedicated Phase 56 integration suite (`phase56_rar_validation_storage_e2e`)
  now covers the normalization path explicitly, including PAR short-circuiting,
  unknown-type rejection, persisted consent-grant details, and fingerprint-based
  consent reuse.
