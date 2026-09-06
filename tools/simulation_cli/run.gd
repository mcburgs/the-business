extends SceneTree

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const PhaseDFixture = preload("res://tests/helpers/phase_d_fixture.gd")
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
    for month_index: int in range(months):
        var commands: Array = []
        if str(session.get("source_kind")) == "synthetic_fixture": commands.append(PhaseDFixture.championship_command(state, month_index))
        var result: RefCounted = pipeline.call("advance_month", state, chronicle, commands, content_index)
        if not bool(result.get("passed")):
            _finish_failure(campaign_ref, months, seed, completed, result.get("errors"), state, chronicle)
            return
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
        var save_id: String = str(options.get("save_id", "phase_d_cli_acceptance"))
        var write: Dictionary = service.call("save", save_id, "Phase D CLI", state, chronicle, {"created_utc": "cli", "updated_utc": "cli"})
        if not bool(write["passed"]):
            _finish_failure(campaign_ref, months, seed, completed, write.get("errors", []), state, chronicle)
            return
        var load_result: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
        save_result = {"requested": true, "passed": bool(load_result.get("passed", false)), "save_id": save_id}
        if not bool(load_result.get("passed", false)):
            _finish_failure(campaign_ref, months, seed, completed, load_result.get("errors", []), state, chronicle)
            return
    var summary: Dictionary = _summary(campaign_ref, months, seed, completed, state, chronicle)
    summary["save_roundtrip"] = save_result
    summary["passed"] = true
    print("WE_PHASE_D_SIM_SUMMARY " + JSON.stringify(summary))
    quit(EXIT_OK)

func _create_session(campaign_ref: String, seed: int) -> Dictionary:
    if campaign_ref.begins_with("save:"):
        var save_id: String = campaign_ref.trim_prefix("save:")
        var loaded: Dictionary = SaveService.new().load_save(save_id)
        if not bool(loaded.get("passed", false)): return loaded
        return {"passed": true, "state": loaded["state"], "chronicle": loaded["chronicle"], "content_index": {}, "source_kind": "persisted_save"}
    if campaign_ref.begins_with("fixture:"):
        var fixture_id: String = campaign_ref.trim_prefix("fixture:")
        if fixture_id != "phase_d": return _failure("CLI001", "campaign", {"reason": "unknown_fixture", "fixture_id": fixture_id})
        var state: RefCounted = PhaseDFixture.make_state()
        var random_service: RefCounted = RandomService.new(seed)
        state.set("rng_state", random_service.call("capture", int(state.get("turn_number"))))
        return {"passed": true, "state": state, "chronicle": PhaseDFixture.make_chronicle(), "content_index": PhaseDFixture.content_index(), "source_kind": "synthetic_fixture"}
    return _failure("CLI001", "campaign", {"reason": "unsupported_campaign_reference", "supported_schemes": ["fixture:<id>", "save:<save_id>"]})

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
        "schema": "we.phase_d.simulation_summary.v1",
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

func _finish_failure(campaign_ref: String, requested: int, seed: int, completed: int, errors: Array, state: Variant, chronicle: Variant) -> void:
    var failure: Dictionary = {
        "schema": "we.phase_d.simulation_summary.v1", "passed": false,
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION, "game_version": ProjectVersion.GAME_VERSION,
        "campaign": campaign_ref, "seed": seed, "requested_months": requested, "completed_months": completed,
        "errors": errors.duplicate(true), "failure_seed": seed,
    }
    if state is RefCounted: failure["final_in_game_date"] = state.get("current_date")
    if chronicle is RefCounted: failure["chronicle_head"] = {"date": chronicle.get("head_date"), "sequence": chronicle.get("head_sequence")}
    _write_failure_artifact(failure)
    print("WE_PHASE_D_SIM_SUMMARY " + JSON.stringify(failure))
    quit(EXIT_FAILURE)

func _write_failure_artifact(failure: Dictionary) -> void:
    var path: String = "user://diagnostics/phase-d-simulation-failure.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(failure, "  ") + "\n")
        file.close()

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
