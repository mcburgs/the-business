extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")

# Phase C never erases runtime identities from authoritative stores. If later
# compaction becomes legal, historical_ids is supplied by the Chronicle identity
# catalog so an old ID can still never be reused.
static func add_runtime(store: Dictionary, entity: RefCounted, expected_family: String, historical_ids: Dictionary = {}) -> Dictionary:
    var canonical_id: String = str(entity.get("id"))
    if not DomainIds.is_runtime_id(canonical_id, expected_family):
        return _error("ID001", "entity.id", {"id": canonical_id, "expected_family": expected_family})
    if store.has(canonical_id) or historical_ids.has(canonical_id):
        return _error("ID002", expected_family + "s[" + canonical_id + "]", {"id": canonical_id})
    store[canonical_id] = entity
    return {"passed": true, "errors": []}

static func add_definition_backed(store: Dictionary, entity: RefCounted, id_property: String, family_label: String) -> Dictionary:
    var canonical_id: String = str(entity.get(id_property))
    if not DomainIds.is_content_id(canonical_id):
        return _error("ID001", family_label + "." + id_property, {"id": canonical_id})
    if store.has(canonical_id):
        return _error("ID002", family_label + "[" + canonical_id + "]", {"id": canonical_id})
    store[canonical_id] = entity
    return {"passed": true, "errors": []}

# Chronicle itself remains Phase D. This compatibility seam lets later Chronicle
# integrity validation resolve an ID against active state or a tombstone catalog
# without redirecting or recycling the old identity.
static func validate_historical_reference(runtime_id: String, active_stores: Array[Dictionary], tombstone_ids: Dictionary = {}) -> Dictionary:
    if not DomainIds.is_runtime_id(runtime_id):
        return _error("ID001", "historical_reference", {"id": runtime_id})
    for store: Dictionary in active_stores:
        if store.has(runtime_id):
            return {"passed": true, "errors": []}
    if tombstone_ids.has(runtime_id):
        return {"passed": true, "errors": []}
    return _error("CHR002", "historical_reference", {"id": runtime_id})

static func sorted_ids(store: Dictionary) -> Array[String]:
    return DomainIds.sorted_keys(store)

static func _error(code: String, path: String, details: Dictionary) -> Dictionary:
    return {
        "passed": false,
        "errors": [{
            "code": code,
            "path": path,
            "localization_key": "validation." + code.to_lower(),
            "details": details.duplicate(true),
        }],
    }
