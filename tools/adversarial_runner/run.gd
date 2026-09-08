extends SceneTree

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const AIPlanningView = preload("res://domain/ai/ai_planning_view.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

const PACKAGE_ID := "F2G-STRAT-001"
const POLICY_VERSION := "f2g.policy.v1"
const PROFILES: Array[String] = [
    "rational_optimizer", "hyper_aggressive_expansionist", "ultra_conservative_operator",
    "talent_hoarder", "market_spammer", "contract_timing_exploiter", "creative_system_exploiter",
    "financial_idiot", "random_valid_command_chaos", "turn_boundary_attacker",
]

var _command_sequence: int = 0

func _init() -> void:
    var opts: Dictionary = _parse_args(OS.get_cmdline_user_args())
    var months: int = maxi(1, int(opts.get("months", 60)))
    var seeds: Array[int] = _parse_seeds(str(opts.get("seeds", "424242,424242,424243,424244")))
    var output_root: String = str(opts.get("output", "res://tests/adversarial/evidence/F2G-STRAT-001"))
    var selected_profiles: Array[String] = PROFILES.duplicate()
    if opts.has("profile"):
        selected_profiles = [str(opts["profile"])]
    var runs: Array[Dictionary] = []
    var errors: Array = []
    for profile: String in selected_profiles:
        if not profile in PROFILES:
            errors.append({"code": "ADV001", "profile": profile, "reason": "unknown_profile"})
            continue
        for seed_index: int in range(seeds.size()):
            var seed: int = seeds[seed_index]
            var run: Dictionary = _simulate(profile, seed, months, output_root, seed_index)
            runs.append(run)
            if not bool(run.get("passed", false)):
                errors.append({"profile": profile, "seed": seed, "errors": run.get("errors", [])})
    var summary: Dictionary = _aggregate(months, seeds, selected_profiles, runs, errors)
    _write_json(output_root.path_join("matrix_summary.json"), summary)
    _write_matrix_markdown(output_root.path_join("MATRIX_SUMMARY.md"), summary)
    print("WE_F2G_ADVERSARIAL_SUMMARY " + JSON.stringify(summary))
    quit(0 if bool(summary.get("passed", false)) else 1)

func _simulate(profile: String, seed: int, months: int, output_root: String, replicate_index: int = 0) -> Dictionary:
    _command_sequence = 0
    var run_id: String = "%s-s%d-r%d" % [profile, seed, replicate_index]
    var run_dir: String = output_root.path_join(run_id)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(run_dir))
    var state: RefCounted = Fixture.make_state(seed)
    var chronicle: RefCounted = Fixture.make_chronicle(6)
    var content_index: Dictionary = Fixture.content_index().duplicate(true)
    content_index["phase_f_ai_controlled_promotions"] = {Fixture.PROMOTION_B: "ai", Fixture.PROMOTION_C: "ai"}
    var pipeline: RefCounted = MonthPipeline.new()
    var view_builder: RefCounted = AIPlanningView.new()
    var state_validator: RefCounted = CampaignStateValidator.new()
    var chronicle_validator: RefCounted = ChronicleValidator.new()
    var ledger: RefCounted = LedgerService.new()
    var state_codec: RefCounted = CampaignStateCodec.new()
    var chronicle_codec: RefCounted = ChronicleCodec.new()
    var history_query: RefCounted = ChronicleQueryService.new()
    var transcript: Array[Dictionary] = []
    var month_metrics: Array[Dictionary] = []
    var invariant_checks: Array[Dictionary] = []
    var run_errors: Array = []
    var accepted_player: int = 0
    var rejected_player: int = 0
    var max_cash_delta: int = 0
    var prior_cash: int = int((((state.get("promotions") as Dictionary)[Fixture.PROMOTION_A] as RefCounted).get("cash") as Dictionary).get("minor_units", 0))
    var date_history: Array[String] = [str(state.get("current_date"))]
    var expected_rejections: int = 0
    var expected_rejection_ids: Dictionary = {}
    var observed_expected_rejections: int = 0

    for month_index: int in range(months):
        var player_view: Dictionary = view_builder.call("build", state, Fixture.PROMOTION_A)
        var leak_check: Dictionary = _validate_player_view(player_view)
        invariant_checks.append({"month": month_index, "check": "knowledge_surface", "passed": leak_check.get("passed"), "errors": leak_check.get("errors", [])})
        if not bool(leak_check.get("passed", false)):
            run_errors.append_array(leak_check.get("errors", []))
            break
        var planned: Dictionary = _policy_commands(profile, player_view, month_index, seed)
        var commands: Array = planned.get("commands", [])
        expected_rejections += int(planned.get("expected_rejections", 0))
        for expected_id: Variant in planned.get("expected_rejection_ids", []): expected_rejection_ids[str(expected_id)] = true
        var requested_by_id: Dictionary = {}
        for command_value: Variant in commands:
            var command: RefCounted = command_value
            requested_by_id[str(command.get("command_id"))] = command
            transcript.append({"month": month_index, "stage": "requested", "command": command.call("to_dict")})
        var result: RefCounted = pipeline.call("advance_month", state, chronicle, commands, content_index)
        if not bool(result.get("passed")):
            run_errors.append({"code": "ADV002", "month": month_index, "reason": "month_pipeline_failed", "errors": result.get("errors")})
            break
        state = result.get("state")
        chronicle = result.get("chronicle")
        date_history.append(str(state.get("current_date")))
        for command_result_value: Variant in result.get("command_results"):
            if not command_result_value is Dictionary: continue
            var command_result: Dictionary = command_result_value
            var command_id: String = str(command_result.get("command_id", ""))
            if requested_by_id.has(command_id):
                transcript.append({"month": month_index, "stage": "result", "result": command_result.duplicate(true)})
                if bool(command_result.get("accepted", false)): accepted_player += 1
                else:
                    rejected_player += 1
                    if expected_rejection_ids.has(command_id): observed_expected_rejections += 1
        var state_validation: Dictionary = state_validator.call("validate", state, content_index)
        var chronicle_validation: Dictionary = chronicle_validator.call("validate", chronicle)
        var ledger_validation: Dictionary = ledger.call("validate_ledger", state.get("world_state"))
        var seat: Dictionary = (state.get("ownership_seat") as RefCounted).call("to_dict")
        var ownership_ok: bool = not seat.has("owner_person_id") and str(seat.get("promotion_id")) == Fixture.PROMOTION_A
        var inv_pass: bool = bool(state_validation.get("passed", false)) and bool(chronicle_validation.get("passed", false)) and bool(ledger_validation.get("passed", false)) and ownership_ok
        invariant_checks.append({"month": month_index, "check": "authoritative_state", "passed": inv_pass, "state_errors": state_validation.get("errors", []), "chronicle_errors": chronicle_validation.get("errors", []), "ledger_errors": ledger_validation.get("errors", []), "ownership_seat_ok": ownership_ok})
        if not inv_pass:
            run_errors.append({"code": "ADV003", "month": month_index, "reason": "invariant_failure", "state": state_validation, "chronicle": chronicle_validation, "ledger": ledger_validation, "ownership_seat_ok": ownership_ok})
            break
        if month_index >= 5 and month_index % 6 == 5:
            var target_date: String = date_history[date_history.size() - 4]
            var before_history: Dictionary = state_codec.call("encode", state)
            var projection: Dictionary = history_query.call("get_projection", chronicle, target_date)
            var after_history: Dictionary = state_codec.call("encode", state)
            var history_ok: bool = bool(projection.get("passed", false)) and before_history == after_history
            invariant_checks.append({"month": month_index, "check": "historical_reconstruction", "target_date": target_date, "passed": history_ok, "errors": projection.get("errors", [])})
            if not history_ok:
                run_errors.append({"code": "ADV004", "month": month_index, "reason": "historical_reconstruction_failure", "target_date": target_date, "errors": projection.get("errors", [])})
                break
        var cash: int = int((((state.get("promotions") as Dictionary)[Fixture.PROMOTION_A] as RefCounted).get("cash") as Dictionary).get("minor_units", 0))
        max_cash_delta = maxi(max_cash_delta, absi(cash - prior_cash))
        prior_cash = cash
        month_metrics.append(_month_metric(state, result, month_index, cash))

    if run_errors.is_empty():
        var save_check: Dictionary = _save_roundtrip(run_id, state, chronicle, state_codec, chronicle_codec)
        invariant_checks.append({"month": months, "check": "save_roundtrip", "passed": save_check.get("passed"), "errors": save_check.get("errors", [])})
        if not bool(save_check.get("passed", false)): run_errors.append_array(save_check.get("errors", []))
    if expected_rejections != observed_expected_rejections:
        run_errors.append({"code": "ADV005", "reason": "expected_rejection_mismatch", "expected": expected_rejections, "observed": observed_expected_rejections})

    var final_state: Dictionary = state_codec.call("encode", state)
    var final_chronicle: Dictionary = chronicle_codec.call("encode", chronicle)
    var fingerprint: String = _hash({"state": final_state, "chronicle": final_chronicle})
    var final_promotion: RefCounted = (state.get("promotions") as Dictionary)[Fixture.PROMOTION_A]
    var run_summary: Dictionary = {
        "schema": "we.f2g.adversarial_run.v1", "package_id": PACKAGE_ID, "policy_id": profile, "policy_version": POLICY_VERSION,
        "baseline_commit": "20ddeaa45bfdbfce98be066cdc13d656d5d6363a", "tree": "ae2ec32af6d5f8af4c91a22fcaf67723849d0c30",
        "engine_expected": ProjectVersion.ENGINE_VERSION, "game_version": ProjectVersion.GAME_VERSION, "architecture_version": ProjectVersion.ARCHITECTURE_VERSION,
        "seed": seed, "months_requested": months, "months_completed": month_metrics.size(), "passed": run_errors.is_empty(), "errors": run_errors,
        "world_fingerprint": fingerprint, "final_date": state.get("current_date"), "final_cash_minor_units": (final_promotion.get("cash") as Dictionary).get("minor_units"),
        "final_prestige": final_promotion.get("prestige"), "final_momentum": final_promotion.get("momentum"),
        "active_contracts": (final_promotion.get("contract_ids") as Array).size(), "accepted_player_commands": accepted_player, "rejected_player_commands": rejected_player,
        "expected_rejections": expected_rejections, "observed_expected_rejections": observed_expected_rejections, "max_abs_month_cash_delta": max_cash_delta,
        "chronicle_counts": chronicle.call("counts"), "maximum_market_concentration": _max_concentration(state), "promotions_active": _active_promotions(state),
    }
    _write_json(run_dir.path_join("manifest.json"), {"package_id": PACKAGE_ID, "run_id": run_id, "policy_id": profile, "policy_version": POLICY_VERSION, "seed": seed, "months": months, "baseline_commit": run_summary["baseline_commit"], "engine_expected": run_summary["engine_expected"], "content_fingerprint": state.get("content_fingerprint")})
    _write_jsonl(run_dir.path_join("commands.jsonl"), transcript)
    _write_json(run_dir.path_join("metrics.json"), {"months": month_metrics})
    _write_json(run_dir.path_join("invariants.json"), {"checks": invariant_checks, "passed": run_errors.is_empty()})
    _write_json(run_dir.path_join("diagnostics.json"), {"errors": run_errors, "max_abs_month_cash_delta": max_cash_delta})
    _write_json(run_dir.path_join("summary.json"), run_summary)
    _write_run_markdown(run_dir.path_join("summary.md"), run_summary)
    _write_run_log(run_dir.path_join("run.log"), run_summary, invariant_checks)
    return run_summary

