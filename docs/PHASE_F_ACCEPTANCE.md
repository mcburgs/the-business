# Phase F Acceptance Record

## Status

**PASS — Phase F: Competitive World**

Phase F is complete when at least three promotions can use incomplete information and separated deterministic planners to compete for markets and talent, recover from stress, and create shallow diplomatic consequences through the canonical command pipeline for multiple years without invalid state, hidden-truth leakage, uncontrolled randomness, history resimulation or automatic total dominance.

## Implemented scope

- phase-2 frozen planning snapshot with mutation guard and organization-scoped planning views;
- organization-owned scouting familiarity, bounded uncertainty, confidence and accumulated field reports;
- ContractState offer, counteroffer, renewal, release, exclusivity and expiry flows with active person/promotion indexes;
- separated OwnerStrategy, TalentManager, TouringPlanner, BookerAI, RecoveryAI and DiplomacyAI modules;
- ordinary AI/automation CommandEnvelope submission through phase-3 CommandRouter;
- explainable market entry/defense/retreat, talent pursuit/retention/release and booking priorities;
- visible recovery budget cuts under financial stress;
- shallow non-aggression, talent-share plumbing and territory-violation consequences;
- contract, knowledge, relation and agreement history in sparse Chronicle projections;
- a reusable Phase F competition fixture, generic CLI route and multi-seed/multi-year soak runner.

## Boundary proof

External talent is absent from raw rival planner state. AIPlanningView converts it to KnowledgeProjection records; unknowns remain unknown and estimates contain confidence/ranges only. Planner source gates reject direct CampaignState people/contracts/RNG access. BookerAI cannot reference ShowPlan, ShowResult or BookingSystem. The planning clone is serialized before and after planning and any mutation fails the month.

Contracts and diplomacy validate before mutation. Rejected commands are byte-for-byte state neutral. Contract commands do not mutate cash; show participation costs continue through the reconciled Phase E ledger. Markets retain only influence-by-promotion component vectors and have no owner field.

## Automated acceptance surface

The pinned runtime discovers 31 tests: all 25 retained Phase A-E tests plus six Phase F unit/integration tests. New coverage proves the knowledge boundary, planner separation, command parity, deterministic planning, contract lifecycle/atomicity, recovery and diplomacy consequences, 24-month three-promotion competition, exact save/load and no-resimulation historical reconstruction.

## Competitive evidence

The 24-month fixed-profile fixture completes with all three promotions active for all 24 months (72 shows), four talent signings, 14 contract lifecycle events, 432 scouting reports, 10 route changes, two new agreements, five territory violations and a maximum final market concentration of `0.60057111715`. Exact replay with seed `246810` matches encoded CampaignState, Chronicle and summary; seed `246811` diverges.

The final five-year matrix is retained in `tests/soak/phase_f_5_year_soak.json` and summarized in `tests/soak/PHASE_F_SOAK_REPORT.md`. It repeats one seed and varies six others while rotating policy profiles across asymmetric organizations.

## Exit gate

**PASS.** Phase F scope, retained regressions, deterministic replay, varied-seed competition, save/load, prior-world reconstruction, long soak, pinned-engine import, static architecture checks and repository hygiene pass. Later-phase UI, deep careers/injuries/contracts/diplomacy, advanced media/finance and final content remain out of scope.
