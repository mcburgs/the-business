# Phase H Physical Pixel Device Result

Phase: **H — Pixel / Android Target Build and Integration**
Source baseline: `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d` / tree `bb77e7f63f291ddfdefcb760224e254378a0f897`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
APK source commit: `4009537e5bc0046b6c6c42055988cfabbb2ffdbb`
APK source tree: `fed0f9218a6a592fd3c43ec80ee8eec17ea7c933`
Status: **PASS — PHYSICAL PIXEL ACCEPTANCE COMPLETE**

Physical acceptance was performed on the designated real Pixel. Off-device simulation was not substituted for this evidence.

## Device identity

- Pixel model: **Google Pixel 9a**
- Android version: **Android 17**
- Android security update observed: **2026-08-05**
- Android build number observed: **CP2A.260805.005**
- display posture tested: **portrait and landscape**
- installation route: **direct APK download/transfer and on-device package install**

## APK identity

- filename: `the-business-phase-h-debug.apk`
- package/application ID: `com.mcburgs.thebusiness.dev`
- ABI: `arm64-v8a`
- build type: development/debug APK
- SHA-256: `43fd8d26529fc7bdf90456bd47326943da01fe6f715d1512cd5780db6d122040`
- file size: `29192408` bytes
- requested Android permissions: none reported by `aapt dump permissions`
- debug signing: ephemeral RSA-2048 Android debug certificate; APK Signature Scheme v2/v3 verification PASS

## Physical acceptance checklist

| # | Check | Result | Physical evidence |
|---:|---|---|---|
| 1 | APK installs | PASS | Installed successfully on Pixel 9a |
| 2 | App launches | PASS | First launch reached gameplay UI |
| 3 | No immediate crash | PASS | Stable first-launch session |
| 4 | Strategic map is initial/home experience | PASS | Map-first home observed on device |
| 5 | Correct controlled promotion loads | PASS | `OWNERSHIP / Promotion Alpha` displayed |
| 6 | Market selection works by touch | PASS | Physical market tap accepted |
| 7 | Map pan works | PASS | One-finger physical drag accepted |
| 8 | Pinch zoom works | PASS | Two-finger physical pinch accepted |
| 9 | People/roster is reachable and usable | PASS | Physical navigation opened People |
| 10 | Touring is reachable and usable | PASS | Physical navigation opened Touring |
| 11 | Wrestling/program is reachable and usable | PASS | Physical navigation opened Wrestling |
| 12 | Chronicle/history is reachable and usable | PASS | Physical navigation opened Chronicle |
| 13 | Canonical legal action can be issued | PASS | User confirmed a meaningful state-changing action could be performed and persisted across relaunch |
| 14 | Duplicate-touch protections remain coherent | PASS | Aggressive tapping produced no visible duplicate/runaway behavior; month advancement remained single-fire |
| 15 | One strategic month advances exactly once | PASS | Physical Advance Month test advanced one month only |
| 16 | Map/HUD/context refresh after month | PASS | Refreshed state remained coherent after physical month advance |
| 17 | Background and resume works | PASS | Backgrounded for roughly 20–30 seconds and resumed normally |
| 18 | Foreground restoration remains coherent | PASS | No extra month advance or visible state corruption on resume |
| 19 | Close/relaunch works | PASS | Force-close and relaunch succeeded |
| 20 | Campaign/save reloads coherently | PASS | Relaunch resumed the same progressed campaign state |
| 21 | Chronicle/current-state agreement survives relaunch | PASS | No discrepancy observed during relaunch/persistence smoke; retained deterministic save/Chronicle regression also PASS |
| 22 | No obvious hidden-information leak through mobile layout | PASS | Device UI continued to present governed rival estimates/confidence; no raw rival truth surface observed |
| 23 | No player avatar/person appears | PASS | Device retained abstract Ownership presentation |
| 24 | Narrow/mobile layout readable and practical | PASS WITH UX DEBT | Functionally usable in both orientations; current layout is visibly dense and rough, accepted for Phase H but a Phase-I presentation-quality target |

## Orientation evidence and decision

Both orientations were physically exercised repeatedly on the Pixel 9a.

- portrait reflow: **PASS**
- landscape layout: **PASS, but visually dense**
- rotation while on map and secondary surfaces: **PASS**
- crash/frozen-control/catastrophic clipping during rotation: **none observed**
- Phase-H orientation decision: **retain responsive sensor orientation for now**

Phase H does not lock the game to portrait or landscape. Both are functional on the target device, and the current landscape composition is noticeably dense. A permanent phone-first orientation/UI decision belongs to Phase I presentation work, not to simulation/domain semantics.

## Physical performance evidence

The direct-install library-session acceptance did not have ADB/logcat/profiling instrumentation attached, so numerical device timings and memory counters were not captured. Qualitative physical smoke was nevertheless performed:

- cold launch: completed without visible hang;
- warm month resolution: completed without visible lockup;
- save/relaunch: completed without visible stall or corruption;
- Chronicle/navigation: responsive during ordinary use;
- map pan/pinch: responsive to physical touch;
- aggressive tapping/navigation for roughly one minute: no major stutter, lockup, duplicate-action runaway, or crash observed;
- memory: not instrumented.

For Phase H this is **PASS with documented non-instrumented profiling limits**. No performance optimization was introduced on intuition alone. The retained off-device timing smoke remains recorded in `docs/PHASE_H_RUNTIME_RESULT.md`.

## Device findings / defects

No Phase-H blocker was found on the Pixel 9a.

The principal finding is presentation debt rather than runtime failure: the current strategic UI is dense and visually rough on a phone, especially in landscape. It is usable enough to prove the target-device architecture and loop, but it is not final-quality mobile UX. This is explicitly deferred to Phase I and must not be misread as completed polish.

## Device conclusion

**PASS.** The designated Pixel installed, launched, navigated, advanced, backgrounded, resumed, closed, relaunched and reloaded the Phase-H APK successfully. Touch map interaction, required gameplay surfaces, lifecycle handling and persistent state all survived physical use. Phase H may proceed to final repository verification and commit-ready staging.