func _policy_commands(profile: String, view: Dictionary, month: int, seed: int) -> Dictionary:
    var commands: Array = []
    var expected_rejections: int = 0
    var expected_rejection_ids: Array[String] = []
    var own_company: Dictionary = (view.get("companies", []) as Array)[0] if not (view.get("companies", []) as Array).is_empty() else {}
    var own_people: Array[String] = []
    for person_id: Variant in (view.get("own_people", {}) as Dictionary).keys(): own_people.append(str(person_id))
    own_people.sort()
    var market_ids: Array[String] = []
    for market_id: Variant in (view.get("markets", {}) as Dictionary).keys(): market_ids.append(str(market_id))
    market_ids.sort()
    var best_market: String = _best_market(view, false)
    var weak_market: String = _best_market(view, true)
    match profile:
        "rational_optimizer":
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": best_market, "intensity": 0.70}))
            _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(12000)}))
            _maybe_renew(commands, view, 1.05)
            _maybe_counter(commands, view)
            _maybe_offer(commands, view, month, 1.02, false)
            if not own_company.is_empty(): _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": best_market}]}))
        "hyper_aggressive_expansionist":
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": weak_market, "intensity": 1.0}))
            _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(70000)}))
            if not own_company.is_empty(): _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": weak_market}]}))
            _maybe_offer(commands, view, month, 1.35, true)
            _maybe_counter(commands, view)
            _maybe_violate(commands, view)
        "ultra_conservative_operator":
            var home: String = str((view.get("home_market_ids", []) as Array)[0]) if not (view.get("home_market_ids", []) as Array).is_empty() else best_market
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": home, "intensity": 0.35}))
            _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(1500)}))
            if not own_company.is_empty():
                _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": home}]}))
                _add(commands, _cmd(view, "command.adjust_budget", {"touring_company_id": own_company.get("touring_company_id"), "monthly_budget": _money(60000)}))
            _maybe_renew(commands, view, 1.0)
            _maybe_counter(commands, view)
        "talent_hoarder":
            _maybe_renew(commands, view, 1.40)
            _maybe_counter(commands, view)
            _offer_all_visible_free_agents(commands, view, month, 1.45)
        "market_spammer":
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": market_ids[-1], "intensity": 1.0}))
            _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(100000)}))
            if not own_company.is_empty(): _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": market_ids[-1]}]}))
        "contract_timing_exploiter":
            _maybe_counter(commands, view)
            _maybe_renew(commands, view, 1.18)
            if month % 3 == 0: _maybe_offer(commands, view, month, 0.78, false)
            elif month % 3 == 1: _maybe_offer(commands, view, month, 1.20, false)
            if month % 12 == 11 and not (view.get("own_contracts", []) as Array).is_empty():
                var contract: Dictionary = (view.get("own_contracts", []) as Array)[-1]
                _add(commands, _cmd(view, "command.release_person", {"contract_id": contract.get("contract_id"), "promotion_id": Fixture.PROMOTION_A}))
        "creative_system_exploiter":
            if not own_company.is_empty() and not (own_company.get("person_assignment_ids", []) as Array).is_empty():
                var star: String = str((own_company.get("person_assignment_ids", []) as Array)[0])
                _add(commands, _cmd(view, "command.push_person", {"touring_company_id": own_company.get("touring_company_id"), "person_id": star, "weight": 1.0}))
                _add(commands, _cmd(view, "command.protect_person", {"touring_company_id": own_company.get("touring_company_id"), "person_id": star, "weight": 1.0}))
            if own_people.size() >= 2:
                _add(commands, _cmd(view, "command.start_program", {"program_id": "program:ADV%02d%03d" % [posmod(seed, 97), month], "promotion_id": Fixture.PROMOTION_A, "side_a_person_ids": [own_people[0]], "side_b_person_ids": [own_people[1]], "purpose_id": "purpose.fixture", "phase_id": "phase.fixture"}))
            if not (view.get("championships", []) as Array).is_empty() and not own_people.is_empty():
                _add(commands, _cmd(view, "command.approve_major_outcome", {"promotion_id": Fixture.PROMOTION_A, "winner_person_id": own_people[0], "championship_id": (view.get("championships", []) as Array)[0].get("championship_id")}))
        "financial_idiot":
            _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(750000)}))
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": weak_market, "intensity": 1.0}))
            if not own_company.is_empty():
                _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": weak_market}]}))
                _add(commands, _cmd(view, "command.adjust_budget", {"touring_company_id": own_company.get("touring_company_id"), "monthly_budget": _money(900000)}))
            _maybe_offer(commands, view, month, 2.0, true)
        "random_valid_command_chaos":
            var choice: int = posmod(seed * 1103515245 + (month + 1) * 12345, 6)
            if choice == 0: _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": market_ids[posmod(seed + month, market_ids.size())], "intensity": float(posmod(seed + month * 7, 101)) / 100.0}))
            elif choice == 1: _add(commands, _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(posmod(seed + month * 1009, 80000))}))
            elif choice == 2 and not own_company.is_empty(): _add(commands, _cmd(view, "command.set_route", {"touring_company_id": own_company.get("touring_company_id"), "route": [{"market_id": market_ids[posmod(seed + month * 3, market_ids.size())]}]}))
            elif choice == 3: _maybe_offer(commands, view, month, 1.0, false)
            elif choice == 4: _maybe_counter(commands, view)
            elif choice == 5 and not own_company.is_empty(): _add(commands, _cmd(view, "command.adjust_budget", {"touring_company_id": own_company.get("touring_company_id"), "monthly_budget": _money(45000 + posmod(seed + month * 77, 200000))}))
        "turn_boundary_attacker":
            _add(commands, _cmd(view, "command.book_market_focus", {"promotion_id": Fixture.PROMOTION_A, "market_id": best_market, "intensity": 0.5}))
            var stale: RefCounted = _cmd(view, "command.set_local_media_spend", {"promotion_id": Fixture.PROMOTION_A, "spend": _money(9000)})
            stale.set("issued_for_turn", int(view.get("turn_number")) - 1)
            _add(commands, stale); expected_rejections += 1; expected_rejection_ids.append(str(stale.get("command_id")))
            if own_people.size() >= 2:
                var duplicate_id: String = "program:ADVDUP%03d" % month
                _add(commands, _cmd(view, "command.start_program", {"program_id": duplicate_id, "promotion_id": Fixture.PROMOTION_A, "side_a_person_ids": [own_people[0]], "side_b_person_ids": [own_people[1]], "purpose_id": "purpose.fixture", "phase_id": "phase.fixture"}))
                var duplicate: RefCounted = _cmd(view, "command.start_program", {"program_id": duplicate_id, "promotion_id": Fixture.PROMOTION_A, "side_a_person_ids": [own_people[0]], "side_b_person_ids": [own_people[1]], "purpose_id": "purpose.fixture", "phase_id": "phase.fixture"})
                _add(commands, duplicate); expected_rejections += 1; expected_rejection_ids.append(str(duplicate.get("command_id")))
    return {"commands": commands, "expected_rejections": expected_rejections, "expected_rejection_ids": expected_rejection_ids}

