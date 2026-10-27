# Phase 178 Base Sync Requalification Record

## Snapshot

- Feature branch parent before sync: `4858b7ec1e62af6b62f81fa7a467e79743786f9b`.
- Incoming `main` parent: `173059a166e9ade0f5f57c9980b7b2400a98538c`.
- The merge preserves the current v1.48 scope and Plan 11 position. The incoming v1.47 qualification history is retained in the added Phase 171–174 planning artifacts and in the two committed parent snapshots recorded in the private merge-retention journal.
- All 14 known conflicts were resolved. The current branch version of `scripts/acceptance/clean_room_saas_journey.py` was retained after semantic comparison; its prepared provider environment, ownership controls, and selected auth-time paths remain intact.

## Qualification Impact

The incoming main history adds `test/lockspire/qualification_ledger_contract_test.exs` to the selected source closure. The old frozen closure contains 1,076 selected inputs; the merged closure must be requalified as 1,077 inputs. Earlier Plan 10 source and package evidence remains valid historical evidence for its exact 1,076-input frozen package and runner identities. It does not qualify the expanded closure. VPROOF-02 therefore remains pending until the refreshed 1,077-input source review, freeze, source gate, and package evidence are complete. VDELIV-01 and VDELIV-02 remain pending their separate delivery owners.

## Preserved Evidence

The merge-retention journal preserves the exact bytes, modes, Git blob IDs, and SHA-256 digests of both committed parent versions for each of the 14 conflicted paths, together with the prior accepted Phase 178 proof artifacts. The prior reports and receipts are unchanged and must not be retargeted to the merged source revision.
