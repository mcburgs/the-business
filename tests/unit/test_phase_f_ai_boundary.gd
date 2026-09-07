extends RefCounted

const PLANNER_PATHS: Array[String] = [
    "res://domain/ai/owner_strategy.gd", "res://domain/ai/talent_manager.gd", "res://domain/ai/touring_planner.gd",
    "res://domain/ai/booker_ai.gd", "res://domain/ai/recovery_ai.gd", "res://domain/ai/diplomacy_ai.gd",
]

func run() -> Dictionary:
    var failures: Array[String] = []
    for path: String in PLANNER_PATHS:
        var file: FileAccess = FileAccess.open(path, FileAccess.READ)
        if file == null: failures.append("Could not inspect AI planner: " + path); continue
        var source: String = file.get_as_text(); file.close()
        if source.contains("CampaignState") or source.contains('state.get("people")') or source.contains('state.get("contracts")') or source.contains('state.get("rng_state")'): failures.append("AI planner bypasses sanitized planning view: " + path)
        if source.contains("ShowPlan") or source.contains("ShowResult") or source.contains("BookingSystem"): failures.append("Booker/planner crossed into card generation or show resolution: " + path)
    var view_file: FileAccess = FileAccess.open("res://domain/ai/ai_planning_view.gd", FileAccess.READ); var view_source: String = view_file.get_as_text(); view_file.close()
    if not view_source.contains("KnowledgeQueryService") or not view_source.contains('"external_talent"'): failures.append("AI planning view must explicitly construct external talent from knowledge projections.")
    return {"name": "phase_f_ai_boundary", "passed": failures.is_empty(), "failures": failures, "planners_checked": PLANNER_PATHS.size()}
