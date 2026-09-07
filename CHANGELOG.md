# Changelog

All notable architecture/build baseline changes are recorded here.

## 0.0.0-phase-f - 2026-09-07

- Added knowledge-filtered, frozen-snapshot planning for three active promotions with deterministic Owner, Talent, Touring, Booker, Recovery and Diplomacy AI modules issuing ordinary command envelopes.
- Added organization-owned scouting familiarity, confidence, bounded-error estimates and accumulated reports without exposing hidden true values to rival planners.
- Added validated offer/counteroffer/renewal/release/expiry contract flows, active roster indexes and talent-market consequences while retaining ledger-only cash mutation.
- Added competitive market entry/defense, visible recovery budget cuts under stress, shallow non-aggression/talent-share plumbing, and territory violations that remain possible but create trust, grievance and Chronicle consequences.
- Expanded HistoricalProjection and persistence for contracts, knowledge and promotion relations; retained exact save/load and no-resimulation prior-world reconstruction.
- Extended the generic simulation CLI with the Phase F competition fixture and added a reusable multi-seed/multi-year soak runner with machine-readable results.
- Added six Phase F architecture/integration tests, bringing the pinned-engine suite to 31 tests while retaining all Phase A-E gates.
- Verified Phase F under Godot `4.7.2.stable.official.ed1daf0bf`: repeated-seed determinism, varied-seed divergence, multi-policy competition, 24-month integration, five-year soak, Chronicle/save, static and fresh-editor gates pass.

## 0.0.0-phase-e - 2026-09-07

- Added deterministic touring-company logistics with route/directive/budget handling, bounded travel pressure/fatigue, availability inputs, and canonical command-boundary mutation.
- Added abstract BookingSystem/ShowPlan generation and ShowResolver/ShowResult resolution so routine cards are generated automatically while selective owner constraints and major outcomes remain possible.
- Added localized overness, heat, shine and signed momentum, reinforcement/decay, derived contextual drawing power, basic program/championship consequences, and explainable causal factors.
- Added bounded audience/media/business/infrastructure market influence, generic local MediaDeal exposure, ledger-backed live/media/overhead economics, and stateful financial stress without instant campaign failure.
- Added reusable qualification-gated hot/cold states driven only by RandomService with bounded intensity/decay and retained causal contributors.
- Extended HistoricalProjection/identity retention and Chronicle recording for real Phase E touring/audience/program/market/media/financial history while preserving sparse checkpoint-plus-delta reconstruction with simulation and RandomService unavailable.
- Extended SaveService/codec handling for Phase E open-state integer semantics and canonical DomainEvent floating-point publication, preserving exact save/load and last-known-good recovery under Godot JSON.
- Extended the generic simulation CLI with equal-seed `phase_e_good` and `phase_e_bad` acceptance fixtures and strategic diagnostics for shows, attendance, money, touring, wrestler audience, programs, influence, media, hot/cold and Chronicle state.
- Added Phase E architecture/strategic tests and static gates; retained all Phase A/B/C/D regression gates.
- Verified Phase E under Godot `4.7.2.stable.official.ed1daf0bf`: static gate PASS with zero failures/warnings; 25/25 headless tests PASS; equal-seed 12-month strategic comparison PASS; save/reload and no-resimulation Chronicle reconstruction PASS; fresh editor import PASS.

## 0.0.0-phase-d - 2026-09-06

- Added the explicit deterministic 15-phase monthly orchestration pipeline with transactional clone/validate/publish semantics, deterministic command commitment through the Phase C boundary, structured TurnContext/TurnResult data, and failure-safe postflight publication.
- Added structured transient and permanent DomainEvents with stable permanent event IDs, monotonic Chronicle sequence IDs, causal/reference metadata, and Chronicle integrity diagnostics.
- Added minimal deterministic reconciled ledger plumbing using integer minor units and currency-definition IDs, with validation-before-mutation and controlled storage under `world_state.ledger_v1`.
- Added ChronicleStore logical event, metric, checkpoint, delta, index, artifact, and historical-identity stores plus a purpose-built HistoricalProjection and read-only checkpoint-plus-delta ChronicleQueryService.
- Added historical identity/tombstone compatibility so committed references remain resolvable after entities become inactive without keeping them artificially active or reusing IDs.
- Added coherent state-plus-Chronicle SaveService orchestration, content/schema compatibility checks, exact RNG checkpoint persistence across JSON, temporary validation/publication, and last-good recovery skeleton with injected-failure coverage.
- Added a generic headless simulation CLI with campaign/session selection, explicit month count and seed, structured summary/failure output, optional save/reload proof, and no authored Great Lakes assumptions in the engine path.
- Added the Phase D 12-month reconstruction proof: prior HistoricalProjection state reconstructs from committed Chronicle checkpoint/delta/identity data while simulation resolution and RandomService are unavailable, without mutating current CampaignState.
- Documented Phase D controlled machine-contract reconstruction and preserved checkpoint cadence, metric cadence, physical Chronicle chunking/compression, compaction, archive permanence, PRNG replacement, scale ceilings, gameplay formulas, and Android I/O as open policy questions.
- Verified Phase D under Godot `4.7.2.stable.official.ed1daf0bf`: static gate PASS with zero failures/warnings; 20/20 headless tests PASS with zero harness failures; 12-month CLI/save-roundtrip PASS; fresh editor import PASS with no retained parser/import/project-configuration errors.

