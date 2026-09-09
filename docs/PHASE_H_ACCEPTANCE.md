# Phase H Pixel / Android Target Build Acceptance

Phase: **H — Pixel / Android Target Build and Integration**
Required starting commit: `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d`
Required starting tree: `bb77e7f63f291ddfdefcb760224e254378a0f897`
Required parent: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Status: **VERIFIED — ANDROID EXPORT + PHYSICAL PIXEL ACCEPTANCE PASS**

## Scope

Phase H puts the accepted Phase G/G→H vertical slice onto the designated Android Pixel without creating mobile-specific simulation authority. It adapts presentation, lifecycle and persistence only as required for a practical phone build. It does not begin Phase I gameplay/content/polish work or the later H→I adversarial device-abuse gate.

## Locked authority

The strategic map remains home. The player remains the non-person `OwnershipSeatState`. Android presentation remains a client of authoritative application/domain state.

Read path:

`CampaignState / Chronicle -> OwnerPresentationQuery -> governed projection -> presentation`

Write path:

`presentation intent -> CampaignSession -> CommandEnvelope -> CommandRouter -> MonthPipeline -> authoritative state -> fresh projection`

G→H protections remain mandatory and verified: setter-intent coalescing, duplicate-month suppression, stale-selection rejection, Chronicle transient-card ownership, cross-promotion authority rejection and hidden-information boundaries.

## Phase H implementation

The verified Phase H state provides:

- reproducible `Android Debug` export configuration with reversible package ID `com.mcburgs.thebusiness.dev`;
- arm64-only APK targeting for the designated Pixel;
- explicit offline-first permission posture with no requested `INTERNET` permission;
- required ETC2/ASTC texture import support for Android export;
- 720x720 square design base with `canvas_items` + `expand` and responsive sensor orientation;
- narrow phone layout with map/detail exclusivity and bottom navigation;
- 48 logical-pixel minimum interactive targets;
- one-finger map pan, two-finger pinch zoom and direct touch market selection;
- Android/system Back returning detail surfaces to the map before exit;
- persistent campaign startup/resume through `CampaignSession` and the existing `SaveService`/Chronicle authority;
- checkpoint after successful authoritative month resolution;
- coalesced background checkpoint requests and retry after failed checkpoint;
- structurally complete last-good recovery;
- exact integer/float preservation at the physical JSON boundary so save/relaunch cannot change deterministic world/history fingerprints.

## Acceptance matrix

