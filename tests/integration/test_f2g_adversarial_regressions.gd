extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ContractSystem = preload("res://domain/people/contract_system.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    _test_player_cannot_mutate_rival_resources(failures)
    _test_player_cannot_mint_media_terms(failures)
    _test_booker_requires_live_employment_and_clears_on_expiry(failures)
    _test_unavailable_people_cannot_be_assigned_or_booked(failures)
    return {"name": "f2g_adversarial_regressions", "passed": failures.is_empty(), "failures": failures}

func _test_player_cannot_mutate_rival_resources(failures: Array[String]) -> void:
    var state: RefCounted = Fixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var codec: RefCounted = Codec.new()
    var before: Dictionary = codec.call("encode", state)
    var result: Dictionary = router.call("apply", state, _command(state, "command:F2G00001", "command.adjust_budget", {
        "touring_company_id": "touring:TOU00002",
        "monthly_budget": {"minor_units": 1, "currency_id": "currency.fixture"},
    }))
    _expect(not bool(result.get("accepted", true)), "F2G-001: player must not mutate a rival touring budget.", failures)
    _expect(before == codec.call("encode", state), "F2G-001: rejected rival-resource mutation must be atomic.", failures)

    var rival_title_before: Array = (((state.get("championships") as Dictionary)["championship:CHA00002"] as RefCounted).get("holder_person_ids") as Array).duplicate()
    var title_result: Dictionary = router.call("apply", state, _command(state, "command:F2G00002", "command.set_champion", {
        "championship_id": "championship:CHA00002", "holder_person_ids": ["person:PER00001"],
    }))
    _expect(not bool(title_result.get("accepted", true)), "F2G-001: player must not mutate a rival championship.", failures)
    _expect((((state.get("championships") as Dictionary)["championship:CHA00002"] as RefCounted).get("holder_person_ids") as Array) == rival_title_before, "F2G-001: rejected rival championship mutation must leave title state unchanged.", failures)

func _test_player_cannot_mint_media_terms(failures: Array[String]) -> void:
    var state: RefCounted = Fixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var codec: RefCounted = Codec.new()
    var before: Dictionary = codec.call("encode", state)
    var result: Dictionary = router.call("apply", state, _command(state, "command:F2G00003", "command.sign_media_deal", {
        "media_deal_id": "media_deal:F2G00001",
        "promotion_id": Fixture.PROMOTION_A,
        "medium_id": "media_medium.invented",
        "outlet_id": "media_outlet.invented",
        "reach_market_ids": [Fixture.MARKET_A],
        "schedule_id": "schedule.invented",
        "cost": {"minor_units": 0, "currency_id": "currency.fixture"},
        "revenue": {"minor_units": 1000000000, "currency_id": "currency.fixture"},
    }))
    _expect(not bool(result.get("accepted", true)), "F2G-002: a player may not author arbitrary media economics.", failures)
    _expect(before == codec.call("encode", state), "F2G-002: rejected media mint must be atomic and create no deal/cash change.", failures)

func _test_booker_requires_live_employment_and_clears_on_expiry(failures: Array[String]) -> void:
    var state: RefCounted = Fixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var result: Dictionary = router.call("apply", state, _command(state, "command:F2G00004", "command.set_booker", {
        "promotion_id": Fixture.PROMOTION_A, "person_id": "person:PER00005",
    }))
    _expect(not bool(result.get("accepted", true)), "F2G-003: player must not appoint another promotion's worker as a free booker.", failures)

    var bookers: Dictionary = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    _expect(str(bookers.get(Fixture.PROMOTION_A, "")) == "person:PER00004", "F2G-003: fixture must begin with the employed player booker.", failures)
    var expiry: Dictionary = ContractSystem.new().call("resolve_expiry", state, "2002-10-01")
    _expect(bool(expiry.get("passed", false)), "F2G-003: expiry resolver must complete.", failures)
    bookers = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    _expect(not bookers.has(Fixture.PROMOTION_A), "F2G-003: an expired booker's appointment must be cleared instead of supplying free skill forever.", failures)

func _test_unavailable_people_cannot_be_assigned_or_booked(failures: Array[String]) -> void:
    var state: RefCounted = Fixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var company: RefCounted = (state.get("touring_companies") as Dictionary)["touring:TOU00001"]
    var before_assignments: Array = (company.get("person_assignment_ids") as Array).duplicate()
    var assigned: Dictionary = router.call("apply", state, _command(state, "command:F2G00005", "command.assign_person", {
        "touring_company_id": "touring:TOU00001", "person_id": "person:PER00005", "assigned": true,
    }))
    _expect(not bool(assigned.get("accepted", true)), "A player must not assign rival-exclusive talent without an employment/talent-share seam.", failures)
    _expect((company.get("person_assignment_ids") as Array) == before_assignments, "Rejected unavailable-person assignment must be atomic.", failures)

    var program_result: Dictionary = router.call("apply", state, _command(state, "command:F2G00006", "command.start_program", {
        "program_id": "program:F2G00001", "promotion_id": Fixture.PROMOTION_A,
        "side_a_person_ids": ["person:PER00001"], "side_b_person_ids": ["person:PER00005"],
        "purpose_id": "purpose.fixture", "phase_id": "phase.fixture",
    }))
    _expect(not bool(program_result.get("accepted", true)), "A player must not create an own-promotion program using unavailable rival talent.", failures)
    _expect(not (state.get("programs") as Dictionary).has("program:F2G00001"), "Rejected unavailable-person program must not leave residue.", failures)

func _command(state: RefCounted, id: String, type: String, payload: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", id); command.set("command_type", type)
    command.set("issued_for_turn", state.get("turn_number")); command.set("issued_on", state.get("current_date"))
    command.set("issuer", {"kind": "player", "promotion_id": Fixture.PROMOTION_A})
    command.set("turn_phase_ordinal", 3); command.set("priority", 10); command.set("issuer_key", "player." + Fixture.PROMOTION_A)
    command.set("payload", payload.duplicate(true))
    return command

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
