# Phase 161: Docs & Verified 1.6.0 Release - Pattern Map

**Mapped:** 2026-10-20
**Files analyzed:** 10 (6 modified, 4 new)
**Analogs found:** 9 / 10 (one is operational-only, no code analog)

All analog paths below were confirmed present and tracked (no `.gsd/capabilities` mirrors involved; all are plain repo source).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `docs/operator-admin.md` (add "Key protection" subsection) | docs (reader guide) | static content | same file, sections `## Find the admin task you need` / `## DCR onboarding...` (lines 9-18, 59+) | exact (same file) |
| `test/lockspire/kek_guidance_contract_test.exs` (extend) | test (doc contract) | file-I/O + string assertion | same file (lines 1-61) | exact (same file) |
| `scripts/maintainer/repo_hygiene_check.sh` (relax equality, lines 676-694) | utility / gate script | transform (sed-parse + compare) | same file, `release_train_has_consistent_versions` | exact (same file) |
| `test/support/lockspire/release_proof/workflow_assertions.ex` (de-pin 1.5.1, lines 112-131) | test support | file-I/O + assertion | same file | exact (same file) |
| `test/support/lockspire/release_proof/package_assertions.ex` (`assert_phase_139_release_train_fail_closed!`, lines 114-209+) | test support | file-I/O + negative-case matrix | same file | exact (same file) |
| `.planning/RELEASE-TRAIN.md` (D-12 refresh) | ledger (machine-parsed markdown) | static, regex-parsed | same file, Current Baseline lines 9-12, Previous release line 15 | exact (same file) |
| `scripts/release/verify_public_release.sh` (NEW, optional; `scripts/release/` does not exist) | utility (verification script) | request-response (curl) + transform | `scripts/publish/verify_install_truth.sh`, `scripts/publish/verify_github_release_target.sh` | role-match |
| `161-SAFE02-EVIDENCE.md` (NEW) | evidence doc | batch (commands + outputs) | `.planning/phases/160-admin-key-protection-missing-kek-copy/160-SECURITY.md` / `160-VERIFICATION.md` | role-match |
| `161-RELEASE-EVIDENCE.md` (NEW) | evidence doc | batch | `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md` | role-match |
| `test/lockspire/release/release_automation_contract_test.exs`, `repository_hygiene_contract_test.exs` (re-run; edit only if helpers change signature) | test | file-I/O | callers of the two helpers above | exact |

Not a code file, no analog needed: v1.44 PR body, #122 `BEGIN_COMMIT_OVERRIDE` text, release dispatch commands (see "No Analog Found").

## Pattern Assignments

### `docs/operator-admin.md` (docs, static)

**Analog:** same file. Voice is plain, "admin pages" / "apps" vocabulary, bold route-group labels, short paragraphs, relative links to sibling guides (`supported-surface.md`, `install-and-onboard.md`), no `.planning/` links.

**Link and voice convention** (lines 5, 11-18):
```markdown
For exact capabilities and limits, see the [supported surface](supported-surface.md). ...
The admin pages group common tasks by the same labels used in the interface:
- **Orient**: use `/admin` or `/admin/overview` to see client and security status, key readiness, ...
```

**Placement:** `## ` sections at lines 9, 20, 39, 59, 68, 83, 94, 103, 119; maintainer sections `###` at 123/143. Add `### Key protection` under `## Find the admin task you need` (after line 18) or as a new `##` before `## Mounting the admin surface` (line 20). Keep before line 119 (maintainer section).

**Content to copy:** the proposed table in RESEARCH.md "Key protection subsection" (7 labels verbatim from `lib/lockspire/web/live/admin/keys_live/protection.ex` `value:` fields). Constraints:
- Link the upgrade note as `upgrading/signing-key-encryption.md` (relative to `docs/`; ExDoc warns on broken extras links).
- D-17: say the missing-KEK error "names `mix lockspire.gen.kek`"; do not claim the error links the upgrade guide.
- No `openssl rand`, `elixir -e`, `.planning/`, or version pins.
- Use "key-encryption key" in full before any abbreviation; never "encryption status".

