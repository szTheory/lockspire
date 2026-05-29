# Phase 102: Generated-Host Scaffolding + Telemetry + Migration - Research

**Researched:** 2026-05-29
**Domain:** Elixir/Phoenix library — install scaffolding regression guards, `:telemetry` emission, operator migration docs, Mix doctor subtask. All work MIRRORS shipped Phases 97-101 behavior; it does not lead the contract.
**Confidence:** HIGH (every cited call site verified by direct file read this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Phase 102's CONTEXT.md (assumptions mode) resolves the technical approach to specific functions and call sites. These are LOCKED — research confirms them, does not re-litigate.

- **D-01:** SCAFFOLD-01/02 are already satisfied at the behavior level by Phases 97/101. The commented `# pipeline :lockspire_protected_api do … # end` canonical block already lives in the install template inside `lockspire_routes/0`'s heredoc and renders verbatim into the host's generated router. The install task parses only `web/scope/path/mount_path/help/sigra_host` — no token-format switch today. Phase 102 adds **no new generated-output behavior** for these two requirements.
- **D-02:** Phase 102's real SCAFFOLD work is **two regression guards** in `release_readiness_contract_test.exs`: (1) a no-format-prompt `refute` over the install task + generator source; (2) an uncomment-ready assertion that the canonical block stays fully commented.
- **D-03:** Emit the telemetry event via **`:telemetry.execute([:lockspire, :rs, :token_format], measurements, metadata)` directly** — NOT through `Lockspire.Observability.emit/4` (which double-emits an audit copy and runs metadata redaction).
- **D-04:** Measurement is the numeric map `%{count: 1}`. The categorical `:jwt | :"opaque-rejected"` value rides in **metadata** under the `token_format` key, alongside `client_id`, `audience`, `binding_type`.
- **D-05:** Emit at **two sites** in `verify_token.ex`: JWT-success (after restrictions succeed) and opaque-rejection (structural-opaque branch).
- **D-06:** **Emit on opaque-rejection too**, not success-only. (User-confirmed.)
- **D-07:** Metadata value is the **literal hyphenated atom `:"opaque-rejected"`**, matching requirement text verbatim — external operator contract. (User-confirmed.)
- **D-08:** Create net-new `docs/upgrading/v1.27.md` (the `docs/upgrading/` directory does not exist yet).
- **D-09:** Document the opt-out **honestly as a runtime `ServerPolicy` update** — `Lockspire.Admin.ServerPolicy.put_access_token_format(:opaque)` — and state explicitly there is **no `config :lockspire` key** for this.
- **D-10:** Name affected clients as **"every client whose `access_token_format` is `nil`"**; cross-reference `AccessTokenSigner.resolve_format/2` precedence. Clients with explicit `:opaque` override are NOT affected.
- **D-11:** Pin the guide with a contract-test constant + assertions in `release_readiness_contract_test.exs`.
- **D-12:** Add a **new subtask module `Mix.Tasks.Lockspire.Doctor.TokenFormat`**, dispatched by a new `run(["token_format" | rest])` clause in `Mix.Tasks.Lockspire.Doctor`. Mirror the existing `RemoteJwks` subtask shape.
- **D-13:** Enumerate clients via `Clients.list_clients/1`, read server default via `ServerPolicy.get_server_policy/0`, compute each client's effective format by **reusing `AccessTokenSigner.resolve_format/2` precedence logic** — not a reimplementation. **(See LANDMINE-1: `resolve_format/2` is `defp` — see "Common Pitfalls".)**
- **D-14:** Output is **read-only and diagnostic-only**: per-client report line plus a flag on every `access_token_format: nil` client. No mutation, no `Mix.raise`, no non-zero exit.

### Claude's Discretion

- Exact regression-guard test names/structure for D-02 (both guards must exist and reuse the existing extraction helper).
- Exact function name/arity for the telemetry emit helper (inline vs small private `emit_token_format/4`).
- Exact prose, headings, ordering of `docs/upgrading/v1.27.md` (D-09/D-10 must hold).
- Exact per-client report line format and flag wording for the doctor task (D-13/D-14 must hold).

### Deferred Ideas (OUT OF SCOPE)

None for this phase. Out-of-milestone items (one-token-everywhere `at+jwt` at `/userinfo`, cross-process/remote Lockspire) are tracked in REQUIREMENTS.md Future Requirements, NOT here. Phase 102 must not add protocol breadth.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCAFFOLD-01 | Install template ships the commented `:lockspire_protected_api` pipeline mirroring the demo's blessed pipeline. | Already shipped (Phase 97/101). Block lives at `priv/templates/lockspire.install/router.ex:11-18`. Phase 102 adds the **uncomment-ready regression guard** (D-02 #2). |
| SCAFFOLD-02 | `mix lockspire.install` does NOT ask about token format. | Already true — install task parses no format switch. Phase 102 adds the **no-format-prompt refute guard** (D-02 #1). |
| TELEMETRY-01 | `[:lockspire, :rs, :token_format]` event on every verification through `VerifyToken`; `:jwt \| :"opaque-rejected"` + `client_id`/`audience`/`binding_type` metadata. | New direct `:telemetry.execute` at two sites in `verify_token.ex` (D-03/04/05). |
| MIGRATE-01 | `docs/upgrading/v1.27.md` names the issuance flip, the runtime opt-out, and the `nil`-inherit affected-client set. | Net-new doc (D-08/09/10) + contract-test pin (D-11). |
| MIGRATE-02 | `mix lockspire.doctor token_format` per-client diagnostic report; flags changed-semantics clients. | New `Doctor.TokenFormat` subtask (D-12/13/14). |
</phase_requirements>

## Summary

Phase 102 is the final v1.27 phase and is almost entirely **validation/guard/diagnostic work that mirrors already-shipped behavior**. Two of the five requirements (SCAFFOLD-01/02) are already satisfied at the user-visible behavior level by Phases 97 and 101 — the install template already carries the commented canonical pipeline block with the absolute audience URI `https://billing.acme-ledger.test`, and the install task already takes no token-format argument. Phase 102's job for those two is purely to add **regression fences** so they cannot silently regress. The three genuinely net-new surfaces are: a `[:lockspire, :rs, :token_format]` `:telemetry` event emitted at two sites inside `Lockspire.Plug.VerifyToken`; a net-new `docs/upgrading/v1.27.md` migration guide pinned by a contract test; and a `mix lockspire.doctor token_format` read-only diagnostic subtask.

All call sites cited in CONTEXT.md were verified by direct file read. **The technical decisions are sound, but three citations have drift that the planner must correct** (see "Citation Accuracy Audit"): the `AccessToken` struct is at `lib/lockspire/access_token.ex` (module `Lockspire.AccessToken`), NOT `lib/lockspire/plug/access_token.ex`; the contract-test extraction helper is *defined* at line 140 (used at 745-759 — CONTEXT conflated definition with use site); and most importantly **`AccessTokenSigner.resolve_format/2` is a `defp` (private)** — the doctor task (D-13) cannot call it directly and must reproduce its three-clause precedence logic against the public `Client`/`ServerPolicy` structs.

The single highest-leverage finding for validation: the established ExUnit telemetry-test idiom in this repo is `:telemetry.attach_many/4` with a handler that `send`s `{:telemetry_event, event, metadata}` to `self()`, then `assert_received`. Mirror `test/lockspire/clients_test.exs:158-182` exactly. And D-03's "don't use `emit/4`" rationale is even stronger than stated: `Redaction.sanitize_value(nil, _)` returns `:drop` (`redaction.ex:195`), so routing the opaque-rejection metadata (all-`nil` values) through `emit/4` would silently strip every field — direct `:telemetry.execute` is mandatory, not merely preferred.

**Primary recommendation:** Treat D-01 through D-14 as locked. Plan four work streams (SCAFFOLD guards / telemetry / migration doc / doctor task) that can run largely in parallel after a shared Wave 0 that fixes the three cited-path corrections. The phase's center of gravity is the `## Validation Architecture` section below — nearly every deliverable IS a test or a pinned contract.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Install scaffolding regression guards (SCAFFOLD-01/02) | Build/Test (`release_readiness_contract_test.exs`) | — | These are drift fences over repo source files, not runtime behavior. They belong in the load-bearing contract test, not in any runtime module. |
| RS token-format telemetry (TELEMETRY-01) | API / Backend (`Lockspire.Plug.VerifyToken`) | Operator observability (`:telemetry` consumers) | The plug is the single point every host-API verification flows through; the event is consumed by operator `Telemetry.Metrics` reporters out-of-process. |
| Migration guide (MIGRATE-01) | Docs (`docs/upgrading/v1.27.md`) | Build/Test (contract-test pin) | Operator-facing prose; its truth is fenced by a contract test so it can't drift from shipped runtime behavior. |
| Doctor diagnostic (MIGRATE-02) | CLI tooling (`Mix.Tasks.Lockspire.Doctor.TokenFormat`) | Admin query layer (`Clients`, `ServerPolicy`) | Read-only operator CLI that reads live `ServerPolicy` + client rows; computes effective format using the same precedence the signer uses. |

## Standard Stack

No new packages. This phase uses only the existing dependency set and Elixir/OTP standard facilities.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | already a transitive dep (Phoenix/Plug pull it; used throughout `lib/lockspire/observability.ex`) | Emit `[:lockspire, :rs, :token_format]` event | Erlang-ecosystem standard event bus; the repo already emits all its events through it. `:telemetry.execute/3` is the canonical emit call. [VERIFIED: codebase — `observability.ex:31` already calls `:telemetry.execute/3`] |
| ExUnit | bundled with Elixir | Telemetry assertions, contract guards, doctor test | Repo's only test framework. [VERIFIED: codebase — all tests `use ExUnit.Case`] |
| Mix.Task | bundled with Elixir/Mix | Doctor subtask | Existing doctor dispatcher + `RemoteJwks` subtask already use `use Mix.Task`. [VERIFIED: `lockspire.doctor.remote_jwks.ex:6`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `OptionParser` | bundled | Parse doctor subtask args | Mirror `RemoteJwks` `@switches`/`OptionParser.parse(... strict: ...)` at `lockspire.doctor.remote_jwks.ex:14-21`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Direct `:telemetry.execute/3` | `Lockspire.Observability.emit/4` | REJECTED by D-03. `emit/4` double-emits an audit-prefixed copy (audit-log flooding on every protected request) AND runs `Redaction.for_telemetry` which **drops all-`nil` metadata** (see Pitfall 2). Direct execute is mandatory. |
| New `Doctor.TokenFormat` subtask | Inline clause in main doctor task | REJECTED by D-12. The dispatcher already uses leading-arg → dedicated module symmetry (`run(["remote-jwks" \| rest])`). An inline extension breaks that symmetry. |

**Installation:** None.

**Version verification:** N/A — no external packages added. `:telemetry` already resolved in `mix.lock` as a transitive dependency; no new registry entries.

## Package Legitimacy Audit

> Not applicable — Phase 102 installs **no external packages**. All work uses the existing dependency set (`:telemetry`, ExUnit, Mix, OptionParser, JOSE for the existing claims path). slopcheck gate intentionally skipped: zero new third-party packages to audit.

## Citation Accuracy Audit

> **REQUIRED READING for the planner.** CONTEXT.md was gathered in assumptions mode and cites file paths and line numbers. Each was verified this session. Confirmed citations are safe to plan against verbatim; the three DRIFT rows below must be corrected in plans.

| CONTEXT.md citation | Verified? | Notes / Correction |
|---------------------|-----------|--------------------|
| `priv/templates/lockspire.install/router.ex:11-18` — commented canonical block in `lockspire_routes/0` heredoc | ✅ CONFIRMED | Block is at lines 11-18, wrapped in `# BEGIN/END LOCKSPIRE_PROTECTED_PIPELINE` markers. Carries `audience: "https://billing.acme-ledger.test"`, `enforce_audience: true`. Static heredoc, no EEx tags in the block. |
| `lib/mix/tasks/lockspire.install.ex:16-26` — arg parse, no format switch | ✅ CONFIRMED | `OptionParser.parse` strict list is exactly `web/scope/path/mount_path/help/sigra_host` (lines 16-26). No `:jwt`/`:opaque`/format token anywhere in the file. |
| `lib/lockspire/generators/install.ex` — second no-format-prompt target | ✅ CONFIRMED | No format logic. NOTE: generator renders the template via `EEx.eval_file` at runtime (line 87), so the generator *source* never contains `:jwt`/`:opaque`. The D-02 refute over generator source is therefore safe and will pass. |
| `release_readiness_contract_test.exs:209-212` — EEx-tag refute on canonical region | ✅ CONFIRMED | Lines 209-211: raises if a `.ex` canonical region contains `<%`. Inside `canonical_hash!/2`. |
| `release_readiness_contract_test.exs:745-759` — "canonical-block extraction helper to reuse" | ⚠️ **DRIFT** | Lines 745-759 are a **test that USES** the helper, not the helper definition. The reusable helper `extract_canonical_pipeline!/2` is **defined at line 140**. The `:elixir_in_commented_heredoc` kind constant for the install template is used at 749/765/1191. Plan against `extract_canonical_pipeline!/2` (def line 140) + `@install_template_router_path` (def line 88). |
| `verify_token.ex` opaque-rejection branch `~111-118` | ✅ CONFIRMED (minor) | Opaque branch is lines **105-122** (`if opaque_shape?(token) do ... end`); the `%AccessToken{...}` returned is lines 114-118. Emit site = just before/after building that struct. |
| `verify_token.ex` `do_verify_token/3` JWT-success return `~124-136` | ✅ CONFIRMED | Success `%AccessToken{}` built lines 128-135, then `\|> apply_restrictions(opts)` (line 136). **Important:** emit the JWT-success event AFTER `apply_restrictions/2` succeeds, but `apply_restrictions/2` can still set `.error` (audience/scope failure) — see Pitfall 4 for where exactly to emit so the count reflects "format decision reached," not "fully authorized." |
| `verify_token.ex` `binding_type(claims)` helper | ✅ CONFIRMED | `binding_type/1` at lines 467-479, returns `"dpop" \| "mtls" \| "dpop+mtls" \| nil`. Already populated on the success-path struct (`binding_type:` line 133). |
| `lib/lockspire/plug/access_token.ex:6-15` — `AccessToken` struct, no top-level audience | ❌ **DRIFT** | **No such file.** The struct is `Lockspire.AccessToken` at **`lib/lockspire/access_token.ex:6-15`** (aliased in `verify_token.ex:15` as `alias Lockspire.AccessToken`). Field set confirmed: `:token, :claims, :client_id, :authorization_scheme, :binding_type, :binding_requirements, :error, binding_verified: false`. **No `audience` field** — read `claims["aud"]` for telemetry, as CONTEXT says. Correct the path in any plan. |
| `observability.ex:29-41` — `emit/4`, audit double-emit + redaction + `count: 1` | ✅ CONFIRMED | `emit/4` lines 25-44: emits both `[:lockspire, :audit, entity, action]` and `[:lockspire, entity, action]`, runs `redact/1`, `Map.put_new(measurements, :count, 1)`. D-03's rationale holds and is reinforced (see Pitfall 2). |
| `server_policy.ex:65-71` (Admin) — `put_access_token_format/1` runtime opt-out | ✅ CONFIRMED | `Lockspire.Admin.ServerPolicy.put_access_token_format/1` at lines 65-73. One-call `Repository.update_server_policy`. Accepts `:jwt \| :opaque` (atom or string). |
| `server_policy.ex:40-43` (Admin) — `get_server_policy/0` | ✅ CONFIRMED | Returns `{:ok, ServerPolicy.t()} \| {:error, term()}` (lines 40-43). Doctor must pattern-match `{:ok, policy}`. |
| `access_token_signer.ex:88-98` — `resolve_format/2` precedence | ⚠️ **DRIFT (severity: high)** | Function exists at lines 88-98 with exactly the stated three-clause precedence (per-client `:jwt\|:opaque` → server `access_token_format \|\| :jwt` → `:jwt`). **BUT it is `defp` (private).** D-13's "reuse `resolve_format/2`" cannot be a direct call. See LANDMINE-1 / Pitfall 1 for the resolution options. |
| `domain/server_policy.ex:38` — server default `:jwt` | ✅ CONFIRMED | `access_token_format: :jwt` in the defstruct (line 38). `@type access_token_format :: :jwt \| :opaque` (line 10). |
| `lockspire.doctor.ex:11-13` — leading-arg dispatcher | ✅ CONFIRMED | `run(["remote-jwks" \| rest])` at lines 11-13 delegates via `Mix.Task.run/2`. Fallback `run(_args)` raises an "Unknown doctor command" help block (lines 15-22) — **the new `token_format` clause must be added AND the help text in the fallback updated** (otherwise the help lies). |
| `lockspire.doctor.remote_jwks.ex` — subtask shape to mirror | ✅ CONFIRMED | `use Mix.Task`, `@requirements ["app.config"]`, `@switches`, `OptionParser.parse(... strict:)`, `print_result/1` helper, `Mix.shell().info/1` per-line output. Clean template to copy. |
| `clients.ex:82-85` — `list_clients/1` | ✅ CONFIRMED | `Lockspire.Admin.Clients.list_clients/1`, returns `{:ok, [Client.t()]} \| {:error, term()}` (lines 82-85). Doctor must match `{:ok, clients}`. |
| `install_generator_test.exs:65-78` — template→host render proof | ⚠️ minor path note | File is at `test/integration/install_generator_test.exs` (not `test/lockspire/...`). Referenced as a render-path precedent; not edited by this phase. |

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────── Phase 102 surfaces ──────────────────┐
                         │                                                          │
 host API request        │   ┌────────────────────────────────────────────────┐   │
 (Bearer/DPoP token) ───────▶│  Lockspire.Plug.VerifyToken.call/2              │   │
                         │   │    extract_token → verify_token/3              │   │
                         │   │      ├─ opaque_shape?  ── YES ─▶ opaque branch ─┼───┼─▶ :telemetry.execute(
                         │   │      │   (lines 105-122)        [EMIT SITE B]    │   │      [:lockspire,:rs,:token_format],
                         │   │      │                          token_format:    │   │      %{count: 1},
                         │   │      │                          :"opaque-rejected"│   │      %{token_format: ...,
                         │   │      └─ NO ─▶ do_verify_token/3                  │   │        client_id, audience,
                         │   │            JOSE verify + rfc9068 + restrictions │   │        binding_type})
                         │   │            success %AccessToken{} ─[EMIT SITE A]┼───┼─▶  (same event,
                         │   │              (lines 128-136)     token_format::jwt│   │     :jwt value)
                         │   └────────────────────────────────────────────────┘   │
                         │                                                          │   consumed by operator
                         └──────────────────────────────────────────────────────────▶ Telemetry.Metrics reporter

  BUILD/TEST tier                                          DOCS + CLI tiers
  ┌────────────────────────────────────────┐   ┌──────────────────────────────────────────────┐
  │ release_readiness_contract_test.exs     │   │ docs/upgrading/v1.27.md  (net-new)            │
  │  • no-format-prompt refute (D-02 #1)    │   │   • issuance flip opaque→:jwt                 │
  │    over install task + generator source │   │   • runtime opt-out:                          │
  │  • uncomment-ready assert (D-02 #2)     │   │     ServerPolicy.put_access_token_format(:opaque)
  │    over RAW install-template bytes       │   │   • affected = clients w/ access_token_format=nil
  │  • migration-guide pins (D-11)          │◀──┼── pinned by @upgrading_v1_27_path assertions   │
  └────────────────────────────────────────┘   └──────────────────────────────────────────────┘
                                                ┌──────────────────────────────────────────────┐
   reads live state ◀───────────────────────── │ mix lockspire.doctor token_format             │
   ServerPolicy.get_server_policy/0            │   Clients.list_clients/1 + get_server_policy/0 │
   Clients.list_clients/1                      │   effective format via resolve_format precedence│
                                                │   flag every access_token_format: nil client  │
                                                └──────────────────────────────────────────────┘
```

### Recommended Project Structure

```
lib/mix/tasks/
├── lockspire.doctor.ex              # ADD run(["token_format" | rest]) clause + update fallback help
└── lockspire.doctor.token_format.ex # NEW — mirror lockspire.doctor.remote_jwks.ex shape

lib/lockspire/plug/
└── verify_token.ex                  # ADD direct :telemetry.execute at two sites

docs/upgrading/
└── v1.27.md                         # NEW directory + file

test/lockspire/
└── release_readiness_contract_test.exs   # ADD 4 guard clauses (2 scaffold, 2 migration-pin)

test/lockspire/plug/
└── verify_token_telemetry_test.exs  # NEW (or extend existing verify_token test) — attach/detach + assert_received

test/mix/tasks/
└── lockspire_doctor_token_format_test.exs # NEW — mirror lockspire_doctor_remote_jwks_test.exs
```

### Pattern 1: Direct `:telemetry.execute/3` emission (bypassing Observability)
**What:** Emit the RS event with no audit copy and no redaction.
**When to use:** Both emit sites in `verify_token.ex`.
**Example:**
```elixir
# Source: codebase convention — observability.ex:31 uses :telemetry.execute/3;
# D-03 mandates bypassing emit/4. measurement numeric (D-04), category in metadata.
:telemetry.execute(
  [:lockspire, :rs, :token_format],
  %{count: 1},
  %{
    token_format: :jwt,                       # or :"opaque-rejected" at site B (D-07)
    client_id: access_token.client_id,        # claims["client_id"] on success; nil on opaque
    audience: Map.get(access_token.claims || %{}, "aud"),  # claims["aud"]; nil on opaque
    binding_type: access_token.binding_type   # already populated on success struct; nil on opaque
  }
)
```

### Pattern 2: ExUnit telemetry assertion (attach_many → send to self → assert_received)
**What:** The repo's established idiom for testing `:telemetry` emission.
**When to use:** The telemetry test.
**Example:**
```elixir
# Source: test/lockspire/clients_test.exs:158-182 (verbatim idiom)
defp attach_events(pid) do
  handler_id = "rs-token-format-test-#{System.unique_integer([:positive])}"
  events = [[:lockspire, :rs, :token_format]]

  :ok =
    :telemetry.attach_many(handler_id, events, fn event, measurements, metadata, test_pid ->
      send(test_pid, {:telemetry_event, event, measurements, metadata})
    end, pid)

  {handler_id, events}
end

# in the test, after exercising VerifyToken.call/2:
assert_received {:telemetry_event, [:lockspire, :rs, :token_format], %{count: 1},
                 %{token_format: :jwt, client_id: cid, audience: aud, binding_type: bt}}
# on_exit / detach: :telemetry.detach(handler_id)
```
Note: `clients_test.exs` uses `assert_received` (synchronous emit) and 3-arg `{:telemetry_event, event, metadata}`. Use 4-arg so measurements can be asserted (D-04 requires `%{count: 1}`).

### Pattern 3: Mix doctor subtask (mirror RemoteJwks)
**What:** Self-contained `use Mix.Task` module with `@requirements ["app.config"]`, OptionParser, `print_result`-style helper, `Mix.shell().info/1` per line.
**When to use:** `Mix.Tasks.Lockspire.Doctor.TokenFormat`.
**Example:** Copy `lockspire.doctor.remote_jwks.ex` structure (lines 1-40, 58-72). Replace `--client`-required logic with: read `get_server_policy/0`, `list_clients/1`, compute per-client effective format, emit one line per client + a flag line for `nil` clients. **No `Mix.raise` on flagged clients** (D-14).

### Pattern 4: Contract-test drift fence
**What:** `refute`/`assert` clauses in `release_readiness_contract_test.exs` over repo source bytes.
**When to use:** All four new guard clauses (2 scaffold, 2 migration-pin).
**Example:**
```elixir
# no-format-prompt guard (D-02 #1) — over TASK + GENERATOR source, NOT the template:
@install_task_path Path.expand("../../lib/mix/tasks/lockspire.install.ex", __DIR__)
@install_generator_path Path.expand("../../lib/lockspire/generators/install.ex", __DIR__)

for path <- [@install_task_path, @install_generator_path] do
  src = File.read!(path)
  refute src =~ ~r/access_token_format|token[_ ]format|:jwt|:opaque/i,
         "install task/generator must never prompt for or branch on token format (SCAFFOLD-02): #{path}"
end
```

### Anti-Patterns to Avoid
- **Running the uncomment-ready guard against the NORMALIZED extraction output:** `extract_canonical_pipeline!/2` with `:elixir_in_commented_heredoc` **strips the `# ` prefix** (`normalize/2`, line 164). Asserting "every line is commented" against that output is a tautology that always passes. Assert against the **raw `File.read!` bytes** between the markers (see Pitfall 3).
- **Emitting through `Observability.emit/4`:** drops all-`nil` opaque metadata + floods audit log (Pitfall 2).
- **Calling `AccessTokenSigner.resolve_format/2` from the doctor:** it's `defp` — won't compile (Pitfall 1).
- **`Mix.raise` / non-zero exit on flagged clients:** breaks operator CI (D-14, explicit).
- **Refute-ing `:jwt`/`:opaque` against the install TEMPLATE:** the template legitimately contains `audience: "..."`, `enforce_audience: true` — the refute targets the **task + generator source only**, never the template.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Canonical-block extraction from install template | A new regex/parser | `extract_canonical_pipeline!/2` (def line 140) + `@install_template_router_path` (line 88) | Already battle-tested across 3 existing tests; handles CRLF, indent-stripping, marker validation. CONTEXT D-02 mandates reuse. |
| Effective-format precedence in doctor | A fresh `case client.access_token_format` ladder | Reproduce `AccessTokenSigner.resolve_format/2`'s exact three clauses (it's private — see Pitfall 1) | The diagnostic MUST report the same format the signer would issue. Diverging logic = a lying doctor. |
| Telemetry assertion plumbing | Custom test process / Agent | `:telemetry.attach_many/4` + `assert_received` | Repo idiom (`clients_test.exs:158-182`); zero new helpers. |
| Doctor task skeleton | Bespoke arg-parsing/output | Mirror `lockspire.doctor.remote_jwks.ex` | A complete worked subtask example already exists; symmetry is a locked decision (D-12). |
| Runtime opt-out mechanism | A new config key or setter | Document existing `ServerPolicy.put_access_token_format(:opaque)` | Already shipped (Phase 99 D-04). A `config/*.exs` key would be a silent no-op (D-09). |

**Key insight:** This phase's correctness depends on REUSING shipped primitives, not building new ones. Every new line of logic that re-derives something already-shipped (format precedence, extraction, opt-out) is a place the scaffold/diagnostic can drift from truth — which is the exact failure mode the phase exists to prevent.

## Runtime State Inventory

> Phase 102 is not a rename/refactor/migration-of-data phase. It is additive (new telemetry, new doc, new doctor task, new test guards) plus operator-facing migration *documentation* for the already-shipped issuance flip. No data migration is introduced by Phase 102 itself.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None introduced by Phase 102. The issuance flip's data semantics (clients with `access_token_format: nil` inheriting server `:jwt`) already shipped in Phase 99 (migration `99-01`). Phase 102 only *documents* and *diagnoses* this. | None — documentation + read-only diagnostic only. |
| Live service config | The runtime opt-out target `ServerPolicy.access_token_format` is durable runtime state on the singleton policy row (Phase 99 D-04), editable via `put_access_token_format/1`. Phase 102 documents it; does not change it. | None — the migration guide must describe (not mutate) this. |
| OS-registered state | None. | None — no OS registrations involved. |
| Secrets/env vars | None. The opt-out is explicitly NOT an env/config key (D-09). | None. |
| Build artifacts | None. No package rename, no compiled-artifact changes. | None. |

**Nothing found requiring data migration** — verified by reading the issuance/signer/server-policy modules; the `nil`→`:jwt` inheritance is a *read-time resolution* in `resolve_format/2`, not stored per-client, so no backfill exists or is needed.

## Common Pitfalls

### Pitfall 1 (LANDMINE-1): `resolve_format/2` is private — the doctor cannot call it
**What goes wrong:** D-13 says "reuse `AccessTokenSigner.resolve_format/2`." A plan that writes `AccessTokenSigner.resolve_format(client, policy)` in the doctor task will not compile — it is `defp` at `access_token_signer.ex:88-98`.
**Why it happens:** CONTEXT.md gathered the precedence intent correctly but did not record the visibility.
**How to avoid:** Two viable resolutions (planner picks; both honor D-13's intent of single-source-of-truth):
  1. **Reproduce the three clauses inline in the doctor task** (lowest blast radius), with a code comment pointing to `access_token_signer.ex:88-98` as the authority, and a contract-test assertion that ties them together if drift is a concern. The logic is tiny and pure: per-client `:jwt|:opaque` wins; `nil` + server policy → `server_fmt || :jwt`; `nil` + no policy → `:jwt`.
  2. **Promote `resolve_format/2` to a public `@spec`'d function** (e.g. keep the `defp` as a thin wrapper, or change `defp`→`def`) so both signer and doctor share one definition. This is the truest "reuse" but touches a shipped Phase-99 module — confirm with the user before widening a stable module's public surface. Given the project's least-surprise/minimal-breadth ethos, option 1 is the safer default; flag option 2 as the alternative.
**Warning signs:** compile error `resolve_format/2 is undefined or private`.

### Pitfall 2: `Observability.emit/4` would silently drop opaque-rejection metadata
**What goes wrong:** If telemetry went through `emit/4`, the opaque-rejection event (all `nil` values: `client_id: nil, audience: nil, binding_type: nil`) loses **every** metadata field — `Redaction.sanitize_value(nil, _surface)` returns `:drop` (`redaction.ex:195`). Operators would see an event with empty metadata.
**Why it happens:** `emit/4` calls `redact/1` → `Redaction.for_telemetry/1`, which reduces each field through `sanitize_value`, dropping `nil`s.
**How to avoid:** D-03's direct `:telemetry.execute/3` (no redaction). This is the verified, reinforced reason — document it in the plan so it isn't "optimized" back to `emit/4` later.
**Warning signs:** opaque-rejection telemetry test asserting `binding_type: nil` fails because the key is absent.

### Pitfall 3: Uncomment-ready guard must read RAW bytes, not normalized extraction
**What goes wrong:** `extract_canonical_pipeline!(path, :elixir_in_commented_heredoc)` strips the `# ` prefix in `normalize/2` (line 164). An assertion like "every body line starts with `# `" against that output always passes (the prefix is already gone) — the guard proves nothing.
**Why it happens:** The existing helper is built for hash-comparison across formats, so it deliberately normalizes away the comment prefix.
**How to avoid:** For D-02 #2, `File.read!` the template, `Regex.run` the BEGIN/END region from the RAW string, split lines, and assert every non-blank body line is prefixed `# ` (allowing leading whitespace before `#`). Reuse the *marker regex* from line 146 but operate on raw captured bytes, not the normalized result. You may still call `extract_canonical_pipeline!/2` additionally to assert the block stays byte-identical to the other RECIPE-01 sites (that's the existing test at line 745) — but the "still commented" property needs the raw read.
**Warning signs:** the guard passes even when you manually uncomment a line in the template (mutation test it).

### Pitfall 4: JWT-success emit must reflect "format decision reached," not "fully authorized"
**What goes wrong:** `do_verify_token/3` builds the success `%AccessToken{}` then pipes through `apply_restrictions/2` (line 136), which can set `.error` for an audience/scope failure. If you emit only when the final struct has no error, you under-count: a token that is structurally a valid `at+jwt` but fails the route's audience check is still a `:jwt`-format verification.
**Why it happens:** The success path and the restriction path share the same return struct; "JWT format confirmed" happens *before* audience/scope enforcement.
**How to avoid:** TELEMETRY-01 prose says "every successful verification" but D-06 reads intent as "every verification attempt that reaches a format decision." The cleanest emit point for site A is **after the `with` in `do_verify_token/3` confirms a verified JWT (claims in hand), regardless of subsequent restriction outcome** — i.e., emit when `verify_signature_and_claims` succeeds and you have `claims`, so `audience`/`client_id`/`binding_type` are all readable from claims. Confirm this framing with the planner; it is the only way `:jwt` count is consistent with the `:"opaque-rejected"` count (which fires at structural-format-decision time, before any restriction). Do NOT emit inside `apply_restrictions/2`. (This is a Claude's-discretion area per CONTEXT — exact emit point/helper shape — so the planner has latitude, but the count semantics must be coherent across both sites.)
**Warning signs:** telemetry shows fewer `:jwt` events than 200-OK requests, or an integration test where an audience-fail JWT produces no `:jwt` event.

### Pitfall 5: The doctor dispatcher fallback help must be updated
**What goes wrong:** Adding `run(["token_format" | rest])` to `lockspire.doctor.ex` without updating the `run(_args)` fallback's "Supported commands:" block (lines 18-21) leaves the help text claiming only `remote-jwks` exists.
**How to avoid:** Add the new command to the fallback help string. Consider a contract-test or doctor-test assertion that the help lists `token_format`.
**Warning signs:** `mix lockspire.doctor bogus` prints help that omits `token_format`.

### Pitfall 6: `list_clients/1` and `get_server_policy/0` return `{:ok, _}` tuples
**What goes wrong:** Treating `list_clients/1` as returning a bare list, or `get_server_policy/0` a bare struct, crashes.
**How to avoid:** Pattern-match `{:ok, clients}` / `{:ok, policy}` and handle `{:error, reason}` calmly (a diagnostic should report the error, not crash). `list_clients/1` is `clients.ex:82-85`; `get_server_policy/0` is `server_policy.ex:40-43`.

## Code Examples

### Reproduced format precedence for the doctor (Pitfall 1, option 1)
```elixir
# Source of truth: Lockspire.Protocol.AccessTokenSigner.resolve_format/2
# (access_token_signer.ex:88-98) — reproduced here because that fn is private.
# Keep these three clauses byte-equivalent to the signer's precedence.
defp effective_format(%Client{access_token_format: fmt}, _policy) when fmt in [:jwt, :opaque], do: fmt
defp effective_format(%Client{access_token_format: nil}, %ServerPolicy{access_token_format: server_fmt}),
  do: server_fmt || :jwt
defp effective_format(%Client{access_token_format: nil}, _policy), do: :jwt
```

### Reading the success-path telemetry metadata from claims (Pitfall 4)
```elixir
# In do_verify_token/3, once claims are verified (audience lives only in claims["aud"];
# the AccessToken struct has NO audience field — access_token.ex:6-15).
%{
  token_format: :jwt,
  client_id: Map.get(claims, "client_id"),
  audience: Map.get(claims, "aud"),
  binding_type: binding_type(claims)   # existing private helper, verify_token.ex:467
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Default access-token format opaque | Default `:jwt` (`ServerPolicy.access_token_format` default `:jwt`) | Phase 99 (v1.27) | The migration guide MUST explain this flip and name `nil`-format clients as inheritors. |
| Install template plain pipeline | Commented canonical `:lockspire_protected_api` block with absolute audience URI | Phases 97/101 | SCAFFOLD-01 already met; Phase 102 only fences it. |
| Server format as boot-time config | Server format as runtime-editable `ServerPolicy` row state | Phase 99 D-04 | Opt-out is a runtime call, NOT a config key (D-09). |

**Deprecated/outdated:** Nothing in this phase's scope is deprecated. Note the `.bak` test files (`dcr_telemetry_redaction_test.exs.bak`, etc.) are dormant — ignore them; they are not part of the suite.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reproducing the three `resolve_format` clauses inline in the doctor (Pitfall 1, option 1) is preferable to widening the signer's public API. | Common Pitfalls / Don't Hand-Roll | LOW — both options satisfy D-13. If the user prefers a shared public function, planner switches to option 2; either way the precedence stays single-sourced in intent. Flagged because changing a shipped module's surface is a user-confirmable decision. |
| A2 | The coherent JWT-success emit point is after `verify_signature_and_claims` succeeds (claims in hand), before/independent of restriction outcome (Pitfall 4). | Common Pitfalls | MEDIUM — if the user insists "successful verification" means "fully authorized incl. audience/scope," the `:jwt` count semantics change and the test assertions differ. CONTEXT D-06 already reinterprets the prose toward "format decision reached," supporting A2, but the exact emit point is Claude's discretion and should be confirmed in planning. |
| A3 | No external packages are needed; `:telemetry` is already resolved transitively. | Standard Stack | LOW — verified `observability.ex` already calls `:telemetry.execute/3`; if `:telemetry` were somehow not a direct dep, a one-line `mix.exs` addition would be needed, but the codebase already depends on it. |

## Open Questions

1. **Should `resolve_format/2` be promoted to public, or reproduced in the doctor?**
   - What we know: it is `defp` (verified); D-13 wants single-source precedence.
   - What's unclear: user's tolerance for widening a shipped Phase-99 module's public API vs. a small reproduced (and comment-anchored, optionally contract-tested) clause set in the doctor.
   - Recommendation: default to reproduction (option 1) for minimal blast radius; surface promotion (option 2) as the alternative in discuss/plan. (Tracked as A1.)

2. **Exact JWT-success emit point.**
   - What we know: must be coherent with the opaque-rejection (format-decision-time) emit; success struct passes through `apply_restrictions/2` which can set `.error`.
   - What's unclear: whether to emit before or after restriction enforcement.
   - Recommendation: emit at format-confirmation time (claims verified), before restriction outcome, so `:jwt` and `:"opaque-rejected"` counts are symmetric. Confirm in planning. (Tracked as A2.)

## Environment Availability

> Phase 102 has no new external runtime dependencies. The doctor task requires the host app's config/repo to be loadable (`@requirements ["app.config"]`), which is the existing precondition for `RemoteJwks`. No new tools, services, or runtimes are introduced.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix toolchain | All deliverables | ✓ (repo builds) | project's pinned Elixir | — |
| `:telemetry` | TELEMETRY-01 | ✓ (transitive, used in `observability.ex`) | resolved in `mix.lock` | — |
| App config + repo at runtime | doctor task (`@requirements ["app.config"]`) | ✓ (same as RemoteJwks) | — | doctor reports `{:error, _}` calmly rather than crashing |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

> This is the heart of Phase 102 — nearly every deliverable IS a test or a pinned contract. Nyquist validation is enabled (no `workflow.nyquist_validation: false` found). Each requirement is mapped to: observable behavior → minimal sufficient assertion → location.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir), `use ExUnit.Case, async: true` (contract test uses `async: true`) |
| Config file | none custom — standard `test/test_helper.exs` + `mix test` |
| Quick run command | `mix test test/lockspire/release_readiness_contract_test.exs` (scaffold + migration pins) |
| Full suite command | `mix ci` (the maintained contributor lane — see `release_readiness_contract_test.exs:219`) or `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior to prove | Test type | Minimal sufficient assertion | Location (file / constant) | Exists? |
|--------|-------------------|-----------|------------------------------|----------------------------|---------|
| SCAFFOLD-02 | Install never prompts/branches on token format | contract refute | `refute source =~ ~r/access_token_format\|token[_ ]format\|:jwt\|:opaque/i` over **task + generator source** (NOT template) | `release_readiness_contract_test.exs` (new clause) using `@install_task_path` + new `@install_generator_path` constant | ❌ Wave 0 |
| SCAFFOLD-01 | Canonical block stays fully commented + uncomment-ready | contract assert (RAW bytes) | Read template raw, capture BEGIN/END region via marker regex (line 146 pattern), assert every non-blank body line matches `~r/^\s*#/`; ALSO existing byte-identical hash test (line 745) keeps it synced to other 3 sites | `release_readiness_contract_test.exs` (new clause) + reuse `@install_template_router_path` (line 88) | ❌ Wave 0 |
| TELEMETRY-01 (JWT success) | `[:lockspire,:rs,:token_format]` fires with `%{count:1}` + `{token_format: :jwt, client_id, audience, binding_type}` on a verified `at+jwt` | unit (plug) | `attach_many` → exercise `VerifyToken.call/2` with a valid signed `at+jwt` (mint via `AccessTokenSigner.issue/3` like `phase100_sender_constraint_e2e_test.exs`, or a fixture) → `assert_received {:telemetry_event, [:lockspire,:rs,:token_format], %{count:1}, %{token_format: :jwt, ...}}` | new `test/lockspire/plug/verify_token_telemetry_test.exs` | ❌ Wave 0 |
| TELEMETRY-01 (opaque reject) | Same event fires with `{token_format: :"opaque-rejected", client_id: nil, audience: nil, binding_type: nil}` on an opaque token | unit (plug) | `attach_many` → `VerifyToken.call/2` with an opaque (non-3-segment) token → `assert_received {:telemetry_event, _, %{count:1}, %{token_format: :"opaque-rejected", binding_type: nil}}` | same telemetry test file | ❌ Wave 0 |
| TELEMETRY-01 (literal atom) | Value is the hyphenated atom, not `:opaque_rejected` | unit (plug) | pattern-match on `:"opaque-rejected"` literally in the assertion above (a wrong spelling fails the match) | same file | ❌ Wave 0 |
| MIGRATE-01 | Guide states honest runtime opt-out + `nil`-inherit naming | contract pin | `doc = File.read!(@upgrading_v1_27_path)`; `assert doc =~ "put_access_token_format(:opaque)"`; `assert doc =~ ~r/access_token_format.{0,40}nil/`; `refute doc =~ ~r/config :lockspire.*access_token_format/` (no phantom config key, D-09) | `release_readiness_contract_test.exs` (new clause) + new `@upgrading_v1_27_path` constant | ❌ Wave 0 |
| MIGRATE-01 | Guide explains the opaque→:jwt default flip | contract pin | `assert doc =~ "opaque"` and `assert doc =~ ":jwt"` and a flip-narrative substring (e.g. "default" + "changes"/"flips") | same clause | ❌ Wave 0 |
| MIGRATE-02 | `mix lockspire.doctor token_format` lists per-client format + flags `nil` clients, read-only | unit (mix task) | Seed a `nil`-format client + an explicit-`:opaque` client; `capture_io`/`Mix.shell(Mix.Shell.Process)` run the task; assert output names both clients with their effective formats; assert the `nil` client is flagged "changed"; assert the `:opaque` client is NOT flagged; assert no exception/raise | new `test/mix/tasks/lockspire_doctor_token_format_test.exs` (mirror `lockspire_doctor_remote_jwks_test.exs`) | ❌ Wave 0 |
| MIGRATE-02 | doctor effective format == signer's resolution | unit | For a `nil` client with server default `:jwt`, doctor reports `:jwt`; flip server to `:opaque` via `put_access_token_format(:opaque)`, re-run, doctor reports `:opaque` for the same client — proving precedence parity | same doctor test | ❌ Wave 0 |
| (dispatcher) | `mix lockspire.doctor token_format` is routed, and help lists it | unit | New `run(["token_format"\|rest])` clause + fallback-help update; assert `Mix.Tasks.Lockspire.Doctor.run(["bogus"])` help/usage references `token_format` | doctor test | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/plug/verify_token_telemetry_test.exs test/mix/tasks/lockspire_doctor_token_format_test.exs` (the three files this phase touches/adds).
- **Per wave merge:** `mix test` (full suite green — verify no telemetry-attach handler leaks across async tests; always `detach` in `on_exit`).
- **Phase gate:** `mix ci` green before `/gsd-verify-work` (this is the repo's canonical full gate; the contract test runs inside it).

### Wave 0 Gaps
- [ ] `test/lockspire/plug/verify_token_telemetry_test.exs` — covers TELEMETRY-01 (both sites + literal atom). Decide: mint a real `at+jwt` via `AccessTokenSigner.issue/3` (precedent: `test/integration/phase100_sender_constraint_e2e_test.exs`) vs. a static fixture. Real-mint is more faithful and matches existing e2e patterns.
- [ ] `test/mix/tasks/lockspire_doctor_token_format_test.exs` — covers MIGRATE-02. Mirror `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs`; use `Mix.Shell.Process` to capture `Mix.shell().info` lines.
- [ ] New contract-test constants in `release_readiness_contract_test.exs`: `@install_generator_path`, `@upgrading_v1_27_path` (and confirm `@install_task_path`/`@install_template_router_path` exist — the latter does at line 88).
- [ ] No framework install needed — ExUnit + Mix.Shell.Process + `:telemetry` test API all present.
- [ ] Shared fixtures: a signed-`at+jwt` builder for the telemetry test (reuse the signer + active-key setup from existing plug/e2e tests; check `test/support` for an existing signing-key fixture before adding one).

## Security Domain

> `security_enforcement` not set to `false`, so included. Phase 102 adds NO runtime authorization/verification behavior change (all verifier/signer/issuance behavior shipped in Phases 98-100). The security-relevant surfaces are narrow.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth logic changed; verifier behavior is frozen for this phase. |
| V3 Session Management | no | N/A. |
| V4 Access Control | no | The doctor task is read-only diagnostic; no authz decision. The plug's access control is unchanged. |
| V5 Input Validation | minimal | Doctor uses `OptionParser` strict switches (mirror RemoteJwks). No untrusted input beyond CLI args. |
| V6 Cryptography | no (frozen) | Signing/verification crypto is unchanged. Telemetry must NOT log token bytes or key material. |
| V7 Logging | yes | Telemetry metadata must carry `client_id`/`audience`/`binding_type` only — **never the raw token, claims blob, or `cnf` material.** D-03's direct-execute path deliberately skips redaction, so the emit site itself must be the redaction discipline: emit exactly the four documented fields, nothing more. |

### Known Threat Patterns for {Elixir/Phoenix telemetry + Mix CLI}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive-data leak via telemetry metadata | Information Disclosure | Emit only `token_format`, `client_id`, `audience`, `binding_type`. Do not include `token`, `claims`, `cnf`, or `jti`. (Reinforces why the four metadata keys are exhaustive.) |
| Doctor task mutating state / breaking operator CI | Tampering / Denial of Service | D-14: read-only, no `Mix.raise`, no non-zero exit. Enforced by the doctor test asserting no raise on flagged clients. |
| Audit-log flooding via per-request emit | Denial of Service (log volume) | D-03: bypass `Observability.emit/4` so no `[:lockspire, :audit, :rs, :token_format]` copy is written per protected request. |
| Migration guide pointing operators at a no-op config key | Misconfiguration / false security | D-09 + contract-test `refute` on `config :lockspire ... access_token_format` keeps the guide pointed at the real runtime setter. |

## Sources

### Primary (HIGH confidence)
- Codebase (read this session): `lib/lockspire/plug/verify_token.ex`, `lib/lockspire/access_token.ex`, `lib/lockspire/observability.ex`, `lib/lockspire/redaction.ex`, `lib/lockspire/protocol/access_token_signer.ex`, `lib/lockspire/admin/server_policy.ex`, `lib/lockspire/domain/server_policy.ex`, `lib/lockspire/admin/clients.ex`, `lib/mix/tasks/lockspire.doctor.ex`, `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`, `lib/mix/tasks/lockspire.install.ex`, `lib/lockspire/generators/install.ex`, `priv/templates/lockspire.install/router.ex`, `test/lockspire/release_readiness_contract_test.exs`, `test/lockspire/clients_test.exs`.
- `.planning/phases/102-.../102-CONTEXT.md` — D-01..D-14 (locked decisions).
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`.

### Secondary (MEDIUM confidence)
- RFC 9068 (`at+jwt`), RFC 8707 (`resource`→`aud`) — context for the `audience` telemetry metadata value (referenced, not re-derived).

### Tertiary (LOW confidence)
- None. No WebSearch was needed; the phase is fully grounded in the existing codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; `:telemetry`/ExUnit/Mix all verified in-repo.
- Architecture / call sites: HIGH — every cited site read directly; drift corrections documented.
- Pitfalls: HIGH — Pitfalls 1 (private `resolve_format`), 2 (`nil` redaction drop), 3 (normalized-vs-raw) verified against source.
- Validation architecture: HIGH — telemetry idiom and contract-test helper patterns confirmed from existing tests.

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable — internal codebase; only invalidated by edits to the cited files before planning completes).
