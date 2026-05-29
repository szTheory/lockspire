# Phase 102: Generated-Host Scaffolding + Telemetry + Migration - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 8 (3 source-modified, 3 source/doc-new, 2 test-new + 1 test-modified)
**Analogs found:** 8 / 8 (every deliverable has a verified in-repo analog)

> All three RESEARCH.md drift corrections were re-verified against source this session and are baked into the excerpts below:
> 1. `AccessToken` struct is `Lockspire.AccessToken` at `lib/lockspire/access_token.ex` (NOT `lib/lockspire/plug/access_token.ex`).
> 2. The reusable canonical-block helper is `extract_canonical_pipeline!/2` **defined at line 140**; lines 745-759 are a *use site* (the byte-identity test). For the uncomment-ready guard, the normalizer at line 164 **strips `# `**, so the guard must read RAW bytes.
> 3. `AccessTokenSigner.resolve_format/2` is **`defp` (private)** — the doctor task cannot call it; reproduce its three clauses.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/plug/verify_token.ex` (MODIFY) | plug (middleware) | event-driven (telemetry emit) | `lib/lockspire/observability.ex:31` (`:telemetry.execute/3` call) | role-match (emit idiom) |
| `lib/mix/tasks/lockspire.doctor.token_format.ex` (NEW) | mix task (CLI) | request-response (read-only query) | `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | exact (shape-for-shape) |
| `lib/mix/tasks/lockspire.doctor.ex` (MODIFY) | mix task (dispatcher) | request-response | existing `run(["remote-jwks" \| rest])` clause in same file (lines 11-13) | exact (same-file symmetry) |
| `docs/upgrading/v1.27.md` (NEW) | docs | n/a (operator prose) | none in `docs/upgrading/` (net-new dir); pinned like contract-test doc assertions | no analog (see below) |
| `test/lockspire/release_readiness_contract_test.exs` (MODIFY) | test (contract guard) | transform (source-byte refute/assert) | `extract_canonical_pipeline!/2` (line 140) + byte-identity test (line 745) in same file | exact (same-file helper) |
| `test/lockspire/plug/verify_token_telemetry_test.exs` (NEW) | test (unit) | event-driven (telemetry assertion) | `test/lockspire/clients_test.exs:158-182` (`attach_many` → `send` self → `assert_received`) | exact (telemetry idiom) |
| `test/mix/tasks/lockspire_doctor_token_format_test.exs` (NEW) | test (unit, mix task) | request-response | `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs` | exact (subtask test) |

## Pattern Assignments

### `lib/lockspire/plug/verify_token.ex` (plug, event-driven) — MODIFY

