# Phase B schema reconstruction record

## Status

`we.phase0.schema.json` in this repository is a **controlled reconstruction**, not the missing original machine-readable Phase 0 artifact referenced by *Canonical Data Schemas and Domain Contracts v0.1*.

The original standalone schema package was not supplied with the governing attachments and was not present on remote `main` when Phase B began. Phase B cannot satisfy its content-loader/validator gate without a machine-readable contract, so the minimum static-content subset required by Phase B has been reconstructed from the governing prose.

## Governing derivation sources

1. *Canonical Data Schemas and Domain Contracts v0.1*, especially identity/reference rules, CampaignPackManifest, map topology, static-vs-runtime ownership, NarrativeContext, data-only mod safety, fixtures, and error codes.
2. *Technical Architecture and Vertical Slice Specification v0.2*, especially §§2-5, §12.5, §14, and the implementation authorization gate.
3. *Development and Build Plan v0.1*, Phase B work packages, deliverables, exit gate, and validation-fixture requirements.
4. *Game Design Document v0.2*, first-slice candidate and no-hard-coded-demo-assumption rules.

## Reconstruction boundary

The reconstructed schema deliberately covers only the Phase B static-content surface:

- pack and campaign manifests;
- content IDs, dates, semantic versions and dependency specs;
- maps, regions, markets and travel connections;
- venues;
- person and promotion seed shells;
- role/ruleset/media definitions;
- championship and contract seed placeholders;
- seeded-history hooks;
- NarrativeContext values used by Phase B authored data.

It deliberately does **not** reconstruct the missing original schemas for mutable CampaignState, runtime entity state, commands/results/events, RNG, saves/migrations, knowledge projections, or Chronicle stores. Those remain governed by the prose contracts for Phase C and later.

## Unavoidable interpretation

The governing prose does not publish the missing original JSON property names for every static definition. Phase B therefore uses conservative field names that map directly to stated responsibilities and avoids tuning fields whose values remain open. In particular:

- generic definition-pack manifests use the common manifest fields without campaign-only `map_id`, `start_date`, or `ruleset_id`;
- campaign manifests are the strict superset described by the contracts;
- generic map coordinates are content-space `x`/`y` values with no engine projection assumption;
- travel distance/time fields state their units explicitly (`base_distance_km`, `base_time_minutes`);
- person/promotion/title/contract files are seed shells, not mutable Phase C state;
- placeholder title/contract/history records carry an explicit `placeholder` flag so skeletal Phase B data cannot masquerade as finished historical content.
- the prose permits explicit data overrides but does not expose the missing machine field/syntax for declaring an override; Phase B therefore rejects duplicate/conflicting IDs rather than inventing an override grammar.
- population/economy/venue tuning fields whose exact missing machine property names are not published are left for later controlled schema expansion; Phase B implements the map fields explicitly required by the Phase B work package and does not guess tuning contracts.

Any later recovery of the original machine-readable Phase 0 package must be compared against this reconstruction. Divergences are architecture-sensitive migration work, not silent edits.

---

# Phase C runtime-contract reconstruction addendum

## Status

The original machine-readable runtime-state/command/save schema portions remain **not supplied**. Phase C therefore performs a second, separately bounded **controlled reconstruction** in typed GDScript field catalogs, validators, and explicit codecs. It does not expand `we.phase0.schema.json` beyond the Phase B static-content subset and never presents the reconstruction as the unavailable original artifact.

## Directly reconstructed contracts

Phase C code derives only details explicitly stated in the governing canonical contract: runtime/content ID forms; canonical validation codes; CampaignState and Appendix A entity field catalogs; numeric representation; the 29 named command types and deterministic ordering tuple; structured command results; the single-root RandomService state; explicit current-state codec/version boundary; migration entry point; and KnowledgeBase/KnowledgeProjection hiding rules.

## Intentionally preserved open shapes

The supplied governing prose does not enumerate complete machine property schemas for every nested supporting value object, including role assignments, health/career internals, audience components, contract compensation/clauses, program sides, tour stops/directives, hot-state objects, world-state internals, event-choice state, and victory details. Those remain explicit opaque data objects beneath their canonical parent fields in Phase C. No undocumented balance formulas, thresholds, decay rates, breakout probabilities, succession mechanics, or scene/presentation identities are introduced.

A recovered original Phase 0 machine package must be compared against both the Phase B static reconstruction and this Phase C code-adjacent reconstruction. Any divergence is architecture-sensitive migration work, not a silent cleanup.

---

# Phase D Chronicle/save/ledger reconstruction addendum

## Status

