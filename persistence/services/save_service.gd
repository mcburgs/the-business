extends RefCounted

const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const ProjectVersion = preload("res://app/bootstrap/project_version.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")

const SAVE_SCHEMA_VERSION: int = 1
const CHRONICLE_SCHEMA_VERSION: int = 1
const MIGRATABLE_ARCHITECTURE_VERSIONS: Array[String] = ["0.2.0"]
const FLOAT64_BITS_KEY: String = "__we_float64_bits_v1"
const INT64_TEXT_KEY: String = "__we_int64_text_v1"

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

    # A stale interrupted transaction must be settled before starting another write. Never
    # delete .previous/.tmp blindly: either may be the only surviving good campaign.
    if DirAccess.dir_exists_absolute(temp_abs) or DirAccess.dir_exists_absolute(previous_abs):
        var interrupted: Dictionary = recover_interrupted_transaction(save_id, str(state.get("content_fingerprint")))
        if not bool(interrupted.get("passed", false)):
            return interrupted

    _remove_tree(temp_abs)
    if DirAccess.make_dir_recursive_absolute(temp_abs.path_join("chronicle")) != OK:
        return _failure("SAVE001", "save", {"reason": "unable_to_create_temp_directory"})

    var state_data: Dictionary = _state_to_json_safe(_state_codec.call("encode", state))
    var chronicle_data: Dictionary = _float_exact_to_json_safe(_chronicle_codec.call("encode", chronicle))
    var manifest: Dictionary = _make_manifest(save_id, display_name, state, chronicle, metadata)
    var chronicle_manifest: Dictionary = {
        "chronicle_schema_version": CHRONICLE_SCHEMA_VERSION,
        "head_date": chronicle.get("head_date"),
        "head_sequence": chronicle.get("head_sequence"),
        "checkpoint_generation": chronicle.get("checkpoint_generation"),
        "integrity": chronicle.call("counts"),
        "data_reference": "chronicle.json",
    }

    if not _write_json(temp_abs.path_join("state.json"), state_data):
        _remove_tree(temp_abs); return _failure("SAVE001", "state", {"reason": "temp_write_failed"})
    if failure_injection_stage == "after_state_write":
        return _failure("SAVE001", "state", {"reason": "injected_interruption_after_state_write"})
    if not _write_json(temp_abs.path_join("chronicle/chronicle.json"), chronicle_data):
        _remove_tree(temp_abs); return _failure("SAVE001", "chronicle", {"reason": "temp_write_failed"})
    if failure_injection_stage == "after_chronicle_write":
        return _failure("SAVE001", "chronicle", {"reason": "injected_interruption_after_chronicle_write"})

    # Hash physical payload bytes after the file is closed. Hashes are optional on legacy
    # Phase-H saves, but mandatory on every save written from H->I onward.
    manifest["state_sha256"] = _sha256_file(temp_abs.path_join("state.json"))
    manifest["chronicle_data_sha256"] = _sha256_file(temp_abs.path_join("chronicle/chronicle.json"))
    chronicle_manifest["data_sha256"] = manifest["chronicle_data_sha256"]

    if not _write_json(temp_abs.path_join("chronicle/manifest.json"), chronicle_manifest):
        _remove_tree(temp_abs); return _failure("SAVE001", "chronicle.manifest", {"reason": "temp_write_failed"})
    if failure_injection_stage == "after_chronicle_manifest_write":
        return _failure("SAVE001", "chronicle.manifest", {"reason": "injected_interruption_after_chronicle_manifest_write"})
    if not _write_json(temp_abs.path_join("manifest.json"), manifest):
        _remove_tree(temp_abs); return _failure("SAVE001", "manifest", {"reason": "temp_write_failed"})
    if failure_injection_stage == "after_manifest_write":
        return _failure("SAVE001", "manifest", {"reason": "injected_interruption_after_manifest_write"})

    var temp_load: Dictionary = _load_from_absolute(temp_abs, state.get("content_fingerprint"), false)
    if not bool(temp_load.get("passed", false)):
        _remove_tree(temp_abs); return temp_load
    if failure_injection_stage == "before_publish":
        _remove_tree(temp_abs)
        return _failure("SAVE001", "publish", {"reason": "injected_failure_before_publish"})

    if DirAccess.dir_exists_absolute(target_abs):
        _remove_tree(previous_abs)
        var rename_old: Error = DirAccess.rename_absolute(target_abs, previous_abs)
        if rename_old != OK:
            _remove_tree(temp_abs); return _failure("SAVE001", "publish", {"reason": "unable_to_preserve_last_good", "error": rename_old})
    if failure_injection_stage == "after_preserve_previous":
        # Models process death after the old primary left its canonical path but before the
        # validated temp checkpoint is promoted. Artifacts are intentionally retained.
        return _failure("SAVE001", "publish", {"reason": "injected_interruption_after_preserve_previous"})

    var publish_error: Error = DirAccess.rename_absolute(temp_abs, target_abs)
    if publish_error != OK:
        if DirAccess.dir_exists_absolute(previous_abs) and not DirAccess.dir_exists_absolute(target_abs):
            DirAccess.rename_absolute(previous_abs, target_abs)
        _remove_tree(temp_abs)
        return _failure("SAVE001", "publish", {"reason": "temp_publish_failed", "error": publish_error})
    if failure_injection_stage == "after_publish":
        # Models death after the new primary is live but before backup rotation/cleanup.
        return _failure("SAVE001", "publish", {"reason": "injected_interruption_after_publish"})

    var backup_result: Dictionary
    if failure_injection_stage == "backup_copy_failure":
        backup_result = {"passed": false, "warning": "injected_backup_copy_failure"}
    else:
        backup_result = _finalize_backup_roots([previous_abs], target_abs, str(state.get("content_fingerprint")))
    if not bool(backup_result.get("passed", false)):
        # The new primary is valid. Crucially, .previous remains untouched so the previous
        # known-good source cannot be destroyed by a failed backup-copy/low-storage path.
        return {
            "passed": true,
            "errors": [],
            "manifest": manifest,
            "path": root_path.path_join(save_id),
            "recovery_available": has_last_good(save_id),
            "recovery_warning": str(backup_result.get("warning", "backup_rotation_failed_previous_retained")),
            "backup_retry_retained": DirAccess.dir_exists_absolute(previous_abs),
        }
    _remove_tree(previous_abs)
    return {"passed": true, "errors": [], "manifest": manifest, "path": root_path.path_join(save_id), "recovery_available": has_last_good(save_id), "recovery_warning": ""}