func _cmd(view: Dictionary, type: String, payload: Dictionary) -> RefCounted:
    _command_sequence += 1
    var clean_payload: Dictionary = payload.duplicate(true)
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", "command:ADV%07d" % _command_sequence)
    command.set("command_type", type); command.set("issued_for_turn", int(view.get("turn_number"))); command.set("issued_on", str(view.get("current_date")))
    command.set("issuer", {"kind": "player", "promotion_id": Fixture.PROMOTION_A}); command.set("turn_phase_ordinal", 3); command.set("priority", 10)
    command.set("issuer_key", "player." + Fixture.PROMOTION_A); command.set("payload", clean_payload)
    return command

func _add(commands: Array, command: Variant) -> void:
    if command is RefCounted: commands.append(command)

func _maybe_counter(commands: Array, view: Dictionary) -> void:
    for pending_value: Variant in view.get("pending_negotiations", []):
        var pending: Dictionary = pending_value
        _add(commands, _cmd(view, "command.counter_offer", {"contract_id": pending.get("contract_id"), "promotion_id": Fixture.PROMOTION_A, "compensation": _contract_money(int(pending.get("counter_minor_units", 0))), "end_date": _future_date(str(view.get("current_date")), 24)}))
        return

func _maybe_renew(commands: Array, view: Dictionary, multiplier: float) -> void:
    var current: String = str(view.get("current_date"))
    for contract_value: Variant in view.get("own_contracts", []):
        var contract: Dictionary = contract_value
        var end_date: String = str(contract.get("end_date", ""))
        if not end_date.is_empty() and _months_between(current, end_date) <= 3:
            var pay: int = int((((contract.get("compensation", {}) as Dictionary).get("base", {}) as Dictionary).get("minor_units", 12000)))
            _add(commands, _cmd(view, "command.renew_contract", {"contract_id": contract.get("contract_id"), "promotion_id": Fixture.PROMOTION_A, "compensation": _contract_money(int(round(float(pay) * multiplier))), "end_date": _future_date(current, 24)}))
            return

