---
phase: 55-rar-protocol-intake
reviewed: 2026-05-06T07:46:45Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/lockspire/domain/pushed_authorization_request.ex
  - lib/lockspire/domain/interaction.ex
  - lib/lockspire/storage/ecto/pushed_authorization_request_record.ex
  - lib/lockspire/storage/ecto/interaction_record.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/protocol/pushed_authorization_request.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - priv/repo/migrations/20260506020000_add_rar_intake_state.exs
  - test/lockspire/protocol/authorization_request_test.exs
  - test/lockspire/protocol/pushed_authorization_request_test.exs
  - test/lockspire/protocol/authorization_flow_test.exs
  - test/integration/phase55_rar_intake_e2e_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 55: Code Review Report

**Reviewed:** 2026-05-06T07:46:45Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The Phase 55 RAR intake implementation is generally sound on the four focus areas
called out by the orchestrator:

1. **JSON parsing safety boundary** — `Jason.decode/1` is used (not `decode!`),
   errors are caught and translated into a stable RFC 9396 §5.4
   `invalid_authorization_details` redirect-safe error. No unsafe `decode!`,
   `:atoms` mode, or `String.to_atom/1` on parsed input.
2. **Length cap implementation** — 2048-byte cap is enforced via `byte_size/1`
   on the raw binary payload, only on the direct `/authorize` pipeline
   (`pushed?: false`), and is skipped for PAR (`pushed?: true`) and for
   pre-decoded lists. Order in the `with` chain is correct (length check
   precedes JSON decode).
3. **RFC 9396 §5.4 error code consistency** — error string is exactly
   `"invalid_authorization_details"` per RFC 9396, and the over-length case
   correctly maps to `error: "invalid_request"` (length is not a §5.4 error).
4. **Carry-through** — RAR is carried `request → PAR domain →
   PAR record (jsonb[]) → consume → flat-params (`pushed_request_to_params`) →
   re-validation as list → Validated → Interaction domain → Interaction
   record`. Round-trip is verified end-to-end by integration tests.

However, four warning-level defects degrade correctness and consistency:
- The Request Object (JAR) projection silently drops `authorization_details`,
  contradicting a test that claims "pre-decoded list (Request Object
  projection)" support.
- `ensure_authorization_details_shape/2` is structurally lax — it accepts a
  list whose elements are structs, lacks RFC 9396 §2 `type` requirement (a
  Phase 56 deferral, but worth flagging), and crucially returns `{:ok, []}`
  for `authorization_details=[]` (an *empty* JSON array), which RFC 9396 §2
  arguably requires to be at least one element.
- The `pushed_request_to_params/1` projection re-injects an empty list as
  `"authorization_details" => []`, which then re-runs the validator on the
  consumed-PAR side — harmless today, but couples the two flows in a way
  that will silently misbehave once Phase 56 introduces stricter shape
  validation.
- The reference `ConsentLive` consent surface does NOT display
  `authorization_details` to the end user. RFC 9396 §1.2 / §6 requires the
  user to see what they are consenting to; carrying RAR through storage is
  insufficient if the consent screen never renders it.

Plus four info-level issues (test description drift, dead-code path on
defaults, magic-number duplication, and a minor documentation gap).

No critical issues found. No security vulnerabilities found.

## Warnings

### WR-01: Request Object (JAR) projection silently drops `authorization_details`

**File:** `lib/lockspire/protocol/request_object.ex:283-298`
**Issue:** `project_to_params/2` enumerates a fixed allowlist of JAR claims
and projects them into the flat-params shape consumed by
`AuthorizationRequest.validate_with_client/3`. The allowlist is:
`client_id, redirect_uri, response_type, scope, prompt, nonce, state,
code_challenge, code_challenge_method`. **`authorization_details` is not in
the list**, so a client that sends a signed Request Object containing
`authorization_details` will have that claim *silently dropped* before
validation — the `Validated` struct receives `authorization_details: []` and
the Interaction is persisted with no RAR.

This contradicts the test in
`test/lockspire/protocol/authorization_request_test.exs:938-952` titled
`"accepts authorization_details from a pre-decoded list (Request Object
projection)"`. That test only verifies the protocol-level handler accepts a
pre-decoded list when *injected directly* — it does NOT exercise the JAR
pipeline end-to-end, so the gap is not caught.

It also breaks RFC 9101 (JAR) + RFC 9396 §3 interop: a FAPI 2.0 client that
is *required* to use signed request objects cannot use RAR at all under the
current implementation.

