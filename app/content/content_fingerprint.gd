extends RefCounted

func compute(resolved_pack_manifests: Array[Dictionary], records_by_family: Dictionary) -> String:
    var normalized_packs: Array[Dictionary] = resolved_pack_manifests.duplicate(true)
    normalized_packs.sort_custom(_compare_pack_id)

    var normalized_records: Dictionary = {}
    var family_names: Array[String] = []
    for family_value: Variant in records_by_family.keys():
        family_names.append(str(family_value))
    family_names.sort()
    for family: String in family_names:
        var records_value: Variant = records_by_family.get(family, [])
        var records: Array = []
        if records_value is Array:
            records = (records_value as Array).duplicate(true)
            records.sort_custom(_compare_record_id)
        normalized_records[family] = records

    var canonical_value: Dictionary = {
        "packs": normalized_packs,
        "records": normalized_records,
    }
    var canonical_text: String = _canonical_json(canonical_value)
    var context: HashingContext = HashingContext.new()
    var start_error: Error = context.start(HashingContext.HASH_SHA256)
    if start_error != OK:
        return ""
    context.update(canonical_text.to_utf8_buffer())
    return context.finish().hex_encode()

func _canonical_json(value: Variant) -> String:
    if value is Dictionary:
        var dictionary: Dictionary = value
        var keys: Array[String] = []
        for key_value: Variant in dictionary.keys():
            keys.append(str(key_value))
        keys.sort()
        var parts: Array[String] = []
        for key: String in keys:
            parts.append(JSON.stringify(key) + ":" + _canonical_json(dictionary.get(key)))
        return "{" + ",".join(parts) + "}"
    if value is Array:
        var array_value: Array = value
        var parts: Array[String] = []
        for item: Variant in array_value:
            parts.append(_canonical_json(item))
        return "[" + ",".join(parts) + "]"
    return JSON.stringify(value)

func _compare_pack_id(left: Dictionary, right: Dictionary) -> bool:
    return str(left.get("pack_id", "")) < str(right.get("pack_id", ""))

func _compare_record_id(left: Variant, right: Variant) -> bool:
    if left is Dictionary and right is Dictionary:
        return str((left as Dictionary).get("id", "")) < str((right as Dictionary).get("id", ""))
    return JSON.stringify(left) < JSON.stringify(right)
