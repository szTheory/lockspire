# Phase 157: Host Surfaces, Redaction Sweep & Release Proof - Research

**Researched:** 2026-10-16
**Domain:** Elixir/Ecto/JOSE secret-hygiene sweep, Phoenix install generator output, Python clean-room harness, CI proof, ExDoc upgrade guide, Release Please
**Confidence:** HIGH for everything verified by experiment or source in this repo; MEDIUM for external-doc claims; items tagged `[ASSUMED]` are listed in the Assumptions Log.

Environment used for every experiment: `HEX_HOME=/private/tmp/lockspire-hex ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 MIX_ENV=test` (Elixir 1.19.5 / OTP 28, Ecto 3.13.6, jose 1.11.12, oban 2.21.1, phoenix_live_dashboard 0.8.7 per `mix.lock`). Baseline before any change: `mix test` on `key_material_leak_test.exs redaction_test.exs envelope_signing_consumers_test.exs architecture_fitness_test.exs documentation_contract_test.exs` gives `61 tests, 0 failures` in about 1 second. [VERIFIED: ran this session]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-00:** Research R1–R8 and "Other resolutions" in `.planning/research/v1.43-key-encryption/SUMMARY.md`, Phase 155 D-00..D-20 and Phase 156 D-00..D-28 stay locked. Under R8, absent config boots and signs, and `generate_key` refuses. SAFE-01 holds in full. No new deps. No new admin copy, so `PRODUCT.md` and the vocabulary contract stay unchanged.

**Redaction sweep (157-01, RED-01)**
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

**Host surfaces (157-02, HOST-01)**
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

**Proof and SAFE-01 gate (157-03, PROOF-01, SAFE-01)**
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

**Docs and release (157-04, DOC-01)**
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

**Plan shape**
- **D-17:** Four plans in two waves, as the roadmap suggests:
  - **Wave 1:** 157-01 (Redaction, D-01..D-06) and 157-02 (Hosts, D-07..D-10). Their files do not overlap.
  - **Wave 2:** 157-03 (Proof and SAFE-01 gate, D-11..D-13) and 157-04 (Docs and release note, D-14..D-16).

  Only 157-04 touches `mix.exs` and the `docs/` files. 157-02 may edit `docs/adoption-demo*.md` prose only where seeds change kids; otherwise leave doc edits to 157-04 to avoid conflicts. R7 split candidate: if 157-04 overruns, split the guide from the architecture, walkthrough and SECURITY updates.

### Claude's Discretion
- The helper name and module placement for D-04 and for the D-05 sentinel matcher.
- The exact printed wording of the D-07 next step, within the shape above.
- Whether the D-12 demo checks run as separate CI steps or inside the existing smoke script.
- How the demo seeds reach the retiring and retired display states through public API calls.

