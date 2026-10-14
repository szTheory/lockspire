---
target: Lockspire admin UI
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "file:/Users/jon/projects/lockspire/lib-lockspire-web-live-admin"
timestamp: 2026-10-12T19-06-45Z
slug: lib-lockspire-web-live-admin
---
# Impeccable critique: Lockspire admin UI

## Assessment

Independent Assessment A scored the pre-follow-up UI 28/40 across Nielsen's ten heuristics. Two findings were fixed during this pass: the P1 conflict between active and unrevoked refresh-token counts, and the duplicate “App registration” label for two destinations. The 28/40 score is retained as the reviewer's pre-fix score; the UI was not rescored after these fixes.

## Scores

| Heuristic | Score |
|---|---:|
| Visibility of system status | 3/4 |
| Match between system and real world | 3/4 |
| User control and freedom | 3/4 |
| Consistency and standards | 3/4 |
| Error prevention | 3/4 |
| Recognition rather than recall | 3/4 |
| Aesthetic and minimalist design | 3/4 |
| Error recovery | 3/4 |
| Flexibility and efficiency | 2/4 |
| Help and documentation | 2/4 |
| **Total** | **28/40** |

## Strongest areas

The overview puts review-worthy security events first and explains their consequences. Revocation controls distinguish one token from an entire refresh-token family and confirm the scope of each action. Restrained styling, active navigation, and readable status labels support scanning.

## Findings

### P1 — Token-family status count conflict — resolved

A reused refresh-token detail counted unrevoked records as “active,” showing one active token while its family summary reported zero active tokens. The family revoke action was offered despite no active family token remaining. The UI now uses the active status count for its summary and action availability, describes a reused token as no longer active, and disables token/family revocation when the affected token or family has no active tokens. The exact demo state was verified live after the fix.

### P2 — Registration navigation labels are ambiguous — resolved

The main navigation and the nested DCR policy navigation both said “App registration,” despite opening different workflows. The nested policy tab now says “Registration rules.”

### P2 — Activity queues are hard to investigate — remaining

Activity queues lack useful search and focused filters, leaving power users to scan records with opaque IDs. Pending interactions do not explain that the host app owns login and consent. Add targeted pivots and a concise explanation of where the next step occurs, while keeping these queues read-only.

### P2 — Activity status groups are dense — remaining

The logout queue presents seven separate status counts; interactions and device authorization show five each. Group the most actionable states and let users inspect the remaining states in the records.

## Experience assessment

Cognitive load is moderate on settings and activity screens. Registration rules combine several allowlists with three expiry settings; section grouping and a review summary help. The overview creates a clear triage path, and confirmation copy adds confidence before consequential actions. Trust previously dropped on the token reuse page because the counts disagreed; that contradiction is now fixed. Pending activity can still feel unresolved when the interface does not say who owns the next step.

Power users need a quicker way to find a specific activity record. First-time support staff may confuse protocol terms such as OAuth scopes, DPoP, and FAPI. Opaque account handles make it harder to identify who is affected.

## Scope and limits

Assessment A reviewed the overview, client list and creation form, provider settings and registration policy, keys and a key detail, consent list and detail, token list and a reuse detail, and the activity queues including overview-linked filters. It did not submit forms. It did not review mobile, zoom, keyboard-only operation, screen-reader behavior, or error states.

Assessment B ran `impeccable detect --json lib/lockspire/web`, which returned `[]`. It inspected tokens, DCR settings, client creation, consent list, and consent detail in an authenticated browser. It did not change demo data. The visual overlay was not injected because the available browser automation could not mutate the page safely in this environment; browser review remained read-only.
