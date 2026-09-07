extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ContractSystem = preload("res://domain/people/contract_system.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = Fixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var codec: RefCounted = Codec.new()
    var validator: RefCounted = CampaignStateValidator.new()
    _expect(bool(validator.call("validate", state, Fixture.content_index()).get("passed", false)), "Phase F fixture must begin valid.", failures)

    var ledger_before: Dictionary = (state.get("world_state") as Dictionary).get("ledger_v1", {}).duplicate(true)
    var first: Dictionary = router.call("apply", state, _command(state, "command:FCON00001", "command.offer_contract", Fixture.PROMOTION_A, {
        "contract_id": "contract:FCON00001", "promotion_id": Fixture.PROMOTION_A, "person_id": Fixture.UNSIGNED_PROSPECT,
        "compensation": {"base": {"minor_units": 8000, "currency_id": "currency.fixture"}}, "exclusivity_id": "exclusivity.fixture", "end_date": "2003-01-01",
    }))
    _expect(bool(first.get("accepted", false)) and str(first.get("details", {}).get("outcome")) == "countered", "A credible low offer should produce a counteroffer through CommandRouter.", failures)
    var counter_minor: int = int(first.get("details", {}).get("counter_minor_units", 0))
    var second: Dictionary = router.call("apply", state, _command(state, "command:FCON00002", "command.counter_offer", Fixture.PROMOTION_A, {
        "contract_id": "contract:FCON00001", "promotion_id": Fixture.PROMOTION_A,
        "compensation": {"base": {"minor_units": counter_minor, "currency_id": "currency.fixture"}}, "end_date": "2003-01-01",
    }))
    _expect(str(second.get("details", {}).get("outcome")) == "accepted", "Meeting a counteroffer must activate the contract.", failures)
    _expect("contract:FCON00001" in ((state.get("people") as Dictionary)[Fixture.UNSIGNED_PROSPECT] as RefCounted).get("active_contract_ids"), "Accepted contract must update the person active index.", failures)
    _expect("contract:FCON00001" in ((state.get("promotions") as Dictionary)[Fixture.PROMOTION_A] as RefCounted).get("contract_ids"), "Accepted contract must update the promotion active index.", failures)

    var released: Dictionary = router.call("apply", state, _command(state, "command:FCON00003", "command.release_person", Fixture.PROMOTION_A, {"contract_id": "contract:FCON00001", "promotion_id": Fixture.PROMOTION_A}))
    _expect(str(released.get("details", {}).get("outcome")) == "released", "Release command should deactivate an active scoped contract.", failures)
    _expect(str(((state.get("contracts") as Dictionary)["contract:FCON00001"] as RefCounted).get("status")) == "released", "Released contract must retain historical identity with inactive status.", failures)

    var renewal: Dictionary = router.call("apply", state, _command(state, "command:FCON00004", "command.renew_contract", Fixture.PROMOTION_A, {"contract_id": "contract:CON00001", "promotion_id": Fixture.PROMOTION_A, "compensation": {"base": {"minor_units": 14000, "currency_id": "currency.fixture"}}, "end_date": "2003-06-01"}))
    _expect(str(renewal.get("details", {}).get("outcome")) == "countered", "Near-expiry renewal should support a counter path.", failures)
    var renewal_counter: int = int(renewal.get("details", {}).get("counter_minor_units", 0))
    var renewed: Dictionary = router.call("apply", state, _command(state, "command:FCON00005", "command.counter_offer", Fixture.PROMOTION_A, {"contract_id": "contract:CON00001", "promotion_id": Fixture.PROMOTION_A, "compensation": {"base": {"minor_units": renewal_counter, "currency_id": "currency.fixture"}}, "end_date": "2003-06-01"}))
    _expect(str(renewed.get("details", {}).get("outcome")) == "accepted" and str(((state.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).get("end_date")) == "2003-06-01", "Renewal counter acceptance must replace terms deterministically.", failures)

    var before_rejection: Dictionary = codec.call("encode", state)
    var rejected: Dictionary = router.call("apply", state, _command(state, "command:FCON00006", "command.offer_contract", Fixture.PROMOTION_A, {"contract_id": "contract:FCON00002", "promotion_id": "promotion:MISSING", "person_id": Fixture.UNSIGNED_STAR, "compensation": {"base": {"minor_units": 20000, "currency_id": "currency.fixture"}}, "exclusivity_id": "exclusivity.fixture", "end_date": "2003-01-01"}))
    _expect(not bool(rejected.get("accepted", true)) and before_rejection == codec.call("encode", state), "Rejected contract commands must be atomic and leave no pending-negotiation residue.", failures)
    _expect(ledger_before == (state.get("world_state") as Dictionary).get("ledger_v1", {}), "Contract commands must not bypass the canonical ledger.", failures)
    _expect(bool(validator.call("validate", state, Fixture.content_index()).get("passed", false)), "Contract transitions must preserve state invariants.", failures)
    var expiry_state: RefCounted = Fixture.make_state()
    var expiry: Dictionary = ContractSystem.new().resolve_expiry(expiry_state, "2001-03-01")
    _expect((expiry.get("events", []) as Array).size() == 1 and str(((expiry_state.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).get("status")) == "expired", "Phase-10 expiry must deactivate an unrenewed contract and emit a historical event.", failures)
    var scoped_state: RefCounted = Fixture.make_state(); var scoped_before: Dictionary = codec.call("encode", scoped_state)
    var cross_scope: Dictionary = router.call("apply", scoped_state, _command(scoped_state, "command:FCON00007", "command.release_person", Fixture.PROMOTION_B, {"contract_id": "contract:CON00001", "promotion_id": Fixture.PROMOTION_A}))
    _expect(not bool(cross_scope.get("accepted", true)) and scoped_before == codec.call("encode", scoped_state), "A promotion must not mutate another promotion's contracts.", failures)
    return {"name": "phase_f_contracts", "passed": failures.is_empty(), "failures": failures}

func _command(state: RefCounted, id: String, type: String, promotion_id: String, payload: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new(); command.set("command_id", id); command.set("command_type", type); command.set("issued_for_turn", state.get("turn_number")); command.set("issued_on", state.get("current_date")); command.set("issuer", {"kind": "ai", "promotion_id": promotion_id}); command.set("turn_phase_ordinal", 3); command.set("priority", 10); command.set("issuer_key", "ai." + promotion_id); command.set("payload", payload.duplicate(true)); return command

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
