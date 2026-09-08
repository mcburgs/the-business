extends SceneTree

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const ContractSystem = preload("res://domain/people/contract_system.gd")

func _init() -> void:
    var state: RefCounted = Fixture.make_state(424242)
    var bookers_before: Dictionary = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    var before: String = str(bookers_before.get(Fixture.PROMOTION_A, ""))
    var expiry: Dictionary = ContractSystem.new().call("resolve_expiry", state, "2002-10-01")
    var bookers_after: Dictionary = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    var after: String = str(bookers_after.get(Fixture.PROMOTION_A, ""))
    var reproduced: bool = bool(expiry.get("passed", false)) and before == "person:PER00004" and after == before
    print("WE_F2G_REPRO " + JSON.stringify({"finding_id":"F2G-003","baseline_expected_vulnerable":true,"expiry_passed":expiry.get("passed"),"booker_before":before,"booker_after":after,"reproduced":reproduced}))
    quit(0 if reproduced else 1)
