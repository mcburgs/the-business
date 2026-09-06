# Build and Verification

## Pinned engine

Use **Godot 4.7.2-stable, standard build**. Do not silently upgrade the project to another engine line. Any deliberate engine change requires a version-control checkpoint and a CHANGELOG entry.

Verify the executable first:

```text
godot --version
```

The expected engine line is `4.7.2.stable` / `4.7.2-stable` depending on platform output formatting.

## Phase A static check

From the repository root:

```text
python tools/static_repo_check.py
```

A passing static check establishes repository shape and dependency-guard prerequisites. It does not replace an engine run.

## Phase A headless gate

Canonical command:

```text
godot --headless --path . --script res://tests/runner.gd
```

The runner:

- boots under stock Godot without an editor plugin;
- recursively discovers `test_*.gd` scripts under `tests/unit/` and `tests/integration/`;
- emits JSON-line diagnostics prefixed `WE_DIAG`;
- emits one machine-readable summary prefixed `WE_TEST_SUMMARY`;
- writes a JSON result artifact to `user://diagnostics/headless-results.json` by default;
- exits `0` on pass, `1` on test failure, `2` on harness/discovery failure, and `3` if tests pass but the result artifact cannot be written.

An explicit output location may be supplied after `--`:

```text
godot --headless --path . --script res://tests/runner.gd -- --output=res://tests/output/headless-results.json
```

`tests/output/*.json` is intentionally ignored by Git.

## Parse-only checks

Godot also supports `--check-only` for scripts. The full headless runner is the acceptance command because it exercises discovery and runtime behavior, but parse-only checks can isolate a syntax failure:

```text
godot --headless --path . --script res://tests/runner.gd --check-only
```

## Launch shell

To launch the minimal Phase A project shell:

```text
godot --path .
```

To import/open in the editor:

```text
godot --editor --path .
```

The launch shell must not become an owner of domain state. Real presentation work begins later.

## Windows note

If Godot is not on PATH, invoke the pinned console executable directly. Example PowerShell shape:

```text
& "C:\\path\\to\\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/runner.gd
```

Use the actual local filename/path rather than changing repository files to match one workstation.

## Git handoff

The repository is initialized with `origin` pointing to:

```text
https://github.com/mcburgs/the-business.git
```

After engine-backed verification and any retained fixes:

```text
git status
git add -A
git commit -m "Verify Phase A under Godot 4.7.2"
git push -u origin main
```

Do not preserve a Work/editor-only fix outside source control.

## Not part of Phase A

- Gameplay formulas
- Great Lakes production content
- Domain schema reinvention
- Android export configuration beyond later environment sanity work
- Production UI or map implementation
