extends RefCounted

const KnowledgeQueryService = preload("res://app/queries/knowledge_query_service.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const KnowledgeBase = preload("res://domain/knowledge/knowledge_base.gd")

var _knowledge_query: RefCounted = KnowledgeQueryService.new()
var _chronicle_query: RefCounted = ChronicleQueryService.new()

func build(state: RefCounted, chronicle: RefCounted, registry: RefCounted) -> Dictionary:
    var controlled_promotion_id: String = str((state.get("ownership_seat") as RefCounted).get("promotion_id"))
    var controlled_promotion: RefCounted = (state.get("promotions") as Dictionary).get(controlled_promotion_id)
    if controlled_promotion == null:
        return {"passed": false, "errors": [{"code": "REF001", "path": "ownership_seat.promotion_id"}]}
    var knowledge_base: RefCounted = (state.get("knowledge_bases") as Dictionary).get(controlled_promotion_id)
    var market_records: Dictionary = _records_by_id(registry, "markets")
    var region_records: Dictionary = _records_by_id(registry, "regions")
    var outlet_records: Dictionary = _records_by_id(registry, "media_outlets")
    var championship_records: Dictionary = _records_by_id(registry, "championships")
    var map_records: Array[Dictionary] = registry.call("get_family", "map")

    return {
        "passed": true,
        "errors": [],
        "date": str(state.get("current_date")),
        "turn_number": int(state.get("turn_number")),
        "ownership": {
            "label": "Ownership",
            "promotion_id": controlled_promotion_id,
            "promotion_name": str(controlled_promotion.get("brand_name")),
        },
        "promotion": _promotion_view(state, controlled_promotion_id),
        "markets": _market_views(state, controlled_promotion_id, knowledge_base, market_records, region_records),
        "connections": _connection_views(map_records),
        "touring": _touring_views(state, controlled_promotion_id, knowledge_base, market_records),
        "roster": _roster_views(state, controlled_promotion_id, market_records),
        "programs": _program_views(state, controlled_promotion_id),
        "championships": _championship_views(state, controlled_promotion_id, championship_records),
        "media": _media_views(state, controlled_promotion_id, outlet_records),
        "recent_history": _recent_history(state, chronicle, controlled_promotion_id, market_records, 14),
        "history_dates": _history_dates(chronicle),
        "attention": _attention(state, controlled_promotion_id),
    }

func historical(state: RefCounted, chronicle: RefCounted, registry: RefCounted, target_date: String) -> Dictionary:
    var current_promotion_id: String = str((state.get("ownership_seat") as RefCounted).get("promotion_id"))
    var result: Dictionary = _chronicle_query.call("get_projection", chronicle, target_date)
    if not bool(result.get("passed", false)):
        return result
    var projection: Dictionary = result.get("projection", {})
    var historical_seat: Dictionary = projection.get("ownership_seat", {})
    var historical_promotion_id: String = str(historical_seat.get("promotion_id", current_promotion_id))
    var promotion_data: Dictionary = (projection.get("promotions", {}) as Dictionary).get(historical_promotion_id, {})
    var historical_knowledge: Dictionary = (projection.get("knowledge", {}) as Dictionary).get(historical_promotion_id, {})
    var knowledge_base: RefCounted = KnowledgeBase.new()
    knowledge_base.set("owner_promotion_id", historical_promotion_id)
    knowledge_base.set("observations", (historical_knowledge.get("observations", []) as Array).duplicate(true))
    knowledge_base.set("familiarity_by_subject", (historical_knowledge.get("familiarity_by_subject", {}) as Dictionary).duplicate(true))
    var market_records: Dictionary = _records_by_id(registry, "markets")
    var market_views: Array[Dictionary] = []
    var historical_markets: Dictionary = projection.get("markets", {})
    var historical_promotions: Dictionary = projection.get("promotions", {})
    var promotion_ids: Array[String] = []
    for promotion_id_value: Variant in historical_promotions.keys(): promotion_ids.append(str(promotion_id_value))
    promotion_ids.sort()
    for market_id_value: Variant in historical_markets.keys():
        var market_id: String = str(market_id_value)
        var market_data: Dictionary = historical_markets[market_id]
        var market_record: Dictionary = market_records.get(market_id, {})
        var rivals: Array[Dictionary] = []
        for promotion_id: String in promotion_ids:
            if promotion_id == historical_promotion_id: continue
            var estimate: Dictionary = _knowledge_query.call("project_field", knowledge_base, market_id, _rival_influence_field(promotion_id)).call("to_dict")
            if str(estimate.get("status", "unknown")) != "unknown":
                rivals.append(_estimate_view(promotion_id, str((historical_promotions.get(promotion_id, {}) as Dictionary).get("brand_name", "Rival promotion")), estimate))
        market_views.append({
            "market_id": market_id,
            "name": str(market_record.get("display_name", market_id)),
            "interest_signal": _signal(float(market_data.get("wrestling_interest", 0.0))),
            "own_presence": _composite_from_dict((market_data.get("influence_by_promotion", {}) as Dictionary).get(historical_promotion_id, {})),
            "rival_presence": rivals,
            "hot_state": _hot_label(market_data.get("current_hot_state", null)),
        })
    market_views.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name")) < str(b.get("name")))
    return {
        "passed": true,
        "errors": [],
        "date": target_date,
        "ownership": {"label": "Ownership", "promotion_id": historical_promotion_id, "promotion_name": str(promotion_data.get("brand_name", ""))},
        "promotion": {
            "promotion_id": historical_promotion_id,
            "name": str(promotion_data.get("brand_name", "")),
            "cash": (promotion_data.get("cash", {}) as Dictionary).duplicate(true),
            "prestige": float(promotion_data.get("prestige", 0.0)),
            "momentum": float(promotion_data.get("momentum", 0.0)),
            "financial_stress": float(promotion_data.get("financial_stress", 0.0)),
        },
        "markets": market_views,
    }

func market_by_id(view: Dictionary, market_id: String) -> Dictionary:
    for market: Dictionary in view.get("markets", []):
        if str(market.get("market_id", "")) == market_id:
            return market.duplicate(true)
    return {}

func _promotion_view(state: RefCounted, promotion_id: String) -> Dictionary:
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
    var booker_id: String = str(((state.get("world_state") as Dictionary).get("booker_by_promotion", {}) as Dictionary).get(promotion_id, ""))
    var booker_name: String = "Unassigned"
    if (state.get("people") as Dictionary).has(booker_id):
        booker_name = str(((state.get("people") as Dictionary)[booker_id] as RefCounted).get("display_name"))
    return {
        "promotion_id": promotion_id,
        "name": str(promotion.get("brand_name")),
        "cash": (promotion.get("cash") as Dictionary).duplicate(true),
        "prestige": float(promotion.get("prestige")),
        "momentum": float(promotion.get("momentum")),
        "morale": float(promotion.get("locker_room_morale")),
        "financial_stress": float(((state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}) as Dictionary).get(promotion_id, 0.0)),
        "booker_person_id": booker_id,
        "booker_name": booker_name,
        "hot_state": _hot_label(promotion.get("current_hot_state")),
    }

