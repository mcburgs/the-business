extends RefCounted

const RandomService = preload("res://app/session/random_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var a: RefCounted = RandomService.new(987654321)
    var b: RefCounted = RandomService.new(987654321)
    var sequence_a: Array = []
    var sequence_b: Array = []
    for index: int in range(8):
        sequence_a.append(a.call("draw_int_range", 0, 1000000, "diagnostic_a" + str(index)))
        sequence_b.append(b.call("draw_int_range", 0, 1000000, ""))
    _expect(sequence_a == sequence_b, "Diagnostic tags must not create hidden RNG streams or alter draws.", failures)

    var source: RefCounted = RandomService.new(11223344)
    source.call("draw_float", "prime")
    source.call("draw_int_range", 1, 10, "prime_2")
    var checkpoint: RefCounted = source.call("capture", 12)
    var expected_next: float = source.call("draw_float", "after_checkpoint")

    var restored: RefCounted = RandomService.new(0)
    var restore_result: Dictionary = restored.call("restore", checkpoint)
    _expect(bool(restore_result.get("passed", false)), "Saved RNG checkpoint must restore.", failures)
    var restored_next: float = restored.call("draw_float", "same_position")
    _expect(restored_next == expected_next, "Restored RNG state must reproduce the subsequent draw exactly.", failures)
    _expect(str(checkpoint.get("provider_id")) == "godot.random_number_generator", "RNG provider identity must be explicit.", failures)
    _expect(str(checkpoint.get("stream_policy")) == "single_root_v1", "Phase C must retain a single root RNG stream.", failures)

    return {"name": "phase_c_random_service", "passed": failures.is_empty(), "failures": failures}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
