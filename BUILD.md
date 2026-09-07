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

For Phase F-R this preserves the complete Phase A-F gate and adds checks for the non-person Ownership Seat, explicit state migration, player issuer scoping, separate Presentation/WrestlingLanguage ShowPlan seams, F-R documentation/artifacts and retained historical Phase F soak evidence. It does not replace an engine run.

## Canonical headless gate

```text
godot --headless --path . --script res://tests/runner.gd
```

The runner:

- boots under stock Godot without an editor plugin;
- recursively discovers `test_*.gd` scripts under `tests/unit/` and `tests/integration/`;
- executes all retained Phase A-F tests plus F-R ownership-seat, migration, command-boundary, Chronicle and architecture-seam regressions;
- emits JSON-line diagnostics prefixed `WE_DIAG`;
- emits one machine-readable summary prefixed `WE_TEST_SUMMARY`;
- writes a JSON result artifact to `user://diagnostics/headless-results.json` by default;
- exits `0` on pass, `1` on test failure, `2` on harness/discovery failure, and `3` if tests pass but the result artifact cannot be written.

An explicit output location may be supplied after `--`:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=res://tests/output/headless-results.json
```

`tests/output/*.json` is intentionally ignored by Git.


## Phase F-R reconciliation gates

Phase F-R does not replace historical Phase F evidence. It adds the player-identity reconciliation and reruns the complete Phase F runtime surface. Current evidence is recorded in `docs/PHASE_F_R_ACCEPTANCE.md` and `docs/PHASE_F_R_RUNTIME_RESULT.md`; audit records are `docs/PHASE_F_R_OWNERSHIP_AUDIT.md` and `docs/PHASE_F_R_ARCHITECTURE_SEAM_AUDIT.md`.

The required competition and soak commands remain the Phase F commands shown below. The F-R soak result is copied to `tests/soak/phase_f_r_5_year_soak.json`; the historically accepted `tests/soak/phase_f_5_year_soak.json` remains unchanged.

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