func has_save_artifact(save_id: String) -> bool:
    return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root_path).path_join(save_id))

func has_last_good(save_id: String) -> bool:
    return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root_path).path_join(save_id).path_join("backups/last_good"))

func has_older_good(save_id: String) -> bool:
    return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root_path).path_join(save_id).path_join("backups/older_good"))

func load_save(save_id: String, expected_content_fingerprint: String = "") -> Dictionary:
    var absolute: String = ProjectSettings.globalize_path(root_path).path_join(save_id)
    return _load_from_absolute(absolute, expected_content_fingerprint, true)

func load_last_good(save_id: String, expected_content_fingerprint: String = "") -> Dictionary:
    var absolute: String = ProjectSettings.globalize_path(root_path).path_join(save_id).path_join("backups/last_good")
    return _load_from_absolute(absolute, expected_content_fingerprint, true)

func load_older_good(save_id: String, expected_content_fingerprint: String = "") -> Dictionary:
    var absolute: String = ProjectSettings.globalize_path(root_path).path_join(save_id).path_join("backups/older_good")
    return _load_from_absolute(absolute, expected_content_fingerprint, true)

func recover_interrupted_transaction(save_id: String, expected_content_fingerprint: String = "") -> Dictionary:
    var base_abs: String = ProjectSettings.globalize_path(root_path)
    var target_abs: String = base_abs.path_join(save_id)
    var temp_abs: String = base_abs.path_join("." + save_id + ".tmp")
    var previous_abs: String = base_abs.path_join("." + save_id + ".previous")
    var staging_abs: String = base_abs.path_join("." + save_id + ".recovery_old")
    var has_temp: bool = DirAccess.dir_exists_absolute(temp_abs)
    var has_previous: bool = DirAccess.dir_exists_absolute(previous_abs)
    if not has_temp and not has_previous:
        return {"passed": true, "recovered": false, "disposition": "no_interrupted_artifacts"}

    var target: Dictionary = _try_load_snapshot(target_abs, expected_content_fingerprint)
    var temp: Dictionary = _try_load_snapshot(temp_abs, expected_content_fingerprint)
    var previous: Dictionary = _try_load_snapshot(previous_abs, expected_content_fingerprint)

    # A fully validated temp is a completed checkpoint. Promote it only when it is newer
    # than the valid canonical primary, or when no valid primary survived.
    var promote_temp: bool = bool(temp.get("passed", false)) and (
        not bool(target.get("passed", false)) or _snapshot_is_newer(temp, target)
    )
    if promote_temp:
        _remove_tree(staging_abs)
        if DirAccess.dir_exists_absolute(target_abs):
            if DirAccess.rename_absolute(target_abs, staging_abs) != OK:
                return _failure("SAVE001", "recovery", {"reason": "unable_to_stage_existing_primary"})
        var promote_error: Error = DirAccess.rename_absolute(temp_abs, target_abs)
        if promote_error != OK:
            if DirAccess.dir_exists_absolute(staging_abs) and not DirAccess.dir_exists_absolute(target_abs):
                DirAccess.rename_absolute(staging_abs, target_abs)
            return _failure("SAVE001", "recovery", {"reason": "unable_to_promote_valid_temp", "error": promote_error})
        var roots: Array[String] = []
        if DirAccess.dir_exists_absolute(staging_abs): roots.append(staging_abs)
        if DirAccess.dir_exists_absolute(previous_abs): roots.append(previous_abs)
        var backups: Dictionary = _finalize_backup_roots(roots, target_abs, expected_content_fingerprint)
        if bool(backups.get("passed", false)):
            _remove_tree(staging_abs)
            _remove_tree(previous_abs)
        return {
            "passed": true,
            "recovered": true,
            "disposition": "promoted_valid_temp",
            "backup_rotation_passed": bool(backups.get("passed", false)),
            "backup_warning": str(backups.get("warning", "")),
        }

    if bool(target.get("passed", false)):
        # The canonical primary already won publication. Finish any interrupted backup
        # rotation, then discard only an invalid/equal-or-older temp.
        var roots: Array[String] = []
        if has_previous: roots.append(previous_abs)
        var backups: Dictionary = _finalize_backup_roots(roots, target_abs, expected_content_fingerprint)
        if bool(backups.get("passed", false)):
            _remove_tree(previous_abs)
        if has_temp and (not bool(temp.get("passed", false)) or not _snapshot_is_newer(temp, target)):
            _remove_tree(temp_abs)
        return {
            "passed": true,
            "recovered": has_previous,
            "disposition": "primary_valid_interrupted_cleanup",
            "backup_rotation_passed": bool(backups.get("passed", true)),
            "backup_warning": str(backups.get("warning", "")),
        }

    # No valid primary/temp survived. Recover the best validated previous transaction,
    # including backups nested inside .previous. Never interpret these artifacts as a new game.
    var candidates: Array[Dictionary] = _collect_snapshot_candidates([previous_abs], expected_content_fingerprint)
    if not candidates.is_empty():
        var chosen: Dictionary = candidates[0]
        _remove_tree(target_abs)
        if not _copy_snapshot(str(chosen.get("path", "")), target_abs):
            return _failure("SAVE001", "recovery", {"reason": "unable_to_restore_previous_snapshot"})
        var backups: Dictionary = _finalize_backup_roots([previous_abs], target_abs, expected_content_fingerprint)
        if bool(backups.get("passed", false)):
            _remove_tree(previous_abs)
        _remove_tree(temp_abs)
        return {
            "passed": true,
            "recovered": true,
            "disposition": "restored_previous_snapshot",
            "source": str(chosen.get("label", "previous")),
            "backup_rotation_passed": bool(backups.get("passed", false)),
            "backup_warning": str(backups.get("warning", "")),
        }

    # If the primary itself is corrupt but still contains a valid normal backup, leave it
    # intact so start_or_resume can perform the ordinary last_good/older_good recovery path.
    var target_backups: Array[Dictionary] = _collect_snapshot_candidates([
        target_abs.path_join("backups/last_good"),
        target_abs.path_join("backups/older_good"),
    ], expected_content_fingerprint, false)
    if not target_backups.is_empty():
        _remove_tree(temp_abs)
        _remove_tree(previous_abs)
        return {"passed": true, "recovered": false, "disposition": "defer_to_primary_backup"}

    return _failure("SAVE001", "recovery", {
        "reason": "interrupted_artifacts_unrecoverable",
        "target_exists": DirAccess.dir_exists_absolute(target_abs),
        "temp_exists": has_temp,
        "previous_exists": has_previous,
    })

