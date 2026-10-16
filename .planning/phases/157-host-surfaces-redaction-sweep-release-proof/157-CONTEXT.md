# Phase 157: Host Surfaces, Redaction Sweep & Release Proof - Context

**Gathered:** 2026-10-16 (assumptions mode, research fan-out: codebase analysis + ecosystem precedent — Rails AR Encryption, Mastodon, Ory Hydra, cloak_ecto, Doorkeeper, Django, Vault transit, EEF Security WG, Phoenix runtime.exs conventions, Conventional Commits/Release Please)
**Status:** Ready for planning

<domain>
## Phase Boundary

Fresh installs, the adoption demo and the clean-room provider host store only envelopes by default. No private key material, envelope ciphertext or KEK value appears anywhere an operator, log reader or host telemetry handler looks. CI and docs prove the whole upgrade path, so the release can ship and CR-01 can close. Requirements: RED-01, HOST-01, PROOF-01, DOC-01, SAFE-01. This phase owns the final SAFE-01 proof for milestone v1.43.

Out of scope for this phase:
- admin UI copy (KEY-UI-01, deferred);
- `mix lockspire.gen.kek` (KEK-03);
- a KMS/Vault provider (KEK-04);
- `{:system, "ENV"}` resolution (KEK-05);
- a decrypt/downgrade task;
- `Process.flag(:sensitive, true)`;
- any protocol behavior change.
</domain>

<decisions>
## Implementation Decisions

### Binding upstream design
- **D-00:** Research R1–R8 and "Other resolutions" in `.planning/research/v1.43-key-encryption/SUMMARY.md`, Phase 155 D-00..D-20 and Phase 156 D-00..D-28 stay locked. Under R8, absent config boots and signs, and `generate_key` refuses. SAFE-01 holds in full. No new deps. No new admin copy, so `PRODUCT.md` and the vocabulary contract stay unchanged.

### Redaction sweep (157-01, RED-01)
- **D-01:** **Close the repo-telemetry residual that Phase 156 handed over.**
  - These `SigningKeyStore` paths must run with `sensitive: true` (`log: false`, `telemetry_event: nil`) through `Repository.Support` (`support.ex:33-50`):
    - `publish_key` insert;
    - `fetch_active_signing_key`;
    - `fetch_signing_key_by_id`;
    - `list_decryption_keys`;
    - `locked_key`;
    - `active_keys_for_update`;
    - `list_signing_keys`, which must default to sensitive.
  - That covers every path that selects or binds `private_jwk_encrypted`.
  - Accepted cost: these queries lose Ecto's per-query log line and telemetry event. Lockspire's own `[:lockspire, :key, …]` telemetry stays.
  - Reference: `156-VERIFICATION.md` "Residual (accepted, deferred)" and `156-REVIEW-DISPOSITION.md`.
- **D-02:** **Fix changeset leakage at the schema.**
  - Add `redact: true` to `field(:private_jwk_encrypted, …)` in `SigningKeyRecord`. Keep the `@derive {Inspect, except: …}` on the domain `SigningKey`.
  - The researcher must confirm how Ecto 3.13 combines `redact: true` with an explicit `@derive Inspect` on the same schema: which one wins, and whether they conflict at compile time. Pick whichever combination masks both `inspect(record)` and `inspect(changeset)` (`changes` and `params`).
  - Prove the result with a test: inspect a `{:error, changeset}` from a forced `unique_constraint(:kid)` conflict through `Lockspire.Admin.generate_key/1`.
- **D-03:** **`Lockspire.Redaction` additions** go into both `@telemetry_drop_keys` and `@audit_drop_keys`, in atom and string forms:
  - `private_jwk_encrypted`, `private_jwk`, `private_key`, `jwk`, `kek`, `key_encryption`, `key_encryption_key`, `envelope`, `ciphertext`.
  - Also add one value-level guard that drops any binary beginning with `<<"LSK", 1>>`, as defense in depth.
  - **Never** drop `kid`, `kek_id`, `previous_kek_id` or `key_id`. Phase 156's D-24..D-28 operator contract depends on them.
  - Do not globally drop one-letter JWK members (`d`, `k`, …). Admin views already strip those via `@private_jwk_members`.
