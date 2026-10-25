# Phase 174: Packaged Proof & Delivery Handoff - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 9 likely implementation/artifact files
**Analogs found:** 9 / 9 (several use focused, role-level rather than exact analogs)

The canonical twelve case IDs and existing source owners remain authoritative. The package evidence index is a planning artifact that joins observations to those IDs; production runner code and its tests must not import or read `.planning` files, so the source PR and CI remain executable without planning documents.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/acceptance/clean_room_saas_journey.py` | acceptance runner / utility | request-response, file-I/O, process lifecycle | same file's `run_boundary`, `run_negative`, `Browser`, and teardown | exact |
| `scripts/acceptance/clean_room/build_provider.py` | fixture builder / config | transform, file-I/O, subprocess | same file's `write_host_runtime` and `prepare_provider` | exact |
| `test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex` | host fixture / service | request-response, transform | same file's `resolve_current_account/2` and `build_claims/2` | exact |
| `test/clean_room/provider_host/lib/clean_room_provider/accounts.ex` | host fixture / model | request-response | same file's `fetch/1` | exact |
| `test/clean_room/provider_host/lib/clean_room_provider_web/controllers/session_controller.ex` | host fixture / controller | request-response | same file's `create/2` and `resume/1` | exact |
| `scripts/acceptance/clean_room/selected_receipts.py` (likely new bounded validator; final name TBD) | utility / validator | transform, file-I/O | `scripts/acceptance/clean_room/lifetime_receipts.py` | role-match; do not weaken its DCR/lifetime contract |
| `test/acceptance/selected_receipt_test.py` (likely new validator tests; final name TBD) | test | transform | `test/acceptance/client_lifetime_receipt_test.py` | exact role/data-flow |
| `.planning/phases/174-packaged-proof-delivery-handoff/174-PROOF-INDEX.json` or equivalent | config / evidence index | transform, file-I/O | phase 171 `171-QUALIFICATION.json` and narrow receipts | role-match; planning-only consumer |
| `docs/supported-surface.md` | documentation | transform | existing supported-surface sections for Phase 37/PAR claims | exact |

The dated delivery handoff, scoped owner reviews, and plan/summary artifacts are planning outputs rather than runtime modules. Follow the development/release/hygiene train and the phase's frozen identity rules; do not make runtime acceptance depend on those artifacts.

## Pattern Assignments

### `scripts/acceptance/clean_room_saas_journey.py` (acceptance runner, request-response)

**Analog:** Same file, existing HTTP journey groups and main lifecycle.

HTTP requests return the wire facts required for assertions: status, normalized headers, and decoded body. Existing helpers validate response status and inspect `Location`; build additional assertions on actual HTTP and safe projections rather than calling Lockspire internals.

**HTTP and response pattern** (lines 71-113, 137-179):

```python
class Browser:
    """A bounded origin-aware cookie jar for the browser side of the journey."""
    def request(self, method, target, data=None, extra_headers=None):
        url = urljoin(self.origin + "/", target)
        parsed = urlparse(url)
        if f"{parsed.scheme}://{parsed.netloc}" != self.origin:
            raise AssertionError(...)
        # Form/JSON encoding, cookies, real HTTPConnection request...
        return {"status": response.status,
                "headers": {key.lower(): value for key, value in pairs},
                "body": raw.decode("utf-8", "replace")}

def require_status(response, status, label):
    if response["status"] != status:
        raise AssertionError(f"{label}: expected HTTP {status}, got {response['status']}"
                             f"{safe_oauth_error_code(response)}")

def redirect(response, label):
    value = response["headers"].get("location")
    if not isinstance(value, str):
        raise AssertionError(f"{label}: missing redirect location")
    # register authorization code/token query values with the redactor
    return value
