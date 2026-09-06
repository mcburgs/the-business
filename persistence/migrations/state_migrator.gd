extends RefCounted

const CURRENT_STATE_SCHEMA_VERSION: int = 1

func migrate_to_current(input: Dictionary) -> Dictionary:
    if not input.has("state_schema_version"):
        return _failure("STATE001", "state_schema_version", {"reason": "required_field_missing"})
    var source_version: int = int(input["state_schema_version"])
    if source_version == CURRENT_STATE_SCHEMA_VERSION:
        return {"passed": true, "data": input.duplicate(true), "errors": [], "migrations_applied": []}
    if source_version > CURRENT_STATE_SCHEMA_VERSION:
        return _failure("STATE001", "state_schema_version", {"reason": "future_schema_not_supported", "actual": source_version, "supported": CURRENT_STATE_SCHEMA_VERSION})
    return _failure("STATE001", "state_schema_version", {"reason": "migration_not_available", "actual": source_version, "target": CURRENT_STATE_SCHEMA_VERSION})

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {
        "passed": false,
        "data": {},
        "migrations_applied": [],
        "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}],
    }
