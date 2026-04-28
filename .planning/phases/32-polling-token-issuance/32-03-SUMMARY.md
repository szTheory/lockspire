---
phase: "32"
plan: "03"
subsystem: "auth"
tags: ["oauth", "oidc", "device-flow", "phoenix", "docs", "tdd"]
requires:
  - phase: "32"
    provides: "Device poll outcomes and shared token redemption from plans 32-01 and 32-02"
provides:
  - "HTTP proof for device polling and token redemption on /token"
  - "Truthful discovery metadata and support-contract docs for the shipped device-flow surface"
  - "End-to-end proof from /device/code through host approval to single-use /token redemption"
affects:
  - "Device client integrations"
  - "OIDC discovery consumers"
  - "Phase 32 release-readiness and onboarding posture"
tech-stack:
  added: []
  patterns: ["thin controller wiring", "truthful discovery publication", "generated-host end-to-end proof"]
key-files:
  created:
    - "test/integration/phase32_device_flow_token_exchange_e2e_test.exs"
    - ".planning/phases/32-polling-token-issuance/32-03-SUMMARY.md"
  modified:
    - "lib/lockspire/web/controllers/token_controller.ex"
    - "test/lockspire/web/token_controller_test.exs"
    - "lib/lockspire/protocol/discovery.ex"
    - "test/lockspire/protocol/discovery_test.exs"
    - "test/lockspire/web/discovery_controller_test.exs"
    - "docs/device-flow-host-guide.md"
    - "docs/install-and-onboard.md"
    - "docs/supported-surface.md"
    - "test/lockspire/release_readiness_contract_test.exs"
    - "lib/lockspire/config.ex"
    - "lib/lockspire/protocol/device_authorization.ex"
    - "lib/lockspire/web/controllers/device_authorization_controller.ex"
key-decisions:
  - "Kept /token and /device/code controllers thin by injecting the missing repository/config seams instead of duplicating device-flow logic in web adapters."
  - "Published device grant and device_authorization_endpoint metadata only because the router already mounts both surfaces and the repo now proves them end-to-end."
  - "Derived the generated-host verification URI from the issuer origin and the canonical /verify seam so device clients follow the same host-owned path documented for Phase 31."
patterns-established:
  - "Public support claims for device flow must be pinned by discovery tests, release-readiness assertions, and a generated-host E2E flow in the repo."
  - "Device authorization responses should carry host-verification and polling truth from protocol/config, not placeholder controller defaults."
requirements-completed: ["DEV-07", "DEV-08"]
duration: 8min
completed: 2026-04-28
---

# Phase 32 Plan 03: Polling Token Issuance Summary

**Public device-flow truth across /token, discovery, docs, and generated-host end-to-end redemption proof**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-28T12:22:30Z
- **Completed:** 2026-04-28T12:30:15Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added repo-backed `/token` controller proof for device pending, `slow_down`, success, denied, expired, and replayed polls while keeping the controller thin.
- Published truthful discovery metadata and support docs for the shipped device-flow surface, including the device authorization endpoint, device grant, host-owned `/verify` seam, and polling semantics.
- Added a generated-host end-to-end proof from `POST /device/code` through host approval to one successful `/token` redemption and a replay collapse to `invalid_grant`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Prove the HTTP token-endpoint contract for device polling** - `204b776` (`test`)
2. **Task 1 GREEN: Publish device polling on the token endpoint** - `908530d` (`feat`)
3. **Task 2 RED: Add failing discovery and docs contract specs** - `a38d8e1` (`test`)
4. **Task 2 GREEN: Publish device flow discovery and docs truth** - `69f19e6` (`feat`)
5. **Task 3 RED: Add failing device flow token exchange E2E spec** - `bdcd96d` (`test`)
6. **Task 3 GREEN: Wire device code issuance to the host verification seam** - `b452435` (`feat`)

## Files Created/Modified