func _maybe_offer(commands: Array, view: Dictionary, month: int, multiplier: float, include_employed: bool) -> void:
    for talent_value: Variant in view.get("external_talent", []):
        var talent: Dictionary = talent_value
        if not include_employed and talent.get("employer_promotion_id") != null: continue
        var demand: Dictionary = talent.get("contract_demand", {})
        if str(demand.get("status", "unknown")) == "unknown": continue
        var range: Dictionary = demand.get("range", {})
        var high: int = int(range.get("max", 12000))
        _add(commands, _cmd(view, "command.offer_contract", {"contract_id": "contract:ADV%02d%04d" % [posmod(month, 99), _command_sequence + 1], "promotion_id": Fixture.PROMOTION_A, "person_id": talent.get("person_id"), "compensation": _contract_money(maxi(1000, int(round(float(high) * multiplier)))), "exclusivity_id": "exclusivity.fixture", "end_date": _future_date(str(view.get("current_date")), 24)}))
        return

func _offer_all_visible_free_agents(commands: Array, view: Dictionary, month: int, multiplier: float) -> void:
    var count: int = 0
    for talent_value: Variant in view.get("external_talent", []):
        var talent: Dictionary = talent_value
        if talent.get("employer_promotion_id") != null: continue
        var demand: Dictionary = talent.get("contract_demand", {})
        if str(demand.get("status", "unknown")) == "unknown": continue
        var high: int = int((demand.get("range", {}) as Dictionary).get("max", 12000))
        _add(commands, _cmd(view, "command.offer_contract", {"contract_id": "contract:ADH%02d%03d" % [posmod(month, 99), count], "promotion_id": Fixture.PROMOTION_A, "person_id": talent.get("person_id"), "compensation": _contract_money(int(round(float(high) * multiplier))), "exclusivity_id": "exclusivity.fixture", "end_date": _future_date(str(view.get("current_date")), 36)}))
        count += 1

