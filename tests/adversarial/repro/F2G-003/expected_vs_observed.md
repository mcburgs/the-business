# F2G-003 - Expired booker remains active without employment

Classification: **defect**
Severity: **material**
Frozen vulnerable baseline: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`

## Observed on baseline

On the frozen F-R baseline, resolving expiry through 2002-10-01 deactivated the player promotion booker contract but left person:PER00004 in world_state.booker_by_promotion.

## Governing expectation

A promotion booker must have a live employment contract. Expiry/release cannot leave a stale staff appointment that supplies free skill.

## Root cause

Contract deactivation removed contract IDs from Person/Promotion and touring assignments but did not reconcile booker_by_promotion.

## Disposition

ContractSystem._deactivate now removes a matching booker appointment; command.set_booker also requires a live same-promotion contract.

Permanent regression: `tests/integration/test_f2g_adversarial_regressions.gd::_test_booker_requires_live_employment_and_clears_on_expiry`.

`pre_fix_output.log` is the actual output from the frozen F-R commit with this repro script copied into an otherwise detached worktree. `post_fix_output.log` is the same script against the corrected F→G candidate; the script exits non-zero there because the historical vulnerability no longer reproduces.
