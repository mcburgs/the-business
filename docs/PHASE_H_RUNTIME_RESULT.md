# Phase H Pixel / Android Runtime Result

Phase: **H — Pixel / Android Target Build and Integration**
Starting commit: `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d`
Starting tree: `bb77e7f63f291ddfdefcb760224e254378a0f897`
Starting parent: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Candidate game/build version: `0.0.0-phase-h` / `H`
Status: **OFF-DEVICE CANDIDATE VERIFIED; ANDROID EXPORT + PHYSICAL DEVICE ACCEPTANCE PENDING**

## Baseline verification

Before modification, the supplied repository and published GitHub `main` were independently confirmed at the required baseline:

- HEAD `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d`;
- tree `bb77e7f63f291ddfdefcb760224e254378a0f897`;
- parent `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`;
- message `Complete G-H adversarial interaction validation`;
- clean working tree;
- runtime `4.7.2.stable.official.ed1daf0bf`;
- baseline static gate PASS;
- baseline complete suite 38/38 PASS;
- retained G→H interaction harness PASS.

## Actual execution toolchain

- Godot: `4.7.2.stable.official.ed1daf0bf`, standard Linux x86_64 build supplied for the phase.
- Java/JDK: OpenJDK `21.0.11`. Godot's stable Android documentation recommends JDK 17 but explicitly supports higher JDK versions. The editor-local Java SDK path was configured outside the repository; the absolute workstation path is intentionally not committed.
- Android SDK: not installed in the execution container.
- `adb`: unavailable because Android Platform-Tools are not installed.
- `apksigner`: unavailable because Android Build-Tools are not installed.
- Godot Android export templates: matching `4.7.2.stable` templates are not installed in the execution container.

The repository does not commit workstation paths, SDK/JDK contents, export templates, Gradle caches, debug keystores or credentials.

## Android configuration

`export_presets.cfg` defines one reversible development preset:

- preset: `Android Debug`;
- format: APK;
- output: `build/android/the-business-phase-h-debug.apk`;
- package/application ID: `com.mcburgs.thebusiness.dev`;
- application name: `The Business`;
- ABI: `arm64-v8a` only;
- network permission posture: `permissions/internet=false`;
- signing posture: Godot development/debug signing; no production keystore or credentials committed;
- Gradle build: disabled for the slice; no Android plugin/native rewrite is introduced.

The Phase-H environment target for a reproducible desktop export follows the pinned Godot stable guidance: Android Platform-Tools 35.0.0+, Build-Tools 35.0.1, Platform 35, current command-line tools, with the stable documentation's NDK/CMake packages available if the exporter/toolchain requires them.

## Mobile presentation

Phase H preserves the accepted map-first hierarchy and adds only responsive/touch behavior required for a phone:

- square 720x720 design base with `canvas_items` + `expand`, which keeps the accepted 1280x720 landscape logical composition while producing a comparable scale factor in portrait;
- handheld orientation `sensor` while both orientations are physically evaluated;
- breakpoint-based narrow mode with map/detail exclusivity and fixed bottom navigation;
- 48 logical-pixel minimum target sizes for required buttons;
- explicit detail `Back to Map` and Android/system Back behavior;
- direct screen-touch market selection;
- one-finger map pan;
- two-finger pinch zoom;
- mouse interactions retained for desktop;
- no critical action depends on hover.

Final off-device render inspection passed at simulated Pixel-class 1080x2424 portrait and 2424x1080 landscape. Portrait renders were inspected for the initial map, market detail, People, Touring, Wrestling, Chronicle and post-month refreshed map; the landscape map/context composition was also inspected. No clipping, overlap, lost navigation, hover-only dependency or post-month layout failure was observed. These renders prove responsive structure, not physical ergonomics; actual touch comfort and orientation preference remain device criteria.

## Lifecycle architecture

`CampaignSession` is the platform-neutral lifecycle/persistence seam. `GameRoot` translates host lifecycle events into that seam; no mobile-only CampaignState or resolver exists.

- normal startup calls `start_or_resume` against the canonical campaign and save ID;
- capture/test startup remains ephemeral;
- Android `APPLICATION_PAUSED` requests and synchronously flushes the already-resolved checkpoint because the process may be suspended/killed immediately afterward; no simulation runs in that callback;
- ordinary focus-out requests the same canonical checkpoint and may defer the file operation to the next frame;
- duplicate lifecycle checkpoint notifications coalesce;
- resume/foreground retries a pending failed checkpoint then refreshes from current authoritative state;
- Android/system Back returns detail -> map first, then checkpoints before exit from map home;
- no month simulation runs inside a lifecycle callback.

## Save/recovery findings and fixes

Phase H exposed two persistence defects that matter specifically at a real app restart boundary.

First, the previous last-good backup layout was not a complete loadable save snapshot: the Chronicle backup did not retain its complete manifest structure. Phase H now copies a complete validated prior snapshot into `backups/last_good` and can load/restore it through the same SaveService codec path.

Second, Godot JSON parsing does not preserve arbitrary Variant integer types and a decimal JSON round trip can move some binary64 values by one representable step. That changed authoritative CampaignState/Chronicle fingerprints across a physical save/relaunch boundary even though the logical state appeared equivalent. Phase H therefore applies an exact, tagged numeric representation only at the physical JSON I/O layer:

- integers use `__we_int64_text_v1` with decimal text;
- floats use `__we_float64_bits_v1` with the exact IEEE-754 bit pattern;
- logical CampaignState/Chronicle codecs and save schema authority remain unchanged;
- existing untagged legacy JSON remains readable.

A continuous multi-month branch and a branch crossing a genuine filesystem save/relaunch boundary now converge to identical CampaignState and Chronicle snapshots/fingerprints.

