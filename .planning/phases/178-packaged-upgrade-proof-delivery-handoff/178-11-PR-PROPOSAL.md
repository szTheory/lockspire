# Proposed corrected v1.48 milestone PR update

This is a concrete local proposal. It does not authorize or perform a remote update.

- Repository/PR: `szTheory/lockspire`, [#141](https://github.com/szTheory/lockspire/pull/141), open, non-draft, unmerged.
- Title: `feat: isolate and rotate client authentication verifiers (v1.48)`.
- Source branch: `milestone/v1.48-client-auth-key-isolation`; target: `main`.
- Latest read-only observed published head: `33db5483bc5aa06b4a51d2742e90fb8616cad7c2`.
- Latest read-only observed base/main: `173059a166e9ade0f5f57c9980b7b2400a98538c`.
- GitHub-reported synthetic merge metadata: `70afa2a31df5d85549678008dbfeb106993126ec`; actual job checkout is not proven by this object.
- Reviewed package source: `50d67751a7844dee2f5f595195a6ab455e313fc6`; 1,079 covered inputs, digest `b869b5c3e7a6642e5dcd30d7ceaae766a6dea992fb698c5af6c4c0f4a0b3b28f`.
- Frozen and actual proof runner: `1757638a7770bb6f09c3b085f002fa7c8b7ed518`.
- Local evidence commit: `7d8306d1e7c1a7ebdfc8a2aa75ce9dea09af164c`. The final publication SHA is a later metadata-only commit; its exact full SHA is recorded outside this file to avoid self-reference.
- Package: 1.6.1; archive `d52efdb25c429cf2e1c93c97f3cd103629a87219e3f94e0af593464b9477f524`; extracted tree `dff904b4fa0515126f47a4477109eaf5237a97b0ec1e07291a8879450d80f4db`.

Native root review/frozen/source/package validation passed. Canonical source CI is 2,456/0 plus two properties; lifetime composition is 47 checks/nine scenarios; verifier composition is 26 receipts/64 cases; installed current/minimum hosts are 96 scenarios. These retain their original execution identities. The complete native package/host record is `178-11-CORRECTED-NATIVE-PACKAGE-HOST-EVIDENCE-50d6775.json` at SHA-256 `d13de4726529878af72145f334018ae0b12972c55a9cc7a38e00fb486f00aba3`. The independent metadata review found no material inconsistency.

Prior canonical failures remain unexplained. Current84579 outer PG cleanup is an attributed terminal fact with original PG-token/full-event retention unavailable. Earlier minimum71794 final PG/root status stays UNKNOWN and unpromoted; accepted fresh minimum9307 has durable terminal cleanup evidence. Every earlier incident, retraction, E-09/E-10 and generic/descriptorless flag remains unwaived. The protected root user archive is unchanged. Full prior proposal bytes are retained in [178-11-PR-PROPOSAL-BEFORE-C50-H175.md](178-11-PR-PROPOSAL-BEFORE-C50-H175.md), SHA-256 `ede7f38c1feea57d0afc93a7b33e087da0ff378387d30c440677e3934c84af5d`; its old identities are historical.

## Exact proposed body

Private reviewable body: `/private/tmp/lockspire178-pr141-C50-final-local-delivery-v1/pr-body.md` (mode 0600).

Body SHA-256: `eaf0ad6a6f6d8b6733356af2ec799da59a8506e743296bbd0f2acd8c4fa90fe3`.

The exact body below is already fully prepared. Its source/lifetime evidence link points to `ad456f7f7370254fb5beebe98cad323b352af273`, and its package/host evidence link points to `7d8306d1e7c1a7ebdfc8a2aa75ce9dea09af164c`. Both commits are local until the authorized update is pushed.

---

## Summary

Give embedded Phoenix hosts dedicated, rotatable encryption keys for client-secret-JWT verifier material. The host retains accounts, login, branding and product policy. Existing client-secret hashes, authenticated lifetimes and one-time secret delivery remain intact.

```text
verifier custody: legacy readers -> dedicated writer -> explicit legacy rejection
maintenance: check -> preview/apply rewrap -> fresh check
recovery: restore retained key or deliberately rotate the partner credential
```

The v1.48 milestone includes reader-first upgrades, mixed-key operation, guarded rotation and issuance, redacted maintenance/recovery tools, and installed-package proof. Follow-up fixes authenticate packaged-source ownership in CI, enable the supervised admin listener, normalize audit database errors and validate client creation before application startup. Dedicated-key validation checks configured and operation-supplied host keys; the cached context stays immutable. CI preserves prepared dependency caches and failure-time timing evidence; no measured speedup is claimed.

Disclosure proof now measures tagged controls independently and attributes events to the operation process and phase. Sensitive reads may emit zero query events. Broad leak scanning and forced-failure, classification, HTTP, storage, audit, ciphertext, CLI and redaction checks remain required. Current receipts require the finite attribution version; historical validation is explicit and non-authoritative.

## Evidence

- **Before:** Published head `33db5483`, CI run `40696973463`: four required jobs passed, Integration and Minimum failed, and Coverage was skipped. Required verifier pair artifacts were absent. Independent review rejected the old disclosure-attribution counters; their earlier local pass remains historical.
  **After:** Three author reviews accept corrected source `50d67751` with 1,079 selected inputs. Python acceptance 289/0, clean-room 48/0 and handler ExUnit 1/0 ran at clean `7dbb1667`; only Credo policy differs at C50, where strict Credo/format/diff checks pass. Execution identities and existing resource warnings remain recorded.
- **Canonical source CI:** Checkout `1757638a` passed architecture 15/0, Fast 2,180/0 with two properties and Integration 261/0: 2,456 tests, zero failures. Three earlier canonical failures remain unexplained; the pass does not diagnose them.
- **Installed lifetime proof:** Three journeys passed; native composition validated 47 checks across nine scenarios, zero failures/skips. Independent recomposition reproduced both retained output hashes.
- **Verifier pairs:** Locked 14 receipts/33 cases and floor 12/31 passed. Native strict composition and independent root validation passed 26 receipts/64 cases with zero failures.
- **Installed current/minimum hosts:** All 16 required scenarios passed at `/lockspire`, `/teams/ops/identity` and `/` on actual Elixir 1.19.5/OTP 28.5 and Elixir 1.18.4/OTP 27.3.4.15: 96 scenarios total. Native receipt/owner checks and original child-journal audits passed. These are local installed proofs, including the dependency-floor pair.
- **Attributable records:** [source/lifetime evidence](https://github.com/szTheory/lockspire/blob/ad456f7f7370254fb5beebe98cad323b352af273/.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-11-CORRECTED-NATIVE-SOURCE-LIFETIME-EVIDENCE-50d6775.json) and [corrected package/host evidence](https://github.com/szTheory/lockspire/blob/7d8306d1e7c1a7ebdfc8a2aa75ce9dea09af164c/.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-11-CORRECTED-NATIVE-PACKAGE-HOST-EVIDENCE-50d6775.json) retain source/runner/package identities, native validation, failed attempts, retractions and custody limitations. The current-run outer PG token/full terminal event was not retained; its shutdown/root removal are attributed terminal facts. Earlier incomplete minimum-run PG/root closure remains unknown; the accepted fresh minimum run has durable terminal cleanup evidence.

The corrected candidate has no hosted result yet. Required hosted gates, milestone audit and main/delivery acceptance remain pending. Earlier incidents, E-09/E-10 and generic/descriptorless flags retain their recorded status. No passing hosted graph or main acceptance is claimed.

## Merge Danger

**Door:** One-way after dedicated writes or retirement of required keys.

Follow the reader-first rollout and documented rollback limits. Retain required keys and backups until the host establishes fleet and recovery readiness. Key retirement remains the host's separate decision.

**Blast Radius:** Authentication.

Verifier configuration, migration, maintenance and recovery affect existing client authentication. The library stays embedded; this correction adds no protocol flow or runtime dependency.

---

## Exact publication boundary

Private publication plan: `/private/tmp/lockspire178-pr141-C50-final-local-delivery-v1/publication-plan.json`. It records the final full publication SHA, body path/hash and latest remote preconditions after the proposal commit exists. It is not part of the commit it identifies.

1. Recheck read-only that PR 141 is open/non-draft/unmerged, both its head and remote source ref equal `33db5483bc5aa06b4a51d2742e90fb8616cad7c2`, and main/base remain `173059a166e9ade0f5f57c9980b7b2400a98538c`. Check the exact proposed commit is a non-force descendant of the published source ref. If these preconditions change, revise the proposal before mutation.
2. Only after explicit approval covering both actions, non-force push the exact full SHA in the private plan to `refs/heads/milestone/v1.48-client-auth-key-isolation`.
3. Read-only verify the exact remote/PR head, then replace PR 141's body with the exact file above. Preserve its hash; do not silently alter the approved text.
4. Do not rerun/dispatch workflows, comment, submit/request reviews, merge, release or publish a package under this proposed approval. Naturally triggered hosted CI must be observed separately. No passing hosted graph or merge approval is implied.

The old exact-head approval was consumed by the `33db5483` update; see [the publication checkpoint](178-11-EXECUTION-CHECKPOINT.md). VPROOF-02 is locally qualified. VDELIV-01 still needs a compatible passing seven-job hosted graph and milestone audit; VDELIV-02 still needs main/delivery acceptance. Plan 11 remains incomplete, Plan 12 unstarted and Phase 178 in progress. No new remote action has occurred.
