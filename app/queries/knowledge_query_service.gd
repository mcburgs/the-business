extends RefCounted

const KnowledgeProjection = preload("res://domain/knowledge/knowledge_projection.gd")

func project_field(knowledge_base: RefCounted, subject_id: String, field_id: String) -> RefCounted:
    var best: Dictionary = {}
    var observations: Array = knowledge_base.get("observations")
    for observation_value: Variant in observations:
        if not observation_value is Dictionary:
            continue
        var observation: Dictionary = observation_value
        if str(observation.get("subject_id", "")) != subject_id or str(observation.get("field_id", "")) != field_id:
            continue
        if best.is_empty() or str(observation.get("observed_on", "")) > str(best.get("observed_on", "")):
            best = observation
    var projection: RefCounted = KnowledgeProjection.new()
    projection.set("subject_id", subject_id)
    projection.set("field_id", field_id)
    if best.is_empty():
        return projection
    var form: String = str(best.get("estimate_form", "unknown"))
    projection.set("confidence", best.get("confidence", null))
    projection.set("observed_on", best.get("observed_on", null))
    match form:
        "exact":
            projection.set("status", "known")
            projection.set("value", _copy_data(best.get("value", null)))
        "range":
            projection.set("status", "estimated")
            projection.set("estimate_range", _copy_data(best.get("range", null)))
        "qualitative":
            projection.set("status", "estimated")
            projection.set("qualitative", _copy_data(best.get("qualitative", null)))
        _:
            projection.set("status", "unknown")
    return projection

func _copy_data(value: Variant) -> Variant:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    if value is Array:
        return (value as Array).duplicate(true)
    return value