---

### `test/lockspire/kek_guidance_contract_test.exs` (test, doc contract)

**Analog:** same file. Do not create a new file.

**Module shape and helpers** (lines 1-4, 29-33):
```elixir
defmodule Lockspire.KekGuidanceContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  ...
  defp read(rel), do: File.read!(Path.join(@repo_root, rel))

  defp files_containing(needle) do
    Enum.filter(scanned_files(), fn rel -> String.contains?(read(rel), needle) end)
  end
```

**Guidance-site assertion to extend** (lines 6-15, 56-60): add `"docs/operator-admin.md"` to `@guidance_files`:
```elixir
test "every key guidance site names mix lockspire.gen.kek" do
  for rel <- @guidance_files do
    assert read(rel) =~ "mix lockspire.gen.kek", "#{rel} must name mix lockspire.gen.kek"
  end
end
```

**New test style** (plain `assert read(rel) =~ ...`, loop with message, no snapshots). Derive labels from the shipped source so docs cannot drift:
```elixir
test "the operator guide documents the read-only Key protection line" do
  guide = read("docs/operator-admin.md")
  src = read("lib/lockspire/web/live/admin/keys_live/protection.ex")
  labels = Regex.scan(~r/value: "([^"]+)"/, src) |> Enum.map(&List.last/1)
  assert length(labels) >= 7
  for label <- labels, do: assert(guide =~ label, "operator guide missing state: #{label}")
  assert guide =~ "Key protection"
  assert guide =~ "read-only"
  assert guide =~ ~r/Unknown.*not a healthy result/s
  assert guide =~ "upgrading/signing-key-encryption.md"
  refute guide =~ ".planning/"
end
```
Caveat: confirm the regex yields only the seven state labels (other `value:` fields in `protection.ex` would need filtering). Companion contracts that must stay green: `test/lockspire/documentation_contract_test.exs` (lines 44, 65, 85, 247-270: operator-admin is an extra, no `.planning/`) and `test/lockspire/web/live/admin/vocabulary_contract_test.exs` (scans only `lib/lockspire/web/live/admin/**`).

---

### `scripts/maintainer/repo_hygiene_check.sh` (gate script, transform)

**Analog:** same file, lines 647-694. Keep the exact-shape sed regexes and the count checks; change only the final comparison (D-16).

**Existing parsers (keep verbatim)** (lines 647-657):
```bash
release_train_metadata_version() {
  sed -nE 's/^- Release Please version metadata: `([0-9]+\.[0-9]+\.[0-9]+)`( <!-- x-release-please-version -->)?$/\1/p' .planning/RELEASE-TRAIN.md
}
release_train_public_package_version() { ... }
release_train_public_package_source_sha() { ... }
```

**Line to change** (line 693):
```bash
[[ "$public_version" == "$metadata_version" && "$public_version" == "$artifact_version" && "$public_version" == "$tag_version" && "$public_source_sha" == "$artifact_source_sha" ]]
```
Replace the first clause with a semver comparison "metadata >= public" while keeping `public == artifact == tag` and `public_source_sha == artifact_source_sha`. Suggested helper (bash, no new deps), placed above the function:
```bash
version_ge() { [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2" ]]; }   # $1 >= $2
```
then `version_ge "$metadata_version" "$public_version" && [[ "$public_version" == "$artifact_version" && ... ]]`.

