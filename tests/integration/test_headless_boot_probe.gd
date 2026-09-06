extends RefCounted

const BootProbe = preload("res://app/bootstrap/boot_probe.gd")
const ProjectVersion = preload("res://app/bootstrap/project_version.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var probe: Variant = BootProbe.new()
    var report: Dictionary = probe.collect()

    _expect(report.get("build_phase", "") == ProjectVersion.BUILD_PHASE, "Boot probe build phase does not match project metadata.", failures)
    _expect(report.get("expected_engine", "") == "4.7.2-stable", "Boot probe engine pin is wrong.", failures)
    _expect(report.get("main_scene", "") == "res://presentation/shell/game_root.tscn", "Boot probe main scene is wrong.", failures)

    return {
        "name": "headless_boot_probe",
        "passed": failures.is_empty(),
        "failures": failures,
        "probe": report,
    }

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
