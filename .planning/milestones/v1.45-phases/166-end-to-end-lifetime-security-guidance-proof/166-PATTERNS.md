# Phase 166: End-to-End Lifetime, Security & Guidance Proof - Pattern Map

**Mapped:** 2026-10-21  
**Files analyzed:** 15 likely modified/extended files across tests, acceptance scripts, CI, and guidance  
**Analogs found:** 15 / 15

Phase 162 is the behavior oracle. Prefer extending the existing acceptance/package lab and focused suites; do not create a second harness. Paths below were verified with `git ls-files` and point to tracked sources.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/integration/app_lifetime_packaged_upgrade_test.exs` | test | batch / request-response | same file | exact |
| `test/clean_room/lifetime_upgrade_scenarios.exs` | test | transform | same file | exact |
| `scripts/acceptance/clean_room_saas_journey.py` | utility | request-response / file-I/O | same file | exact |
| `scripts/acceptance/clean_room/client_lifetime_upgrade.py` | utility | batch / file-I/O | same file | exact |
| `scripts/acceptance/clean_room/package_input.py` | utility | file-I/O / transform | same file | exact |
| `scripts/acceptance/clean_room/redaction.py` | utility | transform | same file | exact |
| `test/lockspire/storage/client_lifetime_conformance_test.exs` | test | CRUD / transaction | same file | exact |
| `test/lockspire/storage/client_lifetime_rollback_test.exs` | test | transaction | same file | exact |
| `test/support/client_lifetime_race_helpers.ex` | utility | event-driven / request-response | same file | exact |
| `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` | test | event-driven | same file | exact |
| `scripts/ci/run_test_matrix.sh` | config | batch | same file | exact |
| `.github/workflows/ci.yml` | config | batch | same file | exact |
| `test/lockspire/client_lifetime_guidance_test.exs` | test | transform | same file | exact |
| `docs/upgrading/client-lifetimes.md` | utility (documentation) | request-response | same file | exact |
| `docs/dynamic-registration.md` | utility (documentation) | request-response | same file | exact |

This is the likely touch set implied by D-01–D-19. Planner should add only files needed by identified contract/evidence gaps; PRODUCT vocabulary and supported-surface docs are additional candidates only if changed claims or UI terms require them.

## Pattern Assignments

### `scripts/acceptance/clean_room/package_input.py` (utility, package/file I/O)

**Analog:** same file; it already builds/unpacks and binds package identity.

**Package input and provenance** (`scripts/acceptance/clean_room/package_input.py:187-237`):

```python
tarball, version, checksum = validate_local_tarball(tarball, allowed_root, source.expected_sha256)
unpack_hex_tarball(tarball, package_root)
unpacked_version = package_version(package_root)
if unpacked_version != version:
    raise PackageInputError("Lockspire package filename and metadata versions differ")
entries = inventory(package_root)
return package_root.resolve(strict=True), entries, PackageIdentity(source.kind, version, checksum)
```

**Fresh child and resolved dependency check** (`:250-270`, `:291-344`):

```python
shutil.copytree(template, child_root, ignore=shutil.ignore_patterns("vendor", "_build", "deps"))
shutil.copytree(package_root, vendor_root, symlinks=False)
if inventory(vendor_root) != package_inventory:
    raise PackageInputError(f"{role} package inventory differs from unpacked input")
...
resolved = assert_below(vendor_root, child_root, f"{role} Lockspire dependency")
if resolved != vendor_root.resolve(strict=True) or Path(observed.decode()).resolve() != resolved:
    raise PackageInputError(f"{role} Lockspire provenance does not match its vendor path")
```

Extend this boundary to compare candidate bytes and vendor/extracted content before any leg runs, including same-name changed-byte/stale-state negative coverage. Reuse one `PackageIdentity` across fresh, legacy and custom-store legs. Current checkout branch computes a checksum only if a tar exists (`:209-214`), so make candidate identity explicit for the whole proof rather than relying on filename/version.

### `scripts/acceptance/clean_room_saas_journey.py` (utility, packaged HTTP request-response)

**Analog:** same script. It runs a real host built against the isolated package and gates requests to the configured origin.

**HTTP boundary** (`:75-107`):

```python
url = urljoin(self.origin + "/", target)
parsed = urlparse(url)
if f"{parsed.scheme}://{parsed.netloc}" != self.origin:
    raise AssertionError(f"cross-origin request expected {self.origin}, got {parsed.scheme}://{parsed.netloc}")