## 0.0.0-phase-c - 2026-09-06

- Added the authoritative campaign-state domain kernel with stable runtime IDs, ID-keyed entity stores, deterministic canonical iteration, non-reused identities, and Phase C lifecycle/reference validation.
- Added slice-critical Person, Promotion, Market, Region, TouringCompany, Contract, Championship, Program, MediaDeal, Venue, Agreement, Relationship, OwnershipSeat, KnowledgeBase, EventState, RandomState, and supporting state/value objects without scene-tree ownership.
- Added the closed 29-command application surface, deterministic command ordering, structured rejection results, validation-before-mutation, and a retained Phase C championship mutation proving the shared command boundary without implementing later simulation.
- Added a single controlled RandomService wrapping Godot RandomNumberGenerator with explicit seed/provider/internal-state checkpoints and deterministic save/restore tests.
- Added comprehensive CampaignState invariant validation, deliberate corrupt-state tests, and derived drawing-power query boundaries that avoid duplicate authoritative persistence.
- Added explicit current-state serialization/deserialization, strict schema-v1 load validation, manifest/RNG/content metadata scaffolding, and migration entry points.
- Added organization-owned knowledge storage and known/estimated/unknown projection with no hidden-truth escape hatch in normal presentation queries.
- Added a separately documented controlled reconstruction of the missing runtime-state/command/save machine contracts, limited to details directly supported by the governing prose.
- Expanded the static repository gate for Phase C architecture boundaries and retained legitimate Godot-generated `.gd.uid` sidecars.
- Verified Phase C under Godot `4.7.2.stable.official.ed1daf0bf`: static gate PASS with zero failures/warnings; 16/16 headless tests PASS with zero harness failures; fresh editor import PASS with no retained parser/import/project-configuration errors.

## 0.0.0-phase-b - 2026-09-06

- Added generic content discovery, dependency resolution, schema-backed structural validation, semantic reference validation, safe data-only path enforcement, immutable-by-copy content registry, and deterministic SHA-256 content fingerprinting.
- Added a controlled reconstruction of the missing Phase 0 machine schema limited to the Phase B static-content surface, with explicit derivation metadata and documentation.
- Added a skeletal Great Lakes 1975 campaign containing 15 markets, six regions, three promotions, placeholder people/staff, local-TV outlets, venue/title/contract placeholders, and seeded-history hooks.
- Added generic Alpha/Beta variable-count campaign fixtures and malformed fixtures covering duplicate IDs, missing references, illegal ranges, dependency failures, path traversal, remote references, executable references, invalid NarrativeContext values, and unknown fields.
- Added Phase B unit/integration gates and a scenario-special-case guard.
- Promoted project build-phase metadata to verified Phase B after the pinned-engine acceptance gate passed.
- Corrected Phase B JSON Schema integer handling for Godot JSON parsing, which materializes integral JSON numbers as floats.
- Verified Phase B under Godot `4.7.2.stable.official.ed1daf0bf`: static gate PASS; 10/10 headless tests PASS; fresh editor import completed without parser/import errors.
- Corrected Phase B integration-test typed-array calls exposed by the real Godot runtime and retained the generated script UID sidecars.

## 0.0.0-phase-a - 2026-09-06

- Created Godot 4.7.2-stable project skeleton.
- Established layered repository boundaries for application, simulation domain, persistence, content, presentation, tooling/tests, and assets.
- Added minimal launch shell that does not own simulation state.
- Added stock-Godot headless smoke-test runner with machine-readable diagnostics and exit codes.
- Added domain dependency guard, bootstrap contract tests, repository contract test, and headless boot probe.
- Added repository/build hygiene, governing-document manifest, and Git baseline.
- Verified the Phase A editor import and headless gate under Godot 4.7.2-stable official build `ed1daf0bf`.
- Corrected the domain dependency guard parser error and hardened the runner against false passes from non-instantiable test scripts.
- Configured the asset ledger CSV as raw data and retained Godot script UID sidecars generated by the pinned engine.
- Corrected the static repository gate so ignored editor caches do not fail an otherwise clean working tree.
