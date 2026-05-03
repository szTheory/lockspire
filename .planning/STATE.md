---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: milestone
status: completed
stopped_at: Phase 43 complete
last_updated: "2026-05-03T13:05:00Z"
last_activity: 2026-05-03
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 18
  completed_plans: 18
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** Milestone v1.10 wrap-up

## Current Position

Phase: 43 (end-to-end-fapi-2-0-validation-and-release-posture) — COMPLETE
Plan: 7 of 7 completed
Status: Phase complete — ready for milestone wrap-up
Last activity: 2026-05-03 — Verified and completed Phase 43

## Performance Metrics

- Phases completed: 3/3
- Plans completed: 18/18

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions and archived milestones.

- **Phase 41 Plan 01**: security_profile stored as durable Ecto.Enum text column following dpop_policy precedent. Mixed-mode escape hatch (client :none overrides global :fapi_2_0_security) preserved per D-01.
- **Phase 41 SecurityProfile Resolver**: Returns %Resolved{} struct not bare atom, giving callers fapi_2_0_security? boolean flag directly.
- **Phase 41 Plan 02**: policy_fn option in Plug opts used for fail-closed test injection (not meck/mox). /userinfo enforcement is header-shape only (no token decode in Plug). Per-client :none escape hatch (D-01) verified by test G2.
- **Phase 41 Plan 03**: security profile operator workflows stay inside the existing admin LiveView shape, with a visible mixed-mode warning instead of hiding the override semantics.
- **Phase 41 Plan 04**: Phase 41 verification is defined by PAR + DPoP enforcement and mixed-mode proof; algorithm lockdown is deferred to Phase 42.
- Discovery and JWKS metadata now advertise only the algorithms actually supported by the resolved FAPI runtime profile.
- DPoP WWW-Authenticate challenge header derives its acceptable algorithms directly from the validator configuration.
- Exposed check_fapi_signing_readiness in Admin.Clients to allow reuse in protocol layer.
- Aligned FAPI check order in DCR validation to check algorithm before server readiness.
- Exposed check_fapi_signing_readiness in Admin.Clients to allow reuse in protocol layer.
- Aligned FAPI check order in DCR validation to check algorithm before server readiness.
- Consumed canonical algorithm policy across logout token signing, end-session validation, and DPoP proof validation.
- [Phase 43]: Truth-in-docs FAPI language is additive and pinned verbatim across SECURITY, README, and supported-surface docs. — Plan 07 will assert the exact strings, so public release posture must share one locked vocabulary.
- [Phase 43 Plan 01]: RFC 9207 `iss` emission is unconditional across AuthorizationFlow success/denial and AuthorizeController redirect-safe error redirects.
- [Phase 43 Plan 01]: Authorization-response `iss` is sourced from `Lockspire.Config.issuer!/0` in both redirect emission seams to keep runtime truth aligned.
- [Phase 43 Plan 02]: Discovery publishes `require_pushed_authorization_requests` from the global server policy only; per-client FAPI overrides do not change server-wide metadata.
- [Phase 43 Plan 02]: Discovery metadata now shares `global_security_profile/0` so FAPI algorithm publication and PAR-required metadata read the same policy source.
- [Phase 43 Plan 03]: `mix lockspire.oidf_conformance` is a deterministic preflight that validates env, PATH commands, and pinned artifacts without invoking the live suite.
- [Phase 43 Plan 03]: Missing-command and missing-artifact coverage use a narrow Application env override seam so Mix task tests stay local and deterministic.
- [Phase 43 Plan 04]: The install generator now emits one host-owned FAPI smoke test bounded to `/authorize` negative-path proof so host apps get executable FAPI evidence without internal-module coupling.
- [Phase 43 Plan 04]: In the install-generator fixture harness, the generated host FAPI test derives its namespace/path from `scope_module` because `app_module/app_path` still resolve to the library project during render.
- [Phase 43 Plan 06]: Milestone E2E proof now pins exact redirect rejection literals across `/authorize`, `/par`, `/token`, and `/end_session`, plus `iss` emission and discovery-mode truth.
- [Phase 43 Plan 07]: Release-readiness contract now locks the public FAPI 2.0 claim vocabulary and the OIDF plan pin while explicitly preserving the preflight-only, non-`private_key_jwt` runtime posture.

### Blockers/Concerns

- **Manual OIDF Docker run still pending**: `mix lockspire.oidf_conformance --validate-env` now verifies prerequisites, but the live OIDF suite remains a documented manual maintainer step and is not a CI pass-gate.
- **Full-suite regression pass still pending**: targeted Phase 43 regression coverage and the Phase 43 code review gate passed on 2026-05-03, but no full `mix test` sweep has been recorded in `.planning` yet.
- **Pre-existing failures remain tracked** in `.planning/phases/41-fapi-2-0-profile-configuration/deferred-items.md` for follow-up during later FAPI phases as needed.

## Session Continuity

**Next action:** Archive v1.10 milestone or run the live OIDF Docker suite as a manual maintainer check

**Resume file:** None

**Stopped at:** Phase 43 complete

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Planned Phase:** 43 (End-to-End FAPI 2.0 Validation and Release Posture) — 7 plans — 2026-05-02T19:55:49.594Z
ite Prep)
