#!/usr/bin/env python3
"""Phase A repository checks that do not require Godot."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_DIRS = [
    "app/bootstrap", "app/session", "app/commands", "app/queries",
    "domain/core", "domain/people", "domain/promotions", "domain/world",
    "domain/touring", "domain/booking", "domain/audience", "domain/economy",
    "domain/media", "domain/diplomacy", "domain/knowledge", "domain/events",
    "domain/chronicle", "domain/ai", "persistence/migrations", "persistence/codecs",
    "content/base", "content/campaigns/great_lakes_1975", "content/schemas",
    "content/localization", "presentation/shell", "presentation/map",
    "presentation/dashboard", "presentation/people", "presentation/touring",
    "presentation/markets", "presentation/finance", "presentation/inbox",
    "presentation/chronicle", "presentation/common", "assets/ui", "assets/portraits",
    "assets/audio", "assets/fonts", "tools/content_validator", "tools/campaign_builder",
    "tools/simulation_cli", "tests/unit", "tests/integration", "tests/golden",
    "tests/soak", "tests/fixtures",
]

REQUIRED_FILES = [
    "project.godot", "README.md", "BUILD.md", "ENGINE_VERSION", "CHANGELOG.md",
    ".gitignore", ".gitattributes", ".editorconfig", "tests/runner.gd",
    "presentation/shell/game_root.tscn", "presentation/shell/game_root.gd",
    "app/bootstrap/project_version.gd", "app/bootstrap/diagnostic_log.gd",
]

FORBIDDEN_DOMAIN_TOKENS = [
    "extends Node", "extends Control", "get_tree(", "SceneTree", "RenderingServer",
    "DisplayServer", "AudioServer", "Input.", "randf(", "randi(", "Time.", "OS.",
]

GENERATED_ROOT_NAMES = {".godot", ".import", "build", "builds", "dist", ".gradle"}


def check() -> dict:
    failures: list[str] = []
    warnings: list[str] = []

    for rel in REQUIRED_DIRS:
        if not (ROOT / rel).is_dir():
            failures.append(f"missing directory: {rel}")

    for rel in REQUIRED_FILES:
        if not (ROOT / rel).is_file():
            failures.append(f"missing file: {rel}")

    engine_pin = (ROOT / "ENGINE_VERSION").read_text(encoding="utf-8").strip()
    if engine_pin != "4.7.2-stable":
        failures.append(f"ENGINE_VERSION is {engine_pin!r}, expected '4.7.2-stable'")

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    if 'run/main_scene="res://presentation/shell/game_root.tscn"' not in project_text:
        failures.append("project.godot does not point to the Phase A launch shell")

    ignore_text = (ROOT / ".gitignore").read_text(encoding="utf-8")
    for required in (".godot/", "builds/", "export_credentials.cfg"):
        if required not in ignore_text:
            failures.append(f".gitignore missing required pattern: {required}")

    for script in sorted((ROOT / "domain").rglob("*.gd")):
        text = script.read_text(encoding="utf-8")
        for token in FORBIDDEN_DOMAIN_TOKENS:
            if token in text:
                failures.append(f"domain boundary violation token {token!r}: {script.relative_to(ROOT)}")

    tracked_generated = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "--", *sorted(GENERATED_ROOT_NAMES)],
        capture_output=True,
        text=True,
        check=False,
    )
    if tracked_generated.returncode != 0:
        warnings.append("Unable to verify whether generated/cache roots are tracked by Git.")
    else:
        for path in tracked_generated.stdout.splitlines():
            failures.append(f"generated/cache path is tracked by Git: {path}")

    schema_dir = ROOT / "content" / "schemas"
    if not any(p.suffix == ".json" for p in schema_dir.iterdir() if p.is_file()):
        warnings.append(
            "No machine-consumable Phase 0 JSON schema was supplied with the source attachments; "
            "Phase A preserves the boundary and does not invent one."
        )

    return {
        "schema": "we.phase_a.static_check.v1",
        "passed": not failures,
        "failures": failures,
        "warnings": warnings,
    }


def main() -> int:
    result = check()
    print(json.dumps(result, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
