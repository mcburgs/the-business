# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository has **verified Phase H: Pixel / Android Target Build and Integration** and is executing the mandatory **H→I adversarial device/persistence gate**. H→I has reproduced and repaired real interrupted-save and corruption-detection defects; final Android/Pixel gate evidence is still required before Phase I may begin.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Verified runtime: **4.7.2.stable.official.ed1daf0bf**
- Game version: **0.0.0-phase-h**
- Build phase: **H**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or uncontrolled global randomness simply to exist.

Great Lakes is data. The 1975 start date is content. Authored promotion/market/roster counts are scenario counts, not engine ceilings.

The canonical 15-phase monthly pipeline remains the only turn-resolution spine. Phase F freezes a planning snapshot in phase 2, gives every controlled promotion a knowledge-filtered planning view, and commits resulting AI/automation commands through the same phase-3 CommandRouter used by players. Owner, Talent, Touring, Booker, Recovery and Diplomacy decisions are separate modules. Booker AI supplies priorities and constraints; the Phase E BookingSystem still creates routine cards. Markets remain component influence spaces rather than owned flags, money remains ledger-backed, and Chronicle reconstruction remains checkpoint-plus-delta replay without AI, commands, RNG or simulation.

Phase H preserves the Phase F/F-R/F→G/G/G→H simulation and deliberately keeps later depth shallow. G→H interaction protections remain permanent. Phase H adds only target-device seams: responsive/touch presentation, persistent startup, lifecycle checkpointing, exact save/relaunch preservation, last-good recovery and a reversible Android debug export preset. It does **not** add Android-specific simulation rules, a second save model, deep injuries/medical systems, ownership succession, acquisitions, sophisticated alliances, advanced national media/PPV/streaming, merchandise/sponsorship/debt depth, a complete manual card editor, final balance, final art/audio, or final campaign population.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase F-R retains the Phase F bounded controlled reconstruction for scouting observations, pending contract negotiations, promotion relations, AI explanations and competition tuning. The derivation boundary and open policy questions are recorded in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`.

## Start here

1. Read `BUILD.md`, `docs/H2I_ACCEPTANCE.md`, `docs/H2I_FINDINGS.md`, `docs/H2I_RUNTIME_RESULT.md`, `docs/H2I_DEVICE_RESULT.md`, then the retained Phase-H/G→H records.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Run the retained G→H interaction harness:

   `godot --headless --path . --script res://tools/adversarial_runner/g2h_interaction_run.gd`

5. Run the H→I persistence attack:

   `godot --headless --path . --script res://tools/adversarial_runner/h2i_persistence_run.gd`

6. Run the three-promotion competition regression and the repeated/varied-seed five-year soak commands documented in `BUILD.md`.
7. With the matching Godot 4.7.2 Android export templates and Android SDK installed, export the Phase-H debug APK:

   `godot --headless --path . --export-debug "Android Debug" build/android/the-business-phase-h-debug.apk`

8. H→I closes only after final Android export evidence and the targeted physical Pixel abuse result are recorded in `docs/H2I_DEVICE_RESULT.md`.

The full governing documents are preserved under `docs/governing/`.
