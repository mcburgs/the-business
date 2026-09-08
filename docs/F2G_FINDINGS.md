# F→G Adversarial Strategic Validation Findings

Package: `F2G-STRAT-001`
Baseline under attack: `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`
Baseline tree: `ae2ec32af6d5f8af4c91a22fcaf67723849d0c30`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Fixture: `phase_f_competition`
Policy version: `f2g.policy.v1`

This record classifies material findings from the first F→G adversarial strategic gate. Legal-player evidence used the knowledge-filtered planning surface and normal command/month pipeline. Historical reproduction scripts exist only to demonstrate the frozen pre-fix defect and are not accepted gameplay paths.

## F2G-001 — Cross-promotion command authority bypass

- **Classification:** DEFECT
- **Severity:** STOP-THE-LINE
- **Test class:** legal gameplay / command-boundary exploit
- **Baseline/runtime/fixture/seed:** `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`; Godot `4.7.2.stable.official.ed1daf0bf`; Phase F competition fixture; seed `424242`
- **Agent/policy:** adversarial player command authority attack
- **Observed:** a player issuer scoped to `promotion:PRO00001` could submit a resource-targeted command against a valid rival resource ID. The historical repro changes rival `touring:TOU00002` budget from `205000` to `1` and returns `accepted:true`.
- **Expected governing behavior:** the non-person Ownership Seat grants authority over the controlled promotion only. Valid knowledge of, or ability to guess, another entity ID must not confer mutation authority.
- **Reproduction / transcript:** `tests/adversarial/repro/F2G-001/reproduce_pre_fix.gd`, `command.txt`, `pre_fix_output.log`.
- **Diagnostic evidence:** the target entity reference was valid, but the command handler did not verify that the target resource belonged to the issuer promotion.
- **Root cause:** envelope-level issuer validation checked that the issuer promotion existed, while several resource-targeted handlers validated only target existence rather than target ownership/scope.
- **Disposition:** FIXED. Shared promotion-scope enforcement now rejects resource/promotion targets outside the issuer's promotion. Related person/program/title availability checks were tightened through the same authority boundary.
- **Regression:** `tests/integration/test_f2g_adversarial_regressions.gd::_test_player_cannot_mutate_rival_resources`.
- **Post-fix rerun:** historical repro is rejected with `STATE003` / `promotion_scope_mismatch`, rival budget remains unchanged; all 33 automated tests and the full accepted adversarial corpus pass.

## F2G-002 — Player-authored media economics create arbitrary value

- **Classification:** DEFECT
- **Severity:** STOP-THE-LINE
- **Test class:** legal gameplay / economic exploit
- **Baseline/runtime/fixture/seed:** `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`; Godot `4.7.2.stable.official.ed1daf0bf`; Phase F competition fixture; seed `424242`
- **Agent/policy:** adversarial economic command attack
- **Observed:** `command.sign_media_deal` accepted caller-authored medium/outlet/schedule/economic terms, including zero cost and one-billion-minor-unit revenue. The fabricated deal became authoritative state and could mint value through the normal economic path.
- **Expected governing behavior:** a player may choose among authoritative opportunities; the player may not author the economic truth of an offer. Legal command payloads cannot be an unrestricted money faucet.
- **Reproduction / transcript:** `tests/adversarial/repro/F2G-002/reproduce_pre_fix.gd`, `command.txt`, `pre_fix_output.log`.
- **Diagnostic evidence:** the baseline returns `accepted:true` and the fabricated media deal exists in authoritative state.
- **Root cause:** the command treated user-supplied deal terms as authoritative offer data without a proposal/offer provenance seam.
- **Disposition:** FIXED. Direct media-deal term creation is restricted to authoritative/system issuance until a governed media-offer system exists. F→G deliberately does not invent that future negotiation system.
- **Regression:** `tests/integration/test_f2g_adversarial_regressions.gd::_test_player_cannot_mint_media_terms`.
- **Post-fix rerun:** historical repro is rejected with `STATE003` / `media_deal_terms_require_authoritative_offer`, no deal is created; all 33 automated tests and the accepted adversarial corpus pass.

