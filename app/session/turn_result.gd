extends RefCounted

var passed: bool = false
var completed_month: bool = false
var start_date: String = ""
var end_date: String = ""
var start_turn: int = 0
var end_turn: int = 0
var phase_trace: Array[int] = []
var phase_names: Array[String] = []
var command_results: Array[Dictionary] = []
var events: Array[Dictionary] = []
var journaled_events: Array[Dictionary] = []
var phase_outputs: Dictionary = {}
var errors: Array[Dictionary] = []
var autosave_requested: bool = false
var state: RefCounted = null
var chronicle: RefCounted = null

func to_summary() -> Dictionary:
    return {
        "passed": passed,
        "completed_month": completed_month,
        "start_date": start_date,
        "end_date": end_date,
        "start_turn": start_turn,
        "end_turn": end_turn,
        "phase_trace": phase_trace.duplicate(),
        "phase_names": phase_names.duplicate(),
        "command_results": command_results.duplicate(true),
        "events": events.duplicate(true),
        "journaled_events": journaled_events.duplicate(true),
        "phase_outputs": phase_outputs.duplicate(true),
        "errors": errors.duplicate(true),
        "autosave_requested": autosave_requested,
    }
