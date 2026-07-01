# Phase 102: Generated-Host Scaffolding + Telemetry + Migration - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

The install template, operator telemetry, the v1.27 migration guide, and a doctor task all reflect the now-proven blessed RS-token-acceptance path (shipped across Phases 97-101) so new adopters land on a working pipeline by default and existing adopters can migrate the issuance-default flip (opaque → JWT) safely. **Phase 102 is the LAST phase of v1.27 and mirrors what CI already proves — it must NOT lead the contract or add protocol breadth.** Requirements: SCAFFOLD-01, SCAFFOLD-02, TELEMETRY-01, MIGRATE-01, MIGRATE-02.

**In scope:** regression guards proving the install never prompts for token format and the install-template canonical pipeline block stays commented/uncomment-ready (SCAFFOLD-01/02); a `[:lockspire, :rs, :token_format]` telemetry event in `Lockspire.Plug.VerifyToken` (TELEMETRY-01); a net-new `docs/upgrading/v1.27.md` migration guide (MIGRATE-01); a `mix lockspire.doctor token_format` diagnostic subtask (MIGRATE-02).

**Out of scope:** any runtime/protocol behavior change to the verifier, signer, issuance, `/userinfo`, or `/introspect` (all shipped Phases 98-100); the four-file hash-lock mechanism itself (Phase 97); the adoption-demo smoke (Phase 101); any new install-time decision or protocol breadth.
</domain>

<decisions>
## Implementation Decisions

### A. Install scaffolding guards (SCAFFOLD-01, SCAFFOLD-02)

- **D-01:** SCAFFOLD-01 and SCAFFOLD-02 are **already satisfied by Phases 97/101** at the behavior level. The commented `# pipeline :lockspire_protected_api do … # end` canonical block already lives in `priv/templates/lockspire.install/router.ex:11-18` inside the `lockspire_routes/0` heredoc and renders verbatim into the host's generated `lib/<web>/router/lockspire.ex` (the block is a static heredoc region with no EEx tags — enforced by `release_readiness_contract_test.exs:209-212`, which raises if the canonical region contains an EEx tag). `lib/mix/tasks/lockspire.install.ex:16-26` parses only `web/scope/path/mount_path/help/sigra_host` — there is no token-format switch today. Phase 102 therefore adds **no new generated-output behavior** for these two requirements.
- **D-02:** Phase 102's real SCAFFOLD work is **two regression guards** added to `test/lockspire/release_readiness_contract_test.exs`:
  1. **No-format-prompt guard:** `refute` any token-format prompt or format decision ever appears in the install task/generator source (`lib/mix/tasks/lockspire.install.ex` and `lib/lockspire/generators/install.ex`) — e.g. `refute source =~ ~r/access_token_format|token.format|:jwt|:opaque/i`. Closes SCAFFOLD-02 against silent reintroduction.
  2. **Uncomment-ready guard:** assert the canonical `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` block in the install template is fully commented (every body line prefixed `# `), reusing the existing extraction helper at `release_readiness_contract_test.exs:745-759`. Closes SCAFFOLD-01 against the block being accidentally un-commented or de-synced.

### B. RS telemetry event (TELEMETRY-01)

- **D-03:** Emit the event via **`:telemetry.execute([:lockspire, :rs, :token_format], measurements, metadata)` directly** — NOT through `Lockspire.Observability.emit/4`. Rationale: `emit/4` (`lib/lockspire/observability.ex:29-41`) double-emits a `[:lockspire, :audit, :rs, :token_format]` copy and runs metadata redaction — neither is wanted for a per-request RS verification counter (audit-log flooding on every protected API request; possible `client_id` redaction).
- **D-04:** The measurement is the numeric map `%{count: 1}` (matching the repo convention that telemetry measurements are numeric — `observability.ex:29-31` hard-codes `count: 1`). The categorical `:jwt | :opaque-rejected` value rides in **metadata** under the `token_format` key, alongside `client_id`, `audience`, `binding_type`.
- **D-05:** Emit at **two sites** in `lib/lockspire/plug/verify_token.ex`:
  1. **JWT-success** — in `do_verify_token/3` after `apply_restrictions/2` succeeds (~line 128-136): `%{token_format: :jwt, client_id: <claims client_id>, audience: <Map.get(claims, "aud")>, binding_type: <binding_type(claims)>}`. The `%AccessToken{}` already carries `client_id` and `binding_type`; `audience` is read from `claims["aud"]` because the `AccessToken` struct (`access_token.ex:6-15`) has no top-level audience field.
  2. **Opaque-rejection** — in the structural-opaque branch of `verify_token/3` (~line 111-118): `%{token_format: :"opaque-rejected", client_id: nil, audience: nil, binding_type: nil}` (opaque tokens carry no parseable claims).
