# Phase H Pixel / Android Target Build Acceptance

Phase: **H — Pixel / Android Target Build and Integration**
Required starting commit: `1944ef08e5f43ffdfa67e86d1ef1dfa94a806e6d`
Required starting tree: `bb77e7f63f291ddfdefcb760224e254378a0f897`
Required parent: `8b732d2568fd36430b6d7260fcd9446dfe54bfd3`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Status: **IN PROGRESS — OFF-DEVICE GATES PASSING; ANDROID EXPORT + PHYSICAL PIXEL EVIDENCE PENDING**

## Scope

Phase H puts the accepted Phase G/G→H vertical slice onto the designated Android Pixel without creating mobile-specific simulation authority. It adapts presentation, lifecycle and persistence only as required for a practical phone build. It does not begin Phase I gameplay/content/polish work or the later H→I adversarial device-abuse gate.

## Locked authority

The strategic map remains home. The player remains the non-person `OwnershipSeatState`. Android presentation remains a client of authoritative application/domain state.

Read path:

`CampaignState / Chronicle -> OwnerPresentationQuery -> governed projection -> presentation`

Write path:

`presentation intent -> CampaignSession -> CommandEnvelope -> CommandRouter -> MonthPipeline -> authoritative state -> fresh projection`

G→H protections remain mandatory: setter-intent coalescing, duplicate-month suppression, stale-selection rejection, Chronicle transient-card ownership, cross-promotion authority rejection and hidden-information boundaries.

## Phase H implementation obligations

The current Phase H candidate provides:

- a reproducible `Android Debug` export preset with reversible package ID `com.mcburgs.thebusiness.dev`;
- arm64-only debug APK targeting for the designated modern Pixel;
- explicit `permissions/internet=false` export policy, preserving the offline-first slice;
- sensor orientation during Phase-H evidence gathering;
- a 720x720 square design base with `canvas_items` + `expand`, preserving the accepted 1280x720 landscape composition while giving portrait and landscape comparable UI scale;
- narrow phone layout with map/detail exclusivity and bottom navigation;
- 48 logical-pixel minimum interactive targets, which scale to larger physical targets on high-density phone output;
- one-finger map pan, two-finger pinch zoom and direct touch market selection;
- Android/system Back returning detail surfaces to the map before exit;
- persistent campaign startup/resume through `CampaignSession` and the existing `SaveService`/Chronicle authority;
- save after successful authoritative month resolution;
- coalesced background checkpoint requests and retry after a failed checkpoint;
- structurally complete last-good recovery;
- exact integer/float preservation at the physical JSON boundary so save/relaunch cannot change deterministic world/history fingerprints.

## Acceptance matrix

Legend: **PASS** = proven off-device or by retained accepted evidence; **PENDING DEVICE** = requires designated Pixel; **PENDING TOOLCHAIN** = requires Android SDK/export templates unavailable in the current execution environment.

