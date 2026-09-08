# F→G Adversarial Strategic Validation - Accepted Evidence

Package: `F2G-STRAT-001`
Baseline under attack: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Policy: `f2g.policy.v1`
Result: **PASS**

## Coverage

- Directed matrix: 10 required profiles × 3 runs each = **30 runs / 720 months**.
- Directed seeds per profile: `424242, 424242, 424243`.
- Every duplicate-seed pair reproduced the same world fingerprint.
- Every profile diverged under seed `424243`.
- Long-horizon supplement: financial idiot 65 months + random valid-command chaos 60 months = **125 additional months**.
- Total accepted evidence: **32 runs / 845 simulated months**.
- All authoritative-state, ledger, Ownership Seat, knowledge-surface, Chronicle reconstruction, and save-roundtrip checks passed after fixes.

## Directed profile summary

| Profile | Runs | Final cash min | Final cash max | Max concentration | Accepted cmds | Rejected cmds |
|---|---:|---:|---:|---:|---:|---:|
| rational_optimizer | 3 | 48169012 | 48244012 | 0.663463 | 249 | 0 |
| hyper_aggressive_expansionist | 3 | 45740596 | 46100596 | 0.589282 | 297 | 0 |
| ultra_conservative_operator | 3 | 45458512 | 45641012 | 0.617594 | 312 | 0 |
| talent_hoarder | 3 | 61353688 | 61886188 | 0.626119 | 30 | 0 |
| market_spammer | 3 | 42100596 | 42183096 | 0.712640 | 216 | 0 |
| contract_timing_exploiter | 3 | 46872988 | 47115488 | 0.637720 | 30 | 0 |
| creative_system_exploiter | 3 | 51712588 | 52027588 | 0.626308 | 222 | 0 |
| financial_idiot | 3 | 29420596 | 29780596 | 0.589658 | 300 | 0 |
| random_valid_command_chaos | 3 | 51357588 | 51670088 | 0.626276 | 41 | 0 |
| turn_boundary_attacker | 3 | 51635088 | 51947588 | 0.626296 | 123 | 123 |

## Material findings

- `F2G-001` **DEFECT / STOP-THE-LINE**: player promotion scope was not enforced by several resource-targeted commands, allowing rival authoritative mutation. Reproduced on the frozen F-R baseline; fixed and regressed.
- `F2G-002` **DEFECT / STOP-THE-LINE**: `command.sign_media_deal` allowed player-authored economic terms, permitting arbitrary value creation. Reproduced on the frozen F-R baseline; fixed by requiring authoritative offer/system creation and regressed.
- `F2G-003` **DEFECT / MATERIAL**: an expired employed booker could remain in `booker_by_promotion` and keep supplying skill without a live contract. Reproduced on the frozen F-R baseline; fixed and regressed.

## Remaining observations

- `F2G-OBS-001` **TUNING**: talent hoarding produced the highest 24-month cash balance in this fixture. It did not create unbounded growth, rival extinction, invalid liquidity, or a universal cross-system loop. Retain for Phase I tuning/red-team comparison.
- `F2G-OBS-002` **ACCEPTED LIMITATION**: the deliberately bad player reached negative cash after 65 months while authoritative state remained coherent. Full player-bankruptcy/debt lifecycle depth is outside the current shallow slice; this is not evidence of corruption.
- `F2G-HARNESS-001` **HARNESS DEFECT, FIXED**: sub-`1e-12` JSON floating representation differences caused a false exact-equality failure. The adversarial harness now compares persisted numeric values semantically at `1e-12`; production persistence behavior is unchanged.

## Gate decision

**PASS. Proceed to Phase G.** No known stop-the-line exploit remains after the accepted fixes and reruns. Same-seed determinism holds, varied seeds diverge, material findings are reproducible, and every fixed game defect has permanent automated regression coverage.
