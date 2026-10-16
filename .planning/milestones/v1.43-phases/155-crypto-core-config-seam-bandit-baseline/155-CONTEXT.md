# Phase 155: Crypto Core, Config Seam & Bandit Baseline - Context

**Gathered:** 2026-10-15 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

The adoption demo and both clean-room hosts run green on Bandit 1.13.1 (landed first, on its own). From then on, a host with a configured KEK writes every new private signing key only as a sealed `LSK\x01` envelope that all six signing/decrypting consumers read; hosts without a KEK keep booting and signing with existing keys, `generate_key` refuses, and boot warning / doctor / verify report the gap. Requirements: DEP-01, KEK-01, KEK-02, ENC-01, ENC-02, ENC-03.

Not in this phase: re-encrypt task, `--check`, `:reject` enforcement at read, KEK rotation, audit/telemetry events (Phase 156); generator output, demo seeds, redaction sweep, docs, release proof (Phase 157).
</domain>

<decisions>
## Implementation Decisions

### Binding upstream design
- **D-00:** Research decisions R1–R8 in `.planning/research/v1.43-key-encryption/SUMMARY.md` are locked (config shape, envelope format and AAD, map-form decoder, missing-vs-invalid KEK behavior, no new deps / migration / rename / caching / compile_env / `secret_key_base` fallback).

### Read seam
- **D-01:** `Lockspire.Protocol.PrivateJwk.decode/1` keeps arity 1 but its binary clause is **replaced** by a map clause taking `%{kid: kid, private_jwk_encrypted: bin}` (struct or map). No binary clause remains, so no consumer can skip the post-decrypt `kid` check (C2). All six call sites already hold the `kid` in the same map/struct.
- **D-02:** Each consumer keeps its existing external error shape. Five sites (ID token, logout token, JARM, introspection JWT, JWT access-token signer) surface `{:error, :invalid_signing_key}`; JAR keeps collapsing to `:decryption_failed` (`jar.ex:38-55`). Tests assert per consumer — do not assert one atom across all six (SAFE-01: no protocol response change).
- **D-03:** The "token exchange" read site (`token_exchange/internal/access_token_signer.ex:208`) is the single JWT access-token signer for every grant (reached from `grant_support.ex` and `refresh_exchange.ex`); envelope-read tests cover it as such.
- **D-04:** `KeyCache`, JWKS, discovery and `list_active_keys` / `list_publishable_keys` stay untouched — they never hold private material. Only `fetch_active_signing_key`, `list_decryption_keys` and `fetch_signing_key_by_id` return ciphertext.

### Config, boot and diagnostics
- **D-05:** `Config.key_encryption!/0` validates fresh from app env on every call and is what `Install.Verify` and the doctor task call. Only `Application.start/2` validates-then-caches the resolved key set in `:persistent_term` (new pattern; the struct gets a redacting `Inspect`). Reason: `mix lockspire.verify` and doctor tasks run under `@requirements ["app.config"]` and never start the app.
- **D-06:** Invalid config raises at boot with a message naming the config key (`:key_encryption` / sub-key) and never the value; the same message text flows into verify `details`, so it must be built from key names only.
- **D-07:** Doctor gets a new `mix lockspire.doctor key_encryption` subcommand (new task + dispatcher clause + help text). In Phase 155 it is presence/validity only; Phase 156-02 extends it with per-KEK-id and legacy row counts.
- **D-08:** `Install.Verify` adds a KEK check in `config_checks/0` using the existing `:ok | :error` contract. A missing KEK is `:error`, so `mix lockspire.verify` fails on an upgraded host without a KEK while the app still boots and signs (user-confirmed 2026-10-15: the loud nudge is intended). No `:warning` status is added.

### Write path
- **D-09:** `Admin.Keys.generate_key/1` seals with the current KEK before `Repository.publish_key`, or returns `{:error, :key_encryption_not_configured}` without writing any row. The KeysLive generic "could not be generated" flash stays as is (admin copy deferred to KEY-UI-01; no new UI wording in this phase).
- **D-10:** `@derive {Inspect, except: [:private_jwk_encrypted]}` is added to `SigningKey` and `SigningKeyRecord` (new — no Inspect derives exist in `lib/` today). The full `Lockspire.Redaction` sweep stays in Phase 157.

