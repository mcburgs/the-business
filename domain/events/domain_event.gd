extends RefCounted

const VALID_NARRATIVE_CONTEXTS: Array[String] = ["public_kayfabe", "backstage_business", "system_neutral"]

static func make(event_type: String, occurred_on: String, entity_ids: Array = [], facts: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
    var event: Dictionary = {
        "event_id": null,
        "sequence_id": null,
        "event_type": event_type,
        "occurred_on": occurred_on,
        "entity_ids": entity_ids.duplicate(),
        "market_id": options.get("market_id"),
        "severity": str(options.get("severity", "routine")),
        "category": str(options.get("category", "simulation")),
        "historical_class": str(options.get("historical_class", "state_change")),
        "facts": _canonical_copy(facts),
        "explanation": _canonical_copy(options.get("explanation", [])),
        "caused_by_event_ids": (options.get("caused_by_event_ids", []) as Array).duplicate(),
        "narrative_key": options.get("narrative_key"),
        "narrative_context": options.get("narrative_context"),
    }
    return event

static func _canonical_copy(value: Variant) -> Variant:
    if value is float:
        if not is_finite(float(value)):
            return 0.0
        return round(float(value) * 1000000000.0) / 1000000000.0
    if value is Dictionary:
        var output: Dictionary = {}
        for key: Variant in (value as Dictionary).keys():
            output[key] = _canonical_copy((value as Dictionary)[key])
        return output
    if value is Array:
        var output: Array = []
        for item: Variant in value:
            output.append(_canonical_copy(item))
        return output
    return value
