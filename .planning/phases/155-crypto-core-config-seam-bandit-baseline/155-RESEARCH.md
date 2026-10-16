# Phase 155: Crypto Core, Config Seam & Bandit Baseline - Research

**Researched:** 2026-10-15
**Domain:** Elixir/OTP `:crypto` AES-256-GCM envelope encryption of signing-key rows; runtime config validation; Bandit host dependency bump
**Confidence:** HIGH (crypto contract prototyped on OTP 27/28/29; repo seams read directly); MEDIUM for Bandit 1.13.1 (released today, 2026-10-15, unsoaked)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-00:** Research decisions R1–R8 in `.planning/research/v1.43-key-encryption/SUMMARY.md` are locked (config shape, envelope format and AAD, map-form decoder, missing-vs-invalid KEK behavior, no new deps / migration / rename / caching / compile_env / `secret_key_base` fallback).
- **D-01:** `Lockspire.Protocol.PrivateJwk.decode/1` keeps arity 1 but its binary clause is **replaced** by a map clause taking `%{kid: kid, private_jwk_encrypted: bin}` (struct or map). No binary clause remains, so no consumer can skip the post-decrypt `kid` check (C2). All six call sites already hold the `kid` in the same map/struct.
- **D-02:** Each consumer keeps its existing external error shape. Five sites (ID token, logout token, JARM, introspection JWT, JWT access-token signer) surface `{:error, :invalid_signing_key}`; JAR keeps collapsing to `:decryption_failed` (`jar.ex:38-55`). Tests assert per consumer — do not assert one atom across all six (SAFE-01: no protocol response change).
- **D-03:** The "token exchange" read site (`token_exchange/internal/access_token_signer.ex:208`) is the single JWT access-token signer for every grant (reached from `grant_support.ex` and `refresh_exchange.ex`); envelope-read tests cover it as such.
- **D-04:** `KeyCache`, JWKS, discovery and `list_active_keys` / `list_publishable_keys` stay untouched — they never hold private material. Only `fetch_active_signing_key`, `list_decryption_keys` and `fetch_signing_key_by_id` return ciphertext.
- **D-05:** `Config.key_encryption!/0` validates fresh from app env on every call and is what `Install.Verify` and the doctor task call. Only `Application.start/2` validates-then-caches the resolved key set in `:persistent_term` (new pattern; the struct gets a redacting `Inspect`). Reason: `mix lockspire.verify` and doctor tasks run under `@requirements ["app.config"]` and never start the app.
- **D-06:** Invalid config raises at boot with a message naming the config key (`:key_encryption` / sub-key) and never the value; the same message text flows into verify `details`, so it must be built from key names only.
- **D-07:** Doctor gets a new `mix lockspire.doctor key_encryption` subcommand (new task + dispatcher clause + help text). In Phase 155 it is presence/validity only; Phase 156-02 extends it with per-KEK-id and legacy row counts.
- **D-08:** `Install.Verify` adds a KEK check in `config_checks/0` using the existing `:ok | :error` contract. A missing KEK is `:error`, so `mix lockspire.verify` fails on an upgraded host without a KEK while the app still boots and signs (user-confirmed 2026-10-15). No `:warning` status is added.
- **D-09:** `Admin.Keys.generate_key/1` seals with the current KEK before `Repository.publish_key`, or returns `{:error, :key_encryption_not_configured}` without writing any row. The KeysLive generic "could not be generated" flash stays as is (admin copy deferred to KEY-UI-01; no new UI wording in this phase).
- **D-10:** `@derive {Inspect, except: [:private_jwk_encrypted]}` is added to `SigningKey` and `SigningKeyRecord` (new — no Inspect derives exist in `lib/` today). The full `Lockspire.Redaction` sweep stays in Phase 157.
- **D-11:** The clean-room provider host gets a fixed test KEK in **Phase 155** (in the config literal written by `scripts/acceptance/clean_room/build_provider.py:63-72`), landing with or before the `generate_key` refusal. (`bootstrap.ex:5` hard-matches `{:ok, _} = generate_key(:sig)`; clean-room e2e plus `lockspire.verify` run on every PR.)
- **D-12:** `config/test.exs` gets fixed test KEKs (at least two ids, so the cipher tests can cover unknown-KEK) with `legacy_plaintext: :allow`. Only the two shared helpers seal (`test/support/seeding_helpers.ex:27`, `test/support/token_exchange_case.ex:290`). The ~25 direct-insert fixtures stay plaintext and double as legacy-read coverage under `:allow`.
- **D-13:** `test/lockspire/protocol/private_jwk_test.exs` and `test/lockspire/audit/audit_writer_test.exs:449` are rewritten for the map-form decoder.
- **D-14:** Adoption demo seeds (`examples/adoption_demo/priv/repo/seeds.exs`) are untouched in 155; demo KEK config is Phase 157.
- **D-15:** Pin `bandit == 1.13.1` in `examples/adoption_demo/mix.exs:33` (currently `~> 1.11`), `test/clean_room/provider_host/mix.exs:22` and `test/clean_room/confidential_client/mix.exs:22` (currently `== 1.12.5`), and run `mix deps.update bandit thousand_island hpax` in each. The compatibility fixture has no direct bandit dep: only refresh its lock. Root `mix.exs` / `mix.lock` unchanged. Green on adoption-demo, compatibility, clean-room e2e and the `ci.yml:75` lock-drift guard.

### Claude's Discretion
- Module names and file layout for the cipher (`Lockspire.Security.KeyEncryption` suggested) and the resolved key-set struct.
- Exact internal reason atoms (`:unknown_kek`, `:tag_mismatch`, `:kid_mismatch`, `:malformed_envelope`, etc.) as long as they collapse per D-02 externally.
- Property-test generator design for the classify test (StreamData is already available only if present in deps; otherwise use an ExUnit loop — no new deps).
- Boot warning wording (Logger, names setting only).

### Deferred Ideas (OUT OF SCOPE)
- Admin "Key protection" line and specific KeysLive error copy for `:key_encryption_not_configured` — KEY-UI-01.
- `:warning` status for verify checks — rejected for now.
- Not in this phase: re-encrypt task, `--check`, `:reject` enforcement at read, KEK rotation, audit/telemetry events (Phase 156); generator output, demo seeds, redaction sweep, docs, release proof (Phase 157).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEP-01 | Demo + both clean-room hosts on Bandit 1.13.1, e2e green, landed before any encryption change | Bandit section: 1.13.1 changelog, no breaking/deprecated options, fixes both GHSAs; stale compat-lock finding; lock-drift guard scope |
| KEK-01 | `:key_encryption` config; invalid config fails boot naming key, never value | Config seam + "Raising without leaking" prototype; validation rule list |
| KEK-02 | Absent config: boots, legacy keys sign, `generate_key` refuses, warning/doctor/verify report | Boot flow, `Install.Verify` + doctor integration, verify_test id-list contract |
| ENC-01 | New keys stored as `LSK\x01` AES-256-GCM envelope w/ AAD | Prototype-verified `crypto_one_time_aead` contract; envelope encoder/decoder pattern |
| ENC-02 | Six consumers read envelopes/legacy via map-form `PrivateJwk.decode` | Call-site table (file:line), per-consumer error shapes, helper sealing |
| ENC-03 | Tests: tamper, row swap, unknown KEK, truncated tag; classify property | Validation Architecture; StreamData already a test dep |
</phase_requirements>

