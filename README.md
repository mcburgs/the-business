# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase E: Strategic Loop**, verified under the pinned Godot 4.7.2-stable runtime. Phase A established the architecture baseline, Phase B the generic static-content foundation, Phase C the authoritative deterministic campaign-state kernel, Phase D the deterministic month/Chronicle/save spine, and Phase E adds the first meaningful headless wrestling-business loop: touring, abstract booking, shows, local audience development, programs/titles, market influence, media, ledger-backed economics, and bounded hot/cold behavior.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Verified runtime: **4.7.2.stable.official.ed1daf0bf**
- Game version: **0.0.0-phase-e**
- Build phase: **E**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or uncontrolled global randomness simply to exist.

Great Lakes is data. The 1975 start date is content. Authored promotion/market/roster counts are scenario counts, not engine ceilings.

The canonical 15-phase monthly pipeline remains the only turn-resolution spine. Phase E populates logistics, booking, show resolution, audience/creative, media/markets and economy without reordering that pipeline or bypassing the command boundary. Booking generates routine ShowPlans automatically; ShowResolver returns structured results/effects; downstream phases apply audience, influence/media and ledger consequences. Local overness/heat/shine/momentum are authoritative while drawing power remains derived. Market influence remains a bounded component vector rather than ownership. Historical reconstruction remains read-only checkpoint-plus-delta replay with no BookingSystem, ShowResolver, simulation or RandomService dependency.

Phase E deliberately does **not** implement strategic rival AI, the full talent market, deep careers/injuries/diplomacy, advanced national media/PPV/streaming, merchandise/sponsorship/debt depth, production UI, final balance, or final campaign population. Those remain later phases.

## Schema note

The original standalone Phase 0 machine-readable schema package referenced by the governing contracts was not supplied. Phase B reconstructed only the minimum static-content subset required by its gate; Phase C reconstructed only directly supported runtime-state/command/save contracts; Phase D reconstructed Chronicle/turn/save/ledger structures; Phase E reconstructs only the directly supported ShowPlan/ShowResult/audience/hot-state/effect/tuning structures required by the strategic loop. The derivation boundary and open policy questions are recorded in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`.

## Start here

1. Read `BUILD.md` and `docs/PHASE_E_ACCEPTANCE.md`.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Run the Phase E coherent-deployment acceptance simulation:

   `godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_good --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_good_acceptance`

5. Compare it with the equal-seed poor-deployment fixture:

   `godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_bad --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_bad_acceptance`

6. Preserve the verified Phase E gate when making later changes: fresh editor import under **Godot 4.7.2-stable** must remain free of retained parser/import/project-configuration errors. See `docs/PHASE_E_RUNTIME_RESULT.md` for recorded evidence.

The full governing documents are preserved under `docs/governing/`.
