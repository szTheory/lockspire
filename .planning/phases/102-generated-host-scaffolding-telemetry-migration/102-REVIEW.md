---
phase: 102-generated-host-scaffolding-telemetry-migration
reviewed: 2026-05-29T10:59:48Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - docs/upgrading/v1.27.md
  - lib/lockspire/plug/verify_token.ex
  - lib/mix/tasks/lockspire.doctor.ex
  - lib/mix/tasks/lockspire.doctor.token_format.ex
  - test/lockspire/plug/verify_token_telemetry_test.exs
  - test/lockspire/release_readiness_contract_test.exs
  - test/mix/tasks/lockspire_doctor_token_format_test.exs
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 102: Code Review Report

**Reviewed:** 2026-05-29T10:59:48Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Reviewed the Phase 102 telemetry instrumentation (`[:lockspire, :rs, :token_format]`),
the read-only `mix lockspire.doctor token_format` subtask, the v1.27 migration guide,
and the contract-test regression guards. No correctness or security blockers were
found. The four phase-critical constraints all hold:

- **(a) observe-only telemetry:** Both emit sites in `verify_token.ex` are pure
  side-effecting `:telemetry.execute/3` calls that do not participate in control
  flow, do not bind the verifier's return value, and cannot swallow errors. A
  subscriber handler that raises is detached by `:telemetry` rather than propagated
  into the verifier. Verifier behavior is unchanged.
- **(b) opaque-rejection metadata:** SITE B emits the literal hyphenated atom
  `:"opaque-rejected"` with `client_id`/`audience`/`binding_type` all `nil`, exactly
  as specified. The direct-execute path correctly bypasses
  `Lockspire.Observability.emit/4` (avoiding the audit double-emit and the
  `nil -> :drop` redaction that would erase the all-nil metadata).
- **(c) doctor read-only + byte-equivalent precedence:** The task never mutates,
  never `Mix.raise`s on a flagged client, and never exits non-zero. The inline
  `effective_format/2` (token_format.ex:104-113) is byte-equivalent to the
  authoritative private `resolve_format/2`
  (access_token_signer.ex:88-98) — identical clause order, guards, and
  `server_fmt || :jwt` fallback; the only difference is the local struct alias name
  (`ServerPolicyStruct`). No divergence.
- **(d) info disclosure:** `client_id`/`audience` in telemetry metadata is consistent
  with the existing internal observability surface and stays within the documented
  four-key allowlist (never `token`/`claims`/`cnf`/`jti`). Acceptable.

The findings below are quality/robustness concerns, not behavior bugs.

## Warnings

### WR-01: SITE A telemetry never fires for JWT-shaped tokens that fail verification — asymmetric counts undocumented for the failure case