- **D-04:** **Guard the decode→JOSE boundary once.**
  - Add one helper next to `PrivateJwk.decode` that turns the decoded map into a JOSE key and returns `{:error, :invalid_signing_key}` on any raise or throw.
  - The helper must not put the map in the error, the log, or a re-raised exception. Re-raise without arguments, following the EEF "strip args from crypto exceptions" guidance and the shape of the 156 IN-02 `Verify.safely` fix.
  - All six consumers use the helper: ID token, logout token, JARM, introspection JWT, the token-exchange access-token signer, and JAR.
  - The researcher should confirm what JOSE 1.11 `JOSE.JWK.from_map/1` raises on malformed maps, and whether the map appears in formatted stack frames. This matters because Oban persists formatted errors in `oban_jobs.errors` for the backchannel logout worker.
- **D-05:** **One canary sweep.** Extend `test/lockspire/security/key_material_leak_test.exs` instead of starting a new harness.
  - Seed a sentinel `d` and a sentinel KEK, then drive:
    - generate, publish, activate, `list_keys`, and signing reads for all six consumers;
    - reencrypt, `--check` and doctor;
    - a forced changeset error;
    - a sealed malformed JWK through each consumer, including the Oban logout worker.
  - Assert that neither the sentinel (raw, base64 and base64url) nor `LSK\x01` bytes ever appear in:
    - `capture_log` at debug level;
    - any attached telemetry event, including `[:repo, :query]`;
    - audit rows and Oban job errors;
    - `inspect` of every struct and changeset;
    - KeysLive and OverviewLive rendered HTML and socket assigns;
    - exception messages.
  - Keep the matching in one helper so CI cites a single proof point.
- **D-06:** Keep the locked decision: no `Process.flag(:sensitive, true)` and no change to `format_status`, because `KeyCache` holds only public JWKs, which a fitness test enforces. Document crash-dump hygiene instead (D-16). Admin assigns are already clean (`to_view` nils the column), so prove that in D-05 rather than changing code.

### Host surfaces (157-02, HOST-01)
- **D-07:** **`mix lockspire.install` prints the runtime block; it never patches `config/runtime.exs`.**
  - The generator creates its own files and prints wiring steps. It never edits host-owned files (`generators/install.ex:124-136`). `runtime.exs` cannot `import_config`. The managed `config/lockspire.exs` is compile-time config, so it must never hold a KEK (C9).
  - Add a numbered next step that prints this block:
    ```elixir
    # config/runtime.exs
    if config_env() == :prod do
      config :lockspire, :key_encryption,
        keys: [{"<YYYY-MM at install>", System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY") ||
          raise("LOCKSPIRE_KEY_ENCRYPTION_KEY is missing. Generate one with: openssl rand -base64 32")}],
        current: "<YYYY-MM at install>",
        legacy_plaintext: :reject
    end
    ```
  - Pair it with a dev/test variant that reads the same env var and falls back to a random 32-byte base64 literal generated per install. This follows the Phoenix `secret_key_base` dev.exs precedent: per project, never shared across installs, and marked `# dev/test only — never reuse in prod`. It means `mix phx.server` and the admin Generate button work on the first try.
  - Prod fails closed. A fresh install has no plaintext rows, so `:reject` costs nothing.
  - Assert the printed output in `test/integration/install_generator_test.exs`, including that two runs print different dev literals.
- **D-08:** **The env var is `LOCKSPIRE_KEY_ENCRYPTION_KEY`.**
  - It has the library prefix, mirrors the config key, and follows the `SECRET_KEY_BASE` style.
  - KEK ids are `YYYY-MM` strings, matching the R1 example.
  - The rotation docs show a second var by convention, `LOCKSPIRE_KEY_ENCRYPTION_KEY_<ID>` or `_NEXT`. The generator never emits a second var.
  - Key generation commands to document, with no new tooling:
    - `openssl rand -base64 32`
    - `elixir -e 'IO.puts(Base.encode64(:crypto.strong_rand_bytes(32)))'`
  - Warn that `mix phx.gen.secret` output is not 32 bytes of base64. The existing config validation already rejects wrong-length keys; check that its error names these commands, and add them if it doesn't. That error text is not admin UI copy.
