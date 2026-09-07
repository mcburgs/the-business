extends RefCounted

const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")

const SAVE_SCHEMA_VERSION: int = 1
const CHRONICLE_SCHEMA_VERSION: int = 1

var root_path: String = "user://saves"
var failure_injection_stage: String = ""
var _state_codec: RefCounted = CampaignStateCodec.new()
var _chronicle_codec: RefCounted = ChronicleCodec.new()

func save(save_id: String, display_name: String, state: RefCounted, chronicle: RefCounted, metadata: Dictionary = {}) -> Dictionary:
    if save_id.is_empty(): return _failure("SAVE001", "save_id", {"reason": "required"})
    var validation: Dictionary = _validate_pair(state, chronicle)
    if not bool(validation["passed"]): return validation
    var base_abs: String = ProjectSettings.globalize_path(root_path)
    DirAccess.make_dir_recursive_absolute(base_abs)
    var target_abs: String = base_abs.path_join(save_id)
    var temp_abs: String = base_abs.path_join("." + save_id + ".tmp")
    var previous_abs: String = base_abs.path_join("." + save_id + ".previous")
    _remove_tree(temp_abs)
    _remove_tree(previous_abs)
    if DirAccess.make_dir_recursive_absolute(temp_abs.path_join("chronicle")) != OK:
        return _failure("SAVE001", "save", {"reason": "unable_to_create_temp_directory"})
    var manifest: Dictionary = _make_manifest(save_id, display_name, state, chronicle, metadata)
    var chronicle_manifest: Dictionary = {
        "chronicle_schema_version": CHRONICLE_SCHEMA_VERSION,
        "head_date": chronicle.get("head_date"),
        "head_sequence": chronicle.get("head_sequence"),
        "checkpoint_generation": chronicle.get("checkpoint_generation"),
        "integrity": chronicle.call("counts"),
        "data_reference": "chronicle.json",
    }
    if not _write_json(temp_abs.path_join("state.json"), _state_to_json_safe(_state_codec.call("encode", state))):
        _remove_tree(temp_abs); return _failure("SAVE001", "state", {"reason": "temp_write_failed"})
    if not _write_json(temp_abs.path_join("chronicle/chronicle.json"), _chronicle_codec.call("encode", chronicle)):
        _remove_tree(temp_abs); return _failure("SAVE001", "chronicle", {"reason": "temp_write_failed"})
    if not _write_json(temp_abs.path_join("chronicle/manifest.json"), chronicle_manifest):
        _remove_tree(temp_abs); return _failure("SAVE001", "chronicle.manifest", {"reason": "temp_write_failed"})
    if not _write_json(temp_abs.path_join("manifest.json"), manifest):
        _remove_tree(temp_abs); return _failure("SAVE001", "manifest", {"reason": "temp_write_failed"})
    var temp_load: Dictionary = _load_from_absolute(temp_abs, state.get("content_fingerprint"), false)
    if not bool(temp_load.get("passed", false)):
        _remove_tree(temp_abs); return temp_load
    if failure_injection_stage == "before_publish":
        _remove_tree(temp_abs)
        return _failure("SAVE001", "publish", {"reason": "injected_failure_before_publish"})
    if DirAccess.dir_exists_absolute(target_abs):
        var rename_old: Error = DirAccess.rename_absolute(target_abs, previous_abs)
        if rename_old != OK:
            _remove_tree(temp_abs); return _failure("SAVE001", "publish", {"reason": "unable_to_preserve_last_good", "error": rename_old})
    var publish_error: Error = DirAccess.rename_absolute(temp_abs, target_abs)
    if publish_error != OK:
        if DirAccess.dir_exists_absolute(previous_abs): DirAccess.rename_absolute(previous_abs, target_abs)
        _remove_tree(temp_abs)
        return _failure("SAVE001", "publish", {"reason": "temp_publish_failed", "error": publish_error})
    if DirAccess.dir_exists_absolute(previous_abs):
        DirAccess.make_dir_recursive_absolute(target_abs.path_join("backups/last_good"))
        _copy_file(previous_abs.path_join("manifest.json"), target_abs.path_join("backups/last_good/manifest.json"))
        _copy_file(previous_abs.path_join("state.json"), target_abs.path_join("backups/last_good/state.json"))
        _copy_file(previous_abs.path_join("chronicle/chronicle.json"), target_abs.path_join("backups/last_good/chronicle.json"))
        _remove_tree(previous_abs)
    return {"passed": true, "errors": [], "manifest": manifest, "path": root_path.path_join(save_id)}

