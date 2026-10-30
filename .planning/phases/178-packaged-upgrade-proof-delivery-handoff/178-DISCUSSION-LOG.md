# Phase 178: Packaged Upgrade Proof & Delivery Handoff - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-26
**Phase:** 178-packaged-upgrade-proof-delivery-handoff
**Mode:** assumptions; owner-delegated research and recommendation adoption
**Areas analyzed:** package/adopter DX; storage/security/concurrency; evidence/delivery/release integrity

## User Direction

Initial assumptions recommended package proof on both existing dependency pairs, narrow harness/adapter extensions, final review/gates and normal delivery/main acceptance. Before any context was written, the owner requested subagent research through relevant stakeholder lenses, primary sources where possible, adversarial alternatives and coherent recommendations that agents automatically follow. The owner emphasized a small, flat dependency tree, applicable repo prompts and the newer brandbook over older prompt branding. This authorizes adopting scoped technical recommendations without another preference menu. It is not a fabricated exact-head merge or publication approval.

## Assumptions Presented

| Area | Original assumption | Confidence | Evidence |
|---|---|---|---|
| Package proof | Both supported pairs must exercise selected fresh/legacy/rotation/recovery behavior with source/archive/compiled bindings. | Confident | Phase 178 roadmap; package_input.py; Phase 175 contract |
| Harness | Extend existing clean-room helpers and delegated PostgreSQL adapter. | Likely | build_provider.py; lifetime_client_store.ex |
| Review/guidance | Settle inputs, refresh affected owners, complete review/audit and exact candidate contributor/hosted gates. | Confident | Phase 174 precedent; 177 completion; CI workflow |
| Delivery | One milestone PR, fresh postmerge exact-main helper receipt, explicit custody; publication separate. | Confident | DEVELOPMENT-TRAIN.md; Phase 175 context/custody |

## Research Fan-out

Three read-only subagents were explicitly authorized and completed. No product, remote ref, resource or package mutation was delegated.

| Research owner | Scope | Consequential result |
|---|---|---|
| package_adopter_research | Installed input/provenance, dependency pairs, actual predecessor, operator command/RPC DX | External artifact source attribution is misleading; lifetime-upgrade runner is a different proof; floor selection is admin-gated; package adapter lacks maintenance callbacks. |
| storage_security_research | Selected authority, independent PostgreSQL contention, commit/audit/rollback, age, recovery and disclosure | Add bounded installed reruns with real blocker/INSERT witnesses; preserve exhaustive source owners; simulated lost response is not actual network-fault injection. |
| delivery_integrity_research | Exact artifact/candidate/PR checkout/main identities, gate/audit ordering and resource/release custody | Synthetic merge SHA differs from PR head; postmerge acceptance cannot be a premerge audit prerequisite; older tag-publish prompt advice loses to current train. |

## Alternatives and Adopted Synthesis

| Decision | Alternatives considered | Adopted recommendation and tradeoff |
|---|---|---|
| Proof breadth | Reuse source evidence only; repeat full crypto/config/endpoint Cartesian product; bounded installed matrix | Four core cells (both dependency pairs × built-in/delegated storage), selected faults through delegated storage on both pairs, exact-source exhaustive evidence retained. Pays package/composition risk without duplicating every source permutation. |
| Old input | Public 1.6.1 only; pre-verifier accepted main only; distinct controls | Exact accepted pre-verifier main is the primary mixed-code predecessor; required checksum-pinned 1.6.1 producer/adopter control on locked pair has explicitly narrower coverage and existing prerequisite migration path. No unsupported full public-release matrix claim. |
| Harness placement | Grow current large runner; clone harness; thin sibling using shared helpers | Bounded group or thin sibling after checking coupling; share package/host/redaction/resource helpers. Placement remains planner discretion. |
| Configuration/composition | Enable admin mode incidentally; generic pair selection; import source test adapter | Decouple generic pair selection and extend host adapter/allowlist using existing public capabilities with callback witnesses. |
| Rollback proof | Rejected metadata; valid failed INSERT; result-only assertion | Reached-INSERT witness plus authoritative postrollback state, separate outer rollback and reporting-boundary checks. Extra fixture setup buys evidence that the intended boundary executed. |
| Issuance/recovery | Ordinary successful call; synthetic ciphertext edit; actual maintenance race | Real maintenance between authentication/JTI use and issuance guard, same-JTI rejection/fresh-JTI success. Retain existing identity policy. |
| Provenance | Label all inputs with runner SHA; tar checksum only; layered separate identities | Runner/source/archive/tree/vendor/resolved/compiled bindings, independently established old source or unknown; candidate source mapping required. |
| Freshness | Rerun every gate after all bookkeeping; ignore doc changes; scoped frozen inputs | Settle source/harness/guidance, rerun affected proof for covered changes and reconcile evidence-only metadata explicitly. |
| PR/main cycle | Require accepted main before premerge verification; declare main green early; staged honest handoff | Candidate proof/audit and truthful integration-pending handoff first, normal reviewed integration, then append fresh main acceptance/addendum. Actual required proof gaps remain blocking. |
| Release architecture | New provenance/chaos service or tag-publish train; existing controlled helpers | Existing local glue and protected normal train, no new dependency/publication scope. |

