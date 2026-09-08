extends RefCounted
const CampaignSession = preload("res://app/session/campaign_session.gd")
func run() -> Dictionary:
    var failures: Array[String] = []; var session: RefCounted = CampaignSession.new(); var started: Dictionary = session.start("res://content/campaigns/great_lakes_1975", 424242)
    _expect(bool(started.get("passed", false)), "Phase G owner projection fixture must start.", failures)
    if not bool(started.get("passed", false)): return {"name": "phase_g_owner_projection", "passed": false, "failures": failures}
    var before: Dictionary = session.state_snapshot(); var projection: Dictionary = session.current_projection(); _expect(bool(projection.get("passed", false)), "Owner presentation projection must succeed.", failures); _expect(session.state_snapshot() == before, "Reading the Phase G projection must not mutate authoritative CampaignState.", failures); _expect(not JSON.stringify(projection).contains("true_value"), "Presentation projection must provide no hidden-truth escape hatch.", failures); _expect(not (projection.get("ownership", {}) as Dictionary).has("person_id") and not (projection.get("ownership", {}) as Dictionary).has("owner_person_id"), "Presentation ownership context must derive from OwnershipSeatState without a player Person.", failures); _expect((projection.get("markets", []) as Array).size() > 0, "Map projection must include campaign markets.", failures)
    var saw := false
    for market: Dictionary in projection.get("markets", []):
        _expect(not market.has("influence_by_promotion"), "Market presentation must not leak the raw authoritative influence dictionary.", failures)
        for rival: Dictionary in market.get("rival_presence", []):
            if str(rival.get("status", "")) == "estimated": saw = true
            _expect(not rival.has("value"), "Rival market presentation must not expose exact truth when knowledge is estimated.", failures)
    _expect(saw, "At least one rival market signal should visibly remain an estimate through KnowledgeProjection.", failures)
    return {"name": "phase_g_owner_projection", "passed": failures.is_empty(), "failures": failures}
func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
