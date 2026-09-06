extends RefCounted

const REQUIRED_DIRECTORIES: Array[String] = [
    "res://app",
    "res://domain",
    "res://persistence",
    "res://content",
    "res://presentation",
    "res://assets",
    "res://tools",
    "res://tests",
]

const REQUIRED_FILES: Array[String] = [
    "res://project.godot",
    "res://README.md",
    "res://BUILD.md",
    "res://ENGINE_VERSION",
    "res://CHANGELOG.md",
    "res://.gitignore",
    "res://tests/runner.gd",
]

func run() -> Dictionary:
    var failures: Array[String] = []

    for path: String in REQUIRED_DIRECTORIES:
        var directory: DirAccess = DirAccess.open(path)
        _expect(directory != null, "Required directory missing: " + path, failures)

    for path: String in REQUIRED_FILES:
        _expect(FileAccess.file_exists(path), "Required file missing: " + path, failures)

    var ignore_file: FileAccess = FileAccess.open("res://.gitignore", FileAccess.READ)
    if ignore_file == null:
        failures.append("Unable to read .gitignore.")
    else:
        var ignore_text: String = ignore_file.get_as_text()
        ignore_file.close()
        _expect(ignore_text.contains(".godot/"), ".gitignore must exclude the Godot editor cache.", failures)
        _expect(ignore_text.contains("builds/"), ".gitignore must exclude generated builds.", failures)
        _expect(ignore_text.contains("export_credentials.cfg"), ".gitignore must exclude export credentials.", failures)

    return {
        "name": "repository_contract",
        "passed": failures.is_empty(),
        "failures": failures,
    }

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
