extends SceneTree

const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")

func _init() -> void:
    var options: Dictionary = _parse_args(OS.get_cmdline_user_args())
    var years: int = maxi(1, int(options.get("years", 5)))
    var months: int = years * 12
    var seeds: Array[int] = _seeds(str(options.get("seeds", "424242,424242,424243,424244,424245,424246,424247,424248")))
    var runs: Array[Dictionary] = []
    var errors: Array = []
    for seed: int in seeds:
        var run: Dictionary = _simulate(seed, months)
        if not bool(run.get("passed", false)):
            errors.append({"seed": seed, "month_index": run.get("month_index"), "errors": run.get("errors", [])})
        runs.append(run)
    var summary: Dictionary = _aggregate(years, months, seeds, runs, errors)
    var output_path: String = str(options.get("output", ""))
    if not output_path.is_empty() and not _write(output_path, summary):
        summary["passed"] = false
        summary["errors"].append({"code": "CLI002", "path": output_path, "details": {"reason": "artifact_write_failed"}})
    print("WE_PHASE_F_SOAK_SUMMARY " + JSON.stringify(summary))
    quit(0 if bool(summary.get("passed", false)) else 1)

func _simulate(seed: int, months: int) -> Dictionary:
    # Rotate policies across promotion identities so the soak does not mistake a
    # stronger starting roster/market for an intrinsically dominant strategy.
    var state: RefCounted = Fixture.make_state(seed, posmod(seed, 3))
    var chronicle: RefCounted = Fixture.make_chronicle(12)
    var pipeline: RefCounted = MonthPipeline.new()
    var metrics: Dictionary = {"shows": {}, "decisions": {}, "events": {}, "scouting_reports": 0, "negative_cash_months": {}, "peak_stress": {}, "recovery_actions": 0, "route_changes": 0, "contested_market_months": 0}
    var routes: Dictionary = _routes(state)
    for month_index: int in range(months):
        var result: RefCounted = pipeline.call("advance_month", state, chronicle, [], Fixture.content_index())
        if not bool(result.get("passed")):
            return {"passed": false, "seed": seed, "month_index": month_index, "errors": result.get("errors")}
        state = result.get("state")
        chronicle = result.get("chronicle")
        var outputs: Dictionary = result.get("phase_outputs")
        for show_value: Variant in outputs.get("show_results", []):
            var promotion_id: String = str((show_value as RefCounted).get("promotion_id"))
            metrics["shows"][promotion_id] = int(metrics["shows"].get(promotion_id, 0)) + 1
        for decision: Dictionary in outputs.get("ai_decisions", []):
            var family: String = str((decision.get("explanation", {}) as Dictionary).get("decision_family", "unknown"))
            metrics["decisions"][family] = int(metrics["decisions"].get(family, 0)) + 1
            if family == "recovery":
                metrics["recovery_actions"] = int(metrics["recovery_actions"]) + 1
        metrics["scouting_reports"] = int(metrics["scouting_reports"]) + (outputs.get("scouting_reports", []) as Array).size()
        for event: Dictionary in result.get("events"):
            var event_type: String = str(event.get("event_type"))
            metrics["events"][event_type] = int(metrics["events"].get(event_type, 0)) + 1
        var current_routes: Dictionary = _routes(state)
        for company_id: Variant in current_routes.keys():
            if current_routes[company_id] != routes.get(company_id):
                metrics["route_changes"] = int(metrics["route_changes"]) + 1
        routes = current_routes
        metrics["contested_market_months"] = int(metrics["contested_market_months"]) + _contested_markets(state)
        for promotion_id: String in (state.get("promotions") as Dictionary).keys():
            var cash: int = int((((state.get("promotions") as Dictionary)[promotion_id] as RefCounted).get("cash") as Dictionary).get("minor_units", 0))
            if cash < 0:
                metrics["negative_cash_months"][promotion_id] = int(metrics["negative_cash_months"].get(promotion_id, 0)) + 1
            var stress: float = float((state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(promotion_id, 0.0))
            metrics["peak_stress"][promotion_id] = maxf(float(metrics["peak_stress"].get(promotion_id, 0.0)), stress)
    var final_promotions: Dictionary = {}
    var winner: String = ""
    var best_score: float = -INF
    for promotion_id: String in (state.get("promotions") as Dictionary).keys():
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
        var score: float = float((promotion.get("cash") as Dictionary).get("minor_units", 0)) + float(promotion.get("prestige")) * 1000000.0
        final_promotions[promotion_id] = {"lifecycle": promotion.get("lifecycle"), "cash_minor_units": (promotion.get("cash") as Dictionary).get("minor_units"), "prestige": promotion.get("prestige"), "momentum": promotion.get("momentum"), "active_contracts": (promotion.get("contract_ids") as Array).size(), "strategy_profile_id": promotion.get("strategy_profile_id"), "score": score}
        if score > best_score:
            best_score = score
            winner = promotion_id
    var encoded_state: Dictionary = CampaignStateCodec.new().encode(state)
    var encoded_chronicle: Dictionary = ChronicleCodec.new().encode(chronicle)
    return {"passed": true, "seed": seed, "months": months, "final_date": state.get("current_date"), "winner_promotion_id": winner, "winner_strategy": (final_promotions.get(winner, {}) as Dictionary).get("strategy_profile_id"), "world_fingerprint": _hash({"state": encoded_state, "chronicle": encoded_chronicle}), "maximum_market_concentration": _max_concentration(state), "promotions": final_promotions, "metrics": metrics, "chronicle_counts": chronicle.call("counts")}

func _aggregate(years: int, months: int, seeds: Array[int], runs: Array[Dictionary], errors: Array) -> Dictionary:
    var fingerprints: Dictionary = {}
    var fingerprints_by_seed: Dictionary = {}
    var policy_wins: Dictionary = {}
    var maximum_concentration: float = 0.0
    var survival: int = 0
    var run_metrics: Array = []
    for run: Dictionary in runs:
        if not bool(run.get("passed", false)):
            continue
        var fingerprint: String = str(run.get("world_fingerprint"))
        fingerprints[fingerprint] = true
        var seed_key: String = str(run.get("seed"))
        if not fingerprints_by_seed.has(seed_key):
            fingerprints_by_seed[seed_key] = {}
        fingerprints_by_seed[seed_key][fingerprint] = true
        var policy: String = str(run.get("winner_strategy"))
        policy_wins[policy] = int(policy_wins.get(policy, 0)) + 1
        maximum_concentration = maxf(maximum_concentration, float(run.get("maximum_market_concentration", 0.0)))
        for promotion: Dictionary in (run.get("promotions", {}) as Dictionary).values():
            if str(promotion.get("lifecycle")) == "active":
                survival += 1
        run_metrics.append({"seed": run.get("seed"), "winner_promotion_id": run.get("winner_promotion_id"), "winner_strategy": policy, "world_fingerprint": fingerprint, "maximum_market_concentration": run.get("maximum_market_concentration"), "promotions": run.get("promotions"), "metrics": run.get("metrics"), "chronicle_counts": run.get("chronicle_counts")})
    var repeat_deterministic: bool = true
    for values: Variant in fingerprints_by_seed.values():
        if (values as Dictionary).size() != 1:
            repeat_deterministic = false
    var unique_seeds: Dictionary = {}
    for seed: int in seeds:
        unique_seeds[str(seed)] = true
    return {"schema": "we.phase_f.soak.v1", "passed": errors.is_empty() and repeat_deterministic, "phase": ProjectVersion.BUILD_PHASE, "game_version": ProjectVersion.GAME_VERSION, "engine_expected": ProjectVersion.ENGINE_VERSION, "years_per_run": years, "months_per_run": months, "seeds": seeds, "run_count": runs.size(), "unique_seed_count": unique_seeds.size(), "repeated_seed_deterministic": repeat_deterministic, "distinct_world_fingerprints": fingerprints.size(), "active_promotion_endings": survival, "maximum_market_concentration": maximum_concentration, "policy_wins": policy_wins, "errors": errors, "runs": run_metrics}

func _routes(state: RefCounted) -> Dictionary:
    var output: Dictionary = {}
    for id: Variant in (state.get("touring_companies") as Dictionary).keys():
        output[str(id)] = (((state.get("touring_companies") as Dictionary)[id] as RefCounted).get("route") as Array).duplicate(true)
    return output

func _contested_markets(state: RefCounted) -> int:
    var count: int = 0
    for market_value: Variant in (state.get("markets") as Dictionary).values():
        var meaningful: int = 0
        for influence: Variant in ((market_value as RefCounted).get("influence_by_promotion") as Dictionary).values():
            if _composite(influence) >= 0.20:
                meaningful += 1
        if meaningful >= 2:
            count += 1
    return count

func _max_concentration(state: RefCounted) -> float:
    var maximum: float = 0.0
    for market_value: Variant in (state.get("markets") as Dictionary).values():
        for influence: Variant in ((market_value as RefCounted).get("influence_by_promotion") as Dictionary).values():
            maximum = maxf(maximum, _composite(influence))
    return maximum

func _composite(value: Variant) -> float:
    var v: Dictionary = value
    return float(v.get("audience", 0.0)) * 0.4 + float(v.get("media", 0.0)) * 0.25 + float(v.get("business", 0.0)) * 0.25 + float(v.get("infrastructure", 0.0)) * 0.1

func _hash(value: Variant) -> String:
    var context: HashingContext = HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    context.update(JSON.stringify(value).to_utf8_buffer())
    return context.finish().hex_encode()

func _seeds(value: String) -> Array[int]:
    var output: Array[int] = []
    for part: String in value.split(","):
        if not part.strip_edges().is_empty():
            output.append(int(part.strip_edges()))
    return output

func _parse_args(arguments: PackedStringArray) -> Dictionary:
    var output: Dictionary = {}
    for argument: String in arguments:
        if argument.begins_with("--years="):
            output["years"] = int(argument.trim_prefix("--years="))
        elif argument.begins_with("--seeds="):
            output["seeds"] = argument.trim_prefix("--seeds=")
        elif argument.begins_with("--output="):
            output["output"] = argument.trim_prefix("--output=")
    return output

func _write(path: String, value: Dictionary) -> bool:
    var absolute_base: String = ProjectSettings.globalize_path(path.get_base_dir())
    var error: Error = DirAccess.make_dir_recursive_absolute(absolute_base)
    if error != OK and error != ERR_ALREADY_EXISTS:
        return false
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(value, "  ") + "\n")
    file.close()
    return true
