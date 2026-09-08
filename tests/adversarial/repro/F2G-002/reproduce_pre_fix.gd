extends SceneTree

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")

func _init() -> void:
    var state: RefCounted = Fixture.make_state(424242)
    var c: RefCounted = _command(state, "command.sign_media_deal", {
        "media_deal_id":"media_deal:F2G002REPRO", "promotion_id":Fixture.PROMOTION_A,
        "medium_id":"media_medium.fabricated", "outlet_id":"media_outlet.fabricated",
        "reach_market_ids":[Fixture.MARKET_A], "schedule_id":"schedule.fabricated",
        "cost":{"minor_units":0,"currency_id":"currency.fixture"},
        "revenue":{"minor_units":1000000000,"currency_id":"currency.fixture"},
    })
    var result: Dictionary = CommandRouter.new().call("apply", state, c)
    var deal_exists: bool = (state.get("media_deals") as Dictionary).has("media_deal:F2G002REPRO")
    var reproduced: bool = bool(result.get("accepted", false)) and deal_exists
    print("WE_F2G_REPRO " + JSON.stringify({"finding_id":"F2G-002","baseline_expected_vulnerable":true,"accepted":result.get("accepted"),"deal_exists":deal_exists,"reproduced":reproduced,"result":result}))
    quit(0 if reproduced else 1)

func _command(state: RefCounted, type: String, payload: Dictionary) -> RefCounted:
    var c: RefCounted = CommandEnvelope.new()
    c.set("command_id", "command:F2G002REPRO")
    c.set("command_type", type)
    c.set("issued_for_turn", state.get("turn_number")); c.set("issued_on", state.get("current_date"))
    c.set("issuer", {"kind":"player","promotion_id":Fixture.PROMOTION_A})
    c.set("turn_phase_ordinal", 3); c.set("priority", 10); c.set("issuer_key", "player." + Fixture.PROMOTION_A)
    c.set("payload", payload.duplicate(true))
    return c