The original machine-readable Phase 0 definitions for `TurnContext`, `TurnResult`, `DomainEvent` journal records, `ChronicleManifest`, historical metrics, `HistoricalProjection`, `ChronicleDelta`, checkpoints, indexes, tombstones/identity epochs, save orchestration metadata, and ledger infrastructure remain **not supplied**. Phase D therefore performs a third bounded **controlled reconstruction** in typed GDScript and explicit codecs. It does not claim to reproduce the unavailable original schema package.

## Directly reconstructed contracts

Phase D derives only structures required by the governing prose: the explicit 15-phase monthly ordering; transient versus permanent DomainEvent identity; monotonic Chronicle sequence IDs; logically separate event, metric, checkpoint, delta, index, artifact and identity stores; the checkpoint-plus-delta reconstruction rule; read-only historical queries; Chronicle-aware SaveManifest fields; coherent state/Chronicle publication; and a minimal reconciled ledger transaction/posting shape using integer minor units plus currency IDs.

`HistoricalProjection` is deliberately purpose-built and contains only the reconstruction fields called for by the governing contracts: promotion identity/ownership/roster/prestige/momentum summaries, championship state, market interest/influence/hot state, agreement status/parties/clauses, media footprints, and identity/presentation references. It is not a serialized `CampaignState` copy.

## Controlled implementation choices

- Chronicle physical persistence uses one coarse `chronicle.json` data segment plus a Chronicle manifest for Phase D. Logical stores remain separate in `ChronicleStore`. Chunking/compression remains open.
- The synthetic acceptance fixture configures a 12-month checkpoint cadence so the architecture can prove an initial keyframe, monthly deltas, and a later checkpoint. The cadence remains store policy, not schema.
- The minimal ledger is retained under the existing open `CampaignState.world_state` extension point as `ledger_v1`, rather than adding an unsupported new top-level CampaignState field to the closed Phase C field catalog. Phase E may migrate this representation if recovered canonical schema or implementation evidence establishes a better authoritative placement.
- Godot JSON does not safely round-trip the full 64-bit `RandomNumberGenerator.state` integer. SaveService therefore encodes that specific RNG internal state as a decimal string in JSON and restores it to the canonical 64-bit integer before `CampaignStateCodec` validation. Money `minor_units` are restored from safe integral JSON numbers before current-state decode.
- Free-form Chronicle fact numbers preserve numeric meaning across JSON even where Godot parses an integer-shaped JSON number as float. Structural sequence/generation/head values remain validated as integral ordering metadata.

## Intentionally preserved open questions

Metric cadence, final checkpoint cadence, Chronicle segmentation/compression, compaction policy, archive permanence, PRNG replacement, full-game scale ceilings, gameplay formulas, balance values, and Android I/O behavior remain open exactly as required by the governing documents.

---

# Phase E strategic-loop reconstruction addendum

## Status

The original Phase 0 machine-readable definitions for `ShowPlan`, `ShowResult`, local audience records, hot/cold state payloads, touring route/directive details, booking/show effects, influence effects, media-resolution effects, explainability records, and strategic tuning remain **not supplied**. Phase E therefore performs a fourth bounded **controlled reconstruction** in typed GDScript and test-fixture tuning data. It does not claim to reproduce the unavailable original schema package.

## Directly reconstructed contracts

Phase E derives only responsibilities directly stated by the governing GDD, Technical Architecture, Canonical Data Schemas & Domain Contracts, and Build Plan: touring companies reference rather than own people; routine cards are generated from touring personnel/directives/program/title/availability context; show resolution returns structured results/effects rather than mutating downstream systems; audience state retains local overness/heat/shine/momentum while drawing power remains derived; market influence retains bounded audience/media/business/infrastructure components; material cash movements post through the reconciled ledger; local television remains a generic MediaDeal implementation; and hot/cold activation requires qualifying conditions plus RandomService.

## Controlled implementation choices

- `ShowPlan` and `ShowResult` are narrow runtime objects containing only the fields required to drive the Phase E loop and explain its outcomes. They are not declared final production schemas.
- Provisional Phase E formula coefficients, thresholds, decay values, hot/cold probabilities, venue/travel/production costs, and media defaults live in the synthetic fixture/ruleset tuning dictionary exposed through `content_index.phase_e_tuning`. They are acceptance tuning, not final balance.
- Phase E uses the existing open `CampaignState.world_state` extension point for booker assignment, approved major outcomes, market focus, local media spend, financial stress, and market-visit streaks. These placements remain migration-aware because the missing original machine schema does not publish deeper nested records.
- Save/load restores only known integer-semantic values inside open world/Chronicle data after Godot JSON parsing. Event facts/explanations are canonicalized to nine decimal places at the DomainEvent boundary so saved Chronicle history is deterministic rather than dependent on one-ULP parser differences.
- HistoricalProjection is expanded only with Phase E values needed to reconstruct meaningful prior strategic state. History remains checkpoint plus ordered deltas and does not serialize a complete monthly CampaignState.

