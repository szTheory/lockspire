# Phase 161: Docs & Verified 1.6.0 Release - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-19
**Phase:** 161-docs-verified-1-6-0-release
**Mode:** assumptions
**Areas analyzed:** Docs scope, Landing v1.44 & PR #121, Publish & verification, SAFE-02 sweep

## Assumptions Presented

### Docs scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Install/upgrade guides already cover gen.kek and {:system, VAR}; only drift fixes needed | Confident | docs/install-and-onboard.md:145-164, docs/upgrading/signing-key-encryption.md |
| Add Key protection subsection to operator-admin.md with contract test; supported-surface unchanged | Confident | grep: "Key protection" absent in docs/; protection.ex; PRODUCT.md:140-142 |
| keys.reencrypt RepoRunner todo stays deferred | Likely | todo file; SAFE-02 quiet diff |

### Landing v1.44 & PR #121
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Milestone branch + single squash PR like v1.43 #131 | Confident | git status ahead 100; PR #131; RELEASE-TRAIN.md |
| #121 misses v1.40/v1.41 (#122 non-conventional title); fix via commit override | Likely | gh pr view 121; git log; vendored release-please commit.js:376 |
| Manual merge of #121; auto-merge disabled; Dependabot PRs held | Confident | gh workflow list; release-please-automerge.yml:31 |

### Publish & SAFE-02
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse Phase 143 exact-ref procedure; add explicit tarball listing | Confident | release.yml:86-109,207-214; 143-RESULT.md; mix.exs:521-533 |
| SAFE-02 milestone diff = v1.44 range only | Likely | git diff 038df080..HEAD empty for mix.exs/lock/migrations/protocol |

## Corrections Made

No corrections — all assumptions confirmed.

User decisions on escalated items:
- Changelog gap: chose BEGIN_COMMIT_OVERRIDE on merged #122 (recommended).
- Todos: defer both (recommended).

## External Research

Flagged for execution-time check rather than researched now:
- Release Please override on an already-merged squash PR body (verify against vendored commit.js).
- Hex API checksum field / HexDocs exact-version URL unchanged since 1.5.1.
