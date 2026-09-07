extends RefCounted

const EntityStore = preload("res://domain/core/entity_store.gd")
const PersonState = preload("res://domain/people/person_state.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var store: Dictionary = {}
    var person: RefCounted = PersonState.new()
    person.set("id", "person:PER00077")

    var added: Dictionary = EntityStore.add_runtime(store, person, "person")
    _expect(bool(added.get("passed", false)), "Valid runtime entity should enter its authoritative ID-keyed store.", failures)
    _expect(EntityStore.sorted_ids(store) == ["person:PER00077"], "Store iteration helper must return canonical sorted IDs.", failures)

    var duplicate: RefCounted = PersonState.new()
    duplicate.set("id", "person:PER00077")
    _expect(_has_code(EntityStore.add_runtime(store, duplicate, "person"), "ID002"), "A runtime ID must never be reused while active/retained.", failures)

    # Phase C exposes no deletion/retirement mutator outside the command boundary.
    # A loaded/constructed retired record remains keyed by the same identity.
    (store["person:PER00077"] as RefCounted).set("lifecycle", "retired")
    _expect(store.has("person:PER00077"), "Retired Phase C identity must remain in the hot store until Chronicle compaction exists.", failures)
    _expect(_has_code(EntityStore.add_runtime(store, duplicate, "person"), "ID002"), "Retired retained IDs must remain unavailable for reuse.", failures)

    var historical_only: Dictionary = {"person:OLD00001": true}
    var resurrected: RefCounted = PersonState.new()
    resurrected.set("id", "person:OLD00001")
    _expect(_has_code(EntityStore.add_runtime({}, resurrected, "person", historical_only), "ID002"), "A future tombstone/identity catalog must prevent reuse after compaction.", failures)
    _expect(bool(EntityStore.validate_historical_reference("person:OLD00001", [], historical_only).get("passed", false)), "Historical IDs may resolve through the future tombstone seam.", failures)
    _expect(_has_code(EntityStore.validate_historical_reference("person:MISSING", [store], historical_only), "CHR002"), "Unresolved historical references must emit CHR002.", failures)

    return {"name": "phase_c_entity_store", "passed": failures.is_empty(), "failures": failures}

func _has_code(result: Dictionary, code: String) -> bool:
    for error_value: Variant in result.get("errors", []):
        if error_value is Dictionary and str((error_value as Dictionary).get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
