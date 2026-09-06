extends RefCounted

const EXECUTABLE_EXTENSIONS: Array[String] = [
    ".gd", ".gdc", ".cs", ".csx", ".js", ".mjs", ".py", ".pyc", ".exe", ".dll", ".so", ".dylib", ".sh", ".bat", ".cmd", ".ps1", ".tscn", ".scn", ".tres", ".res"
]

func validate_pack_file_path(path: String, field_path: String) -> Array[Dictionary]:
    var errors: Array[Dictionary] = []
    var lowered: String = path.to_lower()
    if path.is_empty():
        errors.append(_error("MOD001", field_path, "Pack file path must not be empty."))
        return errors
    if path.is_absolute_path() or path.begins_with("/") or path.begins_with("\\"):
        errors.append(_error("MOD001", field_path, "Pack file path must be relative to the pack root."))
        return errors
    if lowered.contains("://") or lowered.begins_with("data:") or lowered.begins_with("file:") or lowered.begins_with("res:") or lowered.begins_with("user:"):
        errors.append(_error("MOD001", field_path, "Remote, URI, res://, and user:// references are forbidden in authored pack file paths."))
        return errors
    if path.contains("\\"):
        errors.append(_error("MOD001", field_path, "Backslash-separated paths are not accepted; use safe relative forward-slash paths."))
        return errors
    var segments: PackedStringArray = path.split("/", false)
    for segment: String in segments:
        if segment == ".." or segment == ".":
            errors.append(_error("MOD001", field_path, "Path traversal segments are forbidden."))
            return errors
    for extension: String in EXECUTABLE_EXTENSIONS:
        if lowered.ends_with(extension):
            errors.append(_error("MOD002", field_path, "Executable or engine-resource content references are forbidden by the data-only policy."))
            return errors
    if not lowered.ends_with(".json"):
        errors.append(_error("MOD001", field_path, "Phase B pack content files must be JSON data files."))
    return errors

func _error(code: String, path: String, message: String) -> Dictionary:
    return {"code": code, "path": path, "message": message}