func safe_checkpoint(save_id: String, display_name: String, state: RefCounted, chronicle: RefCounted, metadata: Dictionary = {}) -> Dictionary:
    return save(save_id, display_name, state, chronicle, metadata)

func _load_from_absolute(absolute: String, expected_content_fingerprint: String, enforce_compatibility: bool) -> Dictionary:
    var manifest_result: Dictionary = _read_json(absolute.path_join("manifest.json"))
    if not bool(manifest_result["passed"]): return manifest_result
    var manifest: Dictionary = manifest_result["data"]
    var manifest_validation: Dictionary = _validate_manifest(manifest, expected_content_fingerprint if enforce_compatibility else "")
    if not bool(manifest_validation["passed"]): return manifest_validation

    var state_path: String = absolute.path_join(str(manifest.get("state_reference", "state.json")))
    var chronicle_manifest_path: String = absolute.path_join(str(manifest.get("chronicle_manifest_reference", "chronicle/manifest.json")))
    var state_result: Dictionary = _read_json(state_path)
    if not bool(state_result["passed"]): return state_result
    var chronicle_result: Dictionary = _read_json(chronicle_manifest_path)
    if not bool(chronicle_result["passed"]): return chronicle_result
    var chronicle_manifest: Dictionary = chronicle_result["data"]
    var chronicle_data_path: String = absolute.path_join("chronicle/").path_join(str(chronicle_manifest.get("data_reference", "chronicle.json")))
    var chronicle_data_result: Dictionary = _read_json(chronicle_data_path)
    if not bool(chronicle_data_result["passed"]): return chronicle_data_result

    # H->I physical-integrity fields are optional for backward compatibility with accepted
    # Phase-H saves. When present they are authoritative and must match exactly.
    var hashes_enforced: bool = str(manifest.get("architecture_version", "")) == ProjectVersion.ARCHITECTURE_VERSION
    var expected_state_hash: String = str(manifest.get("state_sha256", ""))
    if hashes_enforced and not expected_state_hash.is_empty() and _sha256_file(state_path) != expected_state_hash:
        return _failure("SAVE001", "state.json", {"reason": "payload_hash_mismatch"})
    var expected_chronicle_hash: String = str(manifest.get("chronicle_data_sha256", chronicle_manifest.get("data_sha256", "")))
    if hashes_enforced and not expected_chronicle_hash.is_empty() and _sha256_file(chronicle_data_path) != expected_chronicle_hash:
        return _failure("SAVE001", "chronicle/chronicle.json", {"reason": "payload_hash_mismatch"})
    var chronicle_manifest_hash: String = str(chronicle_manifest.get("data_sha256", ""))
    if hashes_enforced and not chronicle_manifest_hash.is_empty() and chronicle_manifest_hash != _sha256_file(chronicle_data_path):
        return _failure("SAVE001", "chronicle.manifest.data_sha256", {"reason": "payload_hash_mismatch"})

    var decoded_state: Dictionary = _state_codec.call("decode", _state_from_json_safe(state_result["data"]))
    if not bool(decoded_state["passed"]): return {"passed": false, "errors": decoded_state["errors"]}
    var decoded_chronicle: Dictionary = _chronicle_codec.call("decode", _float_exact_from_json_safe(chronicle_data_result["data"]))
    if not bool(decoded_chronicle["passed"]): return {"passed": false, "errors": decoded_chronicle["errors"]}
    var state: RefCounted = decoded_state["state"]
    var chronicle: RefCounted = decoded_chronicle["chronicle"]

    if str(chronicle.get("head_date")) != str(manifest.get("chronicle_head_date")) or int(chronicle.get("head_sequence")) != int(manifest.get("chronicle_head_sequence")):
        return _failure("SAVE001", "manifest.chronicle_head", {"reason": "head_mismatch"})
    if int(chronicle.get("checkpoint_generation")) != int(manifest.get("checkpoint_generation", -1)):
        return _failure("SAVE001", "manifest.checkpoint_generation", {"reason": "checkpoint_generation_mismatch"})
    if str(state.get("current_date")) != str(manifest.get("in_game_date", "")):
        return _failure("SAVE001", "manifest.in_game_date", {"reason": "state_date_mismatch"})
    if str(state.get("ownership_seat").get("promotion_id")) != str(manifest.get("player_promotion_id", "")):
        return _failure("SAVE001", "manifest.player_promotion_id", {"reason": "ownership_mismatch"})
    if str(chronicle.get("head_date")) != "" and str(chronicle.get("head_date")) != str(state.get("current_date")):
        return _failure("SAVE001", "state_chronicle", {"reason": "current_state_chronicle_date_mismatch"})

    var actual_counts: Dictionary = chronicle.call("counts")
    var recorded_counts: Variant = manifest.get("chronicle_integrity_summary", {})
    if recorded_counts is Dictionary and not (recorded_counts as Dictionary).is_empty() and not _semantic_equal(actual_counts, recorded_counts):
        return _failure("SAVE001", "manifest.chronicle_integrity_summary", {"reason": "integrity_count_mismatch", "expected": recorded_counts, "actual": actual_counts})
    var cm_counts: Variant = chronicle_manifest.get("integrity", {})
    if cm_counts is Dictionary and not (cm_counts as Dictionary).is_empty() and not _semantic_equal(actual_counts, cm_counts):
        return _failure("SAVE001", "chronicle.manifest.integrity", {"reason": "integrity_count_mismatch", "expected": cm_counts, "actual": actual_counts})
    if str(chronicle_manifest.get("head_date", "")) != str(chronicle.get("head_date")) or int(chronicle_manifest.get("head_sequence", -1)) != int(chronicle.get("head_sequence")) or int(chronicle_manifest.get("checkpoint_generation", -1)) != int(chronicle.get("checkpoint_generation")):
        return _failure("SAVE001", "chronicle.manifest", {"reason": "chronicle_manifest_mismatch"})

    return {"passed": true, "errors": [], "state": state, "chronicle": chronicle, "manifest": manifest, "migrations_applied": decoded_state.get("migrations_applied", [])}

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
    var architecture_version: String = str(manifest.get("architecture_version", ""))
    if architecture_version != ProjectVersion.ARCHITECTURE_VERSION and not architecture_version in MIGRATABLE_ARCHITECTURE_VERSIONS:
        return _failure("SAVE001", "manifest.architecture_version", {"expected": ProjectVersion.ARCHITECTURE_VERSION, "migratable": MIGRATABLE_ARCHITECTURE_VERSIONS, "actual": architecture_version})
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
    return _float_exact_to_json_safe(output) as Dictionary

