---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
reviewed: 2026-04-26T12:30:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - lib/lockspire/admin/server_policy.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/domain/initial_access_token.ex
  - lib/lockspire/domain/server_policy.ex
  - lib/lockspire/protocol/dcr_policy.ex
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/initial_access_token_record.ex
  - lib/lockspire/storage/ecto/server_policy_record.ex
  - priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs
  - priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs
  - priv/repo/migrations/20260427000020_extend_lockspire_clients_dcr.exs
  - test/lockspire/admin/server_policy_test.exs
  - test/lockspire/domain/initial_access_token_test.exs
  - test/lockspire/protocol/dcr_policy_invariant_test.exs
  - test/lockspire/protocol/dcr_policy_test.exs
  - test/lockspire/storage/ecto/client_record_test.exs
  - test/lockspire/storage/ecto/initial_access_token_record_test.exs
  - test/lockspire/storage/ecto/server_policy_record_test.exs
  - test/support/fixtures/initial_access_token_fixtures.ex
findings:
  blocker: 3
  warning: 9
  total: 12
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-04-26T12:30:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Phase 25 ships RFC 7591 DCR storage primitives, the intersection-only `DcrPolicy.resolve/3`
resolver, IAT storage with hash-at-rest discipline, and a Discovery-binding invariant test.
The migrations are correctly ordered (Migration B creates `lockspire_initial_access_tokens`
before Migration C adds the FK on `lockspire_clients`), and `Lockspire.Security.Policy.hash_token/1`
is reused everywhere a token hash is computed (no hand-rolled SHA primitives).

However, the resolver and the admin read-merge-write singleton plumbing carry three **BLOCKER**
defects:

1. `DcrPolicy.intersect_redirect_uris/5` silently passes inbound `redirect_uris` whose
   `URI.parse/1` yields `nil` scheme/host (e.g., `"not a uri"`, `"/relative-path"`,
   `"javascript:alert(1)"`). The resolver returns `{:ok, ...}` for inbound that should be
   rejected, leaking the bound-check responsibility entirely to Phase 26 and contradicting
   the Resolved-shape contract.
2. `Admin.ServerPolicy.put_dcr_policy/1` and `put_server_policy/1` perform a non-atomic
   read-merge-write across two `Repository` calls. Concurrent admin writes (one updating
   `par_policy`, another updating DCR fields) lose updates — the test suite only exercises
   the sequential path.
3. `DcrPolicy.intersect_redirect_uris/5` performs case-sensitive host comparison.
   `"https://Partner.Example.com/cb"` is rejected against operator allowlist
   `["partner.example.com"]`, contrary to RFC 3986 §3.2.2 (host is case-insensitive).
   This will produce confusing operator-visible behavior the moment a registrant submits
   a mixed-case host.

The Discovery-binding invariant test is structurally sound but its docstring overclaims:
the test does not actually pin equality with the discovery × server-allowlist intersection
(it pins only one representative element + a trivially-true subset assertion).

The IAT fixture's hash-at-rest discipline (`Policy.hash_token/1`, never a hand-rolled
sha256) is correctly enforced — the only remaining concern there is that
`InitialAccessTokenRecord.changeset/2` casts `:id` from the domain struct, which should be
removed for non-singleton tables.

## Blocker Issues

### CR-01: DcrPolicy silently accepts malformed inbound `redirect_uris` (security-relevant bound-check escape)

**File:** `lib/lockspire/protocol/dcr_policy.ex:141-162`
**Issue:**

`intersect_redirect_uris/5` parses each inbound `redirect_uri` with `URI.parse/1` and then
filters out `nil` schemes and hosts before calling `intersect_axis/4`:

```elixir
parsed = redirect_uris |> List.wrap() |> Enum.map(&URI.parse/1)
requested_schemes = parsed |> Enum.map(& &1.scheme) |> Enum.reject(&is_nil/1) |> Enum.uniq()
requested_hosts = parsed |> Enum.map(& &1.host) |> Enum.reject(&is_nil/1) |> Enum.uniq()
```

