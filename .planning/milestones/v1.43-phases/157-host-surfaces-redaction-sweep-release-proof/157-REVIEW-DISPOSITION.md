---
phase: 157-host-surfaces-redaction-sweep-release-proof
review: 157-REVIEW.md
critical: 0
warning: 3
info: 3
---

# Phase 157 — Code Review Disposition

| Finding | Severity | Disposition | Rationale |
|---------|----------|-------------|-----------|
| WR-01 `JOSE.JWT.sign` unguarded after `to_jwk/1`; public-only maps accepted | warning | fixed (`9247292c`) | `PrivateJwk.sign/3` wraps sign+compact with the same no-binding rescue/catch; five signing consumers route through it with their existing error contracts (introspection JWT → `:unsupported_signing_algorithm`, access-token signer → 500 `server_error`, others → `:invalid_signing_key`). `to_jwk/1` rejects maps without a private `d` (oct already refused by `to_public`). Regression tests through every consumer run `KeyMaterialMatcher.refute_leak!` on result and log. |
| WR-02 demo seeds not idempotent (random kids accumulate) | warning | fixed (`657b60b1`) | Key seeding runs only when `Admin.list_keys/0` is empty; still public API, envelope-only. Re-run verified against Postgres: 4 keys, `--check` ready. |
| WR-03 upgrade guide contradicts itself on when key generation is safe | warning | fixed (`65f1ce5b`) | Guide now states generation seals keys once a KEK is configured (any mode) and the real caution is mixed-version/KEK-less nodes during a rolling deploy. Contract test green. |
| IN-01 generator output nondeterministic | info | accepted (no change) | Locked decision D-07: per-install random dev literal and install-date KEK id; tests assert shape and per-run difference. |
| IN-02 demo runtime.exs repeats `demo-1`; non-prod uses public fallback | info | accepted (no change) | Locked decision D-24: demo-only literal in non-prod branch, prod raises; marked demo-only. |
| IN-03 standalone `build_provider.py` KEK not registered with redactor | info | accepted (no change) | Journey path registers the per-run KEK (journey.py:868-870); standalone run produces no evidence scan. Recorded as informational in 157-SECURITY.md. |
