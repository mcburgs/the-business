# Phase F Runtime Verification Result

## Environment

- Phase: **F — Competitive World**
- Game version: `0.0.0-phase-f`
- Engine pin: `Godot 4.7.2-stable`
- Verified runtime: `4.7.2.stable.official.ed1daf0bf`
- Official Linux ZIP SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`
- Starting commit: `c7887b6dd924e9945800ac2df3840508aee709c2`

## Recorded gates

`python tools/static_repo_check.py` returns exit `0`, schema `we.phase_f.static_check.v1`, PASS, zero failures and zero warnings.

`godot --headless --path . --script res://tests/runner.gd` returns exit `0`: 31 discovered, 31 passed, zero failed and zero harness failures.

The Phase F competition integration gate runs 24 months twice with seed `246810` and once with `246811`. Equal-seed encoded CampaignState, Chronicle and summary match exactly; the changed seed diverges. All three promotions sustain operations, markets remain contested, talent and agreements change, recovery actions occur, and no market reaches automatic total dominance.

The exact save/load gate preserves authoritative Phase F state, RNG, contracts, knowledge and Chronicle history/head. A prior competitive month reconstructs from checkpoint plus deltas with AI planning, commands, simulation and RandomService unavailable; current CampaignState remains unchanged.

The five-year soak command is:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=res://tests/soak/phase_f_5_year_soak.json
```

Its retained machine-readable and human-readable results are under `tests/soak/`.

Recorded soak result: PASS; eight 60-month runs; one exact repeated seed; seven unique seeds and seven distinct world fingerprints; 24/24 active promotion endings; 1,440 shows; balanced/expansionist/defensive profiles won 2/5/1 runs; maximum market concentration `0.7584476803`; 8,640 scouting reports; 26 signings; 182 renewals; 16 recovery actions; 16 agreements; 196 territory violations; zero errors.

`godot --headless --editor --path . --quit-after 120` returns exit `0` with no retained parser, import or project-configuration errors attributable to source/content.

`git diff --cached --check` returns exit `0`; generated `.godot/`, logs, saves and transient test output are not staged. Legitimate new `.gd.uid` sidecars are retained.