## Summary

The crypto contract is now fixed by prototype, not recollection. On OTP 27.3.4.15, 28.5 and 29.1.1 (CI primary is OTP 28, minimum OTP 27) `:crypto.crypto_one_time_aead(:aes_256_gcm, ...)` behaves identically. The decisive finding is that **decrypt silently accepts truncated tags**: passing a 15-byte or 4-byte prefix of the real tag returns the plaintext. The envelope decoder must therefore bind-match exactly `tag::binary-size(16)` and treat anything shorter as `:malformed_envelope` before calling `:crypto`; the "truncated tag" test in ENC-03 is only meaningful at the envelope-parse layer, and a naive "truncate the last 1 byte of the whole envelope" test hits the ciphertext/GCM path instead. Wrong key size and wrong IV size on *encrypt or decrypt* **raise** `ErlangError` (`:badarg`); wrong key, wrong AAD, flipped tag/ciphertext, 0-byte and 17-byte tags, and an 8-byte IV on *decrypt* return `:error`. The open wrapper must pattern-match on exact sizes first and still rescue.

Bandit 1.13.1 is a safe drop-in: the changelog lists no breaking changes or deprecations, and none of the endpoint option keys used by the three hosts (`adapter`, `http: [ip:, port:]`) are touched. 1.13.0 fixes GHSA-69m6-wcv4-rwcf and GHSA-v53v-9hvg-37jf (both in the `hex.audit` output for the current lock); 1.13.1 only reverts a stale-connection guard from 1.13.0. One surprise: **the compatibility fixture lock's `bandit`/`thousand_island` entries are unused** (`mix deps.unlock --check-unused` flags them; `mix deps.tree` has no bandit), so "refresh its lock" means `mix deps.unlock bandit thousand_island` (and optionally `mix deps.update hpax`), not a version bump.

For config safety, the leak risk is not `raise` itself but Elixir's value-carrying exceptions: `FunctionClauseError`, `MatchError` and `WithClauseError` print the offending term (prototyped). Validation must use non-bang decoders and a `fail!/2` that receives only key names.

**Primary recommendation:** Land plan 155-01 (Bandit) alone and green; then build `Security.KeyEncryption` as a pure module with exact-size binary matches and a rescue-wrapped `:crypto` call, validate config with `{:ok, _} | {:error, key_name}` helpers feeding a name-only `raise`, and flip the map-form decoder, generate_key and the helper/clean-room KEK in the same plan so no intermediate commit has a plaintext-writing `generate_key` without a KEK in the clean-room.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Seal/open/classify envelope | Library core (pure `Security.KeyEncryption`) | — | Pure function of (keyset, binary, kid); never reads env (R4) |
| KEK config validation + resolved keyset | Library config (`Lockspire.Config`) | Application boot | Fresh validation per call (D-05); boot caches in `:persistent_term` |
| Write path sealing | Admin (`Admin.Keys.generate_key/1`) | Storage (opaque binary) | Single write seam; storage stays dumb |
| Read path decryption | Protocol (`Protocol.PrivateJwk.decode/1`) | six signers/decryptor | Single read seam; plaintext only between decode and sign |
| Diagnostics | Mix tasks (`doctor key_encryption`, `verify`) | `Install.Verify` | Run under `app.config` only, so must not need `:persistent_term` |
| Host test KEKs | Host config (test.exs, build_provider.py) | — | Runtime/host-owned; never compile_env in `lib/` |
| Bandit bump | Host apps (demo, clean rooms, compat lock) | CI | Library has no Bandit dep |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| OTP `:crypto` | OTP 27/28/29 (CI: 28; min 27) | AES-256-GCM via `crypto_one_time_aead/7` | Zero new deps (SAFE-01); behavior prototyped identical on 27.3.4.15, 28.5, 29.1.1 [VERIFIED: local prototype, scratchpad aead.exs] |
| Jason (existing) | existing | Plaintext JWK JSON (`Jason.encode!/1` already used at `admin/keys.ex:62`) | Unchanged |
| StreamData | 1.4.0 (`{:stream_data, "~> 1.0", only: :test}`) | Classify property test | Already a test dep [VERIFIED: mix.exs:75, mix.lock:49]; **no test file uses it yet** (grep of `test/` for `ExUnitProperties|StreamData|check all` returned nothing), so this is the first `use ExUnitProperties` in the repo |

### Host-only (DEP-01)
| Library | Version | Purpose |
|---------|---------|---------|
| bandit | `== 1.13.1` | Host HTTP server (released 2026-10-15) [VERIFIED: hex.pm API] |
| thousand_island | resolves 1.6.0 (bandit requires `~> 1.6`) | transitive [VERIFIED: hex.pm API releases/bandit/1.13.1 requirements] |
| hpax | resolves 1.1.0 (bandit requires `~> 1.1`) | transitive; 1.1.0 published 2026-09-24 [VERIFIED: hex.pm API] |

**Installation (per host, in its directory):**
```bash
export HEX_HOME=/private/tmp/lockspire-hex ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1
mix deps.update bandit thousand_island hpax
```
No new Hex dependency is added to the library or any host.

### Alternatives Considered
Locked by R1–R8 (no cloak, no `Plug.Crypto.encrypt`, no HKDF, no JWE). Not re-researched.

## Package Legitimacy Audit

`gsd-tools package-legitimacy check` supports only npm/pypi/crates (usage error for `hex`), so the seam could not be run. These are not new packages: all three are already in the three host lock files and the verdict rests on hex.pm API data.

| Package | Registry | Age | Source | Verdict | Disposition |
|---------|----------|-----|--------|---------|-------------|
| bandit | hex.pm | multi-year, mtrudel; 1.12.5 (2026-08-20) → 1.13.1 (2026-10-15) | github.com/mtrudel/bandit | Established (already locked) | Approved |
| thousand_island | hex.pm | multi-year; 1.6.0 published 2026-10-15 (same day as bandit 1.13.x) | github.com/mtrudel/thousand_island | Established; new release is a fresh-publish, same maintainer | Approved |
| hpax | hex.pm | multi-year; 1.1.0 (2026-09-24) | github.com/elixir-mint/hpax | Established | Approved |

**Packages removed (SLOP):** none. **Flagged (SUS):** none. Because 1.13.1/1.6.0 are hours old, plan 155-01 should run `mix hex.audit` in each host and review the lock diff before commit (cheap guard, not a checkpoint). Out-of-scope observation: the host locks also pin `mint 1.9.3`, flagged by `mix hex.audit` (EEF-CVE-2026-82729, -82672, MEDIUM) — not part of DEP-01; see Open Questions.

## Bandit 1.12.5 → 1.13.1 (research flag, resolved)

[CITED: github.com/mtrudel/bandit CHANGELOG.md, fetched 2026-10-15; hex.pm API for requirements]