func load_save(save_id: String, expected_content_fingerprint: String = "") -> Dictionary:
    var absolute: String = ProjectSettings.globalize_path(root_path).path_join(save_id)
    return _load_from_absolute(absolute, expected_content_fingerprint, true)

func safe_checkpoint(save_id: String, display_name: String, state: RefCounted, chronicle: RefCounted, metadata: Dictionary = {}) -> Dictionary:
    return save(save_id, display_name, state, chronicle, metadata)

func _load_from_absolute(absolute: String, expected_content_fingerprint: String, enforce_compatibility: bool) -> Dictionary:
    var manifest_result: Dictionary = _read_json(absolute.path_join("manifest.json"))
    if not bool(manifest_result["passed"]): return manifest_result
    var manifest: Dictionary = manifest_result["data"]
    var manifest_validation: Dictionary = _validate_manifest(manifest, expected_content_fingerprint if enforce_compatibility else "")
    if not bool(manifest_validation["passed"]): return manifest_validation
    var state_result: Dictionary = _read_json(absolute.path_join(str(manifest.get("state_reference", "state.json"))))
    if not bool(state_result["passed"]): return state_result
    var chronicle_result: Dictionary = _read_json(absolute.path_join(str(manifest.get("chronicle_manifest_reference", "chronicle/manifest.json"))))
    if not bool(chronicle_result["passed"]): return chronicle_result
    var chronicle_manifest: Dictionary = chronicle_result["data"]
    var chronicle_data_result: Dictionary = _read_json(absolute.path_join("chronicle/").path_join(str(chronicle_manifest.get("data_reference", "chronicle.json"))))
    if not bool(chronicle_data_result["passed"]): return chronicle_data_result
    var decoded_state: Dictionary = _state_codec.call("decode", _state_from_json_safe(state_result["data"]))
    if not bool(decoded_state["passed"]): return {"passed": false, "errors": decoded_state["errors"]}
    var decoded_chronicle: Dictionary = _chronicle_codec.call("decode", chronicle_data_result["data"])
    if not bool(decoded_chronicle["passed"]): return {"passed": false, "errors": decoded_chronicle["errors"]}
    if str(decoded_chronicle["chronicle"].get("head_date")) != str(manifest.get("chronicle_head_date")) or int(decoded_chronicle["chronicle"].get("head_sequence")) != int(manifest.get("chronicle_head_sequence")):
        return _failure("SAVE001", "manifest.chronicle_head", {"reason": "head_mismatch"})
    return {"passed": true, "errors": [], "state": decoded_state["state"], "chronicle": decoded_chronicle["chronicle"], "manifest": manifest}

func _make_manifest(save_id: String, display_name: String, state: RefCounted, chronicle: RefCounted, metadata: Dictionary) -> Dictionary:
    var rng: RefCounted = state.get("rng_state")
    return {
        "save_schema_version": SAVE_SCHEMA_VERSION,
        "architecture_version": ProjectVersion.ARCHITECTURE_VERSION,
        "game_version": ProjectVersion.GAME_VERSION,
        "pinned_engine_major_minor": "4.7",
        "chronicle_schema_version": CHRONICLE_SCHEMA_VERSION,
        "campaign_pack_id": state.get("campaign_pack_id"),
        "campaign_pack_version": state.get("campaign_pack_version"),
        "campaign_pack_hash": metadata.get("campaign_pack_hash", state.get("content_fingerprint")),
        "enabled_packs": metadata.get("enabled_packs", []),
        "resolved_content_fingerprint": state.get("content_fingerprint"),
        "save_id": save_id,
        "display_name": display_name,
        "created_utc": str(metadata.get("created_utc", "unspecified")),
        "updated_utc": str(metadata.get("updated_utc", "unspecified")),
        "in_game_date": state.get("current_date"),
        "player_promotion_id": state.get("ownership_seat").get("promotion_id"),
        "ownership_seat": state.get("ownership_seat").call("to_dict"),
        "rng": _rng_manifest_json_safe(rng.call("to_dict")),
        "chronicle_head_date": chronicle.get("head_date"),
        "chronicle_head_sequence": chronicle.get("head_sequence"),
        "checkpoint_generation": chronicle.get("checkpoint_generation"),
        "chronicle_integrity_summary": chronicle.call("counts"),
        "chronicle_manifest_reference": "chronicle/manifest.json",
        "state_reference": "state.json",
        "recovery_pointer": "backups/last_good",
    }