func _maybe_violate(commands: Array, view: Dictionary) -> void:
    for agreement_value: Variant in view.get("agreements", []):
        var agreement: Dictionary = agreement_value
        if str(agreement.get("status")) != "active" or not Fixture.PROMOTION_A in (agreement.get("party_promotion_ids", []) as Array): continue
        for clause_value: Variant in agreement.get("clauses", []):
            if not clause_value is Dictionary: continue
            var clause: Dictionary = clause_value
            if str(clause.get("protected_promotion_id", "")) == Fixture.PROMOTION_A: continue
            var markets: Array = clause.get("market_ids", [])
            if not markets.is_empty():
                _add(commands, _cmd(view, "command.violate_territory", {"agreement_id": agreement.get("agreement_id"), "violator_promotion_id": Fixture.PROMOTION_A, "market_id": markets[0]}))
                return

func _best_market(view: Dictionary, weakest: bool) -> String:
    var selected: String = ""
    var selected_score: float = INF if weakest else -INF
    for market_id: Variant in (view.get("markets", {}) as Dictionary).keys():
        var market: Dictionary = (view.get("markets", {}) as Dictionary)[market_id]
        var inf: Dictionary = (market.get("influence_by_promotion", {}) as Dictionary).get(Fixture.PROMOTION_A, {})
        var own: float = float(inf.get("audience", 0.0)) * 0.4 + float(inf.get("media", 0.0)) * 0.25 + float(inf.get("business", 0.0)) * 0.25 + float(inf.get("infrastructure", 0.0)) * 0.1
        var score: float = float(market.get("wrestling_interest", 0.0)) * float(market.get("economic_strength", 0.0)) - own * (0.6 if weakest else 0.15)
        if (weakest and score < selected_score) or (not weakest and score > selected_score): selected = str(market_id); selected_score = score
    return selected

