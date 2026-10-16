# Roadmap: Lockspire

## Milestones

- 🚧 **v1.43 Signing Key Encryption at Rest** — Phases 155–157 (in progress; closes CR-01; no OAuth/OIDC behavior change).
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Direction

v1.43 closes CR-01: private signing JWKs stored as plaintext in `private_jwk_encrypted`. Every newly generated key is sealed as an AES-256-GCM envelope (OTP `:crypto`, no new dependency, no schema migration) under a host-supplied, rotatable key-encryption key (KEK) configured in `runtime.exs`. Existing installs upgrade without breaking: legacy rows stay readable, an idempotent re-encryption task migrates them, and an opt-in `legacy_plaintext: :reject` mode refuses plaintext once `--check` passes. The Bandit 1.13.1 CVE bump in the demo and clean-room hosts lands first, on its own. Resolved decisions R1–R8 in [the research summary](research/v1.43-key-encryption/SUMMARY.md) are binding design input. SAFE-01 (no new deps, no migration, no column rename, no decrypted-key cache, no protocol change, security defaults preserved) constrains every phase.

## Phases

<details open>
<summary>🚧 v1.43 Signing Key Encryption at Rest (Phases 155–157)</summary>

- [x] **Phase 155: Crypto Core, Config Seam & Bandit Baseline** — Hosts are on Bandit 1.13.1; new signing keys are written only as KEK-sealed envelopes and every signer reads them.
- [x] **Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal** — Operators can encrypt legacy rows, rotate the KEK, verify readiness and switch on plaintext refusal safely.
- [x] **Phase 157: Host Surfaces, Redaction Sweep & Release Proof** — Fresh installs, demo and clean-room hosts ship encrypted by default, nothing leaks, and CI plus docs prove the upgrade end to end.

</details>

<details>
<summary>✅ v1.42 Admin UI Clarity & Workflow Refinement (Phases 151–154) — completed 2026-10-15</summary>

- [x] Phase 151: Focused Client Registration & Settings (2/2 plans) — its own registration route, focused app task pages, and a primary/secondary/danger action rule.
- [x] Phase 152: Overview & Queue State Clarity (5/5 plans) — overview counts open exact read-only queue subsets, with hedged reuse and sign-out evidence.
- [x] Phase 153: Configure & Support Page Refinement (7/7 plans) — plain language and clear page hierarchy across all 30 admin paths.
- [x] Phase 154: Responsive, Theme & Route Proof (7/7 plans) — contrast, focus and layout fixes with redaction-safe evidence across 7 widths and 3 themes.

**Audit:** [v1.42 milestone audit](milestones/v1.42-MILESTONE-AUDIT.md) — 9/9 requirements, no gaps; bounded UI polish and pre-existing debt accepted.

</details>

<details>
<summary>✅ v1.41 Product Language & Repository Clarity (Phases 148–150) — completed 2026-10-11</summary>

- [x] Phase 148: User-Facing Admin Language (7/7 plans) — task-centered copy that preserves OAuth/OIDC meaning and truthful outcomes.
- [x] Phase 149: Repository Ownership and Lifecycle (1/1 plan) — lifecycle map and evidence-backed preservation decisions.
- [x] Phase 150: Adopter and Maintainer Documentation (2/2 plans) — canonical adoption path and task-grouped HexDocs.

**Audit:** [v1.41 milestone audit](milestones/v1.41-MILESTONE-AUDIT.md) — no requirement or integration gaps; bounded maintenance debt accepted.

</details>

## v1.43 Signing Key Encryption at Rest

**Cross-cutting constraint (SAFE-01, every phase):** no new Hex dependencies; no schema migration; no rename of `private_jwk_encrypted`; no decrypted-key caching (`KeyCache` stays public-JWK only); no OAuth/OIDC behavior change; PKCE S256, exact redirect matching, hashed client secrets, single-use short-lived codes, refresh rotation with family revocation, no implicit flow, no `alg=none`, and strong redaction preserved. No KEK in compile-time config, no `secret_key_base` fallback. Each phase's verification checks this; Phase 157 owns the final proof. No new admin UI copy (R5), so no phase needs a UI design contract.

### Phase 155: Crypto Core, Config Seam & Bandit Baseline

