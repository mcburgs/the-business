extends RefCounted

const ChronicleStore = preload("res://domain/chronicle/chronicle_store.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")

const FIELDS: Array[String] = [
    "schema_version", "head_date", "head_sequence", "checkpoint_generation", "checkpoint_cadence_months",
    "event_journal", "metric_definitions", "metric_series", "checkpoints", "deltas", "chronicle_index",
    "artifact_index", "identity_catalog"
]

func encode(store: RefCounted) -> Dictionary:
    return {
        "schema_version": int(store.get("schema_version")),
        "head_date": str(store.get("head_date")),
        "head_sequence": int(store.get("head_sequence")),
        "checkpoint_generation": int(store.get("checkpoint_generation")),
        "checkpoint_cadence_months": int(store.get("checkpoint_cadence_months")),
        "event_journal": (store.get("event_journal") as Array).duplicate(true),
        "metric_definitions": (store.get("metric_definitions") as Array).duplicate(true),
        "metric_series": (store.get("metric_series") as Dictionary).duplicate(true),
        "checkpoints": (store.get("checkpoints") as Array).duplicate(true),
        "deltas": (store.get("deltas") as Array).duplicate(true),
        "chronicle_index": (store.get("chronicle_index") as Dictionary).duplicate(true),
        "artifact_index": (store.get("artifact_index") as Dictionary).duplicate(true),
        "identity_catalog": (store.get("identity_catalog") as Dictionary).duplicate(true),
    }

func decode(data: Dictionary) -> Dictionary:
    var errors: Array[Dictionary] = []
    for field: String in FIELDS:
        if not data.has(field): _add(errors, "CHR001", field, {"reason": "required"})
    for key: Variant in data.keys():
        if not str(key) in FIELDS: _add(errors, "CHR001", str(key), {"reason": "unknown_field"})
    if not errors.is_empty(): return {"passed": false, "chronicle": null, "errors": errors}
    if int(data.get("schema_version", -1)) != ChronicleStore.SCHEMA_VERSION:
        _add(errors, "CHR001", "schema_version", {"supported": ChronicleStore.SCHEMA_VERSION, "actual": data.get("schema_version")})
        return {"passed": false, "chronicle": null, "errors": errors}
    var store: RefCounted = ChronicleStore.new()
    store.set("schema_version", int(data["schema_version"]))
    store.set("head_date", str(data["head_date"]))
    store.set("head_sequence", int(data["head_sequence"]))
    store.set("checkpoint_generation", int(data["checkpoint_generation"]))
    store.set("checkpoint_cadence_months", int(data["checkpoint_cadence_months"]))
    for field: String in ["event_journal", "metric_definitions", "checkpoints", "deltas"]:
        if not data[field] is Array:
            _add(errors, "CHR001", field, {"reason": "array_required"})
        else:
            var typed_records: Array[Dictionary] = []
            for index: int in range((data[field] as Array).size()):
                var record_value: Variant = (data[field] as Array)[index]
                if not record_value is Dictionary:
                    _add(errors, "CHR001", field + "[" + str(index) + "]", {"reason": "object_required"})
                else:
                    typed_records.append((record_value as Dictionary).duplicate(true))
            store.set(field, typed_records)
    for field: String in ["metric_series", "chronicle_index", "artifact_index", "identity_catalog"]:
        if not data[field] is Dictionary:
            _add(errors, "CHR001", field, {"reason": "object_required"})
        else:
            store.set(field, (data[field] as Dictionary).duplicate(true))
    if not errors.is_empty(): return {"passed": false, "chronicle": null, "errors": errors}
    var validation: Dictionary = ChronicleValidator.new().validate(store)
    if not bool(validation["passed"]): return {"passed": false, "chronicle": null, "errors": validation["errors"]}
    return {"passed": true, "chronicle": store, "errors": []}

func _add(errors: Array[Dictionary], code: String, path: String, details: Dictionary) -> void:
    errors.append({"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)})
