# Phase H Pixel / Android Runtime Result

Phase: **H — Pixel / Android Target Build and Integration**
Starting commit: `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d`
Starting tree: `bb77e7f63f291ddfdefcb760224e254378a0f897`
Starting parent: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Game/build version: `0.0.0-phase-h` / `H`
Status: **VERIFIED — OFF-DEVICE, ANDROID EXPORT AND PHYSICAL PIXEL GATES PASS**

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

## Actual toolchains used

### Off-device implementation and regression environment

- Godot: `4.7.2.stable.official.ed1daf0bf`, standard Linux x86_64 build supplied for the phase.
- Java/JDK available locally: OpenJDK `21.0.11`.
- Local container Android SDK/export templates: unavailable, which is why the final Android export was executed in a temporary GitHub-hosted build environment rather than faking an APK result.

### Successful Android export environment

GitHub Actions run `34292406652` built and inspected the APK from source commit `4009537e5bc0046b6c6c42055988cfabbb2ffdbb` / tree `fed0f9218a6a592fd3c43ec80ee8eec17ea7c933`.

Recorded toolchain:

- runner OS: Ubuntu 24.04 hosted runner;
- Godot: `4.7.2.stable.official.ed1daf0bf`;
- Godot Android export templates: matching `4.7.2.stable` `android_debug.apk` / `android_release.apk` from the official template package;
- Java: Temurin OpenJDK `17.0.20.1+1`;
- Android SDK root: `/usr/local/lib/android/sdk` in the ephemeral runner only;
- Android Platform: `35`;
- Android Build-Tools: `35.0.1`;
- Android Platform-Tools / adb: `37.0.1-15733141`;
- Android command-line tools: `16.0`;
- Android NDK: `28.1.13356709`;
- CMake: `3.10.2.4988404`;
- signing: ephemeral debug keystore created outside the repository.

No SDK/JDK/template/cache path, keystore or credential is committed to source control.

## Android configuration

`export_presets.cfg` defines one reversible development preset:

- preset: `Android Debug`;
- format: APK;
- output: `build/android/the-business-phase-h-debug.apk`;
- package/application ID: `com.mcburgs.thebusiness.dev`;
- application name: `The Business`;
- version: `0.0.0-phase-h`;
- ABI: `arm64-v8a` only;
- network permission posture: `permissions/internet=false`;
- signing posture: development/debug signing only;
- Gradle build: disabled for the slice; no Android plugin/native rewrite introduced;
- project texture import: ETC2/ASTC enabled as required by Godot Android export.

The first remote export attempt correctly failed at Godot's Android texture-compression preflight. Phase H fixed that configuration by enabling `textures/vram_compression/import_etc2_astc=true`; the second build then passed export and inspection.

## Mobile presentation

Phase H preserves the accepted map-first hierarchy and adds only responsive/touch behavior required for a phone:

- square 720x720 design base with `canvas_items` + `expand`;
- handheld `sensor` orientation;
- breakpoint-based narrow mode with map/detail exclusivity and fixed bottom navigation;
- 48 logical-pixel minimum target sizes for required buttons;
- explicit detail `Back to Map` and Android/system Back behavior;
- direct screen-touch market selection;
- one-finger map pan;
- two-finger pinch zoom;
- mouse interactions retained for desktop;
- no critical action depends on hover.

Off-device renders passed at simulated Pixel-class 1080x2424 portrait and 2424x1080 landscape. Physical Pixel 9a testing then confirmed portrait reflow, landscape operation, repeated rotation, direct touch selection, pan, pinch zoom and all required navigation surfaces. Landscape is functional but visually dense; Phase H therefore keeps responsive sensor orientation and records mobile presentation quality as Phase-I debt rather than pretending the current layout is polished.

## Lifecycle architecture

`CampaignSession` remains the platform-neutral lifecycle/persistence seam. `GameRoot` translates host lifecycle events into that seam; no mobile-only CampaignState or resolver exists.

- normal startup calls `start_or_resume` against the canonical campaign and save ID;
- capture/test startup remains ephemeral;
- Android `APPLICATION_PAUSED` requests and synchronously flushes the already-resolved checkpoint because the process may be suspended/killed immediately afterward;
- ordinary focus-out requests the same canonical checkpoint and may defer the file operation to the next frame;
- duplicate lifecycle checkpoint notifications coalesce;
- resume/foreground retries a pending failed checkpoint then refreshes from current authoritative state;
- Android/system Back returns detail -> map first, then checkpoints before exit from map home;
- no month simulation runs inside a lifecycle callback.

Physical Pixel evidence confirmed Back-to-map, background/resume, foreground restoration, force-close/relaunch and persisted campaign reload without duplicate month advancement.

## Save/recovery findings and fixes

Phase H exposed two persistence defects that matter specifically at a real app restart boundary.

First, the previous last-good backup layout was not a complete loadable save snapshot: the Chronicle backup did not retain its complete manifest structure. Phase H now copies a complete validated prior snapshot into `backups/last_good` and can load/restore it through the same SaveService codec path.