### Hosts and test fixtures
- **D-11:** The clean-room provider host gets a fixed test KEK in **Phase 155** (in the config literal written by `scripts/acceptance/clean_room/build_provider.py:63-72`), landing with or before the `generate_key` refusal. Corrects roadmap/research, which scheduled it in 157-02: `bootstrap.ex:5` hard-matches `{:ok, _} = generate_key(:sig)` and the clean-room e2e plus `lockspire.verify` run on every PR.
- **D-12:** `config/test.exs` gets fixed test KEKs (at least two ids, so the cipher tests can cover unknown-KEK) with `legacy_plaintext: :allow`. Only the two shared helpers seal (`test/support/seeding_helpers.ex:27`, `test/support/token_exchange_case.ex:290`). The ~25 direct-insert fixtures stay plaintext and double as legacy-read coverage under `:allow`.
- **D-13:** `test/lockspire/protocol/private_jwk_test.exs` and `test/lockspire/audit/audit_writer_test.exs:449` are rewritten for the map-form decoder.
- **D-14:** Adoption demo seeds (`examples/adoption_demo/priv/repo/seeds.exs`) are untouched in 155 (direct ETF rows keep working under `:allow`); demo KEK config is Phase 157.

### Bandit baseline (plan 155-01, first and standalone)
- **D-15:** Pin `bandit == 1.13.1` in `examples/adoption_demo/mix.exs:33` (currently `~> 1.11`), `test/clean_room/provider_host/mix.exs:22` and `test/clean_room/confidential_client/mix.exs:22` (currently `== 1.12.5`), and run `mix deps.update bandit thousand_island hpax` in each. The compatibility fixture has no direct bandit dep: only refresh its lock (`compatibility/phoenix_1_8_live_view_1_1/mix.lock`, deps_path `../../tmp/lockspire-compatibility-fixture/deps`). Root `mix.exs` / `mix.lock` are unchanged. Green on adoption-demo, compatibility, clean-room e2e and the `ci.yml:75` lock-drift guard.

### Resolved during plan-phase research (2026-10-15)
- **D-16:** Plan 155-01 also bumps `mint` 1.9.3 → 1.11.0 (the version root `mix.lock` already uses) in the adoption demo and both clean-room host locks (`mix deps.update mint`), clearing the two MEDIUM `mix hex.audit` advisories in the same CVE-hygiene commit. Bandit resolves with `thousand_island ~> 1.6` and `hpax ~> 1.1`; pin 1.13.1, never 1.13.0.
- **D-17:** The compatibility fixture lock's `bandit`/`thousand_island` entries are unused (`mix deps.unlock --check-unused`); "refresh" means `mix deps.unlock bandit thousand_island` there (plus `mint` update if it is a used dep), not a version pin.
- **D-18:** A present `:key_encryption` block with `keys: []` is invalid config (fails boot), same as `:reject` without keys.
- **D-19:** Envelope parsing binds `iv::binary-size(12)` and `tag::binary-size(16)` exactly before calling `:crypto` (OTP 27–29 accept truncated tags and 8-byte IVs); `open` also rescues `ErlangError` so bad key/IV sizes become an internal reason, never a raise. The truncated-tag test cuts inside the tag region.
- **D-20:** Config validators return `{:ok, _} | {:error, reason}`, use non-bang `Base.decode64/2`, and raise only via a helper that receives key names and reason atoms, never raw values (no `FunctionClauseError`/`MatchError`/`WithClauseError` paths that print values). A sentinel-value test proves the boot error and verify `details` never contain the configured material.

