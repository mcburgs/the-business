# Phase F-R Acceptance Record

## Status

**PASS — Phase F-R: Post-Phase-F Reconciled Baseline.** Phase F-R is the controlled post-Phase-F alignment baseline. It preserves historical Phase F acceptance while reconciling the player-control contract with GDD/Architecture v0.3.

## Required proposition

A campaign is controlled through an abstract non-person `OwnershipSeatState`. No player `PersonState`, avatar, portrait, biography, age, health, skills, traits or mortality state is required. In-world NPC owners/promoters may remain Persons and retain their own history.

## Implemented reconciliation

- State schema v2 removes `OwnershipSeatState.owner_person_id`.
- Explicit v1 -> v2 migration retires only the obsolete seat/person meaning and preserves `PromotionState.controlling_owner_person_id` unchanged.
- SaveService explicitly accepts historical Phase F architecture `0.2.0` for controlled migration into current architecture `0.3.0`.
- Player commands reject `issuer.person_id` and are scoped to the promotion identified by the ownership seat.
- HistoricalProjection records the non-person ownership seat separately from in-world promotion-owner Persons.
- A controlled promotion can have no controlling owner Person and still validate, simulate, save and reconstruct history.
- `ShowPlan` now has distinct Presentation and WrestlingLanguage context carriers; no psychology or manual-booking engine is implemented early.

## Governing creative artifacts

Phase F-R adds:

- `docs/governing/The_Business_Creative_Direction_and_Experience_Bible_v0_1.docx`
- `docs/governing/The_Business_Creative_to_Systems_Impact_Matrix_v0_1.docx`

These are subordinate to the GDD and Technical Architecture and convert the reconciled direction into practical creative/system law.

## Audit records

- `docs/PHASE_F_R_OWNERSHIP_AUDIT.md`
- `docs/PHASE_F_R_ARCHITECTURE_SEAM_AUDIT.md`

## Automated acceptance surface

The retained Phase A-F suite is not waived. F-R adds `tests/integration/test_phase_f_r_reconciliation.gd` and extends migration/save tests. Final acceptance requires static checks, all discovered headless tests, the exact Phase F competition command, eight-run five-year soak, save/Chronicle reconstruction, fresh editor import and Git hygiene.

## Historical evidence preservation

`docs/PHASE_F_ACCEPTANCE.md`, `docs/PHASE_F_RUNTIME_RESULT.md`, `tests/soak/PHASE_F_SOAK_REPORT.md`, and the historical `tests/soak/phase_f_5_year_soak.json` remain Phase F evidence. F-R does not rewrite them to pretend the reconciled contract existed earlier.

## Exit gate

**PASS.** The player is demonstrably not a Person; campaigns run without a player-person dependency; NPC owner/promoter Persons remain valid; state/save semantics are explicitly migrated; Chronicle/history and command/knowledge boundaries remain coherent; no Great Lakes/1975/fixed-count engine special case was added; all five reconciled creative seams are viable; both controlled creative artifacts are complete; 32/32 headless tests, the 24-month competition run, eight-run five-year soak, save/Chronicle reconstruction, static gate, fresh editor import and staged-tree hygiene pass.

The exact verified baseline is the staged F-R tree based on `e18f32240e1fb3b9c92916da3efc9072e6a2ea85`. It is commit-ready but intentionally uncommitted and unpushed pending owner authorization.
