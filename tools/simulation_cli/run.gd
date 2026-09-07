extends SceneTree

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const PhaseDFixture = preload("res://tests/helpers/phase_d_fixture.gd")
const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const RandomService = preload("res://app/session/random_service.gd")
const SaveService = preload("res://persistence/services/save_service.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")

const EXIT_OK: int = 0
const EXIT_FAILURE: int = 1

func _init() -> void:
    var options: Dictionary = _parse_args(OS.get_cmdline_user_args())
    var campaign_ref: String = str(options.get("campaign", "fixture:phase_d"))
    var months: int = int(options.get("months", 12))
    var seed: int = int(options.get("seed", 12345))
    var session: Dictionary = _create_session(campaign_ref, seed)
    if not bool(session.get("passed", false)):
        _finish_failure(campaign_ref, months, seed, 0, session.get("errors", []), null, null)
        return
    var state: RefCounted = session["state"]
    var chronicle: RefCounted = session["chronicle"]
    var content_index: Dictionary = session["content_index"]
    var pipeline: RefCounted = MonthPipeline.new()
    var completed: int = 0
    var strategic_totals: Dictionary = {"shows": 0, "attendance": 0, "revenue_minor_units": 0, "cost_minor_units": 0, "hot_starts": 0, "hot_ends": 0}
    for month_index: int in range(months):
        var commands: Array = _commands_for_session(session, state, month_index)
        var result: RefCounted = pipeline.call("advance_month", state, chronicle, commands, content_index)
        if not bool(result.get("passed")):
            _finish_failure(campaign_ref, months, seed, completed, result.get("errors"), state, chronicle)
            return
        _accumulate_strategic_totals(strategic_totals, result, session)
        state = result.get("state")
        chronicle = result.get("chronicle")
        completed += 1
    var state_validation: Dictionary = CampaignStateValidator.new().validate(state, content_index)
    var chronicle_validation: Dictionary = ChronicleValidator.new().validate(chronicle)
    if not bool(state_validation["passed"]) or not bool(chronicle_validation["passed"]):
        _finish_failure(campaign_ref, months, seed, completed, state_validation.get("errors", []) + chronicle_validation.get("errors", []), state, chronicle)
        return
    var save_result: Dictionary = {"requested": bool(options.get("save_roundtrip", false)), "passed": true}
    if bool(options.get("save_roundtrip", false)):
        var service: RefCounted = SaveService.new()
        var save_id: String = str(options.get("save_id", "simulation_cli_acceptance"))
        var write: Dictionary = service.call("save", save_id, "Simulation CLI", state, chronicle, {"created_utc": "cli", "updated_utc": "cli"})
        if not bool(write["passed"]):
            _finish_failure(campaign_ref, months, seed, completed, write.get("errors", []), state, chronicle)
            return
        var load_result: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
        save_result = {"requested": true, "passed": bool(load_result.get("passed", false)), "save_id": save_id}
        if not bool(load_result.get("passed", false)):
            _finish_failure(campaign_ref, months, seed, completed, load_result.get("errors", []), state, chronicle)
            return
    var summary: Dictionary = _summary(campaign_ref, months, seed, completed, state, chronicle)
    if str(session.get("source_kind")) == "phase_e_fixture":
        summary["strategic"] = _phase_e_strategic_summary(state, chronicle, strategic_totals)
    summary["save_roundtrip"] = save_result
    summary["passed"] = true
    print("WE_SIM_SUMMARY " + JSON.stringify(summary))
    quit(EXIT_OK)

func _create_session(campaign_ref: String, seed: int) -> Dictionary:
    if campaign_ref.begins_with("save:"):
        var save_id: String = campaign_ref.trim_prefix("save:")
        var loaded: Dictionary = SaveService.new().load_save(save_id)
        if not bool(loaded.get("passed", false)): return loaded
        return {"passed": true, "state": loaded["state"], "chronicle": loaded["chronicle"], "content_index": {}, "source_kind": "persisted_save"}
    if campaign_ref.begins_with("fixture:"):
        var fixture_id: String = campaign_ref.trim_prefix("fixture:")
        if fixture_id == "phase_d":
            var phase_d_state: RefCounted = PhaseDFixture.make_state()
            var random_service: RefCounted = RandomService.new(seed)
            phase_d_state.set("rng_state", random_service.call("capture", int(phase_d_state.get("turn_number"))))
            return {"passed": true, "state": phase_d_state, "chronicle": PhaseDFixture.make_chronicle(), "content_index": PhaseDFixture.content_index(), "source_kind": "phase_d_fixture"}
        if fixture_id in ["phase_e_good", "phase_e_bad"]:
            var strategy: String = "good" if fixture_id == "phase_e_good" else "bad"
            return {"passed": true, "state": PhaseEFixture.make_state(seed), "chronicle": PhaseEFixture.make_chronicle(), "content_index": PhaseEFixture.content_index(), "source_kind": "phase_e_fixture", "strategy": strategy}
        return _failure("CLI001", "campaign", {"reason": "unknown_fixture", "fixture_id": fixture_id})
    return _failure("CLI001", "campaign", {"reason": "unsupported_campaign_reference", "supported_schemes": ["fixture:<id>", "save:<save_id>"]})