| # | Criterion | Status | Evidence |
|---:|---|---|---|
| 1 | Exact published G→H baseline used | PASS | required commit/tree/parent verified before implementation |
| 2 | Pinned Godot preserved | PASS | `4.7.2.stable.official.ed1daf0bf` locally and in Android CI build |
| 3 | Reproducible Android export configuration exists | PASS | `export_presets.cfg`, arm64 debug, reversible package ID, documented toolchain |
| 4 | Actual installable APK produced | PASS | `the-business-phase-h-debug.apk`, 29,192,408 bytes |
| 5 | APK installs on designated Pixel | PASS | Pixel 9a physical install |
| 6 | App launches successfully | PASS | physical first launch |
| 7 | Strategic map remains home | PASS | physical device + automated scene tests |
| 8 | Correct campaign/controlled promotion loads | PASS | physical `Promotion Alpha` ownership surface + session tests |
| 9 | Touch market selection works | PASS | physical touch + synthetic touch regression |
| 10 | Map navigation is practical | PASS | physical one-finger pan/pinch; UI density recorded as Phase-I debt |
| 11 | Required information is not hover-only | PASS | static gate + physical touch-capable controls |
| 12 | People/roster is usable | PASS | physical device navigation |
| 13 | Touring is usable | PASS | physical device navigation |
| 14 | Wrestling/program context is usable | PASS | physical device navigation |
| 15 | Chronicle/history is usable | PASS | physical device navigation + retained Chronicle tests |
| 16 | Canonical legal UI action succeeds | PASS | physical meaningful state change + retained canonical command-path tests |
| 17 | G→H duplicate/stale protections remain effective | PASS | 40/40 suite + retained hostile harness + physical aggressive-tap smoke |
| 18 | Strategic month advances exactly once | PASS | physical device + duplicate-month regression |
| 19 | Post-month presentation refreshes correctly | PASS | physical device + Phase G/G→H presentation regressions |
| 20 | Pause/resume works | PASS | physical background/resume + lifecycle tests |
| 21 | Background/foreground works | PASS | physical 20–30 second background/foreground smoke + coalescing/retry tests |
| 22 | Close/relaunch works | PASS | physical force-close/relaunch + filesystem restart test |
| 23 | Save/reload remains coherent | PASS | physical persisted state + exact state/Chronicle reload regression |
| 24 | Chronicle/current state remain coherent | PASS | physical smoke + retained save/Chronicle fingerprint tests |
| 25 | Recovery behavior acceptable for slice | PASS | corrupt-primary -> last-good recovery regression; physical relaunch path clean |
| 26 | No Android-specific domain authority exists | PASS | static boundary gate |
| 27 | Ownership Seat remains non-person | PASS | physical UI + retained F-R/G/G→H tests |
| 28 | Hidden information remains governed | PASS | physical visible-estimate UI + query/G→H knowledge tests |
| 29 | Orientation decision/open status has physical evidence | PASS | portrait/landscape both exercised; responsive sensor orientation retained |
| 30 | Target-device performance acceptable/profiled | PASS WITH DOCUMENTED LIMIT | no visible blocker under physical smoke; no numerical ADB profiling in direct-install session; off-device timings retained |
| 31 | Complete automated suite passes | PASS | 40/40 |
| 32 | G→H regressions pass | PASS | retained harness + suite |
| 33 | F2G-001/002/003 pass | PASS | retained automated regressions |
| 34 | Competition regression passes | PASS | 24/24 months; save round-trip PASS |
| 35 | Five-year soak passes without drift | PASS | 8x60; accepted run payload preserved value-for-value |
| 36 | Save/Chronicle tests pass | PASS | retained + Phase-H lifecycle/save/recovery tests |
| 37 | Fresh editor/import passes | PASS | headless editor exit 0 |
| 38 | Android export passes | PASS | GitHub Actions run `34292406652`, export/identity/signing checks all green |
| 39 | Static gate passes | PASS | `we.phase_h.static_check.v1`, zero failures/warnings |
| 40 | Hygiene gates pass | PASS | diff checks, generated/cache/credential audit and final staged check |
| 41 | Documentation complete | PASS | acceptance/runtime/device + project records updated |
| 42 | Exact clean commit-ready staged state | PASS | final staged tree recorded after full verification |

## APK identity

- filename: `the-business-phase-h-debug.apk`
- package ID: `com.mcburgs.thebusiness.dev`
- ABI: `arm64-v8a`
- size: `29192408` bytes
- SHA-256: `43fd8d26529fc7bdf90456bd47326943da01fe6f715d1512cd5780db6d122040`
- build source commit: `4009537e5bc0046b6c6c42055988cfabbb2ffdbb`
- build source tree: `fed0f9218a6a592fd3c43ec80ee8eec17ea7c933`
- signing: ephemeral development/debug key; v2/v3 signature verification PASS
- requested permissions: no Android runtime/network permission declared by the APK inspection evidence

## Verified target

- device: **Google Pixel 9a**
- Android: **17**
- physical install/launch/touch/navigation/month/lifecycle/relaunch/save acceptance: **PASS**
- orientation: **responsive portrait + landscape retained for Phase H**
- known non-blocking debt: **phone presentation is dense/rough and requires Phase-I UX/polish work**

## Conclusion

**Phase H is VERIFIED.** The first real Android target-device build is installable and operational on the designated Pixel, while the accepted simulation/application/persistence authority remains intact. Phase I and the later H→I adversarial device/persistence abuse gate have not begun.
