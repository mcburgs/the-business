# H→I Adversarial Device and Persistence Acceptance

Gate: **H→I — Adversarial Device and Persistence Validation**
Target baseline: Phase H `356e4fa2eb3c791e67ec0a2711df3d10e4db6487` / tree `fef771ef5873ef622ab8dff5d1e0e8c00881e30b`
Pinned engine: Godot `4.7.2.stable.official.ed1daf0bf`
Status: **OFF-DEVICE VERIFIED — ANDROID EXPORT / PHYSICAL PIXEL EVIDENCE PENDING**

H→I is not complete until all rows are green on the exact final candidate and the targeted Pixel abuse sequence passes.

| Requirement | Current evidence |
|---|---|
| Frozen GitHub baseline exact | PASS |
| Clean reconstructed baseline before changes | PASS |
| H2I-001 interrupted-publication reproduction | PASS on frozen baseline |
| H2I-002 CampaignState/Chronicle corruption reproduction | PASS on frozen baseline |
| H2I-003 backup-copy durability attack | PASS via retained fault injection |
| Interrupted transaction recovery | PASS |
| Invalid/incomplete temp cannot become authoritative | PASS |
| Unrecoverable interrupted artifacts fail closed | PASS |
| Physical payload corruption detection | PASS |
| Chronicle/state/manifests cross-agree | PASS |
| `last_good` + `older_good` fallback rotation | PASS |
| Pending UI intents remain transient across process death | PASS |
| Failed checkpoint remains retryable | PASS, retained Phase-H regression |
| Complete automated suite | PASS, 41/41 on final off-device candidate |
| Retained G→H hostile interaction harness | PASS |
| Dedicated H→I persistence harness | PASS: 12 months / 12 relaunches / 9 injected interruptions / 90 historical reads |
| Phase-F competition regression | PASS: 24/24 months + save round-trip |
| Eight-run five-year soak | PASS: 8 x 60 months; repeated-seed deterministic; 7 unique seeds -> 7 distinct fingerprints; zero accepted-evidence simulation drift |
| Fresh editor/import | PASS, exit 0 on final off-device candidate |
| Android export / APK inspection | pending |
| Physical Pixel 9a / Android 17 abuse | pending |
| Final diff/hygiene | pending final post-APK/device check |
| Commit-ready staging | pending until device evidence is incorporated |

## Pass condition

H→I passes only when no known tested device/lifecycle sequence can silently corrupt CampaignState or Chronicle, duplicate authoritative commands/months, bypass command/knowledge authority, or strand the player without a diagnosable recovery path.

No Phase-I content/tuning/polish work begins before this record reaches VERIFIED and the verified candidate is explicitly authorized for commit/publish.