func _commands_for_session(session: Dictionary, state: RefCounted, month_index: int) -> Array:
    match str(session.get("source_kind")):
        "phase_d_fixture": return [PhaseDFixture.championship_command(state, month_index)]
        "phase_e_fixture": return PhaseEFixture.strategy_commands(state, str(session.get("strategy", "good")), month_index)
        _: return []

func _accumulate_strategic_totals(totals: Dictionary, result: RefCounted, session: Dictionary) -> void:
    if str(session.get("source_kind")) != "phase_e_fixture": return
    var phase_outputs: Dictionary = result.get("phase_outputs")
    for show_value: Variant in phase_outputs.get("show_results", []):
        var show: RefCounted = show_value
        totals["shows"] = int(totals["shows"]) + 1
        totals["attendance"] = int(totals["attendance"]) + int(show.get("attendance"))
    var economy: Dictionary = phase_outputs.get("economy", {})
    if economy.has(PhaseEFixture.PLAYER_PROMOTION_ID):
        var month_summary: Dictionary = economy[PhaseEFixture.PLAYER_PROMOTION_ID]
        totals["revenue_minor_units"] = int(totals["revenue_minor_units"]) + int(month_summary.get("revenue_minor_units", 0))
        totals["cost_minor_units"] = int(totals["cost_minor_units"]) + int(month_summary.get("cost_minor_units", 0))
    for event_value: Variant in result.get("events"):
        if not event_value is Dictionary: continue
        var event: Dictionary = event_value
        if str(event.get("event_type")) == "HotStateStarted": totals["hot_starts"] = int(totals["hot_starts"]) + 1
        elif str(event.get("event_type")) == "HotStateEnded": totals["hot_ends"] = int(totals["hot_ends"]) + 1

func _parse_args(arguments: PackedStringArray) -> Dictionary:
    var options: Dictionary = {}
    var index: int = 0
    while index < arguments.size():
        var argument: String = arguments[index]
        if argument.begins_with("--campaign="): options["campaign"] = argument.trim_prefix("--campaign=")
        elif argument == "--campaign" and index + 1 < arguments.size(): index += 1; options["campaign"] = arguments[index]
        elif argument.begins_with("--months="): options["months"] = int(argument.trim_prefix("--months="))
        elif argument == "--months" and index + 1 < arguments.size(): index += 1; options["months"] = int(arguments[index])
        elif argument.begins_with("--seed="): options["seed"] = int(argument.trim_prefix("--seed="))
        elif argument == "--seed" and index + 1 < arguments.size(): index += 1; options["seed"] = int(arguments[index])
        elif argument == "--save-roundtrip": options["save_roundtrip"] = true
        elif argument.begins_with("--save-id="): options["save_id"] = argument.trim_prefix("--save-id=")
        index += 1
    return options

func _summary(campaign_ref: String, requested: int, seed: int, completed: int, state: RefCounted, chronicle: RefCounted) -> Dictionary:
    return {
        "schema": "we.simulation_summary.v1",
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION,
        "game_version": ProjectVersion.GAME_VERSION,
        "build_phase": ProjectVersion.BUILD_PHASE,
        "campaign": campaign_ref,
        "campaign_identity": state.get("campaign_pack_id"),
        "content_fingerprint": state.get("content_fingerprint"),
        "seed": seed,
        "requested_months": requested,
        "completed_months": completed,
        "final_in_game_date": state.get("current_date"),
        "invariant_status": "PASS",
        "chronicle_head": {"date": chronicle.get("head_date"), "sequence": chronicle.get("head_sequence"), "checkpoint_generation": chronicle.get("checkpoint_generation")},
        "chronicle_counts": chronicle.call("counts"),
    }