func _state_from_json_safe(data: Dictionary) -> Dictionary:
    var output: Dictionary = data.duplicate(true)
    if output.get("rng_state") is Dictionary:
        var rng: Dictionary = output["rng_state"]
        var internal_value: Variant = rng.get("internal_state")
        if internal_value is String and str(internal_value).is_valid_int(): rng["internal_state"] = int(internal_value)
        output["rng_state"] = rng
    output = _float_exact_from_json_safe(output)
    _restore_minor_units(output)
    return output

func _float_exact_to_json_safe(value: Variant) -> Variant:
    # Godot 4.7 JSON parsing does not preserve every Variant numeric type exactly: some
    # binary64 decimals move by one ULP and integral JSON values decode as floats. A
    # save/reload boundary must not perturb deterministic state or Chronicle fingerprints,
    # so the physical JSON layer tags int64 values and stores float64 IEEE-754 bytes.
    # Logical codecs/save schema remain unchanged, and untagged legacy JSON still loads.
    if value is int:
        return {INT64_TEXT_KEY: str(value)}
    if value is float:
        return {FLOAT64_BITS_KEY: PackedFloat64Array([float(value)]).to_byte_array().hex_encode()}
    if value is Dictionary:
        var encoded_dictionary: Dictionary = {}
        for key: Variant in (value as Dictionary).keys():
            encoded_dictionary[key] = _float_exact_to_json_safe((value as Dictionary)[key])
        return encoded_dictionary
    if value is Array:
        var encoded_array: Array = []
        for item: Variant in (value as Array):
            encoded_array.append(_float_exact_to_json_safe(item))
        return encoded_array
    return value

