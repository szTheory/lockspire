# API Coverage — GitHub repository evidence

> Full coverage by default for the GitHub evidence surface used by Phase 140. Gap closure adds no new external API integration. Every write capability outside the authorized maintenance scope is an explicit opt-out.

| capability | decision | reason |
|---|---|---|
| List open pull requests with authenticated cursor pagination | INTEGRATE | |
| Read each pull request's head, base, state, and changed files | INTEGRATE | |
| Read each pull request's check rollup and job conclusions | INTEGRATE | |
| Read each pull request's exact diff | INTEGRATE | |
| List open issues with authenticated cursor pagination | INTEGRATE | |
| Read canonical CI workflow runs and jobs for an exact SHA | INTEGRATE | |
| Read Release workflow runs and jobs for the same exact SHA | INTEGRATE | |
| Read advertised origin main OID for exact ref comparison | INTEGRATE | |
| Create or edit pull requests or issues | OPT-OUT | D-06 grants no action authority for a concrete remote item; this phase records proposals and evidence. |
| Merge or close pull requests or issues | OPT-OUT | No exact target has separate merge or close authorization. |
| Delete or force-update branches, tags, or worktrees | OPT-OUT | D-05 requires exact-target authority, recovery, worktree safety, and historical-release safety; no deletion is selected. |
| Push a new main candidate | OPT-OUT | A separate blocking-human exact-candidate authorization checkpoint is required after final plan and lifecycle writes. |
| Dispatch protected release publication or publish a package | OPT-OUT | D-14 preserves Release Please and protected exact-ref publication ownership; Phase 140 requires no-publish evidence. |

The read decisions above are already implemented through the existing collector, GitHub CLI queries, and hygiene acceptance path. The new 140-05 through 140-09 plans only repair local evidence and tests and revalidate the same read surface at the final SHA.
