# F2G-001 - Cross-promotion command authority bypass

Classification: **defect**
Severity: **stop-the-line**
Frozen vulnerable baseline: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`

## Observed on baseline

On the frozen F-R baseline, a player issuer scoped to promotion:PRO00001 could submit command.adjust_budget targeting promotion:PRO00002 touring:TOU00002. CommandRouter accepted it and changed the rival budget from 205000 to 1.

## Governing expectation

A player command may mutate only authoritative resources belonging to the promotion controlled by that Ownership Seat. Rival resources must reject atomically.

## Root cause

Resource-targeted command handlers validated referenced entities but did not consistently validate the target entity promotion against issuer.promotion_id.

## Disposition

Added shared promotion-scope validation across promotion/resource commands and additional ownership/availability checks for programs, titles, directives and touring assignments.

Permanent regression: `tests/integration/test_f2g_adversarial_regressions.gd::_test_player_cannot_mutate_rival_resources`.

`pre_fix_output.log` is the actual output from the frozen F-R commit with this repro script copied into an otherwise detached worktree. `post_fix_output.log` is the same script against the corrected F→G candidate; the script exits non-zero there because the historical vulnerability no longer reproduces.