- **D-09:** **Adoption demo**
  - Config: `examples/adoption_demo/config/config.exs` reads `System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY", "<fixed demo-only literal>")` with `legacy_plaintext: :reject`, following the demo's existing `SECRET_KEY_BASE` literal-fallback pattern. Add a comment marking it demo-only, and document the var as demo-only in `docker-compose.yml`. This closes AR-03.
  - Seeds: rewrite them to create every signing key through the public API (`Lockspire.Admin.generate_key/1` → publish → activate, then retire or supersede to reach the retiring and retired display states), mirroring `clean_room_provider/bootstrap.ex:4-7`.
    - Delete the ETF plaintext insert (`seeds.exs:78-98`) and the `<<1>>` placeholder rows (`:209-256`).
    - Do the same audit for `conformance_seeds.exs:68`.
    - Random kids replace fixed ones. Update any doc prose that names `adoption-demo-rs256`.
    - If losing the ES256 display row matters to a page, generate it via `generate_key(:sig)` under the server alg policy rather than a raw insert.
- **D-10:** **Clean-room provider host**
  - Remove the literal `clean-room-1` KEK from `scripts/acceptance/clean_room/build_provider.py`. Read `System.fetch_env!("LOCKSPIRE_KEY_ENCRYPTION_KEY")` instead, with the value set per run in `prepare_provider`'s environment from `base64(os.urandom(32))`.
  - Register that value with the clean-room `Redactor`/`register_secret`, so `scan_evidence` fails if the KEK appears in any evidence.
  - Switch to `legacy_plaintext: :reject` and update the `check_bootstrap` source assertion.
  - This closes AR-02 and IN-03.

### Proof and SAFE-01 gate (157-03, PROOF-01, SAFE-01)
- **D-11:** **One in-repo upgrade journey test**, tagged `@moduletag :integration`, which the CI integration partition already runs (`scripts/ci/run_test_matrix.sh:124-126`). Steps:
  1. Seed legacy JSON and ETF rows for `:sig` and `:enc`, using `key_encryption_helpers.ex`.
  2. Under `:allow`, sign or decrypt with all six consumers.
  3. Run `Mix.Tasks.Lockspire.Keys.Reencrypt.run([])`, then `["--check"]`, and expect exit 0.
  4. Assert at byte level that every stored `private_jwk_encrypted` starts with `"LSK" <> <<1>>` and contains no plaintext `"d"`/`"k"` member or base64url private value.
  5. Flip to `:reject` and repeat all six.
  6. Rotate: add `k2` non-current, switch current, re-encrypt, `--check`, assert zero rows remain on `k1`, remove `k1`.
  7. Repeat all six with the same kids.

  Do not attempt a real-host upgrade from a pre-1.43 Hex release. There is no pre-1.43 package to boot in the harness, and unit seeding of legacy rows is faithful to the bytes 1.5.1 wrote.
- **D-12:** **Real-host checks stay cheap.**
  - The `adoption-demo` CI job runs `mix lockspire.keys.reencrypt --check` (exit 0) and `mix lockspire.doctor key_encryption` after `ecto.setup` and the smoke run (`ci.yml:464-489`).
  - The clean-room provider journey runs the same two commands after bootstrap, next to the existing `lockspire.verify`.
  - Together these prove that fresh installs store only current-KEK envelopes under `:reject`. `--check` opens every envelope.
- **D-13:** **The SAFE-01 gate runs at verification time against the `v1.42` tag** and is recorded in `157-VERIFICATION.md`. Do not add a permanent tag-relative CI test, which would rot at the next deliberate dependency bump. The gate covers:
  - `git diff --exit-code v1.42 -- mix.exs mix.lock priv/repo/migrations`, scoped to dependency lines and with docs extras excluded;
  - the column is still named `private_jwk_encrypted`;
  - the fitness guards (`architecture_fitness_test.exs`: no decrypt in JWKS/KeyCache, single stored-key reader; no `compile_env` for the KEK);
  - `mix test --include integration`, `mix qa` on CI Elixir 1.19.5-otp-28, Dialyzer, and the existing security-default and protocol suites, all with zero edits to their assertions.

