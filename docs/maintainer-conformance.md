# Maintainer Conformance Workflow

This guide is a maintainer workflow doc. It does not define the product contract. For public support truth, start with `docs/supported-surface.md`.

Use the repo-native proof first:

1. Run `mix test test/integration/phase37_protocol_strictness_e2e_test.exs`.
2. Run `mix test test/lockspire/release_readiness_contract_test.exs`.
3. Use the external OIDF or FAPI suite only as optional supplemental corroboration.

This guide covers the Phase 41/42 FAPI 2.0 verification workflow for Lockspire. This is a repo-native-first, preparatory OIDF lane. Phase 42 wires the lane for Phase 43 consumption, does not claim pass-ready certification, does not imply support for mTLS or broader protocol surface beyond the repo-proven embedded-library wedge, and does not turn the external suite into a required release gate or milestone-closing proof.

1. Run the fast local boundary probe script.
2. Run the OpenID Foundation (OIDF) Conformance Suite only if you need optional supplemental maintainer evidence beyond the repo-native proof.

## Prerequisites

- A local host app mounting Lockspire and serving it over HTTP
- A registered Lockspire client you can target during verification
- Docker and Docker Compose for the OIDF suite

## Step 1: Enable the FAPI 2.0 security profile

The probe script assumes the effective `security_profile` is `:fapi_2_0_security` for the client under test.

Enable it either:

- Globally in the admin UI at `/admin/policies/security-profile`
- Or from `iex` in the host app:

```elixir
Lockspire.Admin.put_security_profile(:fapi_2_0_security)
```

If you are testing a per-client opt-in, leave the global profile at `:none` and set the client override to `:fapi_2_0_security` instead.

## Step 2: Run the local boundary probe script

The script sends three live probes:

- Direct `/authorize` without `request_uri`
- `/token` without a `DPoP` header
- `/userinfo` with `Authorization: Bearer ...` and no `DPoP` header

Example:

```bash
LOCKSPIRE_BASE_URL=http://127.0.0.1:4000/lockspire \
LOCKSPIRE_CLIENT_ID=my-fapi-client \
./scripts/conformance/fapi2-check.sh
```

Expected result:

- `/authorize` returns `302` with `error=invalid_request`
- `/token` returns `400` with `invalid_dpop_proof`
- `/userinfo` returns `401` with `invalid_token`

This script is a fast smoke check for the boundary Plug and resource enforcement. It is not a substitute for full standards conformance.

You can also run `mix lockspire.oidf_conformance --validate-env` to validate the prerequisites for this check. It expects `LOCKSPIRE_TEST_DB_HOST` and `OIDF_CONFORMANCE_SERVER` to be set, but it does NOT execute `scripts/conformance/fapi2-check.sh` or send live HTTP probes.

## Step 3: Optional external OIDF Conformance Suite corroboration

1. Clone the suite:

```bash
git clone https://gitlab.com/openid/conformance-suite.git
cd conformance-suite
```

2. Start the suite using the prebuilt images:

```bash
docker-compose -f docker-compose-prebuilt.yml up
```

3. Open `https://localhost:8443/` and accept the local certificate warning.

## Reaching the local Lockspire instance from Docker

If the suite cannot reach your host app, add an `extra_hosts` entry to `docker-compose-prebuilt.yml`:

```yaml
services:
  server:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

Then use these values in the OIDF UI:

- Server URL: `http://host.docker.internal:4000/lockspire`
- Discovery URL: `http://host.docker.internal:4000/lockspire/.well-known/openid-configuration`

## Phase 37 Protocol Strictness

The current shipped strictness claim is backed first by `phase37_protocol_strictness_e2e_test.exs` and `test/lockspire/release_readiness_contract_test.exs`.
Results from `mix conformance.phase37` and this lane are saved to `.artifacts/conformance/phase37` as optional maintainer-only corroboration.
browser cookie and third-party cookie configuration is handled per the environment.

## FAPI 2.0 notes

- Select an appropriate `FAPI2` plan in the OIDF UI.
- Use clients and keys that match the phase’s supported FAPI posture.
- Treat `scripts/conformance/fapi2-check.sh` as the quick preflight and the OIDF suite as optional supplemental evidence, not as a required release gate.

## FAPI 2.0 OIDF plan (Phase 43)

Use the `fapi2-security-profile-final-test-plan` plan in the OIDF UI, with these variants:

- `fapi_profile`: `plain_fapi`
- `client_auth_type`: `private_key_jwt`
- `sender_constrain`: `dpop`
- `fapi_request_method`: `unsigned`
- `fapi_response_mode`: `plain_response`

The same plan and variants are pinned in `scripts/conformance/fapi2-plan.json` as the canonical upstream OIDF reference.
Lockspire's shipped runtime now supports the repo-proven `private_key_jwt` slice described in `docs/supported-surface.md` and `docs/private-key-jwt-host-guide.md`.
This conformance guide is still a maintainer workflow doc, not the product contract: the pinned variant documents the upstream OIDF plan shape while the repo's runtime truth remains defined by the supported-surface docs plus executable proof.
The live Docker run remains a manual maintainer step; CI does not gate on it, it is not part of the public support contract, it is not a required release gate, and it is not milestone-closing proof.

Run `mix lockspire.oidf_conformance --validate-env` to verify your environment, dependencies,
and pinned artifacts before launching the suite.
