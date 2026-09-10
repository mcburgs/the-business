# H→I Adversarial Device and Persistence Findings

Gate: **H→I — Adversarial Device and Persistence Validation**
Frozen target: `356e4fa2eb3c791e67ec0a2711df3d10e4db6487`
Frozen tree: `fef771ef5873ef622ab8dff5d1e0e8c00881e30b`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`

## Purpose

H→I attacks the accepted Phase-H Android/persistence architecture under process interruption, save corruption, lifecycle churn, repeated input, reload pressure and recovery failure. It does not add Phase-I content or change simulation meaning.

## H2I-001 — interrupted directory publication could silently reset a recoverable campaign

**Classification:** stop-the-line persistence defect
**Frozen-baseline reproduction:** confirmed
**Status:** fixed; regression retained

Phase H published a checkpoint by moving the valid primary directory to `.previous` and then renaming the validated `.tmp` directory into the canonical location. If the process died between those renames, the next startup saw no canonical save directory, treated the campaign as new, and the subsequent save path could delete `.previous`. A recoverable CampaignState + Chronicle could therefore be silently replaced by turn zero.

**Repair:** `SaveService.recover_interrupted_transaction()` settles transactional artifacts before `CampaignSession` may interpret absence of the primary directory as a new game. A fully validated newer temp checkpoint is promoted; a valid previous snapshot can be restored; invalid/incomplete artifacts never become history; unrecoverable interrupted artifacts fail closed with `SAVE001` rather than fabricating a new campaign. Chained primary/temp/previous states are resolved using monotonic turn/Chronicle rank.

## H2I-002 — schema-valid disk corruption could evade save validation

**Classification:** stop-the-line state/history integrity defect
**Frozen-baseline reproduction:** confirmed for CampaignState and Chronicle
**Status:** fixed; regressions retained

Phase-H codecs correctly rejected malformed structures, but schema-valid physical mutations could still load. Two frozen-baseline attacks demonstrated this: removing a valid-looking Chronicle delta while leaving the manifest counts unchanged, and changing a Person display name in `state.json`. Both were accepted as ordinary resumes.

**Repair:** every newly written H→I checkpoint records SHA-256 hashes for the physical CampaignState and Chronicle payloads. Load also cross-validates state date/ownership, Chronicle head/sequence/checkpoint generation, both Chronicle integrity summaries, and state/Chronicle date agreement. Accepted older Phase-H/Phase-F migration saves remain readable; current-architecture saves without hashes remain backward compatible until their next checkpoint, which writes hashes.

## H2I-003 — failed backup materialization could destroy the only previous-good source

**Classification:** recovery durability defect
**Frozen code-path analysis:** confirmed; fault-injection regression retained
**Status:** fixed

After publishing the new primary, Phase H attempted to copy `.previous` into `backups/last_good` and then removed `.previous` even when the copy failed. Low-storage or filesystem error during that copy could therefore reduce recovery durability at exactly the wrong moment.

**Repair:** a failed backup copy leaves `.previous` intact and diagnosable for the next recovery attempt. Successful settlement creates a two-generation rotation: `backups/last_good` and `backups/older_good`. Startup falls through to `older_good` if both the primary and `last_good` are invalid.

## Retained non-defects / protections

The attack retained and re-exercised G→H setter-intent coalescing, duplicate-month suppression, stale-selection rejection, Chronicle transient-card ownership, hidden-information projection boundaries, abstract Ownership Seat identity, synchronous pause checkpointing and pending-intent transience. None required architecture weakening.

## Scope conclusion

All three H→I findings were repairable inside the existing application/persistence boundary. No second save model, Android-only authoritative state, historical resimulation, player Person/avatar, Great-Lakes engine branch, alternate month resolver, or presentation-owned truth was introduced.
