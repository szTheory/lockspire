# Phase 143: Publish and Verify Lockspire 1.5.1 - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 6 likely modified files  
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/release.yml` | workflow/config | event-driven, artifact I/O | same workflow, existing publish and postpublish jobs | exact |
| `scripts/publish/release_artifact.py` | utility | transform, file I/O, request-response | same script, manifest and receipt commands | exact |
| `test/lockspire/release_artifact_chain_contract_test.exs` | test | transform, request-response | same test, CLI contract fixtures | exact |
| `test/lockspire/release_workflow_artifact_contract_test.exs` | test | event-driven, file I/O | same test, workflow job/permission assertions | exact |
| `docs/maintainer-release.md` | documentation | maintainer procedure | same runbook, recovery and evidence sections | exact |
| `.planning/RELEASE-TRAIN.md` | planning ledger | batch/update | current baseline and public truth entries | role-match |

## Pattern Assignments

### `.github/workflows/release.yml` (workflow/config, event-driven and artifact I/O)

**Analog:** `.github/workflows/release.yml`

The existing workflow already implements the release lane. Keep Phase 143 additions within its existing job and least-privilege boundaries. Prepublish builds and binds one tar, then transfers the tar, manifest, and bounded receipt (lines 180-208):

```yaml
          python3 scripts/publish/release_artifact.py create \
            --tar "release-input/$package_tar" \
            --source-sha "$VERIFIED_SHA" \
            --output release-input/release-manifest.json
          checksum="$(jq -er '.artifact.sha256' release-input/release-manifest.json)"
          bash scripts/acceptance/run_clean_room_saas_journey.sh \
            --package-tar "release-input/$package_tar" \
            --package-sha256 "$checksum" \
            --only happy_path
```

The protected publisher validates the downloaded artifact before accessing the publish path (lines 249-262):

```yaml
          test "$(find release-input -type f | wc -l | tr -d ' ')" = "3"
          test "$(find release-input -type l | wc -l | tr -d ' ')" = "0"
          package_name="$(jq -er '.artifact.filename' release-input/release-manifest.json)"
          python3 scripts/publish/release_artifact.py verify-local \
            --tar "release-input/$package_name" \
            --manifest release-input/release-manifest.json \
            --source-sha "$VERIFIED_SHA"
```

Extend the existing GitHub release step (lines 301-317) to verify the actual `refs/tags/...` object and peel annotated tags; retain the current create-on-absence behavior. The existing check of `targetCommitish` is insufficient when the tag already exists. Keep receipt generation and artifact upload on an `always()`/failure-capable path, and keep postpublish proof unprivileged. Existing evidence upload shows the bounded-artifact convention (lines 408-455): allowlist JSON files, validate their manifest identity, avoid raw logs, and set explicit retention.

### `scripts/publish/release_artifact.py` (utility, transform and file I/O)

**Analog:** `scripts/publish/release_artifact.py`

The script uses small functions, explicit validation errors, allowlisted JSON fields, and a single CLI parser. The manifest binds version, source SHA, tar filename, byte count, checksum, and runtime (lines 104-120); `verify_local` checks SHA, filename, size, and digest (lines 165-174):

```python
def verify_local(tarball: Path, manifest: dict[str, object], source_sha: str) -> None:
    tarball = regular_tar(tarball)
    artifact = manifest["artifact"]
    assert isinstance(artifact, dict)
    if manifest["source_sha"] != source_sha or SOURCE_PATTERN.fullmatch(source_sha) is None:
        raise EvidenceError("release source SHA mismatch")
    if tarball.name != artifact["filename"] or tarball.stat().st_size != artifact["bytes"]:
        raise EvidenceError("release artifact identity mismatch")
    if sha256(tarball) != artifact["sha256"]:
        raise EvidenceError("release artifact checksum mismatch")