`URI.parse/1` is lenient: malformed/relative inputs yield `%URI{scheme: nil, host: nil}`.
Examples that produce `nil` scheme **and** `nil` host:

- `"/callback"` — relative path
- `"not a uri"` — non-URI free text
- `""` — empty string
- `"file:relative"` — opaque URI

After `Enum.reject(&is_nil/1)`, these contribute nothing to `requested_schemes` and
`requested_hosts`, so `intersect_axis/4` sees empty `requested` sets, computes empty diffs
against the server allowlist, and returns `{:ok, []}` for both axes. The resolver then
returns `{:ok, %Resolved{}}` — i.e., the request is **bound-check approved**.

This is a security-relevant escape: a registrant submitting `redirect_uris: ["/callback"]`
or `redirect_uris: ["javascript:alert(1)"]` (the latter has scheme `"javascript"` and `nil`
host — only host is filtered, scheme would still be checked) bypasses the resolver entirely.
At minimum, the resolver should return `{:error, :invalid_client_metadata,
%{field: :redirect_uri_scheme | :redirect_uri_host, reason: :unparseable, ...}}` for any
URI whose parse result is missing the scheme or host components. Phase 26 may also catch
this, but the resolver's documented contract — "the resolver's job is bound-checking" —
is presently violated.

**Fix:**
```elixir
defp intersect_redirect_uris(
       redirect_uris,
       server_schemes,
       server_hosts,
       iat_schemes,
       iat_hosts
     ) do
  parsed =
    redirect_uris
    |> List.wrap()
    |> Enum.map(&URI.parse/1)

  case Enum.find(parsed, fn uri -> is_nil(uri.scheme) or is_nil(uri.host) end) do
    %URI{} = bad ->
      {:error, :invalid_client_metadata,
       %{field: :redirect_uris, reason: :unparseable, allowed: []}}

    nil ->
      requested_schemes = parsed |> Enum.map(& &1.scheme) |> Enum.uniq()
      # Lowercase host per RFC 3986 §3.2.2 — see CR-03
      requested_hosts = parsed |> Enum.map(&String.downcase(&1.host)) |> Enum.uniq()

      with {:ok, schemes} <-
             intersect_axis(:redirect_uri_scheme, requested_schemes, server_schemes, iat_schemes),
           {:ok, hosts} <-
             intersect_axis(:redirect_uri_host, requested_hosts, server_hosts, iat_hosts) do
        {:ok, schemes, hosts}
      end
  end
end
```

A regression test should send `redirect_uris: ["/cb"]` and `redirect_uris: [""]` and assert
each returns `{:error, :invalid_client_metadata, _}`.

---

### CR-02: `Admin.ServerPolicy.put_dcr_policy/1` lost-update race against `put_server_policy/1`

**File:** `lib/lockspire/admin/server_policy.ex:34-39, 65-71`
**Issue:**

Both setters perform a non-atomic two-step:

```elixir
# put_server_policy/1 — lines 34-39
with {:ok, normalized_mode} <- normalize_par_policy(mode),
     {:ok, %ServerPolicy{} = current} <- Repository.get_server_policy() do
  Repository.put_server_policy(%ServerPolicy{current | par_policy: normalized_mode})
end

# put_dcr_policy/1 — lines 65-71
with {:ok, normalized_attrs} <- normalize_dcr_attrs(attrs),
     {:ok, current} <- Repository.get_server_policy() do
  merged = Map.merge(current, normalized_attrs)
  Repository.put_server_policy(merged)
end
```

`Repository.get_server_policy/0` does **not** lock the row. `Repository.put_server_policy/1`
locks the row internally with `lock("FOR UPDATE")` (lib/lockspire/storage/ecto/repository.ex:115)
— but that only protects the single-statement write, not the read-merge-write performed
above the Repository boundary.

