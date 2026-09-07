# Phase F-R Five-Year Soak Report

## Method

The pinned Godot 4.7.2 runtime advances the reconciled three-promotion Phase F competition fixture for 60 months per run using seeds `424242, 424242, 424243, 424244, 424245, 424246, 424247, 424248`. The first repeated seed proves exact replay; the remaining seeds exercise varied controlled randomness and rotated strategy profiles.

The mandated command wrote temporarily to `tests/soak/phase_f_5_year_soak.json`. Its F-R result was retained as `tests/soak/phase_f_r_5_year_soak.json`, after which the historically accepted Phase F artifact was restored byte-for-byte (SHA-256 `7c37beed43600cb98582e640c90835e3e83e198bc813c44189510cd98f7ce768`).

## Result

**PASS.** Eight runs completed 60/60 months, representing 480 simulated months and 1,440 promotion-month shows. All 24 promotion endings remained active.

- repeated seed `424242`: exact replay;
- seven unique seeds: seven distinct F-R world fingerprints;
- policy wins: balanced `2`, expansionist `5`, defensive `1`;
- maximum market concentration: `0.7584476803`;
- contested-market months: `1,405`;
- scouting reports: `8,640`;
- talent: `26` signings, `8` releases, `182` renewals;
- touring/recovery: `454` route changes and `16` recovery actions;
- diplomacy: `16` agreements and `196` territory violations;
- invalid-state/runtime errors: `0`.

## Comparison with historically accepted Phase F

Every gameplay/mechanical result compared for each corresponding run is unchanged: winner promotion, winner strategy, maximum market concentration, final promotion states, event/decision metrics, and Chronicle counts all match the historical Phase F soak. The world fingerprints intentionally differ because F-R changes the serialized/current-state schema and HistoricalProjection representation by removing the player Person from the Ownership Seat and projecting the non-person seat separately. This is an explainable contract fingerprint change, not a balance or simulation divergence.

The historical Phase F soak remains canonical in `phase_f_5_year_soak.json`; the reconciled F-R machine-readable result is canonical in `phase_f_r_5_year_soak.json`.
