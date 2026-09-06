extends RefCounted

static func between(previous: Dictionary, current: Dictionary, date: String) -> Dictionary:
    var operations: Array[Dictionary] = []
    _diff(previous, current, [], operations)
    return {"date": date, "operations": operations}

static func apply(base: Dictionary, delta: Dictionary) -> Dictionary:
    var output: Dictionary = base.duplicate(true)
    var errors: Array[Dictionary] = []
    for index: int in range((delta.get("operations", []) as Array).size()):
        var operation: Dictionary = delta["operations"][index]
        var applied: bool = _apply_operation(output, operation)
        if not applied:
            errors.append({"code": "CHR003", "path": "deltas.operations[" + str(index) + "]", "localization_key": "validation.chr003", "details": {"operation": operation.duplicate(true)}})
            return {"passed": false, "projection": {}, "errors": errors}
    return {"passed": true, "projection": output, "errors": []}

static func _diff(left: Variant, right: Variant, path: Array, operations: Array[Dictionary]) -> void:
    if left is Dictionary and right is Dictionary:
        var left_dict: Dictionary = left
        var right_dict: Dictionary = right
        var keys: Array[String] = []
        for key: Variant in left_dict.keys(): keys.append(str(key))
        for key: Variant in right_dict.keys():
            if not str(key) in keys: keys.append(str(key))
        keys.sort()
        for key: String in keys:
            var child_path: Array = path.duplicate()
            child_path.append(key)
            if not right_dict.has(key):
                operations.append({"op": "remove", "path": child_path})
            elif not left_dict.has(key):
                operations.append({"op": "add", "path": child_path, "value": _copy(right_dict[key])})
            else:
                _diff(left_dict[key], right_dict[key], child_path, operations)
        return
    if left != right:
        operations.append({"op": "replace", "path": path.duplicate(), "value": _copy(right)})

static func _apply_operation(root: Dictionary, operation: Dictionary) -> bool:
    var path_value: Variant = operation.get("path")
    if not path_value is Array or (path_value as Array).is_empty(): return false
    var path: Array = path_value
    var cursor: Dictionary = root
    for index: int in range(path.size() - 1):
        var key: String = str(path[index])
        if not cursor.has(key) or not cursor[key] is Dictionary: return false
        cursor = cursor[key]
    var leaf: String = str(path[path.size() - 1])
    match str(operation.get("op", "")):
        "add":
            if cursor.has(leaf): return false
            cursor[leaf] = _copy(operation.get("value"))
        "replace":
            if not cursor.has(leaf): return false
            cursor[leaf] = _copy(operation.get("value"))
        "remove":
            if not cursor.has(leaf): return false
            cursor.erase(leaf)
        _: return false
    return true

static func _copy(value: Variant) -> Variant:
    if value is Dictionary: return (value as Dictionary).duplicate(true)
    if value is Array: return (value as Array).duplicate(true)
    return value
