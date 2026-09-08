# F→G Adversarial Strategic Validation Runtime Result

Date: 7 September 2026
Baseline under attack: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Baseline tree: `ae2ec32af6d5f8af4c91a22fcaf67723849d0c30`
Candidate status: local F→G fixes/evidence, uncommitted until separately authorized
Pinned engine: Godot `4.7.2.stable.official.ed1daf0bf`

## Runtime

```text
godot --version
```

Result:

```text
4.7.2.stable.official.ed1daf0bf
```

Actual binary used in the verification environment:

```text
/mnt/data/godot472/Godot_v4.7.2-stable_linux.x86_64
```

## Accepted adversarial package

Package: `tests/adversarial/evidence/F2G-STRAT-001/`

Directed profile command shape:

```text
godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=<PROFILE> --months=24 --seeds=424242,424242,424243 --output=res://tests/adversarial/evidence/F2G-STRAT-001/directed_24m/<PROFILE>
```

Profiles: `rational_optimizer`, `hyper_aggressive_expansionist`, `ultra_conservative_operator`, `talent_hoarder`, `market_spammer`, `contract_timing_exploiter`, `creative_system_exploiter`, `financial_idiot`, `random_valid_command_chaos`, `turn_boundary_attacker`.

Result: **PASS** — 30 runs / 720 months; all runs passed; same-seed deterministic; varied seeds diverged; all promotion endings active; max directed market concentration `0.71264`; 1,820 accepted player commands; 123 intentionally rejected boundary attacks.

Long-horizon commands:

```text
godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=financial_idiot --months=65 --seeds=424242 --output=res://tests/adversarial/evidence/F2G-STRAT-001/long_horizon/financial_idiot_65m

godot --headless --path . --script res://tools/adversarial_runner/run.gd -- --profile=random_valid_command_chaos --months=60 --seeds=424242 --output=res://tests/adversarial/evidence/F2G-STRAT-001/long_horizon/random_valid_command_chaos_60m
```

Result: **PASS** — 2 runs / 125 months. Financial-idiot final cash `-2,076,404` with coherent state; random-chaos final cash `50,385,588`; all three promotions active in both. Total accepted adversarial evidence: **32 runs / 845 months**.

## Historical defect reproduction

Each accepted game defect has a self-contained bundle under `tests/adversarial/repro/F2G-001` through `F2G-003` containing the pre-fix reproduction script, exact command, frozen-baseline output, post-fix output, expected-versus-observed description and regression reference.

Pre-fix baseline results:

- F2G-001: rival touring budget `205000 -> 1`, command accepted.
- F2G-002: fabricated media deal accepted and authoritative.
- F2G-003: expired booker remains assigned after employment expiry.

Post-fix results:

- F2G-001: rejected `STATE003` / `promotion_scope_mismatch`; rival resource unchanged.
- F2G-002: rejected `STATE003` / `media_deal_terms_require_authoritative_offer`; no fabricated deal.
- F2G-003: expired matching booker appointment is cleared.

## Automated test suite

```text
godot --headless --path . --script res://tests/runner.gd
```

Final result: **PASS** — 33 discovered, 33 passed, 0 failed, 0 harness failures. The suite includes `f2g_adversarial_regressions` for F2G-001/002/003.

## Phase F competition regression

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=f2g_final_regression
```

Result: **PASS** — 24/24 months through `2003-01-01`; save round-trip PASS; all three promotions active; 10 active contracts; 3 agreements; 450 knowledge observations; Chronicle remains coherent.

## Retained five-year competition soak

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=res://tests/adversarial/evidence/F2G-STRAT-001/phase_f_regression_5_year_soak.json
```

Result: **PASS** — 8 runs × 60 months; same-seed exact replay; seven unique seeds produce seven fingerprints; all 24 promotion endings active; maximum market concentration `0.7584463303`; policy wins balanced 2 / defensive 1 / expansionist 5; zero errors.

The world fingerprints legitimately differ from the historical F-R soak because F2G-003 changes post-expiry booker state and therefore future history. The deterministic replay requirement remains green.

## Static repository gate

```text
python tools/static_repo_check.py
```

Final result: **PASS** — schema `we.f2g.static_check.v1`, no failures, no warnings.

## Fresh editor/import

```text
godot --headless --editor --path . --quit-after 120
```

Final result: **PASS** — no retained parser, import or project-configuration errors attributable to repository source/content. The container's root-user warning is environmental only.

## Git hygiene

```text
git diff --check
git diff --cached --check
```

Final result: **PASS** for both. Generated `.godot/`, transient logs/saves and scratch execution output are excluded; legitimate Godot UID sidecars generated for retained source are kept where applicable.

## Decision

**F→G PASS. No known stop-the-line exploit remains. Proceed to Phase G presentation from the verified candidate after committing/publishing it as a separate authorized action.**
