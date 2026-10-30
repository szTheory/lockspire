# Historical workflow-owner correction — ready for integration approval

Status: verified locally; no push or PR for this correction. Canonical accepted-main handoff remains pending.

Candidate: `75de906c2571dcc1913520bb46e9d494ed492c96` on `fix/v148-historical-workflow-owners`, based on authoritative main `7afd18e6b6678576aa52acfc00e32cdbeb958760`. Later evidence/approval commits must preserve these selected source bytes.

## Actual outcome so far

PR144 merged after every canonical premerge job and Dependency Review passed. Its exact main push CI41088094026 passed all seven jobs; Release41088094056 succeeded with publication jobs skipped. The actual exact-main helper then passed its fresh local gate, closed its owned database, and emitted real receiptf99015c7. That receipt is preserved as [the attempt5 helper snapshot](178-POSTMERGE-ATTEMPT5-HELPER-RECEIPT.json), with its actual owned source manifest under a separate snapshot name. These are not canonical accepted-main records.

Complete handoff validation exposed another historical/current-source binding: retained receipt-owner workflow digest matches the original execution commit, but validation read today's CI workflow. The prior CI provisioning correction necessarily changed that file. Private-lab authentication and missing retained-package preparation errors were separately isolated and repaired; no application/database restart or historical receipt restamping was used.

## Concrete correction and verification

Delivery validation now retrieves the workflow from its independently supplied, authenticated runner commit and passes an isolated immutable snapshot to the unchanged owner validator. This applies to local pair composition and uploaded artifact owners. Fresh source acceptance remains separate. The regression advances CI after a squash and verifies the full historical handoff. Adversarial tests reject substituting today's digest, forged runtime/runner claims, and unavailable or nonliteral revisions. Synthetic component templates now use their original pinned workflow context for pair CLI and upload; retained receipts stay unchanged.

The final native Python acceptance suite passed301tests, zero failures/errors/skips/unexpected successes; all five source hashes were unchanged before/after. Both full ordinary/squash chains passed. A local probe of the prepared validator passed the entire real retained-evidence chain and the exact already emitted helper receipt; it is explicitly unintegrated evidence, not new accepted-main status. Native exact-source provisioning passed1079selected inputs with clean source afterward. The package archive/tree remain byte-identical to historical qualified output. Hygiene passed18/0/0; whitespace checks passed. The native provisioning and retained-evidence probes started no application or database. Protected root package and pre-existing demo resources are unchanged.

Evidence: [owner-binding verification](178-POSTMERGE-OWNER-BINDING-VERIFICATION.json). The failed red test, two intermediate fixture failures, original failed attempts, precise owner stack, private-lab repairs, and all known limitations remain recorded. PARTIAL formal-coverage debt remains.

## Requested authority

The [prior fixture proposal](178-POSTMERGE-FIXTURE-TIMING-PROPOSAL.md) authorized one non-force push/PR/conditional merge for source5e524; that operation is complete. This is a different exact source revision. Canonical authorization still names5e524 and has not been repointed.

Approve one non-force branch push, a PR for this exact owner-binding source plus truthful evidence/approval metadata, merge only after required CI passes, synchronize main, then run fresh exact-main acceptance and validate its actual emitted receipt/handoff. Preserve the previous authorization before recording the actual new user approval and candidate in the canonical authorization file. This requires another premerge/postmerge CI cycle and fresh private owned acceptance. Do not reuse attempt5's receipt for the next main revision.

Milestone archiving, release publication, and UI implementation remain separate boundaries. Milestone closure must preserve immutable175/177/178 input paths required by the frozen selector and CI, or explicitly validate a migration; do not blindly relocate them.

## Prepared PR title

fix: bind historical receipt owners to executed workflows

## Prepared PR body

Main acceptance's historical receipt validation rejected a valid owner when later CI provisioning changes altered the current workflow digest. Select the workflow from the independently authenticated execution commit for both local pair composition and uploaded owners, then apply the unchanged owner schema, package, runtime and observation checks. Fresh-main source gates remain separate.

Regression coverage includes a complete squash handoff after a CI edit and rejects current-workflow digest substitution, forged runtime/runner claims and missing/nonliteral revisions. Synthetic component templates explicitly retain their immutable workflow epoch; original receipts are unchanged.

Validation: full native Python suite passes, both complete handoff chains pass, and the prepared checker validates the real retained evidence and original actual helper receipt. Native exact-source provisioning passes with unchanged package archive/tree and clean source afterward. Hygiene/whitespace checks pass. Integration, exact-main hosted CI and a fresh actual helper receipt remain required before canonical acceptance. All earlier failed attempts and PARTIAL coverage debt are retained.

### Merge Danger

**Door:** Two-way.

**Blast Radius:** Delivery receipt provenance.
