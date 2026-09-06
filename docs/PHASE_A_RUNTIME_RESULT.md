# Phase A Runtime Result

Date: 2026-09-06

## Verified result

**Static repository gate: PASS**

`python tools/static_repo_check.py` completed with zero failures. It reported one intentional warning: the separate Phase 0 machine-consumable JSON schema package referenced by the governing contract document was not supplied among the available attachments.

## Pinned Godot engine gate

**Status: PASS**

Engine used:

```text
4.7.2.stable.official.ed1daf0bf
```

The official Linux archive matched the SHA-512 checksum published with the Godot 4.7.2-stable release. A clean headless editor open completed without parser, project-configuration, or import warnings after the asset ledger was configured to remain a raw CSV.

Canonical verification command executed from the repository root:

```text
godot --headless --path . --script res://tests/runner.gd
```

Result: exit code `0`; 4 tests discovered, 4 passed, 0 failed, and no harness failures. The runner wrote `user://diagnostics/headless-results.json` successfully.

Retained runtime fixes:

- Corrected the domain dependency guard's statically invalid `RefCounted` versus `Node` type comparison while preserving the intended boundary assertion.
- Made the headless runner treat a non-instantiable test script as a harness failure instead of emitting a false pass after a parser error.
- Marked `assets/asset_ledger.csv` as a raw retained file so Godot does not mis-import its column headings as translation locales.
- Retained Godot-generated script UID sidecars required for stable resource identity under the pinned engine.
- Corrected the static repository check to reject generated/cache paths tracked by Git while allowing the ignored local `.godot` cache created by a valid editor open.
