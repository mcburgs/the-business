extends RefCounted

const ContentLoader = preload("res://app/content/content_loader.gd")
const INVALID_ROOT: String = "res://tests/fixtures/phase_b/invalid"
const CASES: Array[String] = [
    "duplicate_ids",
    "missing_reference",
    "illegal_range",
    "dependency_failure",
    "path_traversal",
    "remote_reference",
    "executable_reference",
    "invalid_narrative_context",
    "unknown_field",
]

func run() -> Dictionary:
    var failures: Array[String] = []
    var observed: Dictionary = {}
    for case_name: String in CASES:
        var expected: Dictionary = _read_expected(INVALID_ROOT.path_join(case_name).path_join("expected.json"), failures)
        if expected.is_empty():
            continue
        var loader: Variant = ContentLoader.new()
        var case_dir: String = INVALID_ROOT.path_join(case_name)
        var case_search_roots: Array[String] = ["res://content/base", case_dir]
        var result: Dictionary = loader.load_campaign(case_dir, case_search_roots)
        _expect(not bool(result.get("passed", true)), "Invalid fixture unexpectedly passed: " + case_name, failures)
        var expected_code: String = str(expected.get("code", ""))
        _expect(_has_code(result.get("errors", []), expected_code), "Invalid fixture '%s' did not emit expected %s. Errors: %s" % [case_name, expected_code, JSON.stringify(result.get("errors", []))], failures)
        observed[case_name] = result.get("errors", [])
    return {"name": "phase_b_invalid_content", "passed": failures.is_empty(), "failures": failures, "observed": observed}

func _read_expected(path: String, failures: Array[String]) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        failures.append("Unable to open invalid fixture expectation: " + path)
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        failures.append("Invalid expected.json: " + path)
        return {}
    return parsed

func _has_code(errors_value: Variant, code: String) -> bool:
    if not errors_value is Array:
        return false
    for error_value: Variant in errors_value:
        if error_value is Dictionary and str((error_value as Dictionary).get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
