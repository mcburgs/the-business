extends RefCounted

const ContentSafety = preload("res://app/content/content_safety.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var safety: Variant = ContentSafety.new()
    _expect(safety.validate_pack_file_path("markets.json", "test").is_empty(), "A normal relative JSON content path should pass.", failures)
    _expect(_has_code(safety.validate_pack_file_path("../markets.json", "test"), "MOD001"), "Traversal must fail with MOD001.", failures)
    _expect(_has_code(safety.validate_pack_file_path("https://example.invalid/markets.json", "test"), "MOD001"), "Remote URL must fail with MOD001.", failures)
    _expect(_has_code(safety.validate_pack_file_path("payload.gd", "test"), "MOD002"), "Executable GDScript reference must fail with MOD002.", failures)
    _expect(_has_code(safety.validate_pack_file_path("payload.tscn", "test"), "MOD002"), "Engine scene resource reference must fail with MOD002.", failures)
    return {"name": "content_safety", "passed": failures.is_empty(), "failures": failures}

func _has_code(errors: Array[Dictionary], code: String) -> bool:
    for error: Dictionary in errors:
        if str(error.get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
