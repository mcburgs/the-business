extends RefCounted

var state: RefCounted
var chronicle: RefCounted
var random_service: RefCounted
var commands: Array = []
var content_index: Dictionary = {}
var phase_hooks: Dictionary = {}
var start_date: String = ""
var target_date: String = ""
var start_turn: int = 0
var planning_snapshot: Dictionary = {}
var start_projection: Dictionary = {}
var transient_events: Array[Dictionary] = []
var command_results: Array[Dictionary] = []
var diagnostics: Array[Dictionary] = []
