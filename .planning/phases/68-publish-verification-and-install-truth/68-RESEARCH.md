# Phase 68: Publish Verification & Install Truth - Research

**Researched:** 2024-05-30
**Domain:** Package Distribution & Release Verification
**Confidence:** HIGH

## Summary

To ensure Lockspire releases are robust and trustworthy, we need automated mechanisms to verify the published state against the repository's intent. This phase introduces "Publish Verification" (querying Hex.pm for metadata and docs) and "Install Truth" (proving the library can be integrated into a fresh Phoenix project). 

**Primary recommendation:** Implement a post-publish script (`scripts/publish/verify_install_truth.sh`) that asserts Hex metadata via the HTTP API, validates Hexdocs availability, and generates a fresh Phoenix host application to prove dependency resolution and compilation of the released package.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None - CONTEXT.md not present.

### the agent's Discretion
None - CONTEXT.md not present.

### Deferred Ideas (OUT OF SCOPE)
None - CONTEXT.md not present.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PUB-01 | After publish, maintainers can verify that Hex package metadata, docs pointers, and release artifacts match the repo's canonical support contract. | Hex API exposes `latest_stable_version` and metadata. Hexdocs provides reliable HTTP status codes. |
| PUB-02 | Post-publish verification proves that a Phoenix maintainer can discover and install the released Lockspire package using the documented embedded host path without contradictory version or support signals. | `mix phx.new` combined with dynamic `mix.exs` injection proves clean installation without repo context. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Publish Metadata Check | Bash Script / CI | Hex API | Validates the external state matches the internal release intent (e.g., matching version numbers). |
| Docs Verification | Bash Script / CI | HexDocs Server | Proves that the canonical support contract and guides were successfully rendered and hosted. |
| Install Truth Test | Bash Script / CI | Phoenix Generator | Proves the package resolves and compiles correctly in a clean-room consumer environment. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `curl` | > 7.0 | HTTP requests to Hex API | Ubiquitous CLI tool for API interaction |
| `jq` | > 1.6 | Parsing Hex JSON metadata | Standard CLI tool for robust JSON extraction |
| `mix phx.new` | ~> 1.8.5 | Generating clean-room Phoenix apps | The canonical way a user starts a Phoenix project |
| `bash` | latest | Orchestrating verification steps | Decouples the verification logic from the project's own Mix environment |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `bash` | Elixir Script (`.exs`) | Elixir is native, but it runs in the context of the repository's dependencies. A Bash script clearly enforces a clean boundary and avoids mix environment pollution during the "Install Truth" test. |

**Installation:**
(Tools are system-level or available via existing Elixir `mix` installations)
```bash
brew install jq curl
```

**Version verification:** 
```bash
jq --version
curl --version
mix phx.new --version
```

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── conformance/           # Existing OIDC conformance
└── publish/
    └── verify_install_truth.sh # New script to verify hex publish and install
```

### Pattern 1: Clean-Room Install Verification
**What:** Generating a new Phoenix application in a temporary directory, injecting the published package into its dependencies, and running compilation.
**When to use:** Post-publish to verify that no internal paths or missing files prevent a consumer from using the package.
**Example:**
```bash
# Source: Standard ecosystem pattern for package testing
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Ensure the latest phx_new archive is available
mix archive.install hex phx_new --force

# Scaffold a minimal app
mix phx.new host_app --no-assets --no-ecto --no-html --no-mailer
cd host_app

# Inject dependency
sed -i.bak "s/deps() do/deps() do\n      {:lockspire, \"$VERSION\"},/" mix.exs

