extends RefCounted

const PhaseDFixture = preload("res://tests/helpers/phase_d_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = PhaseDFixture.make_state()
    var chronicle: RefCounted = PhaseDFixture.make_chronicle(12)
    var pipeline: RefCounted = MonthPipeline.new()
    var expected_by_date: Dictionary = {}
    for month_index: int in range(12):
        var result: RefCounted = pipeline.call("advance_month", state, chronicle, [PhaseDFixture.championship_command(state, month_index)], PhaseDFixture.content_index())
        if not bool(result.get("passed")):
            failures.append("month " + str(month_index + 1) + " failed: " + JSON.stringify(result.get("errors")))
            break
        state = result.get("state")
        chronicle = result.get("chronicle")
        expected_by_date[str(state.get("current_date"))] = HistoricalProjection.from_campaign_state(state)
    if failures.is_empty():
        if str(state.get("current_date")) != "2002-01-01": failures.append("12 months should advance fixture to 2002-01-01")
        if (chronicle.get("checkpoints") as Array).size() != 2: failures.append("12-month run should use sparse checkpoints, not full monthly snapshots")
        if (chronicle.get("deltas") as Array).size() != 10: failures.append("monthly changes between first and annual checkpoint should be represented as deltas")
        if (chronicle.get("event_journal") as Array).size() != 24: failures.append("each month should journal command fact plus MonthAdvanced event")
        if not bool(ChronicleValidator.new().validate(chronicle)["passed"]): failures.append("committed Chronicle must satisfy integrity validation")
        var target_date: String = "2001-07-01"
        var before_state: Dictionary = CampaignStateCodec.new().encode(state)
        var reconstructed: Dictionary = ChronicleQueryService.new().get_projection(chronicle, target_date)
        if not bool(reconstructed["passed"]): failures.append("prior month must reconstruct from recorded checkpoint/deltas with no simulation or RNG service present")
        elif reconstructed["projection"] != expected_by_date[target_date]: failures.append("reconstructed prior projection must equal expected recorded projection")
        if CampaignStateCodec.new().encode(state) != before_state: failures.append("historical reconstruction must not mutate current CampaignState")
        var holder: Array = (reconstructed.get("projection", {}).get("championships", {}).get("championship:CHA00001", {}).get("holder_person_ids", []) as Array)
        if holder != ["person:PER00002"]: failures.append("reconstructed month must preserve the historical title holder")

        var broken_delta_store: RefCounted = PhaseDFixture.make_chronicle()
        broken_delta_store.set("checkpoints", (chronicle.get("checkpoints") as Array).slice(0, 1, 1, true))
        broken_delta_store.set("deltas", [{"date": "2001-03-01", "operations": [{"op": "replace", "path": ["does_not_exist", "x"], "value": 1}]}])
        var broken_reconstruction: Dictionary = ChronicleQueryService.new().get_projection(broken_delta_store, "2001-03-01")
        if bool(broken_reconstruction["passed"]) or str((broken_reconstruction["errors"][0] as Dictionary).get("code")) != "CHR003": failures.append("impossible delta path must fail with CHR003")

        var broken_id = _clone_chronicle(chronicle)
        (broken_id.get("event_journal")[0] as Dictionary)["entity_ids"] = ["person:UNRESOLVED"]
        var id_validation: Dictionary = ChronicleValidator.new().validate(broken_id)
        if bool(id_validation["passed"]) or not _has_code(id_validation["errors"], "CHR002"): failures.append("unresolved historical identity must fail CHR002")

        var broken_sequence = _clone_chronicle(chronicle)
        (broken_sequence.get("event_journal")[0] as Dictionary)["sequence_id"] = 99
        var seq_validation: Dictionary = ChronicleValidator.new().validate(broken_sequence)
        if bool(seq_validation["passed"]) or not _has_code(seq_validation["errors"], "CHR001"): failures.append("invalid journal sequence must fail CHR001")

        var tombstone_catalog: Dictionary = chronicle.get("identity_catalog")
        if not tombstone_catalog.has("person:PER00002"): failures.append("identity catalog must retain historical person identity")
        else:
            var record: Dictionary = tombstone_catalog["person:PER00002"]
            record["active"] = false
            record["last_seen_on"] = "2001-07-01"
            tombstone_catalog["person:PER00002"] = record
            if not bool(ChronicleValidator.new().validate(chronicle)["passed"]): failures.append("inactive/tombstoned historical identity must remain resolvable")
    return {
        "name": "phase_d_chronicle_reconstruction",
        "passed": failures.is_empty(),
        "failures": failures,
        "months_completed": 12 if failures.is_empty() else expected_by_date.size(),
        "chronicle_counts": chronicle.call("counts") if chronicle != null else {},
        "reconstruction_dependencies": {"simulation_resolution": "unavailable", "random_service": "unavailable"},
    }

func _clone_chronicle(store: RefCounted) -> RefCounted:
    const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
    return ChronicleCodec.new().decode(ChronicleCodec.new().encode(store))["chronicle"]

func _has_code(errors: Array, code: String) -> bool:
    for error: Variant in errors:
        if error is Dictionary and str((error as Dictionary).get("code")) == code: return true
    return false
