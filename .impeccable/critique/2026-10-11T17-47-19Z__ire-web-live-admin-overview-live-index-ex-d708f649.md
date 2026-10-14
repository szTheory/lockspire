---
target: Admin Overview
total_score: 24
max_score: 40
na_heuristics: none
p0_count: 0
p1_count: 1
target_identity: "file:/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/overview_live/index.ex"
target_fingerprint: "sha256:41a808b40809418cfe516717ef9bad49c52ab9026e107067948bca915791e82f"
target_path: /Users/jon/projects/lockspire/lib/lockspire/web/live/admin/overview_live/index.ex
timestamp: 2026-10-11T17-47-19Z
slug: ire-web-live-admin-overview-live-index-ex-d708f649
---
## Method and scope

Method: dual-agent (A: overview_design_review · B: overview_detector_browser)

Target: `lib/lockspire/web/live/admin/overview_live/index.ex` and the rendered admin Overview at `http://lockspire-demo.localhost/lockspire/admin/`. Assessment A inspected the supplied Security posture screenshot and a fresh browser view. Assessment B independently ran the Impeccable detector and inspected a separate headed browser session with the live detector overlay. No application data was changed.

Design specificity: Moderately specific. “Orient / Configure / Support / Operate” and the cards map to Lockspire’s staff jobs. The visual language is a familiar admin card grid. Several labels and descriptions expose implementation provenance rather than telling staff what a state means or what action to take.

## Heuristic scores

| # | Heuristic | Score | Evidence |
|---|---|---:|---|
| 1 | Visibility of system status | 3/4 | Counts, active navigation, and Loading / Unavailable states are present. There is no freshness timestamp; a nonzero reuse count has no urgency cue. |
| 2 | Match between system and real world | 2/4 | Relevant records are present, but “reuse incident,” “self-registered client,” “security posture,” PAR, and DPoP assume prior knowledge. |
| 3 | User control and freedom | 3/4 | The page is a read-only hub with direct routes and no trapped flow. |
| 4 | Consistency and standards | 3/4 | Shared card and button patterns are consistent. “Logout failures” differs from “Retryable or discarded logouts.” |
| 5 | Error prevention | 3/4 | No risky actions appear here; ambiguous labels can still mislead, especially “none” and logout status. |
| 6 | Recognition rather than recall | 3/4 | Destinations are grouped and visible, though domain terms rely on prior knowledge. |
| 7 | Flexibility and efficiency | 2/4 | Direct links help; there are no filters, recent records, or other power-user shortcuts. |
| 8 | Aesthetic and minimalist design | 2/4 | The treatment is calm, but duplicate headings and provenance notes add noise. Four cards form a three-plus-one layout at the inspected desktop width. |
| 9 | Error recovery | 2/4 | Unavailable data is distinct from zero in code, but gives little explanation or next step. |
| 10 | Help and documentation | 1/4 | No contextual help explains unfamiliar labels. |
| **Total** |  | **24/40 — Acceptable** | The structure is sound; the page needs clearer priority and meaning. |

## Cognitive load

2 of 8 checks fail: moderate load.

- Pass — Single focus: an orientation hub with one hero action.
- Pass — Chunking: four metrics; each card has at most four fields or three linked rows.
- Pass — Grouping: navigation is grouped into four journeys and information into cards.
- Fail — Visual hierarchy: duplicate Overview labels and repeated source notes compete with counts; a reuse count of 1 looks as neutral as a client count of 5.
- Pass — One thing at a time: separate destinations instead of a multi-step decision.
- Fail — Minimal choices: 10 navigation destinations plus 7 queue links, even though grouping keeps local sections short.
- Pass — Working memory: counts appear beside related links.
- Pass — Progressive disclosure: queue detail stays behind the linked inventories.

## Emotional journey

The grouped navigation and calm layout make the page easy to enter. Nonzero reuse and logout counts suggest problems, but do not explain severity, consequence, or which item to review first. “Security profile: none” may also look alarming without context. The page gives routes but little guidance about what deserves attention now.

## What works

- Grouped navigation maps to actual staff jobs instead of exposing an undifferentiated record list.
- Counts sit near direct links to their supporting inventories.
- The interface is calm, with visible active navigation and focus treatment.

## Prioritized issues

1. **[P1] Give security and delivery counts meaning and priority.** “1 reuse incident” signals a security event without saying what happened or why it matters. Product context says refresh-token reuse revokes the token family. “2 logout failures” combines retryable and discarded deliveries. Use clear labels, state the consequence, and emphasize the existing review destination when the count is nonzero. Keep the queue read-only.
2. **[P2] Remove loaded-state inventory provenance from user-facing copy.** “Measured from client/token/logout inventory” repeats implementation detail and provides no next action. A tooltip would keep low-value information while making it harder to discover. Remove these notes for loaded data; retain useful loading/unavailable feedback and show scope only when it changes interpretation. “Stored server policy” has the same issue unless saved-versus-default state changes a decision.
3. **[P2] Remove the repeated heading and shorten the introduction.** The shell names “Overview”; the hero repeats “OVERVIEW” and “Provider overview.” The paragraph repeats “review” and vaguely says “current authorization activity.” Keep one page title and omit the body or use one short purpose statement.
4. **[P2] Make Security posture describe what is shown.** “Issuer-wide defaults and client overrides that shape protocol behavior” is dense, and this card shows server-policy values rather than client overrides. Use a concrete label such as “Provider security settings,” explain only relevant issuer policy, expand abbreviations when useful, and clarify “Security profile: none.” In the supplied screenshot, “Stored server policy.” sits immediately above the first policy row; add spacing if the note remains.

## Personas

- **Alex, power user:** Grouped navigation and direct links support fast routing. The nonzero reuse count is not prioritized over the “Review clients” hero action. There is no overview filter or recent-record shortcut.
- **Jordan, first-timer:** “Self-registered client,” “reuse incident,” PAR, DPoP, and “security profile: none” assume protocol knowledge. Inventory notes consume space without helping Jordan choose a next step.
- **Sam, accessibility:** Source notes are part of linked-row accessible names (for example, “Refresh reuse incidents 1 Measured from token inventory”). Multiple paragraphs use `role="status"` despite containing non-changing provenance. Focus styling exists; contrast was not measured in Assessment A.

## Detector and browser evidence

The CLI detector exited successfully with exact output `[]` and no rules or locations. It did not confirm that the Elixir/inline HEEx target was scanned, so this is inconclusive rather than a clean scan.

The live browser detector reported two anti-patterns: `low-contrast` at 4.3:1 for `#64748b` text on `#f1f5f9` (highlighting the CLIENTS metric label), and `overused-font` because Inter is used for 89% of text. The overlay script loaded and two visible overlay elements appeared in the headed browser. The low-contrast finding is actionable against the text contrast threshold; the font-frequency finding is not itself evidence of a UX defect and should not prompt an arbitrary secondary font.

## Minor observations

- At the inspected desktop width, three cards occupy the first row and Live operations sits alone below, leaving substantial blank space.
- There is no visible “as of” time, so staff cannot judge freshness while the page stays open.
- Keep the self-registered-client count only if it supports partner onboarding; otherwise it is inventory trivia.
