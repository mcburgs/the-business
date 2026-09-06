extends RefCounted

var fired_event_ids: Array = []
var active_event_ids: Array = []
var cooldown_by_event_id: Dictionary = {}
var choice_history: Array = []

func to_dict() -> Dictionary:
    return {
        "fired_event_ids": fired_event_ids.duplicate(true),
        "active_event_ids": active_event_ids.duplicate(true),
        "cooldown_by_event_id": cooldown_by_event_id.duplicate(true),
        "choice_history": choice_history.duplicate(true),
    }
