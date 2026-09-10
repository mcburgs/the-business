# H→I Runtime Result

Gate: **H→I — Adversarial Device and Persistence Validation**
Frozen baseline: `356e4fa2eb3c791e67ec0a2711df3d10e4db6487`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Status: **OFF-DEVICE VERIFIED — ANDROID EXPORT / PHYSICAL PIXEL EVIDENCE PENDING**

## Required commands

```text
python tools/static_repo_check.py
godot --headless --path . --script res://tests/runner.gd
godot --headless --path . --script res://tools/adversarial_runner/g2h_interaction_run.gd
godot --headless --path . --script res://tools/adversarial_runner/h2i_persistence_run.gd
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=h2i_competition
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=<external>/h2i_5_year_soak.json
godot --headless --editor --path . --quit-after 120
```

## Current results

- Runtime identity: PASS, exact pinned Godot.
- Static gate: PASS, schema `we.h2i.static_check.v1`, zero failures/warnings.
- Complete suite: PASS on canonical command, 41 discovered / 41 passed / 0 failed / 0 harness failures on the final off-device candidate.
- G→H hostile interaction: PASS; 48 repeated callbacks -> 4 final intents; duplicate month -> exactly one month; 40 navigation cycles; 50 historical reselections; touch/knowledge protections green.
- H→I persistence harness: PASS; 12 months, 12 relaunches, 9 injected interruption/recovery sequences, 90 historical projections checked read-only, 12 loadable `last_good` checks.
- Phase-F competition regression: PASS; 24/24 months, final `2003-01-01`, 3 active promotions, 10 contracts, 3 agreements, 450 knowledge observations, invariant PASS, save round-trip PASS.
- Five-year soak: PASS; 8 x 60 months; repeated seed deterministic; 7 unique seeds -> 7 distinct world fingerprints; 24/24 active-promotion endings; maximum market concentration `0.7584463303`; policy wins balanced 2 / defensive 1 / expansionist 5; errors none. The complete `runs` payload is value-for-value equal to accepted F→G evidence. Artifact SHA-256: `545c4d563de2dfca817878d08cdec9e198a2d464d07c8fcc01b0cad3a4f918a9`.
- Editor/import: PASS, exit 0 on the final off-device candidate; no parser/import/project-configuration errors observed.
- Android export/APK inspection: pending.

No simulation/domain tuning was changed by H→I. Final evidence must prove the long-run `runs` payload remains equal to the accepted F→G/Phase-H regression evidence.