- **No breaking changes or deprecations are listed** for 1.13.0 or 1.13.1. No endpoint/http option is renamed or removed. New option: `compress_chunked` (opt-in).
- **Dependency requirement changes (1.13.0, retained in 1.13.1):** `thousand_island ~> 1.6`, `hpax ~> 1.1`. Updating only `bandit` will not resolve; the three-package `mix deps.update` is required (matches R6).
- **Security fixes in 1.13.0:** GHSA-v53v-9hvg-37jf (EEF-CVE-2026-105660: HTTP/1 absolute-/authority-form targets validated like `Host`) and GHSA-69m6-wcv4-rwcf (EEF-CVE-2026-105659: HTTP/2 blocked-send bounded by progress). `mix hex.audit` in the compat fixture currently lists both against `bandit 1.12.5` [VERIFIED: ran `mix hex.audit` in compat dir]. This is "the CVE" in the todo.
- **1.13.1** only reverts the 1.13.0 stale-connection check in `Bandit.Adapter` (#668) because Phoenix relies on stale conns when rendering `Plug.Parsers` errors through `Phoenix.Endpoint.RenderErrors`. Do NOT pin 1.13.0.
- **Behavior changes worth a smoke look (none config-related):** idle connections sending no bytes now close silently instead of a 408; empty 4xx/5xx responses carry `Content-Length: 0`; stricter HTTP/1 request-target and HTTP/2 field validation (control bytes, CR/LF/NUL, content-length vs END_STREAM). The clean-room clients use plain `Req/Mint`-style HTTP against `127.0.0.1`; a strictness regression would surface as e2e failure, which is exactly why the bump lands first.
- **Config audit of the three hosts** [VERIFIED: read/grep]:
  - `examples/adoption_demo/config/config.exs:47-51`: `adapter: Bandit.PhoenixAdapter, http: [ip: demo_bind_ip, port: ...]`.
  - `test/clean_room/confidential_client/config/config.exs:26-27`: `adapter: Bandit.PhoenixAdapter, http: [ip: {127,0,0,1}, port: ...]`.
  - provider host config literal in `scripts/acceptance/clean_room/build_provider.py:58-59`: same shape.
  - None use `inet6`, `compress_chunked`, thousand_island options, `http_1`/`http_2` option blocks, or `plug` tuple forms. Nothing affected.
- **Lock/CI facts:**
  - `ci.yml:75` guards only `mix.lock`, `examples/adoption_demo/mix.lock`, `compatibility/.../mix.lock`, and the release-please package-lock. The two clean-room locks are NOT guarded for drift (they are hashed into the clean-room dep cache key at `ci.yml:330`, so a changed lock correctly busts the cache).
  - Current pins: demo `~> 1.11` (lock 1.12.5); clean-room provider and confidential client `== 1.12.5`; locks carry thousand_island 1.5.0, hpax 1.0.4.
  - **Compat fixture:** `compatibility/phoenix_1_8_live_view_1_1/mix.exs` deps are only lockspire (path), phoenix `== 1.8.5`, phoenix_live_view `== 1.1.28`. `mix deps.unlock --check-unused` reports `:bandit` and `:thousand_island` unused; bandit is absent from `mix deps.tree` [VERIFIED: ran in that directory, 0 matches]. hpax (1.0.4) is used via mint. Therefore for the fixture: run `mix deps.unlock bandit thousand_island` (drops the vulnerable stale entries; satisfies `ci.yml:75` and the compat job's `deps.get --check-locked`, which does not prune unused entries) and, optionally, `mix deps.update hpax`. CONTEXT D-15 says "only refresh its lock"; this is the concrete reading. The planner should verify with `mix deps.get --check-locked` + `mix compile --warnings-as-errors` there (CI compat job uses MIN pair OTP 27 / Elixir 1.18.4).
  - Side effect of my research: running `mix` in the compat dir wrote an `erl_crash.dump` which I deleted; `git status` shows only the pre-existing `.planning/config.json` change.
- **Verification commands per host:** `mix deps.update bandit thousand_island hpax && mix deps.get --check-locked && mix compile --warnings-as-errors && mix hex.audit`; then repo-level `mix test.clean-room.e2e` (`python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path --only boundary --only lifecycle --only negative --only dpop`) and the demo's existing CI job.

## Crypto contract (research flag, resolved by prototype)

[VERIFIED: ran `/private/tmp/claude-501/.../scratchpad/aead.exs` on OTP 29.1.1/Elixir 1.20.4, OTP 28.5/1.20.4, OTP 27.3.4.15/Elixir 1.18.4; results identical across all three]

`:crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, data, aad, tag_or_len, encrypt?)`:

| Case | Result |
|------|--------|
| encrypt, 32B key, 12B IV, tag_len 16 | `{ciphertext, tag}`; `byte_size(ct) == byte_size(pt)`, tag 16 B |
| decrypt, correct | plaintext binary (empty plaintext → `""`) |
| decrypt, flipped tag byte / flipped ct byte / wrong AAD / wrong key | `:error` (no raise) |
| decrypt, **15-byte tag (prefix of real tag)** | **plaintext returned (accepted!)** |
| decrypt, **4-byte tag prefix** | **plaintext returned (accepted!)** |
| decrypt, 0-byte tag, 17-byte tag | `:error` |
| decrypt, 8-byte IV | `:error` |
| decrypt, 0-byte IV | **raises** `ErlangError {:badarg, _, 'Bad IV length'}` |
| encrypt or decrypt, 31-byte key or non-binary key | **raises** `ErlangError {:badarg, _, 'Unknown cipher or invalid key size'}` |
| encrypt, 8-byte IV | succeeds (accepted; do not rely on `:crypto` to enforce 12) |
| non-binary tag (atom) | **raises** `ErlangError ... 'non-binary Tag'` |
| AAD as iodata list | accepted |

**Consequences for the design (prescriptive):**
1. Parse the envelope with a single binary pattern that fixes sizes: `<<"LSK", 1, id_len::8, kek_id::binary-size(id_len), iv::binary-size(12), tag::binary-size(16), ct::binary>>`. A truncated tag (or any short envelope) fails that match → `{:error, :malformed_envelope}` without ever calling `:crypto`. This is the ENC-03 "truncated tag" proof; also add a case where the envelope is cut inside the tag region and one where only the last ciphertext byte is dropped (GCM path → `:decryption_failed`).
2. `open` must never raise: guard sizes (key 32 B, IV 12 B, tag 16 B) *and* wrap the `:crypto` call in `try/rescue ErlangError` mapping to `{:error, :decryption_failed}`.
3. `seal` always uses `:crypto.strong_rand_bytes(12)` per call (C3) and a tag length of 16; never accept a caller-supplied IV (testing hook would invite reuse). Test fixed-IV behavior only via a private/`@doc false` arity if needed; prefer asserting two seals of the same plaintext differ.
4. A valid empty-ciphertext envelope is legal for `:crypto` but a decrypted JWK that is not a JSON object must be `:invalid_signing_key`.

## Architecture Patterns

### System Architecture Diagram

```
WRITE (operator-initiated only)
 Admin.generate_key(use) ──> Config.key_encryption!() ──┬─ not configured ─> {:error, :key_encryption_not_configured}   (no row written)
        │                                                └─ keyset(current id, 32B key)
        ▼
 build JWK+kid ─> Jason.encode!(private_jwk_map) ─> KeyEncryption.seal(keyset, kid, json)
        ▼                                                  (fresh 12B IV, AAD = "lockspire.signing_key.v1" 0 header 0 kid)
 Repository.publish_key (opaque bytea) ─> audit/telemetry (kid only)

READ (six consumers)
 IdToken / LogoutToken / Jarm / IntrospectionJwt / AccessTokenSigner / Jar
        │  hand %{kid:, private_jwk_encrypted:}  (struct or map)
        ▼
 PrivateJwk.decode/1 ──> KeyEncryption.classify(bin)
        ├─ :envelope ──> keyset (persistent_term; fallback fresh) ──> open(...) ──> Jason.decode ──> kid check ──> {:ok, jwk_map}
        │        └─ errors: :kek_not_configured :unknown_kek :malformed_envelope :decryption_failed :kid_mismatch
        └─ :legacy ───> (legacy_plaintext == :allow) JSON, then safe ETF  ──> {:ok, jwk_map}   (existing parsers, unchanged)
        collapse ──> consumer's existing shape (5x {:error,:invalid_signing_key}; JAR -> :decryption_failed)

BOOT
 Application.start/2 ─> Config.key_encryption!() fresh validate
        ├─ invalid  ─> raise (key names only)  → boot fails
        ├─ absent   ─> Logger.warning (names setting only); store :unconfigured
        └─ valid    ─> :persistent_term.put(key, %KeySet{} (redacting Inspect))
 mix lockspire.verify / doctor key_encryption (app.config only) ─> Config.key_encryption!() fresh
```

### Recommended Project Structure
```
lib/lockspire/security/key_encryption.ex          # seal/open/classify, pure; takes %KeySet{}
lib/lockspire/security/key_encryption/key_set.ex  # struct + redacting Inspect (no Config dep => no compile cycle)
lib/lockspire/config.ex                           # key_encryption!/0 (+ cached accessor for runtime reads)
lib/lockspire/protocol/private_jwk.ex             # map-form decode only
lib/lockspire/application.ex                      # validate + warn + persistent_term
lib/mix/tasks/lockspire.doctor.key_encryption.ex  # new; + dispatcher clause/help in lockspire.doctor.ex
lib/lockspire/install/verify.ex                   # :key_encryption check
```
`scripts/ci/check_architecture_topology.sh` fails on compile-connected cycles. `KeyEncryption` must not alias `Lockspire.Config` (Config depends on it for the struct). `Config` already aliases `Security.Policy`, so the direction Config → Security is established.

### Pattern 1: Strict classification, no fall-through (C1)
**What:** `classify/1` matches `<<"LSK", _::binary>>` → `:envelope`; everything else → `:legacy`. Any binary with the prefix that fails the full parse is `:malformed_envelope`, never retried as JSON/ETF. Legacy first bytes are disjoint: JSON object `{` 0x7B (or leading whitespace), ETF 131; envelope `L` 0x4C.
**Example:**
```elixir
# Source: prototype-verified contract (this research) + SUMMARY R2
@header "LSK"
@version 1
def classify(<<@header, _::binary>>), do: :envelope
def classify(bin) when is_binary(bin), do: :legacy
def classify(_), do: :invalid

defp parse(<<@header, @version, id_len::8, kek_id::binary-size(id_len),
             iv::binary-size(12), tag::binary-size(16), ct::binary>> = bin) do
  header_len = 3 + 1 + 1 + id_len
  {:ok, %{kek_id: kek_id, iv: iv, tag: tag, ct: ct, header: binary_part(bin, 0, header_len)}}
end
defp parse(_), do: {:error, :malformed_envelope}
```
Note: an envelope whose version byte is not 1 falls to `parse(_)` → `:malformed_envelope` (still no fall-through since classification already said `:envelope`).

AAD per R2: `"lockspire.signing_key.v1" <> <<0>> <> header <> <<0>> <> kid` where `header` = bytes through the end of `kek_id`. Post-decrypt: JSON `"kid"` must equal the row `kid`, else `:kid_mismatch`. The seal side must build the header and AAD from the same function as the open side to avoid drift.

### Pattern 2: Raising without leaking (research flag, resolved)
**Prototype** (`scratchpad/leak.exs`, Elixir 1.20.4) printed `Exception.format` for each failure style:
- `FunctionClauseError`: stack line shows `Leak.fn_clause("SECRETVALUE!!")` → **leaks the argument**.
- `MatchError` (`{:ok, _} = v`): prints the right-hand-side value → **leaks**.
- `WithClauseError`: prints the unmatched term → **leaks**.
- `Base.decode64!/1` raising `ArgumentError "incorrect padding"`: message has no value (but other bang functions' messages may; avoid).
- `raise ArgumentError, "invalid config :key_encryption :keys: base64_or_size"` from a `fail!(key_name, reason_atom)` that never receives the value: **clean**.

**Prescription:** validators return `{:ok, term} | {:error, key_name_or_reason_atom}` using non-bang `Base.decode64/2`/`Base.url_decode64/2` and guards with catch-all clauses that return errors (never leave a clause gap that raises `FunctionClauseError` with the raw term). Only a final `defp fail!(config_key, reason)` raises `ArgumentError` with a message assembled from literals/atoms. Do not use `{:ok, _} = validate(...)`, `with` without a total `else`, `Keyword.fetch!` on the raw block (its `KeyError` message includes the keyword list), or `inspect/1` of config anywhere. The `Application.start/2` failure wraps the exception and stacktrace in `{:error, {{exception, stacktrace}, {Lockspire.Application, :start, [...]}}}`; raising directly from `start/2` is fine as long as the exception is the name-only `ArgumentError`. The same string is what `Install.Verify.config_check/3` already puts verbatim into `details` (`verify.ex` `safely(fetch)` path), so one message serves both D-06 surfaces. Add a test that sets a config whose invalid value is a recognizable sentinel (e.g. `"SENTINEL-KEK-VALUE"`) and asserts it appears in neither the exception message nor `Exception.format(:error, e, st)`.

Validation rules (R1/R8, KEK-01): `keys` list of `{id, b64}` (id matches `\A[A-Za-z0-9._-]{1,32}\z`, unique); b64 decodes (standard or URL-safe) to exactly 32 bytes; reject all-identical bytes; reject duplicate material under different ids; `current` ∈ ids; `legacy_plaintext ∈ [:allow, :reject]` (default `:allow`); `:reject` with no keys invalid; whole block absent (`nil`) → "unconfigured", not an error. A block present but with empty `keys: []` and `legacy_plaintext: :allow` should be treated as invalid (`keys` empty) — decide in plan; recommended: invalid, to avoid a half-configured block silently behaving as "absent".

### Pattern 3: Config accessor split (D-05)
- `Config.key_encryption!/0` — always validates from `Application.get_env(:lockspire, :key_encryption)`; returns `{:ok, %KeySet{}}`-like or `:unconfigured`-like tagged result, or raises per the project's `!` convention. Recommended: return `%KeySet{}` when configured, `nil` when absent (the `!` raises only on invalid). Used by Verify, doctor, Application.start.
- Runtime hot path (`generate_key`, `PrivateJwk.decode`): `Config.key_encryption_keyset/0` reads `:persistent_term.get({Lockspire, :key_encryption}, :miss)`; on `:miss` (app not started, e.g. a mix task calling the decoder) fall back to a fresh validation WITHOUT caching. This keeps release `eval` and test setups working.
- Test helper (`test/support`, non-async tests only): `put_key_encryption(config)` = `Application.put_env` + re-put `:persistent_term` + `on_exit` restore. `:persistent_term.put` of a changed value triggers a global GC scan — acceptable in tests; never in a request path (reads are free, writes are boot/test only).
- Persistent-term key: use a namespaced tuple, not a bare atom.

### Anti-Patterns to Avoid
- Calling `Config.key_encryption!/0` (fresh base64 decode + dup checks) on every sign — use the cached accessor in the request path.
- `Application.compile_env`, module attributes reading the KEK, or `secret_key_base` fallback (C9). Add an assertion test: `grep`-style check that `lib/` contains no `compile_env(:lockspire, :key_encryption` and `Config.secret_key_base` is not referenced from `Security.KeyEncryption`/`Config.key_encryption`.
- Keeping a binary clause on `PrivateJwk.decode/1` "for convenience" (reopens C2).
- Logging `inspect(reason)` that could contain the binary: `access_token_signer.ex` already does `Logger.error("Failed to sign access token: #{inspect(reason)}")` — reasons must stay atoms, never carry the binary or the decoded map.
- Calling `Jason.decode!`/`binary_to_term` on the decrypted plaintext outside the existing safe path; use `Jason.decode/1` (non-bang) and `Plug.Crypto.non_executable_binary_to_term/2` only on the legacy branch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AEAD cipher | Own cipher/MAC | `:crypto.crypto_one_time_aead/7` AES-256-GCM | Authenticated, in OTP, no dep |
| Randomness | `:rand` / counters for IV | `:crypto.strong_rand_bytes/1` | C3 nonce uniqueness |
| Base64 | Manual decode | `Base.decode64/2` + `Base.url_decode64/2` (padding: both) | Non-bang avoids value-carrying exceptions |
| Constant-time compare | `==` for kid/AAD checks | Not needed for kid (public); GCM tag compare is inside `:crypto` | Do not reimplement tag checks |
| JWK parse | Custom JSON walk | existing `Jason.decode/1` + `JOSE.JWK.from_map/1` at call sites | Unchanged consumer code |
| Property testing | Hand loops with `:rand` | StreamData `check all` (already a dep) | Shrinking, repeatability |

**Key insight:** every risk here is operational (misparse, silent acceptance, leakage), not algorithmic; the prototype table above is the whole cipher surface.

## Runtime State Inventory

> This is not a rename phase, but it changes stored-data semantics and host config, so the relevant categories are answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `lockspire_signing_keys.private_jwk_encrypted` bytea holds legacy JSON/ETF plaintext in existing installs; adoption demo seeds insert ETF rows directly (`seeds.exs:93`) | No migration in 155 (Phase 156 re-encrypt). Legacy rows must keep decoding under `:allow` — covered by keeping legacy parsers behind classification |
| Live service config | None — verified: Lockspire has no external service config for keys | None |
| OS-registered state | None — verified | None |
| Secrets/env vars | New KEK in host runtime config; clean-room provider config literal in `build_provider.py:63-72`; `config/test.exs` | Add test KEKs (D-11, D-12); never reuse `secret_key_base` |
| Build artifacts | Stale `bandit`/`thousand_island` entries in the compat fixture lock; clean-room caches keyed by lock hash (`ci.yml:330`) | `mix deps.unlock` for compat; lock change busts the cache automatically |

## Common Pitfalls

### Pitfall 1: "Truncated tag" test that doesn't test the tag
**What goes wrong:** Dropping the last byte of the whole envelope truncates ciphertext, not the tag; GCM rejects it, giving false confidence that short tags are rejected.
**Why:** `:crypto` accepts 4–15 byte tag prefixes (prototype).
**How to avoid:** Test two things: envelope cut inside the tag (→ `:malformed_envelope`) and a hand-constructed `:crypto` call with a short tag (documenting why the parse-level guard exists). Also assert `open` source never passes a tag whose size is not 16.
**Warning signs:** `open` implemented as `<<..., tag::binary-size(byte_size(rest)-12), ...>>` or any variable-size tag.

### Pitfall 2: Exceptions from `:crypto` escaping the six consumers
**What goes wrong:** A 0-byte IV or 31-byte key raises `ErlangError`; most consumers only `rescue` partially (`PrivateJwk.decode` today rescues broadly, which must be preserved).
**How to avoid:** Size-guard + rescue inside `KeyEncryption.open`; keep the broad rescue/catch in `PrivateJwk.decode`. Test: a KEK struct forged with 31-byte key (bypassing validation) still returns `{:error, _}`.

### Pitfall 3: Row-swap acceptance (C2)
**What goes wrong:** Envelope for key A copied into row B decrypts fine (same KEK) and signs with A's material under B's `kid`.
**How to avoid:** AAD includes `kid` (tag fails) AND post-decrypt JSON `kid` equality. Test both: swap ciphertext between two rows (expect AAD failure), and a forged envelope sealed with the row's own kid but containing another kid in JSON (expect `:kid_mismatch`). Legacy rows are exempt from the AAD but the existing legacy maps carry `"kid"`; do not add a kid check for legacy in 155 (would break `<<1>>`-style and kid-less fixtures).

### Pitfall 4: Clean-room breaks the moment `generate_key` refuses
**What goes wrong:** `bootstrap.ex:5` hard-matches `{:ok, %{key: key}} = Lockspire.Admin.generate_key(:sig)`; with no KEK the provision step crashes and `lockspire.verify` (now KEK-checking) fails, on every PR.
**How to avoid:** Put the test KEK in the `build_provider.py` config literal in the same plan/commit as `generate_key` refusal. The literal is in `config/config.exs` (not runtime.exs; the clean-room host has no `runtime.exs` written by the script) and mix evaluates it for `lockspire.verify` in the default env, so one place serves both verify and the running server [VERIFIED: build_provider.py:51-75 writes only config/config.exs; verify invoked at line ~335 through `run_child_command`]. Use a fixed base64 string (32 non-identical bytes, `+`/`/`/`=` safe inside the Python triple-quoted string, but remember the file uses `\"` escapes for quotes). `check_bootstrap()` (lines 351-) asserts bootstrap text only; consider also asserting the config literal contains `:key_encryption`.

### Pitfall 5: `verify_test.exs` id-list contract
**What goes wrong:** `test/lockspire/install/verify_test.exs:258` asserts the exact sorted list of check ids; adding `:key_encryption` breaks it, and line 221 requires all checks `:ok` in the happy setup (test.exs KEK makes it pass).
**How to avoid:** Update the expected list to include `:key_encryption`; add tests for absent (`:error`, details mention config key only) and invalid (`:error`, no sentinel value). The setup captures/restores a fixed key list (`[:repo, ... :oban]`) at lines ~185-196; add `:key_encryption` to that restore list.

### Pitfall 6: Adoption-demo KeysLive "Generate" now refuses
**What goes wrong:** The demo has no KEK until Phase 157 (D-14), so generating a key via the demo admin UI returns the generic failure flash. Seeds are unaffected (direct insert, `:allow`).
**How to avoid:** Acceptable per D-14; no demo test clicks generate (grep of examples/scripts found none). Record it in the plan as a known, time-boxed regression of the demo UI, not a bug.

### Pitfall 7: Sealed fixtures changing assertions
**What goes wrong:** Tests asserting on stored plaintext. Grep of `test/` for `Jason.decode.*private_jwk_encrypted`, `binary_to_term.*private_jwk`, `private_jwk_encrypted ==` found none; `keys_test.exs:53,82` only assert it is `nil` after stripping. 48 test files mention the column [VERIFIED: grep -rln count]. Most direct inserts stay plaintext (legacy-read coverage).
**How to avoid:** Seal only in the two shared helpers; run the full `mix test.fast` once after the flip to catch outliers.

### Pitfall 8: `persistent_term` stale in tests
**What goes wrong:** Tests that `Application.put_env(:lockspire, :key_encryption, ...)` without re-putting the persistent term see the old keyset.
**How to avoid:** One helper does both; mark those tests `async: false`.

## Code Examples

### Seal / open skeleton (consistent with the verified contract)
```elixir
# Source: prototype scratchpad/aead.exs + SUMMARY R2. Values quoted: AES-256 key 32B, IV 12B, tag 16B.
def seal(%KeySet{} = ks, kid, plaintext) when is_binary(kid) and is_binary(plaintext) do
  {id, key} = KeySet.current!(ks)                       # raises only on programmer error, no values
  iv = :crypto.strong_rand_bytes(12)
  header = <<"LSK", 1, byte_size(id)::8, id::binary>>
  {ct, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad(header, kid), 16, true)
  {:ok, header <> iv <> tag <> ct}
end

def open(%KeySet{} = ks, kid, bin) when is_binary(bin) do
  with {:ok, %{kek_id: id, iv: iv, tag: tag, ct: ct, header: header}} <- parse(bin),
       {:ok, key} <- KeySet.fetch_key(ks, id),           # {:error, :unknown_kek}
       {:ok, pt} <- decrypt(key, iv, ct, aad(header, kid), tag) do
    {:ok, pt}
  end
end

defp decrypt(key, iv, ct, aad, tag)
     when byte_size(key) == 32 and byte_size(iv) == 12 and byte_size(tag) == 16 do
  case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ct, aad, tag, false) do
    pt when is_binary(pt) -> {:ok, pt}
    _ -> {:error, :decryption_failed}
  end
rescue
  _ -> {:error, :decryption_failed}
end
defp decrypt(_, _, _, _, _), do: {:error, :decryption_failed}
```
(`with` here is total because every non-matching result is a tagged `{:error, _}` from our own functions, so no `WithClauseError` with a value.)

### Map-form decoder shape
```elixir
def decode(%{kid: kid, private_jwk_encrypted: bin}) when is_binary(kid) and is_binary(bin) do
  case KeyEncryption.classify(bin) do
    :envelope -> decode_envelope(kid, bin)    # keyset via Config accessor; kid check on JSON "kid"
    :legacy   -> decode_legacy(bin)           # existing JSON then safe ETF (legacy_plaintext :allow in 155)
  end
rescue _ -> {:error, :invalid_signing_key}
catch _, _ -> {:error, :invalid_signing_key}
end
def decode(_), do: {:error, :invalid_signing_key}
```
Internal reasons stay inside `PrivateJwk`/`KeyEncryption`; the public return stays `{:error, :invalid_signing_key}` (D-02). Phase 156 will need the reason for telemetry; a private `decode_with_reason/1` returning the specific atom (and `decode/1` collapsing it) lets 156 reuse without changing 155's public contract. `legacy_plaintext` handling: 155 only needs `:allow` to pass; `:reject` enforcement is Phase 156, but the config must already accept and carry `:reject`.

### Per-consumer call sites (verified by reading)
| Consumer | File:line | Argument available today | Failure shape to preserve |
|----------|-----------|---------------------------|---------------------------|
| ID token | `protocol/id_token.ex:36` | `signing_key: %{kid:, alg:, private_jwk_encrypted: private_jwk}` destructured in head; the `with` uses `PrivateJwk.decode(private_jwk)` | `{:error, :invalid_signing_key}` — change head to bind the whole map (`signing_key: %{kid: kid} = signing_key`) and pass it |
| Logout token | `protocol/logout_token.ex:35` | same destructuring pattern | `{:error, :invalid_signing_key}` (also `sign(_)` fallback) |
| JARM | `protocol/jarm.ex:55` | `signing_key.private_jwk_encrypted`, whole `signing_key` in scope | `{:error, reason}` passthrough → `:invalid_signing_key` |
| Introspection JWT | `protocol/introspection_jwt.ex:36` | `signing_key` struct in scope | same |
| Access-token signer (all grants) | `protocol/token_exchange/internal/access_token_signer.ex:206-208` | head pattern `{:ok, %{kid:, alg:, private_jwk_encrypted:}}` | on `{:error, reason}` logs `inspect(reason)` and returns a 500 `server_error` `%Error{}` — external shape unchanged, reason must remain an atom |
| JAR decrypt | `protocol/jar.ex:43` | `key` (SigningKey struct from `list_decryption_keys`) | collapses every failure inside a try/rescue to `:decryption_failed`; keep |

Test updates: `private_jwk_test.exs` (rewrite for map form; keep the "never raises" matrix with `%{}`/`nil`/`42`/binary-without-map); `audit_writer_test.exs:449` passes `active_key` (struct) instead of the column; `token_exchange_case.ex` `assert_active_signing_key_fixture` (line ~300) calls `PrivateJwk.decode(active_key.private_jwk_encrypted)` and must pass `active_key`.

### Classify property test (StreamData is available)
```elixir
use ExUnitProperties
property "random binaries and legacy encodings never classify as envelope" do
  check all bin <- binary(), not String.starts_with?(bin, "LSK") do
    assert KeyEncryption.classify(bin) == :legacy
  end
end
property "any LSK-prefixed binary is :envelope (never falls through) and never raises on open" ...
```
Plus fixed cases: `Jason.encode!(map)`, `:erlang.term_to_binary(map)`, `<<>>`, leading-whitespace JSON all `:legacy`. This is the first `ExUnitProperties` user in the repo; `use ExUnitProperties` needs no config. Keep `max_runs` default (100) for the < 30 s quick command.

## Where test KEKs go (research flag, resolved)

- **Library tests:** `config/test.exs` (currently lines 29-34 hold the `config :lockspire` repo/issuer block). Add `config :lockspire, :key_encryption, keys: [{"test-1", ...}, {"test-2", ...}], current: "test-1", legacy_plaintext: :allow`. Derive deterministic non-identical 32-byte material at config-eval time, e.g. `:crypto.hash(:sha256, "lockspire-test-kek-1") |> Base.encode64()` — config files may run code, and this avoids committing opaque base64 while staying test-only. test.exs is runtime-evaluated at `mix` start (it is a Mix config file, not `compile_env` use in `lib/`), consistent with C9.
- **Clean-room provider:** inside the `config.exs` literal in `build_provider.py` (the `config :lockspire, ...` block, ~lines 63-72). Fixed base64 string literal; `legacy_plaintext: :allow` is fine (fresh DB). Python string uses `\"` escapes.
- **Clean-room confidential client:** does not run Lockspire (Bandit client only); no KEK.
- **Adoption demo:** none in 155 (D-14).
- `lockspire.verify` in the clean-room runs through `run_child_command(child, environment, "lockspire.verify")` in the same child project, so it sees the `config.exs` KEK (no runtime.exs in play). On a real host the KEK lives in `runtime.exs`; `@requirements ["app.config"]` loads runtime config too, so `Config.key_encryption!/0` works there.

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Plaintext JWK in `private_jwk_encrypted` | Envelope `LSK\x01` AES-256-GCM, AAD binds header + kid | Closes CR-01 for new keys |
| `PrivateJwk.decode(binary)` | `PrivateJwk.decode(%{kid:, private_jwk_encrypted:})` | kid pairing mandatory |
| Bandit 1.12.5 (2 open GHSAs in hosts) | 1.13.1 | audit-clean hosts for Bandit |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `legacy_plaintext: :allow` with empty/absent `keys` while the block is present should be invalid (not "absent") | Pattern 2 | If a host sets only `legacy_plaintext`, boot would fail; low impact, confirm in plan |
| A2 | `:persistent_term` fallback-to-fresh-validate when unset is acceptable for tasks/release `eval` | Pattern 3 | Slightly slower decode when app not started; design choice only |
| A3 | mint 1.9.3 advisories in host locks are out of DEP-01 scope | Open Questions | If the user wants audit-clean hosts, an extra `mix deps.update mint` is required |
| A4 | 1.13.1/1.6.0 are safe given they are hours old (no soak) | Bandit section | e2e failure would surface it; fallback is to hold the bump |

Everything else above is tagged `[VERIFIED]`/`[CITED]` from tool output or the cited changelog this session.

## Open Questions

1. **Should 155-01 also update `mint` in the three host locks?**
   - Known: `mix hex.audit` flags mint 1.9.3 (two MEDIUM advisories) in the compat fixture; the hosts' locks pin the same version. Mint is a client library (the hosts use it only via test clients).
   - Recommendation: out of scope for DEP-01 (requirement text names bandit/thousand_island/hpax). Surface to the user as a one-line follow-up todo rather than widening the "first, standalone, green" plan.
2. **Compat fixture handling** — recommend `mix deps.unlock bandit thousand_island` (+ `mix deps.update hpax` optional) rather than a bandit bump, because the entries are unused. Planner to confirm this satisfies "refresh its lock" for DEP-01 / ROADMAP success criterion 1 (which names only the demo and clean-room hosts).
3. **Empty-`keys` block semantics** (A1) — confirm during plan.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all | yes | 1.20.4/OTP 29.1.1 local; also 1.19.5-otp-28, 1.18.4-otp-27 installed | — |
| CI toolchain | CI | pinned | Elixir 1.19.5 / OTP 28 (primary); MIN 1.18.4 / OTP 27 | — |
| PostgreSQL | `mix test` | assumed (tests use `Lockspire.TestRepo`) | not probed | `mix test.setup` |
| Hex network | `deps.update` | yes (hex.pm API reachable) | — | — |
| Python 3 | clean-room e2e | assumed present | not probed | — |

Run commands with `export HEX_HOME=/private/tmp/lockspire-hex ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1` (the repo's `.tool-versions` only lists nodejs, so asdf requires these env vars).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.20.4 local / 1.19.5 CI) + StreamData 1.4.0 (test-only, present, unused so far) |
| Config file | `config/test.exs`; `test_load_filters` excludes `test/clean_room/` |
| Quick run command | `MIX_ENV=test mix test <paths>` (after `mix test.setup` once) |
| Full suite command | `MIX_ENV=test mix test.fast` (= `test.setup` + `test test/lockspire test/mix test/integration`); `mix ci` and `mix qa.dialyzer` as gates |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEP-01 | Hosts pinned `== 1.13.1`, locks show bandit 1.13.1 / thousand_island 1.6.0 / hpax 1.1.0, e2e green | e2e + lock assertions | `mix test.clean-room.e2e`; in each host `mix deps.get --check-locked && mix compile --warnings-as-errors`; `git diff --exit-code -- mix.lock examples/adoption_demo/mix.lock compatibility/phoenix_1_8_live_view_1_1/mix.lock`; `grep -n '"bandit"' <lock>` | existing CI jobs (adoption-demo, compatibility, clean-room); no new file |
| KEK-01 | Each invalid case (bad base64, wrong length, dup id, dup material, unknown `current`, unknown mode, `:reject` w/o keys, all-identical bytes, bad id charset) raises naming key, sentinel value absent from message and `Exception.format` | unit | `MIX_ENV=test mix test test/lockspire/config_key_encryption_test.exs` | Wave 0 |
| KEK-01 | Application boot raises on invalid config; caches valid keyset | unit/integration (non-async) | `MIX_ENV=test mix test test/lockspire/application_key_encryption_test.exs` (starts app supervisor logic via a callable `Lockspire.Application.validate_key_encryption!/0` or equivalent testable seam, since the app is already started in tests) | Wave 0 |
| KEK-02 | Absent config: `generate_key` → `{:error, :key_encryption_not_configured}` and zero rows inserted; legacy-plaintext row still signs; boot warning via `ExUnit.CaptureLog` | integration | `MIX_ENV=test mix test test/lockspire/admin/keys_test.exs` (extend) | extend existing |
| KEK-02 | `Install.Verify` `:key_encryption` check: ok / absent `:error` / invalid `:error`, id list updated | unit | `MIX_ENV=test mix test test/lockspire/install/verify_test.exs` | extend existing (update id list at line 258) |
| KEK-02 | `mix lockspire.doctor key_encryption`: reports present/absent/invalid, no value in output, exit semantics (diagnostic, non-raising for absent) | mix task | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_key_encryption_test.exs` (pattern: `lockspire_doctor_token_format_test.exs`; `Mix.Task.reenable("lockspire.doctor")` + `...key_encryption`) | Wave 0 |
| ENC-01 | New key row starts with `<<"LSK", 1, byte_size(id), id::binary>>` for current id; two generates differ; AAD binds kid | integration | `MIX_ENV=test mix test test/lockspire/admin/keys_test.exs test/lockspire/security/key_encryption_test.exs` | Wave 0 (cipher test) + extend |
| ENC-02 | Per-consumer envelope + legacy read, per-consumer error shape: ID token, logout token, JARM, introspection JWT, access-token signer, JAR (`:enc` key via `list_decryption_keys`) | unit/integration | `MIX_ENV=test mix test test/lockspire/protocol/private_jwk_test.exs test/lockspire/protocol/id_token_test.exs test/lockspire/protocol/logout_token_test.exs test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/introspection_jwt_test.exs test/lockspire/protocol/access_token_signer_test.exs test/lockspire/protocol/jar_test.exs` (verify actual file names with `ls test/lockspire/protocol` at plan time; extend, do not duplicate) | extend existing |
| ENC-02 | JWKS/discovery never decrypt (no `Config.key_encryption*` / `KeyEncryption` reference from `KeyCache`, JWKS, discovery modules) | structural + behavior | `MIX_ENV=test mix test test/lockspire/architecture_fitness_test.exs` (add AST/grep fitness assertion in style of existing host-repo-call checks) and `test/lockspire/key_cache_test.exs` | extend existing |
| ENC-03 | Tamper ct, tamper tag, swapped between rows (AAD), forged-kid JSON (`:kid_mismatch`), unknown KEK id, truncated tag (parse-level `:malformed_envelope`), short-IV/short-key forged keyset returns error not raise | unit (pure, async) | `MIX_ENV=test mix test test/lockspire/security/key_encryption_test.exs` | Wave 0 |
| ENC-03 | Property: random binaries / JSON / ETF never `:envelope`; any `"LSK"`-prefixed binary is `:envelope` and `open` never raises | property | same file | Wave 0 |
| Inspect redaction (D-10) | `inspect(%SigningKey{private_jwk_encrypted: "SENTINEL"})` and `SigningKeyRecord` omit the field; `inspect(%KeySet{})` shows no key bytes | unit | `MIX_ENV=test mix test test/lockspire/domain/signing_key_inspect_test.exs` | Wave 0 |
| Clean room (D-11) | Provider boots, `Admin.generate_key(:sig)` succeeds, `lockspire.verify` passes with KEK | e2e | `mix test.clean-room.e2e` | existing script, edit `build_provider.py` |

### Sampling Rate
- **Per task commit:** the touched test file(s) via `MIX_ENV=test mix test <paths>` (< 30 s each); for 155-01 the per-host `deps.get --check-locked` + compile.
- **Per wave/plan merge:** `MIX_ENV=test mix test.fast`; `mix qa` (format, compile warnings-as-errors, architecture cycles, credo, sobelow) and `mix qa.dialyzer`.
- **Phase gate:** `mix ci` (includes `test.fast` and `test.integration`) plus `mix test.clean-room.e2e`; full suite green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/lockspire/security/key_encryption_test.exs` — ENC-01/03 incl. property tests (first `ExUnitProperties` use)
- [ ] `test/lockspire/config_key_encryption_test.exs` — KEK-01 validation matrix with sentinel-leak assertions
- [ ] `test/lockspire/application_key_encryption_test.exs` — boot raise/warn/cache (needs a testable validate seam)
- [ ] `test/mix/tasks/lockspire_doctor_key_encryption_test.exs` — D-07
- [ ] `test/lockspire/domain/signing_key_inspect_test.exs` — D-10
- [ ] `test/support/key_encryption_helpers.ex` — `put_key_encryption/1` (env + persistent_term + on_exit restore), plus a `seal_private_jwk/2` used by the two shared seeding helpers
- [ ] Framework install: none (StreamData already present)

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | partly | `generate_key` remains an admin-only command; refusal path writes nothing |
| V5 Input Validation | yes | Strict config validation (rule list above); exact-size envelope parse; non-bang decoders |
| V6 Cryptography | yes | OTP `:crypto` AES-256-GCM, random 12-byte IV per seal, 16-byte tag, AAD binds header+kid; no custom primitives; KEK never from `secret_key_base` |
| V7 Error handling & logging | yes | Name-only exceptions; no `inspect` of config/ciphertext; `@derive {Inspect, except: [...]}`; redacting `Inspect` on KeySet |
| V14 Configuration | yes | KEK only in runtime config, never `compile_env` |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Row swap / ciphertext transplant | Tampering | AAD includes `kid` + post-decrypt `kid` equality |
| Header/KEK-id downgrade | Tampering | AAD includes header through `kek_id` |
| Nonce reuse | Info disclosure | Fresh `strong_rand_bytes(12)` per seal; no caller-supplied IV |
| Truncated/short tag acceptance | Tampering | Exact `binary-size(16)` match (prototype shows `:crypto` accepts shorter tags) |
| Config value leak via crash report | Info disclosure | Name-only `fail!/2`; no value-carrying exceptions (prototype) |
| Prefix-confusion fall-through to legacy parsers | Tampering/Elevation | Strict classify; malformed envelope never retried as JSON/ETF |
| Algorithm/format confusion via stored header | Spoofing | Fixed `LSK`+version; no JWE `alg` header |
| Key material in logs | Info disclosure | Reasons are atoms only; `Logger.error(inspect(reason))` sites stay atom-only |

## Sources

### Primary (HIGH confidence)
- Local prototypes on OTP 27.3.4.15 / 28.5 / 29.1.1: `scratchpad/aead.exs` (crypto contract), `scratchpad/leak.exs` (exception leakage).
- hex.pm API: bandit 1.13.1 requirements (`hpax ~> 1.1`, `thousand_island ~> 1.6`, `plug ~> 1.18`), release dates for bandit/thousand_island/hpax.
- Repo files read this session: `lib/lockspire/protocol/private_jwk.ex`, `application.ex`, `admin/keys.ex:37-79`, `install/verify.ex:40-110`, `install/verify/check.ex`, `mix/tasks/lockspire.doctor.ex`, `lockspire.doctor.token_format.ex`, `lockspire.verify.ex`, the six consumer call sites, `storage/ecto/repository/signing_key_store.ex`, `domain/signing_key.ex`, `storage/ecto/signing_key_record.ex`, `config/test.exs`, `config/config.exs`, `mix.exs`, `scripts/acceptance/clean_room/build_provider.py`, `test/support/seeding_helpers.ex`, `test/support/token_exchange_case.ex`, `test/lockspire/install/verify_test.exs`, `test/lockspire/protocol/private_jwk_test.exs`, `.github/workflows/ci.yml`, `scripts/ci/check_architecture_topology.sh`.
- `mix hex.audit`, `mix deps.unlock --check-unused`, `mix deps.tree` run in `compatibility/phoenix_1_8_live_view_1_1`.

### Secondary (MEDIUM confidence)
- Bandit CHANGELOG (github.com/mtrudel/bandit, fetched via a summarizing fetch tool; entries paraphrased by the tool): no breaking changes listed for 1.13.0/1.13.1.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack / crypto contract: HIGH — prototyped on three OTP majors
- Architecture / call sites: HIGH — read directly
- Bandit 1.13.1: MEDIUM — changelog summarized by tool, released today, not soaked
- Pitfalls: HIGH

**Research date:** 2026-10-15
**Valid until:** 2026-10-22 for Bandit specifics (fast-moving); 30 days for crypto/architecture findings.
