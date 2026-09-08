# G→H Adversarial Interaction Acceptance

Gate: **G→H — Adversarial Interaction Validation**
Required starting commit: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Required starting tree: `a075ea266632c33f5940b12860b5bcffcf3f0ecc`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Status: **VERIFIED**

## Scope

The gate attacks the accepted Phase G player-facing interaction path before Android integration. It does not begin Phase H, alter the simulation model, add mobile packaging, expand gameplay depth, or introduce a second presentation-specific authority.

## Protected architecture

Read path:

`CampaignState / Chronicle -> OwnerPresentationQuery -> governed knowledge/history projection -> StrategicHome / StrategicMapView`

Write path:

`presentation intent -> CampaignSession -> CommandEnvelope -> CommandRouter -> MonthPipeline -> authoritative state -> fresh projection`

Presentation selection, surface, pan/zoom and transient historical-card state remain disposable UI state.

## Attack coverage

The retained G→H regression/harness covers:

1. rapid repeated route, budget, market-focus and push interactions;
2. immediate repeated month advancement;
3. stale command envelope validation after authoritative turn/date change;
4. invalid/cross-promotion target churn;
5. repeated map/people/touring/wrestling/history navigation;
6. live and historical knowledge-boundary probing;
7. high-volume touring route/budget churn and reduced-intent equivalence;
8. repeated Chronicle historical inspection;
9. invalid/stale market selection and re-entry;
10. actual `StrategicHome` / `StrategicMapView` interaction with screen-touch tap/drag events.

## Accepted fixes

The gate permanently fixes and retains regressions for:

- `G2H-001` repeated setter intents duplicating pending authoritative commands;
- `G2H-002` Chronicle historical selector/transient-card node ownership under churn;
- `G2H-003` duplicate month activation within one UI input burst;
- `G2H-004` invalid/stale market IDs becoming presentation selection.

Full finding details are in `docs/G2H_FINDINGS.md`.

## Pass obligations

The gate is accepted only when all of the following are true:

- repeated Phase G setter actions produce one final authoritative intent per governed setter target;
- one UI input burst cannot advance multiple months;
- stale command envelopes are validated against current authoritative turn/date;
- F2G-001/002/003 protections remain green;
- cross-promotion target churn cannot gain authority;
- navigation/selection/history interaction does not mutate CampaignState;
- historical inspection does not mutate Chronicle;
- no alternate presentation path exposes hidden rival truth;
- noisy touring setter sequences are deterministic and equivalent to their final reduced intent set;
- rendered/touch-capable presentation interaction completes without retained runtime errors;
- complete automated, competition, soak, persistence/Chronicle, editor/import, static and hygiene gates pass;
- the repository finishes in an exact staged, reproducible, commit-ready state.

Measured verification is recorded in `docs/G2H_RUNTIME_RESULT.md`.
