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

Install Docker with the Compose plugin, Python 3, curl, and jq. Check the local
tooling and immutable lock without printing environment variables or secrets:

```bash
mix lockspire.oidf_conformance --check
```

The check reports missing tools or inputs before downloads and points to the
two exact profile commands:

```bash
bash scripts/conformance/run_phase37_suite.sh
bash scripts/conformance/run_fapi2_suite.sh
```

Raw downloaded helpers, normalized Compose configuration, and suite work stay
in a private temporary directory and are deleted after the run. The retained
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

`.github/workflows/oidf-conformance.yml` runs both repo-native profiles weekly
from the default branch and remains manually dispatchable. The schedule is a
supplemental reliability history and does not block CI or publication. Workflow
permissions are read-only, overlapping runs are canceled, jobs have timeouts,
and only validated `receipt.json` files are retained for a bounded period.

The hosted maintainer lane is manual-only. Select `run_hosted_lane` during a
dispatch when the repository's optional hosted secrets are configured. Those
URLs remain isolated to that job and are never retained in artifacts or job
summaries. Scheduled runs do not request hosted credentials.

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
