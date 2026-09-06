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
