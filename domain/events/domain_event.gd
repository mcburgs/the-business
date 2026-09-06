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
        "facts": facts.duplicate(true),
        "explanation": (options.get("explanation", []) as Array).duplicate(true),
        "caused_by_event_ids": (options.get("caused_by_event_ids", []) as Array).duplicate(),
        "narrative_key": options.get("narrative_key"),
        "narrative_context": options.get("narrative_context"),
    }
    return event
