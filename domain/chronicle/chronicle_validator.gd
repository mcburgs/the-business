extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const IdentityCatalogService = preload("res://domain/chronicle/identity_catalog_service.gd")

var _identity: RefCounted = IdentityCatalogService.new()

func validate(store: RefCounted) -> Dictionary:
    var errors: Array[Dictionary] = []
    if int(store.get("schema_version")) != 1:
        _add(errors, "CHR001", "schema_version", {"actual": store.get("schema_version")})
    var expected_sequence: int = 1
    var previous_date: String = ""
    for index: int in range((store.get("event_journal") as Array).size()):
        var event: Dictionary = store.get("event_journal")[index]
        if not DomainIds.is_runtime_id(str(event.get("event_id", "")), "event") or int(event.get("sequence_id", -1)) != expected_sequence:
            _add(errors, "CHR001", "event_journal[" + str(index) + "]", {"expected_sequence": expected_sequence, "event_id": event.get("event_id"), "sequence_id": event.get("sequence_id")})
        var date: String = str(event.get("occurred_on", ""))
        if date.is_empty() or (not previous_date.is_empty() and date < previous_date):
            _add(errors, "CHR001", "event_journal[" + str(index) + "].occurred_on", {"previous": previous_date, "actual": date})
        previous_date = date
        for entity_id: Variant in event.get("entity_ids", []):
            if not _identity.call("resolve", store.get("identity_catalog"), str(entity_id)):
                _add(errors, "CHR002", "event_journal[" + str(index) + "].entity_ids", {"entity_id": entity_id})
        expected_sequence += 1
    if int(store.get("head_sequence")) != expected_sequence - 1:
        _add(errors, "CHR001", "head_sequence", {"expected": expected_sequence - 1, "actual": store.get("head_sequence")})
    _validate_ordered_records(store.get("checkpoints"), "checkpoints", errors)
    _validate_ordered_records(store.get("deltas"), "deltas", errors)
    for key: Variant in (store.get("metric_series") as Dictionary).keys():
        var prior: String = ""
        for sample_index: int in range((store.get("metric_series")[key] as Array).size()):
            var sample: Dictionary = store.get("metric_series")[key][sample_index]
            var date: String = str(sample.get("date", ""))
            var value: Variant = sample.get("value")
            if date.is_empty() or (not prior.is_empty() and date < prior) or not (value is float or value is int) or not is_finite(float(value)):
                _add(errors, "CHR001", "metric_series[" + str(key) + "][" + str(sample_index) + "]", {"date": date, "value": value})
            prior = date
    if not (store.get("checkpoints") as Array).is_empty() and str(store.get("head_date")).is_empty():
        _add(errors, "CHR001", "head_date", {"reason": "required_with_committed_history"})
    return {"passed": errors.is_empty(), "errors": errors}

func _validate_ordered_records(records: Array, path: String, errors: Array[Dictionary]) -> void:
    var prior: String = ""
    for index: int in range(records.size()):
        var date: String = str((records[index] as Dictionary).get("date", ""))
        if date.is_empty() or (not prior.is_empty() and date <= prior):
            _add(errors, "CHR001", path + "[" + str(index) + "].date", {"previous": prior, "actual": date})
        prior = date

func _add(errors: Array[Dictionary], code: String, path: String, details: Dictionary) -> void:
    errors.append({"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)})