### Deferred Ideas (OUT OF SCOPE)
- KEY-UI-01: a "Key protection" line on the admin Keys pages, which needs a PRODUCT.md vocabulary entry.
- KEK-03: `mix lockspire.gen.kek`.
- KEK-04: a KMS/Vault provider.
- KEK-05: `{:system, "ENV"}` resolution, which would remove the raw KEK from app env (AR-01).
- Boot warning while `legacy_plaintext: :allow` persists after zero legacy rows remain (Doorkeeper-style nag). This would be new runtime behavior, so it waits for a later milestone.
- `docs/upgrading/v1.37.md` exists but is not in the `mix.exs` extras, and the contract test misses it. This is unrelated doc hygiene for a later milestone.
- Out of scope for the phase: admin UI copy (KEY-UI-01), `mix lockspire.gen.kek` (KEK-03), a KMS/Vault provider (KEK-04), `{:system, "ENV"}` resolution (KEK-05), a decrypt/downgrade task, `Process.flag(:sensitive, true)`, any protocol behavior change. Reviewed-but-not-folded todos: `2026-10-16-mix-tasks-start-repo.md` and `2026-10-13-audit-dcr-default-lifetime-semantics.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RED-01 | No private key material, ciphertext or KEK value in logs, telemetry, audit, `inspect`, changeset errors, admin pages or assigns; `Lockspire.Redaction` covers the new fields | Findings F1 (two more leaking queries than D-01 lists), F2 (changeset `changes` leak today, fix verified), F3 (JOSE exception leak, helper design verified), F4 (existing `"LSK"` assertions are vacuous for inspected bytes), Redaction structure verified |
| HOST-01 | Install generator emits runtime KEK block; demo and clean-room hosts store envelopes | F7 (generator output site and test), F8 (demo seeds: `generate_key(:sig)` yields ES256, state-machine recipe), F9 (clean-room env propagation), config-error text audit |
| PROOF-01 | CI proves end-to-end signing from envelopes for six consumers, no plaintext row, upgrade path | F10 (reencrypt task failure signal is `Mix.Error`, repo-start constraint, committed-DB constraint), consumer driver recipes from `envelope_signing_consumers_test.exs`, CI job lines verified |
| DOC-01 | Four-step order, rotation runbook, remanence, rollback, KEK backup, release-note text; walkthrough/architecture/SECURITY updated | F5 (crash dump facts), F6 (Release Please + PR #121 hazard), doc contract constraints verified |
| SAFE-01 | No new deps, no migration, no rename, no decrypted-key cache, no protocol change | F11 (gate commands and baseline diff against `v1.42`, verified clean for root files) |
</phase_requirements>

## Summary

The four research flags are resolved by experiment (details in the Findings below). Ecto 3.13.6 lets `redact: true` coexist with an explicit `@derive {Inspect, ...}` with no compile conflict: Ecto only auto-derives when no `Inspect` derive exists, and the changeset inspector independently masks `changes` using `__schema__(:redact_fields)`. The repo's current `SigningKeyRecord` changeset leaks the stored bytes today, which is a real RED-01 gap. JOSE 1.11.12 `from_map/1` raises `FunctionClauseError`, `CaseClauseError` and `MatchError` on malformed maps; the `MatchError` for an OKP key with a wrong-length `d` puts the full decoded private bytes in the exception message, and Oban stores `Exception.format` of the blamed exception in `oban_jobs.errors`, so the D-04 helper is justified. Erlang crash dumps do contain persistent_term values and process-held binaries, but not ETS contents (so not Application env); `ERL_CRASH_DUMP_SECONDS=0` and `ERL_CRASH_DUMP_BYTES=0` both suppress the dump. Release Please parses the squash commit message (here: the concatenated commit messages, not the PR body), so the PR body is safe from a major bump, and no commit on the unpushed branch contains `BREAKING`.

Five CONTEXT assumptions need correction before planning (see "Corrections to CONTEXT.md"): D-01's path list is incomplete (`list_active_keys` and `list_publishable_keys` also leak and sit on the JWKS hot path); D-02's proposed test cannot be driven through `generate_key/1` because the insert upserts on `kid`; `generate_key(:sig)` makes an ES256 key, not RS256; the existing `refute text =~ "LSK"` assertions cannot catch inspected envelopes because `inspect` renders them as `<<76, 83, 75, 1, ...>>`; and open Release Please PR #121 (1.6.0, auto-merge enabled) can ship 1.6.0 without this feature before the milestone lands.

**Primary recommendation:** Do the sweep in the order helper → schema → store → redaction → matcher-first-then-extend-sweep, make the sweep matcher walk terms structurally (binary leaves via `:binary.match`) plus text variants including the byte-list form, and treat the D-01 list as 9 paths, not 7.

## Corrections to CONTEXT.md (drift and gaps the planner must absorb)

| # | CONTEXT says | Reality | Impact |
|---|--------------|---------|--------|
| C1 | D-01 lists 7 paths | `list_active_keys` and `list_publishable_keys` also `SELECT` the full row (no `select`) and also reached `[:repo, :query]` with the key column. `list_signing_key_refs` selects `{id, kid}` only and is clean. [VERIFIED: probe test run this session, output `list_active_keys: ... touching_key_column_or_LSK=1`, `list_publishable_keys: ... =1`, `list_signing_key_refs: ... =0`] | 157-01 must add these two (JWKS/discovery hot path). Either `sensitive: true` or `select` that omits the column; recommend `sensitive: true` for uniformity. |
| C2 | D-02 test: forced `unique_constraint(:kid)` through `generate_key/1` | `publish_key` inserts with `on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: [:kid]` and `kid` is `Base.encode16(:crypto.strong_rand_bytes(8))` (`signing_key_store.ex:12-21`, `keys.ex:100`). A conflict upserts; it never returns `{:error, changeset}`. | Prove D-02 by calling `SigningKeyRecord.changeset/2` directly with a `%SigningKey{kid: nil, private_jwk_encrypted: sealed}` (a `validate_required` error), then `inspect/1` the changeset. Verified that today this prints the bytes (see F2). |
| C3 | D-09 "ES256 display row ... via `generate_key(:sig)`" and old seed used RS256 | `signing_key_defaults(_profile, _use)` returns `{JOSE.JWK.generate_key({:ec, "P-256"}), :EC, "ES256"}` for `:sig` (`keys.ex:333-334`); only `:enc` is RSA. Demo currently serves RS256 (`seeds.exs:83-86`). Demo smoke has no alg pin. [VERIFIED: grep of `scripts/demo/adoption_smoke.py`] | Demo keys become ES256 after the rewrite; docs prose at `docs/oauth-oidc-for-phoenix-adopters.md:332` must change. No RSA display row remains unless seeded for `:enc`. |
| C4 | D-05 asserts absence of `LSK\x01` bytes via text | `inspect(envelope)` renders `<<76, 83, 75, 1, 2, 107, ...>>`; `inspect(...) =~ "LSK"` is `false`. [VERIFIED: ran this session] The existing leak test's `refute ... =~ "LSK"` (key_material_leak_test.exs) would pass even if an envelope leaked through inspect. | The matcher must search for `<<76, 83, 75, 1` and walk binary leaves structurally. |
| C5 | `conformance_seeds.exs:68` "do the same audit" | Line 68 is `private_key = JOSE.JWK.generate_key({:rsa, 2048})` for an ephemeral OIDF *client* key; the file has no `SigningKey`, `generate_key` or `private_jwk_encrypted`. [VERIFIED: grep] | Audit result is "nothing to change"; record it in the plan. |
| C6 | `seeds.exs:209-256` placeholders | The `Enum.each([...SigningKey...])` block spans about lines 209-258; the ETF insert is `78-98` as stated. [VERIFIED: Read] | Cosmetic. |
| C7 | "no `compile_env` for the KEK" is a fitness guard in `architecture_fitness_test.exs` | The `compile_env` guard is `test/lockspire/config_key_encryption_test.exs:130` (`refute source =~ ~r/compile_env\(\s*:lockspire,\s*:key_encryption/`). `architecture_fitness_test.exs` holds the "never decrypt" (line 45) and "single stored-key reader" (line 67) guards. [VERIFIED: grep + Read] | SAFE-01 gate must list both files. |
| C8 | D-13 `git diff --exit-code v1.42 -- mix.exs mix.lock priv/repo/migrations` | Currently zero diff for all three. [VERIFIED: `git diff --stat` empty, `git diff v1.42 -- mix.exs \| wc -l` = 0]. But 157-04 edits `mix.exs` (docs extras), so the gate must filter. Demo, compat and clean-room locks do differ from v1.42: bandit 1.12.5 to 1.13.1, thousand_island 1.5.0 to 1.6.0, hpax 1.0.4 to 1.1.0, **mint 1.9.3 to 1.11.0** (DEP-01, not Lockspire's own deps). | Gate command recipe in F11. Mint is part of the expected DEP-01 delta. |
| C9 | D-16 "→ 1.6.0" | Release Please PR #121 "chore(main): release lockspire 1.6.0" is OPEN (v1.42 admin work), and `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` is `true`. [VERIFIED: `gh pr view 121`, `gh api .../variables/...`] The 85 v1.43 commits are local-only (`git log origin/main..HEAD` = 85, 16 `feat`). | If #121 auto-merges first, 1.6.0 ships without encryption and the feature becomes 1.7.0; every "1.6.0" string in the guide is then wrong. See Open Question 1. |
| C10 | D-11 "expect exit 0" | `--check` and failures signal via `Mix.raise` (a `Mix.Error`), not an exit integer (`lockspire.keys.reencrypt.ex:285-286`, quote: `"--check failed: signing keys are not all sealed with the current key-encryption key"`). Tests use `Mix.Task.run` + rescue `Mix.Error`. | "Exit 0" means "returns without raising `Mix.Error`". |
| C11 | CI "adoption-demo" lines `ci.yml:464-489` | Job is `399-489`; smoke step is the last step. [VERIFIED: Read] Other refs verified exact: `ci.yml:74-75`, `184-187`, integration job `271`, `run_test_matrix.sh:124-126`, `generators/install.ex:124-136`, `support.ex:33-50`, architecture `:331`/`:355`, `code-walkthrough.md:463-490`, `admin/keys.ex:60`. | none |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Suppress repo query log/telemetry for key-bearing queries | Database/Storage (`Repository.Support`, `SigningKeyStore`) | — | Ecto emits the event at the repo boundary; only the store call site can disable it |
| Changeset/struct inspect masking | Storage schema (`SigningKeyRecord`, `SigningKey`) | — | `redact:` and `@derive Inspect` are schema-level |
| JOSE-key construction guard | Protocol core (`PrivateJwk`) | six signing consumers | Single decode boundary; consumers call one helper |
| Telemetry/audit metadata scrubbing | Observability (`Lockspire.Redaction`) | — | Shared by `Observability.emit` and audit append |
| Runtime KEK delivery to host | Host app (`config/runtime.exs`, env var) | Install generator prints it | Host owns secrets; library never edits host-owned files |
| Demo/clean-room KEK | Example/harness config | Python orchestrator | Test fixtures, demo-only literals; per-run random for clean room |
| Upgrade proof | Test suite (integration) + CI jobs | Mix tasks as black box | Tasks start their own repo, so the proof must use committed (non-sandbox) data |
| Operator guidance | Docs (`docs/upgrading/...`) | SECURITY.md, architecture, telemetry | Guide is the operator's only rollback/backup contract |

## Standard Stack

No new Hex dependencies (constraint; verified root `mix.exs`/`mix.lock` have zero diff against `v1.42`).

### Core (already locked; versions from `mix.lock`)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto / ecto_sql | 3.13.6 / 3.13.5 | `redact: true`, changeset inspect, `Repo` options | Already the storage layer |
| jose | 1.11.12 | `JOSE.JWK.from_map/1`, `JWT.sign` | Already the JWT layer |
| oban | 2.21.1 | Backchannel logout worker; `Oban.Job.format_attempt` formats errors with `Exception.blame` | Already used |
| telemetry | 1.4.2 | Test attach for `[:repo, :query]` and key events | Already used |
| ExUnit `capture_log` / `Lockspire.TestSupport.TelemetryCapture` | built-in / repo | Sweep harness | Reuse, per D-05 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `sensitive: true` for `list_active_keys`/`list_publishable_keys` | `select` omitting `private_jwk_encrypted` | `select` keeps Ecto query logs on the hot path and never reads the column, but changes loaded struct shape. Both pass the sweep. Recommend `sensitive: true` (one line, same as the other 7 paths, matches D-01's accepted cost). |
| Sealing `d` via changeset `cast` | `put_change(:private_jwk_encrypted, ...)` outside `cast` | `cast` copies the value into `changeset.params` (unmasked by `redact`); `put_change` keeps it out of `params`. Recommend `put_change` (see F2). |

**Installation:** none. **Package Legitimacy Audit:** this phase installs no external packages; nothing to audit. Packages removed (SLOP): none. Flagged (SUS): none.

## Findings (research flags resolved)

### F1. Which store paths leak the key column (supports D-01)
Probe test (scratchpad, not committed) attached to the repo's `[:lockspire, :test_repo, :query]`-prefixed event and called each store function:

```
list_active_keys: queries=1 touching_key_column_or_LSK=1
list_publishable_keys: queries=1 touching_key_column_or_LSK=1
list_signing_keys: ... =1        list_decryption_keys: ... =1
fetch_active_signing_key: ... =1  fetch_signing_key_by_id: ... =1
publish_key_insert: ... =1        list_signing_key_refs: ... =0
publish_signing_key (locked_key + insert): 5 queries, 2 touching
```
[VERIFIED: ran this session]. `update_one` (changeset update of status/timestamps) did not touch the column. Final list to mark sensitive: `publish_key` insert, `list_active_keys`, `list_signing_keys` (default true), `list_publishable_keys`, `list_decryption_keys`, `fetch_active_signing_key`, `fetch_signing_key_by_id`, `locked_key`, `active_keys_for_update`. `sensitive_locked_key` and `replace_material` already use it (`signing_key_store.ex:245-251`, `219-232`). Callers of `list_signing_keys`: `admin/keys.ex:71` (passes opts), `:305` and `reencrypt.ex:207` pass `sensitive: true` already; flipping the default to `Keyword.get(opts, :sensitive, true)` is safe.

Verbatim of the switch to reuse (`support.ex:33-50`): `|> maybe_disable_sensitive_logging(opts)` and `options |> Keyword.put(:log, false) |> Keyword.put(:telemetry_event, nil)`. `Support.insert/3` accepts `sensitive: true` alongside the existing `on_conflict:`/`conflict_target:` opts because `repo_options/1` drops `:sensitive` before calling the repo (`Keyword.drop([:sensitive])`).

The existing leak test only exercised some of these paths, which is why it passed. The extended sweep (D-05) will fail on `list_active_keys`/`list_publishable_keys` until C1 is fixed; that is the intended red-to-green.

### F2. Ecto 3.13.6 `redact: true` with explicit `@derive Inspect` (flag 1)
Source, `deps/ecto/lib/ecto/schema.ex:2346-2348`:
```elixir
if redacted_fields != [] and not List.keymember?(derive, Inspect, 0) and
     derive_inspect?(module) do
  Module.put_attribute(module, :derive, {Inspect, except: redacted_fields})
```
and `deps/ecto/lib/ecto/changeset.ex:4352-4392` (`defimpl Inspect, for: Ecto.Changeset`): `redacted_fields = type.__schema__(:redact_fields)` and `changes |> filter(redacted_fields)` replaces each present key with `"**redacted**"`. [VERIFIED: Read both]

Experiments (compiled without consolidation via `elixir -pa _build/test/lib/*/ebin`, then re-checked in the app):
- Schema with `@derive {Inspect, except: [:secret]}` **and** `redact: true`: compiles clean; struct inspect omits the field (`#A<__meta__: ..., id: nil, kid: "k", ...>`); changeset prints `changes: %{secret: "**redacted**", kid: "k2"}`. **Both coexist; the explicit derive governs the struct, `redact:` governs the changeset.**
- `redact: true` alone: struct inspect is also derived (auto-derive) and the changeset masks.
- Explicit derive only (the repo's current state): struct masked, **changeset leaks**: `changes: %{secret: "SENT2", ...}`. [VERIFIED]
- Real module today: `inspect(SigningKeyRecord.changeset(%SigningKeyRecord{}, %SigningKey{kid: nil, private_jwk_encrypted: "SENTINEL-CIPHER"}))` prints `changes: %{status: :upcoming, use: :sig, private_jwk_encrypted: "SENTINEL-CIPHER", public_jwk: %{}}`, `__schema__(:redact_fields)` is `[]`. [VERIFIED]
- `Ecto.Changeset` inspect never prints `params`, but `changeset.params` (string-keyed map from `cast`) still holds the plaintext/ciphertext and `redact` does not touch it. Anyone doing `inspect(cs.params)` or logging `cs` fields leaks it.
- Error entries (`errors:`) carry no values for `validate_required`/`unique_constraint` (`[kid: {"can't be blank", [validation: :required]}]`). [VERIFIED]

**Recommendation:** keep `@derive {Inspect, except: [:private_jwk_encrypted]}` on `SigningKeyRecord` (line 12) **and** add `redact: true` to the field (line 19). In `changeset/2`, drop `:private_jwk_encrypted` from the `cast` list and apply it with `put_change(:private_jwk_encrypted, key.private_jwk_encrypted)` so the value never enters `changeset.params`. Verify with `refute inspect(cs) =~ sentinel`, `refute inspect(cs.params) =~ sentinel`, and a `Repository.publish_key` round trip (the column must still be written; `put_change` of a `nil` should still be a no-op as today's cast of `nil`).

### F3. JOSE 1.11.12 `from_map/1` on malformed maps (flag 2)
Results with a sentinel `d` (`"SENTINEL-PRIVATE-D-0001-SENTINEL-PRIVATE-D"` base64url-encoded) [VERIFIED: ran this session, `f2*.exs` scratch scripts]:

| Input | Outcome | Value in message? |
|-------|---------|-------------------|
| `%{}`, `%{"d" => d}`, `"kty" => "XX"` | `FunctionClauseError` in `JOSE.JWK.from_record/1`; blamed args show `{:error, {:missing_required_keys, ["keys", "kty"]}}` | no |
| RSA with `d` of non-multiple-of-4 length | `CaseClauseError` `no case clause matching: "A"` (the leftover tail of the base64url string) | **yes, 1 to 3 trailing characters of the encoded value** |
| `d` with illegal char | `CaseClauseError` `no case clause matching: 33` (the offending byte) | one byte |
| **OKP Ed25519 with wrong-length `d`** | **`MatchError` `no match of right hand side value: "SENTINEL-PRIVATE-D-0001-SENTINEL-PRIVATE-D"`** | **YES, the full decoded private bytes, also in `Exception.format` of the blamed exception** (what Oban stores) |
| OKP, correct-length `d`, bad `x` | `MatchError` with `<<0, 0, 0>>` (decoded `x`) | public part only |
| `d` integer / `kty` integer | `FunctionClauseError` in `:jose_base64url.decode!/1` or `:jose_jwk.from_map/1` | no |
| EC with bad `d`, RSA missing `n`, EC with `x` as junk | **returns a `%JOSE.JWK{}` without raising**; sign later raises `ErlangError` (no value in message) | no |
| `JOSE.JWT.sign` with RS256 on an EC key | `ErlangError {:not_supported, ["P-256", :RS256]}` | no |

Important detail: `%JOSE.JWK{keys: ...}` is `:undefined` for **valid** single keys too (the key lives in `.kty`), so `keys != :undefined` is not a validity check. A structural probe that does work: `JOSE.JWK.to_public/1` raises `FunctionClauseError`/`ArithmeticError` on the malformed-but-returned cases and succeeds on valid RSA, EC P-256 and OKP Ed25519 keys. [VERIFIED]

Oban formatting, `deps/oban/lib/oban/job.ex:458-466`: `{blamed, stacktrace} = Exception.blame(kind, error, stacktrace)` then `Exception.format(kind, blamed, stacktrace)` is stored in `errors`. That confirms the OKP `MatchError` text (private bytes) would be persisted in `oban_jobs.errors`. Consumers today: `IdToken`, `LogoutToken`, `Jarm` and `AccessTokenSigner` call `JOSE.JWK.from_map(jwk_map)` inline with no rescue; `IntrospectionJwt.sign_compact_jwt` rescues only `ErlangError`; `Jar.decrypt` has `rescue _` and `catch _, _` (`jar.ex:42-56`). The backchannel worker's `LogoutToken.sign` has only `{:ok, ...}` and `{:error, :invalid_signing_key}` branches (`backchannel_logout_delivery_worker.ex:43-80`), so a raise propagates into Oban.

**Recommended helper** (verified against the malformed set and against RSA/EC/OKP valid keys), placed in `Lockspire.Protocol.PrivateJwk` next to `decode/1`:
```elixir
@spec to_jwk(term()) :: {:ok, JOSE.JWK.t()} | {:error, :invalid_signing_key}
def to_jwk(%{} = map) do
  jwk = JOSE.JWK.from_map(map)
  _public = JOSE.JWK.to_public(jwk)   # raises on structurally invalid key material
  {:ok, jwk}
rescue
  _ -> {:error, :invalid_signing_key}
catch
  _kind, _reason -> {:error, :invalid_signing_key}
end

def to_jwk(_other), do: {:error, :invalid_signing_key}
```
Rules: never bind the exception or stacktrace, never `reraise`, never log. Replace `JOSE.JWK.from_map(jwk_map)` in the six consumers (`id_token.ex:36-50`, `logout_token.ex:35-39`, `jarm.ex:55-60`, `introspection_jwt.ex:36,100`, `access_token_signer.ex:208-211`, `jar.ex:43-44`) by `{:ok, jwk} <- PrivateJwk.to_jwk(jwk_map)` in the existing `with`. A `with` clause failure already falls through to `{:error, reason} -> {:error, reason}` in each, so the response contract (`:invalid_signing_key`, and the existing `server_error` mapping for the access-token signer) is unchanged. Sign-time `ErlangError` for alg/key mismatch is unchanged behaviour and carries no key bytes; leave it (a protocol behaviour change is out of scope). Optional: do the same wrap around `JOSE.JWT.sign` inside the helper if the planner wants to remove the remaining raise, but that would change today's raise-to-500 behaviour for alg mismatch, so do not.

### F4. Existing leak assertions are vacuous for envelopes (matcher design for D-05)
- `inspect(envelope, limit: :infinity)` starts `[<<76, 83, 75, 1, 2, 107, 49, 44, ...` and `=~ "LSK"` is `false`; `=~ "<<76, 83, 75, 1"` is `true`. [VERIFIED]
- Base64 of the header is `Base.encode64("LSK" <> <<1>>)` = `"TFNLAQ=="`; hex is `4c534b01`.
- Sealed JWK bodies for the sentinel are AES-GCM ciphertext, so the sentinel `d` itself never appears in an envelope; the envelope check is the `LSK\x01` prefix. The plaintext sentinel check matters for legacy rows (`Jason.encode!` JSON) and for decoded maps in exception messages.

**Recommended matcher** (one module in `test/support/`, e.g. `Lockspire.KeyMaterialMatcher`, discretion area): 
1. `forbidden = [sentinel_d, kek_one, kek_two, kek raw bytes]` expanded to `[raw, Base.encode64(raw), Base.encode64(raw, padding: false), Base.url_encode64(raw), Base.url_encode64(raw, padding: false), Base.encode16(raw, case: :lower)]`, plus the envelope markers `"LSK" <> <<1>>`, `"<<76, 83, 75, 1"`, `"TFNLAQ"`, `"4c534b01"`.
2. `scan_text(label, text)`: `refute String.contains?` for each form.
3. `scan_term(label, term)`: walk maps, structs (`Map.from_struct` plus the `__struct__`), lists, tuples; for every binary leaf `refute :binary.match(leaf, needle)` for the byte forms; also run `scan_text` on `inspect(term, limit: :infinity, structs: false)` and on default `inspect`.
4. Surfaces: `capture_log(level: :debug)`, every telemetry message from `TelemetryCapture` (metadata, measurements, `result`, `params`, `cast_params`, `query`), `AuditEventRecord` rows, `Oban.Job.errors` via `Oban.Job.format_attempt`/the stored `errors`, `inspect` of `SigningKey`, `SigningKeyRecord`, `KeySet`, changesets, `Exception.message`/`Exception.format` of every rescued error, and rendered HTML plus `socket.assigns` for `KeysLive` and `OverviewLive` (use the patterns in `test/lockspire/web/live/admin/keys_live_test.exs` and `overview_live_test.exs`).
5. Keep the proof self-validating: first assert the matcher flags a deliberately leaky term (a "canary of the canary"), the same way the existing test asserts `log =~ ~r/QUERY (OK|ERROR)/` to avoid vacuity.

For the malformed-JWK-through-each-consumer step, use sealed rows whose plaintext is an OKP map with wrong-length `d`, because that is the one shape whose raw exception currently leaks decoded bytes; the post-helper expectation is `{:error, :invalid_signing_key}` (or the access-token signer's `server_error`) with nothing in the log and no raise. For the Oban step use `Oban.Testing.perform_job/2` on `Lockspire.Workers.BackchannelLogoutDeliveryWorker` (existing `backchannel_logout_delivery_worker_test.exs`); expect `{:discard, :invalid_signing_key}` and assert no raise.

### F5. Erlang crash dump contents and knobs (flag 3)
Experiments (OTP 28.4.1, macOS; `System.halt("boom")` writes a dump; sentinels built at runtime and located via base64/hex search in the dump) [VERIFIED: ran this session, 3 runs]:
- **persistent_term values: present.** Found in `=binary` (and in `=literals` for literal-compiled terms). The dump has a `=persistent_terms` section listing keys and heap pointers.
- **Binaries held by live processes: present** (`=binary`, `=proc_heap`).
- **ETS table contents: absent.** The sentinel stored in a named public ETS table was not found; the dump's `=ets` entries carry table metadata ("Objects: 1"), not rows. Application env lives in the `ac_tab` ETS table, and a sentinel set with `Application.put_env` was **not found** in the dump.
- Dump file mode was `-rw-r-----` (0640) on macOS with umask 022. Linux mode `[ASSUMED]` identical.
- `ERL_CRASH_DUMP_SECONDS=0` produced no dump file; `ERL_CRASH_DUMP_BYTES=0` produced no dump file. [VERIFIED]
- Docs: `ERL_CRASH_DUMP` names the file (default `erl_crash.dump` in the working directory); `ERL_CRASH_DUMP_SECONDS` "If the variable is set to `0` seconds, the runtime system does not even attempt to write the crash dump file", negative waits indefinitely, default `0` if `-heart` given and unset else `-1`; `ERL_CRASH_DUMP_BYTES` "If the variable is set to `0`, the runtime system does not even attempt to write a crash dump file"; `ERL_CRASH_DUMP_NICE` lowers priority (1-39). [CITED: erlang.org/doc/apps/erts/erl_cmd.html]

Consequence for D-14/D-06: the keyset Lockspire caches in `:persistent_term` (`{Lockspire, :key_encryption}`, raw 32-byte keys decoded from the base64) **is** in a crash dump, and the base64 env value is only present if some process heap/binary holds it (app env itself is not dumped). Reword the guide: "A crash dump can contain `:persistent_term` values and the memory of every process, which includes Lockspire's decoded key-encryption keys. App env (ETS) contents are not written to the dump, but anything that read the key into a process is." Keep AR-01 wording about remote shell/Observer reading app env. Recommended operator advice: dump file permissions `0600` and a restricted directory, or `ERL_CRASH_DUMP_SECONDS=0` (or `_BYTES=0`) where policy demands no dumps; releases can set it in `rel/env.sh.eex` `[ASSUMED]`.

### F6. Release Please squash behavior and release hazards (flag 4)
- Repo settings: `squash_merge_commit_title: COMMIT_OR_PR_TITLE`, `squash_merge_commit_message: COMMIT_MESSAGES`, squash/merge/rebase all allowed. [VERIFIED: `gh api repos/:owner/:repo`] So the squash commit message is the PR title (multi-commit PR) plus a body that concatenates every commit message (the v1.42 squash `1cfafd03` body is `* fix(153-01): ...` bullets with `Co-Authored-By:` lines). **The PR description is not part of the commit**, so a PR-body "Upgrade notes" block cannot trigger a bump.
- Release Please source (`src/commit.ts`): `BREAKING-CHANGE:\s*(.*)` is matched against the commit body unanchored (a leading `*` bullet does not prevent a match); footer token `BREAKING CHANGE` is handled through the conventional-commits AST; `!` after the type is a major bump; `BEGIN_COMMIT_OVERRIDE` / `END_COMMIT_OVERRIDE` in the **merged PR body** replace the commit message; the blank-line split requires a bare `type:` after the blank line, so `* feat:` bullets are not split. [CITED: github.com/googleapis/release-please src/commit.ts and README, fetched this session]
- Safety check for this branch: `git log origin/main..HEAD --format=%B | grep -n BREAKING` returned nothing, and no subject matches `^type(scope)?!:`. [VERIFIED] Make this an explicit pre-merge check in 157-04 and re-run it after the last commit (the grep is case-sensitive for the token, but also run `grep -i breaking` to catch prose that a person could later promote to a footer).
- `release-please-config.json`: `release-type: elixir`, `bump-minor-pre-major: false`, manifest `.`: `1.5.1`. A `feat` after 1.5.1 yields a minor bump. The open release PR #121 already proposes 1.6.0 from the v1.42 `feat` commits. [VERIFIED]
- Hazard: `.github/workflows/release-please-automerge.yml` merges eligible Release Please PRs after green main CI when `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED == 'true'` (it is `true`). Any push of the v1.43 work to main updates #121, but a merge of #121 beforehand would publish 1.6.0 without encryption. The guide text "code before 1.6.0 cannot read envelopes" is only true if encryption ships in 1.6.0.
- Use the `BEGIN_COMMIT_OVERRIDE` block (documented behavior) if the planner wants a controlled CHANGELOG line instead of 80+ phase-commit bullets; not required.

### F7. Install generator output (HOST-01)
`instructions/1` is `generators/install.ex:124-136`, printed by `Mix.shell().info(instructions(assigns))` at line 18; steps 1-8 currently end with the FAPI smoke note. Tests assert only substrings (`install_generator_test.exs:292-297`, rerun at `:609`), so adding a numbered step is additive. The block must be rendered at print time (not in a template) so it does not enter `.lockspire/install_manifest.json`, keeping reruns idempotent; the per-install dev literal is `Base.encode64(:crypto.strong_rand_bytes(32))`, which passes `KeySet.new/1` (verified for `"2026-10"` and for the weak-material check: random bytes are not repeated-byte keys). KEK ids must match `@id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/` (`key_set.ex:48`); `YYYY-MM` is valid. [VERIFIED: ran `KeySet.new/1`]

Where the dev/test variant lives: print it for `config/dev.exs` and `config/test.exs` (compile-time files, where Phoenix puts `secret_key_base`), not `runtime.exs`. Recommendation within discretion: print `legacy_plaintext: :reject` there too (fresh install) with a one-line comment: "upgrading an app that already has signing keys? Use `:allow` first; see docs/upgrading/signing-key-encryption.md".

Config error text audit (D-08): `Lockspire.Config.fail_key_encryption!/2` (`config.ex:284-289`) says: `"Each key must be base64 of 32 random bytes; generate one with `openssl rand -base64 32` and set it in config/runtime.exs."` It names `openssl`, not the Elixir one-liner, and does not warn about `mix phx.gen.secret`. The `openssl rand -base64 32` string also appears in `application.ex:40`, `install/verify.ex:97`, `lockspire.keys.reencrypt.ex:147` and `lockspire.doctor.key_encryption.ex:81`, and `test/lockspire/install/verify_test.exs:339` asserts `fix =~ "openssl rand -base64 32"`. Add the one-liner and the phx.gen.secret warning to `config.ex` (the only place that fires for invalid keys); keep every existing `openssl rand -base64 32` substring. Evidence for the warning: `mix phx.gen.secret` prints a 64-character string, which base64-decodes to 48 bytes, and `KeySet.new/1` returns `{:error, {:keys, :invalid_key_length}}` for a 64-byte base64 input. [VERIFIED: ran both]

### F8. Adoption demo seeds and config (HOST-01)
- `config/config.exs` is compile-time config evaluated at every mix invocation; adding `config :lockspire, :key_encryption, keys: [{"demo-1", System.get_env("LOCKSPIRE_KEY_ENCRYPTION_KEY", "<literal>")}], current: "demo-1", legacy_plaintext: :reject` follows the `SECRET_KEY_BASE` fallback pattern at `config.exs:64-66, 77-80`. The literal must not be a repeated-byte key (weak-material check). CI `adoption-demo` job (MIX_ENV=dev) sets no KEK var, so the literal applies. `docker-compose.yml` `web.environment` lists the demo env vars (`LOCKSPIRE_DEMO_*`); add the commented demo-only var there. `docker-compose.db-host.yml` and `docker-compose.traefik.yml` exist too and inherit the config fallback.
- State-machine recipe to reach all four display states using only public API (verified against `keys.ex` / `signing_key_store.ex`): `activate_key` requires `:upcoming` and a `published_at`; activating a key moves the previous `:active` key to `:retiring`; `retire_key` requires `:retiring`. Sequence: K1 `generate_key(:sig)` → `publish_key` → `activate_key`; K2 same (K1 becomes retiring); `retire_key(K1)` (retired); K3 generate/publish/activate (K2 retiring, K3 active); K4 `generate_key(:sig)` only (upcoming; optionally also `publish_key` for a published-upcoming display). Seeds already create the server policy before keys (`seeds.exs` policy at about line 60), which `generate_key/1` needs (`Repository.get_server_policy()`).
- Consequence (C3): every `:sig` key is ES256; `docs/oauth-oidc-for-phoenix-adopters.md:332` (`signed with key id "adoption-demo-rs256"`) is the only prose reference outside `seeds.exs`. 157-02 may edit this one line (it is not in the 157-04-only file set but does not conflict with D-17's intent; call it out to the planner). No test or script references the old kids. [VERIFIED: repo-wide grep]
- CI: the job ends at the smoke step; append two steps with `working-directory: examples/adoption_demo` running `mix lockspire.keys.reencrypt --check` and `mix lockspire.doctor key_encryption` (dev env, Postgres service already up). `Mix.Task` names: `lockspire.doctor` takes `key_encryption` as the subtask argument (`test` calls `Mix.Task.run("lockspire.doctor", ["key_encryption"])`).

### F9. Clean-room provider host (HOST-01)
- `write_host_runtime` (`build_provider.py:46-80`) writes **`config/config.exs`** (not runtime.exs) with `key_encryption: [keys: [{"clean-room-1", "j/nnbOESQTiY8IQZNzKyN8nhCngcI5f1GboKyJoePfQ="}], current: "clean-room-1", legacy_plaintext: :allow]` at lines 74-78. `check_bootstrap` (`:351-370`) asserts `"key_encryption:" in source and "clean-room-1" in source`; `phase133_provider_install_test.exs:23` runs `python3 build_provider.py --check-bootstrap`.
- `fetch_env!` in `config.exs` runs at config load for **every** `mix` subprocess of the provider child. `locked_environment` starts from `os.environ.copy()` (`package_input.py:273-288`). Environments are built in at least three places: `prepare_provider` (`environment`), `main()` `provider_environment` (`clean_room_saas_journey.py:906-907`), and the restart path (`run_dpop`). The simplest correct design: generate once in `main()` right after `redactor = Redactor(SentinelSet.for_run())` (line 865), `os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"] = kek`, and `register_secret(kek)`; every child environment inherits it, the same pattern the script already uses for `TMPDIR`. This is a small deviation from D-10's literal wording ("set per run in `prepare_provider`'s environment") with the same effect; `prepare_provider` can still `environment.setdefault(...)` for standalone callers.
- `scan_evidence` (`:367-374`) rewrites `*.log` through the redactor and asserts safety, so registering the KEK is enough to make it fail on a leak. Also register the raw-decoded form is unnecessary; the base64 string is what an env echo would show.
- Add `run_child_command(provider_child, provider_environment, "lockspire.keys.reencrypt", "--check")` and `"lockspire.doctor", "key_encryption"` after the existing `lockspire.verify` (line 917) and before `Bootstrap.provision!` or after it. `--check` before provisioning proves an empty table is fine; after provisioning proves one sealed active key. Recommend **after** `provision!` (line 918) so the check actually opens an envelope. Bootstrap already uses only public API (`bootstrap.ex:4-7`: `generate_key(:sig)` → `publish_key` → `activate_key`).
- `release.yml:203` runs the clean-room journey against the published package with a Hex version; the new commands exist only in the version that ships this feature, which is the one being verified after publish. Do not replay the new journey against 1.5.1.

### F10. Upgrade journey test constraints (PROOF-01)
- Mix tasks start their own repo: `Ecto.Migrator.with_repo(Lockspire.Config.repo!(), fn _ -> work(mode) end, mode: :temporary)` (`lockspire.keys.reencrypt.ex:109-125`), so the sandbox is not usable; data must be committed and the test must **begin with `Lockspire.TestRepo` stopped** (precedent: `Mix.Tasks.Lockspire.Keys.ReencryptE2ETest`, `lockspire_keys_reencrypt_test.exs:70-95`, which `refute Process.whereis(Lockspire.TestRepo)`, asserts zero foreign signing keys in the committed test DB, uses a `mig-task-<random>` kid prefix, and cleans up in `on_exit`). The new journey test must follow that shape (`async: false`, own kid prefix, cleanup of keys and their audit rows) and must not coexist with a sandbox owner. Two modules asserting "zero foreign keys" will fight each other if one leaves rows; cleanup is mandatory.
- Test selection: `test_helper.exs` excludes `:integration` unless an argument ends with `.exs` or contains `integration`, or `--include integration` is passed. Put the file under `test/integration/` and run it by path. `mix test.integration` = `test.setup` + `test --only integration test/integration`; the `--integration` CI mode runs `mix test --only integration` over the whole tree plus `test.clean-room.e2e`. [VERIFIED: Read `test_helper.exs`, `mix.exs:98`, `run_test_matrix.sh:124-127`]
- Drivers: reuse the six-consumer call shapes from `test/lockspire/protocol/envelope_signing_consumers_test.exs` (IdToken.sign params at lines 80-90, LogoutToken at 140-160, Jarm via `KeyStore` stub, IntrospectionJwt, AccessTokenSigner.issue, Jar via `jar_fixture`). Those take an in-memory `%{kid:, alg:, private_jwk_encrypted:}`; the journey should instead read each row back with `Repository.fetch_signing_key_by_id` (or `Repository.list_signing_keys`) after each phase so the *stored* bytes are what signs. Extract the six drivers into `test/support/` rather than copying.
- Byte-level assertion for step 4: `assert String.starts_with?(bin, "LSK" <> <<1>>)`, `refute String.contains?(bin, "\"d\"")`, `refute String.contains?(bin, "\"k\"")`, and `refute String.contains?(bin, Base.url_encode64(<<d_bytes>>, padding: false))` using the original `d` value from the seeded map (the legacy row's private values are known to the test).
- Rotation: `Helpers.put_key_encryption(keys: [...], current: "k2", legacy_plaintext: :allow)` updates both env and the persistent_term cache (`validate_key_encryption!`); the tasks read `Lockspire.Config.key_encryption!()` fresh from app env, so the app env must hold the config the task should see. `Keys.encryption_status()` returns the per-KEK-id counts for "zero rows remain on `k1`" (used in `lockspire_keys_reencrypt_test.exs:264,342`).
- `--check` raise text on failure: `"--check failed: signing keys are not all sealed with the current key-encryption key"` (`Mix.Error`). Success is a normal return.

### F11. SAFE-01 gate recipe (PROOF-01/SAFE-01, runs at verification time per D-13)
Run from repo root after the last code commit:
```bash
git diff --exit-code v1.42 -- mix.lock priv/repo/migrations
git diff v1.42 -- mix.exs | grep -E '^[+-]\s+\{:[a-z_]+,' ; test $? -eq 1   # no dependency line changed in mix.exs
git diff --name-only v1.42 -- priv/repo/migrations | wc -l                  # expect 0
grep -rn "private_jwk_encrypted" priv/repo/migrations | head -1             # column name unchanged
git diff v1.42 --stat -- examples/adoption_demo/mix.lock test/clean_room compatibility   # expected DEP-01 only: bandit/thousand_island/hpax/mint
```
[VERIFIED baseline: the first command exits 0 today; `mix.exs` diff against `v1.42` is 0 lines today]. Then: `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/config_key_encryption_test.exs test/lockspire/key_cache_test.exs` (public-only cache check lives in the fitness test at line 45 plus `KeyCache` test; confirm the exact file name when planning), and the full suites listed in D-13 on CI Elixir. "Zero edits to security-default and protocol suites" check: `git diff v1.42 --stat -- test/lockspire/protocol test/lockspire/security` must show only additions or changes the plan owns; assertions removed or loosened are a failure (`git diff v1.42 -- test | grep '^-.*assert\|^-.*refute'` reviewed by hand).

### F12. Docs contract constraints (DOC-01)
Verified in `test/lockspire/documentation_contract_test.exs`:
- Every `extras` entry (except README) must appear exactly once across `groups_for_extras` and be in `package_files`; `package_files` includes `Path.wildcard("docs/**/*.md")`, so the new `docs/upgrading/signing-key-encryption.md` is packaged automatically. `Upgrade` group currently holds `docs/upgrading/v1.27.md` and `docs/upgrading/storage-prefix.md` (`mix.exs:219-220, 249-250`); add the new file to both lists in the same commit.
- Architecture: exactly 4 `mermaid` blocks with `accTitle:`/`accDescr:`; the 13 `##` headings in fixed order; the `Bounded plaintext` row and line 355 prose can be edited freely.
- Walkthrough: `length(walkthrough_blocks) in 12..18` and currently 18 `elixir` blocks (`grep -c`); every `elixir` block in architecture and walkthrough must `Code.string_to_quoted/1`; the guides must not contain `.planning/`, `/Users/`, `file://`, GitHub `blob` links, `](lib/` or `](test/` links, or `#L12` anchors. The anchored excerpts (`operation_plan.ex`, `authorization_request.ex`, `authorization_flow.ex`, `refresh_exchange.ex`, `token_store.ex`) must stay. The signing excerpt at `:463-490` (`sign_jwt/2`) is not anchored, so rewrite in place to the `PrivateJwk.decode(signing_key)` shape and keep the block count.
- `install-and-onboard.md`: bash blocks must keep `mix lockspire.install` before `mix ecto.migrate` before `mix lockspire.verify`; the doc must keep `does not prove`, `staff access policy`, `host app`, `host request tests`, `supported-surface.md`; no `.planning/`.
- `README`/`getting-started` route checks are unaffected. The reader-facing guides listed in `adopter and admin guides` (`README`, `getting-started`, `install-and-onboard`, `saas-adoption-recipe`, `adoption-demo`, `operator-admin`) must not contain `.planning/`; the upgrade guide is not in that list but should follow it.
- `docs/telemetry.md:9` claims "Every event emitted by Lockspire produces two paths" and `:14` describes the audit mirror; the `[:lockspire, :key, ...]` family has no section today. Events: operator emits (`generated`, `published`, `activated`, `retired`, `encrypted`, `rewrapped`, `reencrypt_failed`, `reencrypt_completed`, and the `--check` completion) go through `Observability.emit` and have audit mirrors; `legacy_read` and `decode_failed` are emitted by `:telemetry.execute` directly in `private_jwk.ex:69-98` with no audit mirror. [VERIFIED: Read]
- Packaged-doc path rule: `docs/upgrading/storage-prefix.md` is the style precedent (short sections, a command per step).

## Architecture Patterns

### System Architecture Diagram (data flow for what this phase changes)

```
 host operator
   |  openssl rand -base64 32  -> secret manager -> env LOCKSPIRE_KEY_ENCRYPTION_KEY
   v
 config/runtime.exs (host, printed by mix lockspire.install; dev/test literal in dev.exs/test.exs)
   |  Application.put_env(:lockspire, :key_encryption, ...)
   v
 Lockspire.Application.validate_key_encryption!  -> :persistent_term KeySet (decoded keys; in crash dumps)
   |
   +--> Admin.Keys.generate_key --seal--> SigningKeyRecord (put_change, redact:true) --Support.insert(sensitive)--> DB column private_jwk_encrypted ("LSK\x01"...)
   |
   +--> SigningKeyStore reads (sensitive: true; no Ecto log/telemetry) --> PrivateJwk.decode (open envelope / legacy) --> PrivateJwk.to_jwk (rescue, no args)
   |        --> six signers: IdToken | LogoutToken(Oban worker) | Jarm | IntrospectionJwt | AccessTokenSigner | Jar.decrypt
   |
   +--> telemetry/audit --> Lockspire.Redaction (drop key names + LSK value guard) --> reporters / audit rows
   |
 mix lockspire.keys.reencrypt [--dry-run|--check] / doctor key_encryption  (task starts own repo via Ecto.Migrator.with_repo)
   |
 CI: integration partition (upgrade journey) | adoption-demo job (--check, doctor) | clean-room journey (--check, doctor, KEK scanned in evidence)
```

### Recommended file touch list per plan

**157-01 (RED-01)** `lib/lockspire/storage/ecto/repository/signing_key_store.ex`; `lib/lockspire/storage/ecto/signing_key_record.ex`; `lib/lockspire/redaction.ex`; `lib/lockspire/protocol/private_jwk.ex` + `id_token.ex`, `logout_token.ex`, `jarm.ex`, `introspection_jwt.ex`, `jar.ex`, `token_exchange/internal/access_token_signer.ex`; tests: `test/lockspire/security/key_material_leak_test.exs` (extend), `test/support/` matcher, `test/lockspire/redaction/redaction_test.exs`, `test/lockspire/protocol/private_jwk_test.exs`, `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs`. Suggested task order: (1) matcher + failing sweep (red), (2) store `sensitive`, (3) schema `redact`/`put_change`, (4) helper + consumers, (5) Redaction, (6) green sweep.
**157-02 (HOST-01)** `lib/lockspire/generators/install.ex` (+ a small pure function for the dev literal so it is unit testable), `lib/lockspire/config.ex` (error text), `test/integration/install_generator_test.exs`, `examples/adoption_demo/config/config.exs`, `priv/repo/seeds.exs`, `docker-compose.yml`, `docs/oauth-oidc-for-phoenix-adopters.md:332`, `.github/workflows/ci.yml` (adoption-demo steps), `scripts/acceptance/clean_room/build_provider.py`, `scripts/acceptance/clean_room_saas_journey.py`. Wave 1 file overlap with 157-01: none (`config.ex` and `install.ex` are not touched by 157-01). `ci.yml` is touched here and possibly in 157-03; serialize or keep 157-03's CI edit out (the journey test needs no CI change).
**157-03 (PROOF-01, SAFE-01)** new `test/integration/signing_key_upgrade_journey_test.exs` (name is discretion), `test/support/` shared six-consumer drivers (or extend `key_encryption_helpers.ex`), `157-VERIFICATION.md` gate record. No source changes.
**157-04 (DOC-01)** `docs/upgrading/signing-key-encryption.md`, `mix.exs` (extras + groups), `docs/architecture.md`, `docs/code-walkthrough.md`, `docs/telemetry.md`, `SECURITY.md`, `docs/install-and-onboard.md`, `157-RELEASE-NOTES.md` (ready-to-paste PR body, in the phase dir), plus the pre-merge Release Please checks.

### Code examples

Schema (F2):
```elixir
@derive {Inspect, except: [:private_jwk_encrypted]}
schema "lockspire_signing_keys" do
  ...
  field(:private_jwk_encrypted, :binary, redact: true)
```
and in `changeset/2`: remove `:private_jwk_encrypted` from the `cast` list and pipe `|> put_change(:private_jwk_encrypted, key.private_jwk_encrypted)`.

Redaction value-level guard (D-03), slotted before the catch-all `sanitize_value/2` clause in `redaction.ex`:
```elixir
defp sanitize_value(<<"LSK", 1, _rest::binary>>, _surface), do: :drop
```
The 9 key names go into both `@telemetry_drop_keys` and `@audit_drop_keys` as atoms and strings. No current emit site uses these names as metadata keys (grep of `lib` for `jwk:`, `kek:`, `envelope:`, `ciphertext:`, `private_key:`: no hits outside config/doc strings), so dropping them removes nothing observable. `kid`, `kek_id`, `previous_kek_id`, `key_id` are untouched.

Install block rendering (D-07), inside `instructions/1`, an added numbered step 9 (keeps 1-8 intact):
```elixir
kek_id = Date.utc_today() |> Calendar.strftime("%Y-%m")
dev_literal = Base.encode64(:crypto.strong_rand_bytes(32))
```
interpolated into the heredoc; test asserts `output =~ "LOCKSPIRE_KEY_ENCRYPTION_KEY"`, `output =~ "legacy_plaintext: :reject"`, `output =~ ~r/\d{4}-\d{2}/`, and that two `capture_io` runs print different literals (extract with a regex for the 44-character base64).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Masking changesets | A custom `Inspect` impl for changesets | Ecto `redact: true` | Ecto already filters `changes`; verified |
| Suppressing query telemetry | A telemetry handler that scrubs `result` | `Repository.Support` `sensitive: true` | Drops the event at source; already proven for reencrypt |
| Swallowing JOSE exceptions | `try/rescue` in every consumer | One `PrivateJwk.to_jwk/1` | One place to keep "no args" discipline |
| Key generation for hosts | A new `mix lockspire.gen.kek` | `openssl rand -base64 32` or the Elixir one-liner | KEK-03 is deferred |
| Leak scanning | Per-test `refute =~` | One matcher module walking terms + text | Prevents the inspect byte-list blind spot |
| Release notes bump control | A custom changelog script | Squash title + optional `BEGIN_COMMIT_OVERRIDE` | Documented Release Please behavior |
| Upgrade proof via a real older Hex release | A multi-version harness | Seeded legacy rows via `key_encryption_helpers.ex` | Locked by D-11 |

**Key insight:** every defence here exists at a boundary (repo options, schema, one decode helper, one redaction module); the failure mode is a second, undeclared path (the two extra list queries, `changeset.params`, a second consumer's inline `from_map`).

## Common Pitfalls

### Pitfall 1: Vacuous leak assertions
**What goes wrong:** `refute text =~ "LSK"` passes while the envelope leaks as `<<76, 83, 75, 1, ...>>`.
**Why:** Elixir renders non-printable binaries as byte lists. [VERIFIED]
**Avoid:** structural binary scan plus the byte-list needle; self-test the matcher against a deliberately leaky term.
**Warning sign:** a sweep that was green before any production fix landed.

### Pitfall 2: `sensitive: true` on the insert but not the upsert options order
**What goes wrong:** passing `sensitive: true` through `Support.insert/3` is fine, but a direct `repo.insert` call anywhere bypasses it.
**Avoid:** keep all key-table access through `Support`; `rg "SigningKeyRecord" lib` shows only `signing_key_store.ex` and the record module reference it (the Admin/other modules go through `Repository`). [VERIFIED: grep earlier showed only those files for `private_jwk_encrypted` outside protocol/admin]

### Pitfall 3: `redact: true` alone does not cover `changeset.params`
**What goes wrong:** `cs.params["private_jwk_encrypted"]` holds the bytes. **Avoid:** `put_change` instead of `cast` for this field (F2).

### Pitfall 4: Treating `JOSE.JWK.from_map` returning as validity
**What goes wrong:** malformed EC/RSA maps return a struct and fail later at `sign` with an `ErlangError`. **Avoid:** the `to_public/1` probe inside the rescuing helper (F3). `keys: :undefined` is normal.

### Pitfall 5: Python harness env drift
**What goes wrong:** `System.fetch_env!` in `config.exs` crashes any `mix` subprocess whose environment lacks the var (install, compile, doctor, verify, restart of the provider). **Avoid:** set once in `os.environ` in `main()`; assert via `--check-bootstrap` that `clean-room-1` is gone and `fetch_env!` is present; update `check_bootstrap` in the same commit.

### Pitfall 6: Running the upgrade journey inside the sandbox
**What goes wrong:** the task's own `with_repo` connection cannot see uncommitted sandbox rows, and a started `TestRepo` makes the E2E precedent's `refute Process.whereis` fail. **Avoid:** committed data, repo stopped at start, prefixed kids, `on_exit` cleanup.

### Pitfall 7: Docs version string drift
**What goes wrong:** the guide says "1.6.0" while #121 ships 1.6.0 first. **Avoid:** Open Question 1; write the version once, in the release-note file and one guide sentence, so it is a one-line fix.

### Pitfall 8: Demo/ES256 side effects
**What goes wrong:** removing the RS256 key changes the demo's JWKS and token `alg`. **Avoid:** nothing pins RS256; still re-run `scripts/demo/adoption_smoke.py` and any `scripts/demo/admin-ui` flows locally if feasible, and update the doc line.

### Pitfall 9: Postgres statement logging
A host that sets `log_statement = 'all'` (or low `log_min_duration_statement`) writes bind parameters, including plaintext during re-encryption and envelopes, to the database server log, outside Lockspire's control. Add one sentence to the operational hygiene section. [ASSUMED, see A3]

## Runtime State Inventory

Not a rename/migration phase; the only runtime state touched is operator-owned data already covered by Phase 156 (stored rows) and the guide warnings (backups, WAL, replicas). Omitted per template.

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| Explicit `@derive Inspect` for secret fields | `redact: true` (auto-derive plus changeset masking) | Use both here: explicit derive stays on the domain struct; schema gets `redact: true` |
| Passing secrets in error tuples | Strip args from crypto exceptions (EEF) | The `to_jwk/1` shape |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Linux crash-dump file mode is also 0640 and `rel/env.sh.eex` is the right place to export `ERL_CRASH_DUMP_*` in an Elixir release | F5 | Guide wording slightly off; low |
| A2 | Release Please keeps parsing `BREAKING-CHANGE:` in squash bodies the same way in the version pinned by `.github/actions/release-please/runtime` (I read `main`, not the pinned version) | F6 | A bump surprise; mitigated by the pre-merge grep |
| A3 | Postgres `log_statement='all'` logs bind parameters of extended-protocol statements | Pitfall 9 | Guide sentence could be inaccurate; verify against postgresql.org before publishing |
| A4 | Setting the KEK in `os.environ` at the top of the clean-room `main()` reaches every child (all use `locked_environment` -> `os.environ.copy()`) | F9 | A child built from a non-inheriting env fails at `fetch_env!`; `--check-bootstrap` plus the journey run catches it |
| A5 | `sensitive: true` for the two extra list queries is acceptable to the user (loses JWKS-path Ecto query log lines) versus a column-omitting `select` | F1, C1 | User may prefer `select`; both pass the sweep, small rework |
| A6 | A hidden test file name for the KeyCache public-only guard (`key_cache_test.exs`) exists as named | F11 | Gate command needs the actual file; planner should grep |

## Open Questions

1. **Release Please PR #121 and the "1.6.0" label.**
   - Known: #121 (1.6.0, v1.42 only) is open, auto-merge is enabled, the v1.43 commits are unpushed.
   - Unclear: whether the user will hold or close #121, or accept encryption shipping as 1.7.0.
   - Recommendation: add a `checkpoint:human-action` task in 157-04 before the squash merge: confirm release sequencing; keep the version number out of the guide body except one clearly marked sentence plus the release-note file. This does not re-litigate D-16 (`feat` not breaking); it protects the label.
2. **Should the two extra list queries use `sensitive: true` or `select`?** Default to `sensitive: true`; ask only if the user objects to losing Ecto query lines on JWKS (A5).
3. **Dev/test `legacy_plaintext` for the printed variant** (`:reject` recommended, with an upgrade comment). Within discretion.
4. **Where in the clean-room sequence to run `--check`** (recommend after `provision!`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all mix verification | yes | 1.19.5-otp-28 (OTP 28.4.1) | local default is 1.17.3-otp-27: do not use for qa |
| PostgreSQL | integration, probe, demo | yes (accepting on `/tmp:5432`) | psql 14.17 | none |
| Python | clean-room harness | yes | 3.14.4 | none |
| openssl | docs commands / dev literal | yes | 3.6.3 | `elixir -e` one-liner |
| Docker | demo compose (manual check only) | yes | 29.5.2 | skip compose; CI job does the real check |
| gh CLI | Release Please / repo setting checks | yes (authenticated) | n/a | none |
| git | SAFE-01 gate | yes | 2.41.0 | none |

No blocking missing dependencies. The clean-room journey needs network and package build; run it only in CI or deliberately (not part of per-task feedback).

## Validation Architecture

(Nyquist enabled: `workflow.nyquist_validation: true` in `.planning/config.json`.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 / OTP 28), Python scripts for clean-room |
| Config file | `test/test_helper.exs` (integration excluded unless a path ends `.exs` or contains `integration`), `config/test.exs` (fixed test KEKs `test-1`, `test-2`) |
| Quick run command | `cd /Users/jon/projects/lockspire && HEX_HOME=/private/tmp/lockspire-hex ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 MIX_ENV=test mix test <files>` |
| Full suite command | same prefix with `mix test --include integration` (and CI's `mix qa`, Dialyzer) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command (append to the prefix above) | File Exists? |
|--------|----------|-----------|------------------------------------------------|-------------|
| RED-01 | No key bytes via repo log/telemetry for all 9 key-reading paths; sweep over logs, telemetry, audit, inspect, changeset, KeysLive/OverviewLive, exceptions | integration-style unit (DB sandbox) | `mix test test/lockspire/security/key_material_leak_test.exs` | exists, extend |
| RED-01 | Changeset `changes` masked, `params` free of the value, struct inspect masked | unit | `mix test test/lockspire/security/key_material_leak_test.exs` (new describe) or `test/lockspire/storage/ecto/signing_key_record_test.exs` | Wave 0 (new) |
| RED-01 | Redaction drops 9 key names (atom and string) in both surfaces, keeps `kid`/`kek_id`/`previous_kek_id`/`key_id`, drops `<<"LSK",1,...>>` values | unit | `mix test test/lockspire/redaction/redaction_test.exs` | exists, extend |
| RED-01 | `PrivateJwk.to_jwk/1` returns `{:error, :invalid_signing_key}` for malformed shapes (incl. OKP wrong-length `d`) and never raises or echoes; six consumers return existing error contract | unit | `mix test test/lockspire/protocol/private_jwk_test.exs test/lockspire/protocol/envelope_signing_consumers_test.exs` | exists, extend |
| RED-01 | Oban logout worker discards, no raise, no value in `Oban.Job.format_attempt` | unit | `mix test test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` | exists, extend |
| RED-01 | Admin assigns/HTML clean | LiveView | `mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/overview_live_test.exs` | exist |
| HOST-01 | Install prints runtime KEK block, `:reject`, `LOCKSPIRE_KEY_ENCRYPTION_KEY`, dev variant, two runs differ | integration | `mix test test/integration/install_generator_test.exs` | exists, extend |
| HOST-01 | Config error text names the Elixir one-liner and phx.gen.secret warning; `openssl` substring kept | unit | `mix test test/lockspire/config_key_encryption_test.exs test/lockspire/install/verify_test.exs` | exist, extend |
| HOST-01 | Demo seeds create only envelopes; `--check` and doctor pass on a seeded demo | CI job + local | `cd examples/adoption_demo && mix ecto.reset && mix lockspire.keys.reencrypt --check && mix lockspire.doctor key_encryption` (MIX_ENV=dev, Postgres up) ; CI step in `adoption-demo` | Wave 0 (CI steps) |
| HOST-01 | Clean-room host config has no literal KEK, reads env, `:reject`; evidence scan fails on KEK | integration + Python | `mix test test/integration/phase133_provider_install_test.exs` and `python3 scripts/acceptance/clean_room/build_provider.py --check-bootstrap` | exists |
| PROOF-01 | Upgrade journey: legacy to `:allow` signing to reencrypt to `--check` to byte assertions to `:reject` to rotate to remove `k1` | integration | `mix test test/integration/signing_key_upgrade_journey_test.exs` | Wave 0 (new) |
| PROOF-01 | All six consumers sign/decrypt from stored envelopes | integration | same file | Wave 0 |
| DOC-01 | Extras/groups/packaging, architecture order and 4 diagrams, walkthrough <= 18 parseable blocks, no `.planning/` in guides | unit | `mix test test/lockspire/documentation_contract_test.exs` | exists |
| DOC-01 | New guide contains the four steps, rotation, remanence, rollback, KEK-loss, separate backup, crash-dump text | unit | new contract test (suggest `test/lockspire/upgrade_guide_contract_test.exs`) asserting key phrases | Wave 0 (new, optional but recommended) |
| DOC-01 | Release-note file ready; no `BREAKING` token; title shape | shell | `git log origin/main..HEAD --format=%B \| grep -n BREAKING` (expect empty); `grep -n BREAKING .planning/phases/157-*/157-RELEASE-NOTES.md` (expect empty) | Wave 0 |
| SAFE-01 | No dep/migration/column change; fitness guards; protocol suites unchanged | shell + unit | commands in F11, plus `mix test test/lockspire/architecture_fitness_test.exs test/lockspire/config_key_encryption_test.exs` | exist |

### Sampling Rate
- **Per task commit:** the single touched test file(s) with the prefix command (seconds); for Python, `--check-bootstrap`.
- **Per wave merge:** `mix test test/lockspire test/mix --include integration` for Wave 1 touched areas; `mix format --check-formatted` and `mix compile --warnings-as-errors`.
- **Phase gate:** `mix test --include integration`, `mix qa`, Dialyzer, and the clean-room journey in CI on 1.19.5-otp-28 before `/gsd-verify-work` (note memory: local 1.20.x type warnings fail warnings-as-errors; qa/e2e run on CI Elixir).

### Wave 0 Gaps
- [ ] `test/support/` matcher module (D-05) and shared six-consumer drivers (D-11).
- [ ] `test/integration/signing_key_upgrade_journey_test.exs` (PROOF-01).
- [ ] Changeset/inspect test for `SigningKeyRecord` (RED-01).
- [ ] CI steps in `adoption-demo` job; clean-room `--check`/doctor calls.
- [ ] Optional upgrade-guide phrase contract test.

## Security Domain

`security_enforcement` is not set to false in `.planning/config.json`, so it applies.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged (no auth flow change) |
| V3 Session Management | no | unchanged |
| V4 Access Control | no | unchanged (admin mount unchanged) |
| V5 Input Validation | yes | `KeySet.new/1` validation (length, base64, weak-material, id pattern); `PrivateJwk.to_jwk/1` structural check |
| V6 Cryptography | yes | existing AES-256-GCM envelope with AAD binding (Phase 155); no new crypto; never hand-roll |
| V7 Error Handling and Logging | yes | `sensitive: true` repo options, `redact: true`, Redaction drop keys, no-arg exception handling |
| V8 Data Protection | yes | envelope-only storage by default, crash-dump and backup guidance |
| V14 Configuration | yes | KEK only in runtime config/env, generator never patches host files, demo/test literals are marked demo-only |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Key material in query telemetry/log | Information disclosure | `sensitive: true` on all key-column queries (9 paths) |
| Key material in changeset/inspect | Information disclosure | `redact: true` + `put_change` + derive except |
| Private bytes in exception messages persisted by Oban | Information disclosure | `PrivateJwk.to_jwk/1`, no re-raise with args |
| Shared fixed dev KEK reused in prod | Spoofing/Elevation | per-install random literal, `# dev/test only`, prod `raise` when env missing, `:reject` |
| Demo KEK literal copied into a real deployment | Elevation | clearly marked demo-only; fixed literal only in `examples/` |
| KEK in compile-time config | Information disclosure | runtime only; existing `compile_env` guard test |
| Crash dump / backups holding keys | Information disclosure | documented hygiene; remanence warning; rotate signing keys |
| Release metadata triggering unintended major bump | Tampering (process) | pre-merge `BREAKING` grep, no `!` |

## Sources

### Primary (HIGH confidence)
- This repo, read this session: `lib/lockspire/redaction.ex`, `storage/ecto/repository/{support,signing_key_store}.ex`, `storage/ecto/signing_key_record.ex`, `domain/signing_key.ex`, `protocol/private_jwk.ex` and the six consumers, `admin/keys.ex`, `workers/backchannel_logout_delivery_worker.ex`, `generators/install.ex`, `config.ex`, `application.ex`, `key_set.ex`, `mix.exs`, `test/test_helper.exs`, `documentation_contract_test.exs`, `architecture_fitness_test.exs`, `key_material_leak_test.exs`, `lockspire_keys_reencrypt_test.exs`, `envelope_signing_consumers_test.exs`, `key_encryption_helpers.ex`, `.github/workflows/ci.yml`, `release-please-automerge.yml`, `release-please-config.json`, `scripts/acceptance/clean_room/{build_provider,package_input,redaction}.py`, `clean_room_saas_journey.py`, adoption demo config/seeds/compose, docs files named in the findings.
- `deps/ecto/lib/ecto/schema.ex:2335-2350`, `deps/ecto/lib/ecto/changeset.ex:4340-4395`, `deps/oban/lib/oban/job.ex:450-466`, `deps/phoenix_live_dashboard/lib/phoenix/live_dashboard/system_info.ex:753` (env_keys reads `System.get_env(key)` only) and `pages/*` (no app-env or persistent_term display).
- Experiments in `/private/tmp/claude-501/.../scratchpad/` (`f1*.exs` Ecto, `f2*.exs` JOSE, `cd*.exs` crash dumps, `probe_test.exs` repo telemetry, `scan3.py` dump scanner): all outputs quoted above.
- GitHub API for this repo (`gh pr view 121`, repo settings, Actions variable).

### Secondary (MEDIUM confidence)
- Erlang erl command docs: https://www.erlang.org/doc/apps/erts/erl_cmd.html (ERL_CRASH_DUMP_*), https://www.erlang.org/doc/apps/erts/crash_dump.html (sections).
- Release Please: https://github.com/googleapis/release-please (README: squash recommendation, `BREAKING-CHANGE:` footer, `!`, `BEGIN_COMMIT_OVERRIDE`) and https://raw.githubusercontent.com/googleapis/release-please/main/src/commit.ts (parsing; read `main`, not the pinned version).

### Tertiary (LOW confidence)
- Postgres statement-logging behavior and `rel/env.sh.eex` for crash-dump env (A1, A3): from training knowledge, unverified here.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, no new deps, versions read from `mix.lock`.
- Architecture/plan file maps: HIGH, every path read.
- Pitfalls: HIGH for F1-F4, F7-F10 (experiment or source); MEDIUM for Release Please pinned-version behavior; LOW for A1/A3.

**Research date:** 2026-10-16
**Valid until:** 2026-11-15 (repo-local facts are stable until the branch lands; re-check PR #121 state and `origin/main` before planning 157-04).