Second, Godot JSON parsing does not preserve arbitrary Variant integer types and a decimal JSON round trip can move some binary64 values by one representable step. Phase H therefore applies exact tagged numeric representation only at the physical JSON I/O layer:

- integers use `__we_int64_text_v1` with decimal text;
- floats use `__we_float64_bits_v1` with the exact IEEE-754 bit pattern;
- logical CampaignState/Chronicle codecs and save schema remain unchanged;
- existing untagged legacy JSON remains readable.

A continuous multi-month branch and a branch crossing a genuine filesystem save/relaunch boundary converge to identical CampaignState and Chronicle snapshots/fingerprints. Physical device relaunch also preserved the progressed campaign state.

## Automated suite

Command:

```text
godot --headless --path . --script res://tests/runner.gd
```

Verified result:

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

Result: **PASS**.

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

Result: **PASS**.

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

Result: **PASS**, exit 0.

- runs: 8 x 60 months;
- repeated-seed deterministic: true;
- unique seeds: 7;
- distinct world fingerprints: 7;
- active promotion endings: 24/24;
- maximum market concentration: `0.7584463303`;
- policy wins: balanced 2 / defensive 1 / expansionist 5;
- errors: none.

The entire `runs` payload is value-for-value equal to the accepted F→G/G→H Phase-F regression evidence (`tests/adversarial/evidence/F2G-STRAT-001/phase_f_regression_5_year_soak.json`). Only top-level phase/game-version metadata differ. Phase-H integration therefore introduces zero simulation drift. The Phase-H soak JSON SHA-256 is `545c4d563de2dfca817878d08cdec9e198a2d464d07c8fcc01b0cad3a4f918a9`.

## Editor/import

Command:

```text
godot --headless --editor --path . --quit-after 120
```

Result: **PASS**, exit 0. No parser/import/project-configuration errors attributable to repository source/content.

## Performance evidence

Five repeated headless Linux measurements were collected before device acceptance to catch gross regressions. Median values were:

- new persistent campaign startup including initial checkpoint: `82.383 ms`;
- first warm month resolution including post-resolution save: `223.507 ms`;
- second warm month resolution including post-resolution save: `255.241 ms`;
- close-equivalent new-session reload from disk: `86.058 ms`;
- Chronicle historical projection: `6.826 ms`.

Physical Pixel 9a acceptance was performed by direct install without ADB/logcat instrumentation. Numerical device timings/memory were therefore not fabricated. Qualitative physical performance smoke passed: launch, month resolution, navigation, Chronicle use, map pan/pinch, background/resume and relaunch all completed without obvious major stutter, hang, crash or runaway duplicate action. This limitation is documented rather than optimized speculatively.

## Android export and APK inspection

Command:

```text
godot --headless --path . --export-debug "Android Debug" build/android/the-business-phase-h-debug.apk
```

Final result: **PASS** in GitHub Actions run `34292406652`.

APK evidence:

- filename: `the-business-phase-h-debug.apk`;
- size: `29192408` bytes;
- SHA-256: `43fd8d26529fc7bdf90456bd47326943da01fe6f715d1512cd5780db6d122040`;
- package: `com.mcburgs.thebusiness.dev`;
- version: `0.0.0-phase-h`;
- ABI: `arm64-v8a` only;
- `INTERNET` permission: absent;
- signing: v2 PASS, v3 PASS, one RSA-2048 debug signer;
- source commit: `4009537e5bc0046b6c6c42055988cfabbb2ffdbb`;
- source tree: `fed0f9218a6a592fd3c43ec80ee8eec17ea7c933`.

The exact APK was then installed and accepted on a Google Pixel 9a running Android 17.

## Static / hygiene

Phase H extends the static gate to enforce:

- phase/version/orientation/responsive project metadata;
- reversible arm64 Android debug preset with no credentials;
- Android/platform isolation from domain authority;
- platform-neutral lifecycle/persistence application seam;
- exact persistence/recovery seam;
- direct-touch map support and absence of hover-only critical shell actions;
- retained G→H interaction scar tissue.

Final verification includes:

- `python tools/static_repo_check.py`: PASS, schema `we.phase_h.static_check.v1`, zero failures/warnings;
- `git diff --check`: PASS;
- `git diff --cached --check`: PASS on final staged candidate;
- fresh editor/import: PASS;
- complete automated suite: 40/40 PASS;
- G→H interaction harness: PASS;
- Phase-F competition regression: PASS;
- eight-run five-year soak: PASS with zero accepted-evidence drift;
- generated/cache/credential audit: clean.

No `.godot` data, Android SDK/JDK content, Gradle cache, APK/AAB/PCK output, debug keystore, credential, device log or screenshot is staged for source control.

## Runtime conclusion

**Phase H is VERIFIED.** The same accepted authoritative application/domain/persistence architecture now runs as a real arm64 Android APK on the designated Pixel 9a, survives physical touch/lifecycle/relaunch use, and preserves all retained strategic/simulation regressions. Presentation density remains intentionally deferred to Phase I; no Phase-I gameplay/polish work or H→I adversarial device-abuse testing was started here.
