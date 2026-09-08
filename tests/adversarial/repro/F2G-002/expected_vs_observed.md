# F2G-002 - Player-authored media economics mint arbitrary value

Classification: **defect**
Severity: **stop-the-line**
Frozen vulnerable baseline: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`

## Observed on baseline

On the frozen F-R baseline, command.sign_media_deal accepted player-supplied fabricated outlet/medium/schedule terms with zero cost and 1,000,000,000 minor units of revenue, creating the deal as authoritative state.

## Governing expectation

Players may choose among governed offers/decisions, but may not author arbitrary authoritative economic terms. Economic value must originate from an authoritative offer/system seam.

## Root cause

The command treated all payload deal terms as trusted authoritative input and had no issuer-kind/offer provenance guard.

## Disposition

Restricted direct creation of media-deal economic terms to system authority until a governed offer surface exists. Player/AI callers cannot manufacture terms.

Permanent regression: `tests/integration/test_f2g_adversarial_regressions.gd::_test_player_cannot_mint_media_terms`.

`pre_fix_output.log` is the actual output from the frozen F-R commit with this repro script copied into an otherwise detached worktree. `post_fix_output.log` is the same script against the corrected F→G candidate; the script exits non-zero there because the historical vulnerability no longer reproduces.
