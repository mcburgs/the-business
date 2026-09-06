extends RefCounted

var _root_schema: Dictionary = {}

func _init(root_schema: Dictionary = {}) -> void:
    _root_schema = root_schema.duplicate(true)

func validate(value: Variant, schema: Dictionary, path: String = "$") -> Array[Dictionary]:
    var errors: Array[Dictionary] = []
    _validate_into(value, schema, path, errors)
    return errors

func definition(name: String) -> Dictionary:
    var defs_value: Variant = _root_schema.get("$defs", {})
    if not defs_value is Dictionary:
        return {}
    var defs: Dictionary = defs_value
    var found: Variant = defs.get(name, {})
    if found is Dictionary:
        return (found as Dictionary).duplicate(true)
    return {}

func _validate_into(value: Variant, schema: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if schema.has("$ref"):
        var resolved: Dictionary = _resolve_ref(str(schema.get("$ref", "")))
        if resolved.is_empty():
            _append_error(errors, path, "STATE001", "Schema reference could not be resolved: %s" % str(schema.get("$ref", "")))
            return
        _validate_into(value, resolved, path, errors)
        return

    if schema.has("anyOf"):
        var variants_value: Variant = schema.get("anyOf", [])
        if not variants_value is Array:
            _append_error(errors, path, "STATE001", "Schema anyOf is malformed.")
            return
        var matched: bool = false
        for variant_schema_value: Variant in variants_value:
            if not variant_schema_value is Dictionary:
                continue
            var variant_errors: Array[Dictionary] = []
            _validate_into(value, variant_schema_value as Dictionary, path, variant_errors)
            if variant_errors.is_empty():
                matched = true
                break
        if not matched:
            _append_error(errors, path, "STATE001", "Value does not match any permitted schema shape.")
        return

    if schema.has("enum"):
        var allowed_value: Variant = schema.get("enum", [])
        if allowed_value is Array and not (allowed_value as Array).has(value):
            _append_error(errors, path, "STATE001", "Value is not one of the permitted enum values.")
            return

    if schema.has("type"):
        var expected_type: String = str(schema.get("type", ""))
        if not _matches_type(value, expected_type):
            _append_error(errors, path, "STATE001", "Expected %s, got %s." % [expected_type, type_string(typeof(value))])
            return

    if value is Dictionary:
        _validate_object(value as Dictionary, schema, path, errors)
    elif value is Array:
        _validate_array(value as Array, schema, path, errors)
    elif value is String:
        _validate_string(str(value), schema, path, errors)
    elif value is int or value is float:
        _validate_number(float(value), schema, path, errors)

func _validate_object(value: Dictionary, schema: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    var required_value: Variant = schema.get("required", [])
    if required_value is Array:
        for field_value: Variant in required_value:
            var field: String = str(field_value)
            if not value.has(field):
                _append_error(errors, _child_path(path, field), "STATE001", "Required field is missing.")

    var properties: Dictionary = {}
    var properties_value: Variant = schema.get("properties", {})
    if properties_value is Dictionary:
        properties = properties_value

    if schema.has("propertyNames"):
        var property_names_value: Variant = schema.get("propertyNames", {})
        if property_names_value is Dictionary:
            var property_names: Dictionary = property_names_value
            var enum_value: Variant = property_names.get("enum", [])
            if enum_value is Array:
                for key_value: Variant in value.keys():
                    var key_name: String = str(key_value)
                    if not (enum_value as Array).has(key_name):
                        _append_error(errors, _child_path(path, key_name), "STATE001", "Property name is not permitted by the schema.")

    for key_value: Variant in value.keys():
        var key_name: String = str(key_value)
        if properties.has(key_name):
            var child_schema_value: Variant = properties.get(key_name)
            if child_schema_value is Dictionary:
                _validate_into(value.get(key_value), child_schema_value as Dictionary, _child_path(path, key_name), errors)
            continue

        var additional_value: Variant = schema.get("additionalProperties", true)
        if additional_value is bool and not bool(additional_value):
            _append_error(errors, _child_path(path, key_name), "STATE001", "Unknown field is not permitted by schema v1.")
        elif additional_value is Dictionary:
            _validate_into(value.get(key_value), additional_value as Dictionary, _child_path(path, key_name), errors)

func _validate_array(value: Array, schema: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if schema.has("minItems") and value.size() < int(schema.get("minItems", 0)):
        _append_error(errors, path, "STATE001", "Array contains fewer items than permitted.")

    if bool(schema.get("uniqueItems", false)):
        var seen: Dictionary = {}
        for index: int in range(value.size()):
            var marker: String = JSON.stringify(value[index])
            if seen.has(marker):
                _append_error(errors, "%s[%d]" % [path, index], "STATE001", "Array item duplicates an earlier item but uniqueItems is required.")
            else:
                seen[marker] = true

    var item_schema_value: Variant = schema.get("items", {})
    if item_schema_value is Dictionary and not (item_schema_value as Dictionary).is_empty():
        for index: int in range(value.size()):
            _validate_into(value[index], item_schema_value as Dictionary, "%s[%d]" % [path, index], errors)

func _validate_string(value: String, schema: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if schema.has("minLength") and value.length() < int(schema.get("minLength", 0)):
        _append_error(errors, path, "STATE001", "String is shorter than the schema minimum.")

    if schema.has("pattern"):
        var regex: RegEx = RegEx.new()
        var compile_error: Error = regex.compile(str(schema.get("pattern", "")))
        if compile_error != OK:
            _append_error(errors, path, "STATE001", "Schema regex could not be compiled.")
        elif regex.search(value) == null:
            _append_error(errors, path, "ID001" if path.ends_with(".id") or path.ends_with("_id") or path.ends_with("pack_id") else "STATE001", "String does not match the required pattern.")

func _validate_number(value: float, schema: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    if schema.has("minimum") and value < float(schema.get("minimum", 0.0)):
        _append_error(errors, path, "STATE001", "Number is below the permitted minimum.")

func _matches_type(value: Variant, expected_type: String) -> bool:
    match expected_type:
        "object":
            return value is Dictionary
        "array":
            return value is Array
        "string":
            return value is String
        "integer":
            if value is int:
                return true
            if value is float:
                var numeric_value: float = float(value)
                return is_finite(numeric_value) and numeric_value == floor(numeric_value)
            return false
        "number":
            return value is int or value is float
        "boolean":
            return value is bool
        "null":
            return value == null
        _:
            return false

func _resolve_ref(reference: String) -> Dictionary:
    var prefix: String = "#/$defs/"
    if not reference.begins_with(prefix):
        return {}
    return definition(reference.trim_prefix(prefix))

func _child_path(path: String, field: String) -> String:
    if path == "":
        return field
    return path + "." + field

func _append_error(errors: Array[Dictionary], path: String, code: String, message: String) -> void:
    errors.append({"code": code, "path": path, "message": message})
