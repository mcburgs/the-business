# F→G Accepted Execution Commands

Pinned binary used in this environment:

`/mnt/data/godot472/Godot_v4.7.2-stable_linux.x86_64`

Canonical equivalent may be invoked as `godot` when that binary is on PATH.

## Directed 24-month matrix

Each required profile was run with:

```text
godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=<PROFILE> --months=24 --seeds=424242,424242,424243 --output=res://tests/adversarial/evidence/F2G-STRAT-001/directed_24m/<PROFILE>
```

Profiles: `rational_optimizer`, `hyper_aggressive_expansionist`, `ultra_conservative_operator`, `talent_hoarder`, `market_spammer`, `contract_timing_exploiter`, `creative_system_exploiter`, `financial_idiot`, `random_valid_command_chaos`, `turn_boundary_attacker`.

## Long-horizon supplement

```text
godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=financial_idiot --months=65 --seeds=424242 --output=res://tests/adversarial/evidence/F2G-STRAT-001/long_horizon/financial_idiot_65m

godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=random_valid_command_chaos --months=60 --seeds=424242 --output=res://tests/adversarial/evidence/F2G-STRAT-001/long_horizon/random_valid_command_chaos_60m
```

## Regression and repository gates

See `docs/F2G_RUNTIME_RESULT.md` for the final exact commands and results.
