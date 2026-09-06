extends RefCounted

const NARRATIVE_CONTEXTS: Array[String] = ["public_kayfabe", "backstage_business", "system_neutral"]

func validate(campaign_manifest: Dictionary, records_by_family: Dictionary) -> Array[Dictionary]:
    var errors: Array[Dictionary] = []
    var id_to_family: Dictionary = {}

    var family_names: Array[String] = []
    for family_value: Variant in records_by_family.keys():
        family_names.append(str(family_value))
    family_names.sort()

    for family: String in family_names:
        var records_value: Variant = records_by_family.get(family, [])
        if not records_value is Array:
            continue
        for index: int in range((records_value as Array).size()):
            var record_value: Variant = (records_value as Array)[index]
            if not record_value is Dictionary:
                continue
            var record: Dictionary = record_value
            var content_id: String = str(record.get("id", ""))
            if content_id.is_empty():
                continue
            if id_to_family.has(content_id):
                errors.append(_error("ID002", "%s[%d].id" % [family, index], "Duplicate content ID '%s'; first seen in family '%s'." % [content_id, str(id_to_family.get(content_id, ""))]))
            else:
                id_to_family[content_id] = family

    _require_ref(campaign_manifest, "map_id", "map", id_to_family, "manifest.map_id", errors)
    _require_ref(campaign_manifest, "ruleset_id", "rulesets", id_to_family, "manifest.ruleset_id", errors)

    _validate_media_tech(records_by_family, id_to_family, errors)
    _validate_map(records_by_family, id_to_family, errors)
    _validate_regions(records_by_family, id_to_family, errors)
    _validate_markets(records_by_family, id_to_family, errors)
    _validate_venues(records_by_family, id_to_family, errors)
    _validate_people(records_by_family, id_to_family, errors)
    _validate_promotions(records_by_family, id_to_family, errors)
    _validate_media_outlets(records_by_family, id_to_family, errors)
    _validate_championships(records_by_family, id_to_family, errors)
    _validate_contracts(records_by_family, id_to_family, errors)
    _validate_history_hooks(records_by_family, id_to_family, errors)
    return errors

func _validate_media_tech(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "media_tech"):
        _require_ref(indexed.record, "medium_id", "media_mediums", ids, indexed.path + ".medium_id", errors)

func _validate_map(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "map"):
        var record: Dictionary = indexed.record
        _require_ref_array(record, "region_ids", "regions", ids, indexed.path + ".region_ids", errors)
        _require_ref_array(record, "market_ids", "markets", ids, indexed.path + ".market_ids", errors)
        var connections_value: Variant = record.get("connections", [])
        if connections_value is Array:
            for connection_index: int in range((connections_value as Array).size()):
                var connection_value: Variant = (connections_value as Array)[connection_index]
                if not connection_value is Dictionary:
                    continue
                var connection: Dictionary = connection_value
                var base_path: String = "%s.connections[%d]" % [indexed.path, connection_index]
                _require_ref(connection, "from_market_id", "markets", ids, base_path + ".from_market_id", errors)
                _require_ref(connection, "to_market_id", "markets", ids, base_path + ".to_market_id", errors)

func _validate_regions(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "regions"):
        _require_ref_array(indexed.record, "market_ids", "markets", ids, indexed.path + ".market_ids", errors)

func _validate_markets(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "markets"):
        _require_ref(indexed.record, "region_id", "regions", ids, indexed.path + ".region_id", errors)
        _require_ref_array(indexed.record, "venue_ids", "venues", ids, indexed.path + ".venue_ids", errors)

func _validate_venues(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "venues"):
        _require_ref(indexed.record, "market_id", "markets", ids, indexed.path + ".market_id", errors)

func _validate_people(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "people"):
        _require_ref_array(indexed.record, "role_ids", "roles", ids, indexed.path + ".role_ids", errors)
        _require_ref(indexed.record, "home_market_id", "markets", ids, indexed.path + ".home_market_id", errors)

