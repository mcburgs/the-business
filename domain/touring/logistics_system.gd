extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

func resolve(state: RefCounted, content_index: Dictionary, tuning: Dictionary) -> Dictionary:
    var schedules: Array[Dictionary] = []
    var errors: Array[Dictionary] = []
    var turn_number: int = int(state.get("turn_number"))
    var connections: Dictionary = content_index.get("travel_connections", {})
    var companies: Dictionary = state.get("touring_companies")
    var people: Dictionary = state.get("people")
    for company_id: String in DomainIds.sorted_keys(companies):
        var company: RefCounted = companies[company_id]
        if str(company.get("status")) != "active":
            continue
        var route: Array = company.get("route")
        if route.is_empty():
            continue
        var stop_index: int = turn_number % route.size()
        var stop: Dictionary = route[stop_index] if route[stop_index] is Dictionary else {}
        var market_id: String = str(stop.get("market_id", ""))
        if market_id.is_empty() or not (state.get("markets") as Dictionary).has(market_id):
            errors.append(_error("REF001", "touring_companies[" + company_id + "].route", {"market_id": market_id}))
            continue
        var previous_market_id: String = market_id
        if route.size() > 1:
            var previous_index: int = (stop_index - 1 + route.size()) % route.size()
            if route[previous_index] is Dictionary:
                previous_market_id = str((route[previous_index] as Dictionary).get("market_id", market_id))
        var travel_index: float = _travel_index(previous_market_id, market_id, connections, tuning)
        var old_pressure: float = float(company.get("fatigue_pressure"))
        var recovery: float = float(tuning.get("fatigue_recovery", 0.08))
        var travel_gain: float = float(tuning.get("fatigue_travel_gain", 0.35)) * travel_index
        var new_pressure: float = PhaseEMath.clamp01(maxf(0.0, old_pressure - recovery) + travel_gain)
        company.set("fatigue_pressure", new_pressure)
        var available: Array[String] = []
        var unavailable: Array[String] = []
        for person_value: Variant in company.get("person_assignment_ids"):
            var person_id: String = str(person_value)
            if not people.has(person_id):
                unavailable.append(person_id)
                continue
            var person: RefCounted = people[person_id]
            var health: Dictionary = person.get("health")
            if str(health.get("status", "available")) == "available" and str(person.get("lifecycle")) == "active":
                available.append(person_id)
            else:
                unavailable.append(person_id)
        available.sort()
        unavailable.sort()
        schedules.append({
            "touring_company_id": company_id,
            "promotion_id": str(company.get("promotion_id")),
            "market_id": market_id,
            "available_person_ids": available,
            "unavailable_person_ids": unavailable,
            "travel_pressure": new_pressure,
            "travel_cost_index": travel_index,
            "route_stop_index": stop_index,
            "causal_factors": [
                {"source": "route", "market_id": market_id, "stop_index": stop_index},
                {"source": "travel", "from_market_id": previous_market_id, "travel_cost_index": travel_index},
                {"source": "fatigue", "before": old_pressure, "after": new_pressure},
            ],
        })
    return {"passed": errors.is_empty(), "errors": errors, "schedules": schedules}

func _travel_index(from_market_id: String, to_market_id: String, connections: Dictionary, tuning: Dictionary) -> float:
    if from_market_id == to_market_id:
        return float(tuning.get("same_market_travel_index", 0.05))
    var direct_key: String = from_market_id + "|" + to_market_id
    var reverse_key: String = to_market_id + "|" + from_market_id
    var edge: Variant = connections.get(direct_key, connections.get(reverse_key, null))
    if edge is Dictionary:
        return PhaseEMath.clamp01(float((edge as Dictionary).get("base_cost_index", tuning.get("default_travel_index", 0.5))))
    return PhaseEMath.clamp01(float(tuning.get("default_travel_index", 0.5)))

func _error(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}
