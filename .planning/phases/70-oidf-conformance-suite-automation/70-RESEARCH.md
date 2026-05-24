# Phase 70: OIDF Conformance Suite Automation - Research

**Researched:** 2025-05-07
**Domain:** CI/CD Automation, Test Infrastructure, OpenID Conformance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Pivot to resolving CONF-04 (OIDF Conformance Suite Automation) as the primary focus, dropping mTLS.
- Integrate the official OpenID Foundation Conformance Suite into the automated CI pipeline.
- Execute and prove Lockspire's FAPI 2.0 compliance automatically.
- Provide a reproducible local testing lane for developers.

### the agent's Discretion
None explicitly documented beyond standard implementation freedom.

### Deferred Ideas (OUT OF SCOPE)
- Mutual TLS (mTLS, RFC 8705) support.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONF-04 | Setup verifiable automated integration with the OIDF Conformance Test Suite | Identified existing scripts and CI workflows that must be expanded for FAPI 2.0 |
</phase_requirements>

## Summary

The Lockspire project currently has automated OIDF Conformance Suite integration for Phase 37 (`scripts/conformance/run_phase37_suite.sh`), which is triggered in `.github/workflows/oidf-conformance.yml`. For Phase 43/FAPI 2.0, there is only a fast local boundary probe (`scripts/conformance/fapi2-check.sh`) and a JSON plan configuration (`scripts/conformance/fapi2-plan.json`). The actual Docker-based test suite execution for FAPI 2.0 is currently a manual maintainer step documented in `docs/maintainer-conformance.md`.

To satisfy CONF-04, we must introduce a generalized or duplicated test script (e.g., `run_fapi2_suite.sh`) that spins up the OpenID Conformance Suite Docker environment, dynamically configures the suite via Python scripts using `fapi2-plan.json`, executes the FAPI 2.0 test plan against Lockspire, and exports the results to `.artifacts/conformance/fapi2`. Finally, the GitHub Actions CI workflow must be updated to invoke this script automatically and upload the artifacts.

**Primary recommendation:** Create `run_fapi2_suite.sh` modeled closely after the existing `run_phase37_suite.sh`, consuming `fapi2-plan.json`. Ensure the temporary host app created by the script enables the FAPI 2.0 security profile. Finally, add a new job to `.github/workflows/oidf-conformance.yml` that executes this script and uploads the artifacts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OIDF Suite Execution | CI / External Service | Local Machine | The suite is distributed as Docker images and Python scripts executed externally against Lockspire's HTTP endpoints. |
| Test Execution Hook | GitHub Actions | Shell Scripts | `oidf-conformance.yml` drives the execution sequence. |

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Docker Compose | Latest | Orchestrating OIDF Suite containers | Required by OIDF. Already used in Lockspire. |
| Python 3 | 3.10+ | OIDF API interaction scripts | Official scripts provided by OIDF for CI orchestration. |
| GitHub Actions | v4 | Test execution platform | Existing CI mechanism in `.github/workflows/` |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | OIDF Conformance Suite | ✓ | 29.4.x | — |
| Python 3 | Suite Control Scripts | ✓ | 3.14.x | — |
| curl | Suite wait scripts | ✓ | 8.x | — |
| mix | Host application | ✓ | OTP 28 | — |

## Architecture Patterns

### Recommended Project Structure
```
scripts/conformance/
├── run_phase37_suite.sh     # Existing Phase 37 runner
├── run_fapi2_suite.sh       # NEW runner for FAPI 2.0 (To build)
├── phase37-plan.json        # Existing configuration
├── fapi2-plan.json          # Existing configuration
└── fapi2-check.sh           # Existing boundary probe

.github/workflows/
└── oidf-conformance.yml     # To be updated to run FAPI 2.0
```

### Pattern 1: Ephemeral Host App Fixture
**What:** A bash script spins up a temporary HTTP server hosting the Lockspire plug.
**When to use:** In tests, to give the external OIDF Docker container a target to hit.
**Example:**
The `run_phase37_suite.sh` already uses a mix script to start `GeneratedHostAppWeb.Endpoint` dynamically. For FAPI 2.0, we must ensure `Lockspire.Admin.put_security_profile(:fapi_2_0_security)` is set upon initialization within the fixture, or globally configuring it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Running test plans | Custom API interactions with the OIDF suite | Official `run-test-plan.py` provided by OIDF | It correctly polls execution state, saves logs, and reliably captures conformance results. |

## Common Pitfalls

### Pitfall 1: Incorrect Base URLs in Test Plans
**What goes wrong:** The test suite attempts to run against `localhost` instead of `host.docker.internal`, failing to hit the local fixture app.
**Why it happens:** Docker containers map `localhost` to their own loopback interfaces, not the host machine running the temporary Elixir app.
**How to avoid:** Ensure `PROVIDER_BASE_URL` resolves to `http://host.docker.internal:<PORT>` for the Python setup scripts when running locally or in CI.

### Pitfall 2: Forgetting to Enforce FAPI 2.0
**What goes wrong:** The FAPI 2.0 test suite immediately fails because Lockspire does not enforce DPoP or restricts properly.
**Why it happens:** The temporary Elixir app runs with Lockspire's default security profile (`:none`) instead of `:fapi_2_0_security`.
**How to avoid:** Explicitly call `Lockspire.Admin.put_security_profile(:fapi_2_0_security)` or equivalent configuration within the fixture app startup hook inside `run_fapi2_suite.sh`.

## Code Examples

### Updating CI Workflow (`.github/workflows/oidf-conformance.yml`)
Add a new job running FAPI 2.0 conformance based on the existing Phase 37 job structure:
```yaml
  repo-native-fapi2:
    name: Repo-Native FAPI 2.0 Lane
    runs-on: ubuntu-latest
    # Configure postgres service like repo-native-phase37
    steps:
      - name: Check out repository
        uses: actions/checkout@v4
      - name: Set up Elixir and Erlang
        uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{ env.ELIXIR_VERSION }}
          otp-version: ${{ env.OTP_VERSION }}
      - name: Install dependencies
        run: mix deps.get
      - name: Run FAPI 2.0 suite
        run: bash scripts/conformance/run_fapi2_suite.sh
      - name: Upload FAPI 2.0 artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: fapi2-conformance
          path: .artifacts/conformance/fapi2
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Python scripting used for OIDF Suite can interact exactly the same way for FAPI 2.0 as Phase 37. | Summary | The FAPI 2.0 initialization data (provider configuration) might require slightly different structures. |

## Sources

### Primary (HIGH confidence)
- Checked `scripts/conformance/run_phase37_suite.sh` for existing suite runner mechanics.
- Checked `.github/workflows/oidf-conformance.yml` for existing runner integration.
- Checked `scripts/conformance/fapi2-plan.json` for FAPI plan configuration.
- Checked `docs/maintainer-conformance.md` for manual execution knowledge.
- Checked `.planning/phases/70-oidf-conformance-suite-automation/70-CONTEXT.md` for task constraints.
