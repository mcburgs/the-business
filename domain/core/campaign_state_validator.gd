extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")

func validate(state: RefCounted, content_index: Dictionary = {}) -> Dictionary:
    var errors: Array[Dictionary] = []
    _validate_top_level(state, content_index, errors)
    _validate_store_ids(state.get("people"), "people", "id", "person", errors)
    _validate_store_ids(state.get("promotions"), "promotions", "id", "promotion", errors)
    _validate_store_ids(state.get("markets"), "markets", "market_id", "", errors, true)
    _validate_store_ids(state.get("regions"), "regions", "region_id", "", errors, true)
    _validate_store_ids(state.get("touring_companies"), "touring_companies", "id", "touring", errors)
    _validate_store_ids(state.get("contracts"), "contracts", "id", "contract", errors)
    _validate_store_ids(state.get("championships"), "championships", "id", "championship", errors)
    _validate_store_ids(state.get("programs"), "programs", "id", "program", errors)
    _validate_store_ids(state.get("media_deals"), "media_deals", "id", "media_deal", errors)
    _validate_store_ids(state.get("venues"), "venues", "venue_id", "", errors, true)
    _validate_store_ids(state.get("agreements"), "agreements", "id", "agreement", errors)
    _validate_store_ids(state.get("relationships"), "relationships", "id", "relationship", errors)
    _validate_store_ids(state.get("knowledge_bases"), "knowledge_bases", "owner_promotion_id", "promotion", errors)
    _validate_references(state, content_index, errors)
    _validate_ranges(state, errors)
    _validate_data_shapes(state, errors)
    return {"passed": errors.is_empty(), "errors": errors}

func _validate_top_level(state: RefCounted, content_index: Dictionary, errors: Array[Dictionary]) -> void:
    if int(state.get("state_schema_version")) != 1:
        _add(errors, "STATE001", "state_schema_version", {"expected": 1, "actual": state.get("state_schema_version")})
    _content_id(str(state.get("campaign_pack_id")), "campaign_pack_id", errors)
    _content_id(str(state.get("ruleset_id")), "ruleset_id", errors)
    _semver(str(state.get("campaign_pack_version")), "campaign_pack_version", errors)
    _date(str(state.get("current_date")), "current_date", errors)
    var fingerprint: String = str(state.get("content_fingerprint"))
    if fingerprint.length() != 64 or not fingerprint.is_valid_hex_number(false):
        _add(errors, "STATE001", "content_fingerprint", {"reason": "expected_sha256_hex"})
    if int(state.get("turn_number")) < 0:
        _add(errors, "STATE001", "turn_number", {"minimum": 0})
    if not state.get("world_state") is Dictionary:
        _add(errors, "STATE001", "world_state", {"reason": "expected_dictionary"})

    var seat: RefCounted = state.get("ownership_seat") as RefCounted
    if seat == null:
        _add(errors, "STATE001", "ownership_seat", {"reason": "required"})
    else:
        _runtime_ref(str(seat.get("promotion_id")), "promotion", state.get("promotions"), "ownership_seat.promotion_id", errors)
        _runtime_ref(str(seat.get("owner_person_id")), "person", state.get("people"), "ownership_seat.owner_person_id", errors)

    var event_state: RefCounted = state.get("event_state") as RefCounted
    if event_state == null:
        _add(errors, "STATE001", "event_state", {"reason": "required"})
    var victory_state: RefCounted = state.get("victory_state") as RefCounted
    if victory_state == null:
        _add(errors, "STATE001", "victory_state", {"reason": "required"})
    var rng_state: RefCounted = state.get("rng_state") as RefCounted
    if rng_state == null:
        _add(errors, "STATE001", "rng_state", {"reason": "required"})
    else:
        if str(rng_state.get("provider_id")) != "godot.random_number_generator":
            _add(errors, "STATE001", "rng_state.provider_id", {"expected": "godot.random_number_generator", "actual": rng_state.get("provider_id")})
        if str(rng_state.get("stream_policy")) != "single_root_v1":
            _add(errors, "STATE001", "rng_state.stream_policy", {"expected": "single_root_v1", "actual": rng_state.get("stream_policy")})
        if not rng_state.get("seed") is int:
            _add(errors, "STATE001", "rng_state.seed", {"reason": "integer_required"})
        if not rng_state.get("internal_state") is int:
            _add(errors, "STATE001", "rng_state.internal_state", {"reason": "integer_required"})
        var captured_turn: int = int(rng_state.get("captured_turn"))
        if captured_turn < 0 or captured_turn > int(state.get("turn_number")):
            _add(errors, "STATE001", "rng_state.captured_turn", {"minimum": 0, "maximum": state.get("turn_number"), "actual": captured_turn})

    if not content_index.is_empty():
        _content_ref(str(state.get("ruleset_id")), "rulesets", content_index, "ruleset_id", errors)

func _validate_store_ids(store_value: Variant, store_name: String, id_property: String, runtime_family: String, errors: Array[Dictionary], definition_backed: bool = false) -> void:
    if not store_value is Dictionary:
        _add(errors, "STATE001", store_name, {"reason": "expected_dictionary"})
        return
    var store: Dictionary = store_value
    for key_string: String in DomainIds.sorted_keys(store):
        var entity: Variant = store[key_string]
        if not entity is RefCounted:
            _add(errors, "STATE001", store_name + "[" + key_string + "]", {"reason": "expected_state_object"})
            continue
        var canonical_id: String = str((entity as RefCounted).get(id_property))
        if key_string != canonical_id:
            _add(errors, "REF002", store_name + "[" + key_string + "]", {"key": key_string, "canonical_id": canonical_id})
        if definition_backed:
            if not DomainIds.is_content_id(canonical_id):
                _add(errors, "ID001", store_name + "[" + key_string + "]." + id_property, {"id": canonical_id})
        elif not DomainIds.is_runtime_id(canonical_id, runtime_family):
            _add(errors, "ID001", store_name + "[" + key_string + "]." + id_property, {"id": canonical_id, "expected_family": runtime_family})

