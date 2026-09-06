extends RefCounted

const JsonSchemaValidator = preload("res://app/content/json_schema_validator.gd")
const ContentSafety = preload("res://app/content/content_safety.gd")
const VersionConstraint = preload("res://app/content/version_constraint.gd")
const ContentValidator = preload("res://app/content/content_validator.gd")
const ContentFingerprint = preload("res://app/content/content_fingerprint.gd")
const ContentRegistry = preload("res://app/content/content_registry.gd")

const SCHEMA_PATH: String = "res://content/schemas/we.phase0.schema.json"
const FAMILY_SCHEMA_DEFS: Dictionary = {
    "roles": "RoleDefinition",
    "rulesets": "RulesetDefinition",
    "media_mediums": "MediaMediumDefinition",
    "media_tech": "MediaTechDefinition",
    "promotion_strategies": "PromotionStrategyDefinition",
    "map": "MapDefinition",
    "regions": "RegionDefinition",
    "markets": "MarketDefinition",
    "venues": "VenueDefinition",
    "people": "PersonSeedDefinition",
    "promotions": "PromotionSeedDefinition",
    "media_outlets": "MediaOutletDefinition",
    "championships": "ChampionshipSeedDefinition",
    "contracts": "ContractSeedDefinition",
    "history_hooks": "SeededHistoryHook",
}

var _schema_validator: Variant
var _safety: Variant
var _versions: Variant
var _semantic_validator: Variant
var _fingerprinter: Variant

func _init() -> void:
    _safety = ContentSafety.new()
    _versions = VersionConstraint.new()
    _semantic_validator = ContentValidator.new()
    _fingerprinter = ContentFingerprint.new()

func load_campaign(campaign_directory: String, search_roots: Array[String]) -> Dictionary:
    var errors: Array[Dictionary] = []
    var warnings: Array[Dictionary] = []
    var schema_result: Dictionary = _read_json_object(SCHEMA_PATH, "$schema", errors)
    if not errors.is_empty():
        return _failed(errors, warnings)
    _schema_validator = JsonSchemaValidator.new(schema_result)

    var campaign_manifest_path: String = campaign_directory.path_join("manifest.json")
    var campaign_manifest: Dictionary = _read_json_object(campaign_manifest_path, "manifest", errors)
    if not errors.is_empty():
        return _failed(errors, warnings)
    _validate_manifest(campaign_manifest, true, "manifest", errors)
    _validate_manifest_paths(campaign_manifest, "manifest", errors)
    if not errors.is_empty():
        return _failed(errors, warnings)

    var discovered: Dictionary = {}
    for root: String in search_roots:
        _discover_pack_manifests(root, discovered, errors)
    var campaign_pack_id: String = str(campaign_manifest.get("pack_id", ""))
    if discovered.has(campaign_pack_id) and str((discovered[campaign_pack_id] as Dictionary).get("directory", "")) != campaign_directory:
        errors.append(_error("ID002", "manifest.pack_id", "Campaign pack ID conflicts with another discovered pack: %s" % campaign_pack_id))
    discovered[campaign_pack_id] = {"directory": campaign_directory, "manifest": campaign_manifest}
    if not errors.is_empty():
        return _failed(errors, warnings)

    var resolved: Array[Dictionary] = []
    var visiting: Dictionary = {}
    var visited: Dictionary = {}
    _resolve_pack(campaign_pack_id, discovered, visiting, visited, resolved, errors)
    if not errors.is_empty():
        return _failed(errors, warnings)

    var records_by_family: Dictionary = {}
    var resolved_manifests: Array[Dictionary] = []
    for pack: Dictionary in resolved:
        var manifest: Dictionary = pack.get("manifest", {})
        var directory: String = str(pack.get("directory", ""))
        var is_campaign: bool = str(manifest.get("pack_id", "")) == campaign_pack_id
        _validate_manifest(manifest, is_campaign, "pack[%s].manifest" % str(manifest.get("pack_id", "")), errors)
        _validate_manifest_paths(manifest, "pack[%s].manifest" % str(manifest.get("pack_id", "")), errors)
        if not errors.is_empty():
            return _failed(errors, warnings)
        _load_pack_files(directory, manifest, records_by_family, errors)
        if not errors.is_empty():
            return _failed(errors, warnings)
        resolved_manifests.append(manifest.duplicate(true))

    errors.append_array(_semantic_validator.validate(campaign_manifest, records_by_family))
    if not errors.is_empty():
        return _failed(errors, warnings)

    var fingerprint: String = _fingerprinter.compute(resolved_manifests, records_by_family)
    if fingerprint.length() != 64:
        errors.append(_error("STATE001", "content_fingerprint", "SHA-256 content fingerprint could not be produced."))
        return _failed(errors, warnings)

    var registry: Variant = ContentRegistry.new(records_by_family, resolved_manifests, campaign_manifest, fingerprint)
    return {
        "passed": true,
        "errors": errors,
        "warnings": warnings,
        "registry": registry,
        "fingerprint": fingerprint,
        "resolved_pack_ids": _resolved_pack_ids(resolved_manifests),
    }

