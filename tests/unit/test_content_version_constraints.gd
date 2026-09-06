extends RefCounted

const VersionConstraint = preload("res://app/content/version_constraint.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var versions: Variant = VersionConstraint.new()
    var parsed: Dictionary = versions.parse_dependency("wrestling_empire.base>=0.1.0")
    _expect(str(parsed.get("pack_id", "")) == "wrestling_empire.base", "Dependency parser lost pack identity.", failures)
    _expect(str(parsed.get("operator", "")) == ">=", "Dependency parser lost comparison operator.", failures)
    _expect(str(parsed.get("version", "")) == "0.1.0", "Dependency parser lost semantic version.", failures)
    _expect(versions.satisfies("0.1.0", ">=", "0.1.0"), "Equal version should satisfy >=.", failures)
    _expect(versions.satisfies("0.2.0", ">", "0.1.9"), "Newer version should satisfy >.", failures)
    _expect(not versions.satisfies("0.0.9", ">=", "0.1.0"), "Older version must not satisfy minimum dependency.", failures)
    return {"name": "content_version_constraints", "passed": failures.is_empty(), "failures": failures}

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