- **D-06:** **Emit on opaque-rejection too**, not success-only. TELEMETRY-01's prose says "on every successful verification," but the `:opaque-rejected` value is only reachable on the rejection path; intent is read as "every verification attempt that reaches a format decision." (User-confirmed.)
- **D-07:** The metadata value is the **literal hyphenated atom `:"opaque-rejected"`**, matching the requirement text verbatim, rather than the idiomatic `:opaque_rejected`. This is an external contract operators subscribe to and match on. (User-confirmed.)

### C. Migration guide (MIGRATE-01)

- **D-08:** Create net-new `docs/upgrading/v1.27.md` (the `docs/upgrading/` directory does not exist yet; this is the first file in it — no in-directory precedent to mirror). It explains the default issuance flip (opaque → `:jwt`) and the affected-client set.
- **D-09:** The "one-line opt-the-whole-deployment-back-to-opaque" mechanism is documented **honestly as a runtime `ServerPolicy` update** — `Lockspire.Admin.ServerPolicy.put_access_token_format(:opaque)` (`lib/lockspire/admin/server_policy.ex:65-71`, a one-call runtime `update_server_policy` flip) — and the guide states explicitly that there is **no `config :lockspire` key** for this, because Phase 99 D-04 made the server-wide format runtime-editable on the `ServerPolicy` record, not a boot-time `Config` value. Telling operators to edit `config/*.exs` would be a silent no-op.
- **D-10:** The guide names affected clients as **"every client whose `access_token_format` is `nil`"** — these inherit the new server default `:jwt`. It cross-references the authoritative precedence in `Lockspire.Protocol.AccessTokenSigner.resolve_format/2` (`access_token_signer.ex:88-98`): per-client `:jwt|:opaque` wins; `nil` inherits `ServerPolicy.access_token_format` (default `:jwt` per `server_policy.ex:38`). Clients with an explicit `:opaque` override are NOT affected and must not be named as changed.
- **D-11:** Pin the guide with a contract-test constant (e.g. `@upgrading_v1_27_path`) plus assertions in `release_readiness_contract_test.exs` that the doc states the honest runtime opt-out mechanism and the `nil`-inherit affected-client naming, so the migration truth cannot silently drift from shipped behavior.

### D. Doctor task (MIGRATE-02)

- **D-12:** Add a **new subtask module `Mix.Tasks.Lockspire.Doctor.TokenFormat`**, dispatched by a new `run(["token_format" | rest])` clause in `Mix.Tasks.Lockspire.Doctor` (`lib/mix/tasks/lockspire.doctor.ex:11-13`) — so the invocation is `mix lockspire.doctor token_format`, matching the success criterion verbatim. Mirror the existing `Mix.Tasks.Lockspire.Doctor.RemoteJwks` subtask shape (OptionParser, `@requirements ["app.config"]`, `Mix.shell().info` output via a `print_result`-style helper). NOT an inline extension of the main doctor task — that would mismatch the leading-arg dispatcher symmetry.
- **D-13:** The task enumerates all clients via `Lockspire.Admin.Clients.list_clients/1` (`clients.ex:82-85`, returns `{:ok, [Client.t()]}`), reads the server default via `Lockspire.Admin.ServerPolicy.get_server_policy/0` (`server_policy.ex:40-43`), and computes each client's effective format by **reusing `AccessTokenSigner.resolve_format/2`** — not a reimplementation — so the diagnostic cannot report a different effective format than what is actually issued.
- **D-14:** Output is **read-only and diagnostic-only**: a per-client report line plus a flag on **every client with `access_token_format: nil`** (semantics changed — now inherits `:jwt`). No mutation, no `Mix.raise`, no non-zero exit on flagged clients (the criterion says "diagnostic, not enforcement"; raising could break operator CI that runs doctor).