func _float_exact_from_json_safe(value: Variant) -> Variant:
    if value is Dictionary:
        var dictionary: Dictionary = value
        if dictionary.size() == 1 and dictionary.has(INT64_TEXT_KEY):
            var integer_text: Variant = dictionary.get(INT64_TEXT_KEY)
            if integer_text is String and str(integer_text).is_valid_int():
                return int(integer_text)
            return value
        if dictionary.size() == 1 and dictionary.has(FLOAT64_BITS_KEY):
            var bits_text: Variant = dictionary.get(FLOAT64_BITS_KEY)
            if bits_text is String:
                var bytes: PackedByteArray = str(bits_text).hex_decode()
                if bytes.size() == 8:
                    var values: PackedFloat64Array = bytes.to_float64_array()
                    if values.size() == 1:
                        return values[0]
            return value
        var decoded_dictionary: Dictionary = {}
        for key: Variant in dictionary.keys():
            decoded_dictionary[key] = _float_exact_from_json_safe(dictionary[key])
        return decoded_dictionary
    if value is Array:
        var decoded_array: Array = []
        for item: Variant in (value as Array):
            decoded_array.append(_float_exact_from_json_safe(item))
        return decoded_array
    return value

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

func _try_load_snapshot(path: String, expected_content_fingerprint: String) -> Dictionary:
    if not DirAccess.dir_exists_absolute(path):
        return {"passed": false, "path": path, "missing": true}
    var loaded: Dictionary = _load_from_absolute(path, expected_content_fingerprint, true)
    loaded["path"] = path
    return loaded

