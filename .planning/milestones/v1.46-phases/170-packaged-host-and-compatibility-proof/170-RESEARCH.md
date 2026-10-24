# Phase 170: Packaged Host and Compatibility Proof — Research

Researched: 2026-10-23. Planning source: `acda9da47b141978a2a05c2ac795058257f93888` on `feat/164-client-secret-lifetimes`.
Method: inline repository research and official documentation, as requested by the user. No subagents, product changes, package publication or remote ref updates. The user chose the recommendation to plan from existing approved requirements/roadmap without a new CONTEXT.md interview.

## Scope and recommendation

Deliver HPROOF-01, HPROOF-02 and HPROOF-03 through the existing clean-room builder, native generated routes, compatibility fixture and required Integration Checks / Minimum Supported Elixir/OTP jobs. Add a bounded browser driver using Chrome DevTools Protocol and Node's built-in fetch/WebSocket; Python standard-library orchestration reuses existing provenance, process and redaction helpers. No npm package, browser automation framework, auth framework or Lockspire dependency is required.

Plan only in this invocation, honoring the user's inline planning request. Keep the persistent auto_advance setting intact; execution is a separate handoff. UI gate returned frontend=true, hasFrontendEvidence=false, block=false: automated proof is the roadmap's explicit UI scope. Preserve existing UI contracts and admin copy; no new UI design or screenshot signoff is needed.

## Existing evidence and gaps

1. Root and clean-room provider locks both resolve Phoenix **1.8.13** / LiveView **1.2.10**. The compatibility fixture pins **1.8.5** / **1.1.28**. Current CI runs root mix.test.fast under minimum BEAM, then only compiles the exact floor fixture. That root command still uses root Phoenix/LiveView locks; it does not prove floor runtime behavior.
2. `scripts/acceptance/clean_room/build_provider.py:prepare_provider` installs from vendor/lockspire, applies maintained host overlays, audits host/package boundaries and binds the compiled candidate. The provider's default OperatorAuthorization intentionally always denies. Keep that default; an explicit proof option may implement synthetic HOST policy in the disposable child only.
3. The provider endpoint has `/live` with session connect_info, but no browser assets or host root layout bootstrapping LiveSocket. The demo endpoint/root layout/priv static script provide the existing pattern. An installed native router by itself does not prove asset/session/path-signing behavior.
4. `clean_room_saas_journey.py:Browser` is an HTTP cookie jar, not JavaScript/browser transport. Existing `admin_route_proof.mjs` is an agent-browser visual lab, not a required unattended CI transport check. Reuse the former's isolation and the latter's local-only/allowlist discipline, without expanding the visual lab into a second framework.
5. `admin_route_integration_test.exs` and `admin_route_separation_test.exs` already test real server lifecycle, cached-response joins, params authorization, all three mount forms, navigation and independent public/consent boundaries. Re-run the same selected test files inside the exact floor Mix project; do not replace those with prose matching or a new narrow imitation.
6. `package_input.py` already exposes prepare_package, package_source, PackageIdentity, verify_candidate_host, bind_compiled_candidate, verify_child and package-tree hashing. Preserve immutable candidate inventory and child path checks; no checkout library/test-support import in the packaged host.

## Implementation decisions

### R-01: Browser-ready disposable host

Extend prepare_provider with explicit keyword-only `admin_proof=False`, `mount_path="/lockspire"` and later `proof_pair="locked"`. Existing callers retain their current behavior. Allow only the normalized proof mounts `/lockspire`, `/teams/ops/identity`, `/`; derive `/admin` at root without a double slash. Use the package installer with that mount; consume its actual emitted Router.Lockspire helper and deny template. Install proof-specific host modules from a single maintained `test/clean_room/provider_host/admin_proof.exs` into the disposable host before final compile; include root component, synthetic authority/controller and current-policy OperatorAuthorization implementation there. This file is acceptance HOST code, never part of the Hex library.

The explicit proof host serves Phoenix and LiveView assets from its resolved dependency applications, a tiny host-owned LiveSocket initializer and a CSRF root layout. Every generated admin/consent URL and runtime issuer must use the selected prefix. Keep a single canonical route declaration; no copied demo route inventory, monkeypatch of library signing or handwritten phx_join payload.

### R-02: Production-quality browser tracer

New `clean_room_admin_journey.py` prepares one actual candidate package, installs one disposable provider, runs migrations, starts it on allocated loopback, launches `test/browser/packaged_admin_proof.mjs`, validates its safe observations and writes a receipt after cleanup. Node uses an existing Chrome binary (`CHROME_BIN`, macOS application path or Linux google-chrome/chromium), a fresh owned profile and a loopback ephemeral debug listener. Require Node >=22.15 with built-in fetch/WebSocket; fail visibly when tools are missing. Use bounded CDP commands and event predicates, not fixed sleeps. No sandbox-disabling Chrome flag by default.

First tracer: host synthetic staff sign-in, actual static response, successful dependency asset loads, WebSocket handshake and an observed successful LiveView join at `/lockspire/admin`, then a real clients-page LiveView navigation. A boolean DOM connection class alone is insufficient: pair it with successful join/frame evidence and host authorization counters. A socket being open does not prove an authorized LiveView join.

