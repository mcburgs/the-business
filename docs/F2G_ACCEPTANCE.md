# F→G Adversarial Strategic Validation Acceptance

Gate: **F→G adversarial strategic validation**
Accepted package: `F2G-STRAT-001`
Baseline under attack: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Baseline tree: `ae2ec32af6d5f8af4c91a22fcaf67723849d0c30`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Decision: **PASS — proceed to Phase G presentation**

## Scope

The first F→G gate attacks the verified Phase F-R baseline through the legal player surface:

`knowledge-limited AIPlanningView -> scripted adversarial policy -> CommandEnvelope -> CommandRouter -> MonthPipeline -> authoritative state / diagnostics / Chronicle / save evidence`

Policies do not receive debug truth, direct authoritative state mutation, or a player Person/avatar identity. The package targets strategic/gameplay correctness, hidden-information boundaries, command authority, determinism, persistence/history integrity and bounded legal strategy behavior. It does not attempt to implement Phase G UI, deep psychology, full bankruptcy, full media negotiation, dynasties or later balance depth.

## Mandatory attacker coverage

All ten required first-pass profiles were executed:

1. rational optimizer
2. hyper-aggressive expansionist
3. ultra-conservative operator
4. talent hoarder
5. market spammer
6. contract/timing exploiter
7. creative-system exploiter
8. financial idiot
9. random valid-command chaos
10. turn-boundary attacker

Each profile ran 24 months under seeds `424242, 424242, 424243`: **30 directed runs / 720 months**. Every repeated-seed pair produced the same world fingerprint and every profile diverged under the varied seed. All 30 directed runs passed state, ledger, Ownership Seat, knowledge-surface, Chronicle reconstruction and save-roundtrip checks.

Long-horizon supplements added a 65-month financial self-destruction campaign and 60-month random-valid-command campaign: **2 runs / 125 months**. Total accepted F→G evidence is **32 runs / 845 months**, with 2,139 accepted player commands and 123 intentionally rejected turn-boundary commands.

## Material findings and closure

- `F2G-001` — **DEFECT / STOP-THE-LINE**: cross-promotion resource mutation through valid IDs. Fixed with target-promotion command scoping and regressed.
- `F2G-002` — **DEFECT / STOP-THE-LINE**: arbitrary player-authored media economics / money minting. Fixed by requiring authoritative media-offer/system provenance and regressed.
- `F2G-003` — **DEFECT / MATERIAL**: expired booker retained free skill without employment. Fixed by clearing appointments on contract deactivation and requiring live employment; regressed.
- `F2G-HARNESS-001` — **HARNESS / MINOR**: exact floating-bit comparison caused false persistence failures. Fixed with `1e-12` semantic numeric tolerance in the adversarial harness only.
- `F2G-OBS-001` — **TUNING / MINOR**: talent hoarding is strong in the current fixture but bounded and non-universal; defer to Phase I tuning.
- `F2G-OBS-002` — **ACCEPTED LIMITATION / MINOR**: current shallow slice permits negative cash without full bankruptcy lifecycle while preserving coherent state; defer economy/failure depth.

Full details and historical repro evidence are in `docs/F2G_FINDINGS.md` and `tests/adversarial/repro/`.

## Retained strategic/competition regression

The Phase F 24-month competition fixture passes after the accepted fixes with save round-trip, three active promotions, valid contracts/agreements/knowledge and coherent Chronicle history.

The retained Phase F five-year soak was rerun against the F→G candidate using 8 runs × 60 months. It passes with:

- repeated seed exact replay: PASS
- seven unique seeds -> seven distinct world fingerprints: PASS
- all 24 promotion endings active: PASS
- maximum market concentration: `0.7584463303`
- policy wins: balanced `2`, defensive `1`, expansionist `5`
- zero soak errors

World fingerprints differ from the F-R artifact because the accepted `F2G-003` booker-employment lifecycle fix changes legitimate post-expiry simulation history. Determinism, competitive survival and policy distribution remain intact.

## Stop-line checklist

- crash / invalid authoritative references: **none remaining**
- hidden-information leak through legal player policy surface: **none found**
- save/load or Chronicle corruption: **none found**
- same-seed nondeterminism: **none found**
- unbounded legal exploit: **none remaining**
- command-boundary bypass or duplication: **F2G-001 fixed; turn-boundary attacker clean**
- structural collapse to one universal strategy: **not observed**
- non-person Ownership Seat invariant: **preserved**
- accepted fixes have permanent regressions: **yes**
- material findings retain reproducible evidence: **yes**
- remaining observations explicitly classified: **yes**

## Gate decision

**PASS. Phase G map/UI presentation may begin from this F→G-verified candidate.**

This decision does not claim the game is balanced or complete. It means the known stop-line adversarial defects have been removed, the current strategic slice remains deterministic/persistent/coherent under the accepted hostile corpus, and no discovered issue requires an architecture rewrite before presentation work.
