# Phase 175 Native Verifier Age Policy Revision Proposal

**Status: Approved owner policy revision (2026-10-25).** This record makes the D-20 decision concrete. The original discussion recommendation remains preserved in `175-CONTEXT.md`; this approval authorizes the documented policy disposition for planning qualification only. It does not authorize production implementation, Phase 176 planning before the material gate passes, publication, deployment, or cleanup.

## Owner approval

- **Source:** Explicit owner response received by the Phase 175 execution orchestrator on 2026-10-25.
- **Exact response:** “Approve the recommended revision”
- **Approved scope:** The native dedicated verifier follows the authoritative configured client-secret lifetime, with client-app expiry remaining a separate check; `nil`/`0` and v0-unlimited lifetimes may extend beyond 24 hours. Migrated legacy material preserves its authenticated original finite deadline and Plug's strict-after-expiry/equality-valid behavior. Future, malformed, tampered, wrong-key, unsupported-shape, and unbounded migration-age inputs remain rejected unchanged with authorized rotation/reprovision recovery.
- **Limits:** No algorithm, dependency, schema, or other authentication default changes. This records policy authority; it does not implement or publish the runtime behavior.

## Recommended policy

1. A newly written dedicated client-secret-JWT verifier has no additional Plug storage-age timer. Its use is bounded by the existing authoritative client-secret lifetime check; the client application lifetime remains a separate check. A legacy-v0 client or a configured `nil`/`0` secret lifetime therefore remains unlimited under the existing configured-lifetime contract.
2. Migrated legacy material retains its authenticated original timestamp and finite max age. The original deadline is `signed_at_ms + trunc(max_age_seconds * 1000)`; preserve Plug's observed equality behavior (valid at exact equality, expired only after it). Rewrapping cannot restart the timer.
3. Reject future timestamps, unsupported or malformed metadata shapes, wrong-key/tampered material, and nonpositive/infinite migration ages as unsupported. Do not fall back to another decoder or reset age. Leave such rows unchanged and recover them through an authorized secret rotation/reprovision path.

This intentionally removes the current implicit 24-hour Plug age from *new dedicated* verifier material. For a client whose configured secret lifetime is `nil` or `0`, the verifier may remain usable beyond 24 hours while the client and secret remain otherwise eligible. The qualification found no support for adopting that policy without an explicit owner decision. Plug's `max_age: :infinity` is not a shortcut: it accepts future timestamps, so it is not used for migrated material.

## Evidence

See [175-QUALIFICATION.json](./175-QUALIFICATION.json). Actual persisted `ClientAuth.authenticate/3` cases confirmed that fresh and 23-hour-old default Plug verifiers work, two-day-old and future-dated verifiers fail, configured app/secret deadlines reject at equality, and a v0 unlimited row authenticates. JTI insertion occurs after verifier validation but before client lifecycle eligibility; later inactive/expiry failures consume the JTI. No tested authentication attempt created a token, grant, or audit.

The public authenticated metadata reader passed the same focused suite against root-locked Phoenix 1.8.13 / LiveView 1.2.10 / Plug.Crypto 2.2.1 and the declared floor Phoenix 1.8.5 / LiveView 1.1.28 / Plug.Crypto 2.2.1. It recovered the tuple-three, legacy tuple-two, and Phoenix map payloads and their timestamp units. Hash/verifier disagreement is recorded as migration-not-ready; no per-request hash check was introduced.

## Decision recorded

The owner approved this exact native policy on 2026-10-25 with the response recorded above. The configured-unlimited consequence is acknowledged. This resolves the policy authority question for the approved revision; `native_age_policy` and `dependent_planning` may be marked ready only after the literal Plan 175-02 Task 03 material-gate verification passes. VBASE-02 remains pending until its later contract-freeze requirements are completed.

**No production code, dependency, schema, algorithm, existing authentication default, or Phase 176 plan has been changed by this proposal.**
