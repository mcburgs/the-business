# Phase C Runtime Verification Result

## Result

**PASS**

Phase C was runtime-verified on 2026-09-06 using the pinned official Godot build.

## Engine

- Project engine pin: `4.7.2-stable`
- Runtime actually used: `4.7.2.stable.official.ed1daf0bf`
- Uploaded Linux release ZIP SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`

## Static gate

Command:

```text
python tools/static_repo_check.py
```

Result:

- PASS
- failures: 0
- warnings: 0
- schema: `we.phase_c.static_check.v1`

## Canonical headless gate

Command:

```text
godot --headless --path . --script res://tests/runner.gd
```

Result:

- exit code: 0
- tests discovered: 16
- tests passed: 16
- tests failed: 0
- harness failures: 0
- Phase A/B regression tests: PASS
- Phase C state round-trip, command, entity-store, knowledge-projection, RNG, and invariant tests: PASS

## Fresh editor import

Verification command shape used with the same pinned binary:

```text
godot --headless --editor --path . --quit-after 120
```

Result:

- exit code: 0
- parser errors: 0
- retained import errors: 0
- retained project-configuration errors: 0
- legitimate new `.gd.uid` sidecars were generated and retained

## Final-tree procedure

After promotion from candidate metadata to `0.0.0-phase-c`, the static gate and canonical headless gate are rerun against the exact final tree. The staged tree is then checked with:

```text
git diff --cached --check
```

Phase C is not considered committed until those final checks pass.
