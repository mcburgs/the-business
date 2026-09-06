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
