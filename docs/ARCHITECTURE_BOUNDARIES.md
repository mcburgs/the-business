# Architecture Boundaries

The governing Technical Architecture defines inward dependencies:

```text
Presentation -> Application -> Simulation Domain
                         \-> Persistence / content-facing services as explicit boundaries
```

The domain is simulation truth. It must not require scene-tree presence, renderer state, screen size, audio, input devices, wall-clock calls, or direct global randomness.

## Repository layers

- `app/`: bootstrap, session lifecycle, command routing, UI-facing queries.
- `domain/`: pure simulation entities/systems/rules/invariants.
- `persistence/`: save/recovery/migration/codec infrastructure.
- `content/`: validated static definitions, campaigns, schemas, localization.
- `presentation/`: scenes, Controls, map/dashboard/panels, view-facing code.
- `assets/`: governed reproducible UI/portrait/audio/font assets and ledger.
- `tools/`: content/build/simulation tooling.
- `tests/`: stock-Godot unit, integration, golden, soak, and fixtures.

Phase A implements only the shell and enforcement scaffolding required to keep those boundaries real.
