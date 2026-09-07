extends RefCounted

const Fixture = preload("res://tests/helpers/phase_c_fixture.gd")
const KnowledgeQueryService = preload("res://app/queries/knowledge_query_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = Fixture.make_state()
    var knowledge: RefCounted = (state.get("knowledge_bases") as Dictionary)["promotion:PRO00001"]
    var query: RefCounted = KnowledgeQueryService.new()

    var estimated: RefCounted = query.call("project_field", knowledge, "person:PER00002", "skill.performance")
    var estimated_dict: Dictionary = estimated.call("to_dict")
    _expect(str(estimated_dict.get("status", "")) == "estimated", "Ranged observation should project as estimated.", failures)
    _expect(estimated_dict.get("estimate_range") is Dictionary, "Estimated projection should carry its range.", failures)
    _expect(not estimated_dict.has("true_value"), "KnowledgeProjection must have no true_value escape hatch.", failures)
    (estimated_dict.get("estimate_range") as Dictionary)["min"] = 0.0
    var source_observation: Dictionary = ((knowledge.get("observations") as Array)[0] as Dictionary)
    _expect(float((source_observation.get("range") as Dictionary).get("min")) == 0.55, "Projection data must be a detached snapshot, not a mutation handle into authoritative knowledge.", failures)

    var hidden: RefCounted = query.call("project_field", knowledge, "person:PER00002", "injury_risk")
    var hidden_dict: Dictionary = hidden.call("to_dict")
    _expect(str(hidden_dict.get("status", "")) == "unknown", "Unobserved hidden truth must project as unknown.", failures)
    _expect(hidden_dict.get("value") == null, "Unknown projection must not leak hidden authoritative value.", failures)

    var authoritative_person: RefCounted = (state.get("people") as Dictionary)["person:PER00002"]
    _expect((authoritative_person.get("health") as Dictionary).has("injury_risk"), "Fixture must contain hidden authoritative truth so the withholding test is meaningful.", failures)

    return {"name": "phase_c_knowledge_projection", "passed": failures.is_empty(), "failures": failures}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
