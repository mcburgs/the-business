# Phase F-R Ownership / Player Coupling Audit

## Status

**Resolved for Phase F-R.** The historically accepted Phase F implementation contained one genuine player-avatar coupling: `OwnershipSeatState.owner_person_id`. Phase F-R removes that coupling while retaining legitimate NPC owner/promoter Persons and their history.

## Affected contracts and files

| Area | File / contract | Finding | F-R disposition |
|---|---|---|---|
| Player control state | `domain/core/ownership_seat_state.gd` | **Genuine coupling.** Seat serialized `owner_person_id`. | Removed. Seat now contains only controlled `promotion_id` plus transition state. |
| State validation | `domain/core/campaign_state_validator.gd` | **Genuine coupling.** Player seat owner had to resolve to `PersonState`. | Removed seat-to-Person invariant. Promotion owner validation retained. |
| State codec | `persistence/codecs/campaign_state_codec.gd` | **Genuine coupling.** `owner_person_id` was a required OwnershipSeat field. | State schema v2 removes it; decode performs explicit migration first. |
| State migration | `persistence/migrations/state_migrator.gd` | **Missing migration.** Historical schema v1 had no path to reconciled state. | Added explicit v1 -> v2 migration that retires only seat identity and records provenance. |
| Save service | `persistence/services/save_service.gd` | Historical Phase F save manifests use architecture `0.2.0`. | `0.2.0` is an explicitly migratable architecture version; current writes remain `0.3.0`. |
| Command issuer | `app/commands/command_router.gd` | **Genuine coupling seam.** Player issuer could carry `person_id` and arbitrary promotion scope. | Player `person_id` is rejected; player promotion scope must equal `OwnershipSeatState.promotion_id`. AI/automation/system Person issuers remain valid where appropriate. |
| Fixtures | `tests/helpers/phase_c_fixture.gd` and derived Phase D/E/F fixtures | Base fixture created a player seat with an owner Person. | Removed player-Person seat field. Competitive fixture still has NPC controlling owner Persons. |
| Historical projection | `domain/chronicle/historical_projection.gd` | Promotion owner history existed, but control seat was not separately projected. | Added non-person `ownership_seat` projection; promotion `owner_person_id` remains legitimate NPC/world history. |
| Regression coverage | `tests/integration/test_phase_f_r_reconciliation.gd`, state/save tests | No direct proof that a campaign runs without a player Person. | Added execution, migration, command-boundary, NPC-owner, Chronicle and seam regressions. |

## Harmless and required NPC-owner references

The following are **not** player-avatar coupling and remain intentionally unchanged:

- `PromotionState.controlling_owner_person_id` models an in-world human promoter/owner when one exists.
- `role.owner` is an NPC/world role definition.
- Great Lakes `owner_person_seed_id` content references create historical NPC promoters; they are data, not the player.
- `HistoricalProjection.promotions[*].owner_person_id` records in-world promotion governance across history.
- Phase F rival promotion fixtures retain Person owners, including `promotion:PRO00003 -> person:PER00007`.
- Person skills, traits, career/health data and future succession hooks remain available for NPC humans.

The reconciliation rule is therefore implemented as **PLAYER CONTROL SEAT != PERSON ENTITY**, not as “owners are no longer people.”

## No-change findings

- `AIPlanningService` identifies the player-controlled promotion through `ownership_seat.promotion_id`; it does not require a player Person.
- Rival AI planners consume promotion-scoped planning views and knowledge projections, not player-owner skills.
- `KnowledgeBase` remains organization/promotion-owned; hidden truth is not attached to a player avatar.
- `QueryService` / `KnowledgeProjection` have no player-person escape hatch.
- `PersonState` portrait/biography/health/skill-capable fields are NPC-human state only; no presentation runtime binds them to the player.
- `assets/portraits/` is an asset boundary only; no authoritative player portrait assumption was found.
- Great Lakes, 1975, and three-promotion counts remain content/fixture facts. No F-R engine branch was introduced for them.
- Chronicle identity/tombstone infrastructure continues to preserve stable Person identities independently of the non-person ownership seat.
- The historical `Canonical Data Schemas & Domain Contracts v0.1 HISTORICAL BASELINE` DOCX is unchanged and remains evidence of the old contract.

## Migration semantics

State schema v1 is interpreted exactly as historical evidence: `ownership_seat.owner_person_id` expressed the obsolete player-seat/person coupling. Migration to state schema v2 removes that one meaning. It **does not** copy, infer, replace, or erase `PromotionState.controlling_owner_person_id`; the promotion's in-world owner remains whatever the historical state already recorded. The migration emits `migrations_applied` evidence including the legacy seat person ID.

## Acceptance proof

The F-R regression suite explicitly sets the player-controlled promotion's `controlling_owner_person_id` to `null`, validates the campaign, advances a full competitive month, serializes the result, and reconstructs Chronicle projection successfully. Rival NPC owner Persons remain valid at the same time. This proves that campaign control and in-world human ownership are independent concepts.