func _phase_e_strategic_summary(state: RefCounted, chronicle: RefCounted, totals: Dictionary) -> Dictionary:
    var star: RefCounted = (state.get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    var audience: Dictionary = star.get("audience_by_market")
    var market_a: RefCounted = (state.get("markets") as Dictionary)[PhaseEFixture.MARKET_A]
    var market_b: RefCounted = (state.get("markets") as Dictionary)[PhaseEFixture.MARKET_B]
    var program: RefCounted = (state.get("programs") as Dictionary)[PhaseEFixture.PROGRAM_ID]
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID]
    var company: RefCounted = (state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID]
    var local_a: Dictionary = audience.get(PhaseEFixture.MARKET_A, {})
    var local_b: Dictionary = audience.get(PhaseEFixture.MARKET_B, {})
    var revenue: int = int(totals.get("revenue_minor_units", 0))
    var cost: int = int(totals.get("cost_minor_units", 0))
    return {
        "shows_resolved": int(totals.get("shows", 0)),
        "attendance_total": int(totals.get("attendance", 0)),
        "revenue_minor_units": revenue,
        "cost_minor_units": cost,
        "profit_minor_units": revenue - cost,
        "cash_minor_units": int((promotion.get("cash") as Dictionary).get("minor_units", 0)),
        "touring_company": {"id": company.get("id"), "route": (company.get("route") as Array).duplicate(true), "directives": (company.get("directives") as Array).duplicate(true), "fatigue_pressure": company.get("fatigue_pressure")},
        "star_audience": {
            PhaseEFixture.MARKET_A: local_a.duplicate(true),
            PhaseEFixture.MARKET_B: local_b.duplicate(true),
        },
        "program": {"id": program.get("id"), "status": program.get("status"), "heat": program.get("heat"), "momentum": program.get("momentum")},
        "market_influence": {
            PhaseEFixture.MARKET_A: (market_a.get("influence_by_promotion") as Dictionary).get(PhaseEFixture.PLAYER_PROMOTION_ID, {}).duplicate(true),
            PhaseEFixture.MARKET_B: (market_b.get("influence_by_promotion") as Dictionary).get(PhaseEFixture.PLAYER_PROMOTION_ID, {}).duplicate(true),
        },
        "market_interest": {PhaseEFixture.MARKET_A: market_a.get("wrestling_interest"), PhaseEFixture.MARKET_B: market_b.get("wrestling_interest")},
        "media_deals": _active_media_summary(state),
        "financial_stress": (state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(PhaseEFixture.PLAYER_PROMOTION_ID, 0.0),
        "hot_cold": {"starts": int(totals.get("hot_starts", 0)), "ends": int(totals.get("hot_ends", 0))},
        "chronicle_head_sequence": chronicle.get("head_sequence"),
    }

func _active_media_summary(state: RefCounted) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for deal_id: String in (state.get("media_deals") as Dictionary).keys():
        var deal: RefCounted = (state.get("media_deals") as Dictionary)[deal_id]
        if str(deal.get("promotion_id")) != PhaseEFixture.PLAYER_PROMOTION_ID: continue
        output.append({"id": deal_id, "medium_id": deal.get("medium_id"), "status": deal.get("status"), "reach_market_ids": (deal.get("reach_market_ids") as Array).duplicate(true)})
    output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id")) < str(b.get("id")))
    return output

func _finish_failure(campaign_ref: String, requested: int, seed: int, completed: int, errors: Array, state: Variant, chronicle: Variant) -> void:
    var failure: Dictionary = {
        "schema": "we.simulation_summary.v1", "passed": false,
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION, "game_version": ProjectVersion.GAME_VERSION,
        "build_phase": ProjectVersion.BUILD_PHASE, "campaign": campaign_ref, "seed": seed,
        "requested_months": requested, "completed_months": completed, "errors": errors.duplicate(true), "failure_seed": seed,
    }
    if state is RefCounted: failure["final_in_game_date"] = state.get("current_date")
    if chronicle is RefCounted: failure["chronicle_head"] = {"date": chronicle.get("head_date"), "sequence": chronicle.get("head_sequence")}
    _write_failure_artifact(failure)
    print("WE_SIM_SUMMARY " + JSON.stringify(failure))
    quit(EXIT_FAILURE)

func _write_failure_artifact(failure: Dictionary) -> void:
    var path: String = "user://diagnostics/simulation-failure.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(failure, "  ", true, true) + "\n")
        file.close()

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
