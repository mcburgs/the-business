extends RefCounted

const PhaseDFixture = preload("res://tests/helpers/phase_d_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")

var _failures: Array[String] = []

func run() -> Dictionary:
    _test_exact_order_and_month_advance()
    _test_command_order_and_rejection_atomicity()
    _test_preflight_and_postflight_failure()
    return {"name": "phase_d_pipeline", "passed": _failures.is_empty(), "failures": _failures}

func _test_exact_order_and_month_advance() -> void:
    var state: RefCounted = PhaseDFixture.make_state()
    var chronicle: RefCounted = PhaseDFixture.make_chronicle()
    var pipeline: RefCounted = MonthPipeline.new()
    var result: RefCounted = pipeline.call("advance_month", state, chronicle, [PhaseDFixture.championship_command(state, 0)], PhaseDFixture.content_index())
    _expect(bool(result.get("passed")), "one-month pipeline should pass")
    _expect(result.get("phase_trace") == range(15), "phase trace must be exact ordinals 0..14")
    _expect((result.get("phase_names") as Array).size() == 15, "phase names must expose all 15 boundaries")
    _expect(str(result.get("end_date")) == "2001-02-01", "one turn must advance one calendar month")
    _expect(int(result.get("end_turn")) == 8, "turn number must increment once")
    _expect(bool(result.get("autosave_requested")), "successful postflight should request autosave")
    _expect(str(state.get("current_date")) == "2001-01-01", "pipeline must not mutate input state before publication")

func _test_command_order_and_rejection_atomicity() -> void:
    var state: RefCounted = PhaseDFixture.make_state()
    var chronicle: RefCounted = PhaseDFixture.make_chronicle()
    var first: RefCounted = PhaseDFixture.championship_command(state, 1, "person:PER00002")
    first.set("command_id", "command:CMDORDERB")
    first.set("priority", 5)
    var second: RefCounted = PhaseDFixture.championship_command(state, 1, "person:PER00001")
    second.set("command_id", "command:CMDORDERA")
    second.set("priority", 1)
    var bad: RefCounted = PhaseDFixture.championship_command(state, 1, "person:DOESNOTEXIST")
    bad.set("command_id", "command:CMDBAD001")
    bad.set("priority", 0)
    var result: RefCounted = MonthPipeline.new().call("advance_month", state, chronicle, [first, second, bad], PhaseDFixture.content_index())
    _expect(bool(result.get("passed")), "rejected strategic command should not abort an otherwise valid month")
    var output_state: RefCounted = result.get("state")
    var holders: Array = ((output_state.get("championships") as Dictionary)["championship:CHA00001"] as RefCounted).get("holder_person_ids")
    _expect(holders == ["person:PER00002"], "deterministic priority order must produce the expected final champion")
    var results: Array = result.get("command_results")
    _expect(results.size() == 3 and not bool((results[0] as Dictionary).get("accepted")) and bool((results[1] as Dictionary).get("accepted")) and bool((results[2] as Dictionary).get("accepted")), "commands must be committed in canonical sorted order")
    var original_holders: Array = (((state.get("championships") as Dictionary)["championship:CHA00001"] as RefCounted).get("holder_person_ids") as Array)
    _expect(original_holders == ["person:PER00001"], "rejected command and transactional month must not partially mutate retained input state")

func _test_preflight_and_postflight_failure() -> void:
    var corrupt: RefCounted = PhaseDFixture.make_state()
    corrupt.set("current_date", "not-a-date")
    var preflight: RefCounted = MonthPipeline.new().call("advance_month", corrupt, PhaseDFixture.make_chronicle(), [], PhaseDFixture.content_index())
    _expect(not bool(preflight.get("passed")) and (preflight.get("phase_trace") as Array) == [0], "preflight must stop corrupt starting state before downstream phases")
    _expect(not bool(preflight.get("autosave_requested")), "failed preflight cannot request autosave")

    var state: RefCounted = PhaseDFixture.make_state()
    var hook: Callable = Callable(self, "_corrupt_postflight")
    var postflight: RefCounted = MonthPipeline.new().call("advance_month", state, PhaseDFixture.make_chronicle(), [], PhaseDFixture.content_index(), {14: hook})
    _expect(not bool(postflight.get("passed")), "postflight must catch corruption introduced during the turn")
    _expect((postflight.get("phase_trace") as Array).size() == 15, "postflight corruption should occur only after phase 14 is reached")
    _expect(not bool(postflight.get("completed_month")) and not bool(postflight.get("autosave_requested")), "postflight failure must not publish a successful completed month")
    _expect(str(state.get("current_date")) == "2001-01-01", "postflight failure must leave original current state untouched")

func _corrupt_postflight(context: RefCounted) -> Dictionary:
    (context.get("state") as RefCounted).set("turn_number", -5)
    return {"passed": true, "errors": []}

func _expect(condition: bool, message: String) -> void:
    if not condition: _failures.append(message)