| # | Criterion | Status | Evidence |
|---:|---|---|---|
| 1 | Exact published G→H baseline used | PASS | commit/tree/parent and GitHub `main` independently verified |
| 2 | Pinned Godot preserved | PASS | `4.7.2.stable.official.ed1daf0bf` |
| 3 | Reproducible Android export configuration exists | PASS | `export_presets.cfg`, Android Debug, arm64, reversible package ID |
| 4 | Actual installable APK produced | PENDING TOOLCHAIN | current container lacks 4.7.2 Android templates and Android SDK |
| 5 | APK installs on designated Pixel | PENDING DEVICE | physical device required |
| 6 | App launches successfully | PENDING DEVICE | physical device required |
| 7 | Strategic map remains home | PASS off-device / PENDING DEVICE | automated scene test + portrait/landscape renders; physical launch still required |
| 8 | Correct campaign/controlled promotion loads | PASS off-device / PENDING DEVICE | session/projection tests; physical launch still required |
| 9 | Touch market selection works | PASS off-device / PENDING DEVICE | synthetic `InputEventScreenTouch`; physical touch still required |
| 10 | Map navigation is practical | PASS off-device / PENDING DEVICE | pan/pinch tests and renders; ergonomics requires Pixel |
| 11 | Required information is not hover-only | PASS | static gate + touch-capable controls |
| 12 | People/roster is usable | PASS off-device / PENDING DEVICE | responsive portrait render + automated navigation |
| 13 | Touring is usable | PASS off-device / PENDING DEVICE | responsive portrait render + automated navigation |
| 14 | Wrestling/program context is usable | PASS off-device / PENDING DEVICE | responsive portrait render + automated navigation |
| 15 | Chronicle/history is usable | PASS off-device / PENDING DEVICE | responsive portrait render + retained Chronicle tests |
| 16 | Canonical legal UI action succeeds | PASS off-device / PENDING DEVICE | retained Phase G/G→H canonical command path; physical tap pending |
| 17 | G→H duplicate/stale protections remain effective | PASS | complete suite + retained G→H harness |
| 18 | Strategic month advances exactly once | PASS off-device / PENDING DEVICE | G→H duplicate-month regression; physical tap pending |
| 19 | Post-month presentation refreshes correctly | PASS off-device / PENDING DEVICE | Phase G/G→H presentation regressions; physical view pending |
| 20 | Pause/resume works | PASS seam / PENDING DEVICE | lifecycle checkpoint tests; OS lifecycle pending |
| 21 | Background/foreground works | PASS seam / PENDING DEVICE | lifecycle coalescing/retry tests; OS lifecycle pending |
| 22 | Close/relaunch works | PASS seam / PENDING DEVICE | real filesystem save/relaunch test; Android process lifecycle pending |
| 23 | Save/reload remains coherent | PASS off-device / PENDING DEVICE | exact state + Chronicle reload and cross-save deterministic fingerprint |
| 24 | Chronicle/current state remain coherent | PASS off-device / PENDING DEVICE | save/relaunch and retained Chronicle tests |
| 25 | Recovery behavior acceptable for slice | PASS off-device / PENDING DEVICE | corrupt-primary -> load last-good -> restore primary test |
| 26 | No Android-specific domain authority exists | PASS | static boundary gate |
| 27 | Ownership Seat remains non-person | PASS | retained F-R/G/G→H tests + static gate |
| 28 | Hidden information remains governed | PASS | retained query/G→H knowledge tests |
| 29 | Orientation decision/open status has physical evidence | PENDING DEVICE | sensor orientation retained; off-device portrait/landscape both viable |
| 30 | Target-device performance acceptable/profiled | PENDING DEVICE | physical measurements required |
| 31 | Complete automated suite passes | PASS | 40/40 at current candidate verification |
| 32 | G→H regressions pass | PASS | retained harness + suite |
| 33 | F2G-001/002/003 pass | PASS | retained automated regressions |
| 34 | Competition regression passes | PASS | 24/24 months; save round-trip PASS |
| 35 | Five-year soak passes without drift | PASS | 8x60; run payload value-for-value equal to accepted F-R soak |
| 36 | Save/Chronicle tests pass | PASS | retained + new lifecycle/save tests |
| 37 | Fresh editor/import passes | PASS | headless editor exit 0; no repository parser/import errors |
| 38 | Android export passes | PENDING TOOLCHAIN | preset recognized; export blocked only by missing external SDK/templates |
| 39 | Static gate passes | PASS after Phase-H records are present | `we.phase_h.static_check.v1` |
| 40 | Hygiene gates pass | PASS pre-staging | `git diff --check` PASS; generated/cache/credential audit clean; staged check deferred until full gate completion |
| 41 | Documentation complete | PASS for candidate / device fields pending | this record + runtime/device records |
| 42 | Exact clean commit-ready staged state | PENDING DEVICE | cannot certify full Phase H before Android export/device acceptance |

## Stop condition

Phase H must **not** be marked VERIFIED until an APK is built and the designated physical Pixel completes the device checklist in `docs/PHASE_H_DEVICE_RESULT.md`. A clean off-device candidate is not equivalent to physical acceptance.
