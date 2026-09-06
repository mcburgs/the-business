# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase C: Domain Kernel**, verified under the pinned Godot 4.7.2-stable runtime. Phase A established the architecture baseline, Phase B established the generic static-content foundation, and Phase C establishes the authoritative deterministic campaign-state kernel upon which later simulation phases will build.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Verified runtime: **4.7.2.stable.official.ed1daf0bf**
- Game version: **0.0.0-phase-c**
- Build phase: **C**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or uncontrolled global randomness simply to exist.

Great Lakes is data. The 1975 start date is content. The authored promotion/market/roster counts are scenario counts, not engine ceilings.

Phase C adds authoritative mutable `CampaignState`, stable runtime entity identity/stores, the command/result mutation boundary, controlled `RandomService`, invariant validation, explicit current-state codecs/migration scaffolding, and hidden-information knowledge projection. It does **not** implement the Phase D month-resolution simulation, Chronicle runtime, AI strategy, production booking/economy/touring resolution, or production UI.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase B contains a deliberately labeled controlled reconstruction of the minimum static-content subset required by its gate. Phase C separately reconstructs only the runtime-state/command/save contracts directly supported by the governing prose and records the remaining open nested shapes. See `content/schemas/DERIVATION.md`.

## Start here

1. Read `BUILD.md` and `docs/PHASE_C_ACCEPTANCE.md`.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Preserve the verified Phase C gate when making later changes: fresh editor import under **Godot 4.7.2-stable** must remain free of retained parser/import/project-configuration errors. See `docs/PHASE_C_RUNTIME_RESULT.md` for the recorded verification.

The full governing documents are preserved under `docs/governing/`.
