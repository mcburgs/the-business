extends RefCounted

static func success(command_id: String, details: Dictionary = {}) -> Dictionary:
    return {
        "accepted": true,
        "command_id": command_id,
        "errors": [],
        "details": details.duplicate(true),
    }

static func rejection(command_id: String, code: String, path: String, localization_key: String, details: Dictionary = {}) -> Dictionary:
    return {
        "accepted": false,
        "command_id": command_id,
        "errors": [{
            "code": code,
            "path": path,
            "localization_key": localization_key,
            "details": details.duplicate(true),
        }],
        "details": {},
    }
