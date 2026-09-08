extends RefCounted
const CampaignSession = preload("res://app/session/campaign_session.gd")
func run() -> Dictionary:
    var failures: Array[String] = []; var scene: PackedScene = load("res://presentation/shell/game_root.tscn"); _expect(scene != null, "Phase G main presentation scene must load under stock Godot.", failures)
    if scene != null:
        var instance: Node = scene.instantiate(); _expect(instance != null and instance.has_node("PresentationRoot/StrategicHome"), "Phase G main scene must instantiate with the map-first StrategicHome surface.", failures); if instance != null: instance.free()
    var session: RefCounted = CampaignSession.new(); var started: Dictionary = session.start("res://content/campaigns/great_lakes_1975", 424242); _expect(bool(started.get("passed", false)), "Phase G history fixture must start.", failures)
    if bool(started.get("passed", false)):
        var state_before: Dictionary = session.state_snapshot(); var chronicle_before: Dictionary = session.chronicle_snapshot(); var dates: Array = session.current_projection().get("history_dates", []); _expect(not dates.is_empty(), "Opening Chronicle checkpoint must be available for historical inspection.", failures)
        if not dates.is_empty():
            var historical: Dictionary = session.historical_projection(str(dates[0])); _expect(bool(historical.get("passed", false)), "Historical inspection must reconstruct a governed projection without simulation.", failures); _expect(not JSON.stringify(historical).contains("influence_by_promotion"), "Historical presentation must scope raw rival truth out of the Owner view.", failures)
        _expect(session.state_snapshot() == state_before, "Chronicle/historical inspection must not mutate current CampaignState.", failures); _expect(session.chronicle_snapshot() == chronicle_before, "Chronicle/historical inspection must not mutate Chronicle storage.", failures)
    return {"name": "phase_g_presentation_scene_and_history", "passed": failures.is_empty(), "failures": failures}
func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
