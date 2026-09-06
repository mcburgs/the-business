extends SceneTree

const DiagnosticLog = preload("res://app/bootstrap/diagnostic_log.gd")
const ProjectVersion = preload("res://app/bootstrap/project_version.gd")

const EXIT_PASS: int = 0
const EXIT_TEST_FAILURE: int = 1
const EXIT_HARNESS_FAILURE: int = 2
const EXIT_ARTIFACT_FAILURE: int = 3

var _diagnostics: Variant
var _results: Array[Dictionary] = []
var _harness_failures: Array[String] = []

func _init() -> void:
    _diagnostics = DiagnosticLog.new()
    _run()

func _run() -> void:
    var metadata: Dictionary = {
        "game_version": ProjectVersion.GAME_VERSION,
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION,
        "contract_version": ProjectVersion.CONTRACT_VERSION,
        "engine_expected": ProjectVersion.ENGINE_VERSION,
        "engine_actual": str(Engine.get_version_info().get("string", "unknown")),
        "campaign": "none",
        "content_fingerprint": "none",
        "seed": "none",
        "months": 0,
        "phase": ProjectVersion.BUILD_PHASE,
    }
    _diagnostics.info("test", "HEADLESS_RUN_BEGIN", "Headless test run started.", metadata)

    var test_paths: Array[String] = []
    _discover_tests("res://tests/unit", test_paths)
    _discover_tests("res://tests/integration", test_paths)
    test_paths.sort()

    if test_paths.is_empty():
        _harness_failures.append("No test scripts were discovered.")

    for test_path: String in test_paths:
        _execute_test(test_path)

    var failed_count: int = 0
    for result: Dictionary in _results:
        if not bool(result.get("passed", false)):
            failed_count += 1

    var summary: Dictionary = {
        "schema": "we.test_run.v1",
        "phase": ProjectVersion.BUILD_PHASE,
        "passed": _harness_failures.is_empty() and failed_count == 0,
        "tests_discovered": test_paths.size(),
        "tests_passed": _results.size() - failed_count,
        "tests_failed": failed_count,
        "harness_failures": _harness_failures.duplicate(),
        "results": _results.duplicate(true),
        "metadata": metadata,
    }

    print("WE_TEST_SUMMARY " + JSON.stringify(summary))
    var artifact_path: String = _output_path_from_args()
    var artifact_ok: bool = _write_summary(artifact_path, summary)

    if not _harness_failures.is_empty():
        _diagnostics.error("test", "HEADLESS_HARNESS_FAILURE", "Headless test harness failed.", {"failures": _harness_failures})
        quit(EXIT_HARNESS_FAILURE)
        return
    if failed_count > 0:
        _diagnostics.error("test", "HEADLESS_TEST_FAILURE", "One or more headless tests failed.", {"failed_count": failed_count})
        quit(EXIT_TEST_FAILURE)
        return
    if not artifact_ok:
        _diagnostics.error("test", "HEADLESS_ARTIFACT_FAILURE", "Tests passed but the result artifact could not be written.", {"path": artifact_path})
        quit(EXIT_ARTIFACT_FAILURE)
        return

    _diagnostics.info("test", "HEADLESS_RUN_PASS", "All discovered headless tests passed.", {"test_count": _results.size(), "artifact": artifact_path})
    quit(EXIT_PASS)

func _discover_tests(root_path: String, output: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(root_path)
    if directory == null:
        _harness_failures.append("Unable to open test directory: " + root_path)
        return

    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while entry != "":
        if entry != "." and entry != "..":
            var child_path: String = root_path.path_join(entry)
            if directory.current_is_dir():
                _discover_tests(child_path, output)
            elif entry.begins_with("test_") and entry.ends_with(".gd"):
                output.append(child_path)
        entry = directory.get_next()
    directory.list_dir_end()

func _execute_test(test_path: String) -> void:
    var script_resource: Resource = load(test_path)
    if script_resource == null or not script_resource is Script:
        _results.append({
            "name": test_path,
            "path": test_path,
            "passed": false,
            "failures": ["Test script could not be loaded as Script."],
        })
        return

    var instance: Variant = (script_resource as Script).new()
    if instance == null or not instance.has_method("run"):
        _results.append({
            "name": test_path,
            "path": test_path,
            "passed": false,
            "failures": ["Test script does not expose run()."],
        })
        return

    var raw_result: Variant = instance.call("run")
    if not raw_result is Dictionary:
        _results.append({
            "name": test_path,
            "path": test_path,
            "passed": false,
            "failures": ["run() did not return a Dictionary."],
        })
        return

    var result: Dictionary = raw_result
    if not result.has("name"):
        result["name"] = test_path
    result["path"] = test_path
    if not result.has("passed"):
        result["passed"] = false
        result["failures"] = ["Test result omitted required passed field."]
    _results.append(result)

func _output_path_from_args() -> String:
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--output="):
            return argument.trim_prefix("--output=")
    return "user://diagnostics/headless-results.json"

func _write_summary(path: String, summary: Dictionary) -> bool:
    var base_dir: String = path.get_base_dir()
    if base_dir != "":
        var absolute_base: String = ProjectSettings.globalize_path(base_dir)
        var make_error: Error = DirAccess.make_dir_recursive_absolute(absolute_base)
        if make_error != OK and make_error != ERR_ALREADY_EXISTS:
            return false

    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(summary, "  "))
    file.store_line("")
    file.close()
    return true