- `lib/lockspire/web/controllers/token_controller.ex` - Injects the device authorization store into the shared `/token` controller path.
- `test/lockspire/web/token_controller_test.exs` - Proves the public `/token` device polling contract across success, backpressure, terminal errors, and replay.
- `lib/lockspire/protocol/discovery.ex` - Publishes the device authorization endpoint and device-code grant in truthful discovery metadata.
- `test/lockspire/protocol/discovery_test.exs` and `test/lockspire/web/discovery_controller_test.exs` - Pin the protocol and HTTP discovery document to the shipped device-flow surface.
- `docs/device-flow-host-guide.md`, `docs/install-and-onboard.md`, and `docs/supported-surface.md` - Document the host-owned verification seam, 5-second polling baseline, `slow_down` backoff, and supported device-flow scope.
- `test/lockspire/release_readiness_contract_test.exs` - Locks the updated device-flow docs truth into the release-readiness contract.
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` - Exercises `/lockspire/device/code`, host approval at `/verify`, `/lockspire/token` success, and replay failure.
- `lib/lockspire/config.ex`, `lib/lockspire/protocol/device_authorization.ex`, and `lib/lockspire/web/controllers/device_authorization_controller.ex` - Publish the generated-host `/verify` URI and base poll interval from the device authorization endpoint.

## Decisions Made

- Kept the controller changes limited to missing option injection so the protocol and storage layers remain the only owners of device-flow state and RFC mapping.
- Advertised `device_authorization_endpoint` because `/device/code` is already mounted and now verified with a host-backed end-to-end flow.
- Used the generated-host app as the end-to-end harness so the final proof exercises the real host-owned approval seam instead of repo-only state setup.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Replaced the placeholder device verification URI with the generated host `/verify` seam**
- **Found during:** Task 3 (Add end-to-end proof from host approval to token success and replay failure)
- **Issue:** `POST /device/code` still returned the placeholder `https://example.com/device` URI, which made the shipped device authorization response unusable with the generated host approval flow.
- **Fix:** Added `Config.device_verification_uri/0` and passed the derived host verification URI plus the correct `device_authorization_store` option through `Lockspire.Web.DeviceAuthorizationController`.
- **Files modified:** `lib/lockspire/config.ex`, `lib/lockspire/web/controllers/device_authorization_controller.ex`
- **Verification:** `MIX_ENV=test mix test test/integration/phase32_device_flow_token_exchange_e2e_test.exs`
- **Committed in:** `b452435`

**2. [Rule 2 - Missing Critical] Emitted the durable poll interval in device authorization responses**
- **Found during:** Task 3 (Add end-to-end proof from host approval to token success and replay failure)
- **Issue:** The device authorization success struct and JSON adapter supported `interval`, but the protocol response omitted it, leaving device clients without the documented 5-second polling baseline.
- **Fix:** Populated `Success.interval` from `device_auth.effective_poll_interval_seconds`.
- **Files modified:** `lib/lockspire/protocol/device_authorization.ex`
- **Verification:** `MIX_ENV=test mix test test/integration/phase32_device_flow_token_exchange_e2e_test.exs`
- **Committed in:** `b452435`

---

**Total deviations:** 2 auto-fixed (2 missing critical)
**Impact on plan:** Both fixes were required for the shipped `/device/code` surface to match the new docs and end-to-end proof. No scope creep beyond public device-flow correctness.

## Issues Encountered

- The controller tests initially surfaced a missing `device_authorization_store` injection in the shared `/token` controller path.
- The generated-host E2E flow exposed two latent `/device/code` gaps: a placeholder verification URI and a missing `interval` field.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Device clients now have repo-backed proof for `POST /device/code`, host approval at `/verify`, discovery metadata, and single-use `/token` redemption.
- Public support claims for the device-flow slice are aligned across docs, discovery, controller tests, release-readiness tests, and the generated-host integration harness.

## Self-Check: PASSED

- `.planning/phases/32-polling-token-issuance/32-03-SUMMARY.md` FOUND
- `204b776` FOUND
- `908530d` FOUND
- `a38d8e1` FOUND
- `69f19e6` FOUND
- `bdcd96d` FOUND
- `b452435` FOUND

---
*Phase: 32-polling-token-issuance*
*Completed: 2026-04-28*