### Docs and release (157-04, DOC-01)
- **D-14:** **One topic-named guide: `docs/upgrading/signing-key-encryption.md`.** It follows the `docs/upgrading/storage-prefix.md` precedent and goes in the Upgrade group. `mix.exs` extras and `groups_for_extras` change in the same commit (`documentation_contract_test.exs:11-51`). Use the topic name, not the milestone name, because v1.43 ≠ Hex 1.6.0. Structure, where every step has a command and its expected result:
  1. **Before you start:** generate the KEK and store it in your secret manager, separately from DB backups. Take a fresh DB backup. Don't generate signing keys mid-rollout (C5).
  2. **Four-step upgrade order (DOC-01):**
     1. add the `:key_encryption` config with `:allow` and deploy;
     2. `reencrypt --dry-run`, then `reencrypt`;
     3. `reencrypt --check`, which must exit 0;
     4. flip to `:reject`, deploy, and run doctor again.

     For releases, show both `bin/app rpc "Lockspire.Admin.Keys.reencrypt(...)"` and the stopped-VM `Ecto.Migrator.with_repo` snippet, and warn that bare `eval` does not start the repo (156 D-13). Name `--check` as the required verification gate, which goes beyond cloak_ecto's missing verify step.
  3. **KEK rotation runbook (five steps):** add the new key, make it current, re-encrypt, `--check` shows zero rows on the old id, remove the old key. Use Hydra's lesson as the rule: *never remove an old KEK before `--check` passes; keep it in your secret manager as long as you keep backups written under it.*
  4. **Warnings, verbatim-strength:**
     - **Backup remanence:** backups, WAL, replicas, snapshots and dumps from before re-encryption still hold usable plaintext private keys. Expire them, or after the flip, generate new signing keys and retire the previously plaintext ones. That is the only full remedy.
     - **Rollback:** code before 1.6.0 cannot read envelopes, and there is no decrypt task. Before the flip, the rollback is "set `:allow`", never "remove the config".
     - **KEK loss:** if every configured KEK is lost, the signing keys are unrecoverable. Generate new keys; tokens signed by the old ones stop verifying.
     - **Separate KEK backup:** follow the GitLab wording, "storing encrypted information in the same location as its key defeats the purpose".
  5. **Operational hygiene:**
     - Crash dumps (`erl_crash.dump`) can contain process and persistent_term memory. Restrict dump-file permissions, or set `ERL_CRASH_DUMP_SECONDS=0` where policy demands it.
     - The raw KEK stays in app env (AR-01). Anyone with a remote shell or Observer can read it.
     - Never list `LOCKSPIRE_KEY_ENCRYPTION_KEY` in LiveDashboard `env_keys`.
- **D-15:** Update the surrounding docs:
  - **`docs/architecture.md`:** correct the `:355` "encrypted key material where appropriate" line and the `:331` "Bounded plaintext" invariant row. Keep the section order and exactly 4 mermaid diagrams.
  - **`docs/code-walkthrough.md`:** edit the stale signing excerpt at `:463-490` **in place**. The doc contract caps Elixir blocks at 18, and there are 18 already. Excerpts must parse.
  - **`docs/telemetry.md`:** add a `[:lockspire, :key, …]` section stating that hot-path events (legacy_read, refusal, decryption failure) have no audit mirror. Correct the "every event is mirrored" claim.
  - **`SECURITY.md` "Secure defaults":** say that signing keys are encrypted at rest under a host-held KEK.
  - **`docs/install-and-onboard.md`:** add the runtime KEK step.
- **D-16:** **The release is non-breaking `feat` → 1.6.0.**
  - R8 designed the upgrade to be compatible: absent config boots and signs. `generate_key` was already a `{:ok, _} | {:error, _}` API, and the new refusal is a documented error reason.
  - Squash title, following the v1.42 shape: `feat(keys): encrypt private signing keys at rest under a host-held key (v1.43)`. No `!` and no `BREAKING CHANGE` footer.
  - The PR body leads with an **"Upgrade notes — action required"** block: configure the KEK; until you do, Generate refuses and verify/doctor fail. Then come the four steps, the verification command, rollback, backups, and a link to the guide.
  - Write the release-note text in `157-04` as a ready-to-paste file in the phase dir. The researcher should confirm whether Release Please reads squash-body footers for the elixir release type, so the body does not trigger a major bump by accident.

### Plan shape
- **D-17:** Four plans in two waves, as the roadmap suggests:
  - **Wave 1:** 157-01 (Redaction, D-01..D-06) and 157-02 (Hosts, D-07..D-10). Their files do not overlap.
  - **Wave 2:** 157-03 (Proof and SAFE-01 gate, D-11..D-13) and 157-04 (Docs and release note, D-14..D-16).

  Only 157-04 touches `mix.exs` and the `docs/` files. 157-02 may edit `docs/adoption-demo*.md` prose only where seeds change kids; otherwise leave doc edits to 157-04 to avoid conflicts. R7 split candidate: if 157-04 overruns, split the guide from the architecture, walkthrough and SECURITY updates.