Concurrent interleaving:

1. Admin A: `put_server_policy(:required)` reads `current = {par_policy: :optional, registration_policy: :open}`
2. Admin B: `put_dcr_policy(%{registration_policy: :disabled})` reads `current = {par_policy: :optional, registration_policy: :open}`
3. Admin A writes `{par_policy: :required, registration_policy: :open}`
4. Admin B writes `{par_policy: :optional, registration_policy: :disabled}` — **par_policy
   reverts to `:optional`, losing Admin A's update**

The docstring on `put_dcr_policy/1` (lines 53-56) explicitly promises "preserving any
non-DCR fields (notably `par_policy`) on the same row" — this promise is broken under
concurrency. The existing test at `test/lockspire/admin/server_policy_test.exs:111-122`
covers only the sequential path.

The fix requires moving the read-merge-write into a single `Repository.transact/1`
transaction with `lock("FOR UPDATE")` at read time, OR extending `Repository.put_server_policy/1`
to accept a function that mutates the locked row:

**Fix:**
Add `Repository.update_server_policy/1` that takes a mutator function and runs it under the
existing `FOR UPDATE` lock:

```elixir
# lib/lockspire/storage/ecto/repository.ex
@impl ServerPolicyStore
def update_server_policy(mutator) when is_function(mutator, 1) do
  transact(fn ->
    singleton_id = ServerPolicyRecord.singleton_id()

    current_record =
      ServerPolicyRecord
      |> where([p], p.id == ^singleton_id)
      |> lock("FOR UPDATE")
      |> repo().one()

    current =
      case current_record do
        nil -> %ServerPolicy{id: singleton_id}
        %ServerPolicyRecord{} = r -> ServerPolicyRecord.to_domain(r)
      end

    new_policy = mutator.(current)

    case current_record do
      nil ->
        %ServerPolicyRecord{}
        |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
        |> repo_insert()
        |> map_one(&ServerPolicyRecord.to_domain/1)
        |> unwrap_or_rollback()

      %ServerPolicyRecord{} = r ->
        r
        |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
        |> repo_update([])
        |> map_one(&ServerPolicyRecord.to_domain/1)
        |> unwrap_or_rollback()
    end
  end)
end
```

Then `Admin.ServerPolicy.put_server_policy/1` and `put_dcr_policy/1` both call
`update_server_policy/1` with a mutator, eliminating the lost-update race.

A concurrency regression test should `Task.async_stream` interleaved
`put_server_policy(:required)` and `put_dcr_policy(%{registration_policy: :disabled})` calls
and assert no field reverts.

---

### CR-03: `DcrPolicy` host comparison is case-sensitive (RFC 3986 §3.2.2 violation)

**File:** `lib/lockspire/protocol/dcr_policy.ex:154`
**Issue:**

```elixir
requested_hosts = parsed |> Enum.map(& &1.host) |> Enum.reject(&is_nil/1) |> Enum.uniq()
```

`URI.parse/1` preserves the case of the host as supplied by the registrant.
`MapSet.intersection/2` and `MapSet.difference/2` then compare hosts byte-for-byte against
`server_policy.dcr_allowed_redirect_uri_hosts`. A registrant submitting
`"https://Partner.Example.com/cb"` is rejected against operator allowlist
`["partner.example.com"]`, even though RFC 3986 §3.2.2 declares hosts case-insensitive.

Conversely, an operator who happens to seed the allowlist with mixed case (e.g.,
`"PARTNER.EXAMPLE.COM"`) will reject **all** correctly-lowercased registrant submissions —
silently bricking the DCR endpoint for that host.

Symmetry matters: the operator-side admin path (Phase 28) and the resolver must agree on a
canonical form. Without canonicalization, the operator's intent ("allow partner.example.com")
is not faithfully enforced.

The redirect-URI **scheme** axis (line 153) has the same flaw, though scheme case-collisions
are less common in practice (`"HTTPS"` vs `"https"`); RFC 3986 §3.1 also makes scheme
case-insensitive.