func _snapshot_rank(loaded: Dictionary) -> Array[int]:
    if not bool(loaded.get("passed", false)): return [-1, -1, -1]
    var state: RefCounted = loaded.get("state")
    var chronicle: RefCounted = loaded.get("chronicle")
    return [int(state.get("turn_number")), int(chronicle.get("head_sequence")), int(chronicle.get("checkpoint_generation"))]

func _snapshot_is_newer(left: Dictionary, right: Dictionary) -> bool:
    var a: Array[int] = _snapshot_rank(left)
    var b: Array[int] = _snapshot_rank(right)
    for index: int in range(mini(a.size(), b.size())):
        if a[index] != b[index]: return a[index] > b[index]
    return false

func _collect_snapshot_candidates(roots: Array[String], expected_content_fingerprint: String, include_nested: bool = true) -> Array[Dictionary]:
    var candidates: Array[Dictionary] = []
    var seen: Dictionary = {}
    for root: String in roots:
        var paths: Array[String] = [root]
        if include_nested:
            paths.append(root.path_join("backups/last_good"))
            paths.append(root.path_join("backups/older_good"))
        for path: String in paths:
            if seen.has(path): continue
            seen[path] = true
            var loaded: Dictionary = _try_load_snapshot(path, expected_content_fingerprint)
            if not bool(loaded.get("passed", false)): continue
            loaded["label"] = path.get_file()
            candidates.append(loaded)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _snapshot_is_newer(a, b))
    return candidates

