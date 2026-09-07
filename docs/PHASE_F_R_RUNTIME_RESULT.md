# Phase F-R Runtime Verification Result

## Environment

- Phase: **F-R — Post-Phase-F Reconciled Baseline**
- Starting repository commit: `e18f32240e1fb3b9c92916da3efc9072e6a2ea85`
- Game version: `0.0.0-phase-f-r`
- Architecture version: `0.3.0`
- Contract version: `0.2.0`
- Engine pin: `Godot 4.7.2-stable`
- Verified runtime: `4.7.2.stable.official.ed1daf0bf`
- Official Linux ZIP SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`

## Recorded gates

`godot --version` returns exactly `4.7.2.stable.official.ed1daf0bf`.

`godot --headless --path . --script res://tests/runner.gd` returns exit `0`: **32 discovered, 32 passed, 0 failed, 0 harness failures**. This retains all 31 Phase A-F tests and adds `phase_f_r_reconciliation`. Extended state/save tests also exercise the v1 -> v2 ownership-seat migration.

The exact Phase F competition command is:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=phase_f_acceptance
```

It returns exit `0`, completes 24/24 months through `2003-01-01`, reports invariant `PASS`, and completes the requested save round-trip. All three promotions remain active. The final state contains 10 active contracts, three agreements, 450 knowledge observations, and a Chronicle head at sequence 446 with five checkpoints, 19 deltas, 446 events, 43 retained identities, and 144 metrics.

The save/Chronicle regression surface proves current-state round-trip, RNG preservation, non-person ownership seat, legitimate NPC promotion-owner Person references, contracts, knowledge, Chronicle head/history, prior-world reconstruction with AI/commands/simulation/RandomService unavailable, and no mutation of current CampaignState during historical inspection.

## Five-year soak

The exact required command is:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=res://tests/soak/phase_f_5_year_soak.json
```

It returns exit `0`: **PASS**, eight 60-month runs, seven unique seeds, exact repeated-seed replay, seven distinct F-R fingerprints, 24/24 active promotion endings, maximum market concentration `0.7584476803`, and policy wins balanced `2`, expansionist `5`, defensive `1`. Across the matrix: 1,440 shows, 8,640 scouting reports, 26 signings, eight releases, 182 renewals, 454 route changes, 16 recovery actions, 16 agreements, 196 territory violations, and zero errors.

The F-R aggregate and every corresponding mechanical outcome match the historically accepted Phase F soak. World fingerprints differ intentionally because current-state schema and Chronicle HistoricalProjection now encode the reconciled non-person Ownership Seat. Historical Phase F `phase_f_5_year_soak.json` was restored byte-for-byte with SHA-256 `7c37beed43600cb98582e640c90835e3e83e198bc813c44189510cd98f7ce768`; the new result is retained as `phase_f_r_5_year_soak.json`.

## Fresh editor/import

`godot --headless --editor --path . --quit-after 120` returns exit `0`. The pinned editor completes filesystem scan, script registration and editor-layout load with no retained parser/import/project-configuration errors attributable to repository source/content. It creates the legitimate `tests/integration/test_phase_f_r_reconciliation.gd.uid` sidecar. The only emitted warning is the container-environment warning for running Godot as root.

## Static / hygiene

`python tools/static_repo_check.py` returns exit `0`, schema `we.phase_f_r.static_check.v1`, PASS, zero failures and zero warnings.

`git diff --check` returns exit `0`. After deliberate F-R files are staged, `git diff --cached --check` returns exit `0`. `.godot/` remains ignored; no logs, transient saves, test-output scratch files or generated build output are staged. The historically accepted Phase F soak file and historical schema-baseline DOCX remain unchanged.

## Final result

**PASS — Phase F-R runtime/static/persistence/determinism/import/hygiene verification is complete.** The working repository remains based on starting commit `e18f32240e1fb3b9c92916da3efc9072e6a2ea85`; no commit or remote push has been performed.