## F2G-003 — Expired booker remains active without employment

- **Classification:** DEFECT
- **Severity:** MATERIAL
- **Test class:** contract timing / lifecycle defect
- **Baseline/runtime/fixture/seed:** `20ddeaa45bfdbfce98be066cdc13d656d5d6363a`; Godot `4.7.2.stable.official.ed1daf0bf`; Phase F competition fixture; seed `424242`
- **Agent/policy:** contract/timing exploiter
- **Observed:** after `person:PER00004` employment expired, `world_state.booker_by_promotion` still pointed at the person, allowing the promotion to continue receiving booking skill without a live employment contract.
- **Expected governing behavior:** a skill-bearing staff appointment that depends on employment must cease when the qualifying employment ends.
- **Reproduction / transcript:** `tests/adversarial/repro/F2G-003/reproduce_pre_fix.gd`, `command.txt`, `pre_fix_output.log`.
- **Diagnostic evidence:** baseline repro records the same booker before and after contract expiration.
- **Root cause:** contract deactivation updated the contract lifecycle but did not clear the corresponding derived booker appointment; `command.set_booker` also lacked a live same-promotion employment requirement.
- **Disposition:** FIXED. Contract deactivation clears a matching booker appointment and `command.set_booker` now requires live same-promotion employment.
- **Regression:** `tests/integration/test_f2g_adversarial_regressions.gd::_test_booker_requires_live_employment_and_clears_on_expiry`.
- **Post-fix rerun:** booker assignment is empty after expiry; all 33 automated tests, directed adversarial runs and the retained five-year competition soak pass.

## F2G-HARNESS-001 — Exact float-bit comparison produced false persistence failures

- **Classification:** HARNESS
- **Severity:** MINOR
- **Test class:** test-infrastructure correctness
- **Observed:** JSON persistence could round-trip a floating-point value with a difference around `6.94e-18`, causing an exact-equality adversarial check to report state corruption where no material semantic difference existed.
- **Expected behavior:** persistence checks should detect meaningful state changes, not implementation-level floating representation noise below the simulation's numerical significance.
- **Root cause:** the new adversarial harness used exact numeric equality across JSON serialization.
- **Disposition:** FIXED in the harness only. Semantic numeric comparison uses tolerance `1e-12`; production persistence behavior and contracts were not weakened.
- **Regression/rerun:** all save-roundtrip and Chronicle checks across the accepted 32-run adversarial corpus pass.

## F2G-OBS-001 — Talent-hoarder profile leads 24-month cash balance

- **Classification:** TUNING
- **Severity:** MINOR
- **Observed:** the talent-hoarder profile ends the 24-month fixture with the largest controlled-promotion cash balance, approximately `61.35M` to `61.89M` minor units across accepted seeds.
- **Why it is not a current defect:** growth is bounded, all rival promotions remain active, liquidity remains valid, market concentration remains bounded, repeated seeds reproduce, varied seeds diverge, and no cross-system self-feeding or unbounded loop was observed.
- **Disposition:** retain as a Phase I balance/red-team comparison, not a Phase G blocker.

## F2G-OBS-002 — Bad player can remain operational with negative cash

- **Classification:** ACCEPTED LIMITATION
- **Severity:** MINOR
- **Observed:** the 65-month financial-idiot campaign reaches `-2,076,404` cash minor units with financial stress capped at `1.0`, while all three promotions remain active.
- **Why it is not a current defect:** authoritative state, ledger, references, save/load and Chronicle remain coherent. The current vertical slice intentionally does not contain a complete debt/insolvency/bankruptcy lifecycle.
- **Disposition:** future economy/failure-depth work. It does not block Phase G presentation.

## Finding closure

All known STOP-THE-LINE findings from this gate are fixed, reproduced against the frozen F-R baseline, and covered by permanent automated regressions. No remaining finding meets the stop-line definition for crash/corruption, hidden-information leakage, save/Chronicle corruption, same-seed nondeterminism, unbounded legal exploit, command-boundary bypass/duplication, or structural strategic collapse.
