extends RefCounted

var _records_by_family: Dictionary = {}
var _pack_manifests: Array[Dictionary] = []
var _campaign_manifest: Dictionary = {}
var _fingerprint: String = ""

func _init(records_by_family: Dictionary = {}, pack_manifests: Array[Dictionary] = [], campaign_manifest: Dictionary = {}, fingerprint: String = "") -> void:
    _records_by_family = records_by_family.duplicate(true)
    _pack_manifests = pack_manifests.duplicate(true)
    _campaign_manifest = campaign_manifest.duplicate(true)
    _fingerprint = fingerprint

func has(family: String, content_id: String) -> bool:
    return not get_record(family, content_id).is_empty()

func get_record(family: String, content_id: String) -> Dictionary:
    var records_value: Variant = _records_by_family.get(family, [])
    if not records_value is Array:
        return {}
    for record_value: Variant in records_value:
        if record_value is Dictionary and str((record_value as Dictionary).get("id", "")) == content_id:
            return (record_value as Dictionary).duplicate(true)
    return {}

func get_family(family: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var records_value: Variant = _records_by_family.get(family, [])
    if not records_value is Array:
        return output
    for record_value: Variant in records_value:
        if record_value is Dictionary:
            output.append((record_value as Dictionary).duplicate(true))
    return output

func count(family: String) -> int:
    return get_family(family).size()

func family_names() -> Array[String]:
    var output: Array[String] = []
    for family_value: Variant in _records_by_family.keys():
        output.append(str(family_value))
    output.sort()
    return output

func pack_manifests() -> Array[Dictionary]:
    return _pack_manifests.duplicate(true)

func campaign_manifest() -> Dictionary:
    return _campaign_manifest.duplicate(true)

func fingerprint() -> String:
    return _fingerprint
