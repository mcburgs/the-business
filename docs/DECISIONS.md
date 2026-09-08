# Lightweight Decision Trail

This file records implementation decisions made while translating the governing documents into code. It does not supersede those documents.

## ADR-A-001 - Pinned engine and language

**Status:** Accepted for Phase A
**Decision:** Godot 4.7.2-stable, standard build, typed GDScript.
**Reason:** Locked by the Technical Architecture v0.2 and Build Plan v0.1.

## ADR-A-002 - No gameplay state in the launch shell

**Status:** Accepted
**Decision:** `GameRoot` is a minimal Node shell. It emits boot diagnostics only and does not construct or own simulation truth.
**Reason:** The scene tree is replaceable presentation/application infrastructure around the domain model.

## ADR-A-003 - Stock-Godot test harness

**Status:** Accepted
**Decision:** `res://tests/runner.gd` extends `SceneTree`, discovers repository tests, emits JSON diagnostics, writes a summary artifact, and returns meaningful process exit codes. No editor test plugin is required.
**Reason:** Headless simulation/testing is an architectural acceptance requirement.

## ADR-A-004 - No invented Phase 0 machine schemas

**Status:** Superseded for the Phase B static-content subset only by ADR-B-001
**Decision:** Preserve `content/schemas/` as the canonical integration boundary, but do not reverse-engineer or invent `we.phase0.schema.json` during Phase A.
**Reason:** The supplied Canonical Data Schemas & Domain Contracts document references a separate machine-consumable schema package, but that JSON package was not present among the supplied files. Phase A does not silently recreate a Phase 0 deliverable.

## ADR-B-001 - Controlled reconstruction of the missing static-content schema subset

**Status:** Accepted for Phase B
**Decision:** Reconstruct only the machine-readable Phase B static-content subset required to load and validate manifests, maps, authored definitions, seed shells, and history hooks. Label the result `controlled_reconstruction`, retain a derivation record, and do not claim it is the missing original Phase 0 package.
**Reason:** Phase B cannot satisfy its explicit machine-readable content validation gate without this dependency, and the original package remains unavailable. The governing prose is sufficient to derive the required static contracts while explicitly leaving Phase C runtime contracts untouched.

## ADR-B-002 - ContentRegistry is an application/content service, not mutable simulation truth

**Status:** Accepted
**Decision:** `app/content/ContentRegistry` stores resolved authored definitions and returns deep copies to consumers. It does not create CampaignState or own mutable runtime entities.
**Reason:** The governing static/mutable ownership matrix places immutable definitions in ContentRegistry and mutable campaign truth in the later Domain Kernel.

## ADR-B-003 - Generic loader owns discovery, validation, dependency resolution, and fingerprinting

**Status:** Accepted
**Decision:** Campaign selection points the loader at a campaign directory; pack identities, dependencies, file families, map identity, ruleset identity, start date, and record counts all come from data. The loader contains no Great Lakes, 1975, or three-promotion branch.
**Reason:** This is the central Phase B acceptance proposition and prevents the vertical slice from becoming an engine special case.

## ADR-B-004 - Phase B does not instantiate Phase C runtime architecture early

**Status:** Accepted
**Decision:** Person/promotion/title/contract records in Phase B are immutable seed/placeholder definitions only. Runtime CampaignState, entity stores, commands/results, RNG, save codecs, knowledge projection, and Chronicle mutation remain unimplemented until Phase C or later.
**Reason:** The Build Plan sequences those systems into Phase C. Convenience hooks are not authority to collapse the phase boundary.

## ADR-C-001 - Runtime schema reconstruction remains code-adjacent and explicitly controlled

**Status:** Accepted for Phase C
**Decision:** Derive Phase C runtime field catalogs, ID/reference validation, command envelope/catalog, RNG state, current-state codec, migration entry point, and knowledge projection directly from the supplied canonical prose/tables. Do not extend the Phase B reconstructed JSON file and do not claim that typed code is the missing original Phase 0 machine package.
**Reason:** The original machine-readable runtime schema remains unavailable. The supplied canonical contract is precise at the parent/entity field level but intentionally incomplete for several nested supporting value-object shapes. `content/schemas/DERIVATION.md` records those boundaries in its Phase C addendum.

