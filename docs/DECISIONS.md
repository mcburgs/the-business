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

**Status:** Accepted pending artifact availability  
**Decision:** Preserve `content/schemas/` as the canonical integration boundary, but do not reverse-engineer or invent `we.phase0.schema.json` during Phase A.  
**Reason:** The supplied Canonical Data Schemas & Domain Contracts document references a separate machine-consumable schema package, but that JSON package was not present among the supplied files. Phase A does not silently recreate a Phase 0 deliverable.