func _validate_player_view(view: Dictionary) -> Dictionary:
    var errors: Array = []
    for talent_value: Variant in view.get("external_talent", []):
        if not talent_value is Dictionary: continue
        var talent: Dictionary = talent_value
        for forbidden: String in ["skills", "traits", "career", "health", "true_value", "potential"]:
            if talent.has(forbidden): errors.append({"code": "KNOWLEDGE_LEAK", "person_id": talent.get("person_id"), "field": forbidden})
        for field: String in ["performance", "local_value", "contract_demand"]:
            var projection: Variant = talent.get(field)
            if not projection is Dictionary: errors.append({"code": "KNOWLEDGE_LEAK", "person_id": talent.get("person_id"), "field": field, "reason": "projection_object_required"})
            elif (projection as Dictionary).has("true_value"): errors.append({"code": "KNOWLEDGE_LEAK", "person_id": talent.get("person_id"), "field": field, "reason": "true_value_exposed"})
    return {"passed": errors.is_empty(), "errors": errors}

func _save_roundtrip(run_id: String, state: RefCounted, chronicle: RefCounted, state_codec: RefCounted, chronicle_codec: RefCounted) -> Dictionary:
    var service: RefCounted = SaveService.new()
    service.set("root_path", "user://f2g_adversarial_saves")
    var save_id: String = run_id.replace("_", "-")
    var saved: Dictionary = service.call("save", save_id, run_id, state, chronicle, {"created_utc": "f2g-deterministic", "updated_utc": "f2g-deterministic"})
    if not bool(saved.get("passed", false)): return saved
    var loaded: Dictionary = service.call("load_save", save_id, str(state.get("content_fingerprint")))
    if not bool(loaded.get("passed", false)): return loaded
    var encoded_before_chronicle: Dictionary = chronicle_codec.call("encode", chronicle)
    var encoded_after_chronicle: Dictionary = chronicle_codec.call("encode", loaded.get("chronicle"))
    var same_state: bool = _semantic_equal(state_codec.call("encode", state), state_codec.call("encode", loaded.get("state")))
    var same_chronicle: bool = _semantic_equal(encoded_before_chronicle, encoded_after_chronicle)
    var seat_ok: bool = not ((loaded.get("state").get("ownership_seat") as RefCounted).call("to_dict") as Dictionary).has("owner_person_id")
    return {"passed": same_state and same_chronicle and seat_ok, "errors": [] if same_state and same_chronicle and seat_ok else [{"code": "SAVE_ROUNDTRIP_MISMATCH", "same_state": same_state, "same_chronicle": same_chronicle, "seat_ok": seat_ok, "first_chronicle_difference": _first_difference(encoded_before_chronicle, encoded_after_chronicle)}]}

func _semantic_equal(left: Variant, right: Variant) -> bool:
    if (left is int or left is float) and (right is int or right is float): return absf(float(left) - float(right)) <= 0.000000000001
    if left is Dictionary and right is Dictionary:
        if (left as Dictionary).size() != (right as Dictionary).size(): return false
        for key: Variant in (left as Dictionary).keys():
            if not (right as Dictionary).has(key) or not _semantic_equal((left as Dictionary)[key], (right as Dictionary)[key]): return false
        return true
    if left is Array and right is Array:
        if (left as Array).size() != (right as Array).size(): return false
        for i: int in range((left as Array).size()):
            if not _semantic_equal((left as Array)[i], (right as Array)[i]): return false
        return true
    return left == right

func _first_difference(left: Variant, right: Variant, path: String = "root") -> Dictionary:
    if (left is int or left is float) and (right is int or right is float):
        if float(left) != float(right): return {"path": path, "left": left, "right": right, "delta": absf(float(left) - float(right))}
        return {}
    if typeof(left) != typeof(right): return {"path": path, "left": left, "right": right, "left_type": typeof(left), "right_type": typeof(right)}
    if left is Dictionary and right is Dictionary:
        for key: Variant in (left as Dictionary).keys():
            if not (right as Dictionary).has(key): return {"path": path + "." + str(key), "left": (left as Dictionary)[key], "right": "<missing>"}
            var child: Dictionary = _first_difference((left as Dictionary)[key], (right as Dictionary)[key], path + "." + str(key)); if not child.is_empty(): return child
        for key: Variant in (right as Dictionary).keys():
            if not (left as Dictionary).has(key): return {"path": path + "." + str(key), "left": "<missing>", "right": (right as Dictionary)[key]}
        return {}
    if left is Array and right is Array:
        if (left as Array).size() != (right as Array).size(): return {"path": path + ".size", "left": (left as Array).size(), "right": (right as Array).size()}
        for i: int in range((left as Array).size()):
            var child: Dictionary = _first_difference((left as Array)[i], (right as Array)[i], path + "[" + str(i) + "]"); if not child.is_empty(): return child
        return {}
    if left != right: return {"path": path, "left": left, "right": right}
    return {}

