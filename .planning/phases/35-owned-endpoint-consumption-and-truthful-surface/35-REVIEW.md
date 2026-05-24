---
phase: 35-owned-endpoint-consumption-and-truthful-surface
reviewed: 2026-04-28T19:54:07Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - lib/lockspire/protocol/protected_resource_dpop.ex
  - lib/lockspire/protocol/dpop.ex
  - lib/lockspire/protocol/userinfo.ex
  - lib/lockspire/web/controllers/userinfo_controller.ex
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/protocol/registration.ex
  - lib/lockspire/protocol/registration_management.ex
  - lib/lockspire/web/registration_json.ex
  - lib/lockspire/web/router.ex
  - lib/lockspire/web/live/admin/policies_live/dpop.ex
  - lib/lockspire/web/live/admin/clients_live/form_component.ex
  - lib/lockspire/web/live/admin/clients_live/show.ex
  - test/lockspire/protocol/protected_resource_dpop_test.exs
  - test/lockspire/protocol/discovery_test.exs
  - test/lockspire/protocol/registration_management_test.exs
  - test/lockspire/protocol/registration_test.exs
  - test/lockspire/web/discovery_controller_test.exs
  - test/lockspire/web/userinfo_controller_test.exs
  - test/lockspire/web/registration_json_test.exs
  - test/lockspire/web/live/admin/policies_live/dpop_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 35: Code Review Report

**Reviewed:** 2026-04-28T19:54:07Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the phase 35 DPoP userinfo path, truthful discovery surface, DCR DPoP mapping, and the new admin DPoP controls against the phase plans and summaries. Two regressions stood out: some DPoP userinfo failures no longer emit the truthful DPoP challenge promised by the phase, and the new client edit workflow can silently clear a client's name when an operator only changes the DPoP override.

## Warnings

### WR-01: Some DPoP userinfo failures fall back to a Bearer challenge

**File:** `lib/lockspire/web/controllers/userinfo_controller.ex:49`
**Issue:** The DPoP challenge branch only recognizes a subset of `reason_code` values. `ProtectedResourceDPoP` can also emit `:invalid_jwt`, `:invalid_dpop_proof`, and `:invalid_access_token_binding` (`lib/lockspire/protocol/protected_resource_dpop.ex:84-100`), but those codes miss the whitelist and drop into the default Bearer challenge. That breaks the phase goal that malformed proof and binding failures return deterministic DPoP-aware `401 invalid_token` responses with truthful `WWW-Authenticate` headers. The current tests cover replay, wrong `ath`, and wrong key, but not malformed proof or invalid binding.
**Fix:**
```elixir
defp www_authenticate_value(%Error{reason_code: reason_code})
     when reason_code in [
            :invalid_dpop_authorization_scheme,
            :missing_dpop_proof,
            :missing_dpop_ath,
            :invalid_dpop_ath,
            :dpop_binding_mismatch,
            :invalid_access_token_binding,
            :dpop_proof_replayed,
            :invalid_dpop_proof,
            :invalid_jwt,
            :invalid_signature,
            :invalid_typ,
            :missing_jwk,
            :invalid_jwk,
            :invalid_claims_options,
            :missing_htm,
            :invalid_htm,
            :missing_htu,
            :invalid_htu,
            :missing_iat,
            :invalid_iat,
            :stale_iat,
            :future_iat,
            :missing_jti
          ] do
  ...
end
```

### WR-02: Saving the new DPoP override can erase the client name

**File:** `lib/lockspire/web/live/admin/clients_live/show.ex:313`
**Issue:** The edit form no longer renders `client[name]` (`lib/lockspire/web/live/admin/clients_live/form_component.ex:64-120`), but `edit_attrs/1` still always includes `name: params["name"]`. `Admin.update_client/2` keeps explicit `nil` values during normalization (`lib/lockspire/admin/clients.ex:281-311`), so submitting the DPoP override form updates the record with `name = nil`. I confirmed this by running the touched LiveView test file: the SQL update during `saving client DPoP override persists change` writes `"name" = NULL`. This is a silent data-loss regression in the existing safe-edit workflow, and the current test only checks `dpop_policy` and `par_policy`, not that existing metadata survives.
**Fix:**
```elixir
defp edit_attrs(params) do
  %{
    allowed_scopes: split_csv(params["allowed_scopes"]),
    dpop_policy: params["dpop_policy"],
    contacts: split_csv(params["contacts"]),
    logo_uri: params["logo_uri"],
    tos_uri: params["tos_uri"],
    policy_uri: params["policy_uri"]
  }
  |> maybe_put(:name, params["name"])
end

defp maybe_put(attrs, _key, nil), do: attrs
defp maybe_put(attrs, key, value), do: Map.put(attrs, key, value)
```

---

_Reviewed: 2026-04-28T19:54:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