### Claude's Discretion
- The helper name and module placement for D-04 and for the D-05 sentinel matcher.
- The exact printed wording of the D-07 next step, within the shape above.
- Whether the D-12 demo checks run as separate CI steps or inside the existing smoke script.
- How the demo seeds reach the retiring and retired display states through public API calls.

### Folded Todos
None.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`: Phase 157 section, success criteria and pitfalls owned (C5, C7, C8).
- `.planning/REQUIREMENTS.md`: RED-01, HOST-01, PROOF-01, DOC-01, SAFE-01; Future KEY-UI-01 and KEK-03..05.
- `.planning/research/v1.43-key-encryption/SUMMARY.md` (R1–R8, Other resolutions, Out of Scope) and `PITFALLS.md` (C5, C7, C8, C9, M1, M8, m5).
- `.planning/phases/155-crypto-core-config-seam-bandit-baseline/155-CONTEXT.md`, `155-SECURITY.md` (AR-01..03) and `155-REVIEW-DISPOSITION.md` (IN-03).
- `.planning/phases/156-legacy-migration-kek-rotation-plaintext-refusal/156-CONTEXT.md` (D-11a, D-13, D-18, D-22..D-28), `156-VERIFICATION.md` and `156-REVIEW-DISPOSITION.md` (the residual handed to 157).
- `lib/lockspire/redaction.ex`
- `lib/lockspire/storage/ecto/repository/signing_key_store.ex` and `repository/support.ex`
- `lib/lockspire/storage/ecto/signing_key_record.ex` and `lib/lockspire/domain/signing_key.ex`
- `lib/lockspire/admin/keys.ex`
- `lib/lockspire/protocol/private_jwk.ex` and the six consumers:
  - `protocol/id_token.ex`
  - `protocol/logout_token.ex`
  - `protocol/jarm.ex`
  - `protocol/introspection_jwt.ex`
  - `protocol/jar.ex`
  - `token_exchange/internal/access_token_signer.ex`
- `lib/lockspire/generators/install.ex`, `priv/templates/lockspire.install/config.exs`, `test/integration/install_generator_test.exs`
- `examples/adoption_demo/config/config.exs`, `examples/adoption_demo/priv/repo/seeds.exs`, `conformance_seeds.exs`, `docker-compose.yml`
- `scripts/acceptance/clean_room/build_provider.py`, `scripts/acceptance/clean_room_saas_journey.py`, `scripts/acceptance/clean_room/redaction.py`, `test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex`
- `test/lockspire/security/key_material_leak_test.exs`, `test/lockspire/protocol/envelope_signing_consumers_test.exs`, `test/mix/tasks/lockspire_keys_reencrypt_test.exs`, `test/support/key_encryption_helpers.ex`, `test/support/telemetry_capture.ex`
- `test/lockspire/documentation_contract_test.exs`, `test/lockspire/architecture_fitness_test.exs`
- `.github/workflows/ci.yml` (lines 74-75, 184-187, 271-345, 399-489) and `scripts/ci/run_test_matrix.sh`
- `docs/upgrading/storage-prefix.md` (style precedent), `docs/architecture.md`, `docs/code-walkthrough.md`, `docs/telemetry.md`, `docs/install-and-onboard.md`, `SECURITY.md`, `mix.exs` (docs extras and groups)
- `release-please-config.json` and `.release-please-manifest.json` (currently 1.5.1)

External sources the docs should echo:
- Rails AR Encryption guide
- Ory Hydra secrets rotation
- cloak_ecto rotate_keys
- Doorkeeper initializer template
- EEF Security WG sensitive data and crash dumps: https://security.erlef.org/secure_coding_and_deployment_hardening/sensitive_data
- GitLab backup/secrets docs
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Sentinel leak harness:** `test/lockspire/security/key_material_leak_test.exs` covers telemetry, repo query params and results, the debug repo log, audit rows and `capture_log`.
- **Telemetry capture:** `test/support/telemetry_capture.ex` (`attach_many`).
- **KEK test helpers:** `test/support/key_encryption_helpers.ex` provides `put_key_encryption/1`, `legacy_json_row`, `sealed_row`, `insert_signing_key_row!` and `reset_decode_warnings/0`.
- **Sensitive query switch:** `Repository.Support` (`support.ex:33-50`).
- **Admin stripping:** `admin/keys.ex:60` (`@private_jwk_members`) and `:348-424` (`to_view`, `to_detail_view`).
- **Inspect protections:** `domain/signing_key.ex:29`, `signing_key_record.ex:12`, `security/key_encryption/key_set_inspect.ex`.
- **Repo-starting runner:** `Lockspire.Install.RepoRunner`, used by `doctor key_encryption`. `reencrypt` uses `Ecto.Migrator.with_repo`.
- **Public-API key seeding:** `clean_room_provider/bootstrap.ex:4-7`.
- **Clean-room secret scanning:** `register_secret` / `scan_evidence` in `clean_room_saas_journey.py:63,336-376`.

### Established Patterns
- Generators create their own files and print host wiring. They never patch host-owned files.
- Upgrade guides are topic-named under `docs/upgrading/`. The doc contract test enforces extras, groups, packaging, architecture section order, the diagram count and the walkthrough block count.
- Squash title = changelog line (Release Please, `bump-minor-pre-major: false`).
- Operator surfaces carry only `kid`, KEK id, counts and reason atoms.

### Integration Points
- CI integration partition: `--only integration` plus clean-room. Adoption-demo job: `ci.yml:399-489`.
- KEK cache: `application.ex:26-44` holds the `KeySet` in `:persistent_term`. The raw base64 remains in app env (AR-01, documented and not fixed).
- LiveDashboard: only Lockspire's optional metrics page uses it. The demo and clean-room hosts do not mount it.
</code_context>

<specifics>
## Specific Ideas

- The user asked for a full research fan-out with one coherent recommendation bundle to follow automatically, with no menus. Every medium-impact choice above was resolved on precedent. The two candidates for escalation (semver bump, and whether the generator patches files) were settled by existing locked decisions: R8, and the generator ownership boundary.
- The design follows the ecosystem pattern: a key list where the current key encrypts and all keys decrypt, a legacy-tolerant mode for migration only, then strict mode.
- Lockspire goes beyond its peers in two places. `--check` is a verification gate that cloak_ecto lacks, and AAD binds the envelope to the row's `kid`. The upgrade guide should say so plainly.
</specifics>

<deferred>
## Deferred Ideas

- KEY-UI-01: a "Key protection" line on the admin Keys pages, which needs a PRODUCT.md vocabulary entry.
- KEK-03: `mix lockspire.gen.kek`.
- KEK-04: a KMS/Vault provider.
- KEK-05: `{:system, "ENV"}` resolution, which would remove the raw KEK from app env (AR-01).
- Boot warning while `legacy_plaintext: :allow` persists after zero legacy rows remain (Doorkeeper-style nag). This would be new runtime behavior, so it waits for a later milestone.
- `docs/upgrading/v1.37.md` exists but is not in the `mix.exs` extras, and the contract test misses it. This is unrelated doc hygiene for a later milestone.

### Reviewed Todos (not folded)
- `2026-10-16-mix-tasks-start-repo.md`: install-DX fix for `lockspire.client.create`, `doctor token_format` and `doctor remote_jwks`. The key-encryption tasks this phase relies on already start the repo (`RepoRunner`, `with_repo`). Folding the fix in would widen a security release, so it stays pending.
- `2026-10-13-audit-dcr-default-lifetime-semantics.md`: a protocol change, which SAFE-01 excludes. It stays deferred to a later protocol milestone.
</deferred>

## Research flags for gsd-phase-researcher
1. Ecto 3.13: how `redact: true` interacts with an explicit `@derive Inspect` on the same schema, and whether `changeset.params` are masked (D-02).
2. JOSE 1.11: what `JOSE.JWK.from_map/1` raises on malformed maps, and whether the arguments appear in formatted stacktraces, Logger crash reports or Oban `errors` (D-04).
3. Erlang crash dumps: whether they include `:persistent_term` and app env (`ac_tab`). Confirm the `ERL_CRASH_DUMP_SECONDS` and `ERL_CRASH_DUMP_BYTES` knobs (D-14 wording).
4. Release Please (elixir release-type, squash merges): whether body footers are parsed, so the release-note body cannot trigger a major bump by accident (D-16).