**Fix:**

Canonicalize both axes at the boundary:

```elixir
requested_schemes =
  parsed |> Enum.map(&(&1.scheme && String.downcase(&1.scheme))) |> Enum.reject(&is_nil/1) |> Enum.uniq()

requested_hosts =
  parsed |> Enum.map(&(&1.host && String.downcase(&1.host))) |> Enum.reject(&is_nil/1) |> Enum.uniq()
```

And — crucially — canonicalize the operator-side allowlists at admin-mint time
(`Admin.ServerPolicy.put_dcr_policy/1`), or canonicalize at the read site:

```elixir
# in resolve/3, before calling intersect_redirect_uris:
server_schemes = Enum.map(server_policy.dcr_allowed_redirect_uri_schemes, &String.downcase/1)
server_hosts   = Enum.map(server_policy.dcr_allowed_redirect_uri_hosts, &String.downcase/1)
```

Both sides must be downcased; canonicalizing only the inbound side perpetuates the bug
when the operator stores mixed case. A regression test should pass
`{server_allowlist: ["partner.example.com"], inbound: ["https://Partner.Example.com/cb"]}`
and assert `{:ok, ...}`.

---

## Warnings

### WR-01: `intersect_axis/4` truthy-check on `iat_override_list` mishandles empty list

**File:** `lib/lockspire/protocol/dcr_policy.ex:120-123`
**Issue:**

```elixir
defp intersect_axis(field, requested_list, server_allowlist, iat_override_list) do
  requested = MapSet.new(requested_list || [])
  server_set = MapSet.new(server_allowlist || [])
  iat_set = if iat_override_list, do: MapSet.new(iat_override_list), else: server_set
  ...
```

In Elixir, `if [] do ... else ... end` runs the `do` branch (empty list is truthy). So an
operator IAT override of `%{"allowed_scopes" => []}` correctly yields `iat_set = MapSet.new([])`
(empty set), narrowing the effective allowlist to nothing for that axis. This is technically
correct — but the `override_for/2` helper at line 188-191 already returns `nil` when the
override key is absent, and **only** lists pass through when present.

The code path is correct in practice, but the `if iat_override_list` guard is fragile: if
`override_for/2` is ever changed to return `[]` for "absent", the logic silently flips
("no override" becomes "narrow to nothing"). Replace the truthy check with an explicit
`is_nil/1` test for clarity:

**Fix:**
```elixir
iat_set =
  case iat_override_list do
    nil -> server_set
    list when is_list(list) -> MapSet.new(list)
  end
```

---

### WR-02: `DcrPolicyInvariantTest` overclaims — pins subset, not equality

**File:** `test/lockspire/protocol/dcr_policy_invariant_test.exs:7-9, 26-133`
**Issue:**

The module docstring claims:

> Asserts that the set of `token_endpoint_auth_method` values DCR will accept equals
> `MapSet.intersection(ServerPolicy.dcr_allowed_token_endpoint_auth_methods, Discovery.token_endpoint_auth_methods_supported/0)`.

The test does **not** prove equality. It:

1. Picks a single `representative_method` from `expected_set` (line 57) and asserts the
   resolver's `accepted_for_inbound` is a `MapSet.subset?` of `expected_set` (line 74).
2. Asserts a single `discovery_only` probe (in discovery, not in server allowlist) returns
   `:not_in_allowlist` (lines 86-98).
3. Loops over `server_only` (in server allowlist, not in discovery) and asserts
   `MapSet.subset?(probe_accepted ∩ discovery_set, expected_set)` (line 124).

Step 3's assertion is **trivially true**: `probe_accepted = MapSet.new([probe])` where
`probe ∉ discovery_set`, so the intersection is always `MapSet.new()`, which is a subset
of every set. This loop catches no drift. The `bounded_by_discovery` framing is misleading.

