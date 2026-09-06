extends RefCounted

const ArchitectureSentinel = preload("res://domain/core/architecture_sentinel.gd")

const FORBIDDEN_TOKENS: Array[String] = [
    "extends Node",
    "extends Control",
    "get_tree(",
    "SceneTree",
    "RenderingServer",
    "DisplayServer",
    "AudioServer",
    "Input.",
    "randf(",
    "randi(",
    "Time.",
    "OS.",
]

func run() -> Dictionary:
    var failures: Array[String] = []
    var sentinel: Object = ArchitectureSentinel.new()
    _expect(sentinel is RefCounted, "Domain sentinel must be RefCounted.", failures)
    _expect(not (sentinel is Node), "Domain sentinel must not depend on Node/scene-tree presence.", failures)

    var domain_scripts: Array[String] = []
    _collect_gd_scripts("res://domain", domain_scripts, failures)
    domain_scripts.sort()

    for path: String in domain_scripts:
        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null:
            failures.append("Unable to read domain script: " + path)
            continue
        var text: String = file.get_as_text()
        file.close()
        for token: String in FORBIDDEN_TOKENS:
            if text.contains(token):
                failures.append("Forbidden outward/platform dependency token '%s' found in %s" % [token, path])

    return {
        "name": "domain_dependency_guard",
        "passed": failures.is_empty(),
        "failures": failures,
        "domain_scripts_checked": domain_scripts.size(),
    }

func _collect_gd_scripts(root_path: String, output: Array[String], failures: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(root_path)
    if directory == null:
        failures.append("Unable to open domain directory: " + root_path)
        return

    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while entry != "":
        if entry != "." and entry != "..":
            var child_path: String = root_path.path_join(entry)
            if directory.current_is_dir():
                _collect_gd_scripts(child_path, output, failures)
            elif entry.ends_with(".gd"):
                output.append(child_path)
        entry = directory.get_next()
    directory.list_dir_end()

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
