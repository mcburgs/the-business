extends RefCounted

const JsonSchemaValidator = preload("res://app/content/json_schema_validator.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var path: String = "res://content/schemas/we.phase0.schema.json"
    _expect(FileAccess.file_exists(path), "Controlled Phase B schema replacement is missing.", failures)
    if not failures.is_empty():
        return _result(failures)

    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    _expect(file != null, "Controlled Phase B schema replacement cannot be opened.", failures)
    if file == null:
        return _result(failures)
    var text: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text)
    _expect(parsed is Dictionary, "Phase B schema replacement is not valid JSON object data.", failures)
    if not parsed is Dictionary:
        return _result(failures)

    var schema: Dictionary = parsed
    _expect(str(schema.get("$schema", "")) == "https://json-schema.org/draft/2020-12/schema", "Schema must declare JSON Schema Draft 2020-12.", failures)
    _expect(str(schema.get("x-we-derivation-status", "")) == "controlled_reconstruction", "Schema must disclose controlled reconstruction status.", failures)
    _expect(str(schema.get("x-we-original-artifact-status", "")) == "not_supplied", "Schema must not masquerade as the missing original artifact.", failures)

    var defs_value: Variant = schema.get("$defs", {})
    _expect(defs_value is Dictionary, "Schema must expose a $defs dictionary.", failures)
    if defs_value is Dictionary:
        var defs: Dictionary = defs_value
        for required: String in ["ContentId", "CampaignPackManifest", "MapDefinition", "MarketDefinition", "PersonSeedDefinition", "PromotionSeedDefinition", "MediaTechDefinition", "SeededHistoryHook"]:
            _expect(defs.has(required), "Schema is missing required Phase B definition: " + required, failures)
        _expect(not text.contains('"maxItems"'), "Phase B schema must not encode slice population counts as engine limits.", failures)

    _expect(FileAccess.file_exists("res://content/schemas/DERIVATION.md"), "Controlled reconstruction derivation record is missing.", failures)

    # Godot's JSON parser materializes JSON numbers as floats. JSON Schema integer
    # semantics therefore must accept mathematically integral floats such as 1.0.
    var validator: Variant = JsonSchemaValidator.new(schema)
    var parsed_integer_probe: Variant = JSON.parse_string("{\"value\":1}")
    _expect(parsed_integer_probe is Dictionary, "Integer probe JSON did not parse as an object.", failures)
    if parsed_integer_probe is Dictionary:
        var integer_errors: Array[Dictionary] = validator.validate(
            (parsed_integer_probe as Dictionary).get("value"),
            {"type": "integer"},
            "integer_probe"
        )
        _expect(integer_errors.is_empty(), "Schema integer validation must accept integral JSON numbers parsed by Godot.", failures)

    return _result(failures)

func _result(failures: Array[String]) -> Dictionary:
    return {"name": "phase_b_schema_contract", "passed": failures.is_empty(), "failures": failures}

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