**Analog:** `lib/lockspire/observability.ex:31` (the repo's `:telemetry.execute/3` call site) — but emit DIRECTLY per D-03, NOT through `Observability.emit/4`.

**Verified call sites in this file (source read this session):**
- `call/2` — lines 70-81 (extract → `verify_token/3` → assign).
- Opaque-rejection branch in `verify_token/3` — lines **105-122**; the rejection `%AccessToken{}` is built at **lines 114-118**. **EMIT SITE B** is here (claims are unavailable, so all metadata except `token_format` is `nil`).
- JWT-success path in `do_verify_token/3` — the `with` confirms claims, then builds `%AccessToken{}` at **lines 128-135**, then `|> apply_restrictions(opts)` at line 136. **EMIT SITE A** must fire at format-decision time (claims in hand), per Pitfall 4 — emit before/independent of `apply_restrictions/2` so the `:jwt` count is coherent with the `:"opaque-rejected"` count.
- `binding_type/1` helper — lines **467-479** (`binding_type(%{"cnf" => cnf})` ... `binding_type(_claims), do: nil`). Already used on the success struct at line 133. Reuse this helper for SITE A metadata.

**Imports/alias pattern** (lines 12-17, verified):
```elixir
import Plug.Conn
require Logger

alias Lockspire.AccessToken
alias Lockspire.Config
alias Lockspire.KeyCache
```
No `:telemetry` alias needed — `:telemetry.execute/3` is an Erlang call.

**Emit pattern — SITE A (JWT-success)** — read metadata from `claims`, NOT the struct (the struct has no `audience` field; see access_token.ex below):
```elixir
# In do_verify_token/3, after verify_signature_and_claims succeeds (claims in hand),
# emit at format-decision time — independent of apply_restrictions/2 outcome (Pitfall 4).
:telemetry.execute(
  [:lockspire, :rs, :token_format],
  %{count: 1},
  %{
    token_format: :jwt,
    client_id: Map.get(claims, "client_id"),
    audience: Map.get(claims, "aud"),
    binding_type: binding_type(claims)   # existing private helper, line 467
  }
)
```

**Emit pattern — SITE B (opaque-rejection)** — in the `if opaque_shape?(token)` branch (lines 105-122), opaque tokens carry no claims, so every metadata field except the literal hyphenated atom is `nil`:
```elixir
:telemetry.execute(
  [:lockspire, :rs, :token_format],
  %{count: 1},
  %{
    token_format: :"opaque-rejected",   # D-07: literal hyphenated atom, external contract
    client_id: nil,
    audience: nil,
    binding_type: nil
  }
)
```

**Reference excerpt from analog `observability.ex` (the repo's only `:telemetry.execute/3` precedent — DO NOT route through `emit/4`):**
```elixir
# observability.ex:31 — confirmed numeric-measurement convention (count: 1).
# emit/4 ALSO emits [:lockspire, :audit, entity, action] (audit-log flooding) AND runs
# Redaction.for_telemetry which DROPS all-nil metadata (redaction.ex:195 -> :drop).
# D-03 mandates the direct call below precisely to avoid both behaviors.
:telemetry.execute([:lockspire, entity, action], measurements, metadata)
```

---

### `lib/lockspire/access_token.ex` (struct — READ-ONLY reference for telemetry metadata)

**DRIFT-corrected path:** struct is `Lockspire.AccessToken` at `lib/lockspire/access_token.ex` (defstruct line 6, `@type t` line 17). It is `alias`ed in `verify_token.ex:15`.

**Field set (verified):** `:token, :claims, :client_id, :authorization_scheme, :binding_type, :binding_requirements, :error, binding_verified: false`. **No `audience` field** — that is why SITE A reads `Map.get(claims, "aud")`, not the struct.

---

### `lib/mix/tasks/lockspire.doctor.token_format.ex` (mix task, request-response) — NEW

**Analog:** `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` (copy shape-for-shape).

**Module header / requirements pattern** (analog lines 1-17):
```elixir
defmodule Mix.Tasks.Lockspire.Doctor.TokenFormat do
  @moduledoc """
  Diagnose effective access-token format per client (read-only).
  """

  use Mix.Task

  alias Lockspire.Admin.Clients
  alias Lockspire.Admin.ServerPolicy

  @shortdoc "Reports each client's effective access-token format and flags nil-format clients"
  @requirements ["app.config"]

  @switches [
    help: :boolean
  ]
```

**`run/1` + OptionParser pattern** (analog lines 19-40) — mirror, but NO `--client` requirement (this task enumerates ALL clients):
```elixir
@impl Mix.Task
def run(args) do
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

  if invalid != [] do
    Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
  end

  if Keyword.get(opts, :help, false) do
    Mix.shell().info(help())
  else
    # NO Mix.raise on flagged clients (D-14). Read-only, diagnostic-only.
    report()
  end
end
```

**Read-live-state pattern** — both admin reads return `{:ok, _}` tuples (Pitfall 6):
```elixir
# Clients.list_clients/1 -> {:ok, [Client.t()]} | {:error, term()}  (clients.ex:82-85)
# ServerPolicy.get_server_policy/0 -> {:ok, ServerPolicy.t()} | {:error, term()}  (server_policy.ex:40-43)
defp report do
  with {:ok, policy} <- ServerPolicy.get_server_policy(),
       {:ok, clients} <- Clients.list_clients() do
    # per-client lines + nil-format flag
  else
    {:error, reason} ->
      Mix.shell().info("Could not inspect token formats: #{inspect(reason)}")  # report calmly, do NOT crash
  end
end
```

**Effective-format precedence — REPRODUCE `resolve_format/2` (Pitfall 1 / LANDMINE-1).** The signer's function is `defp` at `access_token_signer.ex:88-98` (verified `defp`, three clauses below). Copy the three clauses with a comment pointing at the authority; do NOT call it directly (won't compile):
```elixir
# Source of truth: Lockspire.Protocol.AccessTokenSigner.resolve_format/2
# (access_token_signer.ex:88-98) — reproduced because that fn is private (defp).
# Keep byte-equivalent to the signer's precedence.
defp effective_format(%Client{access_token_format: fmt}, _policy) when fmt in [:jwt, :opaque], do: fmt
defp effective_format(%Client{access_token_format: nil}, %ServerPolicy{access_token_format: server_fmt}),
  do: server_fmt || :jwt
defp effective_format(%Client{access_token_format: nil}, _policy), do: :jwt
```
> NOTE: the structs here are `Lockspire.Domain.Client` and `Lockspire.Domain.ServerPolicy` (the domain structs the signer matches on), not the `Admin` modules. Alias accordingly. Option 2 (promote `resolve_format/2` to `def`) touches a shipped Phase-99 module — flag for user confirmation before widening; default to reproduction.

**Output pattern** (analog `print_result/1`, lines 58-72) — `Mix.shell().info/1` per line; flag every `nil`-format client (changed semantics → now inherits `:jwt`):
```elixir
# Verified analog idiom: build a list of lines, then Enum.each(lines, &Mix.shell().info/1).
# Per-client line + a flag line for access_token_format: nil clients. No Mix.raise (D-14).
```

**Authoritative `resolve_format/2` excerpt (verified `defp`):**
```elixir
# access_token_signer.ex:88-98
@spec resolve_format(Client.t(), ServerPolicy.t() | nil) :: :jwt | :opaque
defp resolve_format(%Client{access_token_format: fmt}, _server_policy)
     when fmt in [:jwt, :opaque],
     do: fmt
defp resolve_format(%Client{access_token_format: nil}, %ServerPolicy{access_token_format: server_fmt}),
     do: server_fmt || :jwt
defp resolve_format(%Client{access_token_format: nil}, _server_policy), do: :jwt
```

---

### `lib/mix/tasks/lockspire.doctor.ex` (dispatcher) — MODIFY

**Analog:** the existing `run(["remote-jwks" | rest])` clause in the same file (lines 11-13). Add a symmetric clause + update the fallback help (Pitfall 5 — otherwise the help lies).

**Existing dispatcher (verified, full file is 23 lines):**
```elixir
@impl Mix.Task
def run(["remote-jwks" | rest]) do
  Mix.Task.run("lockspire.doctor.remote_jwks", rest)
end

def run(_args) do
  Mix.raise("""
  Unknown doctor command.

  Supported commands:
    mix lockspire.doctor remote-jwks --client CLIENT_ID
  """)
end
```

**Change to make** — add a `token_format` clause BEFORE the fallback, and add the command to the fallback help string:
```elixir
def run(["token_format" | rest]) do
  Mix.Task.run("lockspire.doctor.token_format", rest)
end

# ... and inside run(_args)'s "Supported commands:" block, add:
#   mix lockspire.doctor token_format
```

---

### `docs/upgrading/v1.27.md` (docs) — NEW — NO in-repo analog

Net-new directory `docs/upgrading/`. No precedent file to mirror prose against. Its TRUTH is fenced by contract-test assertions (see the contract-test section). Required content per D-09/D-10:
- The default issuance flip: opaque → `:jwt`.
- The honest runtime opt-out: `Lockspire.Admin.ServerPolicy.put_access_token_format(:opaque)` (one call, `server_policy.ex:65-73`). State explicitly there is **no `config :lockspire` key** (would be a silent no-op).
- Affected clients = "every client whose `access_token_format` is `nil`" (these inherit the new server default `:jwt`). Clients with an explicit `:opaque` override are NOT affected and must not be named as changed.
- Cross-reference precedence: per-client `:jwt|:opaque` wins → `nil` inherits `ServerPolicy.access_token_format` (default `:jwt`, `domain/server_policy.ex:38`).

**Contract-pin strings the doc MUST contain (so the pins below pass):** `put_access_token_format(:opaque)`; `access_token_format` near `nil`; `:jwt`; `opaque`; a flip narrative. The doc must NOT contain `config :lockspire ... access_token_format` (refute).

---

### `test/lockspire/release_readiness_contract_test.exs` (contract guard) — MODIFY (4 new clauses)

**Analog:** same-file helpers. Reuse `extract_canonical_pipeline!/2` (def line 140) and `@install_template_router_path` (def lines 88-91). Add new constants `@install_task_path`, `@install_generator_path`, `@upgrading_v1_27_path` (mirror the `Path.expand("../../...", __DIR__)` constant idiom at lines 80-92).

**Constant idiom (verified, lines 80-92):**
```elixir
@install_template_router_path Path.expand(
                                "../../priv/templates/lockspire.install/router.ex",
                                __DIR__
                              )
# Add (Wave 0):
# @install_task_path      Path.expand("../../lib/mix/tasks/lockspire.install.ex", __DIR__)
# @install_generator_path Path.expand("../../lib/lockspire/generators/install.ex", __DIR__)
# @upgrading_v1_27_path   Path.expand("../../docs/upgrading/v1.27.md", __DIR__)
```

**Guard 1 — no-format-prompt refute (D-02 #1, SCAFFOLD-02)** — over TASK + GENERATOR source only, NEVER the template (the template legitimately contains `audience:`/`enforce_audience:`):
```elixir
for path <- [@install_task_path, @install_generator_path] do
  src = File.read!(path)
  refute src =~ ~r/access_token_format|token[_ ]format|:jwt|:opaque/i,
         "install task/generator must never prompt for or branch on token format (SCAFFOLD-02): #{path}"
end
```

**Guard 2 — uncomment-ready RAW-bytes assert (D-02 #2, SCAFFOLD-01).** CRITICAL (Pitfall 3 / anti-pattern): `extract_canonical_pipeline!/2` with `:elixir_in_commented_heredoc` runs `normalize/2` which **strips the `# ` prefix at line 164** — asserting "every line commented" against that output is a tautology. Read RAW bytes and capture the BEGIN/END region with the marker regex (the helper's regex is at line 146), then assert each non-blank body line is commented:
```elixir
# Verified marker regex (line 146):
#   ~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms
raw = File.read!(@install_template_router_path)
[body] =
  Regex.run(
    ~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms,
    raw,
    capture: :all_but_first
  )

for line <- String.split(body, "\n"), String.trim(line) != "" do
  assert line =~ ~r/^\s*#/, "install-template canonical block must stay fully commented (SCAFFOLD-01)"
end
```
Existing byte-identity test (line 745, verified) already keeps the block synced across the four RECIPE-01 sites — leave it; it complements (does not replace) the raw-bytes guard.

**Guard 3 + 4 — migration-guide pins (D-11, MIGRATE-01)** — `File.read!(@upgrading_v1_27_path)` then assert honest opt-out + `nil`-inherit naming + flip narrative, and refute the phantom config key:
```elixir
doc = File.read!(@upgrading_v1_27_path)
assert doc =~ "put_access_token_format(:opaque)"        # honest runtime opt-out (D-09)
assert doc =~ ~r/access_token_format.{0,40}nil/         # nil-inherit affected-client naming (D-10)
assert doc =~ "opaque" and doc =~ ":jwt"                # the flip
refute doc =~ ~r/config :lockspire.*access_token_format/  # no phantom config key (D-09)
```

---

### `test/lockspire/plug/verify_token_telemetry_test.exs` (unit, event-driven) — NEW

**Analog:** `test/lockspire/clients_test.exs:158-182` (the repo's telemetry idiom). Use the 4-arg form so `%{count: 1}` is assertable (the analog uses 3-arg, dropping measurements — D-04 needs measurements).

**attach/detach idiom (verified, lines 158-182):**
```elixir
defp attach_events(pid) do
  handler_id = "rs-token-format-test-#{System.unique_integer([:positive])}"
  events = [[:lockspire, :rs, :token_format]]

  :ok =
    :telemetry.attach_many(handler_id, events, fn event, measurements, metadata, test_pid ->
      send(test_pid, {:telemetry_event, event, measurements, metadata})  # 4-arg (D-04)
    end, pid)

  {handler_id, events}
end

defp detach_events({handler_id, _events}), do: :telemetry.detach(handler_id)
# Always detach in on_exit to avoid handler leaks across async tests (per Sampling Rate notes).
```

**Assertions (both sites + literal atom):**
```elixir
# JWT-success: exercise VerifyToken.call/2 with a valid signed at+jwt
# (mint via AccessTokenSigner.issue/3 — precedent test/integration/phase100_sender_constraint_e2e_test.exs)
assert_received {:telemetry_event, [:lockspire, :rs, :token_format], %{count: 1},
                 %{token_format: :jwt, client_id: _cid, audience: _aud, binding_type: _bt}}

# Opaque-rejection: exercise VerifyToken.call/2 with an opaque (non-3-segment) token
assert_received {:telemetry_event, [:lockspire, :rs, :token_format], %{count: 1},
                 %{token_format: :"opaque-rejected", client_id: nil, audience: nil, binding_type: nil}}
```
The literal-atom requirement (D-07) is covered for free: a wrong spelling (`:opaque_rejected`) fails the pattern match above.

---

### `test/mix/tasks/lockspire_doctor_token_format_test.exs` (unit, mix task) — NEW

**Analog:** `test/mix/tasks/lockspire_doctor_remote_jwks_test.exs` (copy structure verbatim).

**Setup pattern (verified, analog lines 11-44)** — TestRepo + sandbox + `Mix.Task.reenable`:
```elixir
use ExUnit.Case, async: false
import ExUnit.CaptureIO

setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  start_supervised!(Lockspire.TestRepo)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
  :ok
end

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  Mix.Task.reenable("lockspire.doctor")
  Mix.Task.reenable("lockspire.doctor.token_format")
  # seed: one client with access_token_format: nil, one with explicit :opaque
  :ok
end
```

**capture_io + dispatcher assertions (analog lines 51-122):**
```elixir
output = capture_io(fn -> Mix.Task.run("lockspire.doctor", ["token_format"]) end)
# assert nil client named with effective :jwt and flagged "changed"
# assert :opaque-override client named and NOT flagged
# assert no raise (D-14)

# precedence parity: flip server default via ServerPolicy.put_access_token_format(:opaque),
# re-run, assert the nil client now reports :opaque (proves effective_format == signer resolution)

# dispatcher + help (Pitfall 5):
help = capture_io(fn -> Mix.Task.run("lockspire.doctor", ["token_format", "--help"]) end)
assert help =~ "mix lockspire.doctor token_format"
```

---

## Shared Patterns

### Telemetry emission (direct execute, NO Observability.emit/4)
**Source:** `lib/lockspire/observability.ex:31` (the only `:telemetry.execute/3` precedent).
**Apply to:** both emit sites in `verify_token.ex`.
**Why direct:** `emit/4` (lines 25-44) double-emits a `[:lockspire, :audit, ...]` copy (per-request audit flooding) AND runs `Redaction.for_telemetry`, where `Redaction.sanitize_value(nil, _)` returns `:drop` (`redaction.ex:195`) — it would silently strip ALL opaque-rejection metadata (every field `nil`). Direct execute is mandatory, not preferred.
```elixir
:telemetry.execute([:lockspire, :rs, :token_format], %{count: 1}, %{token_format: ..., client_id: ..., audience: ..., binding_type: ...})
```

### Telemetry assertion
**Source:** `test/lockspire/clients_test.exs:158-182`.
**Apply to:** the telemetry test. `attach_many/4` → `send(test_pid, {:telemetry_event, ...})` → `assert_received` → `detach` in `on_exit`. Use 4-arg tuple (include measurements) so `%{count: 1}` is asserted.

### Mix doctor subtask skeleton
**Source:** `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`.
**Apply to:** the new `TokenFormat` subtask. `use Mix.Task` + `@requirements ["app.config"]` + `@switches` + `OptionParser.parse(args, strict: @switches)` + invalid-opts `Mix.raise` + `--help` branch + build line list → `Enum.each(&Mix.shell().info/1)`. Differences: no required `--client`; enumerate all clients; NO `Mix.raise` on flagged clients (D-14).

### Contract-test drift fence
**Source:** `release_readiness_contract_test.exs` — constant idiom (lines 80-92), `extract_canonical_pipeline!/2` (line 140), marker regex (line 146), byte-identity test (line 745).
**Apply to:** all 4 new guard clauses. Reuse `@install_template_router_path`; add `@install_task_path`, `@install_generator_path`, `@upgrading_v1_27_path`. Uncomment-ready guard MUST use RAW bytes (the normalizer strips `# ` at line 164).

### `{:ok, _}`-tuple admin reads
**Source:** `clients.ex:82-85` (`list_clients/1`), `server_policy.ex:40-43` (`get_server_policy/0`).
**Apply to:** the doctor task + its test. Pattern-match `{:ok, _}`; handle `{:error, reason}` calmly (report, do not crash).

### Format-precedence single source of truth
**Source:** `access_token_signer.ex:88-98` (`resolve_format/2`, `defp`).
**Apply to:** doctor task (reproduce the three clauses, comment-anchored) AND migration guide (cross-reference the precedence). The diagnostic's `effective_format/2` MUST stay byte-equivalent to these clauses or the doctor lies.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `docs/upgrading/v1.27.md` | docs | n/a | `docs/upgrading/` is a net-new directory (D-08) — no in-directory precedent. Prose is Claude's discretion; its truth is fenced by the contract-test pins (Guards 3+4) and the required-string list above. |

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/lockspire/plug/`, `lib/lockspire/protocol/`, `lib/lockspire/admin/`, `lib/lockspire/`, `test/lockspire/`, `test/mix/tasks/`, `priv/templates/lockspire.install/`, `docs/upgrading/`.
**Files scanned/read this session:** `lockspire.doctor.remote_jwks.ex`, `lockspire.doctor.ex`, `verify_token.ex` (1-145), `release_readiness_contract_test.exs` (80-168, 744-768), `clients_test.exs` (155-183), `access_token_signer.ex` (80-104), `admin/clients.ex` (82-86), `admin/server_policy.ex` (40-74), `lockspire_doctor_remote_jwks_test.exs`, plus grep verification of struct/helper locations.
**Drift corrections verified against source:** all 3 (AccessToken path, helper-def vs use-site line, `resolve_format/2` is `defp`).
**Pattern extraction date:** 2026-05-29