## Intentionally preserved open questions

Final balance, breakout frequency, detailed booking heuristics, split/merge depth beyond the current coherent hooks, advanced title politics, deep injuries/careers, sponsorship/merchandise/debt, national media/PPV/streaming, rival strategy, scouting, final Chronicle physical segmentation, and production UI remain open for later phases. A recovered original machine-schema package must be compared against this controlled reconstruction before incompatible shapes are silently adopted.

---

# Phase F competitive-world reconstruction addendum

## Status

The original Phase 0 machine-readable definitions for organizational scouting reports, pending contract negotiations, promotion-level relations, AI decision explanations and competitive-world tuning remain **not supplied**. Phase F therefore performs a fifth bounded **controlled reconstruction**. It does not claim that these provisional nested records reproduce an unavailable canonical schema.

## Directly reconstructed contracts

Phase F implements only responsibilities stated by the governing documents: organization-owned knowledge with known/estimated/unknown projections; familiarity and confidence that improve through scouting; exclusive contracts with offer, counteroffer, renewal, release and expiry pressure; separate Owner, Talent, Touring, Booker, Recovery and Diplomacy planners; identical player/AI command resolution; contested multi-component market influence; visible recovery behavior; shallow agreements and hostile-entry consequences; and Chronicle reconstruction without resimulation.

## Controlled implementation choices

- `content_index.phase_f_tuning` holds provisional strategy weights, recovery thresholds, roster targets, scouting margins and agreement thresholds. These are acceptance tuning, not final balance.
- `world_state.contract_negotiations_v1`, `promotion_relations_v1`, `pending_territory_violations_v1` and `talent_shares_v1` are versioned migration-aware extension records.
- Scouting may read authoritative truth only inside phase-12 observation resolution to create a bounded, biased estimate. Rival planners consume only KnowledgeProjection values and never receive that truth.
- AI decision explanations retain goal, observed state, strategy weight, pressure/opportunity/inertia where applicable, bounded noise and principal reasons. They are explainability records, not a final UI schema.
- HistoricalProjection adds contract, knowledge and promotion-relation state; Chronicle remains sparse checkpoint plus ordered deltas and does not replay AI, commands or RandomService.

## Intentionally preserved open questions

Deep contract clauses and disputes, detailed career/injury development, ownership succession, acquisitions, sophisticated alliances and talent exchanges, final AI utility functions, final scouting calibration, production balance, UI presentation and physical Chronicle segmentation remain open.


---

# Phase F-R ownership-seat reconciliation addendum

## Status and provenance

The preserved `The_Business_Canonical_Data_Schemas_and_Domain_Contracts_v0_1_HISTORICAL_BASELINE.docx` remains unchanged historical implementation evidence. GDD v0.3, Technical Architecture v0.3 and the Post-Phase-F Governing Reconciliation Record explicitly supersede one historical runtime meaning: the player may not be represented as a Person. Phase F-R therefore performs a deliberate **controlled reconciliation**, not a retroactive edit of the historical schema baseline.

## Runtime-state delta

`CampaignState.state_schema_version` advances from 1 to 2. `OwnershipSeatState` removes `owner_person_id`; its closed current field set is `promotion_id` and `transition_pending`. `PromotionState.controlling_owner_person_id` is **not** removed or reinterpreted: it remains the in-world NPC/historical ownership reference. `role.owner` and static content `owner_person_seed_id` likewise remain NPC content contracts.

The v1 -> v2 migration removes only the obsolete seat-person field, records the legacy value in `migrations_applied`, advances the state schema, and preserves promotion-owner semantics unchanged. Historical architecture `0.2.0` save manifests are accepted only as an explicit migratable source; current writes use architecture `0.3.0`. This avoids silently treating an old player-avatar identity as current truth.

## Command and Chronicle delta

Player command issuers are promotion-scoped through the non-person Ownership Seat and may not supply `person_id`. AI/automation/system issuers retain Person references where appropriate. HistoricalProjection now records the ownership seat separately from promotion owner Person references so control history and human governance cannot collapse into one identity.

## Creative extension seams

`ShowPlan` receives separate open context records for deliberate Presentation intent and WrestlingLanguage. These are bounded extension seams, not complete Phase F-R schemas or balance formulas. Deep audience belief, wrestling-language profiles, psychology, dynasties, scandal propagation, production map/UI and hands-on card editing remain deferred. RelationshipState stable Person references/tag IDs, Chronicle identity retention and the existing ShowPlan command/resolution path are the accepted future seams.

## Historical baseline protection

No Phase F-R tool or static check rewrites the preserved historical baseline DOCX or the Phase B static-content `we.phase0.schema.json` to pretend those artifacts always contained the reconciled rule. Any future recovered canonical machine package must be diffed against both the historical evidence and this explicit Phase F-R delta.
