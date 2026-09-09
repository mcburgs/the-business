# Build and Verification

## Pinned engine

Use **Godot 4.7.2-stable, standard build**. Do not silently upgrade the project to another engine line. Any deliberate engine change requires a version-control checkpoint and a CHANGELOG entry.

Verify the executable first:

```text
godot --version
```

The verified official runtime is `4.7.2.stable.official.ed1daf0bf`.

## Static repository/content/strategic-loop check

From the repository root:

```text
python tools/static_repo_check.py
```

For Phase H this preserves the complete Phase A-F-R/F→G/G/G→H gate and additionally checks Android/mobile isolation: the reversible arm64 debug preset, square dual-orientation design base, lifecycle/persistence seams, exact save/recovery encoding, direct-touch map behavior, and absence of Android-specific domain authority. It does not replace an engine run or physical Pixel evidence.

## Canonical headless gate

```text
godot --headless --path . --script res://tests/runner.gd
```

The runner:

- boots under stock Godot without an editor plugin;
- recursively discovers `test_*.gd` scripts under `tests/unit/` and `tests/integration/`;
- executes all retained Phase A-F tests plus F-R ownership-seat/migration regressions, the F→G adversarial defect regressions, and Phase G presentation/query/command tests;
- emits JSON-line diagnostics prefixed `WE_DIAG`;
- emits one machine-readable summary prefixed `WE_TEST_SUMMARY`;
- writes a JSON result artifact to `user://diagnostics/headless-results.json` by default;
- exits `0` on pass, `1` on test failure, `2` on harness/discovery failure, and `3` if tests pass but the result artifact cannot be written.

