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
