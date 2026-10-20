# Phase 160: Admin Key Protection & Missing-KEK Copy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-19
**Phase:** 160-admin-key-protection-missing-kek-copy
**Mode:** assumptions
**Areas analyzed:** Data source and state classification, Placement/loading/failure isolation, Missing-KEK generation error, Vocabulary and naming

## Assumptions Presented

### Data source and state classification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse `Admin.encryption_status/0` + presenter with 7-state precedence | Confident | admin/keys.ex, admin/keys/encryption_status.ex, doctor.key_encryption.ex, research ARCHITECTURE.md Item 4 |
| Not-set-up copy does not promise existing keys keep working | Likely | application.ex, admin/keys/reencrypt.ex:113, FEATURES.md:88 |
| stranded_retired ignored; zero keys + KEK reads as encrypted | Likely | encryption_status.ex `ready?/1`, doctor `print_stranded/1` |

### Placement, loading, and failure isolation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Line under page_hero outside inventory case; separate assign; rescue → could-not-check; no connected? guard | Likely | keys_live/index.ex, keys_live_test.exs:607, device_authorizations_live/index.ex:167-177 |
| Reuse security-profile check pattern / decision_summary; neutral tone for could-not-check | Likely | policies_live/security_profile.ex, admin_components.ex |

### Missing-KEK generation error
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New `:key_encryption_not_configured` clause before catch-all; generic copy unchanged; buttons enabled | Confident | admin/keys.ex:85-88, keys_live/index.ex, keys_live_test.exs:205-232 |
| Clause covers both :sig and :enc generation | Likely | admin/keys.ex:85-120, index.ex:85 |

### Vocabulary and naming
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Call it "key-encryption key", not bare "encryption key"; add map rows; no retired rows | Unclear | keys_live/index.ex:44,69,82-86, action_component.ex:112, show.ex:328-341, PRODUCT.md:105-187, vocabulary_contract_test.exs |
| Show only current KEK ID; no counts, ID lists, env var names, config error text | Likely | REQUIREMENTS KEY-UI-01, PITFALLS.md M1 |

## Corrections Made

No corrections — all assumptions confirmed. The one Unclear item (KEK UI term) was put to the user, who chose "key-encryption key" (recommended).

Todos: user chose "Fold none" for the two loosely matched todos.
