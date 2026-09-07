extends RefCounted

const CampaignState = preload("res://domain/core/campaign_state.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const DomainIds = preload("res://domain/core/domain_ids.gd")
const OwnershipSeatState = preload("res://domain/core/ownership_seat_state.gd")
const RandomState = preload("res://domain/core/random_state.gd")
const VictoryState = preload("res://domain/core/victory_state.gd")
const EventState = preload("res://domain/events/event_state.gd")
const PersonState = preload("res://domain/people/person_state.gd")
const PromotionState = preload("res://domain/promotions/promotion_state.gd")
const MarketState = preload("res://domain/world/market_state.gd")
const RegionState = preload("res://domain/world/region_state.gd")
const TouringCompanyState = preload("res://domain/touring/touring_company_state.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const ChampionshipState = preload("res://domain/booking/championship_state.gd")
const ProgramState = preload("res://domain/booking/program_state.gd")
const MediaDealState = preload("res://domain/media/media_deal_state.gd")
const VenueState = preload("res://domain/world/venue_state.gd")
const AgreementState = preload("res://domain/diplomacy/agreement_state.gd")
const RelationshipState = preload("res://domain/people/relationship_state.gd")
const KnowledgeBase = preload("res://domain/knowledge/knowledge_base.gd")

const TOP_FIELDS: Array[String] = [
    "state_schema_version", "campaign_pack_id", "campaign_pack_version", "content_fingerprint",
    "ruleset_id", "current_date", "turn_number", "ownership_seat", "world_state",
    "people", "promotions", "markets", "regions", "touring_companies", "contracts",
    "championships", "programs", "media_deals", "venues", "agreements", "relationships",
    "knowledge_bases", "event_state", "rng_state", "victory_state"
]

const PERSON_FIELDS: Array[String] = ["id", "seed_definition_id", "lifecycle", "legal_name", "display_name", "ring_name", "birth_date", "pronoun_set_id", "home_region_id", "tag_ids", "skills", "traits", "potential", "roles", "health", "relationship_ids", "audience_by_market", "career", "active_contract_ids", "current_hot_state"]
const PROMOTION_FIELDS: Array[String] = ["id", "seed_definition_id", "lifecycle", "brand_name", "controlling_owner_person_id", "ownership_model_id", "ownership_shares", "cash", "prestige", "locker_room_morale", "momentum", "home_market_ids", "contract_ids", "touring_company_ids", "championship_ids", "program_ids", "media_deal_ids", "agreement_ids", "strategy_profile_id", "active_effect_ids", "current_hot_state"]
const MARKET_FIELDS: Array[String] = ["market_id", "wrestling_interest", "economic_strength", "influence_by_promotion", "current_hot_state", "active_effect_ids"]
const REGION_FIELDS: Array[String] = ["region_id", "current_hot_state", "active_effect_ids"]
const TOURING_FIELDS: Array[String] = ["id", "promotion_id", "name", "person_assignment_ids", "carried_championship_ids", "route", "directives", "monthly_budget", "fatigue_pressure", "cohesion", "current_hot_state", "status"]
const CONTRACT_FIELDS: Array[String] = ["id", "person_id", "promotion_id", "status", "start_date", "end_date", "compensation", "exclusivity_id", "clause_ids", "clause_parameters", "leverage", "dispute_state_id"]
const CHAMPIONSHIP_FIELDS: Array[String] = ["id", "promotion_id", "definition_id", "status", "prestige", "holder_person_ids", "recognition_market_ids", "recognition_promotion_ids", "last_change_event_id"]
const PROGRAM_FIELDS: Array[String] = ["id", "promotion_id", "status", "started_on", "ended_on", "side_a", "side_b", "purpose_id", "phase_id", "heat", "momentum", "objective_ids", "planned_direction_id", "chemistry_truth", "current_hot_state"]
const MEDIA_DEAL_FIELDS: Array[String] = ["id", "promotion_id", "medium_id", "outlet_id", "status", "reach_market_ids", "start_date", "end_date", "schedule_id", "cost", "revenue", "exclusivity_id", "production_requirement_ids", "restriction_ids"]
const VENUE_FIELDS: Array[String] = ["venue_id", "availability_state", "relationship_by_promotion", "active_restriction_ids"]
const AGREEMENT_FIELDS: Array[String] = ["id", "party_promotion_ids", "status", "start_date", "end_date", "clause_ids", "clauses", "trust_effect", "last_violation_event_id"]
const RELATIONSHIP_FIELDS: Array[String] = ["id", "person_a_id", "person_b_id", "strength", "trust", "grievance", "tag_ids"]
const KNOWLEDGE_FIELDS: Array[String] = ["owner_promotion_id", "observations", "familiarity_by_subject"]
const OWNERSHIP_FIELDS: Array[String] = ["promotion_id", "owner_person_id", "transition_pending"]
const EVENT_FIELDS: Array[String] = ["fired_event_ids", "active_event_ids", "cooldown_by_event_id", "choice_history"]
const RNG_FIELDS: Array[String] = ["provider_id", "seed", "internal_state", "captured_turn", "stream_policy"]
const VICTORY_FIELDS: Array[String] = ["status", "outcome_id", "details"]

func encode(state: RefCounted) -> Dictionary:
    return {
        "state_schema_version": int(state.get("state_schema_version")),
        "campaign_pack_id": str(state.get("campaign_pack_id")),
        "campaign_pack_version": str(state.get("campaign_pack_version")),
        "content_fingerprint": str(state.get("content_fingerprint")),
        "ruleset_id": str(state.get("ruleset_id")),
        "current_date": str(state.get("current_date")),
        "turn_number": int(state.get("turn_number")),
        "ownership_seat": _deep_copy((state.get("ownership_seat") as RefCounted).call("to_dict")),
        "world_state": (state.get("world_state") as Dictionary).duplicate(true),
        "people": _encode_store(state.get("people")),
        "promotions": _encode_store(state.get("promotions")),
        "markets": _encode_store(state.get("markets")),
        "regions": _encode_store(state.get("regions")),
        "touring_companies": _encode_store(state.get("touring_companies")),
        "contracts": _encode_store(state.get("contracts")),
        "championships": _encode_store(state.get("championships")),
        "programs": _encode_store(state.get("programs")),
        "media_deals": _encode_store(state.get("media_deals")),
        "venues": _encode_store(state.get("venues")),
        "agreements": _encode_store(state.get("agreements")),
        "relationships": _encode_store(state.get("relationships")),
        "knowledge_bases": _encode_store(state.get("knowledge_bases")),
        "event_state": _deep_copy((state.get("event_state") as RefCounted).call("to_dict")),
        "rng_state": _deep_copy((state.get("rng_state") as RefCounted).call("to_dict")),
        "victory_state": _deep_copy((state.get("victory_state") as RefCounted).call("to_dict")),
    }

func decode(data: Dictionary, content_index: Dictionary = {}) -> Dictionary:
    var errors: Array[Dictionary] = []
    _check_closed_required(data, TOP_FIELDS, TOP_FIELDS, "state", errors)
    _validate_top_types(data, errors)
    if not errors.is_empty():
        return {"passed": false, "state": null, "errors": errors}
    if int(data.get("state_schema_version", -1)) != CampaignState.STATE_SCHEMA_VERSION:
        _add(errors, "STATE001", "state_schema_version", {"supported": CampaignState.STATE_SCHEMA_VERSION, "actual": data.get("state_schema_version")})
        return {"passed": false, "state": null, "errors": errors}

    var state: RefCounted = CampaignState.new()
    state.set("state_schema_version", int(data["state_schema_version"]))
    state.set("campaign_pack_id", str(data["campaign_pack_id"]))
    state.set("campaign_pack_version", str(data["campaign_pack_version"]))
    state.set("content_fingerprint", str(data["content_fingerprint"]))
    state.set("ruleset_id", str(data["ruleset_id"]))
    state.set("current_date", str(data["current_date"]))
    state.set("turn_number", int(data["turn_number"]))
    var world_state: Dictionary = _dictionary_or_error(data["world_state"], "world_state", errors)
    _restore_world_state_integer_types(world_state)
    state.set("world_state", world_state)

    state.set("ownership_seat", _decode_record(data["ownership_seat"], OwnershipSeatState, OWNERSHIP_FIELDS, OWNERSHIP_FIELDS, "ownership_seat", errors))
    state.set("event_state", _decode_record(data["event_state"], EventState, EVENT_FIELDS, EVENT_FIELDS, "event_state", errors))
    state.set("rng_state", _decode_record(data["rng_state"], RandomState, RNG_FIELDS, RNG_FIELDS, "rng_state", errors))
    state.set("victory_state", _decode_record(data["victory_state"], VictoryState, VICTORY_FIELDS, VICTORY_FIELDS, "victory_state", errors))

    state.set("people", _decode_store(data["people"], PersonState, PERSON_FIELDS, "id", "people", errors))
    state.set("promotions", _decode_store(data["promotions"], PromotionState, PROMOTION_FIELDS, "id", "promotions", errors))
    state.set("markets", _decode_store(data["markets"], MarketState, MARKET_FIELDS, "market_id", "markets", errors))
    state.set("regions", _decode_store(data["regions"], RegionState, REGION_FIELDS, "region_id", "regions", errors))
    state.set("touring_companies", _decode_store(data["touring_companies"], TouringCompanyState, TOURING_FIELDS, "id", "touring_companies", errors))
    state.set("contracts", _decode_store(data["contracts"], ContractState, CONTRACT_FIELDS, "id", "contracts", errors))
    state.set("championships", _decode_store(data["championships"], ChampionshipState, CHAMPIONSHIP_FIELDS, "id", "championships", errors))
    state.set("programs", _decode_store(data["programs"], ProgramState, PROGRAM_FIELDS, "id", "programs", errors))
    state.set("media_deals", _decode_store(data["media_deals"], MediaDealState, MEDIA_DEAL_FIELDS, "id", "media_deals", errors))
    state.set("venues", _decode_store(data["venues"], VenueState, VENUE_FIELDS, "venue_id", "venues", errors))
    state.set("agreements", _decode_store(data["agreements"], AgreementState, AGREEMENT_FIELDS, "id", "agreements", errors))
    state.set("relationships", _decode_store(data["relationships"], RelationshipState, RELATIONSHIP_FIELDS, "id", "relationships", errors))
    state.set("knowledge_bases", _decode_store(data["knowledge_bases"], KnowledgeBase, KNOWLEDGE_FIELDS, "owner_promotion_id", "knowledge_bases", errors))

    if not errors.is_empty():
        return {"passed": false, "state": null, "errors": errors}
    var validation: Dictionary = CampaignStateValidator.new().validate(state, content_index)
    if not bool(validation.get("passed", false)):
        return {"passed": false, "state": null, "errors": validation.get("errors", [])}
    return {"passed": true, "state": state, "errors": []}

func build_manifest_scaffold(state: RefCounted, save_id: String, display_name: String, game_version: String, architecture_version: String, engine_version: String) -> Dictionary:
    return {
        "save_schema_version": 1,
        "state_schema_version": int(state.get("state_schema_version")),
        "architecture_version": architecture_version,
        "game_version": game_version,
        "engine_version": engine_version,
        "campaign_pack_id": state.get("campaign_pack_id"),
        "campaign_pack_version": state.get("campaign_pack_version"),
        "resolved_content_fingerprint": state.get("content_fingerprint"),
        "save_id": save_id,
        "display_name": display_name,
        "in_game_date": state.get("current_date"),
        "ownership_seat": _deep_copy((state.get("ownership_seat") as RefCounted).call("to_dict")),
        "rng_checkpoint": _deep_copy((state.get("rng_state") as RefCounted).call("to_dict")),
        "phase_c_scaffold": true,
    }

func _encode_store(store_value: Variant) -> Dictionary:
    var output: Dictionary = {}
    if not store_value is Dictionary:
        return output
    var store: Dictionary = store_value
    for id: String in DomainIds.sorted_keys(store):
        var entity: RefCounted = store[id]
        output[id] = _deep_copy(entity.call("to_dict"))
    return output

func _decode_store(value: Variant, script: Script, allowed_fields: Array[String], id_field: String, path: String, errors: Array[Dictionary]) -> Dictionary:
    var output: Dictionary = {}
    if not value is Dictionary:
        _add(errors, "STATE001", path, {"reason": "expected_dictionary"})
        return output
    var input_store: Dictionary = value
    for key: String in DomainIds.sorted_keys(input_store):
        var record_path: String = path + "[" + key + "]"
        var entity: Variant = _decode_record(input_store[key], script, allowed_fields, allowed_fields, record_path, errors)
        if entity == null:
            continue
        var canonical_id: String = str((entity as RefCounted).get(id_field))
        if canonical_id != key:
            _add(errors, "REF002", record_path, {"key": key, "canonical_id": canonical_id})
            continue
        output[key] = entity
    return output

func _decode_record(value: Variant, script: Script, allowed_fields: Array[String], required_fields: Array[String], path: String, errors: Array[Dictionary]) -> Variant:
    if not value is Dictionary:
        _add(errors, "STATE001", path, {"reason": "expected_object"})
        return null
    var record: Dictionary = value
    var error_count_before: int = errors.size()
    _check_closed_required(record, allowed_fields, required_fields, path, errors)
    if errors.size() != error_count_before:
        return null
    var entity: RefCounted = script.new()
    for field: String in allowed_fields:
        var conversion: Dictionary = _coerce_property_value(entity, field, record[field], path + "." + field, errors)
        if bool(conversion.get("passed", false)):
            entity.set(field, conversion.get("value"))
    return entity


func _restore_world_state_integer_types(world_state: Dictionary) -> void:
    # JSON represents numbers as floating point. Restore only fields whose Phase D/E
    # contracts define integer semantics; normalized gameplay quantities remain floats.
    var streaks: Variant = world_state.get("market_visit_streaks", null)
    if streaks is Dictionary:
        _restore_integral_leaves(streaks)
    var spend: Variant = world_state.get("local_media_spend_by_promotion", null)
    if spend is Dictionary:
        _restore_keyed_integers(spend, "minor_units")
    var ledger_value: Variant = world_state.get("ledger_v1", null)
    if ledger_value is Dictionary:
        var ledger: Dictionary = ledger_value
        _restore_integer_key(ledger, "schema_version")
        var accounts: Variant = ledger.get("accounts", null)
        if accounts is Dictionary:
            _restore_integral_leaves(accounts)
        var transactions: Variant = ledger.get("transactions", null)
        if transactions is Array:
            for transaction_value: Variant in transactions:
                if transaction_value is Dictionary:
                    _restore_keyed_integers(transaction_value, "minor_units")

func _restore_keyed_integers(value: Variant, key_name: String) -> void:
    if value is Dictionary:
        var dictionary: Dictionary = value
        for key: Variant in dictionary.keys():
            if str(key) == key_name:
                dictionary[key] = _safe_int(dictionary[key])
            else:
                _restore_keyed_integers(dictionary[key], key_name)
    elif value is Array:
        for item: Variant in value:
            _restore_keyed_integers(item, key_name)

func _restore_integral_leaves(value: Variant) -> void:
    if value is Dictionary:
        var dictionary: Dictionary = value
        for key: Variant in dictionary.keys():
            if dictionary[key] is Dictionary or dictionary[key] is Array:
                _restore_integral_leaves(dictionary[key])
            else:
                dictionary[key] = _safe_int(dictionary[key])
    elif value is Array:
        for index: int in range((value as Array).size()):
            var item: Variant = (value as Array)[index]
            if item is Dictionary or item is Array:
                _restore_integral_leaves(item)
            else:
                (value as Array)[index] = _safe_int(item)

func _restore_integer_key(dictionary: Dictionary, key: String) -> void:
    if dictionary.has(key):
        dictionary[key] = _safe_int(dictionary[key])

func _safe_int(value: Variant) -> Variant:
    if value is int:
        return value
    if value is float and is_finite(float(value)) and float(value) == floor(float(value)) and abs(float(value)) <= 9007199254740991.0:
        return int(value)
    return value

func _validate_top_types(data: Dictionary, errors: Array[Dictionary]) -> void:
    for field: String in ["campaign_pack_id", "campaign_pack_version", "content_fingerprint", "ruleset_id", "current_date"]:
        if data.has(field) and not data[field] is String:
            _add(errors, "STATE001", "state." + field, {"reason": "string_required"})
    for field: String in ["state_schema_version", "turn_number"]:
        if data.has(field) and not _is_integral_number(data[field]):
            _add(errors, "STATE001", "state." + field, {"reason": "integer_required", "value": data[field]})
    for field: String in ["ownership_seat", "world_state", "people", "promotions", "markets", "regions", "touring_companies", "contracts", "championships", "programs", "media_deals", "venues", "agreements", "relationships", "knowledge_bases", "event_state", "rng_state", "victory_state"]:
        if data.has(field) and not data[field] is Dictionary:
            _add(errors, "STATE001", "state." + field, {"reason": "object_required"})

func _coerce_property_value(entity: RefCounted, field: String, value: Variant, path: String, errors: Array[Dictionary]) -> Dictionary:
    var default_value: Variant = entity.get(field)
    if default_value == null:
        return {"passed": true, "value": _deep_copy(value)}
    if default_value is String:
        if not value is String:
            _add(errors, "STATE001", path, {"reason": "string_required"})
            return {"passed": false}
        return {"passed": true, "value": value}
    if default_value is bool:
        if not value is bool:
            _add(errors, "STATE001", path, {"reason": "boolean_required"})
            return {"passed": false}
        return {"passed": true, "value": value}
    if default_value is int:
        if not _is_integral_number(value):
            _add(errors, "STATE001", path, {"reason": "integer_required", "value": value})
            return {"passed": false}
        if value is float and abs(float(value)) > 9007199254740991.0:
            _add(errors, "STATE001", path, {"reason": "unsafe_float_integer_precision", "value": value})
            return {"passed": false}
        return {"passed": true, "value": int(value)}
    if default_value is float:
        if not (value is int or value is float) or not is_finite(float(value)):
            _add(errors, "STATE001", path, {"reason": "finite_number_required", "value": value})
            return {"passed": false}
        return {"passed": true, "value": float(value)}
    if default_value is Dictionary:
        if not value is Dictionary:
            _add(errors, "STATE001", path, {"reason": "object_required"})
            return {"passed": false}
        return {"passed": true, "value": (value as Dictionary).duplicate(true)}
    if default_value is Array:
        if not value is Array:
            _add(errors, "STATE001", path, {"reason": "array_required"})
            return {"passed": false}
        return {"passed": true, "value": (value as Array).duplicate(true)}
    return {"passed": true, "value": _deep_copy(value)}

func _is_integral_number(value: Variant) -> bool:
    if value is int:
        return true
    if value is float:
        return is_finite(float(value)) and float(value) == floor(float(value))
    return false

func _check_closed_required(record: Dictionary, allowed_fields: Array[String], required_fields: Array[String], path: String, errors: Array[Dictionary]) -> void:
    for key: Variant in record.keys():
        if not str(key) in allowed_fields:
            _add(errors, "STATE001", path + "." + str(key), {"reason": "unknown_field_schema_v1"})
    for field: String in required_fields:
        if not record.has(field):
            _add(errors, "STATE001", path + "." + field, {"reason": "required_field_missing"})

func _dictionary_or_error(value: Variant, path: String, errors: Array[Dictionary]) -> Dictionary:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    _add(errors, "STATE001", path, {"reason": "expected_dictionary"})
    return {}

func _deep_copy(value: Variant) -> Variant:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    if value is Array:
        return (value as Array).duplicate(true)
    return value

func _add(errors: Array[Dictionary], code: String, path: String, details: Dictionary) -> void:
    errors.append({
        "code": code,
        "path": path,
        "localization_key": "validation." + code.to_lower(),
        "details": details.duplicate(true),
    })