...
connection.request(method, path, body=body, headers=headers)
response = connection.getresponse()
raw = response.read()
```

**Candidate setup and lifecycle leg dispatch** (`:928-990`):

```python
selected_source = package_source(args.package_tar, args.hex_version, args.package_sha256)
package_root, _package_inventory, package_identity = prepare_package(run_root, selected_source)
...
if "lifecycle" in args.only:
    run_lifecycle(handoff)
if "negative" in args.only:
    run_negative(handoff)
scan_evidence(run_root, redactor)
```

Add DCR lifetime journeys as a bounded scenario in this runner, using production routes and host-owned recovery. Keep each independent deadline gate observable and return safe scenario outcomes/counts. The runner already centralizes cleanup, sanitized errors and isolated provider/client hosts.

### `test/integration/app_lifetime_packaged_upgrade_test.exs` (test, packaged process)

**Analog:** same file.

**Runner lifecycle and receipt assertions** (`:11-53`):

```elixir
runner = Task.async(fn ->
  System.cmd("python3", [@runner, "--scenario", "all", "--receipt", receipt_path],
    stderr_to_stdout: true
  )
end)
...
assert {output, 0} = result
assert output =~ "provider provenance verified"
assert File.regular?(receipt_path)
```

Mirror the bounded timeout, temp root mode `0700`, `on_exit` cleanup, runner exit assertion, and explicit positive scenario/contract counts. Existing test proves upgrade cutover but mostly CLI/SQL; integrated registration/use/expiry belongs in the HTTP journey.

### `test/clean_room/lifetime_upgrade_scenarios.exs` and `scripts/acceptance/clean_room/client_lifetime_upgrade.py` (test + utility, migration/batch)

**Analog:** these same upgrade fixtures (`test/integration/app_lifetime_packaged_upgrade_test.exs:56-79`).

The integration test asserts both `public` and `tenant_auth`, historical date kinds, old writer shutdown before v1 state, preserved checksums, cleanup, and no old binary after activation. Extend scenario data and receipt assertions for runtime use of representative v0 credentials, unlimited grandfathering, explicit v1 replacement, and preservation of unrelated row authority. Do not replace the existing public/custom-prefix and rollback boundary cases.

### `test/lockspire/storage/client_lifetime_conformance_test.exs` (test, adapter callbacks/transaction)

**Analog:** same file; closest test for documented custom adapter composition.

**Contract and callback execution** (`:13-62`):

```elixir
contract = Repository.lifetime_contract()
assert contract.version == 1
assert contract.transaction_authority == Repository.transaction_authority()
assert {:ok, lifetime} = ClientLifetime.adapt(Repository, contract.transaction_authority)
...
assert {:ok, stored} = adapter.register_client(original)
assert rotation_conforms?(adapter, stored, now)
assert Process.get({adapter, :rotation_clock_called, id}) == true
```

Use the explicit `ClientStore` callbacks (`lib/lockspire/storage/client_store.ex:10-50`) and `TransactionStore` transaction identity/participants (`lib/lockspire/storage/transaction_store.ex:8-19`) to compose a host-owned delegating adapter. Current process-dictionary fixtures prove callback/field conformance only; new packaged proof must select the adapter through normal configuration, persist via PostgreSQL, and demonstrate callbacks on successful issue/replacement.

### `test/lockspire/storage/client_lifetime_rollback_test.exs` (test, transaction rollback)

**Analog:** same file.

**Late audit failure restores row and audit count** (`:103-159`):

```elixir
before = client_row(client_id)
before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
assert {:error, _reason} = Repository.replace_client_registration(..., %{action: nil})
assert client_row(client_id) == before
assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
```

For shared-authority proof, retain the full-row before/after strategy and observe after failure from an independent DB session. Assert all relevant client/grant/token/audit participants and no resurrected authority; the existing focused rollback test is not evidence that a configured external adapter shares that authority.

### `test/support/client_lifetime_race_helpers.ex` (utility, event-driven PostgreSQL coordination)

**Analog:** same helper, used by lifetime wait/race suites.

**Independent sessions and observed blocker** (`:9-15`, `:29-37`, `:87-107`):

```elixir
Sandbox.unboxed_run(repo, fn ->
  backend_pid = backend_pid!(repo)
  send(owner, {:lifetime_race_session, label, self(), backend_pid})
  fun.(backend_pid)
end)
...
blockers = blocking_pids(repo, contender_pid)
if blockers == [expected_holder_pid], do: :ok
```

Keep distinct backend IDs and `pg_blocking_pids` observation before releasing the lock holder. Poll sleeps are only observation retries; decision clocks must advance after the observed wait. Reuse existing focused race suites and add only uncovered schedules.

### `scripts/acceptance/clean_room/redaction.py` and `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` (utility/test, redaction)

**Analog:** same script and telemetry test.

**Register real values, scrub output, safe detector diagnostics** (`redaction.py:60-95`):

```python
def register(self, value: object) -> None:
    if not isinstance(value, str) or not value:
        return
    self._values = tuple(sorted(set((*self._values, value)), key=len, reverse=True))