## Automated suite

Command:

```text
godot --headless --path . --script res://tests/runner.gd
```

Current candidate result:

- discovered: 40;
- passed: 40;
- failed: 0;
- harness failures: 0.

New Phase-H tests cover persistent startup, exact state/Chronicle reload, save/restart determinism, failure retry, duplicate lifecycle notification coalescing, structurally loadable last-good recovery, responsive portrait/landscape assumptions, minimum touch targets, system Back, direct touch selection, one-finger pan and pinch zoom.

## Retained G→H interaction regression

Command:

```text
godot --headless --path . --script res://tools/adversarial_runner/g2h_interaction_run.gd
```

Result: PASS.

Measured retained hostile interaction values include:

- 48 repeated route/budget/market-focus/push callbacks -> 4 pending final intents;
- touch market selection succeeds;
- touch drag changes pan;
- immediate duplicate month attack advances turn exactly once;
- repeated navigation and historical inspection complete without retained state/history mutation.

G2H-001/002/003/004 and F2G-001/002/003 remain green in the complete suite.

## Competition regression

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/run.gd -- --campaign fixture:phase_f_competition --years 2 --seed 424242 --save-roundtrip --save-id=phase_h_competition
```

Result: PASS.

- completed months: 24/24;
- final date: `2003-01-01`;
- active promotions: 3;
- contract records: 10;
- agreements: 3;
- knowledge observations: 450;
- invariant status: PASS;
- save round-trip: PASS.

## Five-year multi-seed regression

Command:

```text
godot --headless --path . --script res://tools/simulation_cli/phase_f_soak.gd -- --years=5 --seeds=424242,424242,424243,424244,424245,424246,424247,424248 --output=<external>/phase_h_5_year_soak.json
```

Result: PASS, exit 0.

- runs: 8 x 60 months;
- repeated-seed deterministic: true;
- unique seeds: 7;
- distinct world fingerprints: 7;
- active promotion endings: 24/24;
- maximum market concentration: `0.7584463303`;
- policy wins: balanced 2 / defensive 1 / expansionist 5;
- errors: none.

The entire `runs` payload is value-for-value equal to the accepted F→G/G→H Phase-F regression evidence (`tests/adversarial/evidence/F2G-STRAT-001/phase_f_regression_5_year_soak.json`). Only top-level phase/game-version metadata differ. Phase-H integration therefore introduces zero simulation drift. The final Phase-H soak JSON SHA-256 is `545c4d563de2dfca817878d08cdec9e198a2d464d07c8fcc01b0cad3a4f918a9`.

## Editor/import

Command:

```text
godot --headless --editor --path . --quit-after 120
```

Result: PASS, exit 0. No parser/import/project-configuration errors attributable to repository source/content. The external environment warns that Android build-tools are unavailable; that warning is accounted for by the export-toolchain boundary below.

## Off-device performance smoke (not device acceptance)

Five repeated headless Linux measurements were collected only to catch gross regressions before the Pixel build. Median values were:

- new persistent campaign startup including initial checkpoint: `82.383 ms`;
- first warm month resolution including post-resolution save: `223.507 ms`;
- second warm month resolution including post-resolution save: `255.241 ms`;
- close-equivalent new-session reload from disk: `86.058 ms`;
- Chronicle historical projection: `6.826 ms`.

These numbers are environment-specific diagnostics, **not** substitutes for the Phase-H Pixel launch/month/save/reload/navigation measurements.

## Android export attempt

Command:

```text
godot --headless --path . --export-debug "Android Debug" build/android/the-business-phase-h-debug.apk
```

Result: **BLOCKED BY EXTERNAL TOOLCHAIN, exit 1**.

The preset is recognized, but Godot reports exactly these external prerequisites missing:

- `4.7.2.stable/android_debug.apk` export template;
- `4.7.2.stable/android_release.apk` export template;
- Android SDK `platform-tools` / `adb`;
- Android SDK `build-tools` / `apksigner`.

The installed JDK has been configured, eliminating Java-path configuration as a remaining blocker. Direct acquisition attempts from the execution environment could not materialize the required large external toolchain archives, so Android export must be completed on a machine with the matching templates/SDK.

No APK is claimed or hashed until that export succeeds.

## Static / hygiene

Phase H extends the static gate to enforce:

- phase/version/orientation/responsive project metadata;
- reversible arm64 Android debug preset with no credentials;
- Android/platform isolation from domain authority;
- platform-neutral lifecycle/persistence application seam;
- exact persistence/recovery seam;
- direct-touch map support and absence of hover-only critical shell actions;
- retained G→H interaction scar tissue.

Final off-device rerun results after the Phase-H source/documentation changes:

- `python tools/static_repo_check.py`: PASS, schema `we.phase_h.static_check.v1`, zero failures, zero warnings;
- `git diff --check`: PASS;
- fresh editor/import after source changes: PASS, exit 0;
- complete automated suite: 40/40 PASS;
- G→H interaction harness: PASS;
- Phase-F competition regression: PASS;
- eight-run five-year soak: PASS with zero accepted-evidence drift.

No generated `.godot` data, Android SDK/JDK content, Gradle cache, APK/AAB/PCK output, keystore, credential, device log or screenshot is intended for source control. Full `git diff --cached --check` and the exact final staged tree remain correctly deferred until Android export/device acceptance is complete.

## Runtime conclusion

The Phase H source candidate is ready for Android export/device verification. Off-device evidence proves the architecture, persistence boundary, responsive composition, touch abstraction and all retained simulation regressions. Full Phase H acceptance remains deliberately open until an actual APK is built and the designated Pixel provides the physical evidence recorded in `docs/PHASE_H_DEVICE_RESULT.md`.
