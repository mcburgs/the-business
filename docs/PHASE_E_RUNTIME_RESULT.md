# Phase E Runtime Verification Result

## Environment

- Phase: **E — Strategic Loop**
- Game version: `0.0.0-phase-e`
- Engine pin: `Godot 4.7.2-stable`
- Verified runtime: `4.7.2.stable.official.ed1daf0bf`
- Official Linux ZIP SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`

## Static gate

```text
python tools/static_repo_check.py
```

Required/recorded result: PASS, 0 failures, 0 warnings, schema `we.phase_e.static_check.v1`.

## Canonical headless gate

```text
godot --headless --path . --script res://tests/runner.gd
```

Recorded result: exit 0; 25 discovered; 25 passed; 0 failed; 0 harness failures.

## Phase E coherent-strategy CLI

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_good --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_good_acceptance
```

Recorded result: PASS; 12/12 months; final date `2002-01-01`; 12 shows; attendance 14,145; revenue 35,542,500; cost 1,855,656; profit 33,686,844 minor units; save/reload PASS; Chronicle 64 events / 48 metrics / 9 deltas / 3 checkpoints / 18 identities.

## Phase E poor-strategy CLI

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_e_bad --months 12 --seed 424242 --save-roundtrip --save-id=phase_e_bad_acceptance
```

Recorded result: PASS; 12/12 months; final date `2002-01-01`; 12 shows; attendance 12,019; revenue 30,227,500; cost 3,022,992; profit 27,204,508 minor units; save/reload PASS; Chronicle 80 events / 48 metrics / 9 deltas / 3 checkpoints / 18 identities.

## Determinism

Repeating the coherent fixture with identical initial state, command schedule and seed reproduces the encoded CampaignState, Chronicle and strategic summary exactly. The integration gate records deterministic replay PASS.

## Chronicle reconstruction

`test_phase_e_chronicle_save.gd` reconstructs a prior month containing real Phase E changes from Chronicle checkpoint + deltas with BookingSystem, ShowResolver, simulation resolution and RandomService unavailable and old commands not replayed. Current CampaignState remains unchanged. PASS.

## Save/load and recovery

Exact authoritative Phase E state and RNG checkpoint round-trip through SaveService. Chronicle history/head and stable historical market identity references round-trip. Injected pre-publication failure preserves the prior known-good save. PASS.

Phase E exposed two Godot JSON representation issues: nested integer-semantic values parse as floats, and arbitrary computed doubles can return one ULP away. The persistence boundary now restores known integer semantics, and DomainEvent facts/explanations canonicalize finite floats to nine decimal places before publication.

## Fresh editor import

```text
godot --headless --editor --path . --quit-after 120
```

Recorded result: exit 0 with no retained parser, import or project-configuration errors. The container emits Godot's standard warning about execution as root; that is environmental and not a project import failure.

## Staged-tree hygiene

```text
git diff --cached --check
```

Recorded result: PASS. Generated `.godot/`, runtime save/diagnostic output and temporary artifacts are not staged; legitimate Godot `.gd.uid` sidecars for new scripts are retained.
