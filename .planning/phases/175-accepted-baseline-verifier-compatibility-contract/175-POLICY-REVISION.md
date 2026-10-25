# Phase 175 Native Verifier Age Policy Revision Proposal

**Status: Proposed for owner decision; not approved.** This record makes the remaining D-20 decision concrete. It is evidence and a checkpoint proposal only; it does not authorize production implementation or dependent Phase 176 planning.

## Recommended policy

1. A newly written dedicated client-secret-JWT verifier has no additional Plug storage-age timer. Its use is bounded by the existing authoritative client-secret lifetime check; the client application lifetime remains a separate check. A legacy-v0 client or a configured `nil`/`0` secret lifetime therefore remains unlimited under the existing configured-lifetime contract.
2. Migrated legacy material retains its authenticated original timestamp and finite max age. The original deadline is `signed_at_ms + trunc(max_age_seconds * 1000)`; preserve Plug's observed equality behavior (valid at exact equality, expired only after it). Rewrapping cannot restart the timer.
3. Reject future timestamps, unsupported or malformed metadata shapes, wrong-key/tampered material, and nonpositive/infinite migration ages as unsupported. Do not fall back to another decoder or reset age. Leave such rows unchanged and recover them through an authorized secret rotation/reprovision path.

This intentionally removes the current implicit 24-hour Plug age from *new dedicated* verifier material. For a client whose configured secret lifetime is `nil` or `0`, the verifier may remain usable beyond 24 hours while the client and secret remain otherwise eligible. The qualification found no support for adopting that policy without an explicit owner decision. Plug's `max_age: :infinity` is not a shortcut: it accepts future timestamps, so it is not used for migrated material.

## Evidence

See [175-QUALIFICATION.json](./175-QUALIFICATION.json). Actual persisted `ClientAuth.authenticate/3` cases confirmed that fresh and 23-hour-old default Plug verifiers work, two-day-old and future-dated verifiers fail, configured app/secret deadlines reject at equality, and a v0 unlimited row authenticates. JTI insertion occurs after verifier validation but before client lifecycle eligibility; later inactive/expiry failures consume the JTI. No tested authentication attempt created a token, grant, or audit.

The public authenticated metadata reader passed the same focused suite against root-locked Phoenix 1.8.13 / LiveView 1.2.10 / Plug.Crypto 2.2.1 and the declared floor Phoenix 1.8.5 / LiveView 1.1.28 / Plug.Crypto 2.2.1. It recovered the tuple-three, legacy tuple-two, and Phoenix map payloads and their timestamp units. Hash/verifier disagreement is recorded as migration-not-ready; no per-request hash check was introduced.

## Decision required

Approve or reject this exact native policy before Phase 176 planning. Approval acknowledges the configured-unlimited consequence above and scopes native dedicated storage by configured client-secret lifetime, while preserving migrated finite deadlines and rejecting unsupported rows. If rejected, provide the intended native lifetime semantics and revise the Phase 175 contract before the plan-03 freeze. Until a decision is recorded, `native_age_policy` remains blocked, `dependent_planning` remains `blocked`, and VBASE-02 remains pending.

**No production code, dependency, schema, algorithm, existing authentication default, or Phase 176 plan has been changed by this proposal.**
