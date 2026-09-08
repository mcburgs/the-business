extends RefCounted

const CampaignState = preload("res://domain/core/campaign_state.gd")
const OwnershipSeatState = preload("res://domain/core/ownership_seat_state.gd")
const PersonState = preload("res://domain/people/person_state.gd")
const PromotionState = preload("res://domain/promotions/promotion_state.gd")
const MarketState = preload("res://domain/world/market_state.gd")
const RegionState = preload("res://domain/world/region_state.gd")
const VenueState = preload("res://domain/world/venue_state.gd")
const TouringCompanyState = preload("res://domain/touring/touring_company_state.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const ChampionshipState = preload("res://domain/booking/championship_state.gd")
const ProgramState = preload("res://domain/booking/program_state.gd")
const MediaDealState = preload("res://domain/media/media_deal_state.gd")
const KnowledgeBase = preload("res://domain/knowledge/knowledge_base.gd")
const RandomService = preload("res://app/session/random_service.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const ChronicleStore = preload("res://domain/chronicle/chronicle_store.gd")
const ChronicleCommitter = preload("res://domain/chronicle/chronicle_committer.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")
const SliceTuning = preload("res://app/session/slice_tuning.gd")

const CURRENCY_ID := "currency.usd"

func build(registry: RefCounted, seed: int = 424242) -> Dictionary:
    if registry == null:
        return _failure("STATE001", "registry", "A loaded ContentRegistry is required.")
    var manifest: Dictionary = registry.call("campaign_manifest")
    var promotions_seed: Array[Dictionary] = _sorted_records(registry.call("get_family", "promotions"))
    var people_seed: Array[Dictionary] = _sorted_records(registry.call("get_family", "people"))
    if promotions_seed.is_empty() or people_seed.is_empty():
        return _failure("STATE001", "content", "Campaign requires promotion and person seed records.")

    var maps: Dictionary = _runtime_id_maps(people_seed, promotions_seed, registry.call("get_family", "contracts"), registry.call("get_family", "championships"))
    var state: RefCounted = CampaignState.new()
    state.set("campaign_pack_id", str(manifest.get("pack_id", "")))
    state.set("campaign_pack_version", str(manifest.get("pack_version", "")))
    state.set("content_fingerprint", str(registry.call("fingerprint")))
    state.set("ruleset_id", str(manifest.get("ruleset_id", "")))
    state.set("current_date", str(manifest.get("start_date", "")))
    state.set("turn_number", 0)

    _build_regions(state, registry)
    _build_markets(state, registry, promotions_seed, maps)
    _build_venues(state, registry, maps)
    _build_people(state, people_seed, registry, promotions_seed, maps)
    _build_promotions(state, promotions_seed, maps)
    _build_contracts(state, registry, maps)
    _build_championships(state, registry, maps)
    _build_touring(state, promotions_seed, maps)
    _build_programs(state, promotions_seed, maps)
    _build_media_deals(state, registry, promotions_seed, maps)
    _wire_indexes(state)

    var controlled_promotion_id: String = str((maps["promotion"] as Dictionary).get(str(promotions_seed[0].get("id", "")), ""))
    var seat: RefCounted = OwnershipSeatState.new()
    seat.set("promotion_id", controlled_promotion_id)
    state.set("ownership_seat", seat)
    state.set("world_state", _world_state(state, promotions_seed, maps))
    var random: RefCounted = RandomService.new(seed)
    state.set("rng_state", random.call("capture", 0))
    _build_knowledge(state)

    var content_index: Dictionary = build_content_index(registry)
    var validation: Dictionary = CampaignStateValidator.new().call("validate", state, content_index)
    if not bool(validation.get("passed", false)):
        return {"passed": false, "state": null, "chronicle": null, "content_index": content_index, "errors": validation.get("errors", [])}

    var chronicle: RefCounted = _make_chronicle()
    var initial_events: Array[Dictionary] = []
    var committed: Dictionary = ChronicleCommitter.new().call("commit_month", chronicle, state, initial_events)
    if not bool(committed.get("passed", false)):
        return {"passed": false, "state": null, "chronicle": null, "content_index": content_index, "errors": committed.get("errors", [])}
    var chronicle_validation: Dictionary = ChronicleValidator.new().call("validate", chronicle)
    if not bool(chronicle_validation.get("passed", false)):
        return {"passed": false, "state": null, "chronicle": null, "content_index": content_index, "errors": chronicle_validation.get("errors", [])}
    return {"passed": true, "state": state, "chronicle": chronicle, "content_index": content_index, "errors": []}

func build_content_index(registry: RefCounted) -> Dictionary:
    var index: Dictionary = {}
    for family: String in registry.call("family_names"):
        var values: Dictionary = {}
        for record: Dictionary in registry.call("get_family", family):
            var content_id: String = str(record.get("id", ""))
            if not content_id.is_empty():
                values[content_id] = true
        index[family] = values
    index["phase_e_tuning"] = SliceTuning.phase_e()
    index["phase_f_tuning"] = SliceTuning.phase_f()
    index["travel_connections"] = _travel_connections(registry)
    return index

func _runtime_id_maps(people: Array[Dictionary], promotions: Array[Dictionary], contracts_value: Variant, championships_value: Variant) -> Dictionary:
    var result: Dictionary = {"person": {}, "promotion": {}, "contract": {}, "championship": {}}
    for index: int in range(people.size()):
        result["person"][str(people[index].get("id", ""))] = "person:PER" + str(index + 1).pad_zeros(5)
    for index: int in range(promotions.size()):
        result["promotion"][str(promotions[index].get("id", ""))] = "promotion:PRO" + str(index + 1).pad_zeros(5)
    var contracts: Array[Dictionary] = _sorted_records(contracts_value)
    for index: int in range(contracts.size()):
        result["contract"][str(contracts[index].get("id", ""))] = "contract:CON" + str(index + 1).pad_zeros(5)
    var championships: Array[Dictionary] = _sorted_records(championships_value)
    for index: int in range(championships.size()):
        result["championship"][str(championships[index].get("id", ""))] = "championship:CHA" + str(index + 1).pad_zeros(5)
    return result

func _build_regions(state: RefCounted, registry: RefCounted) -> void:
    var regions: Dictionary = {}
    for record: Dictionary in _sorted_records(registry.call("get_family", "regions")):
        var region: RefCounted = RegionState.new()
        region.set("region_id", str(record.get("id", "")))
        regions[region.get("region_id")] = region
    state.set("regions", regions)

func _build_markets(state: RefCounted, registry: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var markets: Dictionary = {}
    var promotion_map: Dictionary = maps["promotion"]
    var market_records: Array[Dictionary] = _sorted_records(registry.call("get_family", "markets"))
    for index: int in range(market_records.size()):
        var record: Dictionary = market_records[index]
        var market_id: String = str(record.get("id", ""))
        var market: RefCounted = MarketState.new()
        market.set("market_id", market_id)
        market.set("wrestling_interest", clampf(0.52 + float((index * 7) % 13) * 0.015, 0.0, 1.0))
        market.set("economic_strength", clampf(0.48 + float((index * 5) % 11) * 0.02, 0.0, 1.0))
        var influence: Dictionary = {}
        for promotion_seed: Dictionary in promotion_seeds:
            var promotion_id: String = str(promotion_map.get(str(promotion_seed.get("id", "")), ""))
            var home_markets: Array = promotion_seed.get("home_market_ids", [])
            var is_home: bool = market_id in home_markets
            var base: float = 0.58 if is_home else 0.16 + float((index + promotion_id.hash()) % 11) * 0.012
            influence[promotion_id] = {
                "audience": clampf(base, 0.0, 1.0),
                "media": clampf(base - (0.10 if is_home else 0.03), 0.0, 1.0),
                "business": clampf(base - (0.06 if is_home else 0.02), 0.0, 1.0),
                "infrastructure": clampf(base - (0.18 if is_home else 0.06), 0.0, 1.0),
            }
        market.set("influence_by_promotion", influence)
        markets[market_id] = market
    state.set("markets", markets)

func _build_venues(state: RefCounted, registry: RefCounted, maps: Dictionary) -> void:
    var venues: Dictionary = {}
    var promotion_map: Dictionary = maps["promotion"]
    for record: Dictionary in _sorted_records(registry.call("get_family", "venues")):
        var venue: RefCounted = VenueState.new()
        venue.set("venue_id", str(record.get("id", "")))
        var relationships: Dictionary = {}
        for promotion_id: Variant in promotion_map.values():
            relationships[str(promotion_id)] = 0.0
        venue.set("relationship_by_promotion", relationships)
        venues[venue.get("venue_id")] = venue
    state.set("venues", venues)

func _build_people(state: RefCounted, people_seeds: Array[Dictionary], registry: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var people: Dictionary = {}
    var markets: Array[Dictionary] = _sorted_records(registry.call("get_family", "markets"))
    var market_to_region: Dictionary = {}
    for market: Dictionary in markets:
        market_to_region[str(market.get("id", ""))] = str(market.get("region_id", ""))
    var employment: Dictionary = {}
    for promotion_seed: Dictionary in promotion_seeds:
        for seed_key: String in ["owner_person_seed_id", "booker_person_seed_id"]:
            employment[str(promotion_seed.get(seed_key, ""))] = str(promotion_seed.get("id", ""))
    for contract: Dictionary in registry.call("get_family", "contracts"):
        employment[str(contract.get("person_seed_id", ""))] = str(contract.get("promotion_seed_id", ""))

    for index: int in range(people_seeds.size()):
        var record: Dictionary = people_seeds[index]
        var seed_id: String = str(record.get("id", ""))
        var person: RefCounted = PersonState.new()
        person.set("id", str((maps["person"] as Dictionary).get(seed_id, "")))
        person.set("seed_definition_id", seed_id)
        person.set("legal_name", str(record.get("display_name", "")))
        person.set("display_name", str(record.get("display_name", "")))
        person.set("birth_date", "%d-01-01" % (1932 + (index % 16)))
        person.set("pronoun_set_id", "pronoun.unspecified")
        var home_market_id: String = str(record.get("home_market_id", ""))
        person.set("home_region_id", market_to_region.get(home_market_id, null))
        person.set("tag_ids", _content_safe_tags(record.get("tags", [])))
        var role_ids: Array = (record.get("role_ids", []) as Array).duplicate(true)
        person.set("roles", role_ids)
        person.set("skills", _skills_for_roles(role_ids, index))
        person.set("traits", {})
        person.set("potential", {})
        person.set("health", {"status": "available", "injury_risk": 0.12 + float(index % 5) * 0.025})
        person.set("career", {"status": "active"})
        var audience: Dictionary = {}
        var promotion_seed_id: String = str(employment.get(seed_id, ""))
        var home_markets: Array = []
        for promotion_seed: Dictionary in promotion_seeds:
            if str(promotion_seed.get("id", "")) == promotion_seed_id:
                home_markets = promotion_seed.get("home_market_ids", [])
                break
        for market: Dictionary in markets:
            var market_id: String = str(market.get("id", ""))
            var local_home: bool = market_id == home_market_id
            var promo_home: bool = market_id in home_markets
            var overness: float = 0.46 if local_home else (0.34 if promo_home else 0.12 + float((index + market_id.hash()) % 7) * 0.018)
            audience[market_id] = {
                "overness": clampf(overness, 0.0, 1.0),
                "momentum": 0.0,
                "heat": clampf(overness * 0.58, 0.0, 1.0),
                "shine": clampf(overness * 0.72, 0.0, 1.0),
            }
        person.set("audience_by_market", audience)
        people[person.get("id")] = person
    state.set("people", people)

func _build_promotions(state: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var promotions: Dictionary = {}
    var person_map: Dictionary = maps["person"]
    var promotion_map: Dictionary = maps["promotion"]
    for index: int in range(promotion_seeds.size()):
        var record: Dictionary = promotion_seeds[index]
        var promotion: RefCounted = PromotionState.new()
        var promotion_id: String = str(promotion_map.get(str(record.get("id", "")), ""))
        promotion.set("id", promotion_id)
        promotion.set("seed_definition_id", str(record.get("id", "")))
        promotion.set("brand_name", str(record.get("display_name", "")))
        promotion.set("controlling_owner_person_id", person_map.get(str(record.get("owner_person_seed_id", "")), null))
        promotion.set("cash", {"minor_units": 1750000 - index * 180000, "currency_id": CURRENCY_ID})
        promotion.set("prestige", clampf(0.48 + index * 0.025, 0.0, 1.0))
        promotion.set("locker_room_morale", clampf(0.62 - index * 0.02, 0.0, 1.0))
        promotion.set("momentum", 0.02 - index * 0.015)
        promotion.set("home_market_ids", (record.get("home_market_ids", []) as Array).duplicate(true))
        promotion.set("strategy_profile_id", record.get("strategy_profile_id", null))
        promotions[promotion_id] = promotion
    state.set("promotions", promotions)

func _build_contracts(state: RefCounted, registry: RefCounted, maps: Dictionary) -> void:
    var contracts: Dictionary = {}
    var records: Array[Dictionary] = _sorted_records(registry.call("get_family", "contracts"))
    for index: int in range(records.size()):
        var record: Dictionary = records[index]
        var contract: RefCounted = ContractState.new()
        contract.set("id", str((maps["contract"] as Dictionary).get(str(record.get("id", "")), "")))
        contract.set("person_id", str((maps["person"] as Dictionary).get(str(record.get("person_seed_id", "")), "")))
        contract.set("promotion_id", str((maps["promotion"] as Dictionary).get(str(record.get("promotion_seed_id", "")), "")))
        contract.set("start_date", str(record.get("start_date", "")))
        contract.set("end_date", record.get("end_date", null))
        var person: RefCounted = (state.get("people") as Dictionary).get(contract.get("person_id"))
        var roles: Array = person.get("roles") if person != null else []
        var pay: int = 8500
        if "role.owner" in roles: pay = 14000
        elif "role.booker" in roles: pay = 11000
        elif "role.wrestler" in roles: pay = 12500 + (index % 3) * 750
        contract.set("compensation", {"base": {"minor_units": pay, "currency_id": CURRENCY_ID}})
        contract.set("exclusivity_id", "exclusivity.standard")
        contract.set("leverage", clampf(0.28 + float(index % 4) * 0.06, 0.0, 1.0))
        contracts[contract.get("id")] = contract
    state.set("contracts", contracts)

func _build_championships(state: RefCounted, registry: RefCounted, maps: Dictionary) -> void:
    var championships: Dictionary = {}
    var records: Array[Dictionary] = _sorted_records(registry.call("get_family", "championships"))
    for index: int in range(records.size()):
        var record: Dictionary = records[index]
        var championship: RefCounted = ChampionshipState.new()
        championship.set("id", str((maps["championship"] as Dictionary).get(str(record.get("id", "")), "")))
        var promotion_id: String = str((maps["promotion"] as Dictionary).get(str(record.get("promotion_seed_id", "")), ""))
        championship.set("promotion_id", promotion_id)
        championship.set("definition_id", str(record.get("id", "")))
        championship.set("prestige", clampf(0.54 + index * 0.025, 0.0, 1.0))
        var holders: Array = []
        for holder_seed: Variant in record.get("holder_person_seed_ids", []):
            if (maps["person"] as Dictionary).has(str(holder_seed)):
                holders.append((maps["person"] as Dictionary)[str(holder_seed)])
        if holders.is_empty():
            holders = _wrestlers_for_promotion(state, promotion_id).slice(0, 1)
        championship.set("holder_person_ids", holders)
        championship.set("recognition_market_ids", (record.get("recognition_market_ids", []) as Array).duplicate(true))
        championship.set("recognition_promotion_ids", [promotion_id])
        championships[championship.get("id")] = championship
    state.set("championships", championships)

func _build_touring(state: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var touring: Dictionary = {}
    for index: int in range(promotion_seeds.size()):
        var promotion_id: String = str((maps["promotion"] as Dictionary).get(str(promotion_seeds[index].get("id", "")), ""))
        var company: RefCounted = TouringCompanyState.new()
        company.set("id", "touring:TOU" + str(index + 1).pad_zeros(5))
        company.set("promotion_id", promotion_id)
        company.set("name", str((state.get("promotions") as Dictionary)[promotion_id].get("brand_name")) + " Touring Company")
        company.set("person_assignment_ids", _active_people_for_promotion(state, promotion_id, false))
        var home_markets: Array = (promotion_seeds[index].get("home_market_ids", []) as Array).duplicate(true)
        var route: Array = []
        for market_id: Variant in home_markets:
            route.append({"market_id": str(market_id)})
        company.set("route", route.slice(0, mini(2, route.size())))
        company.set("monthly_budget", {"minor_units": 165000 - index * 10000, "currency_id": CURRENCY_ID})
        company.set("fatigue_pressure", 0.08 + index * 0.04)
        company.set("cohesion", 0.74 - index * 0.03)
        touring[company.get("id")] = company
    state.set("touring_companies", touring)

func _build_programs(state: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var programs: Dictionary = {}
    for index: int in range(promotion_seeds.size()):
        var promotion_id: String = str((maps["promotion"] as Dictionary).get(str(promotion_seeds[index].get("id", "")), ""))
        var wrestlers: Array = _wrestlers_for_promotion(state, promotion_id)
        if wrestlers.size() < 2:
            continue
        var program: RefCounted = ProgramState.new()
        program.set("id", "program:PRG" + str(index + 1).pad_zeros(5))
        program.set("promotion_id", promotion_id)
        program.set("started_on", str(state.get("current_date")))
        program.set("side_a", {"person_ids": [wrestlers[0]]})
        program.set("side_b", {"person_ids": [wrestlers[1]]})
        program.set("purpose_id", "program_purpose.feature")
        program.set("phase_id", "program_phase.build")
        program.set("heat", 0.32 + index * 0.035)
        program.set("momentum", 0.01)
        program.set("objective_ids", ["program_objective.build_star"])
        programs[program.get("id")] = program
    state.set("programs", programs)

func _build_media_deals(state: RefCounted, registry: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> void:
    var deals: Dictionary = {}
    var outlets: Array[Dictionary] = _sorted_records(registry.call("get_family", "media_outlets"))
    var serial: int = 1
    for promotion_seed: Dictionary in promotion_seeds:
        var promotion_id: String = str((maps["promotion"] as Dictionary).get(str(promotion_seed.get("id", "")), ""))
        var home_markets: Array = promotion_seed.get("home_market_ids", [])
        var selected: Dictionary = {}
        for outlet: Dictionary in outlets:
            for market_id: Variant in outlet.get("market_ids", []):
                if market_id in home_markets:
                    selected = outlet
                    break
            if not selected.is_empty(): break
        if selected.is_empty(): continue
        var deal: RefCounted = MediaDealState.new()
        deal.set("id", "media_deal:MED" + str(serial).pad_zeros(5)); serial += 1
        deal.set("promotion_id", promotion_id)
        deal.set("medium_id", str(selected.get("medium_id", "")))
        deal.set("outlet_id", str(selected.get("id", "")))
        deal.set("reach_market_ids", (selected.get("market_ids", []) as Array).duplicate(true))
        deal.set("start_date", str(state.get("current_date")))
        deal.set("schedule_id", "schedule.monthly")
        deal.set("cost", {"minor_units": 10000, "currency_id": CURRENCY_ID})
        deal.set("revenue", {"minor_units": 14500, "currency_id": CURRENCY_ID})
        deals[deal.get("id")] = deal
    state.set("media_deals", deals)

func _wire_indexes(state: RefCounted) -> void:
    for person: RefCounted in (state.get("people") as Dictionary).values():
        person.set("active_contract_ids", [])
    for promotion: RefCounted in (state.get("promotions") as Dictionary).values():
        promotion.set("contract_ids", [])
        promotion.set("touring_company_ids", [])
        promotion.set("championship_ids", [])
        promotion.set("program_ids", [])
        promotion.set("media_deal_ids", [])
    for contract_id: String in (state.get("contracts") as Dictionary).keys():
        var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
        var person: RefCounted = (state.get("people") as Dictionary)[str(contract.get("person_id"))]
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[str(contract.get("promotion_id"))]
        person.get("active_contract_ids").append(contract_id)
        promotion.get("contract_ids").append(contract_id)
    for company_id: String in (state.get("touring_companies") as Dictionary).keys():
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
        (state.get("promotions") as Dictionary)[str(company.get("promotion_id"))].get("touring_company_ids").append(company_id)
    for championship_id: String in (state.get("championships") as Dictionary).keys():
        var championship: RefCounted = (state.get("championships") as Dictionary)[championship_id]
        (state.get("promotions") as Dictionary)[str(championship.get("promotion_id"))].get("championship_ids").append(championship_id)
    for program_id: String in (state.get("programs") as Dictionary).keys():
        var program: RefCounted = (state.get("programs") as Dictionary)[program_id]
        (state.get("promotions") as Dictionary)[str(program.get("promotion_id"))].get("program_ids").append(program_id)
    for deal_id: String in (state.get("media_deals") as Dictionary).keys():
        var deal: RefCounted = (state.get("media_deals") as Dictionary)[deal_id]
        (state.get("promotions") as Dictionary)[str(deal.get("promotion_id"))].get("media_deal_ids").append(deal_id)
    for championship: RefCounted in (state.get("championships") as Dictionary).values():
        var promo_id: String = str(championship.get("promotion_id"))
        for company_id: Variant in (state.get("promotions") as Dictionary)[promo_id].get("touring_company_ids"):
            (state.get("touring_companies") as Dictionary)[str(company_id)].get("carried_championship_ids").append(championship.get("id"))

func _world_state(state: RefCounted, promotion_seeds: Array[Dictionary], maps: Dictionary) -> Dictionary:
    var booker_by_promotion: Dictionary = {}
    var stress: Dictionary = {}
    for record: Dictionary in promotion_seeds:
        var promotion_id: String = str((maps["promotion"] as Dictionary).get(str(record.get("id", "")), ""))
        booker_by_promotion[promotion_id] = str((maps["person"] as Dictionary).get(str(record.get("booker_person_seed_id", "")), ""))
        stress[promotion_id] = 0.06
    return {
        "era_id": "era.campaign_start",
        "available_technology_ids": [],
        "global_wrestling_interest": 0.5,
        "booker_by_promotion": booker_by_promotion,
        "local_media_spend_by_promotion": {},
        "financial_stress_by_promotion": stress,
        "market_visit_streaks": {},
        "market_focus_by_promotion": {},
        "approved_major_outcomes": {},
        "presentation_context_by_promotion": {},
        "wrestling_language_context_by_market": {},
    }

func _build_knowledge(state: RefCounted) -> void:
    var knowledge_bases: Dictionary = {}
    for observer_promotion_id: String in (state.get("promotions") as Dictionary).keys():
        var base: RefCounted = KnowledgeBase.new()
        base.set("owner_promotion_id", observer_promotion_id)
        var observations: Array = []
        var familiarity: Dictionary = {}
        for market_id: String in (state.get("markets") as Dictionary).keys():
            familiarity[market_id] = 0.46
            var market: RefCounted = (state.get("markets") as Dictionary)[market_id]
            for rival_promotion_id: String in (state.get("promotions") as Dictionary).keys():
                if rival_promotion_id == observer_promotion_id: continue
                var composite: float = _influence_composite(market, rival_promotion_id)
                observations.append({
                    "subject_id": market_id,
                    "field_id": _rival_influence_field(rival_promotion_id),
                    "estimate_form": "range",
                    "range": {"min": clampf(composite - 0.10, 0.0, 1.0), "max": clampf(composite + 0.10, 0.0, 1.0)},
                    "confidence": 0.62,
                    "source_id": "source.initial_scouting",
                    "observed_on": str(state.get("current_date")),
                    "bias": 0.0,
                    "error_margin": 0.10,
                })
        for company_id: String in (state.get("touring_companies") as Dictionary).keys():
            var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
            if str(company.get("promotion_id")) == observer_promotion_id: continue
            observations.append({
                "subject_id": company_id,
                "field_id": "touring.route",
                "estimate_form": "exact",
                "value": (company.get("route") as Array).duplicate(true),
                "confidence": 0.76,
                "source_id": "source.public_schedule",
                "observed_on": str(state.get("current_date")),
                "bias": 0.0,
                "error_margin": 0.0,
            })
            familiarity[company_id] = 0.54
        base.set("observations", observations)
        base.set("familiarity_by_subject", familiarity)
        knowledge_bases[observer_promotion_id] = base
    state.set("knowledge_bases", knowledge_bases)

func _make_chronicle() -> RefCounted:
    var store: RefCounted = ChronicleStore.new()
    store.set("checkpoint_cadence_months", 6)
    store.set("metric_definitions", [
        {"metric_id": "promotion.prestige", "subject_scope": "promotion", "field": "prestige", "cadence": "monthly", "aggregation": "point", "precision": "float", "retention": "campaign"},
        {"metric_id": "promotion.momentum", "subject_scope": "promotion", "field": "momentum", "cadence": "monthly", "aggregation": "point", "precision": "float", "retention": "campaign"},
    ])
    return store

func _active_people_for_promotion(state: RefCounted, promotion_id: String, include_owner: bool = true) -> Array:
    var people: Array = []
    for contract: RefCounted in (state.get("contracts") as Dictionary).values():
        if str(contract.get("promotion_id")) != promotion_id or str(contract.get("status")) != "active": continue
        var person_id: String = str(contract.get("person_id"))
        var person: RefCounted = (state.get("people") as Dictionary)[person_id]
        if not include_owner and "role.owner" in (person.get("roles") as Array): continue
        people.append(person_id)
    people.sort()
    return people

func _wrestlers_for_promotion(state: RefCounted, promotion_id: String) -> Array:
    var wrestlers: Array = []
    for person_id: Variant in _active_people_for_promotion(state, promotion_id, true):
        if "role.wrestler" in (((state.get("people") as Dictionary)[str(person_id)] as RefCounted).get("roles") as Array):
            wrestlers.append(person_id)
    wrestlers.sort()
    return wrestlers

func _skills_for_roles(roles: Array, index: int) -> Dictionary:
    var skills: Dictionary = {}
    if "role.wrestler" in roles:
        skills["skill.performance"] = 0.64 + float(index % 4) * 0.045
        skills["skill.psychology"] = 0.61 + float(index % 5) * 0.035
        skills["skill.charisma"] = 0.58 + float(index % 6) * 0.04
    if "role.booker" in roles:
        skills["skill.booking"] = 0.70 + float(index % 4) * 0.04
        skills["skill.road_agenting"] = 0.66 + float(index % 3) * 0.045
    if "role.owner" in roles:
        skills["skill.business"] = 0.68 + float(index % 3) * 0.035
    return skills

func _content_safe_tags(tags_value: Variant) -> Array:
    var tags: Array = []
    if tags_value is Array:
        for value: Variant in tags_value:
            var normalized: String = "tag." + str(value).to_lower().replace(" ", "_").replace("-", "_")
            tags.append(normalized)
    return tags

func _influence_composite(market: RefCounted, promotion_id: String) -> float:
    var components: Dictionary = (market.get("influence_by_promotion") as Dictionary).get(promotion_id, {})
    if components.is_empty(): return 0.0
    return float(components.get("audience", 0.0)) * 0.40 + float(components.get("media", 0.0)) * 0.25 + float(components.get("business", 0.0)) * 0.25 + float(components.get("infrastructure", 0.0)) * 0.10

func _rival_influence_field(promotion_id: String) -> String:
    return "promotion_estimate." + promotion_id.get_slice(":", 1).to_lower()

func _travel_connections(registry: RefCounted) -> Dictionary:
    var result: Dictionary = {}
    var map_records: Array[Dictionary] = registry.call("get_family", "map")
    if map_records.is_empty(): return result
    for connection_value: Variant in map_records[0].get("connections", []):
        if not connection_value is Dictionary: continue
        var connection: Dictionary = connection_value
        var a: String = str(connection.get("from_market_id", ""))
        var b: String = str(connection.get("to_market_id", ""))
        var entry: Dictionary = {
            "base_cost_index": float(connection.get("base_cost_index", 1.0)),
            "base_distance_km": float(connection.get("base_distance_km", 0.0)),
            "base_time_minutes": float(connection.get("base_time_minutes", 0.0)),
        }
        result[a + "|" + b] = entry
        result[b + "|" + a] = entry.duplicate(true)
    return result

func _sorted_records(value: Variant) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    if value is Array:
        for item: Variant in value:
            if item is Dictionary:
                output.append((item as Dictionary).duplicate(true))
    output.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id", "")) < str(b.get("id", "")))
    return output

func _failure(code: String, path: String, message: String) -> Dictionary:
    return {"passed": false, "state": null, "chronicle": null, "content_index": {}, "errors": [{"code": code, "path": path, "message": message}]}