### Claude's Discretion
- Module names and file layout for the cipher (`Lockspire.Security.KeyEncryption` suggested) and the resolved key-set struct.
- Exact internal reason atoms (`:unknown_kek`, `:tag_mismatch`, `:kid_mismatch`, `:malformed_envelope`, etc.) as long as they collapse per D-02 externally.
- Property-test generator design for the classify test (StreamData is already available only if present in deps; otherwise use an ExUnit loop — no new deps).
- Boot warning wording (Logger, names setting only).

### Folded Todos
- `2026-10-14-bump-bandit-in-demo-and-clean-room-hosts.md` → plan 155-01 (DEP-01).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.43-key-encryption/SUMMARY.md` — binding decisions R1–R8
- `.planning/research/v1.43-key-encryption/ARCHITECTURE.md`, `PITFALLS.md` (C1, C2, C3, C9, C10 owned here), `STACK.md`, `FEATURES.md`
- `.planning/REQUIREMENTS.md` — DEP-01, KEK-01, KEK-02, ENC-01..03, SAFE-01
- `.planning/ROADMAP.md` — Phase 155 section (success criteria; note corrections D-02, D-07, D-11 above)
- `.planning/todos/pending/2026-10-14-bump-bandit-in-demo-and-clean-room-hosts.md`
- `PRODUCT.md` vocabulary map — only if any admin copy is touched (not expected)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/lockspire/protocol/private_jwk.ex:1-24` — current decoder (JSON then safe ETF, catch-all `:invalid_signing_key`); legacy parsers move behind envelope classification.
- `lib/lockspire/config.ex` — `Application.get_env` getters; errors via `ArgumentError` (`:75,100`) or `Policy.fetch_required_config!` (`:246`). `secret_key_base/0` at `:85` must NOT be used for the KEK.
- `lib/lockspire/install/verify.ex:48-76` — `config_checks/0` and `config_check/3` (exception message goes verbatim into `details`).
- `lib/lockspire/storage/ecto/repository/signing_key_store.ex` — `publish_key` (`:12`), `strip_private_key_material` (`:253`).

### Established Patterns
- Doctor is a subcommand dispatcher (`lib/mix/tasks/lockspire.doctor.ex:10-27`, `remote-jwks`, `token_format`); the `lockspire.doctor.token_format` task is the closest template.
- Admin writes go through `transact_with_audit` in `lib/lockspire/admin/keys.ex`.
- No `:persistent_term` and no `@derive Inspect` in `lib/` yet — both are new patterns this phase introduces.

### Integration Points
- Write: `lib/lockspire/admin/keys.ex:37-79` (`Jason.encode!` at `:62`), facade `lib/lockspire/admin.ex:208-210`, UI `lib/lockspire/web/live/admin/keys_live/index.ex:198-242`.
- Reads: `protocol/id_token.ex:36`, `protocol/logout_token.ex:35`, `protocol/jarm.ex:55`, `protocol/introspection_jwt.ex:36`, `protocol/token_exchange/internal/access_token_signer.ex:208`, `protocol/jar.ex:43`.
- Boot: `lib/lockspire/application.ex:9-19`.
- Structs: `lib/lockspire/domain/signing_key.ex`, `lib/lockspire/storage/ecto/signing_key_record.ex` (column `:binary`).
- Test config: `config/test.exs:29-34`.
- Clean room: `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex:5`, `scripts/acceptance/clean_room/build_provider.py:51-75,335,352`; CI `scripts/ci/run_test_matrix.sh:124-126`, `.github/workflows/ci.yml:75,189+,330,345,399+`, `.github/workflows/release.yml:203`.
</code_context>

<specifics>
## Specific Ideas

- User confirmed (2026-10-15) that `mix lockspire.verify` failing on a KEK-less upgraded host is the intended loud nudge; boot and signing stay non-breaking.
</specifics>

<deferred>
## Deferred Ideas

- Admin "Key protection" line and specific KeysLive error copy for `:key_encryption_not_configured` — KEY-UI-01.
- `:warning` status for verify checks — rejected for now; revisit only if hosts report CI friction.

### Reviewed Todos (not folded)
- `2026-10-13-audit-dcr-default-lifetime-semantics.md` — protocol, unrelated to key storage; already deferred as DCR-01.
</deferred>