```

**Scenario shape:** Existing `run_negative` (lines 1029-1083) and `run_boundary`/`run_happy` (around lines 1088-1130) create real provider/client `Browser`s, issue a control request, check status and callback boundary, then inspect safe persisted/client projections. Use a bounded new `--only` group in this runner and assert valid neighboring controls before unsupported or boundary cases. For PAR consent, preserve exact relative consent location and compare the persisted interaction tuple to the pushed values, following the independent-reference control in `test/integration/phase15_par_authorization_e2e_test.exs:234-278`.

**Receipt coupling constraint:** `main` currently accepts only `happy_path`, `boundary`, `lifecycle`, `negative`, `dpop`, and `dcr_lifetime`; `--receipt` is restricted to only `dcr_lifetime` (lines 1332-1380), and the receipt write path emits lifetime-specific cases (lines 1564-1603). Add a separate bounded selected-case receipt/index path or sibling validator with exact fields and IDs. Preserve `validate_lifetime_receipt` unchanged; do not relax its expected scenario set. If no useful existing Python source/test helper is added to CI, do not make CI discover runtime test code through `.planning`.

**Redaction and owned cleanup:** Keep `safe_oauth_error_code`, `Redactor`, safe failure summaries and evidence scan (lines 147-169, 1535-1563); claim and verify the unique run-root owner (lines 116-134), stop only run child processes and drop only their per-run databases. Output only allowlisted booleans/status/header facts and frozen IDs, never raw token, code, cookie or request body. Loopback HTTP is package-host behavior evidence, not public TLS/proxy/browser reachability.

### Package boundary: `package_input.py` + `build_provider.py` (fixture/build utilities, transform and file-I/O)

**Analogs:** `scripts/acceptance/clean_room/package_input.py` and `scripts/acceptance/clean_room/build_provider.py` (both tracked).

`PackageIdentity` (package_input.py:39-58) keeps source revision, archive SHA-256, and extracted tree SHA-256 separate. `build_package` (179-188) builds a local archive and unpacks it. `verify_candidate_input` (229-245) validates archive and extracted tree before host use. `verify_candidate_host` (308-342) checks candidate tree, vendor tree, resolved dependency path, and compiled marker. Preserve these checks; receipt records should carry verified identities rather than recalculate or conflate them.

`build_provider.py` declares host-owned resolver/interaction handler and `known_scopes` in generated config (157-166). The only fixture scope change selected here is adding `email`; keep host accounts, login/session, claims and consent in `test/clean_room/provider_host`, not Lockspire product code. The builder explicitly removes the template `lib` overlay before installer setup and audits host/runtime boundaries (482-505, 551-565). Reuse its generated-host flow and existing identity checks. No source runner/test should access planning index files at runtime.

### Host fixtures: resolver, account, and session controller (host-owned request-response)

**Analogs:** `test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex:8-44`, `accounts.ex:4-9`, `provider_web/controllers/session_controller.ex:5-29`.

`resolve_current_account/2` takes the account from the host session, while `build_claims/2` builds `Claims` from the host account. `Accounts.fetch/1` returns the minimal deterministic fixture record. `SessionController.create/2` writes host session state and redirects through `resume/1`. For the freshness proof, extend this fixture path to provide an explicit integer host authentication time, and allow the requested scopes; retain host ownership of the data and policy. Avoid a public debug route or product seam change.

**Protocol regression source owners:**

- `test/integration/phase37_protocol_strictness_e2e_test.exs:105-123` checks exact redirect mismatch is HTTP 400 with no `Location`; lines 125-177 check prompt-none callback error/state and no login redirect; lines 179-213 verify an integer `auth_time` from the supplied session.
- `test/integration/phase15_par_authorization_e2e_test.exs:92-232` demonstrates required-PAR direct rejection, valid PAR + PKCE flow and consumed-reference replay. Lines 234-278 provide the P171-005 same-test control/candidate pattern and persisted consent equality.
- `test/lockspire/web/authorize_controller_test.exs:639-701` is the closest correction/controller analog for unsupported response mode: establish a valid query-mode control, then assert first-party HTTP 400 and absence of redirect/OAuth error fields. Reference the recorded Phase 172 same-test RED/GREEN; do not rerun the old deliberate-RED qualification probe.
- `test/lockspire/web/discovery_controller_test.exs:96-126` owns truthful mounted discovery metadata; its package observation must not be described as external origin/TLS evidence.

### Selected receipt/index validator (utility, transform/file-I/O)

**Analog:** `scripts/acceptance/clean_room/lifetime_receipts.py:11-15, 38-65, 68-127, 197-229`.

The validator uses exact allowlists for root/scenario/candidate/cleanup fields, strict digest and revision formats, reconciled nonnegative integer counts, duplicate detection, and an exact expected scenario set. Adopt those structural safeguards in a separate selected-case schema, but keep selected package observations narrow and source/package identities distinct. Retain a reference to canonical IDs and owner paths; do not duplicate the qualification ledger or import/read `.planning` from the executable runner. The canonical index itself may live in the phase directory and link IDs to the run receipt.

**Actual validator test pattern:** `test/acceptance/client_lifetime_receipt_test.py:25-53, 55-89, 121-127` uses `unittest`, `TemporaryDirectory`, a canonical valid fixture, then one-field negative mutations for incomplete observations, skipped/missing scenarios, and invalid counts. Mirror that contract-testing approach for the new validator, with positive exact-set/identity validation plus rejection for unknown fields/IDs, missing IDs, mismatched package identity, unsafe values, and false cleanup markers. No close selected-case validator test currently exists; do not claim one is already present.

### Delivery authority and gates (documentation/handoff, request-response/evidence transform)

**Analogs:** `.planning/DEVELOPMENT-TRAIN.md:16-30`, `.github/workflows/ci.yml`, `scripts/maintainer/repo_hygiene_check.sh:419-448`, `.github/CODEOWNERS:1-9`, `CONTRIBUTING.md:5-24`, `docs/supported-surface.md:11-22`.

The development train owns one reviewed milestone PR to `main`; release publication is separate. `.github/CODEOWNERS` assigns all docs, workflows and release surfaces to `@szTheory`, while `CONTRIBUTING.md` says maintained tests/docs and their CI/package consumers are source-of-truth inputs. The hygiene checker validates the exact workflow run and exactly seven required successful jobs: Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, Adoption Demo Smoke. Keep candidate CI, integration, main acceptance and any publication as distinct statuses. Use the repo hygiene acceptance command only after actual synchronized-main delivery. `docs/supported-surface.md` is the canonical public support contract; match it to delivered package behavior and retain stated advisory/isolation boundaries. The current authority is the exact observed protected-main SHA in CONTEXT (`fe38beee987b135e87c99e7aa7f2488b4c8613e8`) until refreshed by the authorized delivery train; do not infer that milestone branch is accepted main.

## Shared Patterns

### Identity and freshness

**Sources:** `scripts/acceptance/clean_room/package_input.py:39-58,229-245,287-342`; `scripts/acceptance/clean_room/lifetime_receipts.py:53-65,68-81`.

Bind each new receipt to the actual source revision and archive/tree identity; preserve separate vendor, resolver and compiled identities from the builder. Candidate CI and synchronized main are later identities. Do not restamp prior evidence at a new revision; rerun/regenerate only affected owners after covered bytes settle.

### Safe observations

**Sources:** `scripts/acceptance/clean_room_saas_journey.py:147-169,1535-1563`; `scripts/acceptance/clean_room/redaction.py:65-151`.

Only persist status, allowlisted headers, selected callback/consent boundary facts, safe projections, IDs and cleanup booleans. Register secrets as they are observed, scan retained evidence, and report failures through the allowlisted summary. Apply this to both generated receipts and logs.

### Resource ownership

**Source:** `scripts/acceptance/clean_room_saas_journey.py:116-134,1396-1404,1541-1563`; `scripts/acceptance/clean_room/package_input.py:95-105`.

Each run uses a fresh marked temporary root, unique database URLs, allocated loopback ports, and owned child processes. Cleanup must verify the marker before dropping only this run's child databases/removing its root. Preserve the named retained worktrees, history and adoption-demo data in the handoff; cleanup authority does not cover them.

### Existing owner provenance

**Sources:** phase 171 frozen qualification IDs, plus Phase 172/173 summaries and source test owners named above.

Use the exact twelve IDs as index keys; retain original case/source/observation/receipt identities and associate A171-003/P171-005 with their actual Phase 172/173 regression owners. Do not create another qualification matrix or make source-level CI depend on `.planning` paths.

## No Analog Found

| File/behavior | Role | Data Flow | Reason |
|---|---|---|---|
| `174-PROOF-INDEX.json` (or chosen equivalent) | evidence index | transform, file-I/O | No existing selected-case package index exists. Use existing IDs and receipt allowlist patterns; keep it a phase artifact, never a runtime dependency. |
| Selected-case package receipt contract/test | validator/test | transform, file-I/O | Existing receipt machinery is lifetime-specific. Reuse its strict validation/test style in a separate bounded contract while preserving its present behavior. |

## Metadata

**Analog search scope:** `scripts/acceptance/`, `scripts/maintainer/`, `test/acceptance/`, `test/integration/`, `test/clean_room/provider_host/`, `test/lockspire/web/`, `.github/workflows/`, `.github/CODEOWNERS`, `CONTRIBUTING.md`, `.planning/DEVELOPMENT-TRAIN.md`, `docs/supported-surface.md`.
**Tracked-source check:** All named source/test/workflow/doc analogs were verified with `git ls-files`; no `.gsd` runtime mirror paths are used.
**Pattern extraction date:** 2026-10-24
