# v1.48 postmerge acceptance

Status: **accepted main; debug resolved; milestone not yet archived**.

Main `dc3969302152028e2132759eb9edf5a7d260ac39` passed its own hosted CI, no-publish Release, fresh actual local contributor gate, complete historical evidence validation, and canonical root handoff validation. PR145's squash tree equals approved head `bceb05817a3b7c2aa124482aa56fca6c049759a2`; its selected source equals authorized correction `75de906c2571dcc1913520bb46e9d494ed492c96`. No UI work or publication was performed.

## Actual acceptance evidence

- [Actual helper receipt](178-MAIN-ACCEPTANCE.json), SHA256 `c74c4f3715d05852a09a33e92d3535351ed2f02f116e5011233a05fd01016cc2`.
- [Actual owned source capture](178-MAIN-OWNED-SOURCE-MANIFEST.json), SHA256 `ed489fe535e631bfdb3012de79f6c5678a8cdadf80a089c45c2f707f45b368a5`. Architecture15, fast2187 plus2properties, integration261; zero failures. Every captured child group stopped, owned database independently absent after cleanup, original helper/private PostgreSQL groups confirmed closed, data retained.
- [Canonical accepted handoff](178-HANDOFF.json) and [root validation](178-POSTMERGE-MAIN-DELIVERY-VERIFICATION.json).
- [Exact main CI41105446891](https://github.com/szTheory/lockspire/actions/runs/41105446891), attempt1, all seven canonical jobs succeeded. [Release41105446769](https://github.com/szTheory/lockspire/actions/runs/41105446769) succeeded with every publication/terminal publication job skipped.
- Hygiene22PASS/2WARN/0BLOCK. Warnings explicitly retain the existing stopped demo containers and project volumes; no active demo containers were observed and no retained resources were removed.
- [Execution and observation record](178-POSTMERGE-ACCEPTANCE-EXECUTION.json) preserves exact ownership, source, CI, closure, transport and receipt identities. Root protected `lockspire-1.6.1.tar` remains unchanged at `5626784a5699cd17cce2236e3c828ac149af2f8ef901ccfd1b7fcda6145ee9be`.

The receipt and owned capture were copied byte-for-byte from the successful private execution into the canonical paths with owner-only custody, then revalidated in this repository against synchronized HEAD/main/origin/main and authoritative GitHub. They were emitted by the actual helper; the prior attempt5 receipt was not reused.

## Corrections and retained history

[PR143](https://github.com/szTheory/lockspire/pull/143) corrected squash/closed-PR provenance and historical source validation, and made new CI provision its actual checkout. [PR144](https://github.com/szTheory/lockspire/pull/144) corrected a two-second rejection-fixture race and requires its intended rejection. [PR145](https://github.com/szTheory/lockspire/pull/145) binds historical owner workflows to their independently authenticated original execution commit. Each exact correction had explicit user authorization and passed its own hosted gates before merging.

The final checker source passed the full301-test native Python suite, ordinary and squash handoff chains, owner-tampering negatives, real retained-evidence/actual-receipt probe, and native exact-source provisioning. All1079selected inputs remained owned and the package archive/tree stayed byte-identical to the historical package. These qualification records remain separate from the fresh exact-main gate above; see [owner-binding verification](178-POSTMERGE-OWNER-BINDING-VERIFICATION.json).

Original candidate source/review/actual checkout and same-attempt26receipt/64case proof identities remain unchanged in [candidate records](178-CANDIDATE.json) and [hosted gates](178-CANDIDATE-GATES.json). Historical job ownership was authenticated from original checkout logs, retained only in memory during validation. No historical execution was relabelled as current main.

All failed attempts remain retained. Attempt3 passed source tests but failed workflow observation while CI was pending; its exact failing response remains unknown. Attempt4's original assertion remains unknown; a controlled delay independently reproduced the fixture deadline defect, which was corrected and now passes fresh gates. Attempt5's actual helper passed, while handoff exposed isolated-HOME keychain failure, omitted private candidate inputs, then the historical workflow-owner bug. These were separately repaired without restamping old receipts; its separately named [helper snapshot](178-POSTMERGE-ATTEMPT5-HELPER-RECEIPT.json) remains noncanonical history. Intermediate checker/fixture failures and private data are preserved in their linked evidence and execution records.

## Remaining boundary and debt

v1.48 is ready for `$gsd-complete-milestone 1.48`. Milestone archiving has not run. Existing formal-coveragePARTIAL/Nyquistfalse, generic/null/descriptorless advisory classifications, and earlier unknowns remain recorded; the frozen validation draft has not been promoted or rewritten. Supplemental OIDF evidence remains non-certifying.

Milestone closure must preserve immutable175/177/178 source/evidence paths required by the frozen selector and CI, or deliberately validate a migration; do not blindly relocate them. This acceptance qualifies the exact main above; future selected source changes require their own acceptance. The approved UI-quality direction follows the milestone boundary, with its saved Q1–Q10/final-summary constraints and no implementation begun.
