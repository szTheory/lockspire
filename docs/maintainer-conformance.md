# Maintainer Conformance Workflow

This is supplemental maintainer evidence. It is not OpenID certification, it is
not a release gate or milestone-closing proof, and it is not a broader
product-support claim. The
canonical Lockspire support contract remains `docs/supported-surface.md`; the
repo-native tests remain the primary executable proof.

## What is pinned

The external inputs are locked in
`scripts/conformance/oidf-suite-lock.json` and validated before use:

- OpenID Foundation conformance suite `release-v5.1.43` at commit
  `16ad152b1b2c0baacd3d2519128340d95deb2b8c`
- the suite archive and four required helper files by SHA-256
- server, nginx, and MongoDB images by immutable `sha256:` digest
- the Phase 37 and FAPI 2.0 plan files by the checksum recorded in each receipt

Mutable tags such as `latest`, branch heads, checksum fallback, and unpinned
container images fail closed. Updating the suite is a reviewed lock update: pin
the new commit, downloads, checksums, and image digests together, then rerun the
input contracts and both profiles.

## Local prerequisites and commands

Install Docker with the Compose plugin, Python 3 with the OIDF runner's
`httpx` and `pyparsing` modules, curl, and jq. Missing Python modules are caught
by the runner preflight and classified as infrastructure failure. Check the
local tooling and immutable lock without printing environment variables or
secrets:

```bash
mix lockspire.oidf_conformance --check
```

The check reports missing tools or inputs before downloads and points to the
two exact profile commands:

```bash
bash scripts/conformance/run_phase37_suite.sh
bash scripts/conformance/run_fapi2_suite.sh
```

Those low-level commands require `LOCKSPIRE_OIDF_PROVIDER_CONFIG` to name a
private JSON configuration file in the format accepted by the pinned OIDF
runner. For the normal repository proof, use the throwaway wrapper instead:

```bash
LOCKSPIRE_OIDF_EPHEMERAL_DB=true \
  bash scripts/conformance/run_ephemeral_oidf_profile.sh phase37
LOCKSPIRE_OIDF_EPHEMERAL_DB=true \
  bash scripts/conformance/run_ephemeral_oidf_profile.sh fapi2
```

The explicit database acknowledgement prevents the wrapper from resetting or
seeding a normal developer database by accident. The wrapper boots the Billingo
adoption app on a disposable database, binds it only for the duration of the
run, generates client keys and provider JSON inside a mode-700 temporary
directory, and deletes the directory and private host log on exit. The pinned
suite nginx container terminates disposable TLS for the provider and forwards
only the demo's OAuth, login, and protected-resource paths through Docker's
explicit `host.docker.internal:host-gateway` mapping. The suite keeps ownership
of its `/test` routes. No generated key, certificate, or provider JSON is a
repository or Actions secret.

For a hosted provider, the private JSON file supplies the provider discovery
URL, client material, and any browser automation needed by that environment;
it is read in place, never copied into retained evidence, and must not be
committed. The checked-in profile JSON selects the suite plan, variants, and
modules. After Compose has reported readiness, Lockspire translates that
selection into the pinned `scripts/run-test-plan.py` CLI and makes its exit
status authoritative.
Lockspire first uses the runner's non-network `--list` mode to catch invalid
plan syntax, missing Python dependencies, or an incomplete verified archive as
an `infrastructure_failure`; a later nonzero suite result is `suite_failure`.

CI pins CPython `3.13.15`, pip `26.2.1`, and the `actions/setup-python` commit.
The runner's complete Python dependency closure is exact-version and
wheel-SHA-256 locked in `scripts/conformance/runner-requirements.lock`; pip runs
with dependency resolution disabled and verifies the installed versions. This
is deliberately stricter than the upstream suite's unversioned local install
instructions.

Raw downloaded helpers, normalized Compose configuration, the runner's full
stdout/stderr, exported suite results, and suite work stay in a private
temporary directory and are deleted after the run. The retained
profile directories are limited to:

```text
.artifacts/conformance/phase37/receipt.json
.artifacts/conformance/fapi2/receipt.json
```

Each schema-versioned receipt contains only the profile, pinned suite
tag/commit, input hashes and image digests, plan name/checksum, Python version,
bounded result names, timestamps, and a status/classification. It cannot
contain URLs, authorization material, cookies, tokens, secrets, passwords, raw
logs, or provider configuration.

## Scheduled and manual runs

`.github/workflows/oidf-conformance.yml` runs the repo-native Phase 37 proof and
both external profiles weekly from the default branch, and remains manually
dispatchable. The two scheduled jobs are self-contained: each gets a fresh
PostgreSQL service, runs the real embedded Billingo host, mints throwaway
provider/client material, and destroys that material after the pinned suite
returns. This preserves the embedded-library boundary because Billingo still
owns accounts, login, consent presentation, branding, and product policy; CI
merely provisions that host automatically.

The hosted maintainer lane is manual-only. Select `run_hosted_lane` during a
dispatch after configuring the separate optional
`LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON` secret. That is the only provider
configuration secret this workflow needs. GitHub exposes it only to the hosted
runner step; Lockspire writes it to a mode-600 file in the private temporary
run directory, removes it from the child-process environment, and deletes it at
exit. A missing or malformed hosted secret fails before suite startup with an
`infrastructure_failure` receipt. The schedule remains a supplemental
reliability history and does not block CI or publication.
Workflow permissions are read-only, overlapping runs are canceled, jobs have
timeouts, and only validated `receipt.json` files are retained for a bounded
period.

## Reading failures

Classify a failed run before treating it as a protocol defect:

- `infrastructure_failure`: immutable download, checksum, Docker, Compose,
  network, startup, or evidence-production failure. Repair the environment or
  reviewed input lock, then rerun the same commit.
- `suite_failure`: the external suite ran and reported a profile result that
  Lockspire did not satisfy. Reproduce against the same suite commit, plan, and
  image digests; correlate with repo-native tests before changing protocol code.
- `integration_only`: the explicit safe skip mode exercised integration and
  receipt plumbing but did not run the external suite. It is never a conformance
  pass.
- `success`: the pinned runner completed and emitted a validated receipt. This
  is still supplemental evidence, not certification.

Never upload a temporary work directory to diagnose a failure. Inspect raw
output only inside the ephemeral job/local run, redact it before sharing, and
retain the bounded receipt as the durable identity of the run.

## Repo-native proof remains first

Before drawing conclusions from the supplemental lane, run the applicable
Lockspire integration and release-readiness tests. The FAPI boundary probe at
`scripts/conformance/fapi2-check.sh` remains a useful targeted HTTP smoke test
against a configured host, but it is not a substitute for either repo-native
behavior proof or formal external certification.
