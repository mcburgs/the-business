extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const LogisticsSystem = preload("res://domain/touring/logistics_system.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")

var _failures: Array[String] = []

func run() -> Dictionary:
    _test_fixture_and_deterministic_logistics()
    _test_invalid_commands_are_atomic()
    _test_split_merge_hooks()
    return {"name": "phase_e_commands_logistics", "passed": _failures.is_empty(), "failures": _failures}

func _test_fixture_and_deterministic_logistics() -> void:
    var left: RefCounted = PhaseEFixture.make_state()
    var right: RefCounted = PhaseEFixture.make_state()
    _expect(bool(CampaignStateValidator.new().validate(left, PhaseEFixture.content_index())["passed"]), "Phase E fixture must satisfy canonical state validation")
    var logistics: RefCounted = LogisticsSystem.new()
    var a: Dictionary = logistics.call("resolve", left, PhaseEFixture.content_index(), PhaseEFixture.tuning())
    var b: Dictionary = logistics.call("resolve", right, PhaseEFixture.content_index(), PhaseEFixture.tuning())
    _expect(bool(a["passed"]) and a == b, "equal state and generic route data must produce deterministic logistics")
    var schedules: Array = a.get("schedules", [])
    _expect(schedules.size() == 1 and str((schedules[0] as Dictionary).get("market_id")) == PhaseEFixture.MARKET_A, "turn zero should resolve the first route stop")
    var pressure: float = float((schedules[0] as Dictionary).get("travel_pressure", -1.0))
    _expect(pressure >= 0.0 and pressure <= 1.0, "travel/fatigue pressure must remain bounded")
    var rival: RefCounted = (left.get("people") as Dictionary)[PhaseEFixture.RIVAL_ID]
    rival.set("health", {"status": "unavailable", "injury_risk": 0.2})
    var unavailable: Dictionary = logistics.call("resolve", left, PhaseEFixture.content_index(), PhaseEFixture.tuning())
    var schedule: Dictionary = unavailable.get("schedules", [])[0]
    _expect(PhaseEFixture.RIVAL_ID in (schedule.get("unavailable_person_ids", []) as Array) and not PhaseEFixture.RIVAL_ID in (schedule.get("available_person_ids", []) as Array), "logistics must respect unavailable personnel")

func _test_invalid_commands_are_atomic() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var company: RefCounted = (state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID]
    var original_route: Array = (company.get("route") as Array).duplicate(true)
    var invalid_route: RefCounted = PhaseEFixture.command(state, 30, "command.set_route", {"touring_company_id": PhaseEFixture.COMPANY_ID, "route": [{"market_id": "market.does_not_exist"}]})
    var route_result: Dictionary = router.call("apply", state, invalid_route, PhaseEFixture.content_index())
    _expect(not bool(route_result.get("accepted", false)), "invalid route must be rejected")
    _expect(company.get("route") == original_route, "rejected route must not partially mutate company state")

    var create_conflict: RefCounted = PhaseEFixture.command(state, 31, "command.create_touring_company", {
        "touring_company_id": "touring:TOU00002", "promotion_id": PhaseEFixture.PLAYER_PROMOTION_ID, "name": "Conflict Tour",
        "person_assignment_ids": [PhaseEFixture.STAR_ID], "route": [{"market_id": PhaseEFixture.MARKET_B}],
        "monthly_budget": {"minor_units": 50000, "currency_id": "currency.fixture"},
    })
    var conflict_result: Dictionary = router.call("apply", state, create_conflict, PhaseEFixture.content_index())
    _expect(not bool(conflict_result.get("accepted", false)), "a person cannot be duplicated into incompatible simultaneous touring assignments")
    _expect(not (state.get("touring_companies") as Dictionary).has("touring:TOU00002"), "rejected create must not leave a partial touring company")

    var invalid_split: RefCounted = PhaseEFixture.command(state, 32, "command.split_company", {
        "source_touring_company_id": PhaseEFixture.COMPANY_ID, "new_touring_company_id": "touring:TOU00003", "name": "Invalid Split",
        "person_ids": [PhaseEFixture.STAR_ID, PhaseEFixture.RIVAL_ID, PhaseEFixture.SUPPORT_ID],
    })
    var split_result: Dictionary = router.call("apply", state, invalid_split, PhaseEFixture.content_index())
    _expect(not bool(split_result.get("accepted", false)), "split that empties the source company must be rejected")
    _expect(not (state.get("touring_companies") as Dictionary).has("touring:TOU00003"), "rejected split must not partially mutate retained state")

func _test_split_merge_hooks() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var split: RefCounted = PhaseEFixture.command(state, 40, "command.split_company", {
        "source_touring_company_id": PhaseEFixture.COMPANY_ID, "new_touring_company_id": "touring:TOU00004", "name": "Secondary Tour",
        "person_ids": [PhaseEFixture.SUPPORT_ID], "route": [{"market_id": PhaseEFixture.MARKET_B}],
        "monthly_budget": {"minor_units": 60000, "currency_id": "currency.fixture"},
    })
    var split_result: Dictionary = router.call("apply", state, split, PhaseEFixture.content_index())
    _expect(bool(split_result.get("accepted", false)), "valid split hook should create a reference-based secondary company")
    if not bool(split_result.get("accepted", false)): return
    var source: RefCounted = (state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID]
    var secondary: RefCounted = (state.get("touring_companies") as Dictionary)["touring:TOU00004"]
    _expect(not PhaseEFixture.SUPPORT_ID in (source.get("person_assignment_ids") as Array) and PhaseEFixture.SUPPORT_ID in (secondary.get("person_assignment_ids") as Array), "split must move assignment references without owning Person identity")
    var merge: RefCounted = PhaseEFixture.command(state, 41, "command.merge_company", {"target_touring_company_id": PhaseEFixture.COMPANY_ID, "source_touring_company_id": "touring:TOU00004"})
    var merge_result: Dictionary = router.call("apply", state, merge, PhaseEFixture.content_index())
    _expect(bool(merge_result.get("accepted", false)), "valid merge hook should recombine touring assignments")
    _expect(str(secondary.get("status")) == "merged" and (secondary.get("person_assignment_ids") as Array).is_empty(), "merged source must become inactive without duplicating people")
    _expect(PhaseEFixture.SUPPORT_ID in (source.get("person_assignment_ids") as Array), "merge must restore moved person reference to target")

func _expect(condition: bool, message: String) -> void:
    if not condition: _failures.append(message)
