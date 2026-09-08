extends RefCounted

const ContentLoader = preload("res://app/content/content_loader.gd")
const CampaignRuntimeFactory = preload("res://app/session/campaign_runtime_factory.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var search_roots: Array[String] = ["res://content/base", "res://content/campaigns"]
    var loaded: Dictionary = ContentLoader.new().load_campaign("res://content/campaigns/great_lakes_1975", search_roots)
    _expect(bool(loaded.get("passed", false)), "Phase G runtime bootstrap must load the governed campaign content.", failures)
    if not bool(loaded.get("passed", false)): return {"name": "phase_g_runtime_bootstrap", "passed": false, "failures": failures}
    var built: Dictionary = CampaignRuntimeFactory.new().build(loaded.get("registry"), 424242)
    _expect(bool(built.get("passed", false)), "Phase G runtime factory must materialize a valid authoritative campaign: %s" % JSON.stringify(built.get("errors", [])), failures)
    if not bool(built.get("passed", false)): return {"name": "phase_g_runtime_bootstrap", "passed": false, "failures": failures}
    var state: RefCounted = built.get("state"); var seat: Dictionary = (state.get("ownership_seat") as RefCounted).to_dict()
    _expect(seat.has("promotion_id") and not seat.has("owner_person_id") and not seat.has("person_id"), "Phase G runtime must retain the non-person Ownership Seat.", failures)
    _expect((state.get("markets") as Dictionary).size() == (loaded.get("registry") as RefCounted).count("markets"), "Strategic map runtime markets must come from campaign content.", failures)
    _expect((state.get("promotions") as Dictionary).size() == (loaded.get("registry") as RefCounted).count("promotions"), "Promotion runtime count must come from campaign content.", failures)
    var validation: Dictionary = CampaignStateValidator.new().validate(state, built.get("content_index", {})); _expect(bool(validation.get("passed", false)), "Materialized Phase G state must satisfy the canonical CampaignState validator.", failures)
    var chronicle: RefCounted = built.get("chronicle"); _expect((chronicle.get("checkpoints") as Array).size() == 1, "Phase G runtime bootstrap must seed Chronicle with an opening checkpoint rather than re-simulating history.", failures)
    return {"name": "phase_g_runtime_bootstrap", "passed": failures.is_empty(), "failures": failures}
func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