**Fix:** Add `authorization_details` to the JAR projection allowlist:

```elixir
defp project_to_params(%Jar{claims: claims}, %Client{client_id: client_id}) do
  {:ok,
   %{
     "client_id" => client_id,
     "redirect_uri" => claims["redirect_uri"],
     "response_type" => claims["response_type"],
     "scope" => claims["scope"],
     "prompt" => claims["prompt"],
     "nonce" => claims["nonce"],
     "state" => claims["state"],
     "code_challenge" => claims["code_challenge"],
     "code_challenge_method" => claims["code_challenge_method"],
     "authorization_details" => claims["authorization_details"]
   }
   |> Enum.reject(fn {_key, value} -> is_nil(value) end)
   |> Map.new()}
end
```

Also add an end-to-end JAR+RAR test covering the projection path.

Note: `request_object.ex` is technically outside the file scope of this
review, but the defect is structurally caused by the Phase 55 design
assuming the JAR projection would carry the field forward.

### WR-02: Reference `ConsentLive` does not surface `authorization_details` to the user

**File:** `lib/lockspire/web/live/consent_live.ex:45-83`
**Issue:** The reference consent surface renders `@requested_scopes` but
never reads or displays `interaction.authorization_details`. RFC 9396 §1.2
("Authorization Details, in their JSON-based, structured form, can be more
expressive than scopes...") and §6 ("the AS MUST take the
`authorization_details` ... into account") and §13 require the user to see
what they are consenting to. Carrying RAR through `Validated → PAR →
Interaction` is the protocol intake — if the consent screen never renders
it, an end-user approving a payment_initiation RAR has effectively
rubber-stamped a payload they could not see.

The phase scope note correctly says this is "Protocol Intake," with host
display deferred to later phases. The reference `ConsentLive` is shipped as
the canonical example, however, and integrators may copy it and inadvertently
inherit the gap. At minimum, `requested_scopes` should be matched by an
`authorization_details` rendering (or an explicit comment that the host MUST
add this when RAR is in use).

**Fix:** Either (a) extend `load_consent_context/2` to surface
`interaction.authorization_details` and render it in the template, or (b)
add a prominent module-level `@moduledoc` warning that the reference
template intentionally omits RAR rendering and must be supplied by the host
before RFC 9396 conformance can be claimed.

```elixir
{:ok,
 %{
   page_title: "Authorize Access",
   ...
   requested_scopes: interaction.scopes_requested,
   authorization_details: interaction.authorization_details,
   ...
 }}
```

### WR-03: `ensure_authorization_details_shape/2` accepts an empty list as valid RAR

**File:** `lib/lockspire/protocol/authorization_request.ex:615-623`
**Issue:** `ensure_authorization_details_shape/2` returns `{:ok, value}` when
`Enum.all?(value, &is_map/1)` is true. `Enum.all?/2` returns `true` for an
empty list, so `authorization_details=[]` (a literal empty JSON array
submitted by a client) is accepted as a valid RAR request. RFC 9396 §2
defines `authorization_details` as "a JSON array containing JSON objects,"
implying at least one element. An empty array is semantically meaningless
and should be rejected as `invalid_authorization_details`, otherwise a
client can send `authorization_details=[]` to populate the wire-format
without supplying any actual authorization detail (creating audit
ambiguity between "no RAR" and "explicitly empty RAR").

This also collides with the absent-and-empty-string handling, which both
return `{:ok, []}`. The three states ("absent," "empty string," "explicit
empty array") all collapse to the same accepted result, leaving no way to
distinguish them downstream.

**Fix:** Either reject empty arrays explicitly, or document the deliberate
collapse:

```elixir
defp ensure_authorization_details_shape([], params),
  do: invalid_authorization_details(params)

defp ensure_authorization_details_shape(value, params) when is_list(value) do
  if Enum.all?(value, &is_map/1) do
    {:ok, value}
  else
    invalid_authorization_details(params)
  end
end
```

If empty is intentionally allowed, add a comment to that effect citing the
specific phase requirement that defers `type`-presence validation to Phase
56.

### WR-04: `pushed_request_to_params/1` round-trips `authorization_details: []` through the validator unnecessarily

**File:** `lib/lockspire/protocol/authorization_request.ex:723-739`
**Issue:** When a PAR is consumed, `pushed_request_to_params/1` projects the
domain struct back into the flat-params shape and feeds it through
`validate_with_client/3` with `pushed?: false` (because the call comes from
the public `validate/1` path, not `validate_pushed/2`). This means a PAR
that was successfully pushed with a 4KB `authorization_details` will, on
consume, re-enter `validate_authorization_details/2` with `pushed?: false`.

Today this is benign because `validate_authorization_details_length/3` only
runs for `is_binary(value)` — a list bypasses it. But Phase 56 will almost
certainly add structural validation (RFC 9396 §2 `type` whitelist, etc.),
and that validation will run *twice*: once at PAR push time, then again at
PAR consume time on already-validated content. Worse, if the structural
validator is later updated and a host had a request burned at push time
with the *old* rules, consume-time re-validation will reject what was
already accepted, producing a non-recoverable mid-flow failure for the
end user.

This is also a subtle correctness coupling: if Phase 56 ever introduces a
`pushed?`-conditional check, the consume path will silently get the
non-pushed rules.

**Fix:** Either (a) skip re-validation of `authorization_details` on the
PAR-consume path (since the data is already trusted server-owned state), or
(b) propagate a `pushed_at_push_time?` flag through `pushed_request_to_params`
so consume-time validation knows to use pushed-mode rules. Option (a) is
preferred:

```elixir
defp resolve_authorization_params(%{"request_uri" => request_uri} = params, %Client{} = client)
     when is_binary(request_uri) and request_uri != "" do
  with :ok <- ...,
       {:ok, %PushedAuthorizationRequest{} = request} <- ... do
    # Consumed PAR is server-owned trusted state; mark it so downstream
    # validators can short-circuit re-checks of already-validated content.
    {:ok, pushed_request_to_params(request) |> Map.put(:__from_par__, true)}
  end
end
```

At minimum, add a regression test that pushes a 4KB RAR via `/par` and
consumes it via `/authorize?request_uri=...` to lock in the current
permissive behavior.

## Info

### IN-01: Test description says "characters" but cap is bytes

**File:** `test/lockspire/protocol/authorization_request_test.exs:897`
**Issue:** Test name is `"rejects authorization_details longer than 2048
characters on direct requests"`, but the implementation uses `byte_size/1`.
For multi-byte UTF-8 input these differ — a 1024-character payload of
4-byte glyphs is 4096 bytes and would be rejected despite being "1024
characters." The behavior is correct (URI-too-long is a byte-level concern)
but the wording is misleading and may cause future confusion.
**Fix:** Rename the test and the constant docstring to "2048 bytes" and
update the `redirect_error` description string from "exceeds the maximum
allowed size" to "exceeds 2048 bytes".

### IN-02: Empty-string and absent cases collapse with no observable difference

**File:** `lib/lockspire/protocol/authorization_request.ex:570-589`
**Issue:** `nil` and `""` both return `{:ok, []}`. This is fine, but the
two clauses are duplicated boilerplate. Consider collapsing to a single
`when value in [nil, ""]` guard, or a `present?/1` helper, to reduce
surface area for future drift. This is the same pattern already used
elsewhere in the module (`present?/1` at line 874).
**Fix:**
```elixir
case Map.get(params, "authorization_details") do
  value when value in [nil, ""] -> {:ok, []}
  ...
end
```

### IN-03: Magic number `2048` is module-level but description string repeats it implicitly

**File:** `lib/lockspire/protocol/authorization_request.ex:18,597-598`
**Issue:** `@max_authorization_details_length 2048` is defined as a module
attribute, but the user-facing error description hardcodes "exceeds the
maximum allowed size" and never names the limit. Operators and clients
debugging a 414-redirect won't know what threshold they tripped without
reading source. Consider interpolating the limit into the description.
**Fix:**
```elixir
"authorization_details exceeds the maximum allowed size of " <>
  "#{@max_authorization_details_length} bytes"
```

### IN-04: `@type code_challenge_method :: :S256 | nil` includes `nil` but field is `validate_required` in changeset

**File:** `lib/lockspire/domain/pushed_authorization_request.ex:12`
and `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex:50-57`
**Issue:** The domain typespec says `code_challenge_method :: :S256 | nil`,
but the storage `changeset/2` lists `:code_challenge_method` in
`validate_required/2`. The two contracts disagree: domain says nullable,
storage says required. Pre-existing (not introduced by Phase 55) but worth
flagging since this file was modified in the phase. Either tighten the
typespec to `:S256` (since storage rejects nil) or relax the changeset.
**Fix:** Tighten the typespec — current callers always set `:S256`:
```elixir
@type code_challenge_method :: :S256
```

---

_Reviewed: 2026-05-06T07:46:45Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