### Claude's Discretion

- Exact regression-guard test names/structure for D-02, provided both the no-format-prompt refute and the uncomment-ready assertion exist and reuse the existing extraction helper.
- Exact public function name/arity for the telemetry emit helper (inline vs a small private `emit_token_format/4`), provided D-03/D-04/D-05 (direct execute, numeric measurement, two sites, metadata keys) hold.
- Exact prose, headings, and ordering of `docs/upgrading/v1.27.md`, provided D-09 (honest runtime opt-out, no phantom config key) and D-10 (`nil`-inherit naming) hold.
- Exact per-client report line format and flag wording for the doctor task, provided D-13 (reuse `resolve_format/2`) and D-14 (read-only, flag `nil` clients) hold.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase boundary and prior decisions
- `.planning/ROADMAP.md` — Phase 102 goal, four success criteria, and the "Phase 102 must be last / scaffold mirrors what CI proves" build-order rationale.
- `.planning/REQUIREMENTS.md` — SCAFFOLD-01/02, TELEMETRY-01, MIGRATE-01/02 verbatim; traceability (Phase 102 = 5 reqs).
- `.planning/PROJECT.md` — v1.27 milestone goal; Branch A + JWT-default issuance Key Decision; sustainment-default policy.
- `.planning/METHODOLOGY.md` — assumption-first decisive defaults, least-surprise host seam, one-shot recommendation bundle.
- `.planning/phases/99-signer-extraction-jwt-default-issuance/99-CONTEXT.md` — D-04 (server-wide `access_token_format` on runtime `ServerPolicy`, NOT `Config`); D-05/D-06 (per-client nullable override, `nil`=inherit); the issuance flip this phase migrates.
- `.planning/phases/97-contract-docs-first/97-CONTEXT.md` — the four-file canonical-block hash-lock mechanism and BEGIN/END markers the install-template guard depends on.
- `.planning/phases/101-adoption-demo-re-wire/101-CONTEXT.md` — canonical audience URI `https://billing.acme-ledger.test`; the blessed pipeline the install template mirrors.

### Install scaffolding
- `priv/templates/lockspire.install/router.ex` — lines 11-18: the commented canonical pipeline block inside the `lockspire_routes/0` heredoc (already uncomment-ready).
- `lib/mix/tasks/lockspire.install.ex` — lines 16-26: install task arg parsing (no format switch today; the no-prompt guard target).
- `lib/lockspire/generators/install.ex` — install generator source (second no-format-prompt guard target).
- `test/lockspire/release_readiness_contract_test.exs` — lines 209-212 (EEx-tag refute on canonical region), 745-759 (canonical-block extraction helper to reuse for the uncomment-ready guard).
- `test/lockspire/install_generator_test.exs` — lines 65-78: proves the template→host render path (verify routes + prefill text in rendered router).

### RS telemetry
- `lib/lockspire/plug/verify_token.ex` — `call/2` (~71-81); `verify_token/3` opaque-rejection branch (~105-118); `do_verify_token/3` JWT-success return building `%AccessToken{client_id, binding_type}` (~124-136); `binding_type(claims)` helper.
- `lib/lockspire/plug/access_token.ex` — lines 6-15: `AccessToken` struct fields (note: NO top-level `audience`; read `claims["aud"]`).
- `lib/lockspire/observability.ex` — lines 29-41: the `emit/4` helper (audit double-emit + redaction + numeric `count: 1` convention) — the reason D-03 uses direct `:telemetry.execute`.

### Migration guide
- `lib/lockspire/admin/server_policy.ex` — lines 40-43 (`get_server_policy/0`), 65-71 (`put_access_token_format/1`, the honest one-line runtime opt-out).
- `lib/lockspire/protocol/access_token_signer.ex` — lines 88-98: `resolve_format/2` (authoritative per-client → server-default → `:jwt` precedence the guide and doctor cross-reference).
- `lib/lockspire/domain/server_policy.ex` — line 38: server default `:jwt`.
- `docs/upgrading/` — net-new directory; `docs/upgrading/v1.27.md` is the first file.

