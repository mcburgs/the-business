extends RefCounted

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")

func collect() -> Dictionary:
    var version_info: Dictionary = Engine.get_version_info()
    return {
        "schema": "we.boot_probe.v1",
        "game_version": ProjectVersion.GAME_VERSION,
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION,
        "contract_version": ProjectVersion.CONTRACT_VERSION,
        "build_phase": ProjectVersion.BUILD_PHASE,
        "expected_engine": ProjectVersion.ENGINE_VERSION,
        "actual_engine": str(version_info.get("string", "unknown")),
        "main_scene": str(ProjectSettings.get_setting("application/run/main_scene", "")),
    }
