extends RefCounted

var subject_id: String = ""
var field_id: String = ""
var status: String = "unknown"
var value: Variant = null
var estimate_range: Variant = null
var qualitative: Variant = null
var confidence: Variant = null
var observed_on: Variant = null

func to_dict() -> Dictionary:
    return {
        "subject_id": subject_id,
        "field_id": field_id,
        "status": status,
        "value": value,
        "estimate_range": estimate_range,
        "qualitative": qualitative,
        "confidence": confidence,
        "observed_on": observed_on,
    }
