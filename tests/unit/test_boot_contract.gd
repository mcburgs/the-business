extends RefCounted

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var expected_main_scene: String = "res://presentation/shell/game_root.tscn"
    var configured_main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))

    _expect(configured_main_scene == expected_main_scene, "application/run/main_scene must point to the minimal presentation shell.", failures)
    _expect(FileAccess.file_exists(expected_main_scene), "Configured main scene does not exist.", failures)
    _expect(ProjectVersion.ENGINE_VERSION == "4.7.2-stable", "Pinned engine constant changed unexpectedly.", failures)
    _expect(ProjectVersion.ARCHITECTURE_VERSION == "0.3.0", "Architecture version must be 0.3.0 for the reconciled Phase F-R baseline.", failures)

    var actual: Dictionary = Engine.get_version_info()
    _expect(int(actual.get("major", -1)) == 4, "Godot major version must be 4.", failures)
    _expect(int(actual.get("minor", -1)) == 7, "Godot minor version must be 7.", failures)
    _expect(int(actual.get("patch", -1)) == 2, "Godot patch version must be 2.", failures)
    _expect(str(actual.get("status", "")) == "stable", "Godot build status must be stable.", failures)

    return {
        "name": "boot_contract",
        "passed": failures.is_empty(),
        "failures": failures,
    }

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
