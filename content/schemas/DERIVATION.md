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
