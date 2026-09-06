extends RefCounted

var _sequence: int = 0

func info(category: String, code: String, message: String, details: Dictionary = {}) -> Dictionary:
    return _emit("INFO", category, code, message, details)

func warning(category: String, code: String, message: String, details: Dictionary = {}) -> Dictionary:
    return _emit("WARNING", category, code, message, details)

func error(category: String, code: String, message: String, details: Dictionary = {}) -> Dictionary:
    return _emit("ERROR", category, code, message, details)

func _emit(level: String, category: String, code: String, message: String, details: Dictionary) -> Dictionary:
    _sequence += 1
    var record: Dictionary = {
        "schema": "we.diagnostic.v1",
        "sequence": _sequence,
        "level": level,
        "category": category,
        "code": code,
        "message": message,
        "details": details.duplicate(true),
    }
    print("WE_DIAG " + JSON.stringify(record))
    return record