**File:** `lib/lockspire/plug/verify_token.ex:137-188`
**Issue:** SITE A (`:jwt`, line 149) sits inside the success arm of the `with` in
`do_verify_token/3`, after signature + RFC 9068 validation has passed. The `else`
arm (lines 165-187), which handles invalid signature, bad `typ`/`iss`/`exp`/`iat`/`sub`,
`:no_kid`, `:key_not_found`, `:malformed`, and `:verification_crashed`, emits
nothing. By contrast SITE B emits `:"opaque-rejected"` for *every* opaque-shaped
token regardless of validity. The SITE A comment (lines 141-148) only justifies
emitting before `apply_restrictions/2` so that audience/scope failures still count as
`:jwt` — it does not address the larger class of JWT-shaped-but-unverifiable tokens
that produce no event at all. An operator graphing `:jwt` vs `:"opaque-rejected"`
gets a skewed denominator: opaque rejections are counted unconditionally while
JWT-format *rejections* (bad signature etc.) are invisible. This is defensible as
"the JWT never reached a confirmed format decision," but the asymmetry is neither
documented at the site nor covered by a test, so it reads as an oversight.
**Fix:** Either document the deliberate asymmetry explicitly at SITE A ("no event is
emitted for JWT-shaped tokens that fail signature/RFC-9068 validation; only
format-confirmed JWTs and structurally-opaque rejections are counted"), or add a
regression test asserting that a JWT-shaped token with an invalid signature emits no
`[:lockspire, :rs, :token_format]` event, pinning the intended contract:

```elixir
test "does not emit token_format for a JWT-shaped token with an invalid signature" do
  {token, _claims} = generate_key_and_token()
  tampered = String.replace_suffix(token, String.last(token), "A")
  call_with_bearer(tampered)
  refute_received {:telemetry_event, [:lockspire, :rs, :token_format], _, _}
end
```

### WR-02: doctor "never crashes" guarantee is not fully enforced — exceptions in `print_report/2` escape the `with`

**File:** `lib/mix/tasks/lockspire.doctor.token_format.ex:58-94`
**Issue:** The moduledoc and `help/0` promise the task "never raises ... never exits
non-zero." `report/0`'s `with` only rescues the `{:error, reason}` *tuples* returned
by `ServerPolicy.get_server_policy/0` and `Clients.list_clients/0`. Any *exception*
raised inside `print_report/2` — most plausibly a `FunctionClauseError` from
`effective_format/2` if a client's `access_token_format` is ever a value outside
`[:jwt, :opaque, nil]` — would propagate uncaught, abort the `Enum.map`, and exit the
Mix task non-zero. Today this is unreachable because `access_token_format` is an
`Ecto.Enum` constrained to `[:jwt, :opaque]` and nullable (client_record.ex:62), so
the three `effective_format/2` clauses are exhaustive. But the task's headline
contract is robustness, and a future enum value, a hand-edited DB row, or a
non-`%Client{}` element in the list would silently break the "never crashes" promise.
**Fix:** Wrap the whole report path in a rescue so the contract holds unconditionally,
e.g.:

```elixir
defp report do
  with {:ok, policy} <- ServerPolicy.get_server_policy(),
       {:ok, clients} <- Clients.list_clients() do
    print_report(policy, clients)
  else
    {:error, reason} ->
      Mix.shell().info("Could not inspect token formats: #{inspect(reason)}")
  end
rescue
  error ->
    Mix.shell().info("Could not inspect token formats: #{inspect(error)}")
end
```

### WR-03: doctor's effective format can disagree with real issuance when callers do not thread `server_policy_store`

**File:** `lib/mix/tasks/lockspire.doctor.token_format.ex:59-69, 104-113`
**Issue:** The doctor always reads the durable record via
`ServerPolicy.get_server_policy/0`, which returns `{:ok, %ServerPolicy{}}`
(repository.ex:138 backfills a default struct). So nil-format clients are always
resolved against the durable policy. At *issuance* time, however,
`AccessTokenSigner` resolves the policy via `server_policy(request)`, which returns
`nil` (clause 3, `:jwt`) whenever the caller did not thread
`:server_policy_store` into the request opts. The standard token endpoint does thread
it (token_controller.ex:24), so the two agree on the primary grant path — but the
contract that "the doctor uses the same precedence the signer uses" (help/0, line 44)
is only true *given the store is wired*. After an operator runs
`put_access_token_format(:opaque)`, the doctor will report nil-clients as `opaque`
while any issuance path that omits the store would still mint `:jwt`. The doctor
gives no signal that its answer is conditional on store wiring.
**Fix:** This is a pre-existing signer design (not introduced by this phase), so
no code change is required to the signer. Add one clarifying line to `help/0` (and
optionally the report header) noting the resolution assumes the durable
`ServerPolicy` store is consulted at issuance — true for the shipped token endpoint —
so operators do not over-trust the diagnosis on custom issuance paths.

## Info

### IN-01: `effective_format/2` clause 3 is dead in the doctor's call path

**File:** `lib/mix/tasks/lockspire.doctor.token_format.ex:113`
**Issue:** `get_server_policy/0` always returns a `%ServerPolicy{}` struct (never
`nil`), so the `nil + no policy -> :jwt` clause never executes in this task. It is
retained for byte-equivalence with `resolve_format/2`, which is the correct call —
flagging only so a future reader does not "simplify" it away and break the parity
contract the test and comment depend on.
**Fix:** None required. The existing comment (lines 96-103) already justifies its
presence; leave it.

### IN-02: opaque-rejection emit fires before `:malformed` JWT-shaped tokens, so "opaque-rejected" undercounts true opaque presentation

**File:** `lib/lockspire/plug/verify_token.ex:105-135, 194-204`
**Issue:** `opaque_shape?/1` returns `false` for three-segment-but-non-Base64URL
inputs (e.g. `"not.a.jwt"`), routing them to the JOSE path where they classify as
`:malformed` and emit no telemetry (per WR-01). This means `:"opaque-rejected"`
counts only tokens that fail the structural three-segment-Base64URL test, not all
non-JWT presentations. This matches the documented D-01 contract (comment lines
190-193), so it is correct-by-design — noted for the operator reading the metric so
they understand `:"opaque-rejected"` is a structural-shape signal, not a
"every-non-JWT" signal.
**Fix:** None required; consider one sentence in the v1.27 guide or telemetry docs if
operators will consume this counter directly.

### IN-03: migration guide says opaque issuance restored "immediately" — worth a word on in-flight tokens

**File:** `docs/upgrading/v1.27.md:52-62`
**Issue:** "This updates the durable runtime `ServerPolicy` record immediately and
applies to every `nil`-format client." Strictly accurate for *new* issuance, but an
operator could read "immediately" as also affecting already-issued JWTs. Already-minted
`at+jwt` tokens remain valid until expiry regardless of the policy flip.
**Fix:** Add a clause such as "applies to every subsequently issued token for
`nil`-format clients; already-issued access tokens keep their original format until
they expire."

---

_Reviewed: 2026-05-29T10:59:48Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