func _month_metric(state: RefCounted, result: RefCounted, month: int, cash: int) -> Dictionary:
    var outputs: Dictionary = result.get("phase_outputs")
    var shows: int = 0
    for show_value: Variant in outputs.get("show_results", []):
        if str((show_value as RefCounted).get("promotion_id")) == Fixture.PROMOTION_A: shows += 1
    return {"month": month, "date": state.get("current_date"), "cash_minor_units": cash, "financial_stress": float((state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(Fixture.PROMOTION_A, 0.0)), "active_contracts": (((state.get("promotions") as Dictionary)[Fixture.PROMOTION_A] as RefCounted).get("contract_ids") as Array).size(), "shows": shows, "max_market_concentration": _max_concentration(state), "chronicle_head_sequence": result.get("chronicle").get("head_sequence")}

func _aggregate(months: int, seeds: Array[int], profiles: Array[String], runs: Array[Dictionary], errors: Array) -> Dictionary:
    var deterministic: bool = true
    var divergent: bool = true
    var by_profile: Dictionary = {}
    for profile: String in profiles:
        var profile_runs: Array = []
        var by_seed: Dictionary = {}
        var unique: Dictionary = {}
        for run: Dictionary in runs:
            if str(run.get("policy_id")) != profile: continue
            profile_runs.append(run)
            var seed_key: String = str(run.get("seed")); if not by_seed.has(seed_key): by_seed[seed_key] = {}
            by_seed[seed_key][str(run.get("world_fingerprint"))] = true; unique[str(run.get("world_fingerprint"))] = true
        for values: Variant in by_seed.values():
            if (values as Dictionary).size() != 1: deterministic = false
        if unique.size() < mini(2, by_seed.size()): divergent = false
        by_profile[profile] = {"runs": profile_runs.size(), "unique_fingerprints": unique.size(), "final_cash_range": _cash_range(profile_runs), "all_passed": _all_passed(profile_runs), "max_month_cash_delta": _profile_max_delta(profile_runs)}
    var passed: bool = errors.is_empty() and deterministic and divergent and runs.size() == profiles.size() * seeds.size()
    return {"schema": "we.f2g.adversarial_matrix.v1", "package_id": PACKAGE_ID, "baseline_commit": "20ddeaa45bfdbfce98be066cdc13d656d5d6363a", "engine_expected": ProjectVersion.ENGINE_VERSION, "policy_version": POLICY_VERSION, "profiles": profiles, "seeds": seeds, "months_per_run": months, "run_count": runs.size(), "passed": passed, "same_seed_deterministic": deterministic, "varied_seeds_diverge": divergent, "errors": errors, "by_profile": by_profile, "runs": runs}

func _cash_range(runs: Array) -> Dictionary:
    if runs.is_empty(): return {}
    var lo: int = 9223372036854775807; var hi: int = -9223372036854775807
    for r: Dictionary in runs: lo = mini(lo, int(r.get("final_cash_minor_units", 0))); hi = maxi(hi, int(r.get("final_cash_minor_units", 0)))
    return {"min": lo, "max": hi}

func _profile_max_delta(runs: Array) -> int:
    var maximum: int = 0
    for r: Dictionary in runs: maximum = maxi(maximum, int(r.get("max_abs_month_cash_delta", 0)))
    return maximum

func _all_passed(runs: Array) -> bool:
    for r: Dictionary in runs:
        if not bool(r.get("passed", false)): return false
    return true

func _active_promotions(state: RefCounted) -> int:
    var count: int = 0
    for p: Variant in (state.get("promotions") as Dictionary).values():
        if str((p as RefCounted).get("lifecycle")) == "active": count += 1
    return count

func _max_concentration(state: RefCounted) -> float:
    var maximum: float = 0.0
    for market_value: Variant in (state.get("markets") as Dictionary).values():
        for inf_value: Variant in ((market_value as RefCounted).get("influence_by_promotion") as Dictionary).values():
            var v: Dictionary = inf_value
            maximum = maxf(maximum, float(v.get("audience", 0.0)) * 0.4 + float(v.get("media", 0.0)) * 0.25 + float(v.get("business", 0.0)) * 0.25 + float(v.get("infrastructure", 0.0)) * 0.1)
    return maximum

func _money(minor: int) -> Dictionary: return {"minor_units": minor, "currency_id": "currency.fixture"}
func _contract_money(minor: int) -> Dictionary: return {"base": _money(minor)}

func _future_date(date: String, months: int) -> String:
    var parts: PackedStringArray = date.split("-"); var y: int = int(parts[0]); var m: int = int(parts[1]) - 1 + months; y += m / 12; m = posmod(m, 12) + 1
    return "%04d-%02d-01" % [y, m]

func _months_between(a: String, b: String) -> int:
    var ap: PackedStringArray = a.split("-"); var bp: PackedStringArray = b.split("-")
    return (int(bp[0]) - int(ap[0])) * 12 + int(bp[1]) - int(ap[1])

func _hash(value: Dictionary) -> String:
    var ctx: HashingContext = HashingContext.new(); ctx.start(HashingContext.HASH_SHA256); ctx.update(JSON.stringify(value, "", true, true).to_utf8_buffer()); return ctx.finish().hex_encode()

func _write_json(path: String, value: Dictionary) -> bool:
    var abs: String = ProjectSettings.globalize_path(path); DirAccess.make_dir_recursive_absolute(abs.get_base_dir()); var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE)
    if f == null: return false
    f.store_string(JSON.stringify(value, "  ", true, true) + "\n"); f.close(); return true