### Doctor task
- `lib/mix/tasks/lockspire.doctor.ex` — lines 11-13: leading-arg subcommand dispatcher (`remote-jwks` precedent).
- `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` — the subtask shape to mirror (OptionParser, `@requirements ["app.config"]`, `Mix.shell().info` output).
- `lib/lockspire/admin/clients.ex` — lines 82-85: `list_clients/1` for enumeration.

### Standards
- RFC 9068 (`at+jwt`), RFC 8707 (`resource`→`aud`) — context for the `audience` telemetry metadata value.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The install-template canonical block + four-file hash lock (Phases 97/101) already deliver SCAFFOLD-01/02's user-visible behavior; the canonical-block extraction helper (`release_readiness_contract_test.exs:745-759`) is directly reusable for the new uncomment-ready guard.
- `Lockspire.Admin.ServerPolicy.put_access_token_format/1` already exists as the one-call runtime opt-back-to-opaque mechanism — the migration guide documents it, no new code needed for the opt-out itself.
- `AccessTokenSigner.resolve_format/2` is the single authoritative format-precedence rule; both the migration guide and the doctor task reference/reuse it rather than reimplementing precedence.
- `Mix.Tasks.Lockspire.Doctor.RemoteJwks` is a complete worked example of a `lockspire.doctor <subcommand>` subtask — the `token_format` subtask follows it shape-for-shape.
- `%AccessToken{}` already carries `client_id` and `binding_type` on the success path; telemetry metadata needs no new struct fields (audience comes from `claims["aud"]`).

### Established Patterns
- Telemetry convention (`observability.ex:29-31`): measurements are numeric (`count: 1`); categorical values ride in metadata. The RS event follows this — `token_format` is metadata, not a measurement.
- Doctor subcommands dispatch by leading arg in the main task and delegate to a dedicated `Mix.Tasks.Lockspire.Doctor.<Name>` module.
- Release-readiness contract tests are the load-bearing drift fence: scaffolding/migration truth is pinned by `refute`/assert clauses so it cannot silently diverge from shipped behavior.
- Server-wide format is durable runtime `ServerPolicy` state (Phase 99 D-04), never boot-time `Config` — every Phase 102 surface (migration opt-out wording, doctor server-default read) must reflect this.

### Integration Points
- `verify_token.ex` success + opaque-rejection branches are the two telemetry emit sites; the event is consumed by operator `:telemetry`/`Telemetry.Metrics` reporters.
- `docs/upgrading/v1.27.md` is consumed by upgrading operators and pinned by a new contract-test constant.
- `mix lockspire.doctor token_format` reads live `ServerPolicy` + client rows at runtime; its effective-format computation must match `AccessTokenSigner.resolve_format/2` exactly.
</code_context>

<specifics>
## Specific Ideas

- Telemetry event value: literal hyphenated atom `:"opaque-rejected"` (matches REQUIREMENTS.md text verbatim; external contract). Confirmed by user.
- Telemetry fires on opaque-rejection as well as JWT-success, so the full `:jwt | :opaque-rejected` value set is observable. Confirmed by user.
- Migration "one-line opt-out" is the runtime `ServerPolicy.put_access_token_format(:opaque)` call — explicitly NOT a `config/*.exs` key (would be a silent no-op). This is the truthful least-surprise host-seam answer aligned with Phase 99 D-04.
- Doctor task is diagnostic-only (no enforcement / non-zero exit) per the criterion's explicit wording.

## Methodology Lenses Applied
- **Least-surprise host seam:** telemetry modeled as durable protocol-observable state via direct `:telemetry.execute`; migration opt-out documented as the truthful runtime mechanism, not a phantom config key.
- **Assumption-first decisive defaults / one-shot bundle:** all four areas resolved from real call sites and shipped prior decisions; the only two genuinely product-shaping items (telemetry atom spelling, emit-on-rejection) were surfaced for confirmation rather than silently locked, and the user confirmed both.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope. Phase 102 is the last v1.27 phase; remaining out-of-scope items (one-token-everywhere `at+jwt` at `/userinfo`, cross-process/remote Lockspire) are tracked under REQUIREMENTS.md Future Requirements, not this milestone.
</deferred>

---

*Phase: 102-generated-host-scaffolding-telemetry-migration*
*Context gathered: 2026-05-28 (assumptions mode)*
