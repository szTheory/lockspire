# Maintainer Conformance

The Phase 37 conformance lane is the narrow proof path for Lockspire's strict OIDC behavior around exact `redirect_uri` validation, `prompt=none`, `max_age`, and `auth_time`. It stays separate from normal PR CI on purpose.

## Command path

Run the deterministic local lane with:

```bash
MIX_ENV=test mix conformance.phase37
```

That command always runs `test/integration/phase37_protocol_strictness_e2e_test.exs` first. The slower OpenID Foundation suite subset only starts after the generated-host proof is green.

## What the local lane does

`scripts/conformance/run_phase37_suite.sh` is the one obvious entrypoint.

It:

1. boots the generated-host Phoenix fixture on a local port
2. downloads the official OpenID Foundation conformance runner helpers and prebuilt Docker compose file
3. runs the checked-in Phase 37 subset from `scripts/conformance/phase37-plan.json`
4. exports proof artifacts under `.artifacts/conformance/phase37`

The checked-in plan is intentionally narrow. It covers the strictness slice the repo publicly claims today and does not claim broad certification coverage.

## Artifact location

The local and hosted lanes both write proof into:

```text
.artifacts/conformance/phase37
```

Expect at least:

- `phase37-plan.json`
- `provider-config.json`
- `plan-strings.txt`
- `run-summary.json`
- `artifact-files.txt`
- exported suite bundles under `.artifacts/conformance/phase37/exports`
- logs under `.artifacts/conformance/phase37/logs`

## Required environment

The local lane needs a working test database plus Docker:

- `LOCKSPIRE_TEST_DB_HOST`
- `LOCKSPIRE_TEST_DB_PORT`
- `LOCKSPIRE_TEST_DB_USER`
- `LOCKSPIRE_TEST_DB_PASSWORD`
- `LOCKSPIRE_TEST_DB_NAME`

Optional local overrides:

- `LOCKSPIRE_PHASE37_PORT`
- `LOCKSPIRE_PHASE37_PROVIDER_BASE_URL`
- `LOCKSPIRE_PHASE37_ARTIFACT_DIR`
- `OIDF_IMAGE_TAG`
- `OIDF_CONFORMANCE_SERVER`
- `OIDF_CONFORMANCE_SERVER_MTLS`

The hosted maintainer lane reuses the same script in hosted mode and additionally requires:

- `LOCKSPIRE_PHASE37_MODE=hosted`
- `LOCKSPIRE_PHASE37_PROVIDER_DISCOVERY_URL`
- `LOCKSPIRE_PHASE37_PROVIDER_BASE_URL` when discovery is served behind a different browser-visible origin

## Browser and cookie caveats

The repo-native lane uses the suite's browser automation against the generated host's `/login` and consent pages. The wider hosted lane is sensitive to browser cookie partitioning and third-party cookie behavior when the maintainer reproduces results outside the repo-native Docker path.

If a hosted run flakes:

- check whether browser cookie isolation changed between runs
- confirm third-party cookie handling did not block the OP session from surviving the callback loop
- compare the hosted behavior against the repo-native artifact bundle before widening any support claim

## Hosted maintainer lane

`.github/workflows/oidf-conformance.yml` defines two non-PR jobs:

- the repo-native Docker-first lane that runs `MIX_ENV=test mix conformance.phase37`
- the broader hosted or staging lane that reruns `scripts/conformance/run_phase37_suite.sh` against a maintainer-provided discovery URL

Use the hosted lane for wider operator confidence, not as contributor CI.