### R-03: Matrix and policy boundaries

For each pair, run separate host processes/databases at three mounts. Browser matrix: anonymous and nonstaff HTTP denial; permitted entry; real clients filter event / query patch; overview-to-clients live navigation; existing client detail/edit task navigation; allowed transport disconnect/reconnect; current host policy withdrawal before connected join from cached authorized HTML; denied reconnect; denied native params transition after withdrawal; public or consent live-session transition into admin with no staff identity. Assert denial precedes protected callback/data markers using test-host counters and browser DOM absence. Restore authority between cases.

For the cached-HTML case set a test-only pause flag with CDP Page.addScriptToEvaluateOnNewDocument before navigation. The host-owned proof initializer constructs window.liveSocket but delays connect() when this flag is set. Obtain the authorized static render and loaded assets, change authority through a protected fixture-control request, then call the same real liveSocket.connect(). This preserves the browser's native signing/handshake and never reconstructs signed tokens. Ordinary cases connect automatically. For transport reconnect use the real LiveSocket's documented disconnect/connect path and observe a fresh successful/denied join plus host-hook count. Do not call an HTTP reload a reconnect. Use the client API and DOM events for navigation; distinguish cross-live-session redirect + fresh HTTP/connected entry from same-session navigation.

The synthetic host owns staff IDs, mutable identity/session validity and permission lookup. A signed cookie contains references, not an authorization boolean. Proof-only controls require explicit fixture activation, random per-run secret over loopback and CSRF for browser form writes; control secrets remain out of retained evidence. Keep package default deny behavior and public OAuth/OIDC routes independent. Anonymous discovery and JWKS must return 200 with zero staff-authority decisions, and a representative protocol error must be protocol-shaped, not staff denial.

### R-04: Exact runtime matrix

| Leg | Phoenix | LiveView | CI BEAM | PostgreSQL | Runtime checks |
|---|---|---|---|---|---|
| locked | 1.8.13 | 1.2.10 | Elixir 1.19.5 / OTP 28 (existing job) | existing pinned 16 image | shared lifecycle selector + packaged browser at all 3 mounts |
| floor | 1.8.5 | 1.1.28 | Elixir 1.18.4 / OTP 27 (existing job) | existing pinned 14 image | same lifecycle selector inside floor fixture + same packaged browser at all 3 mounts |

Local command-grounding BEAM: Elixir 1.20.4-otp-29 / OTP 29.1.1, already used in Phase 169. Record ACTUAL runtime strings separately; this local runtime is not evidence for CI BEAM versions. No root dependency upgrade or claim for untested combinations.

Extend the existing floor fixture with the already-used host Bandit dependency and already-used test lazy_html dependency; pin Bandit 1.13.1 and preserve exact Phoenix/LiveView pins. These reuse present repository dependencies, not new library dependencies. Add `config_path: "../../config/config.exs"` so test config/migration task work; load only root test_account_resolver and admin_route_host fixtures from test_helper, then explicitly require the same four root test files from the floor test entry point. The floor fixture may import repository test support: label this server-lifecycle evidence. The packaged provider may not.

For packaged floor runs, create the disposable child manifest with exact floor pins and copy the finalized compatibility lock BEFORE verify_child runs; retain existing vendor path/runtime:false dependency. Isolate child caches by pair and environment. Never rewrite tracked locks during verification. Runtime assertions use Application.spec versions and compare served asset identity with the dependency actually running.

### R-05: Safe receipt contract

New `clean_room/admin_receipts.py` owns strict schema/version, expected-case set and validation. Receipt schema 1: `schema_version`, `run_id` (UUID), `source_revision`, `source_dirty` (boolean), `candidate` (version/archive_sha256/tree_sha256), `pair`, `runtime` (Phoenix/LiveView/Elixir/OTP/Node/Chrome versions), `mount`, `evidence_kind`, `scenarios` (allowlisted ID/result/count/duration records), `cleanup` (owned processes/database/profile/root removal booleans), `result`. No HTML, frame payloads, signed sessions, cookie/header values, URL query credentials, JS error dumps or raw process logs. Keep sensitive observations in memory only until converted to booleans/counts. Round monotonic elapsed times to integer milliseconds and reject booleans-as-integers, negative/nonfinite values, duplicate/missing/unknown scenarios and mismatched pair/source/package bindings. Wrapper supplies a fresh run_id to the runner and validator; reject a stale receipt even when its source/package bytes match. Write atomically; validate again before upload. A failure receipt remains failed even if cleanup later succeeds. Failed cleanup is failed proof.

Use existing Redactor/SentinelSet to scan all retained output; sentinel tests include cookie, CSRF, signed LiveView token, fixture-control token and key material. Capture raw child/Chrome output in private ephemeral files only, suppress generic exception objects, scrub before any tail/excerpt, delete raw files before reporting. A safe fixed-stage diagnostic is enough; generic logging must not become an exfiltration path.

### R-06: Required CI and closure