**Goal**: The demo and clean-room hosts run green on Bandit 1.13.1, and from then on a host with a configured KEK writes every new private signing key only as a sealed envelope that every signing and decrypting consumer reads, while hosts without a KEK keep booting and signing with existing keys.
**Depends on**: Nothing (first phase of v1.43).
**Requirements**: DEP-01, KEK-01, KEK-02, ENC-01, ENC-02, ENC-03
**Success Criteria** (what must be TRUE):
  1. The adoption demo and both clean-room hosts are pinned to Bandit `== 1.13.1` (with `thousand_island` and `hpax` updated) and their end-to-end checks pass in a commit that precedes any encryption change.
  2. A host with a valid `:key_encryption` block generates a key and the stored `private_jwk_encrypted` value starts with the `LSK\x01` envelope header for the current KEK id; ID tokens, logout tokens, JARM, introspection JWTs, token exchange and JAR decryption all work from that row with unchanged protocol responses.
  3. Each invalid config case (bad base64, wrong length, duplicate id or material, unknown `current`, unknown mode, `:reject` without keys) stops boot with an error naming the config key and never containing the value.
  4. With no `:key_encryption` config, the app boots, existing legacy keys keep signing, `generate_key` returns `{:error, :key_encryption_not_configured}` without writing a row, and a boot warning, the doctor and `Install.Verify` each report the missing KEK.
  5. Tests reject tampered ciphertext, a ciphertext swapped between rows, an unconfigured KEK id and a truncated tag (all surfacing as `:invalid_signing_key`), and a property test shows random binaries and legacy JSON/ETF never classify as envelopes; JWKS and discovery never decrypt.

**Pitfalls owned**: C1 prefix ambiguity (strict prefix dispatch, no fall-through); C2 row swap (AAD binds header and `kid`, plus post-decrypt `kid` check); C3 nonce reuse (fresh 12-byte IV per seal); C9 KEK in compile-time config (runtime only, `:persistent_term` struct with redacted `Inspect`); C10 plaintext test fixtures (shared seeding helpers seal).
**Research flags**: 155-01 — read the Bandit 1.12.x → 1.13.1 changelog and deprecated endpoint options (not 1.13.0). 155-02 — prototype `:crypto.crypto_one_time_aead/7` tag-mismatch and wrong-size behavior on the CI OTP before fixing the open/error contract.
**Suggested plans** (original roadmapper split; superseded by the 5 plans below — see 155-CONTEXT.md):
- 155-01: Bandit 1.13.1 bump in `examples/adoption_demo`, both `test/clean_room/*` hosts and the compatibility fixture lock; green on its own (DEP-01).
- 155-02: `Lockspire.Security.KeyEncryption` (seal/open/classify, takes a resolved key set, never reads app env); `Config.key_encryption!/0` validation per R1/R8; boot validation and missing-config warning in `Application.start/2`; fixed test KEKs in `config/test.exs`; tamper/swap/unknown-KEK/short-tag tests and the classify property test (KEK-01, ENC-03).
- 155-03: `Admin.Keys.generate_key/1` seals or refuses; map-form-only `PrivateJwk.decode` (remove `decode/1`) across the six read sites; distinct internal reasons collapsed to `:invalid_signing_key`; `seeding_helpers.ex` and `token_exchange_case.ex` seal; `@derive {Inspect, except: [:private_jwk_encrypted]}` on `SigningKey` and `SigningKeyRecord`; minimal doctor and `Install.Verify` KEK-presence check (KEK-02, ENC-01, ENC-02).

**SAFE-01 constraint**: no protocol response changes, no new deps, no migration; verify `KeyCache` holds no private material.
**Plans**: 5/5 plans complete

