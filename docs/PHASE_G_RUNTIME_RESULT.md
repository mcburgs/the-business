# Phase G Runtime Result

Phase: **G — Strategic Map / Playable Presentation**
Starting commit: `2e18d88164b46c7bd5d217a2d8fa4818af0c3f6e`
Starting parent: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Starting tree: `1102cc79c3c630361081b52c40ee9fa9333e648b`
Runtime: `4.7.2.stable.official.ed1daf0bf`
Game version: `0.0.0-phase-g`
Build phase: `G`
Status: **VERIFIED**

This record contains only executed Phase G acceptance results. Historical Phase F/F-R/F→G evidence remains preserved unchanged.

## Baseline

Before Phase G changes the repository was verified at the required commit/tree with a clean working tree. GitHub `main` was independently checked and pointed to the same commit. The pinned engine reported exactly:

```text
4.7.2.stable.official.ed1daf0bf
```

The pre-change static gate passed and the complete entering suite passed **33/33**.

## Static architecture/content gate

Command:

```text
python tools/static_repo_check.py
```

Final result: **PASS** — schema `we.phase_g.static_check.v1`; zero failures; zero warnings.

The Phase G extension rejects presentation imports/references that would bypass the application/query boundary, including direct domain/persistence/command authority, player-Person identity, raw promotion-influence truth and `true_value` escape hatches. It also checks the required session/query/map/default-root seams.

## Complete automated suite

Command:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=/mnt/data/phase_g_work/final_evidence/phase_g_tests.json
```

Final result: **PASS**

- discovered: **37**
- passed: **37**
- failed: **0**
- harness failures: **0**
- runtime metadata: game version `0.0.0-phase-g`, phase `G`

The four added Phase G tests pass:

- `phase_g_runtime_bootstrap`
- `phase_g_owner_projection`
- `phase_g_presentation_scene_and_history`
- `phase_g_command_and_month_flow`

## F→G permanent defect regressions

The complete-suite command above explicitly reports the named test `f2g_adversarial_regressions`: **PASS**. The retained regressions for F2G-001 cross-promotion command authority, F2G-002 caller-authored media economics and F2G-003 expired-booker authority remain green.

## Phase F competition regression

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=f2g_final_regression
```

Result: **PASS**

- 24/24 months completed
- final date `2003-01-01`
- save round-trip PASS
- all three promotions active
- 10 active contracts
- 3 agreements
- 450 knowledge observations
- authoritative invariant status PASS

## Five-year multi-seed soak

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=/mnt/data/phase_g_work/final_evidence/phase_g_5_year_soak.json
```

Result: **PASS**

- 8 runs × 60 months
- repeated-seed deterministic replay PASS
- 7 unique seeds -> 7 distinct world fingerprints
- all 24 promotion endings active
- maximum market concentration `0.7584463303`
- policy wins: balanced `2`, defensive `1`, expansionist `5`
- zero errors

Every `runs` payload, including every world fingerprint and mechanical metric, is value-for-value equal to the accepted F→G soak record at `tests/adversarial/evidence/F2G-STRAT-001/phase_f_regression_5_year_soak.json`. Only aggregate build metadata changes from F-R/`0.0.0-phase-f-r` to G/`0.0.0-phase-g`. Presentation work therefore introduced no simulation-result drift.

## Save / Chronicle / historical reconstruction

Directed retained checks all pass:

- `phase_d_chronicle_reconstruction`: PASS; historical reconstruction runs without simulation/RNG
- `phase_d_save_service`: PASS
- `phase_e_chronicle_save`: PASS
- `phase_f_chronicle_save`: PASS
- `phase_g_presentation_scene_and_history`: PASS; current CampaignState/Chronicle remain unchanged by map selection or historical inspection

## Fresh editor/import

Command:

```text
godot --headless --editor --path . --quit-after 120
```

Result: **PASS**, exit `0`. No parser/import/project-configuration error or warning attributable to repository source/content was retained. Legitimate Godot `.gd.uid` files generated for new Phase G scripts are retained.

## Presentation runtime and visual QA

The default `game_root.tscn` was launched with the pinned engine under a real X11 rendering path using software OpenGL (`llvmpipe`) and dummy audio. Each capture exited `0`; final logs contain no `ERROR`, `SCRIPT ERROR` or parse error. Xvfb reports only the expected inability to change V-Sync mode.

Reference capture form:

```text
xvfb-run -a env LIBGL_ALWAYS_SOFTWARE=1 godot --audio-driver Dummy --disable-vsync --path . --rendering-method gl_compatibility -- --capture=<surface> --capture-path=<scratch>.png --capture-size=1440x900
```

Rendered and manually inspected:

- initial strategic map — 1440×900
- market selected — 1440×900
- people/roster — 1440×900
- touring context — 1440×900
- Chronicle/history — 1440×900
- post-month-advance state — 1440×900
- initial strategic map — 720×900 narrow layout

Visual result: **PASS**. No clipping, overlap, unreadable key/value collapse, broken anchoring, unusable contrast, excessive table density or misleading territory-ownership presentation remains. The map dominates the reference home, selected-market feedback is visible, controlled and observed rival routes are visually distinct, people retain named identity, Chronicle is reachable, post-month cash/date changes are legible, and the narrow layout retains large tap targets without hover-only requirements.

The QA PNG/log files are execution scratch outside the repository and are intentionally not staged.

## Architecture result

Phase G keeps the presentation as a client:

```text
CampaignState / Chronicle
    -> OwnerPresentationQuery
    -> KnowledgeQueryService / ChronicleQueryService
    -> StrategicHome / StrategicMapView
```

Player intent follows:

```text
StrategicHome
    -> CampaignSession
    -> CommandEnvelope
    -> CommandRouter
    -> pending canonical commands
    -> MonthPipeline
    -> authoritative state
    -> fresh OwnerPresentationQuery
```

The controlled promotion comes from the non-person `OwnershipSeatState`. No player Person/avatar state is introduced. Rival information is knowledge-limited/estimated. Historical inspection reconstructs recorded state and does not re-simulate.

## Final hygiene

Final repository hygiene was executed after staging with both commands:

```text
git diff --check
git diff --cached --check
```

Result: **PASS** for both commands. No `.godot` cache, logs, transient saves, screenshots, test scratch or generated build output is staged. Legitimate new `.gd.uid` files are staged. The exact staged tree hash is reported by the execution handoff because embedding a Git tree hash in the tree itself would be delightfully recursive and useless.
