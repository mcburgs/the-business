# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase D: Headless Core Loop**, verified under the pinned Godot 4.7.2-stable runtime. Phase A established the architecture baseline, Phase B the generic static-content foundation, Phase C the authoritative deterministic campaign-state kernel, and Phase D adds the deterministic month-resolution spine, recorded-history Chronicle, reconciled ledger plumbing, save/recovery orchestration, and generic headless simulation command.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Verified runtime: **4.7.2.stable.official.ed1daf0bf**
- Game version: **0.0.0-phase-d**
- Build phase: **D**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or uncontrolled global randomness simply to exist.

Great Lakes is data. The 1975 start date is content. Authored promotion/market/roster counts are scenario counts, not engine ceilings.

Phase D represents one player turn as an inspectable 15-phase monthly pipeline. It resolves a turn transactionally against cloned authoritative state and Chronicle data, publishes only after successful postflight validation, journals permanent DomainEvents, maintains sparse HistoricalProjection checkpoints plus ordered deltas, preserves historical identity through an identity catalog, supports reconciled ledger postings, and saves current state plus Chronicle coherently. Historical reconstruction is read-only recorded-history reconstruction; it does not rerun simulation and does not consume RandomService.

Phase D deliberately does **not** implement Phase E touring, booking, show, audience, influence, market, media, economy, career, diplomacy, scouting, or strategic-AI gameplay formulas. Those phase boundaries exist as narrow extension points so later systems can plug in without redesigning the spine.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase B reconstructed only the minimum static-content subset required by its gate; Phase C reconstructed only directly supported runtime-state/command/save contracts; Phase D similarly reconstructs only the Chronicle, turn, save-orchestration, and ledger machine structures directly supported by governing prose. The derivation boundary and open policy questions are recorded in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`.

## Start here

1. Read `BUILD.md` and `docs/PHASE_D_ACCEPTANCE.md`.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Run the Phase D synthetic acceptance simulation:

   `godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_d --months 12 --seed 424242 --save-roundtrip --save-id=phase_d_acceptance`

5. Preserve the verified Phase D gate when making later changes: fresh editor import under **Godot 4.7.2-stable** must remain free of retained parser/import/project-configuration errors. See `docs/PHASE_D_RUNTIME_RESULT.md` for recorded evidence.

The full governing documents are preserved under `docs/governing/`.