# Prove it fetches and compiles
mix deps.get
mix compile
```

### Anti-Patterns to Avoid
- **Testing against a local path:** Doing `{:lockspire, path: "../"}` inside the test. This proves nothing about the published Hex artifact. The dependency must be fetched from Hex (`{:lockspire, "1.0.0"}`).
- **Parsing `mix.exs` using regex in Elixir:** For Elixir files, `Code.eval_file` or AST inspection is safer, but for a bash script, reading the version directly via a well-constrained string extraction is acceptable.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parsing Hex API | Custom string matching | `jq` | JSON structures from the API can change formatting; `jq` guarantees structural parsing. |
| Mocking a Phoenix App | Copy-pasting boilerplate | `mix phx.new` | Generators ensure the test app perfectly mirrors what a real maintainer experiences today. |

**Key insight:** The install truth test must mirror exactly what a user types. The closer the script is to the "Getting Started" guide, the more valid the verification.

## Common Pitfalls

### Pitfall 1: Hex API Caching
**What goes wrong:** The script queries the Hex API immediately after publish, but the API or CDN hasn't updated, causing the version check to fail.
**Why it happens:** Fastly CDN caches Hex.pm endpoints and Hexdocs.
**How to avoid:** Implement a polling loop (e.g., check every 10 seconds for up to 2 minutes) when fetching the `latest_stable_version` and the HTTP status of the docs.
**Warning signs:** Spurious CI failures immediately following a `hex.publish` job.

### Pitfall 2: Environment Bleed
**What goes wrong:** The test Phoenix app accidentally uses the local Lockspire directory because of a `MIX_ENV` or path leak.
**Why it happens:** Running the script inside the repository directory without proper isolation.
**How to avoid:** Always generate the test application inside a `mktemp -d` directory, strictly outside the repository tree.

## Code Examples

### Fetching Package Metadata
```bash
# Poll until the new version is available on Hex
PACKAGE="lockspire"
EXPECTED_VERSION=$(grep -o 'version: "[^"]*"' mix.exs | cut -d'"' -f2)

for i in {1..12}; do
  HEX_DATA=$(curl -s "https://hex.pm/api/packages/$PACKAGE")
  LATEST=$(echo "$HEX_DATA" | jq -r '.latest_stable_version')
  
  if [ "$LATEST" == "$EXPECTED_VERSION" ]; then
    echo "Version $EXPECTED_VERSION is published!"
    break
  fi
  echo "Waiting for Hex CDN... ($i/12)"
  sleep 10
done
```

### Verifying Docs and Support Contract
```bash
# Ensure the docs and specific critical pages are live
DOCS_URL="https://hexdocs.pm/lockspire/$EXPECTED_VERSION"
CONTRACT_URL="$DOCS_URL/supported-surface.html"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTRACT_URL")
if [ "$HTTP_STATUS" != "200" ]; then
  echo "Support contract docs not found at $CONTRACT_URL"
  exit 1
fi
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `curl` | Publish Verification | ✓ | > 7.0 | — |
| `jq` | Publish Verification | ✓ | > 1.6 | Use python json module |
| `mix` | Install Truth | ✓ | > 1.15 | — |

**Missing dependencies with no fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash (Custom script) |
| Config file | none |
| Quick run command | `bash scripts/publish/verify_install_truth.sh` |
| Full suite command | `bash scripts/publish/verify_install_truth.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PUB-01 | Verify Hex metadata & docs | e2e | `bash scripts/publish/verify_install_truth.sh` | ❌ Wave 0 |
| PUB-02 | Verify install into Phoenix app | e2e | `bash scripts/publish/verify_install_truth.sh` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Run script locally
- **Per wave merge:** Run script via CI (if integrated)
- **Phase gate:** Script executes cleanly, verifying Hex and Install truth

### Wave 0 Gaps
- [ ] `scripts/publish/verify_install_truth.sh` — covers PUB-01 and PUB-02

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Strict parsing of Hex API responses (via `jq`) |
| V6 Cryptography | no | — |

### Known Threat Patterns for Package Publishing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dependency Confusion | Spoofing | Explicitly verify the version and namespace (`lockspire`) from `https://hex.pm/api/packages/lockspire`. |
| Supply Chain Injection | Tampering | Checksum verification (handled natively by `mix deps.get`). |

## Sources

### Primary (HIGH confidence)
- [Hex API Documentation](https://github.com/hexpm/specifications/blob/main/endpoints.md) - Confirmed endpoint structures for querying package details.
- Mix documentation (`mix help deps`) - Verified that installing via standard `{:lockspire, "VERSION"}` pulls strictly from Hex.

### Secondary (MEDIUM confidence)
- Community standards for "install truth": Common practice observed in Elixir library development for testing generators (e.g. Oban, Phoenix itself) involves isolating to a temp directory and running `mix phx.new`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `curl`, `jq`, and `bash` are the industry standard for CLI-based post-release checks.
- Architecture: HIGH - The clean-room generation perfectly aligns with the required "Install Truth" proof.
- Pitfalls: HIGH - Hex.pm CDN caching is a well-known hurdle for immediate post-publish verification.

**Research date:** 2024-05-30
**Valid until:** 2025-05-30