...
if leaked:
    raise RuntimeError(f"redaction sentinel scan failed for {len(leaked)} secret class(es)")
```

The journey registers cookie and handoff values as they arrive (`clean_room_saas_journey.py:99-106,961-962`). Extend this to generated credentials, encoded/verifier/hash material before rendering diagnostics; keep receipts allowlisted. Existing test requires positive events (`dcr_telemetry_redaction_test.exs:115-123`) before scanning captured telemetry and audit rows, but its assertion currently includes a plaintext fragment and captured payload (`:125-137`). Replace diagnostics with safe event/field/count identifiers and add deliberate-failure evidence that itself remains safe.

### `scripts/ci/run_test_matrix.sh` and `.github/workflows/ci.yml` (config, required batch execution)

**Analog:** active tagged integration matrix in `scripts/ci/run_test_matrix.sh:118-127`; workflow artifact/upload conventions in `.github/workflows/ci.yml` (inspect nearby integration job before changing).

```bash
--integration)
  run_coverage_partition integration "MIX_ENV=test mix do test.setup + test --only integration"
  run_partition clean_room "MIX_ENV=test mix test.clean-room.e2e"
  ;;
```

Wire the required proof into this active path (not the skipped Phase 133 wrapper or the shorter `mix test.integration` selection). Assert positive expected counts and preserve truthful skipped/excluded counts. Use existing artifact conventions and bounded retention for sanitized receipts only.

### `docs/upgrading/client-lifetimes.md`, `docs/dynamic-registration.md`, and `test/lockspire/client_lifetime_guidance_test.exs` (documentation and contract test)

**Analog:** same docs and guidance test. Reconcile claims after evidence lands. Keep app expiry, secret expiry, management expiry, disabled state, host recovery and legacy grandfathering distinct; explain issuance-time snapshots and renewal events, no-overlap/lost-response recovery, maintenance cutover, and post-v1 downgrade limits. The guidance contract test is the preferred pattern for asserting user-facing claims against implementation truth. Add no claim of host-session logout or universal immediate offline JWT revocation.

## Shared Patterns

### Evidence and receipt discipline

**Sources:** `scripts/acceptance/clean_room/package_input.py`, `scripts/acceptance/clean_room_saas_journey.py`, `test/integration/app_lifetime_packaged_upgrade_test.exs`  
Bind each proof leg to source revision and actual package content identity; receipts contain scenario/contract IDs, observed outcomes, counts, and cleanup state. Do not retain raw host roots, configs, credentials, dumps, or process/request traces.

### PostgreSQL ordering and rollback

**Sources:** `test/support/client_lifetime_race_helpers.ex`, lifetime race suites, `test/lockspire/storage/client_lifetime_rollback_test.exs`  
Use independent unboxed sessions, assert distinct backends and observed blockers before release, then inspect durable post-wait state. For rollback, compare rows/audit from an independent observer. Shared Sandbox tasks are not independent-transaction evidence.

### Custom storage boundary

**Sources:** `lib/lockspire/storage/client_store.ex`, `lib/lockspire/storage/transaction_store.ex`, `test/lockspire/storage/client_lifetime_conformance_test.exs`  
Composition must use the documented callbacks and one declared transaction authority with client/grant/token/audit participants. Allow only this explicit public seam in the clean-room audit; keep internals and `test/support` inaccessible to packaged hosts.

### Security defaults

**Sources:** `AGENTS.md:39-47`, existing protocol/security suites listed in `166-RESEARCH.md`  
Reuse current S256, exact redirect, hashed secret, code single-use, refresh family reuse, algorithm and fail-closed tests. Add integration checks only where the lifetime flow crosses a control.

## No New Analog Needed

No new framework, storage backend, conformance SDK, or acceptance harness is indicated. If new package/runtime behavior cannot fit the existing host journey, first document the specific missing seam and keep the implementation bounded to that gap.

## Metadata

**Analog search scope:** tracked `test/`, `scripts/acceptance/`, `scripts/ci/`, `lib/lockspire/storage/`, `docs/`, and `.github/workflows/` sources.  
**Files scanned:** 15 primary analogs plus supporting adapter contract and workflow sources.  
**Pattern extraction date:** 2026-10-21