## ADR-C-002 - No current-state compaction before Chronicle identity resolution exists

**Status:** Accepted for Phase C
**Decision:** Phase C authoritative entity stores do not delete or recycle retired runtime identities. Lifecycle changes may make an entity inactive, but its record and ID remain present until later Chronicle identity/tombstone infrastructure can guarantee historical resolvability.
**Reason:** This satisfies runtime-ID non-reuse and creates a safe handoff to later Chronicle compaction without implementing Phase D early.

## ADR-C-003 - One retained Phase C mutation proves the command boundary without importing simulation

**Status:** Accepted for Phase C
**Decision:** The command catalog recognizes all 29 v0.1 command types. `command.set_champion` is retained as a Phase C mutation because its reference/integrity semantics are fully defined and do not require month simulation. Other future-facing command types are contract-visible but reject through the structured command result boundary until their governing simulation phase exists.
**Reason:** Phase C must prove deterministic command ordering, validation-before-mutation, and rollback behavior while explicitly not implementing Phase D/E resolution systems.

## ADR-C-004 - Godot RNG remains a single controlled root stream

**Status:** Accepted for Phase C
**Decision:** RandomService wraps one `RandomNumberGenerator`, records provider ID, explicit seed, internal state, captured turn, and `single_root_v1` stream policy, and treats diagnostic tags as metadata only.
**Reason:** This is the exact initial randomness contract. A project-owned PRNG remains the documented open engineering question rather than a Phase C invention.

## ADR-D-001 - Monthly resolution publishes transactionally after postflight

**Status:** Accepted for Phase D
**Decision:** `MonthPipeline` resolves against cloned `CampaignState` and `ChronicleStore` objects. The completed pair is returned for publication only after phase 14 postflight validation succeeds. A failed phase leaves the caller's retained current state and Chronicle untouched.
**Reason:** This preserves the explicit phase-13 Chronicle commit contract while preventing a failed postflight or persistence-adjacent defect from leaving a half-published month.

## ADR-D-002 - Historical reconstruction is sparse checkpoint plus ordered deltas

**Status:** Accepted; cadence remains configurable
**Decision:** Chronicle stores purpose-built `HistoricalProjection` keyframes and recursive add/replace/remove deltas. The first committed month is checkpointed; later checkpoint cadence is policy. Historical query code accepts only Chronicle data and has no simulation, command-router, AI, or RandomService dependency.
**Reason:** This directly implements ADR-015 through ADR-020 and makes the no-resimulation requirement testable rather than aspirational.

## ADR-D-003 - Phase D uses a coarse JSON Chronicle codec behind logical store boundaries

**Status:** Accepted for Phase D only
**Decision:** SaveService writes current state plus a Chronicle manifest and one coarse Chronicle data file to temporary paths, validates them, then publishes the pair while preserving a last-good copy. Logical Chronicle stores remain distinct in code. Exact chunking/compression remains open.
**Reason:** The governing architecture explicitly permits coarse initial physical segments and forbids prematurely locking the production storage codec.

## ADR-D-004 - Minimum ledger state uses the existing world-state extension point

**Status:** Accepted as controlled reconstruction for Phase D
**Decision:** Reconciled double-entry-style postings are retained under `CampaignState.world_state.ledger_v1` rather than adding a new top-level CampaignState field not present in the supplied field catalog.
**Reason:** Phase D needs durable ledger plumbing, but the missing original machine schema does not publish ledger placement. This choice is deliberately narrow and migration-aware rather than masquerading as recovered canonical schema.

## ADR-E-001 - Phase E mechanics activate through the existing ruleset/content boundary

**Status:** Accepted for Phase E
**Decision:** The Phase E strategic services run when a `phase_e_tuning` dictionary is supplied through the existing content index. Retained Phase A-D fixtures remain behaviorally unchanged when that profile is absent.
**Reason:** This preserves the verified Phase D pipeline and makes gameplay coefficients external/tunable rather than scattering scenario-specific constants through domain code.

## ADR-E-002 - ShowResolver is a pure resolution boundary with downstream effects

**Status:** Accepted
**Decision:** BookingSystem creates structured ShowPlans; ShowResolver consumes plans plus authoritative inputs and RandomService and returns structured ShowResults/causal factors. Audience, media/markets, economy, Chronicle, and persistence consume those outputs in their own canonical phases.
**Reason:** The governing architecture explicitly treats a cross-system resolver monolith as a Phase E rework trigger.

