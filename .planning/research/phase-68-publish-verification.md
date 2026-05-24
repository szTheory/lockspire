# Phase 68 Research: Publish Verification & Install Truth

## 1. Possible Technical Approaches

To satisfy **PUB-01 (Metadata/Docs Truth)** and **PUB-02 (Install/Discovery Truth)**, we must verify the artifact *after* it crosses the Hex.pm boundary.

### Approach A: Automated Hex API & HexDocs Probing (Scripted Verification)
*   **What it is:** A custom Mix task (e.g., `mix lockspire.release.verify <version>`) that queries the Hex API (`hex.pm/api/packages/lockspire`) and HexDocs (`hexdocs.pm/lockspire`) to assert that the description, links, licenses, and docs pointers exactly match the repo's canonical `mix.exs` and `docs/supported-surface.md`.
*   **Pros:** Fast, objective, highly automatable. Instantly proves PUB-01 without manual clicks.
*   **Cons:** Only proves the *metadata* is correct, not that the actual code works or that the tarball contains all necessary files.
*   **Idiomatic Elixir:** Using built-in `httpc` or a lightweight script in `mix.exs` aliases or a maintainer task is very common.

### Approach B: End-to-End Phoenix Smoke Test Workflow (The "Gold Standard" for Install Truth)
*   **What it is:** A GitHub Actions workflow that runs *after* a successful publish. It creates a brand new Phoenix application (`mix phx.new`), injects `{:lockspire, "<version>"}`, runs `mix deps.get`, executes the Lockspire installer (`mix lockspire.install`), and boots the host app to assert it doesn't crash.
*   **Pros:** Absolutely proves PUB-02. It tests the *published Hex artifact*, not the local source code.
*   **Cons:** Slower to execute. Requires maintaining a miniature Phoenix generation script in CI.
*   **Lessons Learned (Ecosystem Footgun):** A notorious footgun in Elixir library development is misconfiguring the `:files` key in `mix.exs` `package/0`. A maintainer will test locally, publish, and users will crash because `.eex` templates or `priv/` directories were silently excluded from the Hex tarball. An E2E test using the *published* package is the only bulletproof way to catch this. Libraries like `Oban` and `Phoenix` rely heavily on generator integration tests for this exact reason.

### Approach C: Manual Maintainer Runbook Verification
*   **What it is:** Adding a checklist to `docs/maintainer-release.md` instructing maintainers to manually verify Hex and test installation.
*   **Cons:** Highly prone to human error, friction-heavy, and violates the developer ergonomics goal of "don't make me think".

---

## 2. Synthesis and Tradeoff Analysis

When considering the Lockspire vision (embedded, zero-surprise, high-assurance OAuth/OIDC), a manual runbook (Approach C) is insufficient. We need to mechanically prove that what we shipped is what we promised.

The primary tradeoff between A and B is speed vs. depth.
*   **A (API Checks)** is fast but shallow.
*   **B (Smoke Test)** is slow but deep.

In the Elixir/Phoenix ecosystem, excellent Developer Experience (DX) means the generators *always work* and the documentation is *always live*. If a Phoenix maintainer tries to install Lockspire and it fails because a `priv/template` was missing in the Hex tarball, trust is immediately lost.

**Lessons from other ecosystems (npm, crates.io):** Successful libraries often employ a "verify-published-artifact" CI step. They download the tarball exactly as a user would and run it. This principle of least surprise dictates that we must test the user's exact golden path.

---

## 3. Final One-Shot Architectural Recommendation

To perfectly satisfy PUB-01 and PUB-02 cohesively, idiomatic to Elixir, and with exceptional maintainer DX, I recommend a **Hybrid Automated Verification Strategy**. We should implement this as a single, unified GitHub Actions workflow called **"Post-Publish Verification"**.

### Step 1: The `mix lockspire.release.verify` Maintainer Task (For PUB-01)
Create a new maintainer-only Mix task (`lib/mix/tasks/lockspire/release.verify.ex`).
*   **What it does:** It takes a version number, polls the Hex API to ensure the version exists, and asserts that the `links` (GitHub, Docs) and `description` match our canonical truth. It then pings `hexdocs.pm/lockspire/<version>/readme.html` to ensure docs are successfully rendered and published.
*   **Ergonomics:** Provides beautiful, colorized console output. This is satisfying to run locally and useful in CI.

### Step 2: The E2E Smoke Test Script (For PUB-02)
Create a standalone shell script (`scripts/conformance/verify_install.sh`) that acts as a mock Phoenix developer.
*   **What it does:**
    1. Installs the `phx_new` archive.
    2. Runs `mix phx.new smoke_test --no-ecto --no-mailer`.
    3. Appends `{:lockspire, "== <version>"}` to `mix.exs`.
    4. Runs `mix deps.get`.
    5. Runs the Lockspire installer.
    6. Runs `mix compile` and boots it to ensure Lockspire mounted correctly.
*   **Why:** This completely eliminates the missing-file tarball footgun and proves the discovery and install path for the end-user.

### Step 3: The Unified GitHub Actions Workflow
Create `.github/workflows/verify-publish.yml`.
*   **Trigger:** Triggered by `workflow_dispatch` initially, or automatically via `workflow_run` triggered by the successful completion of the `hex-publish` job in the `release.yml` workflow.
*   **Execution:**
    1. Runs `mix lockspire.release.verify <version>`.
    2. Runs `scripts/conformance/verify_install.sh <version>`.
*   **Outcome:** If this workflow is green, the maintainer has cryptographic, automated proof that the release is out, the metadata is perfect, the docs are live, and a fresh Phoenix app can install it flawlessly.

### Why this is the perfect recommendation:
1. **Zero Guesswork:** The maintainer merges the release PR, the publish workflow runs, and then the verification workflow runs. The maintainer just looks for a green checkmark.
2. **Ecosystem Idiomatic:** Generating a throwaway Phoenix app in CI to test generator output is a deeply respected pattern in the Elixir community.
3. **Architectural Cohesion:** It perfectly separates the *act of publishing* (trusted, secret-holding lane) from the *act of verifying* (public, unprivileged lane downloading from Hex).
4. **Resiliency:** By putting this in a CI workflow that runs *against Hex.pm*, we test the actual global state of the package manager, not our local git repository.