func _discover_pack_manifests(root: String, discovered: Dictionary, errors: Array[Dictionary]) -> void:
    var directory: DirAccess = DirAccess.open(root)
    if directory == null:
        return
    if FileAccess.file_exists(root.path_join("manifest.json")):
        var manifest_errors: Array[Dictionary] = []
        var manifest: Dictionary = _read_json_object(root.path_join("manifest.json"), root + "/manifest", manifest_errors)
        if manifest_errors.is_empty():
            var pack_id: String = str(manifest.get("pack_id", ""))
            if not pack_id.is_empty():
                if discovered.has(pack_id) and str((discovered[pack_id] as Dictionary).get("directory", "")) != root:
                    errors.append(_error("ID002", root + "/manifest.pack_id", "Duplicate discovered pack ID '%s'." % pack_id))
                else:
                    discovered[pack_id] = {"directory": root, "manifest": manifest}
        else:
            errors.append_array(manifest_errors)

    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while entry != "":
        if entry != "." and entry != ".." and directory.current_is_dir() and not entry.begins_with("."):
            _discover_pack_manifests(root.path_join(entry), discovered, errors)
        entry = directory.get_next()
    directory.list_dir_end()

func _resolve_pack(pack_id: String, discovered: Dictionary, visiting: Dictionary, visited: Dictionary, resolved: Array[Dictionary], errors: Array[Dictionary]) -> void:
    if visited.has(pack_id):
        return
    if visiting.has(pack_id):
        errors.append(_error("STATE003", "dependencies", "Dependency cycle detected at pack '%s'." % pack_id))
        return
    if not discovered.has(pack_id):
        errors.append(_error("REF001", "dependencies", "Required pack '%s' was not discovered." % pack_id))
        return

    visiting[pack_id] = true
    var pack: Dictionary = discovered[pack_id]
    var manifest: Dictionary = pack.get("manifest", {})
    var requires_value: Variant = manifest.get("requires", [])
    if requires_value is Array:
        for index: int in range((requires_value as Array).size()):
            var dependency_spec: String = str((requires_value as Array)[index])
            var parsed: Dictionary = _versions.parse_dependency(dependency_spec)
            if parsed.is_empty():
                errors.append(_error("STATE001", "pack[%s].manifest.requires[%d]" % [pack_id, index], "Dependency spec is malformed: %s" % dependency_spec))
                continue
            var dependency_id: String = str(parsed.get("pack_id", ""))
            if not discovered.has(dependency_id):
                errors.append(_error("REF001", "pack[%s].manifest.requires[%d]" % [pack_id, index], "Required dependency pack '%s' was not discovered." % dependency_id))
                continue
            var dependency_manifest: Dictionary = (discovered[dependency_id] as Dictionary).get("manifest", {})
            var actual_version: String = str(dependency_manifest.get("pack_version", ""))
            if not _versions.satisfies(actual_version, str(parsed.get("operator", "")), str(parsed.get("version", ""))):
                errors.append(_error("REF001", "pack[%s].manifest.requires[%d]" % [pack_id, index], "Dependency '%s' requires %s but discovered version is %s." % [dependency_id, dependency_spec, actual_version]))
                continue
            _resolve_pack(dependency_id, discovered, visiting, visited, resolved, errors)
    visiting.erase(pack_id)
    if not errors.is_empty():
        return
    visited[pack_id] = true
    resolved.append(pack)

