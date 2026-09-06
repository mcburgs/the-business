extends RefCounted

const FORBIDDEN_SCENARIO_TOKENS: Array[String] = ["great_lakes", "great lakes", "1975", "promotion alpha", "promotion beta", "promotion gamma"]

func run() -> Dictionary:
    var failures: Array[String] = []
    var scripts: Array[String] = []
    _collect_scripts("res://app", scripts, failures)
    _collect_scripts("res://domain", scripts, failures)
    scripts.sort()
    for path: String in scripts:
        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null:
            failures.append("Unable to inspect script: " + path)
            continue
        var lowered: String = file.get_as_text().to_lower()
        file.close()
        for token: String in FORBIDDEN_SCENARIO_TOKENS:
            if lowered.contains(token):
                failures.append("Scenario-specific token '%s' found in application/domain code: %s" % [token, path])
    return {"name": "phase_b_no_scenario_special_case", "passed": failures.is_empty(), "failures": failures, "scripts_checked": scripts.size()}

func _collect_scripts(root: String, output: Array[String], failures: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(root)
    if directory == null:
        failures.append("Unable to inspect code directory: " + root)
        return
    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while entry != "":
        if entry != "." and entry != "..":
            var path: String = root.path_join(entry)
            if directory.current_is_dir():
                _collect_scripts(path, output, failures)
            elif entry.ends_with(".gd"):
                output.append(path)
        entry = directory.get_next()
    directory.list_dir_end()
