# G→H Adversarial Interaction Findings

Gate: **G→H — Adversarial Interaction Validation**
Frozen Phase G target: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Frozen Phase G tree: `a075ea266632c33f5940b12860b5bcffcf3f0ecc`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`

## Purpose

This gate attacks the Phase G player-facing presentation/application boundary before Android integration. The target is not game balance. It is hostile interaction: repeated input, stale views, navigation churn, cross-promotion target switching, knowledge-boundary probing, historical inspection, and attempts to make presentation state disagree with authoritative state.

The governing rule remains unchanged: presentation owns ephemeral interaction state only. Authoritative game state changes only through the application command/month boundary.

## Material findings

### G2H-001 — repeated UI setter intents accumulated duplicate authoritative commands

**Classification:** genuine interaction/application-seam defect
**Status:** fixed, regression retained

On the frozen Phase G tree, five identical `command.set_route` UI intents produced five pending commands. Equivalent repetition existed for the other Phase G setter-style actions. A noisy touch sequence could therefore create repeated authoritative command attempts from one human intention.

Pre-fix reproduction against the exact Phase G commit recorded:

- five identical route interactions → pending count `5`;
- the commands remained separate until month resolution.

**Fix:** `CampaignSession.queue_player_command()` now derives a narrow presentation-intent key for the four Phase G setter actions:

- route per touring company;
- budget per touring company;
- market focus per controlled promotion;
- featured push per touring company/person.

An exact duplicate returns the existing pending command as `duplicate_suppressed`. A changed value for the same setter target supersedes that pending intent. Before accepting the replacement, the session validates the candidate through `CommandRouter` against a cloned current authoritative state with all other still-pending canonical commands applied. The UI still does not mutate CampaignState.

Post-fix attack coverage proves 48 repeated Phase G callbacks reduce to four pending intentions and each final command produces exactly one authoritative result.

### G2H-002 — Chronicle rendering reused presentation nodes during rapid historical navigation

**Classification:** presentation defect
**Status:** fixed, regression retained

On the frozen Phase G tree, once multiple historical dates existed, the compressed `OptionButton` construction loop attached the same selector more than once. The engine reported:

`Can't add child ... already has a parent`

The prior same-frame detail teardown also used `queue_free()`, which allowed obsolete transient detail nodes to survive until the frame boundary during hostile navigation/re-entry.

**Fix:** historical selector construction is now explicit and attaches the selector once. Detail replacement is synchronous for these ephemeral UI nodes. Historical inspection keeps one explicitly replaceable `HistoricalProjectionCard` and frees the previous card before adding another.

Post-fix regression performs 40 surface changes and 50 historical reselections with multiple Chronicle dates, while retaining exactly one selector and one historical projection card. CampaignState and Chronicle snapshots remain byte-for-byte logically unchanged by the inspection churn.

### G2H-003 — immediate duplicate month activation could resolve two months

**Classification:** genuine interaction defect
**Status:** fixed, regression retained

On the frozen Phase G presentation, two immediate calls through the month-advance UI path both succeeded and moved authoritative `turn_number` from `0` to `2`.

**Fix:** `StrategicHome` keeps the advance interaction locked through the deferred frame rather than re-enabling it immediately after the synchronous MonthPipeline call. A second activation in the same input burst is explicitly suppressed. `CampaignSession` also retains an independent in-progress guard against true re-entry while resolution is active.

Post-fix regression proves one immediate double activation advances exactly one month; a later deliberate activation after the deferred boundary remains legal.

### G2H-004 — stale/invalid market IDs could become current presentation selection

**Classification:** presentation defect
**Status:** fixed, regression retained

On the frozen Phase G presentation, `_on_market_selected("market:STALEG2H")` replaced the valid selected market with that nonexistent ID. This did not mutate authoritative simulation state, but it created a presentation/domain disagreement and a fragile stale-reference path.

**Fix:** market selection now accepts only IDs present in the current Owner presentation projection. Projection refresh also repairs a stale selection to the current home market or first valid market.

Post-fix regression confirms an invalid/stale market ID is ignored and cannot survive projection refresh.

## Attacks that did not establish a defect

### Stale command envelopes

Existing `CommandRouter` turn/date validation already rejects an envelope authored against a prior view with `CMD002`. The UI does not get to assert that an old action remains valid.

**Classification:** non-issue / existing protection confirmed.

### Cross-promotion target churn

F2G-001 remains effective. Switching presentation targets does not let the player mutate a rival touring company through a valid-looking route command.

**Classification:** non-issue / permanent F→G protection confirmed.

### Hidden-information probing

The live Owner presentation exposes neither `true_value` nor raw `influence_by_promotion`. Observed rival touring does not expose controlled-only budget, fatigue, cohesion, assignments or directives. Historical projection remains scoped and does not create a current-truth escape hatch.

**Classification:** non-issue / knowledge boundary confirmed.

### Touring churn after intent coalescing

Fifty route/budget changes followed by a final legal route and budget reduce to two authoritative pending intents. Resolving that noisy sequence produces the same CampaignState as queuing only the final route and budget from the same seed.

**Classification:** fixed behavior / deterministic equivalence confirmed.

### Historical inspection mutation

Repeated Chronicle/current/historical navigation does not advance simulation, consume a month, replace current CampaignState or mutate Chronicle storage.

**Classification:** non-issue; G2H-002 was presentation-node ownership, not Chronicle authority.

## Scope conclusion

All four material interaction findings were repairable without changing game meaning, domain architecture, knowledge authority, Ownership Seat semantics, touring meaning, booking meaning, or Chronicle reconstruction. The fixes remain in the presentation/application seam where the defects occurred.