Add `scripts/ci/run_host_integration_proof.sh --pair locked|floor --receipt-dir DIR` as the canonical local/CI entry point. Each invocation builds the real candidate into an owned temporary path (no glob choosing a stale tar), verifies its checksum/tree, runs the shared lifecycle selector under the requested pair, runs the 3 packaged mounts sequentially and strictly validates receipts. Exit nonzero for any child failure, skipped/missing case, timeout, stale/malformed receipt or cleanup defect. The validator receives independently supplied expected run ID/source/pair/mount/candidate values, not self-declared identity from the receipt. CI source is GITHUB_SHA; local dirty candidate records exact package hashes and an explicit dirty-source marker without claiming a clean commit.

Wire locked into Integration Checks and floor into Minimum Supported Elixir/OTP. Keep existing job names and required triggers. Do not edit remote branch protection or assert it was inspected. Add runtime Node/Chrome preflight, pair-specific cache keys and SHA/pair-bound artifact names; upload only validated safe receipts even on failure, and never let an upload replace a failing step's status. No continue-on-error or paths-only skip. Existing package/lifetime/protocol matrix remains intact. Retain existing job deadlines initially and measure full runtime/headroom; if the new bounded check breaches its explicit budget, report and tune evidence-backed bounds rather than silently accepting or claiming CI success.

## Architectural Responsibility Map

| Capability | Owner/tier | Files |
|---|---|---|
| OAuth/OIDC/admin production behavior | Existing library | No changes planned |
| Browser sessions, staff/current policy, CSRF/layout and fixture controls | Disposable Phoenix host | provider proof fixture + builder |
| Real asset loading, DOM actions, transport join/reconnect observation | Browser + bounded Node CDP driver | packaged_admin_proof.mjs |
| Package provenance, isolated resources and output redaction | Existing Python helpers + new runner/validator | clean_room_admin_journey.py, admin_receipts.py |
| Exact dependency runtime lifecycle | Existing compatibility host | fixture Mix project + shared existing tests |
| Required command invocation and safe artifact handling | Repository CI | run_host_integration_proof.sh, existing ci.yml jobs |

## Validation Architecture

Freeze the commands/matrix in 170-VALIDATION.md. Every new target must be created in its owning task before invocation; no MISSING sentinel or test stub constitutes acceptance. Fast feedback uses Node test runner and Python unittest (built in); real browser/isolated builds take longer, so tracer and full plan gates deliberately run the actual journey rather than substitute unit success. Use warm dependency caches only after provenance checks, fresh databases per leg, sequential shared-fixture tests and finite command/host/browser deadlines. No human-only acceptance is planned.

Planning command grounding: on the source above, the inherited ASDF command running admin_routes_compile_test, admin_route_inventory_test and compatibility_baseline_contract_test returned **16 passed**, exit 0, ExUnit 0.8s. Expected negative compile output occurred; existing Elixir 1.20 type warnings are not newly introduced. This establishes command paths only, not new browser/floor/CI results.

## Probe disposition

Deterministic spec-less probe returned four rows (original JSON retained in 170-EDGE-COVERAGE.json). HPROOF-01/02 unclassified rows remain explicit assumptions A-170-01/02 with no extra invented acceptance predicate. HPROOF-03 boundary maps to absent/duplicate/missing-case/time-budget/stale-source receipts failing closed (Plan 04); precision maps to exact version/hash comparison and nonnegative integer duration validation (Plan 04). Prohibition recall retained host ownership and honest automated evidence boundaries (Plan 05); routine engineering cases became tests above. Canon injection/path traversal/credential exposure threats remain in the security register, not duplicate bespoke prohibitions. No existing Phase 167–169 closure is reopened.

## Open Questions (RESOLVED)

- Browser tool: native CDP with installed Chrome and Node built-ins; no new package.
- Exact-floor runtime: same server tests inside existing floor Mix host, plus packaged floor browser runs using finalized floor lock.
- Mount coverage: default/nested/root, one host process per mount; no simultaneous multi-mount support.
- UI contract: reuse existing surfaces, no product copy/design change; deterministic UI gate does not block this proof-only phase.
- Execution mode: inline planning and inline checking, explicitly requested. Report this limitation; no independent-agent review claim.

## Sources

- Local source: mix.lock, provider_host/mix.exs+lock, compatibility fixture, ci.yml, build_provider.py, package_input.py, redaction.py, processes.py, the demo endpoint/root/initializer, shared route/separation/integration tests and approved v1.46 research.
- [LiveView 1.1.28 testing](https://phoenix-live-view.hexdocs.pm/1.1.28/Phoenix.LiveViewTest.html): process-based lifecycle checks substitute for a browser; they do not exercise browser transport.
- [Chrome headless](https://developer.chrome.com/docs/automation-and-testing/headless): unattended real browser execution.
- [Chrome Network protocol](https://chromedevtools.github.io/devtools-protocol/tot/Network/): WebSocket handshake/frame/close observations. Use only named stable operations and preflight their availability.
- [Node global WebSocket](https://nodejs.org/api/globals.html#class-websocket): built-in client API, stable since 22.15. Record observed Node version, not the latest docs version as a tested value.

No browser/floor/package/remote CI outcome was executed or inferred during research.