func _validate_references(state: RefCounted, content_index: Dictionary, errors: Array[Dictionary]) -> void:
    var people: Dictionary = state.get("people")
    var promotions: Dictionary = state.get("promotions")
    var markets: Dictionary = state.get("markets")
    var regions: Dictionary = state.get("regions")
    var contracts: Dictionary = state.get("contracts")
    var touring: Dictionary = state.get("touring_companies")
    var championships: Dictionary = state.get("championships")
    var programs: Dictionary = state.get("programs")
    var media_deals: Dictionary = state.get("media_deals")
    var agreements: Dictionary = state.get("agreements")
    var relationships: Dictionary = state.get("relationships")

    for id: String in DomainIds.sorted_keys(promotions):
        var promotion: RefCounted = promotions[id]
        var owner: Variant = promotion.get("controlling_owner_person_id")
        if owner != null:
            _runtime_ref(str(owner), "person", people, "promotions[" + id + "].controlling_owner_person_id", errors)
        _optional_content_id(promotion.get("seed_definition_id"), "promotions[" + id + "].seed_definition_id", errors)
        _optional_content_id(promotion.get("ownership_model_id"), "promotions[" + id + "].ownership_model_id", errors)
        _optional_content_id(promotion.get("strategy_profile_id"), "promotions[" + id + "].strategy_profile_id", errors)
        _content_id_array(promotion.get("active_effect_ids"), "promotions[" + id + "].active_effect_ids", errors)
        _indexed_refs(promotion.get("contract_ids"), contracts, "contract", "promotion_id", id, "promotions[" + id + "].contract_ids", errors)
        _indexed_refs(promotion.get("touring_company_ids"), touring, "touring", "promotion_id", id, "promotions[" + id + "].touring_company_ids", errors)
        _indexed_refs(promotion.get("championship_ids"), championships, "championship", "promotion_id", id, "promotions[" + id + "].championship_ids", errors)
        _indexed_refs(promotion.get("program_ids"), programs, "program", "promotion_id", id, "promotions[" + id + "].program_ids", errors)
        _indexed_refs(promotion.get("media_deal_ids"), media_deals, "media_deal", "promotion_id", id, "promotions[" + id + "].media_deal_ids", errors)
        _id_array_refs(promotion.get("agreement_ids"), agreements, "agreement", "promotions[" + id + "].agreement_ids", errors)
        for agreement_value: Variant in promotion.get("agreement_ids"):
            var agreement_id: String = str(agreement_value)
            if agreements.has(agreement_id):
                var parties: Array = (agreements[agreement_id] as RefCounted).get("party_promotion_ids")
                if not id in parties:
                    _add(errors, "STATE003", "promotions[" + id + "].agreement_ids", {"reason": "agreement_party_index_mismatch", "agreement_id": agreement_id})
        for market_value: Variant in promotion.get("home_market_ids"):
            var market_id: String = str(market_value)
            _content_id(market_id, "promotions[" + id + "].home_market_ids", errors)
            if not markets.has(market_id):
                _add(errors, "REF001", "promotions[" + id + "].home_market_ids", {"id": market_id})

    for id: String in DomainIds.sorted_keys(people):
        var person: RefCounted = people[id]
        _optional_content_id(person.get("seed_definition_id"), "people[" + id + "].seed_definition_id", errors)
        _date(str(person.get("birth_date")), "people[" + id + "].birth_date", errors)
        _content_id(str(person.get("pronoun_set_id")), "people[" + id + "].pronoun_set_id", errors)
        _content_id_array(person.get("tag_ids"), "people[" + id + "].tag_ids", errors)
        var audience_refs: Variant = person.get("audience_by_market")
        if audience_refs is Dictionary:
            for audience_market_id: String in DomainIds.sorted_keys(audience_refs as Dictionary):
                _content_id(audience_market_id, "people[" + id + "].audience_by_market", errors)
                if not markets.has(audience_market_id):
                    _add(errors, "REF001", "people[" + id + "].audience_by_market", {"id": audience_market_id})
        _indexed_refs(person.get("active_contract_ids"), contracts, "contract", "person_id", id, "people[" + id + "].active_contract_ids", errors)
        _id_array_refs(person.get("relationship_ids"), relationships, "relationship", "people[" + id + "].relationship_ids", errors)
        for relationship_value: Variant in person.get("relationship_ids"):
            var relationship_id: String = str(relationship_value)
            if relationships.has(relationship_id):
                var relation: RefCounted = relationships[relationship_id]
                if str(relation.get("person_a_id")) != id and str(relation.get("person_b_id")) != id:
                    _add(errors, "STATE003", "people[" + id + "].relationship_ids", {"reason": "relationship_index_mismatch", "relationship_id": relationship_id})
        var home_region: Variant = person.get("home_region_id")
        if home_region != null:
            _content_id(str(home_region), "people[" + id + "].home_region_id", errors)
            if not regions.has(str(home_region)):
                _add(errors, "REF001", "people[" + id + "].home_region_id", {"id": home_region})

    for id: String in DomainIds.sorted_keys(contracts):
        var contract: RefCounted = contracts[id]
        var person_id: String = str(contract.get("person_id"))
        var promotion_id: String = str(contract.get("promotion_id"))
        _date(str(contract.get("start_date")), "contracts[" + id + "].start_date", errors)
        _optional_date(contract.get("end_date"), "contracts[" + id + "].end_date", errors)
        _content_id(str(contract.get("exclusivity_id")), "contracts[" + id + "].exclusivity_id", errors)
        _content_id_array(contract.get("clause_ids"), "contracts[" + id + "].clause_ids", errors)
        _money_values_recursive(contract.get("compensation"), "contracts[" + id + "].compensation", errors)
        _runtime_ref(person_id, "person", people, "contracts[" + id + "].person_id", errors)
        _runtime_ref(promotion_id, "promotion", promotions, "contracts[" + id + "].promotion_id", errors)
        var is_active: bool = str(contract.get("status")) == "active"
        if is_active and people.has(person_id) and not id in ((people[person_id] as RefCounted).get("active_contract_ids") as Array):
            _add(errors, "STATE003", "contracts[" + id + "]", {"reason": "person_contract_index_missing", "person_id": person_id})
        if is_active and promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("contract_ids") as Array):
            _add(errors, "STATE003", "contracts[" + id + "]", {"reason": "promotion_contract_index_missing", "promotion_id": promotion_id})
        if not is_active and people.has(person_id) and id in ((people[person_id] as RefCounted).get("active_contract_ids") as Array):
            _add(errors, "STATE003", "contracts[" + id + "]", {"reason": "inactive_contract_in_person_active_index", "person_id": person_id})
        if not is_active and promotions.has(promotion_id) and id in ((promotions[promotion_id] as RefCounted).get("contract_ids") as Array):
            _add(errors, "STATE003", "contracts[" + id + "]", {"reason": "inactive_contract_in_promotion_active_index", "promotion_id": promotion_id})

    for id: String in DomainIds.sorted_keys(touring):
        var company: RefCounted = touring[id]
        var promotion_id: String = str(company.get("promotion_id"))
        _runtime_ref(promotion_id, "promotion", promotions, "touring_companies[" + id + "].promotion_id", errors)
        if promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("touring_company_ids") as Array):
            _add(errors, "STATE003", "touring_companies[" + id + "]", {"reason": "promotion_touring_index_missing", "promotion_id": promotion_id})
        _id_array_refs(company.get("person_assignment_ids"), people, "person", "touring_companies[" + id + "].person_assignment_ids", errors)
        _id_array_refs(company.get("carried_championship_ids"), championships, "championship", "touring_companies[" + id + "].carried_championship_ids", errors)
        var route: Variant = company.get("route")
        if route is Array:
            for index: int in range((route as Array).size()):
                var stop: Variant = (route as Array)[index]
                if stop is Dictionary and (stop as Dictionary).has("market_id"):
                    var stop_market_id: String = str((stop as Dictionary)["market_id"])
                    _content_id(stop_market_id, "touring_companies[" + id + "].route[" + str(index) + "].market_id", errors)
                    if not markets.has(stop_market_id):
                        _add(errors, "REF001", "touring_companies[" + id + "].route[" + str(index) + "].market_id", {"id": stop_market_id})

    for id: String in DomainIds.sorted_keys(championships):
        var championship: RefCounted = championships[id]
        var promotion_id: String = str(championship.get("promotion_id"))
        _content_id(str(championship.get("definition_id")), "championships[" + id + "].definition_id", errors)
        _runtime_ref(promotion_id, "promotion", promotions, "championships[" + id + "].promotion_id", errors)
        if promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("championship_ids") as Array):
            _add(errors, "STATE003", "championships[" + id + "]", {"reason": "promotion_championship_index_missing", "promotion_id": promotion_id})
        _id_array_refs(championship.get("holder_person_ids"), people, "person", "championships[" + id + "].holder_person_ids", errors)
        _id_array_refs(championship.get("recognition_promotion_ids"), promotions, "promotion", "championships[" + id + "].recognition_promotion_ids", errors)
        for market_value: Variant in championship.get("recognition_market_ids"):
            var market_id: String = str(market_value)
            _content_id(market_id, "championships[" + id + "].recognition_market_ids", errors)
            if not markets.has(market_id):
                _add(errors, "REF001", "championships[" + id + "].recognition_market_ids", {"id": market_id})
        _optional_runtime_family(championship.get("last_change_event_id"), "event", "championships[" + id + "].last_change_event_id", errors)

    for id: String in DomainIds.sorted_keys(programs):
        var program: RefCounted = programs[id]
        var promotion_id: String = str(program.get("promotion_id"))
        _date(str(program.get("started_on")), "programs[" + id + "].started_on", errors)
        _optional_date(program.get("ended_on"), "programs[" + id + "].ended_on", errors)
        _content_id(str(program.get("purpose_id")), "programs[" + id + "].purpose_id", errors)
        _content_id(str(program.get("phase_id")), "programs[" + id + "].phase_id", errors)
        _content_id_array(program.get("objective_ids"), "programs[" + id + "].objective_ids", errors)
        _optional_content_id(program.get("planned_direction_id"), "programs[" + id + "].planned_direction_id", errors)
        _runtime_ref(promotion_id, "promotion", promotions, "programs[" + id + "].promotion_id", errors)
        if promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("program_ids") as Array):
            _add(errors, "STATE003", "programs[" + id + "]", {"reason": "promotion_program_index_missing", "promotion_id": promotion_id})
        _program_side_refs(program.get("side_a"), people, "programs[" + id + "].side_a", errors)
        _program_side_refs(program.get("side_b"), people, "programs[" + id + "].side_b", errors)

    for id: String in DomainIds.sorted_keys(media_deals):
        var deal: RefCounted = media_deals[id]
        var promotion_id: String = str(deal.get("promotion_id"))
        _content_id(str(deal.get("medium_id")), "media_deals[" + id + "].medium_id", errors)
        _content_id(str(deal.get("outlet_id")), "media_deals[" + id + "].outlet_id", errors)
        _date(str(deal.get("start_date")), "media_deals[" + id + "].start_date", errors)
        _optional_date(deal.get("end_date"), "media_deals[" + id + "].end_date", errors)
        _content_id(str(deal.get("schedule_id")), "media_deals[" + id + "].schedule_id", errors)
        _optional_content_id(deal.get("exclusivity_id"), "media_deals[" + id + "].exclusivity_id", errors)
        _content_id_array(deal.get("production_requirement_ids"), "media_deals[" + id + "].production_requirement_ids", errors)
        _content_id_array(deal.get("restriction_ids"), "media_deals[" + id + "].restriction_ids", errors)
        if deal.get("cost") != null:
            _money_values_recursive(deal.get("cost"), "media_deals[" + id + "].cost", errors)
        if deal.get("revenue") != null:
            _money_values_recursive(deal.get("revenue"), "media_deals[" + id + "].revenue", errors)
        _runtime_ref(promotion_id, "promotion", promotions, "media_deals[" + id + "].promotion_id", errors)
        if promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("media_deal_ids") as Array):
            _add(errors, "STATE003", "media_deals[" + id + "]", {"reason": "promotion_media_deal_index_missing", "promotion_id": promotion_id})
        for market_value: Variant in deal.get("reach_market_ids"):
            var market_id: String = str(market_value)
            _content_id(market_id, "media_deals[" + id + "].reach_market_ids", errors)
            if not markets.has(market_id):
                _add(errors, "REF001", "media_deals[" + id + "].reach_market_ids", {"id": market_id})

    for id: String in DomainIds.sorted_keys(agreements):
        var agreement: RefCounted = agreements[id]
        _date(str(agreement.get("start_date")), "agreements[" + id + "].start_date", errors)
        _optional_date(agreement.get("end_date"), "agreements[" + id + "].end_date", errors)
        _content_id_array(agreement.get("clause_ids"), "agreements[" + id + "].clause_ids", errors)
        _clause_reference_hints(agreement.get("clauses"), markets, people, promotions, "agreements[" + id + "].clauses", errors)
        _id_array_refs(agreement.get("party_promotion_ids"), promotions, "promotion", "agreements[" + id + "].party_promotion_ids", errors)
        for promotion_value: Variant in agreement.get("party_promotion_ids"):
            var promotion_id: String = str(promotion_value)
            if promotions.has(promotion_id) and not id in ((promotions[promotion_id] as RefCounted).get("agreement_ids") as Array):
                _add(errors, "STATE003", "agreements[" + id + "]", {"reason": "promotion_agreement_index_missing", "promotion_id": promotion_id})
        _optional_runtime_family(agreement.get("last_violation_event_id"), "event", "agreements[" + id + "].last_violation_event_id", errors)

    for id: String in DomainIds.sorted_keys(relationships):
        var relationship: RefCounted = relationships[id]
        _content_id_array(relationship.get("tag_ids"), "relationships[" + id + "].tag_ids", errors)
        var person_a_id: String = str(relationship.get("person_a_id"))
        var person_b_id: String = str(relationship.get("person_b_id"))
        _runtime_ref(person_a_id, "person", people, "relationships[" + id + "].person_a_id", errors)
        _runtime_ref(person_b_id, "person", people, "relationships[" + id + "].person_b_id", errors)
        if person_a_id == person_b_id:
            _add(errors, "STATE002", "relationships[" + id + "]", {"reason": "relationship_requires_distinct_people"})
        for person_id: String in [person_a_id, person_b_id]:
            if people.has(person_id) and not id in ((people[person_id] as RefCounted).get("relationship_ids") as Array):
                _add(errors, "STATE003", "relationships[" + id + "]", {"reason": "person_relationship_index_missing", "person_id": person_id})

    var knowledge_bases: Dictionary = state.get("knowledge_bases")
    for promotion_key: String in DomainIds.sorted_keys(knowledge_bases):
        _runtime_ref(promotion_key, "promotion", promotions, "knowledge_bases[" + promotion_key + "].owner_promotion_id", errors)
        _knowledge_observations((knowledge_bases[promotion_key] as RefCounted).get("observations"), "knowledge_bases[" + promotion_key + "].observations", errors)

    for market_id: String in DomainIds.sorted_keys(markets):
        var market: RefCounted = markets[market_id]
        var influence: Dictionary = market.get("influence_by_promotion")
        for promotion_key: String in DomainIds.sorted_keys(influence):
            _runtime_ref(promotion_key, "promotion", promotions, "markets[" + market_id + "].influence_by_promotion[" + promotion_key + "]", errors)

    var venues: Dictionary = state.get("venues")
    for venue_id: String in DomainIds.sorted_keys(venues):
        var venue: RefCounted = venues[venue_id]
        _content_id_array(venue.get("active_restriction_ids"), "venues[" + venue_id + "].active_restriction_ids", errors)
        var relationships_by_promotion: Dictionary = venue.get("relationship_by_promotion")
        for promotion_key: String in DomainIds.sorted_keys(relationships_by_promotion):
            _runtime_ref(promotion_key, "promotion", promotions, "venues[" + venue_id + "].relationship_by_promotion[" + promotion_key + "]", errors)

    if not content_index.is_empty():
        _validate_content_references(state, content_index, errors)

