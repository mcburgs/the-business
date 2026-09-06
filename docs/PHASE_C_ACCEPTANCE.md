# Phase C Acceptance Record

## Status

**PASS - VERIFIED PHASE C**

Phase C Domain Kernel was verified on 2026-09-06 against the exact tree intended for commit under Godot `4.7.2.stable.official.ed1daf0bf`.

## Implemented scope

- C.1 stable runtime/content ID validation, authoritative ID-keyed stores, stable sorted iteration, non-reused runtime identities, non-erasing lifecycle posture, and structured ID/reference diagnostics.
- C.2 authoritative `CampaignState` plus Person, Promotion, Market, Region, TouringCompany, Contract, Championship, Program, MediaDeal, Venue, Agreement, Relationship, OwnershipSeat, KnowledgeBase, EventState, RandomState, and supporting Phase C value-object shells.
- C.3 closed 29-command catalog, deterministic queue ordering, structured command results, stale/invalid rejection, and retained `set_champion` mutation through the application boundary.
- C.4 one-root-stream Godot `RandomNumberGenerator` service with explicit provider, seed, internal state, captured turn, stream policy, and checkpoint restore.
- C.5 state invariant validation for ID/store/reference/family/range/money/assignment/title/contract/touring/content boundaries plus deliberate corruption tests and a derived drawing-power input query that does not persist a score or invent weights.
- C.6 explicit current-state codec, strict schema-v1 parent/entity fields, load validation, save-manifest scaffold, content fingerprint/RNG checkpoint metadata, and migration entry point.
- C.7 organization-owned knowledge storage plus known/estimated/unknown projection without a `true_value` field, with debug truth access separate from normal query paths.

## Deliberate Phase C boundaries

- No monthly simulation or 15-phase month pipeline.
- No AI strategy, economy, booking/show resolution, touring resolution, or invented balance formulas.
- No ChronicleStore, historical reconstruction, replay, journal orchestration, backup/recovery orchestration, production UI, or Android integration.
- Retired entities are not compacted in Phase C. They remain in their ID-keyed store, preserving non-reuse and future Chronicle/tombstone compatibility without implementing Chronicle early.
- Future-facing command types are recognized by the closed catalog but reject through structured command results when their actual resolution belongs to later phases. They do not execute later-phase simulation as no-ops.

## Acceptance gate

- [x] Synthetic CampaignState with multiple entity counts validates.
- [x] Serialize -> deserialize -> validate reproduces current authoritative state.
- [x] Every retained mutation exercised by tests flows through CommandRouter.
- [x] Rejected command leaves state unchanged.
- [x] Command order is deterministic: phase ordinal, priority, issuer key, command ID.
- [x] RNG state persists and seeded fixtures reproduce under the pinned engine.
- [x] Knowledge projections withhold unobserved hidden truth.
- [x] Derived drawing power is not persisted as duplicate authoritative truth.
- [x] Deliberately corrupt state emits structured actionable diagnostics.
- [x] Existing Phase A/B tests remain green.
- [x] Static repository/content/domain-kernel gate passes with zero failures and zero warnings.
- [x] Canonical Godot headless gate exits 0 with 16 discovered / 16 passed / 0 failed / 0 harness failures.
- [x] Fresh editor import under pinned engine exits 0 with no retained parser/import/project-configuration errors.
- [x] Legitimate generated `.gd.uid` sidecars are retained.
- [x] `git diff --cached --check` passes on the final staged tree.

The final staged-tree hygiene check is performed immediately before commit. See `docs/PHASE_C_RUNTIME_RESULT.md` for runtime evidence.
