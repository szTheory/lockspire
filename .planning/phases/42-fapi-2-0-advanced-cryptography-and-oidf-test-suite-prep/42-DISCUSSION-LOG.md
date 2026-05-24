# Phase 42 Discussion Log

**Date:** 2026-05-01
**Mode:** Interactive discuss with parallel advisor-style subagent research
**Outcome:** Locked recommendations captured in `42-CONTEXT.md`

## User Direction

- Discuss all identified gray areas.
- Use subagents to research tradeoffs, ecosystem lessons, idiomatic Elixir/Phoenix/Ecto patterns,
  and successful libraries/systems in adjacent ecosystems.
- Favor one-shot, cohesive recommendations over repeated user decisions.
- Bias future project planning toward opinionated defaults unless a choice is unusually impactful.

## Areas Discussed

### 1. Algorithm Enforcement Surface

**Question:** Under the FAPI profile, should Lockspire limit algorithm enforcement to edge
validators or treat it as a profile-wide contract across owned signing, verification, key
selection, publication, and metadata?

**Options considered:**
- Edge-only validation
- Accept+emit enforcement with permissive storage
- Profile-wide cryptographic contract

**Selected direction:** Profile-wide cryptographic contract, with migration ergonomics borrowed
from permissive-storage rollout.

**Why it was chosen:**
- Fits Lockspire’s macro-policy model from Phase 41
- Matches the repo’s truth-from-runtime pattern
- Avoids the footgun where Lockspire claims FAPI posture but still emits or advertises `RS256`
- Produces the cleanest OIDF/conformance story

**Repo evidence that influenced the choice:**
- `lib/lockspire/protocol/security_profile.ex`
- `lib/lockspire/protocol/dpop.ex`
- `lib/lockspire/protocol/discovery.ex`
- `lib/lockspire/protocol/logout_token.ex`
- `lib/lockspire/protocol/end_session.ex`

### 2. Key and Rejection Policy

**Question:** Should incompatible keys/client metadata be rejected early at write boundaries or
stored durably and rejected only at runtime?

**Options considered:**
- Effective-profile fail-fast rejection at write boundaries
- Durable tolerance with runtime-only rejection
- Quarantine model

**Selected direction:** Effective-profile fail-fast rejection at write/activation boundaries, with
runtime checks retained as defense in depth.

**Why it was chosen:**
- Produces calmer operator UX because errors appear where the bad configuration is introduced
- Keeps durable/admin/discovery state truthful for FAPI-effective paths
- Avoids a second compatibility state machine
- Preserves mixed-mode by allowing legacy rows to remain under `:none` without letting them leak
  into FAPI runtime behavior

**Repo evidence that influenced the choice:**
- `lib/lockspire/admin/keys.ex`
- `lib/lockspire/security/policy.ex`
- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md`

### 3. OIDF Prep Depth

**Question:** Should Phase 42 stop at manual OIDF setup docs or add repo-native executable
conformance harness wiring now?

**Options considered:**
- Manual docs only
- Repo-native harness/preflight/wiring now, proof later
- Full executable conformance gate in Phase 42

**Selected direction:** Add repo-native harness/preflight/wiring now, while deferring full
end-to-end proof and release-gate closure to Phase 43.

**Why it was chosen:**
- Matches Lockspire’s executable-docs and release-truth pattern
- Keeps Phase 43 focused on validation instead of bootstrap work
- Avoids premature certification/support claims
- Improves maintainer DX without collapsing the roadmap boundary

**Repo evidence that influenced the choice:**
- `docs/maintainer-conformance.md`
- `scripts/conformance/fapi2-check.sh`
- `.github/workflows/oidf-conformance.yml`
- `test/lockspire/release_readiness_contract_test.exs`

## External Lessons Folded Into The Recommendation

- Mature auth systems do better when profile enforcement is centralized rather than spread across
  per-endpoint conditionals.
- Truthful metadata and docs matter as much as runtime checks; drift between them is a recurring
  ecosystem footgun.
- Early validation beats runtime surprises for operator-facing auth tooling.
- Executable conformance workflows are materially better than prose-only setup instructions for
  security-sensitive libraries.

## Final Locked Defaults

- FAPI mode is a Lockspire-wide cryptographic contract for owned JWT surfaces.
- The Phase 42 supported FAPI signing set is `ES256` and `PS256` only.
- Legacy non-FAPI rows may remain durable, but cannot be used/published/activated for FAPI.
- Validation should fail fast at write boundaries and stay enforced at runtime.
- OIDF harness wiring belongs in Phase 42; full proof and public closure belong in Phase 43.
- Downstream planning should be opinionated by default unless a decision materially changes
  product posture, support claims, or migration risk.
