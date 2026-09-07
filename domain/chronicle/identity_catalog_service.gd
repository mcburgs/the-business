extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")

const DEFINITION_STORES: Dictionary = {
    "markets": ["market_id", "market", "market_id"],
}

const STORES: Dictionary = {
    "people": ["id", "person", "display_name", "lifecycle"],
    "promotions": ["id", "promotion", "brand_name", "lifecycle"],
    "touring_companies": ["id", "touring", "name", "status"],
    "contracts": ["id", "contract", "id", "status"],
    "championships": ["id", "championship", "definition_id", "status"],
    "programs": ["id", "program", "id", "status"],
    "media_deals": ["id", "media_deal", "id", "status"],
    "agreements": ["id", "agreement", "id", "status"],
    "relationships": ["id", "relationship", "id", "active"],
}

func update_from_state(catalog: Dictionary, state: RefCounted, date: String) -> void:
    for store_name: Variant in DEFINITION_STORES.keys():
        var config: Array = DEFINITION_STORES[store_name]
        var store: Dictionary = state.get(str(store_name))
        for entity_id: String in DomainIds.sorted_keys(store):
            _upsert(catalog, entity_id, str(config[1]), str((store[entity_id] as RefCounted).get(str(config[2]))), "active", date)
    for store_name: Variant in STORES.keys():
        var config: Array = STORES[store_name]
        var store: Dictionary = state.get(str(store_name))
        for entity_id: String in DomainIds.sorted_keys(store):
            var entity: RefCounted = store[entity_id]
            var display_name: String = str(entity.get(str(config[2])))
            if display_name.is_empty(): display_name = entity_id
            var lifecycle: String = str(entity.get(str(config[3])))
            if lifecycle.is_empty(): lifecycle = "active"
            _upsert(catalog, entity_id, str(config[1]), display_name, lifecycle, date)

func _upsert(catalog: Dictionary, entity_id: String, family: String, display_name: String, lifecycle: String, date: String) -> void:
    if display_name.is_empty(): display_name = entity_id
    if not catalog.has(entity_id):
        catalog[entity_id] = {
            "entity_id": entity_id, "family": family, "first_seen_on": date, "last_seen_on": date,
            "active": lifecycle in ["active", "available"],
            "epochs": [{"from": date, "to": null, "display_name": display_name, "lifecycle": lifecycle}],
        }
        return
    var record: Dictionary = catalog[entity_id]
    record["last_seen_on"] = date
    record["active"] = lifecycle in ["active", "available"]
    var epochs: Array = record.get("epochs", [])
    if epochs.is_empty() or str((epochs[epochs.size() - 1] as Dictionary).get("display_name")) != display_name or str((epochs[epochs.size() - 1] as Dictionary).get("lifecycle")) != lifecycle:
        if not epochs.is_empty(): (epochs[epochs.size() - 1] as Dictionary)["to"] = date
        epochs.append({"from": date, "to": null, "display_name": display_name, "lifecycle": lifecycle})
    record["epochs"] = epochs
    catalog[entity_id] = record

func resolve(catalog: Dictionary, entity_id: String) -> bool:
    return catalog.has(entity_id)
