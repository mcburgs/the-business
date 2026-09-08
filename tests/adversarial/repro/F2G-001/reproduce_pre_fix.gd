extends SceneTree

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")

func _init() -> void:
    var state: RefCounted = Fixture.make_state(424242)
    var rival: RefCounted = (state.get("touring_companies") as Dictionary)["touring:TOU00002"]
    var before: int = int((rival.get("monthly_budget") as Dictionary).get("minor_units"))
    var c: RefCounted = _command(state, "command.adjust_budget", {"touring_company_id": "touring:TOU00002", "monthly_budget": {"minor_units": 1, "currency_id": "currency.fixture"}})
    var result: Dictionary = CommandRouter.new().call("apply", state, c)
    var after: int = int((rival.get("monthly_budget") as Dictionary).get("minor_units"))
    var reproduced: bool = bool(result.get("accepted", false)) and before != after and after == 1
    print("WE_F2G_REPRO " + JSON.stringify({"finding_id":"F2G-001","baseline_expected_vulnerable":true,"accepted":result.get("accepted"),"before":before,"after":after,"reproduced":reproduced,"result":result}))
    quit(0 if reproduced else 1)

func _command(state: RefCounted, type: String, payload: Dictionary) -> RefCounted:
    var c: RefCounted = CommandEnvelope.new()
    c.set("command_id", "command:F2G001REPRO")
    c.set("command_type", type)
    c.set("issued_for_turn", state.get("turn_number"))
    c.set("issued_on", state.get("current_date"))
    c.set("issuer", {"kind":"player","promotion_id":Fixture.PROMOTION_A})
    c.set("turn_phase_ordinal", 3); c.set("priority", 10); c.set("issuer_key", "player." + Fixture.PROMOTION_A)
    c.set("payload", payload.duplicate(true))
    return c