```

Retain typed `Path` inputs, bounded errors, no secret-bearing values, and strict field allowlists when extending receipt support. The current receipt implementation (lines 222-252) only admits `prepublish`/`postpublish` and hardcodes `status: verified`; generalize deliberately to explicit per-stage states and observed public truth, while preserving deterministic JSON output (`write_json`, lines 199-202). CLI failures should continue to print one redacted diagnostic and return nonzero (lines 254-256).

### `test/lockspire/release_artifact_chain_contract_test.exs` (test, transform and request-response)

**Analog:** `test/lockspire/release_artifact_chain_contract_test.exs`

Tests create isolated temporary fixtures and invoke the Python CLI with `System.cmd`; use this for receipt-state, manifest identity, checksum, and any new tag-resolution helper fixtures. Existing fixture setup (lines 10-24) cleans up using `on_exit`. Existing assertions verify exact identity, reject malformed values, and exercise public checksum mismatch (roughly lines 45-129). The uploader test reads captured bytes to prove no rebuild (lines 150-172). Follow the contract style: assert externally observable command results and retained bytes, rather than internal implementation details.

### `test/lockspire/release_workflow_artifact_contract_test.exs` (test, event-driven and artifact I/O)

**Analog:** `test/lockspire/release_workflow_artifact_contract_test.exs`

This suite reads the YAML and helper scripts as text, extracts job blocks, then asserts protected boundaries, artifact names, and forbidden secret/log exposure. For example, the protected publish assertions check the `hex-publish` environment, artifact download, local verification, freeze, and the single credential-bearing path (lines 29-50). Postpublish assertions check read-only permissions, no Hex credential, bounded evidence, and runbook consistency (lines 52-70). Extend this suite for tag-ref peeling and failure/always receipt guarantees; preserve assertions that Hex secrets stay out of proof jobs and raw logs are not retained.

### `docs/maintainer-release.md` (documentation, maintainer procedure)

**Analog:** `docs/maintainer-release.md`

Keep operational instructions ordered by actual gates. The postpublish section documents checksum, docs, clean-room proof, stop/recovery rules, same-artifact constraints, retention, and where to record verified truth (lines 176-203). Update this file if the new receipt schema, partial-publication status, recovery expiry, or tag verification changes maintainer actions. Describe commands and factual decisions; do not turn implementation internals or credentials into operator-facing detail.

### `.planning/RELEASE-TRAIN.md` (planning ledger, batch/update)

**Analog:** `.planning/RELEASE-TRAIN.md`

The current baseline separates release metadata from public truth and ties package checksum, source SHA, CI run, artifact proof, and GitHub release evidence together (lines 7-16). Update only from freshly observed release evidence. If Hex is public but later proof fails, record that public presence and checksum separately from full verification, preserve the blocker and recovery boundary, and leave milestone completion open. Do not preserve stale `1.5.0 latest` wording after confirming `1.5.1` is public.

## Shared Patterns

### Exact artifact identity

**Sources:** `.github/workflows/release.yml:180-208, 249-262`; `scripts/publish/release_artifact.py:104-120, 165-174`  
**Apply to:** workflow changes, publisher/verifier, and release contract tests.

Bind and check the same outer tar bytes at every boundary. Do not rebuild in the protected job. Hex's registry checksum must be compared to the manifest's complete tar SHA-256.

### Protected secret boundary and minimal evidence

**Sources:** `.github/workflows/release.yml:263-300, 389-455`; `test/lockspire/release_workflow_artifact_contract_test.exs:29-70`  
**Apply to:** publication and all receipt/postpublish work.

Keep `HEX_API_KEY` limited to the existing approved publish step. Receipts and public verification must be unprivileged, bounded, allowlisted, and redacted; do not upload raw logs or token-like/copy-once values.

### Truthful partial outcome

**Sources:** `scripts/publish/release_artifact.py:222-252`; `.github/workflows/release.yml:398-455`; `.planning/RELEASE-TRAIN.md:7-16`  
**Apply to:** all failure and success paths.

Represent each stage as passed, failed, not run, or unknown. Record Hex public presence independently from complete release verification. A failed workflow does not establish that Hex did not accept the package.

## No Analog Found

No new subsystem or UI/API surface is indicated. Actual Git tag dereferencing has no existing dedicated helper identified in the phase artifacts; extend the release workflow with a focused helper only if that keeps the tag-object handling testable and does not create a parallel release lane.

## Metadata

**Analog search scope:** `.github/workflows/`, `scripts/publish/`, `test/lockspire/`, `docs/`, `.planning/`  
**Tracked-source gate:** all named analogs verified with `git ls-files`.  
**Pattern extraction date:** 2026-10-07
