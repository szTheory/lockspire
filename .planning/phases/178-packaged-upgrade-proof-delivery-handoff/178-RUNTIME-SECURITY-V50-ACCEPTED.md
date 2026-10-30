Reviewer: Codex security auditor /root/review_178_security
Date: 2026-10-28
Disposition: accepted
Scope: bounded offline review of v50/v4 orchestration helpers. C50 source acceptance remains unchanged.

The three reported helper findings are corrected:

- **SEC-178-ADMIN-OBSERVER-01 — resolved.** Wrapper v4 instruments the top-level `package_input` used by the native admin entry. This retains the corrected module identity.
- **SEC-178-ADMIN-CUSTODY-02 — resolved.** The wrapper retains the original Popen before observer work and saves the raw identity before serialization. Identity, serialization and journal failures invalidate the observer but return the original process to native cleanup. They no longer create a false `process=None` state. Finalization retries every retained handle and requires absence of its original identity. Missing identity or incomplete journaling cannot pass. An earlier native cleanup failure remains recorded even if a later retry confirms absence.
- **SEC-178-ADMIN-RETENTION-03 — resolved.** The driver sets dependent cleanup confirmation false before entering the matrix. It restores confirmation only after validated inner closure, so exceptions and interruptions retain dependent data/root.

Outer PostgreSQL shutdown remains distinct from inner closure. The driver now records `server_group_stopped` separately from `dependent_cleanup_confirmed`; directory removal requires both. Stopping that independently owned server through its original identity is permitted while retaining its data. It does not establish inner closure or successful overall cleanup.

The previously reviewed private database preflight, native owner/frozen pins, runtime selection, Python inheritance and strict receipt checks are unchanged. I found no additional gap in this bounded correction.

Hashes matched at initial and final inspection:

| Helper | SHA256 |
|---|---|
| coordinator v50 | `f3502d577865fd25d87de06f9e1911ae7fad70b6ffe5e84157584c4bca9c8c72` |
| driver v50 | `1ddd36f9fb62dd9f7fda2d8fd91a23e849bb61e06aa3e80dd6536bf0a50517c8` |
| child wrapper v4 | `f376e3957fd32c78d3aaaeac9ae7dd6cbe7b2808fd77ad8f1dbe57f355fffb00` |

Worker-reported synthetic fixture results remain attributed evidence. I executed no tests, producers, database or process probes, and made no edits.

This accepts the inspected orchestration correction, not an installed-host result. The v47/v48 rejections, failed run 95249, v46 contact/mutation UNKNOWN, missing historical inner proof and all earlier incidents remain preserved and unwaived.
