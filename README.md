# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase B: Content Foundation**, verified under the pinned Godot 4.7.2-stable runtime. Phase A remains the foundational architecture baseline; Phase B establishes the generic static-content and skeletal Great Lakes 1975 campaign foundation.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or global randomness simply to exist.

Phase B adds static campaign/content infrastructure only. The Great Lakes map, 1975 start date, three promotions, and authored entity counts are data, not engine limits. Mutable CampaignState, commands, RNG, simulation formulas, save codecs, knowledge projection, and Chronicle runtime implementation remain Phase C or later work.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase B therefore contains a deliberately labeled controlled reconstruction of the minimum static-content subset required by the Phase B gate. See `content/schemas/DERIVATION.md`.

## Start here

1. Read `BUILD.md` and `docs/PHASE_B_ACCEPTANCE.md`.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Preserve the verified Phase B gate when making later changes: fresh-clone editor import under **Godot 4.7.2-stable** must remain free of parser/import warnings. See `docs/PHASE_B_RUNTIME_RESULT.md` for the recorded Phase B verification.

The full governing documents are preserved under `docs/governing/`.