func _finalize_backup_roots(roots: Array[String], target_abs: String, expected_content_fingerprint: String) -> Dictionary:
    if roots.is_empty(): return {"passed": true, "copied": 0}
    var candidates: Array[Dictionary] = _collect_snapshot_candidates(roots, expected_content_fingerprint)
    if candidates.is_empty():
        # No valid predecessor is not fatal for the new primary, but interrupted material
        # must be retained/diagnosable rather than silently erased.
        var any_root: bool = false
        for root: String in roots:
            any_root = any_root or DirAccess.dir_exists_absolute(root)
        if any_root: return {"passed": false, "warning": "no_valid_predecessor_snapshot"}
        return {"passed": true, "copied": 0}
    var copied: int = 0
    if not _copy_snapshot(str(candidates[0].get("path", "")), target_abs.path_join("backups/last_good")):
        return {"passed": false, "warning": "last_good_snapshot_copy_failed"}
    copied += 1
    if candidates.size() > 1:
        if not _copy_snapshot(str(candidates[1].get("path", "")), target_abs.path_join("backups/older_good")):
            return {"passed": false, "warning": "older_good_snapshot_copy_failed"}
        copied += 1
    return {"passed": true, "copied": copied}

func _copy_snapshot(source_abs: String, target_abs: String) -> bool:
    _remove_tree(target_abs)
    if DirAccess.make_dir_recursive_absolute(target_abs.path_join("chronicle")) != OK:
        return false
    var files: Array[Array] = [
        ["manifest.json", "manifest.json"],
        ["state.json", "state.json"],
        ["chronicle/manifest.json", "chronicle/manifest.json"],
        ["chronicle/chronicle.json", "chronicle/chronicle.json"],
    ]
    for pair: Array in files:
        var source: String = source_abs.path_join(str(pair[0]))
        var target: String = target_abs.path_join(str(pair[1]))
        if not FileAccess.file_exists(source) or DirAccess.copy_absolute(source, target) != OK:
            _remove_tree(target_abs)
            return false
    return true

func _sha256_file(path: String) -> String:
    if not FileAccess.file_exists(path): return ""
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null: return ""
    var context: HashingContext = HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    while file.get_position() < file.get_length():
        context.update(file.get_buffer(mini(65536, file.get_length() - file.get_position())))
    file.close()
    return context.finish().hex_encode()

func _semantic_equal(left: Variant, right: Variant) -> bool:
    if (left is int or left is float) and (right is int or right is float):
        return float(left) == float(right)
    if left is Dictionary and right is Dictionary:
        if (left as Dictionary).size() != (right as Dictionary).size(): return false
        for key: Variant in (left as Dictionary).keys():
            if not (right as Dictionary).has(key) or not _semantic_equal((left as Dictionary)[key], (right as Dictionary)[key]): return false
        return true
    if left is Array and right is Array:
        if (left as Array).size() != (right as Array).size(): return false
        for index: int in range((left as Array).size()):
            if not _semantic_equal((left as Array)[index], (right as Array)[index]): return false
        return true
    return left == right

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
