extends RefCounted

var command_schema_version: int = 1
var command_id: String = ""
var command_type: String = ""
var issued_for_turn: int = 0
var issued_on: String = ""
var issuer: Dictionary = {}
var turn_phase_ordinal: int = 0
var priority: int = 0
var issuer_key: String = ""
var payload: Dictionary = {}

func ordering_tuple() -> Array:
    return [turn_phase_ordinal, priority, issuer_key, command_id]

func to_dict() -> Dictionary:
    return {
        "command_schema_version": command_schema_version,
        "command_id": command_id,
        "command_type": command_type,
        "issued_for_turn": issued_for_turn,
        "issued_on": issued_on,
        "issuer": issuer.duplicate(true),
        "ordering": {
            "turn_phase_ordinal": turn_phase_ordinal,
            "priority": priority,
            "issuer_key": issuer_key,
        },
        "payload": payload.duplicate(true),
    }
