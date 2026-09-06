extends RefCounted

const Fixture = preload("res://tests/helpers/phase_c_fixture.gd")
const Validator = preload("res://domain/core/campaign_state_validator.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var validator: RefCounted = Validator.new()

    var valid_state: RefCounted = Fixture.make_state()
    var valid: Dictionary = validator.call("validate", valid_state, Fixture.content_index())
    _expect(bool(valid.get("passed", false)), "Synthetic Phase C state should validate: %s" % JSON.stringify(valid.get("errors", [])), failures)

    var bad_range: RefCounted = Fixture.make_state()
    ((bad_range.get("promotions") as Dictionary)["promotion:PRO00001"] as RefCounted).set("prestige", 1.5)
    _expect(_has_code(validator.call("validate", bad_range, Fixture.content_index()), "STATE001"), "Out-of-range normalized state must emit STATE001.", failures)

    var bad_key: RefCounted = Fixture.make_state()
    var people: Dictionary = bad_key.get("people")
    var person: RefCounted = people["person:PER00001"]
    people.erase("person:PER00001")
    people["person:WRONG"] = person
    _expect(_has_code(validator.call("validate", bad_key, Fixture.content_index()), "REF002"), "Collection key/canonical ID mismatch must emit REF002.", failures)

    var orphan: RefCounted = Fixture.make_state()
    ((orphan.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).set("person_id", "person:MISSING")
    _expect(_has_code(validator.call("validate", orphan, Fixture.content_index()), "REF001"), "Orphan required reference must emit REF001.", failures)

    var wrong_family: RefCounted = Fixture.make_state()
    ((wrong_family.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).set("person_id", "promotion:PRO00001")
    _expect(_has_code(validator.call("validate", wrong_family, Fixture.content_index()), "REF003"), "Wrong reference family must emit REF003.", failures)

    var duplicate_assignment: RefCounted = Fixture.make_state()
    ((duplicate_assignment.get("championships") as Dictionary)["championship:CHA00001"] as RefCounted).set("holder_person_ids", ["person:PER00001", "person:PER00001"])
    _expect(_has_code(validator.call("validate", duplicate_assignment, Fixture.content_index()), "STATE002"), "Duplicate assignment must emit STATE002.", failures)

    var incompatible_index: RefCounted = Fixture.make_state()
    ((incompatible_index.get("people") as Dictionary)["person:PER00001"] as RefCounted).set("active_contract_ids", ["contract:CON00002"])
    _expect(_has_code(validator.call("validate", incompatible_index, Fixture.content_index()), "STATE003"), "Cross-owner contract indexes must emit STATE003.", failures)

    var nested_range: RefCounted = Fixture.make_state()
    ((nested_range.get("people") as Dictionary)["person:PER00001"] as RefCounted).set("skills", {"skill.performance": 1.2})
    _expect(_has_code(validator.call("validate", nested_range, Fixture.content_index()), "STATE001"), "Nested canonical normalized values must be range validated.", failures)

    var bad_rng_checkpoint: RefCounted = Fixture.make_state()
    (bad_rng_checkpoint.get("rng_state") as RefCounted).set("captured_turn", 99)
    _expect(_has_code(validator.call("validate", bad_rng_checkpoint, Fixture.content_index()), "STATE001"), "RNG checkpoint turn cannot be ahead of authoritative state.", failures)

    var non_serializable: RefCounted = Fixture.make_state()
    (non_serializable.get("world_state") as Dictionary)["bad_value"] = Callable(self, "run")
    _expect(_has_code(validator.call("validate", non_serializable, Fixture.content_index()), "STATE001"), "Authoritative nested state must reject non-serializable object/callable values.", failures)

    return {"name": "phase_c_state_invariants", "passed": failures.is_empty(), "failures": failures}

func _has_code(result: Dictionary, code: String) -> bool:
    for error_value: Variant in result.get("errors", []):
        if error_value is Dictionary and str((error_value as Dictionary).get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
