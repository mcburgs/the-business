# Phase D Acceptance Record

## Status

**PASS - VERIFIED PHASE D**

Phase D Headless Core Loop was verified on 2026-09-06 against the exact tree intended for commit under Godot `4.7.2.stable.official.ed1daf0bf`.

## Implemented scope

- D.1 explicit `TurnContext`/`TurnResult` and inspectable 15-phase monthly pipeline, with deterministic command commitment, narrow extension hooks, transactional clone/resolve/postflight/publish behavior, and no Phase E gameplay formulas.
- D.2 structured DomainEvent stream with transient turn events, permanent stable event IDs, monotonic Chronicle sequence identity, stable historical references, causal/narrative metadata boundaries, and CHR001/CHR002 validation.
- D.3 minimal reconciled ledger infrastructure using deterministic postings, integer minor units plus currency-definition IDs, source/reference metadata, validation-before-mutation, and rejection of unbalanced/invalid transactions.
- D.4 ChronicleStore logical EventJournal, MetricSeriesStore, CheckpointStore, DeltaStore, ChronicleIndex, skeletal ArtifactIndex, historical identity catalog/tombstones, and read-only ChronicleQueryService.
- D.5 SaveService orchestration for CampaignState plus Chronicle head/data and SaveManifest, compatibility validation, coherent temporary write/validation/publication, exact RNG checkpoint persistence, last-good backup skeleton, and migration-entry preservation.
- D.6 generic `tools/simulation_cli/run.gd` campaign/session/month/seed runner with structured diagnostics and optional save/reload proof.
- D.7 automated 12-month recorded-history proof using sparse checkpoints and deltas, with historical reconstruction performed while simulation resolution and RandomService are unavailable.

## Chronicle reconstruction model

`HistoricalProjection` is a purpose-built reconstruction model, not a CampaignState snapshot. `get_projection(target_date)` finds the nearest checkpoint at or before the target date, copies it, then applies ordered sparse add/replace/remove deltas through the requested date. The synthetic acceptance policy uses a smaller deterministic checkpoint cadence for proof; production cadence remains configurable and unresolved.

The 12-month fixture creates meaningful state changes by alternating an already-canonical championship assignment through the existing command boundary. It does not add touring, booking, audience, influence, economic, or AI gameplay merely to create test activity.

## Controlled reconstruction

The unavailable original Phase 0 machine schema is not claimed to have been recovered. Phase D reconstructs only machine-readable turn/Chronicle/save-orchestration/ledger structures directly supported by governing prose. Notable controlled decisions are recorded in `content/schemas/DERIVATION.md` and `docs/DECISIONS.md`, including sparse Chronicle representation, configurable checkpoint policy, coarse physical Chronicle JSON with logical store separation, `world_state.ledger_v1`, and exact 64-bit RNG-state handling at the JSON persistence boundary.

## Preserved open questions

Phase D does not lock final Chronicle metric cadence, checkpoint cadence, physical chunking/compression, bytes/year target, compaction policy, archive artifact permanence, a project-owned PRNG replacement, full-game entity scale ceilings, gameplay formulas/tuning, or Android-specific I/O behavior.

## Acceptance gate

- [x] Synthetic campaign advances at least 12 months headlessly through the real pipeline.
- [x] Canonical 15-phase pipeline executes in exact deterministic ordinal order 0 through 14.
- [x] Deterministic command commitment remains `(turn phase ordinal, priority, issuer_key, command_id)`.
- [x] Rejected commands do not partially mutate retained state.
- [x] Corrupt starting state fails preflight and does not publish a successful turn.
- [x] Deliberate test-phase corruption is caught by postflight and does not publish a successful month/autosave request.
- [x] Permanent journal events receive stable event IDs and monotonic sequence IDs.
- [x] Chronicle event/head ordering validates and malformed identity/sequence fails with CHR001.
- [x] Historical references resolve through active/inactive identity data and broken historical IDs fail with CHR002.
- [x] Ledger accepts valid reconciled postings and rejects unbalanced postings without partial retained mutation.
- [x] Checkpoints contain HistoricalProjection state rather than whole CampaignState snapshots.
- [x] Sparse Chronicle deltas reconstruct a selected prior month correctly.
- [x] Reconstruction succeeds with simulation resolution unavailable.
- [x] Reconstruction succeeds with RandomService unavailable and consumes no RNG.
- [x] Reconstruction does not mutate current CampaignState.
- [x] Corrupt checkpoint/delta reconstruction fails with CHR003.
- [x] Save/write/load preserves authoritative current state, Chronicle head/meaning, RNG checkpoint, and stable current/historical references.
- [x] Content fingerprint mismatch fails with SAVE001.
- [x] Unsupported newer save schema fails with SAVE002.
- [x] Injected failed publication leaves the last known-good save available.
- [x] Generic headless CLI accepts campaign/session selection, month count, and explicit seed and emits structured summary/failure data.
- [x] Existing Phase A/B/C tests remain green.
- [x] Static gate passes with zero failures and zero warnings.
- [x] Canonical Godot headless gate exits 0 with 20 discovered / 20 passed / 0 failed / 0 harness failures.
- [x] Phase D 12-month CLI/save-roundtrip acceptance invocation exits 0 and completes all 12 months.
- [x] Fresh editor import under the pinned engine exits 0 with no retained parser/import/project-configuration errors.
- [x] Legitimate generated `.gd.uid` sidecars are retained and generated caches/output are excluded.
- [x] `git diff --cached --check` passes on the final staged tree.

## Rework-trigger assessment

Neither architectural rework trigger was reached. Historical reconstruction does not resimulate and has no simulation/RandomService dependency. Chronicle reconstruction does not require redundant full monthly HistoricalProjection snapshots; the acceptance run uses 2 checkpoints and 10 monthly deltas across 12 months.

See `docs/PHASE_D_RUNTIME_RESULT.md` for exact runtime evidence.