Plans:
**Wave 1**
- [x] 155-01-PLAN.md — Bandit 1.13.1 + mint 1.11.0 in demo and clean-room hosts, compat lock pruned (DEP-01; wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 155-02-PLAN.md — KeyEncryption cipher + KeySet, `Config.key_encryption!/0`, boot validate/cache/warn, test KEKs, ENC-03 tests (KEK-01, ENC-03; wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 155-03-PLAN.md — map-form `PrivateJwk.decode` across the six consumers, per-consumer error shapes, JWKS/discovery fitness guard (ENC-02; wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 155-04-PLAN.md — `generate_key` seal-or-refuse + clean-room KEK (one commit), sealed shared seeders (ENC-01, KEK-02, ENC-02; wave 4)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 155-05-PLAN.md — `Install.Verify` `:key_encryption` check, `mix lockspire.doctor key_encryption`, Inspect derives, phase gate (KEK-02, ENC-01; wave 5)

### Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal

**Goal**: An operator can move an existing install from plaintext rows to fully encrypted storage, rotate the KEK without reissuing signing keys, prove readiness, and turn on plaintext refusal without stranding a key, with every step audited and observable through ids and counts only.
**Depends on**: Phase 155 (envelope format, KEK set, map-form decoder and sealing test helpers).
**Requirements**: MIG-01, MIG-02, MIG-03, OPS-01, OPS-02
**Success Criteria** (what must be TRUE):
  1. `mix lockspire.keys.reencrypt` and `Lockspire.Admin.Keys.reencrypt/1` (callable on a running node via `bin/app rpc`; the Mix task covers a stopped VM) encrypt every legacy row, including retired and `use: :enc` rows; `--dry-run` changes nothing; output reports scanned, encrypted, already current and failed-by-`kid`; a second run and two concurrent runs both finish with no double-wrap and no lost row.
  2. `--check` exits non-zero while any legacy or old-KEK row remains and zero once none do; every key the task can re-encrypt blocks it until re-encrypted, whatever its status, and retired keys that cannot be re-encrypted are listed as stranded and do not block it; the doctor `key_encryption` check reports row counts per KEK id and legacy rows.
  3. Under `legacy_plaintext: :reject`, a non-envelope row fails signing with `:invalid_signing_key` (internally `:plaintext_key_refused`) without the legacy parsers running, while envelope rows keep signing.
  4. An operator adds a new `current` KEK, re-encrypts, sees zero rows on the old id, removes the old key and keeps signing with the same `kid`s; the matrix of legacy, old-KEK and new-KEK rows against each current key passes.
  5. Encrypt and re-wrap write durable audit records and telemetry; legacy-read, refusal and decryption-failure emit telemetry only (no durable write on the signing path and no audit mirror); all carry only `kid`, KEK id, counts and reason atoms.

**Pitfalls owned**: C4 KEK loss or mismatch (distinct reasons, per-KEK-id doctor counts, `:unknown_kek`); C5 rolling-deploy ordering (no generation mid-rollout; reject only after `--check`); C6 concurrent re-encrypt races (`SELECT … FOR UPDATE`, re-classify after lock, round-trip verify, CAS on only the ciphertext column and `updated_at`); C7 strict mode too early (`--check` and doctor gate, no boot-time DB scan per R3).
**Research flags**: 156-01 — lock and CAS semantics against existing `signing_key_store` transactions (activate, retire, `publish_key` upserts) before choosing batch size and isolation. 156-02 is a standard pattern; match existing telemetry/audit naming.
**Suggested plans**:
- 156-01: Re-encryption engine shared by legacy migration and KEK rotation; `SigningKeyStore` per-row locked-transaction callback plus repository delegate; `mix lockspire.keys.reencrypt` with `--dry-run` and `--check`; concurrency and rotation-matrix tests (MIG-01, OPS-01, `--check` half of MIG-02).
- 156-02: `:reject` refusal in the decoder; `Keys.encryption_status/0`; doctor `key_encryption` check and `Install.Verify` extension; per-row `key_encrypted`/`key_rewrapped` audit; telemetry for legacy reads, refusals and decrypt failures (MIG-02, MIG-03, OPS-02).

**SAFE-01 constraint**: re-encryption updates only the existing column (no migration, no `kek_id` column); refusal is opt-in, so default protocol behavior is unchanged; no decrypt-to-plaintext path.
**Plans**: 3/3 plans complete

Plans:
**Wave 1**
- [x] 156-01-PLAN.md — Re-encryption engine: `KeyStore` per-row lock/CAS callbacks, `PrivateJwk.read_stored/2`, `Admin.Keys.reencrypt/1` with dry-run, durable audit and operator telemetry; rotation-matrix and real-concurrency tests (MIG-01, OPS-01, OPS-02)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 156-02-PLAN.md — Readiness and CLI: `Admin.Keys.encryption_status/0`, `mix lockspire.keys.reencrypt [--dry-run | --check]`, doctor row counts, `Install.Verify` `:key_storage` check (MIG-01, MIG-02, OPS-01)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 156-03-PLAN.md — `:reject` refusal, hot-path telemetry and deduplicated logging, sentinel leak test, ROADMAP/REQUIREMENTS wording fixes, phase gate (MIG-03, OPS-02)

### Phase 157: Host Surfaces, Redaction Sweep & Release Proof

**Goal**: A fresh install, the adoption demo and the clean-room provider host store only envelopes by default; no private key material, ciphertext or KEK value is visible anywhere an operator or log reader looks; and CI plus docs prove the full upgrade path so the release can ship and CR-01 can close.
**Depends on**: Phase 156 (re-encrypt, `--check`, doctor and `:reject` must exist before the generator defaults to `:reject` and the upgrade proof can run).
**Requirements**: RED-01, HOST-01, PROOF-01, DOC-01, SAFE-01
**Success Criteria** (what must be TRUE):
  1. `mix lockspire.install` emits a `runtime.exs` `:key_encryption` block reading the KEK from an environment variable with `legacy_plaintext: :reject`; the adoption demo seeds and the clean-room provider host boot with a demo/test KEK and store envelopes.
  2. Logs, telemetry, audit records, `inspect` of `SigningKey`, `SigningKeyRecord` and the KEK set, changeset errors, admin pages and LiveView assigns contain no private JWK members, envelope ciphertext or KEK value, and `Lockspire.Redaction` covers the new fields in atom and string forms.
  3. CI signs end to end from encrypted rows for ID token, logout token, JARM, introspection JWT, token exchange and JAR, asserts every stored `private_jwk_encrypted` begins with the envelope prefix and holds no plaintext `d`/`k`, and runs the upgrade path plaintext rows → re-encrypt → `--check` → `:reject`.
  4. Docs give the four-step upgrade order, KEK rotation runbook, backup-remanence and rollback warnings and separate KEK backup guidance; `docs/code-walkthrough.md`, `docs/architecture.md` and SECURITY.md describe envelope storage, and release-note text is ready for the squash title.
  5. The SAFE-01 gate passes: no new Hex deps, no migration, no column rename, no decrypted-key cache, and the existing security-default and protocol suites pass unchanged.

**Pitfalls owned**: C8 leakage via `Inspect`, changesets, logs, telemetry, admin HTML and crash dumps (full sweep; document crash-dump hygiene rather than `Process.flag(:sensitive, true)`); final closure of C5/C7 in docs (do not generate keys mid-rollout; rollback to pre-1.43 breaks signing once rows are encrypted).
**Research flags**: none (standard patterns). Close plan-time gaps: residual app-env exposure of the raw KEK (document; `{:system, "ENV"}` is KEK-05) and whether LiveDashboard's environment page could display app env.
**Suggested plans**:
- 157-01: Redaction sweep and `Lockspire.Redaction` additions with leak tests across logs, telemetry, audit, changesets, admin HTML and assigns (RED-01).
- 157-02: Install generator snippet, demo seeds via the public API, clean-room provider host KEK, demo compose documents a demo-only KEK (HOST-01).
- 157-03: End-to-end signing proof, no-plaintext DB assertion, upgrade-path and rotation proof in CI; SAFE-01 gate (PROOF-01, SAFE-01).
- 157-04: Upgrade and rotation docs, warnings, architecture/walkthrough/SECURITY updates, release-note text (DOC-01). Split candidate if the phase overruns (R7).

**SAFE-01 constraint**: owns the final SAFE-01 proof for the whole milestone; no new admin copy (KEY-UI-01 deferred), so PRODUCT.md vocabulary is unchanged.
**Plans**: 6/6 plans complete

Plans:
**Wave 1**
- [x] 157-01-PLAN.md — Redaction (storage and metadata): sensitive key-column queries and column-free JWKS selects, `redact: true` + `put_change`, Redaction drop keys and envelope guard, single leak matcher and canary sweep across admin, tasks and LiveViews (RED-01)
- [x] 157-02-PLAN.md — Host surfaces: install step 9 runtime KEK block, config error text, adoption demo KEK in `config/runtime.exs` + public-API seeds, clean-room per-run KEK via host `config/runtime.exs` under `:reject` (HOST-01)
- [x] 157-05-PLAN.md — Redaction (decode guard): `PrivateJwk.to_jwk/1` across six consumers with unchanged error contracts and a malformed-key case per consumer (RED-01)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 157-04-PLAN.md — `docs/upgrading/signing-key-encryption.md` + contract test, telemetry/SECURITY/architecture/walkthrough/install docs, release-note file (DOC-01)
- [x] 157-06-PLAN.md — Redaction proof tail: malformed-key leg of the canary sweep across six consumers and the Oban logout worker errors proof (RED-01)

**Wave 3** *(blocked on Wave 2 completion; runs last so the SAFE-01 gate covers the final tree)*
- [x] 157-03-PLAN.md — Upgrade journey integration test for six consumers, demo and clean-room `--check`/doctor CI checks, SAFE-01 gate recorded (PROOF-01, SAFE-01)

### Coverage

| Requirement | Phase |
|-------------|-------|
| DEP-01, KEK-01, KEK-02, ENC-01, ENC-02, ENC-03 | 155 |
| MIG-01, MIG-02, MIG-03, OPS-01, OPS-02 | 156 |
| RED-01, HOST-01, PROOF-01, DOC-01, SAFE-01 | 157 |

16/16 v1.43 requirements mapped; no orphans or duplicates. Two deliberate early touches do not move ownership: the fixed test KEKs (part of HOST-01) land in 155-02 because sealing tests need them, and the `Inspect` derive on the key structs (part of RED-01) lands in 155-05 with the structs; the clean-room provider KEK (part of HOST-01) lands in 155-04 with the `generate_key` refusal so CI stays green.

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 155. Crypto Core, Config Seam & Bandit Baseline | 5/5 | Complete    | 2026-10-16 |
| 156. Legacy Migration, KEK Rotation & Plaintext Refusal | 3/3 | Complete    | 2026-10-16 |
| 157. Host Surfaces, Redaction Sweep & Release Proof | 6/6 | Complete    | 2026-10-16 |

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
