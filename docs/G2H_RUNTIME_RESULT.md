# G→H Adversarial Interaction Runtime Result

Gate: **G→H — Adversarial Interaction Validation**
Starting commit: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Starting tree: `a075ea266632c33f5940b12860b5bcffcf3f0ecc`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Game/build version retained: `0.0.0-phase-g` / `G`
Status: **VERIFIED**

## Baseline verification

The exact published Phase G baseline was reconstructed and checked before modification:

- HEAD `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`;
- tree `a075ea266632c33f5940b12860b5bcffcf3f0ecc`;
- clean working tree;
- GitHub `main` independently confirmed at the same commit/tree;
- Godot `4.7.2.stable.official.ed1daf0bf`;
- baseline static gate PASS, zero failures/warnings;
- baseline complete suite PASS: 37 discovered / 37 passed / 0 failed / 0 harness failures.

## Pre-fix hostile reproduction

A disposable worktree at the exact frozen Phase G commit reproduced the material interaction failures before fixes:

- five identical route interactions -> pending count `5`;
- immediate double month activation -> turn `0` to turn `2`, both calls passed;
- stale market callback changed selection from `market.great_lakes.hamilton` to nonexistent `market:STALEG2H`;
- three Chronicle dates triggered repeated `OptionButton` parent-ownership engine errors during historical rendering.

The fixes and classifications are recorded in `docs/G2H_FINDINGS.md`.

## Retained attack harness

`tests/integration/test_g2h_interaction_regressions.gd` provides deterministic regression coverage for command coalescing, duplicate-month suppression, stale envelope rejection, F2G cross-promotion authority, navigation/history churn, stale selection, knowledge-boundary probing and touring-churn determinism.

`tools/adversarial_runner/g2h_interaction_run.gd` exercises the real `StrategicHome` / `StrategicMapView` presentation path. Its machine schema is `we.g2h.interaction.v1`.

Headless harness result: PASS.

Measured hostile interaction values:

- 48 repeated route/budget/market-focus/push callbacks -> 4 pending final intents;
- touch market selected: `market.great_lakes.chicago`;
- touch drag pan delta: `(30, 25)`;
- immediate duplicate-month attack: turn `0` -> `1` exactly;
- history dates exercised: 3;
- navigation cycles: 40;
- historical reselections: 50;
- failures: none.

## Final complete automated gate

Command:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=<external>/g2h_tests_final.json
```

Result:

- discovered: 38;
- passed: 38;
- failed: 0;
- harness failures: 0;
- `g2h_interaction_regressions`: PASS;
- `f2g_adversarial_regressions`: PASS.

The permanent F2G-001/002/003 regressions therefore remain green after G→H hardening.

## Competition regression

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=g2h_competition
```

Result: PASS.

- completed months: 24/24;
- final date: `2003-01-01`;
- all three promotions active;
- contract records: 10;
- agreements: 3;
- knowledge observations: 450;
- invariant status: PASS;
- save round-trip: PASS.

## Five-year multi-seed regression

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=<external>/g2h_5_year_soak.json
```

Result: PASS.

- runs: 8 x 60 months;
- repeated-seed deterministic: true;
- unique seeds: 7;
- distinct world fingerprints: 7;
- active promotion endings: 24/24;
- maximum market concentration: `0.7584463303`;
- policy wins: balanced 2 / defensive 1 / expansionist 5;
- errors: none.

The complete G→H soak JSON is **exactly value-for-value equal** to the final accepted Phase G soak JSON, including every per-run world fingerprint and metric payload. The interaction fixes therefore introduce zero simulation drift.

## Save / Chronicle regression

The final complete suite retains PASS for:

- `phase_d_chronicle_reconstruction`;
- `phase_d_save_service`;
- `phase_e_chronicle_save`;
- `phase_f_chronicle_save`;
- `phase_g_presentation_scene_and_history`;
- `g2h_interaction_regressions` historical/navigation checks.

Repeated G→H historical inspection leaves both current CampaignState and Chronicle snapshots unchanged.

## Editor/import

Command:

```text
godot --headless --editor --path . --quit-after 120
```

Result: PASS, exit 0. No parser/import/project-configuration errors attributable to repository source/content. The pinned editor generated and retained legitimate `.gd.uid` sidecars for the new G→H regression and adversarial harness.

## Rendered interaction / visual QA

The G→H harness was executed under an actual X11/OpenGL compatibility rendering path with dummy audio. Result: PASS with no script/parser/runtime errors attributable to repository source. The only retained graphical warning is the environment's unsupported V-Sync mode.

Visual inspection passed for:

- 1280x720 hostile-interaction Chronicle state after touch/command/month/navigation/history churn;
- 1440x900 normal post-month strategic map;
- 720x900 narrow Chronicle surface.

No clipping, overlap, duplicate Chronicle selector/card, broken hierarchy, stale-market rendering, or unusable touch-target regression was observed. The narrow layout remains viable for Phase H adaptation.

## Static / hygiene

Final source static schema: `we.g2h.static_check.v1`.

Result: PASS, zero failures, zero warnings.

The gate extends static scar tissue for:

- player-intent coalescing;
- duplicate-month re-entry protection;
- stale-selection repair;
- synchronous historical transient-card ownership;
- retained G→H regression/harness/evidence documents.

`git diff --check` passes before staging. Final staged whitespace check, exact staged file list and staged tree hash are produced at the commit-ready handoff and are not embedded here because changing this tracked document would itself change that tree.

## Gate conclusion

G→H is verified. The Phase G player-facing loop remains map-first, knowledge-limited, non-person Ownership Seat controlled and canonically command-routed under hostile interaction. Four interaction defects were fixed without altering simulation meaning. Phase H Android integration is now the next authorized development phase once this verified G→H tree is committed/published.