func _validate_promotions(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "promotions"):
        var record: Dictionary = indexed.record
        _require_ref(record, "owner_person_seed_id", "people", ids, indexed.path + ".owner_person_seed_id", errors)
        _require_ref(record, "booker_person_seed_id", "people", ids, indexed.path + ".booker_person_seed_id", errors)
        _require_ref_array(record, "home_market_ids", "markets", ids, indexed.path + ".home_market_ids", errors)
        var strategy_id: Variant = record.get("strategy_profile_id")
        if strategy_id != null:
            _require_ref(record, "strategy_profile_id", "promotion_strategies", ids, indexed.path + ".strategy_profile_id", errors)

func _validate_media_outlets(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "media_outlets"):
        var record: Dictionary = indexed.record
        _require_ref(record, "medium_id", "media_mediums", ids, indexed.path + ".medium_id", errors)
        _require_ref(record, "tech_id", "media_tech", ids, indexed.path + ".tech_id", errors)
        _require_ref_array(record, "market_ids", "markets", ids, indexed.path + ".market_ids", errors)

func _validate_championships(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "championships"):
        var record: Dictionary = indexed.record
        _require_ref(record, "promotion_seed_id", "promotions", ids, indexed.path + ".promotion_seed_id", errors)
        _require_ref_array(record, "holder_person_seed_ids", "people", ids, indexed.path + ".holder_person_seed_ids", errors)
        _require_ref_array(record, "recognition_market_ids", "markets", ids, indexed.path + ".recognition_market_ids", errors)

func _validate_contracts(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "contracts"):
        var record: Dictionary = indexed.record
        _require_ref(record, "person_seed_id", "people", ids, indexed.path + ".person_seed_id", errors)
        _require_ref(record, "promotion_seed_id", "promotions", ids, indexed.path + ".promotion_seed_id", errors)

func _validate_history_hooks(records: Dictionary, ids: Dictionary, errors: Array[Dictionary]) -> void:
    for indexed: Dictionary in _indexed(records, "history_hooks"):
        var record: Dictionary = indexed.record
        var context: String = str(record.get("narrative_context", ""))
        if not NARRATIVE_CONTEXTS.has(context):
            errors.append(_error("NAR001", indexed.path + ".narrative_context", "NarrativeContext must be public_kayfabe, backstage_business, or system_neutral."))
        var subject_ids_value: Variant = record.get("subject_ids", [])
        if subject_ids_value is Array:
            for subject_index: int in range((subject_ids_value as Array).size()):
                var subject_id: String = str((subject_ids_value as Array)[subject_index])
                if not ids.has(subject_id):
                    errors.append(_error("REF001", "%s.subject_ids[%d]" % [indexed.path, subject_index], "Required subject reference '%s' does not exist." % subject_id))
        var market_id: Variant = record.get("market_id")
        if market_id != null:
            _require_ref(record, "market_id", "markets", ids, indexed.path + ".market_id", errors)

func _require_ref(record: Dictionary, field: String, expected_family: String, ids: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    var target_id: String = str(record.get(field, ""))
    if target_id.is_empty() or not ids.has(target_id):
        errors.append(_error("REF001", path, "Required reference '%s' does not exist." % target_id))
        return
    var actual_family: String = str(ids.get(target_id, ""))
    if actual_family != expected_family:
        errors.append(_error("REF003", path, "Reference '%s' targets family '%s'; expected '%s'." % [target_id, actual_family, expected_family]))

func _require_ref_array(record: Dictionary, field: String, expected_family: String, ids: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    var values: Variant = record.get(field, [])
    if not values is Array:
        return
    for index: int in range((values as Array).size()):
        var synthetic: Dictionary = {"value": (values as Array)[index]}
        _require_ref(synthetic, "value", expected_family, ids, "%s[%d]" % [path, index], errors)

func _indexed(records: Dictionary, family: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var values: Variant = records.get(family, [])
    if not values is Array:
        return output
    for index: int in range((values as Array).size()):
        var record_value: Variant = (values as Array)[index]
        if record_value is Dictionary:
            output.append({"record": record_value, "path": "%s[%d]" % [family, index]})
    return output

func _error(code: String, path: String, message: String) -> Dictionary:
    return {"code": code, "path": path, "message": message}