func _validate_manifest(manifest: Dictionary, expected_content_fingerprint: String) -> Dictionary:
    if int(manifest.get("save_schema_version", -1)) > SAVE_SCHEMA_VERSION or int(manifest.get("chronicle_schema_version", -1)) > CHRONICLE_SCHEMA_VERSION:
        return _failure("SAVE002", "manifest.schema_version", {"supported_save": SAVE_SCHEMA_VERSION, "actual_save": manifest.get("save_schema_version"), "supported_chronicle": CHRONICLE_SCHEMA_VERSION, "actual_chronicle": manifest.get("chronicle_schema_version")})
    if int(manifest.get("save_schema_version", -1)) != SAVE_SCHEMA_VERSION or int(manifest.get("chronicle_schema_version", -1)) != CHRONICLE_SCHEMA_VERSION:
        return _failure("SAVE001", "manifest.schema_version", {"reason": "unsupported_or_invalid_older_schema"})
    if str(manifest.get("architecture_version", "")) != ProjectVersion.ARCHITECTURE_VERSION:
        return _failure("SAVE001", "manifest.architecture_version", {"expected": ProjectVersion.ARCHITECTURE_VERSION, "actual": manifest.get("architecture_version")})
    if not expected_content_fingerprint.is_empty() and str(manifest.get("resolved_content_fingerprint", "")) != expected_content_fingerprint:
        return _failure("SAVE001", "manifest.resolved_content_fingerprint", {"expected": expected_content_fingerprint, "actual": manifest.get("resolved_content_fingerprint")})
    return {"passed": true, "errors": []}

func _validate_pair(state: RefCounted, chronicle: RefCounted) -> Dictionary:
    var ledger_validation: Dictionary = LedgerService.new().validate_ledger(state.get("world_state"))
    if not bool(ledger_validation.get("passed", false)): return ledger_validation
    if str(chronicle.get("head_date")) != "" and str(chronicle.get("head_date")) != str(state.get("current_date")):
        return _failure("SAVE001", "chronicle.head_date", {"reason": "current_state_chronicle_date_mismatch", "state": state.get("current_date"), "chronicle": chronicle.get("head_date")})
    return {"passed": true, "errors": []}

func _state_to_json_safe(data: Dictionary) -> Dictionary:
    var output: Dictionary = data.duplicate(true)
    if output.get("rng_state") is Dictionary:
        var rng: Dictionary = output["rng_state"]
        rng["internal_state"] = str(rng.get("internal_state"))
        output["rng_state"] = rng
    return output

func _state_from_json_safe(data: Dictionary) -> Dictionary:
    var output: Dictionary = data.duplicate(true)
    if output.get("rng_state") is Dictionary:
        var rng: Dictionary = output["rng_state"]
        var internal_value: Variant = rng.get("internal_state")
        if internal_value is String and str(internal_value).is_valid_int(): rng["internal_state"] = int(internal_value)
        output["rng_state"] = rng
    _restore_minor_units(output)
    return output

func _restore_minor_units(value: Variant) -> void:
    if value is Dictionary:
        var dictionary: Dictionary = value
        for key: Variant in dictionary.keys():
            if str(key) == "minor_units" and dictionary[key] is float:
                var number: float = float(dictionary[key])
                if is_finite(number) and floor(number) == number and abs(number) <= 9007199254740991.0:
                    dictionary[key] = int(number)
            else:
                _restore_minor_units(dictionary[key])
    elif value is Array:
        for item: Variant in value:
            _restore_minor_units(item)

func _rng_manifest_json_safe(data: Dictionary) -> Dictionary:
    var output: Dictionary = data.duplicate(true)
    output["internal_state"] = str(output.get("internal_state"))
    return output

func _write_json(path: String, data: Dictionary) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(data, "  ", true, true))
    file.store_line("")
    file.close()
    return true

func _read_json(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null: return _failure("SAVE001", path, {"reason": "file_open_failed"})
    var text: String = file.get_as_text()
    file.close()
    var json: JSON = JSON.new()
    var error: Error = json.parse(text)
    if error != OK or not json.data is Dictionary:
        return _failure("SAVE001", path, {"reason": "invalid_json", "line": json.get_error_line(), "message": json.get_error_message()})
    return {"passed": true, "errors": [], "data": json.data}

func _copy_file(source: String, target: String) -> void:
    if FileAccess.file_exists(source): DirAccess.copy_absolute(source, target)

func _remove_tree(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path): return
    var directory: DirAccess = DirAccess.open(path)
    if directory == null: return
    directory.list_dir_begin()
    var name: String = directory.get_next()
    while name != "":
        if name != "." and name != "..":
            var child: String = path.path_join(name)
            if directory.current_is_dir(): _remove_tree(child)
            else: DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(path)

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
