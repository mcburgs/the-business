# Build and Verification

## Pinned engine

Use **Godot 4.7.2-stable, standard build**. Do not silently upgrade the project to another engine line. Any deliberate engine change requires a version-control checkpoint and a CHANGELOG entry.

Verify the executable first:

```text
godot --version
```

The expected engine line is `4.7.2.stable` / `4.7.2-stable` depending on platform output formatting. The Phase A verified official build was `4.7.2.stable.official.ed1daf0bf`.

## Static repository/content check

From the repository root:

```text
python tools/static_repo_check.py
```

For Phase B this checks repository shape, the engine pin, architecture/special-case guards, JSON readability, schema reconstruction metadata, safe pack-file references, required validation fixtures, and the Great Lakes skeleton envelope. It does not replace an engine run.

## Canonical headless gate

```text
godot --headless --path . --script res://tests/runner.gd
```

The runner:

- boots under stock Godot without an editor plugin;
- recursively discovers `test_*.gd` scripts under `tests/unit/` and `tests/integration/`;
- executes the retained Phase A architecture/bootstrap tests and Phase B content/schema/fixture tests;
- emits JSON-line diagnostics prefixed `WE_DIAG`;
- emits one machine-readable summary prefixed `WE_TEST_SUMMARY`;
- writes a JSON result artifact to `user://diagnostics/headless-results.json` by default;
- exits `0` on pass, `1` on test failure, `2` on harness/discovery failure, and `3` if tests pass but the result artifact cannot be written.

An explicit output location may be supplied after `--`:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=res://tests/output/headless-results.json
```

`tests/output/*.json` is intentionally ignored by Git.

## Phase B acceptance evidence

A candidate is not complete merely because content files exist. `docs/PHASE_B_ACCEPTANCE.md` is the controlling implementation checklist for this phase. In particular, the same generic loader must load both the Great Lakes skeleton and a fixture with different entity counts, malformed packs must fail with specific codes, unsafe file references must be rejected, and no Great Lakes/1975 conditional may exist in application/domain code.

The reconstructed `content/schemas/we.phase0.schema.json` is explicitly a controlled static-content replacement derived from the governing prose because the referenced original machine package was not supplied. See `content/schemas/DERIVATION.md`.

The recorded verified Phase B runtime/editor result is in `docs/PHASE_B_RUNTIME_RESULT.md`.

## Parse-only checks

The full headless runner is the acceptance command because it exercises discovery and runtime behavior, but parse-only checks can isolate syntax failures:

```text
godot --headless --path . --script res://tests/runner.gd --check-only
```

## Fresh-clone editor import

After headless tests pass, verify a clean clone/import under the pinned engine:

```text
godot --editor --path .
```

Phase B requires no parser/import warnings attributable to retained source/content. Generated `.godot/` cache data remains ignored.

## Launch shell

```text
godot --path .
```

The launch shell remains deliberately minimal and must not become an owner of domain state.

## Windows note

If Godot is not on PATH, invoke the pinned console executable directly. Example PowerShell shape:

```text
& "C:\\path\\to\\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/runner.gd
```

Use the actual local filename/path rather than changing repository files to match one workstation.

## Phase boundary

Not part of Phase B:

- mutable CampaignState or runtime entity stores;
- command/result mutation architecture;
- RandomService and gameplay simulation formulas;
- current-state save codecs/migrations;
- knowledge projection implementation;
- Chronicle runtime capture/reconstruction;
- deep historical content accuracy or completed roster population;
- final names, portraits, visual assets, full international map, or custom-map editor.
