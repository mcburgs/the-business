# Changelog

All notable architecture/build baseline changes are recorded here.

## 0.0.0-phase-h - 2026-09-08

- Began the first real Android/Pixel target integration from the exact accepted G→H baseline without changing simulation/domain authority.
- Added a reversible arm64 `Android Debug` export preset (`com.mcburgs.thebusiness.dev`) with no production credentials or Play Store configuration.
- Adapted the map-first client for phone use with a 720x720 dual-orientation design base, sensor orientation, narrow bottom navigation, 48-logical-pixel touch targets, one-finger pan, two-finger pinch zoom, direct touch selection and system-Back-to-map behavior.
- Added persistent startup/resume and platform-neutral lifecycle checkpoint seams around the existing CampaignSession/SaveService/Chronicle authority; successful months checkpoint only after authoritative resolution.
- Fixed last-good recovery to preserve a complete loadable snapshot and restore a corrupt primary through the same canonical save path.
- Fixed physical JSON persistence so int64 and binary64 values survive a genuine save/relaunch boundary exactly; no CampaignState/Chronicle schema or simulation semantics changed.
- Added Phase-H lifecycle/save/recovery and touch/responsive regressions, bringing the Phase-H automated suite to 40 tests.
- Reconfirmed G→H protections, F2G-001/002/003, competition, eight-run five-year soak, Chronicle/save and editor/import with zero simulation drift.
- Fixed the Android ETC2/ASTC export prerequisite, then produced and inspected the arm64 debug APK under the pinned Godot 4.7.2 toolchain; package/ABI/offline-permission/signing checks passed.
- Completed physical Google Pixel 9a / Android 17 acceptance: install, launch, touch selection, pan/pinch, required surfaces, canonical state change, single month advance, Back, background/resume, rotation, force-close/relaunch and persisted campaign reload all passed.
- Certified Phase H complete with 40/40 automated tests, retained G→H/F2G regressions, competition, eight-run five-year soak, save/Chronicle, editor/import, static and hygiene gates green. Phase I has not begun.

## G→H adversarial interaction gate - 2026-09-08

- Added a retained hostile-interaction regression and rendered interaction harness over the real Phase G presentation/application boundary.
- Fixed `G2H-001`: repeated route/budget/market-focus/push UI setter intents now suppress exact duplicates and supersede prior same-target pending intent while retaining canonical CommandRouter validation.
- Fixed `G2H-002`: Chronicle historical navigation now owns one selector and one replaceable transient historical card, avoiding same-frame node reuse/queued-free churn.
- Fixed `G2H-003`: duplicate month activation in one input burst is suppressed through a deferred presentation lock plus an application re-entry guard.
- Fixed `G2H-004`: stale/invalid market IDs can no longer become current presentation selection.
- Reconfirmed stale-envelope `CMD002`, F2G cross-promotion authority, knowledge limits, non-mutating historical inspection and deterministic touring-churn equivalence.
- Preserved the Phase G game/build version because this is an interphase validation gate; Android integration remains Phase H.

## 0.0.0-phase-g - 2026-09-08

- Replaced the development shell as the default gameplay experience with a map-first strategic home.
- Added deterministic campaign runtime materialization from governed content and retained generic slice tuning.
- Added `CampaignSession` as the presentation-facing application boundary and `OwnerPresentationQuery` as the knowledge-limited view-model seam.
- Added market, controlled-promotion, roster/people, touring, wrestling/program and Chronicle/history presentation surfaces.
- Added canonical UI command flow for market focus, touring route, featured-person push and touring-budget adjustment, plus complete strategic month advancement through `MonthPipeline`.
- Preserved the non-person Ownership Seat and knowledge-limited rival estimates; presentation exposes neither player Person state nor raw authoritative rival truth.
- Added touch-capable map pan/zoom/tap and responsive desktop/narrow layouts in preparation for Phase H without performing Android packaging.
- Added four Phase G automated tests and Phase G static presentation-boundary gates while retaining F2G-001/002/003 regressions and all earlier evidence.

## F→G adversarial strategic gate - 2026-09-07

- Added the canonical `F2G-STRAT-001` adversarial harness using knowledge-filtered player views, validated command envelopes, the normal MonthPipeline, deterministic replay, per-run transcripts/metrics/invariants, Chronicle reconstruction, and save-roundtrip evidence.
- Executed all ten required attacker profiles across duplicate/varied seeds for 30 directed 24-month runs, plus 65-month financial-idiot and 60-month randomized-valid-command hostile campaigns.
- Fixed `F2G-001`: player/AI/automation promotion scope is now enforced across resource-targeted command handlers, blocking cross-promotion authoritative mutation and tightening person/program/title availability checks.
- Fixed `F2G-002`: direct media-deal economic terms can no longer be authored by player/AI callers; authoritative system/offer provenance is required until a governed media-offer flow exists.
- Fixed `F2G-003`: expired employment now clears a matching booker appointment, and `command.set_booker` requires a live same-promotion contract.
- Added permanent adversarial regressions and retained pre-fix/post-fix repro bundles for all three material findings.
- Classified talent-hoarder cash advantage as a tuning observation, negative player cash without a full bankruptcy lifecycle as an accepted shallow-slice limitation, and sub-1e-12 JSON float comparison noise as a fixed harness issue.
- Cleared the F→G gate for Phase G only after the complete retained Phase F-R test/competition/soak/import/static/hygiene verification remained green.

## 0.0.0-phase-f-r - 2026-09-07

- Reconciled player control with GDD/Architecture v0.3: `OwnershipSeatState` is a non-person control seat and no longer stores or validates a player `PersonState` identity.
- Advanced current CampaignState to schema v2 with an explicit v1 -> v2 migration that retires only `ownership_seat.owner_person_id` while preserving in-world `PromotionState.controlling_owner_person_id` semantics and migration evidence.
- Allowed historical Phase F architecture `0.2.0` save manifests through the controlled migration path; current saves identify architecture `0.3.0` / contract `0.2.0`.
- Hardened the command boundary so player issuers cannot carry `person_id` and must be scoped to the promotion controlled by the Ownership Seat; AI/automation/system Person issuers remain available where appropriate.
- Added a separate non-person Ownership Seat to HistoricalProjection while retaining legitimate NPC promotion-owner Person references.
- Added explicit `presentation_context` and `wrestling_language_context` carriers to the existing ShowPlan/BookingSystem/ShowResolver path without implementing deep psychology or a second booking engine.
- Added Phase F-R ownership, migration, save, Chronicle and booking-seam regressions plus controlled ownership/seam audit records.
- Added Creative Direction & Experience Bible v0.1 and Creative-to-Systems Impact Matrix v0.1 as subordinate governing creative artifacts.
- Retained historical Phase F acceptance/soak evidence unchanged and reran the complete Phase F verification surface for the reconciled baseline.


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

## H→I adversarial gate candidate

- Reproduced and repaired interrupted-save publication that could silently reset a recoverable campaign.
- Added pre-start interrupted-transaction settlement and fail-closed unrecoverable-artifact handling.
- Added current-save SHA-256 payload integrity plus state/Chronicle/manifest agreement checks.
- Added two-generation `last_good` / `older_good` recovery rotation while preserving `.previous` on backup-copy failure.
- Added permanent H→I fault-injection regression coverage and a 12-month/relaunch hostile persistence harness.
- Retained G→H command/month/touch/knowledge protections and Phase-F competitive simulation behavior.
