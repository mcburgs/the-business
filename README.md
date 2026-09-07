# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase F-R: Post-Phase-F Reconciled Baseline**, verified under the pinned Godot 4.7.2-stable runtime. Phase F remains historically accepted; F-R aligns the implementation with the reconciled GDD/Architecture v0.3 by making player control a non-person Ownership Seat, preserving NPC owner/promoter Persons, adding explicit save migration, and freezing the creative/system seams required before F->G adversarial testing.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Verified runtime: **4.7.2.stable.official.ed1daf0bf**
- Game version: **0.0.0-phase-f-r**
- Build phase: **F-R**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or uncontrolled global randomness simply to exist.

Great Lakes is data. The 1975 start date is content. Authored promotion/market/roster counts are scenario counts, not engine ceilings.

The canonical 15-phase monthly pipeline remains the only turn-resolution spine. Phase F freezes a planning snapshot in phase 2, gives every controlled promotion a knowledge-filtered planning view, and commits resulting AI/automation commands through the same phase-3 CommandRouter used by players. Owner, Talent, Touring, Booker, Recovery and Diplomacy decisions are separate modules. Booker AI supplies priorities and constraints; the Phase E BookingSystem still creates routine cards. Markets remain component influence spaces rather than owned flags, money remains ledger-backed, and Chronicle reconstruction remains checkpoint-plus-delta replay without AI, commands, RNG or simulation.

Phase F-R preserves Phase F mechanics and deliberately keeps careers, clauses, diplomacy, recovery and scouting shallow. It does **not** implement deep injuries/medical systems, ownership succession, acquisitions, sophisticated alliances, advanced national media/PPV/streaming, merchandise/sponsorship/debt depth, production UI, final balance, or final campaign population.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase F-R retains the Phase F bounded controlled reconstruction for scouting observations, pending contract negotiations, promotion relations, AI explanations and competition tuning. The derivation boundary and open policy questions are recorded in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`.

## Start here

1. Read `BUILD.md`, `docs/PHASE_F_R_ACCEPTANCE.md`, and the two F-R audit records.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Run a three-promotion Phase F competition simulation:

   `godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=phase_f_acceptance`

5. Run the repeated/varied-seed five-year soak matrix:

   `godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248`

6. Preserve historical Phase F evidence and the verified F-R baseline. See `docs/PHASE_F_R_RUNTIME_RESULT.md` for the current pinned-engine evidence.

The full governing documents are preserved under `docs/governing/`.