## Corrections and Refinements

- Initial broad package assumption now explicitly includes both built-in and declared configured storage for core journeys, plus bounded critical installed fault cases.
- Old-artifact identity and public1.6.1 control were made explicit rather than silently reusing the lifetime migration runner.
- The rollback requirement distinguishes audit prevalidation from an actual failed INSERT, and distinguishes simulated indeterminate response from a network-fault claim.
- Delivery ordering resolves a real pre/postmerge dependency cycle without weakening package, review or candidate gates.
- No owner-selected age, algorithm, endpoint, host seam, support boundary or storage policy was reopened. No UI redesign was warranted.
- Recommendations were adopted under explicit delegation. Individual options were not separately confirmed; no human review/merge approval is invented.

## External Research

Primary sources were used to check consequential boundaries, not to expand scope:

- [Elixir library guidelines](https://elixir.hexdocs.pm/library-guidelines.html): host dependency resolution and narrow library responsibility.
- [Hex build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html): package construction does not publish it.
- [Mix 1.19.5 release](https://mix.hexdocs.pm/1.19.5/Mix.Tasks.Release.html): running-node RPC differs from eval; installed release smoke is warranted for documented commands.
- [PostgreSQL 14 isolation](https://www.postgresql.org/docs/14/transaction-iso.html) and [blocking functions](https://www.postgresql.org/docs/14/functions-info.html): updated row authority after lock wait and direct blocker evidence.
- [Ecto transaction API](https://hexdocs.pm/ecto/3.13.5/Ecto.Repo.html#transact/2): nested success is not a separate durable commit.
- [Ecto SQL 3.13.5 source](https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql.ex): independent query logging/telemetry channels.
- [Fernet](https://cryptography.io/en/46.0.3/fernet/) and [Vault rewrap](https://developer.hashicorp.com/vault/api-docs/secret/transit#rewrap-data): custody rotation preserves authority metadata; no package adoption selected.
- [Keycloak update compatibility](https://www.keycloak.org/server/update-compatibility): explicit code/config upgrade compatibility as a deployment precedent, not Lockspire fleet proof.
- [GitHub workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks), [jobs API](https://docs.github.com/en/rest/actions/workflow-jobs), [merge API](https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request): distinct checkout/head identities, attempts and expected-head protection.

## Methodology and Stop Rule

Applied assumption-first/research-first defaults, least-surprise host seam, high-threshold escalation and one-shot bundles. Prompt lenses covered Elixir library practice, host integration, Ecto/audit, telemetry/security and release/conformance. Current supported-surface and release contracts override older aspirational publish guidance. Further broad research has reached diminishing returns; the remaining questions require concrete fixtures, measured runtime results and live gate observations during implementation.

## Evidence Limits

This discussion performed research/inspection only. No new package journeys, contention tests, release RPC, contributor/hosted CI, milestone audit, integration or main acceptance were executed. Prior results retain their own exact identities and limits. Phase 177 E-09/E-10 and descriptorless advisory flags remain unchanged. Host fleet parity, backups, quiescence, server logging and key destruction remain host responsibilities.
