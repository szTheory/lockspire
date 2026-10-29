# PR141 E7AD correction proposal

The previous approved push/body update completed at `f962fce47d97a78ae67522301aa65104d42a8b2d`. Read-only recovery observation reconfirmed PR141 open, non-draft and unmerged at that head, base `173059a166e9ade0f5f57c9980b7b2400a98538c`. The previous proposal is retained byte-for-byte in [the prior proposal](178-11-PR-PROPOSAL-BEFORE-e7ad5e67.md). No new remote mutation has occurred.

The new tested source is `e7ad5e67b7c6d00f97ce347b2576b671ddafd811`, tree `6562e38ea613cf1c9b8651da3bd647d764fb4c0e`. All 1,079 selected inputs have canonical row digest `010613c567019f5dbca057ea5b749038ec54ae273467a17f87520bac76835b1f`. Only the workflow, bounded timeout wrapper and matching test expectation differ from EC92; application/package bytes are identical.

[The correction ledger](178-11-LOCKED-DEADLINE-CORRECTION.json) records fresh source CI (2,463 tests, zero failures, two properties), new verifier matrix (26 receipts, 64 passing cases), three independent review lanes, preserved prior records, final native semantic validation and the finite retained-evidence index. Prior EC92 lifetime/SaaS/96host proofs keep their original identities through measured archive/tree equality. The C762 failure and all older failed/unknown observations are preserved.

Hosted CI40927824424 attempt1 was cancelled: five jobs passed, Integration cancelled and Coverage skipped. The former locked overall deadline emitted `overall/release-rpc/locked/builtin`; its precise inner predicate remains unknown. The new bounded locked total is40minutes, Integration75minutes; floor25/45minutes is unchanged. No new hosted graph is claimed.

The exact final metadata head, PR body and body SHA-256 are recorded after this commit in `/private/tmp/lockspire178-pr141-update-e7ad5e67/proposal.json` to avoid self-reference. The body links to evidence at that head. The final committed selected inputs must equal tested E7AD.

Proposed actions after fresh exact authorization:

1. Reconfirm PR141 and remote branch still equal f962fce4, the base is173059a1, and the proposed head is a non-force descendant. Reconcile changed preconditions before any mutation.
2. Push exactly the recorded metadata head to the existing milestone branch without force.
3. Verify remote branch and PR head equal that exact head, update only PR141 body to the recorded exact bytes, and verify its readback.
4. Observe automatic CI and retain its actual synthetic checkout, complete seven-job graph and both same-attempt package artifacts. Validate the actual candidate before canonical milestone audit.

The prior exact approval is consumed; this update requires fresh authorization. No merge, publication, rerun, manual dispatch, comment or review is proposed. Plan11 remains incomplete, Plan12 is not ready, global security is OPEN_THREATS4, and main acceptance remains pending. E-09/E-10/generic/descriptorless flags retain original dispositions.