func _knowledge_observations(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if not value is Array:
        _add(errors, "STATE001", path, {"reason": "expected_array"})
        return
    var required: Array[String] = ["subject_id", "field_id", "estimate_form", "confidence", "source_id", "observed_on", "bias", "error_margin"]
    for index: int in range((value as Array).size()):
        var observation_value: Variant = (value as Array)[index]
        var observation_path: String = path + "[" + str(index) + "]"
        if not observation_value is Dictionary:
            _add(errors, "STATE001", observation_path, {"reason": "expected_dictionary"})
            continue
        var observation: Dictionary = observation_value
        for field: String in required:
            if not observation.has(field):
                _add(errors, "STATE001", observation_path + "." + field, {"reason": "required_field_missing"})
        if not observation.has("estimate_form"):
            continue
        var form: String = str(observation.get("estimate_form"))
        if not form in ["unknown", "qualitative", "range", "exact"]:
            _add(errors, "STATE001", observation_path + ".estimate_form", {"value": form})
        if observation.has("field_id"):
            _content_id(str(observation["field_id"]), observation_path + ".field_id", errors)
        if observation.has("source_id"):
            _content_id(str(observation["source_id"]), observation_path + ".source_id", errors)
        if observation.has("observed_on"):
            _date(str(observation["observed_on"]), observation_path + ".observed_on", errors)
        if observation.has("subject_id"):
            var subject_id: String = str(observation["subject_id"])
            if not DomainIds.is_runtime_id(subject_id) and not DomainIds.is_content_id(subject_id):
                _add(errors, "ID001", observation_path + ".subject_id", {"id": subject_id})
        if form == "exact" and not observation.has("value"):
            _add(errors, "STATE001", observation_path + ".value", {"reason": "required_for_exact_estimate"})
        if form == "range" and not observation.has("range"):
            _add(errors, "STATE001", observation_path + ".range", {"reason": "required_for_range_estimate"})
        if form == "qualitative" and not observation.has("qualitative"):
            _add(errors, "STATE001", observation_path + ".qualitative", {"reason": "required_for_qualitative_estimate"})

func _clause_reference_hints(value: Variant, markets: Dictionary, people: Dictionary, promotions: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if not value is Array:
        _add(errors, "STATE001", path, {"reason": "expected_array"})
        return
    for index: int in range((value as Array).size()):
        var clause_value: Variant = (value as Array)[index]
        if not clause_value is Dictionary:
            _add(errors, "STATE001", path + "[" + str(index) + "]", {"reason": "expected_dictionary"})
            continue
        var clause: Dictionary = clause_value
        if clause.has("clause_id"):
            _content_id(str(clause["clause_id"]), path + "[" + str(index) + "].clause_id", errors)
        if clause.has("market_ids"):
            _definition_id_array_refs(clause["market_ids"], markets, path + "[" + str(index) + "].market_ids", errors)
        if clause.has("person_ids"):
            _id_array_refs(clause["person_ids"], people, "person", path + "[" + str(index) + "].person_ids", errors)
        if clause.has("promotion_ids"):
            _id_array_refs(clause["promotion_ids"], promotions, "promotion", path + "[" + str(index) + "].promotion_ids", errors)
        if clause.has("protected_promotion_id"):
            _runtime_ref(str(clause["protected_promotion_id"]), "promotion", promotions, path + "[" + str(index) + "].protected_promotion_id", errors)

func _definition_id_array_refs(values: Variant, store: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if not values is Array:
        _add(errors, "STATE001", path, {"reason": "expected_array"})
        return
    var seen: Dictionary = {}
    for value: Variant in values:
        var id: String = str(value)
        _content_id(id, path, errors)
        if seen.has(id):
            _add(errors, "STATE002", path, {"id": id, "reason": "duplicate_assignment"})
        seen[id] = true
        if not store.has(id):
            _add(errors, "REF001", path, {"id": id})

func _validate_content_references(state: RefCounted, content_index: Dictionary, errors: Array[Dictionary]) -> void:
    for market_id: String in DomainIds.sorted_keys(state.get("markets")):
        _content_ref(market_id, "markets", content_index, "markets[" + market_id + "].market_id", errors)
    for region_id: String in DomainIds.sorted_keys(state.get("regions")):
        _content_ref(region_id, "regions", content_index, "regions[" + region_id + "].region_id", errors)
    for venue_id: String in DomainIds.sorted_keys(state.get("venues")):
        _content_ref(venue_id, "venues", content_index, "venues[" + venue_id + "].venue_id", errors)
    for id: String in DomainIds.sorted_keys(state.get("people")):
        var person: RefCounted = (state.get("people") as Dictionary)[id]
        _optional_content_ref(person.get("seed_definition_id"), "people", content_index, "people[" + id + "].seed_definition_id", errors)
    for id: String in DomainIds.sorted_keys(state.get("promotions")):
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[id]
        _optional_content_ref(promotion.get("seed_definition_id"), "promotions", content_index, "promotions[" + id + "].seed_definition_id", errors)
        _optional_content_ref(promotion.get("strategy_profile_id"), "promotion_strategies", content_index, "promotions[" + id + "].strategy_profile_id", errors)
    for id: String in DomainIds.sorted_keys(state.get("championships")):
        _content_ref(str(((state.get("championships") as Dictionary)[id] as RefCounted).get("definition_id")), "championships", content_index, "championships[" + id + "].definition_id", errors)
    for id: String in DomainIds.sorted_keys(state.get("media_deals")):
        var deal: RefCounted = (state.get("media_deals") as Dictionary)[id]
        _content_ref(str(deal.get("medium_id")), "media_mediums", content_index, "media_deals[" + id + "].medium_id", errors)
        _content_ref(str(deal.get("outlet_id")), "media_outlets", content_index, "media_deals[" + id + "].outlet_id", errors)

func _validate_ranges(state: RefCounted, errors: Array[Dictionary]) -> void:
    var world_state: Variant = state.get("world_state")
    if world_state is Dictionary and (world_state as Dictionary).has("global_wrestling_interest"):
        _normalized((world_state as Dictionary)["global_wrestling_interest"], "world_state.global_wrestling_interest", errors)

    for id: String in DomainIds.sorted_keys(state.get("people")):
        var person: RefCounted = (state.get("people") as Dictionary)[id]
        _numeric_dictionary(person.get("skills"), false, "people[" + id + "].skills", errors)
        _numeric_dictionary(person.get("traits"), true, "people[" + id + "].traits", errors)
        _numeric_dictionary(person.get("potential"), false, "people[" + id + "].potential", errors)
        var health: Variant = person.get("health")
        if health is Dictionary and (health as Dictionary).has("injury_risk"):
            _normalized((health as Dictionary)["injury_risk"], "people[" + id + "].health.injury_risk", errors)
        var audience: Variant = person.get("audience_by_market")
        if audience is Dictionary:
            for market_id: String in DomainIds.sorted_keys(audience):
                var local_state: Variant = (audience as Dictionary)[market_id]
                if not local_state is Dictionary:
                    _add(errors, "STATE001", "people[" + id + "].audience_by_market[" + market_id + "]", {"reason": "expected_dictionary"})
                    continue
                for field: String in ["overness", "heat", "shine"]:
                    if (local_state as Dictionary).has(field):
                        _normalized((local_state as Dictionary)[field], "people[" + id + "].audience_by_market[" + market_id + "]." + field, errors)
                if (local_state as Dictionary).has("momentum"):
                    _signed((local_state as Dictionary)["momentum"], "people[" + id + "].audience_by_market[" + market_id + "].momentum", errors)

    for id: String in DomainIds.sorted_keys(state.get("promotions")):
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[id]
        _normalized(promotion.get("prestige"), "promotions[" + id + "].prestige", errors)
        _normalized(promotion.get("locker_room_morale"), "promotions[" + id + "].locker_room_morale", errors)
        _signed(promotion.get("momentum"), "promotions[" + id + "].momentum", errors)
        _money(promotion.get("cash"), "promotions[" + id + "].cash", errors)

    for id: String in DomainIds.sorted_keys(state.get("markets")):
        var market: RefCounted = (state.get("markets") as Dictionary)[id]
        _normalized(market.get("wrestling_interest"), "markets[" + id + "].wrestling_interest", errors)
        _normalized(market.get("economic_strength"), "markets[" + id + "].economic_strength", errors)
        var influence: Dictionary = market.get("influence_by_promotion")
        for promotion_id: String in DomainIds.sorted_keys(influence):
            var components: Variant = influence[promotion_id]
            if not components is Dictionary:
                _add(errors, "STATE001", "markets[" + id + "].influence_by_promotion[" + promotion_id + "]", {"reason": "expected_dictionary"})
                continue
            for component: String in DomainIds.sorted_keys(components as Dictionary):
                _normalized((components as Dictionary)[component], "markets[" + id + "].influence_by_promotion[" + promotion_id + "]." + component, errors)

    for id: String in DomainIds.sorted_keys(state.get("touring_companies")):
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[id]
        _money(company.get("monthly_budget"), "touring_companies[" + id + "].monthly_budget", errors)
        _normalized(company.get("fatigue_pressure"), "touring_companies[" + id + "].fatigue_pressure", errors)
        _normalized(company.get("cohesion"), "touring_companies[" + id + "].cohesion", errors)

    for id: String in DomainIds.sorted_keys(state.get("contracts")):
        _normalized(((state.get("contracts") as Dictionary)[id] as RefCounted).get("leverage"), "contracts[" + id + "].leverage", errors)
    for id: String in DomainIds.sorted_keys(state.get("championships")):
        _normalized(((state.get("championships") as Dictionary)[id] as RefCounted).get("prestige"), "championships[" + id + "].prestige", errors)
    for id: String in DomainIds.sorted_keys(state.get("programs")):
        var program: RefCounted = (state.get("programs") as Dictionary)[id]
        _normalized(program.get("heat"), "programs[" + id + "].heat", errors)
        _signed(program.get("momentum"), "programs[" + id + "].momentum", errors)
    for id: String in DomainIds.sorted_keys(state.get("agreements")):
        _signed(((state.get("agreements") as Dictionary)[id] as RefCounted).get("trust_effect"), "agreements[" + id + "].trust_effect", errors)
    for id: String in DomainIds.sorted_keys(state.get("relationships")):
        var relationship: RefCounted = (state.get("relationships") as Dictionary)[id]
        _signed(relationship.get("strength"), "relationships[" + id + "].strength", errors)
        _signed(relationship.get("trust"), "relationships[" + id + "].trust", errors)
        _signed(relationship.get("grievance"), "relationships[" + id + "].grievance", errors)
    for id: String in DomainIds.sorted_keys(state.get("venues")):
        var relations: Variant = ((state.get("venues") as Dictionary)[id] as RefCounted).get("relationship_by_promotion")
        if relations is Dictionary:
            for promotion_id: String in DomainIds.sorted_keys(relations as Dictionary):
                _signed((relations as Dictionary)[promotion_id], "venues[" + id + "].relationship_by_promotion[" + promotion_id + "]", errors)

    var knowledge_bases: Dictionary = state.get("knowledge_bases")
    for owner_id: String in DomainIds.sorted_keys(knowledge_bases):
        var knowledge: RefCounted = knowledge_bases[owner_id]
        var familiarity: Variant = knowledge.get("familiarity_by_subject")
        if familiarity is Dictionary:
            for subject_id: String in DomainIds.sorted_keys(familiarity as Dictionary):
                _normalized((familiarity as Dictionary)[subject_id], "knowledge_bases[" + owner_id + "].familiarity_by_subject[" + subject_id + "]", errors)
        var observations: Variant = knowledge.get("observations")
        if observations is Array:
            for index: int in range((observations as Array).size()):
                var observation: Variant = (observations as Array)[index]
                if not observation is Dictionary:
                    _add(errors, "STATE001", "knowledge_bases[" + owner_id + "].observations[" + str(index) + "]", {"reason": "expected_dictionary"})
                    continue
                var observation_path: String = "knowledge_bases[" + owner_id + "].observations[" + str(index) + "]"
                if (observation as Dictionary).has("confidence"):
                    _normalized((observation as Dictionary)["confidence"], observation_path + ".confidence", errors)
                var monetary_estimate: bool = str((observation as Dictionary).get("field_id", "")) == "contract.demand_minor_units"
                if (observation as Dictionary).has("bias"):
                    if monetary_estimate:
                        if not _finite_number((observation as Dictionary)["bias"]):
                            _add(errors, "STATE001", observation_path + ".bias", {"reason": "finite_number_required"})
                    else:
                        _signed((observation as Dictionary)["bias"], observation_path + ".bias", errors)
                if (observation as Dictionary).has("error_margin"):
                    if monetary_estimate:
                        var margin: Variant = (observation as Dictionary)["error_margin"]
                        if not _finite_number(margin) or float(margin) < 0.0:
                            _add(errors, "STATE001", observation_path + ".error_margin", {"reason": "nonnegative_finite_number_required"})
                    else:
                        _normalized((observation as Dictionary)["error_margin"], observation_path + ".error_margin", errors)
                if (observation as Dictionary).has("range"):
                    var estimate_range: Variant = (observation as Dictionary)["range"]
                    if estimate_range is Dictionary and (estimate_range as Dictionary).has("min") and (estimate_range as Dictionary).has("max"):
                        var minimum: Variant = (estimate_range as Dictionary)["min"]
                        var maximum: Variant = (estimate_range as Dictionary)["max"]
                        if not _finite_number(minimum) or not _finite_number(maximum) or float(minimum) > float(maximum):
                            _add(errors, "STATE001", observation_path + ".range", {"reason": "finite_ordered_range_required"})

func _validate_data_shapes(state: RefCounted, errors: Array[Dictionary]) -> void:
    _data_only(state.get("world_state"), "world_state", errors)
    for store_name: String in ["people", "promotions", "markets", "regions", "touring_companies", "contracts", "championships", "programs", "media_deals", "venues", "agreements", "relationships", "knowledge_bases"]:
        var store: Variant = state.get(store_name)
        if not store is Dictionary:
            continue
        for id: String in DomainIds.sorted_keys(store as Dictionary):
            var entity: Variant = (store as Dictionary)[id]
            if entity is RefCounted and (entity as RefCounted).has_method("to_dict"):
                _data_only((entity as RefCounted).call("to_dict"), store_name + "[" + id + "]", errors)
    for field: String in ["event_state", "rng_state", "victory_state", "ownership_seat"]:
        var value: Variant = state.get(field)
        if value is RefCounted and (value as RefCounted).has_method("to_dict"):
            _data_only((value as RefCounted).call("to_dict"), field, errors)

func _data_only(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    var value_type: int = typeof(value)
    if value_type == TYPE_NIL or value_type == TYPE_BOOL or value_type == TYPE_INT or value_type == TYPE_STRING:
        return
    if value_type == TYPE_FLOAT:
        if not is_finite(float(value)):
            _add(errors, "STATE001", path, {"reason": "finite_number_required", "value": value})
        return
    if value_type == TYPE_ARRAY:
        var array_value: Array = value
        for index: int in range(array_value.size()):
            _data_only(array_value[index], path + "[" + str(index) + "]", errors)
        return
    if value_type == TYPE_DICTIONARY:
        var dictionary_value: Dictionary = value
        for key: Variant in dictionary_value.keys():
            if not key is String:
                _add(errors, "STATE001", path, {"reason": "string_dictionary_keys_required", "key": str(key)})
                continue
            _data_only(dictionary_value[key], path + "." + str(key), errors)
        return
    _add(errors, "STATE001", path, {"reason": "non_serializable_authoritative_value", "variant_type": value_type})

func _indexed_refs(values: Variant, store: Dictionary, family: String, owner_field: String, expected_owner_id: String, path: String, errors: Array[Dictionary]) -> void:
    _id_array_refs(values, store, family, path, errors)
    if not values is Array:
        return
    for value: Variant in values:
        var entity_id: String = str(value)
        if store.has(entity_id) and str((store[entity_id] as RefCounted).get(owner_field)) != expected_owner_id:
            _add(errors, "STATE003", path, {"reason": "index_owner_mismatch", "id": entity_id, "expected_owner_id": expected_owner_id, "actual_owner_id": (store[entity_id] as RefCounted).get(owner_field)})

func _program_side_refs(side_value: Variant, people: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if not side_value is Dictionary:
        _add(errors, "STATE001", path, {"reason": "expected_dictionary"})
        return
    if (side_value as Dictionary).has("person_ids"):
        _id_array_refs((side_value as Dictionary)["person_ids"], people, "person", path + ".person_ids", errors)

func _runtime_ref(value: String, family: String, store: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if not DomainIds.is_runtime_id(value):
        _add(errors, "ID001", path, {"id": value})
        return
    if DomainIds.runtime_family(value) != family:
        _add(errors, "REF003", path, {"id": value, "expected_family": family, "actual_family": DomainIds.runtime_family(value)})
        return
    if not store.has(value):
        _add(errors, "REF001", path, {"id": value})

func _optional_runtime_family(value: Variant, family: String, path: String, errors: Array[Dictionary]) -> void:
    if value == null:
        return
    var id: String = str(value)
    if not DomainIds.is_runtime_id(id):
        _add(errors, "ID001", path, {"id": id})
    elif DomainIds.runtime_family(id) != family:
        _add(errors, "REF003", path, {"id": id, "expected_family": family, "actual_family": DomainIds.runtime_family(id)})

func _id_array_refs(values: Variant, store: Dictionary, family: String, path: String, errors: Array[Dictionary]) -> void:
    if not values is Array:
        _add(errors, "STATE001", path, {"reason": "expected_array"})
        return
    var seen: Dictionary = {}
    for value: Variant in values:
        var id: String = str(value)
        if seen.has(id):
            _add(errors, "STATE002", path, {"id": id, "reason": "duplicate_assignment"})
        seen[id] = true
        _runtime_ref(id, family, store, path, errors)

func _content_id(value: String, path: String, errors: Array[Dictionary]) -> void:
    if not DomainIds.is_content_id(value):
        _add(errors, "ID001", path, {"id": value})

func _optional_content_ref(value: Variant, family: String, content_index: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if value == null:
        return
    _content_ref(str(value), family, content_index, path, errors)

func _content_ref(value: String, family: String, content_index: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if not DomainIds.is_content_id(value):
        _add(errors, "ID001", path, {"id": value})
        return
    if not content_index.has(family):
        return
    var family_values: Variant = content_index[family]
    var exists: bool = false
    if family_values is Dictionary:
        exists = (family_values as Dictionary).has(value)
    elif family_values is Array:
        exists = value in (family_values as Array)
    if not exists:
        _add(errors, "REF001", path, {"id": value, "content_family": family})

func _content_id_array(values: Variant, path: String, errors: Array[Dictionary]) -> void:
    if not values is Array:
        _add(errors, "STATE001", path, {"reason": "expected_array"})
        return
    var seen: Dictionary = {}
    for value: Variant in values:
        var id: String = str(value)
        _content_id(id, path, errors)
        if seen.has(id):
            _add(errors, "STATE002", path, {"id": id, "reason": "duplicate_assignment"})
        seen[id] = true

func _optional_content_id(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if value != null:
        _content_id(str(value), path, errors)

func _optional_date(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if value != null:
        if not value is String:
            _add(errors, "STATE001", path, {"reason": "date_string_required", "value": value})
        else:
            _date(str(value), path, errors)

func _money_values_recursive(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if value is Dictionary:
        var dictionary_value: Dictionary = value
        if dictionary_value.has("minor_units") or dictionary_value.has("currency_id"):
            _money(dictionary_value, path, errors)
            return
        for key: String in DomainIds.sorted_keys(dictionary_value):
            _money_values_recursive(dictionary_value[key], path + "." + key, errors)
    elif value is Array:
        for index: int in range((value as Array).size()):
            _money_values_recursive((value as Array)[index], path + "[" + str(index) + "]", errors)

func _numeric_dictionary(value: Variant, signed_values: bool, path: String, errors: Array[Dictionary]) -> void:
    if not value is Dictionary:
        _add(errors, "STATE001", path, {"reason": "expected_dictionary"})
        return
    for key: String in DomainIds.sorted_keys(value as Dictionary):
        _content_id(key, path + "." + key, errors)
        if signed_values:
            _signed((value as Dictionary)[key], path + "." + key, errors)
        else:
            _normalized((value as Dictionary)[key], path + "." + key, errors)

func _normalized(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if not _finite_number(value) or float(value) < 0.0 or float(value) > 1.0:
        _add(errors, "STATE001", path, {"range": [0.0, 1.0], "value": value})

func _signed(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if not _finite_number(value) or float(value) < -1.0 or float(value) > 1.0:
        _add(errors, "STATE001", path, {"range": [-1.0, 1.0], "value": value})

func _money(value: Variant, path: String, errors: Array[Dictionary]) -> void:
    if not value is Dictionary:
        _add(errors, "STATE001", path, {"reason": "expected_money"})
        return
    var money: Dictionary = value
    for key: Variant in money.keys():
        if not str(key) in ["minor_units", "currency_id"]:
            _add(errors, "STATE001", path + "." + str(key), {"reason": "unknown_money_field"})
    if not money.has("minor_units") or not money.has("currency_id"):
        _add(errors, "STATE001", path, {"reason": "money_fields_required"})
        return
    var units: Variant = money["minor_units"]
    if not units is int:
        _add(errors, "STATE001", path + ".minor_units", {"reason": "integer_required", "value": units})
    _content_id(str(money["currency_id"]), path + ".currency_id", errors)

func _finite_number(value: Variant) -> bool:
    if not (value is int or value is float):
        return false
    return is_finite(float(value))

func _date(value: String, path: String, errors: Array[Dictionary]) -> void:
    if value.length() != 10 or value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
        _add(errors, "STATE001", path, {"reason": "expected_yyyy_mm_dd", "value": value})
        return
    var year_text: String = value.substr(0, 4)
    var month_text: String = value.substr(5, 2)
    var day_text: String = value.substr(8, 2)
    if not year_text.is_valid_int() or not month_text.is_valid_int() or not day_text.is_valid_int():
        _add(errors, "STATE001", path, {"reason": "expected_yyyy_mm_dd", "value": value})
        return
    var year: int = int(year_text)
    var month: int = int(month_text)
    var day: int = int(day_text)
    var days_in_month: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if year < 1 or month < 1 or month > 12:
        _add(errors, "STATE001", path, {"reason": "invalid_calendar_date", "value": value})
        return
    var leap: bool = (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
    if leap:
        days_in_month[1] = 29
    if day < 1 or day > days_in_month[month - 1]:
        _add(errors, "STATE001", path, {"reason": "invalid_calendar_date", "value": value})

func _semver(value: String, path: String, errors: Array[Dictionary]) -> void:
    var core: String = value
    var plus_index: int = core.find("+")
    if plus_index >= 0:
        core = core.substr(0, plus_index)
    var dash_index: int = core.find("-")
    if dash_index >= 0:
        core = core.substr(0, dash_index)
    var parts: PackedStringArray = core.split(".")
    if parts.size() != 3:
        _add(errors, "STATE001", path, {"reason": "semantic_version_required", "value": value})
        return
    for part: String in parts:
        if part.is_empty() or not part.is_valid_int() or int(part) < 0:
            _add(errors, "STATE001", path, {"reason": "semantic_version_required", "value": value})
            return

func _add(errors: Array[Dictionary], code: String, path: String, details: Dictionary) -> void:
    errors.append({
        "code": code,
        "path": path,
        "localization_key": "validation." + code.to_lower(),
        "details": details.duplicate(true),
    })