func _write_jsonl(path: String, rows: Array) -> bool:
    var abs: String = ProjectSettings.globalize_path(path); DirAccess.make_dir_recursive_absolute(abs.get_base_dir()); var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE)
    if f == null: return false
    for row: Variant in rows: f.store_line(JSON.stringify(row))
    f.close(); return true

func _write_run_markdown(path: String, s: Dictionary) -> void:
    var text: String = "# F→G adversarial run: %s / seed %s\n\n- Passed: **%s**\n- Months: %s/%s\n- Final cash: %s\n- Player commands accepted/rejected: %s/%s\n- Same run fingerprint: `%s`\n- Chronicle: `%s`\n- Errors: `%s`\n" % [s.get("policy_id"), s.get("seed"), s.get("passed"), s.get("months_completed"), s.get("months_requested"), s.get("final_cash_minor_units"), s.get("accepted_player_commands"), s.get("rejected_player_commands"), s.get("world_fingerprint"), JSON.stringify(s.get("chronicle_counts")), JSON.stringify(s.get("errors"))]
    var abs: String = ProjectSettings.globalize_path(path); var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE); if f != null: f.store_string(text); f.close()

func _write_run_log(path: String, s: Dictionary, checks: Array) -> void:
    var abs: String = ProjectSettings.globalize_path(path); var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE); if f == null: return
    f.store_line("package=%s policy=%s seed=%s months=%s passed=%s" % [PACKAGE_ID, s.get("policy_id"), s.get("seed"), s.get("months_completed"), s.get("passed")])
    for c: Variant in checks: f.store_line(JSON.stringify(c))
    f.close()

func _write_matrix_markdown(path: String, s: Dictionary) -> void:
    var text: String = "# F→G Adversarial Matrix Summary\n\n- Package: `%s`\n- Baseline: `%s`\n- Passed: **%s**\n- Runs: %s\n- Months per run: %s\n- Same-seed deterministic: **%s**\n- Varied seeds diverge: **%s**\n\n| Profile | Runs | All pass | Unique fingerprints | Final cash range | Max month cash delta |\n|---|---:|---|---:|---|---:|\n" % [s.get("package_id"), s.get("baseline_commit"), s.get("passed"), s.get("run_count"), s.get("months_per_run"), s.get("same_seed_deterministic"), s.get("varied_seeds_diverge")]
    for p: String in s.get("profiles", []):
        var r: Dictionary = s.get("by_profile", {}).get(p, {}); text += "| %s | %s | %s | %s | %s | %s |\n" % [p, r.get("runs"), r.get("all_passed"), r.get("unique_fingerprints"), JSON.stringify(r.get("final_cash_range")), r.get("max_month_cash_delta")]
    var abs: String = ProjectSettings.globalize_path(path); var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE); if f != null: f.store_string(text); f.close()

func _parse_args(args: PackedStringArray) -> Dictionary:
    var out: Dictionary = {}
    for a: String in args:
        if a.begins_with("--months="): out["months"] = int(a.trim_prefix("--months="))
        elif a.begins_with("--seeds="): out["seeds"] = a.trim_prefix("--seeds=")
        elif a.begins_with("--output="): out["output"] = a.trim_prefix("--output=")
        elif a.begins_with("--profile="): out["profile"] = a.trim_prefix("--profile=")
    return out

func _parse_seeds(text: String) -> Array[int]:
    var out: Array[int] = []
    for p: String in text.split(","):
        if not p.strip_edges().is_empty(): out.append(int(p.strip_edges()))
    return out