An explicit output location may be supplied after `--`:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=res://tests/output/headless-results.json
```

`tests/output/*.json` is intentionally ignored by Git.


## Phase G presentation gates

Phase G acceptance is controlled by `docs/PHASE_G_ACCEPTANCE.md` and recorded in `docs/PHASE_G_RUNTIME_RESULT.md`. The default scene is the strategic map home. Presentation reads through `OwnerPresentationQuery` and writes through `CampaignSession -> CommandEnvelope -> CommandRouter`; month advancement remains `MonthPipeline`.

A playable/reference render can be launched normally with the pinned engine:

```text
godot --path .
```

Phase G visual QA uses the built-in capture arguments on the default scene under a graphical display. Android export is intentionally not part of this phase.

## G→H adversarial interaction gate

The accepted G→H gate attacks the complete Phase G player-facing interaction path before Android integration. It retains the non-person Ownership Seat, knowledge-limited presentation and canonical command/month authority while adding hostile-input regression coverage. Governing records are `docs/G2H_ACCEPTANCE.md`, `docs/G2H_FINDINGS.md`, and `docs/G2H_RUNTIME_RESULT.md`.

Run the deterministic interaction harness headlessly:

```text
godot --headless --path . --script res://tools/adversarial_runner/g2h_interaction_run.gd
```

The harness exercises real `StrategicHome`/`StrategicMapView` touch tap/drag, repeated setter callbacks, immediate duplicate month activation, surface churn, stale market selection, repeated historical inspection and knowledge-boundary checks. The complete automated suite also retains the same behaviors in `test_g2h_interaction_regressions.gd`.

G→H does **not** perform Android export/package work. That remains Phase H.

## Phase H Android / Pixel target build

Phase H is governed by `docs/PHASE_H_ACCEPTANCE.md`, with measured off-device evidence in `docs/PHASE_H_RUNTIME_RESULT.md` and physical evidence in `docs/PHASE_H_DEVICE_RESULT.md`.

The Android debug preset is `Android Debug` and deliberately uses the reversible development package ID `com.mcburgs.thebusiness.dev`. It exports an arm64 APK only and commits no production signing credentials.

The verified Phase-H Android build used Temurin OpenJDK 17.0.20.1+1, Android Platform 35, Build-Tools 35.0.1, Platform-Tools/adb 37.0.1, command-line tools 16.0, NDK 28.1.13356709, CMake 3.10.2.4988404, and matching **Godot 4.7.2-stable export templates**. Keep all SDK/JDK/template/cache paths outside the repository.

Godot editor-local paths must point to the installed JDK and SDK. Then export from the repository root:

```text
godot --headless --path . --export-debug "Android Debug" build/android/the-business-phase-h-debug.apk
```

The generated APK is intentionally ignored by Git. Record its filename, byte size and SHA-256 in the Phase-H device/runtime evidence rather than committing it.

The project uses `canvas_items` + `expand` with a square 720x720 design base and sensor orientation. Pixel 9a acceptance confirmed that both portrait and landscape remain functional, including repeated rotation; Phase H therefore retains responsive dual-orientation behavior rather than imposing a domain-significant lock. Landscape is visibly dense and is a Phase-I presentation-quality target.

Normal startup uses the canonical `CampaignSession`/`SaveService` persistence seam. Successful month resolution checkpoints only after authoritative completion; lifecycle callbacks request/flush the same checkpoint seam and never run a second month resolver. The verified APK is `the-business-phase-h-debug.apk` (SHA-256 `43fd8d26529fc7bdf90456bd47326943da01fe6f715d1512cd5780db6d122040`) and passed install/launch/touch/lifecycle/relaunch acceptance on a Google Pixel 9a running Android 17.

## Phase F-R reconciliation gates

Phase F-R does not replace historical Phase F evidence. It adds the player-identity reconciliation and reruns the complete Phase F runtime surface. Current evidence is recorded in `docs/PHASE_F_R_ACCEPTANCE.md` and `docs/PHASE_F_R_RUNTIME_RESULT.md`; audit records are `docs/PHASE_F_R_OWNERSHIP_AUDIT.md` and `docs/PHASE_F_R_ARCHITECTURE_SEAM_AUDIT.md`.

The required competition and soak commands remain the Phase F commands shown below. The F-R soak result is copied to `tests/soak/phase_f_r_5_year_soak.json`; the historically accepted `tests/soak/phase_f_5_year_soak.json` remains unchanged.

## F→G adversarial strategic gate

The accepted package is `F2G-STRAT-001`. It targets frozen Phase F-R commit `20ddeaa45bfdbfce98be066cdc13d656d5d6363a` through `AIPlanningView -> policy -> CommandEnvelope -> CommandRouter -> MonthPipeline`. Gameplay policies do not receive debug truth or direct authoritative mutation.

The required directed pass is ten profiles × three runs, using seeds `424242,424242,424243` for 24 months each. Long-horizon supplements retain a 65-month financial self-destruction run and a 60-month random-valid-command run. Exact commands, raw logs, transcripts, diagnostics, invariant checks, findings and repro bundles live under `tests/adversarial/evidence/F2G-STRAT-001/` and `tests/adversarial/repro/`.

Gate records are `docs/F2G_ACCEPTANCE.md`, `docs/F2G_RUNTIME_RESULT.md`, and `docs/F2G_FINDINGS.md`. The gate passes only when no known stop-the-line exploit remains, accepted fixes/regressions are green, same-seed determinism holds, and remaining observations are classified.

## Phase E headless strategic-loop gates

The generic CLI under `tools/simulation_cli/` supports the retained Phase D fixture plus Phase E good/bad strategic schedules. Application/domain code contains no acceptance-scenario branch.

Coherent strategy:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_good --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_good_acceptance
```

Poor/concentrated strategy with the same seed:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_bad --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_bad_acceptance
```

The decisive acceptance proposition is comparative: materially different command schedules must create materially different, explainable results in stars, programs, markets/influence and money while remaining deterministic, saveable and historically reconstructable.

## Phase F competitive-world gates

Single competition run:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=phase_f_acceptance
```

Five-year repeated/varied-seed soak:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=res://tests/soak/phase_f_5_year_soak.json
```

The soak output uses schema `we.phase_f.soak.v1` and records fingerprints, policy winners, promotion survival, market concentration, shows, AI decision families, contract/diplomacy events, scouting, recovery, cash stress and Chronicle counts.

## Phase F acceptance evidence

`docs/PHASE_F_ACCEPTANCE.md` is the controlling Phase F checklist. `docs/PHASE_F_RUNTIME_RESULT.md` records pinned-engine commands/results. `tests/soak/phase_f_5_year_soak.json` and `tests/soak/PHASE_F_SOAK_REPORT.md` are the machine-readable and human-readable long-run records.

## Phase E acceptance evidence

`docs/PHASE_E_ACCEPTANCE.md` is the controlling Phase E implementation checklist and strategic comparison. `docs/PHASE_E_RUNTIME_RESULT.md` records the pinned-engine commands/results. The gate proves automatic booking without manual cards, deterministic show/audience/economy propagation, local audience divergence, component influence, ledger reconciliation, qualified hot/cold behavior, real-gameplay Chronicle reconstruction without resimulation/RNG, exact save/load/recovery, and retained Phase A-D regression safety.

The original standalone machine-schema package remains unavailable. Phase E reconstructs only contracts directly supported by governing prose and records those boundaries in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`.

## Earlier acceptance evidence

Phase C acceptance remains recorded in `docs/PHASE_C_ACCEPTANCE.md` and `docs/PHASE_C_RUNTIME_RESULT.md`; Phase A/B records remain unchanged. Later phases must not reopen those baselines without a genuine architecture defect.

## Parse-only checks

The full headless runner is the acceptance command because it exercises discovery and runtime behavior, but parse-only checks can isolate syntax failures:

```text
godot --headless --path . --script res://tests/runner.gd --check-only
```

## Fresh editor import

After headless tests pass, verify a fresh import under the pinned engine. For command-line acceptance the equivalent shape is:

```text
godot --headless --editor --path . --quit-after 120
```

Phase F-R requires no retained parser/import/project-configuration errors attributable to source/content. Generated `.godot/` cache data remains ignored. Legitimate new `.gd.uid` sidecars generated by the pinned editor are retained in Git.

## Final staged-tree hygiene

Before committing a verified phase baseline:

```text
git diff --cached --check
```

Do not commit generated editor/build caches, logs, runtime test output, failure artifacts, or temporary files.

## Launch shell

```text
godot --path .
```

The launch shell remains deliberately minimal and must not become an owner of domain state.

## Windows note

If Godot is not on PATH, invoke the pinned console executable directly. Example PowerShell shape:

```text
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/runner.gd
```

Use the actual local filename/path rather than changing repository files to match one workstation.

## Phase boundary

Phase F now includes strategic rival AI, scouting/knowledge growth, talent negotiation, recovery and shallow diplomacy. It intentionally does not claim deep careers/injuries, ownership succession, acquisitions, sophisticated alliances, advanced national media/PPV/streaming, sponsorship/merchandise/debt, production UI or final balance/content.
