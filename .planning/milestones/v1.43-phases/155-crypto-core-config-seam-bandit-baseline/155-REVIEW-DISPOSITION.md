---
phase: 155-crypto-core-config-seam-bandit-baseline
review: 155-REVIEW.md
critical: 0
warning: 2
info: 3
---

# Phase 155 — Code Review Disposition

| Finding | Severity | Disposition | Rationale |
|---------|----------|-------------|-----------|
| WR-01 `legacy_plaintext: :reject` accepted but not enforced at read | warning | deferred → Phase 156 (MIG-03) | Enforcement is scoped to 156-02 by the approved roadmap; no release ships between 155 and 156 (same v1.43 milestone), so no host can rely on the interim state. Verify/doctor reporting the configured mode is accurate config truth. |
| WR-02 boot cache vs fresh env can diverge; cache-miss raise swallowed to `:invalid_signing_key` | warning | no change (by design, D-05) | Runtime config is read once at boot; changing app env after boot is unsupported. Verify/doctor run as separate `app.config` processes and must validate fresh. The decoder deliberately never raises into protocol paths (SAFE-01); boot already fails on invalid config, so a cache miss only occurs before boot. Failure-reason logging lands with OPS-02 telemetry in 156. |
| IN-01 decode failure reason discarded, never logged | info | deferred → Phase 156 (OPS-02) | `decode_with_reason/1` already exposes the reason; 156-02 adds refusal/decrypt-failure telemetry and audit with ids and reason atoms only. |
| IN-02 base64 padding leniency / trailing newline generic error | info | open (low) | Decoded length must still be exactly 32 bytes, so leniency cannot weaken key strength; revisit error wording with `mix lockspire.gen.kek` (KEK-03). |
| IN-03 clean-room provider hardcodes a KEK | info | deferred → Phase 157 (HOST-01) | Test-only acceptance fixture; 157's generator emits an env-var-sourced KEK, never a literal. Carry this note into 157 planning. |