func _load_pack_files(directory: String, manifest: Dictionary, records_by_family: Dictionary, errors: Array[Dictionary]) -> void:
    var files_value: Variant = manifest.get("files", {})
    if not files_value is Dictionary:
        return
    var files: Dictionary = files_value
    var families: Array[String] = []
    for family_value: Variant in files.keys():
        families.append(str(family_value))
    families.sort()

    for family: String in families:
        if not FAMILY_SCHEMA_DEFS.has(family):
            errors.append(_error("STATE001", "pack[%s].files.%s" % [str(manifest.get("pack_id", "")), family], "No Phase B schema definition is registered for content family '%s'." % family))
            continue
        var file_path: String = directory.path_join(str(files.get(family, "")))
        var parsed: Variant = _read_json(file_path, "pack[%s].%s" % [str(manifest.get("pack_id", "")), family], errors)
        if not errors.is_empty():
            return
        var records: Array = []
        if family == "map":
            if not parsed is Dictionary:
                errors.append(_error("STATE001", family, "Map content file must contain one object."))
                return
            records = [parsed]
        else:
            if not parsed is Array:
                errors.append(_error("STATE001", family, "Content family '%s' must contain an array of records." % family))
                return
            records = parsed as Array

        var record_schema: Dictionary = _schema_validator.definition(str(FAMILY_SCHEMA_DEFS.get(family, "")))
        for index: int in range(records.size()):
            var record_path: String = "%s[%d]" % [family, index]
            if family == "map":
                record_path = "map"
            var structural_errors: Array[Dictionary] = _schema_validator.validate(records[index], record_schema, record_path)
            for error: Dictionary in structural_errors:
                if family == "history_hooks" and str(error.get("path", "")).ends_with(".narrative_context"):
                    error["code"] = "NAR001"
                    error["message"] = "NarrativeContext is missing or invalid."
            errors.append_array(structural_errors)
        if not errors.is_empty():
            return

        if not records_by_family.has(family):
            records_by_family[family] = []
        var destination: Array = records_by_family[family]
        for record_value: Variant in records:
            destination.append((record_value as Dictionary).duplicate(true) if record_value is Dictionary else record_value)
        records_by_family[family] = destination

func _validate_manifest(manifest: Dictionary, is_campaign: bool, path: String, errors: Array[Dictionary]) -> void:
    if _schema_validator == null:
        return
    var definition_name: String = "CampaignPackManifest" if is_campaign else "PackManifest"
    errors.append_array(_schema_validator.validate(manifest, _schema_validator.definition(definition_name), path))

func _validate_manifest_paths(manifest: Dictionary, path: String, errors: Array[Dictionary]) -> void:
    var files_value: Variant = manifest.get("files", {})
    if not files_value is Dictionary:
        return
    var files: Dictionary = files_value
    for family_value: Variant in files.keys():
        var family: String = str(family_value)
        errors.append_array(_safety.validate_pack_file_path(str(files.get(family, "")), path + ".files." + family))

func _read_json_object(path: String, diagnostic_path: String, errors: Array[Dictionary]) -> Dictionary:
    var parsed: Variant = _read_json(path, diagnostic_path, errors)
    if parsed is Dictionary:
        return parsed
    if errors.is_empty():
        errors.append(_error("STATE001", diagnostic_path, "Expected a JSON object in %s." % path))
    return {}

func _read_json(path: String, diagnostic_path: String, errors: Array[Dictionary]) -> Variant:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        errors.append(_error("REF001", diagnostic_path, "Required content file could not be opened: %s" % path))
        return null
    var text: String = file.get_as_text()
    file.close()
    var json: JSON = JSON.new()
    var parse_error: Error = json.parse(text)
    if parse_error != OK:
        errors.append(_error("STATE001", diagnostic_path, "JSON parse failure in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()]))
        return null
    return json.data

func _resolved_pack_ids(manifests: Array[Dictionary]) -> Array[String]:
    var output: Array[String] = []
    for manifest: Dictionary in manifests:
        output.append(str(manifest.get("pack_id", "")))
    return output

func _failed(errors: Array[Dictionary], warnings: Array[Dictionary]) -> Dictionary:
    return {"passed": false, "errors": errors, "warnings": warnings, "registry": null, "fingerprint": "", "resolved_pack_ids": []}

func _error(code: String, path: String, message: String) -> Dictionary:
    return {"code": code, "path": path, "message": message}