What's missing for a genuine equality binding:

- Iterate every member of `expected_set` and assert the resolver accepts it (not just the
  first via `List.first/1`).
- Assert that for any element of `server_allowlist \ expected_set`, the resolver's accepted
  set does NOT include it after the `MapSet.intersection(_, discovery_set)` filter that
  Phase 27 will apply (the test currently asserts only `MapSet.subset?` against `expected_set`,
  which is consistent with both equality and strict-subset).

**Fix:**

Either weaken the docstring (s/`equals`/`is bounded by`/) and remove the trivial loop,
or strengthen the test:

```elixir
# Replace List.first with a loop over the entire expected_set
for method <- expected_set do
  inbound = Map.put(inbound_template, "token_endpoint_auth_method", method)
  assert {:ok, %Resolved{allowed_token_endpoint_auth_methods: [^method]}} =
           DcrPolicy.resolve(server_policy, nil, inbound)
end
```

Either way, the test as it stands risks false confidence: a future refactor could break
the resolver-discovery binding for any method other than `representative_method` and the
test would still pass.

---

### WR-03: `InitialAccessTokenRecord.changeset/2` casts `:id` from domain struct

**File:** `lib/lockspire/storage/ecto/initial_access_token_record.ex:38-46`
**Issue:**

```elixir
def changeset(record, %InitialAccessToken{} = iat) do
  record
  |> cast(Map.from_struct(iat), [
    :id,
    :token_hash,
    ...
  ])
```

Casting `:id` is appropriate for the `lockspire_server_policies` singleton (where the ID is
fixed at `1`), but `lockspire_initial_access_tokens` uses Postgres autoincrement IDs.
Casting `:id` allows a caller to override the generated ID — a fixture or admin code can
accidentally collide with an existing row, producing a unique-constraint violation that's
much harder to diagnose than the desired "ID is server-assigned" semantics.

