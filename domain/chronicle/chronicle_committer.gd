extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")
const ChronicleDelta = preload("res://domain/chronicle/chronicle_delta.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const IdentityCatalogService = preload("res://domain/chronicle/identity_catalog_service.gd")

var _query: RefCounted = ChronicleQueryService.new()
var _identity: RefCounted = IdentityCatalogService.new()

func commit_month(store: RefCounted, state: RefCounted, events: Array[Dictionary]) -> Dictionary:
    var date: String = str(state.get("current_date"))
    var previous_projection: Dictionary = {}
    if not str(store.get("head_date")).is_empty():
        var previous_result: Dictionary = _query.call("get_projection", store, str(store.get("head_date")))
        if not bool(previous_result.get("passed", false)): return previous_result
        previous_projection = previous_result["projection"]
    _identity.call("update_from_state", store.get("identity_catalog"), state, date)
    var promoted: Array[Dictionary] = []
    for transient_event: Dictionary in events:
        var journaled: Dictionary = transient_event.duplicate(true)
        var next_sequence: int = int(store.get("head_sequence")) + 1
        journaled["event_id"] = "event:E" + str(next_sequence).pad_zeros(9)
        journaled["sequence_id"] = next_sequence
        store.get("event_journal").append(journaled)
        store.set("head_sequence", next_sequence)
        promoted.append(journaled)
        _index_event(store, journaled)
        if str(journaled.get("event_type")) == "TerritoryViolated":
            var agreement_id: String = str((journaled.get("facts", {}) as Dictionary).get("agreement_id", ""))
            if (state.get("agreements") as Dictionary).has(agreement_id):
                ((state.get("agreements") as Dictionary)[agreement_id] as RefCounted).set("last_violation_event_id", journaled.get("event_id"))
    var projection: Dictionary = HistoricalProjection.from_campaign_state(state, date)
    var cadence: int = maxi(1, int(store.get("checkpoint_cadence_months")))
    var should_checkpoint: bool = (store.get("checkpoints") as Array).is_empty() or int(state.get("turn_number")) % cadence == 0
    if should_checkpoint:
        store.set("checkpoint_generation", int(store.get("checkpoint_generation")) + 1)
        store.get("checkpoints").append({"date": date, "generation": store.get("checkpoint_generation"), "projection": projection.duplicate(true)})
    elif not previous_projection.is_empty():
        var delta: Dictionary = ChronicleDelta.between(previous_projection, projection, date)
        if not (delta["operations"] as Array).is_empty(): store.get("deltas").append(delta)
    _sample_metrics(store, state, date)
    store.set("head_date", date)
    return {"passed": true, "errors": [], "journaled_events": promoted, "projection": projection}

func _sample_metrics(store: RefCounted, state: RefCounted, date: String) -> void:
    for definition: Dictionary in store.get("metric_definitions"):
        if str(definition.get("cadence", "")) != "monthly": continue
        if str(definition.get("subject_scope", "")) == "promotion" and str(definition.get("field", "")) in ["prestige", "momentum"]:
            for promotion_id: String in DomainIds.sorted_keys(state.get("promotions")):
                var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
                var series_id: String = str(definition.get("metric_id")) + "|" + promotion_id
                if not (store.get("metric_series") as Dictionary).has(series_id): store.get("metric_series")[series_id] = []
                store.get("metric_series")[series_id].append({"date": date, "metric_id": definition.get("metric_id"), "subject_id": promotion_id, "value": float(promotion.get(str(definition.get("field"))))})

func _index_event(store: RefCounted, event: Dictionary) -> void:
    var index: Dictionary = store.get("chronicle_index")
    var by_date: Dictionary = index.get("by_date", {})
    var by_entity: Dictionary = index.get("by_entity", {})
    var date: String = str(event.get("occurred_on"))
    if not by_date.has(date): by_date[date] = []
    by_date[date].append(event["event_id"])
    for entity_id: Variant in event.get("entity_ids", []):
        var key: String = str(entity_id)
        if not by_entity.has(key): by_entity[key] = []
        by_entity[key].append(event["event_id"])
    index["by_date"] = by_date
    index["by_entity"] = by_entity
    store.set("chronicle_index", index)