func _market_views(state: RefCounted, controlled_id: String, knowledge_base: RefCounted, records: Dictionary, region_records: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var promotion_ids: Array[String] = []
    for promotion_id_value: Variant in (state.get("promotions") as Dictionary).keys(): promotion_ids.append(str(promotion_id_value))
    promotion_ids.sort()
    for market_id_value: Variant in (state.get("markets") as Dictionary).keys():
        var market_id: String = str(market_id_value)
        var market: RefCounted = (state.get("markets") as Dictionary)[market_id]
        var record: Dictionary = records.get(market_id, {})
        var region_id: String = str(record.get("region_id", ""))
        var rivals: Array[Dictionary] = []
        if knowledge_base != null:
            for rival_id: String in promotion_ids:
                if rival_id == controlled_id: continue
                var projection: Dictionary = _knowledge_query.call("project_field", knowledge_base, market_id, _rival_influence_field(rival_id)).call("to_dict")
                if str(projection.get("status", "unknown")) != "unknown":
                    var rival: RefCounted = (state.get("promotions") as Dictionary)[rival_id]
                    rivals.append(_estimate_view(rival_id, str(rival.get("brand_name")), projection))
        output.append({
            "market_id": market_id,
            "name": str(record.get("display_name", market_id)),
            "region_id": region_id,
            "region_name": str((region_records.get(region_id, {}) as Dictionary).get("display_name", region_id)),
            "coordinates": _coordinates(record, output.size()),
            "interest_signal": _signal(float(market.get("wrestling_interest"))),
            "economic_signal": _signal(float(market.get("economic_strength"))),
            "own_presence": _influence_composite(market, controlled_id),
            "rival_presence": rivals,
            "hot_state": _hot_label(market.get("current_hot_state")),
            "is_home_market": market_id in (((state.get("promotions") as Dictionary)[controlled_id] as RefCounted).get("home_market_ids") as Array),
        })
    output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name")) < str(b.get("name")))
    return output

func _touring_views(state: RefCounted, controlled_id: String, knowledge_base: RefCounted, market_records: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for company_id_value: Variant in (state.get("touring_companies") as Dictionary).keys():
        var company_id: String = str(company_id_value)
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
        var promotion_id: String = str(company.get("promotion_id"))
        var own: bool = promotion_id == controlled_id
        if own:
            output.append({
                "company_id": company_id,
                "promotion_id": promotion_id,
                "promotion_name": str(((state.get("promotions") as Dictionary)[promotion_id] as RefCounted).get("brand_name")),
                "name": str(company.get("name")),
                "ownership": "controlled",
                "route": _route_view(company.get("route"), market_records),
                "budget": (company.get("monthly_budget") as Dictionary).duplicate(true),
                "fatigue_pressure": float(company.get("fatigue_pressure")),
                "cohesion": float(company.get("cohesion")),
                "person_assignment_ids": (company.get("person_assignment_ids") as Array).duplicate(),
                "directives": (company.get("directives") as Array).duplicate(true),
            })
        elif knowledge_base != null:
            var route_projection: Dictionary = _knowledge_query.call("project_field", knowledge_base, company_id, "touring.route").call("to_dict")
            if str(route_projection.get("status", "unknown")) != "unknown":
                var route: Array = route_projection.get("value", []) if str(route_projection.get("status")) == "known" else []
                output.append({
                    "company_id": company_id,
                    "promotion_id": promotion_id,
                    "promotion_name": str(((state.get("promotions") as Dictionary)[promotion_id] as RefCounted).get("brand_name")),
                    "name": "Observed touring company",
                    "ownership": "observed",
                    "route": _route_view(route, market_records),
                    "confidence": route_projection.get("confidence"),
                    "observed_on": route_projection.get("observed_on"),
                })
    output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if str(a.get("ownership")) != str(b.get("ownership")): return str(a.get("ownership")) < str(b.get("ownership"))
        return str(a.get("promotion_name")) < str(b.get("promotion_name"))
    )
    return output

func _roster_views(state: RefCounted, controlled_id: String, market_records: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var controlled: RefCounted = (state.get("promotions") as Dictionary)[controlled_id]
    for contract_id_value: Variant in controlled.get("contract_ids"):
        var contract_id: String = str(contract_id_value)
        if not (state.get("contracts") as Dictionary).has(contract_id): continue
        var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
        if str(contract.get("status")) != "active": continue
        var person_id: String = str(contract.get("person_id"))
        var person: RefCounted = (state.get("people") as Dictionary)[person_id]
        var audiences: Array[Dictionary] = []
        for market_id: String in (person.get("audience_by_market") as Dictionary).keys():
            var local: Dictionary = (person.get("audience_by_market") as Dictionary)[market_id]
            audiences.append({"market_id": market_id, "market_name": str((market_records.get(market_id, {}) as Dictionary).get("display_name", market_id)), "overness": float(local.get("overness", 0.0)), "momentum": float(local.get("momentum", 0.0)), "heat": float(local.get("heat", 0.0)), "shine": float(local.get("shine", 0.0))})
        output.append({
            "person_id": person_id,
            "name": str(person.get("display_name")),
            "roles": (person.get("roles") as Array).duplicate(true),
            "contract_id": contract_id,
            "contract_end": contract.get("end_date"),
            "compensation": (contract.get("compensation") as Dictionary).duplicate(true),
            "health_status": str((person.get("health") as Dictionary).get("status", "available")),
            "audience": audiences,
            "hot_state": _hot_label(person.get("current_hot_state")),
        })
    output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name")) < str(b.get("name")))
    return output

func _program_views(state: RefCounted, controlled_id: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for program_id_value: Variant in ((state.get("promotions") as Dictionary)[controlled_id] as RefCounted).get("program_ids"):
        var program_id: String = str(program_id_value)
        if not (state.get("programs") as Dictionary).has(program_id): continue
        var program: RefCounted = (state.get("programs") as Dictionary)[program_id]
        output.append({
            "program_id": program_id,
            "status": str(program.get("status")),
            "side_a": _person_names(state, (program.get("side_a") as Dictionary).get("person_ids", [])),
            "side_b": _person_names(state, (program.get("side_b") as Dictionary).get("person_ids", [])),
            "purpose_id": str(program.get("purpose_id")),
            "phase_id": str(program.get("phase_id")),
            "heat": float(program.get("heat")),
            "momentum": float(program.get("momentum")),
            "objective_ids": (program.get("objective_ids") as Array).duplicate(),
        })
    return output

func _championship_views(state: RefCounted, controlled_id: String, records: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for title_id_value: Variant in ((state.get("promotions") as Dictionary)[controlled_id] as RefCounted).get("championship_ids"):
        var title_id: String = str(title_id_value)
        var title: RefCounted = (state.get("championships") as Dictionary).get(title_id)
        if title == null: continue
        output.append({
            "championship_id": title_id,
            "name": str((records.get(str(title.get("definition_id")), {}) as Dictionary).get("display_name", title.get("definition_id"))),
            "holder_names": _person_names(state, title.get("holder_person_ids")),
            "prestige": float(title.get("prestige")),
        })
    return output

func _media_views(state: RefCounted, controlled_id: String, outlets: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for deal_id_value: Variant in ((state.get("promotions") as Dictionary)[controlled_id] as RefCounted).get("media_deal_ids"):
        var deal_id: String = str(deal_id_value)
        var deal: RefCounted = (state.get("media_deals") as Dictionary).get(deal_id)
        if deal == null: continue
        output.append({
            "deal_id": deal_id,
            "outlet_name": str((outlets.get(str(deal.get("outlet_id")), {}) as Dictionary).get("display_name", deal.get("outlet_id"))),
            "medium_id": str(deal.get("medium_id")),
            "reach_market_ids": (deal.get("reach_market_ids") as Array).duplicate(),
        })
    return output

func _recent_history(state: RefCounted, chronicle: RefCounted, controlled_id: String, market_records: Dictionary, limit: int) -> Array[Dictionary]:
    var visible_ids: Dictionary = {controlled_id: true}
    var controlled: RefCounted = (state.get("promotions") as Dictionary)[controlled_id]
    for index_field: String in ["contract_ids", "touring_company_ids", "championship_ids", "program_ids", "media_deal_ids", "agreement_ids"]:
        for value: Variant in controlled.get(index_field): visible_ids[str(value)] = true
    for contract_id_value: Variant in controlled.get("contract_ids"):
        var contract_id: String = str(contract_id_value)
        if (state.get("contracts") as Dictionary).has(contract_id): visible_ids[str(((state.get("contracts") as Dictionary)[contract_id] as RefCounted).get("person_id"))] = true
    var output: Array[Dictionary] = []
    var journal: Array = chronicle.get("event_journal")
    for index: int in range(journal.size() - 1, -1, -1):
        var event: Dictionary = journal[index]
        var visible: bool = false
        for entity_id: Variant in event.get("entity_ids", []):
            if visible_ids.has(str(entity_id)):
                visible = true; break
        if not visible: continue
        var market_id: String = str(event.get("market_id", "")) if event.get("market_id") != null else ""
        output.append({
            "event_id": str(event.get("event_id", "")),
            "date": str(event.get("occurred_on", "")),
            "event_type": str(event.get("event_type", "")),
            "severity": str(event.get("severity", "routine")),
            "category": str(event.get("category", "simulation")),
            "market_id": market_id,
            "market_name": str((market_records.get(market_id, {}) as Dictionary).get("display_name", market_id)) if not market_id.is_empty() else "",
            "entity_names": _entity_names(state, event.get("entity_ids", [])),
        })
        if output.size() >= limit: break
    return output

func _history_dates(chronicle: RefCounted) -> Array[String]:
    var dates: Dictionary = {}
    for checkpoint: Dictionary in chronicle.get("checkpoints"): dates[str(checkpoint.get("date", ""))] = true
    for delta: Dictionary in chronicle.get("deltas"): dates[str(delta.get("date", ""))] = true
    var output: Array[String] = []
    for value: Variant in dates.keys():
        if not str(value).is_empty(): output.append(str(value))
    output.sort()
    output.reverse()
    return output

func _attention(state: RefCounted, controlled_id: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[controlled_id]
    var stress: float = float(((state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}) as Dictionary).get(controlled_id, 0.0))
    if stress >= 0.5:
        output.append({"kind": "risk", "title": "Financial pressure", "detail": "Operating stress is elevated; spending and routing deserve attention."})
    if int((promotion.get("cash") as Dictionary).get("minor_units", 0)) < 300000:
        output.append({"kind": "risk", "title": "Cash is tight", "detail": "The office has limited room for an expensive month."})
    for company_id: Variant in promotion.get("touring_company_ids"):
        var company: RefCounted = (state.get("touring_companies") as Dictionary).get(str(company_id))
        if company != null and float(company.get("fatigue_pressure")) >= 0.55:
            output.append({"kind": "risk", "title": "Touring fatigue", "detail": str(company.get("name")) + " is carrying significant fatigue pressure."})
    if output.is_empty():
        output.append({"kind": "status", "title": "No blocking issues", "detail": "The office can advance the month now, or adjust the current strategy first."})
    return output

func _connection_views(map_records: Array[Dictionary]) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    if map_records.is_empty(): return output
    for value: Variant in map_records[0].get("connections", []):
        if not value is Dictionary: continue
        var connection: Dictionary = value
        output.append({"from_market_id": str(connection.get("from_market_id", "")), "to_market_id": str(connection.get("to_market_id", "")), "distance_km": int(connection.get("base_distance_km", 0)), "time_minutes": int(connection.get("base_time_minutes", 0))})
    return output

func _records_by_id(registry: RefCounted, family: String) -> Dictionary:
    var output: Dictionary = {}
    for record: Dictionary in registry.call("get_family", family): output[str(record.get("id", ""))] = record
    return output

func _coordinates(record: Dictionary, fallback_index: int) -> Dictionary:
    var coordinates: Variant = record.get("coordinates", null)
    if coordinates is Dictionary and (coordinates as Dictionary).has("x") and (coordinates as Dictionary).has("y"):
        return {"x": float((coordinates as Dictionary).get("x", 0.5)), "y": float((coordinates as Dictionary).get("y", 0.5))}
    var column: int = fallback_index % 5
    var row: int = fallback_index / 5
    return {"x": 0.12 + column * 0.19, "y": 0.18 + row * 0.28}

func _route_view(route_value: Variant, market_records: Dictionary) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    if not route_value is Array: return output
    for stop_value: Variant in route_value:
        if not stop_value is Dictionary: continue
        var market_id: String = str((stop_value as Dictionary).get("market_id", ""))
        output.append({"market_id": market_id, "market_name": str((market_records.get(market_id, {}) as Dictionary).get("display_name", market_id))})
    return output

func _estimate_view(promotion_id: String, promotion_name: String, projection: Dictionary) -> Dictionary:
    return {
        "promotion_id": promotion_id,
        "promotion_name": promotion_name,
        "status": str(projection.get("status", "unknown")),
        "estimate_range": (projection.get("estimate_range") as Dictionary).duplicate(true) if projection.get("estimate_range") is Dictionary else null,
        "qualitative": projection.get("qualitative", null),
        "confidence": projection.get("confidence", null),
        "observed_on": projection.get("observed_on", null),
    }

func _person_names(state: RefCounted, ids_value: Variant) -> Array[String]:
    var output: Array[String] = []
    if ids_value is Array:
        for value: Variant in ids_value:
            var person_id: String = str(value)
            if (state.get("people") as Dictionary).has(person_id): output.append(str(((state.get("people") as Dictionary)[person_id] as RefCounted).get("display_name")))
    return output

func _entity_names(state: RefCounted, ids_value: Variant) -> Array[String]:
    var output: Array[String] = []
    if not ids_value is Array: return output
    for value: Variant in ids_value:
        var entity_id: String = str(value)
        if (state.get("people") as Dictionary).has(entity_id): output.append(str(((state.get("people") as Dictionary)[entity_id] as RefCounted).get("display_name")))
        elif (state.get("promotions") as Dictionary).has(entity_id): output.append(str(((state.get("promotions") as Dictionary)[entity_id] as RefCounted).get("brand_name")))
        elif (state.get("touring_companies") as Dictionary).has(entity_id): output.append(str(((state.get("touring_companies") as Dictionary)[entity_id] as RefCounted).get("name")))
    return output

func _influence_composite(market: RefCounted, promotion_id: String) -> float:
    return _composite_from_dict((market.get("influence_by_promotion") as Dictionary).get(promotion_id, {}))

func _composite_from_dict(components_value: Variant) -> float:
    if not components_value is Dictionary: return 0.0
    var components: Dictionary = components_value
    return float(components.get("audience", 0.0)) * 0.40 + float(components.get("media", 0.0)) * 0.25 + float(components.get("business", 0.0)) * 0.25 + float(components.get("infrastructure", 0.0)) * 0.10

func _rival_influence_field(promotion_id: String) -> String:
    return "promotion_estimate." + promotion_id.get_slice(":", 1).to_lower()

func _signal(value: float) -> String:
    if value >= 0.72: return "Very strong"
    if value >= 0.58: return "Strong"
    if value >= 0.43: return "Steady"
    if value >= 0.28: return "Soft"
    return "Weak"

func _hot_label(value: Variant) -> String:
    if value == null: return ""
    if value is Dictionary:
        var kind: String = str((value as Dictionary).get("kind", (value as Dictionary).get("state", "")))
        if not kind.is_empty(): return kind.capitalize()
    return str(value).capitalize()
