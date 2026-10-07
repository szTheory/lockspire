# Phase 143: Publish and Verify Lockspire 1.5.1 - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md; this log preserves the analysis and sources.

**Date:** 2026-10-07
**Phase:** 143-publish-and-verify-lockspire-1-5-1
**Mode:** assumptions (recommendations auto-accepted at the user's direction)
**Areas analyzed:** candidate selection and publication authorization; exact artifact identity; public proof; partial-publication recovery; maintainer DX and release evidence

## Assumptions Presented

### Candidate and publication authorization
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Current `main` and its matching CI/hygiene evidence must be re-established at execution time; Phase 142's accepted SHA is only a dated readiness observation. | Likely | `.planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md`; `.github/workflows/release.yml` |
| Keep Release Please auto-merge closed for this cut; use the existing separately authorized exact-SHA dispatch and `hex-publish` approval. | Confident | Phase 142 `142-CONTEXT.md` D-08/D-10; `docs/maintainer-release.md`; `.github/workflows/release.yml`; `.github/workflows/release-please-automerge.yml` |

### Artifact and public proof
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Build, prepublish-test, transfer, re-hash, and publish the same manifest-bound package tar. | Confident | `.github/workflows/release.yml`; `scripts/publish/release_artifact.py`; `test/lockspire/release_artifact_chain_contract_test.exs` |
| Require matching public Hex checksum, exact-version docs, actual GitHub tag target, and public clean-room install before declaring the release fully verified. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `scripts/publish/verify_install_truth.sh` |

### Partial publication and recovery
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| If Hex publishes but a later gate fails, record public presence accurately while keeping release proof/milestone incomplete; preserve each stage's state and recover only using the same SHA and tar. | Likely | `.github/workflows/release.yml` publish/postpublish job conditions; `.planning/ROADMAP.md`; `.planning/RELEASE-TRAIN.md`; `scripts/publish/publish_hex_idempotently.sh` |
| Existing release validation needs the dereferenced Git tag target; `targetCommitish` alone is not sufficient for an existing tag. | Confident | `.github/workflows/release.yml`; [GitHub Releases REST API](https://docs.github.com/en/rest/releases/releases) |

## Corrections Made

No user corrections were requested; the user explicitly asked that the recommendations be followed automatically. Independent research refined the recommendations with two bounded proof gaps: tag-ref verification for existing releases and a durable terminal receipt when publication or later verification fails.

## Research Tradeoffs and Applied Lenses

- A manually authorized exact-SHA dispatch costs a maintainer setup/approval step, but it preserves the exceptional 1.5.1 candidate boundary. Auto-merge or tag-driven publishing is smoother for the normal train but can change the candidate or authorize an old/non-current commit.
- Build-once and publish-the-same-tar is more machinery than ordinary `mix hex.publish --yes`, but it proves that the tested artifact is the published artifact. Phoenix/Plug/Ecto workflows were useful CI comparators; Oban's release alias was a simpler publish comparator, not an exact-byte provenance precedent.
- Rebuilding after a failed publish would make old prepublish evidence ambiguous. A failed post-Hex stage must report the package as publicly present when observed, while keeping the verified-release state and milestone open.
- Maintainer/SRE lens: refresh exact SHA, CI, hygiene, protected environment, authorization variable, active runs, and public state immediately before dispatch; dispatch once because GitHub concurrency retains only one pending run per group.
- Package-consumer lens: verify whole-tar checksum, matching tag target, versioned docs, and clean-room public install. Security lens: keep Hex credentials behind the protected environment and use no raw secrets in receipts. This phase has no UI/visual-design work, so brandbook guidance does not apply.
- Hex Trusted Publishers/OIDC and signed build attestations are useful future options, but adding either to this cut would widen the already-locked release path.

## External Research Sources

- GitHub [deployment environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [manual dispatch](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow), [artifact handoff](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts), and [concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency).
- Hex [publishing guide](https://hex.pm/docs/publish), [`mix hex.publish` task](https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html), and [outer tarball checksum API](https://hex-core.hexdocs.pm/hex_tarball.html).
- GitHub [release REST API](https://docs.github.com/en/rest/releases/releases); Release Please [design and publishing boundary](https://github.com/googleapis/release-please/blob/main/docs/design.md).
- Ecosystem examples: [Phoenix CI](https://github.com/phoenixframework/phoenix/blob/main/.github/workflows/ci.yml), [Plug CI](https://github.com/elixir-plug/plug/blob/main/.github/workflows/ci.yml), [Ecto SQL CI](https://github.com/elixir-ecto/ecto_sql/blob/master/.github/workflows/ci.yml), and [Oban's Hex release alias](https://github.com/oban-bg/oban/blob/main/mix.exs).

## Live Facts to Refresh During Execution

The 2026-10-07 read-only snapshot showed Hex 1.5.0 as latest with no 1.5.1 release, and no GitHub 1.5.1 tag/release. Before dispatch, refresh current remote `main`, its matching CI/hygiene result, authorization/protection settings, active and pending release runs, release metadata, and public Hex/GitHub state. After publication, query the public checksum/docs and dereferenced tag target again. Repository files cannot establish these mutable facts.