This pattern is duplicated from `ServerPolicyRecord.changeset/2`, where it is required.
Here it is at best unused (the IAT struct's default `:id` is `nil`, which is harmless),
at worst a footgun for fixtures.

**Fix:**
```elixir
def changeset(record, %InitialAccessToken{} = iat) do
  record
  |> cast(Map.from_struct(iat), [
    :token_hash,
    :expires_at,
    :single_use,
    :used_at,
    :revoked_at,
    :policy_overrides,
    :created_by
  ])
  |> validate_required([:token_hash, :expires_at, :single_use])
  |> unique_constraint(:token_hash)
end
```

---

### WR-04: `DcrPolicy.resolve/3` accepts struct-shaped `iat_overrides` silently

**File:** `lib/lockspire/protocol/dcr_policy.ex:65-66`
**Issue:**

```elixir
def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)
    when (is_map(iat_overrides) or is_nil(iat_overrides)) and is_map(inbound_metadata) do
```

In Elixir, structs are maps, so `is_map(iat_overrides)` accepts a `%InitialAccessToken{}`
struct. If a caller accidentally passes the entire IAT struct rather than its
`policy_overrides` field, the resolver doesn't crash — it silently treats the IAT as
"no overrides" because `Map.get(struct, "allowed_scopes")` returns `nil` (struct fields
are atom-keyed).

This is a future footgun for Phase 26's `redeem/1` integration. A typo there
(`DcrPolicy.resolve(server_policy, iat_struct, inbound)` instead of
`DcrPolicy.resolve(server_policy, iat_struct.policy_overrides, inbound)`) silently bypasses
all IAT narrowing.

**Fix:**
Tighten the guard to reject structs:

```elixir
def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)
    when (is_nil(iat_overrides) or
            (is_map(iat_overrides) and not is_struct(iat_overrides))) and
           is_map(inbound_metadata) do
```

Or add an explicit clause that documents the rejection:

```elixir
def resolve(_server_policy, %_{} = struct, _inbound) do
  raise ArgumentError,
        "iat_overrides must be a plain map or nil, got struct: #{inspect(struct.__struct__)}"
end
```

---

### WR-05: `Admin.ServerPolicy.normalize_dcr_attrs/1` silently drops unknown atom keys

**File:** `lib/lockspire/admin/server_policy.ex:92-119`
**Issue:**

```elixir
{key, value}, acc when is_atom(key) ->
  if key in @dcr_field_keys, do: Map.put(acc, key, value), else: acc
```

Unknown atom keys (e.g., a typo `:dcr_allowed_scope` instead of `:dcr_allowed_scopes`) are
silently dropped. The same applies to unknown string keys via `atomize_dcr_key/1` returning
`nil`. An admin form that sends a typo'd field gets `{:ok, %ServerPolicy{...}}` back with
the typo'd value silently lost — no audit trail, no error.

For an admin LiveView (Phase 28), the symmetric "unknown key" surface should at minimum
log a telemetry event and ideally return `{:error, [%{field: :unknown, reason: ...}]}`.
This is documented as a Phase 28 concern, but at the boundary, silent drops are a known
admin-UX hazard.

**Fix:**
At minimum, log unknown keys via `Logger.warning/2` or telemetry; at best, return an error
detail for unknown keys:

```elixir
defp normalize_dcr_attrs(attrs) do
  {atomized, unknown} =
    Enum.reduce(attrs, {%{}, []}, fn ... end)

  if unknown == [] do
    # ... existing logic
  else
    {:error, Enum.map(unknown, &%{field: &1, reason: :unknown_dcr_field, detail: &1})}
  end
end
```

---

### WR-06: `Discovery.token_endpoint_auth_methods_supported/0` decoupled from mounted-route truth

**File:** `lib/lockspire/protocol/discovery.ex:31-32, 90-96`
**Issue:**

The new public 0-arity returns the static module attribute unconditionally:

```elixir
def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported
```

The 1-arity (line 90) returns `[]` when `token_endpoint` is not mounted:

```elixir
defp token_endpoint_auth_methods_supported(endpoint_metadata) do
  if Map.has_key?(endpoint_metadata, "token_endpoint") do
    @token_endpoint_auth_methods_supported
  else
    []
  end
end
```

So the actual published `openid-configuration` JSON document and the value the DCR
invariant test pins against can diverge: a host app that omits the `token_endpoint` route
will publish `"token_endpoint_auth_methods_supported": []` in its discovery doc, but DCR
will still accept methods from the static list.

The DcrPolicyInvariantTest docstring (lines 7-9) acknowledges this, but Phase 27's HTTP
surface "MUST additionally filter the resolver's `allowed_token_endpoint_auth_methods`
through `MapSet.intersection(_, discovery_supported)`" — and "discovery_supported" should
mean the truth-based discovery output, not the static attribute.

**Fix:**
Either:
1. Make the public accessor take an optional opts list and consult mounted routes (mirrors
   the 1-arity logic), or
2. Add a second public accessor `published_token_endpoint_auth_methods_supported/0` that
   reflects the actually-published doc, and rename the static one to make the distinction
   explicit (e.g., `static_token_endpoint_auth_methods_supported/0`).

The DCR invariant test should bind against the **published** set, not the static set;
otherwise Phase 27 has two sources of truth to reconcile.

---

### WR-07: `ClientRecord.update_changeset/2` cast list omits new DCR fields with no documentation

**File:** `lib/lockspire/storage/ecto/client_record.ex:117-140`
**Issue:**

The `update_changeset/2` cast list does not include any of the new Phase 25 DCR-related
fields:

- `provenance` — intentionally excluded (test at client_record_test.exs:87-124 confirms)
- `registration_access_token_hash` — silently excluded
- `registration_client_uri` — silently excluded
- `initial_access_token_id` — silently excluded
- `client_id_issued_at` — silently excluded
- `client_secret_expires_at` — silently excluded

The `provenance` exclusion is documented (D-09 says provenance is create-time-only) and
covered by a regression test. The other five exclusions are **not** documented — Phase 26
(RAT rotation, IAT redemption) will need to update at least
`registration_access_token_hash` and `client_secret_expires_at`. There's no comment
indicating "Phase 26 will add a separate changeset for these," so a future implementer
might extend `update_changeset/2` ad-hoc and accidentally allow ops surfaces (e.g., the
existing admin `set_client_active`) to mutate RAT hashes.

**Fix:**

Add a comment block above `update_changeset/2`:

```elixir
# Phase 25 note: DCR-related fields (registration_access_token_hash,
# registration_client_uri, initial_access_token_id, client_id_issued_at,
# client_secret_expires_at) are deliberately excluded. Phase 26 will introduce a separate
# `dcr_management_changeset/2` for RAT rotation and client_secret rotation under the
# self-registered provenance. Do NOT add these fields to update_changeset/2 — that would
# expose them to the operator-admin path, which must remain unable to mutate RFC 7592
# management state.
```

---

### WR-08: Migration default `[]` for `{:array, :text}` columns persists empty arrays, not NULL

**File:** `priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs:10-15`
**Issue:**

```elixir
add :dcr_allowed_scopes, {:array, :text}, null: false, default: []
```

This is correct for Postgres — `default: []` produces `DEFAULT '{}'` SQL — but a subtle
implication: an existing row inserted before this migration receives `[]`, indistinguishable
from "operator explicitly set this to empty." Combined with `DcrPolicy.resolve/3` rejecting
all non-empty inbound when the allowlist is `[]` (not just nil), this means:

- A host app that runs migration A but doesn't run an operator-mint script will, by default,
  reject **every** DCR request as `:not_in_allowlist`.
- The error message returned (`allowed: []`) tells the registrant "no values are allowed,"
  not "the operator hasn't configured DCR yet."

This is the documented behavior (D-06: "operator must explicitly populate"), but the empty
allowlist + `:disabled` registration policy together produce a "secure-by-default" stance
that's safe but operator-confusing. Pair this with WR-05: an operator typo in admin form
input lands in `[]` allowlist territory and is hard to diagnose from telemetry.

**Fix:**

Recommend a follow-up: if `registration_policy != :disabled` and any
`dcr_allowed_*` is `[]`, the resolver should return a more informative error
(`reason: :dcr_unconfigured` or similar), not `:not_in_allowlist` with `allowed: []`.
Alternatively, document this in the resolver moduledoc so Phase 26's intake validator can
distinguish.

---

### WR-09: `InitialAccessToken.t()` `policy_overrides` typespec is too permissive

**File:** `lib/lockspire/domain/initial_access_token.ex:31`
**Issue:**

```elixir
@type t :: %__MODULE__{
        ...
        policy_overrides: map() | nil,
        ...
      }
```

`map()` accepts any key/value shape. The resolver expects string-keyed map with values
that are lists of strings (per `override_for/2` contract — only lists pass through). A
malformed `policy_overrides: %{:allowed_scopes => "openid"}` (atom key, string value)
silently bypasses every override (the resolver looks up `"allowed_scopes"` string key,
gets nil, falls back to server allowlist).

For a domain type that's the contract between admin-mint (Phase 28) and resolve-time
(this phase), the typespec should pin the shape. This is a documentation/quality issue,
not a correctness bug — but it makes drift between admin and resolver harder to catch with
Dialyzer.

**Fix:**
```elixir
@type policy_overrides :: %{optional(String.t()) => [String.t()]}

@type t :: %__MODULE__{
        ...
        policy_overrides: policy_overrides() | nil,
        ...
      }
```

A matching invariant test (Phase 28) should round-trip a malformed
`policy_overrides: %{atom_key: "value"}` through `redeem/1` and assert it raises or
returns `{:error, :invalid_policy_overrides}`.

---

_Reviewed: 2026-04-26T12:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
