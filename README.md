# The Business

**The Business** is the working repository for the Wrestling Empire game project: an offline, simulation-first wrestling-promotion strategy game built in Godot.

This repository is currently at **Phase A: Repository Skeleton**.

## Current baseline

- Engine: **Godot 4.7.2-stable**
- Language: **typed GDScript**
- Runtime posture: offline, single-process simulation with a replaceable presentation shell
- Primary future target: Android phone
- Development/integration target: Windows desktop plus stock-Godot headless command line
- Canonical remote: `https://github.com/mcburgs/the-business.git`

## Architectural rule

The scene tree is a shell around the domain model. Presentation may depend on Application; Application may depend on Domain; dependencies point inward. Simulation-domain code must not require Nodes, rendering, audio, input, wall-clock access, or global randomness simply to exist.

Phase A contains no gameplay formulas and no production Great Lakes 1975 content. Those belong to later controlled phases.

## Start here

1. Read `BUILD.md`.
2. Run `python tools/static_repo_check.py`.
3. Run the stock-Godot headless test gate:

   `godot --headless --path . --script res://tests/runner.gd`

4. Open the project in **Godot 4.7.2-stable** only after the headless gate is clean.

The full governing documents are preserved under `docs/governing/`.
