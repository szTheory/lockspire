# Maintainer Conformance Workflow

This guide covers the Phase 41/42 FAPI 2.0 verification workflow for Lockspire. This is a preparatory OIDF lane. Phase 42 wires the lane for Phase 43 consumption, does not claim pass-ready certification, and does not imply support for mTLS or `private_key_jwt`.

1. Run the fast local boundary probe script.
2. Run the OpenID Foundation (OIDF) Conformance Suite for definitive verification.

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

## Step 3: Run the OIDF Conformance Suite

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

The suite ensures strict protocol behavior as tested in `phase37_protocol_strictness_e2e_test.exs`.
Results from `mix conformance.phase37` and this lane are saved to `.artifacts/conformance/phase37`.
browser cookie and third-party cookie configuration is handled per the environment.

## FAPI 2.0 notes

- Select an appropriate `FAPI2` plan in the OIDF UI.
- Use clients and keys that match the phase’s supported FAPI posture.
- Treat `scripts/conformance/fapi2-check.sh` as the quick preflight and the OIDF suite as the release gate.

## FAPI 2.0 OIDF plan (Phase 43)

Use the `fapi2-security-profile-final-test-plan` plan in the OIDF UI, with these variants:

- `fapi_profile`: `plain_fapi`
- `client_auth_type`: `private_key_jwt`
- `sender_constrain`: `dpop`
- `fapi_request_method`: `unsigned`
- `fapi_response_mode`: `plain_response`

The same plan and variants are pinned in `scripts/conformance/fapi2-plan.json` as the canonical upstream OIDF reference.
Lockspire does NOT currently support `private_key_jwt`, so this pinned variant is documentation truth for the upstream plan shape, not an executable claim about the current runtime surface.
The live Docker run remains a manual maintainer step; CI does not gate on it.

Run `mix lockspire.oidf_conformance --validate-env` to verify your environment, dependencies,
and pinned artifacts before launching the suite.