**Related caller to re-check** (lines 878-886): `release_train_ver == mix_ver` is still required, so metadata must equal `mix.exs` (this stays true after #121). Also keep the version-pinned docs check (line ~930) in mind: do not pin versions in README/supported-surface.

**Verification pattern:** run `bash scripts/maintainer/repo_hygiene_check.sh --ci` at HEAD (expect 0 BLOCK) and in a scratch `git archive HEAD` copy with the four #121 edits (mix.exs, manifest, CHANGELOG heading, metadata line to 1.6.0; expect 0 BLOCK). Negative cases must still block: metadata < public, public != artifact, SHA mismatch, malformed lines.

---

### `test/support/lockspire/release_proof/workflow_assertions.ex` (test support)

**Analog:** same file, lines 102-141 (`assert_current_release_truth!`). Called from `test/lockspire/release/release_automation_contract_test.exs:11`.

**Hardcoded literals to de-pin** (lines 113-131):
```elixir
assert release_train =~ "Release Please version metadata: `1.5.1`"
assert release_train =~
         "Latest public package: Hex `1.5.1`, published from source `0b56503859b69531ff86d8e4a465a0e75f963594` on 2026-10-08."
assert release_train =~ "protected release run [37795671282](https://github.com/szTheory/lockspire/actions/runs/37795671282)"
assert release_train =~ "public Hex checksum `c13dabdd...`"
assert release_train =~ "[lockspire-v1.5.1](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1)"
```
Replace with regex captures from the file (public version, 40-hex SHA, 64-hex checksum, run id), then assert cross-consistency (tag label == public version; artifact source SHA == public source SHA). Use `Regex.run(~r/^- Latest public package: Hex `(\d+\.\d+\.\d+)`, published from source `([0-9a-f]{40})` on \d{4}-\d{2}-\d{2}\./m, release_train)`. Also relax line 114 to "metadata version >= public version" and keep line 102-103 style invariants (`Paths.mix_version() == Paths.manifest_version()`).

**Keep** the historical-values loop (lines 133-141: previous-release SHA `5d10ce22...`, `33141161205`, `lockspire-v1.5.0`, `30c1f56f...`). When D-12 moves 1.5.1 truth into "Previous release", these remain required, and add the 1.5.1 values to that historical list only if the planner wants them locked.

---

### `test/support/lockspire/release_proof/package_assertions.ex` (test support, negative-case matrix)

**Analog:** same file, `assert_phase_139_release_train_fail_closed!` lines 114-209+.

**Structure to preserve** (lines 114-125, 136-209): derive line variables, then a `cases = [{"label", mutated_source}, ...]` list, each mutation via `String.replace(source, line, mutated)`. Currently the three lines are string literals (lines 116, 118-119, 121-122) and mutations reference literal substrings (`"1.5.1"`, `"1.5.2"`, `"0b565038..."`, `"1b565038..."`, `"c13dabdd..."`, `"lockspire-v1.5.0"`, `"lockspire-v1.5.2"`).

**Change:** derive `metadata_line`, `public_line`, `artifact_line` by `Regex.run`/line-find from `File.read!(release_train_path)` (`Enum.find(String.split(source, "\n"), &String.starts_with?(&1, "- Release Please version metadata:"))`, same for `- Latest public package:` and `- Artifact truth:`), and compute the mutation tokens from the captured version/SHA/checksum (e.g. `bump_patch(version)`, flip first hex char of the SHA). Keep every existing case label. Adjust two cases whose meaning changes under D-16:
- "mismatched Release Please metadata" (line 146-147): metadata `1.5.2` with public `1.5.1` is now allowed; mutate metadata to a version LOWER than public instead (and keep it failing).
- "public package disagrees with Release Please metadata" (157-162): change to public > metadata (fails) or public != artifact (fails).
- Add a positive case: metadata > public with consistent public/artifact/tag/SHA passes the shell gate (run the script against a temp copy as the neighboring cases do; follow the existing runner pattern used further below in the same function).

---

### `.planning/RELEASE-TRAIN.md` (ledger, regex-parsed)

**Analog:** same file lines 9-12 (exact shapes the shell parsers require) and line 15 ("Previous release" bullet style).

**Shapes to preserve** (lines 9, 11, 12):
```markdown
- Release Please version metadata: `1.5.1` <!-- x-release-please-version -->
- Latest public package: Hex `1.5.1`, published from source `<40 hex>` on 2026-10-08. Release Please metadata above is not publication proof.
- Artifact truth: protected release run [<id>](https://github.com/szTheory/lockspire/actions/runs/<id>) for source `<40 hex>` ... verified the public Hex checksum `<64 hex>`, HexDocs, [lockspire-v1.5.1](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1), and clean-room install. Its terminal receipt records `release_verified: true` with no blocker.<free text>
```
Rules: exactly one line each of metadata / public / artifact (counts checked); do not hand-edit the metadata and date lines (Release Please owns them, `x-release-please-*` markers); required standing lines (3, 21, 22, 23) must stay verbatim; every `[..](path)` local link must resolve (`repository_hygiene_contract_test.exs`); no `.planning/` links belong in public guides. Move 1.5.1 truth into a "Previous release" bullet modeled on line 15 (source SHA, CI run, release run, checksum, tag link). Refresh "Current Main Readiness" (line 54) and line 13 "Current-main truth" with 1.6.0 values.

---

### `scripts/release/verify_public_release.sh` (NEW, optional; utility, request-response)

**Analogs:** `scripts/publish/verify_install_truth.sh` (conventions) and `scripts/publish/verify_github_release_target.sh` (reuse as a callee, do not reimplement).

**Header and tool gate** (verify_install_truth.sh lines 1-26):
```bash
#!/usr/bin/env bash
set -euo pipefail
...
INSTALL_TRUTH_DIR=$(mktemp -d -t lockspire-install-truth.XXXXXX)
trap 'rm -rf "$INSTALL_TRUTH_DIR"' EXIT
for cmd in curl jq mix python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not installed."
    exit 1
  fi
done
```

**Hex API fetch + checksum verification** (lines 28-31, 40-47): `jq -er '.artifact.sha256' "$manifest"`, `curl --silent --show-error --location --retry 3 --retry-all-errors -o ... -w "%{http_code}" https://hex.pm/api/packages/lockspire/releases/$EXPECTED_VERSION`, then `python3 scripts/publish/release_artifact.py verify-hex --manifest ... --response ...`.

**HexDocs** (line 67-70): `https://hexdocs.pm/lockspire/$V/supported-surface.html` fetched with `-L` (301 redirect to `lockspire.hexdocs.pm`).

**Argument validation + tag peeling** (verify_github_release_target.sh lines 8-60): `fail()` helper, `[[ "$verified_sha" =~ ^[0-9a-f]{40}$ ]]`, `git ls-remote "$remote_url" "$tag_ref" "$tag_ref^{}"`, `resolved_sha="${peeled_sha:-$direct_sha}"`. Invoke it as `bash scripts/publish/verify_github_release_target.sh lockspire-v1.6.0 https://github.com/szTheory/lockspire.git "$S"`.

**New pieces (no analog; copy from RESEARCH.md "Independent verification script"):** tarball listing via `tar -xOf lockspire-$V.tar contents.tar.gz | tar -tzf -`; expect exactly 3 new tasks `lockspire.doctor.key_encryption`, `lockspire.gen.kek`, `lockspire.keys.reencrypt` and assert `lockspire.test.setup` is ABSENT (D-17, `@package_excluded_files`); SHA-256 of the downloaded outer tarball from `https://repo.hex.pm/tarballs/lockspire-$V.tar` vs API checksum vs manifest; fresh `HEX_HOME`/`MIX_HOME` clean-room host `{:lockspire, "== 1.6.0"}`. Use `python3 -I` for anything reading downloaded JSON and a fresh empty temp dir. Never echo `HEX_API_KEY`; run unprivileged.

If kept inline in the evidence plan instead of a script, no new file is needed and `scripts/` stays unchanged.

---

### `161-SAFE02-EVIDENCE.md` and `161-RELEASE-EVIDENCE.md` (NEW evidence docs)

**Analogs:** `.planning/phases/160-admin-key-protection-missing-kek-copy/160-VERIFICATION.md` and `160-SECURITY.md` (SAFE-02 shape: requirement, command, captured output, verdict); `.planning/milestones/v1.39-phases/143-publish-and-verify-lockspire-1-5-1/143-RESULT.md` (release evidence shape: run IDs, SHAs, checksum, both attempts). Planner should read those two files for headings before writing plans (not excerpted here).

**SAFE-02 commands (from RESEARCH.md, run on final squash SHA):**
```bash
git diff --stat 038df080..<SQUASH> -- mix.exs mix.lock priv/repo/migrations lib/lockspire/protocol config examples compatibility   # expect empty
git diff -U0 038df080..<SQUASH> -- lib | grep -E '^\+' | grep -nE 'Logger\.|:telemetry|IO\.(puts|inspect)|Mix\.shell|inspect\(|raise'
```
Wording (per research): "no change to protocol code, schema, dependencies or security defaults; additive KEK-config feature work only". Note the D-16 repair adds `scripts/` and `test/support/` to the v1.44 diff; say so, since they are outside SAFE-02 forbidden categories. Include the 8-file targeted test list (109 tests) and cite `158/159/160-SECURITY.md`.

---

## Shared Patterns

### Machine-parsed ledger lines are a contract
**Source:** `scripts/maintainer/repo_hygiene_check.sh:647-700` plus `.planning/RELEASE-TRAIN.md:9-12`.
**Apply to:** hygiene script edit, both test-support helpers, RELEASE-TRAIN refresh. Any change to line shape must be made in all four together; helpers must read values from the file rather than literals so the D-12 refresh needs no test edits.

### Doc contract tests: plain string assertions on repo files
**Source:** `test/lockspire/kek_guidance_contract_test.exs:29-33, 56-60`; `test/lockspire/documentation_contract_test.exs:247-270`.
**Apply to:** `docs/operator-admin.md` and any docs touched. `@repo_root` + `read/1`, `assert read(rel) =~ ...`, `refute guide =~ ".planning/"`.

### Release-state side effects are checkpointed, gh/git read-only for the agent
**Source:** CONTEXT.md D-15, RESEARCH.md "Release flow". **Apply to:** all release plans. Checkpoint before: branch push, #122 body edit, v1.44 squash, #121 squash, set/clear `LOCKSPIRE_PHASE143_AUTHORIZED_SHA`, `release.yml` dispatch, `hex-publish` approval, auto-merge decision. Always `gh pr merge --squash`.

### Verification env
**Source:** RESEARCH.md. `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` for `mix docs.verify` and all `MIX_ENV=test mix test` runs (CI parity; local 1.20.4 warnings fail warnings-as-errors).

### Do not touch (SAFE-02 / D-04)
`mix.exs`, `mix.lock`, `priv/repo/migrations`, `lib/lockspire/protocol`, `docs/supported-surface.md`, `.github/workflows/*`, `release-please-config.json`, `.release-please-manifest.json`, `CHANGELOG.md` (Release Please owns it).

## No Analog Found

| File / Artifact | Role | Data Flow | Reason |
|-----------------|------|-----------|--------|
| #122 PR body `BEGIN_COMMIT_OVERRIDE` block | release metadata | PR-body edit | No prior use in repo; follow RESEARCH.md text, entries separated by a blank line, `feat(admin): ... (#122)`, no `BREAKING` |
| v1.44 PR body/title | release metadata | PR | Precedent is PR #131 (`feat(keys): encrypt private signing keys at rest (v1.43)`); read via `gh pr view 131`; honor D-07 (no "every DB-touching task") |
| Tarball content listing step | verification | transform | No existing script lists tarball contents; use RESEARCH.md commands |
| `release.yml` dispatch / variable set / clear | operations | n/a | Procedure only (RESEARCH.md "Publish procedure" step 0-4), no code to copy; no workflow changes |

## Metadata

**Analog search scope:** `scripts/maintainer`, `scripts/publish`, `test/lockspire`, `test/support/lockspire/release_proof`, `docs/`, `.planning/RELEASE-TRAIN.md`, `.planning/phases/160-*`.
**Files read:** CONTEXT.md, RESEARCH.md (full), `kek_guidance_contract_test.exs`, `repo_hygiene_check.sh` (630-720), `workflow_assertions.ex` (95-154), `package_assertions.ex` (95-209), `RELEASE-TRAIN.md`, `verify_install_truth.sh` (1-70), `verify_github_release_target.sh` (1-60), `operator-admin.md` (1-60).
**Pattern extraction date:** 2026-10-20

## PATTERN MAPPING COMPLETE
