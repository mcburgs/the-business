extends RefCounted

const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION
var head_date: String = ""
var head_sequence: int = 0
var checkpoint_generation: int = 0
var checkpoint_cadence_months: int = 12
var event_journal: Array[Dictionary] = []
var metric_definitions: Array[Dictionary] = []
var metric_series: Dictionary = {}
var checkpoints: Array[Dictionary] = []
var deltas: Array[Dictionary] = []
var chronicle_index: Dictionary = {"by_date": {}, "by_entity": {}, "lifetimes": {}}
var artifact_index: Dictionary = {}
var identity_catalog: Dictionary = {}

func counts() -> Dictionary:
    var metric_count: int = 0
    for series_value: Variant in metric_series.values():
        if series_value is Array: metric_count += (series_value as Array).size()
    return {
        "events": event_journal.size(),
        "metrics": metric_count,
        "deltas": deltas.size(),
        "checkpoints": checkpoints.size(),
        "identities": identity_catalog.size(),
    }
