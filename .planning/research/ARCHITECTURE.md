# v1.23 Research: Architecture

## Existing Integration Points

- `lib/lockspire/protocol/registration.ex`
  - currently rejects all DCR logout propagation metadata as `unsupported_in_slice`
  - owns intake validation and initial client persistence
- `lib/lockspire/protocol/registration_management.ex`
  - already reuses the same validator for RFC 7592 updates
  - currently does not map logout propagation metadata back onto the updated client
- `lib/lockspire/web/registration_json.ex`
  - currently omits most stored client metadata fields from DCR read/update responses
- `docs/supported-surface.md`, `docs/dynamic-registration.md`, `docs/operator-admin.md`
  - currently describe logout propagation metadata as unsupported via DCR
- integration and protocol tests under `test/integration` and `test/lockspire/protocol`
  - already cover DCR lifecycle and logout propagation separately

## Suggested Build Order

1. Narrow the supported metadata contract for the four logout propagation fields.
2. Update intake validation in `Registration` to allow and validate those fields.
3. Update RFC 7592 management update mapping so read/update responses reflect stored values.
4. Update JSON rendering so DCR responses expose the new metadata truthfully.
5. Add protocol, controller, and integration coverage for create/read/update negative and positive paths.
6. Update support docs and admin/operator wording to reflect the new self-service boundary.

## Boundary Decisions

- `core`: DCR intake, RFC 7592 management, domain persistence, JSON rendering, tests, docs.
- `defer`: any expansion beyond the existing four metadata fields.
- `defer`: any change to logout execution semantics.
- `defer`: any new package boundary or companion surface.

## Proof Posture

- Merge-blocking proof should be repo-native ExUnit coverage for registration create/read/update and logout propagation reuse.
- Advisory proof can stay limited to existing logout propagation runtime tests; no external conformance lane is required for this milestone.

## Support Truth

- Missing metadata remains valid; logout propagation metadata stays optional.
- Back-channel remains the reliable path.
- Front-channel remains best effort only.
- Hosts still own their RP endpoints; Lockspire only stores and later uses the registered metadata.