## ADR-E-003 - Strategic history expands HistoricalProjection, not monthly snapshots

**Status:** Accepted
**Decision:** HistoricalProjection now retains the minimum Phase E touring, local audience, program, market/influence, media, promotion/financial, championship, agreement, and identity state needed for meaningful historical reconstruction. Chronicle still stores sparse checkpoints plus ordered deltas.
**Reason:** Phase E history must reconstruct real gameplay without rerunning booking, show resolution, audience/economy formulas, commands, or RandomService.

## ADR-E-004 - JSON publication restores integer semantics and canonicalizes event floats

**Status:** Accepted as a persistence-boundary repair
**Decision:** Known integer-semantic values in open world-state and Chronicle structures are restored after Godot JSON parsing, while DomainEvent facts/explanations canonicalize finite floats to nine decimal places before journal publication. RNG internal state continues to use the Phase D decimal-string safeguard.
**Reason:** Phase E exposed that Godot JSON parses integer-shaped nested numbers as floats and can round arbitrary computed doubles by one ULP. Deterministic save/resume requires stable authoritative/history representation rather than tolerance-based acceptance.

## ADR-F-001 - Rival AI receives a sanitized frozen planning view

**Status:** Accepted for Phase F
**Decision:** Phase 2 serializes the authoritative CampaignState, decodes an isolated planning clone, and builds a promotion-scoped plain-data view. Own personnel data is visible to its organization; external talent ability, local value and demand enter only through KnowledgeQueryService projections. The pipeline rejects any planner mutation of the frozen clone.
**Reason:** This enforces the governing knowledge boundary and prevents AI-only truth access while retaining deterministic planning.

## ADR-F-002 - AI responsibilities remain separate command producers

**Status:** Accepted for Phase F
**Decision:** OwnerStrategy, TalentManager, TouringPlanner, BookerAI, RecoveryAI and DiplomacyAI remain separate modules coordinated by AIPlanningService. Their outputs are ordinary CommandEnvelope objects committed by CommandRouter. BookerAI may set push/protect/program priorities but does not construct ShowPlan or resolve shows.
**Reason:** The Build Plan explicitly names god-manager AI and Booker-owned routine card generation as rework triggers.

## ADR-F-003 - Shallow Phase F mutable records use the open world-state extension

**Status:** Accepted as controlled reconstruction
**Decision:** Pending negotiations, promotion-level trust/grievance, pending territory violations and talent-share records live in versioned `CampaignState.world_state` keys. Active ContractState and AgreementState objects remain authoritative domain records. HistoricalProjection retains the minimum contract, knowledge and promotion-relation state needed for prior-world reconstruction.
**Reason:** The governing prose requires these behaviors, but the unavailable Phase 0 machine contracts do not specify final nested persistence records.

## ADR-F-004 - Soak policy comparison rotates strategies across organization identities

**Status:** Accepted for Phase F acceptance tooling
**Decision:** The long soak deterministically rotates balanced, expansionist and defensive profiles across the three asymmetric fixture promotions by seed. Production mechanics are unchanged; the test fixture avoids mistaking a stronger initial roster/home market for an intrinsically superior policy.
**Reason:** Policy variance must be evaluated across contexts rather than inferred from one fixed organization-policy pairing.


## ADR-FR-001 - Player control is a non-person Ownership Seat and current state schema is v2

**Status:** Accepted for Phase F-R
**Decision:** `OwnershipSeatState` contains promotion control and transition state only. CampaignState schema v2 removes the historical `owner_person_id` field. State migration v1 -> v2 explicitly retires that field while leaving every `PromotionState.controlling_owner_person_id` untouched. Historical Phase F architecture `0.2.0` manifests are an explicitly migratable source.
**Reason:** GDD/Architecture v0.3 lock the player as an abstract non-person seat while preserving NPC owner/promoter people. Silent reinterpretation would corrupt both product meaning and historical save provenance.

## ADR-FR-002 - Player command authority is promotion-scoped, never Person-scoped

**Status:** Accepted for Phase F-R
**Decision:** Player `CommandEnvelope.issuer` must identify the promotion controlled by `OwnershipSeatState` and may not contain `person_id`. AI/automation/system issuers retain Person references when a real simulated person is the appropriate actor.
**Reason:** The shared command boundary must not reintroduce the forbidden owner-avatar identity indirectly. Promotion scoping also prevents a player issuer from impersonating a rival promotion.

## ADR-FR-003 - Presentation intent and WrestlingLanguage travel through the existing ShowPlan path

**Status:** Accepted as a narrow Phase F-R seam
**Decision:** `ShowPlan` carries separate `presentation_context` and `wrestling_language_context` dictionaries. BookingSystem may populate them from governed state/content context and ShowResolver carries them as explicit causal context. They have no Phase F-R balance effect. Future hands-on booking must continue to reuse this same ShowPlan/command/resolution architecture.
**Reason:** Reality, Perception and deliberate Presentation must not collapse into one concept, and era/region/audience wrestling language must have a place to enter booking resolution without requiring a future resolver rewrite. Deep psychology, formal language profiles and production UI remain deferred.

## ADR-F2G-001 - Resource command authority is target-promotion scoped

**Status:** Accepted from F→G adversarial gate
**Decision:** Every player/AI/automation command that mutates a promotion-owned resource must validate the target resource promotion against `issuer.promotion_id`, even when the referenced entity itself is valid. Cross-promotion references reject atomically.
**Reason:** F2G-001 proved that issuer validation at envelope level is insufficient when a handler accepts an ID belonging to a rival. Authority belongs to the controlled promotion, not to any valid entity ID the caller can guess.

## ADR-F2G-002 - Economic offer terms require authoritative provenance

**Status:** Accepted from F→G adversarial gate
**Decision:** Direct `command.sign_media_deal` term creation is system-authority only until an authoritative offer/proposal model exists. Future player/UI flow must select or respond to governed terms rather than submit arbitrary revenue/cost payloads.
**Reason:** F2G-002 demonstrated an unbounded money-mint exploit through otherwise valid command payloads. Blocking authored terms is the minimum architecture-compatible fix; inventing a full media negotiation system during F→G would be scope expansion.

## ADR-F2G-003 - Skill-bearing staff appointments require live employment

**Status:** Accepted from F→G adversarial gate
**Decision:** Assigning a booker requires a live same-promotion employment contract, and contract deactivation clears a matching `booker_by_promotion` reference. The same principle governs future staff appointments unless a specific governed loan/share contract says otherwise.
**Reason:** F2G-003 showed that stale staff references can supply free skill after employment ends, contradicting the contract and economy model.


## Phase G — map-first presentation as an application client

**Decision:** The default playable surface is `StrategicHome`, dominated by `StrategicMapView`. Presentation owns transient selection/navigation state only. It may not own or directly mutate CampaignState, construct authoritative domain entities, call CommandRouter, or read debug truth.

**Read seam:** `OwnerPresentationQuery` projects controlled-promotion context, markets, people, touring, wrestling and Chronicle/history. Rival market information is obtained through `KnowledgeQueryService` and remains estimated where the Ownership Seat's knowledge is uncertain. Historical inspection uses `ChronicleQueryService` reconstruction and is subsequently scoped for the Ownership Seat.

**Write seam:** `CampaignSession` converts presentation intent into canonical `CommandEnvelope`s, validates them with `CommandRouter` on a cloned state, queues accepted commands, advances the authoritative month through the existing `MonthPipeline`, then rebuilds the presentation projection.

**Ownership:** The player remains the non-person `OwnershipSeatState`; no player Person or avatar metadata is introduced. NPC owners/promoters remain Persons where the simulation already models them.

**Map provenance:** Phase G consumes the existing normalized market coordinates and map connections from campaign content. No Great Lakes/1975 branch is added to domain/application simulation. A deterministic fallback layout exists only in presentation for content lacking coordinates.

**Opening-state provenance:** The current campaign pack is seed content, not a serialized CampaignState. `CampaignRuntimeFactory` therefore performs deterministic, generic vertical-slice materialization using content identities/records plus retained Phase E/F tuning. The resulting CampaignState is authoritative before UI projection; the presentation never treats bootstrap values as its own truth.

**Deferred:** Android export/package work remains Phase H. Deeper presentation polish, full manual microbooking, additional content depth and balance remain later work.
